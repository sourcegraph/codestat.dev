module Compute exposing (DataFilterMsg(..), Model, Msg(..), Settings, Tab(..), defaults, init, subscriptions, update, view)

import Chart as C
import Chart.Attributes as CA
import ComputeBackend
import Dict exposing (Dict)
import Element as E
import Element.Background as Background
import Element.Border as Border
import Element.Events
import Element.Font as F
import Element.Input as I
import Html exposing (input, text)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder, fail, field, maybe, value)
import Json.Decode.Pipeline
import Process
import Set exposing (Set)
import Shared
import Task
import Url.Builder
import Url.Parser exposing (..)



-- CONSTANTS


width : Int
width =
    800


debounceQueryInputMillis : Float
debounceQueryInputMillis =
    400



-- MODEL


type alias DataValue =
    { name : String
    , value : Float
    }


type alias DataFilter =
    { dataPoints : Int
    , sortByCount : Bool
    , reverse : Bool
    , excludeStopWords : Bool
    }


type alias Model =
    { sourcegraphURL : String
    , query : String
    , debounce : Int
    , dataFilter : DataFilter
    , selectedTab : Tab
    , resultsMap : Dict String DataValue
    , resultCount : Int
    , editible : Bool

    -- Debug client only
    , serverless : Bool
    }


init : Shared.Model -> ( Model, Cmd Msg )
init shared =
    ( { sourcegraphURL = shared.flags.sourcegraphURL
      , query =
            case Maybe.map .computeQueries shared.flags.computeInput of
                Just (query :: _) ->
                    query

                _ ->
                    Shared.placeholderQuery
      , dataFilter =
            case Maybe.andThen .experimentalOptions shared.flags.computeInput of
                Just { dataPoints, sortByCount, reverse, excludeStopWords } ->
                    { dataPoints = Maybe.withDefault 30 dataPoints
                    , sortByCount = Maybe.withDefault True sortByCount
                    , reverse = Maybe.withDefault False reverse
                    , excludeStopWords = Maybe.withDefault False excludeStopWords
                    }

                Nothing ->
                    { dataPoints = 30
                    , sortByCount = True
                    , reverse = False
                    , excludeStopWords = False
                    }
      , selectedTab =
            case shared.flags.computeInput of
                Just { selectedTab } ->
                    case selectedTab of
                        Just some ->
                            case some of
                                "chart" ->
                                    Chart

                                "table" ->
                                    Table

                                "data" ->
                                    Data

                                "number" ->
                                    Number

                                "link-cloud" ->
                                    LinkCloud

                                _ ->
                                    Chart

                        Nothing ->
                            Chart

                Nothing ->
                    Chart
      , debounce = 0
      , resultsMap = Dict.empty
      , resultCount = 0
      , editible =
            case shared.flags.computeInput of
                Just { editible } ->
                    case editible of
                        Just some ->
                            some

                        Nothing ->
                            True

                Nothing ->
                    True
      , serverless = False
      }
    , Task.perform identity (Task.succeed RunCompute)
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ ComputeBackend.receiveEvent (eventDecoder (buildAddress model)) ]


eventDecoder : String -> ComputeBackend.RawEvent -> Msg
eventDecoder address event =
    if event.address /= address then
        NoOp

    else
        case event.eventType of
            Just "results" ->
                OnResults (resultEventDecoder event.data)

            Just "done" ->
                ResultStreamDone

            _ ->
                NoOp


resultEventDecoder : String -> List Result
resultEventDecoder input =
    case Decode.decodeString (Decode.list resultDecoder) input of
        Ok results ->
            results

        Err _ ->
            []



-- UPDATE


type Msg
    = -- User inputs
      OnQueryChanged String
    | OnDebounce
    | OnDataFilter DataFilterMsg
    | OnTabSelected Tab
    | OnToggleEditible
      -- Data processing
    | RunCompute
    | OnResults (List Result)
    | ResultStreamDone
    | NoOp


