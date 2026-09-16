module Logic
  ( Formula (..)
  , Env
  , eval
  , vars
  , truthAssignments
  , truthTable
  , render
  , renderTruthTable
  , isTautology
  , isSatisfiable
  , isContradiction
  ) where

import Data.List (intercalate, nub)

data Formula
  = Var String
  | Not Formula
  | And Formula Formula
  | Or Formula Formula
  | Imp Formula Formula
  | Iff Formula Formula
  deriving (Show, Eq)

type Env = [(String, Bool)]

eval :: Env -> Formula -> Bool
eval env (Var x) =
  case lookup x env of
    Just v  -> v
    Nothing -> error ("Unbound variable: " ++ x)
eval env (Not f) = not (eval env f)
eval env (And f1 f2) = eval env f1 && eval env f2
eval env (Or f1 f2) = eval env f1 || eval env f2
eval env (Imp f1 f2) = not (eval env f1) || eval env f2
eval env (Iff f1 f2) = eval env f1 == eval env f2

vars :: Formula -> [String]
vars = nub . go
  where
    go (Var x) = [x]
    go (Not f) = go f
    go (And f1 f2) = go f1 ++ go f2
    go (Or f1 f2) = go f1 ++ go f2
    go (Imp f1 f2) = go f1 ++ go f2
    go (Iff f1 f2) = go f1 ++ go f2

truthAssignments :: [String] -> [Env]
truthAssignments [] = [[]]
truthAssignments (v:vs) =
  [ (v, b) : env
  | b <- [False, True]
  , env <- truthAssignments vs
  ]

truthTable :: Formula -> [(Env, Bool)]
truthTable f =
  [ (env, eval env f)
  | env <- truthAssignments (vars f)
  ]

isTautology :: Formula -> Bool
isTautology f = all snd (truthTable f)

isSatisfiable :: Formula -> Bool
isSatisfiable f = any snd (truthTable f)

isContradiction :: Formula -> Bool
isContradiction f = not (isSatisfiable f)

-- | Infix notation, parenthesised only where precedence requires it.
render :: Formula -> String
render = go (0 :: Int)
  where
    go _ (Var x) = x
    go p (Not f) = paren (p > 5) ("\172" ++ go 5 f)
    go p (And f1 f2) = binary p 4 " \8743 " (go 4 f1) (go 5 f2)
    go p (Or f1 f2) = binary p 3 " \8744 " (go 3 f1) (go 4 f2)
    go p (Imp f1 f2) = binary p 2 " \8594 " (go 3 f1) (go 2 f2)
    go p (Iff f1 f2) = binary p 1 " \8596 " (go 2 f1) (go 1 f2)

    binary outer prec op l r = paren (outer > prec) (l ++ op ++ r)

    paren True s = "(" ++ s ++ ")"
    paren False s = s

-- | One column per variable, plus a final column for the formula.
renderTruthTable :: Formula -> String
renderTruthTable f =
    unlines (row headers : separator : map assignmentRow (truthTable f))
  where
    names = vars f
    headers = names ++ [render f]
    widths = map length headers

    assignmentRow (env, value) =
      row (map (cell . flip lookup env) names ++ [cell (Just value)])

    row cells = "| " ++ intercalate " | " (zipWith center widths cells) ++ " |"
    separator = "|" ++ intercalate "|" (map (\w -> replicate (w + 2) '-') widths) ++ "|"

    cell (Just True) = "T"
    cell (Just False) = "F"
    cell Nothing = "?"

    center w s = replicate left ' ' ++ s ++ replicate right ' '
      where
        padding = w - length s
        left = padding `div` 2
        right = padding - left
