-- |
-- | The OpenLayers Circle module
-- |
-- | Written by Tomas Stenlund, Sundsvall, Sweden (c) 2020
-- |
module OpenLayers.Style.Circle (
  Circle
  , create
  ) where

-- Standard import
import Prelude

-- Data imports
import Data.Nullable (Nullable, toMaybe, toNullable)
import Data.Maybe (Maybe(..))
import Data.Function.Uncurried
  ( Fn1
  , Fn2
  , Fn3
  , Fn4
  , Fn5
  , runFn1
  , runFn2
  , runFn3
  , runFn4
  , runFn5)

-- Effect imports
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Aff.Compat (EffectFnAff, fromEffectFnAff)

--
-- Foreign data types
-- 
foreign import data Circle :: Type

--
-- Function mapping
--
foreign import createImpl :: forall r . Fn1 {|r} (Effect (Nullable Circle))

create :: forall r . {|r} -> Effect (Maybe Circle)
create o = toMaybe <$> runFn1 createImpl o
