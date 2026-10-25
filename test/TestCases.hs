{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}

module TestCases where

import Data.List.NonEmpty (NonEmpty)
import qualified Data.List.NonEmpty as NonEmpty
import Form

testCases :: [(String, NonEmpty FormalUnit)]
testCases =
    [ --     ("ex1", firstHalf ++ secondHalf)
      -- , ("first", firstHalf)
      -- , ("second", secondHalf)
      ("ex2_11", ex2_11)
    , ("ex2_12", ex2_12)
    , ("ex6_1", ex6_1)
    , ("ex6_2", ex6_2)
    , ("ex6_5", ex6_5)
    , ("bwv1008_04_Sarabande", bwv1008_04_Sarabande)
    , ("haydn_sonata_XVI_07_C_2_menuet", haydn_sonata_XVI_07_C_2_menuet)
    ]

-- firstHalf =
--     [ Leaf "a" (Param [I] None)
--     , Leaf "a" (Param [VI] None)
--     , Leaf "a" (Param [II] None)
--     , Leaf "a" (Param [IV] None)
--     , Leaf "b" (Param [V] None)
--     , Leaf "c" (Param [VI] None)
--     , Leaf "d" (Param [II] None)
--     , Leaf "e" (Param [V] Weak)
--     ]
-- secondHalf =
--     [ Leaf "a" (Param [I] None)
--     , Leaf "a" (Param [I] None)
--     , Leaf "a" (Param [VI] None)
--     , Leaf "a" (Param [VI] None)
--     , Leaf "x" (Param [II] None)
--     , Leaf "y" (Param [II] None)
--     , Leaf "z" (Param [V] None)
--     , Leaf "w" (Param [I] Strong)
-- ]



ex6_1 :: NonEmpty FormalUnit
ex6_1 =
    [ leaf "a" [I, V] None
    , leaf "b" [I, V, I, V] Weak
    , leaf "c" [IV, V, I] None
    , leaf "d" [VI, VII, I, V] Weak
    , leaf "a" [I, V] None
    , leaf "b" [I, V, I, V] Weak
    , leaf "c" [V] None
    , leaf "e" [I] Strong
    ]

ex6_2 :: NonEmpty FormalUnit
ex6_2 =
    [ leaf "a" [I] None
    , leaf "b" [I] None
    , leaf "c" [I] None
    , leaf "a" [V] None
    , leaf "b" [V] None
    , leaf "c" [V] None
    , leaf "b" [I, VI] None
    , leaf "b" [IV, II] None
    , leaf "b" [V] None
    , leaf "d" [I, II, V, I] Strong
    ]

ex6_5 :: NonEmpty FormalUnit
ex6_5 =
    [ leaf "a" [I, V] None
    , leaf "a" [V, I] None
    , leaf "b" [IV, I] None
    , leaf "b" [IV, I] None
    , leaf "c" [II] None
    , leaf "c" [I] None
    , leaf "d" [V] Weak
    , leaf "a" [I, V] None
    , leaf "a" [V, I] None
    , leaf "b" [IV, I] None
    , leaf "b" [IV, I] None
    , leaf "c" [II] None
    , leaf "c" [I] None
    , leaf "e" [V, I] Strong
    ]

ex2_11 :: NonEmpty FormalUnit
ex2_11 =
    [ leaf "a" [I] None
    , leaf "a" [IV] None
    ]

ex2_12 :: NonEmpty FormalUnit
ex2_12 =
    [ leaf "a" [I, V] None
    , leaf "b" [I, III] None
    , leaf "a" [VI, II] None
    , leaf "b" [VI, III] None
    ]

bwv1008_04_Sarabande :: NonEmpty FormalUnit
bwv1008_04_Sarabande =
    NonEmpty.fromList $
        mconcat
            [ nCopies
                2
                [ leaf "A" placeHolderH None
                , leaf "B" placeHolderH None
                , leaf "C" placeHolderH None
                , leaf "D" placeHolderH Weak
                , leaf "A" placeHolderH None
                , leaf "B" placeHolderH None
                , leaf "E" placeHolderH None
                , leaf "D" placeHolderH Weak
                , leaf "A'" placeHolderH None
                , leaf "A'" placeHolderH None
                , leaf "F" placeHolderH None
                , leaf "G" placeHolderH Strong
                ]
            , nCopies
                2
                [ leaf "H" placeHolderH None
                , leaf "I" placeHolderH None
                , leaf "J" placeHolderH None
                , leaf "B" placeHolderH Weak
                , leaf "K" placeHolderH None
                , leaf "K" placeHolderH None
                , leaf "L" placeHolderH None
                , leaf "M" placeHolderH Weak
                , leaf "A'" placeHolderH None
                , leaf "A'" placeHolderH None
                , leaf "N" placeHolderH None
                , leaf "G'" placeHolderH Strong
                , leaf "H'" placeHolderH None
                , leaf "H'" placeHolderH None
                , leaf "F" placeHolderH None
                , leaf "G" placeHolderH Strong
                ]
            ]

haydn_sonata_XVI_07_C_2_menuet :: NonEmpty FormalUnit
haydn_sonata_XVI_07_C_2_menuet =
    NonEmpty.fromList $
        mconcat
            [ menuet
            , trio
            , menuet
            ]
  where
    menuet =
        mconcat
            [ nCopies
                2
                [ leaf "a" [I] None
                , leaf "a" [V] None
                , leaf "a" [I] None
                , leaf "b" [V] Weak
                , leaf "c" [I] None
                , leaf "c" [I] None
                , leaf "d" [I] None
                , leaf "e" [I] Strong
                ]
            , nCopies
                2
                [ leaf "a" [I] None
                , leaf "a" [V] None
                , leaf "f" [V] None
                , leaf "b" [V] Weak
                , leaf "c" [I] None
                , leaf "c" [I] None
                , leaf "d" [V] None
                , leaf "e" [I] Strong
                ]
            ]
    trio =
        mconcat
            [ nCopies 2 trioA
            , nCopies 2 $ trioB ++ trioA
            ]
    trioA =
        [ leaf "g" [I] None
        , leaf "h" [I] None
        , leaf "g" [V] None
        , leaf "h" [V] None
        , leaf "g" [I] None
        , leaf "h" [IV] None
        , leaf "i" [V] None
        , leaf "j" [I] Strong
        ]
    trioB =
        [ leaf "g" [I] None
        , leaf "k" [IV] None
        , leaf "g" [II] None
        , leaf "k" [V] None
        ]

nCopies :: Int -> [a] -> [a]
nCopies n = concat . replicate n

placeHolderH :: [Harmony]
placeHolderH = [I]

-- >>> NonEmpty.toList haydn_sonata_XVI_07_C_2_menuet

