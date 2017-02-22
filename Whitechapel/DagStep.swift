//
//  DagStep.swift
//  Whitechapel
//
//  Created by René Dekker on 15/02/2017.
//  Copyright © 2017 Renevision. All rights reserved.
//

import UIKit

class DagStep : Hashable {
    enum Kind : Int { case walk, coach, alley }
    enum TraverseAction : Int { case keep, delete, traverse }
    
    var nextSteps : Array<DagStep> = []
    var kind : Kind
    var node : Node
    
    static let doTraverse = DagStep()
    
    func isLeaf() -> Bool
    {
        return nextSteps.isEmpty
    }

    private func traverseStep(_ visited:inout [DagStep:DagStep?], action:(DagStep) -> DagStep?) -> DagStep?
    {
        if let result = visited[self] {
            // if we have already examined this step, then simply return the previous result
            return result
        }
        var result = action(self)
        if result === DagStep.doTraverse {
            
            result = self
            if (!isLeaf()) {
                // this is not a Leaf node, examine the children.
                var keep = true
                var children:[DagStep] = []
                for step in nextSteps {
                    let newNode = step.traverseStep(&visited, action: action)
                    keep &&= (newNode === step)
                    if (newNode != nil) {
                        children.append(newNode!)
                    }
                }
                if children.isEmpty {
                    // remove this step if it has no children anymore
                    result = nil
                } else if !keep {
                    // optimization, we keep the existing object if it has not changed
                    // create a new one otherwise
                    result = DagStep(self)
                    result!.nextSteps = children
                }
            }
        }
        visited[self] = result
        return result
    }
    
