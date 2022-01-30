module API.Decklist exposing
    ( ResultDelete
    , ResultIndex
    , ResultRead
    , ResultUpdate
    , delete
    , index
    , indexForUser
    , read
    , update
    )

import API.Auth exposing (auth)
import Data.Collection exposing (Collection)
import Data.Deck exposing (Deck)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Shared


type alias ResultUpdate =
    Result Http.Error ()


update : (ResultUpdate -> msg) -> Shared.Token -> String -> Encode.Value -> Cmd msg
update msg token deckId deck =
    Http.request
        { method = "PUT"
        , url = "/api/v2/decklist/" ++ deckId
        , headers = [ auth token ]
        , timeout = Nothing
        , tracker = Nothing
        , body = Http.jsonBody deck
        , expect = Http.expectWhatever msg
        }


type alias ResultDelete =
    Result Http.Error ()


delete : (ResultDelete -> msg) -> Shared.Token -> String -> Cmd msg
delete msg token deckId =
    Http.request
        { method = "DELETE"
        , url = "/api/v1/decklist/" ++ deckId
        , headers = [ auth token ]
        , timeout = Nothing
        , tracker = Nothing
        , body = Http.emptyBody
        , expect = Http.expectWhatever msg
        }


type alias ResultRead =
    Result Http.Error Deck


read : Collection -> (ResultRead -> msg) -> String -> Cmd msg
read collection msg deckId =
    Http.get
        { url = "/api/v1/decklist/" ++ deckId
        , expect = Http.expectJson msg (Data.Deck.decoder collection)
        }


type alias ResultIndex =
    Result Http.Error (List Deck)


index : Collection -> (ResultIndex -> msg) -> Cmd msg
index collection msg =
    Http.get
        { url = "/api/v1/decklist"
        , expect = Http.expectJson msg (Decode.list <| Data.Deck.decoder collection)
        }


indexForUser : Collection -> (ResultIndex -> msg) -> Shared.Token -> String -> Cmd msg
indexForUser collection msg token userId =
    Http.request
        { method = "GET"
        , url = "/api/v1/decklist?userId=" ++ userId
        , headers = [ auth token ]
        , expect = Http.expectJson msg (Decode.list <| Data.Deck.decoder collection)
        , body = Http.emptyBody
        , timeout = Nothing
        , tracker = Nothing
        }
