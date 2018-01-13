port module Main exposing (main)

import Components.Button
import Components.Color
import Components.LogoElm
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Introspection
import Json.Decode as Decode
import Navigation
import Pages.Page1
import UrlParser exposing ((</>))


-- ROUTES


routes : List Route
routes =
    [ Top
    , Page1
    , Page2
    , Page2_1
    , Styleguide
    , Sitemap
    ]


type Route
    = Top
    | Page1
    | Page2
    | Page2_1
    | Styleguide
    | Sitemap
    | NotFound


type alias RouteData =
    { name : String
    , path : List String
    , view : Model -> Html Msg
    }


routeData : Route -> RouteData
routeData route =
    case route of
        Top ->
            { name = "Intro"
            , path = []
            , view = viewTop
            }

        Page1 ->
            { name = "Page one"
            , path = [ "page1" ]
            , view = Pages.Page1.view
            }

        Page2 ->
            { name = "Page two"
            , path = [ "page2" ]
            , view = viewPage2
            }

        Page2_1 ->
            { name = "Page two.one"
            , path = [ "page2", "subpage1" ]
            , view = viewPage2_1
            }

        Styleguide ->
            { name = "Style Guide"
            , path = [ "styleguide" ]
            , view = viewStyleguide
            }

        Sitemap ->
            { name = "Sitemap"
            , path = [ "sitemap" ]
            , view = viewSitemap
            }

        NotFound ->
            { name = "Page Not Found"
            , path = []
            , view = \_ -> text "Page not found"
            }


routePath : Route -> List String
routePath route =
    .path <| routeData route


pathSeparator : String
pathSeparator =
    "/"


routePathJoined : Route -> String
routePathJoined route =
    pathSeparator ++ String.join pathSeparator (routePath route)


routeName : Route -> String
routeName route =
    .name <| routeData route


routeView : Route -> Model -> Html Msg
routeView route =
    .view <| routeData route


matchers : UrlParser.Parser (Route -> a) a
matchers =
    UrlParser.oneOf
        (List.map
            (\route ->
                let
                    listPath =
                        routePath route
                in
                if List.length listPath == 0 then
                    UrlParser.map route UrlParser.top
                else if List.length listPath == 1 then
                    UrlParser.map route (UrlParser.s <| firstElement listPath)
                else if List.length listPath == 2 then
                    UrlParser.map route
                        ((UrlParser.s <| firstElement listPath)
                            </> (UrlParser.s <| secondElement listPath)
                        )
                else
                    UrlParser.map route UrlParser.top
            )
            routes
        )


locationToRoute : Navigation.Location -> Route
locationToRoute location =
    case UrlParser.parsePath matchers location of
        Just route ->
            route

        Nothing ->
            NotFound



-- PORTS


port urlChange : String -> Cmd msg


port storeLocalStorage : Maybe String -> Cmd msg


port onLocalStorageChange : (Decode.Value -> msg) -> Sub msg



-- TYPES


type Msg
    = ChangeLocation String
    | UrlChange Navigation.Location
    | NewApiData (Result Http.Error DataFromApi)
    | FetchApiData String
    | SetLocalStorage (Result String String)
    | UpdateLocalStorage String


type alias Model =
    { route : Route
    , history : List String
    , apiData : ApiData
    , location : Navigation.Location
    , title : String
    , localStorage : String
    }


type ApiData
    = NoData
    | Fetching
    | Fetched String



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        ChangeLocation location ->
            ( model, Navigation.newUrl location )

        UrlChange location ->
            let
                newRoute =
                    locationToRoute location

                newHistory =
                    location.pathname :: model.history

                newTitle =
                    routeName newRoute ++ " - " ++ model.title
            in
            ( { model | route = newRoute, history = newHistory, location = location }
            , urlChange newTitle
            )

        NewApiData result ->
            case result of
                Ok data ->
                    ( { model | apiData = Fetched data.origin }, Cmd.none )

                Err data ->
                    ( model, Cmd.none )

        FetchApiData url ->
            ( { model | apiData = Fetching }
            , Http.send NewApiData (Http.get url apiDecoder)
            )

        SetLocalStorage result ->
            case result of
                Ok value ->
                    ( { model | localStorage = value }, Cmd.none )

                Err value ->
                    ( model, Cmd.none )

        UpdateLocalStorage value ->
            ( { model | localStorage = value }, storeLocalStorage <| Just value )



-- INIT


initModel : String -> Navigation.Location -> Model
initModel val location =
    { route = locationToRoute location
    , history = [ location.pathname ]
    , apiData = NoData
    , location = location
    , title = "Elm Spa Boilerplate"
    , localStorage = val
    }


initCmd : Model -> Navigation.Location -> Cmd Msg
initCmd model location =
    Cmd.none


init : String -> Navigation.Location -> ( Model, Cmd Msg )
init val location =
    let
        model =
            initModel val location

        cmd =
            initCmd model location
    in
    ( model, cmd )



-- API DECODER


type alias DataFromApi =
    { origin : String }


apiDecoder : Decode.Decoder DataFromApi
apiDecoder =
    Decode.map DataFromApi (Decode.at [ "origin" ] Decode.string)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map SetLocalStorage <| onLocalStorageChange (Decode.decodeValue Decode.string)
        ]



-- VIEWS


view : Model -> Html Msg
view model =
    div []
        [ h1 []
            [ Components.LogoElm.component (Components.LogoElm.Color Components.LogoElm.Orange) 50
            , br [] []
            , text model.title
            ]
        , img [ src "/static/img/skyline.png", style [ ( "width", "100%" ) ] ] []
        , div [ class "menu" ]
            [ ul []
                (List.map
                    (\route -> li [] [ viewLink model route ])
                    routes
                )
            ]
        , div [ class "container" ]
            [ h2 [] [ text <| routeName model.route ]
            , routeView model.route model
            ]
        , div [ class "footer" ]
            [ div [ class "footerContainer" ] [ madeByLucamug ]
            ]
        , forkMe
        ]


