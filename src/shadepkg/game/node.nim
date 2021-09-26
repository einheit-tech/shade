import
  pixie,
  render,
  hashes

export 
  pixie,
  render,
  hashes

type 
  ## Flags indicating how the object should be treated by a layer.
  LayerObjectFlags* = enum
    loUpdate
    loRender
    loPhysics

  Node* = ref object of RootObj
    flags*: set[LayerObjectFlags]

proc initNode*(node: Node, flags: set[LayerObjectFlags]) =
  node.flags = flags

proc newNode*(flags: set[LayerObjectFlags]): Node =
  result = Node()
  initNode(result, flags)

method hash*(this: Node): Hash {.base.} =
  return hash(this[].unsafeAddr)

method update*(this: Node, deltaTime: float) {.base.} =
  discard

method render*(this: Node, ctx: Context, callback: proc() = nil) {.base.} =
  if callback != nil:
    callback()

