# Propositional Logic in Haskell

> [!IMPORTANT]
> Personal exercise — representing propositional logic formulas and generating their truth tables in Haskell.

## Overview

Propositional logic deals with statements that are either true or false (**propositions**), combined with logical connectives such as "and", "or", "not", "if... then", and "if and only if".

Example: `p` = "it is raining", `q` = "I bring an umbrella", `p → q` = "if it is raining, then I bring an umbrella".

A **truth table** lists every possible combination of truth values for the variables in a formula, together with the resulting value of the formula under each assignment.

## The `Formula` type

Each formula is built from the following constructors:

```haskell
data Formula
  = Var String           -- a variable, like "p"
  | Not Formula          -- negation
  | And Formula Formula  -- conjunction
  | Or Formula Formula   -- disjunction
  | Imp Formula Formula  -- implication
  | Iff Formula Formula  -- biconditional
```

So the formula `(p ∧ q) → r` is represented as:

```haskell
Imp (And (Var "p") (Var "q")) (Var "r")
```

## Environments

A truth assignment is represented as an environment mapping variable names to Boolean values:

```haskell
type Env = [(String, Bool)]
```

For example:

```haskell
[("p", True), ("q", False), ("r", True)]
```

## `eval`: evaluating formulas

`eval` takes an environment and recursively computes the truth value of a formula:

```haskell
eval env (Var x)      = -- look up x's value
eval env (Not f)      = not (eval env f)
eval env (And f1 f2)  = eval env f1 && eval env f2
eval env (Or f1 f2)   = eval env f1 || eval env f2
eval env (Imp f1 f2)  = not (eval env f1) || eval env f2
eval env (Iff f1 f2)  = eval env f1 == eval env f2
```

Two important details:

* `Imp f1 f2` is false **only** when `f1` is true and `f2` is false.
* `Iff f1 f2` is true when both sides have the same truth value.

## `vars` and `truthAssignments`

`vars` collects the variable names appearing in a formula, removing duplicates with `nub`.

`truthAssignments` generates every possible truth assignment for a list of variables — `2^n` combinations for `n` variables:

```haskell
truthAssignments []     = [[]]
truthAssignments (v:vs) =
  [ (v, b) : env
  | b <- [False, True]
  , env <- truthAssignments vs
  ]
```

## `truthTable`

The truth table is obtained by evaluating the formula under every possible environment:

```haskell
truthTable formula =
  [ (env, eval env formula)
  | env <- truthAssignments (vars formula)
  ]
```

## Example formula

```haskell
formula = Imp (And (Var "p") (Var "q")) (Var "r")
```

This corresponds to `(p ∧ q) → r`.

The formula is false only when `p` and `q` are true and `r` is false; it is true in all other cases.

## Running

```bash
ghc -o logic Main.hs
./logic
```

or:

```bash
runghc Main.hs
```
