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
  ControllerButtonEventListener* = proc(button: ControllerButton, state: ButtonState)
  MouseButtonEventListener* = proc(button: int, state: ButtonState, x, y, clicks: int)

  MouseButton* {.pure.} = enum
    LEFT = BUTTON_LEFT
    MIDDLE = BUTTON_MIDDLE
    RIGHT = BUTTON_RIGHT
    X1 = BUTTON_X1
    X2 = BUTTON_X2

  ControllerButton* {.pure, size: sizeof(uint8).} = enum
    A = CONTROLLER_BUTTON_A
    B = CONTROLLER_BUTTON_B
    X = CONTROLLER_BUTTON_X
    Y = CONTROLLER_BUTTON_Y
    BACK = CONTROLLER_BUTTON_BACK
    GUIDE = CONTROLLER_BUTTON_GUIDE
    START = CONTROLLER_BUTTON_START 
    LEFT_STICK = CONTROLLER_BUTTON_LEFTSTICK
    RIGHT_STICK = CONTROLLER_BUTTON_RIGHTSTICK
    LEFT_SHOULDER = CONTROLLER_BUTTON_LEFTSHOULDER
    RIGHT_SHOULDER = CONTROLLER_BUTTON_RIGHTSHOULDER
    DPAD_UP = CONTROLLER_BUTTON_DPAD_UP
    DPAD_DOWN = CONTROLLER_BUTTON_DPAD_DOWN
    DPAD_LEFT = CONTROLLER_BUTTON_DPAD_LEFT
    DPAD_RIGHT = CONTROLLER_BUTTON_DPAD_RIGHT
    MISC1 = CONTROLLER_BUTTON_MISC1
    PADDLE1 = SDL_CONTROLLER_BUTTON_PADDLE1
    PADDLE2 = SDL_CONTROLLER_BUTTON_PADDLE2
    PADDLE3 = SDL_CONTROLLER_BUTTON_PADDLE3
    PADDLE4 = SDL_CONTROLLER_BUTTON_PADDLE4
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

    buttons: Table[ControllerButton, ButtonState]
    buttonPressedListeners: Table[ControllerButton, SafeSet[ControllerButtonEventListener]]
    buttonReleasedListeners: Table[ControllerButton, SafeSet[ControllerButtonEventListener]]

  CustomEventListener* = proc(state: InputState)
  CustomEventTriggers = ref object
    keys*: seq[Keycode]
    sticks*: Table[ControllerStick, Vector]
    # TODO: angle or radians? slope?
    ## Table[Stick, AngleRange]
    triggers*: seq[ControllerTrigger]
    mouseButtons*: Table[MouseButton, ButtonAction]
    controllerButtons*: seq[ControllerButton]

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

const CONTROLLER_BUTTON_REVERSE_LOOKUP = {
  CONTROLLER_BUTTON_A: A,
  CONTROLLER_BUTTON_B: B,
  CONTROLLER_BUTTON_X: X,
  CONTROLLER_BUTTON_Y: Y,
  CONTROLLER_BUTTON_BACK: BACK,
  CONTROLLER_BUTTON_GUIDE: GUIDE,
  CONTROLLER_BUTTON_START: START,
  CONTROLLER_BUTTON_LEFTSTICK: LEFT_STICK,
  CONTROLLER_BUTTON_RIGHTSTICK: RIGHT_STICK,
  CONTROLLER_BUTTON_LEFTSHOULDER: LEFT_SHOULDER,
  CONTROLLER_BUTTON_RIGHTSHOULDER: RIGHT_SHOULDER,
  CONTROLLER_BUTTON_DPAD_UP: DPAD_UP,
  CONTROLLER_BUTTON_DPAD_DOWN: DPAD_DOWN,
  CONTROLLER_BUTTON_DPAD_LEFT: DPAD_LEFT,
  CONTROLLER_BUTTON_DPAD_RIGHT: DPAD_RIGHT,
  CONTROLLER_BUTTON_MISC1: MISC1,
  SDL_CONTROLLER_BUTTON_PADDLE1: PADDLE1,
  SDL_CONTROLLER_BUTTON_PADDLE2: PADDLE2,
  SDL_CONTROLLER_BUTTON_PADDLE3: PADDLE3,
  SDL_CONTROLLER_BUTTON_PADDLE4: PADDLE4,
  SDL_CONTROLLER_BUTTON_TOUCHPAD: TOUCHPAD
}.toTable()

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

