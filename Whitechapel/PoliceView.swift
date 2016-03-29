//
//  PoliceView.swift
//  Whitechapel
//
//  Created by René Dekker on 26/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

class PoliceView : UIView {
    var color: UIColor
    var name: String
    var node: Node
    
    init(withName:String, color: UIColor, node: Node) {
        self.name = withName
        self.color = color
        self.node = node
        super.init(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        self.backgroundColor = UIColor.clearColor()
        self.opaque = false;
    }
    
    override func drawRect(rect: CGRect)
    {
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(ctx, color.CGColor)
        CGContextAddArc(ctx, 10, 10, 10, 0, CGFloat(2 * M_PI), 1)
        CGContextClosePath(ctx)
        CGContextDrawPath(ctx, .Fill)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}