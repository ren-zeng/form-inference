{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OrPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}

module Lego (
  plotBlock,
  Vacancy (..),
  mapBlockAnn,
  canvas,
  render,
  Block (..),
  plotTree,
) where

import Data.Functor.Foldable

import Control.Arrow (Arrow (second), first)
import Control.Monad (forM, zipWithM)
import Control.Monad.Reader (
  MonadReader (ask, local),
  Reader,
  runReader,
 )
import Control.Monad.State (
  MonadState (get, put),
  State,
  evalState,
  modify,
 )
import Data.Aeson (ToJSON (toJSON), Value (Object), encodeFile)
import Data.Aeson.KeyMap (fromList)
import Data.Functor.Base (TreeF (..))

import Data.List (nub)
import qualified Data.Map as Map
import Data.Tree (Tree (..))
import Data.Foldable ( Foldable(toList) )

data Vacancy nt t = Vacant nt | Occupied t
  deriving (Show)

isVacant :: Vacancy nt t -> Bool
isVacant Vacant{} = True
isVacant _ = False

isOccupied :: Vacancy nt t -> Bool
isOccupied = not . isVacant

-- layout DSL
data Block ann nt t
  = Block {annotation :: ann, vacancies :: [Vacancy nt t], topSlot :: nt}
  deriving (Show)

mapBlockAnn :: (a -> b) -> Block a nt t -> Block b nt t
mapBlockAnn f (Block a b c) = Block (f a) b c

{- |  a block with exact dimension (merge consecutive terminals (Right{}))
left is hole width, right is surface segment width
-}
type RigidBlock l ann nt t = Block ((l, l), ann) (l, nt) (l, t)

{- |
>>> corners $ Block (0,"f") [Vacant (6,"C"), Occupied (1,"C")] (0,"nt")
[(0,0),(0,1),(6,1),(6,1),(7,1),(7,0),(0,0)]
-}
corners :: forall a ann nt t. (Num a) => RigidBlock a ann nt t -> [(a, a)]
corners a@(Block ((hCap, hHole), ann) sizedRhs sizedLhs) = [(0, 0)] ++ hLines ++ [(totalWidth a, 0), (0, 0)]
 where
  hLines = concat $ evalState (mapM determineLine sizedRhs) 0
  determineLine :: Vacancy (a, nt) (a, t) -> State a [(a, a)]
  determineLine = \case
    Vacant (n, _) -> do
      x <- get -- current x-offset
      put (x + n)
      return $ horizontalLineAt hCap n x
    Occupied (n, _) -> do
      x <- get
      put (x + n)
      return $ horizontalLineAt (hCap + hHole) n x

  horizontalLineAt :: a -> a -> a -> [(a, a)]
  horizontalLineAt depth len x = [(x, depth), (x + len, depth)]

inset :: (Num a) => a -> [(a, a)] -> [(a, a)]
inset amount (p1 : p2 : ps) =
  concat
    [ [shiftRight (shiftDown p1), shiftRight p2]
    , nonChanging
    , [shiftLeft p_1, shiftLeft (shiftDown p_2), shiftRight (shiftDown p_3)]
    ]
 where
  nonChanging = init $ init $ init ps
  [p_1, p_2, p_3] = takeLast 3 ps
  shiftRight = first (+ amount)
  shiftLeft = first (\x -> x - amount)
  shiftDown = second (+ amount)
inset _ _ = error "[inset] nonexhaustive case"

totalWidth :: (Num a) => RigidBlock a ann nt t -> a
totalWidth (Block ann es _) = sum (fromVacancy <$> es)

totalHeight :: (Num a) => RigidBlock a ann nt t -> a
totalHeight (Block ((hCap, hHole), _) _ l) = hCap + hHole

fromVacancy :: Vacancy (l, a) (l, b) -> l
fromVacancy (Vacant (x, _)) = x
fromVacancy (Occupied (x, _)) = x

fromEither :: Either a a -> a
fromEither (Left x) = x
fromEither (Right x) = x

