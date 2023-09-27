import algorithm
import ../render/render

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

proc sortLayers(this: Scene) =
  if not this.isLayerOrderValid:
    this.layers = this.layers.sortedByIt(it.z)

proc update*(this: Scene, deltaTime: float) =
  if this.camera != nil:
    this.camera.update(deltaTime)

  this.sortLayers()
  for layer in this.layers:
    layer.update(deltaTime)

proc renderLayer*(ctx: Target, camera: Camera, layer: Layer) =
  let relativeZ = layer.z - camera.z
  if relativeZ > 0:
    let inversedScalar = 1.0 / relativeZ
    let halfViewportSize = camera.viewport.getSize() * 0.5

    # Subtract half the viewport to center the camera.
    let trans = camera.getLocation() - halfViewportSize * relativeZ
    scale(inversedScalar, inversedScalar, 1.0)
    layer.render(ctx, -trans.x, -trans.y)
    scale(relativeZ, relativeZ, 1.0)

proc renderLayers*(ctx: Target, camera: Camera, layers: seq[Layer]) =
  for layer in layers:
    ctx.renderLayer(camera, layer)

proc render*(this: Scene, ctx: Target) =
  this.sortLayers()
  if this.camera != nil:
    ctx.renderLayers(this.camera, this.layers)
  else:
    for layer in this.layers:
      layer.render(ctx)

