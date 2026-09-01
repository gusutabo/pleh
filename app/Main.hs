module Main (main) where

import System.Environment (getArgs, getProgName)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, hSetEncoding, stderr, stdout, utf8)

import Logic
import Parser (parseFormula)

-- | (p ∧ q) → r, used when no formula is given.
exampleFormula :: Formula
exampleFormula =
  Imp
    (And (Var "p") (Var "q"))
    (Var "r")

main :: IO ()
main = do
  hSetEncoding stdout utf8
  hSetEncoding stderr utf8
  args <- getArgs
  case args of
    [] -> putStr (renderTruthTable exampleFormula)
    ["-h"] -> usage
    ["--help"] -> usage
    _ ->
      case parseFormula (unwords args) of
        Left err -> die err
        Right f -> putStr (renderTruthTable f)

usage :: IO ()
usage = do
  name <- getProgName
  mapM_
    putStrLn
    [ "Usage: " ++ name ++ " [FORMULA]"
    , ""
    , "Print the truth table of a propositional formula."
    , "With no argument, an example formula is used."
    , ""
    , "Connectives (Unicode or ASCII):"
    , "  negation      \172   ~   !    not"
    , "  conjunction   \8743   &   &&   /\\    and"
    , "  disjunction   \8744   |   ||   \\/    or"
    , "  implication   \8594   ->  =>        implies"
    , "  biconditional \8596   <-> <=>       iff"
    , ""
    , "Example:"
    , "  " ++ name ++ " '(p & q) -> r'"
    ]

die :: String -> IO ()
die err = do
  hPutStrLn stderr ("pleh: " ++ err)
  exitFailure
