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




