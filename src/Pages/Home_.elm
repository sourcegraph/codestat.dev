module Pages.Home_ exposing (view)

import Element as E
import Layout
import View exposing (View)


view : View msg
view =
    { title = "codestat.dev"
    , body = Layout.body [ E.el [] (E.text "Hello world!") ]
    }
