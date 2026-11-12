{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultilineStrings #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternSynonyms #-}

module PrettyEggLog (
  TopDeclaration (..),
  S,
  fromEggLogSource,
  parseExpr,
  prettyTerm,
  prettyDeclaration,
  myParser,
  test,
) where

import Data.SCargot.Parse
import Data.SCargot.Repr
import Data.Text (Text)
import qualified Data.Text as T

import Data.List.NonEmpty (groupBy, groupBy1, groupWith, toList)
import qualified Data.Map as M
import Data.String (IsString)
import Prettyprinter
import Relude (NonEmpty, forM_, readFileText)
import Text.Parsec

-- data Match
--     = Equal
--     |

type S = WellFormedSExpr Text

data TopDeclaration a
  = DataType Text [a]
  | DataTypes [(Text, [a])]
  | Rule [a] [a]
  | Birewrite a a
  | Axiom a
  | Relation Text [a]
  | Constructor Text [a]
  | Other a
  | Comments Text
  deriving (Show)

declarationTag :: TopDeclaration a -> String
declarationTag = \case
  DataType{} -> "ADT"
  DataTypes{} -> "ADT"
  Rule{} -> "Rule"
  Birewrite{} -> "Rewrite"
  Axiom{} -> "Axiom"
  Relation{} -> "Type signature"
  Constructor{} -> "Type signature"
  Other{} -> "Other"
  Comments{} -> "Comments"

isOther :: TopDeclaration a -> Bool
isOther (Other _) = True
isOther _ = False

pattern (:=>:) :: [S] -> [S] -> S
pattern xs :=>: ys =
  KeyWord
    "rule"
    [ WFSList xs
      , WFSList ys
      ]

pattern KeyWord :: Text -> [S] -> S
pattern KeyWord x xs = WFSList (WFSAtom x : xs)

pattern (::=) :: Text -> [S] -> [S]
pattern name ::= variants =
  WFSAtom name : variants

parseExpr :: S -> TopDeclaration S
parseExpr = \case
  xs :=>: ys -> Rule xs ys
  KeyWord "datatype" (name ::= variants) -> DataType name variants
  KeyWord "datatype*" xs -> DataTypes $ go <$> xs
  KeyWord "birewrite" [x, y] -> Birewrite x y
  KeyWord "constructor" (name ::= [WFSList xs, y]) -> Constructor name $ xs ++ [y]
  KeyWord "relation" (name ::= [WFSList xs]) -> Relation name xs
  x -> Axiom x
  x -> Other x
 where
  go (WFSList (name ::= variants)) = (name, variants)

atomContent :: S -> Text
atomContent (WFSAtom x) = x
atomContent _ = error "[atomContent] non atom encountered"

isAtom :: WellFormedSExpr atom -> Bool
isAtom (WFSAtom x) = True
isAtom _ = False

{- |
>>> bracketed "321"
(321)
-}
bracketed :: Doc ann -> Doc ann
bracketed = enclose "(" ")"

-- >>> prettyTerm $ KeyWord "union" ["x","y"]
-- union x y

prettyTerm :: S -> Doc ann
prettyTerm = prettyTerm' True

prettyTerm' :: Bool -> S -> Doc ann
prettyTerm' isTopLevel expr = addPotentialBracket expr $ case expr of
  KeyWord op [x, y]
    | Just shown <- M.lookup op builtInInfix ->
        hsep
          [prettyTerm' False x, shown, prettyTerm' False y]
  WFSList xs
    | all isAtom xs -> hsep $ pretty . atomContent <$> xs
    | otherwise -> hsep $ prettyTerm' False <$> xs
  WFSAtom x -> pretty x
 where
  builtInInfix =
    M.fromList
      [ ("!=", "!=")
      , ("=", "=")
      , ("union", "≅")
      ]
  addPotentialBracket s = if isTopLevel || isAtom s then id else bracketed

prettyDeclaration :: (a -> Doc ann) -> TopDeclaration a -> Doc ann
prettyDeclaration f = \case
  DataType x a ->
    pretty x
      <+> align
        ( vsep $
            zipWith
              (<+>)
              ("::=" : repeat "|")
              (f <$> a)
        )
  DataTypes xs -> vsep (prettyDeclaration f . uncurry DataType <$> xs)
  Rule xs ys -> vsep [vsep $ f <$> xs, "---------------", vsep $ f <$> ys]
  Birewrite x y -> hsep [f x, "<~>", f y]
  Axiom x -> f x
  Constructor name xs ->
    hsep
      [ pretty name
      , ":"
      , seperatedBy " -> " (f <$> xs)
      ]
  Relation name xs ->
    hsep
      [ pretty name
      , ":"
      , seperatedBy " -> " ((f <$> xs) ++ ["Relation"])
      ]
  _ -> "[prettyDeclaration] not implemented"

pString = do
  mid <- between (char '"') (char '"') $ many (noneOf ['"'])
  return $ "\"" <> mid <> "\""

pLit = many1 (noneOf ['(', ')', ' ', '"', '\n'])

pComment = string ";;" *> manyTill anyChar newline *> pure ()

myParser = asWellFormed $ setComment pComment $ mkParser $ T.pack <$> (pLit <|> pString)

-- fromEggLogSource :: Text -> TopDeclaration
fromEggLogSource = decode $ myParser

{- | >>> seperatedBy " -> " ["a", "b", "()"]
a -> b -> ()
-}
seperatedBy :: (Foldable t) => Doc ann -> t (Doc ann) -> Doc ann
seperatedBy x = concatWith $ surround x

grouppedDeclarations :: [TopDeclaration S] -> [Doc ann]
grouppedDeclarations xs =
  seperatedBy (vsep $ replicate 2 line) . fmap (prettyDeclaration prettyTerm) . toList
      <$> groupWith
        declarationTag
        xs

test = do
  source <- T.pack <$> readFile "egglog/form.egglog"
  let Right expressions = fmap parseExpr <$> fromEggLogSource source
  let prettyDoc = seperatedBy (vsep $ replicate 3 line) $ grouppedDeclarations expressions
  writeFile "testPrettyProgram.txt" $ show prettyDoc

-- return expressions
