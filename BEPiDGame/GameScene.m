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
#import "APAGraphicsUtilities.h"



@interface GameScene() 
@property (strong, nonatomic) JCImageJoystick *imageJoystick;
@property (strong, nonatomic) JCButton *normalButton;
@property (strong, nonatomic) JCButton *turboButton;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property HeroCharacter *hero;
@property EnemyCharacter *enemy;
@property BOOL atackIntent;
@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        //World Sets
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f); // no gravity
        self.physicsWorld.contactDelegate = self;
		self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
		self.physicsBody.categoryBitMask = APAColliderTypeScenario;
		self.physicsBody.collisionBitMask = APAColliderTypeScenario;
        
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
        [PlayerHero loadSharedAssets];
        [self addChild:self.hero];
        
        //enemy
        self.enemy = [[Boss alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.frame)*1.9,
                                                                         CGRectGetMidY(self.frame))];
        [Boss loadSharedAssets];
        [self addChild:self.enemy];
        
        //self.physicsWorld.contactDelegate = self;
        
    }
    return self;
}

- (void)addNode:(SKNode *)node {
    [self addChild:node];
}

-(void)update:(CFTimeInterval)currentTime {
    
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // more than a second since last update
        timeSinceLast = kMinTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
    }
    
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

static SKEmitterNode *sSharedProjectileSparkEmitter = nil;
- (SKEmitterNode *)sharedProjectileSparkEmitter {
    return sSharedProjectileSparkEmitter;
}

#pragma mark - Physics Delegate
- (void)didBeginContact:(SKPhysicsContact *)contact {
    // Either bodyA or bodyB in the collision could be a character.
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[Character class]]) {
        [(Character *)node collidedWith:contact.bodyB];
    }
    contact.contactPoint;
    // Check bodyB too.
    node = contact.bodyB.node;
    if ([node isKindOfClass:[Character class]]) {
        [(Character *)node collidedWith:contact.bodyA];
    }
    
    // Handle collisions with projectiles.
    if (contact.bodyA.categoryBitMask & APAColliderTypeProjectile || contact.bodyB.categoryBitMask & APAColliderTypeProjectile) {
        SKNode *projectile = (contact.bodyA.categoryBitMask & APAColliderTypeProjectile) ? contact.bodyA.node : contact.bodyB.node;
        
        [projectile runAction:[SKAction removeFromParent]];
        
        if([contact.bodyB.node isKindOfClass:[Boss class]]){
            node = (Character *)contact.bodyB.node;
            //[(Character *)node moveTowards:CGPointMake(node.position.x *1.1, node.position.y *1.1) withTimeInterval:self.lastUpdateTimeInterval];
            
            [node.physicsBody  applyImpulse:CGVectorMake(0, 2.5)];
        }else{
            node = (Character *)contact.bodyA.node;
            //[(Character *)node moveTowards:CGPointMake(node.position.x *1.1, node.position.y *1.1) withTimeInterval:self.lastUpdateTimeInterval];
            
            [node.physicsBody  applyImpulse:CGVectorMake(0, 2.5)];
        }
        
        // Build up a "one shot" particle to indicate where the projectile hit.
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        //[self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = projectile.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }
}

@end
