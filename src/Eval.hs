{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module Eval where

import Control.Monad.Reader
import Control.Monad.State
import Data.Functor (void)
import Data.Functor.Base hiding (head, tail)
import Data.Functor.Foldable
import Data.List
import Data.List.NonEmpty (NonEmpty)
import Data.Tree
import Form
import Formatting
import Generics.SYB (everywhere, mkT)
import Prettyprinter (Pretty (pretty))
import Relude.Unsafe
import Data.Monoid (Sum(..))
import Lego
import Data.Aeson (encodeFile, Value)


-- import Relude (MonadReader (ask), Reader, runReader, ReaderT (runReaderT))

prop_eval_is_inverse_of_infer :: (NonEmpty FormalUnit -> FormalUnit) -> (FormalUnit -> NonEmpty FormalUnit) -> NonEmpty FormalUnit -> Bool
prop_eval_is_inverse_of_infer infer eval surface = surface == eval (infer surface)

-- eval :: (String -> Idea) -> FormalUnit -> Tree (FormalUnitF ())
evalToTree ::
  -- | global variable for idea
  (String -> Idea) ->
  FormalUnit ->
  -- | The expanded tree whose node are the function calls themselves (represented by constructors with parameters), and leafs being the segments of the surface. The size of the leaf should be the same as the size of the surface list.
  Tree (FormalUnitF [Idea])
evalToTree binding unit = applyBindingAll $ cata action unit []
 where
  action ::
    FormalUnitF ([Idea] -> Tree (FormalUnitF [Idea])) ->
    [Idea] ->
    Tree (FormalUnitF [Idea])
  action x = do
    ideas <- ask
    let root = ideas <$ x
        currentNode = Node root
        addedIdea i = substituteBy ideas i : ideas
    let children = case x of
          LeafF idea param -> leaf . uncurry LeafF <$> zipIdeaParam (substituteBy ideas idea) param
          UseIdeaWithF idea param -> leaf . uncurry LeafF <$> zipIdeaParam (substituteBy ideas idea) param
          SeqF idea params -> do
            param <- params
            return $ Node (UseIdeaWithF idea param) $ leaf . uncurry LeafF <$> zipIdeaParam (substituteBy ideas idea) param
          ConcatenateF a b -> ($ ideas) <$> [a, b]
          SentenceF bi pres cont -> ($ addedIdea bi) <$> [pres, cont]
          PeriodF bi ant cons -> ($ addedIdea bi) <$> [ant, cons]
          TwiceFormalUnitF a -> ($ ideas) <$> [a, a]
          HybridAntContF a b -> ($ ideas) <$> [a, b]
          SimpleBinaryF a b -> ($ ideas) <$> [a, a, b, b]
          RoundedBinaryF a b -> ($ ideas) <$> [a, a, b, a, b, a]
          TernaryF a b -> ($ ideas) <$> [a, b, a]
          _ -> error $ "[eval] not implemented case:" <> show root
    return $ currentNode children

  instantiateWith :: [Idea] -> FormalUnit -> FormalUnit
  instantiateWith ideas = everywhere $ mkT (substituteBy ideas)

  applyBindingAll = everywhere $ mkT (applyBinding binding)
  leaf x = Node x []

{- | given a contex of ideas, substitute an idea involving local variable to a more concrete form by replacing its local variable i with the ith idea in the context

>>> map (substituteBy [Label "a",LocalVar 0, Concat (Label "b") (Label "c")])  [LocalVar 1, LocalVar 0, Label "x", Concat (Label "y") (LocalVar 2)]
[LocalVar 0,Label "a",Label "x",Concat (Label "y") (Concat (Label "b") (Label "c"))]
-}
substituteBy :: [Idea] -> Idea -> Idea
substituteBy xs = cata $ \y -> case y of
  LabelF{} -> embed y
  LocalVarF n -> case xs !? n of
    Nothing -> error $ "[substituteBy] list out of bound: " <> show (xs, n, embed y)
    Just x -> x
  ConcatF{} -> embed y
  TwiceF x -> embed y
  _ -> embed y

applyBinding :: (String -> Idea) -> Idea -> Idea
applyBinding binding = cata $ \case
  RefIdeaF s -> binding s
  x -> embed x

leafs :: Tree a -> [a]
leafs = cata $ \case
  NodeF x [] -> [x]
  NodeF _ ys -> concat ys

-- | Interpreting Concat and Twice to list monoid
unRollIdea :: Idea -> [Idea]
unRollIdea = cata $ \case
  LabelF s -> [Label s]
  ConcatF x y -> x ++ y
  TwiceF x -> x ++ x
  RefIdeaF v -> [RefIdea v]
  LocalVarF i -> [LocalVar i]

unRollPhaseParam :: PhraseParam -> [PhraseParam]
unRollPhaseParam = cata $ \case
  ParamF hs strength -> [Param hs strength]
  ConcatParamF x y -> x ++ y

zipIdeaParam :: Idea -> PhraseParam -> [(Idea, PhraseParam)]
-- zipIdeaParam x@Label{} a@Param{} = [(x, a)]
zipIdeaParam x a
  | length ideas == length params = zip ideas params
  | otherwise = error "[zipIdeaParam] unrolled ideas and unrolled phraseparam does not have same length"
 where
  ideas = unRollIdea x
  params = unRollPhaseParam a

-- zipIdeaParam (Concat x y) (ConcatParam a b) = zipIdeaParam x a <> zipIdeaParam y b
-- zipIdeaParam x a = error $ show $
--   prettyApp "[zipIdeaParam] not implemented case: "   [pretty x, pretty a]


{-|

>>> alignLeaf ["a","b","c","d"] $ Node () [Node () [],Node () [],Node () [Node () [],Node () []]]
Node {rootLabel = ((),"abcd"), subForest = [Node {rootLabel = ((),"a"), subForest = []},Node {rootLabel = ((),"b"), subForest = []},Node {rootLabel = ((),"cd"), subForest = [Node {rootLabel = ((),"c"), subForest = []},Node {rootLabel = ((),"d"), subForest = []}]}]}


>>> alignLeaf [(1::Sum Int),4,3,2] $ Node () [Node () [],Node () [],Node () [Node () [],Node () []]]
Node {rootLabel = ((),Sum {getSum = 10}), subForest = [Node {rootLabel = ((),Sum {getSum = 1}), subForest = []},Node {rootLabel = ((),Sum {getSum = 4}), subForest = []},Node {rootLabel = ((),Sum {getSum = 5}), subForest = [Node {rootLabel = ((),Sum {getSum = 3}), subForest = []},Node {rootLabel = ((),Sum {getSum = 2}), subForest = []}]}]}

-}
alignLeaf :: (Monoid b) => [b] -> Tree a -> Tree (a, b)
alignLeaf bs t = flip evalState bs $ cata go t
 where
  go = \case
    NodeF x [] -> do 
      ws <- get  
      put $ tail ws
      return $ Node (x,head ws) []
    NodeF x mts -> do
      ts <- sequence mts
      let b = foldMap (snd . rootLabel) ts
      return $ Node (x, b) ts



plotGrouping :: FormalUnit -> Value
plotGrouping = plotTree (show . prettyAlg . fmap (const "") . fst) .
 alignLeaf @(Sum Int) (repeat 1) .
  evalToTree (\case _ -> error "[plotGrouping]") 

-- test :: [FormalUnitF [Idea]]
test = 
  encodeFile "testlego.excalidraw" $ plotTree show $
  alignLeaf @(Sum Int) (repeat 1)  $
    evalToTree
      (\case "hello" -> Label "leap"; "hi" -> Label "neighbor")
      ( Sentence
          { basicIdea = Label "my-bi"
          , presentation =
              Concatenate
                (Leaf (LocalVar 0) (Param [I] None))
                (Leaf (LocalVar 0) (Param [V] None))
          , continuation =
              Concatenate
                (Seq (LocalVar 0) [Param [III] None, Param [VI] None, Param [II] None])
                (Leaf (RefIdea "hello") (Param [V] Strong))
          }
      )

-- >>>  test

