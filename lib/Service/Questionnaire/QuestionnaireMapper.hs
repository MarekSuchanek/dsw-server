module Service.Questionnaire.QuestionnaireMapper where

import Control.Lens ((^.))
import Data.Time
import Data.UUID (UUID)

import qualified Api.Resource.Questionnaire.QuestionnaireStateDTO as QSD
import qualified Model.Questionnaire.QuestionnaireState as QS

import Api.Resource.Package.PackageDTO
import Api.Resource.Questionnaire.QuestionnaireChangeDTO
import Api.Resource.Questionnaire.QuestionnaireCreateDTO
import Api.Resource.Questionnaire.QuestionnaireDTO
import Api.Resource.Questionnaire.QuestionnaireDetailDTO
import Api.Resource.Questionnaire.QuestionnaireReplyDTO
import Api.Resource.Questionnaire.QuestionnaireStateDTO
import LensesConfig
import Model.KnowledgeModel.KnowledgeModel
import Model.Package.Package
import Model.Questionnaire.Questionnaire
import Model.Questionnaire.QuestionnaireReply
import Model.Questionnaire.QuestionnaireState
import Service.KnowledgeModel.KnowledgeModelMapper
import Service.Package.PackageMapper

toDTO :: Questionnaire -> Package -> QuestionnaireState -> QuestionnaireDTO
toDTO questionnaire package state =
  QuestionnaireDTO
  { _questionnaireDTOUuid = questionnaire ^. uuid
  , _questionnaireDTOName = questionnaire ^. name
  , _questionnaireDTOLevel = questionnaire ^. level
  , _questionnaireDTOPrivate = questionnaire ^. private
  , _questionnaireDTOState = toStateDTO state
  , _questionnaireDTOPackage = packageToDTO package
  , _questionnaireDTOOwnerUuid = questionnaire ^. ownerUuid
  , _questionnaireDTOCreatedAt = questionnaire ^. createdAt
  , _questionnaireDTOUpdatedAt = questionnaire ^. updatedAt
  }

toSimpleDTO :: Questionnaire -> PackageWithEvents -> QuestionnaireState -> QuestionnaireDTO
toSimpleDTO questionnaire package state =
  QuestionnaireDTO
  { _questionnaireDTOUuid = questionnaire ^. uuid
  , _questionnaireDTOName = questionnaire ^. name
  , _questionnaireDTOLevel = questionnaire ^. level
  , _questionnaireDTOPrivate = questionnaire ^. private
  , _questionnaireDTOState = toStateDTO state
  , _questionnaireDTOPackage = packageWithEventsToDTO package
  , _questionnaireDTOOwnerUuid = questionnaire ^. ownerUuid
  , _questionnaireDTOCreatedAt = questionnaire ^. createdAt
  , _questionnaireDTOUpdatedAt = questionnaire ^. updatedAt
  }

toReplyDTO :: Reply -> ReplyDTO
toReplyDTO reply = ReplyDTO {_replyDTOPath = reply ^. path, _replyDTOValue = toReplyValueDTO $ reply ^. value}

toReplyValueDTO :: ReplyValue -> ReplyValueDTO
toReplyValueDTO StringReply {..} = StringReplyDTO {_stringReplyDTOValue = _stringReplyValue}
toReplyValueDTO AnswerReply {..} = AnswerReplyDTO {_answerReplyDTOValue = _answerReplyValue}
toReplyValueDTO ItemListReply {..} = ItemListReplyDTO {_itemListReplyDTOValue = _itemListReplyValue}
toReplyValueDTO IntegrationReply {..} =
  IntegrationReplyDTO {_integrationReplyDTOValue = toIntegrationReplyValueDTO _integrationReplyValue}