proc addListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if not this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind] = newSafeSet[EventListener]()
  this.eventListeners[eventKind].add(listener)

proc removeListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind].remove(listener)

proc addKeyListener*(this: InputHandler, key: Keycode, listener: KeyListener) =
  if not this.keyboard.keyListeners.hasKey(key):
    this.keyboard.keyListeners[key] = newSafeSet[KeyListener]()
  this.keyboard.keyListeners[key].add(listener)

proc removeKeyListener*(this: InputHandler, key: Keycode, listener: KeyListener) =
  if this.keyboard.keyListeners.hasKey(key):
    this.keyboard.keyListeners[key].remove(listener)

proc addMousePressedListener*(this: InputHandler, listener: MouseButtonEventListener) =
  this.mouse.buttonPressedListeners.add(listener)

proc addMouseReleasedListener*(this: InputHandler, listener: MouseButtonEventListener) =
  this.mouse.buttonReleasedListeners.add(listener)

proc addControllerButtonPressedListener*(
  this: InputHandler,
  button: ControllerButton,
  listener: ControllerButtonEventListener
) =
  if not this.controller.buttonPressedListeners.hasKey(button):
    this.controller.buttonPressedListeners[button] = newSafeSet[ControllerButtonEventListener]()
  this.controller.buttonPressedListeners[button].add(listener)

proc addControllerButtonReleasedListener*(
  this: InputHandler,
  button: ControllerButton,
  listener: ControllerButtonEventListener
) =
  if not this.controller.buttonReleasedListeners.hasKey(button):
    this.controller.buttonReleasedListeners[button] = newSafeSet[ControllerButtonEventListener]()
  this.controller.buttonReleasedListeners[button].add(listener)

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

