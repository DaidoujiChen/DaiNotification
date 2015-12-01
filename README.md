# DaiNotification

Simple Way to Add Your Custom Notification

![image](https://s3-ap-northeast-1.amazonaws.com/daidoujiminecraft/Daidouji/DaiNotification.gif)

DaidoujiChen

daidoujichen@gmail.com

## 安裝
將 `DaiNotification/DaiNotification` 整個資料夾複製到你專案的目錄即可.

## 用法
有兩個調用方法可以啟動這個效果, 差別只在於 `Notification` 與 `Notification` 之間, 需不需要插入一個固定的秒數, 來讓顯示不這麼的頻繁, 所以第一個方法是

`````objc
+ (void)show:(UIView *(^)(void))view notificationDuration:(NSTimeInterval)duration whenClicked:(void (^)(void))clicked;
`````

- view, 在這個 block 裡面傳回你想秀在畫面上的通知
- duration, 這則通知顯示在畫面上的時間
- clicked, 當通知被點擊時, 所要做出的回應

簡單的例子可以像是這樣

`````objc
[DaiNotification show: ^UIView *{
	UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
	blackView.backgroundColor = [UIColor blackColor];
	return blackView;
} notificationDuration:10.0f whenClicked: ^{
	NSLog(@"Click!");
}];
`````

可以出現一個黑色的通知, 從畫面上方掉出, 點擊時則會打印 `Click!` 的 log.

第二個方法, 當有超過一個以上的通知要顯示, 中間需要有時間錯開時, 可以調用

`````objc
+ (void)show:(UIView *(^)(void))view notificationDuration:(NSTimeInterval)duration whenClicked:(void (^)(void))clicked delayForNext:(NSTimeInterval)delay;
`````

比上面多出來的參數為

- delay, 可以設定當前這個通知秀完之後, 幾秒後才可以顯示下一個

用同樣簡單的例子來說的話就是

`````objc
for (NSInteger index = 0; index < 100; index++) {
	[DaiNotification show: ^UIView *{
		UIView *blackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 60)];
		blackView.backgroundColor = [UIColor blackColor];
		return blackView;
	} notificationDuration:1.5f whenClicked:^{
		NSLog(@"Click!");
	} delayForNext:1.5f];
}
`````

則可以把通知間隔開來.

## TODO
- clicked block 內應該有暫停通知的方法, 延伸而來的, 就需要另一個重新啟動通知的方法



