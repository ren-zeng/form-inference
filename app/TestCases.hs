{-#LANGUAGE OverloadedStrings #-}
{-#LANGUAGE OverloadedLists #-}
module TestCases where

import Form
import Data.List.NonEmpty (NonEmpty)


testCases :: [(String, NonEmpty FormalUnit)]
testCases =
    [ 
    --     ("ex1", firstHalf ++ secondHalf)
    -- , ("first", firstHalf)
    -- , ("second", secondHalf)
     ("ex6_1", ex6_1)
    ]  where
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
    ex6_1 =
        [ leaf "a" [I, V] None
        , leaf "b" [I, V, I, V] Weak
        , leaf "c" [IV, V, I] None
        , leaf "d" [VI, VII, I, V] Weak
        , leaf "a" [I,V] None
        , leaf "b" [I, V, I, V] Weak
        , leaf "c" [V] None
        , leaf "e" [I] Strong
        ]

leaf :: Idea -> [Harmony] -> CadenceStrength -> FormalUnit
leaf s hs cad = Leaf s (Param hs cad)