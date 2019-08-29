//
//  DDSwitchesScrollView.m
//  
//
//  Created by David Klopp on 06.04.14.
//
//

#import "DDSwitchesScrollView.h"
#import "flipswitch/Flipswitch.h"

@interface DDSwitchesScrollView ()
- (void)_setup;
- (UILabel *)_newNoSwitchesLabel;
@property(nonatomic, assign) BOOL resetOpenPage;
@end


@implementation DDSwitchesScrollView
@synthesize switchesLayout = _switchesLayout;
@synthesize switchesTemplateBundle = _switchesTemplateBundle;
@synthesize switchesIdentifiers = _switchesIdentifiers;
@synthesize switchesPerPage = _switchesPerPage;
@synthesize resetOpenPage = _resetOpenPage;
@synthesize openOnFirstPage = _openOnFirstPage;

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
        [self _setup];
    return self;
}

- (id)init
{
    if (self = [super init])
        [self _setup];
    return self;
}

- (void)_setup
{
    self.bounces = TRUE;
    self.showsHorizontalScrollIndicator = FALSE;
    self.showsVerticalScrollIndicator = FALSE;
    self.pagingEnabled = TRUE;
    self.autoresizesSubviews = FALSE;
    //self.translatesAutoresizingMaskIntoConstraints = FALSE;
    
    self.openOnFirstPage = FALSE;
    self.switchesLayout = DDSwitchesLayoutHorizontal;
    self.switchesPerPage = 0;
    self.resetOpenPage = FALSE;
    
    [self reloadSwitches];
}

- (void)setSwitchesPerPage:(int)switchesPerPage
{
    _switchesPerPage = switchesPerPage;
    self.resetOpenPage = TRUE;
    
    [self layoutSwitches];
}

- (CGRect)switchBounds
{
    CGFloat size = (_switchesLayout == DDSwitchesLayoutHorizontal) ? self.frame.size.height : self.frame.size.width;
    return CGRectMake(0,0,size, size);
}

- (void)setSwitchesLayout:(DDSwitchesLayout)_layout
{
    _switchesLayout = _layout;
    
    // will break openOnFirstPage = FALSE because it changes contentSize before layoutSwitches is called
    /*if (_layout == DDSwitchesLayoutHorizontal)
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    else
        self.autoresizingMask = UIViewAutoresizingFlexibleHeight;*/
    
    [self layoutSwitches];
}

- (void)setSwitchesIdentifiers:(NSArray *)identifiers
{
    if (_switchesIdentifiers)
        [_switchesIdentifiers release];
    _switchesIdentifiers = [identifiers copy];
    
    [self reloadSwitches];
}

- (UILabel *)_newNoSwitchesLabel
{
    UILabel *noSwitchesLabel = [[UILabel alloc ] initWithFrame:self.bounds];
    noSwitchesLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    noSwitchesLabel.textAlignment =  NSTextAlignmentCenter;
    noSwitchesLabel.textColor = [UIColor lightGrayColor];
    noSwitchesLabel.backgroundColor = [UIColor clearColor];
    noSwitchesLabel.font = [UIFont boldSystemFontOfSize:16.0];
    noSwitchesLabel.text = @"Activate Switches from Settings app";
    return [noSwitchesLabel autorelease];
}

- (void)layoutSwitches
{
    CGRect defaultSwitchFrame = [self switchBounds];
    BOOL horizontal = (_switchesLayout == DDSwitchesLayoutHorizontal);
    
    CGFloat toggleWidth = horizontal ? defaultSwitchFrame.size.width : defaultSwitchFrame.size.height;
    CGFloat viewWidth = horizontal ? self.frame.size.width :  self.frame.size.height;
    
    CGFloat minDynamicSpacing = 10.0;
    int maxSwitchesPerPage = floor((viewWidth-minDynamicSpacing)/toggleWidth);
    int tmpSwitchesPerPage = _switchesPerPage;
    if (_switchesPerPage == 0 || _switchesPerPage > maxSwitchesPerPage)
        tmpSwitchesPerPage = maxSwitchesPerPage;

    CGFloat freeSpace = (viewWidth-(tmpSwitchesPerPage*toggleWidth));
    CGFloat dynamicSpacing = freeSpace/(tmpSwitchesPerPage+1);
    
    int count = 0;
    int pageCount = 0;
    for (UIView *toggle in self.subviews) {
        if ([toggle isKindOfClass:[UIButton class]]) {
            if (count == tmpSwitchesPerPage) {
                pageCount ++;
                count = 0;
            }
            
            CGFloat startOffset = dynamicSpacing + (viewWidth*pageCount);
            CGFloat offset = (count == 0) ? startOffset : (startOffset + count*(toggleWidth+dynamicSpacing));
            if (horizontal)
                defaultSwitchFrame.origin.x = offset;
            else
                defaultSwitchFrame.origin.y = offset;
            
            toggle.frame = defaultSwitchFrame;
            
            count++;
        }
    }
    if (count != 0 || (pageCount == 0 && count == 0))
        pageCount ++;
    
    self.contentSize = horizontal ? CGSizeMake(pageCount*viewWidth, toggleWidth) : CGSizeMake(toggleWidth, pageCount*viewWidth);
    
    if (self.resetOpenPage || self.openOnFirstPage || viewWidth == 0)
        self.contentOffset = CGPointMake(0,0);
    else {
        CGFloat offsetValue = horizontal ? self.contentOffset.x : self.contentOffset.y;
        int temp = (offsetValue + viewWidth/2) / viewWidth;
        self.contentOffset = CGPointMake(horizontal ? temp*viewWidth : 0 , horizontal ? 0 : temp*viewWidth);
    }
    
    self.resetOpenPage = FALSE;
}

- (void)reloadSwitches
{
    for (UIView *toggle in self.subviews)
        if ([toggle isKindOfClass:[UIButton class]] || [toggle isKindOfClass:[UILabel class]])
            [toggle removeFromSuperview];
    
    FSSwitchPanel *panel = [FSSwitchPanel sharedPanel];
    
    if (!self.switchesIdentifiers || self.switchesIdentifiers.count == 0) {
        [self addSubview:[self _newNoSwitchesLabel]];
    } else {
        for (NSString *identifier in self.switchesIdentifiers) {
            UIButton *toggle = [panel buttonForSwitchIdentifier:identifier usingTemplate:self.switchesTemplateBundle];
            [self addSubview:toggle];
        }
    }
    
    self.resetOpenPage = TRUE;
    
    [self layoutSwitches];
}


- (void)dealloc
{
    [_switchesTemplateBundle release];
    [_switchesIdentifiers release];
    [super dealloc];
}
@end
