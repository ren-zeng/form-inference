{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications,DeriveDataTypeable #-}
{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE TypeAbstractions #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Monad

import qualified Data.Text as T
import Form
import Formatting
import Prettyprinter
import System.Process (readProcess)
import TestCases
import Data.SCargot
import Data.SCargot.Repr
import Data.List.NonEmpty (NonEmpty)






main :: IO ()
main = do
  forM_ testCases $ \ex -> do
    writeFile "egglog/auto-gen/testCases.egglog" $ uncurry testExampleToEggLog ex
    writeFile "egglog/auto-gen/main.egglog" $ show $ egglogMain (fst ex)
    out <- readProcess "egglog" ["egglog/auto-gen/main.egglog"] ""
    -- putStrLn out
    let terms = fromEggLog @FormalUnit <$> sExprList (T.pack out)
    let prettyResults = vsep $ punctuate (nLines 3) $ map progInfoDoc terms
    print prettyResults
    writeFile ("docs/" <> fst ex <> ".txt") $
      show $
        vsep
          [ "Input surface:"
          , indent 2 $ pretty $ snd ex
          , nLines 3
          , "Output analysis:"
          , indent 2 prettyResults
          ]
--   generateDoc

testExampleToEggLog :: String -> NonEmpty FormalUnit -> String
testExampleToEggLog = egglogLet $ T.unpack . encodeOne printer . toEggLog . fromSurface
    where printer = setFromCarrier fromWellFormed (basicPrint id)

generateDoc :: IO () 
generateDoc =  do
  void $ readProcess "prequery" ["docs/output.typ"] ""
  void $ readProcess "typst" ["compile","docs/output.typ"] ""
   


progInfoDoc :: FormalUnit -> Doc ann
progInfoDoc u = vsep ["size=" <> pretty  (sizeFormalUnit  u) ,pretty u]

egglogMain :: String -> Doc ann
egglogMain var =
  vsep
    [ "(include \"egglog/form.egglog\")"
    , "(include \"egglog/auto-gen/testCases.egglog\")"
    , "(run 200)"
    , "(extract $" <> pretty var <+> "2)"
    ]

nLines :: Int -> Doc ann
nLines n = mconcat (replicate n line)
