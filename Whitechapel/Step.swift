//
//  Step.swift
//  Whitechapel
//
//  Created by René Dekker on 25/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

extension Dictionary {
    mutating func getOrSet(key:Key, _ action:() -> Value) -> Value
    {
        if let value = self[key] {
            return value
        } else {
            let value = action()
            self[key] = value
            return value
        }
    }
}

class Step : Hashable {
    enum TraverseKind { case Include, Exclude, Traverse }
    
    var nextSteps : Array<Step> = []
    var kind : Map.StepKind
    var node : Node
    
    var isLeaf : Bool { return nextSteps.isEmpty }
    
    func traverseStep(inout visited:[Step:Step?], action:(Step) -> TraverseKind) -> Step?
    {
        if let newStep = visited[self] {
            // if we have already examined this step, then simply return the previous result
            print("step: (\(self.node.number)) => \(newStep != nil)")
            return newStep
        }
        let result = action(self)
        print("step: \(self.node.number) => \(result)")
        var newStep : Step? = self
        if result == .Exclude {
            newStep = nil
        } else if result == .Traverse && !nextSteps.isEmpty {
            // if this step should be included, then we simply keep it without traversing
            // the descendants, because they may still be excluded from other paths
            // if this is a Leaf node, then (if it should not be removed), we will keep it.
            // otherwise, we examine the children.
            
            var children: Array<Step> = []
            for child in nextSteps {
                if let newChild = child.traverseStep(&visited, action: action) {
                    children.append(newChild)
                }
            }
            print("     \(self.node.number) => \(children.isEmpty)")
            if children.isEmpty {
                // if the children are all removed, then this step cannot be reached either
                // and so it needs to be removed
                newStep = nil
            } else if children != nextSteps {
                // optimization: simply return self if the children have not changed
                // otherwise, create a new step with the new children
                newStep = Step(node, kind)
                newStep!.nextSteps = children
            }
        }
        visited[self] = newStep
        return newStep
    }

    /// Traverse through the graph that is reachable from this step,
    /// and perform the action on each step in that graph. The function builds a new graph 
    /// according to the instruction of the action and returns that
    /// - parameters:
    ///   - action: The action can return three values for a step, to determine what should be done. Return
    ///     - **.Include** to include the step and all its decendants,
    ///     - **.Exclude** to exclude the step and all its decendants, or
    ///     - **.Traverse** to include the step, unless all decendants are excluded.
    /// - returns: the new graph
    func traverse(action:(Step) -> TraverseKind) -> Step?
    {
        var visited:[Step:Step?] = [:]
        return traverseStep(&visited, action: action)
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func exclude(excluded:Node) -> Step? {
        return traverse { (step) in step.node == excluded ? .Exclude : .Traverse }
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node as a leaf
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func excludeLeaf(excluded:Node) -> Step? {
        return traverse { (step) in (step.isLeaf && step.node == excluded) ? .Exclude : .Traverse }
    }
    
    /// Ensure that all paths through the graph contain a particular node
    /// - parameters:
    ///   - incuded: The node to include
    /// - returns: the reduced graph
    func include(included:Node) -> Step? {
        return traverse { (step) in step.node == included ? .Include : step.isLeaf ? .Exclude : .Traverse }
    }
    
    /// Extend the graph with new steps with nodes that are reachable from the leaf nodes.
    /// Note that this can also remove steps from the graph, if they cannot reach any new nodes
    ///
    /// _This has a confusing implementation, because it does not only build a new graph, but adds children to
    /// the existing graph as well. We should probably rewrite it_
    /// - parameters:
    ///   - kind: the type of reachability to be used
    ///   - map: the map to determine reachability from
    /// - returns: the new graph
    func extend(kind: Map.StepKind, map: Map) -> Step? {
        var addedSteps : [Node:Step] = [:]
        let result = traverse { (step) in
            if !step.isLeaf {
                return .Traverse
            }
            let nodes = map.reachable(from:step.node, kind:kind)
            if nodes.isEmpty {
                return .Exclude
            }
            step.nextSteps = Array(nodes).map {(node) in
                addedSteps.getOrSet(node) { Step(node, kind) }
            }
            return .Include
        }
        return result
    }
    
    /// Returns the set of leaf nodes
    /// - returns: the set of leaf nodes
    func leafNodes() -> Set<Node> {
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
    func reachedNodes() -> Set<Node> {
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
    func nodesOnAllPaths() -> Set<Node> {
        var nodes: Set<Node> = []
        var isFirst = true
        for child in self.nextSteps {
            let childNodes = child.nodesOnAllPaths()
            if isFirst {
                nodes = childNodes;
                isFirst = false
            } else {
                nodes.intersectInPlace(childNodes)
            }
        }
        nodes.insert(self.node)
        return nodes
    }
 
    func printGraphStep(level: Int, inout visited:Set<Step>)
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
        var visited: Set<Step> = []
        self.printGraphStep(0, visited: &visited)
    }

    var hashValue: Int { return unsafeAddressOf(self).hashValue }
    
    init(_ node:Node, _ kind:Map.StepKind = .Walk) {
        self.node = node;
        self.kind = kind;
    }
    
    convenience init() {
        self.init(Node(0, CGPoint(x:0, y:0)))
    }
}

func ==(lhs: Step, rhs: Step) -> Bool {
    return lhs === rhs
}

