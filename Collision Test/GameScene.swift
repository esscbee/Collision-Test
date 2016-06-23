//
//  GameScene.swift
//  Collision Test
//
//  Created by Stephen Brennan on 6/22/16.
//  Copyright (c) 2016 Stephen Brennan. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        let myLabel = SKLabelNode(fontNamed:"Chalkduster")
        myLabel.text = "Hello, World!"
        myLabel.fontSize = 45
        myLabel.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame))
        
        //self.addChild(myLabel)
        // we live in a world with gravity on the y axis
        self.physicsWorld.gravity = CGVectorMake(0, -6)
        
        self.scaleMode = SKSceneScaleMode.ResizeFill
        self.physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
        print(frame)

    }
    override func didChangeSize(oldSize: CGSize) {
        physicsBody = SKPhysicsBody(edgeLoopFromRect: frame)
    }
    
    var counter: UInt32 = 0

    var touchedNodes = [UITouch: Set<TouchedNode>]()
    var nodesMoved = Set<SKNode>()
    
    
    func insertTouch(touch:UITouch, tn:TouchedNode) {
        var ts = touchedNodes[touch]
        if ts == nil {
            ts = Set<TouchedNode>()
            ts?.insert(tn)
            touchedNodes[touch] = ts
        } else {
            ts?.insert(tn)
            touchedNodes[touch] = ts
        }
    }
    

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        
        for touch in touches {
            let location = touch.locationInNode(self)
            var found = false
            self.enumerateChildNodesWithName(NumberLabel.labelName, usingBlock: {
                node, stop in
                if(CGRectContainsPoint(node.frame, location)) {
                    self.insertTouch(touch, tn: TouchedNode(lastPos: location, lastTime: touch.timestamp, node: node))
                    node.physicsBody?.dynamic = false
                    found = true
                }
            })
            
            
            if !found {
                let myLabel  = NumberLabel(num: counter, fontNamed:"Chalkduster", location: location)
                let tn = TouchedNode(lastPos: location, lastTime: touch.timestamp, node: myLabel)
                insertTouch(touch, tn: tn)
                self.nodesMoved.insert(myLabel)
                self.addChild(myLabel)

            }
            counter += 1
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if let touched = self.touchedNodes[touch] {
                for tn in touched {
                    let node = tn.node
                    self.nodesMoved.insert(node)
                    let location = touch.locationInNode(self)
                    node.position = location
                    tn.lastPos = location
                    tn.lastTime = touch.timestamp
                }
            }
        }
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            if let touched = self.touchedNodes[touch] {
                for tn in touched {
                    let node = tn.node
                    if !nodesMoved.contains(node) {
                        node.removeFromParent()
                        counter -= 1
                    } else {
                        nodesMoved.remove(node)
                        // acceleration
                        let loc = touch.locationInNode(self)
                        let ll = tn.lastPos
                        var dx = loc.x - ll.x
                        var dy = loc.y - ll.y
                        let mag = sqrt(dx*dx+dy*dy)
                        
                        
                        let dt = CGFloat(touch.timestamp - tn.lastTime)
                        let k = CGFloat(2000.0)
                        
                        dx = k * (dx / mag) / dt
                        dy = k * (dy / mag) / dt
                        
                        node.physicsBody?.dynamic = true
                        node.physicsBody?.applyForce(CGVector(dx: dx, dy: dy))
                        
                    }
                }
                touchedNodes.removeValueForKey(touch)
            }
        }
    }

   
    func clear() {
        self.enumerateChildNodesWithName("number", usingBlock: {
            node, stop in
            node.removeFromParent()
        })
        self.counter = 0
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}

enum STATE {
    case Binary
    case Hex
    case Decimal
}

class NumberLabel : SKLabelNode {
    static let labelName = "number"
    
    
    var state : STATE = .Binary
    var num : UInt32 = 0
    var timer: NSTimer?
    
    required init(num: UInt32, fontNamed: String?, location: CGPoint?) {
        super.init()
        self.num = num
        self.fontSize = 45
        self.fontName = fontNamed
        self.name = NumberLabel.labelName
        
        if let p = location {
            self.position = p
        }
        render()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(timerCallback), userInfo: nil, repeats: true)
        
    }
    
    func timerCallback() {
        nextState()
        render()
    }
    
    deinit {
        if let t = timer {
            t.delete(self)
            timer = nil
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func randomDelta(range : Int) -> Int {
        let ret = random() % range
        return ret - Int(range / 2)
    }
    
    func render() {
        switch(state) {
        case .Binary:
            self.text = "0" + String(num, radix: 2) + "b"
            break
        case .Hex:
            self.text = "0" + String(num, radix: 16) + "x"
            break
        case .Decimal:
            self.text = String(num)
            break
        }
        self.physicsBody = SKPhysicsBody(rectangleOfSize:  self.frame.size)
        
        if let pb = self.physicsBody {
            pb.affectedByGravity = false
            pb.mass = 1 + CGFloat(num)
            pb.restitution = 0.1
            pb.categoryBitMask = num
            pb.collisionBitMask = num
            pb.friction = 0.01
            pb.applyImpulse(CGVector(dx: randomDelta(15000), dy: randomDelta(15000)))
            pb.dynamic = true
        }
    }
    func nextState() {
        switch(state) {
        case .Binary:
            self.state = .Hex
        case .Hex:
            self.state = .Decimal
        case .Decimal:
            self.state = .Binary
        }
        render()
    }
}

class TouchedNode : Hashable {
    var lastPos: CGPoint
    var lastTime: NSTimeInterval
    var node: SKNode
    
    init(lastPos: CGPoint, lastTime: NSTimeInterval, node: SKNode) {
        self.lastPos = lastPos
        self.lastTime = lastTime
        self.node = node
    }
    var hashValue: Int {
        return node.hashValue
    }
}
func ==(lhs: TouchedNode, rhs: TouchedNode) -> Bool {
    return lhs.node == rhs.node
}
