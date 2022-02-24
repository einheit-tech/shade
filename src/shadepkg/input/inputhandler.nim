import 
  sdl2_nim/sdl,
  tables

import 
  ../math/mathutils

export Scancode, Keycode

export
  BUTTON_LEFT,
  BUTTON_MIDDLE,
  BUTTON_RIGHT,
  PRESSED,
  RELEASED,
  GameControllerButton,
  Keycode

type
  ButtonState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  ButtonEventListener* = proc(button: int, state: ButtonState)

type Mouse* = ref object
  location: Vector
  buttons: Table[int, ButtonState]
  vScrolled: int
  buttonPressedEventListeners: seq[ButtonEventListener]
  buttonReleasedEventListeners: seq[ButtonEventListener]

type
  KeyState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  KeyListener* = proc(key: Keycode, state: KeyState)

  Keyboard* = ref object
    keys: Table[Keycode, KeyState]
    keyListeners: Table[Keycode, seq[KeyListener]]

type
  ControllerButtonState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  # TODO: Deadzones
  Controller* = ref object
    # NOTE: Will add support for multiple controllers, touchpads, etc. later when needed.
    sdlGameController: GameController
    name: string
    axes: Table[GameControllerAxis, float]
    buttons: Table[GameControllerButton, ButtonState]
    buttonPressedEventListeners: seq[ButtonEventListener]
    buttonReleasedEventListeners: seq[ButtonEventListener]

type InputHandler* = ref object
  mouse: Mouse
  keyboard: Keyboard
  controller: Controller

# InputHandler singleton
var Input*: InputHandler

proc initInputHandlerSingleton*() =
  if Input != nil:
    raise newException(Exception, "InputHandler singleton already active!")
  Input = InputHandler(
    mouse: Mouse(),
    keyboard: Keyboard(),
    controller: Controller()
  )

  if init(INIT_GAMECONTROLLER) != 0:
    raise newException(Exception, "Unable to init controller support")

proc addMousePressedEventListener*(this: InputHandler, listener: ButtonEventListener) =
  this.mouse.buttonPressedEventListeners.add(listener)

proc addMouseReleasedEventListener*(this: InputHandler, listener: ButtonEventListener) =
  this.mouse.buttonReleasedEventListeners.add(listener)

proc clearController(this: InputHandler) =
  this.controller.sdlGameController = nil
  this.controller.name = ""
  this.controller.axes.clear()
  this.controller.buttons.clear()

proc setController(this: InputHandler, id: JoystickID) =
  let sdlGameController = gameControllerOpen(id)
  if sdlGameController != nil:
    this.controller.sdlGameController = sdlGameController
    this.controller.name = $sdlGameController.gameControllerName()
    this.controller.axes.clear()
    this.controller.buttons.clear()
  else:
    # TODO: Need some sort of better logging for non-fatal errors.
    echo "Error opening newly connected controller"

proc processEvent*(this: InputHandler, event: Event): bool =
  ## Processes events.
  ## Returns if the user wants to exit the application.
  case event.kind:
    of QUIT:
      return true

    # Mouse
    of MOUSEMOTION:
      this.mouse.location.x = (float) event.motion.x
      this.mouse.location.y = (float) event.motion.y

    of MOUSEBUTTONDOWN:
      let button = event.button.button
      if not this.mouse.buttons.hasKey(button):
        this.mouse.buttons[button] = ButtonState()
      this.mouse.buttons[button].pressed = true
      this.mouse.buttons[button].justPressed = true

      for listener in this.mouse.buttonPressedEventListeners:
        listener(button, this.mouse.buttons[button])

    of MOUSEBUTTONUP:
      let button = event.button.button
      if not this.mouse.buttons.hasKey(button):
        this.mouse.buttons[button] = ButtonState()
      this.mouse.buttons[button].pressed = false
      this.mouse.buttons[button].justPressed = false
      this.mouse.buttons[button].justReleased = true

      for listener in this.mouse.buttonReleasedEventListeners:
        listener(button, this.mouse.buttons[button])

    of MOUSEWHEEL:
      this.mouse.vScrolled = event.wheel.y

    # Keyboard
    of KEYDOWN, KEYUP:
      let 
        keycode = event.key.keysym.sym
        pressed = event.key.state == PRESSED

      if not this.keyboard.keys.hasKey(keycode):
        this.keyboard.keys[keycode] = KeyState()

      this.keyboard.keys[keycode].justPressed = pressed and not this.keyboard.keys[keycode].pressed
      this.keyboard.keys[keycode].pressed = pressed
      this.keyboard.keys[keycode].justReleased = not pressed

      if this.keyboard.keyListeners.hasKey(keycode):
        for listener in this.keyboard.keyListeners[keycode]:
          listener(keycode, this.keyboard.keys[keycode])

    of CONTROLLERDEVICEADDED:
      this.setController(event.cdevice.which)

    of CONTROLLERDEVICEREMOVED:
      this.clearController()

    of CONTROLLERBUTTONDOWN, CONTROLLERBUTTONUP:
      let
        e = event.cbutton
        pressed = e.state == PRESSED

      template buttonState: ButtonState =
        this.controller.buttons[e.button]

      if not this.controller.buttons.hasKey(e.button):
        this.controller.buttons[e.button] = ButtonState()

      buttonState.justPressed = pressed and not this.controller.buttons[e.button].pressed
      buttonState.pressed = pressed
      buttonState.justReleased = not pressed

    of CONTROLLERAXISMOTION:
      let e = event.caxis
      let value = float e.value
      let floatVal = 
        if value < 0:
          -value / float int16.low
        else:
          value / float int16.high

      this.controller.axes[e.axis] = floatVal

    else:
      return false

