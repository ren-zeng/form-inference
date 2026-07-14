{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Data.SCargot
import Data.SCargot.Repr
import qualified Data.Text as T
import Form
import Formatting
import Prettyprinter
import System.Process (proc, rawSystem, readProcess)
import TestCases

main :: IO ()
main = do
  let printer = setFromCarrier fromWellFormed (basicPrint id)
  let ex = head testCases
  writeFile "egglog/testCases.egglog" $
    uncurry
      (egglogLet $ T.unpack . encodeOne printer . toEggLog.  buildSurface)
      ex
  let surface =  (buildSurface . snd) ex
  out <- readProcess "egglog" ["egglog/main.egglog"] ""
  let terms = fromEggLog @FormalUnit <$> sExprList (T.pack out)
  -- mapM_ print terms
  print $
    vsep
      [ "Input surface:"
      , indent 2 $ pretty surface
      , "Output analysis:"
      , indent 2 $ pretty terms
      ]
  return ()
