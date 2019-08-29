// TO-DO
// does this work when airplay mirroring is enabled (?) ([UIScreen mainScreen])
// code cleanup

//thoughts:
// execution time of _UIReplicantView and IOSurface is almost identical on iPhone (0.02s)
// correct me:  _UIReplicantView is much faster on iPad (why?)


#include "substrate.h"
#import "NCModifier.h"

#ifndef kCFCoreFoundationVersionNumber_iOS_7_1
    #define kCFCoreFoundationVersionNumber_iOS_7_1 847.26
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
    #define kCFCoreFoundationVersionNumber_iOS_8_0 1129.15
#endif


// global paths
#define kSnapshotName @"com.devDav.NCModifier.Snapshot"
#define kBundlePath @"/Library/Application Support/NCModifierResources.bundle"
#define kTweakSettings @"/var/mobile/Library/Preferences/com.devDav.NCModifier.plist"

#define kGrayColor [UIColor colorWithRed:61.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0]
#define kCornerRadius 4.0
#define kSegmentHeight 32.0

// change this values if you like
#define kAdditionalSegmentOffsetX 35.0
#define kAdditionalHeaderOffsetY 5.0

// this values might change when apple changes NC layout
#define kStatusbarHeight 20.0
#define kBottomGrabberOrigin 31



// user values
static BOOL showTopSeparator;
static BOOL updateStatusBar;
static BOOL enabled;



%hook SBApplication

%group iOSVersionHelper
%new
- (SBDefaultImageInfo *)_snapshotImageInfoForScreen:(UIScreen *)screen named:(NSString *)name launchingOrientation:(UIInterfaceOrientation)orientation
{
    // iOS 7.1
    if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_8_0)
        return [self _snapshotImageInfoForScreen:screen named:name downscaled:FALSE launchingOrientation:orientation];
    // iOS 8
    return [self _snapshotImageInfoForSceneID:self.mainSceneID named:name size:screen.bounds.size scale:screen.scale downscaled:FALSE launchingOrientation:orientation];
}
%end


%group iOSVersionHelper_8
%new
- (void)_saveSnapshotForScreen:(UIScreen *)screen frame:(CGRect)rect name:(NSString *)name overrideScale:(CGFloat)scale
{
    [self saveSnapshotForSceneID:self.mainSceneID frame:rect name:name overrideScale:scale];
}
%end

%end


%group NCRedesign

static UIView *snapshotShadowView;

%hook SBNotificationCenterViewController

- (void)_loadStatusBar {}

- (void)_loadGrabberContentView {}

- (BOOL)blursBackground { return FALSE; }

- (void)_loadBottomSeparator {}

- (void)_loadContentView
{
    %orig;
    
    //black color behind NC
    UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
    contentView.backgroundColor = [UIColor blackColor];
    
    // add actual background
    UIView *bgView = [[UIView alloc] initWithFrame:contentView.bounds];
    bgView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgView.backgroundColor = kGrayColor;
    bgView.layer.masksToBounds = YES;
    bgView.layer.cornerRadius = kCornerRadius;
    [contentView addSubview:bgView];
    [bgView release];
    
    // block interaction on snapshot
    snapshotShadowView = [[UIView alloc] initWithFrame:self.view.bounds];
    snapshotShadowView.backgroundColor = [UIColor blackColor];
    
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat maxWidth = (size.width > size.height) ? size.width : size.height;
    CGFloat shadowRadius = 4.0;
    
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, -shadowRadius, maxWidth, shadowRadius)];
    snapshotShadowView.layer.masksToBounds = NO;
    snapshotShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
    snapshotShadowView.layer.shadowOpacity = 0.3;
    snapshotShadowView.layer.shadowRadius = shadowRadius;
    snapshotShadowView.layer.shadowPath = shadowPath.CGPath;
    
    [self.view addSubview:snapshotShadowView];
}

- (void)dealloc
{
    [snapshotShadowView removeFromSuperview];
    snapshotShadowView = nil;
    %orig;
}

