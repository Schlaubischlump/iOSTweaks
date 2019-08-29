#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>


#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
    #define kCFCoreFoundationVersionNumber_iOS_8_0 1129.15
#endif

#define kIsIOS8 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)


#define kDefaultEnabledSwitches @[@"com.a3tweaks.switch.airplane-mode", @"com.a3tweaks.switch.wifi", @"com.a3tweaks.switch.location", @"com.a3tweaks.switch.rotation-lock", @"com.a3tweaks.switch.cellular-data", @"com.a3tweaks.switch.3g"]


#define kResourcePath @"/Library/Application Support/CCModifier/"
#define kIconTemplatePath [kResourcePath stringByAppendingPathComponent:@"IconTemplate.bundle"]
#define kResourceBundlePath [kResourcePath stringByAppendingPathComponent:@"CCModifierResources.bundle"]

#define kPreferencePath @"/var/mobile/Library/Preferences"
#define kTweakSettings [kPreferencePath stringByAppendingPathComponent:@"com.devDav.CCModifier.plist"]
#define kSwitchesSettings [kPreferencePath stringByAppendingPathComponent:@"com.devDav.CCModifierSwitches.plist"]

#define kGrayColor [UIColor colorWithRed:61.0/255.0 green:66.0/255.0 blue:71.0/255.0 alpha:1.0]

#define kAnimationDuration 0.3f
#define kMaxDuration 0.5f
#define kMinDuration 0.25f

extern NSArray *enabledSwitches;
extern int switchesPerPage;
extern BOOL redesignMediaControls; // redesign media controls
extern BOOL doubleTapEnabled; // toggle between brightness and volume
extern int sliderType; // brightness or volume
extern BOOL resetSlider;
extern BOOL openOnFirstPage;


@interface SpringBoard : UIApplication
- (id)displayIdentifier;
- (void)_relaunchSpringBoardNow;

- (float)backlightLevel;
- (void)setBacklightLevel:(float)arg1;
@end

@interface SBUserAgent : NSObject
+ (id)sharedUserAgent;
- (BOOL)deviceIsLocked;
@end

@interface _UIParallaxMotionEffect : UIMotionEffect
@end

@interface UIView (_private_)
- ( _UIParallaxMotionEffect *)_parallaxMotionEffect;
@end

@interface SBInteractionPassThroughView : UIView
@end

@interface SBWallpaperEffectView : UIView
@end

@interface SBAppSliderSnapshotView : UIView
@end

@interface SBAppSliderHomePageCellView : UIView {
    UIImageView *_wallpaperView;
}
@end

@interface SBAppSwitcherHomePageCellView : UIView {
    UIImageView *_wallpaperView;
}
@end


@interface SBAppSliderScrollView : UIScrollView
@end

@interface SBAppSwitcherPageView : UIView
- (UIView *)view;
+ (CGSize)sizeForOrientation:(UIInterfaceOrientation)arg1;
@end

@interface SBAppSliderItemScrollView  : UIScrollView
@property(retain, nonatomic) SBAppSwitcherPageView *item;
@end

// iOS 7
@interface SBAppSliderScrollingViewController : UIViewController {
    NSMutableArray *_items;
}
- (void)_updateVisiblePageViews;
- (SBAppSwitcherPageView *)pageViewForIndex:(int)index;
@end

// iOS 8
@interface SBAppSwitcherPageViewController : UIViewController
- (void)_updateVisiblePageViews;
@end

// iOS 7
@interface SBAppSliderController : UIViewController {
    UIView *_contentView;
}
- (UIViewController *)pageController; //SBAppSliderScrollingViewController
- (UIInterfaceOrientation)_windowInterfaceOrientation;

+ (BOOL)shouldProvideHomeSnapshotIfPossible;
- (SBAppSwitcherPageView *)pageForDisplayIdentifier:(NSString *)identifier;
- (float)_scaleForFullscreenPageView;
- (void)_updatePageViewScale:(float)scale;
- (void)sliderScroller:(id)pageController itemTapped:(NSUInteger)index; //SBAppSliderScrollingViewController
- (void)sliderScroller:(id)pageController itemWantsToBeRemoved:(NSUInteger)index; //SBAppSliderScrollingViewController
- (CGRect)_nominalPageViewFrame;

// new
- (CGSize)dd_rotatetViewSize;
- (float)dd_scaleForSmallPageView;
- (CGFloat)dd_proposedPageControllerViewVerticalOffset;
@end

// iOS 8
@interface SBDIsplayItem : NSObject
@property(readonly, nonatomic) NSString *displayIdentifier;
@end

// iOS 8
@interface SBDisplayLayout : NSObject
- (NSDictionary *)plistRepresentation;
@property(readonly, nonatomic) NSArray *displayItems;
@end

// iOS 8
@interface SBAppSwitcherController : UIViewController {
}
- (UIInterfaceOrientation)_windowInterfaceOrientation;
- (UIViewController *)pageController; //SBAppSwitcherPageViewController
- (SBAppSwitcherPageView *)pageForDisplayLayout:(id)arg1;
- (float)_scaleForFullscreenPageView;
- (void)_updatePageViewScale:(float)scale;

//new
- (CGSize)dd_rotatetViewSize;
- (float)dd_scaleForSmallPageView;
- (CGFloat)dd_proposedPageControllerViewVerticalOffset;
- (void)switcherScroller:(id)scroller displayItemWantsToBeRemoved:(SBDisplayLayout *)item; //SBAppSwitcherPageViewController *
- (void)switcherScroller:(id)scroller itemTapped:(SBDisplayLayout *)arg2; //SBAppSwitcherPageViewController *
@end

// Fix Compilation
@interface UIViewController (PageControllerFix)
- (NSUInteger)currentPage;
@end

@interface UIScrollView (PageScrollViewFix)
- (UIView *)item;
@end


@interface SBControlCenterController : NSObject
@property(nonatomic, getter=isPresented) BOOL presented;
- (BOOL)dd_allowsCCMultitaskingGesture;
- (void)updateTransitionWithTouchLocation:(CGPoint)location velocity:(CGPoint)velocity;
@end

@interface  SBUIController : NSObject
+ (id)sharedInstance;
- (id)switcherController; //iOS 7:SBAppSliderController  || iOS 8:SBAppSwitcherController
- (BOOL)isAppSwitcherShowing;
- (BOOL)_activateAppSwitcherFromSide:(int)side; // iOS 7
- (BOOL)_activateAppSwitcher; // iOS 8
- (void)dismissSwitcherAnimated:(BOOL)animated;
- (void)animateAppSwitcherDismissalToApplication:(NSString *)application withCompletion:(id)completion;

- (float)dd_sliderAnimationPercentForTouchLocationY:(CGFloat)y endYPosition:(CGFloat)endY;
@end

@interface SBAssistantController : NSObject
+ (BOOL)isAssistantVisible;
@end


@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (void)decreaseVolume;
- (void)increaseVolume;
- (float)volume;
@end


typedef struct {
	int startStyle;
	int endStyle;
	CGFloat transitionFraction;
} SCD_Struct_SB29;

@interface SBWallpaperController : NSObject
+ (id)sharedInstance;
- (SBWallpaperEffectView *)_newWallpaperEffectViewForVariant:(int)variant transitionState:(SCD_Struct_SB29)arg2;
@end

