//
//  ViewController.m
//  BEPiDGame
//
//  Created by Felipe Dias Pereira on 27/03/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import "ViewController.h"
#import "GameScene.h"
#import "InicialScene.h"
@interface ViewController()
{
    SKView * skViewGame;
    GameScene * sceneGame;
    SKSpriteNode *nodoSombra;
    SKCropNode *cropNode;
    SKSpriteNode *textureNode;
    NSInteger difficult;
}
@property (weak, nonatomic) IBOutlet UIButton *btHard;
@property (weak, nonatomic) IBOutlet UIButton *btMedium;
@property (weak, nonatomic) IBOutlet UIButton *btEasy;
@property (weak, nonatomic) IBOutlet UIView *viewConfig;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //seta bordas redondas dos botões
    self.btEasy.layer.borderWidth = 0.5f;
    self.btEasy.layer.cornerRadius = 5;
    self.btMedium.layer.borderWidth = 0.5f;
    self.btMedium.layer.cornerRadius = 5;
    self.btHard.layer.borderWidth = 0.5f;
    self.btHard.layer.cornerRadius = 5;
    
    // Configure the view.
    skViewGame = (SKView *)self.view;
    skViewGame.showsFPS = YES;
    skViewGame.showsNodeCount = YES;
    skViewGame.showsPhysics = YES;
    
    // Create and configure the scene.
    sceneGame = [GameScene sceneWithSize:CGSizeMake(skViewGame.bounds.size.height,skViewGame.bounds.size.width)];
    sceneGame.scaleMode = SKSceneScaleModeAspectFill;
    
    [skViewGame presentScene:sceneGame];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)EsconderScene
{
    [self hideUIElements:YES animated:YES];
}

#pragma mark - UI Display and Actions
- (void)hideUIElements:(BOOL)shouldHide animated:(BOOL)shouldAnimate {
    CGFloat alpha = shouldHide ? 0.0f : 1.0f;
    
    if (shouldAnimate) {
        [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.btEasy.alpha = alpha;
            self.btMedium.alpha = alpha;
            self.btHard.alpha = alpha;
            self.viewConfig.alpha = alpha;
        } completion:NULL];
    } else {
        [self.btEasy setAlpha:alpha];
        [self.btMedium setAlpha:alpha];
        [self.btHard setAlpha:alpha];
        [self.viewConfig setAlpha:alpha];
    }
}
- (IBAction)TouchEasy:(id)sender
{
    difficult = [(UIButton *)sender tag];
    [self EsconderScene];
    
}
- (IBAction)TouchMedium:(id)sender
{
    difficult = [(UIButton *)sender tag];
    [self EsconderScene];
}

- (IBAction)TouchHard:(id)sender
{
    difficult = [(UIButton *)sender tag];
    [self EsconderScene];
}

@end
