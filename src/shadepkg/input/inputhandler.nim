import 
  std/[tables, hashes]

import
  sdl2_nim/sdl,
  safeset

import
  ../math/mathutils,
  ../util/types

export
  Scancode,
  Keycode,
  Event,
  EventKind

export
  PRESSED,
  RELEASED,
  Keycode

const DEFAULT_DEADZONE = 0.1

type
  ButtonAction* {.pure.} = enum
    PRESSED,
    RELEASED

  InputState* {.pure, inheritable.} = object
    pressed*: bool
    justPressed*: bool
    justReleased*: bool

  ButtonState* = InputState

  ButtonEventListener* = proc(button: int, state: ButtonState)
  MouseButtonEventListener* = proc(button: int, state: ButtonState, x, y, clicks: int)

  MouseButton* {.pure.} = enum
    LEFT = BUTTON_LEFT
    MIDDLE = BUTTON_MIDDLE
    RIGHT = BUTTON_RIGHT
    X1 = BUTTON_X1
    X2 = BUTTON_X2

  ControllerButton* {.pure, size: sizeof(uint8).} = enum
    A = CONTROLLER_BUTTON_A,
    B = CONTROLLER_BUTTON_B,
    X = CONTROLLER_BUTTON_X,
    Y = CONTROLLER_BUTTON_Y,
    BACK = CONTROLLER_BUTTON_BACK,
    GUIDE = CONTROLLER_BUTTON_GUIDE,
    START = CONTROLLER_BUTTON_START, 
    LEFT_STICK = CONTROLLER_BUTTON_LEFTSTICK,
    RIGHT_STICK = CONTROLLER_BUTTON_RIGHTSTICK,
    LEFT_SHOULDER = CONTROLLER_BUTTON_LEFTSHOULDER,
    RIGHT_SHOULDER = CONTROLLER_BUTTON_RIGHTSHOULDER,
    DPAD_UP = CONTROLLER_BUTTON_DPAD_UP,
    DPAD_DOWN = CONTROLLER_BUTTON_DPAD_DOWN,
    DPAD_LEFT = CONTROLLER_BUTTON_DPAD_LEFT,
    DPAD_RIGHT = CONTROLLER_BUTTON_DPAD_RIGHT,
    MISC1 = CONTROLLER_BUTTON_MISC1,
    PADDLE1 = SDL_CONTROLLER_BUTTON_PADDLE1,
    PADDLE2 = SDL_CONTROLLER_BUTTON_PADDLE2,
    PADDLE3 = SDL_CONTROLLER_BUTTON_PADDLE3,
    PADDLE4 = SDL_CONTROLLER_BUTTON_PADDLE4,
    TOUCHPAD = SDL_CONTROLLER_BUTTON_TOUCHPAD

  Direction* {.pure.} = enum
    UP,
    DOWN,
    LEFT,
    RIGHT

  ControllerStick* {.pure.} = enum
    ## Analog sticks
    LEFT,
    RIGHT

  ControllerTrigger* {.pure, size: sizeof(uint8).} = enum
    TRIGGER_LEFT = CONTROLLER_AXIS_TRIGGERLEFT,
    TRIGGER_RIGHT = CONTROLLER_AXIS_TRIGGERRIGHT

  Mouse* = ref object
    location: Vector
    buttons: Table[int, ButtonState]
    vScrolled: int
    buttonPressedListeners: seq[MouseButtonEventListener]
    buttonReleasedListeners: seq[MouseButtonEventListener]

  KeyState* = InputState
  KeyListener* = proc(key: Keycode, state: KeyState)
  Keyboard* = ref object
    keys: Table[Keycode, KeyState]
    keyListeners: Table[Keycode, SafeSet[KeyListener]]

  ControllerStickState* = object
    x*: float
    y*: float

  ControllerStickEventListener* = proc(stick: ControllerStick, state: ControllerStickState)

  ControllerButtonState* = object
    pressed: bool
    justPressed: bool
    justReleased: bool

  Controller* = ref object
    # NOTE: Will add support for multiple controllers, touchpads, etc. later when needed.
    sdlGameController: GameController
    deadzoneRadius*: float
    name: string

    leftStick: ControllerStickState
    rightStick: ControllerStickState
    stickListeners: seq[ControllerStickEventListener]

    buttons: Table[GameControllerButton, ButtonState]
    buttonPressedListeners: seq[ButtonEventListener]
    buttonReleasedListeners: seq[ButtonEventListener]

  CustomEventListener* = proc(state: InputState)
  CustomEventTriggers = ref object
    keys*: seq[Keycode]
    sticks*: Table[ControllerStick, Vector]
    # TODO: angle or radians? slope?
    ## Table[Stick, AngleRange]
    triggers*: seq[ControllerTrigger]
    mouseButtons*: Table[MouseButton, ButtonAction]
    controllerButtons*: seq[GameControllerButton]

  # NOTE: Desired syntax:
  # let upEvent = Input.createCustomEvent("up")
  # upEvent.addTrigger(Stick.LEFT, Direction.UP)
  # upEvent.addTrigger(K_UP, PRESSED)
  # upEvent.onTrigger(proc(state: InputState) = discard)

  EventListener* = proc(e: Event): bool
  ## Return true to remove the listener from the InputHandler.
  InputHandler* = ref object
    eventListeners: Table[EventKind, SafeSet[EventListener]]

    customEvents: Table[string, InputState]
    customEventTriggers: Table[string, CustomEventTriggers]
    customEventListeners: Table[string, SafeSet[CustomEventListener]]

    mouse: Mouse
    keyboard: Keyboard
    controller*: Controller
    windowScaling*: Vector

