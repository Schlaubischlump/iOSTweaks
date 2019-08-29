#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>

#define kGrayColor [UIColor colorWithRed:61.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0]

@interface PSListController (_HeaderFix_)
- (void)viewDidLoad;
- (UINavigationController *)navigationController;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface SmoothNCSettingsListController : PSListController
- (void)viewDidLoad;
@end


@implementation SmoothNCSettingsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"SmoothNCSettings" target:self] retain];
    }
    return _specifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"SmoothNC";
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = kGrayColor;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.navigationController.navigationBar.tintColor = nil;

	[super viewWillDisappear:animated];
}

-(void)openPayPal
{
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@""]];
}
@end
