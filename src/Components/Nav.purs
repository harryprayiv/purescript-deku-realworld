module Components.Nav where

import Prelude

import API.Types (User)
import Data.Foldable (oneOf)
import Data.Maybe (Maybe, isJust, isNothing, maybe)
import Deku.Attribute (Attribute, (:=))
import Deku.Control (text, text_)
import Deku.Core (class Korok, Domable)
import Deku.DOM as D
import Deku.Listeners (click)
import Deku.Pursx (nut, (~~))
import Effect (Effect)
import FRP.Dedup (dedup)
import FRP.Event (AnEvent, Event)
import Route (Route(..))
import Type.Proxy (Proxy(..))

nav_ =
  Proxy    :: Proxy
         """<nav class="navbar navbar-light">
    <div class="container">
        <a class="navbar-brand" href="/#/">conduit</a>
        ~navbar~
    </div>
</nav>"""

nav :: forall s m lock payload.
  Korok s m => Effect Unit -> AnEvent m Route -> AnEvent m (Maybe User) -> Domable m lock payload
nav logOut route currentUser = nav_ ~~
  { navbar: nut
      ( D.ul (pure $ D.Class := "nav navbar-nav pull-xs-right")
          [ navItem Home "/#/" "Home" (pure true)
          , navItem Editor "/#/editor" "Editor" (isJust <$> currentUser)
          , navItem Settings "/#/settings" "Settings" (isJust <$> currentUser)
          , navItem LogIn "/#/login" "Sign in" (isNothing <$> currentUser)
          , navItem Register "/#/register" "Sign up" (isNothing <$> currentUser)
          , D.li
              ( oneOf
                  [ pure $ D.Class := "nav-item"
                  , doDisplay (isJust <$> currentUser)
                  ]
              )
              [ D.a
                  ( oneOf
                      [ pure $ D.Href := "/#/"
                      , pure $ D.Class := "nav-link"
                      , click $ pure logOut
                      ]
                  )
                  [ text_ "Log out" ]
              ]
          ]
      )
  }
  where
  navItem :: Route -> String -> String -> AnEvent m Boolean -> Domable m lock payload
  navItem myRoute href label displayCondition = navItem' myRoute (pure href) (pure label) displayCondition

  doDisplay :: AnEvent m Boolean -> AnEvent m (Attribute D.Li_)
  doDisplay displayCondition = dedup displayCondition <#> ((if _ then "" else "display: none;") >>> (D.Style := _))

  navItem' :: Route -> AnEvent m String -> AnEvent m String -> AnEvent m Boolean -> Domable m lock payload
  navItem' myRoute href label displayCondition = D.li
    ( oneOf
        [ pure $ D.Class := "nav-item"
        , doDisplay displayCondition
        ]
    )
    [ D.a
        ( oneOf
            [ href <#> (D.Href := _)
            , dedup
                ( map (eq myRoute >>> if _ then " active" else "")
                    (route)
                ) <#> \r -> D.Class := "nav-link" <> r
            ]
        )
        [ text label
        ]
    ]