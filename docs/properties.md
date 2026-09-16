# Logical Properties

## Variables

```haskell
vars :: Formula -> [String]
```

`vars` returns the distinct variables occurring in a formula:

```haskell
vars
  (And
    (Var "p")
    (Or (Var "q") (Var "p")))
```

returns:

```haskell
["p", "q"]
```

## Truth assignments

```haskell
truthAssignments :: [String] -> [Env]
```

For `n` variables, exhaustive generation produces `2^n` assignments. This exponential growth is intrinsic to truth-table generation.

## Truth tables

```haskell
truthTable :: Formula -> [(Env, Bool)]
```

Conceptually:

```text
truthTable(φ) = { (ρ, ⟦φ⟧ρ) | ρ assigns values to every variable in φ }
```

For `p ∧ q`:

```text
p       q       p ∧ q
False   False   False
False   True    False
True    False   False
True    True    True
```

## Tautology

```haskell
isTautology :: Formula -> Bool
```

```text
∀ρ. ⟦φ⟧ρ = True
```

The implementation is:

```haskell
isTautology f = all snd (truthTable f)
```

## Satisfiability

```haskell
isSatisfiable :: Formula -> Bool
```

```text
∃ρ. ⟦φ⟧ρ = True
```

The implementation is:

```haskell
isSatisfiable f = any snd (truthTable f)
```

## Contradiction

```haskell
isContradiction :: Formula -> Bool
```

```text
¬∃ρ. ⟦φ⟧ρ = True
```

Equivalently:

```text
∀ρ. ⟦φ⟧ρ = False
```

```haskell
isContradiction f = not (isSatisfiable f)
```
