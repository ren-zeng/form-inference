{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveTraversable #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneKindSignatures #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeFamilyDependencies #-}
{-# LANGUAGE TypeOperators #-}

module Rules (
  -- ** Core Types

  -- InferenceRule (..),
  -- Extended,
  -- fillVars,
  Fix (..),
  MetaVar (..),

  -- ** Pretty printing
) where

-- prettyInferenceRule,

import Data.Fix (Fix (..), hoistFix)
import Data.Functor.Compose (Compose (..))
import Data.Functor.Foldable
import Data.Functor.Foldable.TH
import Data.Kind
import GHC.Generics
import Prettyprinter
import Vary (Vary, (:|))
import qualified Vary

data MetaVar = MetaVar String
  deriving (Show)

instance Pretty MetaVar where
  pretty (MetaVar x) = pretty x

data VarExtended f a
  = WildCard
  | V MetaVar
  | Embed (f a)
  deriving (Show, Functor)

makeBaseFunctor ''VarExtended

class PrettyAlg f where
  prettyAlg :: f (Doc ann) -> Doc ann

{- | `Extended` is the term for pattern matching for a ADT. On top of the original ADT, we conceptually add two constructors with 1) WildCard, and 2) meta-variable. We want to do this parametrically without modifying the definition of the original ADT. This can't simply be done by as a sum type on top of the original ADT because it will result in a non-recursive one. Instead, we extend the ADT's base functor `f`, and then define the extended ADT as the fixed point of the extended base functor.

suppose the original ADT has a type parameter a, then it can be represented as a fixed point `Fix f a` we
-}
type Extended f = Fix (VarExtended f)

type family MapList f xs where
  MapList f '[] = '[]
  MapList f (x ': xs) = f x ': MapList f xs

-- type Universe fs = Vary (MapList Extended fs)

type family All (c :: k -> Constraint) (ts :: [k]) :: Constraint where
  All c '[] = ()
  All c (t ': ts) = (c t, All c ts)

data InferenceRule a
  = Implies Int ([MetaVar] -> ([Condition a], [Action a]))

data Condition a
  = HasTerm a
  | MetaVar ::= a

instance (Pretty a) => Pretty (Condition a) where
  pretty = \case
    HasTerm x -> pretty x
    v ::= x -> pretty v <+> "::=" <+> pretty x

data Action a
  = IntroTerm a
  | SetVal a a
  | Union a a

instance (Pretty a) => Pretty (Action a) where
  pretty = \case
    IntroTerm a -> pretty a
    SetVal x y -> pretty x <+> "<-" <+> pretty y
    Union x y -> pretty x <+> "≅" <+> pretty y

fillVars :: InferenceRule a -> ([Condition a], [Action a])
fillVars (Implies n f) = f $ MetaVar <$> take n vars
 where
  vars = map (\i -> "?" <> show i) [0 :: Int ..]

data Expr a = Lit a | Plus (Expr a) (Expr a)
  deriving (Generic, Show)

makeBaseFunctor ''Expr

data Expr1 = A | Times Expr1 Expr1
  deriving (Generic, Show)

makeBaseFunctor ''Expr1

prettyExtended ::
  (Functor f) =>
  (f (Doc ann) -> Doc ann) ->
  Extended f ->
  Doc ann
prettyExtended alg = cata $ \case
  WildCard -> "_"
  V (MetaVar x) -> pretty x
  Embed x -> alg x

-- goal ::
--   (Functor f) =>
--   (f (Doc ann) -> Doc ann) ->
--   (Vary (MapList Extended fs) -> Doc ann) ->
--   Vary (MapList Extended (f ': fs)) ->
--   Doc ann
-- goal alg = prettyVariant alg

prettyInferenceRule ::
  (Pretty a) =>
  InferenceRule a ->
  Doc ann
prettyInferenceRule r =
  vsep
    [ vsep $ pretty <$> premise
    , "-----------"
    , vsep $ pretty <$> conclusion
    ]
 where
  (premise, conclusion) = fillVars r

-- -- tests

prettyExprAlg :: (Pretty a) => ExprF a (Doc ann) -> Doc ann
prettyExprAlg = \case
  LitF x -> pretty x
  PlusF x y -> enclose "(" ")" $ x <+> "+" <+> y

instance (Pretty a) => PrettyAlg (ExprF a) where
  prettyAlg = prettyExprAlg

-- rule1 :: InferenceRule (Extended (ExprF Int))
rule1 :: forall xs. (Extended (ExprF Int) :| xs) => InferenceRule (Vary xs)
rule1 = Implies 3 $ \[x, y, z] ->
  ( [HasTerm $ Vary.from @(Extended (ExprF Int)) @xs  $ Plus' (Var' x) (Plus' (Var' y) (Var' z))]
  , [IntroTerm $ Vary.from  @(Extended (ExprF Int)) @xs  $ Plus' (Plus' (Var' x) (Var' y)) (Var' z)]
  )

testPretty =
  prettyExtended (prettyExprAlg @Int) $
    Plus' (Lit' 3) (Plus' (Lit' 4) (Lit' 5))

instance (PrettyAlg f, Functor f) => Pretty (Extended f) where
  pretty = prettyExtended prettyAlg

-- instance All Pretty xs => Pretty (Vary xs) where

-- testSingleType = prettyInferenceRule rule1  

-- >>> testSingleType
-- (?0 + (?1 + ?2))
-- -----------
-- ((?0 + ?1) + ?2)

pattern Plus' :: Extended (ExprF a) -> Extended (ExprF a) -> Extended (ExprF a)
pattern Plus' x y = (Fix (Embed (PlusF x y)))

pattern Var' :: MetaVar -> Extended (ExprF a)
pattern Var' x = Fix (V x)

pattern Lit' :: a -> Extended (ExprF a)
pattern Lit' x = Fix (Embed (LitF x))

-- pattern Times' :: Extended Expr1F -> Extended Expr1F -> Extended Expr1F
-- pattern Times' x y = Fix (Embed (TimesF x y))

-- -- testMultiTypes = undefined
