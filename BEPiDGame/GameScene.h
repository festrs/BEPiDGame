//
//  GameScene.h
//  BEPiDGame
//
//  Created by Felipe Dias Pereira on 27/03/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#define kMinTimeInterval (1.0f / 60.0f)
#define kStartLives 11

@interface GameScene : SKScene <SKPhysicsContactDelegate>
- (void)addNode:(SKNode *)node;
@end
