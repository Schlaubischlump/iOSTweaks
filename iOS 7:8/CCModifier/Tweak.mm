#include "substrate.h"

#import <notify.h>

#import "CCModifier.h"
#import "DDCornerView.h"
#import "DDControlsToggleView.h"
#import "flipswitch/Flipswitch.h"


/*
TODO:
- CODE CLEANUP!!!!!!
*/


// user Settings
static BOOL enabled;
static BOOL ccGestureEnabled;
static BOOL inSwitcherGestureEnabled;
static BOOL swipeUpToClose;
static BOOL disableGrabber;


int switchesPerPage;
BOOL redesignMediaControls;
NSArray *enabledSwitches;
BOOL openOnFirstPage;



static DDControlsToggleView *controlsView;
static DDCornerView *cornersView;

static BOOL isAnimatingToSwitcher = FALSE;
static int animationIndex = 0;


%group CCRedesign


%hook AppSwitcherSliderController

%new(f@:)
- (CGFloat)dd_proposedPageControllerViewVerticalOffset { return 15.0f; }

%new(f@:)
- (float)dd_scaleForSmallPageView { return 1.0; }

%new
- (CGSize)dd_rotatetViewSize
{
    // geometry isn't flipped inside SpringBoard because app switcher is actually in Portrait mode
    BOOL landscape = UIInterfaceOrientationIsLandscape([self _windowInterfaceOrientation]);
    
    CGSize viewSize = [self view].frame.size;
    CGFloat height = landscape ? viewSize.width : viewSize.height;
    CGFloat width = landscape ? viewSize.height : viewSize.width;
    return CGSizeMake(width, height);
}

- (void)loadView
{
    %orig;
    
    // gray background
    UIView *contentView = MSHookIvar<UIView *>(self, "_contentView");
    
    cornersView = [[DDCornerView alloc] initWithFrame:[self view].bounds];
    cornersView.backgroundColor = [UIColor clearColor];
    cornersView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [[self view] insertSubview:cornersView atIndex:0];
    
    if (kIsIOS8) {
        [contentView.subviews[0] removeFromSuperview];
    } else {
        // dont't eat touches in switcher: iphone uses SBInteractionPassTroughView || ipad uses UIView with _UIParallaxMotionEffect
        for (UIView *view in contentView.subviews)
            if ([view isKindOfClass:%c(SBInteractionPassThroughView)] || [view _parallaxMotionEffect])
                [view removeFromSuperview];
    }
    
    controlsView = [[DDControlsToggleView alloc] initWithFrame:CGRectZero];
    controlsView.switchesView.switchesPerPage = switchesPerPage;
    
    [contentView addSubview:controlsView];
    [controlsView.mediaControlsViewController didMoveToParentViewController:self];
    [self addChildViewController:controlsView.mediaControlsViewController];
}

- (void)viewWillAppear:(BOOL)appear
{
    %orig;
    
    // fix switches loaded to early => flipswitch toggles not working
    [controlsView reloadSwitchView];
}

//fix switchSpring tweak
- (UIScrollView *)contentScrollView
{
    UIScrollView *scrollView = %orig;
    if (!scrollView)
        return MSHookIvar<UIScrollView *>([self pageController], "_scrollView");
    return scrollView;
}

- (void)_layoutInOrientation:(UIInterfaceOrientation)orientation
{
    %orig;
    
    // update corners
    [cornersView setNeedsDisplay];
    
    // update layout of controls
    CGSize viewSize = [self dd_rotatetViewSize];
    CGFloat yOrigin = [self _nominalPageViewFrame].size.height + [self dd_proposedPageControllerViewVerticalOffset];
    
    [controlsView.mediaControlsViewController dd_willShow]; // update Slider settings
    
    controlsView.frame = CGRectMake(0,yOrigin,viewSize.width,viewSize.height - yOrigin);
    [controlsView layoutForInterfaceOrientation:orientation inBounds:controlsView.bounds];
}

- (void)handleVolumeDecrease { [[%c(SBMediaController) sharedInstance] decreaseVolume]; }

- (void)handleVolumeIncrease { [[%c(SBMediaController) sharedInstance] increaseVolume]; }

- (id)iconController { return nil; }

// iOS 8
- (id)_peopleViewController { return nil; };

