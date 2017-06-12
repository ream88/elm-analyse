module Analyser.Checks.UnusedTypeAlias exposing (checker)

import Elm.Syntax.Range exposing (Range)
import Elm.Syntax.TypeAnnotation exposing (..)
import Elm.Syntax.TypeAlias exposing (..)
import Analyser.FileContext exposing (FileContext)
import Elm.Interface as Interface exposing (Interface)
import Analyser.Messages.Types exposing (Message, MessageData(UnusedTypeAlias), newMessage)
import Dict exposing (Dict)
import ASTUtil.Inspector as Inspector exposing (Order(Post), defaultConfig)
import Tuple3
import Analyser.Configuration exposing (Configuration)
import Analyser.Checks.Base exposing (Checker, keyBasedChecker)


checker : Checker
checker =
    { check = scan
    , shouldCheck = keyBasedChecker [ "UnusedTypeAlias" ]
    }


type alias Context =
    Dict String ( String, Range, Int )


scan : FileContext -> Configuration -> List Message
scan fileContext _ =
    let
        collectedAliased : Context
        collectedAliased =
            Inspector.inspect
                { defaultConfig | onTypeAlias = Post onTypeAlias }
                fileContext.ast
                Dict.empty
    in
        Inspector.inspect
            { defaultConfig
                | onTypeAnnotation = Post onTypeAnnotation
                , onFunctionOrValue = Post onFunctionOrValue
            }
            fileContext.ast
            collectedAliased
            |> Dict.toList
            |> List.filter (Tuple.second >> Tuple3.third >> (<) 0 >> not)
            |> List.filter (Tuple.first >> flip Interface.exposesAlias fileContext.interface >> not)
            |> List.map (Tuple.mapSecond Tuple3.second)
            |> List.map (uncurry (UnusedTypeAlias fileContext.path))
            |> List.map (newMessage [ ( fileContext.sha1, fileContext.path ) ])


markTypeAlias : String -> Context -> Context
markTypeAlias key context =
    Dict.update key (Maybe.map (Tuple3.mapThird ((+) 1))) context


onTypeAnnotation : TypeAnnotation -> Context -> Context
onTypeAnnotation typeAnnotation context =
    case typeAnnotation of
        Typed [] x _ _ ->
            markTypeAlias x context

        _ ->
            context


onFunctionOrValue : String -> Context -> Context
onFunctionOrValue =
    markTypeAlias


onTypeAlias : TypeAlias -> Context -> Context
onTypeAlias typeAlias context =
    Dict.insert typeAlias.name ( typeAlias.name, typeAlias.range, 0 ) context