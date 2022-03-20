import tables

import
  ../binarytree,
  ../aabb,
  ../vector2

import ../../game/physicsbody

type TreeNode[T: Boundable] = ref object
  aabb: AABB
  # Object that owns the AABB
  obj: T

  parentNode: TreeNode[T]
  leftNode: TreeNode[T]
  rightNode: TreeNode[T]

proc newTreeNode[T: Boundable](
  aabb: AABB,
  obj: T = nil,
  parentNode, leftNode, rightNode: TreeNode[T] = nil
): TreeNode[T] =
  result = TreeNode[T](
    aabb: aabb,
    obj: obj,
    parentNode: parentNode,
    leftNode: leftNode,
    rightNode: rightNode
  )

template isLeaf(n: TreeNode): bool =
  n.leftNode == nil

# TREE

type AABBTree*[T: Boundable] = ref object
  rootNode: TreeNode[T]
  objToNodeMap: Table[T, TreeNode[T]]

proc newAABBTree*[T: Boundable](): AABBTree[T] =
  result = AABBTree[T]()

proc addObject*[T: Boundable](this: AABBTree[T], obj: T) =
  let objAABB = obj.getBounds()

  if this.rootNode == nil:
    this.rootNode = newTreeNode[T](objAABB, obj)
    this.objToNodeMap[obj] = this.rootNode
    return
  
  var
    currentNode = this.rootNode
    newAABB = this.rootNode.aabb

  while not currentNode.isLeaf():
    let
      leftNode = currentNode.leftNode
      rightNode = currentNode.rightNode
      newNodeAABB = createBoundsAround(currentNode.aabb, objAABB)
      newLeftNodeAABB = createBoundsAround(leftNode.aabb, objAABB)
      newRightNodeAABB = createBoundsAround(rightNode.aabb, objAABB)

    let volumeDiff = newNodeAABB.getArea() - currentNode.aabb.getArea()
    if volumeDiff > 0:
      var leftCost, rightCost: float

      if leftNode.isLeaf():
        leftCost = newLeftNodeAABB.getArea() + volumeDiff
      else:
        leftCost = newLeftNodeAABB.getArea() - leftNode.aabb.getArea() + volumeDiff

      if rightNode.isLeaf():
        rightCost = newRightNodeAABB.getArea() + volumeDiff
      else:
        rightCost = newRightNodeAABB.getArea() - rightNode.aabb.getArea() + volumeDiff

      if newNodeAABB.getArea() < leftCost * 1.3 and newNodeAABB.getArea() < rightCost * 1.3:
        break

      currentNode.aabb = newNodeAABB

      if leftCost > rightCost:
        currentNode = rightNode
        newAABB = newRightNodeAABB
      else:
        currentNode = leftNode
        newAABB = newLeftNodeAABB

      # Continue looping if volumeDiff is > 0
      continue

    currentNode.aabb = newNodeAABB

    let
      leftVolumeIncrease = newLeftNodeAABB.getArea() - leftNode.aabb.getArea()
      rightVolumeIncrease = newRightNodeAABB.getArea() - rightNode.aabb.getArea()

    if leftVolumeIncrease > rightVolumeIncrease:
      currentNode = rightNode
      newAABB = newRightNodeAABB
    else:
      currentNode = leftNode
      newAABB = newLeftNodeAABB

  let newChild = newTreeNode[T](
    currentNode.aabb,
    currentNode.obj,
    currentNode,
    currentNode.leftNode,
    currentNode.rightNode
  )
  
  if newChild.obj != nil:
    this.objToNodeMap[newChild.obj] = newChild

  currentNode.leftNode = newChild
  currentNode.rightNode = newTreeNode[T](objAABB, obj, currentNode, nil, nil)
  currentNode.obj = nil
  currentNode.aabb =
    if currentNode == this.rootNode:
      createBoundsAround(this.rootNode.aabb, objAABB)
    else:
      newAABB

  this.objToNodeMap[obj] = currentNode.rightNode

proc removeObject*[T: Boundable](this: AABBTree[T], obj: T) =
  var node: TreeNode[T]
  if this.objToNodeMap.pop(obj, node):
    this.removeNode(node)

proc findOverlappingObjects*[T: Boundable](this: AABBTree[T], aabb: AABB): seq[T] =
  if this.rootNode == nil:
    return

  var
    index = 0
    nodesToCheck = @[this.rootNode]

  while nodesToCheck.len > index:
    let
      leftNode = nodesToCheck[index].leftNode
      rightNode = nodesToCheck[index].rightNode

    # TODO: Move this out of the loop so we don't have to check every iteration
    if nodesToCheck[index] == this.rootNode and
       this.rootNode.obj != nil and
       this.rootNode.aabb.intersects(aabb):
         result.add(this.rootNode.obj)

    if leftNode != nil and leftNode.aabb.intersects(aabb):
      if not leftNode.isLeaf():
        nodesToCheck.add(leftNode)
      else:
        result.add(leftNode.obj)

    if rightNode != nil and rightNode.aabb.intersects(aabb):
      if not rightNode.isLeaf():
        nodesToCheck.add(rightNode)
      else:
        result.add(rightNode.obj)

    index += 1

proc removeNode*[T: Boundable](this: AABBTree[T], node: TreeNode[T]) =
  if node.parentNode == nil:
    this.rootNode = nil
    return

  let
    parentNode = node.parentNode
    sibling =
      if parentNode.leftNode == node:
        parentNode.rightNode
      else:
        parentNode.leftNode

  parentNode.aabb = sibling.aabb
  parentNode.obj = sibling.obj
  parentNode.leftNode = sibling.leftNode
  parentNode.rightNode = sibling.rightNode

  if not sibling.isLeaf():
    sibling.leftNode.parentNode = parentNode
    sibling.rightNode.parentNode = parentNode

  if this.objToNodeMap.hasKey(parentNode.obj):
    this.objToNodeMap[parentNode.obj] = parentNode

  var currentNode = parentNode.parentNode
  while currentNode != nil:
    currentNode.aabb = createBoundsAround(currentNode.leftNode.aabb, currentNode.rightNode.aabb)
    currentNode = currentNode.parentNode

proc render*(this: AABBTree, ctx: Target) =
  for node in this.objToNodeMap.values():
    node.aabb.stroke(ctx)

