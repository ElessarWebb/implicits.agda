module SystemF.BigStep.Extrinsic.Terms where

open import Prelude
open import SystemF.BigStep.Types
open import Data.List
open import Data.Fin.Substitution

-- erased (type-free) System F syntax
data Term : Set where
  unit : Term
  ƛ : Term → Term
  Λ : Term → Term
  _·_ : Term → Term → Term
  _[-] : Term → Term
  var : ℕ → Term

-- environments
Env : Set

data Val : Set where
  unit : Val
  clos : Env → (t : Term) → Val
  tclos : Env → (t : Term) → Val

Env = List Val

-- injection of Values into Terms

⟦_⟧ : Val → Term
⟦ unit ⟧ = unit
⟦ clos x t ⟧ = ƛ t
⟦ tclos x t ⟧ = Λ t
