import
  std/algorithm,
  std/monotimes,
  os,
  math,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  scene,
  gamestate,
  ../input/inputhandler,
  ../audio/audioplayer,
  ../render/color

const
  oneBillion = 1000000000
  oneMillion = 1000000

type
  Engine* = ref object of RootObj
    screen*: Target
    scene: Scene
    hud*: Layer
    # The color to fill the screen with to clear it every frame.
    clearColor*: Color
    shouldExit: bool
    # Delta smoothing: measure average delta time and discard outliers to avoid physics stutters
    deltaSmoothing: int

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
  fullscreen: bool = false,
  windowFlags: int = WINDOW_ALLOW_HIGHDPI or int(INIT_ENABLE_VSYNC),
  clearColor: Color = BLACK
) =
  if Game != nil:
    raise newException(Exception, "Game has already been initialized!")

  when defined(debug):
    setDebugLevel(DEBUG_LEVEL_MAX)

  # Squeeze in fullscreen flags if requested.
  let windowFlags =
    if fullscreen:
      windowFlags or WINDOW_FULLSCREEN_DESKTOP
    else:
      windowFlags

  let target = init(uint16 gameWidth, uint16 gameHeight, uint32 windowFlags)
  if target == nil:
    raise newException(Exception, "Failed to init SDL!")

  Game = Engine()
  Game.screen = target
  Game.scene = scene
  Game.clearColor = clearColor

  gamestate.updateResolution(gameWidth.float, gameHeight.float)

  initInputHandlerSingleton()
  initAudioPlayerSingleton()

  gamestate.onResolutionChanged:
    # Returns false if there's no renderer or window size is 0. Don't care about the result.
    discard setWindowResolution(uint16 gamestate.resolution.x, uint16 gamestate.resolution.y)

  # Input event handlers

  proc handleWindowEvents(e: Event): bool =
    if e.window.event == WINDOWEVENT_RESIZED:
      gamestate.updateResolution(float e.window.data1, float e.window.data2)

  Input.addEventListener(WINDOWEVENT, handleWindowEvents)
  Input.addEventListener(QUIT,
    proc(e: Event): bool =
      Game.shouldExit = true
  )

template time*(this: Engine): float = this.time
template screen*(this: Engine): Target = this.screen
template scene*(this: Engine): Scene = this.scene
template `scene=`*(this: Engine, scene: Scene) = this.scene = scene

proc setDeltaSmoothing*(this: Engine, deltaSmoothing: int) =
  this.deltaSmoothing = max(0, deltaSmoothing)

proc median(l, r: int): int =
  return l + ((r - l) div 2)

proc q13(values: seq[float]): tuple[q1: float, q3: float] =
  let sortedValues = sorted(values)
  let n = len(sortedValues)
  let mid = median(0, n)
  let q1 = sortedValues[median(0, mid)]
  let q3 = sortedValues[median(mid + 1, n)]
  return (q1, q3)

proc iqr(q13: tuple[q1: float, q3: float]): float =
  return q13.q3 - q13.q1

proc outlier(value: float, q13: tuple[q1: float, q3: float]): bool =
  let i = 1.5 * iqr(q13)
  let lower = q13.q1 - i
  let upper = q13.q3 + i
  return value < lower or value > upper

proc handleEvents(this: Engine) =
  ## Passes all pending events to the inputhandler singleton.
  ## Returns if the application should exit.
  var event: Event
  while pollEvent(event.addr) != 0:
    Input.processEvent(event)

proc loop(this: Engine) =
  var
    startTimeNanos: int64 = getMonoTime().ticks
    previousTimeNanos: int64 = startTimeNanos
    deltaTime: float = 0
    deltaSmoothing: int = this.deltaSmoothing
    deltaWindow: seq[float] = newSeqOfCap[float](deltaSmoothing)
    refreshRate: int = -1

  while not this.shouldExit:
    this.handleEvents()
    this.update(deltaTime)
    this.render(this.screen)
    Input.update(deltaTime)
    flip(this.screen)

    let time = getMonoTime().ticks
    let elapsedNanos = time - previousTimeNanos
    previousTimeNanos = time

    let realDeltaTime = float(elapsedNanos) / float(oneBillion)
    deltaTime = realDeltaTime

    if refreshRate == -1:
      # Process delta smoothing
      if this.deltaSmoothing != 0:
        # Detect if delta window needs to change size
        if this.deltaSmoothing != deltaSmoothing:
          deltaSmoothing = this.deltaSmoothing
          deltaWindow = newSeqOfCap[float](deltaSmoothing)
        # Push new sample
        deltaWindow.add(realDeltaTime)
        # Only start using delta window after it's filled up
        if len(deltaWindow) == deltaSmoothing:
          # Prune outliers
          var newDeltaWindow: seq[float] = newSeqOfCap[float](deltaSmoothing)
          let deltaWindowQ13 = q13(deltaWindow)
          var foundOutlier = false
          for sample in deltaWindow:
            if outlier(sample, deltaWindowQ13):
              foundOutlier = true
            else:
              newDeltaWindow.add(sample)
          deltaWindow = newDeltaWindow
          if not foundOutlier:
            # Calculate average elapsed time over the window
            let deltaSmoothingFloat = float(deltaSmoothing)
            var avg: float = 0.0
            for sample in deltaWindow:
              avg += sample / deltaSmoothingFloat
            # Convert into integer refresh rate
            refreshRate = int round(1.0 / avg)
    else:
      # Use refresh rate to override "real" delta time
      deltaTime = 1.0 / float(refreshRate)

  this.teardown()

proc start*(this: Engine) =
  # TODO: Make this async so it's non-blocking
  this.loop()

proc stop*(this: Engine) =
  this.shouldExit = true

proc teardown(this: Engine) =
  # TODO: Should tear down the running scene here
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

  # Save the normal matrix
  pushMatrix()

  this.scene.render(screen)
  if this.hud != nil:
    this.hud.render(screen)

  # Restore normal matrix
  popMatrix()
