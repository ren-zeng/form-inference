{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Form (
  -- ** Recursive form data type
  FormalUnit (..),

  -- *** Supporting data types
  CadenceStrength (..),
  Harmony (..),
  Idea (..),
  PhraseParam (..),
  IdeaBinding (..),
  FormalUnitBinding (..),

  -- ** operations on formal unit
  sizeFormalUnit,
  -- depthFormalUnit,
  depressFormalUnit,

  -- *** generic operations on formal unit
  FormalUnitF (..),
  foldFormalUnit,
  unfoldFormalUnit,

  -- ** Utility
  fromSurface,
  zipLeaf,
) where

import Data.Functor.Foldable
import Data.Functor.Foldable.TH
import Data.Generics
import Data.IntMap (IntMap)
import Data.List.NonEmpty hiding (map)
import Data.Map (Map)
import qualified Data.Map as Map
import Data.SCargot.Repr
import Data.String
import Data.Text (Text)
import qualified Data.Text as T
import Data.Tree (Tree)
import Formatting
import Prettyprinter
import Relude
import Relude.Unsafe
import Prelude ()

data CadenceStrength = Weak | Strong | None deriving (Show, Read, Data)
data Harmony = I | II | III | IV | V | VI | VII deriving (Show, Read, Data)
data Idea
  = Label String
  | Concat Idea Idea
  | Twice Idea
  | RefIdea String
  | LocalVar Int
  deriving (Show, Data)

data PhraseParam
  = Param [Harmony] CadenceStrength
  | ConcatParam PhraseParam PhraseParam
  deriving (Show, Data)
data IdeaBinding = BindIdea String Idea deriving (Show)
data FormalUnitBinding = BindFormalUnit String FormalUnit deriving (Show)

{- |
A FormalUnit is a program that generates a list of pairs (Idea , PhraseParam parameter). 
-}
data FormalUnit
  = Leaf Idea PhraseParam
  | RefFormalUnit String
  | LocalFormalUnit Int
  | UseIdeaWith Idea PhraseParam
  | Sentence Idea FormalUnit FormalUnit
  | Period {antecedentHead :: FormalUnit, antecedent :: FormalUnit, consequent :: FormalUnit}
  | Presentation {basicIdea :: Idea, usage1 :: FormalUnit, usage2 :: FormalUnit}
  | Continuation FormalUnit FormalUnit
  | Concatenate FormalUnit FormalUnit
  | TwiceFormalUnit FormalUnit
  | HybridAntCont FormalUnit FormalUnit
  | SimpleBinary FormalUnit FormalUnit
  | RoundedBinary FormalUnit FormalUnit
  | Ternary FormalUnit FormalUnit
  | Antecedent FormalUnit FormalUnit
  | Consequent FormalUnit FormalUnit
  deriving (Show, Data)

makeBaseFunctor ''FormalUnit

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
    LocalVar x -> "$" <> pretty x
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
      UseIdeaWith idea param ->
        sep
          [ "UseIdeaWith"
          , indent 2
              $ sep
                [ pretty idea
                , pretty param
                ]
          ]
      LocalFormalUnit i -> "$" <> pretty i
      RefFormalUnit v -> pretty v
      Sentence idea x y ->
        sep
          [ "Sentence"
          , indent 2
              $ sep
                [ "basicIdea" <> "=" <+> pretty idea
                , "presentation" <> "=" <+> pretty x
                , "continuation" <> "=" <+> pretty y
                ]
          ]
      Period uBinding x y ->
        sep
          [ "Period"
          , indent 2
              $ sep
                [ "antecedentHead" <> "=" <+> pretty uBinding
                , "antecedent" <> "=" <+> pretty x
                , "consequent" <> "=" <+> pretty y
                ]
          ]
      Presentation id1 param1 param2 ->
        sep
          [ "Presentation"
          , indent 2
              $ vsep
                [ "basicIdea" <> "=" <+> pretty id1
                , "occur1" <> "=" <+> pretty param1
                , "occur2" <> "=" <+> pretty param2
                ]
          ]
      Concatenate u1 u2 -> prettyApp "Concatenate" [pretty u1, pretty u2]
      Continuation u1 u2 ->
        sep
          [ "Continuation"
          , indent 2
              $ sep
                [ pretty u1
                , pretty u2
                ]
          ]
      TwiceFormalUnit x -> prettyApp "TwiceFormalUnit" [pretty x]
      HybridAntCont  x y -> prettyApp "HybridAntCont" [ pretty x, pretty y]
      Antecedent x y -> prettyApp "Antecedent" [pretty x, pretty y]
      Consequent x y -> prettyApp "Consequent" [pretty x, pretty y]
      SimpleBinary x y -> prettyApp "SimpleBinary" [pretty x, pretty y]
      RoundedBinary x y -> prettyApp "RoundedBinary" [pretty x, pretty y]
      Ternary x y -> prettyApp "Ternary" [pretty x, pretty y]

bracketPretty x = "(" <> x <> ")"

instance FromEggLog Idea where
  fromEggLog = \case
    WFSAtom _ -> error "[FromEggLog Idea] not expecting Atom"
    WFSList ["Label", WFSAtom x] -> Label $ T.unpack x
    WFSList ["Concat", x, y] -> Concat (fromEggLog x) (fromEggLog y)
    WFSList ["Twice", x] -> Twice (fromEggLog x)
    WFSList ["RefIdea", WFSAtom x] -> RefIdea (T.unpack x)
    WFSList ["LocalVar", WFSAtom x] -> LocalVar (read $ T.unpack x)
    x -> error $ "[FromEggLog Idea] bad input " <> show x

  toEggLog = \case
    Label x -> WFSList [WFSAtom "Label", toEggLog $ T.pack x]
    LocalVar i -> WFSList [WFSAtom "LocalVar", WFSAtom $ T.pack $ show i]

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
    WFSList [WFSAtom "UseIdeaWith", x, y] ->
      UseIdeaWith
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
    WFSList [WFSAtom "LocalFormalUnit", WFSAtom i] -> LocalFormalUnit $ read $ T.unpack i
    WFSList [WFSAtom "TwiceFormalUnit", x] -> TwiceFormalUnit $ fromEggLog x
    WFSList [WFSAtom "HybridAntCont", x, y] -> HybridAntCont  (fromEggLog x) (fromEggLog y)
    WFSList [WFSAtom "Antecedent", x, y] -> Antecedent (fromEggLog x) (fromEggLog y)
    WFSList [WFSAtom "Consequent", x, y] -> Consequent (fromEggLog x) (fromEggLog y)
    WFSList [WFSAtom "SimpleBinary", x, y] -> SimpleBinary (fromEggLog x) (fromEggLog y)
    WFSList [WFSAtom "RoundedBinary", x, y] -> RoundedBinary (fromEggLog x) (fromEggLog y)
    WFSList [WFSAtom "Ternary", x, y] -> Ternary (fromEggLog x) (fromEggLog y)
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

{- | Given a non-empty list of atomic formal units, construct a trivial formal unit using (right branching) `Concatenate`

>>>  fromSurface [Leaf "a" (Param [I,V] None), Leaf "b" (Param [II] None), Leaf "a" (Param [V,I] Strong)]
Concatenate (Leaf (Label "a") (Param [I,V] None)) (Concatenate (Leaf (Label "b") (Param [II] None)) (Leaf (Label "a") (Param [V,I] Strong)))
-}
fromSurface :: NonEmpty FormalUnit -> FormalUnit
fromSurface (x :| []) = x
fromSurface (x :| y : ys) = Concatenate x (fromSurface $ y :| ys)

{- |
@
extractHarmony ::
@
-}
foldFormalUnit :: (FormalUnitF a -> a) -> FormalUnit -> a
foldFormalUnit = cata

unfoldFormalUnit :: (a -> FormalUnitF a) -> a -> FormalUnit
unfoldFormalUnit = ana

sizeFormalUnit :: FormalUnit -> Int
sizeFormalUnit = gSize

gSize :: forall a. (Data a) => a -> Int
gSize =
  (\x -> 1 + sum (gmapQ gSize x))
    `extQ` const @Int @String 0
    `extQ` const @Int @Int 0
    `extQ` (listSize @Int)
    `extQ` (listSize @String)
    `extQ` (listSize @Harmony)

listSize :: (Data b) => [b] -> Int
listSize = sum . map gSize

-- depthFormalUnit = undefined

depressFormalUnit :: FormalUnit -> FormalUnit
depressFormalUnit = foldFormalUnit $ \case
  LeafF idea param -> Leaf idea param
  UseIdeaWithF idea param -> zipLeaf idea param

{- | zip the concat trees of idea and phrase param

>>> pretty $ zipLeaf (Concat "a" (Concat "b" "c")) (ConcatParam (Param [I] None) (ConcatParam (Param [I] None) (Param [V] None)))
{a ⟦I None⟧} + {b ⟦I None⟧} + {c ⟦V None⟧}


when the idea and phrase parameter are not concatenated in the same shape,  it results in error

>>> zipLeaf (Concat "a" "b") (Param [I] None)
[zipLeaf malformed arguments]: zipLeaf
                                 a+b
                                 ⟦I None⟧
-}
zipLeaf :: Idea -> PhraseParam -> FormalUnit
zipLeaf idea@Label{} param@Param{} = Leaf idea param
zipLeaf (Concat x y) (ConcatParam a b) = Concatenate (zipLeaf x a) (zipLeaf y b)
zipLeaf idea param =
  prettyError
    "zipLeaf malformed arguments"
    (prettyApp "zipLeaf" [pretty idea, pretty param])

data Ctx = FormBinding (Map String FormalUnit) (IntMap FormalUnit)

-- eval :: FormalUnit -> FormalUnit
-- eval  = flip evalState (FormBinding mempty mempty) . hylo alg coalg
--   where
--     alg :: FormalUnitF (State Ctx FormalUnit) -> State Ctx FormalUnit
--     alg = \case
--       LeafF _ _ -> undefined

--     coalg :: FormalUnit -> FormalUnitF (State Ctx FormalUnit)
--     coalg = \case
--       Leaf _ _ -> undefined

-- RefFormalUnitF ref ->  return $ varBinds `Map.lookup` ref