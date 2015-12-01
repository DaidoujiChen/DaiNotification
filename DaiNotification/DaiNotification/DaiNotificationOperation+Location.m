//
//  DaiNotificationOperation+Location.m
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/12/1.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "DaiNotificationOperation+Location.h"
#import <UIKit/UIKit.h>

@implementation DaiNotificationOperation (Location)

// 通知縮上去時的 frame
- (CGRect)notificationDismissFrame:(CGRect)originFrame {
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat viewWidth = CGRectGetWidth(originFrame);
    CGFloat viewHeight = CGRectGetHeight(originFrame);
    CGFloat gapToLeft = (screenWidth - viewWidth) / 2;
    CGRect dismissFrame = originFrame;
    dismissFrame.origin = CGPointMake(gapToLeft, -viewHeight);
    return dismissFrame;
}

// 通知秀出來時的 frame
- (CGRect)notificationShowFrame:(CGRect)originFrame {
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat viewWidth = CGRectGetWidth(originFrame);
    CGFloat gapToLeft = (screenWidth - viewWidth) / 2;
    CGRect dismissFrame = originFrame;
    dismissFrame.origin = CGPointMake(gapToLeft, 0);
    return dismissFrame;
}

// 是不是低於 1 / 3 的自身高度
- (BOOL)isLessOneThirdOfHeight:(CGRect)viewFrame {
    return viewFrame.origin.y <= -CGRectGetHeight(viewFrame) / 3;
}

// 修正移動過後的通知中心點
- (CGPoint)notificationFixedCenter:(UIView *)view currentLocation:(CGPoint)currentLocation previousLocation:(CGPoint)previousLocation {
    CGFloat deltaY = currentLocation.y - previousLocation.y;
    CGPoint fixedCenter = view.center;
    fixedCenter.y += deltaY;
    if (fixedCenter.y >= CGRectGetHeight(view.bounds) / 2) {
        fixedCenter.y = CGRectGetHeight(view.bounds) / 2;
    }
    return fixedCenter;
}

@end