-- a block with exact location and exact shape
data PositionedBlock pos l ann nt t = PositionedBlock pos (RigidBlock l ann nt t)
  deriving (Show)

hsep :: forall l ann nt t. (Num l) => [RigidBlock l ann nt t] -> [PositionedBlock (l, l) l ann nt t]
hsep bs = runReader (mapM addOffSet bs) (0, 0)
 where
  addOffSet :: RigidBlock l ann nt t -> Reader (l, l) (PositionedBlock (l, l) l ann nt t)
  addOffSet b = do
    pos <- ask
    local (\(x, y) -> (x + totalWidth b, y)) $ return $ PositionedBlock pos b

fillVacantWith :: (a -> nt -> b) -> (t -> b) -> [Vacancy nt t] -> [a] -> [b]
fillVacantWith f g vs xs
  | length xs /= length (filter isVacant vs) = error "[assignLength] arity mismatch"
  | otherwise = case vs of
      [] -> []
      Occupied t : vs' -> g t : fillVacantWith f g vs' xs
      Vacant nt : vs' -> f (head xs) nt : fillVacantWith f g vs' (tail xs)

assignLength :: (Num l) => [Vacancy nt t] -> [RigidBlock l ann nt t] -> [Vacancy (l, nt) (l, t)]
assignLength =
  fillVacantWith
    (\b nt -> Vacant (totalWidth b, nt))
    (\t -> Occupied (1, t))

{- |
>>> toDefaultRigid id f9
RigidBlock (Block {annotation = "f9", vacancies = [Vacant "someNT",Occupied (),Occupied (),Occupied (),Occupied (),Occupied ()], topSlot = "someNT"}) [Left 1,Right 1,Right 1,Right 1,Right 1,Right 1] 1
-}
toDefaultRigid ::
  (Num l) =>
  -- | capHeight
  l ->
  (Block a nt t -> ann) ->
  Block a nt t ->
  RigidBlock l ann nt t
toDefaultRigid hCap f b =
  Block
    ((hCap, 1), f b)
    ((\case Vacant nt -> Vacant (1, nt); Occupied t -> Occupied (1, t)) <$> vacancies b)
    (1, topSlot b)

{- |
calculates the dimensions of blocks in a tree based on the tree structure
- the total width of a block is the sum of widths of its gaps and the sum of the widths of its terminals (all of size 1)
- the height of a block's hole is the largest combined height of its child block
- the height of a block's cap is
    (for leaf blocks) its distance to max depth
    (for node blocks) always 1
-}
render ::
  forall a nt t l ann.
  (Num l, Ord l) =>
  (Block a nt t -> ann) ->
  Tree (Block a nt t) ->
  Tree (RigidBlock l ann nt t)
render f t = runReader (cata go t) 0
 where
  maxDepth = depth t

  go :: TreeF (Block a nt t) _ -> Reader l _
  go = \case
    NodeF b [] -> do
      currentDepth <- ask
      return $
        Node
          (toDefaultRigid (maxDepth - currentDepth) f b)
          []
    NodeF b ts -> do
      ts' <- mapM (local (+ 1)) ts
      let childBlocks = rootLabel <$> ts'
      let h = maximum $ totalHeight <$> childBlocks
          sizedRHS = assignLength (vacancies b) childBlocks
          w = sum $ (\case Vacant (l, _) -> l; Occupied (l, _) -> l) <$> sizedRHS
      return $
        Node
          { rootLabel =
              Block
                ((1, h), f b)
                sizedRHS
                (w, topSlot b)
          , subForest = ts'
          }

depth :: (Num l, Ord l) => Tree a -> l
depth = cata $ \case
  NodeF _ [] -> 0
  NodeF _ ds -> 1 + maximum ds

