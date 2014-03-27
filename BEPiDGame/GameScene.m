//
//  GameScene.m
//  BEPiDGame
//
//  Created by Felipe Dias Pereira on 27/03/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import "GameScene.h"
#import "JCImageJoystick.h"
#import "JCButton.h"
#import "HeroCharacter.h"
#import "PlayerHero.h"
#import "EnemyCharacter.h"
#import "Boss.h"

@interface GameScene() <SKPhysicsContactDelegate>
@property (strong, nonatomic) JCImageJoystick *imageJoystick;
@property (strong, nonatomic) JCButton *normalButton;
@property (strong, nonatomic) JCButton *turboButton;
@property HeroCharacter *hero;
@property EnemyCharacter *enemy;
@property BOOL atackIntent;
@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        //JCImageJoystic
        self.imageJoystick = [[JCImageJoystick alloc]initWithJoystickImage:(@"joystick.png") baseImage:@"dpad.png"];
        [self.imageJoystick setPosition:CGPointMake(70, 70)];
        [self addChild:self.imageJoystick];
        
        self.normalButton = [[JCButton alloc] initWithButtonRadius:25 color:[SKColor greenColor] pressedColor:[SKColor blackColor] isTurbo:NO];
        [self.normalButton setPosition:CGPointMake(size.width - 40,95)];
        [self addChild:self.normalButton];
        
        
        self.turboButton = [[JCButton alloc] initWithButtonRadius:25 color:[SKColor yellowColor] pressedColor:[SKColor blackColor] isTurbo:YES];
        [self.turboButton setPosition:CGPointMake(size.width - 85,50)];
        [self addChild:self.turboButton];
        
        
        //scheduling the action to check buttons
        SKAction *wait = [SKAction waitForDuration:0.3];
        SKAction *checkButtons = [SKAction runBlock:^{
            [self checkButtons];
        }];
        SKAction *checkButtonsAction = [SKAction sequence:@[wait,checkButtons]];
        [self runAction:[SKAction repeatActionForever:checkButtonsAction]];
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        //hero
        self.hero = [[PlayerHero alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.frame)*1.5,
                                                                  CGRectGetMidY(self.frame)) withPlayer:nil];
        [self.hero characterScene];
        self.hero.physicsBody.affectedByGravity = NO;
        [PlayerHero loadSharedAssets];
        [self addChild:self.hero];
        
        //enemy
        self.enemy = [[Boss alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.frame)*1.5,
                                                                         CGRectGetMidY(self.frame))];
        self.enemy.physicsBody.affectedByGravity = NO;
        [Boss loadSharedAssets];
        [self addChild:self.enemy];
    }
    return self;
}

- (void)addNode:(SKNode *)node {
    [self addChild:node];
}

-(void)update:(CFTimeInterval)currentTime {
    
    if(self.imageJoystick.touchesBegin && !self.atackIntent){
        [self.hero moveTowards:CGPointMake(self.hero.position.x+self.imageJoystick.x *2, self.hero.position.y+self.imageJoystick.y *2) withTimeInterval:currentTime];
    }
    [self.hero updateWithTimeSinceLastUpdate:currentTime];
    [self.enemy updateWithTimeSinceLastUpdate:currentTime];
    self.atackIntent = FALSE;
}

- (void)checkButtons
{
    
    if (self.normalButton.wasPressed) {
        self.atackIntent = TRUE;
        [self.hero performAttackAction];
    }
    
    if (self.turboButton.wasPressed) {
        
    }
    
}



#pragma mark - Physics Delegate
- (void)didBeginContact:(SKPhysicsContact *)contact {
    // Either bodyA or bodyB in the collision could be a character.
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[Character class]]) {
        [(Character *)node collidedWith:contact.bodyB];
    }
    
    // Check bodyB too.
    node = contact.bodyB.node;
    if ([node isKindOfClass:[Character class]]) {
        [(Character *)node collidedWith:contact.bodyA];
    }
    
    // Handle collisions with projectiles.
    if (contact.bodyA.categoryBitMask & APAColliderTypeProjectile || contact.bodyB.categoryBitMask & APAColliderTypeProjectile) {
        SKNode *projectile = (contact.bodyA.categoryBitMask & APAColliderTypeProjectile) ? contact.bodyA.node : contact.bodyB.node;
        
        [projectile runAction:[SKAction removeFromParent]];
        
        // Build up a "one shot" particle to indicate where the projectile hit.
//        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
//        [self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
//        emitter.position = projectile.position;
//        APARunOneShotEmitter(emitter, 0.15f);
    }
}

@end