type DataFilterMsg
    = OnDataPoints String
    | OnSortByCheckbox Bool
    | OnReverseCheckbox Bool
    | OnExcludeStopWordsCheckbox Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnQueryChanged newQuery ->
            ( { model | query = newQuery, debounce = model.debounce + 1 }
            , Task.perform (\_ -> OnDebounce) (Process.sleep debounceQueryInputMillis)
            )

        OnDebounce ->
            if model.debounce - 1 == 0 then
                update RunCompute { model | debounce = model.debounce - 1 }

            else
                ( { model | debounce = model.debounce - 1 }, Cmd.none )

        OnDataFilter dataFilterMsg ->
            let
                newDataFilter =
                    updateDataFilter dataFilterMsg model.dataFilter
            in
            ( { model | dataFilter = newDataFilter }
            , ComputeBackend.emitInput
                { computeQueries = [ model.query ]
                , experimentalOptions =
                    Just
                        { dataPoints = Just newDataFilter.dataPoints
                        , sortByCount = Just newDataFilter.sortByCount
                        , reverse = Just newDataFilter.reverse
                        , excludeStopWords = Just newDataFilter.excludeStopWords
                        }
                , editible = Just model.editible
                , selectedTab =
                    Just (encodeTab model.selectedTab)
                }
            )

        OnTabSelected selectedTab ->
            ( { model | selectedTab = selectedTab }, Cmd.none )

        OnToggleEditible ->
            ( { model | editible = not model.editible }, Cmd.none )

        RunCompute ->
            let
                ( query, _ ) =
                    parseLinkQuery model.query
            in
            if model.serverless then
                ( { model | resultsMap = exampleResultsMap }, Cmd.none )

            else
                ( { model | resultsMap = Dict.empty, resultCount = 0 }
                , Cmd.batch
                    [ ComputeBackend.emitInput
                        { computeQueries = [ query ]
                        , experimentalOptions =
                            Just
                                { dataPoints = Just model.dataFilter.dataPoints
                                , sortByCount = Just model.dataFilter.sortByCount
                                , reverse = Just model.dataFilter.reverse
                                , excludeStopWords = Just model.dataFilter.excludeStopWords
                                }
                        , editible = Just model.editible
                        , selectedTab = Just (encodeTab model.selectedTab)
                        }
                    , ComputeBackend.openStream
                        ( buildAddress model
                        , Nothing
                        )
                    ]
                )

        OnResults r ->
            ( { model
                | resultsMap = List.foldl updateResultsMap model.resultsMap (parseResults r)
                , resultCount = model.resultCount + List.length r
              }
            , Cmd.none
            )

        ResultStreamDone ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


encodeTab : Tab -> ComputeBackend.Tab
encodeTab v =
    case v of
        Chart ->
            "chart"

        Table ->
            "table"

        Data ->
            "Data"

        Number ->
            "number"

        LinkCloud ->
            "link-cloud"


buildAddress : Model -> String
buildAddress model =
    let
        ( query, _ ) =
            parseLinkQuery model.query
    in
    Url.Builder.crossOrigin
        model.sourcegraphURL
        [ ".api", "compute", "stream" ]
        [ Url.Builder.string "q" query ]


parseString : String -> ( String, String )
parseString s =
    case String.split " (group by) " s of
        name :: groupName :: _ ->
            ( name, groupName )

        _ ->
            ( s, s )


groupResults : Dict String DataValue -> Dict String DataValue
groupResults inputDict =
    let
        updateValue name v =
            case v of
                Nothing ->
                    Just { name = name, value = 1 }

                Just e ->
                    Just { e | value = e.value + 1 }

        updateEntry s dict =
            let
                ( name, _ ) =
                    parseString s
            in
            Dict.update name (updateValue name) dict
    in
    List.foldl updateEntry Dict.empty (Dict.keys inputDict)


updateDataFilter : DataFilterMsg -> DataFilter -> DataFilter
updateDataFilter msg dataFilter =
    case msg of
        OnSortByCheckbox sortByCount ->
            { dataFilter | sortByCount = sortByCount }

        OnReverseCheckbox reverse ->
            { dataFilter | reverse = reverse }

        OnExcludeStopWordsCheckbox excludeStopWords ->
            { dataFilter | excludeStopWords = excludeStopWords }

        OnDataPoints i ->
            let
                newDataPoints =
                    case String.toInt i of
                        Just n ->
                            n

                        Nothing ->
                            0
            in
            { dataFilter | dataPoints = newDataPoints }



-- VIEW


