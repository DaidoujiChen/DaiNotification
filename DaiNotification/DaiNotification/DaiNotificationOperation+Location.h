//
//  DaiNotificationOperation+Location.h
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/12/1.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "DaiNotificationOperation.h"

@interface DaiNotificationOperation (Location)

- (CGRect)notificationDismissFrame:(CGRect)originFrame;
- (CGRect)notificationShowFrame:(CGRect)originFrame;
- (BOOL)isLessOneThirdOfHeight:(CGRect)viewFrame;
- (CGPoint)notificationFixedCenter:(UIView *)view currentLocation:(CGPoint)currentLocation previousLocation:(CGPoint)previousLocation;

@end
