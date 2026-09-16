# Overview and Usage

Pleh represents propositional logic formulas and generates their truth tables in Haskell.

A formula can contain propositional variables, negation, conjunction, disjunction, implication, and biconditional. For example:

```text
(p ∧ q) → r
```

Pleh evaluates this formula for every possible assignment of truth values to `p`, `q`, and `r`.

## Rendering formulas

```haskell
render :: Formula -> String
```

`render` converts the AST into a human-readable expression. Operator precedence, from weakest to strongest binding, is:

```text
Iff   ↔
Imp   →
Or    ∨
And   ∧
Not   ¬
```

Thus `p ∧ q → r` is interpreted as `(p ∧ q) → r`, while `¬p ∧ q` is interpreted as `(¬p) ∧ q`.

## Rendering truth tables

```haskell
renderTruthTable :: Formula -> String
```

This converts a generated truth table into an aligned textual table.

## Complete example

```haskell
formula :: Formula
formula =
  Imp
    (And (Var "p") (Var "q"))
    (Var "r")
```

There are `2^3 = 8` possible assignments. They can be inspected with:

```haskell
truthTable formula
renderTruthTable formula
isTautology formula
isSatisfiable formula
isContradiction formula
```

## Running

With Cabal:

```bash
cabal run pleh
```

Or directly with GHC from the project root:

```bash
ghc -isrc -iapp -o logic app/Main.hs
./logic
```
