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
#import "SKButton.h"

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
@property (strong, nonatomic) JCButton *attackButton;
@property (strong, nonatomic) JCButton *testButton;
@property (nonatomic, strong) ViewController *myVC;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic, readonly) SKNode *world;
@property (nonatomic) NSMutableArray *layers;
@property SKSpriteNode *lava;
@property (strong,nonatomic) NSMutableArray *enemys;
@property BOOL atackIntent;
@property (nonatomic, readwrite) NSMutableArray *heroes;
@property (nonatomic) NSMutableArray *players;          // array of player objects or NSNull for no player
@property (nonatomic) PlayerHero *defaultPlayer;         // player '1' controlled by keyboard/touch

#pragma  mark - HUD vars
@property (nonatomic) NSArray *hudAvatars;              // keep track of the various nodes for the HUD
@property (nonatomic) NSArray *hudLabels;               // - there are always 'kNumPlayers' instances in each array
@property (nonatomic) NSArray *hudScores;
@property (nonatomic) NSArray *hudPercents;      // an array of NSArrays of life hearts
@property (nonatomic) float lifeBarX;
@end

@implementation GameScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        //heros
        _heroes = [[NSMutableArray alloc] init];
        _enemys = [[NSMutableArray alloc] init];
        
        //world sets
        //self.backgroundColor = [SKColor blackColor];
        self.physicsWorld.gravity = CGVectorMake(0.0f, 0.0f); // no gravity
        self.physicsWorld.contactDelegate = self;

        _world = [[SKNode alloc] init];
        [_world setName:@"world"];
        _layers = [NSMutableArray arrayWithCapacity:kWorldLayerCount];
        for (int i = 0; i < kWorldLayerCount; i++) {
            SKNode *layer = [[SKNode alloc] init];
            layer.zPosition = i - kWorldLayerCount;
            [_world addChild:layer];
            [(NSMutableArray *)_layers addObject:layer];
        }
        
        [self addChild:_world];
        
        _world.xScale = 0.6f;
        _world.yScale = 0.6f;
        //lava
        _lava = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0] size:CGSizeMake(self.frame.size.width*3, self.frame.size.height*3)];
        [_lava setTexture:[SKTexture textureWithImageNamed:@"lava"]];
        _lava.position = CGPointMake(_world.position.x, _world.position.y);
        //_lava.zPosition = -2; // pra lava ficar abaixo da ilha
        _lava.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:_lava.frame];
        _lava.physicsBody.categoryBitMask = ColliderTypeScenario;
		_lava.physicsBody.collisionBitMask = ColliderTypeScenario;
        
        [self addNode:_lava atWorldLayer:APAWorldLayerGround];
        
        //island
        _island = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.3 green:0.2 blue:0.2 alpha:1.0] size:CGSizeMake(_lava.frame.size.width*0.4f, _lava.frame.size.height*0.4f)];
        [_island setTexture:[SKTexture textureWithImageNamed:@"rock"]];
        //_island.position = CGPointMake(_lava.frame.size.width/2, _lava.frame.size.height/2);
        //_island.zPosition = -1; // pra ilha ficar embaixo dos personagens
        //island body
        _island.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_island.frame.size];
		_island.physicsBody.categoryBitMask = ColliderTypeIsland;
		_island.physicsBody.collisionBitMask = ColliderTypeIsland;
		_island.physicsBody.contactTestBitMask = ColliderTypeHero | ColliderTypeGoblinOrBoss;
        [self addNode:_island atWorldLayer:APAWorldLayerBelowCharacter];
        
        //direcionalz
        self.imageJoystick = [[JCImageJoystick alloc]initWithJoystickImage:(@"joystick.png") baseImage:@"dpad.png"];
        [self.imageJoystick setPosition:CGPointMake(70, 70)];
        [self addChild:self.imageJoystick];
        
        //attack button
        self.attackButton = [[JCButton alloc] initWithButtonRadius:25 color:[SKColor lightGrayColor] pressedColor:[SKColor blackColor] isTurbo:NO];
        [self.attackButton setPosition:CGPointMake(size.width - 40,60)];
        [self addChild:self.attackButton];

        //método que testa se os botões foram pressionados
        SKAction *wait = [SKAction waitForDuration:0.5];
        SKAction *checkButtons = [SKAction runBlock:^{
            [self checkButtons];
        }];
        SKAction *checkButtonsAction = [SKAction sequence:@[wait,checkButtons]];
        [self runAction:[SKAction repeatActionForever:checkButtonsAction]];

        [PlayerHero loadSharedAssets];
        [Boss loadSharedAssets];
    }
    return self;
}

