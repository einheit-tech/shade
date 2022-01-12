type BinaryTree*[T] = ref object 
  left, right: BinaryTree[T]
  data: T

proc newNode*[T](data: T): BinaryTree[T] =
  new(result)
  result.data = data

proc add*[T](this: var BinaryTree[T], n: BinaryTree[T]) =
  ## Inserts a node into the tree.
  if this == nil:
    this = n
  else:
    var it = this
    while it != nil:
      # Compare the data items,
      # using the generic `cmp` proc that works for any type that has a `==` and `<` operator
      var c = cmp(it.data, n.data)
      if c < 0:
        if it.left == nil:
          it.left = n
          return
        it = it.left
      else:
        if it.right == nil:
          it.right = n
          return
        it = it.right

proc add*[T](this: var BinaryTree[T], data: T) =
  this.add(newNode(data))

iterator preorder*[T](this: BinaryTree[T]): T =
  ## Preorder traversal of a binary tree.
  # This uses an explicit stack,
  # which is more efficient than a recursive iterator factory.
  var stack: seq[BinaryTree[T]] = @[this]
  while stack.len > 0:
    var n = stack.pop()
    while n != nil:
      yield n.data
      # Push right subtree onto the stack
      stack.add(n.right)  
      # Then follow the left pointer
      n = n.left          

