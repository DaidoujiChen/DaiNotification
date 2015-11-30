//
//  DaiNotificationWindow.h
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DaiNotificationWindowDelegate;

@interface DaiNotificationWindow : UIWindow

@property (nonatomic, weak) id <DaiNotificationWindowDelegate> eventDelegate;

@end

@protocol DaiNotificationWindowDelegate <NSObject>

@required
- (BOOL)shouldHandleTouchAtPoint:(CGPoint)point;

@end
