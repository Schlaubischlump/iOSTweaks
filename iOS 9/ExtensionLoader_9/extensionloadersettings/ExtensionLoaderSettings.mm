#import "../DD_Defines.h"

#import <UIKit/UIKit.h>
#import <AppSupport/AppSupport.h>
#import <Preferences/Preferences.h>
#import <objc/runtime.h>
#import "rocketbootstrap.h"

#define kTitleValueSection 0
#define kEnabledPluginsSection 1
#define kDisabledPluginsSection 2
#define kDonateButtonSection 3

#define kBlueColor [UIColor colorWithRed:61.0f/255.0f green:164.0f/255.0f blue:248.0f/255.0f alpha:1.0]

@interface NSMutableArray (Extras)
@end
@implementation NSMutableArray (Extras)

- (void)moveObjectFromIndex:(NSUInteger)origIndex toIndex:(NSUInteger)newIndex
{
    if (newIndex != origIndex) {
        id object = [self objectAtIndex:origIndex];
        [object retain];
        [self removeObjectAtIndex:origIndex];
        if (newIndex >= [self count]) {
            [self addObject:object];
        } else {
            [self insertObject:object atIndex:newIndex];
        }
        [object release];
    }
}
@end


@interface PSViewController (_view)
@property (nonatomic, assign) NSString *title;
- (UINavigationController *)navigationController;
- (void)setView:(UIView *)view;
- (void)viewDidLoad;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewWillAppear:(BOOL)animated;
@end

@interface ExtensionLoaderSettingsListController : PSViewController  <UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *enabledPlugins;
    NSMutableArray *disabledPlugins;
    NSString *pluginPath;
    CPDistributedMessagingCenter *messagingCenter;
}
- (void)savePreferences;
- (NSMutableArray *)enabledPlugins;
- (NSMutableArray *)disabledPlugins;

@end


@implementation ExtensionLoaderSettingsListController

#pragma mark -
#pragma mark - Setup

- (id)init 
{
    if (self = [super init]) {
        self.title = NAME;
        
        messagingCenter = (CPDistributedMessagingCenter *)[objc_getClass("CPDistributedMessagingCenter") centerNamed:NC_CENTER_NAME];
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        [messagingCenter sendMessageName:@"LoadPlugins" userInfo:nil];
        
        NSDictionary *plugins = [messagingCenter sendMessageAndReceiveReplyName:@"Plugins" userInfo:nil];
        enabledPlugins =  [[NSMutableArray alloc] initWithArray:[plugins objectForKey:@"EnabledPlugins"]];
        disabledPlugins = [[NSMutableArray alloc] initWithArray:[plugins objectForKey:@"DisabledPlugins"]];
        pluginPath = [NSString stringWithFormat:@"%@", [plugins objectForKey:@"PluginPath"]];
    }
    
    return self;
}

- (void)loadView
{
    UITableView *tableView = [[UITableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    
    self.view = tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    self.table.editing = YES;
    self.table.allowsSelectionDuringEditing = YES;
    self.table.allowsSelection = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = kBlueColor;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    self.navigationController.navigationBar.tintColor = nil;
}

-(void)dealloc
{
    [enabledPlugins release];
    [disabledPlugins release];
    [super dealloc];
    
}


#pragma mark -
#pragma mark - Getter

- (UITableView *)table
{
    // fix resume of preference app
    return (UITableView *)self.view;
}


- (NSMutableArray *)enabledPlugins
{
    return enabledPlugins;
}

- (NSMutableArray *)disabledPlugins
{
    return disabledPlugins;
}


#pragma mark -
#pragma mark - Helper

-(void)openPayPal
{
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@""]];
}

- (void)savePreferences
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
    if(!dict)
        dict = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *indexDict = [NSMutableDictionary dictionary];
    [indexDict setObject:self.enabledPlugins forKey:@"Enabled"];
    [indexDict setObject:self.disabledPlugins forKey:@"Disabled"];
    [dict setObject:indexDict forKey:@"Plugins"];
    [dict writeToFile:SETTINGS_PATH atomically:YES];
    [dict release];
    
    // Plugins need reload
    [messagingCenter sendMessageName:@"Update" userInfo:nil];
}