table : String -> List DataValue -> E.Element Msg
table query data =
    let
        ( _, queryUrl ) =
            parseLinkQuery query

        headerAttrs =
            [ F.bold
            , F.size 12
            , F.color darkModeFontColor
            , E.padding 5
            , Border.widthEach { bottom = 1, top = 0, left = 0, right = 0 }
            ]
    in
    E.el [ E.centerX ]
        (E.table [ E.width E.fill ]
            { data = data
            , columns =
                [ { header = E.el headerAttrs (E.text " ")
                  , width = E.fillPortion 2
                  , view =
                        \v ->
                            E.el [ E.padding 5 ]
                                (E.el [ E.width E.fill, E.padding 10, Border.rounded 5, Border.width 1 ]
                                    (if queryUrl == "" then
                                        E.text v.name

                                     else
                                        let
                                            url =
                                                String.replace "$1" v.name queryUrl
                                        in
                                        E.link [] { url = url, label = E.text v.name }
                                    )
                                )
                  }
                , { header = E.el (headerAttrs ++ [ F.alignRight ]) (E.text "Count")
                  , width = E.fillPortion 1
                  , view =
                        \v ->
                            E.el
                                [ E.centerY
                                , F.size 12
                                , F.color darkModeFontColor
                                , F.alignRight
                                , E.padding 5
                                ]
                                (E.text (String.fromFloat v.value))
                  }
                ]
            }
        )


histogram : List DataValue -> E.Element Msg
histogram data =
    E.el
        [ E.width E.fill
        , E.height (E.fill |> E.minimum 400)
        , E.centerX
        , E.alignTop
        , E.padding 30
        ]
        (E.html
            (C.chart
                [ CA.height 300, CA.width (toFloat width) ]
                [ C.bars
                    [ CA.spacing 0.0 ]
                    [ C.bar .value [ CA.color "#A112FF", CA.roundTop 0.2 ] ]
                    data
                , C.binLabels .name [ CA.moveDown 25, CA.color "#21cd06", CA.rotate 45, CA.alignRight ]
                , C.barLabels [ CA.moveDown 24, CA.color "white", CA.fontSize 16 ]
                ]
            )
        )


dataView : List DataValue -> E.Element Msg
dataView data =
    E.row []
        [ E.el [ E.padding 10, E.alignLeft, E.width E.fill ]
            (E.column [] (List.map (\d -> E.text d.name) data))
        ]


numberView : List DataValue -> E.Element Msg
numberView data =
    let
        value =
            case List.head data of
                Just v ->
                    v.value

                Nothing ->
                    0
    in
    E.el [ F.size 60 ] (E.text (String.fromFloat value))


linkCloudView : String -> List DataValue -> E.Element Msg
linkCloudView query data =
    let
        ( _, queryUrl ) =
            parseLinkQuery query
    in
    E.wrappedRow [ F.size 18, E.spacing 4 ]
        (List.map
            (\value ->
                let
                    url =
                        String.replace "$1" value.name queryUrl
                in
                E.link [] { url = url, label = E.text (String.concat [ value.name, "  " ]) }
            )
            data
        )


parseLinkQuery : String -> ( String, String )
parseLinkQuery s =
    case String.split " @@@ " s of
        realQuery :: url :: _ ->
            ( realQuery, url )

        _ ->
            ( s, "" )


viewDataFilter : DataFilter -> E.Element DataFilterMsg
viewDataFilter dataFilter =
    E.row [ E.paddingXY 0 10 ]
        [ I.text [ E.width (E.fill |> E.maximum 65), F.center, Background.color darkModeTextInputColor ]
            { onChange = OnDataPoints
            , placeholder = Nothing
            , text =
                case dataFilter.dataPoints of
                    0 ->
                        ""

                    n ->
                        String.fromInt n
            , label = I.labelHidden ""
            }
        , I.checkbox [ E.paddingXY 10 0 ]
            { onChange = OnSortByCheckbox
            , icon = I.defaultCheckbox
            , checked = dataFilter.sortByCount
            , label = I.labelRight [] (E.text "sort by count")
            }
        , I.checkbox [ E.paddingXY 10 0 ]
            { onChange = OnReverseCheckbox
            , icon = I.defaultCheckbox
            , checked = dataFilter.reverse
            , label = I.labelRight [] (E.text "reverse")
            }
        , I.checkbox [ E.paddingXY 10 0 ]
            { onChange = OnExcludeStopWordsCheckbox
            , icon = I.defaultCheckbox
            , checked = dataFilter.excludeStopWords
            , label = I.labelRight [] (E.text "exclude stop words")
            }
        ]


