#!/usr/bin/python2.5

__author__ = 'DeWitt Clinton <dewitt@unto.net>'

class BinarySearchTree(object):
  """A tree data structure that exhibits O(h) behavior for basic operations.

  A binary search tree is a tree data structure that supports dynamic
  set operations including Insert, Delete, Minimum, Maximum, etc., in
  O(h) time, where h is the height of the tree.  For a balanced tree,
  such as is expected when elements are inserted in random order, h is
  equal to lg n, where n is the number of elements, and thus
  operations will require O(lg n) time.  However, in the worst case,
  such as when the nodes are inserted in sorted or reverse sorted
  order, the height of the tree will be equal to n, and thus the upper
  bound on operations is O(n).
  
  References: 
    [Cor] Thomas H. Cormen, Charles E. Leiserson, et. al,
    _Introduction to Algorithms, Second Edition_, 2007, p253-p264
  """

  def __init__(self):
    """Constructs a new empty BinarySearchTree.

    """
    self.root = None

  def Insert(self, node):
    """Inserts the node into the tree.

    Cost:
      O(h) for trees of height h
    Args:
      node: a BinarySearchTree.Node instance
    """
    parent = None
    current = self.root

    # Descend to the leaf that follows from the binary search
    # invariant.  This is a no-op if the tree is empty.
    while current:
      parent = current
      if node.value < current.value:
        current = current.left
      else:
        current = current.right

    # Attach the node to the tree
    node.parent = parent
    if not parent:  # The tree was empty
      self.root = node
    else:
      if node.value < parent.value:
        parent.left = node
      else:
        parent.right = node

  def Delete(self, node):
    """Removes the node from the tree.

    Cost:
      O(h) for trees of height h
    Args:
      node: a BinarySearchTree.Node instance
    """
    # There are three possible cases:  Either (a) the node
    # has no children and can be deleted, (b) the node has
    # one child and can be spliced out, or (c) the node has
    # two children and its successor should be copied into
    # its place and subsequently removed.
    if not node.left or not node.right:
      to_remove = node  # case (a) or (b)
    else:
      to_remove = node.Successor()  # case (c)

    # The node to be removed will have either zero children (case a)
    # or one (cases b or c) child.  Keep a pointer to this child (if
    # one exists), so it can be moved upwards.
    if to_remove.left:
      child = to_remove.left  # case (b) or (c)
    else:
      child = to_remove.right  # case (a), (b), or (c)

    # If there is a child then reparent it in place of the 
    # node being removed.  Case (b) or (c)
    if child:
      child.parent = to_remove.parent

    # If the node being removed was the root of the tree, then
    # the child (if one exists) becomes the new root
    if not to_remove.parent:
      self.root = child
    else:  
      # Move the child up to the new parent
      if to_remove == to_remove.parent.left:  # removing the left child
        to_remove.parent.left = child
      else:  # removing the right child
        to_remove.parent.right = child

    # In case (c), copying the values into the node
    if to_remove != node: 
      node.value = to_remove.value

    # Clean up any dangling references so the node can be gc'ed
    to_remove.parent = None
    to_remove.left = None
    to_remove.right = None

  def Minimum(self):
    """Returns the node with the smallest value.

    Cost:
      O(h) for trees of height h
    Returns:
      The BinarySearchTree.Node with the smallest value or None if the
      tree is empty.
    """
    if not self.root:
      return None
    return self.root.Minimum()

  def Maximum(self):
    """Returns the node with the largest value.

    Cost:
      O(h) for trees of height h
    Returns:
      The BinarySearchTree.Node with the largest value or None if the
      tree is empty.
    """
    if not self.root:
      return None
    return self.root.Maximum()

  def Search(self, value):
    """Returns a node with the specified value.

    Cost:
      O(h) for trees of height h
    Returns:
      The BinarySearchTree.Node with the specified value or None if the
      tree if the value is not found.
    """
    current = self.root
    while current and current.value != value:
      if value < current.value:
        current = current.left
      else:
        current = current.right
    return current

  def Inorder(self):
    """Returns an iterator that traverses the tree in order.

    The binary search tree invariant holds that the in order traversal
    will return elements in sorted order.

    Cost:
      O(1) to return the iterator, and O(n) to walk all of the nodes
      in the tree.  Additionally uses O(h) stack frames.
    Returns:
      An iterator that yields nodes in order.
    """
    if self.root:
      return self.root.Inorder()
    else:
      return iter([])

  def __contains__(self, key):
    """Returns true if the tree contains a node with a value matching key.

    Cost:
      O(h) for trees of height h
    Args:
      key: the value to be searched for
    Returns:
      True if the tree contains a node with a value matching the key.
    """
    return bool(self.Search(key))

  def __delitem__(self, key):
    """Removes the first node whose value matches the key.

    Cost:
      O(h) for trees of height h
    Args:
      key: the key to match against the node's value
    Raises:
      KeyError if the tree does not contain a node with that value.
    """
    node = self.Search(key)
    if node:
      self.Delete(node)
    else:
      raise KeyError('%s not found in tree' % key)

  def __getitem__(self, key):
    """Returns the value of a node if one exists that matches the key.

    Cost:
      O(h) for trees of height h
    Args:
      key: the key to match against the node's value
    Raises:
      KeyError if the tree does not contain a node with that value.
    Returns:
      The value of a node if one exists that matches the key.
    """
    node = self.Search(key)
    if node:
      return node.value
    else:
      raise KeyError('%s not found in tree' % key)

  def __iter__(self):
    """Returns an iterator over the values in an inorder traversal.

    This differs from Inorder in that it returns values, not Nodes.

    Cost:
      O(1) to return the iterator, and O(n) to walk all of the nodes
      in the tree.  Additionally uses O(h) stack frames.
    Returns:
      An iterator that yields values in order.
    """
    for node in self.Inorder():
      yield node.value

  def __len__(self):
    """Returns the number of nodes in the tree.

    Cost:
      O(n) for trees of n nodes
    Returns:
      The number of nodes in the tree.
    """
    return len(list(self.Inorder()))

  def __str__(self):
    """Returns a string representation of the tree.

    Returns:
      A string representation of the tree.
    """
    if not self.root:
      return '()'
    else:
      return str(self.root)


