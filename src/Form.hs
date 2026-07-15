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
  | RefIdea String
  deriving (Show)

data PhraseParam
  = Param [Harmony] CadenceStrength
  | ConcatParam PhraseParam PhraseParam
  deriving (Show)
data IdeaBinding = BindIdea String Idea deriving (Show)
data FormalUnitBinding = BindFormalUnit String FormalUnit deriving (Show)
data FormalUnit
  = Leaf Idea PhraseParam
  | RefFormalUnit String
  | ZipFormalUnit Idea PhraseParam
  | Sentence IdeaBinding FormalUnit FormalUnit
  | Period FormalUnitBinding FormalUnit FormalUnit
  | Presentation IdeaBinding FormalUnit FormalUnit
  | Continuation FormalUnit FormalUnit
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
    RefIdea x -> pretty x
instance Pretty PhraseParam where
  pretty = \case
    Param hs cad -> "⟦" <> hsep [hcat $ punctuate "-" (fmap pretty hs), pretty cad] <> "⟧"
    ConcatParam x y -> pretty x <> "+" <> pretty y

instance Pretty IdeaBinding where
  pretty (BindIdea v x) = "<" <> pretty v <+> ":=" <+> pretty x <> ">"

instance Pretty FormalUnitBinding where
  pretty (BindFormalUnit v x) = "<<" <> pretty v <+> ":=" <+> pretty x <> ">>"

instance Pretty FormalUnit where
  pretty =
    align . \case
      Leaf idea param -> "{" <> hsep [pretty idea, pretty param] <> "}"
      ZipFormalUnit idea param ->
        sep
          [ "ZipFormalUnit"
          , indent 2 $
              sep
                [ pretty idea
                , pretty param
                ]
          ]
      RefFormalUnit v -> pretty v
      Sentence iBinding x y ->
        sep
          [ "Sentence"
          , indent 2 $
              sep
                [ pretty iBinding
                , pretty x
                , pretty y
                ]
          ]
      Period uBinding x y ->
        sep
          [ "Period"
          , indent 2 $
              sep
                [ pretty uBinding
                , pretty x
                , pretty y
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
        sep
          [pretty u1, "+", pretty u2]
      Continuation u1 u2 ->
        sep
          [ "Continuation"
          , indent 2 $
              sep
                [ pretty u1
                , pretty u2
                ]
          ]

bracketPretty x = "(" <> x <> ")"

instance FromEggLog Idea where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog Idea] not expecting Atom"
    WFSList ["Label", WFSAtom x] -> Label $ T.unpack x
    WFSList ["Concat", x, y] -> Concat (fromEggLog x) (fromEggLog y)
    WFSList ["Twice", x] -> Twice (fromEggLog x)
    WFSList ["RefIdea", WFSAtom x] -> RefIdea (T.unpack x)
    x -> error $ "[FromEggLog Idea] bad input " <> show x

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
    WFSList [WFSAtom "ConcatParam", x, y] -> ConcatParam (fromEggLog x) (fromEggLog y)
  toEggLog (Param hs cad) = WFSList ["Param", toEggLog hs, toEggLog cad]

instance FromEggLog IdeaBinding where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog IdeaBinding] not expecting atom"
    WFSList [WFSAtom "BindIdea", WFSAtom var, idea] -> BindIdea (T.unpack var) (fromEggLog idea)

instance FromEggLog FormalUnitBinding where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog FormalUnitBinding] not expecting atom"
    WFSList [WFSAtom "BindFormalUnit", WFSAtom var, u] -> BindFormalUnit (T.unpack var) (fromEggLog u)

instance FromEggLog FormalUnit where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog FormalUnit] not expecting atom"
    WFSList [WFSAtom "Leaf", idea, param] ->
      Leaf
        (fromEggLog idea)
        (fromEggLog param)
    WFSList [WFSAtom "RefFormalUnit", WFSAtom v] ->
      RefFormalUnit $ T.unpack v
    WFSList [WFSAtom "Sentence", iBinding, x, y] ->
      Sentence
        (fromEggLog iBinding)
        (fromEggLog x)
        (fromEggLog y)
    WFSList [WFSAtom "ZipFormalUnit", x, y] ->
      ZipFormalUnit
        (fromEggLog x)
        (fromEggLog y)
    WFSList [WFSAtom "Period", uBinding, param1, param2] ->
      Period
        (fromEggLog uBinding)
        (fromEggLog param1)
        (fromEggLog param2)
    WFSList [WFSAtom "Presentation", id1, param1, param2] ->
      Presentation
        (fromEggLog id1)
        (fromEggLog param1)
        (fromEggLog param2)
    WFSList [WFSAtom "Continuation", u1, u2] ->
      Continuation
        (fromEggLog u1)
        (fromEggLog u2)
    WFSList [WFSAtom "Concatenate", u1, u2] ->
      Concatenate
        (fromEggLog u1)
        (fromEggLog u2)
    x -> error $ "[fromEggLog FormalUnit] bad input " <> show x
  toEggLog = \case
    Leaf idea param -> WFSList [WFSAtom "Leaf", toEggLog idea, toEggLog param]
    Sentence iBinding x y ->
      WFSList
        [ WFSAtom "Sentence"
        , toEggLog iBinding
        , toEggLog x
        , toEggLog y
        ]
    Period uBinding x y ->
      WFSList
        [ WFSAtom "Period"
        , toEggLog uBinding
        , toEggLog x
        , toEggLog y
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
