import tables

import
  ../binarytree,
  ../rectangle,
  ../vector2

import ../../game/physicsbody

# TODO:
# See:
# https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/
# https://www.geeksforgeeks.org/level-order-tree-traversal/
# https://www.azurefromthetrenches.com/introductory-guide-to-aabb-tree-collision-detection/
# https://github.com/JamesRandall/SimpleVoxelEngine/blob/master/voxelEngine/src/AABBTree.cpp

const AABB_NULL_NODE = int.high

type TreeNode[T: Boundable] = ref object
  # Object that owns the AABB
  obj: T
  aabb: Rectangle

  parentNodeIndex: Natural
  leftNodeIndex: Natural
  rightNodeIndex: Natural
  nextNodeIndex: Natural

proc newTreeNode(): TreeNode =
  result = TreeNode(
    parentNodeIndex: AABB_NULL_NODE,
    leftNodeIndex: AABB_NULL_NODE,
    rightNodeIndex: AABB_NULL_NODE,
    nextNodeIndex: AABB_NULL_NODE
  )

template isLeaf(n: TreeNode): bool =
  n.leftNodeIndex == AABB_NULL_NODE

template isBranch(n: TreeNode): bool =
  not n.isLeaf()

# TREE

type AABBTree*[T: Boundable] = ref object
  objectIndexMap: Table[T, int]
  nodes: seq[TreeNode[T]]
  rootNodeIndex: Natural
  allocatedNodeCount: Natural
  nextFreeNodeIndex: Natural
  nodeCapacity: Natural
  growthSize: Positive

proc insertLeaf(this: AABBTree, leafNodeIndex: Natural)
proc fixUpwardsTree(this: AABBTree, index: Natural)
proc updateLeaf(this: AABBTree, index: Natural, newAABB: Rectangle)

proc newAABBTree*[T: Boundable](initialNodeCount: Natural, growthSize: Positive = 16): AABBTree[T] =
  result = AABBTree[T](
    nodes: newSeq[TreeNode[T]](initialNodeCount),
    rootNodeIndex: AABB_NULL_NODE,
    nextFreeNodeIndex: 0,
    growthSize: growthSize
  )

proc allocateNode(this: AABBTree): Natural =
  ## Allocates a new node and returns its index in the tree's nodes.
  if this.nextFreeNodeIndex == AABB_NULL_NODE:
    assert this.allocatedNodeCount == this.nodeCapacity
    this.nodeCapacity += this.growthSize

    for i in 1..this.growthSize:
      let node = newTreeNode()
      node.nextNodeIndex = this.allocatedNodeCount + i
      this.nodes.add(node)

    this.nodes[^1].nextNodeIndex = AABB_NULL_NODE
    this.nextFreeNodeIndex = this.allocatedNodeCount

  result = this.nextFreeNodeIndex
  let allocateNode = this.nodes[result]
  allocateNode.parentNodeIndex = AABB_NULL_NODE
  allocateNode.leftNodeIndex = AABB_NULL_NODE
  allocateNode.rightNodeIndex = AABB_NULL_NODE
  this.nextFreeNodeIndex = allocateNode.nextNodeIndex
  this.allocatedNodeCount += 1

proc deallocateNode(this: AABBTree, index: Natural) =
  let node = this.nodes[index]
  node.nextNodeIndex = this.nextFreeNodeIndex
  this.nextFreeNodeIndex = index
  this.allocatedNodeCount -= 1

proc insert*(this: AABBTree, shape: Boundable) =
  let index = this.allocateNode()
  let node = this.nodes[index]

  node.obj = shape
  node.aabb = node.obj.getBounds()

  this.insertLeaf(index)
  this.objectIndexMap[node.obj] = index

proc remove*(this: AABBTree, obj: Boundable) =
  let index = this.objectIndexMap[obj]
  this.removeLeaf(index)
  this.deallocateNode(index)
  this.objectIndexMap.del(obj)

proc update*(this: AABBTree, obj: Boundable) =
  let index = this.objectIndexMap[obj]
  this.updateLeaf(index, obj.getAABB())

proc queryOverlaps*(this: AABBTree, obj: Boundable): seq[Rectangle] =
  let
    stack: seq[Natural]
    testAABB = obj.getAABB()

  stack.add(this.rootNodeIndex)
  
  while stack.len > 0:
    let index = stack.pop()
    if index == AABB_NULL_NODE:
      continue
    
    let node = this.nodes[index]
    if node.aabb.overlaps(testAABB):
      if node.isLeaf() and node.obj != obj:
        # TODO: why push_front?
        result.insert(node.obj, 0)
      else:
        stack.add(node.leftNodeIndex)
        stack.add(node.rightNodeIndex)

