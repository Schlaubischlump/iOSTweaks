//
//  DDLyricsView.m
//
//
//  Created by David Klopp on 21.02.14.
//
// This project uses ARC


#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "DDLyricsView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SpringBoard : UIApplication
- (UIInterfaceOrientation)_frontMostAppOrientation;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL)trackIsBeingPlayedByMusicApp;
- (id)_nowPlayingInfo;
@property BOOL suppressHUD;
@end



@protocol MPUSystemMediaControlsDelegate <NSObject>
@optional
- (void)systemMediaControlsViewController:(id)mediaController didTapOnTrackInformationView:(id)trackView;
- (void)systemMediaControlsViewController:(id)mediaController didReceiveTapOnControlType:(int)type;
@end

@interface MPUSystemMediaControlsViewController : UIViewController
@property(readonly, nonatomic) UIView *artworkView;
@property (nonatomic, assign) id<MPUSystemMediaControlsDelegate> delegate;
@end


// found by try and error
typedef enum : NSInteger {
    MPUSystemMediaControlsStyleUnknownWhite = 3,
    MPUSystemMediaControlsStyleLockscreen = 2,
    MPUSystemMediaControlsStyleControlCenter = 1,
    MPUSystemMediaControlsStyleUnknownBlack = 0,
} MPUSystemMediaControlsStyle;





@interface NCMediaControllerPlugin_view : UIView <MPUSystemMediaControlsDelegate>
{
    SBMediaController *mediaController;
}
@property (nonatomic, strong) MPUSystemMediaControlsViewController *mediaController;
@property (nonatomic, strong) DDLyricsView *lyricsView;

@end

@interface NCMediaControllerPlugin_view ()
- (void)_layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)showLyricsView;
@end


@implementation NCMediaControllerPlugin_view
@synthesize mediaController = _mediaController;
@synthesize lyricsView = _lyricsView;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {        
        mediaController = [objc_getClass("SBMediaController") sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingInfoChanged) name:@"SBMediaNowPlayingChangedNotification" object:nil];
        
        self.mediaController = [[objc_getClass("MPUSystemMediaControlsViewController") alloc] initWithStyle:MPUSystemMediaControlsStyleLockscreen];
        // _mediaController.delegate = self;
        
        self.lyricsView = [[DDLyricsView alloc] initWithFrame:CGRectZero];
        _lyricsView.alpha = 0.0;
        _lyricsView.hidden = TRUE;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLyricsView)];
        tapGesture.numberOfTapsRequired = 1;
        [_mediaController.artworkView addGestureRecognizer:tapGesture];
        
        [_mediaController.artworkView addSubview:_lyricsView];
        [self addSubview:_mediaController.view];
        [self addSubview:_mediaController.artworkView];
        
        _mediaController.artworkView.userInteractionEnabled = YES;
    }
    return self;
}

- (void)dealloc
{
    self.mediaController = nil;
    self.lyricsView = nil;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // autoresizing is broken because of apples implementation (SBSizeObservingView) :/
    UIInterfaceOrientation orientation = [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] _frontMostAppOrientation];
    [self _layoutSubviewsForInterfaceOrientation:orientation];
}

- (void)_layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    CGFloat height = self.bounds.size.height;
    CGFloat width = self.bounds.size.width;
    CGFloat artworkViewMargin = 15;
    
    if (UIInterfaceOrientationIsPortrait(orientation)) {
        CGFloat artworkViewSize = height/2-(artworkViewMargin*2);
        CGFloat artworkViewMarginLeft = (width-artworkViewSize)/2;
        _mediaController.artworkView.frame = CGRectMake(artworkViewMarginLeft, artworkViewMargin, artworkViewSize, artworkViewSize);
        _mediaController.view.frame = CGRectMake(0, height/2, width, height/2);
    } else {
        CGFloat artworkViewSize = height-(artworkViewMargin*2);
        _mediaController.artworkView.frame = CGRectMake(artworkViewMargin, artworkViewMargin, artworkViewSize, artworkViewSize);
        CGFloat controlsXOffset = artworkViewMargin*2+artworkViewSize;
        _mediaController.view.frame = CGRectMake(controlsXOffset, artworkViewMargin, width-controlsXOffset, height);
    }
    
    CGFloat lyricsViewMargin = 15;
    CGSize artworkViewSize = _mediaController.artworkView.bounds.size;
    _lyricsView.frame = CGRectMake(lyricsViewMargin, lyricsViewMargin, artworkViewSize.width-(lyricsViewMargin*2), artworkViewSize.height-(lyricsViewMargin*2));
}


- (void)nowPlayingInfoChanged
{
    if (!_lyricsView.hidden) {
        _lyricsView.hidden = !(_lyricsView.lyricsAvailable && mediaController.trackIsBeingPlayedByMusicApp);
        [_lyricsView updateBlurAndLyrics]; // only works if view is visible
    }
}


- (void)showLyricsView
{
    BOOL newHidden = !_lyricsView.hidden;
    
    if (_lyricsView.lyricsAvailable && mediaController.trackIsBeingPlayedByMusicApp) {
        if (!newHidden) {
            _lyricsView.alpha = 0.0;
            _lyricsView.hidden = newHidden;
        }
        
        [UIView animateWithDuration:0.3 animations:^{
                             _lyricsView.alpha = !newHidden ? 1.0 : 0.0;
                         } completion:^(BOOL finished){
                             if (!newHidden)
                                 [_lyricsView updateBlurAndLyrics];
                             else
                                 _lyricsView.hidden = newHidden;
                         }];
    }
}


- (void)viewEntersForeground {
    mediaController.suppressHUD = TRUE;
}

- (void)viewWillAppear {
    // this should not be needed ... but it's necassaray >.<
    if (!_lyricsView.hidden)
        [_lyricsView updateBlurAndLyrics];
    
    [_mediaController viewWillAppear:TRUE];
}

- (void)viewDidAppear {
    [_mediaController viewDidAppear:TRUE];
}

- (void)viewEntersBackground {
    mediaController.suppressHUD = FALSE;
}

- (void)viewWillDisappear {
    [_mediaController viewWillDisappear:TRUE];
}

- (void)viewDidDisappear {
    [_mediaController viewDidDisappear:TRUE];
}


/* //delegate
- (void)systemMediaControlsViewController:(id)mediaController didTapOnTrackInformationView:(id)trackView {} //disabled for lockscreen style
- (void)systemMediaControlsViewController:(id)mediaController didReceiveTapOnControlType:(int)type {}
 */
@end