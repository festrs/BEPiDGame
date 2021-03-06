
/*
     File: APACharacter.m
 Abstract: n/a
  Version: 1.2
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import "Character.h"
#import "APAGraphicsUtilities.h"
#import "ParallaxSprite.h"
#import "Boss.h"
#import "PlayerHero.h"


@interface Character ()
@property (nonatomic) SKSpriteNode *shadowBlob;
@end

@implementation Character

#pragma mark - Initialization
- (id)initWithTexture:(SKTexture *)texture atPosition:(CGPoint)position {
    self = [super initWithTexture:texture];
    
    if (self) {
        self.usesParallaxEffect = NO;           // standard sprite - there's no parallax
        [self sharedInitAtPosition:position];
        self.physicsBody.friction = 1.0f;
        self.physicsBody.restitution = 0.0f;
        self.physicsBody.linearDamping = 0.1f;
        self.physicsBody.mass = 0.2f;
        
        if([self isKindOfClass:[PlayerHero class]])
            [self increaseMana];
        
        SKAction *wait = [SKAction waitForDuration:0.5];
        SKAction *isInLava = [SKAction runBlock:^{
            if(self.isInLava == TRUE){

                //partícula da lava
                SKEmitterNode *emitter = [[self damageEmitter] copy];
                if (emitter) {

                    //emitter.zPosition = 5;
                    [self addChild:emitter];
                    APARunOneShotEmitter(emitter, 1.5f);
                }
                
                
                
                
                
                
//                SKEmitterNode *emitter = [[self deathEmitter] copy];
//                emitter.zPosition = -0.8;
//                [self addChild:emitter];
//                APARunOneShotEmitter(emitter, 1.5f);
                
//                [self runAction:[SKAction sequence:@[
//                                                     [SKAction waitForDuration:2.0f],
//                                                     [SKAction runBlock:^{
//                    [scene heroWasKilled:self];
//                }],
//                                                     [SKAction removeFromParent],
//                                                     ]]];
                
                
                
                
                [self applyDamage:10.0f];
            }
        }];
        SKAction *checkLava = [SKAction sequence:@[wait,isInLava]];
        [self runAction:[SKAction repeatActionForever:checkLava]];
    }
    
    return self;
}

- (id)initWithSprites:(NSArray *)sprites atPosition:(CGPoint)position usingOffset:(CGFloat)offset {
    self = [super initWithSprites:sprites usingOffset:offset];
    if (self) {
        [self sharedInitAtPosition:position];
    }
    
    return self;
}

- (void)sharedInitAtPosition:(CGPoint)position {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"Environment"];
    
    _shadowBlob = [SKSpriteNode spriteNodeWithTexture:[atlas textureNamed:@"blobShadow.png"]];
    _shadowBlob.zPosition = -1.0f;
    
    self.position = position;
    
    _health = 100.0f;
    _mana = 100.0f;
    _movementSpeed = kMovementSpeed;
    _animated = YES;
    _animationSpeed = 1.0f/28.0f;
    _atackSpeed = 1.0f/78.f;
    _atackDamage = 2.0f;
    [self configurePhysicsBody];
}

- (void)reset {
    // Reset some base states (used when recycling character instances).
    self.health = 100.0f;
    self.mana = 100.0f;
    self.dying = NO;
    self.attacking = NO;
    self.inLava = NO;
    self.animated = YES;
    self.requestedAnimation = APAAnimationStateIdle;
    self.shadowBlob.alpha = 1.0f;
}

#pragma mark - Overridden Methods
- (void)configurePhysicsBody {
    // Overridden by subclasses to create a physics body with relevant collision settings for this character.
}

- (void)animationDidComplete:(APAAnimationState)animation {
    // Called when a requested animation has completed (usually overriden).
}

- (void)performHeroAttackAction {
    if (self.attacking) {
        return;
    }
    
    if (self.mana < kManaToProjectile && [self isKindOfClass:[PlayerHero class]]) {
        return;
    }else{
        self.mana -= kManaToProjectile;
    }
    self.attacking = YES;
    self.requestedAnimation = APAAnimationStateAttack;
}

- (void)performEnemyAttackAction {
    if (self.attacking) {
        return;
    }
    
    self.attacking = YES;
    self.requestedAnimation = APAAnimationStateAttack;
}


- (void)collidedWith:(SKPhysicsBody *)other {
    // Handle a collision with another character, projectile, wall, etc (usually overidden).
}

- (void)performDeath {
    [self removeAllActions];
    self.health = 0.0f;
    self.dying = YES;
    self.requestedAnimation = APAAnimationStateDeath;
    [self resolveRequestedAnimation];
}

#pragma mark - Damage
- (BOOL)applyDamage:(CGFloat)damage fromProjectile:(SKNode *)projectile {
    return [self applyDamage:damage * projectile.alpha];
}

- (BOOL)applyDamage:(CGFloat)damage {
    // Apply damage and return YES if death.
    self.health -= damage;
    if([self isKindOfClass:[PlayerHero class]]){
        GameScene *scene = (GameScene *)self.scene;
        [scene updateHUDForPlayer:(PlayerHero *)self];
    }
    if (self.health > 0.0f) {
        //APAMultiplayerLayeredCharacterScene *scene = (APAMultiplayerLayeredCharacterScene *)[self characterScene];
        
        // Build up "one shot" particle.
        SKEmitterNode *emitter = [[self damageEmitter] copy];
        if (emitter) {
            //[scene addNode:emitter atWorldLayer:APAWorldLayerAboveCharacter];
            
            emitter.position = self.position;
            APARunOneShotEmitter(emitter, 0.15f);
        }
        
        // Show the damage.
        SKAction *damageAction = [self damageAction];
        if (damageAction) {
            [self runAction:damageAction];
        }
        
        
        return NO;
    }
    
    [self performDeath];
    
    return YES;
}

#pragma mark - Mana
- (BOOL)decreaseMana:(CGFloat)mana {
    
    // Decrease mana and return YES, if the have enought mana, return NO
    if ((self.mana - mana) >= 0) {
        
        self.mana -= mana;
        if([self isKindOfClass:[PlayerHero class]]){
            GameScene *scene = (GameScene *)self.scene;
            [scene updateHUDForPlayer:(PlayerHero *)self];
        }
        return YES;

    }else{
        return NO;
    }
}

- (void)increaseMana {
    
    if (self.mana < 100) {
        
        if (self.mana + kIncreaseManaAmount >= 100) {
            self.mana += 100 - self.mana;
        }else{
            self.mana += kIncreaseManaAmount;
        }
        
        if([self isKindOfClass:[PlayerHero class]]){
            GameScene *scene = (GameScene *)self.scene;
            [scene updateHUDForPlayer:(PlayerHero *)self];
        }
    }
    
    if (!self.isDying) {
        [self performSelector:@selector(increaseMana) withObject:nil afterDelay:kIncreaseManaInterval];
    }
}

#pragma mark - Setting Shadow Blob properties
- (void)setScale:(CGFloat)scale {
    [super setScale:scale];
    
    self.shadowBlob.scale = scale;
}

- (void)setAlpha:(CGFloat)alpha {
    [super setAlpha:alpha];
    
    self.shadowBlob.alpha = alpha;
}

#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval {
    // Shadow always follows our main sprite.
    self.shadowBlob.position = self.position;

    if (self.isAnimated) {
        [self resolveRequestedAnimation];
    }
}

#pragma mark - Animation
- (void)resolveRequestedAnimation {
    // Determine the animation we want to play.
    NSString *animationKey = nil;
    NSArray *animationFrames = nil;
    APAAnimationState animationState = self.requestedAnimation;
    self.animationSpeed = 1.0f/28.0f;
    switch (animationState) {
            
        default:
        case APAAnimationStateIdle:
            animationKey = @"anim_idle";
            animationFrames = [self idleAnimationFrames];
            break;
            
        case APAAnimationStateWalk:
            animationKey = @"anim_walk";
            animationFrames = [self walkAnimationFrames];
            break;
            
        case APAAnimationStateAttack:
            animationKey = @"anim_attack";
            if([self isKindOfClass:[Boss class]]){
                self.animationSpeed = self.atackSpeed;
            }else{
                self.animationSpeed = 1.0f/88.0f;
            }
            animationFrames = [self attackAnimationFrames];
            break;
            
        case APAAnimationStateGetHit:
            animationKey = @"anim_gethit";
            animationFrames = [self getHitAnimationFrames];
            break;
            
        case APAAnimationStateDeath:
            animationKey = @"anim_death";
            animationFrames = [self deathAnimationFrames];
            break;
    }
    
    if (animationKey) {
        [self fireAnimationForState:animationState usingTextures:animationFrames withKey:animationKey];
    }
    
    self.requestedAnimation = self.dying ? APAAnimationStateDeath : APAAnimationStateIdle;
}

- (void)fireAnimationForState:(APAAnimationState)animationState usingTextures:(NSArray *)frames withKey:(NSString *)key {
    SKAction *animAction = [self actionForKey:key];
    if (animAction || [frames count] < 1) {
        return; // we already have a running animation or there aren't any frames to animate
    }
    self.activeAnimationKey = key;
    if(!([self isKindOfClass:[Boss class]] && self.attacking && (animationState != APAAnimationStateAttack && animationState != APAAnimationStateDeath))){
        [self runAction:[SKAction sequence:@[
                                             [SKAction animateWithTextures:frames timePerFrame:self.animationSpeed resize:YES restore:NO],
                                             [SKAction runBlock:^{
            [self animationHasCompleted:animationState];
        }]]] withKey:key];
    }
}

- (void)fadeIn:(CGFloat)duration {
    // Fade in the main sprite and blob shadow.
    SKAction *fadeAction = [SKAction fadeInWithDuration:duration];
    
    self.alpha = 0.0f;
    [self runAction:fadeAction];
    
    self.shadowBlob.alpha = 0.0f;
    [self.shadowBlob runAction:fadeAction];
}


- (void)animationHasCompleted:(APAAnimationState)animationState {
    if (self.dying) {
        self.animated = NO;
        [self.shadowBlob runAction:[SKAction fadeOutWithDuration:1.5f]];
    }
    
    [self animationDidComplete:animationState];
    
    if (self.attacking && animationState == APAAnimationStateAttack) {
        self.attacking = NO;
    }
    
    self.activeAnimationKey = nil;
}

#pragma mark - Working with Scenes

- (void)removeFromParent {
    [self.shadowBlob removeFromParent];
    [super removeFromParent];
}

- (GameScene *)characterScene {
    GameScene *scene = (id)[self scene];
    
    if ([scene isKindOfClass:[GameScene class]]) {
        return scene;
    } else {
        return nil;
    }
}

#pragma mark - Orientation and Movement

- (CGFloat)faceTo:(CGPoint)position {
    CGFloat ang = APA_POLAR_ADJUST(APARadiansBetweenPoints(position, self.position));
    SKAction *action = [SKAction rotateToAngle:ang duration:0.0];
    [self runAction:action];
    return ang;
}

- (void)moveTowards:(CGPoint)position withTimeInterval:(NSTimeInterval)timeInterval {
    //self.physicsBody.velocity = CGVectorMake(0, 0);
    CGPoint curPosition = self.position;
    CGFloat dx = position.x - curPosition.x;
    CGFloat dy = position.y - curPosition.y;
    CGFloat dt = self.movementSpeed * timeInterval;
    
    CGFloat ang = APA_POLAR_ADJUST(APARadiansBetweenPoints(position, curPosition));
    self.zRotation = ang;
    
    CGFloat distRemaining = hypotf(dx, dy);
    if (distRemaining < dt) {
        self.position = position;
    } else {
        self.position = CGPointMake(curPosition.x - sinf(ang)*dt,
                                    curPosition.y + cosf(ang)*dt);
    }
    
    self.requestedAnimation = APAAnimationStateWalk;
}

- (void)moveInDirection:(CGPoint)direction withTimeInterval:(NSTimeInterval)timeInterval {
    CGPoint curPosition = self.position;
    CGFloat movementSpeed = self.movementSpeed;
    CGFloat dx = movementSpeed * direction.x;
    CGFloat dy = movementSpeed * direction.y;
    CGFloat dt = movementSpeed * timeInterval;
    
    CGPoint targetPosition = CGPointMake(curPosition.x + dx, curPosition.y + dy);
    
    CGFloat ang = APA_POLAR_ADJUST(APARadiansBetweenPoints(targetPosition, curPosition));
    self.zRotation = ang;
    
    CGFloat distRemaining = hypotf(dx, dy);
    if (distRemaining < dt) {
        self.position = targetPosition;
    } else {
        self.position = CGPointMake(curPosition.x - sinf(ang)*dt,
                                    curPosition.y + cosf(ang)*dt);
    }

    // Don't change to a walk animation if we planning an attack.
    if (!self.attacking) {
        self.requestedAnimation = APAAnimationStateWalk;
    }
}

#pragma mark - Shared Assets
+ (void)loadSharedAssets {
    // overridden by subclasses
}

- (NSArray *)idleAnimationFrames {
    return nil;
}

- (NSArray *)walkAnimationFrames {
    return nil;
}

- (NSArray *)attackAnimationFrames {
    return nil;
}

- (NSArray *)getHitAnimationFrames {
    return nil;
}

- (NSArray *)deathAnimationFrames {
    return nil;
}

- (SKEmitterNode *)damageEmitter {
    return nil;
}

- (SKAction *)damageAction {
    return nil;
}

@end
