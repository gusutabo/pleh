# Typing Judgments

## Formation judgment

Let `Γ` be a context containing the propositional variables available to a formula. We write:

```text
Γ ⊢ φ wf
```

to mean that formula `φ` is well formed in context `Γ`.

The symbol `φ` is a metavariable for an arbitrary formula; `ψ` and `χ` are commonly used for other formulas.

### Variable

A variable is well formed when it occurs in the context:

```text
x : Bool ∈ Γ
----------------
Γ ⊢ Var x wf
```

### Negation

```text
Γ ⊢ φ wf
----------------
Γ ⊢ Not φ wf
```

### Binary operators

The same rule pattern applies to every binary connective:

```text
Γ ⊢ φ wf    Γ ⊢ ψ wf
---------------------
Γ ⊢ And φ ψ wf
```

```text
Γ ⊢ φ wf    Γ ⊢ ψ wf
---------------------
Γ ⊢ Or φ ψ wf
```

```text
Γ ⊢ φ wf    Γ ⊢ ψ wf
---------------------
Γ ⊢ Imp φ ψ wf
```

```text
Γ ⊢ φ wf    Γ ⊢ ψ wf
---------------------
Γ ⊢ Iff φ ψ wf
```

These rules describe the recursive structure already encoded by the Haskell datatype.

## Why `wf` instead of `: Formula`?

In Haskell, `Formula` is a type. In the metatheory, `Γ ⊢ φ wf` is a well-formedness judgment. Since `Formula` is not itself an object-language type system with typing rules, `wf` is more precise here.

The current design is **extrinsically specified**: Haskell guarantees that a constructed value has type `Formula`, while the context-based well-formedness condition is described separately.

For example, `Var "anything"` is always a Haskell value of type `Formula`, even if the name is not present in an external context.

## Contexts and environments

The runtime environment is:

```haskell
type Env = [(String, Bool)]
```

A context describes available variables:

```text
Γ = { p : Bool, q : Bool, r : Bool }
```

An environment assigns concrete values:

```text
ρ = { p ↦ True, q ↦ False, r ↦ True }
```

Mathematically, the current list representation is a partial mapping:

```text
ρ : String ⇀ Bool
```

A useful relationship is `dom(ρ) ⊆ dom(Γ)`. When every variable in the context has a value, `dom(ρ) = dom(Γ)`.
