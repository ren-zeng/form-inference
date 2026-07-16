{-# LANGUAGE OverloadedLists #-}
{-# LANGUAGE OverloadedStrings #-}

module TestCases where

import Data.List.NonEmpty (NonEmpty)
import Form

testCases :: [(String, NonEmpty FormalUnit)]
testCases =
    [ --     ("ex1", firstHalf ++ secondHalf)
      -- , ("first", firstHalf)
      -- , ("second", secondHalf)
      ("ex2_11",ex2_11)
      , ("ex2_12",ex2_12)
      ,("ex6_1", ex6_1)
      , ("ex6_2",ex6_2)
      , ("ex6_5",ex6_5)
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

leaf :: Idea -> [Harmony] -> CadenceStrength -> FormalUnit
leaf s hs cad = Leaf s (Param hs cad)

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
    , leaf "b" [I,VI] None
    , leaf "b" [IV,II] None
    , leaf "b" [V] None
    , leaf "d" [I, II, V, I] Strong
    ]

ex6_5 :: NonEmpty FormalUnit
ex6_5 = 
    [ leaf "a" [I,V] None 
    , leaf "a" [V,I] None
    , leaf "b" [IV,I] None
    , leaf "b" [IV,I] None 
    , leaf "c" [II] None 
    , leaf "c" [I] None 
    , leaf "d" [V] Weak
    -- , leaf "a" [I,V] None 
    -- , leaf "a" [V,I] None 
    -- , leaf "b" [IV,I] None
    -- , leaf "b" [IV,I] None 
    -- , leaf "c" [II] None 
    -- , leaf "c" [I] None 
    -- , leaf "e" [VII,V,I] Strong
    ]

ex2_11 :: NonEmpty FormalUnit
ex2_11 = [
  leaf "a" [I] None,
  leaf "a" [IV] None
  ]


ex2_12 :: NonEmpty FormalUnit
ex2_12 = [
  leaf "a" [I,V] None,
  leaf "b" [I,III] None,
  leaf "a" [VI,II] None,
  leaf "b" [VI,III] None
  ]