# InputHandler singleton
var Input*: InputHandler

proc initInputHandlerSingleton*(windowScaling: Vector) =
  if Input != nil:
    raise newException(Exception, "InputHandler singleton already active!")
  Input = InputHandler(
    mouse: Mouse(),
    keyboard: Keyboard(),
    controller: Controller(deadzoneRadius: DEFAULT_DEADZONE),
    windowScaling: windowScaling
  )

  if init(INIT_GAMECONTROLLER) != 0:
    raise newException(Exception, "Unable to init controller support")

proc addEventListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if not this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind] = newSafeSet[EventListener]()
  this.eventListeners[eventKind].add(listener)

proc removeEventListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind].remove(listener)

proc addKeyEventListener*(this: InputHandler, key: Keycode, listener: KeyListener) =
  if not this.keyboard.keyListeners.hasKey(key):
    this.keyboard.keyListeners[key] = newSafeSet[KeyListener]()
  this.keyboard.keyListeners[key].add(listener)

proc removeKeyEventListener*(this: InputHandler, key: Keycode, listener: KeyListener) =
  if this.keyboard.keyListeners.hasKey(key):
    this.keyboard.keyListeners[key].remove(listener)

proc addMousePressedEventListener*(this: InputHandler, listener: MouseButtonEventListener) =
  this.mouse.buttonPressedListeners.add(listener)

proc addMouseReleasedEventListener*(this: InputHandler, listener: MouseButtonEventListener) =
  this.mouse.buttonReleasedListeners.add(listener)

## Custom Events

proc registerCustomEvent*(this: InputHandler, eventName: string) =
  this.customEvents[eventName] = InputState()
  this.customEventTriggers[eventName] = CustomEventTriggers()
  this.customEventListeners[eventName] = newSafeSet[CustomEventListener]()

