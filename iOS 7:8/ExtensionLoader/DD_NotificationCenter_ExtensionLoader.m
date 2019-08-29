#import "DD_NotificationCenter_ExtensionLoader.h"
#import "DD_Custom_SBBulletinObserverViewController.h"

#import <objc/runtime.h>

static NSMutableArray *defaultViewControllers = nil;

@implementation DD_NotificationCenter_ExtensionLoader

- (NSString *)centerName
{
    return NC_CENTER_NAME;
}

- (DD_Custom_SBBulletinObserverViewController *)createPluginForBundle:(NSBundle *)bundle
{
    NSString *plugin_id = bundle.bundleIdentifier;
    
    
    UIView *view = [[bundle.principalClass alloc] initWithFrame:CGRectMake(0,0,0,0)];
    DD_Custom_SBBulletinObserverViewController *controller = [[objc_getClass("DD_Custom_SBBulletinObserverViewController") alloc] initWithObserverFeed:OBSERVER_FEED];
    [controller dd_insertViewContainer:view];
    [controller setPluginID:plugin_id];
    [controller setTitle:[self pluginNameForId:plugin_id]];

    [view release];
    
    return [controller autorelease];
}

- (SBBulletinObserverViewController *)pluginForId:(NSString *)plugin_id
{
    for (DD_Custom_SBBulletinObserverViewController *con in plugins)
        if ([con.plugin_id isEqualToString:plugin_id])
            return con;
    
    for (SBBulletinObserverViewController *con in defaultViewControllers)
        if([con.plugin_id isEqualToString:plugin_id])
            return con;
    
    return nil;
}

- (NSMutableArray *)defaultViewControllers
{
    if(!defaultViewControllers)
        defaultViewControllers = [[NSMutableArray alloc] init];
    
    return defaultViewControllers;
}

- (void)addDefaultViewControllerIdentifiers
{
    // only call this once // this might help to support tweaks that hook setViewControllers directly
    for (SBBulletinObserverViewController *customViewController in defaultViewControllers)
        [identifiers addObject:customViewController.plugin_id];
}

- (NSString *)pluginImagePathForId:(NSString *)plugin_id
{
    for (SBBulletinObserverViewController *con in defaultViewControllers)
        if([con.plugin_id isEqualToString:plugin_id]) {
            NSString *dvcImagePath = [NSString stringWithFormat:@"%@/%@_image@2x.png", SETTINGS_BUNDLE_PATH, plugin_id]; //only support retina
            if ([[NSFileManager defaultManager] fileExistsAtPath:dvcImagePath]) //support for direct setViewControllers hooks
                return dvcImagePath;
        }
    
    return [super pluginImagePathForId:plugin_id];
}


- (NSString *)pluginNameForId:(NSString *)plugin_id
{
    // Display Name in NC and in Settings
    for (SBBulletinObserverViewController *con in defaultViewControllers)
        if([con.plugin_id isEqualToString:plugin_id])
            return con.title;
    
    return [super pluginNameForId:plugin_id];
}

- (void)dealloc
{
    [defaultViewControllers release];
    [super dealloc];
}

@end