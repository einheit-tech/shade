import 
  sdl2_nim/sdl,
  pixie,
  tables

from sdl2_nim/sdl import Scancode, Keycode

import 
  ../math/mathutils

export Scancode, Keycode

type
  MouseButtonState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  MouseInfo = object
    location: Vec2
    buttons: Table[int, MouseButtonState]

  KeyState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  InputHandler* = ref object
    window: Window
    mouse: MouseInfo
    keys: Table[Keycode, KeyState]

# InputHandler singleton
var Input*: InputHandler

proc initInputHandlerSingleton*(window: Window) =
  if Input != nil:
    raise newException(Exception, "InputHandler singleton already active!")
  Input = InputHandler(window: window)
 
proc processEvent*(this: InputHandler, event: Event): bool =
  ## Processes events.
  ## Returns if the user wants to exit the application.

  case event.kind:
    of QUIT:
      return true

    # Mouse
    of MOUSEMOTION:
      Input.mouse.location.x = (float) event.motion.x
      Input.mouse.location.y = (float) event.motion.y

    of MOUSEBUTTONUP:
      let button = event.button.button
      if not Input.mouse.buttons.hasKey(button):
        Input.mouse.buttons[button] = MouseButtonState()
      Input.mouse.buttons[button].pressed = false
      Input.mouse.buttons[button].justPressed = false
      Input.mouse.buttons[button].justReleased = true

    of MOUSEBUTTONDOWN:
      let button = event.button.button
      if not Input.mouse.buttons.hasKey(button):
        Input.mouse.buttons[button] = MouseButtonState()
      Input.mouse.buttons[button].pressed = true
      Input.mouse.buttons[button].justPressed = true

    # Keyboard
    of KEYDOWN, KEYUP:
      let 
        keycode = event.key.keysym.sym
        pressed = event.key.state == PRESSED

      if not Input.keys.hasKey(keycode):
        Input.keys[keycode] = KeyState()

      Input.keys[keycode].pressed = pressed
      Input.keys[keycode].justPressed = pressed
      Input.keys[keycode].justReleased = not pressed

    else:
      return false

# Mouse

proc getMouseButtonState*(this: InputHandler, button: int): MouseButtonState =
  if not this.mouse.buttons.hasKey(button):
    this.mouse.buttons[button] = MouseButtonState()
  return this.mouse.buttons[button]

template isMouseButtonPressed*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).pressed

template wasMouseButtonJustPressed*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).justPressed

template wasMouseButtonJustReleased*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).justReleased

# Keyboard

proc getKeyState*(this: InputHandler, keycode: Keycode): KeyState =
  if not this.keys.hasKey(keycode):
    this.keys[keycode] = KeyState()
  return this.keys[keycode]

template isKeyPressed*(this: InputHandler, keycode: Keycode): bool =
  this.getKeyState(keycode).pressed

template wasKeyJustPressed*(this: InputHandler, keycode: Keycode): bool =
  this.getKeyState(keycode).justPressed

template wasKeyJustReleased*(this: InputHandler, keycode: Keycode): bool =
  this.getKeyState(keycode).justReleased

# Left mouse button

template isLeftMouseButtonPressed*(this: InputHandler): bool =
  this.isMouseButtonPressed(BUTTON_LEFT)

template wasLeftMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(BUTTON_LEFT)

template wasLeftMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(BUTTON_LEFT)

# Right mouse button

template isRightMouseButtonPressed*(this: InputHandler): bool =
  this.isMouseButtonPressed(BUTTON_RIGHT)

template wasRightMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(BUTTON_RIGHT)

template wasRightMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(BUTTON_RIGHT)

proc mouseLocation*(this: InputHandler): Vec2 =
  return this.mouse.location

proc update*(this: InputHandler, deltaTime: float) =
  # Update justPressed props (invoked _after_ the game was updated).
  for button in this.mouse.buttons.mvalues:
    button.justPressed = false
    button.justReleased = false

  for key in this.keys.mvalues:
    key.justPressed = false
    key.justReleased = false

when defined(inputdebug):
  proc renderInputInfo*(ctx: Context) =
    ## Render debug info

    # TODO: This will be stupid slow if the library doesn't cache the font.
    var font = readFont("fonts/JetBrainsMono-Regular.ttf")
    font.size = 20
    font.paint.color = rgba(120, 120, 0, 255)

    let mouseLoc = Input.mouseLocation()
    var mouseLocationText = "Mouse Location:"
    mouseLocationText &= "(" & $mouseLoc.x & ", " & $mouseLoc.y & ")"

    var leftButtonText  = "\n\nLeft Button:"
    leftButtonText &= "\n  Pressed: " & $Input.isLeftMouseButtonPressed()
    leftButtonText &= "\n  Just Pressed: " & $Input.wasLeftMouseButtonJustPressed()
    leftButtonText &= "\n  Just Released: " & $Input.wasLeftMouseButtonJustReleased()

    var rightButtonText = "\n\nRight Button:"
    rightButtonText &= "\n  Pressed: " & $Input.isRightMouseButtonPressed()
    rightButtonText &= "\n  Just Pressed: " & $Input.wasRightMouseButtonJustPressed()
    rightButtonText &= "\n  Just Released: " & $Input.wasRightMouseButtonJustReleased()

    # Keyboard
    
    var pressedKeys = "\n\n"
    for key, state in Input.keys:
      if state.pressed:
        pressedKeys &= $key & " "

    let text = mouseLocationText & leftButtonText & rightButtonText & pressedKeys

    ctx.image.fillText(font.typeset(text, vec2(1920, 1080)), translate(vec2(10, 10)))
