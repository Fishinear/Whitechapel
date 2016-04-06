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

extension SequenceType {
    func mapFilter<T>(function: (Self.Generator.Element) throws -> T?) rethrows -> [T]
    {
        var result:Array<T> = []
        self.forEach { (element: Self.Generator.Element) in
            if let ne = try? function(element) {
                if let ne = ne {
                    result.append(ne)
                }
            }
        }
        return result
    }
}

class Step : Hashable {
    enum Kind : Int { case Walk, Coach, Alley }
    
    var nextSteps : Array<Step> = []
    var kind : Kind
    var node : Node
    
    var isLeaf : Bool { return nextSteps.isEmpty }
    
    /// Return the Traverse value from the action in traverse, if you want to traverse the tree
    static let Traverse = Step()
    
    private func traverseStep(inout visited:[Step:Step?], action:(Step) -> Step?) -> Step?
    {
        if let newStep = visited[self] {
            // if we have already examined this step, then simply return the previous result
            return newStep
        }
        var newStep = action(self)
        if newStep === Step.Traverse && !isLeaf {
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
                newStep = Step(node, kind)
                newStep!.nextSteps = children
            }
        }
        if newStep === Step.Traverse {
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
    func traverse(action:(Step) -> Step?) -> Step?
    {
        var visited:[Step:Step?] = [:]
        return traverseStep(&visited, action: action)
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func exclude(excluded:Node) -> Step?
    {
        return traverse { (step) in step.node == excluded ? nil : .Traverse }
    }
    
    /// Ensures that all paths through the graph do **not** contain a particular node as a leaf
    /// - parameters:
    ///   - excluded: The node to exclude
    /// - returns: the reduced graph
    func excludeLeaf(excluded:Node) -> Step?
    {
        return traverse { (step) in (step.isLeaf && step.node == excluded) ? nil : .Traverse }
    }
    
    /// Ensure that all paths through the graph contain a particular node
    /// - parameters:
    ///   - incuded: The node to include
    /// - returns: the reduced graph
    func include(included:Node) -> Step?
    {
        return traverse { (step) in step.node == included ? step : (step.isLeaf ? nil : .Traverse) }
    }
    
    
    private func extendStep(kind: Kind,
                    traversable:Set<Node.Kind>,
                    map: Map,
                    inout addedSteps:[Node:Step],
                    parent:Node?) -> Step?
    {
        let newStep = Step(node, kind)
        if isLeaf {
            let childNodes = map.reachable(from: node, traversable: traversable).filter { $0 != parent }
            newStep.nextSteps = childNodes.map { node in
                addedSteps.getOrSet(node) { Step(node, kind) }
            }
        } else {
            newStep.nextSteps = nextSteps.mapFilter { step in
                step.extendStep(kind,
                    traversable: traversable,
                    map: map,
                    addedSteps: &addedSteps,
                    parent: parent != nil ? self.node : nil)
            }
        }
        return newStep.nextSteps.isEmpty ? nil : newStep
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
    func extend(kind: Kind, traversable:Set<Node.Kind>, map: Map, noGrandpa: Bool = false) -> Step?
    {
        var addedSteps : [Node:Step] = [:]
        return extendStep(kind,
                          traversable: traversable,
                          map: map,
                          addedSteps: &addedSteps,
                          parent: noGrandpa ? self.node : nil)
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
    
    init(_ node:Node, _ kind:Kind = .Walk) {
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

