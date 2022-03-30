module Pages.Compute exposing (Model, Msg, init, page, update, view)

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
page shared req =
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
                , E.map WordCloudMsg (Compute.view model.wordCloud)
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map WordCloudMsg (Compute.subscriptions model.wordCloud)
