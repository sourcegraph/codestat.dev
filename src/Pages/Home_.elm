module Pages.Home_ exposing (Model, Msg, init, page, update, view)

import Compute exposing (Tab(..))
import Dict exposing (Dict)
import Element as E
import Element.Border as Border
import Element.Font as Font
import Element.Region as Region
import Layout
import Page
import Request exposing (Request)
import Shared
import Task
import Url.Parser exposing (..)
import View exposing (View)


data =
    [ { description = ""
      , query = "context:@r/go-100-gh lang:go content:output((type \\w* interface) -> $1 (group by) $repo) count:all"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
    ]


type alias Panel =
    { description : String
    , inputs : Compute.Model
    }


type alias Model =
    Dict Int Panel


type Msg
    = Update Int Compute.Msg


type alias PanelInputs =
    { description : String
    , query : String
    , selectedTab : Tab
    , dataPoints : Int
    , sortByCount : Bool
    , reverse : Bool
    , excludeStopWords : Bool
    , editible : Bool
    }


page : Shared.Model -> Request -> Page.With Model Msg
page shared _ =
    Page.element
        { init = init shared
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


init : Shared.Model -> ( Model, Cmd Msg )
init _ =
    let
        model =
            data
                |> List.map initPanel
                |> List.indexedMap Tuple.pair
                |> Dict.fromList
    in
    ( model
    , Dict.keys model
        |> List.map (\i -> Task.perform identity (Task.succeed (Update i Compute.RunCompute)))
        |> Cmd.batch
    )


initPanel : PanelInputs -> Panel
initPanel { description, query, selectedTab, dataPoints, sortByCount, reverse, excludeStopWords, editible } =
    { description = description
    , inputs =
        { sourcegraphURL = "https://sourcegraph.com"
        , query = query
        , dataFilter =
            { dataPoints = dataPoints
            , sortByCount = sortByCount
            , reverse = reverse
            , excludeStopWords = excludeStopWords
            }
        , selectedTab = selectedTab
        , editible = editible
        , debounce = 0
        , resultCount = 0
        , resultsMap = Dict.empty
        , serverless = False
        }
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update (Update i m) model =
    (Dict.get i model
        |> Maybe.map (Compute.update m << .inputs)
        |> Maybe.map
            (\( newInputs, cmd ) ->
                ( Dict.update i
                    (Maybe.map (\v -> { v | inputs = newInputs }))
                    model
                , Cmd.map (Update i) cmd
                )
            )
    )
        |> Maybe.withDefault ( model, Cmd.none )


view : Model -> View Msg
view model =
    { title = "codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.width (E.fill |> E.maximum 800), E.spacingXY 0 32, E.centerX ]
                [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 } ] (E.text "Real time stats from 2 million open source repositories")
                , exampleView model
                , linkedPagesView
                , detailsView
                ]
            ]
    }


exampleView : Model -> E.Element Msg
exampleView model =
    E.column [ E.width E.fill, E.spacingXY 0 32, E.centerX ]
        ([ E.paragraph []
            [ E.text "codestat.dev runs regex search queries over 2m+ open source repositories and performs computation in real time, as thousands of results stream in to your browser!"
            ]
         , E.paragraph [] [ E.text "Ever wondered what most popular `interface` type name is in the top 100 Go repositories? We can answer that:" ]
         ]
            ++ dataView model
            ++ [ E.paragraph []
                    [ E.text "Once the results finish loading, you'll see that \"Logger\" is the most popular Go interface name found and is found in 33 of the top 100 Go repositories!"
                    ]
               ]
        )


dataView : Model -> List (E.Element Msg)
dataView model =
    Dict.toList model
        |> List.map
            (\( i, { description, inputs } ) ->
                E.column [ E.width E.fill, E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 } ]
                    [ E.el [ Region.heading 2, Font.size 20 ] (E.text description)
                    , E.map (Update i) (Compute.view Compute.defaults inputs)
                    ]
            )


