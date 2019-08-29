#import "DDSystemMediaControlsViewController.h"
#import "CCModifier.h"
#import <objc/runtime.h>

@interface UISlider (_private_)
- (UIImageView *)_maxValueView;
- (UIImageView *)_minValueView;
- (UIImageView *)_maxTrackView;
- (UIImageView *)_minTrackView;
@end



%group DDSystemMediaControlsViewControllerGroup

static BOOL behavesAsBrightnessSlider = FALSE;
static BOOL isChangingBrightness = FALSE;
static BOOL firstLoad = TRUE;

BOOL doubleTapEnabled;
BOOL resetSlider;

// option 0: Volume Slider
// option 1: Brightness Slider
// option 2: Last One
int sliderType;

%subclass DDSystemMediaControlsViewController : MPUSystemMediaControlsViewController

- (void)loadView
{
    %orig;

    // get Images
    NSBundle *bundle = [[NSBundle alloc] initWithPath:kResourceBundlePath];
   
    NSString *maximumTrackImagePath = [bundle pathForResource:@"MaxmimumTrack@2x" ofType:@"png"];
    UIImage *maximumTrackImage = [[UIImage imageWithContentsOfFile:maximumTrackImagePath] stretchableImageWithLeftCapWidth:4 topCapHeight: 0];
        
    NSString *minimumTrackImagePath = [bundle pathForResource:@"MinimumTrack@2x" ofType:@"png"];
    UIImage *minimumTrackImage = [[UIImage imageWithContentsOfFile:minimumTrackImagePath] stretchableImageWithLeftCapWidth:4 topCapHeight: 0];
    
    NSString *volumeThumbImagePath = [bundle pathForResource:@"VolumeThumbImage@2x" ofType:@"png"];
    UIImage *volumeThumbImage = [UIImage imageWithContentsOfFile:volumeThumbImagePath];
    
    NSString *rightImagePath = [bundle pathForResource:@"VolumeIconRightImage@2x" ofType:@"png"];
    UIImage *rightImage = [UIImage imageWithContentsOfFile:rightImagePath];
    
    NSString *leftImagePath = [bundle pathForResource:@"VolumeIconLeftImage@2x" ofType:@"png"];
    UIImage *leftImage = [UIImage imageWithContentsOfFile:leftImagePath];
    
        
    // volume slider
    UISlider *volumeSlider = [[self dd_mediaControlsVolumeView] slider];
    
    // tap gesture
    object_setClass([self dd_mediaControlsVolumeView], objc_getClass("DDMediaControlsVolumeView"));
        
    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dd_volumeSliderTapped:)] autorelease];
    tapGestureRecognizer.numberOfTapsRequired = 2;
    [volumeSlider addGestureRecognizer:tapGestureRecognizer];
        
    // update slider value when brightness changes and slider does not show sound volume
    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenBrightnessDidChangeNotification object:[UIScreen mainScreen] queue:nil usingBlock:^(NSNotification *notification)
    {
            if (behavesAsBrightnessSlider && !isChangingBrightness)
                [self dd_volumeBrightnessSliderUpdateValueWithAnimation:TRUE];
    }];
    
    if (redesignMediaControls)
    {
        // set track images
        [volumeSlider setMinimumTrackImage:minimumTrackImage forState:UIControlStateNormal];
        [volumeSlider setMaximumTrackImage:maximumTrackImage forState:UIControlStateNormal];
        [volumeSlider setThumbImage:volumeThumbImage forState:UIControlStateNormal];
        [volumeSlider bringSubviewToFront:MSHookIvar<UIImageView *>(volumeSlider, "_thumbView")]; // fix thumb not in front of slider
        
        // progress slider
        object_setClass([self dd_chronologicalProgressView], objc_getClass("DDChronologicalProgressView"));
        
        UISlider *progressSlider = MSHookIvar<UISlider *>([self dd_chronologicalProgressView], "_slider");
        [progressSlider setMinimumTrackImage:minimumTrackImage forState:UIControlStateNormal];
        [progressSlider setMaximumTrackImage:maximumTrackImage forState:UIControlStateNormal];
        
        // fix alpha
        progressSlider._minTrackView.alpha = 1.0;
        progressSlider._maxTrackView.alpha = 1.0;
    }
    
    // set speaker images
    volumeSlider.maximumValueImage = rightImage;
    volumeSlider.minimumValueImage = leftImage;
    
    
    
    [bundle release];
}

%new(v@:)
- (void)dd_willShow
{
    // update slider
    BOOL newBehavesAsBrightnessSlider = (sliderType == 1);
    if ( (behavesAsBrightnessSlider != newBehavesAsBrightnessSlider && resetSlider) || firstLoad ) {
        behavesAsBrightnessSlider = newBehavesAsBrightnessSlider;
        [self dd_updateVolumeBrightnessSlider];
        
        if (firstLoad)
            firstLoad = FALSE;
    }
    
    if (behavesAsBrightnessSlider)
        [self dd_volumeBrightnessSliderUpdateValueWithAnimation:FALSE];
}


