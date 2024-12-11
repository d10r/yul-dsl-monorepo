{-# OPTIONS_GHC -Wno-orphans #-}
module YulDSL.YulCatObj.Prelude.Linear.Num where

-- base
import qualified Prelude        as Prelude.Base
-- linear-base
import           Prelude.Linear
import qualified Unsafe.Linear  as UnsafeLinear
-- yul-dsl
import           YulDSL.Core


--
-- FromInteger instances for ABI types
--

instance FromInteger Integer where
  fromInteger = id

instance (KnownBool s, ValidINTn n) => FromInteger (INTx s n) where
  fromInteger = UnsafeLinear.toLinear Prelude.Base.fromInteger

--
--  Num instances for (YulCat r a)
--

instance (YulO1 r, YulNum a) => Additive (YulCat eff r a) where
  a + b = YulNumAdd <.< YulProd a b <.< YulDup

instance (YulO1 r, YulNum a) => AddIdentity (YulCat eff r a) where
  zero = YulEmbed (fromIntegral (0 :: Integer))

instance (YulO1 r, YulNum a) => AdditiveGroup (YulCat eff r a) where
  negate a = YulNumNeg <.< a
instance (YulO1 r, KnownBool s, ValidINTn n) => FromInteger (YulCat eff r (INTx s n)) where
  fromInteger x = YulEmbed (fromInteger x)
