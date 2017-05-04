module LFRef.Welltyped where

open import Prelude

open import Data.List hiding ([_])
open import Data.Vec as Vec hiding ([_]; map)
open import Data.Star hiding (_▻▻_; map)
open import Data.Sum hiding (map)
open import Extensions.List as L using ()

open import LFRef.Syntax hiding (subst)
open import Relation.Binary.List.Pointwise using (Rel)

record ConType (n : ℕ) : Set where
  field
    m : ℕ
    args : Tele n m
    tp   : ℕ
    indices : List (Term m)

Sig : ℕ → Set
Sig n = List (∃ (Tele n)) × List (ConType n)

Ctx : (n : ℕ) → Set
Ctx n = Vec (Type n) n

-- store typings
World : ℕ → Set
World n = List (Type n)

-- assumptions for now
-- these should all be provable/axiomatized
postulate
  _:+:_ : ∀ {n} → Type n → Ctx n → Ctx (suc n)
  weaken-𝕊 : ∀ {n} → Sig n → Sig (suc n)
  weaken-Σ : ∀ {n} → World n → World (suc n)
  weaken-tp : ∀ {n} → Type n → Type (suc n)

  -- TODO constructor wellformedness

-- mutually inductive welltypedness judgments for kinds/types and terms respectively
data _,_,_⊢_teleok : ∀ {n m} → (𝕊 : Sig n) → World n → Ctx n → Tele n m → Set
data _,_,_⊢_::_ : ∀ {n m} (𝕊 : Sig n) → World n → Ctx n → Type n → Tele n m → Set
data _,_,_⊢_∶_ : ∀ {n} (𝕊 : Sig n) → World n → Ctx n → Term n → Type n → Set

data _,_,_⊢_teleok where
  ε : ∀ {n 𝕊 Σ} {Γ : Ctx n} → 𝕊 , Σ , Γ ⊢ ε teleok

  _⟶_ : ∀ {n m 𝕊 Σ Γ} {A : Type n} {K : Tele (suc n) m}→
        𝕊 , Σ , Γ ⊢ A :: ε →
        weaken-𝕊 𝕊 , weaken-Σ Σ , (A :+: Γ) ⊢ K teleok →
        𝕊 , Σ , Γ ⊢ (A ⟶ K) teleok

data _,_,_⊢_∶ⁿ_ {n} (𝕊 : Sig n) (Σ : World n) (Γ : Ctx n) : ∀ {m} → List (Term n) → Tele n m → Set where

  ε : 𝕊 , Σ , Γ ⊢ [] ∶ⁿ ε

  _⟶_ : ∀ {m A t ts} {B : Tele (suc n) m}→
        𝕊 , Σ , Γ ⊢ t ∶ A →
        𝕊 , Σ , Γ ⊢ ts ∶ⁿ (B tele/ (sub t)) →
        𝕊 , Σ , Γ ⊢ (t ∷ ts) ∶ⁿ (A ⟶ B)

lem : ∀ {n m 𝕊 Σ Γ ts} {T : Tele n m} → 𝕊 , Σ , Γ ⊢ ts ∶ⁿ T → length ts ≡ m
lem ε = refl
lem (x ⟶ p) with lem p
lem (x ⟶ p) | refl = refl

-- construct the type of the term returned from a proper, complete constructor application
_con[/_] : ∀ {n 𝕊 Σ Γ ts} → (C : ConType n) → 𝕊 , Σ , Γ ⊢ ts ∶ⁿ (ConType.args C) → Type n
_con[/_] {ts = ts} record { m = m ; args = args ; tp = tp ; indices = indices } p =
  tp [ map (flip _/_ (subst (Vec _) (lem p) (fromList ts))) indices ]

