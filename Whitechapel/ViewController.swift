//
//  ViewController.swift
//  Whitechapel
//
//  Created by René Dekker on 25/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var mapScrollView: UIScrollView!
    @IBOutlet weak var scrollViewContent: UIView!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var jackButton: UIBarButtonItem!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    let CIRCLE_RADIUS: CGFloat = 8
    
    var tiledLayer: CATiledLayer?
    var game = Game()
    var number = 1
    var possibleJackPositions: Set<Node> = []
    var certainJackPast: Set<Node> = []
    var possibleJackPast: Set<Node> = []
    
    func update() {
        certainJackPast = game.certainJackPast
        possibleJackPast = game.possibleJackPast
        possibleJackPositions = game.currentJackLocations
        mapView.setNeedsDisplay()
        game.graph.printGraph()
    }
        
    @IBAction func moveJack(sender: AnyObject) {
        let controller: UIAlertController
        if game.murderLocations.count == 0 {
            controller = UIAlertController(title: "Murder first", message: "Select a location to murder first", preferredStyle: .Alert)
            controller.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        } else {
            controller = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            controller.addAction(UIAlertAction(title: "Walk", style: .Default, handler: { (UIAlertAction) in
                self.game.doJackStep(.Walk)
                self.update()
            }))
            controller.addAction(UIAlertAction(title: "Coach", style: .Default, handler: { (UIAlertAction) in
                self.game.doJackStep(.Coach)
                self.update()
            }))
            controller.addAction(UIAlertAction(title: "Alley", style: .Default, handler: { (UIAlertAction) in
                self.game.doJackStep(.Alley)
                self.update()
            }))
            controller.addAction(UIAlertAction(title: "Reached Hideout", style: .Destructive, handler: { (UIAlertAction) in
                self.game.newRound()
                self.update()
            }))
            controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        }
        if let presenter = controller.popoverPresentationController {
            presenter.barButtonItem = jackButton
        }
        self.presentViewController(controller, animated: true, completion:nil)
    }
    
    func addPolice(name:String, color:UIColor, pt:CGPoint) {
        if let node = game.setPoliceLocation(name, loc: pt) {
            let view = PoliceView(withName:name, color: color, node:node)
            overlayView.addSubview(view)
            view.center = pt
            let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.dragPolice))
            view.addGestureRecognizer(dragGesture)
        }
    }
    
    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        let bbox = CGContextGetClipBoundingBox(ctx)
//        print(String(format: "bbox: %f, %f, %f, %f", bbox.origin.x, bbox.origin.y, bbox.size.width, bbox.size.height))

        let bounds = CGRectInset(bbox, -10, -10)

        CGContextSetGrayStrokeColor(ctx, 0, 1)
        CGContextSetLineCap(ctx, .Round)
        
        // draw the dotted lines for the paths
        CGContextSetLineWidth(ctx, 1)
        CGContextSetLineDash(ctx, 2, [2, 3], 2)
        for node in game.map.allNodes {
            for subNode in node.neighbourNodes.filter({ $0.kind != .Alley }) {
                if unsafeAddressOf(node) < unsafeAddressOf(subNode) {
                    let rect = CGRect(x: node.location.x,
                                      y: node.location.y,
                                      width: subNode.location.x - node.location.x,
                                      height: subNode.location.y - node.location.y)
                    if CGRectIntersectsRect(rect, bounds) {
                        CGContextMoveToPoint(ctx, node.location.x, node.location.y)
                        CGContextAddLineToPoint(ctx, subNode.location.x, subNode.location.y)
                        CGContextDrawPath(ctx, .Stroke)
                    }
                }
            }
        }
        
        CGContextSetLineWidth(ctx, 2)
        CGContextSetLineDash(ctx, 0, nil, 0)

        UIGraphicsPushContext(ctx)
        let font = UIFont.systemFontOfSize(6, weight: UIFontWeightBold)
        var attrs:[String: AnyObject] = [NSFontAttributeName : font]
        for (number, node) in game.map.nodes {
            let loc = node.location
            if (!CGRectContainsPoint(bounds, loc)) {
                continue
            }
            if (game.murderLocations.contains(node)) {
                CGContextSetRGBFillColor(ctx, 1, 0, 0, 1)
            } else if (certainJackPast.contains(node)) {
                CGContextSetRGBFillColor(ctx, 1, 1, 0, 1)
            } else if (possibleJackPast.contains(node)) {
                CGContextSetRGBFillColor(ctx, 1, 1, 0.7, 1)
            } else {
                CGContextSetGrayFillColor(ctx, 1, 1)
            }
            if (possibleJackPositions.contains(node)) {
                CGContextSetRGBStrokeColor(ctx, 1, 0, 0, 1)
            } else {
                CGContextSetGrayStrokeColor(ctx, 0, 1)
            }
            if (game.possibleHideouts.contains(node)) {
                CGContextSetLineDash(ctx, 0, [0, CGFloat(M_PI)], 2)
            } else {
                CGContextSetLineDash(ctx, 0, nil, 0)
            }
            CGContextAddArc(ctx, loc.x, loc.y, CIRCLE_RADIUS, 0, CGFloat(2 * M_PI), 1)
            CGContextClosePath(ctx)
            CGContextDrawPath(ctx, .FillStroke)
            
            let textColor = game.murderLocations.contains(node) ? UIColor.whiteColor() : UIColor.blackColor()
            attrs[NSForegroundColorAttributeName] = textColor
            let string: NSString = String(format: "%d", number)
            let size = string.sizeWithAttributes(attrs)
            let pt = CGPoint(x: loc.x - size.width / 2, y: loc.y - size.height / 2)
            string.drawAtPoint(pt, withAttributes: attrs)
        }

