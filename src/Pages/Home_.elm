module Pages.Home_ exposing (view)

import Html as H
import Html.Attributes as A
import Layout
import View exposing (View)


view : View msg
view =
    { title = "codestat.dev"
    , body = Layout.body [ H.text "Hello world!" ]
    }
