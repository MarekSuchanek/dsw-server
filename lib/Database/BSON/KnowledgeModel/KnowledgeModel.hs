module Database.BSON.KnowledgeModel.KnowledgeModel where

import Control.Lens ((^.))
import qualified Data.Bson as BSON
import Data.Bson.Generic
import Data.UUID

import Database.BSON.Common
import LensesConfig
import Model.KnowledgeModel.KnowledgeModel

-- -------------------------
-- KNOWLEDGE MODEL ---------
-- -------------------------
instance ToBSON KnowledgeModel where
  toBSON km =
    [ "uuid" BSON.=: serializeUUID (km ^. uuid)
    , "name" BSON.=: (km ^. name)
    , "chapters" BSON.=: (km ^. chapters)
    , "tags" BSON.=: (km ^. tags)
    ]

instance FromBSON KnowledgeModel where
  fromBSON doc = do
    kmUuidS <- BSON.lookup "uuid" doc
    kmUuid <- fromString kmUuidS
    kmName <- BSON.lookup "name" doc
    kmChapters <- BSON.lookup "chapters" doc
    kmTags <- BSON.lookup "tags" doc
    return
      KnowledgeModel
      { _knowledgeModelUuid = kmUuid
      , _knowledgeModelName = kmName
      , _knowledgeModelChapters = kmChapters
      , _knowledgeModelTags = kmTags
      }

-- -------------------------
-- CHAPTER -----------------
-- -------------------------
instance ToBSON Chapter where
  toBSON model =
    [ "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "title" BSON.=: (model ^. title)
    , "text" BSON.=: (model ^. text)
    , "questions" BSON.=: (model ^. questions)
    ]

instance FromBSON Chapter where
  fromBSON doc = do
    chUuidS <- BSON.lookup "uuid" doc
    chUuid <- fromString chUuidS
    chTitle <- BSON.lookup "title" doc
    chText <- BSON.lookup "text" doc
    chQuestions <- BSON.lookup "questions" doc
    return
      Chapter {_chapterUuid = chUuid, _chapterTitle = chTitle, _chapterText = chText, _chapterQuestions = chQuestions}

