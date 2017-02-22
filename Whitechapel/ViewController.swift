//
//  ViewController.swift
//  Whitechapel
//
//  Created by René Dekker on 25/03/2016.
//  Copyright © 2016 Renevision. All rights reserved.
//

import UIKit

extension UIImage {
    
    func addShadow(blurSize: CGFloat = 6.0) -> UIImage {
        
        let shadowColor = UIColor(red:0.87, green:0.78, blue:0.67, alpha:0.8).cgColor
        
        let context = CGContext(data: nil,
                                width: Int(self.size.width + blurSize),
                                height: Int(self.size.height + blurSize),
                                bitsPerComponent: self.cgImage!.bitsPerComponent,
                                bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        context.setShadow(offset: CGSize(width: blurSize/2,height: -blurSize/2),
                          blur: blurSize,
                          color: shadowColor)
        context.draw(self.cgImage!,
                     in: CGRect(x: 0, y: blurSize, width: self.size.width, height: self.size.height),
                     byTiling:false);
        
        return UIImage(cgImage: context.makeImage()!)
    }
}

class ViewController: UIViewController, UIScrollViewDelegate, CALayerDelegate
{
    
    @IBOutlet weak var mapScrollView: UIScrollView!
    @IBOutlet weak var scrollViewContent: UIView!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var jackButton: UIButton!
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    let CIRCLE_RADIUS: CGFloat = 8
    
    var mapContentSize = CGSize()
    var tiledLayer: CATiledLayer?
    var game: Game = Game(policeLocations: [:])
    var number = 1
    var possibleJackPositions: Set<Node> = []
    var certainJackPast: Set<Node> = []
    var possibleJackPast: Set<Node> = []
    var policeViews: [String:PoliceView] = [:]
    
    func update()
    {
        certainJackPast = game.certainJackPast
        possibleJackPast = game.possibleJackPast
        possibleJackPositions = game.currentJackLocations
        mapView.setNeedsDisplay()
        game.current.graph.printGraph()
        policeViews.forEach { (name: String, view: PoliceView) in
            view.update(node:game.current.policeNodes[name]!)
        }
    }
    
    @IBAction
    func moveJack(_ sender: AnyObject)
    {
        let enabled = game.murderLocations.count != 0
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let undoDescription = game.undoActionDescription()
        var action = UIAlertAction(title: undoDescription != nil ? "Undo \(undoDescription!)" : "Undo",
                                   style: .default,
                                   handler: { _ in
            self.game.undo()
            self.update()
        })
        action.isEnabled = undoDescription != nil
        controller.addAction(action)
        action = UIAlertAction(title: "Walk", style: .default, handler: { _ in
            self.game.doJackStep(.walk)
            self.update()
        })
        action.isEnabled = enabled
        controller.addAction(action)
        action = UIAlertAction(title: "Coach", style: .default, handler: { _ in
            self.game.doJackStep(.coach)
            self.update()
        })
        action.isEnabled = enabled
        controller.addAction(action)
        action = UIAlertAction(title: "Alley", style: .default, handler: { _ in
            self.game.doJackStep(.alley)
            self.update()
        })
        action.isEnabled = enabled
        controller.addAction(action)
        action = UIAlertAction(title: "Walk to hideout", style: .destructive, handler: { _ in
            let confirmation = UIAlertController(title: "Start new round",
                                                 message: "Are you sure you want Jack to walk to his hideout and start a new round?",
                                                 preferredStyle: .alert)
            confirmation.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirmation.addAction(UIAlertAction(title: "New round", style: .destructive, handler: { _ in
                self.game.doJackStep(.walk)
                self.game.newRound()
                self.update()
            }))
            confirmation.view.layoutIfNeeded()
            self.present(confirmation, animated: true, completion: nil)
        })
        action.isEnabled = enabled
        controller.addAction(action)
        
        controller.addAction(UIAlertAction(title: "New game", style: .destructive, handler: { _ in
            let confirmation = UIAlertController(title: "Start new game",
                                                 message: "Are you sure you want to start a new game?",
                                                 preferredStyle: .alert)
            if !enabled && self.game.possibleHideouts.isEmpty {
                confirmation.message = "Select a murder location to start the game"
                confirmation.addAction(UIAlertAction(title: "OK", style: .cancel))
            } else {
                confirmation.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                confirmation.addAction(UIAlertAction(title: "New game", style: .destructive, handler: { _ in
                    self.resetGame()
                }))
            }
            confirmation.view.layoutIfNeeded()
            self.present(confirmation, animated: true, completion: nil)
        }))
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        controller.popoverPresentationController?.sourceView = jackButton.superview
        controller.popoverPresentationController?.sourceRect = jackButton.frame

        controller.view.layoutIfNeeded()
        self.present(controller, animated: true, completion:nil)
    }
    
