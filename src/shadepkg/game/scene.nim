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
    this.layers = this.layers.sortedByIt(it.z)

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
  this.camera.renderInViewportSpace:
    this.renderLayers(ctx, callback)
    if callback != nil:
      callback()

render(Scene, Node):
  this.sortLayers()
  if this.camera != nil:
    this.renderWithCamera(ctx, callback)
  else:
    this.renderLayers(ctx, callback)

