module Pages.Search exposing (Model, Msg, page)

import Cards exposing (Card)
import Dict
import Fuzzy
import Gen.Params.Search exposing (Params)
import Html exposing (..)
import Html.Attributes exposing (class)
import Page
import Request
import Shared exposing (Collection)
import UI.Card
import UI.FilterSelection
import UI.Layout.Footer
import UI.Layout.Header
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.element
        { init = init shared.collection req
        , update = update
        , view = view
        , subscriptions = always Sub.none
        }


type alias Model =
    { matches : List Card
    , collection : Collection
    , header : UI.Layout.Header.Model
    , primaryFilters : UI.FilterSelection.Model Cards.Trait Msg
    , secondaryFilters : UI.FilterSelection.Model Cards.Trait Msg
    , attackTypeFilters : UI.FilterSelection.Model Cards.AttackType Msg
    }


init : Collection -> Request.With Params -> ( Model, Cmd Msg )
init collection req =
    let
        header =
            UI.Layout.Header.init req
    in
    ( { collection = collection
      , header = header
      , matches = matchesForQuery collection header.queryString
      , primaryFilters = UI.FilterSelection.primaryTraits
      , secondaryFilters = UI.FilterSelection.secondaryTraits
      , attackTypeFilters = UI.FilterSelection.attackTypes
      }
    , Cmd.none
    )


matchesForQuery : Collection -> Maybe String -> List Card
matchesForQuery collection query =
    case query of
        Nothing ->
            Dict.values collection

        Just q ->
            Dict.keys collection |> fuzzySort q |> List.take 3 |> List.filterMap (\k -> Dict.get k collection)


fuzzySort : String -> List String -> List String
fuzzySort query items =
    let
        simpleMatch config separators needle hay =
            Fuzzy.match config separators needle hay |> .score
    in
    List.sortBy (simpleMatch [] [] query) items



-- UPDATE


type Msg
    = FromHeader UI.Layout.Header.Msg
    | FromPrimaryFilter (UI.FilterSelection.Msg Cards.Trait)
    | FromSecondaryFilter (UI.FilterSelection.Msg Cards.Trait)
    | FromAttackTypesFilter (UI.FilterSelection.Msg Cards.AttackType)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FromHeader subMsg ->
            let
                ( newHeader, headerCmd ) =
                    UI.Layout.Header.update subMsg model.header
            in
            ( { model | header = newHeader, matches = matchesForQuery model.collection newHeader.queryString }, headerCmd )

        FromPrimaryFilter subMsg ->
            ( { model | primaryFilters = UI.FilterSelection.update subMsg model.primaryFilters }, Cmd.none )

        FromSecondaryFilter subMsg ->
            ( { model | secondaryFilters = UI.FilterSelection.update subMsg model.secondaryFilters }, Cmd.none )

        FromAttackTypesFilter subMsg ->
            ( { model | attackTypeFilters = UI.FilterSelection.update subMsg model.attackTypeFilters }, Cmd.none )



-- VIEW


view : Model -> View Msg
view model =
    [ UI.Layout.Header.view FromHeader
    , div [ class "page-content" ]
        [ h2 [] [ text "Filters" ]
        , div [ class "search-filters" ]
            [ div [ class "search-filter" ] [ UI.FilterSelection.view FromPrimaryFilter model.primaryFilters ]
            , div [ class "search-filter" ] [ UI.FilterSelection.view FromSecondaryFilter model.secondaryFilters ]
            , div [ class "search-filter" ] [ UI.FilterSelection.view FromAttackTypesFilter model.attackTypeFilters ]
            ]
        , h3 [] [ text "matches" ]
        , ul [ class "search-results" ]
            (model.matches
                |> List.filter (UI.FilterSelection.isAllowed Cards.traits model.primaryFilters)
                |> List.filter (UI.FilterSelection.isAllowed Cards.traits model.secondaryFilters)
                |> List.filter (UI.FilterSelection.isAllowed Cards.attackTypes model.attackTypeFilters)
                |> List.map
                    (\card ->
                        li [ class "search-result" ]
                            [ UI.Card.lazy card
                            ]
                    )
            )
        ]
    , UI.Layout.Footer.view
    ]
