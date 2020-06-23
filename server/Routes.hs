{-# LANGUAGE OverloadedStrings #-}
module Routes where

import Data.Text (Text)
import Katip (Severity(..), logFM, ls)
import Control.Lens (view)
import Control.Monad.Reader.Class (ask)
import Control.Monad.IO.Class
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
 
import App
import API
import Template

orgCapture :: WebLink -> App Response
orgCapture link = do
  logFM InfoS . ls $ "POST to /capture with data: " <> show link
  p <- ask (view pathL)
  logFM DebugS . ls $ render $ template link
  liftIO . TIO.appendFile (T.unpack p) $ render $ template link
  pure $ Response p "ok"

orgRef :: App Text
orgRef = do
  logFM InfoS "POST /ref"
  pure "org-ref"

heartbeat :: App Text
heartbeat = do
  logFM InfoS "GET /heartbeat"
  p <- ask (view pathL)
  pure p
