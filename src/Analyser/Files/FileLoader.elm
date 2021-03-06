port module Analyser.Files.FileLoader exposing (Msg, init, subscriptions, update)

import Analyser.Files.FileContent as FileContent exposing (FileContent)
import Analyser.Files.Types exposing (LoadedSourceFile)
import Elm.Json.Encode
import Json.Encode
import Result
import Util.Logger as Logger


port loadFile : String -> Cmd msg


port fileContent : (FileContent -> msg) -> Sub msg


port storeAstForSha : ( String, String ) -> Cmd msg


type Msg
    = OnFileContent FileContent


init : String -> Cmd Msg
init s =
    Cmd.batch
        [ loadFile s
        , Logger.info ("Load file " ++ s ++ "...")
        ]


subscriptions : Sub Msg
subscriptions =
    fileContent OnFileContent


update : Msg -> ( LoadedSourceFile, Cmd a )
update msg =
    case msg of
        OnFileContent fileContent ->
            let
                ( fileLoad, store ) =
                    FileContent.asRawFile fileContent

                cmd =
                    if store then
                        ( fileContent.sha1, Result.toMaybe fileLoad )
                            |> uncurry (Maybe.map2 (\a b -> storeAstForSha ( a, Json.Encode.encode 0 (Elm.Json.Encode.encode b) )))
                            |> Maybe.withDefault Cmd.none
                    else
                        Cmd.none
            in
            ( ( fileContent, fileLoad )
            , cmd
            )