// iOS 7
- (void)animatePresentationFromDisplayIdentifier:(NSString *)identifier withViews:(NSDictionary *)views fromSide:(int)side withCompletion:(void (^)(void))completion
{
    [self view].backgroundColor = kGrayColor;
    controlsView.alpha = 1.0;
    
    NSString *springboardIdentifier = [(SpringBoard *)[UIApplication sharedApplication] displayIdentifier];
    animationIndex = [identifier isEqualToString:springboardIdentifier] ? 0 : 1;
    
    isAnimatingToSwitcher = TRUE;
    %orig;
    isAnimatingToSwitcher = FALSE;
}

// iOS 8
- (void)animatePresentationFromDisplayLayout:(SBDisplayLayout *)layout withViews:(NSDictionary *)views withCompletion:(void (^)(void))completion
{
    [self view].backgroundColor = kGrayColor;
    controlsView.alpha = 1.0;
    
    NSArray *displayItems = layout.displayItems;
    if ((int)displayItems.count >= 0) {
        NSString *identifier = [(SBDIsplayItem *)displayItems[0] displayIdentifier];
        NSString *springboardIdentifier = [(SpringBoard *)[UIApplication sharedApplication] displayIdentifier];
        animationIndex = [identifier isEqualToString:springboardIdentifier] ? 0 : 1;
    
        isAnimatingToSwitcher = TRUE;
        %orig;
        isAnimatingToSwitcher = FALSE;
    }
}

// iOS 7
- (void)animateDismissalToDisplayIdentifier:(NSString *)identifier withCompletion:(void (^)(void))completion
{
    SBAppSwitcherPageView *pageView = [self pageForDisplayIdentifier:identifier];
    UIView *contentView = pageView.view;  // SBAppSliderHomePageCellView || SBAppSliderSnapshotView || SBAppSwitcherContextHostWrapperView
    
    BOOL isHomeScreen, usesWallpaper;
    isHomeScreen = [contentView isKindOfClass:%c(SBAppSliderHomePageCellView)];
    if (!isHomeScreen)
        usesWallpaper = (MSHookIvar<SBWallpaperEffectView *>(contentView, "_wallpaperEffectView") != nil);
    
    if (isHomeScreen || usesWallpaper)
        [UIView transitionWithView:cornersView duration:kAnimationDuration options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self view].backgroundColor = [UIColor clearColor];
            controlsView.alpha = 0.0;
        } completion:NULL];
    
    %orig;
}

// iOS 8
- (void)animateDismissalToDisplayLayout:(SBDisplayLayout *)layout withCompletion:(void (^)(void))completion
{
    SBAppSwitcherPageView *pageView = [self pageForDisplayLayout:layout];
    UIView *contentView = pageView.view;  // SBAppSwitcherHomePageCellView || SBAppSwitcherSnapshotView || SBAppSwitcherContextHostWrapperView
    
    BOOL isHomeScreen, usesWallpaper;
    isHomeScreen = [contentView isKindOfClass:%c(SBAppSwitcherHomePageCellView)];
    if (!isHomeScreen)
        usesWallpaper = (MSHookIvar<SBWallpaperEffectView *>(contentView, "_wallpaperEffectView") != nil);
        
        if (isHomeScreen || usesWallpaper)
            [UIView transitionWithView:cornersView duration:kAnimationDuration options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self view].backgroundColor = [UIColor clearColor];
                controlsView.alpha = 0.0;
            } completion:NULL];
    
    %orig;
}

// iOS 7
- (CGFloat)_sliderThumbnailVerticalPositionOffset
{
    // _nominalPageViewFrame is calculated based on this function
    // [self pageController].view sets its frame to _nominalPageViewFrame
    // 0 = [self view].center
    // [self view].frame.size.height/2 - appSwitcherPageView.frame.size.height/2 - _sliderThumbnailVerticalPositionOffset = Yoffset of [self pageController].view
    UIInterfaceOrientation orientation = [self _windowInterfaceOrientation];
    
    CGFloat halfViewHeight = [self dd_rotatetViewSize].height/2;
    CGFloat halfAppSwitcherPageViewHeight = [%c(SBAppSwitcherPageView) sizeForOrientation:orientation].height/2;
    CGFloat proposedYOffset = [self dd_proposedPageControllerViewVerticalOffset];
    
    return proposedYOffset-halfViewHeight+halfAppSwitcherPageViewHeight;
}

// iOS 8
- (CGFloat)_switcherThumbnailVerticalPositionOffset
{
    UIInterfaceOrientation orientation = [self _windowInterfaceOrientation];
    
    CGFloat halfViewHeight = [self dd_rotatetViewSize].height/2;
    CGFloat halfAppSwitcherPageViewHeight = [%c(SBAppSwitcherPageView) sizeForOrientation:orientation].height/2;
    CGFloat proposedYOffset = [self dd_proposedPageControllerViewVerticalOffset];
    
    return proposedYOffset-halfViewHeight+halfAppSwitcherPageViewHeight;
}

