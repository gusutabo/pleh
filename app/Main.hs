module Main (main) where

import System.IO (hSetEncoding, stdout, utf8)

import Logic

-- (p ∧ q) → r
formula :: Formula
formula =
  Imp
    (And (Var "p") (Var "q"))
    (Var "r")

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStr (renderTruthTable formula)
