{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE KindSignatures #-}
module Main where

import Data.Aeson
import GHC.Generics
import Network.Wai.Handler.Warp
import Servant
import Data.Text
import System.IO (stdout)
import Control.Exception (bracket)
import Control.Monad.Reader (ReaderT(..), runReaderT)
import Control.Monad.Reader.Class (MonadReader, local, ask)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Lens (makeLenses, over, view)
import Katip (ColorStrategy(..), permitItem, Severity(..), Verbosity(..),
  registerScribe, defaultScribeSettings, initLogEnv, closeScribes, logTM, logFM, runKatipContextT, ls, LogEnv, Namespace
  )
import qualified Katip as K

data WebLink = WebLink
  { url   :: !Text
  , title :: !Text
  , selection :: !( Maybe Text )
  , comment :: !( Maybe Text )
  , tags :: ![Text]
  } deriving stock (Eq, Show, Generic)
    deriving anyclass (FromJSON)

type API
  =    "heartbeat" :> Get '[JSON] Text
  :<|> "org" :> "capture" :> ReqBody '[JSON] WebLink :> Post '[JSON] Text
  -- :<|> "org" :> "ref" :> ReqBody '[JSON] WebLink :> Post '[JSON] Text

api :: Proxy API
api = Proxy

-- katip settings --------------------------------------------------------------------

data Config = Config
  { _logNamespace :: !K.Namespace
  , _logContext :: !K.LogContexts
  , _logEnv :: !K.LogEnv
  -- whatever other read-only config you need
  , _environment   :: !( Maybe Text )
  , _version       :: !( Maybe Text )
  } -- deriving (Generic, Show)

makeLenses ''Config

newtype App a = App { unApp :: ReaderT Config Handler a }
  deriving (Functor)

instance MonadReader Config App where
  ask = App ask
  local f (App rt) = App $ local f rt

instance MonadIO App where
  liftIO = App . liftIO

instance Monad App where
  (App ma) >>= faMb = App $ do
    a <- ma
    unApp $ faMb a

instance Applicative App where
  pure = App . pure
  (App mf) <*> (App ma) = App $ mf <*> ma

-- These instances get even easier with lenses!
instance K.Katip App where
  getLogEnv = view logEnv
  localLogEnv f (App m) = App (local (over logEnv f) m)

instance K.KatipContext App where
  getKatipContext = view logContext
  localKatipContext f (App m) = App (local (over logContext f) m)
  getKatipNamespace = view logNamespace
  localKatipNamespace f (App m) = App (local (over logNamespace f) m)


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

-- run everything --------------------------------------------------------------------

main :: IO ()
main = do
  handleScribe <- K.mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
  let mkLogEnv = registerScribe "stdout" handleScribe defaultScribeSettings =<< initLogEnv initialNamespace environment
  bracket mkLogEnv closeScribes $ \logenv -> do
    startupMsg logenv
    runApp logenv
 
  where
    port :: Int
    port = 8080
    initialNamespace :: K.Namespace
    initialNamespace = "local"
    initialContext :: K.LogContexts
    initialContext = mempty
    environment :: K.Environment
    environment = "local"

    startupMsg :: K.LogEnv -> IO ()
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
