//
//  GameOverScene.swift
//  FastArrow
//
//  Created by Bogdan Mishura on 9/16/19.
//  Copyright © 2019 Bogdan Mishura. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    init(size: CGSize, won: Bool) {
        super.init(size: size)
        
        //1
        backgroundColor = SKColor.black
        
        //2
        let message = won ? "You Won" : "You Lose :("
        
        //3
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.white
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(label)
        
        //4
        run(SKAction.sequence([SKAction.wait(forDuration: 3.0),
                               SKAction.run() {[weak self] in
                                //5
                                guard let `self` = self else {return}
                                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                                let scene = GameScene(size: size)
                                self.view?.presentScene(scene, transition: reveal)
            }
            ]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
