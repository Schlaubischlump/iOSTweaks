#import <UIKit/UIKit.h>

@interface  SBBulletinObserverViewController : UIViewController
- (id)initWithObserverFeed:(unsigned long long)arg1;

// added
- (id)plugin_id;
- (void)dd_ObserverViewControllerEntersForeground;
- (void)dd_ObserverViewControllerEntersBackground;
@end

// default views
@interface SBTodayViewController : SBBulletinObserverViewController
@end

@interface SBNotificationsModeViewController : SBBulletinObserverViewController
@end

@interface SBNotificationsMissedModeViewController : SBNotificationsModeViewController
@end

@interface SBNotificationsAllModeViewController : SBNotificationsModeViewController
@end



@interface SBBulletinViewController : UITableViewController
- (CGRect)tableViewFrame;
@end


@interface DD_Custom_SBBulletinObserverViewController : SBBulletinObserverViewController
- (void)setPluginID:(NSString *)pluginID;
- (void)dd_insertViewContainer:(UIView *)container;
- (void)dd_informContainer:(SEL)selector;
@end