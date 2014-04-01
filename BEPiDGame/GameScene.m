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

#define kNumPlayers 1


/* Player states for the four players in the HUD. */
typedef enum : uint8_t {
    APAHUDStateLocal,
    APAHUDStateConnecting,
    APAHUDStateDisconnected,
    APAHUDStateConnected
} APAHUDState;

@interface GameScene()
@property (strong, nonatomic) JCImageJoystick *imageJoystick;
@property (strong, nonatomic) JCButton *normalButton;
@property (strong, nonatomic) JCButton *turboButton;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property SKSpriteNode *island;
@property PlayerHero *hero;
@property EnemyCharacter *enemy;
@property BOOL atackIntent;


@property (nonatomic) NSMutableArray *players;          // array of player objects or NSNull for no player
@property (nonatomic) PlayerHero *defaultPlayer;         // player '1' controlled by keyboard/touch


#pragma  mark - HUD vars
@property (nonatomic) NSArray *hudAvatars;              // keep track of the various nodes for the HUD
@property (nonatomic) NSArray *hudLabels;               // - there are always 'kNumPlayers' instances in each array
@property (nonatomic) NSArray *hudScores;
@property (nonatomic) NSArray *hudLifeHeartArrays;      // an array of NSArrays of life hearts
@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        
        //world sets
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f); // no gravity
        self.physicsWorld.contactDelegate = self;
		self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
		self.physicsBody.categoryBitMask = APAColliderTypeScenario;
		self.physicsBody.collisionBitMask = APAColliderTypeScenario;
        
        //island
        _island = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.3 green:0.2 blue:0.2 alpha:1.0] size:CGSizeMake(self.frame.size.width*0.7f, self.frame.size.height*0.7f)];
        _island.position = CGPointMake(size.width/2, size.height/2);

        //island body
        _island.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_island.frame.size];
		_island.physicsBody.categoryBitMask = APAColliderTypeIsland;
		_island.physicsBody.collisionBitMask = APAColliderTypeIsland;
		_island.physicsBody.contactTestBitMask = APAColliderTypeHero | APAColliderTypeGoblinOrBoss;
        _island.zPosition = -1; // pra ilha ficar embaixo dos personagens
        [self addChild:_island];
        
        //direcional
        self.imageJoystick = [[JCImageJoystick alloc]initWithJoystickImage:(@"joystick.png") baseImage:@"dpad.png"];
        [self.imageJoystick setPosition:CGPointMake(70, 70)];
        [self addChild:self.imageJoystick];
        
        //normal button
        self.normalButton = [[JCButton alloc] initWithButtonRadius:25 color:[SKColor greenColor] pressedColor:[SKColor blackColor] isTurbo:NO];
        [self.normalButton setPosition:CGPointMake(size.width - 40,95)];
        [self addChild:self.normalButton];
        
        //turbo button
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
        
        self.backgroundColor = [SKColor colorWithRed:0.4 green:0.15 blue:0.15 alpha:1.0];
        
        //hero
        self.hero = [[PlayerHero alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.frame)-120,
              
                                                                   CGRectGetMidY(self.frame)) withPlayer:nil];
        [self.hero characterScene];
        [PlayerHero loadSharedAssets];
        [self addChild:self.hero];
        
        
        _players = [[NSMutableArray alloc] initWithCapacity:kNumPlayers];
        _defaultPlayer = self.hero;
        [(NSMutableArray *)_players addObject:_defaultPlayer];
        for (int i = 1; i < kNumPlayers; i++) {
            [(NSMutableArray *)_players addObject:[NSNull null]];
        }

        
        //enemy
        self.enemy = [[Boss alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.frame)+120,
                                                              CGRectGetMidY(self.frame))];
        [Boss loadSharedAssets];
        [self addChild:self.enemy];
        
        
        [self buildHUD];
        [self updateHUDForPlayer:self.hero forState:APAHUDStateLocal withMessage:nil];
        
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
        [self addSquareIn:CGPointMake(0,self.size.height-80) withColor:[SKColor yellowColor]];
    }
    
}

- (void)addSquareIn:(CGPoint)position
          withColor:(SKColor *)color
{
    Character *square = [[Character alloc] init];
    square.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:square.frame];
    
    // Our object type for collisions.
    square.physicsBody.categoryBitMask = APAColliderTypeWall;
    
    // Collides with these objects.
    square.physicsBody.collisionBitMask =  APAColliderTypeHero;
    
    // We want notifications for colliding with these objects.
    square.physicsBody.contactTestBitMask =  APAColliderTypeHero;
    
    [square setPosition:position];
    
    SKAction *move = [SKAction moveTo:CGPointMake(self.size.width+square.size.width/2,position.y) duration:1];
    SKAction *destroy = [SKAction removeFromParent];
    [self addChild:square];
    [square runAction:[SKAction sequence:@[move,destroy]]];
}

