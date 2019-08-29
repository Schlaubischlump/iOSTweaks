#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>


#define kGrayColor [UIColor colorWithRed:61.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0]



@interface PSListController (_HeaderFix_)
- (void)viewDidLoad;
- (UINavigationController *)navigationController;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
@end

@interface NCModifierSettingsListController : PSListController
- (void)viewDidLoad;
@end


@implementation NCModifierSettingsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"NCModifierSettings" target:self] retain];
    }
    return _specifiers;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"NCModifier";
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
    system("killall -9 backboardd");
}

- (void)openPayPal
{
    [[UIApplication sharedApplication]openURL:[NSURL URLWithString:@""]];
} 
@end
