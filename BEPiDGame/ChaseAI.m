/*
 File: APAChaseAI.m
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

#import "ChaseAI.h"
#import "Character.h"
#import "APAGraphicsUtilities.h"
#import "HeroCharacter.h"

@interface ChaseAI ()
@property CGPoint pointToWalk;
@property BOOL walking;
@property BOOL attacking;
@end

@implementation ChaseAI

#pragma mark - Initialization
- (id)initWithCharacter:(Character *)character target:(Character *)target {
    self = [super initWithCharacter:character target:target];
    if (self) {
        _maxAlertRadius = (kEnemyAlertRadius * 2.0f);
        _chaseRadius = (kCharacterCollisionRadius * 2.0f);
        _walking = FALSE;
        _attacking = FALSE;
        //scheduling the action to Attack
        SKAction *wait = [SKAction waitForDuration:5.3];
        SKAction *attack = [SKAction runBlock:^{
            [self performAttackMonster];
        }];
        SKAction *checkAttack = [SKAction sequence:@[wait,attack]];
        [self.character runAction:[SKAction repeatActionForever:checkAttack]];
        
    }
    return self;
}

-(void) walkAction{
    self.walking = TRUE;
    GameScene *scene = (GameScene *)self.character.scene;
    CGPoint point = CGPointMake(
                                                                     random() % (unsigned int)1024+70,
                                                                     random() % (unsigned int)640+70);
                                         self.pointToWalk = point;
    CGFloat multiplierForDirection;
    
    CGSize screenSize = scene.frame.size;
    
    float bearVelocity = 1024 / 6.0;
    
    //x and y distances for move
    CGPoint moveDifference = CGPointMake(self.pointToWalk.x - self.character.position.x, self.pointToWalk.y - self.character.position.y);
    float distanceToMove = sqrtf(moveDifference.x * moveDifference.x + moveDifference.y * moveDifference.y);
    
    float moveDuration = distanceToMove / bearVelocity;
    
    if (moveDifference.x < 0) {
        multiplierForDirection = 1;
    } else {
        multiplierForDirection = -1;
    }
    //_bear.xScale = fabs(_bear.xScale) * multiplierForDirection;
    
    CGFloat ang = APA_POLAR_ADJUST(APARadiansBetweenPoints(self.pointToWalk, self.character.position));
    self.character.zRotation = ang;
    
    if ([self.character actionForKey:@"bearMoving"]) {
        //stop just the moving to a new location, but leave the walking legs movement running
        [self.character removeActionForKey:@"bearMoving"];
    }
    
    if (![self.character actionForKey:@"walkingInPlace"]) {
        //if legs are not moving go ahead and start them
        [self.character walking];  //start the bear walking
    }
    
    SKAction *moveAction = [SKAction moveTo:self.pointToWalk duration:moveDuration];
    SKAction *doneAction = [SKAction runBlock:(dispatch_block_t)^() {
        NSLog(@"Animation Completed");
        [self.character moveEnded];
        self.walking = FALSE;
    }];
    
    SKAction *moveActionWithDone = [SKAction sequence:@[moveAction,doneAction ]];
    
    [self.character runAction:moveActionWithDone withKey:@"bearMoving"];
}



#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval {
    
//    if(!self.walking){
//        [self walkAction];
//    }
    
    Character *ourCharacter = self.character;
    GameScene *scene = [ourCharacter characterScene];
    CGPoint position = ourCharacter.position;
    if (ourCharacter.dying) {
        self.target = nil;
        return;
    }
    if(!self.walking && !self.target){
        
        self.walking = TRUE;
        CGPoint point = CGPointMake(
                                    random() % (unsigned int)scene.island.size.width+70,
                                    random() % (unsigned int)scene.island.size.height+70);
        self.pointToWalk = point;
    }
    
    
    
    // Otherwise chase or attack the target, if it's near enough.
    CGFloat chaseRadius = self.chaseRadius;
    CGFloat distance = APADistanceBetweenPoints(position, self.pointToWalk);

    if (distance > chaseRadius && self.walking && !self.target) {
        CGFloat pointX = (self.pointToWalk.x - position.x)/150 + position.x;
        CGFloat pointY = (self.pointToWalk.y - position.y)/150 + position.y;
        [self.character moveTowards:CGPointMake(pointX, pointY) withTimeInterval:interval];
    }else{
        self.walking = FALSE;
        if(self.target !=nil){
            [self.character faceTo:self.target.position];
            [self.character performAttackAction];
        }
    }
    
    
}

- (void)performAttackMonster {
    Character *ourCharacter = self.character;
    
    if (ourCharacter.dying) {
        self.target = nil;
        return;
    }
    
    CGPoint position = ourCharacter.position;
    GameScene *scene = [ourCharacter characterScene];
    CGFloat closestHeroDistance = MAXFLOAT;
    
    for (Character *hero in scene.heroes) {
        CGPoint heroPosition = hero.position;
        CGFloat distance = APADistanceBetweenPoints(position, heroPosition);
        if (distance < kEnemyAlertRadius && distance < closestHeroDistance && !hero.dying) {
            closestHeroDistance = distance;
            self.target = hero;
        }
    }
}

@end
