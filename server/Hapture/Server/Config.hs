{-# LANGUAGE TemplateHaskell #-}
module Hapture.Server.Config where

import Data.Text
import Control.Lens (makeLensesFor)
import Options.Applicative
import Options.Applicative.Text (textOption)

import Data.Port

data Config = Config
  { port :: Int
  , path :: Text
  }

makeLensesFor
  [ ("port", "portL")
  , ("path", "pathL")
  ] ''Config

parseConfig :: Parser Config
parseConfig = Config
   <$> option auto
       ( long "port"
      <> short 'p'
      <> metavar "PORT"
      <> showDefault
      <> value 10046
      <> help "port to run server on" )
   <*> textOption
       ( long "file"
      <> short 'f'
      <> help "file path to append 'haptures' to"
      <> metavar "PATH" )


getOpts :: ParserInfo Config
getOpts = info (parseConfig <**> helper)
      ( fullDesc
     <> progDesc "Start a hapture server for PATH file"
     <> header "hapture - a test for optparse-applicative" )

getOptsIO :: IO Config
getOptsIO = execParser getOpts
