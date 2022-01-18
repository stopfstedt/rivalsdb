module Pages.Home_ exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.Home_ exposing (Params)
import Html exposing (..)
import Page
import Request
import Shared
import UI.Layout.Template
import UI.MultiSelect
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init req
        , update = update
        , view = view shared
        , subscriptions = always Sub.none
        }


type alias Model =
    { multi : UI.MultiSelect.Model Int }


init : Request.With Params -> ( Model, Effect Msg )
init _ =
    ( { multi =
            UI.MultiSelect.init
                [ ( 1, "One" )
                , ( 2, "Two" )
                , ( 3, "Three" )
                , ( 4, "Four" )
                ]
      }
    , Effect.none
    )


type Msg
    = FromShared Shared.Msg
    | FromMulti (UI.MultiSelect.Msg Int)


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        FromShared subMsg ->
            ( model, Effect.fromShared subMsg )

        FromMulti subMsg ->
            ( { model | multi = UI.MultiSelect.update subMsg model.multi }, Effect.none )


view : Shared.Model -> Model -> View Msg
view shared model =
    UI.Layout.Template.view FromShared
        shared
        [ h1 [] [ text "oioioi" ]
        , UI.MultiSelect.view FromMulti model.multi
        ]
