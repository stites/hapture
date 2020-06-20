{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.Wai.Handler.Warp (run)
import Servant
import Data.Text (Text)
import System.IO (stdout)
import Control.Exception (bracket)
import Control.Monad.Reader (ReaderT(..), runReaderT)
import Katip (ColorStrategy(..), permitItem, Severity(..), Verbosity(..),
  registerScribe, defaultScribeSettings, initLogEnv, closeScribes, logFM, runKatipContextT, ls, LogEnv, Namespace, LogContexts
  )
import qualified Katip as K

import Lib
import App


main :: IO ()
main = do
  handleScribe <- K.mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
  let mkLogEnv = registerScribe "stdout" handleScribe defaultScribeSettings =<< initLogEnv initialNamespace env
  bracket mkLogEnv closeScribes $ \logenv -> do
    startupMsg logenv
    runApp logenv
 
  where
    port :: Int
    port = 8080

    initialNamespace :: Namespace
    initialNamespace = "local"

    initialContext :: LogContexts
    initialContext = mempty

    env :: K.Environment
    env = "local"

    startupMsg :: LogEnv -> IO ()
    startupMsg le
      = runKatipContextT le initialContext initialNamespace
      . logFM InfoS
      . ls $ "starting server on port " <> show port

    runApp :: K.LogEnv -> IO ()
    runApp le = run port . app
      $ Config initialNamespace initialContext le Nothing Nothing

app :: Config -> Application
app s = serve api $ hoistServer api (nt s) server
  where
    server :: ServerT API App
    server = heartbeat :<|> orgCapture

    nt :: Config -> App a -> Handler a
    nt s x = runReaderT (unApp x) s

orgCapture :: WebLink -> App Text
orgCapture link = do
  logFM InfoS "POST org/capture"
  pure "org-capture"

orgRef :: App Text
orgRef = do
  logFM InfoS "POST org/ref"
  pure "org-ref"

heartbeat :: App Text
heartbeat = do
  logFM InfoS "GET heartbeat"
  pure "ok"
