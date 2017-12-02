module Service.Package.PackageService where

import Control.Lens ((^.))
import Control.Monad.Reader
import Crypto.PasswordStore
import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BS
import Data.List
import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as T
import Data.UUID as U
import Text.Regex

import Api.Resources.Branch.BranchDTO
import Api.Resources.Organization.OrganizationDTO
import Api.Resources.Package.PackageDTO
import Api.Resources.Package.PackageSimpleDTO
import Api.Resources.Package.PackageWithEventsDTO
import Common.Context
import Common.Error
import Common.Types
import Common.Uuid
import Database.DAO.Branch.BranchDAO
import Database.DAO.Event.EventDAO
import Database.DAO.Package.PackageDAO
import Model.Branch.Branch
import Model.Event.Event
import Model.Package.Package
import Service.Event.EventMapper
import Service.Organization.OrganizationService
import Service.Package.PackageMapper

getPackagesFiltered :: Context -> [(Text, Text)] -> IO (Either AppError [PackageDTO])
getPackagesFiltered context queryParams = do
  eitherPackages <- findPackagesFiltered context queryParams
  case eitherPackages of
    Right packages -> return . Right . fmap packageToDTO $ packages
    Left error -> return . Left $ error

getSimplePackagesFiltered :: Context -> [(Text, Text)] -> IO (Either AppError [PackageSimpleDTO])
getSimplePackagesFiltered context queryParams = do
  eitherPackages <- findPackagesFiltered context queryParams
  case eitherPackages of
    Right packages -> do
      let uniquePackages = makePackagesUnique packages
      return . Right . fmap packageToSimpleDTO $ uniquePackages
      where makePackagesUnique :: [Package] -> [Package]
            makePackagesUnique = foldl addIfUnique []
            addIfUnique :: [Package] -> Package -> [Package]
            addIfUnique packages newPackage =
              case isAlreadyInArray packages newPackage of
                (Just _) -> packages
                Nothing -> packages ++ [newPackage]
            isAlreadyInArray :: [Package] -> Package -> Maybe Package
            isAlreadyInArray packages newPackage = find (equalSameArtifactId (newPackage ^. pkgArtifactId)) packages
            hasSameArtifactId :: Package -> Package -> Bool
            hasSameArtifactId pkg1 pkg2 = pkg1 ^. pkgArtifactId == pkg2 ^. pkgArtifactId
            equalSameArtifactId :: String -> Package -> Bool
            equalSameArtifactId artifactId pkg = artifactId == pkg ^. pkgArtifactId
    Left error -> return . Left $ error

getPackageById :: Context -> String -> IO (Either AppError PackageDTO)
getPackageById context pkgId = do
  eitherPackage <- findPackageById context pkgId
  case eitherPackage of
    Right package -> return . Right . packageToDTO $ package
    Left error -> return . Left $ error

getPackageWithEventsById :: Context -> String -> IO (Either AppError PackageWithEventsDTO)
getPackageWithEventsById context pkgId = do
  eitherPackage <- findPackageWithEventsById context pkgId
  case eitherPackage of
    Right package -> return . Right . packageWithEventsToDTOWithEvents $ package
    Left error -> return . Left $ error

createPackage :: Context -> String -> String -> String -> String -> String -> Maybe String -> [Event] -> IO PackageDTO
createPackage context name groupId artifactId version description maybeParentPackageId events = do
  let package = buildPackage name groupId artifactId version description maybeParentPackageId events
  insertPackage context package
  return $ packageWithEventsToDTO package

createPackageFromKMC :: Context -> String -> String -> String -> IO (Either AppError PackageDTO)
createPackageFromKMC context branchUuid version description =
  validateVersionFormat version $
  getBranch branchUuid $ \branch ->
    getCurrentOrganization $ \organization ->
      validateVersion version branch organization $ do
        let name = branch ^. bweName
        let groupId = organization ^. orgdtoGroupId
        let artifactId = branch ^. bweArtifactId
        let events = branch ^. bweEvents
        let mPpId = branch ^. bweParentPackageId
        createdPackage <- createPackage context name groupId artifactId version description mPpId events
        return . Right $ createdPackage
  where
    validateVersionFormat version callback =
      case isVersionInValidFormat version of
        Nothing -> callback
        Just error -> return . Left $ error
    getBranch branchUuid callback = do
      eitherBranch <- findBranchWithEventsById context branchUuid
      case eitherBranch of
        Right branch -> callback branch
        Left error -> return . Left $ error
    getCurrentOrganization callback = do
      eitherOrganization <- getOrganization context
      case eitherOrganization of
        Right organization -> callback organization
        Left error -> return . Left $ error
    validateVersion version branch organization callback = do
      let groupId = organization ^. orgdtoGroupId
      let artifactId = branch ^. bweArtifactId
      eitherMaybePackage <- getTheNewestPackageByGroupIdAndArtifactId context groupId artifactId
      case eitherMaybePackage of
        Right (Just package) ->
          case isVersionHigher version (package ^. pkgVersion) of
            Nothing -> callback
            Just error -> return . Left $ error
        Right Nothing -> callback
        Left error -> return . Left $ error

importPackage :: Context -> BS.ByteString -> IO (Either AppError PackageDTO)
importPackage context fileContent = do
  let eitherDeserializedFile = eitherDecode fileContent
  case eitherDeserializedFile of
    Right deserializedFile -> do
      let packageWithEvents = fromDTOWithEvents deserializedFile
      let pName = packageWithEvents ^. pkgweName
      let pGroupId = packageWithEvents ^. pkgweGroupId
      let pArtifactId = packageWithEvents ^. pkgweArtifactId
      let pVersion = packageWithEvents ^. pkgweVersion
      let pDescription = packageWithEvents ^. pkgweDescription
      let pParentPackageId = packageWithEvents ^. pkgweParentPackageId
      let pEvents = packageWithEvents ^. pkgweEvents
      createdPkg <- createPackage context pName pGroupId pArtifactId pVersion pDescription pParentPackageId pEvents
      return . Right $ createdPkg
    Left error -> return . Left . createErrorWithErrorMessage $ error

