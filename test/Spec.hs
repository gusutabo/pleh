module Main (main) where

import Test.Hspec
import Control.Exception (evaluate)
import Logic

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
