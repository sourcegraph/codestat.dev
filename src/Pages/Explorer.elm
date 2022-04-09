module Pages.Explorer exposing (Model, Msg, init, page, update, view)

import Browser.Navigation as Navigation
import Compute exposing (Msg(..), Tab(..))
import Dict
import Element as E
import Element.Font as Font
import Element.Region as Region
import Layout
import Page
import Request exposing (Request)
import Shared
import Url
import Url.Builder
import Url.Parser exposing (..)
import View exposing (View)


type alias Model =
    Compute.Model


type Msg
    = Explorer Compute.Msg


type alias UrlParams =
    -- Values in the URL that may initialize query or tab
    { query : Maybe String
    , tab : Maybe Tab
    }


page : Shared.Model -> Request -> Page.With Model Msg
page shared ({ query } as req) =
    Page.element
        { init = init shared (decodeUrlParams query)
        , update = update req
        , view = view
        , subscriptions = subscriptions
        }


init : Shared.Model -> UrlParams -> ( Model, Cmd Msg )
init shared urlParams =
    Compute.init shared
        |> Tuple.mapBoth
            (\model ->
                { model
                    | query = Maybe.withDefault model.query urlParams.query
                    , selectedTab = Maybe.withDefault model.selectedTab urlParams.tab
                }
            )
            (Cmd.map Explorer)


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update req msg model =
    let
        ( computeModel, computeCmd ) =
            case msg of
                Explorer subMsg ->
                    Compute.update subMsg model

        explorerCmd =
            -- Explorer page doesn't modify the model, just possibly a command (triggers URL update)
            case msg of
                Explorer subMsg ->
                    case subMsg of
                        OnTabSelected tab ->
                            Navigation.pushUrl req.key (encodeNewUrl model.query tab)

                        OnDebounce ->
                            Navigation.pushUrl req.key (encodeNewUrl model.query model.selectedTab)

                        _ ->
                            Cmd.none
    in
    ( computeModel, Cmd.map Explorer (Cmd.batch [ computeCmd, explorerCmd ]) )


view : Model -> View Msg
view model =
    { title = "compute data explorer"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Compute data explorer")
                , E.el [ E.paddingXY 0 32, E.width E.fill ] (E.map Explorer (Compute.view Compute.defaults model))
                , E.el [ Region.heading 2, Font.size 20, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ] (E.text "How do I use this?")
                , E.paragraph [ E.paddingEach { top = 32, right = 0, bottom = 0, left = 0 }, E.width (E.fill |> E.maximum 800) ]
                    [ E.text "Documentation is lacking right now, sorry! We're working on it. For now I suggest you check out "
                    , E.link [] { url = "https://twitter.com/rvtond/status/1509677515761094659", label = E.text "this Twitter thread" }
                    , E.text " which details some of the capabilities. You can also click the (source) text next to any stat (on the homepage, etc.) to see the query it uses."
                    ]
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map Explorer (Compute.subscriptions model)


encodeNewUrl query selectedTab =
    Url.Builder.relative
        [ "explorer" ]
        [ Url.Builder.string "q" query
        , Url.Builder.string "t" (tabToString selectedTab)
        ]


decodeUrlParams : Dict.Dict String String -> UrlParams
decodeUrlParams params =
    { query = Dict.get "q" params
    , tab = Maybe.andThen tabFromString (Dict.get "t" params)
    }


tabFromString : String -> Maybe Tab
tabFromString s =
    case s of
        "chart" ->
            Just Chart

        "table" ->
            Just Table

        "data" ->
            Just Data

        "number" ->
            Just Number

        "linkCloud" ->
            Just LinkCloud

        _ ->
            Nothing


tabToString : Tab -> String
tabToString tab =
    case tab of
        Chart ->
            "chart"

        Table ->
            "table"

        Data ->
            "data"

        Number ->
            "number"

        LinkCloud ->
            "linkCloud"
