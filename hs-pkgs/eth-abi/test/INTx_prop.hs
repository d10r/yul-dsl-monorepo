module INTx_prop where

import Data.Maybe
import Data.Proxy
--
import Test.Hspec
import Test.QuickCheck
--
import Ethereum.ContractABI.ABICoreType
import Ethereum.ContractABI.CoreType.INTx


validate_bounds :: forall i n. (i ~ INTx True n, ValidINTn n) => Proxy i -> Bool
validate_bounds _ = isNothing (fromInteger (toInteger (maxBound @i) + 1) :: Maybe i) &&
                    isNothing (fromInteger (toInteger (minBound @i) - 1) :: Maybe i)

test_bounds_op1 :: forall i n. (i ~ INTx True n, ValidINTn n)
                => Proxy i -> Integer -> Property
test_bounds_op1 _ a = a >= minVal && a <= maxVal ==>
                      go negate negate && go abs abs
  where minVal = toInteger (minBound @i)
        maxVal = toInteger (maxBound @i)
        a' = fromWord(integerToWord a) :: Maybe i
        go op' op = if op a > maxVal || op a < minVal
                    then isNothing (op' a')
                    else op' a' == fromInteger (op a)

test_bounds_op2 :: forall i n. (i ~ INTx True n, ValidINTn n)
                => Proxy i -> Integer -> Integer -> Property
test_bounds_op2 _ a b = a >= minVal && a <= maxVal && b >= minVal && b <= maxVal ==>
                        go (+) (+) && go (*) (*)
  where minVal = toInteger (minBound @i)
        maxVal = toInteger (maxBound @i)
        a' = fromWord (integerToWord a) :: Maybe i
        b' = fromWord (integerToWord b) :: Maybe i
        go op' op = if a `op` b > maxVal || a `op` b < minVal
                    then isNothing (a' `op'` b')
                    else a' `op'` b' == fromInteger (a `op` b)

test_twos_complement_law :: forall i n. (i ~ INTx True n, ValidINTn n)
                         => Proxy i -> Integer -> Property
test_twos_complement_law _ a = a >= toInteger (minBound @i) && a <= toInteger (maxBound @i) ==>
  a1 <= maxUnsignedVal && a2 <= maxUnsignedVal && a1 + a2 == maxUnsignedVal
  where wordToIntegerFrom n = wordToInteger (toWord (fromJust (fromInteger n) :: i))
        maxUnsignedVal = toInteger (maxBound @(INTx False n))
        a1 = wordToIntegerFrom a
        a2 = wordToIntegerFrom (-(a + 1))

test_most_intx :: forall a b.
                  Example b
               => (a -> b) -> (forall i n. (i ~ INTx True n, ValidINTn n) => Proxy i -> a) -> SpecWith (Arg b)
test_most_intx g f = do
  it "  8bits" $ g (f (Proxy @I8))
  it " 16bits" $ g (f (Proxy @I16))
  it " 32bits" $ g (f (Proxy @I32))
  it " 64bits" $ g (f (Proxy @I64))
  it "128bits" $ g (f (Proxy @I128))
  it "256bits" $ g (f (Proxy @I256))

tests = describe "INTx" $ do
  describe "Minimum and maximum bounds" $ test_most_intx id validate_bounds
  describe "Property of bounds for unary operators" $ test_most_intx property test_bounds_op1
  describe "property of bounds for binary operators" $ test_most_intx property test_bounds_op2
  describe "Two's complement law" $ test_most_intx property test_twos_complement_law
