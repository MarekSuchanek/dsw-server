module Api.Resource.Branch.BranchCreateDTO where

import GHC.Generics

data BranchCreateDTO = BranchCreateDTO
  { _branchCreateDTOName :: String
  , _branchCreateDTOKmId :: String
  , _branchCreateDTOParentPackageId :: Maybe String
  } deriving (Generic)
