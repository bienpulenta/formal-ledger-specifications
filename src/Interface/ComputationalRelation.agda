{-# OPTIONS --safe #-}

module Interface.ComputationalRelation where

open import Prelude

open import Interface.DecEq

open import Relation.Binary.PropositionalEquality
open import Relation.Nullary

infix -150 ∙_
infixr -100 _∙_
infix -50 _────────────────────────────────_
_────────────────────────────────_ : Set → Set → Set
A ──────────────────────────────── B = A → B

_∙_ : Set → Set → Set
A ∙ B = A → B

∙_ : Set → Set
∙ A = A

private
  variable
    C S Sig : Set
    c : C
    s s' s'' : S
    sig : Sig

module _ (STS : C → S → Sig → S → Set) where

  record Computational : Set where
    constructor MkComputational
    field
      compute : C → S → Sig → Maybe S
      ≡-just⇔STS : compute c s sig ≡ just s' ⇔ STS c s sig s'

  ExtendedRel : C → S → Sig → Maybe S → Set
  ExtendedRel c s sig (just s') = STS c s sig s'
  ExtendedRel c s sig nothing   = ∀ s' → ¬ STS c s sig s'

module _ {STS : C → S → Sig → S → Set} (comp : Computational STS) where

  open Computational comp

  ExtendedRelSTS = ExtendedRel STS

  ExtendedRel-compute : ExtendedRelSTS c s sig (compute c s sig)
  ExtendedRel-compute {c} {s} {sig} with compute c s sig | inspect (compute c s) sig
  ... | just s' | [ eq ] = Equivalence.to ≡-just⇔STS eq
  ... | nothing | [ eq ] = λ s' h → case trans (sym $ Equivalence.from ≡-just⇔STS h) eq of λ ()

  ExtendedRel-rightUnique : ExtendedRelSTS c s sig s' → ExtendedRelSTS c s sig s'' → s' ≡ s''
  ExtendedRel-rightUnique {s' = just x}  {just x'} h h' = trans (sym $ Equivalence.from ≡-just⇔STS h) (Equivalence.from ≡-just⇔STS h')
  ExtendedRel-rightUnique {s' = just x}  {nothing} h h' = ⊥-elim $ h' x h
  ExtendedRel-rightUnique {s' = nothing} {just x'} h h' = ⊥-elim $ h x' h'
  ExtendedRel-rightUnique {s' = nothing} {nothing} h h' = refl

  computational⇒rightUnique : STS c s sig s' → STS c s sig s'' → s' ≡ s''
  computational⇒rightUnique h h' with ExtendedRel-rightUnique h h'
  ... | refl = refl

  Computational⇒Dec : ⦃ _ : DecEq S ⦄ → Dec (STS c s sig s')
  Computational⇒Dec {c} {s} {sig} {s'} with compute c s sig | ExtendedRel-compute {c} {s} {sig}
  ... | nothing | ExSTS = no (ExSTS s')
  ... | just x  | ExSTS with x ≟ s'
  ... | no ¬p    = no  λ h → ¬p $ sym $ computational⇒rightUnique h ExSTS
  ... | yes refl = yes ExSTS

module _ {STS : C → S → Sig → S → Set} (comp comp' : Computational STS) where

  open Computational comp  renaming (compute to compute₁)
  open Computational comp' renaming (compute to compute₂)

  compute-ext≡ : compute₁ c s sig ≡ compute₂ c s sig
  compute-ext≡ = ExtendedRel-rightUnique comp (ExtendedRel-compute comp) (ExtendedRel-compute comp')

Computational⇒Dec' : ⦃ _ : DecEq S ⦄ {STS : C → S → Sig → S → Set} ⦃ comp : Computational STS ⦄
                      → Dec (STS c s sig s')
Computational⇒Dec' ⦃ comp = comp ⦄ = Computational⇒Dec comp