- (void)viewWillAppear:(BOOL)appear
{
    %orig;
        
    UIScreen *mainScreen = [UIScreen mainScreen];
    snapshotShadowView.frame = [self _containerFrame];
    
    if (updateStatusBar)
    {
        BOOL statusBarHidden;
        BOOL legacyStatusBar;
        int statusBarStyle;
        
        SpringBoard *springboard = (SpringBoard *)[UIApplication sharedApplication];
        SBApplication *topApp = [springboard _accessibilityFrontMostApplication];
        BOOL onLockscreen = [[%c(SBUserAgent) sharedUserAgent] deviceIsLocked];
            
        if (topApp && !onLockscreen) {
            if ([ topApp respondsToSelector:@selector(statusBarHiddenForCurrentOrientation)])
                statusBarHidden = [topApp statusBarHiddenForCurrentOrientation];
            else
                statusBarHidden = [topApp statusBarHidden];
                
            if (!statusBarHidden) {
                legacyStatusBar = MSHookIvar<BOOL>(topApp, "_statusBarIsLegacy");
                statusBarStyle = [topApp effectiveStatusBarStyle];
            }
            
            //get image orientation
            UIInterfaceOrientation orientation = [springboard _frontMostAppOrientation];
            
            CGFloat angle = 0.0;
            UIImageOrientation imageOrientation = UIImageOrientationUp;
            if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                imageOrientation = UIImageOrientationDown;
                angle = 180.0;
            } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
                imageOrientation = UIImageOrientationRight;
                angle = 90.0;
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                imageOrientation = UIImageOrientationLeft;
                angle = 270.0;
            }
            
            //add Wallpaper to Background
            int variant = [topApp wallpaperStyle];

            SCD_Struct_SB29 state;
            state.startStyle = 8;
            state.endStyle = 8;
            state.transitionFraction = 0.0;
            
            SBWallpaperEffectView *effectView = [[%c(SBWallpaperController) sharedInstance] _newWallpaperEffectViewForVariant:variant transitionState:state];
            effectView.transform = CGAffineTransformMakeRotation(angle* M_PI / 180.0);
            effectView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
            effectView.frame = snapshotShadowView.bounds;
            [snapshotShadowView addSubview:effectView];
            
            // add app snapshot (without wallpaper)
            [topApp _saveSnapshotForScreen:mainScreen frame:mainScreen.bounds name:kSnapshotName overrideScale:mainScreen.scale];
            UIImage *image = [topApp _snapshotImageInfoForScreen:mainScreen named:kSnapshotName launchingOrientation:orientation].image;

            // springboard does not darken the wallpaper => every app does this on their own
            UIImageView *appSnapshotView = [[UIImageView alloc] initWithFrame:snapshotShadowView.bounds];
            appSnapshotView.backgroundColor = [UIColor clearColor];
            appSnapshotView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            appSnapshotView.image = [UIImage imageWithCGImage:[image CGImage] scale:mainScreen.scale orientation:imageOrientation];
            [snapshotShadowView addSubview:appSnapshotView];
            [appSnapshotView release];
        } else {
            statusBarHidden = [springboard isSpringBoardStatusBarHidden];
            if (!statusBarHidden) {
                legacyStatusBar = FALSE;
                statusBarStyle = onLockscreen ? [[[%c(SBLockScreenManager) sharedInstance] lockScreenViewController] statusBarStyle] : [springboard currentHomescreenStatusBarStyle];
            }
            
            _UIReplicantView *snapshotView;
            NSMutableArray *windows = [NSMutableArray array];
            
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
                UIWindow *wallpaper = [[%c(SBWallpaperController) sharedInstance] _window];
                UIWindow *appWindow = [springboard _keyWindowForScreen:mainScreen];
                if (wallpaper) [windows addObject:wallpaper];
                if (appWindow) [windows addObject:appWindow];
                
                if (windows.count != 0)
                    snapshotView = [%c(_UIReplicantView) snapshotWindows:windows withRect:mainScreen.bounds];
            } else {
                // remove statusbar and bulletin banner from _UIReplicantView snapshot
                UIWindow *statusBarWindow = [springboard statusBarWindow];
                UIWindow *bulletinBanner = [[%c(SBBulletinWindowController) sharedInstance] window];
                if (statusBarWindow) [windows addObject:statusBarWindow];
                if (bulletinBanner) [windows addObject:bulletinBanner];
                
                if (windows.count != 0)
                    snapshotView = [mainScreen _snapshotExcludingWindows:windows withRect:mainScreen.bounds];
            }
            if (windows.count != 0)
                [snapshotShadowView addSubview:snapshotView];
        }
        
        // add "Fake" UIStatusbar
        if (!statusBarHidden) {
            UIStatusBar *statusBar = [[UIStatusBar alloc] initWithFrame:CGRectMake(0,0,snapshotShadowView.frame.size.width,0) showForegroundView:TRUE];
            statusBar.simulatesLegacyAppearance = legacyStatusBar;
            [statusBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
            [statusBar requestStyle: statusBarStyle];
            [snapshotShadowView addSubview:statusBar];
            [statusBar release];
        }
    } else {
        _UIReplicantView *snapshotView = [mainScreen snapshotViewAfterScreenUpdates:NO];
        [snapshotShadowView addSubview:snapshotView];
    }
    
    [self.view bringSubviewToFront:snapshotShadowView];
}