    func resetGame()
    {
        // Police Stations:
        let policeData = ["Blue":   (CGPoint(x: 377, y: 362), UIColor.blue),
                          "Red":    (CGPoint(x: 740, y: 150), UIColor.red),
                          "Green":  (CGPoint(x: 228, y: 445), UIColor.green),
                          "Yellow": (CGPoint(x: 731, y: 391), UIColor.yellow),
                          "Brown":  (CGPoint(x: 392, y: 146), UIColor.orange),
//                          "":       (CGPoint(x: 556, y: 175), UIColor.black),
//                          "":       (CGPoint(x: 593, y: 351), UIColor.black),
                          ]
        
        game = Game(policeLocations: policeData.mapValues(transform: { $0.0 }))
        
        overlayView.subviews.forEach { $0.removeFromSuperview() }
        
        policeData.forEach { (name: String, data: (location: CGPoint, color: UIColor)) in
            if let node = game.current.policeNodes[name] {
                let view = PoliceView(withName:name, color: data.color, node:node)
                overlayView.addSubview(view)
                view.center = node.location
                let dragGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.dragPolice))
                view.addGestureRecognizer(dragGesture)
                let scrollGesture = mapScrollView.panGestureRecognizer
                scrollGesture.require(toFail: dragGesture)
                policeViews[name] = view
            }
        }

