import
  std/monotimes,
  sdl2_nim/sdl,
  sdl2_nim/sdl_gpu

import
  refresh_rate_calculator as refresh_rate_calculator_module,
  scene,
  gamestate,
  ../input/inputhandler,
  ../audio/audioplayer,
  ../render/color,
  ../ui/ui

const ONE_BILLION = 1000000000

type
  Engine* = ref object of RootObj
    screen*: Target
    scene: Scene
    ui: UI
    # The color to fill the screen with to clear it every frame.
    clearColor*: Color
    shouldExit: bool
    refreshRate: int
    # Use fixed rate delta times
    useFixedDeltaTime*: bool

proc detectWindowScaling(this: Engine): Vector
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
  windowFlags: int = WINDOW_ALLOW_HIGHDPI and int(INIT_ENABLE_VSYNC),
  clearColor: Color = BLACK,
  useFixedDeltaTime: bool = true,
  iconFilename: string = ""
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

  var refreshRate = 0

  if target.context != nil:
    let window = getWindowFromId(target.context.windowID)
    window.setWindowTitle(title)
    var displayMode: DisplayMode
    discard window.getWindowDisplayMode(displayMode.addr)
    refreshRate = displayMode.refreshRate
    if iconFilename.len > 0:
      let iconSurface = loadSurface(iconFilename)
      window.setWindowIcon(iconSurface)
      freeSurface(iconSurface)

  Game = Engine()
  Game.screen = target
  Game.scene = scene
  Game.clearColor = clearColor
  Game.refreshRate = refreshRate
  Game.useFixedDeltaTime = useFixedDeltaTime

  gamestate.updateResolution(gameWidth.float, gameHeight.float)

  initInputHandlerSingleton(Game.detectWindowScaling())
  initAudioPlayerSingleton()

  gamestate.onResolutionChanged:
    # Returns false if there's no renderer or window size is 0. Don't care about the result.
    discard setWindowResolution(uint16 gamestate.resolution.x, uint16 gamestate.resolution.y)

  # Input event handlers

  proc handleWindowEvents(e: Event): bool =
    if e.window.event == WINDOWEVENT_RESIZED or e.window.event == WINDOWEVENT_SIZE_CHANGED:
      gamestate.updateResolution(float e.window.data1, float e.window.data2)
      Input.windowScaling = Game.detectWindowScaling()

  Input.addListener(WINDOWEVENT, handleWindowEvents)
  Input.addListener(QUIT,
    proc(e: Event): bool =
      Game.shouldExit = true
  )

  # Configure inputs for UI
  Input.onEvent(MOUSEBUTTONDOWN):
    Game.ui.handlePress(float e.button.x, float e.button.y)
  Input.onEvent(FINGERDOWN):
    Game.ui.handlePress(float e.tfinger.x, float e.tfinger.y)

template screen*(this: Engine): Target =
  this.screen

template scene*(this: Engine): Scene =
  this.scene

template `scene=`*(this: Engine, scene: Scene) =
  this.scene = scene

proc detectWindowScaling(this: Engine): Vector =
  result = VECTOR_ONE
  if this.screen.context != nil:
    # Get "real" size in pixels
    var vwidth: uint16
    var vheight: uint16
    this.screen.getVirtualResolution(vwidth.addr, vheight.addr)
    if vwidth > 0 and vheight > 0:
      # Get the window size (in potentially scaled pixels)
      var windowWidth: cint
      var windowHeight: cint
      let window = getWindowFromId(this.screen.context.windowID)
      window.getWindowSize(windowWidth.addr, windowHeight.addr)
      if windowWidth > 0 and windowHeight > 0:
        # Calculate scaling
        result = vector(
          float(vwidth) / float(windowWidth),
          float(vheight) / float(windowHeight)
        )

proc handleEvents(this: Engine) =
  ## Passes all pending events to the inputhandler singleton.
  ## Returns if the application should exit.
  var event: Event
  while pollEvent(event.addr) != 0:
    Input.processEvent(event)

proc loop(this: Engine) =
  var
    previousTimeNanos: int64 = getMonoTime().ticks
    deltaTime: float = 0
    refreshRateCalculator: RefreshRateCalculator

  while not this.shouldExit:
    this.handleEvents()
    this.update(deltaTime)
    this.render(this.screen)
    Input.resetFrameSpecificState()
    flip(this.screen)

    let time = getMonoTime().ticks
    let elapsedNanos = time - previousTimeNanos
    previousTimeNanos = time

    if this.useFixedDeltaTime:
      if this.refreshRate > 0:
        deltaTime = 1.0 / float(this.refreshRate)
      else:
        if refreshRateCalculator == nil:
          refreshRateCalculator = RefreshRateCalculator()

        refreshRateCalculator.calcRefreshRate(elapsedNanos)

        if refreshRateCalculator.refreshRate > 0:
          this.refreshRate = refreshRateCalculator.refreshRate
          refreshRateCalculator = nil
        else:
          deltaTime = float(elapsedNanos) / float(ONE_BILLION)

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

proc getUIRoot*(this: Engine): UIComponent =
  return this.ui.getUIRoot()

proc setUIRoot*(this: Engine, root: UIComponent) =
  this.ui.setUIRoot(root)

proc update*(this: Engine, deltaTime: float) =
  gamestate.runTime += deltaTime
  if this.scene != nil:
    this.scene.update(deltaTime)

proc render*(this: Engine, screen: Target) =
  if this.scene == nil:
    return

  clearColor(this.screen, this.clearColor)

  # Save the normal matrix
  pushMatrix()

  this.scene.render(screen)

  this.ui.layout(gamestate.resolution.x, gamestate.resolution.y)
  this.ui.render(screen)

  # Restore normal matrix
  popMatrix()