data _,_,_⊢_::_ where

  Ref : ∀ {n 𝕊 Σ} {Γ : Ctx n} {A} →
        𝕊 , Σ , Γ ⊢ A :: ε →
        ----------------------
        𝕊 , Σ , Γ ⊢ Ref A :: ε

  Unit : ∀ {n 𝕊 Σ} {Γ : Ctx n} →
        ----------------------
        𝕊 , Σ , Γ ⊢ Unit :: ε

  _[_] : ∀ {n 𝕊 Σ} {Γ : Ctx n} {k K ts} →
         (proj₁ 𝕊) L.[ k ]= K →
         𝕊 , Σ , Γ ⊢ (proj₂ K) teleok →
         𝕊 , Σ , Γ ⊢ ts ∶ⁿ (proj₂ K) →
         ---------------------------------
         𝕊 , Σ , Γ ⊢ k [ ts ] :: ε

data _,_,_⊢_∶_ where

  unit : ∀ {n 𝕊 Σ} {Γ : Ctx n} →
        ---------------------------------
        𝕊 , Σ , Γ ⊢ unit ∶ Unit

  var : ∀ {n 𝕊 Σ} {Γ : Ctx n} {i A} →
        Γ [ i ]= A →
        ---------------------------------
        𝕊 , Σ , Γ ⊢ var i ∶ A

  con : ∀ {n 𝕊 Σ} {Γ : Ctx n} {c C ts} →
        (proj₂ 𝕊) L.[ c ]= C →
        (p : 𝕊 , Σ , Γ ⊢ ts ∶ⁿ (ConType.args C)) →
        ---------------------------------
        𝕊 , Σ , Γ ⊢ con c ts ∶ (C con[/ p ])

  loc : ∀ {n 𝕊 Σ} {Γ : Ctx n} {i S} →
        Σ L.[ i ]= S →
        ---------------------------------
        𝕊 , Σ , Γ ⊢ loc i ∶ S

data _,_,_⊢ₑ_∶_ : ∀ {n} (𝕊 : Sig n) → World n → Ctx n → Exp n → Type n → Set where

  tm   : ∀ {n t} {Γ : Ctx n} {𝕊 Σ A} →
         𝕊 , Σ , Γ ⊢ t ∶ A →
         -----------------
         𝕊 , Σ , Γ ⊢ₑ tm t ∶ A

  lett : ∀ {n x c A B 𝕊 Σ} {Γ : Ctx n} →
         𝕊 , Σ , Γ ⊢ₑ x ∶ A →
         (weaken-𝕊 𝕊) , (weaken-Σ Σ) , (A :+: Γ) ⊢ₑ c ∶ weaken-tp B →
         ---------------------------------------------
         𝕊 , Σ , Γ ⊢ₑ lett x c ∶ B

  ref : ∀ {n x A 𝕊 Σ} {Γ : Ctx n} →
        𝕊 , Σ , Γ ⊢ₑ x ∶ A →
        ---------------------------------------
        𝕊 , Σ , Γ ⊢ₑ ref x ∶ Ref A

  !_  : ∀ {n x A} {Γ : Ctx n} {𝕊 Σ} →
        𝕊 , Σ , Γ ⊢ₑ x ∶ Ref A →
        ---------------------------------------
        𝕊 , Σ , Γ ⊢ₑ (! x) ∶ A

  _≔_ : ∀ {n i x A} {Γ : Ctx n} {𝕊 Σ} →
        𝕊 , Σ , Γ ⊢ₑ i ∶ Ref A →
        𝕊 , Σ , Γ ⊢ₑ x ∶ A →
        ---------------------------------------
        𝕊 , Σ , Γ ⊢ₑ (i ≔ x) ∶ Unit

-- store welltypedness relation
-- as a pointwise lifting of the welltyped relation on closed expressions between a world and a store
_,_,_⊢_ : ∀ {n} → Sig n → World n → Ctx n → Store n → Set
𝕊 , Σ , Γ ⊢ μ = Rel (λ A x → 𝕊 , Σ , Γ ⊢ x ∶ A) Σ μ