{- |
>>> addPosition $ render annotation $ ex2
Node {rootLabel = ((0,0),Block {annotation = (4,"Prol"), vacancies = [Vacant (11,""),Vacant (11,"")], topSlot = (22,"Root")}), subForest = [Node {rootLabel = ((0,1),Block {annotation = (3,"f9"), vacancies = [Vacant (6,"Am7"),Occupied (1,"C7"),Occupied (1,"F^7"),Occupied (1,"B%7"),Occupied (1,"E7"),Occupied (1,"Am7")], topSlot = (11,"Am7")}), subForest = [Node {rootLabel = ((0,2),Block {annotation = (2,"f9"), vacancies = [Vacant (1,"Am7"),Occupied (1,"C7"),Occupied (1,"F^7"),Occupied (1,"B%7"),Occupied (1,"E7"),Occupied (1,"Am7")], topSlot = (6,"Am7")}), subForest = [Node {rootLabel = ((0,3),Block {annotation = (1,"T"), vacancies = [Occupied (1,"Am7")], topSlot = (1,"Am7")}), subForest = []}]}]},Node {rootLabel = ((11,1),Block {annotation = (3,"f9"), vacancies = [Vacant (6,"Am7"),Occupied (1,"C7"),Occupied (1,"F^7"),Occupied (1,"B%7"),Occupied (1,"E7"),Occupied (1,"Am7")], topSlot = (11,"Am7")}), subForest = [Node {rootLabel = ((11,2),Block {annotation = (2,"f9"), vacancies = [Vacant (1,"Am7"),Occupied (1,"C7"),Occupied (1,"F^7"),Occupied (1,"B%7"),Occupied (1,"E7"),Occupied (1,"Am7")], topSlot = (6,"Am7")}), subForest = [Node {rootLabel = ((11,3),Block {annotation = (1,"T"), vacancies = [Occupied (1,"Am7")], topSlot = (1,"Am7")}), subForest = []}]}]}]}
-}
addPosition :: (Num l) => Tree (RigidBlock l ann nt t) -> Tree ((l, l), RigidBlock l ann nt t)
addPosition = flip runReader (0, 0) . cata go
 where
  go (NodeF b actions) = do
    (widths :: [l]) <- fmap (totalWidth . snd . rootLabel) <$> sequence actions
    -- calculates where to put child blocks
    let markedOffSets :: [Vacancy l l] =
          fillVacantWith
            (\l nt -> Vacant l)
            (\t -> Occupied 1)
            (vacancies b)
            widths
    let xOffSets :: [l] = takeVacant $ assignOffSets markedOffSets
    rs <-
      zipWithM
        (\a dx -> local (\(x, y) -> (x + dx, y + 1)) a)
        actions
        xOffSets
    (x, y) <- ask
    return (Node ((x, y), b) rs)

offSets :: (Num l) => [l] -> [l]
offSets = init . scanl (+) 0

assignOffSets :: (Num l) => [Vacancy l l] -> [Vacancy l l]
assignOffSets vs = zipWith go vs xs
 where
  xs = offSets $ (\case Occupied x -> x; Vacant x -> x) <$> vs
  go (Occupied _) x = Occupied x
  go (Vacant _) x = Vacant x

takeVacant :: [Vacancy nt t] -> [nt]
takeVacant [] = []
takeVacant (Vacant nt : vs) = nt : takeVacant vs
takeVacant (Occupied _ : vs) = takeVacant vs

type Color = String

excalidrawBlock ::
  forall l.
  (ToJSON l, _) =>
  -- | offset
  (l, l) ->
  -- | shape tracing points
  [(l, l)] ->
  -- | color (same pattern has same color)
  Color ->
  -- | text width
  l ->
  -- | top NT (LHS of prod rule)
  String ->
  -- | operation text
  String ->
  [((l, l), String)] -> --  ^ bottom symbols
  [Value]
