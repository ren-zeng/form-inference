{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Main where

import Control.Monad
import Data.SCargot
import Data.SCargot.Repr
import qualified Data.Text as T
import Data.Text.Prettyprint.Doc.Util (putDocW)
import Form
import Formatting
import Prettyprinter
import System.Process (proc, rawSystem, readProcess)
import TestCases

main :: IO ()
main = do
  let printer = setFromCarrier fromWellFormed (basicPrint id)
  forM_ testCases $ \ex -> do
    writeFile "egglog/testCases.egglog" $
      uncurry
        (egglogLet $ T.unpack . encodeOne printer . toEggLog . buildSurface)
        ex
    writeFile "egglog/main.egglog" $ show $ egglogMain (fst ex)
    let surface = (buildSurface . snd) ex
    out <- readProcess "egglog" ["egglog/main.egglog"] ""
    -- putStrLn out
    let terms = fromEggLog @FormalUnit <$> sExprList (T.pack out)
    -- mapM_ print terms
    writeFile ("doc/" <> fst ex <> ".txt") $
      show $
        vsep
          [ "Input surface:"
          , indent 2 $ pretty surface
          , "Output analysis:"
          , indent 2 $ vsep $ punctuate  (nLines 3) $ map pretty terms
          ]

egglogMain :: String -> Doc ann
egglogMain var =
  vsep
    [ "(include \"egglog/form.egglog\")"
    , "(include \"egglog/testCases.egglog\")"
    , "(run 100)"
    , "(extract $" <> pretty var <+> "10)"
    -- , "(print-function GetStartingHarmony)"
    ]

nLines :: Int -> Doc ann
nLines n = mconcat (replicate n line)