proc dispatchCustomEvent*(this: InputHandler, eventName: string) =
  if not this.customEventListeners.hasKey(eventName) or not this.customEvents.hasKey(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  let state = this.customEvents[eventName]
  for listener in this.customEventListeners[eventName]:
    listener(state)

proc addCustomEventListener*(this: InputHandler, eventName: string, listener: CustomEventListener) =
  if not this.customEventListeners.hasKey(eventName):
    this.customEventListeners[eventName] = newSafeSet[CustomEventListener]()
  this.customEventListeners[eventName].add(listener)

# proc addCustomEventTrigger*(this: InputHandler, eventName: string, button: GameControllerButton) =
#   if this.customEventTriggers.hasKey(eventName):
#     this.customEventTriggers[eventName].controllerButtons.add(button)

# TODO: Make an example with mouse buttons first
proc addCustomEventTrigger*(
  this: InputHandler,
  eventName: string,
  mouseButton: MouseButton,
  action: ButtonAction = ButtonAction.PRESSED
) =
  if not this.customEventTriggers.hasKey(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  this.customEventTriggers[eventName].mouseButtons[mouseButton] = action

  # TODO:
  # Would be nice if I could just add a new button event listener that triggers the custom event,
  # but then how do we remove that listener when we remove the custom event?
  # Maybe worry about that later.

  let listener =
    proc(button: int, state: ButtonState, x, y, clicks: int) =
      this.dispatchCustomEvent(eventName)

  if action == ButtonAction.PRESSED:
    this.addMousePressedEventListener(listener)
  elif action == ButtonAction.RELEASED:
    this.addMouseReleasedEventListener(listener)

# proc addCustomEventTrigger*(this: InputHandler, eventName: string, stick: Stick, dir: Direction) =
#   this.customEventTriggers[eventName] = CustomEventTriggers()
#   if this.customEventTriggers.hasKey(eventName):
#     this.customEventTriggers[eventName].sticks.add(stick)

proc clearController(this: InputHandler) =
  this.controller.sdlGameController = nil
  this.controller.name = ""
  this.controller.leftStick = ControllerStickState()
  this.controller.rightStick = ControllerStickState()
  # this.controller.triggers.clear()
  this.controller.buttons.clear()

proc setController(this: InputHandler, id: JoystickID) =
  let sdlGameController = gameControllerOpen(id)
  if sdlGameController != nil:
    this.controller.sdlGameController = sdlGameController
    this.controller.name = $sdlGameController.gameControllerName()
    this.controller.leftStick = ControllerStickState()
    this.controller.rightStick = ControllerStickState()
    # this.controller.triggers.clear()
    this.controller.buttons.clear()
  else:
    # TODO: Need some sort of better logging for non-fatal errors.
    echo "Error opening newly connected controller"

proc processEvent*(this: InputHandler, event: Event) =
  ## Processes events.
  ## Returns if the user wants to exit the application.
  case event.kind:
    # Mouse
    of MOUSEMOTION:
      this.mouse.location.x = float(event.motion.x) * this.windowScaling.x
      this.mouse.location.y = float(event.motion.y) * this.windowScaling.y

    of MOUSEBUTTONDOWN:
      let
        buttonEvent = event.button
        button = buttonEvent.button
        buttonX: int = int(float(buttonEvent.x) * this.windowScaling.x)
        buttonY: int = int(float(buttonEvent.y) * this.windowScaling.y)
      if not this.mouse.buttons.hasKey(button):
        this.mouse.buttons[button] = ButtonState()
      this.mouse.buttons[button].pressed = true
      this.mouse.buttons[button].justPressed = true

      for listener in this.mouse.buttonPressedListeners:
        listener(button, this.mouse.buttons[button], buttonX, buttonY, int buttonEvent.clicks)

    of MOUSEBUTTONUP:
      let
        buttonEvent = event.button
        button = buttonEvent.button
        buttonX: int = int(float(buttonEvent.x) * this.windowScaling.x)
        buttonY: int = int(float(buttonEvent.y) * this.windowScaling.y)

      if not this.mouse.buttons.hasKey(button):
        this.mouse.buttons[button] = ButtonState()
      this.mouse.buttons[button].pressed = false
      this.mouse.buttons[button].justPressed = false
      this.mouse.buttons[button].justReleased = true

      for listener in this.mouse.buttonReleasedListeners:
        listener(button, this.mouse.buttons[button], buttonX, buttonY, int buttonEvent.clicks)

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
      let
        e = event.caxis
        axis = e.axis

      var value = float e.value
      value =
        if value < 0:
          -value / float int16.low
        else:
          value / float int16.high

      if abs(value) <= this.controller.deadzoneRadius:
        value = 0.0

      case axis:
        of CONTROLLER_AXIS_LEFTX:
          this.controller.leftStick.x = value
        of CONTROLLER_AXIS_LEFTY:
          this.controller.leftStick.y = value
        of CONTROLLER_AXIS_RIGHTX:
          this.controller.rightStick.x = value
        of CONTROLLER_AXIS_RIGHTY:
          this.controller.rightStick.y = value
        else:
          # TODO: Triggers
          discard

    else:
      discard

  if this.eventListeners.hasKey(event.kind):
    for listener in this.eventListeners[event.kind]:
      if listener(event):
        this.eventListeners[event.kind].remove(listener)

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
  this.isMouseButtonPressed(MouseButton.LEFT)

template wasLeftMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(MouseButton.LEFT)

template wasLeftMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(MouseButton.LEFT)

# Right mouse button

template isRightMouseButtonPressed*(this: InputHandler): bool =
  this.isMouseButtonPressed(MouseButton.RIGHT)

template wasRightMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(MouseButton.RIGHT)

template wasRightMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(MouseButton.RIGHT)

# Wheel

template wheelScrolledLastFrame*(this: InputHandler): int =
  this.mouse.vScrolled

proc mouseLocation*(this: InputHandler): Vector =
  return this.mouse.location

# Controller

proc leftStick*(this: InputHandler): ControllerStickState =
  result = this.controller.leftStick

proc rightStick*(this: InputHandler): ControllerStickState =
  result = this.controller.rightStick

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

proc resetFrameSpecificState*(this: InputHandler) =
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