toIntegrationReplyValueDTO :: IntegrationReplyValue -> IntegrationReplyValueDTO
toIntegrationReplyValueDTO (FairsharingIntegrationReply' reply) =
  FairsharingIntegrationReplyDTO' . toFairsharingIntegrationReplyDTO $ reply

toFairsharingIntegrationReplyDTO :: FairsharingIntegrationReply -> FairsharingIntegrationReplyDTO
toFairsharingIntegrationReplyDTO FairsharingIntegrationReply {..} =
  FairsharingIntegrationReplyDTO
  { _fairsharingIntegrationReplyDTOIntId = _fairsharingIntegrationReplyIntId
  , _fairsharingIntegrationReplyDTOName = _fairsharingIntegrationReplyName
  }

toDetailWithPackageWithEventsDTO :: Questionnaire -> PackageWithEvents -> QuestionnaireState -> QuestionnaireDetailDTO
toDetailWithPackageWithEventsDTO questionnaire package state =
  QuestionnaireDetailDTO
  { _questionnaireDetailDTOUuid = questionnaire ^. uuid
  , _questionnaireDetailDTOName = questionnaire ^. name
  , _questionnaireDetailDTOLevel = questionnaire ^. level
  , _questionnaireDetailDTOPrivate = questionnaire ^. private
  , _questionnaireDetailDTOState = toStateDTO state
  , _questionnaireDetailDTOPackage = packageWithEventsToDTO package
  , _questionnaireDetailDTOSelectedTagUuids = questionnaire ^. selectedTagUuids
  , _questionnaireDetailDTOKnowledgeModel = toKnowledgeModelDTO $ questionnaire ^. knowledgeModel
  , _questionnaireDetailDTOReplies = toReplyDTO <$> questionnaire ^. replies
  , _questionnaireDetailDTOOwnerUuid = questionnaire ^. ownerUuid
  , _questionnaireDetailDTOCreatedAt = questionnaire ^. createdAt
  , _questionnaireDetailDTOUpdatedAt = questionnaire ^. updatedAt
  }

toDetailWithPackageDTO :: Questionnaire -> PackageDTO -> QuestionnaireState -> QuestionnaireDetailDTO
toDetailWithPackageDTO questionnaire package state =
  QuestionnaireDetailDTO
  { _questionnaireDetailDTOUuid = questionnaire ^. uuid
  , _questionnaireDetailDTOName = questionnaire ^. name
  , _questionnaireDetailDTOLevel = questionnaire ^. level
  , _questionnaireDetailDTOPrivate = questionnaire ^. private
  , _questionnaireDetailDTOState = toStateDTO state
  , _questionnaireDetailDTOPackage = package
  , _questionnaireDetailDTOSelectedTagUuids = questionnaire ^. selectedTagUuids
  , _questionnaireDetailDTOKnowledgeModel = toKnowledgeModelDTO $ questionnaire ^. knowledgeModel
  , _questionnaireDetailDTOReplies = toReplyDTO <$> questionnaire ^. replies
  , _questionnaireDetailDTOOwnerUuid = questionnaire ^. ownerUuid
  , _questionnaireDetailDTOCreatedAt = questionnaire ^. createdAt
  , _questionnaireDetailDTOUpdatedAt = questionnaire ^. updatedAt
  }

toStateDTO :: QuestionnaireState -> QuestionnaireStateDTO
toStateDTO QS.QSDefault = QSD.QSDefault
toStateDTO QS.QSMigrating = QSD.QSMigrating
toStateDTO QS.QSOutdated = QSD.QSOutdated

fromReplyDTO :: ReplyDTO -> Reply
fromReplyDTO reply = Reply {_replyPath = reply ^. path, _replyValue = fromReplyValueDTO $ reply ^. value}

fromReplyValueDTO :: ReplyValueDTO -> ReplyValue
fromReplyValueDTO StringReplyDTO {..} = StringReply {_stringReplyValue = _stringReplyDTOValue}
fromReplyValueDTO AnswerReplyDTO {..} = AnswerReply {_answerReplyValue = _answerReplyDTOValue}
fromReplyValueDTO ItemListReplyDTO {..} = ItemListReply {_itemListReplyValue = _itemListReplyDTOValue}
fromReplyValueDTO IntegrationReplyDTO {..} =
  IntegrationReply {_integrationReplyValue = fromIntegrationReplyValueDTO _integrationReplyDTOValue}

fromIntegrationReplyValueDTO :: IntegrationReplyValueDTO -> IntegrationReplyValue
fromIntegrationReplyValueDTO (FairsharingIntegrationReplyDTO' reply) =
  FairsharingIntegrationReply' . fromFairsharingIntegrationReplyDTO $ reply

fromFairsharingIntegrationReplyDTO :: FairsharingIntegrationReplyDTO -> FairsharingIntegrationReply
fromFairsharingIntegrationReplyDTO FairsharingIntegrationReplyDTO {..} =
  FairsharingIntegrationReply
  { _fairsharingIntegrationReplyIntId = _fairsharingIntegrationReplyDTOIntId
  , _fairsharingIntegrationReplyName = _fairsharingIntegrationReplyDTOName
  }

fromChangeDTO :: QuestionnaireDetailDTO -> QuestionnaireChangeDTO -> UTCTime -> Questionnaire
fromChangeDTO qtn dto now =
  Questionnaire
  { _questionnaireUuid = qtn ^. uuid
  , _questionnaireName = qtn ^. name
  , _questionnaireLevel = dto ^. level
  , _questionnairePrivate = qtn ^. private
  , _questionnairePackageId = qtn ^. package . pId
  , _questionnaireSelectedTagUuids = qtn ^. selectedTagUuids
  , _questionnaireKnowledgeModel = fromKnowledgeModelDTO $ qtn ^. knowledgeModel
  , _questionnaireReplies = fromReplyDTO <$> dto ^. replies
  , _questionnaireOwnerUuid = qtn ^. ownerUuid
  , _questionnaireCreatedAt = qtn ^. createdAt
  , _questionnaireUpdatedAt = now
  }

fromQuestionnaireCreateDTO ::
     QuestionnaireCreateDTO -> UUID -> KnowledgeModel -> UUID -> UTCTime -> UTCTime -> Questionnaire
fromQuestionnaireCreateDTO dto qtnUuid knowledgeModel currentUserUuid qtnCreatedAt qtnUpdatedAt =
  Questionnaire
  { _questionnaireUuid = qtnUuid
  , _questionnaireName = dto ^. name
  , _questionnaireLevel = 1
  , _questionnairePrivate = dto ^. private
  , _questionnairePackageId = dto ^. packageId
  , _questionnaireSelectedTagUuids = dto ^. tagUuids
  , _questionnaireKnowledgeModel = knowledgeModel
  , _questionnaireReplies = []
  , _questionnaireOwnerUuid =
      if dto ^. private
        then Just currentUserUuid
        else Nothing
  , _questionnaireCreatedAt = qtnCreatedAt
  , _questionnaireUpdatedAt = qtnUpdatedAt
  }
