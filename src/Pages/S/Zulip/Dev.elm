module Pages.S.Zulip.Dev exposing (Model, Msg, init, page, update, view)

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


title =
    "zulip/dev - codestat.dev"


header =
    "Zulip development stats"


data =
    [ { description = "Top committers to github.com/zulip/zulip in last 6mo"
      , query = "repo:github\\.com/zulip/zulip$ content:output((.|\n)* -> $author) type:commit since:\"6 months ago\" count:all"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
    , { description = "Commit message topics in last 3mo"
      , query = "repo:github\\.com/zulip/zulip$ type:commit since:\"3 months ago\" count:10000 content:output((?i)(zulip|add|update|fixes|remove)|(\\w+) -> $2) @@@ https://sourcegraph.com/search?q=context:global+r\nepo:github%5C.com/golang/go%24+type:commit+$1&patternType=regexp"
      , dataPoints = 50
      , sortByCount = True
      , reverse = False
      , excludeStopWords = True
      , selectedTab = LinkCloud
      , editible = False
      }
    , { description = "Most modified files in last 2mo"
      , query = "since:\"2 months ago\" repo:github\\.com/zulip/zulip$ content:output(^.*/.*\\ (.*/.*) -> $1) type:diff count:all @@@ https://sourcegraph.com/search?q=context:global+repo:github%5C.com/zulip/zulip%24+type:diff+file:$1&patternType=literal"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = True
      , selectedTab = Table
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
    { title = title
    , body =
        Layout.body
            [ E.column [ E.centerX ]
                ([ headerView ] ++ dataView model ++ [ footerView ])
            ]
    }


headerView : E.Element Msg
headerView =
    E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 64, right = 0, bottom = 32, left = 0 } ]
        (E.text header)


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
    E.column []
        [ E.el [ Region.heading 2, Font.size 20 ] (E.text "How does this work?")
        , Layout.howDoesThisWork
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Dict.toList model
        |> List.map (\( i, { inputs } ) -> Sub.map (Update i) (Compute.subscriptions inputs))
        |> Sub.batch
