{-# LANGUAGE OverloadedStrings #-}
module Main where

import Network.Wai.Handler.Warp (run)
import Servant
import Control.Monad.Reader (ReaderT(..), runReaderT)

import Hapture.API
import Hapture.Server.App
import Hapture.Server.Routes
import Hapture.Server.Logging
import Hapture.Server.Config as Config


main :: IO ()
main =
  getOptsIO >>= \cfg ->
    runInitialLogEnv $ \logenv -> do
      startupMsg (port cfg) logenv
      run (port cfg) . app $ defaultEnvironment (Config.path cfg) logenv
     
app :: Environment -> Application
app s = serve api $ hoistServer api (nt s) server
  where
    server :: ServerT API App
    server = heartbeat :<|> orgCapture

    nt :: Environment -> App a -> Handler a
    nt c x = runReaderT (unApp x) c
