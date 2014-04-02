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
@end

@implementation ChaseAI

#pragma mark - Initialization
- (id)initWithCharacter:(Character *)character target:(Character *)target {
    self = [super initWithCharacter:character target:target];
    if (self) {
        _maxAlertRadius = (kEnemyAlertRadius * 2.0f);
        _chaseRadius = (kCharacterCollisionRadius * 2.0f);
        _walking = FALSE;
    }
    return self;
}

#pragma mark - Loop Update
- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)interval {
    Character *ourCharacter = self.character;
    
    if (ourCharacter.dying) {
        self.target = nil;
        return;
    }
    if(!self.walking){
        GameScene *scene = [ourCharacter characterScene];
        self.walking = TRUE;
        CGPoint point = CGPointMake(
                    random() % (unsigned int)scene.island.size.width,
                    random() % (unsigned int)scene.island.size.height);
        self.pointToWalk = point;
    }
    
    // If there's no target, don't do anything.
    Character *target = self.target;
    if (!target) {
        //return;
    }
    
    // Otherwise chase or attack the target, if it's near enough.
    CGFloat chaseRadius = self.chaseRadius;
    CGPoint position = ourCharacter.position;
    CGFloat distance = APADistanceBetweenPoints(position, self.pointToWalk);
    if (distance > chaseRadius) {
        CGFloat pointX = (self.pointToWalk.x - position.x)/500 + position.x;
        CGFloat pointY = (self.pointToWalk.y - position.y)/500 + position.y;
        [self.character moveTowards:CGPointMake(pointX, pointY) withTimeInterval:interval];
    } else if (distance < chaseRadius) {
        self.walking = FALSE;
    }
}

@end
