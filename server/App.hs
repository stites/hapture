{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module App where

import Servant
import Data.Text (Text)
import Control.Monad.Reader (ReaderT(..))
import Control.Monad.Reader.Class (MonadReader, local, ask)
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Lens (makeLenses, over, view)
import Katip (LogEnv, Namespace, LogContexts)
import qualified Katip as K


data Config = Config
  { _logNamespace :: !Namespace
  , _logContext :: !LogContexts
  , _logEnv :: !LogEnv
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