- (void)dealloc
{
    [cornersView release];
    [controlsView release];
    %orig;
}

%end


%hook PageController

// scroll to actual app that was visible
- (void)setOffsetToIndex:(int)index animated:(BOOL)animated
{
    %orig(isAnimatingToSwitcher ? animationIndex : index, animated);
    [self _updateVisiblePageViews]; //fix page on the right disappears bug (hopefully)
}
%end


%hook SBAppSwitcherPageView

// spacing between pages

// iOS 7
+ (CGFloat)_edgeBorderForOrientation:(UIInterfaceOrientation)orientation { return 10; }

// iOS 8
+ (CGFloat)_horizontalEdgeBorderForOrientation:(UIInterfaceOrientation)orientation { return 10; }

%end

%end





%group SBUIControllerHelper

%hook SBUIController

%new(f@:ff)
- (float)dd_sliderAnimationPercentForTouchLocationY:(CGFloat)y endYPosition:(CGFloat)endY
{
    id sliderController = [self switcherController];
    CGFloat height = [sliderController dd_rotatetViewSize].height;
    float flippedAnimationPercent = (y-endY)/(height-endY);
    return 1-flippedAnimationPercent;
}

- (void)handleShowNotificationsSystemGesture:(id)gesture
{
    if (!self.isAppSwitcherShowing)
        %orig;
}
%end

%end





%group CCMultitaskingGesture

static BOOL gestureStarted;
static BOOL removeCurrentItem; // swipe all the way up to close an app
static BOOL animateToOriginalCenter;

// replace ControlCenter gesture by custom gesture
%hook SBControlCenterController

%new(B@:)
- (BOOL)dd_allowsCCMultitaskingGesture
{
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    BOOL isLocked = [[%c(SBUserAgent) sharedUserAgent] deviceIsLocked];
    BOOL isShowingAssistant = [%c(SBAssistantController) isAssistantVisible];
    return !uiController.isAppSwitcherShowing && !gestureStarted && !isLocked && !isShowingAssistant;
}

- (BOOL)isGrabberVisible { return (disableGrabber) ? TRUE : %orig; }

- (void)beginTransitionWithTouchLocation:(CGPoint)location
{
    //CC was shown by activator => allow dismiss gesture || gesture allowed on lockscreen || gesture is disabled
    BOOL isLocked = [[%c(SBUserAgent) sharedUserAgent] deviceIsLocked];
    if (self.isPresented || isLocked || !ccGestureEnabled) {
        %orig;
        return;
    }
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    if ([self dd_allowsCCMultitaskingGesture]) {
        gestureStarted = TRUE;
        
        id sliderController = [uiController switcherController];
        
        // no animation
        [UIView animateWithDuration:0.0 animations:^{
            if (kIsIOS8)
                [uiController _activateAppSwitcher];
            else
                [uiController _activateAppSwitcherFromSide:2];
        }];
        
        [sliderController _updatePageViewScale:[sliderController _scaleForFullscreenPageView]]; //scale preview to fullscreen again
        
        /*/ animate to startscale => smoother animation
        [UIView animateWithDuration:0.2 animations:^{
            [self updateTransitionWithTouchLocation:location velocity:CGPointZero];
        }];*/
    }
}

