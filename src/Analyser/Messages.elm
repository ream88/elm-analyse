module Analyser.Messages exposing (Message(..), asString)

import AST.Types as AST


type Message
    = UnreadableSourceFile FileName
    | UnreadableDependencyFile FileName String
    | UnusedVariable FileName String AST.Range
    | UnusedTopLevel FileName String AST.Range
    | ExposeAll FileName AST.Range
    | ImportAll FileName AST.ModuleName AST.Range
    | NoTopLevelSignature FileName String AST.Range


type alias FileName =
    String


asString : Message -> String
asString m =
    case m of
        UnusedTopLevel fileName varName range ->
            String.concat
                [ "Unused top level definition `"
                , varName
                , "` in file \""
                , fileName
                , "\" at "
                , rangeToString range
                ]

        UnusedVariable fileName varName range ->
            String.concat
                [ "Unused variable `"
                , varName
                , "` in file \""
                , fileName
                , "\" at "
                , rangeToString range
                ]

        UnreadableSourceFile s ->
            String.concat
                [ "Could not parse source file: ", s ]

        UnreadableDependencyFile dependency path ->
            String.concat
                [ "Could not parse file in dependency"
                , dependency
                , ": "
                , path
                ]

        ExposeAll fileName range ->
            String.concat
                [ "Exposing all in file \""
                , fileName
                , "\" at "
                , rangeToString range
                ]

        ImportAll fileName moduleName range ->
            String.concat
                [ "Importing all from module `"
                , String.join "." moduleName
                , "`in file \""
                , fileName
                , "\" at "
                , rangeToString range
                ]

        NoTopLevelSignature fileName varName range ->
            String.concat
                [ "No signature for top level definition `"
                , varName
                , "` in file \""
                , fileName
                , "\" at "
                , rangeToString range
                ]


locationToString : AST.Location -> String
locationToString { row, column } =
    "(" ++ toString row ++ "," ++ toString column ++ ")"


rangeToString : AST.Range -> String
rangeToString { start, end } =
    "(" ++ locationToString start ++ "," ++ locationToString end ++ ")"
