{-# LANGUAGE FlexibleContexts     #-}

-- |
-- Module      : Acessability.Model.Transform
-- Description : The database model
-- Copyright   : (c) Tomas Stenlund, 2019
-- License     : BSD-3
-- Maintainer  : tomas.stenlund@permobil.com
-- Stability   : experimental
-- Portability : POSIX
-- 
-- This module contains functions that transform from database to gql primitives
--
module Accessability.Model.Transform (
    toDataItem,
    toGenericItem,
    toGQLItem,
    textToKey,
    keyToText,
    idToKey,
    keyToID) where

--
-- Standard imports
--
import Data.Text.Encoding (encodeUtf8)
import Data.Text (Text)
import Data.Morpheus.Types    (ID(..), unpackID)
import Data.HexString (toBinary, hexString, fromBinary, toText)

--
-- Persistence imports
--
import Database.Persist.Sql

--
-- Our own imports
--
import qualified Accessability.Model.Database as DB
import Accessability.Data.Geo
import qualified Accessability.Model.GQL as GQL
import qualified Accessability.Data.Item as G

-- | Convert from ID to database key
idToKey:: ToBackendKey SqlBackend record => ID -> Key record
idToKey key = toSqlKey $ toBinary $ hexString $ encodeUtf8 $ unpackID key

keyToID::ToBackendKey SqlBackend record => Key record -> ID
keyToID key = ID { unpackID = toText $ fromBinary $ fromSqlKey key }

-- | Convert from Text to database key
textToKey::ToBackendKey SqlBackend record => Text -> Key record
textToKey key = toSqlKey $ toBinary $ hexString $ encodeUtf8 key

-- | Convert from Text to database key
keyToText::ToBackendKey SqlBackend record => Key record -> Text
keyToText key = toText $ fromBinary $ fromSqlKey key

-- | Converts a database item to a GQL item
toGQLItem::(Key DB.Item, DB.Item)  -- ^ The database item
    ->GQL.Item      -- ^ The GQL item
toGQLItem (key, item) = GQL.Item { GQL.itemId = Just $ keyToID key,
    GQL.itemName =  DB.itemName item,
    GQL.itemDescription = DB.itemDescription item,
    GQL.itemLevel = DB.itemLevel item,
    GQL.itemSource = DB.itemSource item,
    GQL.itemState = DB.itemState item,
    GQL.itemLongitude = realToFrac $ longitude $ DB.itemPosition item,
    GQL.itemLatitude = realToFrac $ latitude $ DB.itemPosition item}

-- | Converts a database item to a generic
toGenericItem::(Key DB.Item, DB.Item)   -- ^ The database item
    ->G.Item                            -- ^ The Generic item
toGenericItem (key, item) = G.Item { G.itemId = Just $ keyToText key,
    G.itemName =  DB.itemName item,
    G.itemDescription = DB.itemDescription item,
    G.itemLevel = DB.itemLevel item,
    G.itemSource = DB.itemSource item,
    G.itemState = DB.itemState item,
    G.itemLongitude = realToFrac $ longitude $ DB.itemPosition item,
    G.itemLatitude = realToFrac $ latitude $ DB.itemPosition item}

-- | Converts a GQL item to a database item
toDataItem::GQL.Item   -- ^ The database item
    ->DB.Item        -- ^ The GQL item
toDataItem item = DB.Item { DB.itemName =  GQL.itemName item,
    DB.itemDescription = GQL.itemDescription item,
    DB.itemLevel = GQL.itemLevel item,
    DB.itemSource = GQL.itemSource item,
    DB.itemState = GQL.itemState item,
    DB.itemPosition = Position $ PointXY (realToFrac $ GQL.itemLatitude item) (realToFrac $ GQL.itemLongitude item)}
--    DB.itemLatitude = realToFrac $ GQL.itemLatitude item,
--    DB.itemLongitude = realToFrac $ GQL.itemLongitude item}
