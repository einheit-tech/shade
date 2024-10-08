import 
  std/[tables]

import
  sdl2_nim/sdl,
  safeseq

import ../math/[mathutils, vector2]
export mathutils, vector2

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
    PRESSED
    RELEASED

  KeyAction* {.pure.} = ButtonAction

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
    LEFT = CONTROLLER_AXIS_TRIGGERLEFT,
    RIGHT = CONTROLLER_AXIS_TRIGGERRIGHT

  Mouse* = ref object
    location: Vector
    buttons: Table[int, ButtonState]
    vScrolled: int
    buttonListeners: seq[MouseButtonEventListener]

  KeyState* = InputState
  KeyListener* = proc(key: Keycode, state: KeyState)
  Keyboard* = ref object
    keys: Table[Keycode, KeyState]
    eventListeners: SafeSeq[KeyListener]

  ControllerStickState* = object
    x*: float
    y*: float

  ControllerTriggerState* = object
    value*: CompletionRatio

  ControllerStickEventCallback* = proc(state: ControllerStickState)
  ControllerStickEventFilter* = proc(state: ControllerStickState): bool
  ControllerStickEventListener* = object
    filter: ControllerStickEventFilter
    callback: ControllerStickEventCallback

  ControllerButtonState* = InputState

  ControllerTriggerEventCallback* = proc(value: CompletionRatio)
  ControllerTriggerEventListener* = object
    triggerThreshhold: CompletionRatio
    callback: ControllerTriggerEventCallback

  Controller* = ref object
    # NOTE: Will add support for multiple controllers, touchpads, etc. later when needed.
    sdlGameController: GameController
    ## Deadzone applied to all controller axis inputs (analog sticks and triggers).
    deadzoneRadius*: float
    name: string

    leftStick: ControllerStickState
    rightStick: ControllerStickState
    rightStickListeners: seq[ControllerStickEventListener]
    leftStickListeners: seq[ControllerStickEventListener]

    leftTrigger: ControllerTriggerState
    rightTrigger: ControllerTriggerState
    rightTriggerListeners: seq[ControllerTriggerEventListener]
    leftTriggerListeners: seq[ControllerTriggerEventListener]

    buttons: Table[ControllerButton, ButtonState]
    buttonListeners: Table[ControllerButton, SafeSeq[ControllerButtonEventListener]]

  EventListener* = proc(e: Event): bool
  ## Return true to remove the listener from the InputHandler.
  InputHandler* = ref object
    eventListeners: Table[EventKind, SafeSeq[EventListener]]

    customActions: Table[string, ptr InputState]

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
    keyboard: Keyboard(eventListeners: newSafeSeq[KeyListener]()),
    controller: Controller(deadzoneRadius: DEFAULT_DEADZONE),
    windowScaling: windowScaling,
    customActions: initTable[string, ptr InputState]()
  )

  # TODO: Put this back in when it stops lagging
  # if init(INIT_GAMECONTROLLER) != 0:
  if init(INIT_EVENTS) != 0:
    raise newException(Exception, "Unable to init controller support")

proc addListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if not this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind] = newSafeSeq[EventListener]()
  this.eventListeners[eventKind].add(listener)

template onEvent*(this: InputHandler, eventKind: EventKind, body: untyped) =
  this.addListener(eventKind, proc(e {.inject.}: Event): bool = body)

proc removeListener*(this: InputHandler, eventKind: EventKind, listener: EventListener) =
  if this.eventListeners.hasKey(eventKind):
    this.eventListeners[eventKind].remove(listener)

proc addKeyboardEventListener*(this: InputHandler, listener: KeyListener) =
  this.keyboard.eventListeners.add(listener)

proc removeKeyboardEventListener*(this: InputHandler, listener: KeyListener) =
  this.keyboard.eventListeners.remove(listener)

template onAnyKeyEvent*(this: InputHandler, body: untyped) =
  this.addKeyboardEventListener(
    proc(key {.inject.}: Keycode, state {.inject.}: KeyState) =
      if (state.justPressed or state.justReleased):
        body
  )

template onKeyEvent*(this: InputHandler, k: Keycode, body: untyped) =
  this.onAnyKeyEvent:
    if k == key:
      body

