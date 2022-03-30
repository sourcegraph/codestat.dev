module Pages.S.Chat.Zulip exposing (Model, Msg, init, page, update, view)

import Compute
import ComputeBackend
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
        flags =
            shared.flags

        computeInput : ComputeBackend.ComputeInput
        computeInput =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://(\\w+)\\.zulipchat\\.com -> $1:@:$repo) count:1000" ]
            , experimentalOptions = Nothing
            , editible = Just False
            }

        mergedFlags =
            { flags | computeInput = Just computeInput }

        ( subModel, subCmd ) =
            Compute.init { shared | flags = mergedFlags }
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
    { title = "Zulip"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Zulip chat: stats from 2m+ repositories")
                , E.map WordCloudMsg (Compute.view model.wordCloud)
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map WordCloudMsg (Compute.subscriptions model.wordCloud)
