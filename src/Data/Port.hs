-- | really trivial package until I can find it on hackage somewhere

module Data.Port where

import Control.Exception.Safe

newtype Port = Port { unPort :: Int }

mkPort :: Int -> Port
mkPort i
  | i > 1000 && i < 65000 = Port i
  | otherwise = error "bad port number"

port :: MonadThrow m => Int -> m Port
port i
  | i > 1000 && i < 65000 = pure $ Port i
  | otherwise = throwString "bad port number"
