module Pages.Home_ exposing (Model, Msg, init, page, update, view)

import Compute
import ComputeBackend
import Element as E
import Element.Border as Border
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
                    [ E.text "Ever wondered what most popular `interface` type name is in the top 100 Go repositories? We can answer that:"
                    ]
                , E.el [ E.paddingEach { top = 32, right = 0, bottom = 50, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 0 Compute.defaults)
                , E.paragraph [ E.paddingEach { top = 48, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "Once the results finish loading, you'll see that \"Logger\" is the most popular Go interface name found and is found in 33 of the top 100 Go repositories!"
                    ]
                , E.el [ E.centerX, Region.heading 2, Font.size 20, E.paddingEach { top = 48, right = 0, bottom = 16, left = 0 } ] (E.text "🔥 All project stats 🔥")
                , E.column
                    [ E.paddingEach { top = 16, right = 0, bottom = 16, left = 0 }
                    , Border.widthEach { bottom = 1, left = 0, right = 0, top = 1 }
                    , Border.color (E.rgb255 33 205 6)
                    , E.width E.fill
                    ]
                    [ E.row [ E.padding 16 ]
                        [ statGroup "Zulip"
                            [ ( "chat groups", "/s/zulip/groups" )
                            , ( "development", "/s/zulip/dev" )
                            ]
                        , statGroup "Golang"
                            [ ( "development", "/s/golang/dev" )
                            , ( "net pkg", "/s/golang/net" )
                            ]
                        , statGroup "The Archives"
                            [ ( "Microsoft 3D Movie Maker (1995)", "/s/the-archives/microsoft-movie-maker" )
                            ]
                        ]
                    , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                        [ E.el [ Font.size 12 ] (E.text "(more coming soon)")
                        ]
                    , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                        [ E.text "Want a custom code stat? We'll add it! Just tweet us "
                        , E.link [] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
                        ]
                    ]
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 48, right = 0, bottom = 0, left = 0 } ] (E.text "Tech details")
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "This leverage an experimental "
                    , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "Sourcegraph search compute API" }
                    , E.text " which, behind the scenes, searches over a very large trigram index (roughly the top 2 million GitHub repositories by stars) so that we can do regexp matching over *all* that code, stream every match back to the browser using the EventSource API, and finally visualize them."
                    ]
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text " You can even "
                    , E.link [] { url = "/explorer", label = E.text "explore the data" }
                    , E.text " using your own queries!"
                    ]
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 48, right = 0, bottom = 0, left = 0 } ] (E.text "History")
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.link [] { url = "https://twitter.com/slimsag", label = E.text "@slimsag" }
                    , E.text " here! I've been working at "
                    , E.link [] { url = "https://sourcegraph.com", label = E.text "Sourcegraph" }
                    , E.text " a little over 7 years, my coworker "
                    , E.link [] { url = "https://twitter.com/rvtond", label = E.text "@rvtond" }
                    , E.text " (researcher on the Search team), has been tirelessly building out a 'search compute' engine for the past few years - originally as a sort of one-man passion project (I remember the day he joined he was talking about building this, and has since pulled in a few other passionate devs.)"
                    ]
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text " Recently, the backend API began to really come together. At the same time, I kept hearing great things about the "
                    , E.link [] { url = "https://elm-lang.org", label = E.text "Elm language" }
                    , E.text ", and it turned out he was using it to prototype! The more I played around with his work, the more powerful I thought it was and I wanted to find a nice way to share that power with others "
                    ]
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "Conveniently, my manager had given me a week to try out a crazy-idea between projects *and* I had another full week for a hackathon, two whole weeks! I took the opportunity to learn Elm (which was hard, but worth it) and pester my coworker for all his knowledge. codestat.dev was born! "
                    ]
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "This is an unofficial Sourcegraph project, all very experimental! If you like it, let us know! "
                    ]
                ]
            ]
    }


statGroup : String -> List ( String, String ) -> E.Element msg
statGroup groupName stats =
    E.column [ E.padding 8 ]
        [ E.el
            [ E.centerX
            , Region.heading 3
            , Font.size 20
            , E.paddingEach { top = 0, right = 0, bottom = 16, left = 0 }
            ]
            (E.text groupName)
        , E.column
            [ Border.widthEach { bottom = 1, left = 1, right = 1, top = 1 }
            , Border.color (E.rgb255 33 205 6)
            , E.padding 8
            , E.height (E.fill |> E.minimum 100)
            , E.width (E.fill |> E.minimum 100)
            ]
            (List.map stat stats)
        ]


stat : ( String, String ) -> E.Element msg
stat labelUrl =
    let
        ( label, url ) =
            labelUrl
    in
    E.link [ E.padding 8 ] { url = url, label = E.text label }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