static SKEmitterNode *sSharedProjectileSparkEmitter = nil;
- (SKEmitterNode *)sharedProjectileSparkEmitter {
    return sSharedProjectileSparkEmitter;
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    
    NSLog(@"Algo se encostou.");
    
    //bodyA e bodyB não podem ser heróis ao mesmo tempo
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyB];
    node = contact.bodyB.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyA];
    
    //colisão de projéteis
    if (contact.bodyA.categoryBitMask & APAColliderTypeProjectile || contact.bodyB.categoryBitMask & APAColliderTypeProjectile)
    {
        SKNode *projectile = (contact.bodyA.categoryBitMask & APAColliderTypeProjectile) ? contact.bodyA.node : contact.bodyB.node;
        
        [projectile runAction:[SKAction removeFromParent]];
        
        if([contact.bodyB.node isKindOfClass:[Boss class]])
        {
            node = (Character *)contact.bodyB.node;
        }
        else if([contact.bodyA.node isKindOfClass:[Boss class]])
        {
            node = (Character *)contact.bodyA.node;
        
            //hud update
            self.hero.score = self.hero.score + 20;
            [self updateHUDForPlayer:self.hero];
        }
        else
            node = (Character *)contact.bodyA.node;

        //aplicando a força do impacto
        [node.physicsBody applyImpulse:CGVectorMake(node.position.x-contact.contactPoint.x, node.position.y-contact.contactPoint.y) atPoint:contact.contactPoint];
        
        // Build up a "one shot" particle to indicate where the projectile hit.
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        //[self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = projectile.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }
}

#pragma mark - HUD and Scores
- (void)buildHUD {
    NSString *iconNames[] = { @"iconWarrior_blue", @"iconWarrior_green", @"iconWarrior_pink", @"iconWarrior_red" };
    NSArray *colors = @[ [SKColor greenColor], [SKColor blueColor], [SKColor yellowColor], [SKColor redColor] ];
    CGFloat hudX = 0;
    CGFloat hudY = self.frame.size.height - 30;
    CGFloat hudD = self.frame.size.width / kNumPlayers;
    
    _hudAvatars = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudLabels = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudScores = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudLifeHeartArrays = [NSMutableArray arrayWithCapacity:kNumPlayers];
    SKNode *hud = [[SKNode alloc] init];
    
    for (int i = 0; i < kNumPlayers; i++) {
        SKSpriteNode *avatar = [SKSpriteNode spriteNodeWithImageNamed:iconNames[i]];
        avatar.scale = 0.5;
        avatar.alpha = 0.5;
        avatar.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 0.5), self.frame.size.height - avatar.size.height * 0.5 - 8 );
        [(NSMutableArray *)_hudAvatars addObject:avatar];
        [hud addChild:avatar];
        
        SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
        label.text = @"NO PLAYER";
        label.fontColor = colors[i];
        label.fontSize = 16;
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        label.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0), hudY + 10 );
        [(NSMutableArray *)_hudLabels addObject:label];
        [hud addChild:label];
        
        SKLabelNode *score = [SKLabelNode labelNodeWithFontNamed:@"Copperplate"];
        score.text = @"SCORE: 0";
        score.fontColor = colors[i];
        score.fontSize = 16;
        score.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        score.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0), hudY - 40 );
        [(NSMutableArray *)_hudScores addObject:score];
        [hud addChild:score];
        
        [(NSMutableArray *)_hudLifeHeartArrays addObject:[NSMutableArray arrayWithCapacity:kStartLives]];
        for (int j = 0; j < kStartLives; j++) {
            SKSpriteNode *heart = [SKSpriteNode spriteNodeWithImageNamed:@"lives.png"];
            heart.scale = 0.4;
            heart.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0) + 18 + ((heart.size.width + 5) * j), hudY - 10);
            heart.alpha = 0.1;
            [_hudLifeHeartArrays[i] addObject:heart];
            [hud addChild:heart];
        }
    }
    
    [self addChild:hud];
}
#pragma mark - Metodos HUD
- (void)updateHUDForPlayer:(PlayerHero *)player forState:(APAHUDState)state withMessage:(NSString *)message {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    
    SKSpriteNode *avatar = self.hudAvatars[playerIndex];
    [avatar runAction:[SKAction sequence: @[[SKAction fadeAlphaTo:1.0 duration:1.0], [SKAction fadeAlphaTo:0.2 duration:1.0], [SKAction fadeAlphaTo:1.0 duration:1.0]]]];
    
    SKLabelNode *label = self.hudLabels[playerIndex];
    CGFloat heartAlpha = 1.0;
    switch (state) {
        case APAHUDStateLocal:;
            label.text = @"ME";
            break;
        case APAHUDStateConnecting:
            heartAlpha = 0.25;
            if (message) {
                label.text = message;
            } else {
                label.text = @"AVAILABLE";
            }
            break;
        case APAHUDStateDisconnected:
            avatar.alpha = 0.5;
            heartAlpha = 0.1;
            label.text = @"NO PLAYER";
            break;
        case APAHUDStateConnected:
            if (message) {
                label.text = message;
            } else {
                label.text = @"CONNECTED";
            }
            break;
    }
    
    for (int i = 0; i < player.livesLeft; i++) {
        SKSpriteNode *heart = self.hudLifeHeartArrays[playerIndex][i];
        heart.alpha = heartAlpha;
    }
}

- (void)updateHUDForPlayer:(PlayerHero *)player {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    SKLabelNode *label = self.hudScores[playerIndex];
    label.text = [NSString stringWithFormat:@"SCORE: %d", player.score];
}

- (void)updateHUDAfterHeroDeathForPlayer:(PlayerHero *)player {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    
    // Fade out the relevant heart - one-based livesLeft has already been decremented.
    NSUInteger heartNumber = player.livesLeft;
    
    NSArray *heartArray = self.hudLifeHeartArrays[playerIndex];
    SKSpriteNode *heart = heartArray[heartNumber];
    [heart runAction:[SKAction fadeAlphaTo:0.0 duration:3.0f]];
}

- (void)addToScore:(uint32_t)amount afterEnemyKillWithProjectile:(SKNode *)projectile {
    PlayerHero *player = projectile.userData[kPlayer];
    
    player.score += amount;
    
    [self updateHUDForPlayer:player];
}

@end
