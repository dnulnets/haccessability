-- |
-- | The Root container module
-- |
-- | Written by Tomas Stenlund, Sundsvall, Sweden (c) 2019
-- |
module Accessibility.Root (component, Input, Query (..)) where

-- Standard import
import Prelude

-- Data imports
import Data.Maybe (Maybe(..), maybe)
import Data.Symbol (SProxy(..))

-- Monad imports
import Control.Monad.Reader.Trans (class MonadAsk)

-- Effect imports
import Effect.Aff.Class (class MonadAff)
import Effect.Console (log)

-- Halogen imports
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Halogen.HTML.Properties.ARIA as HPA
import Halogen.HTML.Events as HE

-- DOM import
import DOM.HTML.Indexed.ButtonType (ButtonType(..))

-- Our own stuff
import Accessibility.Data.Route (Page(..))
import Accessibility.Component.HTML.Utils
  ( css
  , style
  , prop
  , href)
import Accessibility.Component.Login as Login
import Accessibility.Component.MapAdmin as MapAdmin
import Accessibility.Component.Point as Point
import Accessibility.Interface.Navigate (class ManageNavigation, gotoPage)
import Accessibility.Interface.Authenticate (class ManageAuthentication
  , UserInfo (..)
  , logout)
import Accessibility.Interface.Item (class ManageItem)
import Accessibility.Interface.Entity (class ManageEntity)

-- | The state of the root page
type State = {  userInfo :: Maybe UserInfo  -- ^ User information of the logged in user
              , alert::Maybe String         -- ^ Alert info
              , page :: Page }              -- ^ What page to show in the root container

-- |The user info that comes into the root page
type Input = Maybe UserInfo

-- | The query that allows us to change page of the root
data Query a = GotoPageRequest Page a

-- | The actions supported by the root page
data Action = SetUser  (Maybe UserInfo)   -- ^Sets the user
            | Logout                            -- ^Logs out the user
            | AuthenticationError               -- ^Authentication error
            | PointSubmitted                    -- ^A POI has been added or changed
            | Alert (Maybe String)              -- ^Alert

-- | The set of slots for the root container
type ChildSlots = ( login ∷ Login.Slot Unit,
                    mapadmin :: MapAdmin.Slot Unit,
                    point :: Point.Slot Unit )

_login = SProxy::SProxy "login"
_mapadmin = SProxy::SProxy "mapadmin"
_point = SProxy::SProxy "point"

component ∷ ∀ r o m. MonadAff m
  => ManageAuthentication m
  => ManageNavigation m
  => ManageItem m
  => ManageEntity m
  => MonadAsk r m
  => H.Component HH.HTML Query Input o m
component =
  H.mkComponent
    { initialState
    , render
    , eval: H.mkEval $ H.defaultEval { handleAction = handleAction, handleQuery = handleQuery }
    }

-- | The root container initial state
initialState ∷ Input → State
initialState ui = { userInfo: ui
                    , alert: Nothing
                    , page: maybe Login (const Home) ui }

-- The alert banner if there are any problems with the application
alert ::forall p i . Maybe String
            -> HH.HTML p i
alert (Just t) = HH.div [css "alert alert-danger"] [HH.text $ t]
alert Nothing = HH.div [] []

-- |The navigation bar for the page
navbar∷forall p i . Array (HH.HTML p i) -> HH.HTML p i
navbar html = HH.nav [css "navbar navbar-dark bg-warning navbar-expand-md", HPA.role "navigation"] html

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
                    [HH.ul [css "navbar-nav mr-auto"] ([] <>
                      maybe [] (\_->[HH.li [css "nav-item active"] [HH.a [css "nav-link", href Home] [HH.text "Map"]]]) state.userInfo
--                      , HH.li [css "nav-item"] [HH.a [css "nav-link", href (Point "0000000000000001" false)] [HH.text "Add POI"]]
                      <> [])
                    ]

