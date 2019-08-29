//
//  DDLyricsView.m
//  
//
//  Created by David Klopp on 21.02.14.
//
//

#import "DDLyricsView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVAsset.h>


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define kMediaItemURLForID(trackID) [NSURL URLWithString:[NSString stringWithFormat:@"ipod-library://item/item.m4a?id=%@", trackID]]
#define kUniqueIdentifierKey @"uniqueIdentifier"

#define kiPhoneFontSize 12.0
#define kiPadFontSize 16.0



@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (NSDictionary *)_nowPlayingInfo;
@end

@interface DDLyricsView ()
@property (nonatomic, strong) UITextView *textView;
- (void)_updateLyrics;
@end


@implementation DDLyricsView
@synthesize textView = _textView;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.dynamic = FALSE;
        self.saturationDeltaFactor = 1.8;
        self.autoresizesSubviews = TRUE;
        self.layer.masksToBounds = TRUE;
        self.layer.cornerRadius = 10.0;
        self.tintColor = [UIColor whiteColor];
        
        
        self.textView = [[UITextView alloc] initWithFrame:self.bounds];
        _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _textView.showsVerticalScrollIndicator = TRUE;
        _textView.backgroundColor = [UIColor colorWithRed:237.0/255.0 green:237.0/255.0 blue:237.0/255.0 alpha:0.7];
        _textView.alpha = 1.0;
        _textView.textAlignment = NSTextAlignmentCenter;
        _textView.font = [UIFont systemFontOfSize: (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 16.0 : 12.0];
        _textView.textColor = [UIColor darkGrayColor];
        _textView.editable = FALSE;
        _textView.tag = 1;
        
        [self addSubview:_textView];
        
        [self _updateLyrics];
    }
    return self;
}

- (BOOL)lyricsAvailable
{
    return ![self.currentSongLyrics isEqualToString:@""];
}

- (NSString *)currentSongLyrics
{
    NSString* lyrics;
    NSURL* songURL;
    
    // shitty workaround on iOS 7.1 and up "valueForProperty:" crashes if music app is not open
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.1")) {
        NSDictionary *playingInfo = [[NSClassFromString(@"SBMediaController") sharedInstance] _nowPlayingInfo];
        NSString *songID = [playingInfo objectForKey:kUniqueIdentifierKey];
        songURL = kMediaItemURLForID(songID);
    } else {
        // Oh apple ....Puuhhh... use AVAsset because "MPMediaItemPropertyLyrics" not working always
        MPMusicPlayerController *player = [MPMusicPlayerController iPodMusicPlayer];
        MPMediaItem *mediaItem = [player nowPlayingItem];
        songURL = [mediaItem valueForProperty:MPMediaItemPropertyAssetURL];
    }
    
    //lyrics is sometimes nil on 7.1 and up altought it shouldn't
    AVAsset* songAsset = [AVURLAsset URLAssetWithURL:songURL options:nil];
    if (songAsset)
        lyrics = [songAsset lyrics];

    return lyrics ? lyrics : @"";
}

- (void)_updateLyrics
{
    self.textView.text = self.currentSongLyrics;
}

- (void)updateBlurAndLyrics
{
    // updates Text and Blur
    [self _updateLyrics];
    [self setNeedsDisplay];
}


- (void)dealloc
{
    self.textView = nil;
}
@end
