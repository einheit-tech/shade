import tables

import
  ../binarytree,
  ../rectangle,
  ../vector2,
  collisionshape

# TODO:
# See:
# https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/
# https://www.geeksforgeeks.org/level-order-tree-traversal/
# https://www.azurefromthetrenches.com/introductory-guide-to-aabb-tree-collision-detection/
# https://github.com/JamesRandall/SimpleVoxelEngine/blob/master/voxelEngine/src/AABBTree.cpp

# NODE

const AABB_NULL_NODE = int.high

type Node = ref object
  # Object that owns the AABB
  obj: CollisionShape
  aabb: Rectangle

  parentNodeIndex: Natural
  leftNodeIndex: Natural
  rightNodeIndex: Natural
  nextNodeIndex: Natural

proc newNode(): Node =
  result = Node(
    parentNodeIndex: AABB_NULL_NODE,
    leftNodeIndex: AABB_NULL_NODE,
    rightNodeIndex: AABB_NULL_NODE,
    nextNodeIndex: AABB_NULL_NODE
  )

template isLeaf(n: Node): bool =
  n.leftNodeIndex == AABB_NULL_NODE

template isBranch(n: Node): bool =
  not n.isLeaf()

# TREE

type AABBTree*[T] = ref object
  objectIndexMap: Table[T, int]
  nodes: seq[Node]
  rootNodeIndex: Natural
  allocatedNodeCount: Natural
  nextFreeNodeIndex: Natural
  # nodeCapacity: Natural
  # growthSize: Positive

proc insertLeaf(this: AABBTree, index: Natural)

proc newAABBTree*(): AABBTree =
  result = AABBTree(
    rootNodeIndex: AABB_NULL_NODE,
    nextFreeNodeIndex: 0
  )

proc allocateNode(this: AABBTree): Natural =
  ## Allocates a new node and returns its index in the tree's nodes.

  # TODO: Need grow logic?
  result = this.nextFreeNodeIndex
  let node = this.nodes[result]
  node.parentNodeIndex = AABB_NULL_NODE
  node.leftNodeIndex = AABB_NULL_NODE
  node.rightNodeIndex = AABB_NULL_NODE
  this.nextFreeNodeIndex = node.nextNodeIndex

proc deallocateNode(this: AABBTree, index: Natural) =
  let node = this.nodes[index]
  node.nextNodeIndex = this.nextFreeNodeIndex
  this.nextFreeNodeIndex = index

proc insert(this: AABBTree, shape: CollisionShape) =
  let index = this.allocateNode()
  let node = this.nodes[index]

  node.obj = shape
  node.aabb = node.obj.getBounds()

  this.insertLeaf(index)
  this.objectIndexMap[node.obj] = index

proc remove(this: AABBTree, obj: CollisionShape) =
  let index = this.objectIndexMap[obj]
  this.removeLeaf(index)
  this.deallocateNode(index)
  this.objectIndexMap.del(obj)

proc update(this: AABBTree, obj: CollisionShape) =
  let index = this.objectIndexMap[obj]
  this.updateLeaf(index, obj.getAABB())

proc queryOverlaps(this: AABBTree, obj: CollisionShape): seq[Rectangle] =
  let
    stack: seq[Natural]
    testAABB = obj.getAABB()

  stack.push(this.rootNodeIndex)
  
  while stack.len > 0:
    let index = stack.pop()
    if index == AABB_NULL_NODE:
      continue
    
    let node = this.nodes[index]
    if node.aabb.overlaps(testAABB):
      if node.isLeaf() and node.obj != obj:
        # TODO: why push_front?
        result.push(node.obj)
      else:
        stack.push(node.leftNodeIndex)
        stack.push(node.rightNodeIndex)

proc insertLeaf(this: AABBTree, index: Natural) =
  let node = this.nodes[index]

  # Must be a leaf node
  assert node.parentNodeIndex == AABB_NULL_NODE
  assert node.leftNodeIndex == AABB_NULL_NODE
  assert node.rightNodeIndex == AABB_NULL_NODE

  if this.rootNodeIndex == AABB_NULL_NODE:
    # If the tree is empty, make the root the new leaf.
    this.rootNodeIndex = index
    return
  
  # Search for the best place to insert the new leaf.
  # Using surface area and depth as search heuristics.

  let treeNodeIndex = this.rootNodeIndex

  while this.nodes[treeNodeIndex].isBranch():
    discard

proc removeLeaf(this: AABBTree, index: Natural) =
  discard

proc updateLeaf(this: AABBTree, index: Natural, newAABB: Rectangle) =
  let node = this.nodes[index]
  if node.aabb.contains(newAABB):
    return
  
  this.removeLeaf(index)
  node.aabb = newAABB
  this.insertLeaf(index)

proc fixUpwardsTree(this: AABBTree, index: Natural) =
  while index != AABB_NULL_NODE:
    let node = this.nodes[index]
    
    # Every node should be a parent.
    assert node.leftNodeIndex != AABB_NULL_NODE and node.rightNodeIndex != AABB_NULL_NODE
    
    # Fix height and area.
    let leftNode = this.nodes[node.leftNodeIndex]
    let rightNode = this.nodes[node.rightNodeIndex]
    node.aabb = leftNode.aabb + rightNode.aabb
    
    index = node.parentNodeIndex