/*
        for node in game.map.allNodes {
            if (!CGRectContainsPoint(bounds, node.location)) {
                continue
            }
            if (node.kind != .Number) {
                CGContextSetRGBStrokeColor(ctx, node.kind == .Dot ? 1.0 : 0.0, 0.0, 1.0, 0.5)
                CGContextAddArc(ctx, node.location.x, node.location.y, 4, 0, CGFloat(2 * M_PI), 1)
                CGContextClosePath(ctx)
                CGContextDrawPath(ctx, .Stroke)
            }
            if (node.neighbourNodes.count <= 1) {
                print(String(format:"problem with %d  %f, %f: %d", node.number, node.location.x, node.location.y, node.neighbourNodes.count))
            }
        }
 */
 
        UIGraphicsPopContext()
    }
    
    //The event handling methods
    func handleSingleTap(recognizer:UITapGestureRecognizer)
    {
        let location = recognizer.locationInView(overlayView);
        print(String(format: "%1.0f,%1.0f, ", location.x, location.y))
        if let node = game.map.nodeAtLocation(location) {
            if (node.kind == .Number) {
                let controller = UIAlertController(title:nil, message: nil, preferredStyle: .ActionSheet)
                let notVisitedAction = UIAlertAction(title: "Not visited", style: .Default, handler: { (UIAlertAction) in
                    self.game.setNotVisited(node)
                    self.update()
                })
                let visitedAction = UIAlertAction(title: "Visited", style: .Default, handler: { (UIAlertAction) in
                    self.game.setVisited(node)
                    self.update()
                })
                let arrestAction = UIAlertAction(title: "Arrest", style: .Default, handler: { (UIAlertAction) in
                    self.game.arrest(node)
                    self.update()
                })
                let murderAction = UIAlertAction(title: "Murder", style: .Destructive, handler: { (UIAlertAction) in
                    self.game.murder(node)
                    self.update()
                })
                notVisitedAction.enabled = game.murderLocations.count > 0
                visitedAction.enabled = game.murderLocations.count > 0 &&
                                        (possibleJackPast.contains(node) || possibleJackPositions.contains(node))
                arrestAction.enabled = visitedAction.enabled
                murderAction.enabled = game.isMurderStillPossible()
                
                controller.addAction(notVisitedAction)
                controller.addAction(visitedAction)
                controller.addAction(arrestAction)
                controller.addAction(murderAction)
                
                controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                
                if let presenter = controller.popoverPresentationController {
                    presenter.sourceView = self.overlayView;
                    let rect = CGRect(x:node.location.x, y:node.location.y, width:0, height:0)
                    presenter.sourceRect = CGRectInset(rect, -CIRCLE_RADIUS, -CIRCLE_RADIUS);
                }
                self.presentViewController(controller, animated: true, completion:nil)
            }
        }
    }
    
    func dragPolice(recognizer:UIPanGestureRecognizer)
    {
        let location = recognizer.locationInView(overlayView);
        recognizer.view!.center = location
        if (recognizer.state == .Ended) {
            let view = recognizer.view! as! PoliceView
            if let node = game.setPoliceLocation(view.name, loc: location) {
                view.node = node
            }
            view.center = view.node.location
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView?
    {
        return scrollViewContent
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        let contentScale = scale * UIScreen.mainScreen().scale; // Handle retina
        for view in overlayView.subviews {
            view.contentScaleFactor = contentScale
        }
        
        print("zoom acale:\(scale)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tiledLayer = mapView.layer as! CATiledLayer
        tiledLayer.delegate = self
        tiledLayer.tileSize = CGSizeMake(256.0, 256.0)
            
        tiledLayer.levelsOfDetail = 5
        tiledLayer.levelsOfDetailBias = 5
        tiledLayer.frame = mapView.bounds
        
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleSingleTap))
        overlayView.addGestureRecognizer(singleFingerTap)
        mapScrollView.contentSize = scrollViewContent.frame.size
        
        /* Police Stations:
            377,362,
            413,247, (not correct?)
            730,390,
            228,445,
            740,150,
            731,391,
            556,175,
            392,146,
         */
        addPolice("Blue",   color: UIColor.blueColor(), pt: CGPoint(x: 377, y: 362))
        addPolice("Red",    color: UIColor.redColor(), pt: CGPoint(x: 740, y: 150))
        addPolice("Green",  color: UIColor.greenColor(), pt: CGPoint(x: 228, y: 445))
        addPolice("Yellow", color: UIColor.yellowColor(), pt: CGPoint(x: 731, y: 391))
        addPolice("Brown",  color: UIColor.orangeColor(), pt: CGPoint(x: 392, y: 146))
        update()
        dispatch_async(dispatch_get_main_queue()) { 
            self.mapScrollView.zoomScale = self.mapScrollView.frame.size.height / self.scrollViewContent.frame.size.height
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

