{-# LANGUAGE OverloadedStrings #-}

import Pinboard
import Control.Monad.Trans.Except
import Control.Monad.Trans.Reader
import Control.Monad

main :: IO ()
main = do
  let config =
        withStdoutLogging
          (fromApiToken "api token")
          { filterLoggingT = infoLevelFilter }
  result <- runPinboard config $ getPostsRecent Nothing Nothing
  case result of
    Right details -> print ("Right: " ++ show details)
    Left pinboardError -> print ("Left: " ++ show pinboardError)
