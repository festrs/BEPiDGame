/*
     File: APAEnemyCharacter.m
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

#import "EnemyCharacter.h"
#import "ArtificialIntelligence.h"

#define kHeroProjectileSpeed 280.0
#define kHeroProjectileLifetime 2.0 // 1.0 seconds until the projectile disappears
#define kHeroProjectileFadeOutTime 0.6 // 0.6 seconds until the projectile starts to fade out

@implementation EnemyCharacter

#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval {
    [super updateWithTimeSinceLastUpdate:interval];
    
    [self.intelligence updateWithTimeSinceLastUpdate:interval];
}

- (void)animationDidComplete:(APAAnimationState)animationState {
    if (animationState == APAAnimationStateAttack) {
        // Attacking hero should apply same damage as collision with hero, so simply
        // tell the target that we collided with it.
        //[self.intelligence.target collidedWith:self.physicsBody];
        [self fireProjectile];
    }
}

#pragma mark - Projectiles
- (void)fireProjectile {
    GameScene *scene = [self characterScene];
    
    //sfor (int i = -4; i <=5 ; i++) {
        SKSpriteNode *projectile = [[self projectile] copy];
        projectile.physicsBody.affectedByGravity=NO;
        projectile.position = self.position;
        projectile.zRotation = self.zRotation;
        SKEmitterNode *emitter = [[self projectileEmitter] copy];
        emitter.targetNode = [self.scene childNodeWithName:@"world"];
        [projectile addChild:emitter];
        
        
        [scene addNode:projectile];
        
        CGFloat rot = projectile.zRotation;
        
        [projectile runAction:[SKAction moveByX:-sinf(rot)*self.projectileSpeed*kHeroProjectileLifetime
                                              y:cosf(rot)*self.projectileSpeed*kHeroProjectileLifetime
                                       duration:kHeroProjectileLifetime]];
        
        [projectile runAction:[SKAction sequence:@[[SKAction waitForDuration:kHeroProjectileFadeOutTime],
                                                   [SKAction fadeOutWithDuration:kHeroProjectileLifetime - kHeroProjectileFadeOutTime],
                                                   [SKAction removeFromParent]]]];
        [projectile runAction:[self projectileSoundAction]];
    //}

    self.intelligence.target = nil;
    //projectile.userData = [NSMutableDictionary dictionaryWithObject:self.player forKey:kPlayer];
}

- (SKSpriteNode *)projectile {
    // Overridden by subclasses to return a suitable projectile.
    return nil;
}

- (SKEmitterNode *)projectileEmitter {
    // Overridden by subclasses to return the particle emitter to attach to the projectile.
    return nil;
}

static SKAction *sSharedProjectileSoundAction = nil;
- (SKAction *)projectileSoundAction {
    return sSharedProjectileSoundAction;
}




@end
