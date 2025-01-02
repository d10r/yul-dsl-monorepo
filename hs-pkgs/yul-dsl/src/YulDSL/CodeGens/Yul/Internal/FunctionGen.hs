{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE OverloadedStrings   #-}
module YulDSL.CodeGens.Yul.Internal.FunctionGen
  ( compile_cat
  , compile_named_cat
  , compile_exported_fn
  ) where

-- base
-- text
import Data.Text.Lazy                              qualified as T
--
import YulDSL.Core
--
import YulDSL.CodeGens.Yul.Internal.CodeFormatters
import YulDSL.CodeGens.Yul.Internal.CodeGen
import YulDSL.CodeGens.Yul.Internal.RhsExpr
import YulDSL.CodeGens.Yul.Internal.Variable


do_compile_cat :: HasCallStack
               => AnyYulCat -> CGState RhsExprGen
do_compile_cat (MkAnyYulCat (cat :: YulCat eff a b)) = go cat where
  -- - type conversions
  go (YulExtendType)     = build_rhs_aliases @a
  go (YulReduceType)     = build_rhs_aliases @a
  go (YulCoerceType)     = build_rhs_aliases @a
  go (YulSplit)          = build_rhs_aliases @a
  -- - categorical
  go (YulId)             = build_rhs_aliases @a
  go (YulComp cb ac)     = go_comp cb ac
  go (YulProd ab cd)     = go_prod ab cd
  go (YulSwap @_ @m @n)  = go_swap @m @n
  go (YulFork ab ac)     = go_fork ab ac
  go (YulExl @_ @m @n)   = go_extract @m @n True  {- extractLeft -}
  go (YulExr @_ @m @n)   = go_extract @m @n False {- extractLeft -}
  go (YulDis)            = go_dis @a
  go (YulDup)            = go_dup @a
  -- - control flows
  go (YulEmb @_ @m @n x) = go_emb @m @n x
  go (YulITE ct cf)      = go_ite ct cf
  go (YulJmpU t)         = go_jmpu t
  go (YulJmpB t)         = go_jmpb t
  go (YulCall @_ @m @n)  = go_call @m @n 'c'
  -- - storage effects
  go (YulSGet)           = go_sget
  go (YulSPut @_ @m)     = go_sput @m

go_comp :: forall eff a b c. (HasCallStack, YulO3 a b c)
        => YulCat eff c b -> YulCat eff a c -> CGState RhsExprGen
go_comp cb ac = build_code_block @a @b $ \ind (code, a_ins) -> do
    let title = T.pack $ "comp " ++
          "(" ++ abiTypeCompactName @a ++ ") -> " ++
          "(" ++ abiTypeCompactName @c ++ ") -> " ++
          "(" ++ abiTypeCompactName @b ++ ")"
    ac_gen <- do_compile_cat (MkAnyYulCat ac)
    cb_gen <- do_compile_cat (MkAnyYulCat cb)
    (code',  c_outs) <- gen_rhs_exprs ac_gen ind (code,  a_ins)
    (code'', b_outs) <- gen_rhs_exprs cb_gen ind (code', c_outs)
    pure (decor_code ind title code'', b_outs)

go_prod :: forall eff a b c d. (HasCallStack, YulO4 a b c d)
        => YulCat eff a b -> YulCat eff c d -> CGState RhsExprGen
go_prod ab cd = build_code_block @(a, c) @(b, d) $ \ind (code, ac_ins) -> do
    let title = T.pack $ "prod " ++
          ("(" ++ abiTypeCompactName @a ++ ", " ++ abiTypeCompactName @c ++ ") -> ") ++
          ("(" ++ abiTypeCompactName @b ++ ", " ++ abiTypeCompactName @d ++ ")")
        ca = length (abiTypeInfo @a)
        a_ins = take ca ac_ins
        c_ins = drop ca ac_ins
    ab_gen <- do_compile_cat (MkAnyYulCat ab)
    cd_gen <- do_compile_cat (MkAnyYulCat cd)
    (code',  b_outs) <- gen_rhs_exprs ab_gen ind (code,  a_ins)
    (code'', d_outs) <- gen_rhs_exprs cd_gen ind (code', c_ins)
    pure (decor_code ind title code'', b_outs ++ d_outs)

go_swap :: forall a b. (HasCallStack, YulO2 a b)
        => CGState RhsExprGen
go_swap = build_code_block @(a, b) @(b, a) $ \ind (code, ab_ins) -> do
  let title = T.pack $ "swap " ++ ("(" ++ abiTypeCompactName @a ++ ", " ++ abiTypeCompactName @b ++ ")")
      ca = length (abiTypeInfo @a)
      (va, vb) = splitAt ca ab_ins
  pure (decor_code ind title code, vb ++ va)

go_fork :: forall eff a b c. (HasCallStack, YulO3 a b c)
        => YulCat eff a b -> YulCat eff a c -> CGState RhsExprGen
go_fork ab ac = build_code_block @a @(b, c) $ \ind (code, a_ins) -> do
  let title = T.pack $ "fork " ++
        "(" ++ abiTypeCompactName @a ++ ") -> " ++
        "(" ++ abiTypeCompactName @b ++ ", " ++ abiTypeCompactName @c ++ ")"
  ab_gen <- do_compile_cat (MkAnyYulCat ab)
  ac_gen <- do_compile_cat (MkAnyYulCat ac)
  (code',  b_outs) <- gen_rhs_exprs ab_gen ind (code,  a_ins)
  (code'', c_outs) <- gen_rhs_exprs ac_gen ind (code', a_ins)

  pure (decor_code ind title code'', b_outs ++ c_outs)

go_extract :: forall a b. (HasCallStack, YulO2 a b)
           => Bool -> CGState RhsExprGen
go_extract extractLeft =
  let title = T.pack $ ("extract" <> if extractLeft then "L " else "R ") ++
              ("(" ++ abiTypeCompactName @a ++ ", " ++ abiTypeCompactName @b ++ ")")
      na = length (abiTypeInfo @a)
  in if extractLeft
     then build_code_block @(a, b) @a $
          \ind (code, ab_ins) -> pure (decor_code ind title code, take na ab_ins)
     else build_code_block @(a, b) @b $
          \ind (code, ab_ins) -> pure (decor_code ind title code, drop na ab_ins)

go_dis :: forall a. (HasCallStack, YulO1 a)
       => CGState RhsExprGen
go_dis = build_code_block @a @() $ \ind (code, _) ->
  let title = T.pack $ "dis " ++ "(" ++ abiTypeCompactName @a ++ ")"
  in pure (decor_code ind title code, [])

go_dup :: forall a. (HasCallStack, YulO1 a)
       => CGState RhsExprGen
go_dup = build_code_block @a @(a, a) $ \ind (code, a_ins) ->
  let title = T.pack $ "dup (" ++ abiTypeCompactName @a ++ ")"
  in pure (decor_code ind title code, a_ins ++ a_ins)

go_emb :: forall a b. (HasCallStack, YulO2 a b)
       => b -> CGState RhsExprGen
go_emb b =
  case length (abiTypeInfo @b) of
    0 -> build_code_block @a @() $ \_ (code, _) -> pure (code, [])
    -- FIXME: proper implementation of embeddable
    1 -> build_inline_expr @a $ \_ -> pure (T.pack (show b))
    _ -> error ("Unembedable: " ++ show b)
--
go_ite :: forall eff a b. (HasCallStack, YulO2 a b)
       => YulCat eff a b -> YulCat eff a b -> CGState RhsExprGen
go_ite ct cf = build_code_block @(BOOL, a) @b $ \ind (code, ba_ins) -> do
  let title = T.pack $ "ite (" ++ abiTypeCompactName @a ++ ")"
      a_ins = drop 1 ba_ins
  b_vars <- cg_create_vars @b
  ct_gen <- do_compile_cat (MkAnyYulCat ct)
  cf_gen <- do_compile_cat (MkAnyYulCat cf)
  (ct_code, ct_outs) <- gen_rhs_exprs ct_gen (indent ind) ("", a_ins)
  (cf_code, cf_outs) <- gen_rhs_exprs cf_gen (indent ind) ("", a_ins)
  pure ( decor_code ind title $
         code <>
         declare_vars ind b_vars <>
         ind ("switch " <> rhs_expr_to_code (ba_ins !! 0)) <>
         cbracket ind "case 1" -- true branch
         (\ind' -> ct_code <>
           assign_vars ind' b_vars ct_outs
         ) <>
         cbracket ind "default" -- false branch
         (\ind' -> cf_code <>
           assign_vars ind' b_vars cf_outs
         )
       , mk_rhs_vars b_vars )

go_jmpu :: forall eff a b. (HasCallStack, YulO2 a b)
        => NamedYulCat eff a b -> CGState RhsExprGen
go_jmpu (cid, cat) = cg_insert_dependent_cat cid (MkAnyYulCat cat)
                       >> go_jmp @a @b ("u$" ++ cid)

go_jmpb :: forall a b. (HasCallStack, YulO2 a b)
        => BuiltInYulFunction a b -> CGState RhsExprGen
go_jmpb (builtinName, _) = cg_use_builtin builtinName
                           >> go_jmp @a @b builtinName

go_jmp :: forall a b. (HasCallStack, YulO2 a b)
       => String -> CGState RhsExprGen
go_jmp fname = do
  let callExpr a_ins = T.pack fname <> "(" <> T.intercalate ", " (fmap rhs_expr_to_code a_ins) <> ")"
  if length (abiTypeInfo @b) <= 1
    then build_inline_expr @a (pure . callExpr)
    else build_code_block @a @b $ \ind (code, a_ins) -> do
    b_vars <- cg_create_vars @b
    pure ( code <>
           declare_vars ind b_vars <>
           ind (T.intercalate ", " (fmap unVar b_vars) <> " := " <> callExpr a_ins)
         , mk_rhs_vars b_vars )

go_call :: forall a b. (HasCallStack, YulO2 a b)
        => Char -> CGState RhsExprGen
go_call _ = error "TODO"

go_sget :: HasCallStack
        => CGState RhsExprGen
go_sget = build_inline_expr @ADDR $
          \ins -> pure ("sload(" <> rhs_expr_to_code (ins !! 0) <> ")")

go_sput :: forall a. (HasCallStack, YulO1 a)
        => CGState RhsExprGen
go_sput = build_code_block @(ADDR, a) @() $
          \ind (code, ins) -> pure
          ( code <>
            ind ("sstore(" <> T.intercalate ", " (fmap rhs_expr_to_code ins) <> ")")
          , [])

compile_cat :: forall a b eff. (HasCallStack, YulO2 a b)
            => Indenter -> YulCat eff a b -> ([Var], [Var]) -> CGState Code
compile_cat ind acat (a_vars, b_vars) = do
  gen <- do_compile_cat (MkAnyYulCat acat)
  (code, b_outs) <- gen_rhs_exprs gen ind ("", mk_rhs_vars a_vars)
  pure $
    code <>
    assign_vars ind b_vars b_outs

compile_named_cat :: forall a b eff. (HasCallStack, YulO2 a b)
           => Indenter -> NamedYulCat eff a b -> CGState Code
compile_named_cat ind (cid, cat) = do
  vars_a <- cg_create_vars @a
  vars_b <- cg_create_vars @b

  code <- cbracket_m ind
    ( "function " <> T.pack ("u$" ++ cid) <>
      "(" <> spread_vars vars_a <> ")" <>
      (if null vars_b then "" else " -> " <> spread_vars vars_b)
    )
    ( \ind' -> do
        body <- compile_cat ind' cat (vars_a, vars_b)
        pure $
          body <>
          ind' "leave"
    )

  cg_reset_for_fn
  pure code

compile_exported_fn :: HasCallStack
                  => Indenter -> ExportedFn -> CGState Code
compile_exported_fn ind f = withExportedFn f (compile_named_cat ind)
