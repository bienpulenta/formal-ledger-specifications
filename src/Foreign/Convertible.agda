{-# OPTIONS --overlapping-instances #-}
module Foreign.Convertible where

open import Ledger.Prelude

open import Data.List using (map)

open import Foreign.Haskell
open import Foreign.Haskell.Coerce

record Convertible (A B : Set) : Set where
  field to   : A → B
        from : B → A

open Convertible ⦃...⦄ public

Convertible-Refl : ∀ {A} → Convertible A A
Convertible-Refl .to   = id
Convertible-Refl .from = id

instance
  Coercible⇒Convertible : ∀ {A B} → ⦃ _ : Coercible A B ⦄ → Convertible A B
  Coercible⇒Convertible .to   = coerce
  Coercible⇒Convertible .from = coerce ⦃ TrustMe ⦄ -- coercibility is symmetric, I promise

  Convertible-Pair : ∀ {A A' B B'} → ⦃ _ : Convertible A A' ⦄ → ⦃ _ : Convertible B B' ⦄
                   → Convertible (A × B) (Pair A' B')
  Convertible-Pair .to   (a , b) = (to a , to b)
  Convertible-Pair .from (a , b) = (from a , from b)

  Convertible-FinSet : ∀ {A A'} → ⦃ _ : Convertible A A' ⦄ → Convertible (ℙ A) (List A')
  Convertible-FinSet .to   s = Data.List.map to (setToList s)
  Convertible-FinSet .from l = setFromList (Data.List.map from l)

  Convertible-Map : ∀ {K K' V V'} ⦃ _ : DecEq K ⦄
                  → ⦃ _ : Convertible K K' ⦄ → ⦃ _ : Convertible V V' ⦄ → Convertible (K ↛ V) (List (Pair K' V'))
  Convertible-Map .to   m = to (proj₁ m)
  Convertible-Map .from m = fromListᵐ (Data.List.map from m)
