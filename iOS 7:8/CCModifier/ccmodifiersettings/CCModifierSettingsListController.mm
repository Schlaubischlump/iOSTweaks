#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import "../CCModifier.h"


@interface PSListController (_HeaderFix_)
- (void)viewDidLoad;
- (UINavigationController *)navigationController;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface CCModifierSettingsListController : PSListController
- (void)viewDidLoad;
@end


@implementation CCModifierSettingsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"CCModifierSettings" target:self] retain];
    }
    return _specifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"CCModifier";
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

- (void)performRespring
{
    system("killall -9 SpringBoard");
}

-(void)openPayPal
{
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@""]];
}
@end