-- |The right navigation bar
navbarRight∷forall p . State -> HH.HTML p Action
navbarRight state = HH.a [css "navbar-text", HE.onClick \_ -> Just Logout]
                      [HH.text $ maybe "Not logged in" (\(UserInfo v)->"Logout " <> v.username) state.userInfo]

render ∷ ∀ r m . MonadAff m
  => ManageAuthentication m
  => ManageNavigation m
  => ManageEntity m
  => ManageItem m
  => MonadAsk r m
  => State → H.ComponentHTML Action ChildSlots m
render state = HH.div [css "ha-root"] [
  HH.header [] [navbar $ (navbarHeader "Case 3 Prototype") <> [navbarLeft state, navbarRight state]],
  HH.main [css "container ha-main", HPA.role "main"][alert state.alert, view state.page]]

-- | Render the main view of the page
view ∷ ∀ r m. MonadAff m
       ⇒ ManageAuthentication m
       ⇒ ManageNavigation m
       => ManageEntity m
       => ManageItem m
       ⇒ MonadAsk r m
       ⇒ Page → H.ComponentHTML Action ChildSlots m
view Login = HH.slot _login  unit Login.component  unit (Just <<< loginMessageConv)
view Home =  HH.slot _mapadmin unit MapAdmin.component unit (Just <<< mapadminMessageConv)
view (Point k true) =  HH.slot _point unit Point.component (Point.ViewPOI k) (Just <<< pointMessageConv)
view (Point k false) = HH.slot _point unit Point.component (Point.UpdatePOI k) (Just <<< pointMessageConv)
view (AddPoint la lo) = HH.slot _point unit Point.component (Point.AddPOI la lo) (Just <<< pointMessageConv)
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
loginMessageConv::Login.Output->Action
loginMessageConv (Login.SetUser ui) = SetUser ui
loginMessageConv (Login.Alert s) = Alert s

-- |Converts mapamin messages to root actions
mapadminMessageConv::MapAdmin.Output->Action
mapadminMessageConv MapAdmin.AuthenticationError = AuthenticationError
mapadminMessageConv (MapAdmin.Alert s) = Alert s

-- |Converts point messages to root actions
pointMessageConv::Point.Output->Action
pointMessageConv Point.Submitted = PointSubmitted
pointMessageConv Point.AuthenticationError = AuthenticationError
pointMessageConv (Point.Alert s) = Alert s

-- | Handle the queries sent to the root page
handleQuery ∷ ∀ r o m a .
              MonadAff m ⇒ 
              MonadAsk r m ⇒
              ManageNavigation m =>
              Query a → H.HalogenM State Action ChildSlots o m (Maybe a)
handleQuery = case _ of
  GotoPageRequest newpage a → do
    state ← H.get
    H.liftEffect $ log $ "GotoPageRequest to " <> show newpage
    decided <- pure $ maybe Login (const newpage) state.userInfo
    H.liftEffect $ log $ "GotoPageRequest was decided to be " <> show decided
    if decided /= newpage
      then do
        gotoPage Login
      else do
        if decided /= Login
          then do
            H.put $ state { page = decided }
          else do
            H.put $ state { page = decided, userInfo = Nothing }

    pure (Just a)

-- | Handle the root containers actions
handleAction ∷ ∀ r o m . MonadAff m
  => ManageAuthentication m
  => MonadAsk r m
  => ManageNavigation m
  => Action → H.HalogenM State Action ChildSlots o m Unit

-- Sets the logged in user
handleAction (SetUser ui) = do
  H.modify_ $ _ {userInfo = ui}

-- Logs out the current user and move to the login page, clear the current
-- alert
handleAction Logout = do
  H.modify_ $ _ { userInfo = Nothing, alert = Nothing }
  logout
  gotoPage Login
  
-- Logs out the current user and move to the login page, do not alter any
-- alert.
handleAction AuthenticationError = do
  H.modify_ $ _ { userInfo = Nothing }
  logout
  gotoPage Login

-- A point has been submitted or canceled from the Point page
handleAction PointSubmitted = do
  gotoPage Home

-- An alert has been issued from a sub component
handleAction (Alert s) = do
  H.modify_ $ _ { alert = s}
