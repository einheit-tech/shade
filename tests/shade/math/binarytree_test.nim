import
  nimtest,
  shade,
  sequtils

describe "BinaryTree":

  describe "preorder":

    it "works with a single node":
      let
        tree = newNode(1)
        nodes = tree.preorderValues().toSeq()
      assertEquals(nodes, @[1])

    it "displays the correct order with just one child":
      var tree = newNode(1)
      tree.add(2)
      let nodes = tree.preorderValues().toSeq()

      assertEquals(nodes, @[1, 2])

    it "displays the correct order with two children":
      var tree = newNode(1)
      tree.add(2)
      tree.add(0)
      let nodes = tree.preorderValues().toSeq()
      assertEquals(nodes, @[1, 0, 2])

    it "displays the correct order with multiple layers":
      var tree = newNode(5)
      tree.add(3)
      tree.add(2)
      tree.add(1)
      tree.add(4)

      tree.add(8)
      tree.add(6)
      tree.add(9)
      tree.add(7)

      let nodes = tree.preorderValues().toSeq()

      assertEquals(
        nodes,
        @[
          5,
          3,
          2,
          1,
          4,
          8,
          6,
          7,
          9
        ]
      )

  describe "postorder":

    it "works with a single node":
      let
        tree = newNode(1)
        nodes = tree.postorderValues().toSeq()
      assertEquals(nodes, @[1])

    it "displays the correct order with just one child":
      var tree = newNode(1)
      tree.add(2)
      let nodes = tree.postorderValues().toSeq()

      assertEquals(nodes, @[2, 1])

    it "displays the correct order with two children":
      var tree = newNode(1)
      tree.add(2)
      tree.add(0)

      let nodes = tree.postorderValues().toSeq()
      assertEquals(nodes, @[0, 2, 1])

    it "displays the correct order with multiple layers":
      var tree = newNode(5)
      tree.add(3)
      tree.add(2)
      tree.add(1)
      tree.add(4)

      tree.add(8)
      tree.add(7)
      tree.add(6)
      tree.add(9)

      let nodes = tree.postorderValues().toSeq()

      assertEquals(
        nodes,
        @[
          1,
          2,
          4,
          3,
          6,
          7,
          9,
          8,
          5
        ]
      )

