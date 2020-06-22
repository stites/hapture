{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE KindSignatures #-}
module Lib
    ( WebLink(..), Response(..)
    , API, api
    ) where

import Data.Aeson
import GHC.Generics
import Servant
import Data.Text (Text)

data WebLink = WebLink
  { url   :: !Text
  , title :: !Text
  , selection :: !( Maybe Text )
  , comment :: !( Maybe Text )
  , tags :: ![Text]
  } deriving stock (Eq, Show, Generic)
    deriving anyclass (FromJSON, ToJSON)

data Response = Response
  { path :: Text
  , status :: Text
  } deriving stock (Eq, Show, Generic)
    deriving anyclass (FromJSON, ToJSON)

type API
  =    "heartbeat" :> Get '[JSON] Text -- /heartbeat GET
  :<|> "capture" :> ReqBody '[JSON] WebLink :> Post '[JSON] Response -- /org/capture POST
  -- :<|> "org" :> "ref" :> ReqBody '[JSON] WebLink :> Post '[JSON] Text

api :: Proxy API
api = Proxy
