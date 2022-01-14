type BinaryTree*[T] = ref object 
  left, right: BinaryTree[T]
  value: T

proc newNode*[T](value: T): BinaryTree[T] =
  new(result)
  result.value = value

template isLeafNode*[T](node: BinaryTree[T]): bool =
  node.left.isNil and node.right.isNil

iterator preorder*[T](this: BinaryTree[T]): BinaryTree[T] =
  ## Preorder traversal of a binary tree.
  ## Left, root, then right (depth-first search, top to bottom).
  var stack: seq[BinaryTree[T]] = @[this]
  while stack.len > 0:
    var n = stack.pop()
    while n != nil:
      yield n
      stack.add(n.right)  
      n = n.left          

template doWhile(condition, body: untyped): untyped =
  body
  while condition:
    body

iterator postorder*[T](this: BinaryTree[T]): BinaryTree[T] =
  ## Postorder traversal of a binary tree.
  ## Left, root, then right (depth-first search, bottom to top).
  var stack: seq[BinaryTree[T]] = @[this]
  doWhile stack.len > 0:
    let n = stack.pop()
    if n.isLeafNode():
      yield n
    else:
      if n.right != nil:
        stack.add(n.right)

      if n.left != nil:
        stack.add(n.left)
      
  yield this

proc add*[T](this: var BinaryTree[T], n: BinaryTree[T]) =
  ## Inserts a node into the tree.
  if this == nil:
    this = n
  else:
    var it = this
    while it != nil:
      # Compare the value items,
      # using the generic `cmp` proc that works for any type that has a `==` and `<` operator.
      # In the future we will enforce this with concepts, when they are ready.
      if cmp(it.value, n.value) > 0:
        if it.left == nil:
          it.left = n
          return
        it = it.left
      else:
        if it.right == nil:
          it.right = n
          return
        it = it.right

template add*[T](this: var BinaryTree[T], value: T) =
  this.add(newNode(value))

# TODO:
# See:
# https://www.geeksforgeeks.org/tree-traversals-inorder-preorder-and-postorder/
# https://www.geeksforgeeks.org/level-order-tree-traversal/
# https://www.azurefromthetrenches.com/introductory-guide-to-aabb-tree-collision-detection/

