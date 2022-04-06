module Panels exposing (..)

import Array exposing (Array)
import Compute
import ComputeBackend
import Element as E
import Shared
import Url.Parser exposing (..)


type alias Model =
    Array Compute.Model


type Msg
    = Index Int Compute.Msg


init : (Msg -> msg) -> Shared.Model -> List ComputeBackend.ComputeInput -> ( Model, Cmd msg )
init panelMsg shared panels =
    let
        ( models, cmds ) =
            List.unzip (initPanels (\index computeMsg -> panelMsg (Index index computeMsg)) shared panels)
    in
    ( Array.fromList models, Cmd.batch cmds )


initPanels : (Int -> Compute.Msg -> msg) -> Shared.Model -> List ComputeBackend.ComputeInput -> List ( Compute.Model, Cmd msg )
initPanels panelMsg shared panels =
    List.indexedMap
        (\index panelInput ->
            let
                flags =
                    shared.flags

                mergedFlags =
                    { flags | computeInput = Just panelInput }

                ( subModel, subCmd ) =
                    Compute.init { shared | flags = mergedFlags }
            in
            ( subModel, Cmd.map (panelMsg index) subCmd )
        )
        panels


update : (Msg -> msg) -> Msg -> Model -> ( Model, Cmd msg )
update panelMsg msg model =
    case msg of
        Index index computeMsg ->
            case Array.get index model of
                Just panel ->
                    let
                        ( subModel, subCmd ) =
                            Compute.update computeMsg panel

                        ourMsg =
                            Cmd.map (Index index) subCmd
                    in
                    ( Array.set index subModel model, Cmd.map panelMsg ourMsg )

                Nothing ->
                    ( model, Cmd.none )


render : (Msg -> msg) -> Array Compute.Model -> Int -> Compute.Settings -> E.Element msg
render panelMsg panels index settings =
    case Array.get index panels of
        Just panel ->
            E.map panelMsg (E.map (Index index) (Compute.view settings panel))

        Nothing ->
            E.none


subscriptions : (Msg -> msg) -> Model -> Sub msg
subscriptions panelMsg model =
    let
        mapper : Int -> Compute.Model -> Sub msg
        mapper index panel =
            let
                msg : Sub Msg
                msg =
                    Sub.map (Index index) (Compute.subscriptions panel)
            in
            Sub.map panelMsg msg
    in
    Sub.batch
        (Array.toList
            (Array.indexedMap mapper model)
        )
