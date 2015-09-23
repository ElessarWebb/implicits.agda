open import Prelude

module Implicits.Improved.Ambiguous.Resolution (TC : Set) (_tc≟_ : (a b : TC) → Dec (a ≡ b)) where

open import Coinduction
open import Data.Fin.Substitution
open import Implicits.Oliveira.Types TC _tc≟_
open import Implicits.Oliveira.Terms TC _tc≟_
open import Implicits.Oliveira.Contexts TC _tc≟_
open import Implicits.Oliveira.Substitutions TC _tc≟_

module NotSyntaxDirected where
  infixl 5 _⊢ᵣ_
  data _⊢ᵣ_ {ν} (Δ : ICtx ν) : Type ν → Set where
    r-tabs : ∀ {r} → ∞ (ictx-weaken Δ ⊢ᵣ r) → Δ ⊢ᵣ ∀' r
    r-tapp : ∀ {r} a → ∞ (Δ ⊢ᵣ ∀' r) → Δ ⊢ᵣ (r tp[/tp a ])
    r-ivar : ∀ {r} → r List.∈ Δ → Δ ⊢ᵣ r
    r-iabs : ∀ {a b} → ∞ ((a List.∷ Δ) ⊢ᵣ b) → Δ ⊢ᵣ (a ⇒ b)
    r-iapp : ∀ {a b} → ∞ (Δ ⊢ᵣ (a ⇒ b)) → ∞ (Δ ⊢ᵣ a) → Δ ⊢ᵣ b

module SyntaxDirected where
  infixl 5 _⊢ᵣ_ _⊢_↓_
  mutual
    data _⊢_↓_ {ν} (Δ : ICtx ν) : Type ν → SimpleType ν → Set where
      i-simp : ∀ a → Δ ⊢ simpl a ↓ a
      i-iabs : ∀ {ρ₁ ρ₂ a} → ∞ (Δ ⊢ᵣ ρ₁) → Δ ⊢ ρ₂ ↓ a → Δ ⊢ ρ₁ ⇒ ρ₂ ↓ a
      i-tabs : ∀ {ρ a} b → Δ ⊢ ρ tp[/tp b ] ↓ a → Δ ⊢ ∀' ρ ↓ a

    data _⊢ᵣ_ {ν} (Δ : ICtx ν) : Type ν → Set where
      r-simp : ∀ {r τ} → (r List.∈ Δ) → Δ ⊢ r ↓ τ → Δ ⊢ᵣ simpl τ
      r-iabs : ∀ {ρ₁ ρ₂} → ∞ ((ρ₁ List.∷ Δ) ⊢ᵣ ρ₂) → Δ ⊢ᵣ (ρ₁ ⇒ ρ₂)
      r-tabs : ∀ {ρ} → ∞ (ictx-weaken Δ ⊢ᵣ ρ) → Δ ⊢ᵣ ∀' ρ

  complexity : ∀ {ν} → Type ν → ℕ
  complexity (simpl (tc x)) = 1
  complexity (simpl (tvar n)) = 1
  complexity (simpl (a →' b)) = complexity a N+ complexity b
  complexity (a ⇒ b) = complexity a N+ complexity b
  complexity (∀' x) = complexity x

  data ⊢diverges {ν} {Δ : ICtx ν} : ∀ {a τ} → Δ ⊢ a ↓ τ → Set where

  open import Data.List.Any.Membership using (map-mono)
  open import Data.List.Any
  open Membership-≡

  mutual

    -- extending contexts is safe: it preserves the r ↓ a relation
    -- (this is not true for Oliveira's deterministic calculus)
    ⊆-r↓a : ∀ {ν} {Δ Δ' : ICtx ν} {a r} → Δ ⊢ r ↓ a → Δ ⊆ Δ' → Δ' ⊢ r ↓ a
    ⊆-r↓a (i-simp a) _ = i-simp a
    ⊆-r↓a (i-iabs x₁ x₂) f = i-iabs (♯ (⊆-Δ⊢a (♭ x₁) f)) (⊆-r↓a x₂ f)
    ⊆-r↓a (i-tabs b x₁) f = i-tabs b (⊆-r↓a x₁ f)

    -- extending contexts is safe: it preserves the ⊢ᵣ a relation
    -- (this is not true for Oliveira's deterministic calculus)
    ⊆-Δ⊢a : ∀ {ν} {Δ Δ' : ICtx ν} {a} → Δ ⊢ᵣ a → Δ ⊆ Δ' → Δ' ⊢ᵣ a
    ⊆-Δ⊢a (r-simp x₁ x₂) f = r-simp (f x₁) (⊆-r↓a x₂ f)
    ⊆-Δ⊢a (r-iabs x₁) f =
      r-iabs (♯ (⊆-Δ⊢a (♭ x₁) (λ{ (here px) → here px ; (there x₂) → there (f x₂) })))
    ⊆-Δ⊢a (r-tabs x) f = r-tabs (♯ (⊆-Δ⊢a (♭ x) f'))
      where
        f' = map-mono (flip TypeSubst._/_ TypeSubst.wk) f