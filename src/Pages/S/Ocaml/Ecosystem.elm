module Pages.S.Ocaml.Ecosystem exposing (Model, Msg, page)

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
    "ocaml/ecosystem - codestat.dev"


header =
    "OCaml ecosystem stats"


data =
    [ { description = "Do projects use Lwt or Async? (counted from opam files in GH repos)"
      , query = "file:opam|\\.opam$ -repo:opam-repository content:output(\\\"(async|lwt)\\\" -> $1) count:all"
      , dataPoints = 10
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
    , { description = "Most used Jane Street libraries"
      , query = "file:\\.opam$|opam -repo:opam-repository -repo:janestreet content:output(\"(base|core|core_kernel|async|sexplib|bin_prot|hardcaml|incremental|bonsai|ppx_let)\" -> $1) count:all"
      , dataPoints = 20
      , sortByCount = True
      , reverse = False
      , excludeStopWords = False
      , selectedTab = Chart
      , editible = False
      }
    , { description = "OCaml at Meta/Facebook, one of the largest industrial users"
      , query = "repo:github\\.com/facebook lang:ocaml type:path content:output(.* -> $lang files in $repo) count:all"
      , dataPoints = 50
      , sortByCount = True
      , reverse = False
      , excludeStopWords = True
      , selectedTab = Table
      , editible = False
      }
    , { description = "List of projects using Jane Street libraries (click source and edit 50 to see more)"
      , query = "file:\\.opam$|opam -repo:opam-repository -repo:janestreet content:output(\\\"(base|core|core_kernel|async|sexplib|bin_prot|hardcaml|incremental|bonsai|ppx_let)\\\" -> $repo) count:all"
      , dataPoints = 50
      , sortByCount = True
      , reverse = False
      , excludeStopWords = True
      , selectedTab = Data
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
