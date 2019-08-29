#import "DD_NotificationCenter_ExtensionLoader.h"
#import "DD_Custom_SBNCColumnViewController.h"
#include "substrate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface SBModeViewController : UIViewController
- (void)_invalidateSegmentLayout;
- (void)_invalidateContentLayout;
- (void)_layoutContentIfNecessary;
- (void)_layoutSegmentsIfNecessary;
@property(retain, nonatomic) NSArray *viewControllers;
@property(nonatomic, assign) SBNCColumnViewController *selectedViewController;
- (BOOL)_contentOffset:(CGPoint *)offset forChildViewController:(SBNCColumnViewController *)controller;

//new
- (BOOL)selectedViewControllerIsLocked;
- (void)setSelectedViewControllerIsLocked:(BOOL)locked;
- (SBNCColumnViewController *)lastSelectedViewController;
- (void)setLastSelectedViewController:(SBNCColumnViewController *)viewController;
@end


DD_NotificationCenter_ExtensionLoader *ncExtensionLoader;


%hook SBModeViewController

%new
- (BOOL)selectedViewControllerIsLocked
{
    /*
    If your tweak manipulates "selectedViewController" while NotificationCenter is not showing:
    If you want your changes to take effect, override this methode to always return NO.
    Note: You must take care of opening the right segment yourself!
    */
    return [objc_getAssociatedObject(self, @selector(dd_selectedViewControllerIsLocked)) boolValue];
}

%new(v@:B)
- (void)setSelectedViewControllerIsLocked:(BOOL)locked
{
    objc_setAssociatedObject(self, @selector(dd_selectedViewControllerIsLocked), @(locked), OBJC_ASSOCIATION_ASSIGN);
}


%new
- (SBNCColumnViewController *)lastSelectedViewController
{
    return objc_getAssociatedObject(self, @selector(dd_lastSelectedViewController));
}

%new(v@:@)
- (void)setLastSelectedViewController:(SBNCColumnViewController *)viewController
{
    objc_setAssociatedObject(self, @selector(dd_lastSelectedViewController), viewController, OBJC_ASSOCIATION_ASSIGN);
}



// Fix Notification center opens wrong segment

- (void)viewDidAppear:(BOOL)appear
{
    self.selectedViewControllerIsLocked = YES;
    %orig;
}

- (void)viewWillDisappear:(BOOL)appear
{
    self.selectedViewControllerIsLocked = NO;
    %orig;
}




// load our plugins

- (void)_loadContentView
{
    %orig;
    
    // Slider, buttons etc. inside  DD_Custom_SBNCColumnViewController.view respond better
    UIScrollView *contentView = MSHookIvar<UIScrollView *>(self, "_contentView");
    contentView.delaysContentTouches = NO;
}

- (void)setViewControllers:(NSArray *)controllers
{
    [ncExtensionLoader loadItems];

    if(controllers && ncExtensionLoader.defaultViewControllers.count == 0) {
        [ncExtensionLoader.defaultViewControllers addObjectsFromArray:controllers];
        [ncExtensionLoader addDefaultViewControllerIdentifiers];
    }

    NSMutableArray *plugins = [NSMutableArray array];
    NSMutableArray *enabledPIDs = [ncExtensionLoader enabledPlugins];

    for(unsigned int i=0; i < enabledPIDs.count; i++) {
        DD_Custom_SBNCColumnViewController *pidViewController = [ncExtensionLoader pluginForId:enabledPIDs[i]];
        if(pidViewController)
            [plugins addObject:pidViewController];
    }

    // addControllers
    %orig(plugins);
}


- (void)viewWillAppear:(BOOL)appear
{
    // force reload of plugins
    if(ncExtensionLoader.currentStatus == Update) {
        HBLogDebug(@"reload");
        [self _invalidateSegmentLayout];
        [self _invalidateContentLayout];
        [self setViewControllers:nil];
        [self _layoutContentIfNecessary];
        [self _layoutSegmentsIfNecessary];
        
        NSString *pid = ncExtensionLoader.enabledPlugins[0];
        self.lastSelectedViewController = [ncExtensionLoader pluginForId:pid];
    }
    
    [ncExtensionLoader setStatus:Normal];
    
    %orig;
}

- (void)setSelectedViewController:(SBNCColumnViewController *)selectedViewController animated:(BOOL)animated
{
    SBNCColumnViewController *oldSelectedViewController = (SBNCColumnViewController *)self.selectedViewController;
    
    // Fix NotificationCenter opens wrong segment after closing custom view
    if (!self.selectedViewControllerIsLocked)
        selectedViewController = self.lastSelectedViewController;
    %orig(selectedViewController, animated);
    
    if ([oldSelectedViewController isKindOfClass:%c(SBNCColumnViewController)]) {
        for (SBNCColumnViewController *viewCon in self.viewControllers) {
            BOOL isSelectedViewController = (viewCon == selectedViewController);
            BOOL isOldSelectedViewController = (viewCon == oldSelectedViewController);

            if (isSelectedViewController && !isOldSelectedViewController)
                [viewCon dd_ObserverViewControllerEntersForeground];
            else if (!isSelectedViewController && isOldSelectedViewController)
                [viewCon dd_ObserverViewControllerEntersBackground];
        }
    }
    
    self.lastSelectedViewController = selectedViewController;
}

- (void)viewWillLayoutSubviews
{
    %orig;
    
    // FIX: view not appering because of wrong offset
    // has this something to do with autolayout or size classes ? 
    for (SBNCColumnViewController *con in self.viewControllers) {
        UIView *view = con.view;
        CGRect frame = view.frame;
        CGPoint offset = CGPointZero;
        [self _contentOffset:&offset forChildViewController:con];
        frame.origin = offset;
        view.frame = frame;
    }
}

%end




%hook SBNCColumnViewController
%new(@@:)
- (id)plugin_id {
    return self.title ? [NSString stringWithFormat:@"%lu_%@", (unsigned long)self.hash, self.title] : @"";
}

%new(v@:)
- (void)dd_ObserverViewControllerEntersForeground {}

%new(v@:)
- (void)dd_ObserverViewControllerEntersBackground {}

%end



%hook SBTodayViewController
- (id)plugin_id
{
    return NC_TODAY_IDENTIFIER;
}
%end


%hook SBNotificationsViewController
- (id)plugin_id
{
    return NC_NOTIFICATIONS_IDENTIFIER;
}
%end



%ctor 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    ncExtensionLoader = [[DD_NotificationCenter_ExtensionLoader alloc] init];

    [pool release];
}