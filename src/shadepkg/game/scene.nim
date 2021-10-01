import algorithm

import
  layer,
  entity

export
  layer,
  entity

type Scene* = ref object of Node
  layers: seq[Layer]
  isLayerOrderValid: bool

proc initScene*(scene: Scene) =
  initNode(Node(scene), {loUpdate, loRender})
  scene.isLayerOrderValid = true

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
    # this.layers = this.layers.sortedByIt(it.z)
    this.layers.sort[:Layer](
      proc (x, y: Layer): int {.closure.} = (x.z - y.z).int,
      SortOrder.Descending
    )

method update*(this: Scene, deltaTime: float) =
  procCall Node(this).update(deltaTime)
  this.sortLayers()
  this.forEachLayer(layer):
    layer.update(deltaTime)

render(Scene, Node):
  this.sortLayers()
  this.forEachLayer(layer):
    layer.render(ctx)

