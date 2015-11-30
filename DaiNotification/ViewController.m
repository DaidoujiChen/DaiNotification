//
//  ViewController.m
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "ViewController.h"
#import "DaiNotification.h"

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    for (NSInteger index = 0; index < 100; index++) {
        [DaiNotification show: ^UIView *{
            CGFloat maxWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, maxWidth - 20, 64)];
            UIView *notificationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, maxWidth - 20, 44)];
            notificationView.backgroundColor = [UIColor orangeColor];
            notificationView.layer.cornerRadius = 10.0f;
            notificationView.layer.shadowColor = [UIColor blackColor].CGColor;
            notificationView.layer.shadowOffset = CGSizeMake(1.5f, 1.5f);
            notificationView.layer.shadowOpacity = 1.0f;
            notificationView.layer.shadowRadius = 1.0f;
            notificationView.center = containerView.center;
            [containerView addSubview:notificationView];
            UILabel *newLabel = [[UILabel alloc] initWithFrame:notificationView.bounds];
            newLabel.backgroundColor = [UIColor clearColor];
            newLabel.textColor = [UIColor whiteColor];
            newLabel.text = [NSString stringWithFormat:@"這是第 %td 則通知!!", index];
            newLabel.textAlignment = NSTextAlignmentCenter;
            [notificationView addSubview:newLabel];
            return containerView;
        } notificationDuration:5.0f whenClicked: ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"通知被點到了!!" message:[NSString stringWithFormat:@"這是第 %td 則通知!!", index] delegate:nil cancelButtonTitle:@"好!" otherButtonTitles:nil];
            [alert show];
        } delayForNext:1.5f];
    }
}

@end
