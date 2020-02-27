-- |
-- | The Root container module
-- |
-- | Written by Tomas Stenlund, Sundsvall, Sweden (c) 2019
-- |
module Accessability.Root (component) where

import Prelude

import Data.Maybe (Maybe(..), maybe)
import Data.Symbol (SProxy(..))

import Control.Monad.Reader.Trans (class MonadAsk)

import Effect.Aff.Class (class MonadAff)

import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as HPA

-- DOM import
import DOM.HTML.Indexed.ButtonType (ButtonType(..))
import Web.HTML.Navigator.Geolocation (NavigatorGeolocation)

-- Our own stuff
import Accessability.Data.Route (Page(..))
import Accessability.Component.HTML.Utils (css,
                                  style,
                                  prop,
                                  href)
                                  
import Accessability.Component.Login as Login
import Accessability.Component.Nearby as Nearby
import Accessability.Interface.Navigate (class ManageNavigation)
import Accessability.Interface.Authenticate (class ManageAuthentication, UserInfo (..))

type State = {  userInfo :: Maybe UserInfo
              , page :: Page }

-- | The actions supported by the root page
data Action = SetUserAction  (Maybe UserInfo)   -- ^Sets the user
            
-- | The set of slots for the root container
type ChildSlots = ( login ∷ Login.Slot Unit,
                    nearby :: Nearby.Slot Unit )

_login = SProxy::SProxy "login"
_nearby = SProxy::SProxy "nearby"

component ∷ ∀ r q i o m. MonadAff m
  => ManageAuthentication m
  => ManageNavigation m
  => MonadAsk { geo ∷ Maybe NavigatorGeolocation | r } m
  => H.Component HH.HTML q i o m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
    }

initialState ∷ ∀ i. i → State
initialState _ = {  userInfo: Nothing
                  , page: Login }

-- |The navigation bar for the page
navbar∷forall p i . Array (HH.HTML p i) -> HH.HTML p i
navbar html = HH.nav [css "navbar navbar-dark bg-warning fixed-top navbar-expand-md", HPA.role "navigation"] html

-- |The header of the navigation bar
navbarHeader∷forall p i . String -> Array( HH.HTML p i )
navbarHeader header = [HH.button [css "navbar-toggler",
                        HP.type_ ButtonButton,
                        prop "data-toggle" "collapse",
                        prop "data-target" "#navbarCollapse",
                        HPA.expanded "false",
                        HPA.controls "navbarCollapse",
                        HPA.label "Toggle navigation"]
                        [HH.span [css "navbar-toggler-icon"] []],
                      HH.a [css "navbar-brand", href Home]
                        [HH.text header]                                                               
                      ]

-- |The left navigation bar
navbarLeft∷forall p . State -> HH.HTML p Action
navbarLeft state = HH.div [css "collapse navbar-collapse", HP.id_ "navbarCollapse"]
                    [HH.ul [css "navbar-nav mr-auto"] [
                      HH.li [css "nav-item active"] [HH.a [css "nav-link", href Home] [HH.text "Link 1"]],
                      HH.li [css "nav-item"] [HH.a [css "nav-link", href Home] [HH.text "Link 2"]],
                      HH.li [css "nav-item"] [HH.a [css "nav-link", href Home] [HH.text "Link 3"]]
                      ]          
                    ]

-- |The right navigation bar
navbarRight∷forall p . State -> HH.HTML p Action
navbarRight state = HH.a [css "navbar-text", href Home]
                      [HH.text $ maybe "Not logged in" (\(UserInfo v)->v.username) state.userInfo]

render ∷ ∀ r m . MonadAff m
  => ManageAuthentication m
  => ManageNavigation m
  => MonadAsk { geo ∷ Maybe NavigatorGeolocation | r } m
  => State → H.ComponentHTML Action ChildSlots m
render state = HH.div [] [
  HH.header [] [navbar $ (navbarHeader "Accessability portal") <> [navbarLeft state, navbarRight state]],
  HH.main [css "container", HPA.role "main"][view state.page]]

-- | Render the main view of the page
view ∷ ∀ r m. MonadAff m
       ⇒ ManageAuthentication m
       ⇒ ManageNavigation m
       ⇒ MonadAsk { geo ∷ Maybe NavigatorGeolocation | r } m
       ⇒ Page → H.ComponentHTML Action ChildSlots m
view Login = HH.slot _login  unit Login.component  unit (Just <<< loginMessageConv)
view Home =  HH.slot _nearby unit Nearby.component unit absurd
view _ = HH.div
             [css "container", style "margin-top:20px"]
             [HH.div
              [css "row"]
              [HH.div
               [css "col-md-12"]
               [HH.div
                [css "col-md-3 col-md-offset-1"]
                [HH.h2
                 []
                 [HH.text "ERROR Unknown page"]
                ]
               ]
              ]
             ]

-- |Converts login messages to root actions
loginMessageConv::Login.Message->Action
loginMessageConv (Login.SetUserMessage ui) = SetUserAction ui

handleAction ∷ ∀ r o m . MonadAff m 
  => MonadAsk { geo ∷ Maybe NavigatorGeolocation | r } m
  => Action → H.HalogenM State Action ChildSlots o m Unit
handleAction = case _ of
  SetUserAction ui →
    H.modify_ \st → st { userInfo = ui }
