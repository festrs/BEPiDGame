//
//  GameScene.h
//  BEPiDGame
//
//  Created by Felipe Dias Pereira on 27/03/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "ViewController.h"
#define kMinTimeInterval (1.0f / 60.0f)
#define kStartLives 3

/* The layers in a scene. */
typedef enum : uint8_t {
	APAWorldLayerGround = 0,
	APAWorldLayerBelowCharacter,
	APAWorldLayerCharacter,
	APAWorldLayerAboveCharacter,
	APAWorldLayerTop,
	kWorldLayerCount
} APAWorldLayer;

@class HeroCharacter, Character, Boss, PlayerHero;

@interface GameScene : SKScene <SKPhysicsContactDelegate>
@property (nonatomic, readonly) ViewController *myVC;
@property (nonatomic, readonly) NSArray *heroes;  
- (void)addNode:(SKNode *)node;
@property SKSpriteNode *island;
@property SKCropNode *cropNode;
- (void)addNode:(SKNode *)node atWorldLayer:(APAWorldLayer)layer;
- (void)heroWasKilled:(HeroCharacter *)hero;
-(void)monsterWasKilled:(Boss *)monster;
-(void) startGame: (NSInteger )level;
@property (nonatomic, copy) void (^gameOverBlock)(BOOL didWin);
- (void)updateHUDForPlayer:(PlayerHero *)player;
@end