-(void) startGame: (NSInteger )level{
    //scheduling the action to check buttons
    SKAction *wait = [SKAction waitForDuration:0.3];
    SKAction *checkButtons = [SKAction runBlock:^{
        [self checkButtons];
    }];
    SKAction *checkButtonsAction = [SKAction sequence:@[wait,checkButtons]];
    [self runAction:[SKAction repeatActionForever:checkButtonsAction]];
    
    //hero
    PlayerHero *hero = [[PlayerHero alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.island.frame)-120,
                                                               CGRectGetMidY(self.island.frame)) withPlayer:nil];
    [hero characterScene];
    
    [self addNode:hero atWorldLayer:APAWorldLayerCharacter];
    
    
    //_defaultPlayer = self.hero;
    
    [self centerWorldOnCharacter:hero];
    
    [(NSMutableArray *)self.heroes addObject:hero];
    
    
    //enemy
    for(int i = 0; i < level; i++){
        Boss * enemy = [[Boss alloc] initAtPosition:CGPointMake(CGRectGetMidX(self.island.frame)+120*i,
                                                          CGRectGetMidY(self.island.frame))];
    
    
        [self addNode:enemy atWorldLayer:APAWorldLayerCharacter];
        [self desacelerateCharacter:enemy];
        [self.enemys addObject:enemy];
    }
    //método recursivo que desacelera o character caso ele esteja com força aplicada nele
    [self desacelerateCharacter:hero];

    
    [self buildHUD];
    [self updateHUDForPlayer:hero forState:APAHUDStateLocal withMessage:nil];
    
}

- (void)heroWasKilled:(HeroCharacter *)hero {
    
    [self removeAllNodeatWorldLayer:APAWorldLayerCharacter];
    NSLog(@"%@",self.children);
    [self.enemys removeAllObjects];
    [(NSMutableArray *)self.heroes removeObject:hero];
    self.gameOverBlock(TRUE);
}

-(void)buttonAction{
    [self startGame:8];
    
}

-(void)setMyVC:(ViewController *)myVC
{
    _myVC = myVC;
}

- (void)addNode:(SKNode *)node {
    [_world addChild:node];
}

- (void)addNode:(SKNode *)node atWorldLayer:(APAWorldLayer)layer {
    SKNode *layerNode = self.layers[layer];
    [layerNode addChild:node];
}

- (void)removeAllNodeatWorldLayer:(APAWorldLayer )layer{
    SKNode *layerNode = self.layers[layer];
    [layerNode removeAllChildren];
}

#pragma mark - Mapping
//- (void)centerWorldOnPosition:(CGPoint)position {
//    [self.world setPosition:CGPointMake(-(position.x) + (CGRectGetMidX(self.frame) * 0.6f),
//                                        -(position.y) + (CGRectGetMidY(self.frame) * 0.6f))];
//}
- (void)centerWorldOnPosition:(CGPoint)position {
        [self.world setPosition:CGPointMake(
                                            -(position.x) + (CGRectGetMidX(self.frame)*0.6f),
                                            -(position.y) + (CGRectGetMidY(self.frame))
                                            )];
    //NSLog(@"\nwx: %.2f \npx: %.2f",self.world.position.x,-position.x);
}


- (void)centerWorldOnCharacter:(Character *)character {
    [self centerWorldOnPosition:character.position];
}

