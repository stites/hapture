-- | hard-coded templates for the time being
{-# LANGUAGE OverloadedStrings #-}
module Template where

import Data.Maybe
import Data.OrgMode.Types (Headline(..), StateKeyword(..), Section(..), Plannings(..))
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.IO as TIO
import qualified Data.OrgMode.Types as Org

import API

emptysection :: Text -> Section
emptysection = Section Nothing (Plns mempty) [] mempty mempty []

template :: WebLink -> Headline
template link = Headline 1 (Just $ StateKeyword "TODO") Nothing htitle Nothing Nothing (API.tags link) hsection []
 where
  htitle :: Text
  htitle = "Check out [[" <> API.url link <> "]["<> API.title link <> "]]"

  msection :: Maybe Section
  msection =
    if isNothing (API.selection link) && isNothing (API.comment link)
    then Nothing
    else Just
     $ emptysection
     $ T.intercalate "\n"
     $ filter (/= "")
     [ maybe "" ("Selection: "<>) (API.selection link)
     , maybe "" ("Comment: "<>) (API.comment link)
     ]

  hsection :: Section
  hsection = fromMaybe (emptysection "") msection
    
render :: Headline -> Text
render h = T.intercalate "\n"
  [ ""
  , hstring
  , Org.sectionParagraph $ Org.section h
  , ""
  ]
  where
    Org.Depth d = Org.depth h
   
    htags = if null (Org.tags h) then "" else ":" <> T.intercalate ":" (Org.tags h) <> ":"

    hstring :: Text
    hstring
      = T.intercalate " "
      $ filter (/= "")
      [ T.replicate d "*"
      , maybe "" Org.unStateKeyword (Org.stateKeyword h)
      , maybe "" (\p -> "[#" <> T.pack (show p) <> "]") (Org.priority h)
      , Org.title h -- assumes no newlines
      , htags
      ]