inputRow : Model -> E.Element Msg
inputRow model =
    E.el [ E.centerX, E.width E.fill ]
        (E.column [ E.width E.fill ]
            [ I.text [ Background.color darkModeTextInputColor ]
                { onChange = OnQueryChanged
                , placeholder = Nothing
                , text = model.query
                , label = I.labelHidden ""
                }
            , E.map OnDataFilter (viewDataFilter model.dataFilter)
            ]
        )


type Tab
    = Chart
    | Table
    | Data
    | Number
    | LinkCloud


color =
    { skyBlue = E.rgb255 0x00 0xCB 0xEC
    , vividViolet = E.rgb255 0xA1 0x12 0xFF
    , vermillion = E.rgb255 0xFF 0x55 0x43
    }


tab : Tab -> Tab -> E.Element Msg
tab thisTab selectedTab =
    let
        isSelected =
            thisTab == selectedTab

        padOffset =
            if isSelected then
                0

            else
                2

        borderWidths =
            if isSelected then
                { left = 1, top = 1, right = 1, bottom = 0 }

            else
                { bottom = 1, top = 0, left = 0, right = 0 }

        corners =
            if isSelected then
                { topLeft = 6, topRight = 6, bottomLeft = 0, bottomRight = 0 }

            else
                { topLeft = 0, topRight = 0, bottomLeft = 0, bottomRight = 0 }

        tabColor =
            case selectedTab of
                Chart ->
                    color.vividViolet

                Table ->
                    color.vermillion

                Data ->
                    color.skyBlue

                Number ->
                    color.skyBlue

                LinkCloud ->
                    color.skyBlue

        text =
            case thisTab of
                Chart ->
                    "Chart"

                Table ->
                    "Table"

                Data ->
                    "Data"

                Number ->
                    "Number"

                LinkCloud ->
                    "Link cloud"
    in
    E.el
        [ Border.widthEach borderWidths
        , Border.roundEach corners
        , Border.color tabColor
        , Element.Events.onClick (OnTabSelected thisTab)
        , E.htmlAttribute (Html.Attributes.style "cursor" "pointer")
        , E.width E.fill
        ]
        (E.el
            [ E.centerX
            , E.width E.fill
            , E.centerY
            , E.paddingEach { left = 30, right = 30, top = 10 + padOffset, bottom = 10 - padOffset }
            ]
            (E.text text)
        )


outputRow : Tab -> E.Element Msg
outputRow selectedTab =
    E.row [ E.centerX, E.width E.fill ]
        [ tab Chart selectedTab
        , tab Table selectedTab
        , tab Data selectedTab
        , tab Number selectedTab
        , tab LinkCloud selectedTab
        ]


type alias Settings =
    { minHeight : Maybe Int }


defaults : Settings
defaults =
    { minHeight = Nothing }


view : Settings -> Model -> E.Element Msg
view settings model =
    let
        data =
            Dict.toList
                (if String.contains " (group by) " model.query then
                    groupResults model.resultsMap

                 else
                    model.resultsMap
                )
                |> List.map Tuple.second
                |> filterData model.dataFilter
    in
    E.row
        [ E.centerX
        , E.width (E.fill |> E.maximum 850)
        , case settings.minHeight of
            Just min ->
                E.height (E.fill |> E.minimum min)

            Nothing ->
                E.height E.fill
        ]
        [ E.column [ E.centerX, E.width E.fill, E.height E.fill, E.paddingXY 20 20 ]
            [ E.row [ E.width E.fill ]
                [ E.el [ E.alignLeft ] (E.text (String.concat [ "analyzed ", String.fromInt model.resultCount, " results" ]))
                , E.el [ E.alignRight, F.size 12, Element.Events.onClick OnToggleEditible, E.paddingXY 8 8, E.pointer ]
                    (E.text
                        (if model.editible then
                            "(hide)"

                         else
                            " (source)"
                        )
                    )
                ]
            , if model.editible then
                inputRow model

              else
                E.none
            , if model.editible then
                outputRow model.selectedTab

              else
                E.none
            , case model.selectedTab of
                Chart ->
                    histogram data

                Table ->
                    table model.query data

                Data ->
                    dataView data

                Number ->
                    numberView data

                LinkCloud ->
                    linkCloudView model.query data
            ]
        ]



