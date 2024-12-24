{-# OPTIONS_GHC -Wno-missing-signatures #-}
{-# LANGUAGE OverloadedStrings #-}
module YulDSL.CodeGens.Yul.Internal.BuiltIns.Arithmetic (exports) where
-- base
import           Data.List                                    (stripPrefix)
import           Data.Maybe                                   (fromJust)
-- text
import qualified Data.Text.Lazy                               as T
--
import           YulDSL.CodeGens.Yul.Internal.BuiltInRegistra


cmp_builtins = mk_builtin "__cmp_" $ \part full ->
  let (op, typ) = break (== '_') part
      cleanf = "__cleanup_t" <> typ
  in ( [ "function " <> T.pack full <> "(x, y) -> b {"
       , "  b := " <> T.pack op <> "(" <> T.pack cleanf <> "(x), " <> T.pack cleanf <> "(y))"
       , "}"
       ]
     , [ cleanf
       , op])

append_checked_maybe_variants op@(safeOpPrefix, _) =
  let opname = fromJust (stripPrefix "__safe_" safeOpPrefix)
  in [ op
     -- checked operator that reverts
     , mk_builtin ("__checked_" <> opname) $ \part full ->
         ( [ "function " <> T.pack full <> "(x, y) -> result {"
           , "  let failed := false"
           , "  result, failed := " <> T.pack (safeOpPrefix <> part) <> "(x, y)"
           , "  if eq(failed, true) { panic_error_0x11() }"
           , "}"
           ]
         , [ safeOpPrefix <> part
           , "panic_error_0x11"
           ])
     -- maybe type wrapped operator
     , mk_builtin ("__maybe_" <> opname) $ \part full ->
         ( [ "function " <> T.pack full <> "(tx, x, ty, y) -> t, result {"
           , "  t := iszero(or(iszero(tx), iszero(ty)))"
           , "  if eq(t, true) {" -- both Just values
           , "    result, t := " <> T.pack (safeOpPrefix <> part) <> "(x, y)"
           , "    if eq(t, true) {" -- t: failed
           , "      result := 0"
           , "    }"
           , "    t := iszero(t)" -- flip t: not failed / Just value
           , "  }"
           , "}"
           ]
         , [ safeOpPrefix <> part
           ])
     ]

safe_add_uintn = mk_builtin "__safe_add_t_uint" $ \part full ->
  let part' = T.pack part
      nbits = read part :: Int
      maxVal = "0x" <> replicate (nbits `div` 4) 'f'
  in ( [ "function " <> T.pack full <> "(x, y) -> sum, failed {"
       , "  x := __cleanup_t_uint" <> part' <> "(x)"
       , "  y := __cleanup_t_uint" <> part' <> "(y)"
       , "  sum := add(x, y)"
       , "  if "
         <> (if nbits < 256 then "gt(sum, " <> T.pack maxVal <> ")" else "gt(x, sum)")
         <> " { failed := true }"
       , "}"
       ]
     , [ "__cleanup_t_uint" <> part
       ])

safe_add_intn = mk_builtin "__safe_add_t_int" $ \part full ->
  let part' = T.pack part
      nbits = read part :: Int
      minVal = "0x7f" <> replicate (nbits `div` 4 - 2) 'f'
      maxVal = "0x"   <> replicate (64 - nbits `div` 4) 'f' <> "80" <> replicate (nbits `div` 4 - 2) '0'
  in ( [ "function " <> T.pack full <> "(x, y) -> sum, failed {"
       , "  x := __cleanup_t_int" <> part' <> "(x)"
       , "  y := __cleanup_t_int" <> part' <> "(y)"
       , "  sum := add(x, y)"
       , "  if or("
       , (if nbits < 256
          then "    sgt(sum, " <> T.pack minVal <> "),\n" <>
               "    slt(sum, " <> T.pack maxVal <> ")"
          else "    and(sge(x, 0), slt(sum, y)),\n" <>
               "    and(slt(x, 0), sge(sum, y))"
         )
       , "  ) { failed := true }"
       , "}"
       ]
     , [ "__cleanup_t_int" <> part
       , "sge"
       ])

safe_sub_uintn = mk_builtin "__safe_sub_t_uint" $ \part full ->
  let part' = T.pack part
      nbits = read part :: Int
      maxVal = "0x" <> replicate (nbits `div` 4) 'f'
  in ( [ "function " <> T.pack full <> "(x, y) -> diff, failed {"
       , "  x := __cleanup_t_uint" <> part' <> "(x)"
       , "  y := __cleanup_t_uint" <> part' <> "(y)"
       , "  diff := sub(x, y)"
       , "  if "
         <> (if nbits < 256 then "gt(diff, " <> T.pack maxVal <> ")" else "gt(diff, x)")
         <> " { failed := true}"
       , "}"
       ]
     , [ "__cleanup_t_uint" <> part
       ])

safe_sub_intn = mk_builtin "__safe_sub_t_int" $ \part full ->
  let part' = T.pack part
      nbits = read part :: Int
      minVal = "0x7f" <> replicate (nbits `div` 4 - 2) 'f'
      maxVal = "0x"   <> replicate (64 - nbits `div` 4) 'f' <> "80" <> replicate (nbits `div` 4 - 2) '0'
  in ( [ "function " <> T.pack full <> "(x, y) -> diff, failed {"
       , "  x := __cleanup_t_int" <> part' <> "(x)"
       , "  y := __cleanup_t_int" <> part' <> "(y)"
       , "  diff := sub(x, y)"
       , "  if or("
       , (if nbits < 256
          then "    slt(diff, " <> T.pack maxVal <> "),\n" <>
               "    sgt(diff, " <> T.pack minVal <> ")"
          else "    and(sge(y, 0), sgt(diff, x)),\n" <>
               "    and(slt(y, 0), slt(diff, x))"
         )
       , "  ) { failed := true }"
       , "}"
       ]
     , [ "__cleanup_t_int" <> part
       , "sge"
       ])

exports :: [BuiltInEntry]
exports =
  [ cmp_builtins ] ++
  append_checked_maybe_variants safe_add_uintn ++
  append_checked_maybe_variants safe_add_intn ++
  append_checked_maybe_variants safe_sub_uintn ++
  append_checked_maybe_variants safe_sub_intn
