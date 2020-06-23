{-# LANGUAGE OverloadedStrings #-}
module Logging where

import Control.Exception (bracket)
import System.IO (stdout)
import Katip (ColorStrategy(..), permitItem, Severity(..), Verbosity(..),
  registerScribe, defaultScribeSettings, initLogEnv, closeScribes, logFM, runKatipContextT, ls, LogEnv, Namespace, LogContexts
  )
import qualified Katip as K

runInitialLogEnv :: (LogEnv -> IO x) -> IO x
runInitialLogEnv = bracket mkLogEnv closeScribes

mkLogEnv :: IO LogEnv
mkLogEnv = do
  handleScribe <- K.mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
  initialLE <- initLogEnv initialNamespace env
  registerScribe "stdout" handleScribe defaultScribeSettings initialLE

initialNamespace :: Namespace
initialNamespace = "local"

initialContext :: LogContexts
initialContext = mempty

env :: K.Environment
env = "local"

startupMsg :: Int -> LogEnv -> IO ()
startupMsg port le
  = runKatipContextT le initialContext initialNamespace
  . logFM InfoS
  . ls $ "starting server on port " <> show port

