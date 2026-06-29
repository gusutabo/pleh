module Logic where
  
import Data.List (nub)

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
vars (Var x) = [x]
vars (Not f) = vars f
vars (And f1 f2) = nub (vars f1 ++ vars f2)
vars (Or f1 f2) = nub (vars f1 ++ vars f2)
vars (Imp f1 f2) = nub (vars f1 ++ vars f2)
vars (Iff f1 f2) = nub (vars f1 ++ vars f2)

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
  
formula :: Formula
formula =
  Imp
    (And (Var "p") (Var "q"))
    (Var "r")

isTautology :: Formula -> Bool
isTautology f = all snd (truthTable f)

isSatisfiable :: Formula -> Bool
isSatisfiable f = any snd (truthTable f)

isContradiction :: Formula -> Bool
isContradiction f = not (isSatisfiable f)