excalidrawBlock (x, y) ps c w s op rhs =
  [ Object $
      fromList
        [ ("points", toJSON $ inset d ps)
        , ("type", toJSON @String "line")
        , ("x", toJSON x)
        , ("y", toJSON y)
        , ("strokeColor", toJSON c)
        , ("scale", toJSON @Int 100)
        , ("fillStyle", toJSON @String "cross-hatch")
        , ("opacity", "50")
        , ("backgroundColor", toJSON c)
        , ("roughness", toJSON @Int 0)
        ]
  -- , Object $
  --     fromList
  --       [ ("type", "rectangle")
  --       , ("width", toJSON boxWidth)
  --       , ("height", toJSON h)
  --       , ("fillStyle", "solid")
  --       , ("stroke", toJSON 2)
  --       , ("backgroundColor", "white")
  --       , ("x", toJSON $ x + toptextX - 0.5 * boxWidth)
  --       , ("y", toJSON $ y - 0.5 * (h - d))
  --       , ("strokeColor", "brown")
  --       , ("roundness", Object (fromList [("type", toJSON 2)]))
  --       ]
  -- , ntText s
  , opText op
  ]
    -- ++ botTexts
 where
  toptextX = average $ fst <$> takeLast 2 ps
  average xs = sum xs / fromIntegral (length xs)
  boxWidth = w - 2 * d
  h = 0.5 * w
  d = 10 -- inset amount
  opText = textAt (x + toptextX - 0.5 * w, y + h)
  ntText = textAt (x + toptextX - 0.5 * w, y - 0.5 * (h - d))
  botTexts = (\((_x, _y), s) -> textAt (_x, _y - d) s) <$> rhs
  textAt :: (l, l) -> String -> Value
  textAt (_x, _y) _op =
    Object $
      fromList
        [ ("type", "text")
        , ("width", toJSON w)
        , ("height", toJSON h)
        , ("fillStyle", "solid")
        , ("strokeWidth", toJSON @Int 2)
        , ("backgroundColor", "transparent")
        , ("x", toJSON _x)
        , ("y", toJSON _y)
        , ("text", toJSON _op)
        , ("fontSize", toJSON @Int 10)
        , ("fontFamily", toJSON @Int 5)
        , ("textAlign", "center")
        , ("strokeColor", "brown")
        , ("strokeStyle", "solid")
        ]

{- |
>>> takeLast 2 [1,2,3,4,5]
[4,5]
-}
takeLast :: Int -> [a] -> [a]
takeLast n xs = drop (length xs - n) xs

canvas :: [Value] -> Value
canvas xs =
  Object $
    fromList
      [ ("type", toJSON @String "excalidraw")
      , ("version", toJSON @Int 2)
      , ("elements", toJSON xs)
      ]

scale :: (Num l) => l -> (l, l) -> (l, l)
scale n (x, y) = (n * x, n * y)

plotBlock :: (Show t) => Tree (Block String String t) -> Value
plotBlock x =
  plotBlock'
    (\flex -> colors Map.! annotation flex)
    topSlot
    annotation
    id
    (100 :: Double)
    x
 where
  palette = ["gray", "teal", "green", "orange", "purple", "red", "brown", "lime"]
  colors = Map.fromList $ zip names $ cycle palette
  names = nub $ foldr (\a b -> annotation a : b) [] x

plotBlock' ::
  forall ann a nt t l.
  (Show nt, Show t, Num l, ToJSON l, Fractional l, Ord l) =>
  (ann -> Color) ->
  (ann -> String) ->
  (ann -> String) ->
  (Block a nt t -> ann) ->
  -- | terminal width
  l ->
  Tree (Block a nt t) ->
  Value
plotBlock' =  gPlotBlock (canvas . foldMap id) renderRigidInExcalidraw
  -- canvas
  --   . foldMap id
  --   . para @(Tree ((l, l), RigidBlock l ann nt t)) @(Tree [Value])
  --     ( \(NodeF (pos, b) rs) ->
  --         Node
  --           { rootLabel =
  --               renderRigidInExcalidraw
  --                 getColor
  --                 getTopNT
  --                 getOp
  --                 terminalWidth
  --                 pos
  --                 b
  --           , subForest = snd <$> rs
  --           }
  --     )
  --   . addPosition
  --   . render f

-- plotBlockAsHTML = gPlotBlock (HTML.div . foldMap id) renderRigidInHTML

