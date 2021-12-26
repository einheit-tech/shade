import
  std/monotimes,
  os,
  math,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  scene,
  constants,
  gamestate,
  ../input/inputhandler,
  ../audio/audioplayer,
  ../render/color

const
  # TODO: Get hz of monitor or allow this to be configurable.
  fps = 60
  oneBillion = 1000000000
  oneMillion = 1000000
  sleepNanos = round(oneBillion / fps).int

type 
  Engine* = ref object of RootObj
    shouldExit: bool
    screen: Target

    scene: Scene

    # The color to fill the screen with to clear it every frame.
    clearColor: Color

proc update*(this: Engine, deltaTime: float)
proc render*(this: Engine, screen: Target)
proc stop*(this: Engine)
proc teardown(this: Engine)

# Singleton
var Game*: Engine

proc initEngineSingleton*(
  title: string,
  gameWidth, gameHeight: int,
  scene: Scene = newScene(),
  windowFlags: int = WINDOW_FULLSCREEN_DESKTOP or WINDOW_ALLOW_HIGHDPI,
  clearColor: Color = BLACK
) =
  if Game != nil:
    raise newException(Exception, "Game has already been initialized!")

  when defined(debug):
    setDebugLevel(DEBUG_LEVEL_MAX)

  let target = init(uint16 gameWidth, uint16 gameHeight, uint32 windowFlags)
  if target == nil:
    raise newException(Exception, "Failed to init SDL!")

  Game = Engine()
  Game.screen = target
  Game.scene = scene
  Game.clearColor = clearColor

  gamestate.resolutionPixels = vector(gameWidth.float, gameHeight.float)
  gamestate.resolutionMeters = gamestate.resolutionPixels * pixelToMeterScalar

  initInputHandlerSingleton()
  initAudioPlayerSingleton()

template time*(this: Engine): float = this.time
template screen*(this: Engine): Target = this.screen
template scene*(this: Engine): Scene = this.scene
template `scene=`*(this: Engine, scene: Scene) = this.scene = scene

proc handleEvents(this: Engine): bool =
  ## Passes all pending events to the inputhandler singleton.
  ## Returns if the application should exit.
  var event: Event
  while pollEvent(event.addr) != 0:
    if Input.processEvent(event):
      return true
  return false
    
proc loop(this: Engine) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while not this.shouldExit:
    # Determine elapsed time in seconds

    let deltaTime: float = elapsedNanos.float64 / oneBillion.float64

    this.shouldExit = this.handleEvents()
    this.update(deltaTime)
    this.render(this.screen)

    Input.update(deltaTime)

    # Calculate sleep time
    elapsedNanos = getMonoTime().ticks - startTimeNanos
    let sleepMilis =
      round(max(0, sleepNanos - elapsedNanos).float64 / oneMillion.float64).int
    sleep(sleepMilis)

    let time = getMonoTime().ticks
    elapsedNanos = time - startTimeNanos
    startTimeNanos = time

  this.teardown()

proc start*(this: Engine) =
  # TODO: Make this async so it's non-blocking
  this.loop()

proc stop*(this: Engine) =
  this.shouldExit = true

proc teardown(this: Engine) =
  sdl_gpu.quit()
  logInfo(LogCategoryApplication, "SDL shutdown completed")

proc update*(this: Engine, deltaTime: float) =
  gamestate.time += deltaTime
  if this.scene != nil:
    this.scene.update(deltaTime)

proc render*(this: Engine, screen: Target) =
  if this.scene == nil:
    return

  clearColor(this.screen, this.clearColor)

  this.scene.render(screen)

  flip(this.screen)

