#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AppSupport/AppSupport.h>

#import "DD_Defines.h"

typedef enum {
    Normal = 0,
    Update = 1
}
Status;


@interface DD_ExtensionLoader : NSObject
{
    NSMutableArray *plugins;
    NSMutableArray *identifiers;
    CPDistributedMessagingCenter *messagingCenter;
    Status _currentStatus;
}
@property (nonatomic, assign) BOOL hasLoadedPlugins;

- (void)loadItems;
- (NSMutableArray *)plugins;
- (id)pluginForId:(NSString *)plugin_id;
- (BOOL)isPluginEnabled:(NSString *)plugin_id;

- (NSMutableArray *)enabledPluginsIndexed;
- (NSMutableArray *)disabledPlugins;

- (NSString *)pluginNameForId:(NSString *)plugin_id;
- (NSString *)pluginImagePathForId:(NSString *)plugin_id;

- (void)update;
- (void)setStatus:(Status)theStatus;
@property (nonatomic, assign) Status currentStatus;
@end


@interface DD_ExtensionLoader (Protected)
- (BOOL)isOSVersionSupported:(NSString *)minOS;
- (id)createPluginForBundle:(NSBundle *)bundle;
@end

@interface DD_ExtensionLoader (Plugin)
-(NSString *)plugin_id;
@end