module Pages.S.Zulip.Groups exposing (Model, Msg, init, page, update, view)

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
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://[-\\w]+\\.(zulipchat\\.com) -> $1) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 20
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "number"
            }

        panel1 : ComputeBackend.ComputeInput
        panel1 =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://([-\\w]+)\\.zulipchat\\.com -> $1 (group by) $repo) count:all" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Nothing
            }

        panel2 : ComputeBackend.ComputeInput
        panel2 =
            { computeQueries = [ "(lang:markdown OR lang:text) content:output(https://([-\\w]+)\\.zulipchat\\.com -> $1 (group by) $repo) count:all @@@ https://$1.zulipchat.com" ]
            , experimentalOptions =
                Just
                    { dataPoints = Just 10000
                    , sortByCount = Nothing
                    , reverse = Nothing
                    , excludeStopWords = Nothing
                    }
            , editible = Just False
            , selectedTab = Just "link-cloud"
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
    { title = "zulip/groups - codestat.dev"
    , body =
        Layout.body
            [ E.column [ E.centerX ]
                [ E.el [ Region.heading 1, Font.size 24, E.paddingEach { top = 64, right = 0, bottom = 0, left = 0 } ]
                    (E.text "Zulip chat groups in top 2m+ repositories")
                , E.el [ E.centerX, E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 0 Compute.defaults)
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "Top 10 most-linked Zulip chat groups")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 1 Compute.defaults)
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "All Zulip chat groups by most-linked")
                , E.el [ E.paddingEach { top = 0, right = 0, bottom = 32, left = 0 }, E.width E.fill ] (Panels.render PanelsMsg model.panels 2 { minHeight = Just 550 })
                , E.el [ Region.heading 2, Font.size 20 ] (E.text "How does this work?")
                , Layout.howDoesThisWork
                ]
            ]
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Panels.subscriptions PanelsMsg model.panels
