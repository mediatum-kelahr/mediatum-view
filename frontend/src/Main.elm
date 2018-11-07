module Main exposing (main)

import App
import Browser
import Browser.Navigation
import Html exposing (Html)
import Html.Attributes
import Html.Events
import Url exposing (Url)


type alias Model =
    { navigationKey : Browser.Navigation.Key
    , app : App.Model
    }


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        , onUrlRequest = UrlRequest << Debug.log "onUrlRequest"
        , onUrlChange = UrlChanged << Debug.log "onUrlChange"
        }


type Msg
    = NoOp
    | UrlRequest Browser.UrlRequest
    | UrlChanged Url.Url
    | AppMsg App.Msg


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags url navigationKey =
    let
        ( appModel, appCmd ) =
            App.init ()
    in
    ( { navigationKey = navigationKey
      , app = appModel
      }
    , Cmd.map AppMsg appCmd
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UrlRequest urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Browser.Navigation.pushUrl
                        model.navigationKey
                        (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Browser.Navigation.load href
                    )

        UrlChanged url ->
            ( model
            , Cmd.none
            )

        AppMsg subMsg ->
            let
                ( subModel, subCmd ) =
                    App.update subMsg model.app
            in
            ( { model
                | app = subModel
              }
            , Cmd.map AppMsg subCmd
            )


view : Model -> Browser.Document Msg
view model =
    { title = "mediaTUM View"
    , body =
        [ App.view model.app
            |> Html.map AppMsg
        ]
    }