- (void)updateTransitionWithTouchLocation:(CGPoint)location velocity:(CGPoint)velocity
{
    BOOL isLocked = [[%c(SBUserAgent) sharedUserAgent] deviceIsLocked];
    if (self.isPresented || isLocked || !ccGestureEnabled) {
        %orig;
        return;
    }
    
    if (!gestureStarted)
        return;
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    id sliderController = [uiController switcherController];
    UIViewController *pageController = [sliderController pageController];
    
    CGRect pageControllerFrame = pageController.view.frame;
    
    // percentage
    CGFloat endYOrigin = [sliderController dd_proposedPageControllerViewVerticalOffset];
    CGFloat pageControllerEndAnimationCenter = endYOrigin+pageControllerFrame.size.height/2;
    
    // scale
    float scaleValue;
    float minimumScale = [sliderController dd_scaleForSmallPageView];
    float maximumScale = [sliderController _scaleForFullscreenPageView];
    
    // move card up
    NSArray *itemScrollViews;
    if (kIsIOS8) {
        NSMutableDictionary *items = MSHookIvar<NSMutableDictionary *>(pageController, "_items");
        itemScrollViews = [items allValues]; // iOS 8: SBAppSwitcherItemScrollView
    } else {
        itemScrollViews = [NSArray arrayWithArray:MSHookIvar<NSMutableArray *>(pageController, "_items")]; // iOS 7: SBAppSliderItemScrollView
    }
    
    int currentPage = [pageController currentPage];
    UIScrollView *scrollView = itemScrollViews[currentPage];
    CGPoint contentOffset = scrollView.contentOffset;
    
    // touch is above the pageController center
    animateToOriginalCenter = (location.y <= pageControllerEndAnimationCenter) && swipeUpToClose;
    
    if (animateToOriginalCenter) {
        CGFloat newY = pageControllerEndAnimationCenter-location.y;
        contentOffset.y =  newY;
        scaleValue = minimumScale;
        
        //touch is heigh enough to remove Item //scrollview height is not accurate in landscape => use pageView := [scrollView item] height
        removeCurrentItem = (newY >= [scrollView item].frame.size.height/2);
    } else {
        contentOffset.y = 0;
        float percentage = [uiController dd_sliderAnimationPercentForTouchLocationY:location.y endYPosition:pageControllerEndAnimationCenter];
        scaleValue = maximumScale-((maximumScale-minimumScale)*percentage);
        
        removeCurrentItem = FALSE;
    }

    scrollView.contentOffset = contentOffset;
    [sliderController _updatePageViewScale:scaleValue];
}

- (void)endTransitionWithVelocity:(CGPoint)velocity completion:(void (^)(void))callbackBlock
{
    BOOL isLocked = [[%c(SBUserAgent) sharedUserAgent] deviceIsLocked];
    if (self.isPresented || isLocked || !ccGestureEnabled) {
        %orig;
        return;
    }
    
    if (!gestureStarted) {
        callbackBlock(); //prevent GUI from staying blocked
        return;
    }
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    id sliderController = [uiController switcherController];
    UIViewController *pageController = [sliderController pageController];

    CGFloat endYOrigin = [sliderController dd_proposedPageControllerViewVerticalOffset];
    CGFloat allPixel = [sliderController dd_rotatetViewSize].height - (endYOrigin+pageController.view.frame.size.height/2);
    
    NSTimeInterval duration = ABS(allPixel/velocity.y);
    if (duration > kMaxDuration)
        duration = kMaxDuration;
    else if (duration < kMinDuration)
        duration = kMinDuration;
            
    BOOL zoomIn = velocity.y < 0;
    float minimumScale = [sliderController dd_scaleForSmallPageView];
    
    NSArray *itemScrollViews;
    if (kIsIOS8) {
        NSMutableDictionary *items = MSHookIvar<NSMutableDictionary *>(pageController, "_items");
        itemScrollViews = [items allValues]; // iOS 8: SBAppSwitcherItemScrollView
    } else {
        itemScrollViews = [NSArray arrayWithArray:MSHookIvar<NSMutableArray *>(pageController, "_items")]; // iOS 7: SBAppSliderItemScrollView
    }
    
    int currentPage = [pageController currentPage];
    UIScrollView *scrollView = itemScrollViews[currentPage];
    
    [UIView animateWithDuration:duration animations:^{
        if (zoomIn || (animateToOriginalCenter && !removeCurrentItem)) {
            CGPoint contentOffset = scrollView.contentOffset;
            contentOffset.y = (removeCurrentItem && animateToOriginalCenter) ? scrollView.frame.size.height : 0;
            scrollView.contentOffset = contentOffset;
            
            [sliderController _updatePageViewScale:minimumScale];
        } else {
            [uiController dismissSwitcherAnimated:TRUE];
        }
    } completion:^(BOOL finished) {
        callbackBlock(); //prevent GUI from staying blocked
        
        if (removeCurrentItem) {
            // close app
            if (kIsIOS8) {
                NSMutableDictionary *items = MSHookIvar<NSMutableDictionary *>(pageController, "_items");
                [sliderController switcherScroller:pageController displayItemWantsToBeRemoved:items.allKeys[currentPage]];
            } else
                [sliderController sliderScroller:pageController itemWantsToBeRemoved:currentPage];
            removeCurrentItem = FALSE;
        }
    }];
    
    gestureStarted = FALSE;
}

