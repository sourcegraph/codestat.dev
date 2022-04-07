module Pages.S.Zulip.Dev exposing (Model, Msg, init, page, update, view)

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
            { computeQueries = [ "repo:github\\.com/zulip/zulip$ content:output((.|\n)* -> $author) type:commit since:\"6 months ago\" count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10
                    , sortByCount = Just True
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "chart"
            }

        panel1 : ComputeBackend.ComputeInput
        panel1 =
            { computeQueries = [ "repo:github\\.com/zulip/zulip$ type:commit since:\"3 months ago\" count:10000 content:output((\\w+) -> $1) @@@ https://sourcegraph.com/search?q=context:global+repo:github%5C.com/zulip/zulip%24+type:commit+$1&patternType=regexp" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 50
                    , sortByCount = Just True
                    , reverse = Nothing
                    , excludeStopWords = Just True
                    }
            , editible = Just False
            , selectedTab = Just "link-cloud"
            }

        panel2 : ComputeBackend.ComputeInput
        panel2 =
            { computeQueries = [ "since:\"2 months ago\" repo:github\\.com/zulip/zulip$ content:output(^.*/.*\\ (.*/.*) -> $1) type:diff count:all @@@ https://sourcegraph.com/search?q=context:global+repo:github%5C.com/zulip/zulip%24+type:diff+file:$1&patternType=literal" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10
                    , sortByCount = Just True
                    , reverse = Nothing
                    , excludeStopWords = Just True
                    }
            , editible = Just False
            , selectedTab = Just "table"
            }

        ( panelsModel, panelsCmd ) =
            Panels.init PanelsMsg shared [ panel0, panel1, panel2 ]
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
    { title = "zulip/dev - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX ]
                [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 64, right = 0, bottom = 32, left = 0 } ]
                    (E.text "Zulip development stats")
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Top committers to github.com/zulip/zulip in last 6mo")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 0 Compute.defaults)
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Commit message topics in last 3mo")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 1 { minHeight = Just 200 })
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Most modified files in last 2mo")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 2 Compute.defaults)
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "How does this work?")
                , Layout.howDoesThisWork
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
