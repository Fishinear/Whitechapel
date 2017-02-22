//
//  Extensions.swift
//  Whitechapel
//
//  Created by René Dekker on 17/02/2017.
//  Copyright © 2017 Renevision. All rights reserved.
//

import Foundation

infix operator ||=
extension Bool {
    @discardableResult
    static func ||= (variable: inout Bool, value: Bool) -> Bool {
        variable = variable || value
        return variable
    }
}

infix operator &&=
extension Bool {
    @discardableResult
    static func &&= (variable: inout Bool, value: Bool) -> Bool {
        variable = variable && value
        return variable
    }
}

extension Dictionary {
    mutating func getOrSet(_ key:Key, _ action:() -> Value) -> Value
    {
        if let value = self[key] {
            return value
        } else {
            let value = action()
            self[key] = value
            return value
        }
    }

    func mapValues<T>(transform: (Value)->T) -> Dictionary<Key,T> {
        var dict = [Key:T]()
        for (key, value) in zip(self.keys, self.values.map(transform)) {
            dict[key] = value
        }
        return dict
    }
}

extension Sequence {
    func mapFilter<T>(_ function: (Self.Iterator.Element) throws -> T?) rethrows -> [T]
    {
        var result:Array<T> = []
        self.forEach { (element: Self.Iterator.Element) in
            if let ne = try? function(element) {
                if let ne = ne {
                    result.append(ne)
                }
            }
        }
        return result
    }
}