- (void)viewWillDisappear:(BOOL)appear
{
    %orig;
    
    [snapshotShadowView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)_setContainerFrame:(CGRect)frame
{
    %orig; //call %orig for setting right position
    
    //fix subviews position
    UIView *container = MSHookIvar<UIView *>(self, "_containerView");
    for (UIView *subview in container.subviews) {
        CGRect sFrame = subview.frame;
        sFrame.origin.y = -frame.origin.y;
        subview.frame = sFrame;
    }
    
    CGFloat bottomPreviewInset = kBottomGrabberOrigin+kStatusbarHeight-kAdditionalHeaderOffsetY;
    if (-frame.origin.y <= bottomPreviewInset)
        frame.origin.y = self.view.frame.size.height-bottomPreviewInset;
    else
        frame.origin.y += self.view.frame.size.height;
    snapshotShadowView.frame = frame;
}

// disables moving bulletin banner when NC is moving down
- (CGRect)revealRectForBulletin:(id)bulletin { return CGRectMake(0,0,0,0); }
%end


%hook SBNotificationsSectionHeaderView

- (void)setFloating:(BOOL)floating
{
    //FIX: _UIBackdropView changes color when scrolling Notifications in allView
    %orig;
    self.contentView.backgroundColor = kGrayColor;
}
%end

%hook SBNotificationCenterHeaderView

- (void)setFloating:(BOOL)floating
{
    %orig;
    self.contentView.backgroundColor = kGrayColor;
}
%end



%hook SBNotificationCenterController

- (BOOL)blursBackground { return FALSE; }

//always allow NC gesture without showing grabber view first
- (void)_setGrabberEnabled:(BOOL)enable { %orig(FALSE); }
%end

%hook SBModeViewController

- (void)viewWillLayoutSubviews
{    
    %orig;
    
    UIView *headerView = MSHookIvar<UIView *>(self, "_headerView");
    CGRect headerFrame = headerView.frame;
    headerFrame.origin.y = kAdditionalHeaderOffsetY;
    headerView.frame = headerFrame;
    
    UIView *separator = MSHookIvar<UIView *>(self, "_separator");
    separator.hidden = !showTopSeparator;
    
    UIScrollView *contentView = MSHookIvar<UIScrollView *>(self, "_contentView");
    CGPoint offset = contentView.contentOffset;
    CGRect cFrame = contentView.frame;
    cFrame.size.height -= kStatusbarHeight;
    contentView.frame = cFrame;
    contentView.contentOffset = offset; //FIX: NCObey or openNCSection error caused by settings contentView frame
}

// not there on iOS 7.1.x and up
- (CGSize)_modeControlSizeForMode:(int)mode
{
    CGSize size = %orig;
    size.width -= kAdditionalSegmentOffsetX*2;
    size.height = kSegmentHeight;
    return size;
}

- (CGRect)_modeControlFrameWithHeaderBounds:(CGRect)rect forMode:(int)mode
{
    CGRect frame = %orig;
    frame.origin.y = rect.size.height-kSegmentHeight;
    
    // iOS 7.1.x and iOS 8.x
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_1) {
        frame.size.width -= kAdditionalSegmentOffsetX*2;
        frame.size.height = kSegmentHeight;
        frame.origin.x += kAdditionalSegmentOffsetX;
    }
    
    if (showTopSeparator)
        frame.origin.y = (frame.origin.y-kAdditionalHeaderOffsetY)/2.0;
    return frame;
}
%end


