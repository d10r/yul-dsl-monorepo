{-|

Copyright   : (c) 2023-2024 Miao, ZhiCheng
License     : LGPL-3
Maintainer  : hellwolf@yolc.dev
Stability   : experimental

= Description

Yul object builder. Yul object specification can be found from [solidity
documentation](https://docs.soliditylang.org/en/latest/yul.html#specification-of-yul-object).

-}
module YulDSL.Core.YulObject
  ( AnyExportedYulCat (MkAnyExportedYulCat), withAnyExportedYulCat
  , pureFn,staticFn, omniFn
  , YulObject (..), mkYulObject
  , emptyCtor
  ) where

-- base
import Control.Exception                          (assert)
import Data.List                                  (intercalate)
-- eth-abi
import Ethereum.ContractABI.ABITypeable           (abiTypeCanonName)
import Ethereum.ContractABI.CoreType.NP
-- import Ethereum.ContractABI.CoreType.NP
import Ethereum.ContractABI.ExtendedType.SELECTOR
--
import YulDSL.Core.YulCat
import YulDSL.Effects.Pure

-- | Existential yul function that is exported.
data AnyExportedYulCat where
  MkAnyExportedYulCat :: forall k { eff :: k } xs b. YulO2 (NP xs) b
                      => SELECTOR -> YulCatEffectClass -> NamedYulCat eff (NP xs) b -> AnyExportedYulCat

withAnyExportedYulCat :: AnyExportedYulCat
  -> (forall k { eff :: k } xs b. (YulO2 (NP xs) b ) => NamedYulCat eff (NP xs) b -> a)
  -> a
withAnyExportedYulCat (MkAnyExportedYulCat _ _ f) g = g f

pureFn :: forall f xs b eff.
  ( AssertPureEffect eff
  , KnownYulCatEffect eff
  , YulO2 (NP xs) b
  , EquivalentNPOfFunction f xs b
  ) => String -> Fn eff f -> AnyExportedYulCat
pureFn fname (MkFn f) = assert (classifyYulCatEffect @eff == PureEffect)
  MkAnyExportedYulCat (mkTypedSelector @(NP xs) fname) PureEffect f

staticFn :: forall f xs b eff.
  ( AssertStaticEffect eff
  , KnownYulCatEffect eff
  , YulO2 (NP xs) b
  , EquivalentNPOfFunction f xs b
  ) => String -> Fn eff f -> AnyExportedYulCat
staticFn fname (MkFn f) = assert (classifyYulCatEffect @eff == StaticEffect)
  MkAnyExportedYulCat (mkTypedSelector @(NP xs) fname) StaticEffect f

omniFn :: forall f xs b eff.
  ( AssertOmniEffect eff
  , KnownYulCatEffect eff
  , YulO2 (NP xs) b
  , EquivalentNPOfFunction f xs b
  ) => String -> Fn eff f -> AnyExportedYulCat
omniFn fname (MkFn f) = assert (classifyYulCatEffect @eff == OmniEffect)
  MkAnyExportedYulCat (mkTypedSelector @(NP xs) fname) OmniEffect f

instance Show AnyExportedYulCat where
  show (MkAnyExportedYulCat s PureEffect   cat) = "pure "   <> show_fn_spec s cat
  show (MkAnyExportedYulCat s StaticEffect cat) = "static " <> show_fn_spec s cat
  show (MkAnyExportedYulCat s OmniEffect   cat) = "omni "   <> show_fn_spec s cat

show_fn_spec :: forall xs b eff. YulO2 (NP xs) b
             => SELECTOR -> NamedYulCat eff (NP xs) b -> String
show_fn_spec (SELECTOR (sel, fsig)) cat@(cid, _) =
  let fspec = case fsig of
                Just (MkFuncSig fname) -> fname ++ "," ++ show sel ++ "," ++ cid
                Nothing                -> show sel ++ "," ++ cid
  in "fn " <> fspec <> "(" <> abiTypeCanonName @(NP xs) <> ") -> " <> abiTypeCanonName @b <> "\n" <>
     show cat

-- | A Yul Object per spec.
--
-- Note:
--   * Do not confuse this with YulObj which is an "object" in the category of YulCat.
--   * Specification: https://docs.soliditylang.org/en/latest/yul.html#specification-of-yul-object
data YulObject = MkYulObject { yulObjectName :: String
                             , yulObjectCtor :: AnyYulCat  -- FIXME support constructor
                             , yulObjectSFns :: [AnyExportedYulCat] -- scoped functions
                             , yulSubObjects :: [YulObject]
                             -- , TODO support object data
                             }

instance Show YulObject where
  show o = "-- Functions:\n\n"
           <> intercalate "\n\n" (fmap show (yulObjectSFns  o))
           <> "\n\n-- Init code:\n\n"
           <> (show . yulObjectCtor) o

mkYulObject :: String
            -> AnyYulCat
            -> [AnyExportedYulCat]
            -> YulObject
mkYulObject name ctor afns = MkYulObject { yulObjectName = name
                                         , yulObjectCtor = ctor
                                         , yulObjectSFns = afns
                                         , yulSubObjects = []
                                         }

emptyCtor :: AnyYulCat
emptyCtor = MkAnyYulCat (YulDis @Pure @())
