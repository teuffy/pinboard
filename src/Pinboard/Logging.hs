{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE Rank2Types #-}

-- |
-- Module      : Pinboard.Logging
-- Copyright   : (c) Jon Schoning, 2015
-- Maintainer  : jonschoning@gmail.com
-- Stability   : experimental
-- Portability : POSIX
module Pinboard.Logging
  ( withStdoutLogging
  , withStderrLogging
  , withNoLogging
  , logNST
  , logOnException
  , runLogOnException
  , nullLogger
  , runNullLoggingT
  , errorLevelFilter
  , infoLevelFilter
  , debugLevelFilter
  ) where

import Control.Monad.IO.Class
import Control.Monad.Logger
import Control.Exception.Safe
import Data.Time
import Data.Monoid

import Data.Text as T

import Pinboard.Types

------------------------------------------------------------------------------

withStdoutLogging :: PinboardConfig -> PinboardConfig
withStdoutLogging p =
  p
  { execLoggingT = runStdoutLoggingT
  }

withStderrLogging :: PinboardConfig -> PinboardConfig
withStderrLogging p =
  p
  { execLoggingT = runStderrLoggingT
  }

withNoLogging :: PinboardConfig -> PinboardConfig
withNoLogging p =
  p
  { execLoggingT = runNullLoggingT
  }

------------------------------------------------------------------------------

logOnException
  :: (MonadLogger m, MonadCatch m, MonadIO m)
  => T.Text -> m a -> m a
logOnException src =
  handle
    (\(e :: SomeException) -> do
       logNST LevelError src (toText e)
       throw e)

runLogOnException
  :: (MonadCatch m, MonadIO m)
  => T.Text -> PinboardConfig -> LoggingT m a -> m a
runLogOnException logSrc config = runConfigLoggingT config . logOnException logSrc

------------------------------------------------------------------------------

logNST
  :: (MonadIO m, MonadLogger m)
  => LogLevel -> Text -> Text -> m ()
logNST l s t =
  liftIO (toText <$> getCurrentTime) >>=
  \time -> logOtherNS ("[pinboard/" <> s <> "]") l ("@(" <> time <> ") " <> t)

------------------------------------------------------------------------------

nullLogger :: Loc -> LogSource -> LogLevel -> LogStr -> IO ()
nullLogger _ _ _ _ = return ()

runNullLoggingT :: LoggingT m a -> m a
runNullLoggingT = (`runLoggingT` nullLogger)

------------------------------------------------------------------------------

errorLevelFilter :: LogSource -> LogLevel -> Bool
errorLevelFilter = minLevelFilter LevelError

infoLevelFilter :: LogSource -> LogLevel -> Bool
infoLevelFilter = minLevelFilter LevelInfo

debugLevelFilter :: LogSource -> LogLevel -> Bool
debugLevelFilter = minLevelFilter LevelDebug

minLevelFilter :: LogLevel -> LogSource -> LogLevel -> Bool
minLevelFilter l _ l' = l' >= l

toText
  :: Show a
  => a -> Text
toText = T.pack . show
