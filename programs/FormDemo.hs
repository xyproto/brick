{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
module Main where

import qualified Data.Text as T
import Lens.Micro.TH
import Data.Monoid ((<>))

import Graphics.Vty
import Brick
import Brick.Forms
import Brick.Focus
import Brick.Widgets.Edit
import Brick.Widgets.Border
import Brick.Widgets.Center

data Name = NameField
          | AgeField
          | BikeField
          | HandedField
          | PasswordField
          | LeftHandField
          | RightHandField
          | AmbiField
          deriving (Eq, Ord, Show)

data Handedness = LeftHanded | RightHanded | Ambidextrous
                deriving (Show, Eq)

data FormState =
    FormState { _name      :: T.Text
              , _age       :: Int
              , _ridesBike :: Bool
              , _handed    :: Handedness
              , _password  :: T.Text
              }
              deriving (Show)

makeLenses ''FormState

mkForm :: FormState -> Form FormState e Name
mkForm =
    let label s w = padBottom (Pad 1) $
                    (vLimit 1 $ hLimit 15 $ str s <+> fill ' ') <+> w
    in newForm [ label "Name" @@=
                   editTextField name NameField (Just 1)
               , label "Age" @@=
                   editShowableField age AgeField
               , label "Password" @@=
                   editPasswordField password PasswordField
               , label "Dominant hand" @@=
                   radioField handed [ (LeftHanded, LeftHandField, "Left")
                                     , (RightHanded, RightHandField, "Right")
                                     , (Ambidextrous, AmbiField, "Both")
                                     ]
               , (\w -> label "" (w <+> str " Do you ride a bicycle?")) @@=
                   checkboxField ridesBike BikeField
               ]

theMap :: AttrMap
theMap = attrMap defAttr
  [ (editAttr, white `on` black)
  , (editFocusedAttr, black `on` yellow)
  , (invalidFormInputAttr, white `on` red)
  , (focusedFormInputAttr, black `on` yellow)
  ]

draw :: Form FormState e Name -> [Widget Name]
draw f = [vCenter $ hCenter form <=> hCenter help]
    where
        form = border $ padAll 1 $ hLimit 50 $ renderForm f
        help = padTop (Pad 1) $ borderWithLabel (str "Help") body
        body = str $ "- Name is free-form text\n" <>
                     "- Age must be an integer (try entering an\n" <>
                     "  invalid age!)\n" <>
                     "- Handedness selects from a list of options\n" <>
                     "- The last option is a checkbox"

app :: App (Form FormState e Name) e Name
app =
    App { appDraw = draw
        , appHandleEvent = \s ev ->
            case ev of
                VtyEvent (EvResize {})     -> continue s
                VtyEvent (EvKey KEsc [])   -> halt s
                VtyEvent (EvKey KEnter []) -> halt s
                _                          -> continue =<< handleFormEvent ev s
        , appChooseCursor = focusRingCursor formFocus
        , appStartEvent = return
        , appAttrMap = const theMap
        }

main :: IO ()
main = do
    let initialForm = FormState { _name = ""
                                , _age = 0
                                , _handed = RightHanded
                                , _ridesBike = False
                                , _password = ""
                                }
        f = mkForm initialForm
    f' <- defaultMain app f
    print $ formState f'
