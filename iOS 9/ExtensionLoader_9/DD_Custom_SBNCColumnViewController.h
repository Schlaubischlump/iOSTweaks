#import <UIKit/UIKit.h>


// iOS 9
@interface SBNCColumnViewController : UIViewController
// added
- (id)plugin_id;
- (void)dd_ObserverViewControllerEntersForeground;
- (void)dd_ObserverViewControllerEntersBackground;
@end



@interface  SBBulletinObserverViewController : SBNCColumnViewController
- (id)initWithObserverFeed:(unsigned long long)arg1;

// added
- (id)plugin_id;
- (void)dd_ObserverViewControllerEntersForeground;
- (void)dd_ObserverViewControllerEntersBackground;
@end


@interface SBWidgetHandlingNCColumnViewController : SBNCColumnViewController
@end



// default views
@interface SBTodayViewController : SBWidgetHandlingNCColumnViewController
@end

@interface SBNotificationsViewController : SBBulletinObserverViewController
@end



@interface DD_Custom_SBNCColumnViewController : SBNCColumnViewController
- (void)setPluginID:(NSString *)pluginID;
- (void)dd_insertViewContainer:(UIView *)container;
- (void)dd_informContainer:(SEL)selector;
@end