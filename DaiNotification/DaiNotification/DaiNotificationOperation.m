//
//  DaiNotificationOperation.m
//  DaiNotification
//
//  Created by DaidoujiChen on 2015/11/30.
//  Copyright © 2015年 DaidoujiChen. All rights reserved.
//

#import "DaiNotificationOperation.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface DaiNotificationOperation ()

// 讓 NSOperation 知道是不是該結束了
@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;

// 由外部代入的對應表, 其中包含需要顯示的畫面, 停留時間, 被點擊時的動作
@property (nonatomic, strong) NSMapTable *mapTable;
@property (nonatomic, readonly) UIView *view;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) void (^clicked)(void);

// 顯示用的 window
@property (nonatomic, strong) DaiNotificationWindow *notificationWindow;

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

#pragma mark * Fest Access Current Object, Readonly

// 唯讀, 取得使用者自定義 view 一次
- (UIView *)view {
    if (!objc_getAssociatedObject(self, _cmd)) {
        objc_setAssociatedObject(self, _cmd, [self userCustomView], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return objc_getAssociatedObject(self, _cmd);
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
        UIView *view = weakSelf.view;
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat viewHeight = CGRectGetHeight(view.bounds);
        CGRect newFrame = view.frame;
        newFrame.origin = CGPointMake((screenWidth - viewWidth) / 2, -viewHeight);
        view.frame = newFrame;
        [weakSelf.notificationWindow addSubview:view];
    });
}

#pragma mark * 為使用者客製的 view 添加手勢動作

// 修改使用者傳入的 view
- (UIView *)userCustomView {
    UIView *(^viewBlock)(void) = [self.mapTable objectForKey:@"view"];
    UIView *view = viewBlock();
    [self disableUserInteractionOn:view];
    view.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClicked)];
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
- (void)onClicked {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf fadeOut];
        weakSelf.clicked();
    });
}

// 滑動通知可以移動通知, 用移動的距離決定是否上縮
- (void)onPan:(UIPanGestureRecognizer *)panGestureRecognizer {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(dismiss) object:nil];

        CGPoint previousLocation = objc_getAssociatedObject(weakSelf, _cmd) ? [objc_getAssociatedObject(weakSelf, _cmd) CGPointValue] : CGPointZero;
        if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
            previousLocation = [panGestureRecognizer locationInView:weakSelf.view.superview];
        }
        else if (panGestureRecognizer.state == UIGestureRecognizerStatePossible || panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            
            // 通知的位置只要往上超過自身高度的 1 / 3 就往上收回去, 否則就往下彈
            if (weakSelf.view.frame.origin.y <= -CGRectGetHeight(weakSelf.view.bounds) / 3) {
                [weakSelf dismiss];
            }
            else {
                [weakSelf show];
            }
            return;
        }
        
        CGPoint currentLocation = [panGestureRecognizer locationInView:weakSelf.view.superview];
        CGFloat deltaY = currentLocation.y - previousLocation.y;
        CGPoint newCenter = weakSelf.view.center;
        newCenter.y += deltaY;
        if (newCenter.y >= CGRectGetHeight(weakSelf.view.bounds) / 2) {
            newCenter.y = CGRectGetHeight(weakSelf.view.bounds) / 2;
        }
        weakSelf.view.center = newCenter;
        objc_setAssociatedObject(weakSelf, _cmd, [NSValue valueWithCGPoint:currentLocation], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

#pragma mark * 動畫效果

// 通知掉下來的動畫
- (void)show {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *view = weakSelf.view;
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat gapToLeft = (screenWidth - viewWidth) / 2;
        
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.55f initialSpringVelocity:0.55f options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations: ^{
            CGRect animationFrame = view.frame;
            animationFrame.origin = CGPointMake(gapToLeft, 0);
            view.frame = animationFrame;
        } completion: ^(BOOL finished) {
            [weakSelf performSelector:@selector(dismiss) withObject:nil afterDelay:weakSelf.duration];
        }];
    });
}

// 通知收回去的動畫
- (void)dismiss {
    __weak DaiNotificationOperation *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *view = weakSelf.view;
        CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat viewHeight = CGRectGetHeight(view.bounds);
        CGFloat gapToLeft = (screenWidth - viewWidth) / 2;
        
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseInOut animations: ^{
            CGRect animationFrame = view.frame;
            animationFrame.origin = CGPointMake(gapToLeft, -viewHeight);
            view.frame = animationFrame;
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

#pragma mark - operation status

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
