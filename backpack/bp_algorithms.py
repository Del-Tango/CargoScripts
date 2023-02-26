#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# ALGORITHMS

import heapq
import logging
#import pysnooper

from collections import deque

log = logging.getLogger('')


#@pysnooper.snoop()
def dijkstra(graph, start):
    '''
    [ NOTE ]: Algorithm Breakdown

    1) Create a set of visited nodes, initially empty.

    2) Create a list of unvisited nodes, initially containing all nodes in the
    graph.

    3) Set the distance of the starting node to zero, and the distances of all
    other nodes to infinity.

    4) While there are still unvisited nodes:

        a. Select the node with the smallest distance.
        b. Add it to the set of visited nodes.
        c. For each of its neighbors that is still unvisited:

            c1. Calculate the distance to the neighbor through the current node.
            c2. If this distance is smaller than the neighbor's current distance,
            update it.

    5) When all nodes have been visited, the shortest path to each node can be
    found by following the path with the smallest total distance.
    '''
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    queue = [(0, start)]
    visited = set()
    while queue:
        (current_distance, current_node) = heapq.heappop(queue)
        if current_node in visited:
            continue
        visited.add(current_node)
        for neighbor, weight in graph[current_node].items():
            distance = current_distance + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(queue, (distance, neighbor))
    return distances


def quick_sort(array):
    '''
    [ NOTE ]: Algorithm Breakdown

    1) Select a pivot element from the list. The pivot element can be any element
    from the list, but it's common to select the first or last element in the list
    as the pivot.

    2) Partition the list into two sub-lists, one with elements smaller than the
    pivot and the other with elements larger than the pivot.

    3) Recursively sort the sub-lists using the same algorithm until the entire
    list is sorted.

    [ WARNING ]: Recursive implementation
    '''
    log.debug('')
    if len(array) <= 1:
        return array
    pivot = array[0]
    left = [x for x in array[1:] if x <= pivot]
    right = [x for x in array[1:] if x > pivot]
    return quick_sort(left) + [pivot] + quick_sort(right)


def binary_search(array, x):
    '''
    [ NOTE ]: Algorithm Breakdown

    1) Initialize two variables, low and high, to the first and last indices of
    the array or list.

    2) While low is less than or equal to high, do the following:

        a. Find the middle index mid of the current search interval, by taking
        the average of low and high, rounding down to an integer if necessary.

        b. If the value at index mid is equal to the target value, return mid.

        c. If the value at index mid is greater than the target value, set high
        to mid - 1, since the target value can only be in the left half of the
        search interval.

        d. If the value at index mid is less than the target value, set low to
        mid + 1, since the target value can only be in the right half of the
        search interval.

    3) If the target value is not found in the array or list, return -1.
    '''
    log.debug('')
    low, high = 0, len(array) - 1
    while low <= high:
        # NOTE: Make sure to use floor division operator '//'
        mid = (low + high) // 2
        if array[mid] == x:
            return mid
        elif array[mid] < x:
            low = mid + 1
        else:
            high = mid - 1
    return -1


def depth_first_search(graph, start):
    '''
    [ NOTE ]: Algorithm Breakdown

    1) Initialize a stack S with the starting vertex.

    2) While S is not empty, do the following:

        a. Pop a vertex v from S.

        b. If v has not been visited, mark it as visited and do whatever
        processing is needed for v.

        c. Push all adjacent vertices of v that have not been visited onto S.

    3) Repeat step 2 until all vertices have been visited.
    '''
    log.debug('')
    visited, stack = set(), [start]
    while stack:
        vertex = stack.pop()
        if vertex not in visited:
            visited.add(vertex)
            print(vertex)
            stack.extend(graph[vertex] - visited)
    return visited


def breadth_first_search(graph, start):
    '''
    [ NOTE ]: Algorithm Breakdown

    1) Initialize a queue Q with the starting vertex.

    2) While Q is not empty, do the following:

        a. Dequeue a vertex v from Q.

        b. If v has not been visited, mark it as visited and do whatever
        processing is needed for v.

        c. Enqueue all adjacent vertices of v that have not been visited and are
        not already in Q.

    3) Repeat step 2 until all vertices have been visited.
    '''
    log.debug('')
    visited, queue = set(), deque([start])
    while queue:
        vertex = queue.popleft()
        if vertex not in visited:
            visited.add(vertex)
            print(vertex)
            queue.extend(graph[vertex] - visited)
    return visited


def fibonacci_generator(n):
    '''
    [ WARNING ]: Recursive implementation
    '''
    log.debug('')
    if n == 0:
        return 0
    elif n == 1:
        return 1
    else:
        return fibonacci_generator(n-1) + fibonacci_generator(n-2)