%new(v@:)
- (void)dd_volumeBrightnessSliderUpdateValueWithAnimation:(BOOL)animated
{
    float sliderValue = behavesAsBrightnessSlider ? [(SpringBoard *)[UIApplication sharedApplication] backlightLevel] : [[%c(SBMediaController) sharedInstance] volume];
    UISlider *volumeSlider = [[self dd_mediaControlsVolumeView] slider];
    
    [UIView animateWithDuration:0.25 animations:^{
        [volumeSlider setValue:sliderValue animated:animated];
    }];
}

%new(v@:)
- (void)dd_updateVolumeBrightnessSlider
{
    UISlider *slider = [[self dd_mediaControlsVolumeView] slider];
    
    NSBundle *bundle = [[[NSBundle alloc] initWithPath:kResourceBundlePath] autorelease ];
    // get Images
    NSString *rightImagePath = [bundle pathForResource:!behavesAsBrightnessSlider ? @"VolumeIconRightImage@2x" : @"BrightnessIconRightImage@2x" ofType:@"png"];
    UIImage *rightImage = [UIImage imageWithContentsOfFile:rightImagePath];
    
    NSString *leftImagePath = [bundle pathForResource:!behavesAsBrightnessSlider ?  @"VolumeIconLeftImage@2x" : @"BrightnessIconLeftImage@2x" ofType:@"png"];
    UIImage *leftImage = [UIImage imageWithContentsOfFile:leftImagePath];
    
    // set Images
    slider.maximumValueImage = rightImage;
    slider.minimumValueImage = leftImage;
    
    // update slider value
    [self dd_volumeBrightnessSliderUpdateValueWithAnimation:TRUE];
}

%new(v@:@)
- (void)dd_volumeSliderTapped:(UITapGestureRecognizer *)recognizer
{
    if (doubleTapEnabled) {
        behavesAsBrightnessSlider = !behavesAsBrightnessSlider;
        [self dd_updateVolumeBrightnessSlider];
    }
}

%new(@@:)
- (_MPUSystemMediaControlsView *)dd_systemMediaControlsView
{
    return MSHookIvar<_MPUSystemMediaControlsView *>(self, "_mediaControlsView");
}

%new(@@:)
- (MPUMediaControlsVolumeView *)dd_mediaControlsVolumeView
{
    return [[self dd_systemMediaControlsView] volumeView];
}

%new(@@:)
- (MPUChronologicalProgressView *)dd_chronologicalProgressView
{
    return [[self dd_systemMediaControlsView] timeInformationView];
}

%new(v@:f)
- (void)dd_setSlidersAlpha:(CGFloat)alpha
{
    [self dd_chronologicalProgressView].alpha = alpha;
    [self dd_mediaControlsVolumeView].alpha = alpha;
}
%end


%subclass DDChronologicalProgressView : MPUChronologicalProgressView

- (id)_thumbImage
{
    // only way to change the image and the thumbrect
    if (self.totalDuration == 0.0)
        return %orig;
    
    NSBundle *bundle = [NSBundle bundleWithPath:kResourceBundlePath];
    NSString *progressThumbImagePath = [bundle pathForResource:self.scrubbingEnabled ? @"ProgressSliderThumb@2x" : @"ProgressSliderThumbSmall@2x" ofType:@"png"];
    return [UIImage imageWithContentsOfFile:progressThumbImagePath];
}
%end


%subclass DDMediaControlsVolumeView : MPUMediaControlsVolumeView

// disable volume slider functions
- (BOOL)_shouldStartBlinkingVolumeWarningIndicator { return behavesAsBrightnessSlider ? FALSE : %orig; };

- (void)volumeController:(id)arg1 EUVolumeLimitDidChange:(float)arg2 { if (!behavesAsBrightnessSlider) %orig; }

- (void)volumeController:(id)arg1 EUVolumeLimitEnforcedDidChange:(BOOL)arg2 { if (!behavesAsBrightnessSlider) %orig; }

- (void)volumeController:(id)arg1 volumeValueDidChange:(float)arg2 { if (!behavesAsBrightnessSlider) %orig; }

- (void)volumeController:(id)arg1 volumeWarningStateDidChange:(int)arg2 { if (!behavesAsBrightnessSlider) %orig; }

- (void)_volumeSliderBeganChanging:(id)arg1
{
    if (!behavesAsBrightnessSlider)
        %orig;
    else
        isChangingBrightness = TRUE;
}

- (void)_volumeSliderStoppedChanging:(id)arg1
{
    if (!behavesAsBrightnessSlider)
        %orig;
    else
        isChangingBrightness = FALSE;
}


// enabled brightness change
- (void)_volumeSliderValueChanged:(UISlider *)slider
{
    if (behavesAsBrightnessSlider)
    {
        SBBrightnessController *brightnessController = [%c(SBBrightnessController) sharedBrightnessController];
        [brightnessController _setBrightnessLevel:slider.value showHUD:FALSE];
    } else {
        %orig;
    }
}

%end

%end


%ctor {
    // ExtensionLoader plugin might load the same class
    if (!NSClassFromString(@"DDSystemMediaControlsViewController"))
        %init(DDSystemMediaControlsViewControllerGroup)
}