%hook SBModeControlManager

- (UISegmentedControl *)_segmentedControlForUse:(int)use
{
    UISegmentedControl*segment = %orig;
    segment.tintColor = [UIColor clearColor];
    
    [segment setTitleTextAttributes: @{
        NSFontAttributeName:[UIFont boldSystemFontOfSize:13.0],
        NSForegroundColorAttributeName:[UIColor whiteColor]
    } forState:UIControlStateSelected];
    
    [segment setTitleTextAttributes: @{
        NSFontAttributeName:[UIFont boldSystemFontOfSize:13.0],
        NSForegroundColorAttributeName:[UIColor whiteColor]
    } forState:UIControlStateNormal];
    
    [segment setTitleTextAttributes: @{
        NSFontAttributeName:[UIFont boldSystemFontOfSize:13.0],
        NSForegroundColorAttributeName:[UIColor whiteColor]
    } forState:UIControlStateHighlighted];

    NSBundle *bundle = [[NSBundle alloc] initWithPath:kBundlePath];

    NSString *imagePath = [bundle pathForResource:@"Segment@2x" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    [segment setBackgroundImage:image forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    NSString *imagePathSelected = [bundle pathForResource:@"SegmentSelected@2x" ofType:@"png"];
    UIImage *imageSelected = [UIImage imageWithContentsOfFile:imagePathSelected];
    [segment setBackgroundImage:imageSelected forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [segment setBackgroundImage:imageSelected forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    NSString *dividerPathLeft = [bundle pathForResource:@"DividerLeft@2x" ofType:@"png"];
    UIImage *imageDividerLeft = [UIImage imageWithContentsOfFile:dividerPathLeft];
    [segment setDividerImage:imageDividerLeft forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segment setDividerImage:imageDividerLeft forLeftSegmentState:UIControlStateHighlighted rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    NSString *dividerPathRight = [bundle pathForResource:@"DividerRight@2x" ofType:@"png"];
    UIImage *imageDividerRight = [UIImage imageWithContentsOfFile:dividerPathRight];
    [segment setDividerImage:imageDividerRight forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [segment setDividerImage:imageDividerRight forLeftSegmentState:UIControlStateNormal rightSegmentState: UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    NSString *dividerPathNormal = [bundle pathForResource:@"DividerNormal@2x" ofType:@"png"];
    UIImage *imageDividerNormal = [UIImage imageWithContentsOfFile:dividerPathNormal];
    [segment setDividerImage:imageDividerNormal forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    NSString *dividerPathSelected = [bundle pathForResource:@"DividerSelected@2x" ofType:@"png"];
    UIImage *imageDividerSelected = [UIImage imageWithContentsOfFile:dividerPathSelected];
    [segment setDividerImage:imageDividerSelected forLeftSegmentState:UIControlStateHighlighted rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
    [segment setDividerImage:imageDividerSelected forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];

    [bundle release];

    return segment;
}
%end

%end






static void LoadSettings()
{
    CFStringRef tweakID = CFSTR("com.devDav.NCModifier");
    CFPreferencesAppSynchronize(tweakID);
    
	id tempEnabled = (id)CFPreferencesCopyAppValue(CFSTR("NCMEnabled"), tweakID);
    enabled = tempEnabled ? [tempEnabled boolValue] : YES;
    
    id tempShowSeparator = (id)CFPreferencesCopyAppValue(CFSTR("NCMShowSeparator"), tweakID);
    showTopSeparator = tempShowSeparator ? [tempShowSeparator boolValue] : FALSE;
    
    id tempUpdateStatusBar = (id)CFPreferencesCopyAppValue(CFSTR("NCMUpdateStatusBar"), tweakID);
    updateStatusBar = tempUpdateStatusBar ? [tempUpdateStatusBar boolValue] : FALSE;
}

static void SettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	LoadSettings();
}

%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LoadSettings();
    if (enabled)
        %init(NCRedesign);
        
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_1)
        %init(iOSVersionHelper);
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
        %init(iOSVersionHelper_8)
        
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, SettingsChanged, CFSTR("com.devDav.NCModifier/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        
    [pool drain];
}