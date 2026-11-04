{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Formatting (
  -- ** egglog translation to s-expression datatype
  sExprList,
  sExpr,
  FromEggLog (..),
  egglogLet,
  bracket,

  -- ** pretty printting util
  prettyApp,
  prettyError,
  prettyTree,
) where

import Data.SCargot
import Data.SCargot.Repr
import qualified Data.Text as T
import GHC.Stack (HasCallStack)
import Prettyprinter
import Text.Parsec
import Data.Tree
import Data.Functor.Foldable
import Data.Functor.Base

pString = do
  mid <- between (char '"') (char '"') $ many (noneOf ['"'])
  return $ "\"" <> mid <> "\""

pLit = many1 (noneOf ['(', ')', ' ', '"'])

myParser = asWellFormed $ mkParser $ T.pack <$> (pLit <|> pString)

sExprList :: T.Text -> [WellFormedSExpr T.Text]
sExprList x = case decodeOne myParser x of
  Right (WFSList xs) -> xs
  Left err -> error $ "Error: " ++ err
  _ -> error $ "expecting s-expression list but got atom"

sExpr :: T.Text -> WellFormedSExpr T.Text
sExpr x = case decodeOne myParser x of
  Right y -> y
  Left err -> error $ "Error: " ++ err
  _ -> error $ "expecting s-expression list but got atom"

class FromEggLog a where
  fromEggLog :: WellFormedSExpr T.Text -> a
  toEggLog :: a -> WellFormedSExpr T.Text

instance (Pretty a) => Pretty (WellFormedSExpr a) where
  pretty = \case
    WFSAtom x -> pretty x
    WFSList (x : xs) -> vsep [pretty x, indent 2 $ vsep $ pretty <$> xs]

egglogLet :: (a -> String) -> String -> a -> String
egglogLet f var x = bracket ["let", "$" <> var, f x]

egglogVec :: [String] -> String
egglogVec x = bracket ("vec-of" : x)

bracket :: [String] -> String
bracket x = "(" <> unwords x <> ")"

{- | Format function application using indentation
>>> prettyApp "f" [prettyApp "h" ["y1","y2"],"x1", prettyApp "g" ["x2"]]
f
  h
    y1
    y2
  x1
  g
    x2
-}
prettyApp :: Doc ann -> [Doc ann] -> Doc ann
prettyApp f args = vsep [f, indent 2 $ vsep args]

prettyError :: (HasCallStack) => Doc ann -> Doc ann -> a
prettyError title msg = error $ show $ surround title "[" "]:"  <+> align msg

prettyTree :: (a -> Doc ann) -> Tree a -> Doc ann
prettyTree f = cata $ \case 
  NodeF x rs -> prettyApp (f x) rs