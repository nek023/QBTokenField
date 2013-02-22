//
//  ViewController.m
//  QBTokenField
//
//  Created by questbeat on 2013/02/01.
//  Copyright (c) 2013年 Katsuma Tanaka. All rights reserved.
//

#import "ViewController.h"

#import "QBToken.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    
    // tokenField
    QBTokenField *tokenField = [[QBTokenField alloc] initWithFrame:CGRectMake(0, 0, 320, 42)];
    tokenField.delegate = self;
    
    for(NSUInteger i = 0; i < 20; i++) {
        QBToken *token = [QBToken tokenWithText:[NSString stringWithFormat:@"token%d", i]];
        [tokenField addToken:token animated:NO];
    }
    
    [self.view addSubview:tokenField];
    [tokenField release];
}


#pragma mark - QBTokenFieldDelegate

- (BOOL)tokenField:(QBTokenField *)tokenField shouldChangeHeight:(CGFloat)height
{
    return YES;
}

@end
