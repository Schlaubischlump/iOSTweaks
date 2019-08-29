// reuse this class for every Plugin Architecture (should work as drop in replacement)
// multiple plugin systems based on centerName

#import "DD_ExtensionLoader.h"

#import <objc/runtime.h>
#import "rocketbootstrap.h"

@implementation DD_ExtensionLoader
@synthesize currentStatus  = _currentStatus;
@synthesize hasLoadedPlugins = _hasLoadedPlugins;

- (id)init
{
    if(self = [super init])
    {
        self.hasLoadedPlugins = NO;
        
        plugins     = [[NSMutableArray alloc] init];
        identifiers = [[NSMutableArray alloc] init];
        
        NSString *centerName = [self centerName];
        if (centerName)
        {
            messagingCenter = (CPDistributedMessagingCenter *)[CPDistributedMessagingCenter centerNamed:centerName];
            rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
            [messagingCenter runServerOnCurrentThread];
            [messagingCenter registerForMessageName:    @"Plugins" target:self selector: @selector(returnPlugins)];
            [messagingCenter registerForMessageName: @"PluginInfo" target:self selector: @selector(returnPluginInfo:withUserInfo:)];
            [messagingCenter registerForMessageName:@"LoadPlugins" target:self selector:     @selector(loadItems)];
            [messagingCenter registerForMessageName:     @"Update" target:self selector:        @selector(update)];
        }
    }
    return self;
}

- (NSString *)centerName
{
    return nil;
}

- (NSDictionary *)returnPluginInfo:(NSString *)name withUserInfo:(NSDictionary *)userinfo
{
    NSString *plugin_id = userinfo[@"plugin_ID"];
    return @{@"name" : [self pluginNameForId:plugin_id], @"imagePath" : [self pluginImagePathForId:plugin_id]};
}


- (NSDictionary *)returnPlugins
{
    return @{ @"EnabledPlugins" : [self enabledPluginsIndexed], @"DisabledPlugins" : [self disabledPlugins] };
}

- (void)update
{
    [self setStatus:Update];
}

- (void)setStatus:(Status)theStatus
{
    self.currentStatus = theStatus;
}

- (BOOL)isOSVersionSupported:(NSString *)minOS
{
    return (!minOS || minOS.length < 1 ||[[[UIDevice currentDevice] systemVersion] compare:minOS options:NSNumericSearch] != NSOrderedAscending);
}

- (void)loadItems
{
    if(!self.hasLoadedPlugins)
    {
        [plugins removeAllObjects];
        [identifiers removeAllObjects];
        NSFileManager *fm = [[NSFileManager alloc] init];
        NSArray *dirContents = [fm contentsOfDirectoryAtPath:PLUGIN_PATH error:nil];
        
        for(unsigned int i = 0; i < dirContents.count; i++) {
            NSString *path = [PLUGIN_PATH stringByAppendingPathComponent:dirContents[i]];
            
            if([[path pathExtension] isEqualToString:@"bundle"])
            {
                NSBundle *bundle = [NSBundle bundleWithPath:path];
                NSError *error = nil;
                if ([self isOSVersionSupported:[bundle objectForInfoDictionaryKey:@"MinimumOSVersion"]] ) {
                    [bundle loadAndReturnError:&error];
                    if(!error) {
                        id plugin = [self createPluginForBundle:bundle];
                        
                        if (plugin){
                            [identifiers addObject:bundle.bundleIdentifier];
                            [plugins addObject:plugin];
                        }

                    }
                }
            }
        }
        [fm release];
        
        self.hasLoadedPlugins = YES;
    }
}

- (id)createPluginForBundle:(NSBundle *)bundle
{    
    return nil;
}

- (NSMutableArray *)disabledPlugins
{
    [self loadItems];
    NSMutableArray *array = [NSMutableArray array];
    
    for(int i = 0; i< [identifiers count]; i++)
    {
        NSString *pid = [identifiers objectAtIndex:i];
        if(![self isPluginEnabled:pid])
            [array addObject:pid];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    NSArray *tmpDisabled = [dict[@"Plugins"] objectForKey:@"Disabled"];
    NSMutableArray *disabledPlugins = [NSMutableArray array];
    if (tmpDisabled)
    {
        for (NSString *pid in tmpDisabled)
            if ([array containsObject:pid])
                [disabledPlugins addObject:pid];
        
        return disabledPlugins;
    }
    
    return array;
}

- (NSMutableArray *)enabledPluginsIndexed
{
    [self loadItems];
    NSMutableArray *array = [NSMutableArray array];
    
    for(int i = 0; i< [identifiers count]; i++)
    {
        NSString *pid = [identifiers objectAtIndex:i];
        if ([self isPluginEnabled:pid])
            [array addObject:pid];
        
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    NSArray *tmpEnabled = [dict[@"Plugins"] objectForKey:@"Enabled"];
    NSMutableArray *enabledPlugins = [NSMutableArray array];
    
    if (tmpEnabled)
    {
        //FIX: plugin was removed
        for (NSString *pid in tmpEnabled)
            if ([array containsObject:pid])
                [enabledPlugins addObject:pid];
        
        //FIX: plugin was added
        for (NSString *pid in array)
            if (![enabledPlugins containsObject:pid])
                [enabledPlugins addObject:pid];
        
        return enabledPlugins;
    }
    return array;
}

- (BOOL)isPluginEnabled:(NSString *)plugin_id
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:SETTINGS_PATH];
    NSArray *disabledPlugins = [dict[@"Plugins"] objectForKey:@"Disabled"];
    if (disabledPlugins)
        return ![disabledPlugins containsObject:plugin_id];
    return YES;
}

- (id)pluginForId:(NSString *)plugin_id
{
    NSUInteger index = [identifiers indexOfObject:plugin_id];
    id plugin = plugins[index];
    if (plugin)
        return plugin;
    return nil;
}

- (NSString *)pluginNameForId:(NSString *)plugin_id
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:PLUGIN_PATH error:nil];
    
    for(unsigned int i = 0; i < dirContents.count; i++) {
        NSString *path = [PLUGIN_PATH stringByAppendingPathComponent:dirContents[i]];
        
        if([[path pathExtension] isEqualToString:@"bundle"])
        {
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            if([plugin_id isEqualToString:bundle.bundleIdentifier])
                return [bundle objectForInfoDictionaryKey:@"name"];
        }
    }
    return plugin_id;
}

- (NSString *)pluginImagePathForId:(NSString *)plugin_id
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:PLUGIN_PATH error:nil];
        
    for(unsigned int i = 0; i < [dirContents count]; i++) {
        NSString *path = [PLUGIN_PATH stringByAppendingPathComponent:[dirContents objectAtIndex:i]];
            
        if([[path pathExtension] isEqualToString:@"bundle"]) {
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            
            if([plugin_id isEqualToString:[bundle bundleIdentifier]]) {
                NSString *iconName =  [bundle objectForInfoDictionaryKey:@"icon"];
                NSString *iconPath = [bundle pathForResource:[iconName stringByDeletingPathExtension] ofType:[iconName pathExtension]];
                if(iconName && iconPath)
                    return iconPath;
            }
        }
    }
    return [SETTINGS_BUNDLE_PATH stringByAppendingPathComponent:@"Not_Found.png"];
}

- (NSMutableArray *)plugins
{
    return plugins;
}

- (void)dealloc
{
    [plugins release];
    [identifiers release];
    
    [super dealloc];
}
@end