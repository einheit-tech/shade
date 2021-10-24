import algorithm

import
  layer,
  node,
  camera,
  gamestate

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
    # TODO: Is there a performance difference?
    # Test in the future when implementing something
    # which better utilizes layers.

    this.layers = this.layers.sortedByIt(it.z)
    # this.layers.sort[:Layer](
    #   proc (x, y: Layer): int {.closure.} = (x.z - y.z).int,
    #   SortOrder.Descending
    # )

method update*(this: Scene, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.sortLayers()
  this.forEachLayer(layer):
    layer.update(deltaTime)

proc renderLayers(this: Scene, ctx: Target, callback: proc = nil) =
  this.forEachLayer(l):
    l.render(ctx)

  if callback != nil:
    callback()

proc renderWithCamera(this: Scene, ctx: Target, callback: proc = nil) =
  # Subtract half the screen resolution to center the camera.
  let translation = this.camera.center - gamestate.resolution * 0.5
  translate(-translation.x, -translation.y, 0)

  this.renderLayers(ctx, callback)

  if callback != nil:
    callback()

  translate(translation.x, translation.y, 0)

render(Scene, Node):
  this.sortLayers()

  if this.camera != nil:
    this.renderWithCamera(ctx, callback)
  else:
    this.renderLayers(ctx, callback)

