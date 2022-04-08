module Pages.Explorer exposing (Model, Msg, init, page, update, view)

import Compute
import Element as E
import Element.Font as Font
import Element.Region as Region
import Layout
import Page
import Request exposing (Request)
import Shared
import Url.Parser exposing (..)
import View exposing (View)



type alias Model =
    { explorer : Compute.Model
    }


type Msg
    = Explorer Compute.Msg


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
        ( subModel, subCmd ) =
            Compute.init shared
    in
    ( { explorer = subModel }, Cmd.map Explorer subCmd )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Explorer subMsg ->
            let
                ( subModel, subCmd ) =
                    Compute.update subMsg model.explorer
            in
            ( { model | explorer = subModel }, Cmd.map Explorer subCmd )


view : Model -> View Msg
view model =
    { title = "compute data explorer"
    , body =
        Layout.body
            [ E.column [ E.centerX, E.paddingXY 0 64 ]
                [ E.el [ Region.heading 1, Font.size 24 ] (E.text "Compute data explorer")
                , E.el [ E.paddingXY 0 32, E.width E.fill ] (E.map Explorer (Compute.view Compute.defaults model.explorer))
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
    Sub.map Explorer (Compute.subscriptions model.explorer)