        update()
        DispatchQueue.main.async {
            self.setMinZoom(size: self.mapScrollView.frame.size)
            self.mapScrollView.zoomScale = self.mapScrollView.minimumZoomScale;
        }
    }
    
    func draw(_ layer: CALayer, in ctx: CGContext)
    {
        let bbox = ctx.boundingBoxOfClipPath
//        print(String(format: "bbox: %f, %f, %f, %f", bbox.origin.x, bbox.origin.y, bbox.size.width, bbox.size.height))

        let bounds = bbox.insetBy(dx: -10, dy: -10)

        ctx.setStrokeColor(gray: 0, alpha: 1)
        ctx.setLineCap(.round)
        
        // draw the dotted lines for the paths
        ctx.setLineWidth(1)
        ctx.setLineDash(phase: 2, lengths: [2, 3]);
        for node in game.map.allNodes {
            for subNode in node.neighbourNodes.filter({ $0.kind != .alley }) {
                if Unmanaged.passUnretained(node).toOpaque() < Unmanaged.passUnretained(subNode).toOpaque() {
                    let rect = CGRect(x: node.location.x,
                                      y: node.location.y,
                                      width: subNode.location.x - node.location.x,
                                      height: subNode.location.y - node.location.y)
                    if rect.intersects(bounds) {
                        ctx.move(to: CGPoint(x: node.location.x, y: node.location.y))
                        ctx.addLine(to: CGPoint(x: subNode.location.x, y: subNode.location.y))
                        ctx.drawPath(using: .stroke)
                    }
                }
            }
        }
        
        ctx.setLineWidth(2)
        ctx.setLineDash(phase:0, lengths:[]);

        UIGraphicsPushContext(ctx)
        let font = UIFont.systemFont(ofSize: 6, weight: UIFontWeightBold)
        var attrs:[String: AnyObject] = [NSFontAttributeName : font]
        for (number, node) in game.map.nodes {
            let loc = node.location
            if (!bounds.contains(loc)) {
                continue
            }
            if (game.murderLocations.contains(node)) {
                ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 1)
            } else if (certainJackPast.contains(node)) {
                ctx.setFillColor(red: 1, green: 1, blue: 0, alpha: 1)
            } else if (possibleJackPast.contains(node)) {
                ctx.setFillColor(red: 1, green: 1, blue: 0.7, alpha: 1)
            } else {
                ctx.setFillColor(gray: 1, alpha: 1)
            }
            if (possibleJackPositions.contains(node)) {
                ctx.setStrokeColor(red: 1, green: 0, blue: 0, alpha: 1)
            } else {
                ctx.setStrokeColor(gray: 0, alpha: 1)
            }
            if (game.possibleHideouts.contains(node)) {
                ctx.setLineDash(phase: 0, lengths: [0, CGFloat(M_PI)]);
            } else {
                ctx.setLineDash(phase: 0, lengths: []);
            }
            ctx.addArc(center: loc, radius: CIRCLE_RADIUS, startAngle: 0, endAngle:  CGFloat(2 * M_PI), clockwise: true)
            ctx.closePath()
            ctx.drawPath(using: .fillStroke)
            
            let textColor = game.murderLocations.contains(node) ? UIColor.white : UIColor.black
            attrs[NSForegroundColorAttributeName] = textColor
            let string: NSString = String(format: "%d", number) as NSString
            let size = string.size(attributes: attrs)
            let pt = CGPoint(x: loc.x - size.width / 2, y: loc.y - size.height / 2)
            string.draw(at: pt, withAttributes: attrs)
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
    func handleSingleTap(_ recognizer:UITapGestureRecognizer)
    {
        let location = recognizer.location(in: overlayView);
        print(String(format: "%1.0f,%1.0f, ", location.x, location.y))
        if let node = game.map.nodeAtLocation(location) {
            if (node.kind == .number) {
                let controller = UIAlertController(title:nil, message: nil, preferredStyle: .actionSheet)
                let notVisitedAction = UIAlertAction(title: "Not visited", style: .default, handler: { (UIAlertAction) in
                    self.game.setNotVisited(node)
                    self.update()
                })
                let visitedAction = UIAlertAction(title: "Visited", style: .default, handler: { (UIAlertAction) in
                    self.game.setVisited(node)
                    self.update()
                })
                let arrestAction = UIAlertAction(title: "Failed arrest", style: .default, handler: { (UIAlertAction) in
                    self.game.arrest(node)
                    self.update()
                })
                let murderAction = UIAlertAction(title: "Murder", style: .destructive, handler: { (UIAlertAction) in
                    self.game.murder(node)
                    self.update()
                })
                notVisitedAction.isEnabled = game.murderLocations.count > 0
                visitedAction.isEnabled = game.murderLocations.count > 0 &&
                                        (possibleJackPast.contains(node) || possibleJackPositions.contains(node))
                arrestAction.isEnabled = visitedAction.isEnabled
                murderAction.isEnabled = game.isMurderStillPossible()
                
                controller.addAction(notVisitedAction)
                controller.addAction(visitedAction)
                controller.addAction(arrestAction)
                controller.addAction(murderAction)
                
                controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                
                controller.view.layoutIfNeeded()
                if let presenter = controller.popoverPresentationController {
                    presenter.sourceView = self.overlayView;
                    let rect = CGRect(x:node.location.x, y:node.location.y, width:0, height:0)
                    presenter.sourceRect = rect.insetBy(dx: -CIRCLE_RADIUS, dy: -CIRCLE_RADIUS);
                }
                self.present(controller, animated: true, completion:nil)
            }
        }
    }
    
    func dragPolice(_ recognizer:UIPanGestureRecognizer)
    {
        let location = recognizer.location(in: overlayView);
        recognizer.view!.center = location
        if (recognizer.state == .ended) {
            let view = recognizer.view! as! PoliceView
            if let node = game.movePolice(view.name, loc: location) {
                view.update(node: node)
            }
            view.center = view.node.location
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
        return scrollViewContent
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        let contentScale = scale * UIScreen.main.scale; // Handle retina
//        for view in overlayView.subviews {
//            view.contentScaleFactor = contentScale
//        }
//        
        print("zoom acale:\(scale) minzoom:\(mapScrollView.minimumZoomScale) size:\(mapScrollView.frame.size)")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        setMinZoom(size: size);
    }

    func setMinZoom(size: CGSize)
    {
        let minZoomScale = max(1, size.width / mapContentSize.width, size.height / mapContentSize.height)
        print("minzoom current:\(mapScrollView.minimumZoomScale) new:\(minZoomScale) size:\(size) content:\(mapContentSize) contentSize:\(mapScrollView.contentSize)")
        mapScrollView.minimumZoomScale = minZoomScale
        if mapScrollView.zoomScale < minZoomScale {
            mapScrollView.zoomScale = minZoomScale
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let image = jackButton.image(for:.normal)!
        jackButton.setImage(image.addShadow(blurSize:6.0), for: .normal)
        let tiledLayer = mapView.layer as! CATiledLayer
        tiledLayer.delegate = self
        tiledLayer.tileSize = CGSize(width: 1024, height: 1024)
            
        tiledLayer.levelsOfDetail = 5
        tiledLayer.levelsOfDetailBias = 5
        tiledLayer.frame = mapView.bounds
        
       // mapView.contentScaleFactor = 1
        
        let singleFingerTap = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleSingleTap))
        overlayView.addGestureRecognizer(singleFingerTap)
        mapContentSize = scrollViewContent.frame.size
        mapScrollView.contentSize = mapContentSize
        
        resetGame()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

