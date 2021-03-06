//
//  LogoViewController.m
//  BEPiDGame
//
//  Created by Jáder Borba Nunes on 07/04/14.
//  Copyright (c) 2014 Felipe Dias Pereira. All rights reserved.
//

#import "LogoViewController.h"
@interface LogoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *gameLogo;
@property (weak, nonatomic) IBOutlet UIButton *btJogar;
@end

@implementation LogoViewController

-(void)viewWillAppear:(BOOL)animated
{
    //seta bordas redondas dos botões
    self.btJogar.backgroundColor = [UIColor redColor];
    self.btJogar.layer.borderWidth = 0.5f;
    self.btJogar.layer.cornerRadius = 5;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (IBAction)TouchJogar:(id)sender
{
    [self performSegueWithIdentifier: @"gotoDifficult" sender: self];
}

@end
