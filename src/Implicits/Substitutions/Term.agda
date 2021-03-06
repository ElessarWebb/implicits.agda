open import Prelude hiding (subst)

module Implicits.Substitutions.Term where

open import Implicits.Syntax.Type
open import Implicits.Syntax.Term

open import Data.Fin.Substitution
open import Data.Star as Star hiding (map)
open import Data.Star.Properties
open import Data.Vec hiding ([_])

open import Implicits.Substitutions.Type as TypeSubst using () 

module TermTypeSubst where

  module TermTypeApp {T} (l : Lift T Type) where
    open Lift l hiding (var)
    open TypeSubst.TypeApp l renaming (_/_ to _/tp_)

    infixl 8 _/_

    -- Apply a type substitution to a term
    _/_ : ∀ {ν μ n} → Term ν n → Sub T ν μ → Term μ n
    var x      / σ = var x
    Λ t        / σ = Λ (t / σ ↑)
    λ' a t     / σ = λ' (a /tp σ) (t / σ)
    t [ a ]    / σ = (t / σ) [ a /tp σ ]
    s · t      / σ = (s / σ) · (t / σ)
    ρ a t      / σ = ρ (a /tp σ) (t / σ)
    r ⟨⟩     / σ = (r / σ) ⟨⟩
    r with' e  / σ = (r / σ) with' (e / σ)

  open TypeSubst using (varLift; termLift; sub)

  module Lifted {T} (lift : Lift T Type) {n} where
    application : Application (λ ν → Term ν n) T
    application = record { _/_ = TermTypeApp._/_ lift {n = n} }

    open Application application public

  open Lifted termLift public

  -- apply a type variable substitution (renaming) to a term
  _/Var_ : ∀ {ν μ n} → Term ν n → Sub Fin ν μ → Term μ n
  _/Var_ = TermTypeApp._/_ varLift

  -- weaken a term with an additional type variable
  weaken : ∀ {ν n} → Term ν n → Term (suc ν) n
  weaken t = t /Var VarSubst.wk

  infix 8 _[/_]

  -- shorthand for single-variable type substitutions in terms
  _[/_] : ∀ {ν n} → Term (suc ν) n → Type ν → Term ν n
  t [/ b ] = t / sub b

module TermTermSubst where

  -- Substitutions of terms in terms
  TermSub : (ℕ → ℕ → Set) → ℕ → ℕ → ℕ → Set
  TermSub T ν m n = Sub (T ν) m n

  record TermLift (T : ℕ → ℕ → Set) : Set where
    infix 10 _↑tm _↑tp
    field
      lift : ∀ {ν n} → T ν n → Term ν n
      _↑tm : ∀ {ν m n} → TermSub T ν m n → TermSub T ν (suc m) (suc n)
      _↑tp : ∀ {ν m n} → TermSub T ν m n → TermSub T (suc ν) m n

  module TermTermApp {T} (l : TermLift T) where
    open TermLift l

    infixl 8 _/_

    -- Apply a term substitution to a term
    _/_ : ∀ {ν m n} → Term ν m → TermSub T ν m n → Term ν n
    var x      / σ = lift $ lookup x σ
    Λ t        / σ = Λ (t / σ ↑tp)
    λ' a t     / σ = λ' a (t / σ ↑tm)
    t [ a ]    / σ = (t / σ) [ a ]
    s · t      / σ = (s / σ) · (t / σ)
    ρ a t      / σ = ρ a (t / σ ↑tm)
    r ⟨⟩        / σ = (r / σ) ⟨⟩
    r with' e  / σ = (r / σ) with' (e / σ)

  Fin′ : ℕ → ℕ → Set
  Fin′ _ m = Fin m

  varLift : TermLift Fin′
  varLift = record { lift = var; _↑tm = VarSubst._↑; _↑tp = Prelude.id }

  infixl 8 _/Var_

  _/Var_ : ∀ {ν m n} → Term ν m → Sub Fin m n → Term ν n
  _/Var_ = TermTermApp._/_ varLift

  private
    module ExpandSimple {n : ℕ} where
      simple : Simple (Term n)
      simple = record { var = var; weaken = λ t → t /Var VarSubst.wk }

      open Simple simple public

  open ExpandSimple  using (_↑; simple)
  open TermTypeSubst using () renaming (weaken to weakenTp)

  termLift : TermLift Term
  termLift = record
    { lift = Prelude.id; _↑tm = _↑ ; _↑tp = λ ρ → map weakenTp ρ }

  private
    module ExpandSubst {ν : ℕ} where
      app : Application (Term ν) (Term ν)
      app = record { _/_ = TermTermApp._/_ termLift {ν = ν} }

      subst : Subst (Term ν)
      subst = record
        { simple      = simple
        ; application = app
        }

      open Subst subst public

  open ExpandSubst public hiding (var; simple)

  infix 8 _[/_]

  -- Shorthand for single-variable term substitutions in terms
  _[/_] : ∀ {ν n} → Term ν (suc n) → Term ν n → Term ν n
  s [/ t ] = s / sub t
