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
 
  let mkLogEnv = initLogEnv initialNamespace env
               >>= registerScribe "stdout" handleScribe defaultScribeSettings
              
  bracket mkLogEnv closeScribes $ \logenv -> do
    startupMsg logenv
    runApp logenv
 
  where
    mkLogEnv = do
      handleScribe <- K.mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
      initialLE <- initLogEnv initialNamespace env
      registerScribe "stdout" handleScribe defaultScribeSettings initialLE

    port :: Int
    port = 10046 -- IO Org

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

orgCapture :: WebLink -> App Response
orgCapture link = do
  logFM InfoS . ls $ "POST to /capture with data: " <> show link
  pure $ Response "/it/is/a/path.org" "ok"

orgRef :: App Text
orgRef = do
  logFM InfoS "POST /ref"
  pure "org-ref"

heartbeat :: App Text
heartbeat = do
  logFM InfoS "GET /heartbeat"
  pure "ok"
