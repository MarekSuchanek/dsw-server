module Service.Migration.KnowledgeModel.Applicator.ApplyEvent where

import Model.Error.Error
import Model.KnowledgeModel.KnowledgeModel
import Model.KnowledgeModel.Path

class ApplyEventToKM e where
  applyEventToKM :: e -> Path -> Either AppError (Maybe KnowledgeModel) -> Either AppError (Maybe KnowledgeModel)

class ApplyEventToChapter e where
  applyEventToChapter :: e -> Path -> Either AppError Chapter -> Either AppError Chapter

class ApplyEventToQuestion e where
  applyEventToQuestion :: e -> Path -> Either AppError Question -> Either AppError Question

class ApplyEventToAnswer e where
  applyEventToAnswer :: e -> Path -> Either AppError Answer -> Either AppError Answer

class ApplyEventToExpert e where
  applyEventToExpert :: e -> Path -> Either AppError Expert -> Either AppError Expert

class ApplyEventToReference e where
  applyEventToReference :: e -> Path -> Either AppError Reference -> Either AppError Reference

class ApplyEventToTag e where
  applyEventToTag :: e -> Path -> Either AppError Tag -> Either AppError Tag

class ApplyEventToIntegration e where
  applyEventToIntegration :: e -> Path -> Either AppError Integration -> Either AppError Integration

-- --------------------------------
-- HELPERS
-- --------------------------------
heApplyEventToKM e path eKM callback =
  case applyEventToKM e path eKM of
    Right km -> callback km
    Left e -> Left e

heApplyEventToChapter e path eChapter callback =
  case applyEventToChapter e path eChapter of
    Right chapter -> callback chapter
    Left e -> Left e

heApplyEventToQuestion e path eQuestion callback =
  case applyEventToQuestion e path eQuestion of
    Right question -> callback question
    Left e -> Left e

heApplyEventToAnswer e path eAnswer callback =
  case applyEventToAnswer e path eAnswer of
    Right answer -> callback answer
    Left e -> Left e

heApplyEventToExpert e path eExpert callback =
  case applyEventToExpert e path eExpert of
    Right expert -> callback expert
    Left e -> Left e

heApplyEventToReference e path eReference callback =
  case applyEventToReference e path eReference of
    Right reference -> callback reference
    Left e -> Left e

heApplyEventToTag e path eTag callback =
  case applyEventToTag e path eTag of
    Right tag -> callback tag
    Left e -> Left e

heApplyEventToIntegration e path eIntegration callback =
  case applyEventToIntegration e path eIntegration of
    Right integration -> callback integration
    Left e -> Left e
