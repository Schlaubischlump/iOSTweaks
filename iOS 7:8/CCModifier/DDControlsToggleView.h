//
//  DDControlsToggleView.h
//  
//
//  Created by David Klopp on 08.03.14.
//
//

#import "DDSystemMediaControlsViewController.h"
#import "DDSwitchesScrollView.h"

@interface DDControlsToggleView : UIView
@property(nonatomic, readonly) DDSystemMediaControlsViewController *mediaControlsViewController;
@property(nonatomic, readonly) DDSwitchesScrollView *switchesView;
- (void)layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds;
- (void)reloadSwitchView;
- (void)layoutSwitchView;
@end
