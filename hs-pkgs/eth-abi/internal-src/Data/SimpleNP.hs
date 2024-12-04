{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE LinearTypes         #-}
module Data.SimpleNP
  ( Multiplicity (Many, One)
  , NP (Nil, (:*))
  , LiftFunction
  , UncurryNP'Fst, UncurryNP'Snd, UncurryNP'Multiplicity, UncurryNP
  , CurryNP, CurryingNP'Head, CurryingNP'Tail
  , CurryingNP (curryingNP), UncurryingNP(uncurryingNP)
  , module Internal.Data.Type.List
  ) where

-- base
import           Data.Kind               (Constraint, Type)
import           Data.List               (intercalate)
import           GHC.Base                (Multiplicity (..))
-- constraints
import           Data.Constraint.Forall  (Forall)
--
import           Internal.Data.Type.List


-- | N-ary product without a type function comparing to its homonym in the "sop" package.
data NP :: [Type] -> Type where
  Nil  :: NP '[]
  (:*) :: x -> NP xs -> NP (x : xs)
infixr 5 :*

--
-- Type level functions for NP
--

-- | Lift a currying function type from its simplified form, denoted as @f@, into a new form.
--
--   This lifted function consists of a type function, @m@, for each argument, followed by a multiplicity arrow of @p@,
--   and uses a type function @mb@, for the result of the lifted function.
type family LiftFunction f (m  :: Type -> Type) (mb :: Type -> Type) (p :: Multiplicity) where
  LiftFunction  (x1 -> g) m mb p = m x1 %p-> LiftFunction g m mb p
  LiftFunction        (b) m mb _ = mb b

-- | Uncurry the arguments of a function to a list of types.
type family UncurryNP'Fst f :: [Type] where
  UncurryNP'Fst (x1 %_-> g) = x1 : UncurryNP'Fst (g)
  UncurryNP'Fst         (b) = '[]

-- | Uncurry the result of a function.
type family UncurryNP'Snd f  where
  UncurryNP'Snd (_ %_-> g) = UncurryNP'Snd (g)
  UncurryNP'Snd        (b) = b

-- | Uncurry and extract the multiplicity of the last arrow.
type family UncurryNP'Multiplicity f :: Multiplicity where
  UncurryNP'Multiplicity         (x1 %p-> b) = p
  UncurryNP'Multiplicity                 (b) = Many

-- | Uncurry a function to its NP form whose multiplicity of the last arrow is preserved.
type UncurryNP f = NP (UncurryNP'Fst f) %(UncurryNP'Multiplicity f)-> UncurryNP'Snd f

-- | Convert a function in ts NP form @np -> b@ to a curried function with multiplicity arrows in @p@.
--
--   Note: To add multiplicity-polymorphic arrows or to decorate arguments with additional type function, use
--   'LiftFunction'.
type family CurryNP np b where
  CurryNP (NP (x:xs)) b = x -> CurryNP (NP xs) b
  CurryNP (NP    '[]) b = b

-- | The type of the head of arguments of an currying function.
type family CurryingNP'Head f where
  CurryingNP'Head (a1 %_-> g) = a1
  CurryingNP'Head         (b) = ()

-- | The type of the tail of an currying function.
type family CurryingNP'Tail f where
  CurryingNP'Tail (a1 %p-> g) = CurryingNP'Tail g
  CurryingNP'Tail         (b) = b

--
-- Type classes for defining uncurrying/currying functions for NP
--

-- | Uncurrying a function into a function of @NP xs@ to @b@.
class UncurryingNP f (xs :: [Type]) b
      (m1 :: Type -> Type) (m1b :: Type -> Type)
      (m2 :: Type -> Type) (m2b :: Type -> Type)
      (p :: Multiplicity) where
  uncurryingNP :: forall.
                  ( UncurryNP'Fst f ~ xs
                  , UncurryNP'Snd f ~ b
                  -- rewrite the second lift function into its one-arity form
                  , LiftFunction (NP xs -> b) m2 m2b p ~ (m2 (NP xs) %p-> m2b b)
                  )
               => LiftFunction           f  m1 m1b p  -- ^ from this lifted function
             %p-> LiftFunction (NP xs -> b) m2 m2b p  -- ^ to this lifted function

-- | Currying a function of @NP xs@ to @b@.
class CurryingNP (xs :: [Type]) b
      (m1 :: Type -> Type) (mb :: Type -> Type)
      (m2 :: Type -> Type)
      (p :: Multiplicity) where
  curryingNP :: forall f.
                ( CurryNP (NP xs) b ~ f
                -- rewrite the first lift function into its one-arity form
                , LiftFunction (NP xs -> b) m2 mb p ~ (m2 (NP xs) %p-> mb b)
                )
             => LiftFunction (NP xs -> b) m2 mb p -- ^ from this lifted function
           %p-> LiftFunction           f  m1 mb p -- ^ to this lifted function

--
-- base instances
--

type family ConstraintMap (xs :: [Type]) (c :: Type -> Constraint) :: Constraint where
  ConstraintMap '[]    c = ()
  ConstraintMap (x:xs) c = (c x, ConstraintMap xs c)

instance Show (NP '[]) where
  show _ = "()"

instance (Show x, Show (NP xs)) => Show (NP (x : xs)) where
  show (x :* xs) = "(" ++ show x ++ " :* " ++ show xs ++ ")"

--
-- Internal
--

-- Existential wrapper of any 'NP' values.
data AnyNP (c :: Type -> Constraint) where
  MkAnyEmptyNP    :: forall c. AnyNP c
  MkAnyNonEmptyNP :: forall c x xs. ConstraintMap (x:xs) c => x -> NP xs -> AnyNP c

-- Show a NP as a list of strings.
show_any_np :: AnyNP Show -> [String]
show_any_np MkAnyEmptyNP                    = []
show_any_np (MkAnyNonEmptyNP x Nil)         = [show x]
show_any_np (MkAnyNonEmptyNP x (x' :* xs')) = [show x] ++ show_any_np (MkAnyNonEmptyNP x' xs')
