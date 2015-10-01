//
//  AppDelegate.h
//
//

#import <UIKit/UIKit.h>
#import "cocos2d.h"

@interface AppDelegate : NSObject <UIApplicationDelegate, CCDirectorDelegate>
{
    UIWindow *window_;
    UINavigationController *navController_;
    
    CCDirectorIOS	*director_;							// weak ref
}

+ (AppDelegate*) sharedInstance;

@property (nonatomic, retain) UIWindow *window;
@property (readonly) UINavigationController *navController;
@property (readonly) CCDirectorIOS *director;

@end
