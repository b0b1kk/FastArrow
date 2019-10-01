//
//  GameScene.swift
//  FastArrow
//
//  Created by Bogdan Mishura on 9/15/19.
//  Copyright © 2019 Bogdan Mishura. All rights reserved.
//

import SpriteKit
import GameplayKit

func +(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func -(left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func *(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func /(point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch (x86_64) || arch (arm64))
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrt(Float(a)))
}

#endif
extension CGPoint {
    func length() -> CGFloat {
        return sqrt(y * y)
        
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}


class GameScene: SKScene {
    
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let all: UInt32 = UInt32.max
        static let target: UInt32 = 0b1   //1
        static let projectile: UInt32 = 0b10  //2
    }
    //number for moving to arrow
    let pointOnX: CGFloat = 100
    
    
    let player = SKSpriteNode(imageNamed: "arrow")
    
    var targetDestroyed = 0
    
    var scoreLabel: SKLabelNode!
    
    var timer = Timer()
    
    override func didMove(to view: SKView) {
        
        // create background
        let background = SKSpriteNode(imageNamed: "background")
        background.position = view.center
        background.size = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2)
        addChild(background)
        
        // create playr arrow
        player.position = CGPoint(x: size.width * 0.5, y: size.height * 0.1)
        addChild(player)
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run(addTarget), SKAction.wait(forDuration: 1.0)
            ])))
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        // create score label
        scoreLabel = SKLabelNode()
        scoreLabel.text = "Score: \(targetDestroyed)"
        scoreLabel.position = CGPoint(x: frame.size.width * 0.25, y: frame.size.height - scoreLabel.calculateAccumulatedFrame().height - 35)
        scoreLabel.fontColor = .yellow
        scoreLabel.fontName = "Chalkduster"
        addChild(scoreLabel)
        
        
    }
    
    
    func random() -> CGFloat {
        return CGFloat(CGFloat(arc4random()) / 0xFFFFFFFF)
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    func addTarget() {
        
        //Create target
        let target = SKSpriteNode(imageNamed: "target")
        
        //Determine where to spawn the target along the Y axis
        let actualyY = random(min: target.size.height / 2 + 300, max: (size.height - target.size.height / 2) - 60)
        
        //Position the target slightly off-screen along the right edge,
        //and along a random position along thy Y axis as calculater above
        target.position = CGPoint(x: -target.size.width / 2, y: actualyY)
        
        //Add the target to the scene
        addChild(target)
        
        //create trail for target
        let trailTarget = SKEmitterNode(fileNamed: "Trail")!
        trailTarget.targetNode = scene
        trailTarget.position.x = target.position.x + 5
        target.zPosition = 2
        target.addChild(trailTarget)
        
        //Determine speed of the target
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        
        //Create the actions
        let actionMove = SKAction.move(to: CGPoint(x: size.width + target.size.width / 2, y: actualyY), duration: TimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent()
        let loseAction = SKAction.run { [weak self] in
            guard let `self` = self else {return}
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
        target.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        
        //1 - Create a physics body for the sprite. In this case, the body is defined as a rectangle of the same size as the sprite, since that's a decent approximation for the arrow.
        target.physicsBody = SKPhysicsBody(circleOfRadius: target.size.width / 2)
        //2 - Set the sprite to be dynamic. This means that the physics engine will not control the movement of the arrow. You will through the code you've already written, using move actions.
        target.physicsBody?.isDynamic = true
        //3 - Set the category bit mask to be the arrowCategory you defined earlier.
        target.physicsBody?.categoryBitMask = PhysicsCategory.target
        //4 - contactTestBitMask indicates what categories of objects this object should notify the contact listener when they intersect. You choose projectiles here.
        target.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
        //5 - collisionBitMask indicates what categories of objects this object that the physics engine handle contact responses to (i.e. bounce off of). You don't want the arrow and projectile to bounce off each other — it's OK for them to go right through each other in this game — so you set this to .none.
        target.physicsBody?.collisionBitMask = PhysicsCategory.none
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLoc = touch.location(in: self)
            guard touchLoc.x >= pointOnX, touchLoc.x <= size.width - pointOnX else {return}
            player.position.x = touchLoc.x
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLoc = touch.location(in: self)
            guard touchLoc.x >= pointOnX, touchLoc.x <= size.width - pointOnX else {return}
            player.position.x = touchLoc.x
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // 1 - choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "arrow")
        projectile.position = player.position
        
        // 3 - determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - bail out if you are shooting down
        if offset.y < 0 {return}
        
        // 5 - OK to add now - you have double cheked position
        addChild(projectile)
        
        // 6 - create trail for arrow
        let trailArrow = SKEmitterNode(fileNamed: "Trail")!
        trailArrow.targetNode = scene
        trailArrow.position.y = player.position.y - 130
        projectile.zPosition = 3
        
        projectile.addChild(trailArrow)
        
        // 7 - get the direction of where to shoot
        let direction = offset.normalized()
        
        // 8 - make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 9 - add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 10 - create the action
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
        player.isHidden = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (Timer) in
            self.player.isHidden = false
        })
        
        // 11
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.target
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        projectile.physicsBody?.usesPreciseCollisionDetection = true
    }
    
    
    
    func projectileDidColleideWithTarget(projectile: SKSpriteNode, target: SKSpriteNode) {
        targetDestroyed += 1
        scoreLabel.text = "Score: \(targetDestroyed)"
        if targetDestroyed > 30 {
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            let gameOverScene = GameOverScene(size: self.size, won: true)
            view?.presentScene(gameOverScene, transition: reveal)
        }
        projectile.removeFromParent()
        target.removeFromParent()
        
        //create label with score point for hit a target
        let hitLabel = SKLabelNode()
        let attribute = [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 25), NSAttributedString.Key.foregroundColor : UIColor.yellow]
        hitLabel.attributedText = NSAttributedString(string: "+1", attributes: attribute)
        hitLabel.position = projectile.position
        addChild(hitLabel)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { (Timer) in
            hitLabel.removeFromParent()
        })
        
        
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        //1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        //2
        if ((firstBody.categoryBitMask & PhysicsCategory.target != 0) && (secondBody.categoryBitMask & PhysicsCategory.projectile != 0)) {
            if let target = firstBody.node as? SKSpriteNode, let projectile = secondBody.node as? SKSpriteNode {
                projectileDidColleideWithTarget(projectile: projectile, target: target)
            }
        }
        
    }
    
    
}

