module Impure.LFRef.Welltyped where

open import Prelude

open import Data.List hiding ([_])
open import Data.List.All hiding (map)
open import Data.Vec as Vec hiding ([_]; map)
open import Data.Star hiding (_▻▻_; map)
open import Data.Sum hiding (map)
open import Extensions.List as L using ()

open import Impure.LFRef.Syntax hiding (subst)
open import Relation.Binary.List.Pointwise using (Rel)

Ctx : (n : ℕ) → Set
Ctx n = Vec (Type n) n

-- store typings
World : Set
World = List (Type 0)

weaken₁-tp : ∀ {n} → Type n → Type (suc n)
weaken₁-tp tp = tp tp/ wk

_:+:_ : ∀ {n} → Type n → Ctx n → Ctx (suc n)
a :+: Γ = (weaken₁-tp a) ∷ (Vec.map (flip _tp/_ wk) Γ)

weaken+-tm : ∀ {m} n → Term m → Term (n + m)
weaken+-tm n t = t / (wk⋆ n)

weaken+-tp : ∀ n → Type 0 → Type n
weaken+-tp zero t = t
weaken+-tp (suc n) t = subst Type (+-right-identity (suc n)) (t tp/ (wk⋆ (suc n)))

weaken+-tele : ∀ {m n} k → Tele n m → Tele (n + k) m
weaken+-tele k T = subst (flip Tele _) (+-comm k _) (T tele/ (wk⋆ k))

-- mutually inductive welltypedness judgments for kinds/types and terms respectively
data _,_,_⊢_teleok : ∀ {n m} → (𝕊 : Sig) → World → Ctx n → Tele n m → Set
data _,_,_⊢_::_ : ∀ {n m} (𝕊 : Sig) → World → Ctx n → Type n → Tele n m → Set
data _,_,_⊢_∶_ : ∀ {n} (𝕊 : Sig) → World → Ctx n → Term n → Type n → Set

data _,_,_⊢_teleok where
  ε : ∀ {n 𝕊 Σ} {Γ : Ctx n} → 𝕊 , Σ , Γ ⊢ ε teleok

  _⟶_ : ∀ {n m 𝕊 Σ Γ} {A : Type n} {K : Tele (suc n) m}→
        𝕊 , Σ , Γ ⊢ A :: ε →
        𝕊 , Σ , (A :+: Γ) ⊢ K teleok →
        𝕊 , Σ , Γ ⊢ (A ⟶ K) teleok

data _,_,_⊢_∶ⁿ_ {n} (𝕊 : Sig) (Σ : World) (Γ : Ctx n) :
     ∀ {m} → List (Term n) → Tele n m → Set where

  ε : 𝕊 , Σ , Γ ⊢ [] ∶ⁿ ε

  _⟶_ : ∀ {m A t ts} {B : Tele (suc n) m}→
        𝕊 , Σ , Γ ⊢ t ∶ A →
        𝕊 , Σ , Γ ⊢ ts ∶ⁿ (B tele/ (sub t)) →
        𝕊 , Σ , Γ ⊢ (t ∷ ts) ∶ⁿ (A ⟶ B)

-- specialize the returntype from a constructor from it's welltyped arguments
_con[_/_] : ∀ {n} → (C : ConType) → (ts : List (Term n)) → length ts ≡ (ConType.m C) → Type n
_con[_/_] {n} C ts p =
  (ConType.tp C) [
    map
      (flip _/_ (subst (Vec _) p (fromList ts)))
      (ConType.indices C)
  ]

-- specialize the return type of a function from it's welltyped arguments
_fun[_/_] : ∀ {n m} → Type m → (ts : List (Term n)) → length ts ≡ m → Type n
_fun[_/_] {n} {m} a ts p = a tp/ subst (Vec _) p ((fromList ts))

data _,_,_⊢_::_ where

  Ref : ∀ {n 𝕊 Σ} {Γ : Ctx n} {A} →
        𝕊 , Σ , Γ ⊢ A :: ε →
        ----------------------
        𝕊 , Σ , Γ ⊢ Ref A :: ε

  Unit : ∀ {n 𝕊 Σ} {Γ : Ctx n} →
        ---------------------
        𝕊 , Σ , Γ ⊢ Unit :: ε

  _[_] : ∀ {n 𝕊 Σ} {Γ : Ctx n} {k K ts} →
         (Sig.types 𝕊) L.[ k ]= K →
         𝕊 , [] , [] ⊢ (proj₂ K) teleok →
         𝕊 , Σ , Γ ⊢ ts ∶ⁿ (weaken+-tele n (proj₂ K)) →
         -------------------------
         𝕊 , Σ , Γ ⊢ k [ ts ] :: ε

