module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    , handleEffectMsg
    , SignInStatus(..)
    )

{-|

@docs Flags, decoder
@docs Model, Msg
@docs init, update, subscriptions
@docs handleEffectMsg

@docs SignInStatus

-}

import Api.User exposing (User)
import Browser.Navigation
import Effect exposing (Effect)
import Http
import Json.Decode
import Route exposing (Route)
import Route.Path



-- INIT


type alias Flags =
    { token : Maybe String
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.map Flags
        (Json.Decode.maybe (Json.Decode.field "token" Json.Decode.string))


type alias Model =
    { signInStatus : SignInStatus
    }


type SignInStatus
    = NotSignedIn
    | SignedInWithToken String
    | SignedInWithUser User
    | FailedToSignIn Http.Error


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    let
        flags : Flags
        flags =
            flagsResult
                |> Result.withDefault { token = Nothing }

        signInStatus : SignInStatus
        signInStatus =
            case flags.token of
                Nothing ->
                    NotSignedIn

                Just token ->
                    SignedInWithToken token
    in
    ( { signInStatus = signInStatus
      }
    , case flags.token of
        Just token ->
            Effect.fromCmd
                (Api.User.getCurrentUser
                    { token = token
                    , onResponse = UserApiResponded
                    }
                )

        Nothing ->
            Effect.none
    )



-- UPDATE


type Msg
    = UserApiResponded (Result Http.Error User)
    | FromEffect Effect.Msg


handleEffectMsg : Effect.Msg -> Msg
handleEffectMsg =
    FromEffect


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        UserApiResponded (Ok user) ->
            ( { model | signInStatus = SignedInWithUser user }
            , Effect.none
            )

        UserApiResponded (Err httpError) ->
            ( { model | signInStatus = FailedToSignIn httpError }
            , Effect.none
            )

        FromEffect (Effect.SignInPageSignedInUser (Ok user)) ->
            ( { model | signInStatus = SignedInWithUser user }
            , Effect.pushRoute
                { path = Route.Path.Home_
                , query = []
                , hash = Nothing
                }
            )

        FromEffect (Effect.SignInPageSignedInUser (Err httpError)) ->
            ( { model | signInStatus = FailedToSignIn httpError }
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions req model =
    Sub.none
