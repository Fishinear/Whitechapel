//
//  Node.swift
//  Whitechapel
//
//  Created by René Dekker on 25/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import Foundation
import UIKit

class Node : Hashable {
    enum Kind { case number, dot, police, alley, connect }
    var kind: Kind = .number
    var number: Int
    var location: CGPoint
    var neighbourNodes: Set<Node> = []
    
    var hashValue: Int { return Unmanaged.passUnretained(self).toOpaque().hashValue }
    
    init(_ num:Int, _ loc: CGPoint) {
        number = num
        location = loc
    }
}

func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs === rhs
}