proc addCustomEventTrigger*(
  this: InputHandler,
  eventName: string,
  button: ControllerButton,
  action: ButtonAction = ButtonAction.PRESSED
) =
  if not this.customEventTriggers.hasKey(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  # TODO: Is this line even needed?
  # this.customEventTriggers[eventName].controllerButtons[button] = action

  # TODO: How do we remove this listener when we remove the custom event?
  let listener =
    proc(button: int, state: ButtonState, x, y, clicks: int) =
      this.dispatchCustomEvent(eventName)

  if action == ButtonAction.PRESSED:
    this.addMousePressedListener(listener)
  elif action == ButtonAction.RELEASED:
    this.addMouseReleasedListener(listener)

proc addCustomEventTrigger*(
  this: InputHandler,
  eventName: string,
  mouseButton: MouseButton,
  action: ButtonAction = ButtonAction.PRESSED
) =
  if not this.customEventTriggers.hasKey(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  this.customEventTriggers[eventName].mouseButtons[mouseButton] = action

  # TODO: How do we remove this listener when we remove the custom event?
  let listener =
    proc(button: int, state: ButtonState, x, y, clicks: int) =
      this.dispatchCustomEvent(eventName)

  if action == ButtonAction.PRESSED:
    this.addMousePressedListener(listener)
  elif action == ButtonAction.RELEASED:
    this.addMouseReleasedListener(listener)

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

template handleMouseMotionEvent(this: InputHandler, e: MouseMotionEventObj) =
  this.mouse.location.x = float(e.x) * this.windowScaling.x
  this.mouse.location.y = float(e.y) * this.windowScaling.y

template handleMouseButtonEvent(this: InputHandler, e: MouseButtonEventObj) =
  let
    button = e.button
    buttonX: int = int(float(e.x) * this.windowScaling.x)
    buttonY: int = int(float(e.y) * this.windowScaling.y)

  if not this.mouse.buttons.hasKey(button):
    this.mouse.buttons[button] = ButtonState()

  let eventIsPressed = event.kind == MOUSEBUTTONDOWN
  this.mouse.buttons[button].pressed = eventIsPressed
  this.mouse.buttons[button].justPressed = eventIsPressed
  this.mouse.buttons[button].justReleased = not eventIsPressed

  if eventIsPressed:
    for listener in this.mouse.buttonPressedListeners:
      listener(button, this.mouse.buttons[button], buttonX, buttonY, int e.clicks)
  else:
    for listener in this.mouse.buttonReleasedListeners:
      listener(button, this.mouse.buttons[button], buttonX, buttonY, int e.clicks)

template handleMouseWheelEvent(this: InputHandler, e: MouseWheelEventObj) =
  this.mouse.vScrolled = e.y

template handleKeyboardEvent(this: InputHandler, e: KeyboardEventObj) =
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

template handleControllerDeviceEvent(this: InputHandler, e: ControllerDeviceEventObj) =
  if e.kind == CONTROLLERDEVICEADDED:
    this.setController(event.cdevice.which)
  elif e.kind == CONTROLLERDEVICEREMOVED:
    this.clearController()

template handleControllerButtonEvent(this: InputHandler, e: ControllerButtonEventObj) =
  if CONTROLLER_BUTTON_REVERSE_LOOKUP.hasKey(e.button):
    let 
      pressed = e.state == PRESSED
      button = CONTROLLER_BUTTON_REVERSE_LOOKUP[e.button]

    template buttonState: ButtonState =
      this.controller.buttons[button]

    if not this.controller.buttons.hasKey(button):
      this.controller.buttons[button] = ButtonState()

    buttonState.justPressed = pressed and not buttonState.pressed
    buttonState.pressed = pressed
    buttonState.justReleased = not pressed

    if pressed:
      if this.controller.buttonPressedListeners.hasKey(button):
        for listener in this.controller.buttonPressedListeners[button]:
          listener(button, buttonState)
    else:
      if this.controller.buttonReleasedListeners.hasKey(button):
        for listener in this.controller.buttonReleasedListeners[button]:
          listener(button, buttonState)

template handleControllerAxisEvent(this: InputHandler, e: ControllerAxisEventObj) =
  let axis = e.axis
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

proc processEvent*(this: InputHandler, event: Event) =
  case event.kind:
    # Mouse
    of MOUSEMOTION:
      this.handleMouseMotionEvent(event.motion)

    of MOUSEBUTTONDOWN, MOUSEBUTTONUP:
      this.handleMouseButtonEvent(event.button)

    of MOUSEWHEEL:
      this.handleMouseWheelEvent(event.wheel)

    # Keyboard
    of KEYDOWN, KEYUP:
      this.handleKeyboardEvent(event.key)

    # Controller
    of CONTROLLERDEVICEADDED, CONTROLLERDEVICEREMOVED:
      this.handleControllerDeviceEvent(event.cdevice)

    of CONTROLLERBUTTONDOWN, CONTROLLERBUTTONUP:
      this.handleControllerButtonEvent(event.cbutton)

    of CONTROLLERAXISMOTION:
      this.handleControllerAxisEvent(event.caxis)

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

proc getControllerButtonState*(this: InputHandler, button: ControllerButton): ButtonState =
  if not this.controller.buttons.hasKey(button):
    this.controller.buttons[button] = ButtonState()
  return this.controller.buttons[button]

template isControllerButtonPressed*(this: InputHandler, button: ControllerButton): bool =
  this.getControllerButtonState(button).pressed

template wasControllerButtonJustPressed*(this: InputHandler, button: ControllerButton): bool =
  this.getControllerButtonState(button).justPressed

template wasControllerButtonJustReleased*(this: InputHandler, button: ControllerButton): bool =
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

