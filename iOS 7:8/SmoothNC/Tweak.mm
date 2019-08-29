#include <substrate.h>
#import <UIKit/UIKit.h>


@interface SBModeViewController : UIViewController <UIGestureRecognizerDelegate> {
    UIScrollView *_contentView;
    UISwipeGestureRecognizer *_leftSwipeGestureRecognizer;
    UISwipeGestureRecognizer *_rightSwipeGestureRecognizer;
}
@property(retain, nonatomic) NSArray *viewControllers;
- (void)_loadContentView;
- (void)setSelectedViewController:(id)arg1 animated:(_Bool)arg2;
- (void)handleModeChange:(id)arg1;

- (void)dd_setSmoothScrollingEnabled:(BOOL)enabled;
- (UIPanGestureRecognizer *)dd_panGestureRecognizer;
- (void)dd_setPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer;
- (void)dd_handlePan:(UIPanGestureRecognizer *)recognizer;
@end

@interface SBNotificationCenterViewController : UIViewController {
    SBModeViewController *_modeController;
}
@end

@interface SBNotificationCenterController : NSObject
+ (id)sharedInstanceIfExists;
@property(readonly, nonatomic) SBNotificationCenterViewController *viewController;
@end


#define kPreferencePath @"/var/mobile/Library/Preferences/com.devDav.SmoothNC.plist"
#define kAnimationDuration 0.25
#define kSwipeVelocityXThreshold 500

static BOOL useSmoothScrolling;

static CGPoint startOffset;
static BOOL settingsChanged = TRUE;


%hook SBModeViewController

- (void)_loadContentView
{
    %orig;
    
    UIScrollView *contentView = MSHookIvar<UIScrollView *>(self, "_contentView");
    UIPanGestureRecognizer *recognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dd_handlePan:)] autorelease];
    recognizer.delegate = self;
    recognizer.cancelsTouchesInView = NO;
    recognizer.minimumNumberOfTouches = 1;
    recognizer.maximumNumberOfTouches = 1;
    [contentView addGestureRecognizer:recognizer];
    
    [self dd_setPanGestureRecognizer:recognizer];
}

%new(B@:@@)
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // dont't cancel touches in UISlider
    return ![touch.view isKindOfClass:[UISlider class]];
}

- (void)viewWillAppear:(BOOL)appear
{
    %orig;
    
    if (settingsChanged)
        [self dd_setSmoothScrollingEnabled:useSmoothScrolling];
    
    settingsChanged = FALSE;
}

%new(v@:@)
- (void)dd_setPanGestureRecognizer:(UIPanGestureRecognizer *)recognizer {
    objc_setAssociatedObject(self, @selector(dd_panGestureRecognizer), recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%new(@@:)
- (UIPanGestureRecognizer *)dd_panGestureRecognizer {
    return objc_getAssociatedObject(self, @selector(dd_panGestureRecognizer));
}

%new(v@:B)
- (void)dd_setSmoothScrollingEnabled:(BOOL)enabled
{
    [self dd_panGestureRecognizer].enabled = enabled;
    MSHookIvar<UISwipeGestureRecognizer *>(self, "_leftSwipeGestureRecognizer").enabled = !enabled;
    MSHookIvar<UISwipeGestureRecognizer *>(self, "_rightSwipeGestureRecognizer").enabled = !enabled;
}

%new(v@:@)
- (void)dd_handlePan:(UIPanGestureRecognizer *)recognizer
{
    UIScrollView *contentView = (UIScrollView *)recognizer.view;
    UIGestureRecognizerState state = recognizer.state;
    
    if (state == UIGestureRecognizerStateBegan) {
        startOffset = contentView.contentOffset;
        recognizer.cancelsTouchesInView = YES;
    }
    else if (state == UIGestureRecognizerStateChanged) {
        // more natural scrolling on first and last page
        CGFloat frameWidth = contentView.frame.size.width; //320 (screen width) *pages
        CGFloat contentWidth = contentView.contentSize.width; //320 (screen width)
        CGFloat lastPageOffset = (frameWidth-contentWidth);
        
        CGPoint translation = [recognizer translationInView:contentView];
        CGFloat xOffset = startOffset.x-translation.x;
        
        if (xOffset < 0)
            xOffset /= 3;
        else if (xOffset > lastPageOffset)
            xOffset = lastPageOffset-(translation.x/3);
        
        contentView.contentOffset = CGPointMake(xOffset, startOffset.y);
    } else {
        CGFloat absolutXOffset = contentView.contentOffset.x;
        CGFloat contentWidth = contentView.contentSize.width; //320 (screen width)
        CGFloat frameWidth = contentView.frame.size.width; //320 (screen width) *pages
        CGFloat relativXOffset = fmodf(absolutXOffset, contentWidth);
        
        CGFloat maxOffset = frameWidth-contentWidth;
        CGFloat minOffset = 0;
        CGFloat xVelocity = [recognizer velocityInView:self.view].x;
        int normalizedOffset;
        
        //simulate paging
        if (ABS(xVelocity) > kSwipeVelocityXThreshold) // swipe
            normalizedOffset = (xVelocity > 0) ? (absolutXOffset-relativXOffset) : (absolutXOffset-relativXOffset+contentWidth);
        else // pan
            normalizedOffset = (relativXOffset > contentWidth/2) ? (absolutXOffset-relativXOffset+contentWidth) : (absolutXOffset-relativXOffset);
        
        // correct value for swipe on last or first page
        if (normalizedOffset > maxOffset)
            normalizedOffset = maxOffset;
        else if (normalizedOffset < minOffset)
            normalizedOffset = minOffset;
            
        int indexToSelect = normalizedOffset/contentWidth;
        
        [UIView animateWithDuration:kAnimationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [contentView setContentOffset:CGPointMake(normalizedOffset, contentView.contentOffset.y) animated:FALSE];
        } completion:^(BOOL finished){
            [self setSelectedViewController:self.viewControllers[indexToSelect] animated:FALSE];
            recognizer.cancelsTouchesInView = NO;
        }];
    }
}
%end


static void LoadSettings()
{
    CFStringRef tweakID = CFSTR("com.devDav.SmoothNC");
    CFPreferencesAppSynchronize(tweakID);
    
    id tempEnabled = (id)CFPreferencesCopyAppValue(CFSTR("SNCEnabled"), tweakID);
    useSmoothScrolling = tempEnabled ? [tempEnabled boolValue] : YES;
}

static void SettingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    settingsChanged = TRUE;
	LoadSettings();
}

%ctor
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init();
    
    if (!class_conformsToProtocol(%c(SBModeViewController), @protocol(UIGestureRecognizerDelegate)))
        class_addProtocol(%c(SBModeViewController), @protocol(UIGestureRecognizerDelegate));
    
    LoadSettings();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, SettingsChanged, CFSTR("com.devDav.SmoothNC/settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    [pool drain];
}