# Mouse

proc getMouseButtonState*(this: InputHandler, button: int): ButtonState =
  if not this.mouse.buttons.hasKey(button):
    this.mouse.buttons[button] = ButtonState()
  return this.mouse.buttons[button]

template isMouseButtonPressed*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).pressed

template wasMouseButtonJustPressed*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).justPressed

template wasMouseButtonJustReleased*(this: InputHandler, button: int): bool =
  this.getMouseButtonState(button).justReleased

# Keyboard

proc getKeyState*(this: InputHandler, keycode: Keycode): KeyState =
  if not this.keyboard.keys.hasKey(keycode):
    this.keyboard.keys[keycode] = KeyState()
  return this.keyboard.keys[keycode]

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

# Wheel

template wheelScrolledLastFrame*(this: InputHandler): int =
  this.mouse.vScrolled

proc mouseLocation*(this: InputHandler): Vector =
  return this.mouse.location

# Controller

proc leftStickX*(this: InputHandler): float =
  if this.controller.axes.hasKey(CONTROLLER_AXIS_LEFTX):
    return this.controller.axes[CONTROLLER_AXIS_LEFTX]

proc leftStickY*(this: InputHandler): float =
  if this.controller.axes.hasKey(CONTROLLER_AXIS_LEFTY):
    return this.controller.axes[CONTROLLER_AXIS_LEFTY]

proc rightStickX*(this: InputHandler): float =
  if this.controller.axes.hasKey(CONTROLLER_AXIS_RIGHTX):
    return this.controller.axes[CONTROLLER_AXIS_RIGHTX]

proc rightStickY*(this: InputHandler): float =
  if this.controller.axes.hasKey(CONTROLLER_AXIS_RIGHTY):
    return this.controller.axes[CONTROLLER_AXIS_RIGHTY]

proc getControllerButtonState*(this: InputHandler, button: GameControllerButton): ButtonState =
  if not this.controller.buttons.hasKey(button):
    this.controller.buttons[button] = ButtonState()
  return this.controller.buttons[button]

template isControllerButtonPressed*(this: InputHandler, button: GameControllerButton): bool =
  this.getControllerButtonState(button).pressed

template wasControllerButtonJustPressed*(this: InputHandler, button: GameControllerButton): bool =
  this.getControllerButtonState(button).justPressed

template wasControllerButtonJustReleased*(this: InputHandler, button: GameControllerButton): bool =
  this.getControllerButtonState(button).justReleased

proc update*(this: InputHandler, deltaTime: float) =
  # Update justPressed props (invoked _after_ the game was updated).
  for button in this.mouse.buttons.mvalues:
    button.justPressed = false
    button.justReleased = false

  for key in this.keyboard.keys.mvalues:
    key.justPressed = false
    key.justReleased = false

  for button in this.controller.buttons.mvalues:
    button.justPressed = false
    button.justReleased = false

  this.mouse.vScrolled = 0

