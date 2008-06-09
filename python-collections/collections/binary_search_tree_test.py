#!/usr/bin/python2.5

import unittest

from binary_search_tree import BinarySearchTree, Node

class BinarySearchTreeTest(unittest.TestCase):

  def testConstructor(self):
    bst = BinarySearchTree()

  def testInsert(self):
    bst = BinarySearchTree()
    bst.Insert(Node(None))
    bst.Insert(Node(1))
    bst.Insert(Node('a'))
    bst = self._GetTestTree()
    bst.Insert(Node(2))
    bst.Insert(Node(13))
    bst.Insert(Node(14))
    bst.Insert(Node(24))

  def testMinimum(self):
    bst = BinarySearchTree()
    self.assertEquals(None, bst.Minimum())
    bst.Insert(Node('b'))
    self.assertEquals('b', bst.Minimum().value)
    bst.Insert(Node('c'))
    self.assertEquals('b', bst.Minimum().value)
    bst.Insert(Node('a'))
    self.assertEquals('a', bst.Minimum().value)
    bst = self._GetTestTree()
    self.assertEquals(3, bst.Minimum().value)

  def testMaximum(self):
    bst = BinarySearchTree()
    self.assertEquals(None, bst.Maximum())
    bst.Insert(Node('b'))
    self.assertEquals('b', bst.Maximum().value)
    bst.Insert(Node('a'))
    self.assertEquals('b', bst.Maximum().value)
    bst.Insert(Node('c'))
    self.assertEquals('c', bst.Maximum().value)
    bst = self._GetTestTree()
    self.assertEquals(23, bst.Maximum().value)

  def testSearch(self):
    bst = BinarySearchTree()
    self.assertEquals(None, bst.Search('a'))
    bst.Insert(Node('a'))
    self.assertEquals('a', bst.Search('a').value)
    self.assertEquals(None, bst.Search('b'))
    bst.Insert(Node('b'))
    self.assertEquals('a', bst.Search('a').value)
    self.assertEquals('b', bst.Search('b').value)
    bst = self._GetTestTree()
    self.assertEquals(13, bst.Search(13).value)
    self.assertEquals(16, bst.Search(16).value)
    self.assertEquals(5, bst.Search(5).value)

  def testSuccessor(self):
    bst = BinarySearchTree()
    bst.Insert(Node(1))
    one = bst.Search(1)
    self.assertEquals(None, one.Successor())
    bst.Insert(Node(2))
    self.assertEquals(2, one.Successor().value)
    bst = self._GetTestTree()
    fifteen = bst.Search(15)
    self.assertEquals(16, fifteen.Successor().value)
    sixteen = bst.Search(16)
    self.assertEquals(18, sixteen.Successor().value)
    thirteen = bst.Search(13)
    self.assertEquals(15, thirteen.Successor().value)
    seven = bst.Search(7)
    self.assertEquals(10, seven.Successor().value)
    # Test that the list of successors from the minimum node is
    # equivalent to the inorder traversal
    start = bst.Minimum()
    results = []
    current = start
    while current:
      results.append(current)
      current = current.Successor()
    self.assertEquals(self._ToValueList(list(bst.Inorder())),
                      self._ToValueList(results))

  def testPredecessor(self):
    bst = BinarySearchTree()
    bst.Insert(Node(2))
    two = bst.Search(2)
    self.assertEquals(None, two.Predecessor())
    bst.Insert(Node(1))
    self.assertEquals(1, two.Predecessor().value)
    bst = self._GetTestTree()
    fifteen = bst.Search(15)
    self.assertEquals(13, fifteen.Predecessor().value)
    sixteen = bst.Search(16)
    self.assertEquals(15, sixteen.Predecessor().value)
    thirteen = bst.Search(13)
    self.assertEquals(12, thirteen.Predecessor().value)
    seven = bst.Search(7)
    self.assertEquals(6, seven.Predecessor().value)
    # Test that the list of predecessors from the maximum node is
    # equivalent to the reversed inorder traversal
    start = bst.Maximum()
    results = []
    current = start
    while current:
      results.append(current)
      current = current.Predecessor()
    self.assertEquals(self._ToValueList(reversed(list(bst.Inorder()))),
                      self._ToValueList(results))

  def testDelete(self):
    # Test deleting the root of a single element tree
    bst = BinarySearchTree()
    bst.Insert(Node(1))
    root = bst.Search(1)
    self.assertEquals(1, root.value)
    bst.Delete(root)
    self.assertEquals(None, bst.Search(1))

    # Test case (a)
    bst = self._GetTestTree()
    z = bst.Search(13)
    self.assertEquals(13, z.value)
    bst.Delete(z)
    self.assertEquals(None, bst.Search(13))
    twelve = bst.Search(12)
    self.assertEquals(12, twelve.value)
    self.assertEquals(5, twelve.parent.value)
    self.assertEquals(10, twelve.left.value)
    self.assertEquals(None, twelve.right)

    # Test case (b)
    bst = self._GetTestTree()
    z = bst.Search(16)
    self.assertEquals(16, z.value)
    bst.Delete(z)
    self.assertEquals(None, bst.Search(16))
    twenty = bst.Search(20)
    self.assertEquals(20, twenty.value)
    self.assertEquals(15, twenty.parent.value)
    self.assertEquals(18, twenty.left.value)
    self.assertEquals(23, twenty.right.value)

    # Test case (c)
    bst = self._GetTestTree()
    z = bst.Search(5)
    self.assertEquals(5, z.value)
    bst.Delete(z)
    self.assertEquals(None, bst.Search(5))
    six = bst.Search(6)
    self.assertEquals(6, six.value)
    self.assertEquals(15, six.parent.value)
    self.assertEquals(3, six.left.value)
    self.assertEquals(12, six.right.value)
    
  def testInoder(self):
    bst = BinarySearchTree()
    self.assertEquals([], list(bst.Inorder()))
    bst.Insert(Node(1))
    self.assertEquals([1], self._ToValueList(list(bst.Inorder())))
    bst = self._GetTestTree()
    self.assertEquals([3,5,6,7,10,12,13,15,16,18,20,23], 
                      self._ToValueList(list(bst.Inorder())))

  def testContains(self):
    bst = self._GetTestTree()
    self.assertFalse(1 in bst)
    self.assertTrue(15 in bst)
    self.assertTrue(7 in bst)

  def testDelitem(self):
    bst = self._GetTestTree()
    self.assertFalse(1 in bst)
    try:
      del bst[1]
    except KeyError:
      pass  # expected
    else:
      self.fail("KeyError expected")
    self.assertTrue(3 in bst)
    del bst[3]
    self.assertFalse(3 in bst)    
    try:
      del bst[3]
    except KeyError:
      pass  # expected
    else:
      self.fail("KeyError expected")
    bst.Insert(Node(15))  # add a second 15
    self.assertTrue(15 in bst)
    del bst[15]
    self.assertTrue(15 in bst)
    del bst[15]
    self.assertFalse(15 in bst)    
    try:
      del bst[15]
    except KeyError:
      pass  # expected
    else:
      self.fail("KeyError expected")

  def testGetItem(self):
    bst = self._GetTestTree()
    self.assertRaises(KeyError, lambda: bst[1])
    self.assertEquals(3, bst[3])
    self.assertEquals(15, bst[15])

  def testLen(self):
    bst = BinarySearchTree()
    self.assertEquals(0, len(bst))
    bst.Insert(Node(1))
    self.assertEquals(1, len(bst))
    bst = self._GetTestTree()
    self.assertEquals(12, len(bst))

  def testIter(self):
    bst = BinarySearchTree()
    self.assertEquals([], list(bst))
    bst.Insert(Node(1))
    self.assertEquals([1], list(bst))
    bst = self._GetTestTree()
    self.assertEquals([3,5,6,7,10,12,13,15,16,18,20,23], list(bst))

  def testStr(self):
    bst = BinarySearchTree()
    self.assertEquals('()', str(bst))
    bst = self._GetTestTree()
    self.assertEquals('(15 (5 (3 NIL NIL) (12 (10 (6 NIL (7 NIL NIL)) NIL) '
                      '(13 NIL NIL))) (16 NIL (20 (18 NIL NIL) (23 NIL NIL))))',
                      str(bst))

  def _GetTestTree(self):
    """Returns the tree described by figure 12.4a in p263 of [Cor]."""
    bst = BinarySearchTree()
    bst.Insert(Node(15))
    bst.Insert(Node(5))
    bst.Insert(Node(16))
    bst.Insert(Node(3))
    bst.Insert(Node(12))
    bst.Insert(Node(20))
    bst.Insert(Node(10))
    bst.Insert(Node(13))
    bst.Insert(Node(18))
    bst.Insert(Node(23))
    bst.Insert(Node(6))
    bst.Insert(Node(7))
    return bst

  def _ToValueList(self, node_list):
    """Convert a list of nodes to a list of values."""
    return [node.value for node in node_list]

if __name__ == "__main__":
  unittest.main()
