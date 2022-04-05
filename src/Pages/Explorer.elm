module Pages.Explorer exposing (Model, Msg, init, page, update, view)

import Compute
import Element as E
import Element.Font as Font
import Element.Region as Region
import Layout
import Page
import Request exposing (Request)
import Shared
import Url.Parser exposing (..)
import View exposing (View)


type alias Model =
    { wordCloud : Compute.Model
    }


type Msg
    = WordCloudMsg Compute.Msg


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init shared
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    let
        ( subModel, subCmd ) =
            Compute.init shared
    in
    ( { wordCloud = subModel }, Cmd.map WordCloudMsg subCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        WordCloudMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Compute.update subMsg model.wordCloud
            in
            ( { model | wordCloud = subModel }, Cmd.map WordCloudMsg subCmd )


view : Model -> View Msg
view model =
    { title = "compute data explorer"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Compute data explorer")
                , E.el [ E.paddingXY 0 32 ] (E.map WordCloudMsg (Compute.view model.wordCloud))
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 } ] (E.text "About")
                , about
                ]
            ]
    }


about : E.Element msg
about =
    E.column []
        [ E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
            [ E.text "codestat.dev leverages an "
            , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "experimental Sourcegraph compute API" }
            , E.text " to perform regex searches over the code in 2m+ open source repositories"
            , E.text ", and then perform computation over the result set. "
            , E.link [] { url = "https://elm-lang.org", label = E.text "The Elm language" }
            , E.text " is used to visualize the results, and render the data explorer above."
            ]
        , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
            [ E.text "You can learn more about how powerful this all is "
            , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "via this thread" }
            , E.text " from the creator of Compute at Sourcegraph."
            ]
        , E.paragraph [ E.paddingXY 0 32, E.width (E.fill |> E.maximum 800) ]
            [ E.text "All this stuff is pretty early stages! Feel free to tweet us "
            , E.link [] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map WordCloudMsg (Compute.subscriptions model.wordCloud)
