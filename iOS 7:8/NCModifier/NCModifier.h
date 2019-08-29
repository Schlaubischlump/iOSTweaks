#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>

@interface SBModeViewController : UIViewController
@property(retain, nonatomic) NSArray *viewControllers;
- (void)setSelectedViewController:(id)controller animated:(BOOL)animated;
@end

@interface SBNotificationCenterViewController : UIViewController
- (CGRect)_containerFrame;
@end

@interface SBNotificationCenterController : NSObject
@end

@interface SBNotificationCenterSeparatorView : UIView
@end

@interface SBNotificationSeparatorView : UIView
@end

@interface _SBFVibrantTableViewHeaderFooterView : UITableViewHeaderFooterView
@end

@interface SBNotificationsSectionHeaderView  : _SBFVibrantTableViewHeaderFooterView
@end

@interface SBNotificationCenterHeaderView : _SBFVibrantTableViewHeaderFooterView
@end

@interface _UIReplicantView : UIView
+ (_UIReplicantView *)snapshotWindows:(NSArray *)windows withRect:(CGRect)rect;
@end

@interface UIView (_snapshot_)
- (_UIReplicantView *)snapshot;
- (_UIReplicantView *)snapshotViewAfterScreenUpdates:(BOOL)updates; //documented
@end

@interface UIScreen (_snapshot_)
//- (_UIReplicantView *)snapshot;
- (_UIReplicantView *)snapshotViewAfterScreenUpdates:(BOOL)updates; //documented
- (_UIReplicantView *)_snapshotExcludingWindows:(NSArray *)windows withRect:(CGRect)rect; // undocumented
@end


// live updates
@interface SBAlert : UIViewController
- (int)statusBarStyle;
@end

@interface SBLockScreenViewControllerBase : SBAlert
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
@property(readonly, nonatomic) SBLockScreenViewControllerBase *lockScreenViewController; //returns SBLockScreenViewController not SBLockScreenViewControllerBase
@end

@interface UIApplication (_private_)
- (UIWindow *)statusBarWindow;
@end


@interface SBBulletinWindowController : NSObject
+ (id)sharedInstance;
@property(readonly, nonatomic) UIWindow *window;
@end

@interface SBUserAgent : NSObject
+ (id)sharedUserAgent;
- (BOOL)deviceIsLocked;
@end

@interface UIStatusBar : UIView
@property(nonatomic) BOOL simulatesLegacyAppearance;
- (void)requestStyle:(int)arg1;
- (id)initWithFrame:(CGRect)frame showForegroundView:(BOOL)show;
@end

typedef struct {
	int startStyle;
	int endStyle;
	CGFloat transitionFraction;
} SCD_Struct_SB29;

@interface SBWallpaperEffectView : UIView
@end

@interface SBWallpaperController : NSObject
+ (id)sharedInstance;
- (UIWindow *)_window;
- (SBWallpaperEffectView *)_newWallpaperEffectViewForVariant:(int)variant transitionState:(SCD_Struct_SB29)arg2;
@end


@interface SBDefaultImageInfo : NSObject
@property(retain, nonatomic) UIImage *image;
@end

@interface SBApplication : NSObject
- (int)wallpaperStyle;
- (NSString *)mainSceneID; // iOS 8
- (void)_saveSnapshotForScreen:(UIScreen *)screen frame:(CGRect)rect name:(NSString *)name overrideScale:(CGFloat)scale; // iOS 7
- (void)saveSnapshotForSceneID:(NSString *)sceneID frame:(CGRect)rect name:(NSString *)name overrideScale:(CGFloat)scale; // iOS 8
- (SBDefaultImageInfo *)_snapshotImageInfoForSceneID:(NSString *)sceneID named:(NSString *)name size:(CGSize)size scale:(CGFloat)scale downscaled:(BOOL)downscaled launchingOrientation:(UIInterfaceOrientation)orientation; // iOS 8
- (SBDefaultImageInfo *)_snapshotImageInfoForScreen:(UIScreen *)screen named:(NSString *)name downscaled:(BOOL)downscaled launchingOrientation:(UIInterfaceOrientation)orientation; // iOS 7.1.x
- (SBDefaultImageInfo *)_snapshotImageInfoForScreen:(UIScreen *)screen named:(NSString *)name launchingOrientation:(UIInterfaceOrientation)orientation; // 7.0.x
- (BOOL)statusBarHidden; // not accurate in safari landscape // iOS 7
- (BOOL)statusBarHiddenForCurrentOrientation; // iOS 8
//- (long long)statusBarStyle;
- (long long)effectiveStatusBarStyle;
@end

@interface SpringBoard : UIApplication
- (BOOL)isSpringBoardStatusBarHidden;
- (int)currentHomescreenStatusBarStyle;
- (UIWindow *)_keyWindowForScreen:(UIScreen *)screen;
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (UIInterfaceOrientation)_frontMostAppOrientation;
- (SBApplication *)_accessibilityFrontMostApplication;
@end