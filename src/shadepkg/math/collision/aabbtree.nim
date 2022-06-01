import tables

import
  ../aabb,
  ../vector2

import ../../game/physicsbody

type TreeNode[T: Boundable] = ref object
  aabb: AABB
  # Object that owns the AABB
  value: T

  leftNode: TreeNode[T]
  rightNode: TreeNode[T]

proc newTreeNode[T: Boundable](
  aabb: AABB,
  value: T = nil,
  leftNode, rightNode: TreeNode[T] = nil
): TreeNode[T] =
  result = TreeNode[T](
    aabb: aabb,
    value: value,
    leftNode: leftNode,
    rightNode: rightNode
  )

template isLeaf(n: TreeNode): bool =
  n.leftNode.isNil and n.rightNode.isNil

template depth*(n: TreeNode): int =
  if n.isLeaf:
    0
  else:
    1 + max(n.leftNode.depth, n.rightNode.depth)

proc add*[T: Boundable](this: TreeNode[T], aabb: AABB, value: T) =
  if this.isLeaf():
    this.leftNode = newTreeNode(this, this.value, this.leftNode, this.rightNode)
    this.rightNode = newTreeNode(aabb, value)

    this.aabb = merge(this.aabb, aabb)
    this.value = nil
  else:
    let
      branchMerge = merge(this.aabb, aabb)
      leftMerge = merge(this.leftNode.aabb, aabb)
      rightMerge = merge(this.rightNode.aabb, aabb)

    # Calculate amount of overlap.
    let
      branchOverlap = this.aabb.getOverlap(aabb)
      leftOverlap = leftMerge.getOverlap(this.rightNode.aabb)
      rightOverlap = rightMerge.getOverlap(this.leftNode.aabb)

    # Calculate change in the sum of bounding perimeters.
    var branchCost = branchMerge.perimeter()
    let
      thisPerimeter = this.aabb.perimeter()
      leftCost = branchCost - thisPerimeter + leftMerge.perimeter() - this.leftNode.aabb.volume() + leftOverlap
      rightCost = branchCost - thisPerimeter + rightMerge.perimeter() - this.rightNode.aabb.volume() + rightOverlap

    branchCost += branchOverlap
    
    if branchCost < leftCost and branchCost < rightCost:
      this.left = newTreeNode(this.aabb, this.value, this.leftNode, this.rightNode)
      this.right = newTreeNode(aabb, value)
      this.value = nil
    elif leftCost < rightCost:
      this.leftNode.add(aabb, value)
    else:
      this.rightNode.add(aabb, value)

    this.aabb = merge(this.leftNode.aabb, this.rightNode.aabb)