linkedPagesView : E.Element Msg
linkedPagesView =
    E.column [ E.width E.fill, E.paddingXY 0 32, E.spacingXY 0 32 ]
        [ E.el [ E.centerX, Region.heading 2, Font.size 20 ] (E.text "🔥 All project stats 🔥")
        , E.column
            [ E.paddingXY 0 16
            , E.spacingXY 0 16
            , Border.widthEach { bottom = 1, left = 0, right = 0, top = 1 }
            , Border.color (E.rgb255 33 205 6)
            , E.width E.fill
            ]
            [ E.wrappedRow [ E.padding 16, E.centerX ]
                [ statGroup "Zulip"
                    [ ( "chat groups", "/s/zulip/groups" )
                    , ( "development", "/s/zulip/dev" )
                    ]
                , statGroup "Golang"
                    [ ( "development", "/s/golang/dev" )
                    , ( "net pkg", "/s/golang/net" )
                    , ( "conventions", "/s/golang/conventions" )
                    ]
                , statGroup "The Archives"
                    [ ( "Microsoft 3D Movie Maker (1995)    ", "/s/the-archives/microsoft-movie-maker" )
                    ]
                ]
            , E.paragraph [] [ E.el [ Font.size 12 ] (E.text "(more coming soon)") ]
            , E.paragraph []
                [ E.text "Want a custom code stat? We'll add it! Just tweet us "
                , E.link [] { url = "https://twitter.com/codestat_dev", label = E.text "@codestat_dev" }
                ]
            ]
        ]


detailsView : E.Element Msg
detailsView =
    E.column [ E.width E.fill, E.paddingXY 0 32, E.spacingXY 0 32 ]
        [ E.el [ Region.heading 2, Font.size 20 ] (E.text "Tech details")
        , E.paragraph []
            [ E.text "This leverage an experimental "
            , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "Sourcegraph search compute API" }
            , E.text " which, behind the scenes, searches over a very large trigram index (roughly the top 2 million GitHub repositories by stars) so that we can do regexp matching over *all* that code, stream every match back to the browser using the EventSource API, and finally visualize them."
            ]
        , E.paragraph []
            [ E.text " You can even "
            , E.link [] { url = "/explorer", label = E.text "explore the data" }
            , E.text " using your own queries!"
            ]
        , E.el [ Region.heading 2, Font.size 20 ] (E.text "History")
        , E.paragraph []
            [ E.link [] { url = "https://twitter.com/slimsag", label = E.text "@slimsag" }
            , E.text " here! I've been working at "
            , E.link [] { url = "https://sourcegraph.com", label = E.text "Sourcegraph" }
            , E.text " a little over 7 years, my coworker "
            , E.link [] { url = "https://twitter.com/rvtond", label = E.text "@rvtond" }
            , E.text " (researcher on the Search team), has been tirelessly building out a 'search compute' engine for the past few years - originally as a sort of one-man passion project (I remember the day he joined he was talking about building this, and has since pulled in a few other passionate devs.)"
            ]
        , E.paragraph []
            [ E.text " Recently, the backend API began to really come together. At the same time, I kept hearing great things about the "
            , E.link [] { url = "https://elm-lang.org", label = E.text "Elm language" }
            , E.text ", and it turned out he was using it to prototype! The more I played around with his work, the more powerful I thought it was and I wanted to find a nice way to share that power with others "
            ]
        , E.paragraph []
            [ E.text "Conveniently, my manager had given me a week to try out a crazy-idea between projects *and* I had another full week for a hackathon, two whole weeks! I took the opportunity to learn Elm (which was hard, but worth it) and pester my coworker for all his knowledge. codestat.dev was born! "
            ]
        , E.paragraph []
            [ E.text "This is an unofficial Sourcegraph project, all very experimental! If you like it, let us know! "
            ]
        ]


statGroup : String -> List ( String, String ) -> E.Element msg
statGroup groupName stats =
    E.column [ E.width E.fill, E.padding 8 ]
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
    Dict.toList model
        |> List.map (\( i, { inputs } ) -> Sub.map (Update i) (Compute.subscriptions inputs))
        |> Sub.batch
