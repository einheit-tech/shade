import ../render/render

type
  ## Flags indicating how the object should be treated.
  NodeFlags* = uint8

  Node* = ref object of RootObj
    flags*: NodeFlags
    # Invoked after this node has been updated.
    onUpdate*: proc(this: Node, deltaTime: float)

const
  DEAD* =  0b0001'u8
  UPDATE* = 0b0010'u8
  RENDER* = 0b0100'u8
  UPDATE_AND_RENDER*: NodeFlags = UPDATE or RENDER

proc initNode*(node: Node, flags: NodeFlags = UPDATE_AND_RENDER) =
  node.flags = flags

proc newNode*(flags: NodeFlags = UPDATE_AND_RENDER): Node =
  result = Node()
  initNode(result, flags)

template isAlive*(this: Node): bool =
  (this.flags and DEAD) == not DEAD

template isDead*(this: Node): bool =
  (this.flags and DEAD) == DEAD

template shouldUpdate*(this: Node): bool =
  (this.flags and UPDATE) == UPDATE

template shouldRender*(this: Node): bool =
  (this.flags and RENDER) == RENDER

method update*(this: Node, deltaTime: float) {.base.} =
  if this.onUpdate != nil:
    this.onUpdate(this, deltaTime)

Node.renderAsParent:
  discard

