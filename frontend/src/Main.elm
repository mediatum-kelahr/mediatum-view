module Main exposing (main)

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Icons
import Select
import Tree
import Search exposing (SearchType, SimpleSearchDomain)


type alias Model =
    { searchType : SearchType
    , searchString : String
    , tree : Tree.Model
    , search : Search.Model
    }


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


type Msg
    = SearchString String
    | SetSearchType SearchType
    | Submit
    | TreeMsg Tree.Msg
    | SearchMsg Search.Msg


init : ( Model, Cmd Msg )
init =
    let
        initialSearchType =
            Search.SimpleSearch Search.SearchAttributes

        ( treeModel, treeCmd ) =
            Tree.init

        ( searchModel, searchCmd ) =
            Search.init
                { folder = Nothing
                , searchType = initialSearchType
                , searchString = ""
                }

        model =
            { searchType = initialSearchType
            , searchString = ""
            , tree = treeModel
            , search = searchModel
            }
    in
        ( model
        , Cmd.batch
            [ Cmd.map TreeMsg treeCmd
            , Cmd.map SearchMsg searchCmd
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchString str ->
            ( { model | searchString = str }
            , Cmd.none
            )

        SetSearchType searchType ->
            ( { model | searchType = searchType }
            , Cmd.none
            )

        TreeMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Tree.update subMsg model.tree
            in
                ( { model | tree = subModel }
                , Cmd.map TreeMsg subCmd
                )

        SearchMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    Search.update subMsg model.search
            in
                ( { model | search = subModel }
                , Cmd.map SearchMsg subCmd
                )

        Submit ->
            let
                ( searchModel, searchCmd ) =
                    Search.init
                        { folder = model.tree |> Tree.selectedFolderId
                        , searchType = model.searchType
                        , searchString = model.searchString
                        }
            in
                ( { model
                    | search = searchModel
                  }
                , Cmd.map SearchMsg searchCmd
                )


view : Model -> Html Msg
view model =
    Html.div [ Html.Attributes.class "page-container" ]
        [ Icons.definitions
        , Html.header []
            [ Html.h2 []
                [ Html.text "mediaTUM HSB Demo 2018-06-14"
                , Html.div [ Html.Attributes.class "color" ]
                    [ Html.text "PostgreSQL · PostGraphile · GraphQL · Elm" ]
                ]
            , viewSearchControls model
            ]
        , Html.main_ []
            [ Html.aside []
                [ Html.map TreeMsg <| Tree.view model.tree
                ]
            , Html.article []
                [ Html.map SearchMsg <|
                    Search.view model.tree model.search
                ]
            ]
        ]


viewSearchControls : Model -> Html Msg
viewSearchControls model =
    Html.form
        [ Html.Attributes.class "search-bar"
        , Html.Events.onSubmit Submit
        ]
        [ Select.fromSelected_
            [ Search.SimpleSearch Search.SearchAttributes
            , Search.SimpleSearch Search.SearchFulltext
            , Search.SimpleSearch Search.SearchAll
            , Search.AuthorSearch
            ]
            SetSearchType
            toString
            Search.searchTypeText
            model.searchType
        , Html.input
            [ Html.Attributes.class "search-input"
            , Html.Attributes.type_ "search"
            , Html.Attributes.placeholder "Search ..."
            , Html.Attributes.value model.searchString
            , Html.Events.onInput SearchString
            ]
            []
        , Html.button
            [ Html.Attributes.type_ "submit"
            , Html.Attributes.value "Search"
            ]
            [ Icons.search ]
        ]