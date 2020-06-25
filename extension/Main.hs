{-# LANGUAGE OverloadedStrings #-}
module Main where

import Data.Text (Text)
import Data.Maybe (fromMaybe)
import Servant.JS
import Text.Blaze.Html5 (Html, AttributeValue, (!), button, textarea, body, docTypeHtml, input, legend, fieldset, script, meta)
import Text.Blaze.Html5.Attributes (type_, cols, placeholder, rows, lang, for, src, charset)
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
import qualified Data.Text.IO as T (writeFile)
import qualified Data.Text.Lazy as TL
import Text.Blaze.Html.Renderer.Text (renderHtml)

import Hapture.API
import Data.Port

main :: IO ()
main = do
  -- writeHTMLFiles
  writeJSFiles

apiJS :: Text
apiJS = jsForAPI api vanillaJS

writeJSFiles :: IO ()
writeJSFiles = do
  T.writeFile "extension/api.js" apiJS

commonHeader :: AttributeValue -> Html
commonHeader jsfile = do
    meta ! charset "UTF-8"
    script ! type_ "text/javascript" ! src jsfile $ mempty
    H.style "input:invalid {background-color: red;}"

template :: (AttributeValue, Maybe Html) -> Html -> Html
template (jsfile, mheadextras) bod = docTypeHtml ! lang "en" $ do
  H.head $ do
    commonHeader jsfile
    fromMaybe (pure ()) mheadextras
  body $ bod


optionsHtml :: Html
optionsHtml = template ("options_page.js", Just optionstyle) $ do
  fieldset $ do
    legend "Endpoint"
    input ! type_ "URL" ! A.id "endpoint_id"
    H.div ! A.id "has_permission_id"
          ! A.style "display: none; color: red"
          $ "No permission to access the endpoint. "
          <> "Will request when you press \"Save\"."

  H.label ! for "notification_id" $ "Notification after capture"
  H.div $ input ! type_ "checkbox" ! A.id "notification_id"

  H.label ! for "default_tags_id" $ "Default tags"
  H.div $ input ! type_ "text" ! A.id "default_tags_id"
 
  H.div $ button ! A.id "save_id" $ "Save"
  where
    optionstyle = H.style "input:invalid {background-color: red;}"

popupHtml :: Html
popupHtml = template ("popup.js", Nothing) $ do
  H.div $ textarea
        ! A.id "comment_id"
        ! rows "4"
        ! cols "50"
        ! placeholder "Enter your comments; press Ctrl-Enter to capture"
        $ mempty
       
  H.div $ textarea ! A.id "tags_id" ! rows "1" ! cols "50" $ mempty
  H.div $ button ! A.id "button_id" ! type_ "button" $ "capture!"

writeHTMLFiles :: IO ()
writeHTMLFiles = do
  T.writeFile "extension/popup.html" (TL.toStrict $ renderHtml popupHtml)
  T.writeFile "extension/options.html" (TL.toStrict $ renderHtml optionsHtml)
