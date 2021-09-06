import 
  staticglfw,
  pixie,
  tables

import 
  math/mathutils

type
  MouseButtonState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool
  MouseInfo = object
    location: Vec2
    buttons: Table[int, MouseButtonState]

  # TODO: is there a better way to represent this data?
  # Need to inform user if key is pressed, repeating, or just released.
  KeyState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  InputHandler* = ref object
    window: Window
    mouse: MouseInfo
    keys: Table[int, KeyState]
    # TODO: Key info
    # https://www.glfw.org/docs/3.0/group__input.html#gaef49b72d84d615bca0a6ed65485e035d

# InputHandler singleton
var Input*: InputHandler

proc bindMouseButtonCallback(this: InputHandler)
proc bindKeyboardCallback(this: InputHandler)

proc initInputHandlerSingleton*(window: Window) =
  Input = InputHandler(window: window)
  Input.bindMouseButtonCallback()
  Input.bindKeyboardCallback()

# Mouse

proc getMouseButtonState*(button: int): MouseButtonState =
  if not Input.mouse.buttons.hasKey(button):
    Input.mouse.buttons[button] = MouseButtonState()
  return Input.mouse.buttons[button]

template isMouseButtonPressed*(button: int): bool =
  getMouseButtonState(button).pressed

template wasMouseButtonJustPressed*(button: int): bool =
  getMouseButtonState(button).justPressed

template wasMouseButtonJustReleased*(button: int): bool =
  getMouseButtonState(button).justReleased

# Keyboard

proc getKeyState*(keycode: int): KeyState =
  if not Input.keys.hasKey(keycode):
    Input.keys[keycode] = KeyState()
  return Input.keys[keycode]

template isKeyPressed*(keycode: int): bool =
  getKeyState(keycode).pressed

template wasKeyJustPressed*(keycode: int): bool =
  getKeyState(keycode).justPressed

template wasKeyJustReleased*(keycode: int): bool =
  getKeyState(keycode).justReleased


# Left mouse button

template isLeftMouseButtonPressed*(): bool =
  isMouseButtonPressed(MOUSE_BUTTON_LEFT)

template wasLeftMouseButtonJustPressed*(): bool =
  wasMouseButtonJustPressed(MOUSE_BUTTON_LEFT)

template wasLeftMouseButtonJustReleased*(): bool =
  wasMouseButtonJustReleased(MOUSE_BUTTON_LEFT)

# Right mouse button

template isRightMouseButtonPressed*(): bool =
  isMouseButtonPressed(MOUSE_BUTTON_RIGHT)

template wasRightMouseButtonJustPressed*(): bool =
  wasMouseButtonJustPressed(MOUSE_BUTTON_RIGHT)

template wasRightMouseButtonJustReleased*(): bool =
  wasMouseButtonJustReleased(MOUSE_BUTTON_RIGHT)

proc bindMouseButtonCallback(this: InputHandler) =

  # C-binding callback when mouse events occur.
  proc onMouseButtonEvent(window: Window, button, action, modifiers: cint) {.cdecl.} =
    if not Input.mouse.buttons.hasKey(button):
      Input.mouse.buttons[button] = MouseButtonState()

    # Assign appropriate state to the button.
    Input.mouse.buttons[button].pressed = action == PRESS
    if action == PRESS:
      Input.mouse.buttons[button].justPressed = true
    elif action == RELEASE:
      Input.mouse.buttons[button].justReleased = true

  discard this.window.setMouseButtonCallback(onMouseButtonEvent)

  proc onMouseMoveEvent(window: Window, x, y: float) {.cdecl.} =
    Input.mouse.location.x = x
    Input.mouse.location.y = y

  discard this.window.setCursorPosCallback(onMouseMoveEvent)

proc bindKeyboardCallback(this: InputHandler) =

  # C-binding callback when key events occur.
  proc onKeyboardEvent(window: Window, key, scancode, action, mods: cint) {.cdecl.} =
    ## key: The keyboard key that was pressed or released (KEY_FOO).
    ## scancode: The system-specific scancode of the key.
    ## action: PRESS, RELEASE, or REPEAT
    ## mods: Bit field describing which modifier keys were held down.
    ##       MOD_SHIFT, MOD_CONTROL, MOD_ALT, MOD_SUPER

    if not Input.keys.hasKey(key):
      Input.keys[key] = KeyState()

    # Assign appropriate state to the key.
    Input.keys[key].pressed = action == PRESS or action == REPEAT
    if action == PRESS:
      Input.keys[key].justPressed = true
    elif action == RELEASE:
      Input.keys[key].justReleased = true

  discard this.window.setKeyCallback(onKeyboardEvent)

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
    leftButtonText &= "\n  Pressed: " & $isLeftMouseButtonPressed()
    leftButtonText &= "\n  Just Pressed: " & $wasLeftMouseButtonJustPressed()
    leftButtonText &= "\n  Just Released: " & $wasLeftMouseButtonJustReleased()

    var rightButtonText = "\n\nRight Button:"
    rightButtonText &= "\n  Pressed: " & $isRightMouseButtonPressed()
    rightButtonText &= "\n  Just Pressed: " & $wasRightMouseButtonJustPressed()
    rightButtonText &= "\n  Just Released: " & $wasRightMouseButtonJustReleased()

    # Keyboard
    
    var pressedKeys = "\n\n"
    for key, state in Input.keys:
      if state.pressed:
        pressedKeys &= $key & " "

    let text = mouseLocationText & leftButtonText & rightButtonText & pressedKeys

    ctx.image.fillText(font.typeset(text, vec2(1920, 1080)), translate(vec2(10, 10)))

