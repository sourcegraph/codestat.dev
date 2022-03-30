module Pages.Home_ exposing (view)

import Element as E
import Element.Font as Font
import Element.Region as Region
import Layout
import View exposing (View)


view : View msg
view =
    { title = "codestat.dev"
    , body =
        Layout.body
            [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Recent stats")
            , E.link [ Region.heading 1, E.paddingXY 0 8 ] { url = "/s/chat/zulip", label = E.text "Zulip " }
            , E.el [] (E.text "Hello world!")
            ]
    }
