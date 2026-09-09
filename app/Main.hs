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


main = print "hello"
-- main :: IO ()
-- main = do
--   let printer = setFromCarrier fromWellFormed (basicPrint id)
--   forM_ testCases $ \ex -> do
--     writeFile "egglog/testCases.egglog" $
--       uncurry
--         (egglogLet $ T.unpack . encodeOne printer . toEggLog . fromSurface)
--         ex
--     writeFile "egglog/main.egglog" $ show $ egglogMain (fst ex)
--     let surface =  snd ex
--     out <- readProcess "egglog" ["egglog/main.egglog"] ""
--     putStrLn out
--     let terms = fromEggLog @FormalUnit <$> sExprList (T.pack out)
--     -- mapM_ print terms
--     writeFile ("docs/" <> fst ex <> ".txt") $
--       show $
--         vsep
--           [ "Input surface:"
--           , indent 2 $ pretty surface
--           , nLines 3
--           , "Output analysis:"
--           , indent 2 $ vsep $ punctuate (nLines 3) $ map progInfoDoc terms
--           ]
--   generateDoc


-- generateDoc :: IO () 
-- generateDoc =  do
--   void $ readProcess "prequery" ["docs/output.typ"] ""
--   void $ readProcess "typst" ["compile","docs/output.typ"] ""
   


-- progInfoDoc :: FormalUnit -> Doc ann
-- progInfoDoc u = vsep ["size=" <> pretty  (sizeFormalUnit  u) ,pretty u]

-- egglogMain :: String -> Doc ann
-- egglogMain var =
--   vsep
--     [ "(include \"egglog/form.egglog\")"
--     , "(include \"egglog/testCases.egglog\")"
--     , "(run 200)"
--     , "(extract $" <> pretty var <+> "2)"
--     -- , "(print-function GetStartingHarmony)"
--     ]

-- nLines :: Int -> Doc ann
-- nLines n = mconcat (replicate n line)
