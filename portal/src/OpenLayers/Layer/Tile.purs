-- |
-- | The OpenLayers Feature module
-- |
-- | Written by Tomas Stenlund, Sundsvall, Sweden (c) 2020
-- |
module OpenLayers.Layer.Tile (
  Tile
  , RawTile

  , create) where

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

-- Import own modules
import OpenLayers.Layer.BaseTileLayer as BaseTileLayer

--
-- Foreign data types
-- 
foreign import data RawTile :: Type
type Tile = BaseTileLayer.BaseTileLayer RawTile

--
-- Function mapping
--
foreign import createImpl :: forall r . Fn1 {|r} (Effect (Nullable Tile))

create :: forall r . {|r} -> Effect (Maybe Tile)
create o = toMaybe <$> runFn1 createImpl o