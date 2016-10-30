//
//  TiledView.swift
//  Whitechapel
//
//  Created by René Dekker on 26/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

class TiledView : UIView {
    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }
}
