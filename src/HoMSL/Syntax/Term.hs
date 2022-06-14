{-# LANGUAGE DerivingStrategies #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

-- | Identifiers, sorts, and terms.
module HoMSL.Syntax.Term
  ( Id (..),
    Sort (..),
    sortArgs,
    Term (..),
    pattern Apps,
  )
where

import Data.Foldable

-- * Identifiers

-- | An identifier
data Id = Id
  { -- | The original name.
    idName :: String,
    -- | The identifier's sort.
    idSort :: Sort,
    -- | A unique used to avoid capture.
    idUnique :: {-# UNPACK #-} !Int
  }

instance Eq Id where
  x == y =
    idUnique x == idUnique y

instance Show Id where
  showsPrec _ x =
    showString (idName x) . showString "_" . shows (idUnique x)

-- * Sorts

-- | Simple types over trees and propositions.
data Sort
  = -- | Individuals (i.e. trees)
    I
  | -- | Proposition
    O
  | -- | Function arrow
    Sort :-> Sort
  deriving stock (Eq, Show)

infixr 0 :->

-- | Collect the maximal list of arguments of a sort.
sortArgs :: Sort -> [Sort]
sortArgs I = []
sortArgs O = []
sortArgs (s :-> t) =
  s : sortArgs t

-- * Terms

-- | Applicative terms.
data Term
  = -- | Local variable.
    Var Id
  | -- | Function symbol or program-level variable.
    Sym String
  | -- | Application.
    App Term Term
  deriving stock (Eq)

instance Show Term where
  showsPrec _ (Var x) = shows x
  showsPrec _ (Sym s) = showString s
  showsPrec p (Apps fun args) =
    showParen (p > 10) $
      showsPrec 11 fun
        . foldl' (\k arg -> k . showString " " . showsPrec 11 arg) id args

{-# COMPLETE Apps #-}

-- | Terms in spinal form.
pattern Apps :: Term -> [Term] -> Term
pattern Apps fun args <-
  (viewApps -> (fun, reverse -> args))
  where
    Apps fun args = foldl' App fun args

-- | Collect the arguments to a term (in reverse order).
viewApps :: Term -> (Term, [Term])
viewApps (Var x) = (Var x, [])
viewApps (Sym f) = (Sym f, [])
viewApps (App fun arg) =
  let (fun', args) = viewApps fun
   in (fun', arg : args)