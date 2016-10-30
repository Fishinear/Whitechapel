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
        self.backgroundColor = UIColor.clear
        self.isOpaque = false;
    }
    
    override func draw(_ rect: CGRect)
    {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(color.cgColor)
        ctx?.addArc(center: CGPoint(x:10,y:10), radius: 10, startAngle: 0, endAngle: CGFloat(2 * M_PI), clockwise: true)
        ctx?.closePath()
        ctx?.drawPath(using: .fill)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
