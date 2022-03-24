module Shared exposing
    ( ComputeFlags
    , Flags
    , Model
    , Msg
    , init
    , placeholderQuery
    , subscriptions
    , update
    )

import ComputeInput
import Json.Decode
import Json.Decode.Pipeline
import Request exposing (Request)


type alias ComputeFlags =
    { sourcegraphURL : String
    , computeInput : Maybe ComputeInput.ComputeInput
    }


type alias Flags =
    Json.Decode.Value


type alias Model =
    { flags : ComputeFlags }


type Msg
    = NoOp



-- DECODERS


flagsDecoder : Json.Decode.Decoder ComputeFlags
flagsDecoder =
    Json.Decode.succeed ComputeFlags
        |> Json.Decode.Pipeline.required "sourcegraphURL" Json.Decode.string
        |> Json.Decode.Pipeline.required "computeInput" (Json.Decode.nullable ComputeInput.computeInputDecoder)



-- INIT


placeholderQuery : String
placeholderQuery =
    "repo:github\\.com/sourcegraph/sourcegraph$ content:output((.|\\n)* -> $author) type:commit"


init : Request -> Flags -> ( Model, Cmd Msg )
init _ json =
    let
        flags =
            case Json.Decode.decodeValue flagsDecoder json of
                Ok result ->
                    result

                Err _ ->
                    -- no initial flags
                    { sourcegraphURL = ""
                    , computeInput =
                        Just
                            { computeQueries = [ placeholderQuery ]
                            , experimentalOptions = Nothing
                            }
                    }
    in
    ( { flags = flags }, Cmd.none )



-- UPDATE


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
