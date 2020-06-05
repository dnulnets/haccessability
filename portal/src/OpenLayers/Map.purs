-- |
-- | The OpenLayers Feature module
-- |
-- | Written by Tomas Stenlund, Sundsvall, Sweden (c) 2020
-- |
module OpenLayers.Map (Map, create) where

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
foreign import data Map :: Type

--
-- Function mapping
--
foreign import createImpl :: forall r . Fn1 {|r} (Effect (Nullable Map))

create :: forall r . {|r} -> Effect (Maybe Map)
create o = toMaybe <$> runFn1 createImpl o
