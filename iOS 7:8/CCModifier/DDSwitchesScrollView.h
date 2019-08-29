//
//  DDSwitchesScrollView.h
//  
//
//  Created by David Klopp on 06.04.14.
//
//

#import <UIKit/UIKit.h>

typedef enum {
    DDSwitchesLayoutVertical = 0,
    DDSwitchesLayoutHorizontal = 1
} DDSwitchesLayout;

@interface DDSwitchesScrollView : UIScrollView
@property(nonatomic, assign) DDSwitchesLayout switchesLayout;
@property(nonatomic, retain) NSBundle *switchesTemplateBundle;
@property(nonatomic, assign) int switchesPerPage;
@property(nonatomic, assign) BOOL openOnFirstPage;
@property(nonatomic, copy) NSArray *switchesIdentifiers;
- (void)reloadSwitches;
- (void)layoutSwitches;
@end
