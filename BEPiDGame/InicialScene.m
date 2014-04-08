//
//  InicialScene.m
//  BEPiDGame
//
//  Created by Jáder Borba Nunes on 02/04/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import "InicialScene.h"

@implementation InicialScene
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        SKTexture *spaceshipTextureLava = [SKTexture textureWithImageNamed:@"lava"];
		SKTexture *halfSpaceshipTextureLava = [SKTexture textureWithRect:CGRectMake(0, 0, 1.0,1.0) inTexture:spaceshipTextureLava];
		SKSpriteNode *textureNodeLava = [SKSpriteNode spriteNodeWithTexture:halfSpaceshipTextureLava];
        [textureNodeLava setSize:CGSizeMake(self.frame.size.width, self.frame.size.height)];
        textureNodeLava.alpha = 0.3;
		textureNodeLava.position = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/2);
		[self addChild:textureNodeLava];
        
        // Texture
		SKTexture *spaceshipTexture = [SKTexture textureWithImageNamed:@"logoInicial"];
		SKTexture *halfSpaceshipTexture = [SKTexture textureWithRect:CGRectMake(0, 0, 1.0,1.0) inTexture:spaceshipTexture];
		SKSpriteNode *textureNode = [SKSpriteNode spriteNodeWithTexture:halfSpaceshipTexture];
        [textureNode setSize:CGSizeMake(350.0, 180.0)];
		textureNode.position = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/1.5);
		[self addChild:textureNode];
        
        SKTexture *spaceshipTextureFundo = [SKTexture textureWithImageNamed:@"FundoLogo"];
		SKTexture *halfSpaceshipTextureFundo = [SKTexture textureWithRect:CGRectMake(0, 0, 1.0,1.0) inTexture:spaceshipTextureFundo];
		SKSpriteNode *textureNodeFundo = [SKSpriteNode spriteNodeWithTexture:halfSpaceshipTextureFundo];
        [textureNodeFundo setSize:CGSizeMake(350.0, 180.0)];
		textureNodeFundo.position = CGPointMake(CGRectGetWidth(self.frame)/2, CGRectGetHeight(self.frame)/1.5);
        
        // Crop
		SKCropNode *cropNode = [SKCropNode new];
		cropNode.maskNode = textureNode;
		[cropNode addChild:textureNodeFundo];
		[self addChild:cropNode];
    }
    return self;
}
@end
