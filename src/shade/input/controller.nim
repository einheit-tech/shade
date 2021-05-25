import nico

import ../math/vector2

type
  Mouse* = ref object
    location*: Vector2
    isPressed*: bool
    justPressed*: bool

  Controller* = ref object of RootObj
    accelerating*: bool
    decelerating*: bool
    accelerateKey*: Keycode
    decelerateKey*: Keycode
    mouse*: Mouse
    debug*: bool
    debugFontScale*: Positive

proc newController*(): Controller =
  Controller(
    mouse: Mouse(),
    accelerating: false,
    accelerateKey: Keycode(K_w),
    decelerateKey: Keycode(K_s),
    debugFontScale: 1
  )

proc update*(this: Controller, deltaTime: float) =
  # Mouse Coordinates
  let mouseScreenCoords = mouse()
  let cameraLoc = getCamera()
  this.mouse.location = initVector2(
    mouseScreenCoords[0] + cameraLoc[0],
    mouseScreenCoords[1] + cameraLoc[1]
  )

  # Mouse Button
  this.mouse.isPressed = mousebtn(0)
  this.mouse.justPressed = mousebtnp(0)

  # Control Keys
  this.accelerating = key(this.accelerateKey)
  this.decelerating = key(this.decelerateKey)

proc debugPrint*(this: Controller, text: string, x: int, y: int) =
  print(
    text,
    x * this.debugFontScale.Pint,
    y * this.debugFontScale.Pint,
    this.debugFontScale.Pint
  )

proc render*(this: Controller) =
  if not this.debug:
    return

  # Mouse down
  setColor(1)
  this.debugPrint("mouse down:", 10, 20)
  if this.mouse.isPressed:
    setColor(10)
    this.debugPrint("true", 80, 20)
  else:
    setColor(2)
    this.debugPrint("false", 80, 20)

  # Mouse just down
  setColor(1)
  this.debugPrint("mouse just down:", 10, 30)
  case this.mouse.justPressed:
  of true:
    setColor(10)
    this.debugPrint("true", 80, 30)
  of false:
    setColor(2)
    this.debugPrint("false", 80, 30)

  # Mouse X Coordinate
  setColor(1)
  this.debugPrint("mouse x:", 10, 40)
  this.debugPrint($this.mouse.location.x, 80, 40)

  # Mouse Y Coordinate
  this.debugPrint("mouse y:", 10, 50)
  this.debugPrint($this.mouse.location.y, 80, 50)

  # Accelerating
  setColor(1)
  this.debugPrint("accelerating:", 10, 60)
  case this.accelerating:
  of true:
    setColor(10)
    this.debugPrint("true", 80, 60)
  of false:
    setColor(2)
    this.debugPrint("false", 80, 60)

  # Decelerating
  setColor(1)
  this.debugPrint("decelerating:", 10, 70)
  case this.decelerating:
  of true:
    setColor(10)
    this.debugPrint("true", 80, 70)
  of false:
    setColor(2)
    this.debugPrint("false", 80, 70)