-(void)update:(CFTimeInterval)currentTime {
    
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > 1) { // more than a second since last update
        timeSinceLast = kMinTimeInterval;
        self.lastUpdateTimeInterval = currentTime;
        
    }
        PlayerHero *hero = nil;
    if ([self.heroes count] > 0) {
        hero = [self.heroes objectAtIndex:0];
    }

    if(!hero.isDying){
        if(self.imageJoystick.touchesBegin && !self.atackIntent){
            [hero moveTowards:CGPointMake(hero.position.x+self.imageJoystick.x *2, hero.position.y+self.imageJoystick.y *2) withTimeInterval:currentTime];
        }
        [hero updateWithTimeSinceLastUpdate:currentTime];
        [self centerWorldOnCharacter:hero];
    }
    
        for (Boss *boss in self.enemys) {
            [boss updateWithTimeSinceLastUpdate:currentTime];
        }
    if(self.enemys.count == 0 && self.heroes.count > 0){
        [self heroWasKilled:hero];
    }
    
    self.atackIntent = FALSE;
}

- (void)checkButtons
{
    if (self.attackButton.wasPressed) {
        self.atackIntent = TRUE;
        PlayerHero *hero = [self.heroes objectAtIndex:0];
        [hero performAttackAction];
    }
}

static SKEmitterNode *sSharedProjectileSparkEmitter = nil;
- (SKEmitterNode *)sharedProjectileSparkEmitter {
    return sSharedProjectileSparkEmitter;
}


