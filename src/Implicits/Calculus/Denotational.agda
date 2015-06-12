module Implicits.Calculus.Denotational where

open import Prelude

open import Implicits.Calculus.WellTyped
open import Implicits.SystemF.WellTyped as F using ()
open import Extensions.ListFirst
open import Data.Fin.Substitution
open import Data.Vec.Properties

⟦_⟧tp : ∀ {ν} → Type ν → F.Type ν
⟦ tvar n ⟧tp = F.tvar n
⟦ a →' b ⟧tp = ⟦ a ⟧tp F.→' ⟦ b ⟧tp
⟦ a ⇒ b ⟧tp = ⟦ a ⟧tp F.→' ⟦ b ⟧tp

⟦_⟧pt : ∀ {ν} → PolyType ν → F.Type ν
⟦ mono tp ⟧pt = ⟦ tp ⟧tp
⟦ ∀' x ⟧pt = F.∀' ⟦ x ⟧pt

⟦_⟧tps : ∀ {ν n} → Vec (Type ν) n → Vec (F.Type ν) n
⟦ v ⟧tps = map (⟦_⟧tp) v

⟦_⟧ctx : ∀ {ν n} → Ktx ν n → F.Ctx ν n
⟦ Γ , Δ ⟧ctx = map ⟦_⟧pt Γ

-- construct an System F term from an implicit resolution
⟦_⟧i : ∀ {ν n} {K : Ktx ν n} {a} → K Δ↝ a → F.Term ν n

