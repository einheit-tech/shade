import
  ../../testutils,
  shade

describe "SafeSet":

  describe "add":
    it "adds an element to the set":
      let safeset = newSafeSet[string]()
      safeset.add("foobar")
      assertEquals(safeset.len, 1)

      for item in safeset:
        assertEquals(item, "foobar")

    it "adds an element to the set during iteration":
      let safeset = newSafeSet[string]()
      safeset.add("foobar")
      assertEquals(safeset.len, 1)

      for item in safeset:
        safeset.add("barbaz")
      
      assertEquals(safeset.len, 2)

  describe "remove":
    it "removes an element remove the set":
      let safeset = newSafeSet[string]()
      safeset.add("foobar")
      assertEquals(safeset.len, 1)

      for item in safeset:
        assertEquals(item, "foobar")

      safeset.remove("foobar")
      assertEquals(safeset.len, 0)

    it "removes an element remove the set during iteration":
      let safeset = newSafeSet[string]()
      safeset.add("foobar")
      assertEquals(safeset.len, 1)

      for item in safeset:
        safeset.remove("foobar")

      assertEquals(safeset.len, 0)


