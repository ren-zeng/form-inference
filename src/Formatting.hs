{-# LANGUAGE LambdaCase #-}
module Formatting (sExprList,
   sExpr,FromEggLog(..),egglogLet,bracket) where
import Data.SCargot.Repr
import qualified Data.Text as T
import Data.SCargot
import Text.Parsec
import Prettyprinter
import Data.List.NonEmpty
import Data.Aeson


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
  fromEggLog ::  WellFormedSExpr T.Text -> a 
  toEggLog :: a -> WellFormedSExpr T.Text



instance Pretty a => Pretty (WellFormedSExpr a) where 
  pretty = \case 
    WFSAtom x -> pretty x
    WFSList (x:xs) -> vsep [pretty x, indent 2 $ vsep $ pretty <$> xs]

egglogLet :: (a -> String) -> String -> a -> String
egglogLet f var x = bracket ["let", "$"<>var, f x]

egglogVec :: [String] -> String
egglogVec x = bracket ("vec-of" : x)

bracket :: [String] -> String
bracket x = "(" <> unwords x <> ")"