⟦_⟧ : ∀ {ν n} {K : Ktx ν n} {t} {a : PolyType ν} → K ⊢ t ∈ a → F.Term ν n
⟦_⟧ (var x) = F.var x
⟦_⟧ (Λ t) = F.Λ ⟦ t ⟧
⟦_⟧ (λ' a x) = F.λ' ⟦ a ⟧tp ⟦ x ⟧
⟦_⟧ (f [ b ]) = F._[_] ⟦ f ⟧ ⟦ b ⟧tp
⟦_⟧ (f · e) = ⟦ f ⟧ F.· ⟦ e ⟧
⟦_⟧ (ρ a x) = F.λ' ⟦ a ⟧tp ⟦ x ⟧
⟦_⟧ (_⟨⟩ f e∈Δ) = ⟦ f ⟧ F.· ⟦ e∈Δ ⟧i
⟦_⟧ (let'_in'_ {a = a} t e) = (F.λ' ⟦ a ⟧pt ⟦ e ⟧) F.· ⟦ t ⟧
⟦_⟧ (implicit_in'_ {a = a} t e) = (F.λ' ⟦ a ⟧pt ⟦ e ⟧) F.· ⟦ t ⟧

⟦_⟧i (r , p) with first⟶witness p
⟦_⟧i {ν} {n} {proj₁ , proj₂} (a₁ , p) | by-value x = {!!}
⟦_⟧i {ν} {n} {proj₁ , proj₂} (._ , p) | yields x x₁ = {!!}

-- lookup in and interpreted context Γ is equivalent to interpreting a type, looked up in K
lookup⋆⟦⟧ctx : ∀ {ν n} (K : Ktx ν n) x → lookup x ⟦ K ⟧ctx ≡ ⟦ lookup x $ proj₁ K ⟧pt
lookup⋆⟦⟧ctx K x = sym $ lookup⋆map (proj₁ K) ⟦_⟧pt x

module Lemmas where
  module TS = TypeSubst
  module FTS = F.TypeSubst
  module PTS = PTypeSubst
  
  private
    module tss = Simple TS.simple
    module ftss = Simple FTS.simple

  -- implicitly constructed F-terms preserve type
  postulate ⟦⟧i-wt-lemma : ∀ {ν n} {K : Ktx ν n} {a} (i : K Δ↝ a) → ⟦ K ⟧ctx F.⊢ ⟦ i ⟧i ∈ ⟦ a ⟧pt

  -- type in type substitution commutes with type interpretation
  postulate tp/tp⋆⟦⟧ctx : ∀ {ν} (a : PolyType (suc ν)) b → ⟦ a ptp[/tp b ] ⟧pt ≡ ⟦ a ⟧pt F.tp[/tp ⟦ b ⟧tp ]

  postulate weaken⋆⟦_⟧tp : ∀ {ν} → _≗_ {A = Type ν} (⟦_⟧tp ∘ tss.weaken) (ftss.weaken ∘ ⟦_⟧tp)

  -- helper lemma on mapping type-semantics over weakend substitutions
  ⟦⟧tps⋆weaken : ∀ {ν n} (xs : Vec (Type ν) n) → 
                 ⟦ (map tss.weaken xs) ⟧tps ≡ (map ftss.weaken ⟦ xs ⟧tps)
  ⟦⟧tps⋆weaken xs = begin
    (map ⟦_⟧tp ∘ map tss.weaken) xs
     ≡⟨ sym $ (map-∘ ⟦_⟧tp tss.weaken) xs ⟩
    map (⟦_⟧tp ∘ tss.weaken) xs
     ≡⟨ (map-cong weaken⋆⟦_⟧tp) xs ⟩
    map (ftss.weaken ∘ ⟦_⟧tp) xs
     ≡⟨ (map-∘ ftss.weaken ⟦_⟧tp) xs ⟩ 
    map ftss.weaken (map ⟦_⟧tp xs) ∎
     
  -- the semantics of identity type-substitution is exactly 
  -- system-f's identity type substitution
  ⟦id⟧≡fid : ∀ {n} → map ⟦_⟧tp (TS.id {n}) ≡ FTS.id
  ⟦id⟧≡fid {zero} = refl
  ⟦id⟧≡fid {suc n} = begin
    map ⟦_⟧tp (tvar zero ∷ map tss.weaken (TS.id {n})) 
      ≡⟨ refl ⟩
    F.tvar zero ∷ (map ⟦_⟧tp (map tss.weaken (TS.id {n}))) 
      ≡⟨ cong (_∷_ (F.tvar zero)) (⟦⟧tps⋆weaken (TS.id {n})) ⟩
    F.tvar zero ∷ (map ftss.weaken (map ⟦_⟧tp (TS.id {n}))) 
      ≡⟨ cong (λ e → F.tvar zero ∷ (map ftss.weaken e)) ⟦id⟧≡fid ⟩
    F.tvar zero ∷ (map ftss.weaken (FTS.id {n})) 
      ≡⟨ refl ⟩
    FTS.id ∎
  
  -- the semantics of type weakening is exactly system-f's type weakening
  ⟦wk⟧≡fwk : ∀ {n} → map ⟦_⟧tp (TS.wk {n}) ≡ FTS.wk {n}
  ⟦wk⟧≡fwk = begin
    map ⟦_⟧tp TS.wk 
      ≡⟨ ⟦⟧tps⋆weaken TS.id ⟩
    map ftss.weaken (map ⟦_⟧tp TS.id) 
      ≡⟨ cong (map ftss.weaken) ⟦id⟧≡fid ⟩
    FTS.wk ∎

  -- interpretation of contexts 
  ⟦⟧tps⋆↑ :  ∀ {ν n} (v : Vec (Type ν) n) → ⟦ v TS.↑ ⟧tps ≡ ⟦ v ⟧tps FTS.↑
  ⟦⟧tps⋆↑ xs = begin
    F.tvar zero ∷ (map ⟦_⟧tp (map tss.weaken xs)) 
      ≡⟨ cong (_∷_ (F.tvar zero)) (⟦⟧tps⋆weaken xs) ⟩
    F.tvar zero ∷ (map ftss.weaken (map ⟦_⟧tp xs)) 
      ≡⟨ refl ⟩
    (map ⟦_⟧tp xs) FTS.↑ ∎

  -- type substitution commutes with interpreting types
  /⋆⟦⟧tp : ∀ {ν μ} (tp : Type ν) (σ : Sub Type ν μ) → ⟦ tp TS./ σ ⟧tp ≡ ⟦ tp ⟧tp FTS./ (map ⟦_⟧tp σ)
  /⋆⟦⟧tp (tvar n) σ = begin
    ⟦ lookup n σ ⟧tp 
      ≡⟨ lookup⋆map σ ⟦_⟧tp n ⟩
    ⟦ tvar n ⟧tp FTS./ (map ⟦_⟧tp σ) ∎
  /⋆⟦⟧tp (l →' r) σ = cong₂ F._→'_ (/⋆⟦⟧tp l σ) (/⋆⟦⟧tp r σ)
  /⋆⟦⟧tp (l ⇒ r) σ = cong₂ F._→'_ (/⋆⟦⟧tp l σ) (/⋆⟦⟧tp r σ)

  -- polytype substitution commutes with interpreting types
  /⋆⟦⟧pt : ∀ {ν μ} (tp : PolyType ν) (σ : Sub Type ν μ) → ⟦ tp PTS./ σ ⟧pt ≡ ⟦ tp ⟧pt FTS./ (map ⟦_⟧tp σ)
  /⋆⟦⟧pt (mono x) σ = /⋆⟦⟧tp x σ
  /⋆⟦⟧pt (∀' tp) σ = begin
    F.∀' (⟦ tp PTS./ (σ TS.↑) ⟧pt) 
      ≡⟨ cong F.∀' (/⋆⟦⟧pt tp (σ TS.↑)) ⟩
    F.∀' (⟦ tp ⟧pt FTS./ (map ⟦_⟧tp (σ TS.↑))) 
      ≡⟨ cong (λ e → F.∀' (⟦ tp ⟧pt FTS./ e)) (⟦⟧tps⋆↑ σ) ⟩
    ⟦ ∀' tp ⟧pt FTS./ (map ⟦_⟧tp σ) ∎

  -- type weakening commutes with interpreting types
  {-
  weaken-tp⋆⟦⟧tp : ∀ {ν} (tp : Type ν) → ⟦ tp TS./ TS.wk ⟧tp ≡ ⟦ tp ⟧tp FTS./ FTS.wk
  weaken-tp⋆⟦⟧tp tp = begin
    ⟦ tp TS./ TS.wk ⟧tp 
      ≡⟨ /⋆⟦⟧tp tp TS.wk ⟩
    ⟦ tp ⟧tp FTS./ (map ⟦_⟧tp TS.wk) 
      ≡⟨ cong (λ e → ⟦ tp ⟧tp FTS./ e) ⟦wk⟧≡fwk ⟩
    ⟦ tp ⟧tp FTS./ FTS.wk ∎
  -}

  -- type weakening commutes with interpreting types
  weaken-pt⋆⟦⟧pt : ∀ {ν} (tp : PolyType ν) → ⟦ tp PTS./ TS.wk ⟧pt ≡ ⟦ tp ⟧pt FTS./ FTS.wk
  weaken-pt⋆⟦⟧pt tp = begin
    ⟦ tp PTS./ TS.wk ⟧pt
      ≡⟨ /⋆⟦⟧pt tp TS.wk ⟩
    ⟦ tp ⟧pt FTS./ (map ⟦_⟧tp TS.wk) 
      ≡⟨ cong (λ e → ⟦ tp ⟧pt FTS./ e) ⟦wk⟧≡fwk ⟩
    ⟦ tp ⟧pt FTS./ FTS.wk ∎

  -- context weakening commutes with interpreting contexts
  ctx-weaken⋆⟦⟧ctx : ∀ {ν n} (K : Ktx ν n) → ⟦ ktx-weaken K ⟧ctx ≡ F.ctx-weaken ⟦ K ⟧ctx
  ctx-weaken⋆⟦⟧ctx ([] , Δ) = refl
  ctx-weaken⋆⟦⟧ctx (x ∷ Γ , Δ) with ctx-weaken⋆⟦⟧ctx (Γ , Δ)
  ctx-weaken⋆⟦⟧ctx (x ∷ Γ , Δ) | ih = begin
    ⟦ ktx-weaken (x ∷ Γ , Δ) ⟧ctx ≡⟨ refl ⟩ 
    ⟦ x PTS./ TS.wk ⟧pt ∷ xs ≡⟨ cong (flip _∷_ xs) (weaken-pt⋆⟦⟧pt x) ⟩
    ⟦ x ⟧pt FTS./ FTS.wk ∷ ⟦ ktx-weaken (Γ , Δ) ⟧ctx ≡⟨ cong (_∷_ (⟦ x ⟧pt FTS./ FTS.wk)) ih ⟩
    ⟦ x ⟧pt FTS./ FTS.wk ∷ F.ctx-weaken ⟦ Γ , Δ ⟧ctx ≡⟨ refl ⟩
    F.ctx-weaken ⟦ x ∷ Γ , Δ ⟧ctx ∎
    where
      xs = map ⟦_⟧pt $ map (λ s → s PTS./ TS.wk ) Γ

open Lemmas

-- interpretation of well-typed terms in System F preserves type
⟦⟧-preserves-tp : ∀ {ν n} {K : Ktx ν n} {t a} → (wt-t : K ⊢ t ∈ a) → ⟦ K ⟧ctx F.⊢ ⟦ wt-t ⟧ ∈ ⟦ a ⟧pt
⟦⟧-preserves-tp {K = K} (var x) = subst-wt-var (lookup⋆⟦⟧ctx K x) (F.var x)
  where
    subst-wt-var = subst (λ a → ⟦ K ⟧ctx F.⊢ (F.var x) ∈ a)
⟦⟧-preserves-tp {K = K} {a = ∀' a} (Λ wt-e) with ⟦⟧-preserves-tp wt-e 
... | f-wt-e = F.Λ (subst-wt-ctx (ctx-weaken⋆⟦⟧ctx K) f-wt-e)
  where
    subst-wt-ctx = subst (λ c → c F.⊢ ⟦ wt-e ⟧ ∈ ⟦ a ⟧pt)
⟦⟧-preserves-tp (λ' a wt-e) with ⟦⟧-preserves-tp wt-e
⟦⟧-preserves-tp (λ' a wt-e) | x = F.λ' ⟦ a ⟧tp x
⟦⟧-preserves-tp {K = K} (_[_] {a = a} wt-tc b) with ⟦⟧-preserves-tp wt-tc
... | x = subst-tp (sym $ tp/tp⋆⟦⟧ctx a b) (x F.[ ⟦ b ⟧tp ])
  where
    subst-tp = subst (λ c → ⟦ K ⟧ctx F.⊢ ⟦ wt-tc [ b ] ⟧ ∈ c) 
⟦⟧-preserves-tp (wt-f · wt-e) with ⟦⟧-preserves-tp wt-f | ⟦⟧-preserves-tp wt-e
⟦⟧-preserves-tp (wt-f · wt-e) | x | y = x F.· y
⟦⟧-preserves-tp (ρ a wt-e) with ⟦⟧-preserves-tp wt-e
⟦⟧-preserves-tp (ρ a wt-e) | x = F.λ' ⟦ a ⟧tp x
⟦⟧-preserves-tp (_⟨⟩ wt-r e) with ⟦⟧-preserves-tp wt-r 
⟦⟧-preserves-tp (_⟨⟩ wt-r e) | f-wt-r = let wt-f-e = ⟦⟧i-wt-lemma e in f-wt-r F.· wt-f-e
⟦⟧-preserves-tp (let' wt-e₁ in' wt-e₂) with ⟦⟧-preserves-tp wt-e₁ | ⟦⟧-preserves-tp wt-e₂
⟦⟧-preserves-tp (let'_in'_ {a = a} wt-e₁ wt-e₂) | x | y = (F.λ' ⟦ a ⟧pt y) F.· x
⟦⟧-preserves-tp (implicit wt-e₁ in' wt-e₂) with ⟦⟧-preserves-tp wt-e₁ | ⟦⟧-preserves-tp wt-e₂
⟦⟧-preserves-tp (implicit_in'_ {a = a} wt-e₁ wt-e₂) | x | y = (F.λ' ⟦ a ⟧pt y) F.· x
