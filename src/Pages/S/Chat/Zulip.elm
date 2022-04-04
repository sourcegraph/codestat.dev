module Pages.S.Chat.Zulip exposing (Model, Msg, init, page, update, view)

import Array exposing (Array)
import Compute
import ComputeBackend
import Element as E
import Element.Font as Font
import Element.Region as Region
import Layout
import Page
import Panels
import Request exposing (Request)
import Shared
import Url.Parser exposing (..)
import View exposing (View)


type alias Model =
    { panels : Panels.Model
    }


type Msg
    = PanelsMsg Panels.Msg


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
        panel0 : ComputeBackend.ComputeInput
        panel0 =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://(\\w+)\\.zulipchat\\.com -> $1 (group by) $repo) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Nothing
            }

        panel1 : ComputeBackend.ComputeInput
        panel1 =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://\\w+\\.(zulipchat\\.com) -> $1) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 20
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "number"
            }

        ( panelsModel, panelsCmd ) =
            Panels.init PanelsMsg shared [ panel0, panel1 ]
    in
    ( { panels = panelsModel }, panelsCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PanelsMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Panels.update PanelsMsg subMsg model.panels
            in
            ( { model | panels = subModel }, subCmd )


view : Model -> View Msg
view model =
    { title = "Zulip chat - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Zulip chat stats from 2m+ OSS repositories")
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ] (E.text "Top 10 most-linked Zulip chat groups")
                , Panels.render PanelsMsg model.panels 0
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ]
                    (E.row []
                        [ E.text "Unique Zulip chat rooms across 2m+ repos: "
                        , Panels.render PanelsMsg model.panels 1
                        ]
                    )
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
