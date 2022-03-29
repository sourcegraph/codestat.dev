port module ComputeBackend exposing
    ( ComputeInput
    , RawEvent
    , computeInputDecoder
    , emitInput
    , openStream
    , receiveEvent
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline



-- PORTS


type alias RawEvent =
    { data : String
    , eventType : Maybe String
    , id : Maybe String
    }


port receiveEvent : (RawEvent -> msg) -> Sub msg


port openStream : ( String, Maybe String ) -> Cmd msg


port emitInput : ComputeInput -> Cmd msg



-- FLAGS


type alias ComputeInput =
    { computeQueries : List String
    , experimentalOptions : Maybe ExperimentalOptions
    }


type alias ExperimentalOptions =
    { dataPoints : Maybe Int
    , sortByCount : Maybe Bool
    , reverse : Maybe Bool
    , excludeStopWords : Maybe Bool
    }



-- DECODERS


computeInputDecoder : Decoder ComputeInput
computeInputDecoder =
    Decode.succeed ComputeInput
        |> Json.Decode.Pipeline.required "computeQueries" (Decode.list Decode.string)
        |> Json.Decode.Pipeline.optional "experimentalOptions" (Decode.maybe experimentalOptionsDecoder) Nothing


experimentalOptionsDecoder : Decoder ExperimentalOptions
experimentalOptionsDecoder =
    Decode.succeed ExperimentalOptions
        |> Json.Decode.Pipeline.optional "dataPoints" (Decode.maybe Decode.int) Nothing
        |> Json.Decode.Pipeline.optional "sortByCount" (Decode.maybe Decode.bool) Nothing
        |> Json.Decode.Pipeline.optional "reverse" (Decode.maybe Decode.bool) Nothing
        |> Json.Decode.Pipeline.optional "excludeStopWords" (Decode.maybe Decode.bool) Nothing
