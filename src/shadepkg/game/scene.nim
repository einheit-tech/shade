import algorithm

import
  layer,
  node,
  constants,
  gamestate,
  camera

export
  layer,
  node

type Scene* = ref object of Node
  layers: seq[Layer]
  isLayerOrderValid: bool
  camera: Camera

proc initScene*(scene: Scene) =
  initNode(Node(scene), {loUpdate, loRender})
  scene.isLayerOrderValid = true

proc newScene*(): Scene = 
  result = Scene()
  initScene(result)

proc `camera=`*(this: Scene, camera: Camera) =
  if this.camera != nil:
    this.removeChild(this.camera)

  this.camera = camera
  this.addChild(this.camera)

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

method update*(this: Scene, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.sortLayers()
  this.forEachLayer(layer):
    layer.update(deltaTime)

proc renderWithCamera(this: Scene, ctx: Target) =
  # Subtract half the screen resolution to center the camera.
  var
    relativeZ: float
    inversedScalar: float

  this.forEachLayer(l):
    relativeZ = l.z - this.camera.z
    if relativeZ > 0:

      inversedScalar = 1.0 / relativeZ
      let halfViewportSize = dvec2(this.camera.viewport.width, this.camera.viewport.height) * meterToPixelScalar * 0.5
      let trans = (this.camera.center * meterToPixelScalar) * inversedScalar - halfViewportSize
      translate(
        -trans.x,
        -trans.y,
        0
      )

      scale(inversedScalar, inversedScalar, 1.0)

      l.render(ctx)

      scale(relativeZ, relativeZ, 1.0)
      translate(
        trans.x,
        trans.y,
        0
      )

render(Scene, Node):
  this.sortLayers()
  if this.camera != nil:
    this.renderWithCamera(ctx)
  else:
    this.forEachLayer(l):
      l.render(ctx)

  if callback != nil:
    callback()

