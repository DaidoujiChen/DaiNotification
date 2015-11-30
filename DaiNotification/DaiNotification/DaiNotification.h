//
//  DaiNotification.h
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DaiNotification : NSObject

+ (void)show:(UIView *(^)(void))view notificationDuration:(NSTimeInterval)duration whenClicked:(void (^)(void))clicked delayForNext:(NSTimeInterval)delay;

@end
