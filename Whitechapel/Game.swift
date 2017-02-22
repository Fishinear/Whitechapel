//
//  Game.swift
//  Whitechapel
//
//  Created by René Dekker on 26/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

class GameState {
    let description: String
    let graph: DagStep
    let policeNodes: [String : Node]
    
    init (description:String, graph:DagStep, policeNodes:[String:Node])
    {
        self.description = description
        self.graph = graph
        self.policeNodes = policeNodes
    }
}

class Game {
    let map = Map()
    var undoList: [GameState] = []
    var current: GameState
    
    var currentJackLocations: Set<Node> { return current.graph.leafNodes() }
    var possibleJackPast: Set<Node> { return current.graph.reachedNodes() }
    var certainJackPast: Set<Node> { return current.graph.nodesOnAllPaths() }
    var possibleHideouts: Set<Node> = []
    var murderLocations: Set<Node> { return Set(current.graph.nextSteps.map { (step) in step.node }) }
    
    init(policeLocations:[String:CGPoint])
    {
        var policeNodes: [String:Node] = [:]
        for name in policeLocations.keys {
            if let node = map.nodeAtLocation(policeLocations[name]!, radius: 20) {
                if (node.kind == .dot) {
                    node.kind = .police
                    policeNodes[name] = node
                }
            }
        }
        current = GameState(description:"initial", graph: DagStep(), policeNodes: policeNodes)
    }
    
    @discardableResult
    func undo() -> Bool
    {
        if undoList.isEmpty {
            return false
        }
        for node in current.policeNodes.values {
            node.kind = .dot
        }
        current = undoList.removeLast()
        for node in current.policeNodes.values {
            node.kind = .police
        }
        return true
    }
    
    func undoActionDescription() -> String?
    {
        if undoList.isEmpty {
            return nil
        } else {
            return current.description
        }
    }
    func addNewState(_ description:String, _ graph:DagStep)
    {
        undoList.append(current)
        current = GameState(description: description, graph: graph, policeNodes: current.policeNodes)
    }
    
    @discardableResult
    func doJackStep(_ kind:DagStep.Kind) -> Bool
    {
        let traversable: Set<Node.Kind>
        let name: String
        switch kind {
        case .walk:     name = "Walk";  traversable = [.dot, .connect]
        case .coach:    name = "Coach"; traversable = [.dot, .connect, .police]
        case .alley:    name = "Alley"; traversable = [.alley]
        }
        var newGraph = current.graph.extend(kind, traversable: traversable, map: map)
        if newGraph != nil && kind == .coach {
            newGraph = newGraph!.extend(kind, traversable: traversable, map: map, noGrandpa: true)
        }
        if newGraph != nil {
            addNewState(name, newGraph!)
        }
        return newGraph != nil
    }
    
    @discardableResult
    func murder(_ node:Node) -> Bool
    {
        addNewState("Murder at \(node.number)", current.graph.addNextStep(node))
        return true
    }
    
    @discardableResult
    func setNotVisited(_ node:Node) -> Bool
    {
        if let newGraph = current.graph.exclude(node) {
            addNewState("Not visited \(node.number)", newGraph)
            return true
        }
        return false
    }
    
    @discardableResult
    func setVisited(_ node:Node) -> Bool
    {
        if let newGraph = current.graph.include(node) {
            addNewState("Visited \(node.number)", newGraph)
            return true
        }
        return false
    }
    
    @discardableResult
    func arrest(_ node:Node) -> Bool
    {
        if let newGraph = current.graph.excludeLeaf(node) {
            addNewState("Failed arrest \(node.number)", newGraph)
            return true
        }
        return false
    }
    
    func newRound()
    {
        if (possibleHideouts.isEmpty) {
            possibleHideouts = currentJackLocations
        } else {
            possibleHideouts.formIntersection(currentJackLocations)
        }
        current = GameState(description:"Initial", graph:DagStep(), policeNodes:current.policeNodes)
        undoList = []
    }
    
    func isMurderStillPossible() -> Bool
    {
        return current.graph.nextSteps.isEmpty || current.graph.nextSteps.first!.nextSteps.isEmpty
    }

    func movePolice(_ name:String, loc:CGPoint) -> Node?
    {
        if let node = map.nodeAtLocation(loc, radius: 20) {
            if (node.kind == .dot) {
                undoList.append(current)
                var policeNodes = current.policeNodes
                if let oldNode = policeNodes[name] {
                    oldNode.kind = .dot
                }
                policeNodes[name] = node
                node.kind = .police
                current = GameState(description: "\(name) move", graph: current.graph, policeNodes: policeNodes)
                return node
            }
        }
        return nil
    }

}