gPlotBlock ::
  forall b r ann a nt t l.
  (_) =>
  (Tree b -> r) ->
  ( (ann -> Color) ->
    (ann -> String) ->
    (ann -> String) ->
    l ->
    (l, l) ->
    RigidBlock l ann nt t ->
    b
  ) ->
  (ann -> Color) ->
  (ann -> String) ->
  (ann -> String) ->
  (Block a nt t -> ann) ->
  l ->
  Tree (Block a nt t) ->
  r
gPlotBlock combine renderRigid getColor getTopNT getOp getAnn terminalWidth =
  combine
    . para @(Tree ((l, l), RigidBlock l ann nt t)) @(Tree b)
      ( \(NodeF (pos, b) rs) ->
          Node
            { rootLabel =
                renderRigid
                  getColor
                  getTopNT
                  getOp
                  terminalWidth
                  pos
                  b
            , subForest = snd <$> rs
            }
      )
    . addPosition
    . render getAnn

renderRigidInExcalidraw ::
  (_) =>
  (ann -> Color) ->
  (ann -> String) ->
  (ann -> String) ->
  l ->
  (l, l) ->
  RigidBlock l ann nt t ->
  [Value]
renderRigidInExcalidraw c nt op terminalWidth _pos@(x, y) _b@(Block ((hCap, hHole), ann) sizedRhs sizedLHS) =
  excalidrawBlock
    (scale terminalWidth _pos)
    (scale terminalWidth <$> corners _b)
    (c ann)
    terminalWidth
    (nt ann)
    (op ann)
    positionedRHS
 where
  positionedRHS = flip evalState x $ forM sizedRhs $ \case
    Vacant (dx, nt) -> do
      xOffSet <- get
      modify (+ dx)
      return (scale terminalWidth (xOffSet, y + hCap), show nt)
    Occupied (dx, t) -> do
      xOffSet <- get
      modify (+ dx)
      return (scale terminalWidth (xOffSet, y + hHole), show t)



-- converting template to Tree (Blocks)

prodRuleToBlock :: a -> nt -> [Vacancy nt t] -> Block a nt t
prodRuleToBlock name lhs rhs =
  Block{annotation = name, vacancies = rhs, topSlot = lhs}

treeToTreeOfBlock :: Tree a -> Tree (Block a () ())
treeToTreeOfBlock = cata $ \case
  NodeF x [] -> Node (Block x [Occupied ()] ()) []
  NodeF x ts ->
    Node
      (Block x (Vacant () <$ ts) ())
      ts

plotTree :: forall a. (a -> String) -> Tree a -> Value
plotTree f = plotBlock . fmap formatBlock . treeToTreeOfBlock
 where
  formatBlock :: Block a () () -> Block String String String
  formatBlock (Block x vs _) = Block (f x) (vacancyToString <$> vs) ""

  vacancyToString (Vacant _) = Vacant ""
  vacancyToString (Occupied _) = Occupied ""

-- fmap templateToBlock . templateToTree toProdRule

-- examples

f9 :: nt -> [Vacancy nt t] -> Block String nt t
f9 lhs rhs =
  Block
    { annotation = "f9"
    , vacancies = rhs
    , topSlot = lhs
    }

terminalBlock :: nt -> t -> Tree (Block String nt t)
terminalBlock nt t = Node (Block "T" [Occupied t] nt) []

sittingOn :: a -> [Tree a] -> Tree a
sittingOn = Node

ex1 :: Tree (Block String String String)
ex1 = f `sittingOn` [f `sittingOn` [terminalBlock "Am7" "Am7"]]
 where
  f =
    f9
      "Am7"
      [ Vacant "Am7"
      , Occupied "C7"
      , Occupied "F^7"
      , Occupied "B%7"
      , Occupied "E7"
      , Occupied "Am7"
      ]
ex2 =
  Block
    { annotation = "Prol"
    , vacancies = [Vacant "", Vacant ""]
    , topSlot = "Root"
    }
    `sittingOn` [ex1, ex1]

test = encodeFile "testLego.excalidraw" $ plotBlock ex2

-- >>> main
-- "DONE"
