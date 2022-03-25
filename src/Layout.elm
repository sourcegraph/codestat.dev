module Layout exposing (body)

import Html as H
import Html.Attributes as A


body : List (H.Html msg) -> List (H.Html msg)
body content =
    [ header
    , H.div [ A.style "flex-grow" "1", A.style "padding" "1rem" ] content
    , footer
    ]


header : H.Html msg
header =
    H.header [ A.style "padding" "1rem", A.style "padding-bottom" "0" ]
        [ H.a [ A.href "/", A.class "logo" ]
            [ H.h1 [ A.style "margin" "0" ]
                [ H.span [ A.style "font-size" "32px", A.style "margin-right" "0.25em" ] [ H.text "▄▆█" ]
                , H.text "codestats.dev"
                ]
            ]
        , H.h4 [ A.style "margin" "0" ] [ H.text "> stats from 2m+ repositories" ]
        ]


footer : H.Html msg
footer =
    H.footer
        [ A.style "display" "flex"
        , A.style "justify-content" "space-around"
        , A.style "border-top" "1px solid #21cd06"
        , A.style "padding-bottom" "1.5rem"
        ]
        [ H.span
            [ A.style "padding" "0.5rem"
            , A.style "flex-grow" "1"
            , A.style "text-align" "center"
            , A.style "border-right" "1px solid #21cd06"
            ]
            [ H.text "powered by "
            , H.a [ A.href "https://sourcegraph.com" ] [ H.text "Sourcegraph" ]
            ]
        , H.span
            [ A.style "padding" "0.5rem"
            , A.style "flex-grow" "1"
            , A.style "text-align" "center"
            , A.style "border-right" "1px solid #21cd06"
            ]
            [ H.a [ A.href "/compute" ] [ H.text "raw data explorer" ]
            ]
        , H.span
            [ A.style "padding" "0.5rem"
            , A.style "flex-grow" "1"
            , A.style "text-align" "center"
            ]
            [ H.text "feedback/requests? "
            , H.a [ A.href "https://twitter.com/CodeStatsDev" ] [ H.text "@CodeStatsDev" ]
            , H.text " on Twitter"
            ]
        ]
