module Pages.S.TheArchives.MicrosoftMovieMaker exposing (Model, Msg, page)

import Compute exposing (Tab(..))
import Dict exposing (Dict)
import Element as E
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
    [ { description = "Language breakdown (number of files)"
      , query = "repo:^github\\.com/microsoft/Microsoft-3D-Movie-Maker$ content:output(.* -> $lang) type:path count:all"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }

    {--This one's too heavy right now
    , { description = "Language breakdown (lines of code)"
      , query = "repo:^github\\.com/microsoft/Microsoft-3D-Movie-Maker$ content:output(.* -> $lang) type:file count:all"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
-}
    , { description = "Most common starting words of `printf` statements"
      , query = "repo:^github\\.com/microsoft/Microsoft-3D-Movie-Maker$ -file:.cht content:output(printf\\(\\\"([^\\s\\\"]+) -> $1) type:file count:all"
      , dataPoints = 15
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
    , { description = "Interesting or funny words in the repo (click link to see context)"
      , query = "repo:^github\\.com/microsoft/Microsoft-3D-Movie-Maker$ -file:.gitignore -file:.cht content:output(\\b(careful|stuff|nuke|funny|silly|\\.\\.\\.why|crap|good!|crash|impossible) -> $1) type:file count:all  @@@ https://sourcegraph.com/search?q=context:global+repo:^github%5C.com/microsoft/Microsoft-3D-Movie-Maker%24+-file:%5C.cht+$1&patternType=literal"
      , dataPoints = 20
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = LinkCloud
      , editible = False
      }
    , { description = "Most common in-line comments"
      , query = "repo:^github\\.com/microsoft/Microsoft-3D-Movie-Maker$ -file:.cht content:output(//(?:/*)?(?: -*)?(.*) -> $1) type:file count:all"
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
    { title = "the-archives/microsoft-movie-maker - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.spacingXY 0 70 ]
                ([ headerView ] ++ dataView model ++ [ footerView ])
            ]
    }


headerView : E.Element Msg
headerView =
    E.column [ E.width E.fill, E.paddingXY 0 50 ]
        [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 64, right = 0, bottom = 32, left = 0 } ]
            (E.text "Microsoft 3D Movie Maker (1995)")
        , E.newTabLink [ Font.size 20 ]
            { url = "https://twitter.com/shanselman/status/1521698902579159040"
            , label = E.el [ Font.color (E.rgb255 0x12 0x93 0xD8) ] (E.text "Open source release announced on May 3, 2022 ↗")
            }
        ]


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


footerView : E.Element Msg
footerView =
    E.column [ E.width E.fill ]
        [ E.el [ Region.heading 2, Font.size 20 ] (E.text "How does this work?")
        , Layout.howDoesThisWork
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Dict.toList model
        |> List.map (\( i, { inputs } ) -> Sub.map (Update i) (Compute.subscriptions inputs))
        |> Sub.batch