proc insertLeaf(this: AABBTree, leafNodeIndex: Natural) =
  let leafNode = this.nodes[leafNodeIndex]

  # Must be a leaf node
  assert leafNode.parentNodeIndex == AABB_NULL_NODE
  assert leafNode.leftNodeIndex == AABB_NULL_NODE
  assert leafNode.rightNodeIndex == AABB_NULL_NODE

  if this.rootNodeIndex == AABB_NULL_NODE:
    # If the tree is empty, make the root the new leaf.
    this.rootNodeIndex = leafNodeIndex
    return
  
  # Search for the best place to insert the new leaf.
  # Using surface area and depth as search heuristics.

  var treeNodeIndex = this.rootNodeIndex

  while this.nodes[treeNodeIndex].isBranch():
    let
      treeNode = this.nodes[treeNodeIndex]
      leftNodeIndex = treeNode.leftNodeIndex
      rightNodeIndex = treeNode.rightNodeIndex
      leftNode = this.nodes[leftNodeIndex]
      rightNode = this.nodes[rightNodeIndex]
      combinedAABB = treeNode.aabb + leafNode.aabb
      combinedArea = combinedAABB.getArea()
      newParentNodeCost = combinedArea * 2.0
      minimumPushDownCost = (combinedArea - treeNode.aabb.getArea()) * 2.0

    # Use costs to determine if a new parent should be created
    var costLeft, costRight: float
    if leftNode.isLeaf():
      costLeft = (leafNode.aabb + leftNode.aabb).getArea() + minimumPushDownCost
    else:
      let newLeftAABB = leafNode.aabb + leftNode.aabb
      costLeft = newLeftAABB.getArea() - leftNode.aabb.getArea() + minimumPushDownCost

    if rightNode.isLeaf():
      costRight = (leafNode.aabb + rightNode.aabb).getArea() + minimumPushDownCost
    else:
      let newRightAABB = leafNode.aabb + rightNode.aabb
      costRight = newRightAABB.getArea() - rightNode.aabb.getArea() + minimumPushDownCost

    # If the cost of creating a new parent node is less than descending other branches in either direction,
    # we know we need to create a new parent node here and attach the leaf.
    if newParentNodeCost < costLeft and newParentNodeCost < costRight:
      break
    
    if costLeft < costRight:
      treeNodeIndex = leftNodeIndex
    else:
      treeNodeIndex = rightNodeIndex
    
    # The leaf's sibling is going to be the node we found above,
    # and we are going to create a new parent node and attach the leaf and this item
    let
      leafSiblingIndex = treeNodeIndex
      leafSibling = this.nodes[leafSiblingIndex]
      oldParentIndex = leafSiblingIndex
      newParentIndex = this.allocateNode()
      newParent = this.nodes[newParentIndex]

    newParent.parentNodeIndex = oldParentIndex
    newParent.leftNodeIndex = leafSiblingIndex
    newParent.rightNodeIndex = leafNodeIndex

    leafNode.parentNodeIndex = newParentIndex
    leafSibling.parentNodeIndex = newParentIndex
    
    if oldParentIndex == AABB_NULL_NODE:
      # The old parent was the root, now this should be the new root.
      this.rootNodeIndex = newParentIndex
    else:
      # The old parent was not the root.
      # Need to patch the left or right index to point to the new node.
      let oldParent = this.nodes[oldParentIndex]
      if oldParent.leftNodeIndex == leafSiblingIndex:
        oldParent.leftNodeIndex = newParentIndex
      else:
        oldParent.rightNodeIndex = newParentIndex

    treeNodeIndex = leafNode.parentNodeIndex
    this.fixUpwardsTree(treeNodeIndex)

proc removeLeaf(this: AABBTree, leafNodeIndex: Natural) =
  # If the leaf is the root, we can clear the root pointer and return.
  if leafNodeIndex == this.rootNodeIndex:
    this.rootNodeIndex = AABB_NULL_NODE
    return
  
  let
    leafNode = this.nodes[leafNodeIndex]
    parentNodeIndex = leafNode.parentNodeIndex
    parentNode = this.nodes[parentNodeIndex]
    grandparentNodeIndex = parentNode.parentNodeIndex
    siblingNodeIndex =
      if parentNode.leftNodeIndex == leafNodeIndex:
        parentNode.rightNodeIndex
      else:
        parentNode.leftNodeIndex

  assert siblingNodeIndex != AABB_NULL_NODE

  let siblingNode = this.nodes[siblingNodeIndex]

  if grandparentNodeIndex != AABB_NULL_NODE:
    # If we have a valid grandparent,
    # destroy the parent and connect the sibling to the grandparent in its place.
    let grandparentNode = this.nodes[grandparentNodeIndex]
    if grandparentNode.leftNodeIndex == parentNodeIndex:
      grandparentNode.leftNodeIndex = siblingNodeIndex
    else:
      grandparentNode.rightNodeIndex = siblingNodeIndex

    siblingNode.parentNodeIndex = grandparentNodeIndex

    this.deallocateNode(parentNodeIndex)
    this.fixUpwardsTree(grandparentNodeIndex)
  else:
    # If there's no grandparent, then the parent is the root.
    # The sibling becomes the root and has its parent removed.
    this.rootNodeIndex = siblingNodeIndex
    siblingNode.parentNodeIndex = AABB_NULL_NODE
    this.deallocateNode(parentNodeIndex)

  leafNode.parentNodeIndex = AABB_NULL_NODE

proc updateLeaf(this: AABBTree, index: Natural, newAABB: Rectangle) =
  let node = this.nodes[index]
  if node.aabb.contains(newAABB):
    return
  
  this.removeLeaf(index)
  node.aabb = newAABB
  this.insertLeaf(index)

proc fixUpwardsTree(this: AABBTree, index: Natural) =
  var treeNodeIndex = index
  while treeNodeIndex != AABB_NULL_NODE:
    let node = this.nodes[treeNodeIndex]
    
    # Every node should be a parent.
    assert node.leftNodeIndex != AABB_NULL_NODE and node.rightNodeIndex != AABB_NULL_NODE
    
    # Fix height and area.
    let leftNode = this.nodes[node.leftNodeIndex]
    let rightNode = this.nodes[node.rightNodeIndex]
    node.aabb = leftNode.aabb + rightNode.aabb
    
    treeNodeIndex = node.parentNodeIndex

