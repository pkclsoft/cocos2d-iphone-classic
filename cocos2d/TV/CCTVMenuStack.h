//
//  CCTVMenuStack.h
//
//  Created by Peter Easdown on 25/09/2015.
//

#import <Foundation/Foundation.h>

#import "CCMenu.h"

/**
 *  A simple stack for managing nesting of CCTVMenu objects.  Effectively provides a way for
 *  a tvOS app to handle focus management when swapping between scenes/layers.
 */
@interface CCTVMenuStack : NSObject

/**
 *  Returns a singleton instance of CCTVMenuStack.
 */
+ (CCTVMenuStack*) sharedTVMenuStack;

/**
 *  Disable whatever menu is currently on the top of the stack, and put this new menu onto the top
 *  ensuring it is enabled.
 */
- (void) pushMenu:(CCMenu*)menu;

/**
 *  Pop the current menu off the stack, and enable the menu that is then on the top.
 */
- (CCMenu*) popMenu;

@end
