{-# OPTIONS --safe --no-import-sorts #-}

open import Agda.Primitive renaming (Set to Type)
open import Axiom.Set

module Axiom.Set.Properties {ℓ} (th : Theory {ℓ}) where

open import Prelude hiding (isEquivalence; trans; filter)
open Theory th

import Data.List
import Data.Sum
import Function.Related.Propositional as R
open import Data.List.Ext.Properties
open import Data.List.Membership.Propositional using () renaming (_∈_ to _∈ˡ_)
open import Data.List.Membership.Propositional.Properties hiding (finite)
open import Data.Product using (map₂)
open import Function.Related using (toRelated; fromRelated)
open import Relation.Binary
open import Relation.Binary.Lattice
open import Relation.Binary.Morphism
open import Relation.Unary using () renaming (Decidable to Dec₁)

open Equivalence

private variable A B C D : Type ℓ
                 X X' Y Y' Z : Set A

∈-map⁺'' : ∀ {f : A → B} {X} {a} → a ∈ X → f a ∈ map f X
∈-map⁺'' h = to ∈-map (-, refl , h)

∈-filter⁻' : ∀ {X : Set A} {P : A → Type} {sp-P : specProperty P} {a} → a ∈ filter sp-P X → (P a × a ∈ X)
∈-filter⁻' = from ∈-filter

∈-∪⁻ : ∀ {X Y : Set A} {a} → a ∈ X ∪ Y → a ∈ X ⊎ a ∈ Y
∈-∪⁻ = from ∈-∪

∈-map⁻' : ∀ {f : A → B} {X} {b} → b ∈ map f X → (∃[ a ] b ≡ f a × a ∈ X)
∈-map⁻' = from ∈-map

∈-fromList⁻ : ∀ {l : List A} {a} → a ∈ fromList l → a ∈ˡ l
∈-fromList⁻ = from ∈-fromList

∈-filter⁺' : ∀ {X : Set A} {P : A → Type} {sp-P : specProperty P} {a} → (P a × a ∈ X) → a ∈ filter sp-P X
∈-filter⁺' = to ∈-filter

∈-∪⁺ : ∀ {X Y : Set A} {a} → a ∈ X ⊎ a ∈ Y → a ∈ X ∪ Y
∈-∪⁺ = to ∈-∪

∈-map⁺' : ∀ {f : A → B} {X} {b} → (∃[ a ] b ≡ f a × a ∈ X) → b ∈ map f X
∈-map⁺' = to ∈-map

∈-fromList⁺ : ∀ {l : List A} {a} → a ∈ˡ l → a ∈ fromList l
∈-fromList⁺ = to ∈-fromList

open import Tactic.AnyOf
open import Tactic.Defaults

-- Because of missing macro hygiene, we have to copy&paste this. https://github.com/agda/agda/issues/3819
private macro
  ∈⇒P = anyOfⁿᵗ (quote ∈-filter⁻' ∷ quote ∈-∪⁻ ∷ quote ∈-map⁻' ∷ quote ∈-fromList⁻ ∷ [])
  P⇒∈ = anyOfⁿᵗ (quote ∈-filter⁺' ∷ quote ∈-∪⁺ ∷ quote ∈-map⁺' ∷ quote ∈-fromList⁺ ∷ [])
  ∈⇔P = anyOfⁿᵗ (quote ∈-filter⁻' ∷ quote ∈-∪⁻ ∷ quote ∈-map⁻' ∷ quote ∈-fromList⁻ ∷ quote ∈-filter⁺' ∷ quote ∈-∪⁺ ∷ quote ∈-map⁺' ∷ quote ∈-fromList⁺ ∷ [])

-- FIXME: proving this has some weird issues when making a implicit in
-- in the definiton of _≡ᵉ'_
≡ᵉ⇔≡ᵉ' : X ≡ᵉ Y ⇔ X ≡ᵉ' Y
≡ᵉ⇔≡ᵉ' = mk⇔
  (λ where (X⊆Y , Y⊆X) _ → mk⇔ X⊆Y Y⊆X)
  (λ a∈X⇔a∈Y → (λ {_} → to (a∈X⇔a∈Y _)) , λ {_} → from (a∈X⇔a∈Y _))

cong-⊆⇒cong : {f : Set A → Set B} → f Preserves _⊆_ ⟶ _⊆_ → f Preserves _≡ᵉ_ ⟶ _≡ᵉ_
cong-⊆⇒cong h X≡ᵉX' = h (proj₁ X≡ᵉX') , h (proj₂ X≡ᵉX')

cong-⊆⇒cong₂ : {f : Set A → Set B → Set C}
             → f Preserves₂ _⊆_ ⟶ _⊆_ ⟶ _⊆_ → f Preserves₂ _≡ᵉ_ ⟶ _≡ᵉ_ ⟶ _≡ᵉ_
cong-⊆⇒cong₂ h X≡ᵉX' Y≡ᵉY' = h (proj₁ X≡ᵉX') (proj₁ Y≡ᵉY') , h (proj₂ X≡ᵉX') (proj₂ Y≡ᵉY')

⊆-Transitive : Transitive (_⊆_ {A})
⊆-Transitive X⊆Y Y⊆Z = Y⊆Z ∘ X⊆Y

≡ᵉ-isEquivalence : IsEquivalence (_≡ᵉ_ {A})
≡ᵉ-isEquivalence = record
  { refl = id , id
  ; sym = λ where (h , h') → (h' , h)
  ; trans = λ eq₁ eq₂ → ⊆-Transitive (proj₁ eq₁) (proj₁ eq₂) , ⊆-Transitive (proj₂ eq₂) (proj₂ eq₁) }

⊆-isPreorder : IsPreorder (_≡ᵉ_ {A}) _⊆_
⊆-isPreorder = λ where
  .isEquivalence → ≡ᵉ-isEquivalence
  .reflexive     → proj₁
  .trans         → ⊆-Transitive
    where open IsPreorder

⊆-Preorder : {A} → Preorder _ _ _
⊆-Preorder {A} = record { Carrier = Set A ; _≈_ = _≡ᵉ_ ; _∼_ = _⊆_ ; isPreorder = ⊆-isPreorder }

⊆-PartialOrder : IsPartialOrder (_≡ᵉ_ {A}) _⊆_
⊆-PartialOrder = record
  { isPreorder = ⊆-isPreorder
  ; antisym    = _,_ }

∉-∅ : ∀ {a : A} → a ∉ ∅
∉-∅ h = case ∈⇔P h of λ ()

∅-minimum : Minimum (_⊆_ {A}) ∅
∅-minimum = λ _ → ⊥-elim ∘ ∉-∅

∅-least : X ⊆ ∅ → X ≡ᵉ ∅
∅-least X⊆∅ = (X⊆∅ , ∅-minimum _)

∅-weakly-finite : weakly-finite {A = A} ∅
∅-weakly-finite = [] , ⊥-elim ∘ ∉-∅

filter-⊆ : ∀ {P} {sp-P : specProperty P} → filter sp-P X ⊆ X
filter-⊆ = proj₂ ∘′ ∈⇔P

filter-finite : ∀ {P : A → Type}
              → (sp : specProperty P) → Dec₁ P → finite X → finite (filter sp X)
filter-finite {X = X} {P} sp P? (l , hl) = Data.List.filter P? l , λ {a} →
  a ∈ filter sp X            ∼⟨ R.SK-sym ∈-filter ⟩
  (P a × a ∈ X)              ∼⟨ R.K-refl ×-cong hl ⟩
  (P a × a ∈ˡ l)             ∼⟨ mk⇔ (uncurry $ flip $ ∈-filter⁺ P?) (Data.Product.swap ∘ ∈-filter⁻ P?) ⟩
  a ∈ˡ Data.List.filter P? l ∎
  where open R.EquationalReasoning

∪-⊆ˡ : X ⊆ X ∪ Y
∪-⊆ˡ = ∈⇔P ∘′ inj₁

∪-⊆ʳ : Y ⊆ X ∪ Y
∪-⊆ʳ = ∈⇔P ∘′ inj₂

∪-⊆ : X ⊆ Z → Y ⊆ Z → X ∪ Y ⊆ Z
∪-⊆ X⊆Z Y⊆Z = λ a∈X∪Y → [ X⊆Z , Y⊆Z ]′ (∈⇔P a∈X∪Y)

∪-Supremum : Supremum (_⊆_ {A}) _∪_
∪-Supremum _ _ = ∪-⊆ˡ , ∪-⊆ʳ , λ _ → ∪-⊆

∪-cong-⊆ : (_∪_ {A}) Preserves₂ _⊆_ ⟶ _⊆_ ⟶ _⊆_
∪-cong-⊆ X⊆X' Y⊆Y' = ∈⇔P ∘′ (Data.Sum.map X⊆X' Y⊆Y') ∘′ ∈⇔P

∪-cong : (_∪_ {A}) Preserves₂ _≡ᵉ_ ⟶ _≡ᵉ_ ⟶ _≡ᵉ_
∪-cong = cong-⊆⇒cong₂ ∪-cong-⊆

∪-preserves-finite : _∪_ {A} Preservesˢ₂ finite
∪-preserves-finite {a = X} {Y} (l , hX) (l' , hY) = (l ++ l') , λ {a} →
  a ∈ X ∪ Y ∼⟨ R.SK-sym ∈-∪ ⟩
  (a ∈ X ⊎ a ∈ Y) ∼⟨ hX ⊎-cong hY ⟩
  (a ∈ˡ l ⊎ a ∈ˡ l') ∼⟨ mk⇔ Data.Sum.[ ∈-++⁺ˡ , ∈-++⁺ʳ _ ] (∈-++⁻ _) ⟩
  a ∈ˡ l ++ l' ∎
  where open R.EquationalReasoning

∪-sym : X ∪ Y ≡ᵉ Y ∪ X
∪-sym = ∪-⊆ ∪-⊆ʳ ∪-⊆ˡ , ∪-⊆ ∪-⊆ʳ ∪-⊆ˡ

Set-JoinSemilattice : IsJoinSemilattice (_≡ᵉ_ {A}) _⊆_ _∪_
Set-JoinSemilattice = record { isPartialOrder = ⊆-PartialOrder ; supremum = ∪-Supremum }

Set-BoundedJoinSemilattice : IsBoundedJoinSemilattice (_≡ᵉ_ {A}) _⊆_ _∪_ ∅
Set-BoundedJoinSemilattice = record { isJoinSemilattice = Set-JoinSemilattice ; minimum = ∅-minimum }

disjoint-sym : disjoint X Y → disjoint Y X
disjoint-sym disj = flip disj

module Intersectionᵖ (sp-∈ : spec-∈ A) where
  open Intersection sp-∈

  disjoint⇒disjoint' : disjoint X Y → disjoint' X Y
  disjoint⇒disjoint' h = ∅-least (⊥-elim ∘ uncurry h ∘ from ∈-∩)

  disjoint'⇒disjoint : disjoint' X Y → disjoint X Y
  disjoint'⇒disjoint h a∈X a∈Y = ∉-∅ (to (to ≡ᵉ⇔≡ᵉ' h _) (to ∈-∩ (a∈X , a∈Y)))

  ∩-⊆ˡ : X ∩ Y ⊆ X
  ∩-⊆ˡ = proj₁ ∘ from ∈-∩

  ∩-⊆ʳ : X ∩ Y ⊆ Y
  ∩-⊆ʳ = proj₂ ∘ from ∈-∩

  ∩-⊆ : Z ⊆ X → Z ⊆ Y → Z ⊆ X ∩ Y
  ∩-⊆ Z⊆X Z⊆Y = λ x∈Z → to ∈-∩ (< Z⊆X , Z⊆Y > x∈Z)

  ∩-Infimum : Infimum _⊆_ _∩_
  ∩-Infimum X Y = ∩-⊆ˡ , ∩-⊆ʳ , λ _ → ∩-⊆

  ∩-preserves-finite : _∩_ Preservesˢ₂ weakly-finite
  ∩-preserves-finite _ = ⊆-weakly-finite ∩-⊆ʳ

  ∩-cong-⊆ : _∩_ Preserves₂ _⊆_ ⟶ _⊆_ ⟶ _⊆_
  ∩-cong-⊆ X⊆X' Y⊆Y' a∈X∩Y = to ∈-∩ (Data.Product.map X⊆X' Y⊆Y' (from ∈-∩ a∈X∩Y))

  ∩-cong : _∩_ Preserves₂ _≡ᵉ_ ⟶ _≡ᵉ_ ⟶ _≡ᵉ_
  ∩-cong = cong-⊆⇒cong₂ ∩-cong-⊆

  ∩-OrderHomomorphismʳ : ∀ {X} → IsOrderHomomorphism _≡ᵉ_ _≡ᵉ_ _⊆_ _⊆_ (X ∩_)
  ∩-OrderHomomorphismʳ = record { cong = ∩-cong (id , id) ; mono = ∩-cong-⊆ id }

  ∩-OrderHomomorphismˡ : ∀ {X} → IsOrderHomomorphism _≡ᵉ_ _≡ᵉ_ _⊆_ _⊆_ (_∩ X)
  ∩-OrderHomomorphismˡ = record { cong = flip ∩-cong (id , id) ; mono = flip ∩-cong-⊆ id }

  Set-Lattice : IsLattice _≡ᵉ_ _⊆_ _∪_ _∩_
  Set-Lattice =
    record { isPartialOrder = ⊆-PartialOrder ; supremum = ∪-Supremum ; infimum = ∩-Infimum }
