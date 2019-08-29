//
//  DDLyricsView.h
//  
//
//  Created by David Klopp on 21.02.14.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "FXBlurView.h"

@interface DDLyricsView : FXBlurView
- (NSString *)currentSongLyrics;
- (void)updateBlurAndLyrics;
- (BOOL)lyricsAvailable;
@end
