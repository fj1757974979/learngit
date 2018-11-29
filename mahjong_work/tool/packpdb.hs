{-# LANGUAGE OverloadedStrings #-}

module Main where

import Database.SQLite
  (openConnection,
   closeConnection,
   execStatement_,
   SQLiteHandle,
   insertRow,
   execParamStatement_,
   Value(..))
import System.Directory (doesDirectoryExist, getDirectoryContents, createDirectoryIfMissing)
import System.FilePath ((</>), takeExtension, takeDirectory)
import Control.Monad (filterM, forM, liftM)
import Data.Text (replace, pack, unpack)
import System.Process (rawSystem)
import Crypto.Hash.MD5 (hash)
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as B (c2w, w2c)
import qualified Data.ByteString.Base16 as Base16
import System.Environment (getArgs)

-- inputDir = "tmp/script"
-- outputPDB = "tmp/script.pdb"

packDirectory :: SQLiteHandle -> FilePath -> FilePath -> IO ()
packDirectory h root dir = do
  files <- getDirectoryContents dir
  let allFiles = filter (`notElem` [".", "..", ".svn", ".git", "tool", "shoot"]) files
  files <- filterM (fmap not . doesDirectoryExist) $ map (dir </>) allFiles
  dirs <- filterM doesDirectoryExist $ map (dir </>) allFiles
  forM files (packFile h root)
  forM dirs (packDirectory h root)
  return ()

packFile :: SQLiteHandle -> FilePath -> FilePath -> IO ()
packFile h root file = do
  putStrLn (root ++ "," ++ file)
  content <- B.readFile file
  let fileName = unpack . replace (pack (root ++ "/")) (pack "") . pack $ file
      md5 = map B.w2c $ B.unpack $ Base16.encode $ hash content
  execParamStatement_ h "INSERT INTO resource VALUES (:file_name, :md5, :file_data)" 
    [(":file_name", Text fileName),
     (":md5", Text md5),
     (":file_data", Blob content)]
  return ()
-- inputDir = "tmp/script"
-- outputPDB = "tmp/script.pdb"

main = do
  args <- getArgs
  
  let inputDir = head args
      outputPDB = head $ tail args

  rawSystem "rm" ["-f",outputPDB]
  createDirectoryIfMissing True $ takeDirectory outputPDB
  h <- openConnection outputPDB
  execStatement_ h "CREATE TABLE IF NOT EXISTS resource (file_name varchar(260) PRIMARY KEY, md5 var_char(32), file_data BLOB)"
  packDirectory h inputDir inputDir
  closeConnection h