- (void)OLDdidBeginContact:(SKPhysicsContact *)contact {

    NSLog(@"bodyA:%u bodyB:%u",contact.bodyA.categoryBitMask,contact.bodyB.categoryBitMask);
    
    //chamando o método de colisão da classe se for um char (hero ou enemy)
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyB];
    node = contact.bodyB.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyA];
    
    SKPhysicsBody *mainBody = [[SKPhysicsBody alloc] init];
    SKPhysicsBody *collisionBody = [[SKPhysicsBody alloc] init];
    
    //testa se algum character entrou da ilha
    if (contact.bodyA.categoryBitMask & ColliderTypeIsland || contact.bodyB.categoryBitMask & ColliderTypeIsland)
    {
        if (contact.bodyA.categoryBitMask & ColliderTypeIsland) {
            mainBody = contact.bodyA;
            collisionBody = contact.bodyB;
        }else{
            mainBody = contact.bodyB;
            collisionBody = contact.bodyA;
        }

        if (collisionBody.categoryBitMask & ColliderTypeHero || collisionBody.categoryBitMask & ColliderTypeGoblinOrBoss)
        {
            NSLog(@"Saiu da lava.");
            [(Character *)collisionBody.node setInLava:NO];
        }
    }
    
    //colisão de projéteis do hero
    if (contact.bodyA.categoryBitMask & ColliderTypeProjectile || contact.bodyB.categoryBitMask & ColliderTypeProjectile)
    {
        if (contact.bodyA.categoryBitMask & ColliderTypeProjectile) {
            mainBody = contact.bodyA;
            collisionBody = contact.bodyB;
        }else{
            mainBody = contact.bodyB;
            collisionBody = contact.bodyA;
        }
        
        //se o corpo colidido for um projétil de inimigo, eles são jogados pra longe e não eliminados
        if (collisionBody.categoryBitMask & ColliderTypeProjectileBoss) {

        }else{
            //elimina o projétil assim que toca no alvo
            [mainBody.node runAction:[SKAction removeFromParent]];
        }

        //hud update se o alvo for um inimigo
        if([collisionBody.node isKindOfClass:[Boss class]])
        {
            PlayerHero *hero = [self.heroes objectAtIndex:0];
            hero.score = hero.score + 20;
            [self updateHUDForPlayer:hero];
        }

        double angle = atan2(contact.contactPoint.y-node.position.y,contact.contactPoint.x-node.position.x);
        
        NSLog(@"%f",angle);
        
        CGVector vector = CGVectorMake(60*cos(angle), 60*sin(angle));
        
        NSLog(@"%f",vector.dx);
        NSLog(@"%f",vector.dy);
        [collisionBody.node.physicsBody applyImpulse:vector atPoint:contact.contactPoint];
        
        //cria uma partícula para indicar onde o projétil acertou
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        //[self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = mainBody.node.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }
    
    //colisão de projéteis do boss
    if (contact.bodyA.categoryBitMask & ColliderTypeProjectileBoss || contact.bodyB.categoryBitMask & ColliderTypeProjectileBoss)
    {
        if (contact.bodyA.categoryBitMask & ColliderTypeProjectileBoss) {
            mainBody = contact.bodyA;
            collisionBody = contact.bodyB;
        }else{
            mainBody = contact.bodyB;
            collisionBody = contact.bodyA;
        }
        
        //se o corpo colidido for um projétil de inimigo, eles são jogados pra longe e não eliminados
        if (collisionBody.categoryBitMask & ColliderTypeProjectile) {
            
            //aplicando a força do impacto no alvo
            double angle = atan2(contact.contactPoint.y-node.position.y,contact.contactPoint.x-node.position.x);
            
            NSLog(@"%f",angle);
            
            CGVector vector = CGVectorMake(60*cos(angle), 60*sin(angle));
            
            NSLog(@"%f",vector.dx);
            NSLog(@"%f",vector.dy);
            [collisionBody.node.physicsBody applyImpulse:vector atPoint:contact.contactPoint];
            
        }else{
            //elimina o projétil assim que toca no alvo
            [mainBody.node runAction:[SKAction removeFromParent]];
        }


        
        //cria uma partícula para indicar onde o projétil acertou
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        //[self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = mainBody.node.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }
}




- (void)didBeginContact:(SKPhysicsContact *)contact {
    
    //NSLog(@"bodyA:%u bodyB:%u",contact.bodyA.categoryBitMask,contact.bodyB.categoryBitMask);
    
    //chamando o método de colisão da classe se for um char (hero ou enemy)
    SKNode *node = contact.bodyA.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyB];
    node = contact.bodyB.node;
    if ([node isKindOfClass:[Character class]])
        [(Character *)node collidedWith:contact.bodyA];
    
    SKPhysicsBody *mainBody = [[SKPhysicsBody alloc] init];
    SKPhysicsBody *collisionBody = [[SKPhysicsBody alloc] init];
    
    //testa se algum character entrou da ilha
    if (contact.bodyA.categoryBitMask & ColliderTypeIsland || contact.bodyB.categoryBitMask & ColliderTypeIsland)
    {
        if (contact.bodyA.categoryBitMask & ColliderTypeIsland) {
            mainBody = contact.bodyA;
            collisionBody = contact.bodyB;
        }else{
            mainBody = contact.bodyB;
            collisionBody = contact.bodyA;
        }
        
        if (collisionBody.categoryBitMask & ColliderTypeHero || collisionBody.categoryBitMask & ColliderTypeGoblinOrBoss)
        {
            //NSLog(@"Saiu da lava.");
            [(Character *)collisionBody.node setInLava:NO];
        }
    }
    
    //colisão de projéteis nos character
    if ((contact.bodyA.categoryBitMask & ColliderTypeProjectile || contact.bodyB.categoryBitMask & ColliderTypeProjectile || contact.bodyA.categoryBitMask & ColliderTypeProjectileBoss || contact.bodyB.categoryBitMask & ColliderTypeProjectileBoss)
        && ([contact.bodyA.node isKindOfClass:[Character class]] || [contact.bodyB.node isKindOfClass:[Character class]]))
    {
        SKNode *projectile = [[SKNode alloc] init];
        if (contact.bodyA.categoryBitMask & ColliderTypeProjectile || contact.bodyA.categoryBitMask & ColliderTypeProjectileBoss) {
            projectile = contact.bodyA.node;
            node = contact.bodyB.node;
            NSLog(@"Corpo A é o projétil");
        }else{
            projectile = contact.bodyB.node;
            node = contact.bodyA.node;
            NSLog(@"Corpo B é o projétil");
        }
        
        //elimina o projétil assim que toca no alvo
        [projectile runAction:[SKAction removeFromParent]];
        
        //hud update se o alvo for um inimigo
        PlayerHero *hero = [self.heroes objectAtIndex:0];
        if([node isKindOfClass:[Boss class]])
        {
            hero.score = hero.score + 20;
            [self updateHUDForPlayer:hero];
        }
        
        if([node isKindOfClass:[PlayerHero class]]){
            [self updateHUDForPlayer:hero];
        }

        //aplicando a força do impacto no alvo se não estiver morto
        Character *nodeChar = (Character *)node;
        if (!nodeChar.isDying) {
            CGVector vector = CGVectorMake(
                                           (node.position.x-projectile.position.x)*0.4,
                                           (node.position.y-projectile.position.y)*0.4
                                           );
            [node.physicsBody applyImpulse:vector atPoint:contact.contactPoint];
        }

        // Build up a "one shot" particle to indicate where the projectile hit.
        SKEmitterNode *emitter = [[self sharedProjectileSparkEmitter] copy];
        //[self addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
        emitter.position = projectile.position;
        APARunOneShotEmitter(emitter, 0.15f);
    }else if((contact.bodyA.categoryBitMask & ColliderTypeProjectile || contact.bodyB.categoryBitMask & ColliderTypeProjectile) && (contact.bodyA.categoryBitMask & ColliderTypeProjectileBoss || contact.bodyB.categoryBitMask & ColliderTypeProjectileBoss)){
        // projeteis se tocando

        CGVector vector = CGVectorMake(
                                       (contact.bodyA.node.position.x-contact.bodyB.node.position.x)*0.4,
                                       (contact.bodyA.node.position.y-contact.bodyB.node.position.y)*0.4
                                       );
        CGVector negativeVector = CGVectorMake(
                                       -(contact.bodyA.node.position.x-contact.bodyB.node.position.x)*0.4,
                                       -(contact.bodyA.node.position.y-contact.bodyB.node.position.y)*0.4
                                       );
        [contact.bodyA.node.physicsBody applyImpulse:vector atPoint:contact.contactPoint];
        [contact.bodyB.node.physicsBody applyImpulse:negativeVector atPoint:contact.contactPoint];
    }
}


