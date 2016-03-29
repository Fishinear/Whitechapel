//
//  Game.swift
//  Whitechapel
//
//  Created by René Dekker on 26/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

class Game {
    var map = Map()
    var graph: Step = Step()
    var policeNodes: [String : Node] = [:]
    
    var currentJackLocations: Set<Node> { return graph.leafNodes() }
    var possibleJackPast: Set<Node> { return graph.reachedNodes() }
    var certainJackPast: Set<Node> { return graph.nodesOnAllPaths() }
    var possibleHideouts: Set<Node> = []
    var murderLocations: Set<Node> { return Set(graph.nextSteps.map { (step) in step.node }) }
    
    func doJackStep(kind:Map.StepKind) -> Bool
    {
        if let newPath = graph.extend(kind, map: map) {
            graph = newPath
            if (kind != .Coach) {
                return true
            }
            if let newPath = graph.extend(kind, map: map) {
                graph = newPath
                return true
            }
        }
        return false
    }
    
    func murder(node:Node) -> Bool
    {
        graph.nextSteps.append(Step(node))
        return true
    }
    
    func setNotVisited(node:Node) -> Bool
    {
        if let newGraph = graph.exclude(node) {
            graph = newGraph
            return true
        } else {
            return false
        }
    }
    
    func setVisited(node:Node) -> Bool
    {
        if let newGraph = graph.include(node) {
            graph = newGraph
            return true
        } else {
            return false
        }
    }
    
    func arrest(node:Node) -> Bool
    {
        if let newGraph = graph.excludeLeaf(node) {
            graph = newGraph
            return true
        } else {
            return false
        }
    }
    
    func newRound()
    {
        if (possibleHideouts.isEmpty) {
            possibleHideouts = currentJackLocations
        } else {
            possibleHideouts.intersectInPlace(currentJackLocations)
        }
        graph = Step()
    }
    
    func isMurderStillPossible() -> Bool
    {
        for step in graph.nextSteps {
            if !step.nextSteps.isEmpty {
                return false
            }
        }
        return true
    }

    func setPoliceLocation(name:String, loc:CGPoint) -> Node?
    {
        if let node = map.nodeAtLocation(loc, radius: 12) {
            if (node.kind == .Dot) {
                if let oldNode = policeNodes[name] {
                    oldNode.kind = .Dot
                }
                policeNodes[name] = node
                node.kind = .Police
                return node
            }
        }
        return nil
    }
    
}