viewLink : Model -> Route -> Html Msg
viewLink model route =
    let
        url =
            routePathJoined route

        onLinkClick : String -> Attribute Msg
        onLinkClick path =
            onWithOptions "click"
                { stopPropagation = False
                , preventDefault = True
                }
                (Decode.succeed (ChangeLocation path))
    in
    if model.route == route then
        div [ class "selected" ] [ text (routeName route) ]
    else
        a [ href url, onLinkClick url ] [ text (routeName route) ]



-- VIEWS PAGES


viewTop : Model -> Html Msg
viewTop model =
    div []
        [ p [] [ text "This is a boilerplate for an Elm Single Page Application." ]
        , p [] [ text "Find a detailed post at..." ]
        , p []
            [ text "The code is at "
            , a [ href "https://github.com/lucamug/elm-spa-boilerplate" ] [ text "https://github.com/lucamug/elm-spa-boilerplate" ]
            ]
        , h3 [] [ text "Ajax request example" ]
        , case model.apiData of
            NoData ->
                div []
                    [ p [] [ Components.Button.component Components.Button.LargeImportant (onClick <| FetchApiData "https://httpbin.org/delay/1") "My IP is..." ]
                    , p [] [ text <| "Your IP is ..." ]
                    ]

            Fetching ->
                div []
                    [ p [] [ Components.Button.component Components.Button.LargeImportantWithSpinner noAttribute "My IP is..." ]
                    , p [] [ text <| "Your IP is ..." ]
                    ]

            Fetched ip ->
                div []
                    [ p [] [ Components.Button.component Components.Button.LargeImportant (onClick <| FetchApiData "https://httpbin.org/delay/1") "My IP is..." ]
                    , p [] [ text <| "Your IP is " ++ ip ]
                    ]
        , h3 [] [ text "Local Storage" ]
        , p [] [ text "Example of local storage implementation using flags and ports. The value in the input field below is automatically read and written into localStorage.spa." ]
        , input
            [ style [ ( "font-size", "18px" ), ( "padding", "10px 14px" ) ]
            , value model.localStorage
            , onInput UpdateLocalStorage
            ]
            []
        ]


viewStyleguide : Model -> Html Msg
viewStyleguide model =
    div []
        [ text "This is a Living Style Guide automatically generated from the code."
        , Introspection.view Components.Color.introspection
        , Introspection.view Components.Button.introspection
        , Introspection.view Components.LogoElm.introspection
        ]


viewSitemap : Model -> Html Msg
viewSitemap model =
    let
        path route =
            String.join "/" (routePath route)

        tdStyle =
            style [ ( "padding", "4px 10px" ) ]
    in
    table []
        (List.map
            (\route ->
                let
                    url =
                        model.location.origin ++ routePathJoined route
                in
                tr []
                    [ td [ tdStyle ] [ viewLink model route ]
                    , td [ tdStyle ] [ a [ href url ] [ text url ] ]
                    ]
            )
            routes
        )


viewPage2 : Model -> Html Msg
viewPage2 model =
    pre [] [ text """I cannot well repeat how there I entered,
So full was I of slumber at the moment
In which I had abandoned the true way.

But after I had reached a mountain's foot,
At that point where the valley terminated,
Which had with consternation pierced my heart,

Upward I looked, and I beheld its shoulders
Vested already with that planet's rays
Which leadeth others right by every road.""" ]


viewPage2_1 : Model -> Html Msg
viewPage2_1 model =
    pre [] [ text """Then was the fear a little quieted
That in my heart's lake had endured throughout
The night, which I had passed so piteously

And even as he, who, with distressful breath,
Forth issued from the sea upon the shore,
Turns to the water perilous and gazes;

So did my soul, that still was fleeing onward,
Turn itself back to re-behold the pass
Which never yet a living person left.""" ]



-- HELPERS


firstElement : List String -> String
firstElement list =
    Maybe.withDefault "" (List.head list)


secondElement : List String -> String
secondElement list =
    firstElement (Maybe.withDefault [] (List.tail list))


noAttribute : Attribute msg
noAttribute =
    attribute "no-data" ""



-- MAIN


main : Program String Model Msg
main =
    Navigation.programWithFlags UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- FORK ME ON GITHUB


forkMe : Html msg
forkMe =
    a [ href "https://github.com/lucamug/elm-spa-boilerplate" ]
        [ img
            [ src "https://camo.githubusercontent.com/a6677b08c955af8400f44c6298f40e7d19cc5b2d/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f72696768745f677261795f3664366436642e706e67"
            , alt "Fork me on GitHub"
            , style
                [ ( "position", "absolute" )
                , ( "top", "0px" )
                , ( "right", "0px" )
                , ( "border", "0px" )
                ]
            ]
            []
        ]



-- MADE BY LUCAMUG


madeByLucamug : Html msg
madeByLucamug =
    a [ class "lucamug", href "https://github.com/lucamug" ]
        [ node "style" [] [ text """
        .lucamug{opacity:.4;color:#000;display:block;text-decoration:none}
        .lucamug:hover{opacity:.5}
        .lucamug:hover .lucamugSpin{transform:rotate(0deg);padding:0;position:relative;top:0;}
        .lucamugSpin{color:red ;display:inline-block;transition:all .4s ease-in-out; transform:rotate(60deg);padding:0 2px 0 4px;position:relative;top:-4px;}""" ]
        , text "made with "
        , span [ class "lucamugSpin" ] [ text "凸" ]
        , text " by lucamug"
        ]
