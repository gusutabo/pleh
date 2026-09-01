-- Arbitrary Formula is an orphan: generating formulas is a testing concern.
{-# OPTIONS_GHC -Wno-orphans #-}

module Main (main) where

import Data.List (nub)
import Test.Hspec
import Test.Hspec.QuickCheck (prop)
import Test.QuickCheck (Arbitrary (..), elements, oneof, sized)
import Control.Exception (evaluate)
import Logic
import Parser (parseFormula)

-- Three variables at most, so no truth table exceeds eight rows.
instance Arbitrary Formula where
  arbitrary = sized gen
    where
      gen n
        | n <= 1 = variable
        | otherwise =
            oneof
              [ variable
              , Not <$> gen (n - 1)
              , binary And
              , binary Or
              , binary Imp
              , binary Iff
              ]
        where
          variable = Var <$> elements ["p", "q", "r"]
          binary con = con <$> gen (n `div` 2) <*> gen (n `div` 2)

  shrink (Var _) = []
  shrink (Not f) = f : map Not (shrink f)
  shrink (And f1 f2) = [f1, f2] ++ [And a b | (a, b) <- shrink (f1, f2)]
  shrink (Or f1 f2) = [f1, f2] ++ [Or a b | (a, b) <- shrink (f1, f2)]
  shrink (Imp f1 f2) = [f1, f2] ++ [Imp a b | (a, b) <- shrink (f1, f2)]
  shrink (Iff f1 f2) = [f1, f2] ++ [Iff a b | (a, b) <- shrink (f1, f2)]

equivalent :: Formula -> Formula -> Bool
equivalent f1 f2 = isTautology (Iff f1 f2)

main :: IO ()
main = hspec $ do
  describe "isTautology" $ do
    it "is True for p ∨ ¬p (classic tautology)" $ do
      let f = Or (Var "p") (Not (Var "p"))
      isTautology f `shouldBe` True

    it "is True for p → p (trivial tautology)" $ do
      let f = Imp (Var "p") (Var "p")
      isTautology f `shouldBe` True

    it "is False for p ∧ ¬p (a contradiction, not a tautology)" $ do
      let f = And (Var "p") (Not (Var "p"))
      isTautology f `shouldBe` False

    it "is False for a contingent formula like (p ∧ q) → r" $ do
      let f = Imp (And (Var "p") (Var "q")) (Var "r")
      isTautology f `shouldBe` False

    it "is True for p ∨ q ∨ ¬p ∨ ¬q (always covers every case)" $ do
      let f = Or (Or (Var "p") (Var "q")) (Or (Not (Var "p")) (Not (Var "q")))
      isTautology f `shouldBe` True

  describe "isSatisfiable" $ do
    it "is True for a contingent formula like (p ∧ q) → r" $ do
      let f = Imp (And (Var "p") (Var "q")) (Var "r")
      isSatisfiable f `shouldBe` True

    it "is True for a tautology (p ∨ ¬p), since it's true everywhere" $ do
      let f = Or (Var "p") (Not (Var "p"))
      isSatisfiable f `shouldBe` True

    it "is False for a contradiction (p ∧ ¬p)" $ do
      let f = And (Var "p") (Not (Var "p"))
      isSatisfiable f `shouldBe` False

    it "is True for a single variable (p)" $ do
      isSatisfiable (Var "p") `shouldBe` True

  describe "isContradiction" $ do
    it "is True for p ∧ ¬p (classic contradiction)" $ do
      let f = And (Var "p") (Not (Var "p"))
      isContradiction f `shouldBe` True

    it "is False for a tautology (p ∨ ¬p)" $ do
      let f = Or (Var "p") (Not (Var "p"))
      isContradiction f `shouldBe` False

    it "is False for a contingent formula like (p ∧ q) → r" $ do
      let f = Imp (And (Var "p") (Var "q")) (Var "r")
      isContradiction f `shouldBe` False

    it "is False for a single variable (p)" $ do
      isContradiction (Var "p") `shouldBe` False

  describe "relationships between isTautology, isSatisfiable, and isContradiction" $ do
    it "isContradiction f == not (isSatisfiable f), for a contradiction" $ do
      let f = And (Var "p") (Not (Var "p"))
      isContradiction f `shouldBe` not (isSatisfiable f)

    it "isContradiction f == not (isSatisfiable f), for a contingent formula" $ do
      let f = Imp (And (Var "p") (Var "q")) (Var "r")
      isContradiction f `shouldBe` not (isSatisfiable f)

    it "isTautology f implies isSatisfiable f" $ do
      let f = Or (Var "p") (Not (Var "p"))
      (isTautology f, isSatisfiable f) `shouldBe` (True, True)

    it "isTautology f == isContradiction (Not f)" $ do
      let f = Or (Var "p") (Not (Var "p"))
      isTautology f `shouldBe` isContradiction (Not f)

  describe "eval" $ do
    it "evaluates a single True variable correctly" $ do
      eval [("p", True)] (Var "p") `shouldBe` True

    it "evaluates a single False variable correctly" $ do
      eval [("p", False)] (Var "p") `shouldBe` False

    it "evaluates Not correctly" $ do
      eval [("p", True)] (Not (Var "p")) `shouldBe` False

    it "evaluates And correctly" $ do
      eval [("p", True), ("q", False)] (And (Var "p") (Var "q")) `shouldBe` False

    it "evaluates Or correctly" $ do
      eval [("p", True), ("q", False)] (Or (Var "p") (Var "q")) `shouldBe` True

    it "evaluates Imp correctly when antecedent is False (vacuously True)" $ do
      eval [("p", False), ("q", False)] (Imp (Var "p") (Var "q")) `shouldBe` True

    it "evaluates Imp correctly when antecedent is True and consequent is False" $ do
      eval [("p", True), ("q", False)] (Imp (Var "p") (Var "q")) `shouldBe` False

    it "evaluates Iff correctly when both sides match" $ do
      eval [("p", True), ("q", True)] (Iff (Var "p") (Var "q")) `shouldBe` True

    it "evaluates Iff correctly when sides differ" $ do
      eval [("p", True), ("q", False)] (Iff (Var "p") (Var "q")) `shouldBe` False

    it "throws an error for an unbound variable" $ do
      evaluate (eval [] (Var "p")) `shouldThrow` anyErrorCall

  describe "vars" $ do
    it "returns a single variable for Var" $ do
      vars (Var "p") `shouldBe` ["p"]

    it "deduplicates repeated variables" $ do
      vars (And (Var "p") (Var "p")) `shouldMatchList` ["p"]

    it "collects all distinct variables from a compound formula" $ do
      let f = Imp (And (Var "p") (Var "q")) (Var "r")
      vars f `shouldMatchList` ["p", "q", "r"]

    it "passes through Not without changing the variable set" $ do
      vars (Not (Var "p")) `shouldBe` ["p"]

  describe "truthAssignments" $ do
    it "returns a single empty environment for no variables" $ do
      truthAssignments [] `shouldBe` [[]]

    it "returns 2 environments for 1 variable" $ do
      length (truthAssignments ["p"]) `shouldBe` 2

    it "returns 4 environments for 2 variables" $ do
      length (truthAssignments ["p", "q"]) `shouldBe` 4

    it "returns 8 environments for 3 variables" $ do
      length (truthAssignments ["p", "q", "r"]) `shouldBe` 8

    it "covers every combination of True/False for 2 variables" $ do
      let envs = truthAssignments ["p", "q"]
      envs `shouldMatchList`
        [ [("p", False), ("q", False)]
        , [("p", False), ("q", True)]
        , [("p", True),  ("q", False)]
        , [("p", True),  ("q", True)]
        ]

  describe "parseFormula" $ do
    it "parses a variable" $ do
      parseFormula "p" `shouldBe` Right (Var "p")

    it "binds \8743 tighter than \8594" $ do
      parseFormula "p & q -> r"
        `shouldBe` Right (Imp (And (Var "p") (Var "q")) (Var "r"))

    it "binds \8743 tighter than \8744" $ do
      parseFormula "p | q & r"
        `shouldBe` Right (Or (Var "p") (And (Var "q") (Var "r")))

    it "honours explicit parentheses over precedence" $ do
      parseFormula "(p | q) & r"
        `shouldBe` Right (And (Or (Var "p") (Var "q")) (Var "r"))

    it "associates \8594 to the right" $ do
      parseFormula "p -> q -> r"
        `shouldBe` Right (Imp (Var "p") (Imp (Var "q") (Var "r")))

    it "associates \8743 to the left" $ do
      parseFormula "p & q & r"
        `shouldBe` Right (And (And (Var "p") (Var "q")) (Var "r"))

    it "binds \172 tighter than any binary connective" $ do
      parseFormula "~p & q"
        `shouldBe` Right (And (Not (Var "p")) (Var "q"))

    it "reads the ASCII and Unicode spellings identically" $ do
      parseFormula "p & q -> r" `shouldBe` parseFormula "p \8743 q \8594 r"

    it "reads the keyword spellings identically" $ do
      parseFormula "p and q implies r" `shouldBe` parseFormula "p & q -> r"

    it "rejects a trailing operator" $ do
      parseFormula "p &" `shouldSatisfy` isLeft

    it "rejects an unclosed parenthesis" $ do
      parseFormula "(p & q" `shouldSatisfy` isLeft

    it "rejects an unknown character" $ do
      parseFormula "p # q" `shouldSatisfy` isLeft

    it "rejects two adjacent variables" $ do
      parseFormula "p q" `shouldSatisfy` isLeft

    it "rejects the empty input" $ do
      parseFormula "" `shouldSatisfy` isLeft

  describe "properties" $ do
    prop "render round-trips through parseFormula" $ \f ->
      parseFormula (render f) == Right f

    prop "a truth table has one row per assignment" $ \f ->
      length (truthTable f) == 2 ^ length (vars f)

    prop "vars are distinct" $ \f ->
      let vs = vars f in length (nub vs) == length vs

    prop "isContradiction is the negation of isSatisfiable" $ \f ->
      isContradiction f == not (isSatisfiable f)

    prop "isTautology f is isContradiction (Not f)" $ \f ->
      isTautology f == isContradiction (Not f)

    prop "every tautology is satisfiable" $ \f ->
      not (isTautology f) || isSatisfiable f

    prop "double negation" $ \f ->
      equivalent (Not (Not f)) f

    prop "De Morgan, over conjunction" $ \f1 f2 ->
      equivalent (Not (And f1 f2)) (Or (Not f1) (Not f2))

    prop "De Morgan, over disjunction" $ \f1 f2 ->
      equivalent (Not (Or f1 f2)) (And (Not f1) (Not f2))

    prop "material implication" $ \f1 f2 ->
      equivalent (Imp f1 f2) (Or (Not f1) f2)

    prop "contraposition" $ \f1 f2 ->
      equivalent (Imp f1 f2) (Imp (Not f2) (Not f1))

    prop "a biconditional is implication in both directions" $ \f1 f2 ->
      equivalent (Iff f1 f2) (And (Imp f1 f2) (Imp f2 f1))

isLeft :: Either a b -> Bool
isLeft (Left _) = True
isLeft (Right _) = False