class Node(object):
  
  def __init__(self, value):
    self.value = value
    self.left = None
    self.right = None
    self.parent = None

  def Minimum(self):
    """Returns this or the descendent node with the smallest value.

    Cost:
      O(h) for trees of height h
    Returns:
      The BinarySearchTree.Node with the smallest value below and
      including this node.
    """
    current = self
    while current.left:
      current = current.left
    return current

  def Maximum(self):
    """Returns this or the descendent node with the largest value.

    Cost:
      O(h) for trees of height h
    Returns:
      The BinarySearchTree.Node with the largest value below and
      including this node.
    """
    current = self
    while current.right:
      current = current.right
    return current

  def Successor(self):
    """Returns the successor node if it exists.

    Cost:
      O(h) for trees of height h
    Returns:
      The sucessor BinarySearchTree.Node if it exists, or None if
      this node is the largest node in the tree.
    """
    # If the right subtree is nonempty, then the successor is
    # the leftmost node of the right subtree
    if self.right:
      return self.right.Minimum()

    # Otherwise the successor is the first ancestor node that
    # is the left child of its parent
    node = self
    parent = node.parent
    while parent and node == parent.right:
      node = parent
      parent = node.parent
    return parent

  def Predecessor(self):
    """Returns the predecessor node if it exists.

    Cost:
      O(h) for trees of height h
    Returns:
      The predecessor BinarySearchTree.Node if it exists, or None if
      this node is the largest node in the tree.
    """
    # If the left subtree is nonempty, then the predecessor is
    # the rightmost node of the left subtree
    if self.left:
      return self.left.Maximum()

    # Otherwise the predecessor is the first ancestor node that
    # is the right child of its parent
    node = self
    parent = node.parent
    while parent and node == parent.left:
      node = parent
      parent = node.parent
    return parent

  def Inorder(self):
    """Returns an iterator that traverses the nodes in order.

    The binary search tree invariant holds that the in order
    traversal will return elements in sorted order.

    Cost:
      O(1) to return the iterator, and O(n) to walk all of the nodes
      below and including this node.  Additionally uses O(h) stack
      frames.
    Returns:
      An iterator that yields nodes in order.
    """
    if self.left:
      for element in self.left.Inorder():
        yield element
    yield self
    if self.right:
      for element in self.right.Inorder():
        yield element

  def __str__(self):
    parts = [str(self.value)]
    if self.left:
      parts.append(str(self.left))
    else:
      parts.append('NIL')
    if self.right:
      parts.append(str(self.right))
    else:
      parts.append('NIL')
    return '(' + ' '.join(parts) + ')'
  

