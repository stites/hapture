{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Hapture.Server.App where

import Servant
import Data.Text (Text)
import Control.Monad.Reader (ReaderT(..))
import Control.Monad.Reader.Class (MonadReader, local, ask)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Lens (makeLensesFor, over, view)
import Katip (LogEnv, Namespace, LogContexts)
import qualified Katip as K

import Hapture.Server.Logging

data Environment = Environment
  { logNamespace :: !Namespace
  , logContext :: !LogContexts
  , logEnv :: !LogEnv
  -- whatever other read-only config you need
  , version :: !( Maybe Text )
  , path :: !Text
  } -- deriving (Generic, Show)

defaultEnvironment :: Text -> LogEnv -> Environment
defaultEnvironment p le = Environment initialNamespace initialContext le Nothing p

makeLensesFor
  [ ("logNamespace", "logNamespaceL")
  , ("logContext", "logContextL")
  , ("logEnv", "logEnvL")
  , ("environment", "environmentL")
  , ("version", "versionL")
  , ("path", "pathL")
  ] ''Environment

newtype App a = App { unApp :: ReaderT Environment Handler a }
  deriving (Functor)

instance MonadReader Environment App where
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
  getLogEnv = view logEnvL
  localLogEnv f (App m) = App (local (over logEnvL f) m)

instance K.KatipContext App where
  getKatipContext = view logContextL
  localKatipContext f (App m) = App (local (over logContextL f) m)
  getKatipNamespace = view logNamespaceL
  localKatipNamespace f (App m) = App (local (over logNamespaceL f) m)