- (void)cancelTransition
{
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    [uiController dismissSwitcherAnimated:TRUE];
    
    gestureStarted = FALSE;
    
    %orig;
}

%end




%end


%group SwitcherGesture

//pan down on card
static CGPoint startLocation;
static BOOL scrollsVertical;
static BOOL isFrontMostCard;

%hook PageController

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView //iOS 7: SBAppSliderItemScrollView || iOS 8: SBAppSwictherItemScrollView
{
    %orig;
    
    if (!inSwitcherGestureEnabled || gestureStarted)
        return;
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    id sliderController = [uiController switcherController];
    startLocation = [scrollView.panGestureRecognizer locationInView:(UIView *)[sliderController view]];
    
    CGPoint trueVelocity = [scrollView.panGestureRecognizer velocityInView:(UIView *)[sliderController view]];
    scrollsVertical = ABS(trueVelocity.y) > ABS(trueVelocity.x);
    
    NSArray *itemScrollViews;
    if (kIsIOS8) {
        NSMutableDictionary *items = MSHookIvar<NSMutableDictionary *>(self, "_items");
        itemScrollViews = [items allValues]; // iOS 8: SBAppSwitcherItemScrollView
    } else {
        itemScrollViews = [NSArray arrayWithArray:MSHookIvar<NSMutableArray *>(self, "_items")]; // iOS 7: SBAppSliderItemScrollView
    }
    NSUInteger index = [itemScrollViews indexOfObject:scrollView];
    isFrontMostCard = (index == [self currentPage]);
}

- (void)scrollViewDidScroll:(SBAppSliderItemScrollView  *)scrollView
{
    // gestureStarted to FIX:
    // Landscapeleft -> swipeUpToClose first app -> swipeUpToClose second app -> scrollViewDidScroll gets called -> resets contentOffset.y
    if (!inSwitcherGestureEnabled || gestureStarted) {
        %orig;
        return;
    }
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    id sliderController = [uiController switcherController];
    
    CGPoint location = [scrollView.panGestureRecognizer locationInView:(UIView *)[sliderController view]];
    BOOL isZooming = (location.y >= startLocation.y);
    
    if (isZooming && scrollsVertical && isFrontMostCard) {
        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
        
        float percentage = [uiController dd_sliderAnimationPercentForTouchLocationY:location.y endYPosition:startLocation.y];
        
        // scale
        float minimumScale = [sliderController dd_scaleForSmallPageView];
        float maximumScale = [sliderController _scaleForFullscreenPageView];
        float scaleValue = maximumScale-((maximumScale-minimumScale)*percentage);
        
        [sliderController _updatePageViewScale:scaleValue];
    } else {
        %orig;
    }
}

