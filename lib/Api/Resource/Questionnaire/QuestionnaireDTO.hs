module Api.Resource.Questionnaire.QuestionnaireDTO where

import Data.Time
import qualified Data.UUID as U

import Api.Resource.Package.PackageDTO
import Api.Resource.Questionnaire.QuestionnaireStateDTO

data QuestionnaireDTO = QuestionnaireDTO
  { _questionnaireDTOUuid :: U.UUID
  , _questionnaireDTOName :: String
  , _questionnaireDTOLevel :: Int
  , _questionnaireDTOPrivate :: Bool
  , _questionnaireDTOState :: QuestionnaireStateDTO
  , _questionnaireDTOPackage :: PackageDTO
  , _questionnaireDTOOwnerUuid :: Maybe U.UUID
  , _questionnaireDTOCreatedAt :: UTCTime
  , _questionnaireDTOUpdatedAt :: UTCTime
  } deriving (Show, Eq)