-- DATA LOGIC


parseResults : List Result -> List String
parseResults l =
    List.filterMap
        (\r ->
            case r of
                Output v ->
                    String.split "\n" v.value
                        |> List.filter (not << String.isEmpty)
                        |> Just

                ReplaceInPlace v ->
                    Just [ v.value ]
        )
        l
        |> List.concat


updateResultsMap : String -> Dict String DataValue -> Dict String DataValue
updateResultsMap textResult =
    Dict.update
        textResult
        (\v ->
            case v of
                Nothing ->
                    Just { name = textResult, value = 1 }

                Just existing ->
                    Just { existing | value = existing.value + 1 }
        )


filterData : DataFilter -> List DataValue -> List DataValue
filterData { dataPoints, sortByCount, reverse, excludeStopWords } data =
    let
        pipeSort =
            if sortByCount then
                List.sortWith
                    (\l r ->
                        if l.value < r.value then
                            GT

                        else if l.value > r.value then
                            LT

                        else
                            EQ
                    )

            else
                identity
    in
    let
        pipeReverse =
            if reverse then
                List.reverse

            else
                identity
    in
    let
        pipeStopWords =
            if excludeStopWords then
                List.filter (\{ name } -> not (Set.member (String.toLower name) stopWords))

            else
                identity
    in
    data
        |> pipeStopWords
        |> pipeSort
        |> pipeReverse
        |> List.take dataPoints
        |> pipeReverse



-- STREAMING RESULT TYPES


type Result
    = Output TextResult
    | ReplaceInPlace TextResult


type alias TextResult =
    { value : String
    , repository : Maybe String
    , commit : Maybe String
    , path : Maybe String
    }


resultDecoder : Decoder Result
resultDecoder =
    field "kind" Decode.string
        |> Decode.andThen
            (\t ->
                case t of
                    "replace-in-place" ->
                        textResultDecoder
                            |> Decode.map ReplaceInPlace

                    "output" ->
                        textResultDecoder
                            |> Decode.map Output

                    _ ->
                        fail ("Unrecognized type " ++ t)
            )


textResultDecoder : Decoder TextResult
textResultDecoder =
    Decode.succeed TextResult
        |> Json.Decode.Pipeline.required "value" Decode.string
        |> Json.Decode.Pipeline.optional "repository" (maybe Decode.string) Nothing
        |> Json.Decode.Pipeline.optional "commit" (maybe Decode.string) Nothing
        |> Json.Decode.Pipeline.optional "path" (maybe Decode.string) Nothing



-- STYLING


darkModeFontColor : E.Color
darkModeFontColor =
    E.rgb255 0xFF 0xFF 0xFF


darkModeTextInputColor : E.Color
darkModeTextInputColor =
    E.rgb255 0x1D 0x22 0x2F



-- DEBUG DATA


exampleResultsMap : Dict String DataValue
exampleResultsMap =
    [ { name = "Errorf"
      , value = 10.0
      }
    , { name = "Func\nmulti\nline"
      , value = 5.0
      }
    , { name = "Qux"
      , value = 2.0
      }
    ]
        |> List.map (\d -> ( d.name, d ))
        |> Dict.fromList



-- STOP WORD DATA