-- -------------------------
-- QUESTION ----------------
-- -------------------------
instance ToBSON Question where
  toBSON (OptionsQuestion' event) = toBSON event
  toBSON (ListQuestion' event) = toBSON event
  toBSON (ValueQuestion' event) = toBSON event

instance FromBSON Question where
  fromBSON doc = do
    questionType <- BSON.lookup "questionType" doc
    case questionType of
      "OptionsQuestion" -> OptionsQuestion' <$> (fromBSON doc :: Maybe OptionsQuestion)
      "ListQuestion" -> ListQuestion' <$> (fromBSON doc :: Maybe ListQuestion)
      "ValueQuestion" -> ValueQuestion' <$> (fromBSON doc :: Maybe ValueQuestion)

-- ------------------------------------------------
instance ToBSON OptionsQuestion where
  toBSON model =
    [ "questionType" BSON.=: "OptionsQuestion"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "title" BSON.=: (model ^. title)
    , "text" BSON.=: (model ^. text)
    , "requiredLevel" BSON.=: (model ^. requiredLevel)
    , "tagUuids" BSON.=: serializeUUIDList (model ^. tagUuids)
    , "note" BSON.=: (model ^. note)
    , "references" BSON.=: (model ^. references)
    , "experts" BSON.=: (model ^. experts)
    , "answers" BSON.=: (model ^. answers)
    ]

instance FromBSON OptionsQuestion where
  fromBSON doc = do
    qUuidS <- BSON.lookup "uuid" doc
    qUuid <- fromString qUuidS
    qTitle <- BSON.lookup "title" doc
    qText <- BSON.lookup "text" doc
    qRequiredLevel <- BSON.lookup "requiredLevel" doc
    qTagUuids <- deserializeMaybeUUIDList $ BSON.lookup "tagUuids" doc
    qNote <- BSON.lookup "note" doc
    qReferences <- BSON.lookup "references" doc
    qExperts <- BSON.lookup "experts" doc
    qAnswers <- BSON.lookup "answers" doc
    return
      OptionsQuestion
      { _optionsQuestionUuid = qUuid
      , _optionsQuestionTitle = qTitle
      , _optionsQuestionText = qText
      , _optionsQuestionRequiredLevel = qRequiredLevel
      , _optionsQuestionTagUuids = qTagUuids
      , _optionsQuestionNote = qNote
      , _optionsQuestionReferences = qReferences
      , _optionsQuestionExperts = qExperts
      , _optionsQuestionAnswers = qAnswers
      }

-- ------------------------------------------------
instance ToBSON ListQuestion where
  toBSON model =
    [ "questionType" BSON.=: "ListQuestion"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "title" BSON.=: (model ^. title)
    , "text" BSON.=: (model ^. text)
    , "requiredLevel" BSON.=: (model ^. requiredLevel)
    , "tagUuids" BSON.=: serializeUUIDList (model ^. tagUuids)
    , "note" BSON.=: (model ^. note)
    , "references" BSON.=: (model ^. references)
    , "experts" BSON.=: (model ^. experts)
    , "itemTemplateTitle" BSON.=: (model ^. itemTemplateTitle)
    , "itemTemplateQuestions" BSON.=: (model ^. itemTemplateQuestions)
    ]

instance FromBSON ListQuestion where
  fromBSON doc = do
    qUuidS <- BSON.lookup "uuid" doc
    qUuid <- fromString qUuidS
    qTitle <- BSON.lookup "title" doc
    qText <- BSON.lookup "text" doc
    qRequiredLevel <- BSON.lookup "requiredLevel" doc
    qTagUuids <- deserializeMaybeUUIDList $ BSON.lookup "tagUuids" doc
    qNote <- BSON.lookup "note" doc
    qReferences <- BSON.lookup "references" doc
    qExperts <- BSON.lookup "experts" doc
    qItemTemplateTitle <- BSON.lookup "itemTemplateTitle" doc
    qItemTemplateQuestions <- BSON.lookup "itemTemplateQuestions" doc
    return
      ListQuestion
      { _listQuestionUuid = qUuid
      , _listQuestionTitle = qTitle
      , _listQuestionText = qText
      , _listQuestionRequiredLevel = qRequiredLevel
      , _listQuestionTagUuids = qTagUuids
      , _listQuestionNote = qNote
      , _listQuestionReferences = qReferences
      , _listQuestionExperts = qExperts
      , _listQuestionItemTemplateTitle = qItemTemplateTitle
      , _listQuestionItemTemplateQuestions = qItemTemplateQuestions
      }

-- ------------------------------------------------
instance ToBSON ValueQuestion where
  toBSON model =
    [ "questionType" BSON.=: "ValueQuestion"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "title" BSON.=: (model ^. title)
    , "text" BSON.=: (model ^. text)
    , "requiredLevel" BSON.=: (model ^. requiredLevel)
    , "tagUuids" BSON.=: serializeUUIDList (model ^. tagUuids)
    , "note" BSON.=: (model ^. note)
    , "references" BSON.=: (model ^. references)
    , "experts" BSON.=: (model ^. experts)
    , "valueType" BSON.=: serializeQuestionValueType (model ^. valueType)
    ]

instance FromBSON ValueQuestion where
  fromBSON doc = do
    qUuidS <- BSON.lookup "uuid" doc
    qUuid <- fromString qUuidS
    qTitle <- BSON.lookup "title" doc
    qText <- BSON.lookup "text" doc
    qRequiredLevel <- BSON.lookup "requiredLevel" doc
    qTagUuids <- deserializeMaybeUUIDList $ BSON.lookup "tagUuids" doc
    qNote <- BSON.lookup "note" doc
    qReferences <- BSON.lookup "references" doc
    qExperts <- BSON.lookup "experts" doc
    qValueType <- deserializeQuestionValueType $ BSON.lookup "valueType" doc
    return
      ValueQuestion
      { _valueQuestionUuid = qUuid
      , _valueQuestionTitle = qTitle
      , _valueQuestionText = qText
      , _valueQuestionRequiredLevel = qRequiredLevel
      , _valueQuestionTagUuids = qTagUuids
      , _valueQuestionNote = qNote
      , _valueQuestionReferences = qReferences
      , _valueQuestionExperts = qExperts
      , _valueQuestionValueType = qValueType
      }

-- -------------------------
-- ANSWER ------------------
-- -------------------------
instance ToBSON Answer where
  toBSON model =
    [ "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "label" BSON.=: (model ^. label)
    , "advice" BSON.=: (model ^. advice)
    , "followUps" BSON.=: (model ^. followUps)
    , "metricMeasures" BSON.=: (model ^. metricMeasures)
    ]

instance FromBSON Answer where
  fromBSON doc = do
    ansUuidS <- BSON.lookup "uuid" doc
    ansUuid <- fromString ansUuidS
    ansLabel <- BSON.lookup "label" doc
    ansAdvice <- BSON.lookup "advice" doc
    ansFollowUps <- BSON.lookup "followUps" doc
    ansMetricMeasures <- BSON.lookup "metricMeasures" doc
    return
      Answer
      { _answerUuid = ansUuid
      , _answerLabel = ansLabel
      , _answerAdvice = ansAdvice
      , _answerFollowUps = ansFollowUps
      , _answerMetricMeasures = ansMetricMeasures
      }

-- -------------------------
-- EXPERT ------------------
-- -------------------------
instance ToBSON Expert where
  toBSON model =
    ["uuid" BSON.=: serializeUUID (model ^. uuid), "name" BSON.=: (model ^. name), "email" BSON.=: (model ^. email)]

instance FromBSON Expert where
  fromBSON doc = do
    expUuidS <- BSON.lookup "uuid" doc
    expUuid <- fromString expUuidS
    expName <- BSON.lookup "name" doc
    expEmail <- BSON.lookup "email" doc
    return Expert {_expertUuid = expUuid, _expertName = expName, _expertEmail = expEmail}

-- -------------------------
-- REFERENCE ---------------
-- -------------------------
instance ToBSON Reference where
  toBSON (ResourcePageReference' event) = toBSON event
  toBSON (URLReference' event) = toBSON event
  toBSON (CrossReference' event) = toBSON event

instance FromBSON Reference where
  fromBSON doc = do
    referenceType <- BSON.lookup "referenceType" doc
    case referenceType of
      "ResourcePageReference" -> ResourcePageReference' <$> (fromBSON doc :: Maybe ResourcePageReference)
      "URLReference" -> URLReference' <$> (fromBSON doc :: Maybe URLReference)
      "CrossReference" -> CrossReference' <$> (fromBSON doc :: Maybe CrossReference)

-- ------------------------------------------------
instance ToBSON ResourcePageReference where
  toBSON model =
    [ "referenceType" BSON.=: "ResourcePageReference"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "shortUuid" BSON.=: (model ^. shortUuid)
    ]

instance FromBSON ResourcePageReference where
  fromBSON doc = do
    refUuid <- deserializeMaybeUUID $ BSON.lookup "uuid" doc
    refShortUuid <- BSON.lookup "shortUuid" doc
    return ResourcePageReference {_resourcePageReferenceUuid = refUuid, _resourcePageReferenceShortUuid = refShortUuid}

-- ------------------------------------------------
instance ToBSON URLReference where
  toBSON model =
    [ "referenceType" BSON.=: "URLReference"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "url" BSON.=: (model ^. url)
    , "label" BSON.=: (model ^. label)
    ]

instance FromBSON URLReference where
  fromBSON doc = do
    refUuid <- deserializeMaybeUUID $ BSON.lookup "uuid" doc
    refUrl <- BSON.lookup "url" doc
    refLabel <- BSON.lookup "label" doc
    return URLReference {_uRLReferenceUuid = refUuid, _uRLReferenceUrl = refUrl, _uRLReferenceLabel = refLabel}

-- ------------------------------------------------
instance ToBSON CrossReference where
  toBSON model =
    [ "referenceType" BSON.=: "CrossReference"
    , "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "targetUuid" BSON.=: serializeUUID (model ^. targetUuid)
    , "description" BSON.=: (model ^. description)
    ]

instance FromBSON CrossReference where
  fromBSON doc = do
    refUuid <- deserializeMaybeUUID $ BSON.lookup "uuid" doc
    refTargetUuid <- deserializeMaybeUUID $ BSON.lookup "targetUuid" doc
    refDescription <- BSON.lookup "description" doc
    return
      CrossReference
      { _crossReferenceUuid = refUuid
      , _crossReferenceTargetUuid = refTargetUuid
      , _crossReferenceDescription = refDescription
      }

-- -------------------------
-- METRIC ------------------
-- -------------------------
instance ToBSON Metric where
  toBSON model =
    [ "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "title" BSON.=: (model ^. title)
    , "abbreviation" BSON.=: (model ^. abbreviation)
    , "description" BSON.=: (model ^. description)
    , "references" BSON.=: (model ^. references)
    , "createdAt" BSON.=: (model ^. createdAt)
    , "updatedAt" BSON.=: (model ^. updatedAt)
    ]

instance FromBSON Metric where
  fromBSON doc = do
    mUuid <- deserializeMaybeUUID $ BSON.lookup "uuid" doc
    mTitle <- BSON.lookup "title" doc
    mAbbreviation <- BSON.lookup "abbreviation" doc
    mDescription <- BSON.lookup "description" doc
    mReferences <- BSON.lookup "references" doc
    mCreatedAt <- BSON.lookup "createdAt" doc
    mUpdatedAt <- BSON.lookup "updatedAt" doc
    return
      Metric
      { _metricUuid = mUuid
      , _metricTitle = mTitle
      , _metricAbbreviation = mAbbreviation
      , _metricDescription = mDescription
      , _metricReferences = mReferences
      , _metricCreatedAt = mCreatedAt
      , _metricUpdatedAt = mUpdatedAt
      }

instance ToBSON MetricMeasure where
  toBSON model =
    [ "metricUuid" BSON.=: serializeUUID (model ^. metricUuid)
    , "measure" BSON.=: (model ^. measure)
    , "weight" BSON.=: (model ^. weight)
    ]

instance FromBSON MetricMeasure where
  fromBSON doc = do
    mmMetricUuid <- deserializeMaybeUUID $ BSON.lookup "metricUuid" doc
    mmMeasure <- BSON.lookup "measure" doc
    mmWeight <- BSON.lookup "weight" doc
    return
      MetricMeasure
      {_metricMeasureMetricUuid = mmMetricUuid, _metricMeasureMeasure = mmMeasure, _metricMeasureWeight = mmWeight}

-- -------------------------
-- TAG ---------------------
-- -------------------------
instance ToBSON Tag where
  toBSON model =
    [ "uuid" BSON.=: serializeUUID (model ^. uuid)
    , "name" BSON.=: (model ^. name)
    , "description" BSON.=: (model ^. description)
    , "color" BSON.=: (model ^. color)
    ]

instance FromBSON Tag where
  fromBSON doc = do
    tUuid <- deserializeMaybeUUID $ BSON.lookup "uuid" doc
    tName <- BSON.lookup "name" doc
    tDescription <- BSON.lookup "description" doc
    tColor <- BSON.lookup "color" doc
    return Tag {_tagUuid = tUuid, _tagName = tName, _tagDescription = tDescription, _tagColor = tColor}