template onKeyPressed*(this: InputHandler, key: Keycode, body: untyped) =
  this.onKeyEvent(key):
    if state.justPressed:
      body

template onKeyReleased*(this: InputHandler, key: Keycode, body: untyped) =
  this.onKeyEvent(key):
    if state.justReleased:
      body

proc addMouseButtonListener*(this: InputHandler, listener: MouseButtonEventListener) =
  this.mouse.buttonListeners.add(listener)

template onMouseButtonEvent*(this: InputHandler, body: untyped) =
  this.addMouseButtonListener(
    proc(button {.inject.}: int, state {.inject.}: ButtonState, x, y, clicks {.inject.}: int) =
      body
  )

template onMouseButtonPressed*(this: InputHandler, body: untyped) =
  this.addMouseButtonListener(
    proc(button {.inject.}: int, state {.inject.}: ButtonState, x, y, clicks {.inject.}: int) =
      if state.justPressed:
        body
  )

template onMouseButtonReleased*(this: InputHandler, body: untyped) =
  this.addMouseButtonListener(
    proc(button {.inject.}: int, state {.inject.}: ButtonState, x, y, clicks {.inject.}: int) =
      if not state.justReleased:
        body
  )

proc addControllerButtonListener*(
  this: InputHandler,
  button: ControllerButton,
  listener: ControllerButtonEventListener
) =
  if not this.controller.buttonListeners.hasKey(button):
    this.controller.buttonListeners[button] = newSafeSeq[ControllerButtonEventListener]()
  this.controller.buttonListeners[button].add(listener)

template onControllerButtonEvent*(this: InputHandler, button: ControllerButton, body: untyped) =
  this.addControllerButtonListener(
    button,
    proc(button {.inject.}: ControllerButton, state {.inject.}: ButtonState) =
      body
  )

proc addControllerStickListener*(
  this: InputHandler,
  stick: ControllerStick,
  callback: ControllerStickEventCallback,
  filter: ControllerStickEventFilter = nil
) =
  let eventListener = ControllerStickEventListener(callback: callback, filter: filter)
  if stick == ControllerStick.LEFT:
    this.controller.leftStickListeners.add(eventListener)
  else:
    this.controller.rightStickListeners.add(eventListener)

proc addControllerTriggerListener*(
  this: InputHandler,
  trigger: ControllerTrigger,
  callback: ControllerTriggerEventCallback,
  triggerThreshhold: CompletionRatio = 1.0
) =
  let eventListener = ControllerTriggerEventListener(
    callback: callback,
    triggerThreshhold: triggerThreshhold
  )
  if trigger == ControllerTrigger.LEFT:
    this.controller.leftTriggerListeners.add(eventListener)
  else:
    this.controller.rightTriggerListeners.add(eventListener)

## Custom Events

proc registerCustomAction*(this: InputHandler, eventName: string) =
  this.customActions[eventName] = nil

template isCustomActionRegistered*(this: InputHandler, eventName: string): bool =
  eventName in this.customActions

