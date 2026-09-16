# Formula Syntax

## The `Formula` type

A propositional formula can be built from variables, negation, conjunction, disjunction, implication, and biconditional:

```haskell
data Formula
  = Var String
  | Not Formula
  | And Formula Formula
  | Or Formula Formula
  | Imp Formula Formula
  | Iff Formula Formula
  deriving (Show, Eq)
```

This is an inductive algebraic data type. Each constructor describes one possible way of constructing a formula.

## Constructor types

```haskell
Var :: String -> Formula
Not :: Formula -> Formula
And :: Formula -> Formula -> Formula
Or  :: Formula -> Formula -> Formula
Imp :: Formula -> Formula -> Formula
Iff :: Formula -> Formula -> Formula
```

For example:

```haskell
And (Var "p") (Var "q")
```

represents:

```text
p ∧ q
```

The formula `(p ∧ q) → r` is represented as:

```haskell
Imp
  (And (Var "p") (Var "q"))
  (Var "r")
```

The datatype is the abstract syntax tree (AST) of the logic language. It describes syntax, while evaluation describes semantics.
