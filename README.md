# Propositional Logic in Haskell

[![CI](https://github.com/gusutabo/pleh/actions/workflows/ci.yml/badge.svg)](https://github.com/gusutabo/pleh/actions/workflows/ci.yml)

> [!IMPORTANT]
> Personal exercise — representing propositional logic formulas and generating their truth tables in Haskell.

**pleh** stands for *Propositional Logic Evaluator in Haskell*.

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

## Classifying formulas

Once a formula's whole truth table is available, classifying it is a matter of
looking at the result column:

```haskell
isTautology     f = all snd (truthTable f)   -- true under every assignment
isSatisfiable   f = any snd (truthTable f)   -- true under at least one
isContradiction f = not (isSatisfiable f)    -- true under none
```

So `p ∨ ¬p` is a tautology, `p ∧ ¬p` is a contradiction, and `(p ∧ q) → r` is
neither — it is *contingent*, true under some assignments and false under others.

## Rendering

`render` prints a formula in infix notation, adding parentheses only where the
operator precedences require them. Connectives bind in the usual order — `¬`
tightest, then `∧`, `∨`, `→`, `↔` — with `→` and `↔` associating to the right
and `∧` and `∨` to the left:

```haskell
render (And (Var "p") (And (Var "q") (Var "r")))  -- "p ∧ (q ∧ r)"
render (And (And (Var "p") (Var "q")) (Var "r"))  -- "p ∧ q ∧ r"
render (Not (And (Var "p") (Var "q")))            -- "¬(p ∧ q)"
```

`renderTruthTable` lays the table out with one column per variable and a final
column for the formula itself.

## Parsing

`parseFormula :: String -> Either String Formula` reads a formula back from
text. Each connective has a Unicode spelling, one or more ASCII spellings, and a
keyword spelling:

| Connective | Unicode | ASCII | Keyword |
| --- | --- | --- | --- |
| negation | `¬` | `~` `!` | `not` |
| conjunction | `∧` | `&` `&&` `/\` | `and` |
| disjunction | `∨` | `\|` `\|\|` `\/` | `or` |
| implication | `→` | `->` `=>` | `implies` |
| biconditional | `↔` | `<->` `<=>` | `iff` |

Precedence and associativity match `render`, so parsing is its left inverse:
`parseFormula (render f) == Right f` for every formula `f`.

## Example formula

```haskell
formula = Imp (And (Var "p") (Var "q")) (Var "r")
```

This corresponds to `(p ∧ q) → r`.

The formula is false only when `p` and `q` are true and `r` is false; it is true
in all other cases:

```
| p | q | r | p ∧ q → r |
|---|---|---|-----------|
| F | F | F |     T     |
| F | F | T |     T     |
| F | T | F |     T     |
| F | T | T |     T     |
| T | F | F |     T     |
| T | F | T |     T     |
| T | T | F |     F     |
| T | T | T |     T     |
```

The header reads `p ∧ q → r` rather than `(p ∧ q) → r` because `∧` already binds
tighter than `→`, so the parentheses would be redundant.

## Project layout

| Path | Component |
| --- | --- |
| `src/Logic.hs` | the `pleh` library — the `Formula` type and everything that operates on it |
| `app/Main.hs` | the `pleh` executable — prints the example formula's truth table |
| `test/Spec.hs` | the `pleh-test` hspec suite |

## Building and running

```bash
cabal build
cabal test
```

With no argument, `pleh` prints the truth table of the example formula:

```bash
cabal run pleh
```

Otherwise it parses the formula given on the command line:

```bash
$ cabal run pleh -- '(p | q) & ~r'
| p | q | r | (p ∨ q) ∧ ¬r |
|---|---|---|--------------|
| F | F | F |      F       |
| F | F | T |      F       |
| F | T | F |      T       |
| F | T | T |      F       |
| T | F | F |      T       |
| T | F | T |      F       |
| T | T | F |      T       |
| T | T | T |      F       |
```

A formula that does not parse is reported on stderr, with a non-zero exit status:

```bash
$ cabal run pleh -- 'p & '
pleh: Expected a variable or '(' but reached the end of the input
```

Run `pleh --help` for the full list of accepted connectives.
