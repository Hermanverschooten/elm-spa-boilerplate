module Parts.Button
    exposing
        ( introspection
        , large
        , largeImportant
        , largeImportantWithSpinner
        , largeWithSpinner
        , small
        , smallImportant
        )

import Color
import Element
import Element.Background
import Element.Border
import Element.Font
import Element.Hack
import Element.Input
import Introspection
import Parts.Color


introspection : Introspection.Introspection2 msg
introspection =
    { name = "Button"
    , signature = "String -> Maybe msg -> Element.Element msg"
    , description = "Button accept a type, an Html.Attribute msg that can be attribute that return a messages, such as onClick, and a string that is used inside the button."
    , usage = """small "I am an usage example" Nothing"""
    , usageResult = small "I am an usage example" Nothing
    , types = types
    , example = identity
    }


types : List ( Element.Element msg, String )
types =
    [ ( small "Button" Nothing, "small" )
    , ( large "Button" Nothing, "large" )
    , ( largeWithSpinner "Button" Nothing, "largeWithSpinner" )
    , ( smallImportant "Button" Nothing, "smallImportant" )
    , ( largeImportant "Button" Nothing, "largeImportant" )
    , ( largeImportantWithSpinner "Button" Nothing, "largeImportantWithSpinner" )
    ]


type Type
    = Small
    | SmallImportant
    | Large
    | LargeImportant
    | LargeWithSpinner
    | LargeImportantWithSpinner


type Color
    = Regular
    | Important
    | TextOnRegular
    | TextOnImportant


type Size
    = SmallSize
    | LargeSize


typeToColor : Color -> Color.Color
typeToColor color =
    case color of
        Regular ->
            Parts.Color.white

        Important ->
            Parts.Color.elmOrange

        TextOnRegular ->
            Parts.Color.fontColor

        TextOnImportant ->
            Parts.Color.white


sizeToInt : Size -> Int
sizeToInt size =
    case size of
        SmallSize ->
            16

        LargeSize ->
            32


small : String -> Maybe msg -> Element.Element msg
small label onPress =
    component label onPress Small


smallImportant : String -> Maybe msg -> Element.Element msg
smallImportant label onPress =
    component label onPress SmallImportant


large : String -> Maybe msg -> Element.Element msg
large label onPress =
    component label onPress Large


largeImportant : String -> Maybe msg -> Element.Element msg
largeImportant label onPress =
    component label onPress LargeImportant


largeWithSpinner : String -> Maybe msg -> Element.Element msg
largeWithSpinner label onPress =
    component label onPress LargeWithSpinner


largeImportantWithSpinner : String -> Maybe msg -> Element.Element msg
largeImportantWithSpinner label onPress =
    component label onPress LargeImportantWithSpinner


component : String -> Maybe msg -> Type -> Element.Element msg
component label onPress type_ =
    let
        { size, bgColor, spinner } =
            case type_ of
                Small ->
                    { size = SmallSize
                    , bgColor = Regular
                    , spinner = False
                    }

                SmallImportant ->
                    { size = SmallSize
                    , bgColor = Important
                    , spinner = False
                    }

                Large ->
                    { size = LargeSize
                    , bgColor = Regular
                    , spinner = False
                    }

                LargeImportant ->
                    { size = LargeSize
                    , bgColor = Important
                    , spinner = False
                    }

                LargeWithSpinner ->
                    { size = LargeSize
                    , bgColor = Regular
                    , spinner = True
                    }

                LargeImportantWithSpinner ->
                    { size = LargeSize
                    , bgColor = Important
                    , spinner = True
                    }

        textColor =
            case bgColor of
                Regular ->
                    TextOnRegular

                _ ->
                    TextOnImportant

        sizeInt =
            sizeToInt size

        spinnerElement =
            Element.paragraph [ Element.padding <| sizeInt - 5 ]
                [ Element.Hack.styleElement "@keyframes spinner { to { transform: rotate(360deg); } }"
                , Element.el
                    [ Element.Font.size 30

                    --, Element.moveUp 0
                    , Element.Hack.style
                        [ ( "animation", "spinner .6s linear infinite" )
                        ]
                    ]
                  <|
                    -- Element.text "🌸"
                    Element.text "🏵"
                ]
    in
    Element.Input.button
        [ Element.inFront spinner spinnerElement
        , Element.Background.color <| typeToColor bgColor
        , Element.Font.color <| typeToColor textColor
        , Element.Border.rounded 10
        , Element.Border.width 1
        , Element.Border.color <| typeToColor textColor
        , Element.Hack.style [ ( "transition", "all .3s" ) ]
        , Element.centerY
        , if spinner then
            Element.Hack.style [ ( "cursor", "progress" ) ]
          else
            Element.Hack.style [ ( "cursor", "pointer" ) ]
        , if spinner then
            Element.paddingEach
                { top = sizeInt
                , left = sizeInt * 2 + 10
                , bottom = sizeInt
                , right = sizeInt * 2 - 10
                }
          else
            Element.paddingEach
                { top = sizeInt
                , left = sizeInt * 2
                , bottom = sizeInt
                , right = sizeInt * 2
                }
        ]
        { onPress = onPress
        , label = Element.text label
        }