stopWords : Set String
stopWords =
    Set.fromList [ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "'ll", "'tis", "'twas", "'ve", "10", "39", "a", "a's", "able", "ableabout", "about", "above", "abroad", "abst", "accordance", "according", "accordingly", "across", "act", "actually", "ad", "added", "adj", "adopted", "ae", "af", "affected", "affecting", "affects", "after", "afterwards", "ag", "again", "against", "ago", "ah", "ahead", "ai", "ain't", "aint", "al", "all", "allow", "allows", "almost", "alone", "along", "alongside", "already", "also", "although", "always", "am", "amid", "amidst", "among", "amongst", "amoungst", "amount", "an", "and", "announce", "another", "any", "anybody", "anyhow", "anymore", "anyone", "anything", "anyway", "anyways", "anywhere", "ao", "apart", "apparently", "appear", "appreciate", "appropriate", "approximately", "aq", "ar", "are", "area", "areas", "aren", "aren't", "arent", "arise", "around", "arpa", "as", "aside", "ask", "asked", "asking", "asks", "associated", "at", "au", "auth", "available", "aw", "away", "awfully", "az", "b", "ba", "back", "backed", "backing", "backs", "backward", "backwards", "bb", "bd", "be", "became", "because", "become", "becomes", "becoming", "been", "before", "beforehand", "began", "begin", "beginning", "beginnings", "begins", "behind", "being", "beings", "believe", "below", "beside", "besides", "best", "better", "between", "beyond", "bf", "bg", "bh", "bi", "big", "bill", "billion", "biol", "bj", "bm", "bn", "bo", "both", "bottom", "br", "brief", "briefly", "bs", "bt", "but", "buy", "bv", "bw", "by", "bz", "c", "c'mon", "c's", "ca", "call", "came", "can", "can't", "cannot", "cant", "caption", "case", "cases", "cause", "causes", "cc", "cd", "certain", "certainly", "cf", "cg", "ch", "changes", "ci", "ck", "cl", "clear", "clearly", "click", "cm", "cmon", "cn", "co", "co.", "com", "come", "comes", "computer", "con", "concerning", "consequently", "consider", "considering", "contain", "containing", "contains", "copy", "corresponding", "could", "could've", "couldn", "couldn't", "couldnt", "course", "cr", "cry", "cs", "cu", "currently", "cv", "cx", "cy", "cz", "d", "dare", "daren't", "darent", "date", "de", "dear", "definitely", "describe", "described", "despite", "detail", "did", "didn", "didn't", "didnt", "differ", "different", "differently", "directly", "dj", "dk", "dm", "do", "does", "doesn", "doesn't", "doesnt", "doing", "don", "don't", "done", "dont", "doubtful", "down", "downed", "downing", "downs", "downwards", "due", "during", "dz", "e", "each", "early", "ec", "ed", "edu", "ee", "effect", "eg", "eh", "eight", "eighty", "either", "eleven", "else", "elsewhere", "empty", "end", "ended", "ending", "ends", "enough", "entirely", "er", "es", "especially", "et", "et-al", "etc", "even", "evenly", "ever", "evermore", "every", "everybody", "everyone", "everything", "everywhere", "ex", "exactly", "example", "except", "f", "face", "faces", "fact", "facts", "fairly", "far", "farther", "felt", "few", "fewer", "ff", "fi", "fifteen", "fifth", "fifty", "fify", "fill", "find", "finds", "fire", "first", "five", "fix", "fj", "fk", "fm", "fo", "followed", "following", "follows", "for", "forever", "former", "formerly", "forth", "forty", "forward", "found", "four", "fr", "free", "from", "front", "full", "fully", "further", "furthered", "furthering", "furthermore", "furthers", "fx", "g", "ga", "gave", "gb", "gd", "ge", "general", "generally", "get", "gets", "getting", "gf", "gg", "gh", "gi", "give", "given", "gives", "giving", "gl", "gm", "gmt", "gn", "go", "goes", "going", "gone", "good", "goods", "got", "gotten", "gov", "gp", "gq", "gr", "great", "greater", "greatest", "greetings", "group", "grouped", "grouping", "groups", "gs", "gt", "gu", "gw", "gy", "h", "had", "hadn't", "hadnt", "half", "happens", "hardly", "has", "hasn", "hasn't", "hasnt", "have", "haven", "haven't", "havent", "having", "he", "he'd", "he'll", "he's", "hed", "hell", "hello", "help", "hence", "her", "here", "here's", "hereafter", "hereby", "herein", "heres", "hereupon", "hers", "herself", "herse”", "hes", "hi", "hid", "high", "higher", "highest", "him", "himself", "himse”", "his", "hither", "hk", "hm", "hn", "home", "homepage", "hopefully", "how", "how'd", "how'll", "how's", "howbeit", "however", "hr", "ht", "htm", "html", "http", "hu", "hundred", "i", "i'd", "i'll", "i'm", "i've", "i.e.", "id", "ie", "if", "ignored", "ii", "il", "ill", "im", "immediate", "immediately", "importance", "important", "in", "inasmuch", "inc", "inc.", "indeed", "index", "indicate", "indicated", "indicates", "information", "inner", "inside", "insofar", "instead", "int", "interest", "interested", "interesting", "interests", "into", "invention", "inward", "io", "iq", "ir", "is", "isn", "isn't", "isnt", "it", "it'd", "it'll", "it's", "itd", "itll", "its", "itself", "itse”", "ive", "j", "je", "jm", "jo", "join", "jp", "just", "k", "ke", "keep", "keeps", "kept", "keys", "kg", "kh", "ki", "kind", "km", "kn", "knew", "know", "known", "knows", "kp", "kr", "kw", "ky", "kz", "l", "la", "large", "largely", "last", "lately", "later", "latest", "latter", "latterly", "lb", "lc", "least", "length", "less", "lest", "let", "let's", "lets", "li", "like", "liked", "likely", "likewise", "line", "little", "lk", "ll", "long", "longer", "longest", "look", "looking", "looks", "low", "lower", "lr", "ls", "lt", "ltd", "lu", "lv", "ly", "m", "ma", "made", "mainly", "make", "makes", "making", "man", "many", "may", "maybe", "mayn't", "maynt", "mc", "md", "me", "mean", "means", "meantime", "meanwhile", "member", "members", "men", "merely", "mg", "mh", "microsoft", "might", "might've", "mightn't", "mightnt", "mil", "mill", "million", "mine", "minus", "miss", "mk", "ml", "mm", "mn", "mo", "more", "moreover", "most", "mostly", "move", "mp", "mq", "mr", "mrs", "ms", "msie", "mt", "mu", "much", "mug", "must", "must've", "mustn't", "mustnt", "mv", "mw", "mx", "my", "myself", "myse”", "mz", "n", "na", "name", "namely", "nay", "nc", "nd", "ne", "near", "nearly", "necessarily", "necessary", "need", "needed", "needing", "needn't", "neednt", "needs", "neither", "net", "netscape", "never", "neverf", "neverless", "nevertheless", "new", "newer", "newest", "next", "nf", "ng", "ni", "nine", "ninety", "nl", "no", "no-one", "nobody", "non", "none", "nonetheless", "noone", "nor", "normally", "nos", "not", "noted", "nothing", "notwithstanding", "novel", "now", "nowhere", "np", "nr", "nu", "null", "number", "numbers", "nz", "o", "obtain", "obtained", "obviously", "of", "off", "often", "oh", "ok", "okay", "old", "older", "oldest", "om", "omitted", "on", "once", "one", "one's", "ones", "only", "onto", "open", "opened", "opening", "opens", "opposite", "or", "ord", "order", "ordered", "ordering", "orders", "org", "other", "others", "otherwise", "ought", "oughtn't", "oughtnt", "our", "ours", "ourselves", "out", "outside", "over", "overall", "owing", "own", "p", "pa", "page", "pages", "part", "parted", "particular", "particularly", "parting", "parts", "past", "pe", "per", "perhaps", "pf", "pg", "ph", "pk", "pl", "place", "placed", "places", "please", "plus", "pm", "pmid", "pn", "point", "pointed", "pointing", "points", "poorly", "possible", "possibly", "potentially", "pp", "pr", "predominantly", "present", "presented", "presenting", "presents", "presumably", "previously", "primarily", "probably", "problem", "problems", "promptly", "proud", "provided", "provides", "pt", "put", "puts", "pw", "py", "q", "qa", "que", "quickly", "quite", "qv", "r", "ran", "rather", "rd", "re", "readily", "really", "reasonably", "recent", "recently", "ref", "refs", "regarding", "regardless", "regards", "related", "relatively", "research", "reserved", "respectively", "resulted", "resulting", "results", "right", "ring", "ro", "room", "rooms", "round", "ru", "run", "rw", "s", "sa", "said", "same", "saw", "say", "saying", "says", "sb", "sc", "sd", "se", "sec", "second", "secondly", "seconds", "section", "see", "seeing", "seem", "seemed", "seeming", "seems", "seen", "sees", "self", "selves", "sensible", "sent", "serious", "seriously", "seven", "seventy", "several", "sg", "sh", "shall", "shan't", "shant", "she", "she'd", "she'll", "she's", "shed", "shell", "shes", "should", "should've", "shouldn", "shouldn't", "shouldnt", "show", "showed", "showing", "shown", "showns", "shows", "si", "side", "sides", "significant", "significantly", "similar", "similarly", "since", "sincere", "site", "six", "sixty", "sj", "sk", "sl", "slightly", "sm", "small", "smaller", "smallest", "sn", "so", "some", "somebody", "someday", "somehow", "someone", "somethan", "something", "sometime", "sometimes", "somewhat", "somewhere", "soon", "sorry", "specifically", "specified", "specify", "specifying", "sr", "st", "state", "states", "still", "stop", "strongly", "su", "sub", "substantially", "successfully", "such", "sufficiently", "suggest", "sup", "sure", "sv", "sy", "system", "sz", "t", "t's", "take", "taken", "taking", "tc", "td", "tell", "ten", "tends", "test", "text", "tf", "tg", "th", "than", "thank", "thanks", "thanx", "that", "that'll", "that's", "that've", "thatll", "thats", "thatve", "the", "their", "theirs", "them", "themselves", "then", "thence", "there", "there'd", "there'll", "there're", "there's", "there've", "thereafter", "thereby", "thered", "therefore", "therein", "therell", "thereof", "therere", "theres", "thereto", "thereupon", "thereve", "these", "they", "they'd", "they'll", "they're", "they've", "theyd", "theyll", "theyre", "theyve", "thick", "thin", "thing", "things", "think", "thinks", "third", "thirty", "this", "thorough", "thoroughly", "those", "thou", "though", "thoughh", "thought", "thoughts", "thousand", "three", "throug", "through", "throughout", "thru", "thus", "til", "till", "tip", "tis", "tj", "tk", "tm", "tn", "to", "today", "together", "too", "took", "top", "toward", "towards", "tp", "tr", "tried", "tries", "trillion", "truly", "try", "trying", "ts", "tt", "turn", "turned", "turning", "turns", "tv", "tw", "twas", "twelve", "twenty", "twice", "two", "tz", "u", "ua", "ug", "uk", "um", "un", "under", "underneath", "undoing", "unfortunately", "unless", "unlike", "unlikely", "until", "unto", "up", "upon", "ups", "upwards", "us", "use", "used", "useful", "usefully", "usefulness", "uses", "using", "usually", "uucp", "uy", "uz", "v", "va", "value", "various", "vc", "ve", "versus", "very", "vg", "vi", "via", "viz", "vn", "vol", "vols", "vs", "vu", "w", "want", "wanted", "wanting", "wants", "was", "wasn", "wasn't", "wasnt", "way", "ways", "we", "we'd", "we'll", "we're", "we've", "web", "webpage", "website", "wed", "welcome", "well", "wells", "went", "were", "weren", "weren't", "werent", "weve", "wf", "what", "what'd", "what'll", "what's", "what've", "whatever", "whatll", "whats", "whatve", "when", "when'd", "when'll", "when's", "whence", "whenever", "where", "where'd", "where'll", "where's", "whereafter", "whereas", "whereby", "wherein", "wheres", "whereupon", "wherever", "whether", "which", "whichever", "while", "whilst", "whim", "whither", "who", "who'd", "who'll", "who's", "whod", "whoever", "whole", "wholl", "whom", "whomever", "whos", "whose", "why", "why'd", "why'll", "why's", "widely", "width", "will", "willing", "wish", "with", "within", "without", "won", "won't", "wonder", "wont", "words", "work", "worked", "working", "works", "world", "would", "would've", "wouldn", "wouldn't", "wouldnt", "ws", "www", "x", "y", "ye", "year", "years", "yes", "yet", "you", "you'd", "you'll", "you're", "you've", "youd", "youll", "young", "younger", "youngest", "your", "youre", "yours", "yourself", "yourselves", "youve", "yt", "yu", "z", "za", "zero", "zm", "zr", "Signed" ]
