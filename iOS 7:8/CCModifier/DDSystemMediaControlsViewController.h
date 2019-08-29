typedef enum : NSInteger {
    MPUSystemMediaControlsStyleUnknownWhite = 3,
    MPUSystemMediaControlsStyleLockscreen = 2,
    MPUSystemMediaControlsStyleControlCenter = 1,
    MPUSystemMediaControlsStyleUnknownBlack = 0,
} MPUSystemMediaControlsStyle;


@interface MPUChronologicalProgressView : UIView {
    UISlider* _slider;
}
@property(nonatomic) BOOL scrubbingEnabled;
@property(nonatomic) CGFloat currentTime;
@property(nonatomic) CGFloat totalDuration;
@end

@interface MPUMediaControlsVolumeSlider : UISlider
@end

@interface MPUMediaControlsVolumeView : UIView
@property(readonly) MPUMediaControlsVolumeSlider * slider;
@end

@interface _MPUSystemMediaControlsView : UIView
@property(retain, nonatomic) MPUMediaControlsVolumeView *volumeView;
@property(retain) MPUChronologicalProgressView* timeInformationView;
@end

@interface MPUSystemMediaControlsViewController : UIViewController
- (id)initWithStyle:(int)style;
@end

@interface DDChronologicalProgressView : MPUChronologicalProgressView
@end

@interface DDSystemMediaControlsViewController : MPUSystemMediaControlsViewController
- (_MPUSystemMediaControlsView *)dd_systemMediaControlsView;
- (MPUMediaControlsVolumeView *)dd_mediaControlsVolumeView;
- (MPUChronologicalProgressView *)dd_chronologicalProgressView;
- (void)dd_setSlidersAlpha:(CGFloat)alpha;
- (void)dd_volumeBrightnessSliderUpdateValueWithAnimation:(BOOL)animated;
- (void)dd_updateVolumeBrightnessSlider;
- (void)dd_volumeSliderTapped:(UITapGestureRecognizer *)recognizer;

- (void)dd_willShow; // called when switcher activates
@end

@interface DDMediaControlsVolumeView : MPUMediaControlsVolumeView
@end


@interface SBBrightnessController : NSObject
+ (id)sharedBrightnessController;
- (void)setBrightnessLevel:(float)level;
- (void)_setBrightnessLevel:(float)level showHUD:(BOOL)arg2;
@end