    /// Traverse through the graph that is reachable from this step,
    /// and perform the action on each step in that graph. The function builds a new graph
    /// according to the instruction of the action and returns that
    /// - parameters:
    ///   - action: The action can return three values for a step, to determine what should be done. Return
    ///     - **a new step** to include the step and all its decendants (the new step can be the argument to action itself),
    ///     - **nil** to exclude the step and all its unique decendants, or
    ///     - **.doTraverse** to include the step, unless all decendants are excluded.
    /// - returns: the new graph
    @discardableResult
    func traverse(_ action:(DagStep) -> DagStep?) -> DagStep?
    {
        var visited: [DagStep:DagStep?] = [:]
        return traverseStep(&visited, action: action)
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func exclude(_ excluded:Node) -> DagStep?
    {
        return traverse() { (step) in
            step.node == excluded ? nil : .doTraverse
        }
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node as a leaf
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func excludeLeaf(_ excluded:Node) -> DagStep?
    {
        return traverse() { (step) in
            (step.isLeaf() && step.node == excluded) ? nil : .doTraverse
        }
    }
    
    /// Ensure that all paths through the graph contain a particular node
    /// - parameters:
    ///   - incuded: The node to include
    /// - returns: the reduced graph
    func include(_ included:Node) -> DagStep?
    {
        return traverse() { (step) in
            step.node == included ? step : (step.isLeaf() ? nil : .doTraverse)
        }
    }
    
    private func extendStep(_ kind: Kind,
                    traversable: Set<Node.Kind>,
                    map: Map,
                    visited: inout [DagStep:DagStep],
                    addedSteps: inout [Node:DagStep],
                    parent: DagStep? = nil)
        -> DagStep?
    {
        if let result = visited[self] {
            // if we have already examined this step, then simply return the previous result
            return result
        }
        var result: DagStep? = nil
        if isLeaf() {
            var childNodes = map.reachable(from: node, traversable: traversable)
            if let parentNode = parent?.node {
                childNodes.remove(parentNode)
            }
            // only keep the step if it can be extended
            if !childNodes.isEmpty {
                result = DagStep(self)
                result!.nextSteps = childNodes.map { node in
                    addedSteps.getOrSet(node) { DagStep(node, kind) }
                }
            }
            if (parent == nil) {
                // we only store the result for re-use if we did not filter out the parent node
                visited[self] = result
            }
        } else {
            // this is not a Leaf node, examine the children.
            var children:[DagStep] = []
            for step in nextSteps {
                let newStep = step.extendStep(kind,
                                              traversable: traversable,
                                              map: map,
                                              visited: &visited,
                                              addedSteps: &addedSteps,
                                              parent: parent == nil ? nil : self)
                if (newStep != nil) {
                    children.append(newStep!)
                }
            }
            if children.isEmpty {
                // remove this step if it has no children anymore
                result = nil
            } else {
                // optimization, we keep the existing object if it has not changed
                // create a new one otherwise
                result = DagStep(self)
                result!.nextSteps = children
            }
            visited[self] = result
        }
        return result

    }
    
    /// Extend the graph with new steps with nodes that are reachable from the leaf nodes.
    /// Note that this can also remove steps from the graph, if they cannot reach any new nodes
    ///
    /// - parameters:
    ///   - kind: the kind of the new steps that are created
    ///   - traversable: the Node kinds that can be walked through to reach a neighbour Node
    ///   - map: the map to determine reachability from
    ///   - noGrandpa: set to true if it is not allowed to reach the node you just came from
    /// - returns: the new graph after the extend
    func extend(_ kind: Kind, traversable:Set<Node.Kind>, map: Map, noGrandpa: Bool = false) -> DagStep?
    {
        var visited: [DagStep:DagStep] = [:]
        var addedSteps : [Node:DagStep] = [:]
        return extendStep(kind,
                          traversable: traversable,
                          map: map,
                          visited: &visited,
                          addedSteps: &addedSteps,
                          parent: noGrandpa ? self : nil)
    }
    
    /// Returns the set of leaf nodes
    /// - returns: the set of leaf nodes
    func leafNodes() -> Set<Node>
    {
        var nodes: Set<Node> = [];
        traverse() { (step) in
            if step.isLeaf() {
                nodes.insert(step.node)
            }
            return .doTraverse
        }
        return nodes;
    }
    
    /// Returns the set of all nodes in the graph, ignoring the leaf steps
    /// - returns: the set of nodes
    func reachedNodes() -> Set<Node>
    {
        var nodes: Set<Node> = [];
        traverse() { (step) in
            if !step.isLeaf() {
                nodes.insert(step.node)
            }
            return .doTraverse
        }
        return nodes;
    }
    
    private func nodesOnAllPathsStep(_ visited: inout [DagStep:Set<Node>]) -> Set<Node>
    {
        var nodes: Set<Node> = []
        var first = true
        
        if let existing = visited[self] {
            // if we have already examined this step, then simply return the previous result
            return existing
        }
        if !isLeaf() {
            for child in nextSteps {
                let result = child.nodesOnAllPathsStep(&visited)
                if first {
                    nodes = result
                    first = false
                } else {
                    nodes = nodes.intersection(result)
                }
            }
        }
        nodes.insert(node)
        visited[self] = nodes
        return nodes
    }
    
    /// Returns the nodes that are present on all possible paths through the graph
    /// - returns: the set of nodes
    func nodesOnAllPaths() -> Set<Node>
    {
        var visited: [DagStep:Set<Node>] = [:]
        return self.nodesOnAllPathsStep(&visited)
        
    }
    
    /// Creates a new graph with an added next step
    /// - parameters:
    ///   - node: the node for the next step
    /// - returns: the new graph
    func addNextStep(_ node:Node) -> DagStep
    {
        let newGraph = DagStep(self)
        newGraph.nextSteps = self.nextSteps
        newGraph.nextSteps.append(DagStep(node))
        return newGraph
    }
    
    private func printGraphStep(_ level: Int, visited:inout Set<DagStep>)
    {
        for _ in 0...level {
            print("  ", terminator:"")
        }
        if visited.contains(self) {
            print(String(format:"(%d)", node.number))
            return
        }
        print(node.number)
        visited.insert(self)
        for child in nextSteps {
            child.printGraphStep(level + 1, visited: &visited)
        }
    }
    
    /// Prints the graph for debugging purposes
    func printGraph()
    {
        var visited: Set<DagStep> = []
        self.printGraphStep(0, visited: &visited)
    }
    
    var hashValue: Int { return Unmanaged.passUnretained(self).toOpaque().hashValue }
    
    init(_ node:Node, _ kind:Kind = .walk)
    {
        self.node = node
        self.kind = kind
    }
    
    convenience init()
    {
        self.init(Node(0, CGPoint(x:0, y:0)))
    }
    
    convenience init(_ other: DagStep)
    {
        self.init(other.node, other.kind)
    }
}

func ==(lhs: DagStep, rhs: DagStep) -> Bool {
    return lhs === rhs
}

