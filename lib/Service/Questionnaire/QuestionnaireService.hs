module Service.Questionnaire.QuestionnaireService where

import Control.Lens ((^.))
import Control.Monad.Reader (liftIO)
import Data.Time
import qualified Data.UUID as U

import Api.Resource.Questionnaire.QuestionnaireChangeDTO
import Api.Resource.Questionnaire.QuestionnaireCreateDTO
import Api.Resource.Questionnaire.QuestionnaireDTO
import Api.Resource.Questionnaire.QuestionnaireDetailDTO
import Database.DAO.Package.PackageDAO
import Database.DAO.Questionnaire.QuestionnaireDAO
import LensesConfig
import Localization
import Model.Context.AppContext
import Model.Context.AppContextHelpers
import Model.Error.Error
import Model.Package.Package
import Model.Questionnaire.Questionnaire
import Service.KnowledgeModel.KnowledgeModelApplicator
import Service.KnowledgeModel.KnowledgeModelFilter
import Service.Package.PackageService
import Service.Questionnaire.QuestionnaireMapper
import Util.Uuid

import Model.Questionnaire.QuestionnaireState

getQuestionnaires :: AppContextM (Either AppError [QuestionnaireDTO])
getQuestionnaires =
  heFindQuestionnaires $ \questionnaires -> do
    let ioEitherQuestionnairesWithPackages = addPackage <$> questionnaires
    Prelude.foldl foldFn (return . Right $ []) ioEitherQuestionnairesWithPackages
  where
    addPackage :: Questionnaire -> AppContextM (Either AppError (Questionnaire, Package))
    addPackage qtn = heFindPackageById (qtn ^. packageId) $ \pkg -> return . Right $ (qtn, pkg)
    foldFn ::
         AppContextM (Either AppError [QuestionnaireDTO])
      -> AppContextM (Either AppError (Questionnaire, Package))
      -> AppContextM (Either AppError [QuestionnaireDTO])
    foldFn ioEitherAcc ioEitherQtnWithPkg = do
      eitherAcc <- ioEitherAcc
      case eitherAcc of
        Right acc -> do
          eitherQtnWithPkg <- ioEitherQtnWithPkg
          case eitherQtnWithPkg of
            Right (qtn, pkg) -> do
              -- TODO: Find actual state and remove the import
              let qtnDTO = toDTO qtn pkg QSDefault
              return . Right $ acc ++ [qtnDTO]
            Left error -> return . Left $ error
        Left error -> return . Left $ error

getQuestionnairesForCurrentUser :: AppContextM (Either AppError [QuestionnaireDTO])
getQuestionnairesForCurrentUser =
  heGetCurrentUser $ \currentUser ->
    heGetQuestionnaires $ \questionnaires ->
      if currentUser ^. role == "ADMIN"
        then return . Right $ questionnaires
        else return . Right $ filter (justOwnersAndPublicQuestionnaires currentUser) questionnaires
  where
    justOwnersAndPublicQuestionnaires currentUser questionnaire =
      questionnaire ^. private == False || questionnaire ^. ownerUuid == (Just $ currentUser ^. uuid)

createQuestionnaire :: QuestionnaireCreateDTO -> AppContextM (Either AppError QuestionnaireDTO)
createQuestionnaire questionnaireCreateDto = do
  qtnUuid <- liftIO generateUuid
  createQuestionnaireWithGivenUuid qtnUuid questionnaireCreateDto

createQuestionnaireWithGivenUuid :: U.UUID -> QuestionnaireCreateDTO -> AppContextM (Either AppError QuestionnaireDTO)
createQuestionnaireWithGivenUuid qtnUuid reqDto =
  heGetCurrentUser $ \currentUser ->
    heFindPackageWithEventsById (reqDto ^. packageId) $ \package ->
      heGetAllPreviousEventsSincePackageId (reqDto ^. packageId) $ \events ->
        heCreateKnowledgeModel events $ \knowledgeModel -> do
          let filteredKm = filterKnowledgeModel (reqDto ^. tagUuids) knowledgeModel
          now <- liftIO getCurrentTime
          let qtn = fromQuestionnaireCreateDTO reqDto qtnUuid filteredKm (currentUser ^. uuid) now now
          insertQuestionnaire qtn
          -- TODO: Find the actual questionnaire state
          return . Right $ toSimpleDTO qtn package QSDefault

getQuestionnaireById :: String -> AppContextM (Either AppError QuestionnaireDTO)
getQuestionnaireById qtnUuid =
  heFindQuestionnaireById qtnUuid $ \qtn ->
    -- TODO: Find the actual questionnaire state
    checkPermissionToQtn qtn $ heFindPackageById (qtn ^. packageId) $ \package -> return . Right $ toDTO qtn package QSDefault

getQuestionnaireDetailById :: String -> AppContextM (Either AppError QuestionnaireDetailDTO)
getQuestionnaireDetailById qtnUuid =
  heFindQuestionnaireById qtnUuid $ \qtn ->
    checkPermissionToQtn qtn $ do
      heFindPackageWithEventsById (qtn ^. packageId) $ \package ->
        return . Right $ toDetailWithPackageWithEventsDTO qtn package

modifyQuestionnaire :: String -> QuestionnaireChangeDTO -> AppContextM (Either AppError QuestionnaireDetailDTO)
modifyQuestionnaire qtnUuid reqDto =
  heGetQuestionnaireDetailById qtnUuid $ \qtnDto -> do
    now <- liftIO getCurrentTime
    let updatedQtn = fromChangeDTO qtnDto reqDto now
    updateQuestionnaireById updatedQtn
    return . Right $ toDetailWithPackageDTO updatedQtn (qtnDto ^. package)

deleteQuestionnaire :: String -> AppContextM (Maybe AppError)
deleteQuestionnaire qtnUuid =
  hmGetQuestionnaireById qtnUuid $ \questionnaire -> do
    deleteQuestionnaireById qtnUuid
    return Nothing

-- --------------------------------
-- PRIVATE
-- --------------------------------
checkPermissionToQtn qtn callback =
  heGetCurrentUser $ \currentUser ->
    if currentUser ^. role == "ADMIN" || qtn ^. private == False || qtn ^. ownerUuid == (Just $ currentUser ^. uuid)
      then callback
      else return . Left . NotExistsError $ _ERROR_DATABASE__ENTITY_NOT_FOUND

-- --------------------------------
-- HELPERS
-- --------------------------------
heGetQuestionnaires callback = do
  eitherQuestionnaires <- getQuestionnaires
  case eitherQuestionnaires of
    Right questionnaires -> callback questionnaires
    Left error -> return . Left $ error

-- -----------------------------------------------------
hmGetQuestionnaireById qtnUuid callback = do
  eitherQuestionnaire <- getQuestionnaireById qtnUuid
  case eitherQuestionnaire of
    Right questionnaire -> callback questionnaire
    Left error -> return . Just $ error

-- -----------------------------------------------------
heGetQuestionnaireDetailById qtnUuid callback = do
  eitherQuestionnaire <- getQuestionnaireDetailById qtnUuid
  case eitherQuestionnaire of
    Right questionnaire -> callback questionnaire
    Left error -> return . Left $ error