#pragma mark - UITableView
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == kEnabledPluginsSection) {
        int enabledPluginsCount = self.enabledPlugins.count;
        return (enabledPluginsCount == 0) ? 1 : enabledPluginsCount;
    } else if (section == kDisabledPluginsSection) {
        int disabledPluginsCount = self.disabledPlugins.count;
        return (disabledPluginsCount == 0) ? 1 : disabledPluginsCount;
    } else if (section == kTitleValueSection) {
        return 1;
    } else if (section == kDonateButtonSection) {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kEnabledPluginsSection)
        return @"Enabled Plugins";
    else if (section == kDisabledPluginsSection)
        return @"Disabled Plugins";
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kDisabledPluginsSection)
        return @"Reorder plugins in NotificationCenter.";
    else if (section == kDonateButtonSection)
        return @"© 2014 David Klopp";
    return nil;
}
    
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTitleValueSection && indexPath.row == 0)
        return 80;
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kTitleValueSection && indexPath.row == 0)
        return 80;
    return 44;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == kDonateButtonSection && indexPath.row == 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const cellID = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID forIndexPath:indexPath];
    
    if (indexPath.section == kTitleValueSection && indexPath.row == 0) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = NAME;
        cell.textLabel.alpha = 1.0f;
        cell.textLabel.textColor = [UIColor blackColor];
        
        NSString *imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"HeaderIcon@2x" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:imgPath];
    } else if (indexPath.section == kDonateButtonSection && indexPath.row == 0) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.text = @"Donate";
        cell.textLabel.alpha = 1.0f;
        cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
                
        NSString *imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"paypal@2x" ofType:@"png"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:imgPath];
    } else if ((indexPath.section == kEnabledPluginsSection && self.enabledPlugins.count > 0) || (indexPath.section == kDisabledPluginsSection && self.disabledPlugins.count > 0)) {
        NSString *bundle_ID = (indexPath.section == kEnabledPluginsSection ? self.enabledPlugins[indexPath.row] : self.disabledPlugins[indexPath.row]);
        
        NSDictionary *dict = [NSDictionary dictionaryWithObject:bundle_ID forKey:@"plugin_ID"];
        NSDictionary *info = [messagingCenter sendMessageAndReceiveReplyName:@"PluginInfo" userInfo:dict];
        
        cell.textLabel.text = info[@"name"];
        cell.imageView.image = [UIImage imageWithContentsOfFile:info[@"imagePath"]];
        cell.textLabel.alpha = 1.0f;
        cell.textLabel.textAlignment= NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor blackColor];
    } else {
        cell.imageView.image = nil;
        cell.textLabel.alpha = 0.5f;
        cell.textLabel.text = @"Empty";
        cell.textLabel.textAlignment= NSTextAlignmentLeft;
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    return cell;
}
    
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == kEnabledPluginsSection || indexPath.section == kDisabledPluginsSection || (indexPath.section == kDonateButtonSection && indexPath.row == 0));
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((self.enabledPlugins.count <= 1 && indexPath.section == kEnabledPluginsSection) || (self.disabledPlugins.count == 0 && indexPath.section == kDisabledPluginsSection))
        return FALSE;
    
    return (indexPath.section == kEnabledPluginsSection || indexPath.section == kDisabledPluginsSection);
}



#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kDonateButtonSection && indexPath.row == 0) {
        [self openPayPal];
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    int section = proposedDestinationIndexPath.section;
    
    if ((self.enabledPlugins.count == 0 && section == kEnabledPluginsSection) || (self.disabledPlugins.count == 0 && section == kDisabledPluginsSection))
        proposedDestinationIndexPath = [NSIndexPath indexPathForRow:(section == kEnabledPluginsSection) ? 0 : 0 inSection:section];
    
    return (section == kEnabledPluginsSection || section == kDisabledPluginsSection) ? proposedDestinationIndexPath : sourceIndexPath;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    BOOL clearRow = ((toIndexPath.section == kEnabledPluginsSection && self.enabledPlugins.count == 0) || (toIndexPath.section == kDisabledPluginsSection && self.disabledPlugins.count == 0));
    
    
    // update plugin arrays
    NSIndexPath *insertIndexPath = toIndexPath;    
    if (clearRow)
        insertIndexPath = [NSIndexPath indexPathForRow:0 inSection:toIndexPath.section];
    
    
    if(fromIndexPath.section == kDisabledPluginsSection && toIndexPath.section == kDisabledPluginsSection)
    {
        [self.disabledPlugins moveObjectFromIndex:fromIndexPath.row toIndex:insertIndexPath.row];
    }
    else if(fromIndexPath.section == kEnabledPluginsSection && toIndexPath.section == kDisabledPluginsSection)
    {
        [self.disabledPlugins insertObject:self.enabledPlugins[fromIndexPath.row] atIndex:insertIndexPath.row];
        [self.enabledPlugins removeObjectAtIndex:fromIndexPath.row];
    }
    else if (fromIndexPath.section == kDisabledPluginsSection && toIndexPath.section == kEnabledPluginsSection)
    {
        
        [self.enabledPlugins insertObject:self.disabledPlugins[fromIndexPath.row] atIndex:insertIndexPath.row];
        [self.disabledPlugins removeObjectAtIndex:fromIndexPath.row];
    }
    else if(toIndexPath.section == kEnabledPluginsSection && fromIndexPath.section == kEnabledPluginsSection) {
        [self.enabledPlugins moveObjectFromIndex:fromIndexPath.row toIndex:insertIndexPath.row];
    }
    
    
    
    /*/ check this if arrays are updated
    BOOL insertRow = ((fromIndexPath.section == kEnabledPluginsSection && self.enabledPlugins.count == 0) || (fromIndexPath.section == kDisabledPluginsSection && self.disabledPlugins.count == 0));
    
    if (insertRow)
    {
        int section = fromIndexPath.section;
        int row = 0;
        
        NSIndexPath *indexPathToAdd = [NSIndexPath indexPathForRow:row inSection:section];
        [self.table insertRowsAtIndexPaths:@[indexPathToAdd] withRowAnimation:UITableViewRowAnimationFade];
    }
    
    
    // animate Cells
    if (clearRow)
    {
        int section = toIndexPath.section;
        int row = (section == kDisabledPluginsSection) ? 1 : 0;
        
        NSIndexPath *indexPathToRemove = [NSIndexPath indexPathForRow:row inSection:section];
        [self.table deleteRowsAtIndexPaths:@[indexPathToRemove] withRowAnimation:UITableViewRowAnimationFade];
    }*/
    
    // save changes
    [self savePreferences];
}



// undocumented
// - (void)tableView:(UITableView *)tableView didCancelReorderingRowAtIndexPath:(NSIndexPath *)indexPath {}
// - (void)tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath {}

- (void)tableView:(UITableView *)tableView didEndReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView reloadData];
}




@end

