module Main where

import System.Directory (doesDirectoryExist, getDirectoryContents, createDirectoryIfMissing)
import System.FilePath ((</>), takeExtension, takeDirectory)
import Control.Monad (filterM, forM)
import Data.Text (replace, pack, unpack)
import System.Process (rawSystem)

inputPath = "home/script"
outputPath = "tmp/script"

isLua :: FilePath -> Bool
isLua file = takeExtension file == ".lua"

buildPath :: FilePath -> IO ()
buildPath dir = do
  files <- getDirectoryContents dir
  let allFiles = filter (`notElem` [".", "..", ".svn", ".git", "test", "tool", "shoot"]) files
  --let allFiles = filter (`notElem` [".", "..", ".svn", ".git", "tool", "shoot"]) files
  files <- filterM (fmap not . doesDirectoryExist) $ map (dir </>) allFiles
  dirs <- filterM doesDirectoryExist $ map (dir </>) allFiles
  forM (filter isLua files) buildFile
  forM dirs buildPath
  return ()

buildFile :: FilePath -> IO ()
buildFile luaFile = do
  let loFile = unpack . replace (pack inputPath) (pack outputPath) . pack $ luaFile
      scriptName = unpack . replace (pack (inputPath ++ "/")) (pack "") . pack $ luaFile
      command =  "bin/luajit_ios -bg -t raw " ++ luaFile ++ " " ++ loFile
  putStrLn command
  createDirectoryIfMissing True $ takeDirectory loFile
  rawSystem "bin/luajit_ios" ["-bg", "-t", "raw", luaFile, loFile]
  return ()

main = buildPath inputPath
