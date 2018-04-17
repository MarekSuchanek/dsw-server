module Specs.API.Common where

import Control.Lens ((^.))
import Control.Monad.Logger (runStdoutLoggingT)
import Control.Monad.Reader (runReaderT)
import Data.Aeson (Value(..), (.=), encode, object)
import Data.ByteString.Char8 as BS
import Data.Foldable
import qualified Data.List as L
import Data.Maybe
import qualified Data.UUID as U
import Network.HTTP.Types.Header
import Network.Wai (Application)
import Test.Hspec
import qualified Test.Hspec.Expectations.Pretty as TP
import Test.Hspec.Wai hiding (shouldRespondWith)
import qualified Test.Hspec.Wai.JSON as HJ
import Test.Hspec.Wai.Matcher
import Web.Scotty.Trans (scottyAppT)

import Api.Resource.Error.ErrorDTO
import Api.Router
import Common.Context
import Common.Error
import Common.Types
import Database.Connection
import LensesConfig
import Model.Config.DSWConfig
import Model.Context.AppContext
import Model.User.User
import Service.Token.TokenService
import Service.User.UserService

startWebApp :: Context -> DSWConfig -> IO Application
startWebApp context dswConfig = do
  let appContext =
        AppContext
        { _appContextEnvironment = Test
        , _appContextConfig = dswConfig
        , _appContextPool = context ^. ctxDbPool
        , _appContextOldContext = context
        }
      t m = runStdoutLoggingT $ runReaderT (runAppContextM m) appContext
  scottyAppT t (createEndpoints appContext)

reqAuthHeader :: Header
reqAuthHeader =
  ( "Authorization"
  , "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyVXVpZCI6ImVjNmY4ZTkwLTJhOTEtNDllYy1hYTNmLTllYWIyMjY3ZmM2NiIsInBlcm1pc3Npb25zIjpbIlVNX1BFUk0iLCJPUkdfUEVSTSIsIktNX1BFUk0iLCJLTV9VUEdSQURFX1BFUk0iLCJLTV9QVUJMSVNIX1BFUk0iLCJQTV9QRVJNIiwiV0laX1BFUk0iLCJETVBfUEVSTSJdfQ.BFBXG8gjJeqt3i-hKzsp10_ePM5st34vuJqiYeNwyu4")

reqAuthHeaderWithoutPerms :: DSWConfig -> Permission -> Header
reqAuthHeaderWithoutPerms dswConfig perm =
  let allPerms = getPermissionForRole dswConfig "ADMIN"
      user =
        User
        { _uUuid = fromJust . U.fromString $ "76a60891-f00e-456f-88c5-ee9c705fee6d"
        , _uName = "John"
        , _uSurname = "Doe"
        , _uEmail = "john.doe@example.com"
        , _uPasswordHash = "sha256|17|DQE8FVBnLhQOFBoamcfO4Q==|vxeEl9qYMTDuKkymrH3eIIYVpQMAKnyY9324kp++QKo="
        , _uRole = "ADMIN"
        , _uPermissions = L.delete perm allPerms
        , _uIsActive = True
        }
      token = createToken user (dswConfig ^. jwtConfig ^. secret)
  in ("Authorization", BS.concat ["Bearer ", BS.pack token])

reqCtHeader :: Header
reqCtHeader = ("Content-Type", "application/json")

resCtHeader = "Content-Type" <:> "application/json"

resCorsHeaders =
  [ "Access-Control-Allow-Credential" <:> "true"
  , "Access-Control-Allow-Headers" <:> "Origin, X-Requested-With, Content-Type, Accept, Authorization"
  , "Access-Control-Allow-Methods" <:> "OPTIONS, HEAD, GET, POST, PUT, DELETE"
  , "Access-Control-Allow-Origin" <:> "*"
  ]

shouldRespondWith r matcher = do
  forM_ (match r matcher) (liftIO . expectationFailure)

