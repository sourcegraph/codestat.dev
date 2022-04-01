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
    { panel1 : Compute.Model
    , panel2 : Compute.Model
    }


type Msg
    = Panel1Msg Compute.Msg
    | Panel2Msg Compute.Msg


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

        panel1ComputeInput : ComputeBackend.ComputeInput
        panel1ComputeInput =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://(\\w+)\\.zulipchat\\.com -> $1 (group by) $repo) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            }

        panel1MergedFlags =
            { flags | computeInput = Just panel1ComputeInput }

        ( panel1SubModel, panel1SubCmd ) =
            Compute.init { shared | flags = panel1MergedFlags }

        panel2ComputeInput : ComputeBackend.ComputeInput
        panel2ComputeInput =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://\\w+\\.(zulipchat\\.com) -> $1) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 20
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            }

        panel2MergedFlags =
            { flags | computeInput = Just panel2ComputeInput }

        ( panel2SubModel, panel2SubCmd ) =
            Compute.init { shared | flags = panel2MergedFlags }
    in
    ( { panel1 = panel1SubModel, panel2 = panel2SubModel }
    , Cmd.batch
        [ Cmd.map Panel1Msg panel1SubCmd
        , Cmd.map Panel2Msg panel2SubCmd
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Panel1Msg subMsg ->
            let
                ( subModel, subCmd ) =
                    Compute.update subMsg model.panel1
            in
            ( { model | panel1 = subModel }, Cmd.map Panel1Msg subCmd )

        Panel2Msg subMsg ->
            let
                ( subModel, subCmd ) =
                    Compute.update subMsg model.panel2
            in
            ( { model | panel2 = subModel }, Cmd.map Panel2Msg subCmd )


view : Model -> View Msg
view model =
    { title = "Zulip - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Zulip chat stats from 2m+ repositories")
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ] (E.text "Top 10 most-linked Zulip chat groups")
                , E.map Panel1Msg (Compute.view model.panel1)
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ] (E.text "Unique Zulip chat rooms across 2m+ repos")
                , E.map Panel2Msg (Compute.view model.panel2)
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map Panel1Msg (Compute.subscriptions model.panel1)
        , Sub.map Panel2Msg (Compute.subscriptions model.panel2)
        ]
