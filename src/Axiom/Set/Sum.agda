{-# OPTIONS --safe --no-import-sorts #-}

open import Agda.Primitive renaming (Set to Type)
open import Axiom.Set
open import Algebra using (CommutativeMonoid)

open import Prelude

module Axiom.Set.Sum (th : Theory {lzero}) ⦃ M : CommutativeMonoid 0ℓ 0ℓ ⦄ where
open Theory th
open import Axiom.Set.Factor th
open import Axiom.Set.Properties th
open import Axiom.Set.Rel th
open import Axiom.Set.Map th

open import Algebra.Properties.CommutativeSemigroup
open import Data.List.Ext.Properties
open import Data.List.Relation.Binary.Permutation.Propositional
open import Data.List.Relation.Unary.Unique.Propositional
open import Interface.DecEq
open import Relation.Binary hiding (Rel)
open import Relation.Nullary.Decidable using (¬?)
open import Relation.Unary using () renaming (Decidable to Dec₁)

open import Tactic.AnyOf
open import Tactic.Defaults

-- Because of missing macro hygiene, we have to copy&paste this. https://github.com/agda/agda/issues/3819
private macro
  ∈⇒P = anyOfⁿᵗ (quote ∈-filter⁻' ∷ quote ∈-∪⁻ ∷ quote ∈-map⁻' ∷ quote ∈-fromList⁻ ∷ [])
  P⇒∈ = anyOfⁿᵗ (quote ∈-filter⁺' ∷ quote ∈-∪⁺ ∷ quote ∈-map⁺' ∷ quote ∈-fromList⁺ ∷ [])
  ∈⇔P = anyOfⁿᵗ (quote ∈-filter⁻' ∷ quote ∈-∪⁻ ∷ quote ∈-map⁻' ∷ quote ∈-fromList⁻ ∷ quote ∈-filter⁺' ∷ quote ∈-∪⁺ ∷ quote ∈-map⁺' ∷ quote ∈-fromList⁺ ∷ [])

private variable A B : Type
                 X Y : Set A

open CommutativeMonoid M renaming (trans to ≈-trans)
import Relation.Binary.Reasoning.Setoid as SetoidReasoning
open SetoidReasoning (CommutativeMonoid.setoid M)
open import Data.List.Properties using (foldr-++)

private variable f : A → Carrier

indexedSumL : (A → Carrier) → List A → Carrier
indexedSumL f = foldr (λ x → f x ∙_) ε

syntax indexedSumL (λ a → x) m = Σˡ[ a ← m ] x

indexedSumL' : (A → Carrier) → Σ (List A) Unique → Carrier
indexedSumL' f = indexedSumL f ∘ proj₁

fold-cong↭ : ∀ {l l' : List A} → l ↭ l' → foldr (λ x → f x ∙_) ε l ≈ foldr (λ x → f x ∙_) ε l'
fold-cong↭ refl = begin _ ∎
fold-cong↭ (prep _ h) = ∙-congˡ (fold-cong↭ h)
fold-cong↭ {f = f} (swap {xs} {ys} x y h) = begin
  f x ∙ (f y ∙ indexedSumL f xs) ≈⟨ x∙yz≈y∙xz commutativeSemigroup _ _ _ ⟩
  f y ∙ (f x ∙ indexedSumL f xs) ≈⟨ ∙-congˡ (∙-congˡ (fold-cong↭ h)) ⟩
  f y ∙ (f x ∙ indexedSumL f ys) ∎
fold-cong↭ (trans h h₁) = ≈-trans (fold-cong↭ h) (fold-cong↭ h₁)

indexedSum : ⦃ _ : DecEq A ⦄ → (A → Carrier) → FinSet A → Carrier
indexedSum f = let open FactorUnique _≈_ (indexedSumL' f) fold-cong↭ in factor

indexedSumL-++ : {l l' : List A} → indexedSumL f (l ++ l') ≈ indexedSumL f l ∙ indexedSumL f l'
indexedSumL-++ {f = f} {l = l} {l'} = begin
  indexedSumL f (l ++ l')                   ≡⟨ foldr-++ (λ x → f x ∙_) ε l l' ⟩
  foldr (λ x → f x ∙_) (indexedSumL f l') l ≈⟨ helper (indexedSumL f l') l f ⟩
  indexedSumL f l ∙ indexedSumL f l'        ∎
  where
    helper : ∀ m (l : List A) f → foldr (λ x → f x ∙_) m l ≈ indexedSumL f l ∙ m
    helper m [] f = begin m ≈˘⟨ identityˡ m ⟩ ε ∙ m ∎
    helper m (x ∷ l) f = begin
      f x ∙ foldr (λ y → f y ∙_) m l ≈⟨ ∙-congˡ (helper m l f) ⟩
      f x ∙ (indexedSumL f l ∙ m)    ≈˘⟨ assoc _ _ _ ⟩
      f x ∙ indexedSumL f l ∙ m      ∎


module _ ⦃ _ : DecEq A ⦄ {f : A → Carrier} where
  open FactorUnique _≈_ (indexedSumL' f) fold-cong↭

  indexedSum-cong : indexedSum f Preserves (_≡ᵉ_ on proj₁) ⟶ _≈_
  indexedSum-cong {x} {y} = factor-cong {x = x} {y}

  indexedSum-∪ : ⦃ Xᶠ : finite X ⦄ ⦃ Yᶠ : finite Y ⦄ → disjoint X Y
    → indexedSum f ((X ∪ Y) ᶠ) ≈ indexedSum f (X ᶠ) ∙ indexedSum f (Y ᶠ)
  indexedSum-∪ disj = factor-∪' {λ x y z → z ≈ x ∙ y} disj
      λ {l} disj' → ≈-trans (fold-cong↭ (dedup-++-↭ disj')) (indexedSumL-++ {l = deduplicate _≟_ l})


module _ ⦃ _ : DecEq A ⦄ ⦃ _ : DecEq B ⦄ where

  indexedSumᵐ : (A × B → Carrier) → FinMap A B → Carrier
  indexedSumᵐ f (m , _ , h) = indexedSum f (m , h)

  indexedSumᵐ-cong : {f : A × B → Carrier} → indexedSumᵐ f Preserves (_≡ᵉ_ on proj₁) ⟶ _≈_
  indexedSumᵐ-cong {x = x , _ , h} {y , _ , h'} = indexedSum-cong {x = x , h} {y , h'}

  module IndexedSumUnionᵐ (sp-∈ : spec-∈ A) (∈-A-dec : {X : Set A} → Dec₁ (_∈ X)) where
    open Unionᵐ sp-∈

    ∪ᵐˡ-finite : {R R' : Rel A B} → finite R → finite R' → finite (R ∪ᵐˡ' R')
    ∪ᵐˡ-finite Rᶠ R'ᶠ = ∪-preserves-finite Rᶠ (filter-finite (sp-∘ (sp-¬ sp-∈) _) (¬? ∘ ∈-A-dec ∘ _) R'ᶠ)

    _∪ᵐˡᶠ_ : FinMap A B → FinMap A B → FinMap A B
    (_ , hX , Xᶠ) ∪ᵐˡᶠ (_ , hY , Yᶠ) = toFinMap ((_ , hX) ∪ᵐˡ (_ , hY)) (∪ᵐˡ-finite Xᶠ Yᶠ)

    indexedSumᵐ-∪ : ∀ {X Y : FinMap A B} {f} → disjoint (dom (toMap X ˢ)) (dom (toMap Y ˢ))
                  → indexedSumᵐ f (X ∪ᵐˡᶠ Y) ≈ indexedSumᵐ f X ∙ indexedSumᵐ f Y
    indexedSumᵐ-∪ {X = X'@(X , _ , Xᶠ)} {Y'@(Y , _ , Yᶠ)} {f} disj = begin
      indexedSumᵐ f (X' ∪ᵐˡᶠ Y')    ≈⟨ indexedSum-cong {x = -, ∪ᵐˡ-finite Xᶠ Yᶠ} {(X ∪ Y) ᶠ} (disjoint-∪ᵐˡ-∪ disj) ⟩
      indexedSum f ((X ∪ Y) ᶠ)      ≈⟨ indexedSum-∪ (disjoint-dom⇒disjoint disj) ⟩
      indexedSumᵐ f X' ∙ indexedSumᵐ f Y' ∎
      where instance _ = Xᶠ
                     _ = Yᶠ

  syntax indexedSumᵐ  (λ a → x) m = Σᵐ[ a ← m ] x
