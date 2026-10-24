{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeAbstractions #-}
{-# LANGUAGE TypeApplications #-}

module Main (main,mainWithBackEnd,inferForm) where

import Control.Monad

import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NonEmpty
import Data.SCargot
import Data.SCargot.Repr
import qualified Data.Text as T
import Eval
import Form
import Formatting
import Prettyprinter
import Prettyprinter.Render.String (renderString)
import Prettyprinter.Render.Text (putDoc)
import System.Directory (listDirectory)
import System.Process (readProcess)
import TestCases

linzAnnotationFolder = "test/LinzAnnotation"
withPrefix x y = x <> y 





main ::  IO ()
main = mainWithBackEnd (readProcess "egglog" [])

inferForm :: 
  (String -> IO String) -> (String,NonEmpty FormalUnit)-> IO [FormalUnit]
inferForm runEgglog (name,surface) = do 
  out <- runEgglog $ show $ egglogMain (name,surface)
  putStrLn out
  let terms = fromEggLog @FormalUnit <$> sExprList (T.pack out)
  return terms

mainWithBackEnd :: (String -> IO String) -> IO ()
mainWithBackEnd runEgglog = do
  linzFiles <- listDirectory linzAnnotationFolder
  linzAnnotation <- mapM (fmap readLinzAnnotation . readFile) $ 
    fmap (withPrefix (linzAnnotationFolder <> "/")) linzFiles
  forM_ (testCases ++ zip linzFiles linzAnnotation) $ \ex -> do
    candidates <- inferForm runEgglog ex
    let surfaceSize = sizeFormalUnit $ fromSurface (snd ex)
    let prettyResults = vsep $ punctuate (nLines 3) $ map (progInfoDoc surfaceSize) candidates
    -- testInvertable $ head terms
    print prettyResults
    writeFile ("docs/model-outputs/" <> fst ex <> ".txt") $
      show $
        -- renderString $ layoutPretty (LayoutOptions Unbounded) $
        vsep
          [ "Input surface:"
          , "size" <+> "=" <+> pretty surfaceSize
          , indent 2 $ vsep $ pretty <$> NonEmpty.toList (snd ex)
          , nLines 3
          , "Output analysis:"
          , indent 2 prettyResults
          ]
  generateDoc

testInvertable :: FormalUnit -> IO ()
testInvertable x = do
  mapM_ print result
 where
  result = leafs $ eval undefined x

testExampleToEggLog :: String -> NonEmpty FormalUnit -> String
testExampleToEggLog = egglogLet $ T.unpack . encodeOne printer . toEggLog . fromSurface
 where
  printer = setFromCarrier fromWellFormed (basicPrint id)

generateDoc :: IO ()
generateDoc = do
  void $ readProcess "prequery" ["docs/output.typ"] ""
  void $ readProcess "typst" ["compile", "docs/output.typ"] ""

progInfoDoc :: Int -> FormalUnit -> Doc ann
progInfoDoc n u =
  vsep
    [ hsep
        [ "size=" <> pretty (sizeFormalUnit u)
        , "compressionRate=" <> pretty (fromIntegral n / fromIntegral (sizeFormalUnit u))
        ]
    , pretty u
    ]

egglogMain :: (String, NonEmpty FormalUnit)  -> Doc ann
egglogMain (var,surface) =
  vsep
    [ 
      -- "(include \"egglog/form.egglog\")"
    pretty  egglogDefs
    -- , "(include \"egglog/auto-gen/testCases.egglog\")"
    , pretty  $ testExampleToEggLog var surface
    , "(run 200)"
    , "(extract $" <> pretty var <+> "2)"
    ]

nLines :: Int -> Doc ann
nLines n = mconcat (replicate n line)
