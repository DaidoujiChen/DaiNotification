//
//  DaiNotificationOperation.h
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DaiNotificationWindow.h"

@interface DaiNotificationOperation : NSOperation <DaiNotificationWindowDelegate>

- (instancetype)initWithMapTable:(NSMapTable *)mapTable;

@end