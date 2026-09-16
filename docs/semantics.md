# Semantics and Evaluation

## Syntax versus semantics

The `Formula` type describes the syntax of formulas: which expressions can be constructed. Evaluation describes their semantics: what truth value a formula has under a particular assignment.

```text
Syntax
   ↓
Formula
   ↓
Evaluation under an environment
   ↓
Bool
```

## Evaluation

The basic evaluator has type:

```haskell
eval :: Env -> Formula -> Bool
```

Conceptually:

```text
eval : Env → Formula → Bool
```

For example:

```haskell
eval [("p", True), ("q", False)]
     (And (Var "p") (Var "q"))
```

produces `False`.

## Semantic notation

Double brackets denote semantic evaluation:

```text
⟦φ⟧ρ
```

For variables and connectives:

```text
x ∈ dom(ρ)
--------------------
⟦Var x⟧ρ = ρ(x)
```

```text
⟦Not φ⟧ρ = ¬⟦φ⟧ρ
⟦And φ ψ⟧ρ = ⟦φ⟧ρ ∧ ⟦ψ⟧ρ
⟦Or φ ψ⟧ρ = ⟦φ⟧ρ ∨ ⟦ψ⟧ρ
⟦Imp φ ψ⟧ρ = ¬⟦φ⟧ρ ∨ ⟦ψ⟧ρ
⟦Iff φ ψ⟧ρ = (⟦φ⟧ρ = ⟦ψ⟧ρ)
```

## Partiality of `eval`

Although `eval` has type `Env -> Formula -> Bool`, it is not total over all possible inputs:

```haskell
eval [] (Var "p")
```

causes a runtime error because `p` is not bound. The semantic interpretation is well defined when:

```text
vars(φ) ⊆ dom(ρ)
```

## Checked evaluation

The total alternative is:

```haskell
data EvalError
  = UnboundVariable String
  deriving (Show, Eq)

evalChecked :: Env -> Formula -> Either EvalError Bool
```

Examples:

```haskell
evalChecked [("p", True)] (Var "p")
-- Right True

evalChecked [] (Var "p")
-- Left (UnboundVariable "p")
```

`Either EvalError Bool` is a sum type: evaluation produces either an `EvalError` or a `Bool`. Failure is represented in the type rather than hidden behind `error`.

## Typing and semantic judgment

The formation judgment is:

```text
Γ ⊢ φ wf
```

The environment judgment can be written as:

```text
Γ ⊢ ρ : Env
```

and typed evaluation as:

```text
Γ ⊢ ρ : Env    Γ ⊢ φ wf
----------------------------------
Γ ⊢ evalChecked ρ φ : Either EvalError Bool
```

For a successful evaluation:

```text
Γ ⊢ ρ : Env    Γ ⊢ φ wf    ρ ⊨ φ ⇓ b
-------------------------------------
Γ ⊢ evalChecked ρ φ = Right b
```

For an unbound variable:

```text
x ∉ dom(ρ)
----------------------------------------------
Γ ⊢ evalChecked ρ (Var x) = Left (UnboundVariable x)
```