-(void)didEndContact:(SKPhysicsContact *)contact
{
    //NSLog(@"Algo se desencostou.");
    
    //testa se algum character saiu da ilha
    if (contact.bodyA.categoryBitMask & ColliderTypeIsland)
        if (contact.bodyB.categoryBitMask & ColliderTypeHero || contact.bodyB.categoryBitMask & ColliderTypeGoblinOrBoss)
        {
            //NSLog(@"Entrou na lava.");
            [(Character *)contact.bodyB.node setInLava:YES];
        }
}

-(void)desacelerateCharacter:(Character *)node
{
    //NSLog(@"velocidade:%.2f %.2f - velocidade angular:%.2f",node.physicsBody.velocity.dx,node.physicsBody.velocity.dy,node.physicsBody.angularVelocity);
    
    //a desaceleração só acontece se alguma força estiver sendo aplicada no corpo
    if (node.physicsBody.velocity.dx != 0 ||
        node.physicsBody.velocity.dy != 0 ||
        node.physicsBody.angularVelocity != 0)
    {
        //desacelera em 10% a velocidade e giro
        node.physicsBody.velocity = CGVectorMake(node.physicsBody.velocity.dx*0.9f, node.physicsBody.velocity.dy*0.9f);
        node.physicsBody.angularVelocity = node.physicsBody.angularVelocity*0.9;
        
        //para se tiver muito devagar
        if ( fabsf(node.physicsBody.velocity.dx) + fabs(node.physicsBody.velocity.dy) < 5.0f)
            node.physicsBody.velocity = CGVectorMake(0, 0);
        
        //para de girar se tiver girando muito devagar
        if (node.physicsBody.angularVelocity < 2.0f)
            node.physicsBody.angularVelocity = 0;
    }
    
    //método só não se renova se o monstro estiver morrendo
    if (!node.isDying)
        [self performSelector:@selector(desacelerateCharacter:) withObject:node afterDelay:0.1];
    else
    {
        node.physicsBody.velocity = CGVectorMake(0, 0);
        node.physicsBody.angularVelocity = 0;
    }
}

