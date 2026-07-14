{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

module Form where

import Data.List
import Data.List.NonEmpty
import Data.SCargot.Repr
import Data.String
import Data.Text (Text)
import qualified Data.Text as T
import Formatting
import Prettyprinter

data CadenceStrength = Weak | Strong | None deriving (Show, Read)

data Harmony = I | II | III | IV | V | VI | VII deriving (Show, Read)
data Idea
  = Label String
  | Concat Idea Idea
  | Twice Idea
  deriving (Show)

data PhraseParam = Param [Harmony] CadenceStrength deriving (Show)

data FormalUnit
  = Leaf Idea PhraseParam
  | Sentence Idea Idea PhraseParam PhraseParam
  | Period Idea Idea Idea PhraseParam PhraseParam
  | Presentation Idea PhraseParam PhraseParam
  | Concatenate FormalUnit FormalUnit
  deriving (Show)

instance IsString Idea where
  fromString = Label

instance Pretty CadenceStrength
instance Pretty Harmony
instance Pretty Idea where
  pretty = \case
    Label x -> pretty x
    Concat x y -> pretty x <> "+" <> pretty y
    Twice x -> "Twice" <+> pretty x
instance Pretty PhraseParam where
  pretty (Param hs cad) = "⟦" <> hsep [hcat $ punctuate "-" (fmap pretty hs), pretty cad] <> "⟧"

instance Pretty FormalUnit where
  pretty = \case
    Leaf idea param -> "{" <> hsep [pretty idea, pretty param] <> "}"
    Sentence id1 id2 param1 param2 ->
      sep
        [ "Sentence"
        , indent 2 $
            sep
              [ pretty id1
              , pretty id2
              , pretty param1
              , pretty param2
              ]
        ]
    Period id1 id2 id3 param1 param2 ->
      sep
        [ "Period"
        , indent 2 $
            sep
              [ pretty id1
              , pretty id2
              , pretty id3
              , pretty param1
              , pretty param2
              ]
        ]
    Presentation id1 param1 param2 ->
      sep
        [ "Presentation"
        , indent 2 $
            sep
              [ pretty id1
              , pretty param1
              , pretty param2
              ]
        ]
    Concatenate u1 u2 ->
      hsep
        [pretty u1, "+", pretty u2]

bracketPretty x = "(" <> x <> ")"

instance FromEggLog Idea where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog Idea] not expecting Atom"
    WFSList ["Label", WFSAtom x] -> Label $ T.unpack x
    WFSList ["Concat", x, y] -> Concat (fromEggLog x) (fromEggLog y)
    WFSList ["Twice", x] -> Twice (fromEggLog x)

  toEggLog (Label x) = WFSList [WFSAtom "Label", toEggLog $ T.pack x]

instance FromEggLog CadenceStrength where
  fromEggLog = \case
    WFSList [WFSAtom x] -> read $ T.unpack x
  toEggLog = WFSList . pure . WFSAtom . T.pack . show

instance FromEggLog Harmony where
  fromEggLog = \case
    WFSList [WFSAtom x] -> read $ T.unpack x
  toEggLog = WFSList . pure . WFSAtom . T.pack . show

instance FromEggLog Text where
  fromEggLog = \case
    WFSAtom t -> t
    WFSList _ -> error "[FromEggLog Text] not expecting List"
  toEggLog = WFSAtom . T.pack . show

instance FromEggLog PhraseParam where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog PhraseParam] not expecting atom"
    WFSList [WFSAtom "Param", hs, cad] -> Param (fromEggLog hs) (fromEggLog cad)
  toEggLog (Param hs cad) = WFSList ["Param", toEggLog hs, toEggLog cad]

instance FromEggLog FormalUnit where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog FormalUnit] not expecting atom"
    WFSList [WFSAtom "Leaf", idea, param] ->
      Leaf
        (fromEggLog idea)
        (fromEggLog param)
    WFSList [WFSAtom "Sentence", id1, id2, param1, param2] ->
      Sentence
        (fromEggLog id1)
        (fromEggLog id2)
        (fromEggLog param1)
        (fromEggLog param2)
    WFSList [WFSAtom "Period", id1, id2, id3, param1, param2] ->
      Period
        (fromEggLog id1)
        (fromEggLog id2)
        (fromEggLog id3)
        (fromEggLog param1)
        (fromEggLog param2)
    WFSList [WFSAtom "Presentation", id1, param1, param2] ->
      Presentation
        (fromEggLog id1)
        (fromEggLog param1)
        (fromEggLog param2)
    WFSList [WFSAtom "Concatenate", u1, u2] ->
      Concatenate
        (fromEggLog u1)
        (fromEggLog u2)
  toEggLog = \case
    Leaf idea param -> WFSList [WFSAtom "Leaf", toEggLog idea, toEggLog param]
    Sentence id1 id2 param1 param2 ->
      WFSList
        [ WFSAtom "Sentence"
        , toEggLog id1
        , toEggLog id2
        , toEggLog param1
        , toEggLog param2
        ]
    Period id1 id2 id3 param1 param2 ->
      WFSList
        [ WFSAtom "Period"
        , toEggLog id1
        , toEggLog id2
        , toEggLog id3
        , toEggLog param1
        , toEggLog param2
        ]
    Presentation id1 param1 param2 ->
      WFSList
        [ WFSAtom "Presentation"
        , toEggLog id1
        , toEggLog param1
        , toEggLog param2
        ]
    Concatenate u1 u2 ->
      WFSList
        [WFSAtom "Concatenate", toEggLog u1, toEggLog u2]

instance (FromEggLog a) => FromEggLog [a] where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog [a]] not expecting atom"
    WFSList (WFSAtom "vec-of" : xs) -> fromEggLog <$> xs
  toEggLog xs = WFSList (WFSAtom "vec-of" : (toEggLog <$> xs))

buildSurface :: NonEmpty FormalUnit -> FormalUnit
buildSurface (x :| []) = x
buildSurface (x :| y : ys) = Concatenate x (buildSurface $ y :| ys)