data _,_,_⊢_∶_ where

  unit : ∀ {n 𝕊 Σ} {Γ : Ctx n} →
        -----------------------
        𝕊 , Σ , Γ ⊢ unit ∶ Unit

  var : ∀ {n 𝕊 Σ} {Γ : Ctx n} {i A} →
        Γ [ i ]= A →
        ---------------------
        𝕊 , Σ , Γ ⊢ var i ∶ A

  con : ∀ {n 𝕊 Σ} {Γ : Ctx n} {c C ts} →
        (Sig.constructors 𝕊) L.[ c ]= C →
        (p : 𝕊 , Σ , Γ ⊢ ts ∶ⁿ weaken+-tele n (ConType.args C)) →
        (q : length ts ≡ (ConType.m C)) →
        ------------------------------------
        𝕊 , Σ , Γ ⊢ con c ts ∶ (C con[ ts / q ])

  loc : ∀ {n 𝕊 Σ} {Γ : Ctx n} {i S} →
        Σ L.[ i ]= S →
        ---------------------
        𝕊 , Σ , Γ ⊢ loc i ∶ Ref (weaken+-tp n S)

data _,_,_⊢ₑ_∶_ : ∀ {n} (𝕊 : Sig) → World → Ctx n → Exp n → Type n → Set where

  tm   : ∀ {n t} {Γ : Ctx n} {𝕊 Σ A} →
         𝕊 , Σ , Γ ⊢ t ∶ A →
         ---------------------
         𝕊 , Σ , Γ ⊢ₑ tm t ∶ A

  _·★[_]_ : ∀ {n fn ts 𝕊 Σ φ} {Γ : Ctx n} →
         (Sig.funs 𝕊) L.[ fn ]= φ →
         (q : length ts ≡ (Fun.m φ)) →
         (p : 𝕊 , Σ , Γ ⊢ ts ∶ⁿ weaken+-tele n (Fun.args φ)) →
         -----------------------------------------------------
         𝕊 , Σ , Γ ⊢ₑ (fn ·★ ts) ∶ ((Fun.returntype φ) fun[ ts / q ])

  ref : ∀ {n x A 𝕊 Σ} {Γ : Ctx n} →
        𝕊 , Σ , Γ ⊢ₑ x ∶ A →
        --------------------------
        𝕊 , Σ , Γ ⊢ₑ ref x ∶ Ref A

  !_  : ∀ {n x A} {Γ : Ctx n} {𝕊 Σ} →

        𝕊 , Σ , Γ ⊢ₑ x ∶ Ref A →
        ----------------------
        𝕊 , Σ , Γ ⊢ₑ (! x) ∶ A

  _≔_ : ∀ {n i x A} {Γ : Ctx n} {𝕊 Σ} →
        𝕊 , Σ , Γ ⊢ₑ i ∶ Ref A →
        𝕊 , Σ , Γ ⊢ₑ x ∶ A →
        --------------------------
        𝕊 , Σ , Γ ⊢ₑ (i ≔ x) ∶ Unit

data _,_,_⊢ₛ_∶_ : ∀ {n} (𝕊 : Sig) → World → Ctx n → SeqExp n → Type n → Set where

  ret  : ∀ {n x A 𝕊 Σ} {Γ : Ctx n} →
         𝕊 , Σ , Γ ⊢ₑ x ∶ A →
         ---------------------
         𝕊 , Σ , Γ ⊢ₛ ret x ∶ A

  lett : ∀ {n x c A B 𝕊 Σ} {Γ : Ctx n} →
         𝕊 , Σ , Γ ⊢ₑ x ∶ A →
         𝕊 , (Σ) , (A :+: Γ) ⊢ₛ c ∶ weaken₁-tp B →
         ---------------------------------------r
         𝕊 , Σ , Γ ⊢ₛ lett x c ∶ B

-- telescopes as context transformers
_⊢⟦_⟧ : ∀ {n m} → Ctx n → Tele n m → Ctx (n + m)
Γ ⊢⟦ ε ⟧ = subst Ctx (sym $ +-right-identity _) Γ
_⊢⟦_⟧ {n} Γ (_⟶_ {m = m} x T) = subst Ctx (sym $ +-suc n m) ((x :+: Γ) ⊢⟦ T ⟧)

_⊢_fnOk : Sig → Fun → Set
_⊢_fnOk 𝕊 φ = 𝕊 , [] , ([] ⊢⟦ Fun.args φ ⟧) ⊢ₑ (Fun.body φ) ∶ (Fun.returntype φ)

-- valid signature contexts
record _,_⊢ok {n} (𝕊 : Sig) (Γ : Ctx n) : Set where
  field
    funs-ok : All (λ x → 𝕊 ⊢ x fnOk) (Sig.funs 𝕊)

-- store welltypedness relation
-- as a pointwise lifting of the welltyped relation on closed expressions between a world and a store
_,_⊢_ : Sig → World → Store → Set
_,_⊢_ 𝕊 Σ μ = Rel (λ A x → 𝕊 , Σ , [] ⊢ (proj₁ x) ∶ A) Σ μ

-- a useful lemma about telescoped terms
tele-fit-length : ∀ {n m 𝕊 Σ Γ ts} {T : Tele n m} → 𝕊 , Σ , Γ ⊢ ts ∶ⁿ T → length ts ≡ m
tele-fit-length ε = refl
tele-fit-length (x ⟶ p) with tele-fit-length p
tele-fit-length (x ⟶ p) | refl = refl
