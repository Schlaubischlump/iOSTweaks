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
- (id)_nowPlayingInfo;
@property BOOL suppressHUD;
@end



@protocol MPUSystemMediaControlsDelegate <NSObject>
@optional
- (void)systemMediaControlsViewController:(id)mediaController didTapOnTrackInformationView:(id)trackView;
- (void)systemMediaControlsViewController:(id)mediaController didReceiveTapOnControlType:(int)type;
@end

@interface MPUSystemMediaControlsViewController : UIViewController
@property(readonly, nonatomic) UIImageView *artworkView;
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
@property (nonatomic, strong) MPUSystemMediaControlsViewController *mediaControlsView;
@property (nonatomic, strong) DDLyricsView *lyricsView;
@property (nonatomic, strong) UIImageView *artworkView;

@end

@interface NCMediaControllerPlugin_view ()
- (void)_layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (void)showLyricsView;
@end


@implementation NCMediaControllerPlugin_view
@synthesize mediaControlsView = _mediaControlsView;
@synthesize lyricsView = _lyricsView;
@synthesize artworkView = _artworkView;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {        
        mediaController = [objc_getClass("SBMediaController") sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingInfoChanged) name:@"SBMediaNowPlayingChangedNotification" object:nil];
        
        self.mediaControlsView = [[objc_getClass("MPUSystemMediaControlsViewController") alloc] initWithStyle:MPUSystemMediaControlsStyleLockscreen];
        // _mediaControlsView.delegate = self;
        
        self.lyricsView = [[DDLyricsView alloc] initWithFrame:CGRectZero];
        _lyricsView.alpha = 0.0;
        _lyricsView.hidden = YES;

        
        self.artworkView = [[UIImageView alloc] init];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLyricsView)];
        tapGesture.numberOfTapsRequired = 1;
        [_artworkView addGestureRecognizer:tapGesture];
        
        
        [_artworkView addSubview:_lyricsView];
        [self addSubview:_mediaControlsView.view];
        [self addSubview:_artworkView];
        
        _artworkView.userInteractionEnabled = YES;
    }
    return self;
}

- (void)dealloc
{
    self.mediaControlsView = nil;
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
        _artworkView.frame = CGRectMake(artworkViewMarginLeft, artworkViewMargin, artworkViewSize, artworkViewSize);
        _mediaControlsView.view.frame = CGRectMake(0, height/2, width, height/2);
    } else {
        CGFloat artworkViewSize = height-(artworkViewMargin*2);
        _artworkView.frame = CGRectMake(artworkViewMargin, artworkViewMargin, artworkViewSize, artworkViewSize);
        CGFloat controlsXOffset = artworkViewMargin*2+artworkViewSize;
        _mediaControlsView.view.frame = CGRectMake(controlsXOffset, artworkViewMargin, width-controlsXOffset, height);
    }
    
    _lyricsView.frame = _artworkView.bounds;
}


- (void)nowPlayingInfoChanged
{
    HBLogDebug(@"changed");
    
    // update artwork
    MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];
    MPMediaItem *mediaItem = [player nowPlayingItem];
    MPMediaItemArtwork *artwork = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
    
    UIImageView *artworkView = _artworkView;
    artworkView.image = [artwork imageWithSize:artworkView.frame.size];
    
    
    if (!_lyricsView.hidden) {
        // update blur
        _lyricsView.hidden = !(_lyricsView.lyricsAvailable);
        [_lyricsView updateBlurAndLyrics]; // only works if view is visible
    }
}


- (void)showLyricsView
{
    BOOL newHidden = !_lyricsView.hidden;
    
    if (_lyricsView.lyricsAvailable) {
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
    mediaController.suppressHUD = YES;
    
    // update artwork
    MPMusicPlayerController *player = [MPMusicPlayerController systemMusicPlayer];
    MPMediaItem *mediaItem = [player nowPlayingItem];
    MPMediaItemArtwork *artwork = [mediaItem valueForProperty:MPMediaItemPropertyArtwork];
    
    UIImageView *artworkView = _artworkView;
    artworkView.image = [artwork imageWithSize:artworkView.frame.size];
    
    _artworkView.hidden = false;
}

- (void)viewWillAppear {
    // this should not be needed ... but it's necassaray >.<
    if (!_lyricsView.hidden)
        [_lyricsView updateBlurAndLyrics];
    
    [_mediaControlsView viewWillAppear:YES];
}

- (void)viewDidAppear {
    [_mediaControlsView viewDidAppear:YES];
}

- (void)viewEntersBackground {
    mediaController.suppressHUD = NO;
}

- (void)viewWillDisappear {
    [_mediaControlsView viewWillDisappear:YES];
}

- (void)viewDidDisappear {
    [_mediaControlsView viewDidDisappear:YES];
}


/* //delegate
- (void)systemMediaControlsViewController:(id)mediaController didTapOnTrackInformationView:(id)trackView {} //disabled for lockscreen style
- (void)systemMediaControlsViewController:(id)mediaController didReceiveTapOnControlType:(int)type {}
 */
@end