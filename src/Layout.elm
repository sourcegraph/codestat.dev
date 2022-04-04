module Layout exposing (body, howDoesThisWork)

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
                        , E.el [] (E.text "codestat.dev")
                        ]
                }
            , E.el
                [ Region.heading 4
                , Font.size 16
                , Font.color (E.rgb 0.7 0.7 0.7)
                , E.paddingXY 0 8
                ]
                (E.text "> stats from 2m+ OSS repositories")
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
            (E.link [ E.centerX ] { url = "/compute", label = E.text "compute data explorer" })
        , E.el
            [ E.width E.fill
            , Font.center
            , E.paddingXY 8 8
            ]
            (E.row [ E.width E.fill, Font.center, E.centerX, Font.justify ]
                [ E.el [ E.centerX ] (E.text "feedback / requests? ")
                , E.link [ E.centerX ] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
                , E.el [ E.centerX ] (E.text " on Twiter")
                ]
            )
        ]


howDoesThisWork : E.Element msg
howDoesThisWork =
    E.column []
        [ E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
            [ E.text "codestat.dev leverages an "
            , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "experimental Sourcegraph compute API" }
            , E.text " to perform regex searches over the code in 2m+ open source repositories"
            , E.text ", and then perform computation over the result set (you can explore yourself using the "
            , E.link [] { url = "/compute", label = E.text "compute data explorer" }
            , E.text ") We then use the "
            , E.link [] { url = "https://elm-lang.org", label = E.text "Elm language" }
            , E.text " to visualize the results."
            ]
        , E.paragraph [ E.paddingXY 0 32, E.width (E.fill |> E.maximum 800) ]
            [ E.text "Want a different code stat like this for OSS code or your project? Tweet requests "
            , E.link [] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
            ]
        ]
