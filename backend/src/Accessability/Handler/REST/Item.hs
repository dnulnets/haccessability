{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies        #-}
-- |
-- Module      : Acessability.Handler.REST
-- Description : The REST API entrypoint
-- Copyright   : (c) Tomas Stenlund, 2019
-- License     : BSD-3
-- Maintainer  : tomas.stenlund@permobil.com
-- Stability   : experimental
-- Portability : POSIX
--
-- This module contains the handler for REST API
--
module Accessability.Handler.REST.Item
    ( getItemR
    , putItemR
    , deleteItemR
    , postCreateItemR
    , postItemsR
    , getAttributesR
    , getItemAttributesR
    , putItemAttributesR
    , postItemsAndValuesR
    )
where

--
-- Import standard libs
--
import           Data.Aeson                     (encode)
import           Data.Maybe                     (fromMaybe)
import           Data.Text                      (Text, pack, splitOn)
import qualified UnliftIO.Exception             as UIOE

--
-- Yesod and HTTP imports
--
import           Network.HTTP.Types             (status200)
import           Yesod

--
-- My own imports
--
import           Accessability.Data.Analysis    (evaluatePOI)
import           Accessability.Data.Functor
import           Accessability.Data.Geo
import           Accessability.Data.Item        (Attribute (..), Item (..),
                                                 ItemValue (..))
import qualified Accessability.Data.User        as U
import           Accessability.Foundation       (Handler, getAuthenticatedUser,
                                                 requireAuthentication)
import qualified Accessability.Handler.Database as DBF
import qualified Accessability.Model.Database   as DB
import           Accessability.Model.REST.Item
import           Accessability.Model.Transform

-- | The REST GET handler for an item, i.e. return with the data of an item based on the items
-- key provided in the URL api/item/0000000000000001
--
getItemR
    :: Text      -- ^ The item key
    -> Handler Value -- ^ The item as a JSON response
getItemR key = do
    requireAuthentication
    result <- UIOE.catchAny
        (fffmap toGenericItem $ DBF.dbFetchItem $ textToKey key)
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to get the item from the database", key]
                <> splitOn "\n" (pack e)
        Right Nothing  -> sendResponseNoContent
        Right (Just i) -> sendStatusJSON status200 i

-- | The REST delete handler, i.e. return with the data of an item based on the items
-- key and delete the item.
deleteItemR
    :: Text      -- ^ The item key
    -> Handler () -- ^ The item as a JSON response
deleteItemR key = do
    requireAuthentication
    result <- UIOE.catchAny (DBF.dbDeleteItem $ textToKey key)
                            (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to delete the item from the database", key]
                <> splitOn "\n" (pack e)
        Right _ -> sendResponseNoContent

-- | The REST put handler, i.e. return with the updated data of the changed item based
-- on the specified key
putItemR
    :: Text      -- ^ The item key
    -> Handler Value -- ^ The item as a JSON response
putItemR key = do
    requireAuthentication
    queryBody <- requireCheckJsonBody :: Handler PutItemBody
    result    <- UIOE.catchAny
        (  fffmap toGenericItem
        $  DBF.dbUpdateItem (textToKey key)
        $  DBF.changeField DB.ItemName (putItemName queryBody)
        <> DBF.changeField DB.ItemGuid (putItemGuid queryBody)
        <> DBF.changeField DB.ItemDescription (putItemDescription queryBody)
        <> DBF.changeField DB.ItemSource (putItemSource queryBody)
        <> DBF.changeField DB.ItemModifier (putItemModifier queryBody)
        <> DBF.changeField DB.ItemApproval (putItemApproval queryBody)
        <> DBF.changeField
               DB.ItemPosition
               (maybePosition (realToFrac <$> putItemLongitude queryBody)
                              (realToFrac <$> putItemLatitude queryBody)
               )
        )
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to update the item in the database", key]
                <> splitOn "\n" (pack e)
        Right item -> sendStatusJSON status200 item

-- | The REST post handler, i.e. creates a new item with the specified data in the body
-- and return with the data as stored in the database.
postCreateItemR :: Handler Value -- ^ The item as a JSON response
postCreateItemR = do
    requireAuthentication
    body   <- requireCheckJsonBody :: Handler PostItemBody
    result <- UIOE.catchAny
        (fffmap toGenericItem DBF.dbCreateItem $ DB.Item
            { DB.itemGuid        = postItemGuid body
            , DB.itemCreated     = postItemCreated body
            , DB.itemModifier    = postItemModifier body
            , DB.itemApproval    = postItemApproval body
            , DB.itemName        = postItemName body
            , DB.itemDescription = postItemDescription body
            , DB.itemSource      = postItemSource body
            , DB.itemPosition    = Position $ PointXY
                                       (realToFrac $ postItemLongitude body)
                                       (realToFrac $ postItemLatitude body)
            }
        )
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to create a new item in the database"]
                <> splitOn "\n" (pack e)
        Right item -> sendStatusJSON status200 item

-- | The REST get handler for items, i.e. a list of items based on a body where the
-- search fields are spceified.
postItemsR :: Handler Value    -- ^ The list of items as a JSON response
postItemsR = do
    requireAuthentication
    queryBody <- requireCheckJsonBody :: Handler PostItemsBody
    result    <- UIOE.catchAny
        (fffmap
            toGenericItem
            (DBF.dbFetchItems
                (postItemsText queryBody)
                (maybePosition (realToFrac <$> postItemsLongitude queryBody)
                               (realToFrac <$> postItemsLatitude queryBody)
                )
                (realToFrac <$> postItemsDistance queryBody)
                (postItemsLimit queryBody)
            )
        )
        (pure . Left . show)
    case result of
        Left e -> do
            liftIO $ putStrLn "Unable to find any items"
            invalidArgs
                $  ["Unable to find any items in the database"]
                <> splitOn "\n" (pack e)
        Right items -> do
            sendStatusJSON status200 items

-- | The REST get handler for items, i.e. a list of items based on a body where the
-- search fields are spceified.
postItemsAndValuesR :: Handler Value    -- ^ The list of items as a JSON response
postItemsAndValuesR = do
    requireAuthentication

    -- Get the user properties
    mkey <- getAuthenticatedUser
    props <- case mkey of
        Just key -> do
            result <- UIOE.catchAny
                (fffmap toGenericUserProperty $ DBF.dbFetchUserProperties $ textToKey
                    key
                )
                (pure . Left . show)
            case result of
                Left e  -> pure []
                Right a -> pure a
        Nothing -> pure []

    -- Get the items
    queryBody <- requireCheckJsonBody :: Handler PostItemsBody
    items    <- (either (const []) id) <$> UIOE.catchAny
        (fffmap
            toGenericItem
            (DBF.dbFetchItems
                (postItemsText queryBody)
                (maybePosition (realToFrac <$> postItemsLongitude queryBody)
                               (realToFrac <$> postItemsLatitude queryBody)
                )
                (realToFrac <$> postItemsDistance queryBody)
                (postItemsLimit queryBody)
            )
        )
        (pure . Left . show)

    -- Calculate the value of the POI in respect to the user properties
    attrs <- sequence $ fetchItemAttributes <$> (toItemId items)
    sendStatusJSON status200 $ zipWith mergeItem items $ (evaluatePOI props) <$> attrs

    where

      toItemId::[Item]->[Maybe Text]
      toItemId ai = itemId <$> ai
    
      mergeItem::Item->ItemValue->Item
      mergeItem item iv = item {itemPositive = Just $ positive iv
                                , itemNegative = Just $ negative iv
                                , itemUnknown = Just $ unknown iv}

      fetchItemAttributes::Maybe Text->Handler [Attribute]
      fetchItemAttributes Nothing = pure []
      fetchItemAttributes (Just key) = do
        result <- UIOE.catchAny
          (fffmap toGenericItemAttribute $ DBF.dbFetchItemAttributes $ textToKey key)
          (pure . Left . show)
        case result of
            Left e  -> pure []
            Right a -> pure a



-- | The REST get handler for attributes, i.e. a list of attributes that an item can
-- have.
getAttributesR :: Handler Value    -- ^ The list of items as a JSON response
getAttributesR = do
    requireAuthentication
    result <- UIOE.catchAny
        (fffmap toGenericAttribute DBF.dbFetchAttributes)
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to get the attributes from the database"]
                <> splitOn "\n" (pack e)
        Right a -> sendStatusJSON status200 a

-- | The REST GET handler for an item, i.e. return with the data of an item based on the items
-- key provided in the URL api/item/0000000000000001
getItemAttributesR
    :: Text      -- ^ The item key
    -> Handler Value -- ^ The list of possible attributes and their values, if any
getItemAttributesR key = do
    requireAuthentication
    result <- UIOE.catchAny
        (fffmap toGenericItemAttribute $ DBF.dbFetchItemAttributes $ textToKey
            key
        )
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to get the item from the database", key]
                <> splitOn "\n" (pack e)
        Right a -> sendStatusJSON status200 a


-- | The REST PUT handler for the attributes of an item
--
-- If the record has an attributeValueID and a value it is an update
-- If the record has an attributeValueID and no value it is a delete
-- If the record has no attributeValueID and a value it is an insert
-- If the record has no attributeValueID and no value it is ignored
putItemAttributesR :: Text -> Handler Value
putItemAttributesR key = do
    requireAuthentication
    queryBody <- requireCheckJsonBody :: Handler [PutItemAttributes]
    result    <- UIOE.catchAny
        (DBF.dbUpdateItemAttributes (doit <$> queryBody))
        (pure . Left . show)
    case result of
        Left e ->
            invalidArgs
                $  ["Unable to update the items parameters ", key]
                <> splitOn "\n" (pack e)
        Right _ -> sendResponseStatus status200 Null
  where
    doit
        :: PutItemAttributes
        -> (Maybe (Key DB.AttributeValue), Maybe DB.AttributeValue)
    doit pia =
        ( textToKey <$> putItemAttributesAttributeValueId pia
        , case putItemAttributesValue pia of
            Just v -> Just $ DB.AttributeValue
                { DB.attributeValueAttribute = textToKey $ fromMaybe
                                                   "0000000000000000"
                                                   (putItemAttributesAttributeId
                                                       pia
                                                   )
                , DB.attributeValueItem      = textToKey key
                , DB.attributeValueValue     = v
                }
            Nothing -> Nothing
        )