deletePackagesByQueryParams :: Context -> [(Text, Text)] -> IO ()
deletePackagesByQueryParams = deletePackagesFiltered

deletePackage :: Context -> String -> IO (Maybe AppError)
deletePackage context pkgId = do
  eitherPackage <- findPackageById context pkgId
  case eitherPackage of
    Right package -> do
      deletePackageById context pkgId
      return Nothing
    Left error -> return . Just $ error

getTheNewestPackageByGroupIdAndArtifactId :: Context -> String -> String -> IO (Either AppError (Maybe Package))
getTheNewestPackageByGroupIdAndArtifactId context groupId artifactId = do
  eitherPackages <- findPackageByGroupIdAndArtifactId context groupId artifactId
  case eitherPackages of
    Right packages ->
      if length packages == 0
        then return . Right $ Nothing
        else do
          let sorted = sortPackagesByVersion packages
          return . Right . Just . head $ sorted
    Left error -> return . Left $ error

getAllPreviousEventsSincePackageId :: Context -> String -> IO (Either AppError [Event])
getAllPreviousEventsSincePackageId context pkgId = do
  eitherPackage <- findPackageWithEventsById context pkgId
  case eitherPackage of
    Right package ->
      case package ^. pkgweParentPackageId of
        Just parentPackageId -> do
          eitherEvents <- getAllPreviousEventsSincePackageId context parentPackageId
          case eitherEvents of
            Right events -> return . Right $ events ++ (package ^. pkgweEvents)
            Left error -> return . Left $ error
        Nothing -> return . Right $ package ^. pkgweEvents
    Left error -> return . Left $ error

getAllPreviousEventsSincePackageIdAndUntilPackageId :: Context -> String -> String -> IO (Either AppError [Event])
getAllPreviousEventsSincePackageIdAndUntilPackageId context sincePkgId untilPkgId = go sincePkgId
  where
    go pkgId =
      if pkgId == untilPkgId
        then return . Right $ []
        else do
          eitherPackage <- findPackageWithEventsById context pkgId
          case eitherPackage of
            Right package ->
              case package ^. pkgweParentPackageId of
                Just parentPackageId -> do
                  eitherEvents <- go parentPackageId
                  case eitherEvents of
                    Right events -> return . Right $ events ++ (package ^. pkgweEvents)
                    Left error -> return . Left $ error
                Nothing -> return . Right $ package ^. pkgweEvents
            Left error -> return . Left $ error

getNewerPackages :: Context -> String -> IO (Either AppError [Package])
getNewerPackages context currentPkgId =
  getPackages $ \packages -> do
    let packagesWithHigherVersion = filter (\pkg -> isNothing $ isVersionHigher (pkg ^. pkgVersion) version) packages
    return . Right . sortPackagesByVersion $ packagesWithHigherVersion
  where
    getPackages callback = do
      eitherPackages <- findPackageByGroupIdAndArtifactId context groupId artifactId
      case eitherPackages of
        Right packages -> callback packages
        Left error -> return . Left $ error
    groupId = T.unpack $ splitPackageId currentPkgId !! 0
    artifactId = T.unpack $ splitPackageId currentPkgId !! 1
    version = T.unpack $ splitPackageId currentPkgId !! 2

isVersionInValidFormat :: String -> Maybe AppError
isVersionInValidFormat version =
  if isJust $ matchRegex validationRegex version
    then Nothing
    else Just . createErrorWithErrorMessage $ "Version is not in valid format"
  where
    validationRegex = mkRegex "^[0-9].[0-9].[0-9]$"

isVersionHigher :: String -> String -> Maybe AppError
isVersionHigher newVersion oldVersion =
  if compareVersion newVersion oldVersion == GT
    then Nothing
    else Just . createErrorWithErrorMessage $ "New version has to be higher than the previous one"

compareVersionNeg :: String -> String -> Ordering
compareVersionNeg verA verB = compareVersion verB verA

compareVersion :: String -> String -> Ordering
compareVersion versionA versionB =
  case compare versionAMajor versionBMajor of
    LT -> LT
    GT -> GT
    EQ ->
      case compare versionAMinor versionBMinor of
        LT -> LT
        GT -> GT
        EQ ->
          case compare versionAPatch versionBPatch of
            LT -> LT
            GT -> GT
            EQ -> EQ
  where
    versionASplitted = splitVersion versionA
    versionBSplitted = splitVersion versionB
    versionAMajor = read . T.unpack $ (versionASplitted !! 0) :: Int
    versionAMinor = read . T.unpack $ (versionASplitted !! 1) :: Int
    versionAPatch = read . T.unpack $ (versionASplitted !! 2) :: Int
    versionBMajor = read . T.unpack $ (versionBSplitted !! 0) :: Int
    versionBMinor = read . T.unpack $ (versionBSplitted !! 1) :: Int
    versionBPatch = read . T.unpack $ (versionBSplitted !! 2) :: Int

sortPackagesByVersion :: [Package] -> [Package]
sortPackagesByVersion = sortBy (\p1 p2 -> compareVersionNeg (p1 ^. pkgVersion) (p2 ^. pkgVersion))

splitPackageId :: String -> [Text]
splitPackageId packageId = T.splitOn ":" (T.pack packageId)

splitVersion :: String -> [Text]
splitVersion version = T.splitOn "." (T.pack version)