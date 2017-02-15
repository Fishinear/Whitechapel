//
//  DagStep.swift
//  Whitechapel
//
//  Created by René Dekker on 15/02/2017.
//  Copyright © 2017 Renevision. All rights reserved.
//

import UIKit

infix operator ||=
extension Bool {
    @discardableResult
    static func ||= (variable: inout Bool, value: Bool) -> Bool {
        variable = variable || value
        return variable
    }
}

class DagStep : Hashable {
    enum Kind : Int { case walk, coach, alley }
    
    var nextSteps : Array<DagStep> = []
    var kind : Kind
    var node : Node
    var deletedAtTime : Int
    
    var isLeaf : Bool { return nextSteps.isEmpty }
    
    /// Return the Traverse value from the action in traverse, if you want to traverse the tree
    static let Traverse = DagStep()
    
    fileprivate func traverseStep(_ visited:inout [DagStep:DagStep?], action:(DagStep) -> DagStep?) -> DagStep?
    {
        if let newStep = visited[self] {
            // if we have already examined this step, then simply return the previous result
            return newStep
        }
        var newStep = action(self)
        if newStep === DagStep.Traverse && !isLeaf {
            // if this is a Leaf node, then (if it should not be removed), we will keep it.
            // otherwise, we examine the children.
            
            let children = nextSteps.mapFilter {
                $0.traverseStep(&visited, action: action)
            }
            if children.isEmpty {
                // if the children are all removed, then this step cannot be reached either
                // and so it needs to be removed
                newStep = nil
            } else if children == nextSteps {
                // optimization: simply return self if the children have not changed
                newStep = self
            } else {
                // otherwise, create a new step with the new children
                newStep = DagStep(node, kind)
                newStep!.nextSteps = children
            }
        }
        if newStep === DagStep.Traverse {
            newStep = self
        }
        visited[self] = newStep
        return newStep
    }
    
    /// Traverse through the graph that is reachable from this step,
    /// and perform the action on each step in that graph. The function builds a new graph
    /// according to the instruction of the action and returns that
    /// - parameters:
    ///   - action: The action can return three values for a step, to determine what should be done. Return
    ///     - **a new step** to include the step and all its decendants (the new step can be the argument to action itself),
    ///     - **nil** to exclude the step and all its decendants, or
    ///     - **.Traverse** to include the step, unless all decendants are excluded.
    /// - returns: the new graph
    @discardableResult
    func traverse(_ action:(DagStep) -> DagStep?) -> DagStep?
    {
        var visited:[DagStep:DagStep?] = [:]
        return traverseStep(&visited, action: action)
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func exclude(_ excluded:Node) -> DagStep?
    {
        return traverse { (step) in step.node == excluded ? nil : .Traverse }
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node as a leaf
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func excludeLeaf(_ excluded:Node) -> DagStep?
    {
        return traverse { (step) in (step.isLeaf && step.node == excluded) ? nil : .Traverse }
    }
    
    /// Ensure that all paths through the graph contain a particular node
    /// - parameters:
    ///   - incuded: The node to include
    /// - returns: the reduced graph
    func include(_ included:Node) -> DagStep?
    {
        return traverse { (step) in step.node == included ? step : (step.isLeaf ? nil : .Traverse) }
    }
    
    
    fileprivate func extendStep(_ kind: Kind,
                                traversable:Set<Node.Kind>,
                                map: Map,
                                time:Int,
                                level:Int,
                                _ addedSteps:inout [Node:DagStep],
                                _ visitedLeaves:inout Set<DagStep>) -> Bool
    {
        if deletedAtTime <= time {
            return false
        }
        if level == time - 1 {
            if !visitedLeaves.contains(self) {
                let childNodes = map.reachable(from: node, traversable: traversable)
                nextSteps = childNodes.map { node in
                    addedSteps.getOrSet(node) { DagStep(node, kind) }
                }
                visitedLeaves.insert(self)
            }
        } else {
            var hasChildren = false
            for step in nextSteps {
                hasChildren ||= step.extendStep(kind,
                                                traversable: traversable,
                                                map: map,
                                                time: time,
                                                level: level+1,
                                                &addedSteps,
                                                &visitedLeaves)
            }
            if !hasChildren {
                deletedAtTime = time
                return false
            }
        }
        return true
    }
    
    /// Extend the graph with new steps with nodes that are reachable from the leaf nodes.
    /// Note that this can also remove steps from the graph, if they cannot reach any new nodes
    ///
    /// - parameters:
    ///   - kind: the kind of the new steps that are created
    ///   - traversable: the Node kinds that can be walked through to reach a neighbour Node
    ///   - map: the map to determine reachability from
    ///   - noGrandpa: set to true if it is not allowed to reach the node you just came from
    /// - returns: the new graph
    func extend(_ kind: Kind, traversable:Set<Node.Kind>, map: Map, time: Int) -> Bool
    {
        var addedSteps : [Node:DagStep] = [:]
        var visitedLeaves : Set<DagStep> = []
        return extendStep(kind,
                          traversable: traversable,
                          map: map,
                          time: time,
                          level: 0,
                          &addedSteps,
                          &visitedLeaves)
    }
    
    /// Returns the set of leaf nodes
    /// - returns: the set of leaf nodes
    func leafNodes() -> Set<Node>
    {
        var nodes: Set<Node> = [];
        traverse { (step) in
            if (step.isLeaf) {
                nodes.insert(step.node)
            }
            return .Traverse
        }
        return nodes;
    }
    
    /// Returns the set of all nodes in the graph, ignoring the leaf steps
    /// - returns: the set of nodes
    func reachedNodes() -> Set<Node>
    {
        var nodes: Set<Node> = [];
        traverse { (step) in
            if (!step.isLeaf) {
                nodes.insert(step.node)
            }
            return .Traverse
        }
        return nodes;
    }
    
    /// Returns the nodes that are present on all possible paths through the graph
    /// - returns: the set of nodes
    func nodesOnAllPaths() -> Set<Node>
    {
        var nodes: Set<Node> = []
        var isFirst = true
        for child in self.nextSteps {
            let childNodes = child.nodesOnAllPaths()
            if isFirst {
                nodes = childNodes;
                isFirst = false
            } else {
                nodes.formIntersection(childNodes)
            }
        }
        nodes.insert(self.node)
        return nodes
    }
    
    func printGraphStep(_ level: Int, visited:inout Set<DagStep>)
    {
        for _ in 0...level {
            print("  ", terminator:"")
        }
        if visited.contains(self) {
            print(String(format:"(%d)", self.node.number))
            return
        }
        print(self.node.number)
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
    
    init(_ node:Node, _ kind:Kind = .walk) {
        self.node = node
        self.kind = kind
        self.deletedAtTime = Int.max
    }
    
    convenience init() {
        self.init(Node(0, CGPoint(x:0, y:0)))
    }
}

func ==(lhs: DagStep, rhs: DagStep) -> Bool {
    return lhs === rhs
}

