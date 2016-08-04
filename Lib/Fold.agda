module Generic.Lib.Fold where

open import Generic.Lib.Intro
open import Generic.Lib.Decidable
open import Generic.Lib.Category
open import Generic.Lib.Maybe
open import Generic.Lib.List
open import Generic.Lib.Reflection

foldTypeOf : Data Type -> Type
foldTypeOf (packData d a b cs ns) = let i = countPi a; j = countPi b; ab = appendType a b in
  appendType (implPi ab) ∘ rpi (iarg (quoteTerm Level)) ∘ abs "π" ∘
    rpi (earg (appendType (shiftBy (j + 1) b) (sort (set (rvar j []))))) ∘ abs "P" $
      foldr (λ c r -> rpi (earg (mapName (λ p -> rvar p ∘ drop i) d (shiftBy (j + 2) c)))
                          (abs "_" (shift r)))
            (rpi (earg (def d (piToArgs (i + j + 2) ab)))
                 (abs "_" (rvar 1 (piToArgs (j + 3) b))))
             cs

clausesOf : Data Type -> Name -> List Clause
clausesOf (packData d a b cs ns) f = allToList $ mapAllInd (λ {a} n -> clauseOf n a) ns where
  k = length cs

  tryHyp : (List String -> Term -> Term) -> ℕ -> Type -> Maybe Term
  tryHyp rec n = go id where
    go : (List String -> List String) -> Type -> Maybe Term
    go l (rpi (earg a) (abs s b)) = go (l ∘ (s ∷_)) b
    go l (rpi  _       (abs s b)) = go l b
    go l (def e _)                = let i = length (l []) in if d == e
      then just $ rec (l []) (vis rvar (n + i) (map (λ v -> rvar v []) (downFrom i)))
      else nothing
    go l  _                       = nothing

  fromPi : (List String -> Term -> Term) -> ℕ -> Type -> List Term
  fromPi rec (suc n) (rpi (earg a) (abs s b)) =
    maybe id (rvar n []) (tryHyp rec n a) ∷ fromPi rec n b
  fromPi rec  n      (rpi  _       (abs s b)) = fromPi rec n b
  fromPi rec  n       b                       = []

  clauseOf : ℕ -> Type -> Name -> Clause
  clauseOf i c n = let es = epiToStrs c; j  = length es in
    clause (pvars ("P" ∷ unmap (λ n -> "f" ++ˢ showName n) ns) ∷ʳ earg (con n (pvars es)))
      (vis rvar (k + j ∸ suc i) (fromPi (λ l t -> foldr elam
        (vis def f (map (λ v -> rvar (v + length l) []) (downFromTo (suc k + j) j) ∷ʳ t)) l) j c))

deriveFoldTo : Name -> Name -> TC _
deriveFoldTo f d =
  getType d >>= λ ab ->
  getData d >>= λ D  ->
  declareDef (earg f) (foldTypeOf D) >>
  defineFun f (clausesOf D f)

-- This drops leading implicit arguments, because `fd` is "applied" to the empty spine.
-- Which breaks unification in some cases.
macro
  fold : Name -> Term -> TC _
  fold d ?r =
    freshName ("fold" ++ˢ showName d) >>= λ fd ->
    deriveFoldTo fd d >>
    unify ?r (def fd [])
