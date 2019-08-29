//
//  DDControlsToggleView.m
//  
//
//  Created by David Klopp on 08.03.14.
//
//

#import "DDControlsToggleView.h"
#import <objc/runtime.h>
#import "flipswitch/Flipswitch.h"
#import "CCModifier.h"


@interface DDControlsToggleView ()
- (void)_iPhone_layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds;
- (void)_iPad_layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds;
@end


@implementation DDControlsToggleView
@synthesize mediaControlsViewController = _mediaControlsViewController;
@synthesize switchesView = _switchesView;

+ (BOOL)isIPad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // Media Controls
        _mediaControlsViewController = [(DDSystemMediaControlsViewController *)[objc_getClass("DDSystemMediaControlsViewController") alloc] initWithStyle:MPUSystemMediaControlsStyleLockscreen];
        
        // setup switches
        _switchesView = [[DDSwitchesScrollView alloc] initWithFrame:CGRectZero];
        _switchesView.switchesTemplateBundle = [NSBundle bundleWithPath:kIconTemplatePath];
        [self reloadSwitchView];
        
        [self addSubview:_mediaControlsViewController.view];
        [self addSubview:_switchesView];
    }
    return self;
}

- (void)dealloc
{
    [_switchesView removeFromSuperview];
    [_mediaControlsViewController release];
    
    [super dealloc];
}

- (void)layoutSwitchView
{
    _switchesView.switchesPerPage = switchesPerPage;
    [_switchesView layoutSwitches];
}

- (void)reloadSwitchView
{
    _switchesView.switchesIdentifiers = enabledSwitches;
    [_switchesView reloadSwitches];
}

- (void)layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds
{
    // layout subviews
    if ([DDControlsToggleView isIPad])
        [self _iPad_layoutForInterfaceOrientation:orientation inBounds:bounds];
    else
        [self _iPhone_layoutForInterfaceOrientation:orientation inBounds:bounds];
}

- (void)_iPhone_layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds
{
    BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);
    CGSize size = bounds.size;
        
    // switchesView
    CGFloat switchesViewYOrigin = landscape ? 0 : 30;
    CGFloat switchesViewWidth = size.width / (landscape ? 2 : 1);;
    CGFloat switchesViewXOrigin = landscape ? size.width/4 : 0;
    CGFloat switchesViewHeight = 40.0;
    
    _switchesView.frame = CGRectMake(switchesViewXOrigin, switchesViewYOrigin, switchesViewWidth, switchesViewHeight);
    _switchesView.openOnFirstPage = openOnFirstPage;
    [_switchesView layoutSwitches];
    
    //mediaView
    CGFloat mediaViewYOrigin = (switchesViewYOrigin+switchesViewHeight);
    CGFloat mediaViewHeight = size.height -  mediaViewYOrigin;
    CGFloat mediaViewWidth = size.width / (landscape ? 2 : 1);
    CGFloat mediaViewXOrigin = landscape ? size.width/4 : 0;
    
    _mediaControlsViewController.view.frame = CGRectMake(mediaViewXOrigin, mediaViewYOrigin, mediaViewWidth, mediaViewHeight);
    [_mediaControlsViewController dd_setSlidersAlpha:landscape ? 0.0f : 1.0f];
}

- (void)_iPad_layoutForInterfaceOrientation:(UIInterfaceOrientation)orientation inBounds:(CGRect)bounds
{
    CGSize size = bounds.size;
    
    // switchesView
    CGFloat switchesViewYOrigin = size.height/5;
    CGFloat switchesViewWidth = size.width/2;
    CGFloat switchesViewXOrigin = size.width/4;
    CGFloat switchesViewHeight = 40.0;
    
    _switchesView.frame = CGRectMake(switchesViewXOrigin, switchesViewYOrigin, switchesViewWidth, switchesViewHeight);
    _switchesView.openOnFirstPage = openOnFirstPage;
    [_switchesView layoutSwitches];
    
    //mediaView
    CGFloat mediaViewYOrigin = switchesViewYOrigin+switchesViewHeight+50;
    CGFloat mediaViewHeight = size.height - mediaViewYOrigin;
    CGFloat mediaViewWidth = size.width/2;
    CGFloat mediaViewXOrigin = mediaViewWidth/2;
    
    _mediaControlsViewController.view.frame = CGRectMake(mediaViewXOrigin, mediaViewYOrigin, mediaViewWidth, mediaViewHeight);
}

@end