#pragma mark - HUD and Scores

- (void)buildHUD {
    NSString *iconNames[] = { @"iconWarrior_blue" };
    NSArray *colors = @[ [SKColor greenColor]];
    CGFloat hudX = 0;
    CGFloat hudY = self.frame.size.height - 30;
    CGFloat hudD = self.frame.size.width / kNumPlayers;
    
    _hudAvatars = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudLabels = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudScores = [NSMutableArray arrayWithCapacity:kNumPlayers];
    _hudPercents = [NSMutableArray arrayWithCapacity:kNumPlayers];
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
        
//        [(NSMutableArray *)_hudLifeHeartArrays addObject:[NSMutableArray arrayWithCapacity:kStartLives]];
//        for (int j = 0; j < kStartLives; j++) {
//            SKSpriteNode *heart = [SKSpriteNode spriteNodeWithImageNamed:@"lives.png"];
//            heart.scale = 0.4;
//            heart.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0) + 18 + ((heart.size.width + 5) * j), hudY - 10);
//            heart.alpha = 1;
//            [_hudLifeHeartArrays[i] addObject:heart];
//            [hud addChild:heart];
//        }
        
        SKSpriteNode *nodeTest = [[SKSpriteNode alloc]init];
        nodeTest.size = CGSizeMake(100, 10);
        nodeTest.color = [SKColor greenColor];
        nodeTest.position = CGPointMake(hudX + i * hudD + (avatar.size.width * 1.0) + ((nodeTest.size.width / 2)), hudY - 10);
        
        self.lifeBarX = nodeTest.position.x;
        
        [(NSMutableArray *) _hudPercents addObject:nodeTest];
        [hud addChild:nodeTest];
    }
    
    [self addChild:hud];
}

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
    
    //NSLog(@"health %f", player.health);
    
//    for (int i = 0; i < player.livesLeft; i++) {
//        SKSpriteNode *heart = self.hudLifeHeartArrays[playerIndex][i];
//        heart.alpha = heartAlpha;
//    }
}

- (void)updateHUDForPlayer:(PlayerHero *)player {
    NSUInteger playerIndex = [self.players indexOfObject:player];
    SKLabelNode *label = self.hudScores[playerIndex];
    label.text = [NSString stringWithFormat:@"SCORE: %d", player.score];
    
    float teste = (player.health / 100) * 100;
    
    float diferenca = (100 - teste);
    
    //NSLog(@"%f , %f", teste , diferenca);
    
    SKSpriteNode *lblPercent = self.hudPercents[playerIndex];
    lblPercent.size = CGSizeMake((player.health / 100) * 100 , 10);
    lblPercent.position = CGPointMake(self.lifeBarX - (diferenca /2), lblPercent.position.y);
    
    
    //NSLog(@"Teste %f", player.health);
}

- (void)updateHUDAfterHeroDeathForPlayer:(PlayerHero *)player {
    //NSUInteger playerIndex = [self.players indexOfObject:player];
    
    // Fade out the relevant heart - one-based livesLeft has already been decremented.
    //NSUInteger heartNumber = player.livesLeft;
   // NSArray *heartArray = self.hudLifeHeartArrays[playerIndex];
    //SKSpriteNode *heart = heartArray[heartNumber];
    //[heart runAction:[SKAction fadeAlphaTo:0.0 duration:3.0f]];
}

- (void)addToScore:(uint32_t)amount afterEnemyKillWithProjectile:(SKNode *)projectile {
    PlayerHero *player = projectile.userData[kPlayer];
    
    player.score += amount;
    
    [self updateHUDForPlayer:player];
}

@end
