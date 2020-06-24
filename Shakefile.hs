module Main where

import Development.Shake
import Development.Shake.FilePath
import System.Process (callCommand)

buildDir :: FilePath
buildDir = "_build"

main :: IO ()
main = shakeArgs shakeOptions { shakeFiles = buildDir } $ do
    want [ buildDir </> "background.js" ]

    phony "clean" $ do
      putNormal $ "Cleaning files in './"<> buildDir <>"'"
      removeFilesAfter buildDir ["//*"]

    -- makeDeployPhony "deploy" "background.js"

    phony "repl" $ liftIO $ callCommand "pulp repl"

    phony "build" $ need [buildDir </> "background.js"]

    buildDir </> "main.js" %> \out -> do
      sources <- getDirectoryFiles "" ["extension//*.purs", "extension//*.js", "psc-package.json"]
      need sources
      liftIO $ callCommand $
        "pulp browserify --standalone main "
        <> "--to " <> out <> " --build-path " <> (buildDir </> "pulp-output")
