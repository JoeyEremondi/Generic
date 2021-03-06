module Generic.Examples.Data.Lift where

open import Generic.Main as Main hiding (Lift; lift; lower)

Lift : ∀ {α} β -> Set α -> Set (α ⊔ β)
Lift β = readData Main.Lift

pattern lift x = !#₀ (relv x , lrefl)

lower : ∀ {α} {A : Set α} β -> Lift β A -> A
lower β (lift x) = x
