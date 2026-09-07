{-# LANGUAGE ExplicitForAll #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE UnicodeSyntax #-}

module Scratch (encodeSeq,enumSegmentation,bestSegmentation) where

import Control.Monad
import Data.Foldable (minimumBy, maximumBy)
import Data.Function
import qualified Data.List.NonEmpty as NonEmpty
import  Data.List.NonEmpty (NonEmpty)
import Data.Ord
import Prettyprinter (Pretty (pretty))
import Relude.Extra
import qualified Data.IntMap.Strict as IntMap 
import Data.IntMap.Strict (IntMap)
import Data.List (intersect)
import Data.Semigroup (diff)
import qualified Data.Set as Set

{-|

>>> bestSegment exactMatch $ concat $ replicate 3 [1,2,3]
[[1,2,3,1,2,3,1,2,3]]

>>> replicate 3 [1,2,3] `elem` (enumSegmentation $ concat $ replicate 3 [1,2,3])
True

>>> ssm exactMatch $ replicate 3 [1,2,3]
[[0,0,0],[0,0,0],[0,0,0]]


>>> bestSegment exactMatch piece
[[1,2,3,1,2,3,5,4,3,2,1]]

>>> ssm exactMatch $ bestSegment exactMatch piece
[[0]]


-}
bestSegment :: forall a b. (Fractional b, Ord b) => ([a] -> [a] -> b) -> [a] -> [[a]]
bestSegment f = minimumBy (comparing (matrixScore . ssm f)) . enumSegmentation

piece = [1,2,3,1,2,3,5,4,3,2,1]

exactMatch x y = if x == y then 0 else 1


{- |
>>> enumSegmentation [1..5]
[[[1,2,3,4,5]],[[1,2,3,4],[5]],[[1,2,3],[4,5]],[[1,2,3],[4],[5]],[[1,2],[3,4,5]],[[1,2],[3,4],[5]],[[1,2],[3],[4,5]],[[1,2],[3],[4],[5]],[[1],[2,3,4,5]],[[1],[2,3,4],[5]],[[1],[2,3],[4,5]],[[1],[2,3],[4],[5]],[[1],[2],[3,4,5]],[[1],[2],[3,4],[5]],[[1],[2],[3],[4,5]],[[1],[2],[3],[4],[5]]]

-}
enumSegmentation :: [a] -> [[[a]]]
enumSegmentation xs = (applyBoundary <$> boundaries) <*> pure xs
 where
  boundaries = replicateM (length xs - 1) [False, True]

{- |


>>> applyBoundary [True,False,True,False] [1,2,3,4,5]
[[1],[2,3],[4,5]]

-}
applyBoundary :: [Bool] -> [a] -> [[a]]
applyBoundary bs xs = go [] [] bs xs
 where
  go :: [[a]] -> [a] -> [Bool] -> [a] -> [[a]]
  go segs temp [] [x] = segs ++ [temp ++ [x]]
  go segs temp (b : bs) remain = case b of
    True -> go (segs ++ [temp ++ l']) [] bs r'
    False -> go segs (temp ++ l') bs r'
   where
    (l', r') = splitAt 1 remain

-- >>> splits [1,2,3]
-- [([],[1,2,3]),([1],[2,3]),([1,2],[3]),([1,2,3],[])]

splits :: [a] -> [([a], [a])]
splits xs = do
  i <- [0 .. length xs]
  let init = take i xs
  let remain = drop i xs
  return (init, remain)

matrixScore :: Fractional b => [[b]] -> b
matrixScore segs = (/ (n*n)) $ sum $ g <$> segs
  where
    n = fromIntegral $ length segs 
    g = sum

{- | self-similarity matrix of a list based on a given binary function

>>> pretty $ ssm (\ x y -> if x == y then "1" else "-") [1,2,3,1,2,3,3,4,3,2,1]
[ [1, -, -, 1, -, -, -, -, -, -, 1]
, [-, 1, -, -, 1, -, -, -, -, 1, -]
, [-, -, 1, -, -, 1, 1, -, 1, -, -]
, [1, -, -, 1, -, -, -, -, -, -, 1]
, [-, 1, -, -, 1, -, -, -, -, 1, -]
, [-, -, 1, -, -, 1, 1, -, 1, -, -]
, [-, -, 1, -, -, 1, 1, -, 1, -, -]
, [-, -, -, -, -, -, -, 1, -, -, -]
, [-, -, 1, -, -, 1, 1, -, 1, -, -]
, [-, 1, -, -, 1, -, -, -, -, 1, -]
, [1, -, -, 1, -, -, -, -, -, -, 1] ]
-}
ssm :: (a -> a -> b) -> [a] -> [[b]]
ssm f xs = (\x -> f x <$> xs) <$> xs


data SegRep a w = Raw a w | VarOf Int w
  deriving Show
data Encode a w = WithStored (IntMap a) [SegRep a w] [a]
  deriving Show

getCost :: SegRep a w -> w
getCost (Raw _ w) = w
getCost (VarOf _ w) = w

{- | Compute how a list is elementwise encoded using either the element itself or referencing previous element, given the corresponding cost functions for raw encode and referencing. 

== example

suppose we want the encode a list of string, which can be think of as a segmentation of a larger string.

suppose the cost for encoding a string y as a variation of x is the number of non-shared characters in both strings

>>> dist "abc" "caef"
3.0

and the cost for raw encoding of a string is just its length

>>> length "yyyu"
4

then for the segmentation ["abc","acd","d","ef"], its encoding is

>>> encodeSeq (fromIntegral . length) dist  ["abc","acd","d","ef"]
WithStored (fromList [(0,"acd")]) [Raw "abc" 3.0,VarOf 0 2.0,Raw "d" 1.0,Raw "ef" 2.0] ["abc","acd","d","ef"]

the total cost of the encoding is 

>>> encodingCost $ encodeSeq (fromIntegral . length) dist  ["abc","acd","d","ef"]
8.0

-}
encodeSeq :: (Ord b) => (a -> b) -> (a -> a -> b) -> [a] -> Encode a b
encodeSeq rawCost varCost  = foldl' go (WithStored mempty [] [])  
  where 
  go (WithStored mem encoded seen) x = 
    
    if length seen > 0 && refCost < rawCost x
      then WithStored 
        (IntMap.insert ref x mem) 
        (encoded ++ [VarOf ref refCost]) 
        (seen ++ [x])
        
      else WithStored 
        mem 
        (encoded ++ [Raw x (rawCost x)])
        (seen ++ [x])
    where 
        varCosts = zip [0..] (varCost x <$> seen) 
        (ref,refCost) = minimumBy (comparing snd) varCosts

encodingCost :: Num b => Encode a b -> b
encodingCost (WithStored _ encoded _)= sum $  getCost <$> encoded

{-
>>> commonCharsRatio "abcd" "acef"
0.5
-}
dist :: Ord a => [a] -> [a] -> Double
dist xs ys = fromIntegral 
  (Set.size $ Set.symmetricDifference (Set.fromList xs) (Set.fromList ys) ) 


dist2 :: [a] -> [a] -> Double
dist2 xs ys = fromIntegral $ abs (length xs - length ys) 


{-

>>> bestSegmentation (fromIntegral . length) (\x y -> 1 + editDist x y) piece
[[1,2,3],[1,2,3,5,4,3,2,1]]

>>> encodeSeq (fromIntegral . length) (\x y -> 1 + editDist x y) [[1,2,3],[1,2,3,5,4,3,2,1]]
WithStored (fromList [(0,[1,2,3,5,4,3,2,1])]) [Raw [1,2,3] 3,VarOf 0 6] [[1,2,3],[1,2,3,5,4,3,2,1]]
-}
bestSegmentation :: (Ord b, Num b) => ([a] -> b) -> ([a] -> [a] -> b) -> [a] -> [[a]]
bestSegmentation rawCost varCost = minimumBy (comparing $ encodingCost . encodeSeq rawCost varCost) . enumSegmentation

twinkle = [1,5,6,5,4,3,2,1,5,4,3,2,5,4,3,2,1,5,6,5,4,3,2,1]


editDist :: Eq a => [a] -> [a] -> Int
editDist a b 
    = last (if lab == 0 then mainDiag
	    else if lab > 0 then lowers !! (lab - 1)
		 else{- < 0 -}   uppers !! (-1 - lab))
    where mainDiag = oneDiag a b (head uppers) (-1 : head lowers)
	  uppers = eachDiag a b (mainDiag : uppers) -- upper diagonals
	  lowers = eachDiag b a (mainDiag : lowers) -- lower diagonals
	  eachDiag a [] diags = []
	  eachDiag a (bch:bs) (lastDiag:diags) = oneDiag a bs nextDiag lastDiag : eachDiag a bs diags
	      where nextDiag = head (tail diags)
	  oneDiag a b diagAbove diagBelow = thisdiag
	      where doDiag [] b nw n w = []
		    doDiag a [] nw n w = []
		    doDiag (ach:as) (bch:bs) nw n w = me : (doDiag as bs me (tail n) (tail w))
			where me = if ach == bch then nw else 1 + min3 (head w) nw (head n)
		    firstelt = 1 + head diagBelow
		    thisdiag = firstelt : doDiag a b firstelt diagAbove (tail diagBelow)
	  lab = length a - length b
          min3 x y z = if x < y then x else min y z
