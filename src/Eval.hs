{-# LANGUAGE LambdaCase #-}

module Eval where

import Data.Functor (void)
import Data.Functor.Base
import Data.Functor.Foldable
import Data.Tree
import Form
import Generics.SYB (everywhere, mkT)
import Prettyprinter (Pretty (pretty))
import Control.Monad.Reader
import Relude.Unsafe
import Data.List
-- import Relude (MonadReader (ask), Reader, runReader, ReaderT (runReaderT))

-- eval :: (String -> Idea) -> FormalUnit -> Tree (FormalUnitF ())
eval :: (String -> Idea) -> FormalUnit -> Tree (FormalUnitF [Idea])
eval binding unit = applyBindingAll $ cata action unit []
  where
    action ::
        FormalUnitF ([Idea] -> Tree (FormalUnitF [Idea])) ->
        [Idea] ->
        Tree (FormalUnitF [Idea])
    action x = do 
        ideas <- ask
        let root = ideas <$ x
        case x of
            LeafF{} -> return $ Node root[]
            UseIdeaWithF idea params -> return $
                Node
                    { rootLabel = root
                    , subForest = leaf . uncurry LeafF <$> zipIdeaParam (substituteBy ideas idea) params
                    }
            SeqF idea params -> return $
                Node
                    { rootLabel = root
                    , subForest = (\p -> Node (LeafF (substituteBy ideas idea) p) []) <$> params
                    }
            ConcatenateF a b -> return $ Node root [a ideas, b ideas]
            SentenceF bi pres cont -> return $
                Node
                    root
                    [ pres (substituteBy ideas bi:ideas) , cont (substituteBy ideas bi:ideas)]
            PeriodF bi ant cons ->  return $ Node root [ant (substituteBy ideas bi:ideas), cons (substituteBy ideas bi:ideas)]
            TwiceFormalUnitF a -> return $ Node root [a ideas, a ideas]
            HybridAntContF a b -> return $ Node root [a ideas, b ideas]
            SimpleBinaryF a b -> return $ Node root $ ($ ideas) <$> [a , a, b, b]
            RoundedBinaryF a b -> return $ Node root $ ($ ideas) <$> [a, a, b, a, b, a]
            TernaryF a b -> return $ Node root $ ($ ideas) <$> [a, b, a]
            _ -> error $ "[eval] not implemented case:" <> show root
    instantiateWith :: [Idea] -> FormalUnit -> FormalUnit
    instantiateWith ideas = everywhere $ mkT (substituteBy ideas)

    applyBindingAll = everywhere $ mkT (applyBinding binding)
    leaf x = Node x []

substituteBy :: [Idea] -> Idea -> Idea
substituteBy xs = cata $ \y -> case y of
    LabelF{} -> embed y
    LocalVarF n -> case xs !? n of 
        Nothing -> error $ "[substituteBy] list out of bound: " <> show (xs,n, embed y)
        Just x -> x
    ConcatF{} -> embed y
    TwiceF{} -> embed y
    _ -> embed y

applyBinding :: (String -> Idea) -> Idea -> Idea
applyBinding binding = cata $ \case
    RefIdeaF s -> binding s
    x -> embed x

test =
    leafs $
        eval
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

leafs :: Tree a -> [a]
leafs = cata $ \case
    NodeF x [] -> [x]
    NodeF _ ys -> concat ys

zipIdeaParam :: Idea -> PhraseParam -> [(Idea, PhraseParam)]
zipIdeaParam x@Label{} a@Param{} = [(x, a)]
zipIdeaParam (Concat x y) (ConcatParam a b) = zipIdeaParam x a <> zipIdeaParam y b
zipIdeaParam x a = error $ "[zipIdeaParam] not implemented case: " <> show (x, a)

-- >>>  test
-- [LeafF (LocalVar 0) (Param [I] None),LeafF (LocalVar 0) (Param [V] None),LeafF (Label "my-bi") (Param [III] None),LeafF (Label "my-bi") (Param [VI] None),LeafF (Label "my-bi") (Param [II] None),LeafF (Label "leap") (Param [V] Strong)]
