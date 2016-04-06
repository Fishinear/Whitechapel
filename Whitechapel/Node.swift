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
    enum Kind { case Number, Dot, Police, Alley, Connect }
    var kind: Kind = .Number
    var number: Int
    var location: CGPoint
    var neighbourNodes: Set<Node> = []
    
    var hashValue: Int { return unsafeAddressOf(self).hashValue }
    
    init(_ num:Int, _ loc: CGPoint) {
        number = num
        location = loc
    }
}

func ==(lhs: Node, rhs: Node) -> Bool {
    return lhs === rhs
}
