//
//  RootViewController.m
//  coco2d-tvos
//
//

#import "RootViewController.h"

@implementation RootViewController

#if !defined(__TV_OS_VERSION_MAX_ALLOWED)
-(UIInterfaceOrientationMask)supportedInterfaceOrientations{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    return UIInterfaceOrientationMaskLandscapeLeft;
#else
    return UIInterfaceOrientationLandscapeLeft;
#endif
}
#endif

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end

