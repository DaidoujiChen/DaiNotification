//
//  DaiNotification.m
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "DaiNotification.h"
#import <objc/runtime.h>
#import "DaiNotificationOperation.h"

@implementation DaiNotification

#pragma mark - Class Method

+ (void)show:(UIView *(^)(void))view notificationDuration:(NSTimeInterval)duration whenClicked:(void (^)(void))clicked {
    [self show:view notificationDuration:duration whenClicked:clicked];
}

+ (void)show:(UIView *(^)(void))view notificationDuration:(NSTimeInterval)duration whenClicked:(void (^)(void))clicked delayForNext:(NSTimeInterval)delay {
    
    if (!view) {
        NSLog(@"View 為必要創建元件");
        return;
    }
    
    NSMapTable *newMapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsCopyIn valueOptions:NSPointerFunctionsCopyIn];
    [newMapTable setObject:view forKey:@"view"];
    [newMapTable setObject:@(duration) forKey:@"duration"];
    if (!clicked) {
        [newMapTable setObject:clicked forKey:@"clicked"];
    }
    
    // 加入 operation queue
    [[self notificationQueue] addOperation:[[DaiNotificationOperation alloc] initWithMapTable:newMapTable]];
    if (delay > 0) {
        [[self notificationQueue] addOperationWithBlock: ^{
            [NSThread sleepForTimeInterval:delay];
        }];
    }
}

#pragma mark - Runtime Object

+ (NSOperationQueue *)notificationQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSOperationQueue *notificationOperationQueue = [NSOperationQueue new];
        notificationOperationQueue.maxConcurrentOperationCount = 1;
        objc_setAssociatedObject(self, _cmd, notificationOperationQueue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
    return  objc_getAssociatedObject(self, _cmd);
}

@end
