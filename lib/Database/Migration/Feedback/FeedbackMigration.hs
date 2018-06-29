module Database.Migration.Feedback.FeedbackMigration where

import Control.Monad.Logger (logInfo)

import Database.DAO.Feedback.FeedbackDAO
import Database.Migration.Feedback.Data.Feedbacks

runMigration = do
  $(logInfo) "MIGRATION (Feedback/Feedback): started"
  deleteFeedbacks
  insertFeedback feedback1
  $(logInfo) "MIGRATION (Feedback/Feedback): ended"