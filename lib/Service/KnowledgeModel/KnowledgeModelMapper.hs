module Service.KnowledgeModel.KnowledgeModelMapper where

import Control.Lens ((^.))

import Api.Resource.KnowledgeModel.KnowledgeModelDTO
import LensesConfig
import Model.KnowledgeModel.KnowledgeModel

toKnowledgeModelDTO :: KnowledgeModel -> KnowledgeModelDTO
toKnowledgeModelDTO km =
  KnowledgeModelDTO
  { _knowledgeModelDTOUuid = km ^. uuid
  , _knowledgeModelDTOName = km ^. name
  , _knowledgeModelDTOTags = toTagDTO <$> (km ^. tags)
  , _knowledgeModelDTOChapters = toChapterDTO <$> (km ^. chapters)
  }

toChapterDTO :: Chapter -> ChapterDTO
toChapterDTO chapter =
  ChapterDTO
  { _chapterDTOUuid = chapter ^. uuid
  , _chapterDTOTitle = chapter ^. title
  , _chapterDTOText = chapter ^. text
  , _chapterDTOQuestions = toQuestionDTO <$> (chapter ^. questions)
  }

toQuestionDTO :: Question -> QuestionDTO
toQuestionDTO (OptionsQuestion' question) =
  OptionsQuestionDTO'
    OptionsQuestionDTO
    { _optionsQuestionDTOUuid = question ^. uuid
    , _optionsQuestionDTOTitle = question ^. title
    , _optionsQuestionDTOText = question ^. text
    , _optionsQuestionDTORequiredLevel = question ^. requiredLevel
    , _optionsQuestionDTOTagUuids = question ^. tagUuids
    , _optionsQuestionDTONote = question ^. note
    , _optionsQuestionDTOExperts = toExpertDTO <$> (question ^. experts)
    , _optionsQuestionDTOReferences = toReferenceDTO <$> (question ^. references)
    , _optionsQuestionDTOAnswers = toAnswerDTO <$> (question ^. answers)
    }
toQuestionDTO (ListQuestion' question) =
  ListQuestionDTO'
    ListQuestionDTO
    { _listQuestionDTOUuid = question ^. uuid
    , _listQuestionDTOTitle = question ^. title
    , _listQuestionDTOText = question ^. text
    , _listQuestionDTORequiredLevel = question ^. requiredLevel
    , _listQuestionDTOTagUuids = question ^. tagUuids
    , _listQuestionDTONote = question ^. note
    , _listQuestionDTOExperts = toExpertDTO <$> (question ^. experts)
    , _listQuestionDTOReferences = toReferenceDTO <$> (question ^. references)
    , _listQuestionDTOItemTemplateTitle = question ^. itemTemplateTitle
    , _listQuestionDTOItemTemplateQuestions = toQuestionDTO <$> (question ^. itemTemplateQuestions)
    }
toQuestionDTO (ValueQuestion' question) =
  ValueQuestionDTO'
    ValueQuestionDTO
    { _valueQuestionDTOUuid = question ^. uuid
    , _valueQuestionDTOTitle = question ^. title
    , _valueQuestionDTOText = question ^. text
    , _valueQuestionDTORequiredLevel = question ^. requiredLevel
    , _valueQuestionDTOTagUuids = question ^. tagUuids
    , _valueQuestionDTONote = question ^. note
    , _valueQuestionDTOExperts = toExpertDTO <$> (question ^. experts)
    , _valueQuestionDTOReferences = toReferenceDTO <$> (question ^. references)
    , _valueQuestionDTOValueType = question ^. valueType
    }

toAnswerDTO :: Answer -> AnswerDTO
toAnswerDTO answer =
  AnswerDTO
  { _answerDTOUuid = answer ^. uuid
  , _answerDTOLabel = answer ^. label
  , _answerDTOAdvice = answer ^. advice
  , _answerDTOFollowUps = toQuestionDTO <$> (answer ^. followUps)
  , _answerDTOMetricMeasures = toMetricMeasureDTO <$> (answer ^. metricMeasures)
  }

toExpertDTO :: Expert -> ExpertDTO
toExpertDTO expert =
  ExpertDTO {_expertDTOUuid = expert ^. uuid, _expertDTOName = expert ^. name, _expertDTOEmail = expert ^. email}

toReferenceDTO :: Reference -> ReferenceDTO
toReferenceDTO (ResourcePageReference' reference) =
  ResourcePageReferenceDTO'
    ResourcePageReferenceDTO
    {_resourcePageReferenceDTOUuid = reference ^. uuid, _resourcePageReferenceDTOShortUuid = reference ^. shortUuid}
toReferenceDTO (URLReference' reference) =
  URLReferenceDTO'
    URLReferenceDTO
    { _uRLReferenceDTOUuid = reference ^. uuid
    , _uRLReferenceDTOUrl = reference ^. url
    , _uRLReferenceDTOLabel = reference ^. label
    }
toReferenceDTO (CrossReference' reference) =
  CrossReferenceDTO'
    CrossReferenceDTO
    { _crossReferenceDTOUuid = reference ^. uuid
    , _crossReferenceDTOTargetUuid = reference ^. targetUuid
    , _crossReferenceDTODescription = reference ^. description
    }

toMetricMeasureDTO :: MetricMeasure -> MetricMeasureDTO
toMetricMeasureDTO m =
  MetricMeasureDTO
  { _metricMeasureDTOMetricUuid = m ^. metricUuid
  , _metricMeasureDTOMeasure = m ^. measure
  , _metricMeasureDTOWeight = m ^. weight
  }

toTagDTO :: Tag -> TagDTO
toTagDTO tag =
  TagDTO
  { _tagDTOUuid = tag ^. uuid
  , _tagDTOName = tag ^. name
  , _tagDTODescription = tag ^. description
  , _tagDTOColor = tag ^. color
  }

-- ----------------------------------------
-- ----------------------------------------
fromKnowledgeModelDTO :: KnowledgeModelDTO -> KnowledgeModel
fromKnowledgeModelDTO km =
  KnowledgeModel
  { _knowledgeModelUuid = km ^. uuid
  , _knowledgeModelName = km ^. name
  , _knowledgeModelTags = fromTagDTO <$> (km ^. tags)
  , _knowledgeModelChapters = fromChapterDTO <$> (km ^. chapters)
  }

fromChapterDTO :: ChapterDTO -> Chapter
fromChapterDTO chapter =
  Chapter
  { _chapterUuid = chapter ^. uuid
  , _chapterTitle = chapter ^. title
  , _chapterText = chapter ^. text
  , _chapterQuestions = fromQuestionDTO <$> (chapter ^. questions)
  }

fromQuestionDTO :: QuestionDTO -> Question
fromQuestionDTO (OptionsQuestionDTO' question) =
  OptionsQuestion'
    OptionsQuestion
    { _optionsQuestionUuid = question ^. uuid
    , _optionsQuestionTitle = question ^. title
    , _optionsQuestionText = question ^. text
    , _optionsQuestionRequiredLevel = question ^. requiredLevel
    , _optionsQuestionTagUuids = question ^. tagUuids
    , _optionsQuestionNote = question ^. note
    , _optionsQuestionExperts = fromExpertDTO <$> (question ^. experts)
    , _optionsQuestionReferences = fromReferenceDTO <$> (question ^. references)
    , _optionsQuestionAnswers = fromAnswerDTO <$> (question ^. answers)
    }
fromQuestionDTO (ListQuestionDTO' question) =
  ListQuestion'
    ListQuestion
    { _listQuestionUuid = question ^. uuid
    , _listQuestionTitle = question ^. title
    , _listQuestionText = question ^. text
    , _listQuestionRequiredLevel = question ^. requiredLevel
    , _listQuestionTagUuids = question ^. tagUuids
    , _listQuestionNote = question ^. note
    , _listQuestionExperts = fromExpertDTO <$> (question ^. experts)
    , _listQuestionReferences = fromReferenceDTO <$> (question ^. references)
    , _listQuestionItemTemplateTitle = question ^. itemTemplateTitle
    , _listQuestionItemTemplateQuestions = fromQuestionDTO <$> (question ^. itemTemplateQuestions)
    }
fromQuestionDTO (ValueQuestionDTO' question) =
  ValueQuestion'
    ValueQuestion
    { _valueQuestionUuid = question ^. uuid
    , _valueQuestionTitle = question ^. title
    , _valueQuestionText = question ^. text
    , _valueQuestionRequiredLevel = question ^. requiredLevel
    , _valueQuestionTagUuids = question ^. tagUuids
    , _valueQuestionNote = question ^. note
    , _valueQuestionExperts = fromExpertDTO <$> (question ^. experts)
    , _valueQuestionReferences = fromReferenceDTO <$> (question ^. references)
    , _valueQuestionValueType = question ^. valueType
    }

fromAnswerDTO :: AnswerDTO -> Answer
fromAnswerDTO answer =
  Answer
  { _answerUuid = answer ^. uuid
  , _answerLabel = answer ^. label
  , _answerAdvice = answer ^. advice
  , _answerFollowUps = fromQuestionDTO <$> (answer ^. followUps)
  , _answerMetricMeasures = fromMetricMeasureDTO <$> (answer ^. metricMeasures)
  }

fromExpertDTO :: ExpertDTO -> Expert
fromExpertDTO expert =
  Expert {_expertUuid = expert ^. uuid, _expertName = expert ^. name, _expertEmail = expert ^. email}

fromReferenceDTO :: ReferenceDTO -> Reference
fromReferenceDTO (ResourcePageReferenceDTO' reference) =
  ResourcePageReference'
    ResourcePageReference
    {_resourcePageReferenceUuid = reference ^. uuid, _resourcePageReferenceShortUuid = reference ^. shortUuid}
fromReferenceDTO (URLReferenceDTO' reference) =
  URLReference'
    URLReference
    { _uRLReferenceUuid = reference ^. uuid
    , _uRLReferenceUrl = reference ^. url
    , _uRLReferenceLabel = reference ^. label
    }
fromReferenceDTO (CrossReferenceDTO' reference) =
  CrossReference'
    CrossReference
    { _crossReferenceUuid = reference ^. uuid
    , _crossReferenceTargetUuid = reference ^. targetUuid
    , _crossReferenceDescription = reference ^. description
    }

fromMetricMeasureDTO :: MetricMeasureDTO -> MetricMeasure
fromMetricMeasureDTO m =
  MetricMeasure
  {_metricMeasureMetricUuid = m ^. metricUuid, _metricMeasureMeasure = m ^. measure, _metricMeasureWeight = m ^. weight}

fromTagDTO :: TagDTO -> Tag
fromTagDTO tag =
  Tag {_tagUuid = tag ^. uuid, _tagName = tag ^. name, _tagDescription = tag ^. description, _tagColor = tag ^. color}
