import
  std/monotimes,
  os,
  math,
  pixie,
  sdl2_nim/sdl

import
  scene,
  ../input/inputhandler,
  ../audio/audioplayer

const
  # TODO: Get hz of monitor or allow this to be configurable.
  fps = 60
  oneBillion = 1000000000
  oneMillion = 1000000
  sleepNanos = round(oneBillion / fps).int

const
  rmask = uint32 0x000000ff
  gmask = uint32 0x0000ff00
  bmask = uint32 0x00ff0000
  amask = uint32 0xff000000

var
  surface: Surface
  texture: Texture

type 
  Game* = ref object of RootObj
    shouldExit: bool
    window*: Window
    renderer: Renderer
    texture: Texture

    gameWidth: int
    gameHeight: int
    scene: Scene
    ctx: Context
    bgColor: ColorRGBX

method update*(this: Game, deltaTime: float) {.base.}
method render*(this: Game, ctx: Context) {.base.}
method stop*(this: Game) {.base.}
method teardown*(this: Game) {.base.}

proc initGame*(
  game: var Game,
  title: string,
  gameWidth, gameHeight: int,
  scene: Scene = newScene(),
  bgColor: ColorRGBX = rgba(0, 0, 0, 255),
  windowFlags: int = WINDOW_FULLSCREEN_DESKTOP,
  renderFlags: int = RendererAccelerated and RENDERER_PRESENTVSYNC
) =
  if sdl.init(INIT_EVERYTHING) != 0:
    discard

  let screen = newImage(gameWidth, gameHeight)
  game.ctx = newContext(screen)
  game.scene = scene
  game.gameWidth = gameWidth
  game.gameHeight = gameHeight
  game.bgColor = bgColor

  game.window = createWindow(
    title,
    0,
    0,
    cint game.gameWidth,
    cint game.gameHeight,
    uint32 windowFlags
  )
  game.renderer = createRenderer(game.window, -1, uint32 renderFlags)
  initInputHandlerSingleton(game.window)
  initAudioPlayerSingleton()

proc newGame*(
  title: string,
  gameWidth, gameHeight: int,
  scene: Scene = newScene(),
  bgColor: ColorRGBX = rgba(0, 0, 0, 255),
  windowFlags: int = WINDOW_FULLSCREEN_DESKTOP,
  renderFlags: int = RendererAccelerated and RENDERER_PRESENTVSYNC
): Game =
  result = Game()
  initGame(
    result,
    title,
    gameWidth,
    gameHeight,
    scene,
    bgColor,
    windowFlags,
    renderFlags
  )

template ctx*(this: Game): Context = this.ctx
template scene*(this: Game): Scene = this.scene
template `scene=`*(this: Game, scene: Scene) = this.scene = scene

proc handleEvents(this: Game): bool =
  ## Passes all pending events to the inputhandler singleton.
  ## Returns if the application should exit.
  var event: Event
  while pollEvent(event.addr) != 0:
    if Input.processEvent(event):
      return true
  return false
    
proc loop(this: Game) =
  var
    startTimeNanos = getMonoTime().ticks
    elapsedNanos: int64 = 0

  while not this.shouldExit:
    # Determine elapsed time in seconds
    let deltaTime: float = elapsedNanos.float64 / oneBillion.float64

    this.shouldExit = this.handleEvents()
    this.update(deltaTime)
    this.render(this.ctx)

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

proc start*(this: Game) =
  # TODO: Make this async so it's non-blocking
  this.loop()

method stop*(this: Game) {.base.} =
  this.shouldExit = true

method teardown*(this: Game) {.base.} =
  this.renderer.destroyRenderer()
  this.window.destroyWindow()
  logInfo(sdl.LogCategoryApplication, "SDL shutdown completed")
  sdl.quit()

method update*(this: Game, deltaTime: float) {.base.} =
  if this.scene != nil:
    this.scene.update(deltaTime)

method render(this: Game, ctx: Context) {.base.} =
  if this.scene == nil:
    return

  ctx.image.fill(this.bgColor)
  this.scene.render(ctx)

  when defined(inputdebug):
    renderInputInfo(ctx)

  # Render data to sdl renderer
  var dataPtr = ctx.image.data[0].addr
  surface = createRGBSurfaceFrom(
    dataPtr,
    cint this.gameWidth,
    cint this.gameHeight,
    cint 32,
    cint 4 * this.gameWidth,
    rmask,
    gmask,
    bmask,
    amask
  )
  texture = this.renderer.createTextureFromSurface(surface)
  sdl.freeSurface(surface)
  discard this.renderer.renderCopy(texture, nil, nil)
  sdl.destroyTexture(texture)

  # Actual screen rendering
  this.renderer.renderPresent()

