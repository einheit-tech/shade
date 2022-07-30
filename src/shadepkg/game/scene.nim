import algorithm

import
  layer,
  camera,
  gamestate

export layer

type Scene* = ref object
  layers: seq[Layer]
  isLayerOrderValid: bool
  camera*: Camera

proc initScene*(scene: Scene) =
  scene.isLayerOrderValid = true
  gamestate.onResolutionChanged:
    if scene.camera != nil:
      scene.camera.updateViewport()

proc newScene*(): Scene = 
  result = Scene()
  initScene(result)

proc invalidateLayerOrder(this: Scene) =
  this.isLayerOrderValid = false

proc addLayer*(this: Scene, layer: Layer) =
  this.layers.add(layer)
  layer.addZChangeListener(proc(oldZ, newZ: float) = this.invalidateLayerOrder())

template forEachLayer*(this: Scene, layer, body) =
  for l in this.layers:
    var layer: Layer = l
    body

proc sortLayers(this: Scene) =
  if not this.isLayerOrderValid:
    this.layers = this.layers.sortedByIt(it.z)

proc update*(this: Scene, deltaTime: float) =
  if this.camera != nil:
    this.camera.update(deltaTime)

  this.sortLayers()
  this.forEachLayer(layer):
    layer.update(deltaTime)

proc renderWithCamera(this: Scene, ctx: Target) =
  # Subtract half the viewport to center the camera.
  var
    relativeZ: float
    inversedScalar: float

  this.forEachLayer(l):
    relativeZ = l.z - this.camera.z
    if relativeZ > 0:
      inversedScalar = 1.0 / relativeZ
      let halfViewportSize = this.camera.viewport.getSize() * 0.5

      let trans = this.camera.getLocation() - halfViewportSize * relativeZ
      scale(inversedScalar, inversedScalar, 1.0)
      l.render(ctx, -trans.x, -trans.y)
      scale(relativeZ, relativeZ, 1.0)

proc render*(this: Scene, ctx: Target) =
  this.sortLayers()
  if this.camera != nil:
    this.renderWithCamera(ctx)
  else:
    this.forEachLayer(l):
      l.render(ctx)