createInvalidJsonTest reqMethod reqUrl reqBody missingField =
  it "HTTP 400 BAD REQUEST when json is not valid" $ do
    let reqHeaders = [reqAuthHeader, reqCtHeader]
      -- GIVEN: Prepare expectation
    let expStatus = 400
    let expHeaders = [resCtHeader] ++ resCorsHeaders
    let expDto = createErrorWithErrorMessage $ "Error in $: key \"" ++ missingField ++ "\" not present"
    let expBody = encode expDto
      -- WHEN: Call APIA
    response <- request reqMethod reqUrl reqHeaders reqBody
      -- AND: Compare response with expetation
    let responseMatcher =
          ResponseMatcher {matchHeaders = expHeaders, matchStatus = expStatus, matchBody = bodyEquals expBody}
    response `shouldRespondWith` responseMatcher

createInvalidJsonArrayTest reqMethod reqUrl reqBody missingField =
  it "HTTP 400 BAD REQUEST when json is not valid" $ do
    let reqHeaders = [reqAuthHeader, reqCtHeader]
      -- GIVEN: Prepare expectation
    let expStatus = 400
    let expHeaders = [resCtHeader] ++ resCorsHeaders
    let expDto = createErrorWithErrorMessage $ "Error in $[0]: key \"" ++ missingField ++ "\" not present"
    let expBody = encode expDto
      -- WHEN: Call APIA
    response <- request reqMethod reqUrl reqHeaders reqBody
      -- AND: Compare response with expetation
    let responseMatcher =
          ResponseMatcher {matchHeaders = expHeaders, matchStatus = expStatus, matchBody = bodyEquals expBody}
    response `shouldRespondWith` responseMatcher

createAuthTest reqMethod reqUrl reqHeaders reqBody =
  it "HTTP 401 UNAUTHORIZED" $
    -- GIVEN: Prepare expectation
   do
    let expBody =
          [HJ.json|
    {
      status: 401,
      error: "Unauthorized"
    }
    |]
    let expHeaders = [resCtHeader] ++ resCorsHeaders
    let expStatus = 401
    -- WHEN: Call API
    response <- request reqMethod reqUrl reqHeaders reqBody
    -- AND: Compare response with expetation
    let responseMatcher =
          ResponseMatcher {matchHeaders = expHeaders, matchStatus = expStatus, matchBody = bodyEquals expBody}
    response `shouldRespondWith` responseMatcher

createNoPermissionTest dswConfig reqMethod reqUrl otherHeaders reqBody missingPerm =
  it "HTTP 403 FORBIDDEN - no required permission" $
    -- GIVEN: Prepare request
   do
    let authHeader = reqAuthHeaderWithoutPerms dswConfig missingPerm
    let reqHeaders = [authHeader] ++ otherHeaders
    -- GIVEN: Prepare expectation
    let expBody =
          [HJ.json|
    {
      status: 403,
      error: "Forbidden"
    }
    |]
    let expHeaders = [resCtHeader] ++ resCorsHeaders
    let expStatus = 403
    -- WHEN: Call API
    response <- request reqMethod reqUrl reqHeaders reqBody
    -- AND: Compare response with expetation
    let responseMatcher =
          ResponseMatcher {matchHeaders = expHeaders, matchStatus = expStatus, matchBody = bodyEquals expBody}
    response `shouldRespondWith` responseMatcher

createNotFoundTest reqMethod reqUrl reqHeaders reqBody =
  it "HTTP 404 NOT FOUND - entity doesn't exist" $
      -- GIVEN: Prepare expectation
   do
    let expStatus = 404
    let expHeaders = [resCtHeader] ++ resCorsHeaders
    let expDto = NotExistsError "Entity does not exist"
    let expBody = encode expDto
      -- WHEN: Call APIA
    response <- request reqMethod reqUrl reqHeaders reqBody
      -- AND: Compare response with expetation
    let responseMatcher =
          ResponseMatcher {matchHeaders = expHeaders, matchStatus = expStatus, matchBody = bodyEquals expBody}
    response `shouldRespondWith` responseMatcher
