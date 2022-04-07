module Pages.S.Golang.Net exposing (Model, Msg, init, page, update, view)

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
        panel0 : ComputeBackend.ComputeInput
        panel0 =
            { computeQueries = [ "lang:go content:output((net\\.[A-Z]\\w+) -> $1) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 20
                    , sortByCount = Just True
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "chart"
            }

        panel1 : ComputeBackend.ComputeInput
        panel1 =
            { computeQueries = [ "lang:go content:output((http\\.[A-Z]\\w+) -> $1) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 20
                    , sortByCount = Just True
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "chart"
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
    { title = "golang/net - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX ]
                [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 64, right = 0, bottom = 32, left = 0 } ]
                    (E.text "Golang net package stats")
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Most used net.Symbol across all Go repositories")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 0 Compute.defaults)
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Most used http.Symbol across all Go repositories")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 1 { minHeight = Just 500 })
                , Layout.howDoesThisWork
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
