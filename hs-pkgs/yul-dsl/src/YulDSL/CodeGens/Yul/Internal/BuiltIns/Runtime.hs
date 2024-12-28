{-# OPTIONS_GHC -Wno-missing-signatures #-}
{-# LANGUAGE OverloadedStrings #-}
module YulDSL.CodeGens.Yul.Internal.BuiltIns.Runtime (exports) where
-- yul-dsl
import YulDSL.Core
-- text
import Data.Text.Lazy                               qualified as T
--
import YulDSL.CodeGens.Yul.Internal.BuiltInRegistra
import YulDSL.CodeGens.Yul.Internal.Variable

------------------------------------------------------------------------------------------------------------------------
-- Memory management
------------------------------------------------------------------------------------------------------------------------

allocate_unbounded =  const_builtin "__allocate_unbounded"
  [ "function __allocate_unbounded() -> memPtr { memPtr := mload(64) }" ]

------------------------------------------------------------------------------------------------------------------------
-- Dispatcher
------------------------------------------------------------------------------------------------------------------------

dispatcher_builtins =
  [ const_builtin_with_deps "__dispatcher_dependencies" [] -- it is a pseudo builtin
    [ "__allocate_unbounded"
    , "__selector"
    ]

  , const_builtin "__selector"
    [ "function selector() -> s {"
    , " s := div(calldataload(0), 0x100000000000000000000000000000000000000000000000000000000)"
    , "}"
    ]
  ]

------------------------------------------------------------------------------------------------------------------------
-- Exceptions
------------------------------------------------------------------------------------------------------------------------

revert0 = mk_builtin "__revert_" $ \part full ->
  let types = decodeAbiCoreTypeCompactName part
      vars  = gen_vars (length types)
  in ( [ "function " <> T.pack full <> "() -> " <> spread_vars vars  <> " {"
       , " revert(0, 0)"
       , "}"
       ]
     , [])

panic_errors = mk_builtin "panic_error_" $ \part full ->
  ( [ "function " <> T.pack full <> "() {"
    -- `cast sig 'Panic(uint256)'` == 0x4e487b71
    , "  mstore(0, 0x4e487b71" <> T.pack (replicate 56 '0') <> ")"
    , "  mstore(4, " <> T.pack part <> ")"
    , "  revert(0, 0x24)"
    , "}"
    ]
  , [])

exports =
  [ allocate_unbounded
  ] ++
  [ revert0
  , panic_errors
  ] ++
  dispatcher_builtins
