module Article exposing
    ( Model
    , Msg
    , Return(..)
    , initEmpty
    , initWithQuery
    , update
    , view
    )

import Article.Collection
import Article.Details
import Article.Directory
import Article.Empty
import Article.Fts
import Document exposing (DocumentId)
import Folder exposing (Folder, FolderCounts)
import Html exposing (Html)
import Html.Attributes
import Query exposing (Query)
import Tree
import Utils


type alias Context =
    { query : Query
    }


type Return
    = NoReturn
    | FolderCounts FolderCounts
    | SetQuery Query


type alias Model =
    { content : Content
    }


type Content
    = EmptyModel Article.Empty.Model
    | CollectionModel Article.Collection.Model
    | DirectoryModel Article.Directory.Model
    | FtsModel Article.Fts.Model
    | DetailsModel Article.Details.Model


type Msg
    = EmptyMsg Article.Empty.Msg
    | CollectionMsg Article.Collection.Msg
    | DirectoryMsg Article.Directory.Msg
    | FtsMsg Article.Fts.Msg
    | DetailsMsg Article.Details.Msg


initEmpty : () -> ( Model, Cmd Msg )
initEmpty _ =
    let
        ( subModel, subCmd ) =
            Article.Empty.init ()
    in
    ( { content = EmptyModel subModel }
    , Cmd.map EmptyMsg subCmd
    )


initWithQuery : Query -> ( Model, Cmd Msg )
initWithQuery query =
    case query of
        Query.CollectionQuery collectionQuery ->
            let
                ( subModel, subCmd ) =
                    Article.Collection.init ()
            in
            ( { content = CollectionModel subModel }
            , Cmd.map CollectionMsg subCmd
            )

        Query.DetailsQuery detailsQuery ->
            let
                ( subModel, subCmd ) =
                    Article.Details.init <|
                        { detailsQuery = detailsQuery }
            in
            ( { content = DetailsModel subModel }
            , Cmd.map DetailsMsg subCmd
            )

        Query.DirectoryQuery directoryQuery ->
            let
                ( subModel, subCmd ) =
                    Article.Directory.init
                        { directoryQuery = directoryQuery }
            in
            ( { content = DirectoryModel subModel }
            , Cmd.map DirectoryMsg subCmd
            )

        Query.FtsQuery ftsQuery ->
            let
                ( subModel, subCmd ) =
                    Article.Fts.init { ftsQuery = ftsQuery }
            in
            ( { content = FtsModel subModel }
            , Cmd.map FtsMsg subCmd
            )


update : Context -> Msg -> Model -> ( Model, Cmd Msg, Return )
update context msg model =
    case ( msg, model.content, context.query ) of
        ( EmptyMsg subMsg, EmptyModel subModel, _ ) ->
            let
                ( subModel1, subCmd ) =
                    Article.Empty.update subMsg subModel
            in
            ( { model | content = EmptyModel subModel1 }
            , Cmd.map EmptyMsg subCmd
            , NoReturn
            )

        ( CollectionMsg subMsg, CollectionModel subModel, _ ) ->
            let
                ( subModel1, subCmd ) =
                    Article.Collection.update subMsg subModel
            in
            ( { model | content = CollectionModel subModel1 }
            , Cmd.map CollectionMsg subCmd
            , NoReturn
            )

        ( DirectoryMsg subMsg, DirectoryModel subModel, Query.DirectoryQuery directoryQuery ) ->
            let
                ( subModel1, subCmd, documentSelection ) =
                    Article.Directory.update
                        { directoryQuery = directoryQuery }
                        subMsg
                        subModel
            in
            case documentSelection of
                Article.Directory.NoReturn ->
                    ( { model | content = DirectoryModel subModel1 }
                    , Cmd.map DirectoryMsg subCmd
                    , NoReturn
                    )

                Article.Directory.ShowDocument documentId ->
                    ( model
                    , Cmd.none
                    , SetQuery <|
                        Query.DetailsQuery
                            { folder = directoryQuery.folder
                            , documentId = documentId
                            }
                    )

        ( FtsMsg subMsg, FtsModel subModel, Query.FtsQuery ftsQuery ) ->
            let
                ( subModel1, subCmd, subReturn ) =
                    Article.Fts.update
                        { ftsQuery = ftsQuery }
                        subMsg
                        subModel
            in
            case subReturn of
                Article.Fts.NoReturn ->
                    ( { model | content = FtsModel subModel1 }
                    , Cmd.map FtsMsg subCmd
                    , NoReturn
                    )

                Article.Fts.FolderCounts folderCounts ->
                    ( model
                    , Cmd.none
                    , FolderCounts folderCounts
                    )

                Article.Fts.ShowDocument documentId ->
                    ( model
                    , Cmd.none
                    , SetQuery <|
                        Query.DetailsQuery
                            { folder = ftsQuery.folder
                            , documentId = documentId
                            }
                    )

        ( DetailsMsg subMsg, DetailsModel subModel, _ ) ->
            let
                ( subModel1, subCmd ) =
                    Article.Details.update subMsg subModel
            in
            ( { model | content = DetailsModel subModel1 }
            , Cmd.map DetailsMsg subCmd
            , NoReturn
            )

        _ ->
            -- Message doesn't match model; shouldn't never happen
            -- Or model doesn't match query-context; TODO: Can this happen?
            ( model, Cmd.none, NoReturn )


view : Tree.Model -> Context -> Model -> Html Msg
view tree context model =
    Html.article
        [ Html.Attributes.class "article" ]
        [ Html.div
            [ Html.Attributes.class "breadcrumbs" ]
            [ Tree.viewBreadcrumbs tree
                (Query.getFolder context.query |> .id)
            ]
        , Query.view context.query
        , viewContent context model
        ]


viewContent : Context -> Model -> Html Msg
viewContent context model =
    case ( model.content, context.query ) of
        ( EmptyModel subModel, _ ) ->
            Article.Empty.view subModel
                |> Html.map EmptyMsg

        ( CollectionModel subModel, _ ) ->
            Article.Collection.view
                { -- TODO: We construct a synthetic collectionQuery here.
                  --       We should probably use the one from context.query
                  collectionQuery =
                    { folder = Query.getFolder context.query }
                }
                subModel
                |> Html.map CollectionMsg

        ( DirectoryModel subModel, Query.DirectoryQuery directoryQuery ) ->
            Article.Directory.view
                { directoryQuery = directoryQuery }
                subModel
                |> Html.map DirectoryMsg

        ( FtsModel subModel, Query.FtsQuery ftsQuery ) ->
            Article.Fts.view
                { ftsQuery = ftsQuery }
                subModel
                |> Html.map FtsMsg

        ( DetailsModel subModel, _ ) ->
            Article.Details.view subModel
                |> Html.map DetailsMsg

        _ ->
            -- Model doesn't match query-context; TODO: Can this happen?
            Html.text ""
