module Pages.Home_ exposing (Model, Msg, init, page, update, view)

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
            { computeQueries = [ "context:@r/go-100-gh lang:go content:output((type \\w* interface) -> $1 (group by) $repo) count:all" ]
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

        ( panelsModel, panelsCmd ) =
            Panels.init PanelsMsg shared [ panel0 ]
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
    { title = "codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX ]
                [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 } ] (E.text "Real time stats from 2 million open source repositories")
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "codestat.dev runs regex search queries over 2m+ open source repositories and performs"
                    , E.text " computation in real time, as thousands of results stream in to your browser!"
                    ]
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "For example-we can search the top 100 Go repositories and find the most popular interface type name:"
                    ]
                , E.el [ E.paddingEach { top = 32, right = 0, bottom = 50, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 0)
                , E.paragraph [ E.paddingXY 0 32, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "Once results stop loading, you'll see Logger is the most popular name found in ~33 of the top Go repositories!"
                    ]
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 } ] (E.text "Recent project stats")
                , E.column [ E.paddingEach { top = 16, right = 0, bottom = 32, left = 0 } ]
                    [ E.row []
                        [ E.text "• "
                        , E.link [ Region.heading 1, E.paddingXY 0 8 ] { url = "/s/zulip", label = E.text "Zulip" }
                        , E.text " - chat software for distributed teams"
                        ]
                    , E.row []
                        [ E.text "• more projects coming soon.."
                        ]
                    ]
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 } ] (E.text "How it works")
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "Behind the scenes we leverage an experimental "
                    , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "Sourcegraph compute API" }
                    , E.text " to perform computation over thousands to millions of search results from Sourcegraph code search"
                    , E.text " (you can explore yourself using the "
                    , E.link [] { url = "/explorer", label = E.text "compute data explorer" }
                    , E.text ".) We then use the "
                    , E.link [] { url = "https://elm-lang.org", label = E.text "Elm language" }
                    , E.text " to visualize the results."
                    ]
                , E.paragraph [ E.paddingXY 0 32, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "We create dashboards for interesting stats/projects and post them to our Twitter "
                    , E.link [] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
                    ]
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
