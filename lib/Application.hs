module Application
  ( runServer
  ) where

import Control.Lens ((^.))
import Control.Monad.Catch
import Control.Monad.Logger (runStdoutLoggingT)
import Control.Monad.Reader (liftIO, runReaderT)
import Control.Retry
import Data.Default (def)
import Network.Wai.Handler.Warp
       (Settings, defaultSettings, setPort)
import Web.Scotty.Trans (Options, scottyOptsT, settings, verbose)

import Api.Router
import Constant.Component
import Database.Connection
import qualified Database.Migration.Development.Migration as DM
import qualified Database.Migration.Production.Migration as PM
import Integration.Http.Common.HttpClientFactory
import LensesConfig
import Messaging.Connection
import Model.Config.Environment
import Model.Context.AppContextHelpers
import Model.Context.BaseContext
import Service.Config.ApplicationConfigService
import Service.Config.BuildInfoConfigService
import qualified Service.Migration.Metamodel.MigratorService as MM
import Util.Logger

import System.IO

applicationConfigFile = "config/application.yml"

buildInfoFile = "config/build-info.yml"

retryCount = 5

retryBaseWait = 2000000

retryBackoff = exponentialBackoff retryBaseWait <> limitRetries retryCount

runServer :: IO ()
runServer = do
  hSetBuffering stdout LineBuffering
  runStdoutLoggingT $ do
    liftIO $
      putStrLn
        "/--------------------------------------------------------------\\\n\
        \|   _____   _______          _______                           |\n\
        \|  |  __ \\ / ____\\ \\        / / ____|                          |\n\
        \|  | |  | | (___  \\ \\  /\\  / / (___   ___ _ ____   _____ _ __  |\n\
        \|  | |  | |\\___ \\  \\ \\/  \\/ / \\___ \\ / _ \\ '__\\ \\ / / _ \\ '__| |\n\
        \|  | |__| |____) |  \\  /\\  /  ____) |  __/ |   \\ V /  __/ |    |\n\
        \|  |_____/|_____/    \\/  \\/  |_____/ \\___|_|    \\_/ \\___|_|    |\n\
        \|                                                              |\n\
        \\\--------------------------------------------------------------/"
    logInfo $ msg _CMP_SERVER "started"
    hLoadConfig applicationConfigFile getApplicationConfig $ \appConfig ->
      hLoadConfig buildInfoFile getBuildInfoConfig $ \buildInfoConfig -> do
        logInfo $ "ENVIRONMENT: set to " ++ (show $ appConfig ^. general . environment)
        dbPool <- connectDB appConfig
        msgChannel <- connectMQ appConfig
        httpClientManager <- setupHttpClientManager appConfig
        let baseContext =
              BaseContext
              { _baseContextAppConfig = appConfig
              , _baseContextBuildInfoConfig = buildInfoConfig
              , _baseContextPool = dbPool
              , _baseContextMsgChannel = msgChannel
              , _baseContextHttpClientManager = httpClientManager
              }
        liftIO $ runDBMigrations baseContext
        liftIO $ runMetamodelMigrations baseContext
        liftIO $ runApplication baseContext

-- --------------------------------
-- PRIVATE
-- --------------------------------
hLoadConfig fileName loadFn callback = do
  eitherConfig <- liftIO (loadFn fileName)
  case eitherConfig of
    Right config -> do
      logInfo $ msg _CMP_CONFIG ("'" ++ fileName ++ "' loaded")
      callback config
    Left error -> do
      logError $ msg _CMP_CONFIG "load failed"
      logError $ msg _CMP_CONFIG ("can't load '" ++ fileName ++ "'. Maybe the file is missing or not well-formatted")
      logError $ msg _CMP_CONFIG (show error)

withRetry :: RetryPolicyM IO -> String -> String -> IO a -> IO a
withRetry backoff _CMP description action = recovering backoff handlers wrappedAction
  where
    wrappedAction _ = action
    handlers = skipAsyncExceptions ++ [handler]
    handler retryStatus = Handler $ \(_ :: SomeException) -> loggingHandler retryStatus
    loggingHandler retryStatus = do
      let nextWait =
            case rsPreviousDelay retryStatus of
              Just x -> 2 * (fromIntegral x) / 1000000
              Nothing -> fromIntegral retryBaseWait / 1000000
      if rsIterNumber retryStatus < retryCount
        then do
          let retryInfo = "retry #" ++ show (rsIterNumber retryStatus + 1) ++ " in " ++ show nextWait ++ " seconds"
          runStdoutLoggingT $ logWarn $ msg _CMP (description ++ " - " ++ retryInfo)
        else runStdoutLoggingT $ logError $ msg _CMP description
      return True

connectDB appConfig = do
  logInfo $ msg _CMP_DATABASE "connecting to the database"
  dbPool <-
    liftIO $
    withRetry retryBackoff _CMP_DATABASE "failed to connect to the database" (createDatabaseConnectionPool appConfig)
  logInfo $ msg _CMP_DATABASE "connected"
  return dbPool

connectMQ appConfig =
  if (appConfig ^. messaging ^. enabled)
    then do
      logInfo $ msg _CMP_MESSAGING "connecting to the message broker"
      msgChannel <-
        liftIO $
        withRetry
          retryBackoff
          _CMP_MESSAGING
          "failed to connect to the message broker"
          (createMessagingChannel appConfig)
      logInfo $ msg _CMP_MESSAGING "connected"
      return msgChannel
    else do
      logInfo $ msg _CMP_MESSAGING "not enabled - skipping"
      return Nothing

setupHttpClientManager appConfig = do
  logInfo $ msg _CMP_INTEGRATION "creating http client manager"
  httpClientManager <- liftIO $ createHttpClientManager appConfig
  logInfo $ msg _CMP_INTEGRATION "http client manager successfully created"
  return httpClientManager

runDBMigrations context =
  case context ^. appConfig . general . environment of
    Development -> runStdoutLoggingT $ runAppContextWithBaseContext DM.runMigration context
    Staging -> runStdoutLoggingT $ PM.runMigration context
    Production -> runStdoutLoggingT $ PM.runMigration context
    _ -> return ()

runMetamodelMigrations context = runStdoutLoggingT $ runAppContextWithBaseContext MM.migrateCompleteDatabase context

runApplication :: BaseContext -> IO ()
runApplication context = do
  let o = getOptions context
  let r m = runStdoutLoggingT $ runReaderT (runBaseContextM m) context
  scottyOptsT o r (createEndpoints context)

getOptions :: BaseContext -> Options
getOptions context =
  def
  { settings = getSettings context
  , verbose =
      case context ^. appConfig . general . environment of
        Production -> 0
        Staging -> 1
        Development -> 1
        Test -> 0
  }

getSettings :: BaseContext -> Settings
getSettings context =
  let webPort = context ^. appConfig . general . serverPort
  in setPort webPort defaultSettings