proc addCustomActionTrigger*(this: InputHandler, eventName: string, key: Keycode) =
  if not this.isCustomActionRegistered(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  if key notin this.keyboard.keys:
    this.keyboard.keys[key] = KeyState()

  this.customActions[eventName] = this.keyboard.keys[key].addr

proc addCustomActionTrigger*(this: InputHandler, eventName: string, button: ControllerButton) =
  if not this.isCustomActionRegistered(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  if button notin this.controller.buttons:
    this.controller.buttons[button] = ButtonState()

  this.customActions[eventName] = this.controller.buttons[button].addr

proc addCustomActionTrigger*(this: InputHandler, eventName: string, mouseButton: MouseButton) =
  if not this.isCustomActionRegistered(eventName):
    raise newException(Exception, "Custom event " & eventName & " has not been registered")

  if (int mouseButton) notin this.mouse.buttons:
    this.mouse.buttons[int mouseButton] = ButtonState()

  this.customActions[eventName] = this.mouse.buttons[int mouseButton].addr

proc clearController(this: InputHandler) =
  this.controller.sdlGameController = nil
  this.controller.name = ""
  this.controller.leftStick = ControllerStickState()
  this.controller.rightStick = ControllerStickState()
  this.controller.leftTrigger = ControllerTriggerState()
  this.controller.rightTrigger = ControllerTriggerState()
  this.controller.buttons.clear()

proc setController(this: InputHandler, id: JoystickID) =
  let sdlGameController = gameControllerOpen(id)
  if sdlGameController != nil:
    this.controller.sdlGameController = sdlGameController
    this.controller.name = $sdlGameController.gameControllerName()
    this.controller.leftStick = ControllerStickState()
    this.controller.rightStick = ControllerStickState()
    this.controller.leftTrigger = ControllerTriggerState()
    this.controller.rightTrigger = ControllerTriggerState()
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

  for listener in this.mouse.buttonListeners:
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

  let keystate = this.keyboard.keys[keycode]
  for listener in this.keyboard.eventListeners:
    listener(keycode, keystate)

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

    if this.controller.buttonListeners.hasKey(button):
      for listener in this.controller.buttonListeners[button]:
        listener(button, buttonState)

template notifyLeftStickListeners(this: InputHandler) =
  for listener in this.controller.leftStickListeners:
    if listener.filter == nil or listener.filter(this.controller.leftStick):
      listener.callback(this.controller.leftStick)

template notifyRightStickListeners(this: InputHandler) =
  for listener in this.controller.rightStickListeners:
    if listener.filter == nil or listener.filter(this.controller.rightStick):
      listener.callback(this.controller.rightStick)

template notifyLeftTriggerListeners(this: InputHandler) =
  for listener in this.controller.leftTriggerListeners:
    if listener.triggerThreshhold <= this.controller.leftTrigger.value:
      listener.callback(this.controller.leftTrigger.value)

template notifyRightTriggerListeners(this: InputHandler) =
  for listener in this.controller.rightTriggerListeners:
    if listener.triggerThreshhold <= this.controller.rightTrigger.value:
      listener.callback(this.controller.rightTrigger.value)

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
      if value != this.controller.leftStick.x:
        this.controller.leftStick.x = value
        this.notifyLeftStickListeners()
    of CONTROLLER_AXIS_LEFTY:
      if value != this.controller.leftStick.y:
        this.controller.leftStick.y = value
        this.notifyLeftStickListeners()
    of CONTROLLER_AXIS_RIGHTX:
      if value != this.controller.rightStick.x:
        this.controller.rightStick.x = value
        this.notifyRightStickListeners()
    of CONTROLLER_AXIS_RIGHTY:
      if value != this.controller.rightStick.y:
        this.controller.rightStick.y = value
        this.notifyRightStickListeners()
    of CONTROLLER_AXIS_TRIGGERLEFT:
      if value != this.controller.leftTrigger.value:
        this.controller.leftTrigger.value = value
        this.notifyLeftTriggerListeners()
    of CONTROLLER_AXIS_TRIGGERRIGHT:
      if value != this.controller.rightTrigger.value:
        this.controller.rightTrigger.value = value
        this.notifyRightTriggerListeners()
    else:
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
  this.isMouseButtonPressed(ord MouseButton.LEFT)

template wasLeftMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(ord MouseButton.LEFT)

template wasLeftMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(ord MouseButton.LEFT)

# Right mouse button

template isRightMouseButtonPressed*(this: InputHandler): bool =
  this.isMouseButtonPressed(ord MouseButton.RIGHT)

template wasRightMouseButtonJustPressed*(this: InputHandler): bool =
  this.wasMouseButtonJustPressed(ord MouseButton.RIGHT)

template wasRightMouseButtonJustReleased*(this: InputHandler): bool =
  this.wasMouseButtonJustReleased(ord MouseButton.RIGHT)

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

# Custom Events

proc isActionPressed*(this: InputHandler, action: string): bool =
  return this.customActions[action].pressed

proc wasActionJustPressed*(this: InputHandler, action: string): bool =
  return this.customActions[action].justPressed

proc wasActionJustReleased*(this: InputHandler, action: string): bool =
  return this.customActions[action].justReleased

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

  for eventName, state in this.customActions.mpairs:
    state.justPressed = false
    state.justReleased = false

  this.mouse.vScrolled = 0

