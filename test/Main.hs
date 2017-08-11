{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import Boltzmann.Data
import Data.Data
import Debug.Trace
import Test.Hspec
import Test.Hspec.QuickCheck
import Test.QuickCheck
import Text.Show.Pretty

import Regex

instance (Data a, Arbitrary a) => Arbitrary (Reg a) where
  arbitrary = sized $ generatorPWith [positiveInts]

positiveInts :: Alias Gen
positiveInts = alias $ \() -> fmap getPositive arbitrary :: Gen Int

-- instance Arbitrary a => Arbitrary (Reg a) where
--   arbitrary =
--     oneof [ Union <$> (resize 1 arbitrary) <*> (resize 1 arbitrary)
--           , Cat <$> (resize 1 arbitrary) <*> (resize 1 arbitrary)
--           , Rep <$> (resize 1 arbitrary)
--           , Lit <$> arbitrary
--           ]

main :: IO ()
main =
  hspec $ do
    describe "regex-fsm tests" $ do
      it "Should successfully simulate (a|b) on an ENFA" $ do
        let Right regex = parseRegex "(a|b)"
        simulateENFA "a" (thompsons regex) `shouldBe` True
        simulateENFA "b" (thompsons regex) `shouldBe` True
        simulateENFA "c" (thompsons regex) `shouldBe` False
        simulateENFA "" (thompsons regex) `shouldBe` False
      it "Should successfully simulate (a*b) on an ENFA" $ do
        let Right regex = parseRegex "(a*b)"
        simulateENFA "" (thompsons regex) `shouldBe` False
        simulateENFA "b" (thompsons regex) `shouldBe` True
        simulateENFA "ab" (thompsons regex) `shouldBe` True
        simulateENFA "bb" (thompsons regex) `shouldBe` False
        simulateENFA "aaaaab" (thompsons regex) `shouldBe` True
      it "Should successfully simulate (a*|b*) on an ENFA" $ do
        let Right regex = parseRegex "(a*|b*)"
        simulateENFA "" (thompsons regex) `shouldBe` True
        simulateENFA "ab" (thompsons regex) `shouldBe` False
        simulateENFA "a" (thompsons regex) `shouldBe` True
        simulateENFA "b" (thompsons regex) `shouldBe` True
        simulateENFA (replicate 100 'a') (thompsons regex) `shouldBe` True
        simulateENFA (replicate 100 'b') (thompsons regex) `shouldBe` True

      it "Should successfully simulate (a|b) on a DFA" $ do
        let Right regex = parseRegex "(a|b)"
            dfa = subset (thompsons regex)
        simulateDFA "a" dfa `shouldBe` True
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA "c" dfa `shouldBe` False
        simulateDFA "" dfa `shouldBe` False
      it "Should successfully simulate (a*b) on a DFA" $ do
        let Right regex = parseRegex "(a*b)"
            dfa = subset (thompsons regex)
        simulateDFA "" dfa `shouldBe` False
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA "ab" dfa `shouldBe` True
        simulateDFA "bb" dfa `shouldBe` False
        simulateDFA "aaaaab" dfa `shouldBe` True
      it "Should successfully simulate (a*|b*) on a DFA" $ do
        let Right regex = parseRegex "(a*|b*)"
            dfa = subset (thompsons regex)
        simulateDFA "" dfa `shouldBe` True
        simulateDFA "ab" dfa `shouldBe` False
        simulateDFA "a" dfa `shouldBe` True
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA (replicate 100 'a') dfa `shouldBe` True
        simulateDFA (replicate 100 'b') dfa `shouldBe` True

      it "Should successfully simulate (a|b) on a minimized DFA" $ do
        let Right regex = parseRegex "(a|b)"
            dfa = minimize $ subset (thompsons regex)
        simulateDFA "a" dfa `shouldBe` True
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA "c" dfa `shouldBe` False
        simulateDFA "" dfa `shouldBe` False
      it "Should successfully simulate (a*b) on a minimized DFA" $ do
        let Right regex = parseRegex "(a*b)"
            dfa = minimize $ subset (thompsons regex)
        simulateDFA "" dfa `shouldBe` False
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA "ab" dfa `shouldBe` True
        simulateDFA "bb" dfa `shouldBe` False
        simulateDFA "aaaaab" dfa `shouldBe` True
      it "Should successfully simulate (a*|b*) on a minimized DFA" $ do
        let Right regex = parseRegex "(a*|b*)"
            dfa = minimize $ subset (thompsons regex)
        simulateDFA "" dfa `shouldBe` True
        simulateDFA "ab" dfa `shouldBe` False
        simulateDFA "a" dfa `shouldBe` True
        simulateDFA "b" dfa `shouldBe` True
        simulateDFA (replicate 100 'a') dfa `shouldBe` True
        simulateDFA (replicate 100 'b') dfa `shouldBe` True

      -- it "Should produce the same simulated results on all regex" $ do
      --   property $ \((input:: String, regex :: Reg Char)) ->
      --     traceShow (input, regex) $ do
      --       let enfa = thompsons regex
      --           dfa = subset enfa
      --           mdfa = minimize dfa
      --           a = simulateENFA input enfa
      --           b = simulateDFA input dfa
      --           c = simulateDFA input mdfa
      --       traceShow (ppShow dfa) $ a == b `shouldBe` b == c

