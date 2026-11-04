{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RequiredTypeArguments #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeAbstractions #-}
{-# LANGUAGE TypeApplications #-}

module Main (main, mainWithBackEnd, inferForm) where

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

main :: IO ()
main = mainWithBackEnd (readProcess "egglog" [])

eitherToIOError :: (a -> String) -> Either a b -> IO b
eitherToIOError f = \case
  Left a -> error $ f a
  Right b -> return b

parseAnnotation :: String -> IO (NonEmpty FormalUnit)
parseAnnotation = eitherToIOError show . readLinzAnnotation

mainWithBackEnd :: (String -> IO String) -> IO ()
mainWithBackEnd runEgglog = do
  linzFiles <- listDirectory linzAnnotationFolder
  linzAnnotation <-
    mapM (parseAnnotation <=< readFile) $
      fmap (withPrefix (linzAnnotationFolder <> "/")) linzFiles
  forM_ (testCases ++ zip linzFiles linzAnnotation) $ \ex -> do
    candidates <- inferForm runEgglog ex
    let surfaceSize = sizeFormalUnit $ fromSurface (snd ex)
    let prettyResults = vsep $ punctuate (nLines 3) $ map (progInfoDoc surfaceSize) candidates
    let best = head candidates
    print $ pretty ex
    print $ pretty best
    testInvertable $ head candidates
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
          , "expanded analysis:"
          , indent 2 $ vsep $ punctuate (nLines 3) $ prettyTree viaShow. evalToTree undefined <$> candidates
          , "re-generated surface"
          ,indent 2 $ vsep $ punctuate (nLines 3) $ vsep . map viaShow . leafs . evalToTree undefined <$> candidates
          ]
  generateDoc




testInvertable :: FormalUnit -> IO ()
testInvertable x = do
  print result
 where
  result = leafs $ evalToTree undefined x

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

nLines :: Int -> Doc ann
nLines n = mconcat (replicate n line)
