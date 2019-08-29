#import "DD_Custom_SBNCColumnViewController.h"
#import "DD_Defines.h"

@interface UIView (ExtensionsLoader)
- (void)viewWillAppear;
- (void)viewDidAppear;
- (void)viewWillDisappear;
- (void)viewDidDisappear;
- (void)viewEntersForeground;
- (void)viewEntersBackground;
@end


#define kContainerTag 123

%subclass DD_Custom_SBNCColumnViewController :  SBNCColumnViewController

- (void)_insertContentUnavailableView {}


- (void)viewWillLayoutSubviews
{
    %orig;

    //before this function is called self.view.bounds is CGRectZero
    UIView *container = [self.view viewWithTag:kContainerTag];
    container.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)appear
{
    %orig;
    [self dd_informContainer:@selector(viewWillAppear)];
}

- (void)viewDidAppear:(BOOL)appear
{
    %orig;
            
    [self dd_informContainer:@selector(viewDidAppear)];
}

- (void)viewWillDisappear:(BOOL)disappear
{
    %orig;
    [self dd_informContainer:@selector(viewWillDisappear)];
}

- (void)viewDidDisappear:(BOOL)disappear
{
    %orig;
    [self dd_informContainer:@selector(viewDidDisappear)];
}

- (void)dd_ObserverViewControllerEntersForeground
{
    [self dd_informContainer:@selector(viewEntersForeground)];
}

- (void)dd_ObserverViewControllerEntersBackground
{
    [self dd_informContainer:@selector(viewEntersBackground)];
}

- (id)title
{
    NSString *title = %orig;
    return (title != nil) ? title : self.plugin_id;
}

// function already added to SBBulletinObserverViewController
- (id)plugin_id
{
    return objc_getAssociatedObject(self, @selector(plugin_id));
}

%new(v@:@)
- (void)setPluginID:(NSString *)pluginID
{
    objc_setAssociatedObject(self, @selector(plugin_id), pluginID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

%new(v@::)
- (void)dd_informContainer:(SEL)selector
{
    UIView *container = [self.view viewWithTag:kContainerTag];
    if(container && [container respondsToSelector:selector])
        [container performSelector:selector withObject:nil afterDelay:0.0];
}

%new(v@:@)
- (void)dd_insertViewContainer:(UIView *)container
{
    container.tag = kContainerTag;

    [self.view addSubview:container];
}
%end