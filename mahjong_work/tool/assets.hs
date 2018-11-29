module Main where

import Data.List
import Data.List.Utils (replace)
import qualified Data.Text as T 
import Data.Ord (comparing)
import Control.Monad (forM, mapM, liftM)
import System.Directory (doesDirectoryExist, getDirectoryContents, getModificationTime)
import System.FilePath ((</>), takeDirectory)
import System.Time
import Text.Regex.Posix ((=~))
import System.IO (openFile, hClose, hFileSize, IOMode(..), withFile)
import Control.Exception (handle, bracket)
import qualified Text.JSON as JSON
import Text.JSON.Pretty (pp_value, render)
import Data.Tuple.Select -- tuple
import Crypto.Hash.MD5 (hash)
import qualified Data.ByteString as B
import qualified Data.ByteString.Internal as B (c2w, w2c)
import qualified Data.ByteString.Base16 as Base16
-- import Data.String.Utils -- MissingH

type FileSize = Integer
getRecursiveContents :: FilePath -> IO [(FilePath, FileSize, String)]

getRecursiveContents topdir = do
  names <- getDirectoryContents topdir
  let properNames = filter (`notElem` [".", "..", ".svn", ".git", "Makefile", ".DS_Store", ".gitmodules", "tool", "Thumbs.db", "sound", "music", "onlyu"]) names
  paths <- forM properNames $ \name -> do
    let path = topdir </> name
    isDirectory <- doesDirectoryExist path
    if isDirectory
       then getRecursiveContents path
       else
      do
        putStrLn path
        length <- withFile path ReadMode hFileSize
        -- (UTCTime time _) <- getModificationTime path
        content <- B.readFile path 
        let md5 = map B.w2c $ B.unpack $ Base16.encode $ hash content
        return [(replace "new_resource" "resource" path, length, md5)]
  return (concat paths)

getRecursiveContentsScript :: FilePath -> IO [(FilePath, FileSize, String)]

getRecursiveContentsScript topdir = do
  names <- getDirectoryContents topdir
  let properNames = filter (`notElem` [".", "..", ".svn", ".git", "Makefile", ".DS_Store", ".gitmodules", "tool", "Thumbs.db", "onlyu"]) names
  paths <- forM properNames $ \name -> do
    let path = topdir </> name
    isDirectory <- doesDirectoryExist path
    if isDirectory
       then getRecursiveContentsScript path
       else
      do
        putStrLn path
        length <- withFile path ReadMode hFileSize
        -- (UTCTime time _) <- getModificationTime path
        content <- B.readFile path 
        let md5 = map B.w2c $ B.unpack $ Base16.encode $ hash content
        return [(replace "new_resource" "resource" path, length, md5)]
  return (concat paths)

directorys :: [(FilePath, FileSize, String)] -> [FilePath]
directorys = drop 1 . map head . group . sortBy (comparing length) . map (takeDirectory . sel1)

filterFile = filter (not . (=~ ".proto$") . sel1)

translate_path :: FilePath -> FilePath
translate_path = drop 2

validFiles :: [(FilePath, FileSize, String)] -> [(FilePath, FileSize, String)]
validFiles = map (\item -> (translate_path $ sel1 item, sel2 item, sel3 item)) . filterFile

outputMethod = writeFile "etc/files"
-- outputMethod = putStrLn
renderToString = render . pp_value . JSON.showJSON
doReplace = T.unpack . T.replace (T.pack "\\\\") (T.pack "/") . T.pack

main = do
  paths_td <- getRecursiveContents "./resource"
  paths_script <- getRecursiveContentsScript "./home/script"
  paths_shader <- getRecursiveContents "./home/shader"
  let paths = paths_td ++ paths_script ++ paths_shader
      paths' = validFiles paths
  outputMethod $ doReplace $ renderToString paths'
