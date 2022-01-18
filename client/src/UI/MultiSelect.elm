module UI.MultiSelect exposing (Model, Msg, init, selected, update, view)

import Html exposing (Html, div, input, span, text)
import Html.Attributes exposing (class, value)
import Html.Events exposing (onClick, onInput)


type alias Model value =
    { options : List (Option value) }


selected : Model value -> List value
selected model =
    List.filterMap
        (\( value, isSelected, _ ) ->
            if isSelected then
                Just value

            else
                Nothing
        )
        model.options


type alias Option value =
    ( value, Bool, String )


init : List ( value, String ) -> Model value
init =
    List.map (\( value, title ) -> ( value, False, title )) >> Model


type Msg value
    = InputChanged String
    | SelectOption value
    | RemoveOption value


update : Msg value -> Model value -> Model value
update msg model =
    case msg of
        InputChanged _ ->
            model

        SelectOption _ ->
            model

        RemoveOption removedValue ->
            { model | options = List.map (turnOff removedValue) model.options }


turnOff : value -> Option value -> Option value
turnOff removedValue ( value, oldSelected, title ) =
    ( value
    , if value == removedValue then
        False

      else
        oldSelected
    , title
    )


view : (Msg value -> msg) -> Model value -> Html msg
view msg model =
    div [ class "multiselect" ]
        (List.concat
            [ model.options
                |> List.filterMap
                    (\( value, isSelected, title ) ->
                        if not isSelected then
                            Nothing

                        else
                            Just
                                (span [ class "multiselect__selected-option" ]
                                    [ text title
                                    , span
                                        [ class "multiselect__selected-option-remove"
                                        , onClick <| msg (RemoveOption value)
                                        ]
                                        [ text "x" ]
                                    ]
                                )
                    )
            , [ input
                    [ class "multiselect__input"
                    , onInput <| msg << InputChanged
                    ]
                    []
              ]
            ]
        )
