module Layout exposing (body)

import Element as E
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Html as H
import Html.Attributes as A


body : List (E.Element msg) -> List (H.Html msg)
body content =
    [ E.layout
        [ fontFamily
        , Font.color (E.rgb 1 1 1)
        , Font.size 14
        ]
        (E.column [ E.width E.fill, E.height E.fill, E.paddingXY 32 0 ]
            [ E.row [ E.width E.fill ] [ header ]
            , E.row [ E.width E.fill, E.height E.fill ]
                [ E.column [ E.height E.fill, E.width E.fill ] content
                ]
            , E.row [ E.width E.fill ] [ footer ]
            ]
        )
    ]


fontFamily : E.Attribute msg
fontFamily =
    Font.family [ Font.typeface "JetBrains Mono", Font.monospace ]


header : E.Element msg
header =
    E.el [ Region.navigation, E.paddingXY 0 24 ]
        (E.column
            []
            [ E.link [ E.htmlAttribute (A.class "logo") ]
                { url = "/"
                , label =
                    E.row [ Font.size 32 ]
                        [ E.el
                            [ E.paddingEach { top = 0, right = 8, bottom = 0, left = 0 }
                            ]
                            (E.text "▄▆█")
                        , E.el [] (E.text "codestats.dev")
                        ]
                }
            , E.el
                [ Region.heading 4
                , Font.size 16
                , Font.color (E.rgb 1 1 1)
                , E.paddingXY 0 8
                ]
                (E.text "> stats from 2m+ repositories")
            ]
        )


footer : E.Element msg
footer =
    E.row
        [ Font.color (E.rgb 1 1 1)
        , Border.widthEach { bottom = 0, left = 0, right = 0, top = 1 }
        , Border.color (E.rgb255 33 205 6)
        , E.width E.fill
        , E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }
        , Region.footer
        , Font.size 12
        ]
        [ E.el
            [ E.width E.fill
            , Border.widthEach { bottom = 0, left = 0, right = 1, top = 0 }
            , Border.color (E.rgb255 33 205 6)
            , E.paddingXY 8 8
            ]
            (E.row [ E.width E.fill, Font.center, E.centerX, Font.justify ]
                [ E.el [ E.centerX ] (E.text "powered by ")
                , E.link [ E.centerX ] { url = "https://sourcegraph.com", label = E.text "Sourcegraph" }
                ]
            )
        , E.el
            [ E.width E.fill
            , Font.center
            , Border.widthEach { bottom = 0, left = 0, right = 1, top = 0 }
            , Border.color (E.rgb255 33 205 6)
            , E.paddingXY 8 8
            ]
            (E.link [ E.centerX ] { url = "/compute", label = E.text "compute explorer" })
        , E.el
            [ E.width E.fill
            , Font.center
            , E.paddingXY 8 8
            ]
            (E.row [ E.width E.fill, Font.center, E.centerX, Font.justify ]
                [ E.el [ E.centerX ] (E.text "feedback / requests? ")
                , E.link [ E.centerX ] { url = "https://twitter.com/CodeStatsDev", label = E.text "@CodeStatsDev" }
                , E.el [ E.centerX ] (E.text " on Twiter")
                ]
            )
        ]



-- E.el []
--     (E.html
--         (H.footer
--             [ A.style "display" "flex"
--             , A.style "justify-content" "space-around"
--             , A.style "border-top" "1px solid #21cd06"
--             , A.style "padding-bottom" "1.5rem"
--             ]
--             [ H.span
--                 [ A.style "padding" "0.5rem"
--                 , A.style "flex-grow" "1"
--                 , A.style "text-align" "center"
--                 , A.style "border-right" "1px solid #21cd06"
--                 ]
--                 [ H.text "powered by "
--                 , H.a [ A.href "https://sourcegraph.com" ] [ H.text "Sourcegraph" ]
--                 ]
--             , H.span
--                 [ A.style "padding" "0.5rem"
--                 , A.style "flex-grow" "1"
--                 , A.style "text-align" "center"
--                 , A.style "border-right" "1px solid #21cd06"
--                 ]
--                 [ H.a [ A.href "/compute" ] [ H.text "compute explorer" ]
--                 ]
--             , H.span
--                 [ A.style "padding" "0.5rem"
--                 , A.style "flex-grow" "1"
--                 , A.style "text-align" "center"
--                 ]
--                 [ H.text "feedback/requests? "
--                 , H.a [ A.href "https://twitter.com/CodeStatsDev" ] [ H.text "@CodeStatsDev" ]
--                 , H.text " on Twitter"
--                 ]
--             ]
--         )
--     )
