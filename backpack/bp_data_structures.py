#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# DATA STRUCTURES

import logging

log = logging.getLogger('')


class Node:

    def __init__(self, value):
        log.debug('')
        self.value = value
        self.next = None
        self.left = None
        self.right = None


class Tree:

    def __init__(self):
        self.root = None


class BinarySearchTree:

    def __init__(self):
        self.root = None

    def insert(self, value):
        if self.root is None:
            self.root = Node(value)
        else:
            self._insert_recursive(self.root, value)

    def _insert_recursive(self, node, value):
        if value < node.value:
            if node.left is None:
                node.left = Node(value)
            else:
                self._insert_recursive(node.left, value)
        else:
            if node.right is None:
                node.right = Node(value)
            else:
                self._insert_recursive(node.right, value)

    def search(self, value):
        return self._search_recursive(self.root, value)

    def _search_recursive(self, node, value):
        if node is None or node.value == value:
            return node
        if value < node.value:
            return self._search_recursive(node.left, value)
        return self._search_recursive(node.right, value)


class LinkedList:

    def __init__(self):
        log.debug('')
        self.head = None

    def add(self, value):
        log.debug('')
        node = Node(value)
        if self.head is None:
            self.head = node
        else:
            current = self.head
            while current.next is not None:
                current = current.next
            current.next = node

    def print(self):
        log.debug('')
        current = self.head
        while current is not None:
            print(current.value)
            current = current.next


class Stack:

    def __init__(self):
        log.debug('')
        self.stack = []

    def push(self, value):
        log.debug('')
        self.stack.append(value)

    def pop(self):
        log.debug('')
        if len(self.stack) == 0:
            return None
        return self.stack.pop()


class Queue:

    def __init__(self):
        log.debug('')
        self.queue = []

    def enqueue(self, value):
        log.debug('')
        self.queue.append(value)

    def dequeue(self):
        log.debug('')
        if len(self.queue) == 0:
            return None
        else:
            return self.queue.pop(0)


class Deque:
    def __init__(self):
        self.items = []

    def is_empty(self):
        return len(self.items) == 0

    def add_front(self, item):
        self.items.insert(0, item)

    def add_rear(self, item):
        self.items.append(item)

    def remove_front(self):
        if not self.is_empty():
            return self.items.pop(0)
        else:
            raise IndexError("Deque is empty")

    def remove_rear(self):
        if not self.is_empty():
            return self.items.pop()
        else:
            raise IndexError("Deque is empty")

    def size(self):
        return len(self.items)