- (void)scrollViewWillEndDragging:(SBAppSliderItemScrollView  *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(CGPoint)contentOffset
{
    if (!inSwitcherGestureEnabled || gestureStarted) {
        %orig;
        return;
    }
    
    SBUIController *uiController = [%c(SBUIController) sharedInstance];
    id sliderController = [uiController switcherController];
    
    CGPoint location = [scrollView.panGestureRecognizer locationInView:(UIView *)[sliderController view]];
    CGPoint trueVelocity = [scrollView.panGestureRecognizer velocityInView:(UIView *)[sliderController view]];
    BOOL isZooming = (location.y >= startLocation.y);
    
    // is animating zoom at the moment
    if (isZooming && scrollsVertical && isFrontMostCard){
        CGFloat endYOrigin = [sliderController dd_proposedPageControllerViewVerticalOffset];
        CGFloat allPixel = [sliderController dd_rotatetViewSize].height - (endYOrigin+[self view].frame.size.height/2);
        
        NSTimeInterval duration = ABS(allPixel/trueVelocity.y);
        if (duration > kMaxDuration)
            duration = kMaxDuration;
        else if (duration < kMinDuration)
            duration = kMinDuration;
                
        BOOL zoomIn = trueVelocity.y < 0;
        float minimumScale = [sliderController dd_scaleForSmallPageView];
                
        [UIView animateWithDuration:duration animations:^{
            if (zoomIn)
                [sliderController _updatePageViewScale:minimumScale];
            else {
                int currentPage = [self currentPage];
                if (kIsIOS8) {
                    NSMutableDictionary *items = MSHookIvar<NSMutableDictionary *>(self, "_items");
                    [sliderController switcherScroller:self itemTapped:items.allKeys[currentPage]];
                } else {
                    [sliderController sliderScroller:self itemTapped:currentPage];
                }
            }
        }];
    } else {
        %orig;
    }
}
%end

%end



static void LoadSettings()
{
    
    CFStringRef tweakID = CFSTR("com.devDav.CCModifier");
    CFPreferencesAppSynchronize(tweakID);
    
    id tempEnabled = (id)CFPreferencesCopyAppValue(CFSTR("CCMEnabled"), tweakID);
    enabled = tempEnabled ? [tempEnabled boolValue] : YES;
    
    id tempSwipeUpToClose = (id)CFPreferencesCopyAppValue(CFSTR("CCMSwipeUpToClose"), tweakID);
    swipeUpToClose = tempSwipeUpToClose ? [tempSwipeUpToClose boolValue] : FALSE;
    
    id tempInSwitcherGestureEnabled = (id)CFPreferencesCopyAppValue(CFSTR("CCMInSwitcherGestureEnabled"), tweakID);
    inSwitcherGestureEnabled = tempInSwitcherGestureEnabled ? [tempInSwitcherGestureEnabled boolValue] : YES;
    
    id tempCCGestureEnabled = (id)CFPreferencesCopyAppValue(CFSTR("CCMCCGestureEnabled"), tweakID);
    ccGestureEnabled = tempCCGestureEnabled ? [tempCCGestureEnabled boolValue] : YES;
    
    id tempDisableGrabber = (id)CFPreferencesCopyAppValue(CFSTR("CCMDisableGrabber"), tweakID);
    disableGrabber = tempDisableGrabber ? [tempDisableGrabber boolValue] : YES;
    
    id tempRedesignMediaControls = (id)CFPreferencesCopyAppValue(CFSTR("CCMRedesignMediaControls"), tweakID);
    redesignMediaControls = tempRedesignMediaControls ? [tempRedesignMediaControls boolValue] : YES;
    
    id tempSwitcherPerPage = (id)CFPreferencesCopyAppValue(CFSTR("CCMSwitchesPerPage"), tweakID);
    switchesPerPage = tempSwitcherPerPage ? [tempSwitcherPerPage intValue] : 5;
    
    id tempDoubleTap = (id)CFPreferencesCopyAppValue(CFSTR("CCMDoubleTapEnabled"), tweakID);
    doubleTapEnabled = tempDoubleTap ? [tempDoubleTap boolValue] : YES;
    
    id tempSliderType = (id)CFPreferencesCopyAppValue(CFSTR("CCMDefaultSlider"), tweakID);
    sliderType = tempSliderType ? [tempSliderType intValue] : 0;
    
    id tempResetSlider = (id)CFPreferencesCopyAppValue(CFSTR("CCMResetSlider"), tweakID);
    resetSlider = tempResetSlider ? [tempResetSlider boolValue] : YES;
    
    id tempOpenOnFirstPage = (id)CFPreferencesCopyAppValue(CFSTR("CCMOpenOnFirstPage"), tweakID);
    openOnFirstPage = tempOpenOnFirstPage ? [tempOpenOnFirstPage boolValue] : YES;
    
    if (enabled && controlsView)
        [controlsView layoutSwitchView];
}

static void LoadToggles()
{
    if (enabledSwitches)
        [enabledSwitches release];
    
    NSDictionary *switchesSettings = [[NSDictionary alloc] initWithContentsOfFile:kSwitchesSettings];
    enabledSwitches = switchesSettings ? [[switchesSettings objectForKey:@"CCMEnabledSwitches"] copy] : [kDefaultEnabledSwitches copy];
    [switchesSettings release];
        
    if (enabled && controlsView)
        [controlsView reloadSwitchView];
}


static void SettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	LoadSettings();
}

static void TogglesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadToggles();
}


%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    LoadSettings();
    LoadToggles();
    
    if (enabled) {
        Class $AppSwitcherSliderController = kIsIOS8 ? %c(SBAppSwitcherController) : %c(SBAppSliderController);
        Class $PageController = kIsIOS8 ? %c(SBAppSwitcherPageViewController) : %c(SBAppSliderScrollingViewController);
        
        %init(CCRedesign, AppSwitcherSliderController=$AppSwitcherSliderController, PageController = $PageController);
        %init(CCMultitaskingGesture)
        %init(SwitcherGesture, PageController = $PageController)
        %init(SBUIControllerHelper)
    }
    
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, SettingsChanged, CFSTR("com.devDav.CCModifier/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, TogglesChanged, CFSTR("com.devDav.CCModifier/toggleschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    [pool drain];
}