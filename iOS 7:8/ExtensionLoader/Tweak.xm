#import "DD_NotificationCenter_ExtensionLoader.h"
#import "DD_Custom_SBBulletinObserverViewController.h"
#include "substrate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface SBModeViewController : UIViewController
- (void)_invalidateSegmentLayout;
- (void)_invalidateContentLayout;
- (void)_layoutContentIfNecessary;
- (void)_layoutSegmentsIfNecessary;
@property(retain, nonatomic) NSArray *viewControllers;
@property(nonatomic, assign) UIViewController *selectedViewController;
@end


DD_NotificationCenter_ExtensionLoader *ncExtensionLoader;

%hook SBModeViewController

- (void)_loadContentView
{
    %orig;
    
    // Slider, buttons etc. inside  DD_Custom_SBBulletinObserverViewController.view respond better
    UIScrollView *contentView = MSHookIvar<UIScrollView *>(self, "_contentView");
    contentView.delaysContentTouches = FALSE;
}

- (void)setViewControllers:(NSArray *)controllers
{
    [ncExtensionLoader loadItems];

    if(controllers && ncExtensionLoader.defaultViewControllers.count == 0) {
        [ncExtensionLoader.defaultViewControllers addObjectsFromArray:controllers];
        [ncExtensionLoader addDefaultViewControllerIdentifiers];
    }

    NSMutableArray *plugins = [NSMutableArray array];
    NSMutableArray *indexed = [ncExtensionLoader enabledPluginsIndexed];

    for(unsigned int i=0; i < indexed.count; i++) {
        DD_Custom_SBBulletinObserverViewController *pidViewController = [ncExtensionLoader pluginForId:indexed[i]];
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
        [self _invalidateSegmentLayout];
        [self _invalidateContentLayout];
        [self setViewControllers:nil];
        [self _layoutContentIfNecessary];
        [self _layoutSegmentsIfNecessary];
    }
    
    [ncExtensionLoader setStatus:Normal];

    %orig;
}

- (void)setSelectedViewController:(SBBulletinObserverViewController *)selectedViewController animated:(BOOL)animated
{
    SBBulletinObserverViewController *oldSelectedViewController = (SBBulletinObserverViewController *)self.selectedViewController;

    %orig;
    
    if ([oldSelectedViewController isKindOfClass:%c(SBBulletinObserverViewController)])
        for (SBBulletinObserverViewController *viewCon in self.viewControllers)
        {
            BOOL isSelectedViewController = (viewCon == selectedViewController);
            BOOL isOldSelectedViewController = (viewCon == oldSelectedViewController);

            if (isSelectedViewController && !isOldSelectedViewController)
                [viewCon dd_ObserverViewControllerEntersForeground];
            else if (!isSelectedViewController && isOldSelectedViewController )
                [viewCon dd_ObserverViewControllerEntersBackground];
        }
}
%end


%hook SBBulletinObserverViewController
// might support plugins which hook setViewControllers directly... this should not be necassary (>,<)
// generate custom plugin_id
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
- (id)plugin_id {
    return NC_TODAY_IDENTIFIER;
}
%end

// iOS 7 only
%hook SBNotificationsMissedModeViewController
- (id)plugin_id {
    return NC_MISSED_IDENTIFIER;
}
%end

%hook SBNotificationsAllModeViewController
- (id)plugin_id {
    return NC_ALL_IDENTIFIER;
}
%end


%ctor 
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    %init;
    ncExtensionLoader = [[DD_NotificationCenter_ExtensionLoader alloc] init];

    [pool release];
}