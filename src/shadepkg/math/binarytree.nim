type BinaryTree*[T] = ref object 
  parent*, left*, right*: BinaryTree[T]
  value*: T

proc newNode*[T](value: T): BinaryTree[T] =
  new(result)
  result.value = value

template isLeafNode*[T](node: BinaryTree[T]): bool =
  node.left.isNil and node.right.isNil

template peek[T](arr: openArray[T]): T =
  arr[arr.high]

proc setLeaf*[T](leaf: BinaryTree[T], value: T) =
  ## Makes `leaf` a leaf node with nil children and the given value.
  ## This does not affect the leaf's parent.
  leaf.value = value
  leaf.left = nil
  leaf.right = nil

proc setBranch*(branch, left, right: BinaryTree) =
  ## Makes `branch` a branch node with the given children.
  left.parent = branch
  right.parent = branch
  branch.left = left
  branch.right = right

proc getSibling*(this: BinaryTree): BinaryTree =
  ## Retrieves the sibling of the given node.
  if this == this.parent.left:
    return this.parent.right
  else:
    return this.parent.left

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

iterator preorderValues*[T](this: BinaryTree[T]): T =
  for n in preorder(this):
    yield n.value

iterator postorder*[T](this: BinaryTree[T]): BinaryTree[T] =
  ## Postorder traversal of a binary tree.
  ## Left, root, then right (depth-first search, bottom to top).
  var stack: seq[BinaryTree[T]]
  var root: BinaryTree[T] = this
  while true:
    while root != nil:
      stack.add(root)
      stack.add(root)
      root = root.left

    if stack.len == 0:
      break

    root = stack.pop()
    
    if stack.len > 0 and stack.peek() == root:
      root = root.right
    else:
      yield root
      root = nil

iterator postorderValues*[T](this: BinaryTree[T]): T =
  for n in postorder(this):
    yield n.value

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

