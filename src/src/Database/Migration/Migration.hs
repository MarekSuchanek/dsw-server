module Database.Migration.Migration where

import Context
import Database.Migration.Organization.OrganizationMigration as ORG
import Database.Migration.Package.PackageMigration as PKG
import Database.Migration.User.UserMigration as UM

runMigration context dspConfig = do
  putStrLn "MIGRATION: started"
  ORG.runMigration context dspConfig
  UM.runMigration context dspConfig
  PKG.runMigration context dspConfig
  putStrLn "MIGRATION: ended"
