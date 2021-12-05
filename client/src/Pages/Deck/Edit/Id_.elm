module Pages.Deck.Edit.Id_ exposing (Model, Msg, page)

import API.Decklist
import Auth
import Browser.Navigation as Navigation exposing (Key)
import Cards
import Deck exposing (DeckPostSave, Name(..))
import Effect exposing (Effect)
import Gen.Params.Deck.Edit.Id_ exposing (Params)
import Gen.Route as Route
import Html exposing (Html, li, span, text, ul)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Page
import Request
import Shared
import UI.DeckbuildSelections as DeckbuildSelections
import UI.Decklist
import UI.Icon as Icon
import UI.Layout.Deck
import UI.Layout.Template
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.protected.advanced
        (\user ->
            { init = init shared.collection req.key req.params.id
            , update = update user
            , view = view shared
            , subscriptions = always Sub.none
            }
        )



-- INIT


type Model
    = Loading Key
    | Editing Key Data


type alias Data =
    { deck : DeckPostSave
    , builderOptions : DeckbuildSelections.Model Msg
    }


init : Shared.Collection -> Key -> String -> ( Model, Effect Msg )
init collection key deckId =
    ( Loading key
    , Effect.fromCmd <| API.Decklist.read collection FetchedDecklist deckId
    )


type Msg
    = FromShared Shared.Msg
    | FromBuilderOptions DeckbuildSelections.Msg
    | ChoseLeader Cards.Faction
    | Save
    | SavedDecklist API.Decklist.ResultUpdate
    | Delete
    | DeletedDecklist API.Decklist.ResultDelete
    | StartRenameDeck
    | DeckNameChanged String
    | SaveNewDeckName
    | FetchedDecklist API.Decklist.ResultRead


update : Auth.User -> Msg -> Model -> ( Model, Effect Msg )
update user msg modelx =
    case ( modelx, msg ) of
        ( _, FromShared subMsg ) ->
            ( modelx, Effect.fromShared subMsg )

        ( Loading key, FetchedDecklist (Ok deck) ) ->
            ( Editing key { deck = deck, builderOptions = DeckbuildSelections.init }, Effect.none )

        ( _, FetchedDecklist (Err _) ) ->
            ( modelx, Effect.none )

        ( Loading _, _ ) ->
            ( modelx, Effect.none )

        ( Editing key oldModel, FetchedDecklist (Ok deck) ) ->
            ( Editing key { oldModel | deck = deck }, Effect.none )

        ( Editing key oldModel, FromBuilderOptions (DeckbuildSelections.ChangedDecklist change) ) ->
            let
                oldDeck =
                    oldModel.deck
            in
            ( Editing key { oldModel | deck = { oldDeck | decklist = Deck.setCard oldDeck.decklist change } }, Effect.none )

        ( Editing key oldModel, FromBuilderOptions subMsg ) ->
            ( Editing key { oldModel | builderOptions = DeckbuildSelections.update subMsg oldModel.builderOptions }, Effect.none )

        ( Editing key model, ChoseLeader leader ) ->
            let
                oldDeck =
                    model.deck
            in
            ( Editing key { model | deck = { oldDeck | decklist = Deck.setLeader oldDeck.decklist leader } }, Effect.none )

        ( Editing key model, Save ) ->
            case Deck.encode (Deck.PostSave model.deck) of
                Just encodedDeck ->
                    ( Editing key model, API.Decklist.update SavedDecklist user.token model.deck.meta.id encodedDeck |> Effect.fromCmd )

                _ ->
                    ( Editing key model, Effect.none )

        ( Editing key model, SavedDecklist _ ) ->
            ( Editing key model, Effect.none )

        ( Editing key model, Delete ) ->
            ( Editing key model, API.Decklist.delete DeletedDecklist user.token model.deck.meta.id |> Effect.fromCmd )

        ( Editing key model, DeletedDecklist _ ) ->
            ( Editing key model, Route.toHref Route.MyDecks |> Navigation.replaceUrl key |> Effect.fromCmd )

        ( Editing key model, StartRenameDeck ) ->
            let
                oldDeck =
                    model.deck

                oldMeta =
                    oldDeck.meta
            in
            ( Editing key { model | deck = { oldDeck | meta = { oldMeta | name = Deck.BeingNamed "" } } }, Effect.none )

        ( Editing key model, DeckNameChanged newName ) ->
            let
                oldDeck =
                    model.deck

                oldMeta =
                    oldDeck.meta
            in
            case model.deck.meta.name of
                BeingNamed _ ->
                    ( Editing key { model | deck = { oldDeck | meta = { oldMeta | name = Deck.BeingNamed newName } } }, Effect.none )

                _ ->
                    ( Editing key model, Effect.none )

        ( Editing key model, SaveNewDeckName ) ->
            let
                oldDeck =
                    model.deck

                oldMeta =
                    oldDeck.meta
            in
            case model.deck.meta.name of
                BeingNamed newName ->
                    case String.trim newName of
                        "" ->
                            ( Editing key { model | deck = { oldDeck | meta = { oldMeta | name = Deck.Unnamed } } }, Effect.none )

                        trimmedName ->
                            ( Editing key { model | deck = { oldDeck | meta = { oldMeta | name = Deck.Named trimmedName } } }, Effect.none )

                _ ->
                    ( Editing key model, Effect.none )


decklistActions : UI.Decklist.Actions Msg
decklistActions =
    { setLeader = ChoseLeader
    , startNameChange = StartRenameDeck
    , changeName = DeckNameChanged
    , endNameChange = SaveNewDeckName
    }


view : Shared.Model -> Model -> View Msg
view shared model =
    case model of
        Loading _ ->
            UI.Layout.Template.view FromShared shared []

        Editing _ data ->
            UI.Layout.Template.view FromShared
                shared
                [ UI.Layout.Deck.writeMode
                    { actions = viewActions
                    , decklist = [ UI.Decklist.viewEdit decklistActions data.deck ]
                    , selectors = [ DeckbuildSelections.view shared.collection FromBuilderOptions data.builderOptions data.deck.decklist ]
                    }
                ]


viewActions : List (Html Msg)
viewActions =
    [ ul [ class "actions-list" ]
        [ li [ class "actions-item", onClick Save ]
            [ span [ class "actions-icon" ] [ Icon.icon ( Icon.Save, Icon.Standard ) ]
            , span [ class "actions-description" ] [ text "Save" ]
            ]
        , li [ class "actions-item", onClick Delete ]
            [ span [ class "actions-icon" ] [ Icon.icon ( Icon.Save, Icon.Standard ) ]
            , span [ class "actions-description" ] [ text "Delete" ]
            ]
        ]
    ]
