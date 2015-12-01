//
//  DaiNotificationOperation.m
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "DaiNotificationOperation.h"
#import <UIKit/UIKit.h>
#import "DaiNotificationOperation+Location.h"

@interface DaiNotificationOperation ()

// 讓 NSOperation 知道是不是該結束了
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;

// 由外部代入的對應表, 其中包含需要顯示的畫面, 停留時間, 被點擊時的動作
@property (nonatomic, strong) NSMapTable *mapTable;
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, strong) UIView *internalView;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) void (^clicked)(void);

// 顯示用的 window
@property (nonatomic, strong) DaiNotificationWindow *notificationWindow;

// 紀錄前一次 pan 的位置
@property (nonatomic, assign) CGPoint previousLocation;

@end

@implementation DaiNotificationOperation

#pragma mark - DaiNotificationWindowDelegate

// 決定要不要 handle 這個觸碰
- (BOOL)shouldHandleTouchAtPoint:(CGPoint)point {
    CGPoint pointInLocalCoordinates = [self.notificationWindow convertPoint:point fromView:nil];
    if (CGRectContainsPoint(self.view.frame, pointInLocalCoordinates)) {
        return YES;
    }
    return NO;
}

#pragma mark - Private Instance Method

#pragma mark * Fast Access Current Object, Readonly

// 唯讀, 取得使用者自定義 view 一次
- (UIView *)view {
    if (!self.internalView) {
        self.internalView = [self userCustomView];
    }
    return self.internalView;
}

// 唯讀, 取得使用者自定義通知出現時間
- (NSTimeInterval)duration {
    NSTimeInterval duration = [[self.mapTable objectForKey:@"duration"] doubleValue];
    return duration;
}

// 唯讀, 取得使用者自定義點擊動作
- (void (^)(void))clicked {
    return [self.mapTable objectForKey:@"clicked"];
}

#pragma mark * init

// 初始畫面該有項目
- (void)setupInitValues {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // 用另一個 window 來顯示
        weakSelf.notificationWindow = [[DaiNotificationWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        weakSelf.notificationWindow.eventDelegate = weakSelf;
        [weakSelf.notificationWindow makeKeyAndVisible];
        
        // 將使用者客製 view 放到正確位置
        weakSelf.view.frame = [weakSelf notificationDismissFrame:weakSelf.view.frame];
        [weakSelf.notificationWindow addSubview:weakSelf.view];
    });
}

#pragma mark * 在通知上添加手勢動作

// 修改使用者傳入的 view
- (UIView *)userCustomView {
    UIView *(^viewBlock)(void) = [self.mapTable objectForKey:@"view"];
    UIView *view = viewBlock();
    [self disableUserInteractionOn:view];
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [view addGestureRecognizer:tapGestureRecognizer];
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
    [view addGestureRecognizer:panGestureRecognizer];
    return view;
}

// 遞迴的關閉全部的 userInteractionEnabled
- (void)disableUserInteractionOn:(UIView *)view {
    view.userInteractionEnabled = NO;
    for (UIView *subview in view.subviews) {
        [self disableUserInteractionOn:subview];
    }
}

// 點擊通知觸發的手勢效果
- (void)onTap:(UITapGestureRecognizer *)tapGestureRecognizer {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf fadeOut];
        if (weakSelf.clicked) {
            weakSelf.clicked();
        }
    });
}

// 滑動通知可以移動通知, 用移動的距離決定是否上縮
- (void)onPan:(UIPanGestureRecognizer *)panGestureRecognizer {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(dismiss) object:nil];
        
        // pan 狀態為 Began 時, 紀錄第一個點
        // 為 Possible, Ended, Cancelled 實作結束動畫
        switch (panGestureRecognizer.state) {
            case UIGestureRecognizerStateBegan:
                weakSelf.previousLocation = [panGestureRecognizer locationInView:weakSelf.view.superview];
                break;
                
            case UIGestureRecognizerStatePossible:
            case UIGestureRecognizerStateEnded:
            case UIGestureRecognizerStateCancelled:
                
                // 通知的位置只要往上超過自身高度的 1 / 3 就往上收回去, 否則就往下彈
                [weakSelf isLessOneThirdOfHeight:weakSelf.view.frame] ? [weakSelf dismiss] : [weakSelf show];
                return;
                
            default:
                break;
        }
        
        // 移動後的中心點
        CGPoint currentLocation = [panGestureRecognizer locationInView:weakSelf.view.superview];
        weakSelf.view.center = [weakSelf notificationFixedCenter:weakSelf.view currentLocation:currentLocation previousLocation:self.previousLocation];
        
        // 記錄這次 pan 位置
        weakSelf.previousLocation = currentLocation;
    });
}

#pragma mark * 動畫效果

// 通知掉下來的動畫
- (void)show {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.55f initialSpringVelocity:0.55f options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations: ^{
            weakSelf.view.frame = [weakSelf notificationShowFrame:weakSelf.view.frame];
        } completion: ^(BOOL finished) {
            [weakSelf performSelector:@selector(dismiss) withObject:nil afterDelay:weakSelf.duration];
        }];
    });
}

// 通知收回去的動畫
- (void)dismiss {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations: ^{
            weakSelf.view.frame = [weakSelf notificationDismissFrame:weakSelf.view.frame];
        } completion: ^(BOOL finished) {
            [weakSelf operationFinish];
        }];
    });
}

// 通知被點擊時, 淡出的動畫效果
- (void)fadeOut {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(dismiss) object:nil];
        
        UIView *view = weakSelf.view;
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations: ^{
            view.alpha = 0;
        } completion: ^(BOOL finished) {
            [weakSelf operationFinish];
        }];
    });
}

#pragma mark - Life Cycle

// 初始方法
- (instancetype)initWithMapTable:(NSMapTable *)mapTable {
    self = [super init];
    if (self) {
        self.mapTable = mapTable;
    }
    return self;
}


#pragma mark - Observing Customization

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    return YES;
}

#pragma mark - Methods to Override

- (BOOL)isAsynchronous {
    return YES;
}

- (void)start {
    if ([self isCancelled]) {
        [self operationFinish];
        return;
    }
    [self operationStart];
    [self setupInitValues];
    [self show];
}

#pragma mark - Operation Status

- (void)operationStart {
    self.isFinished = NO;
    self.isExecuting = YES;
}

- (void)operationFinish {
    [self.mapTable removeAllObjects];
    self.notificationWindow.hidden = YES;
    self.isFinished = YES;
    self.isExecuting = NO;
}

@end
