//
//  CCMenuStack.m
//
//  Created by Peter Easdown on 25/09/2015.
//

#import "CCTVMenuStack.h"

@interface CCTVMenuStack()

/**
 *  The internal stack.
 */
@property (nonatomic, retain) NSMutableArray *stack;

@end

/**
 *  A simple stack for managing nesting of CCTVMenu objects.  Effectively provides a way for
 *  a tvOS app to handle focus management when swapping between scenes/layers.
 */
@implementation CCTVMenuStack

/**
 *  Default initialiser.
 */
- (id) init {
    self = [super init];
    
    if (self != nil) {
        self.stack = [NSMutableArray arrayWithCapacity:5];
    }
    
    return self;
}

/**
 * A static instance of this class.  You should only need one stack in a given app.
 */
static CCTVMenuStack *static_tvMenu = nil;

/**
 *  Returns a singleton instance of CCTVMenuStack.
 */
+ (CCTVMenuStack*) sharedTVMenuStack {
    if (static_tvMenu == nil) {
        static_tvMenu = [[CCTVMenuStack alloc] init];
    }
    
    return static_tvMenu;
}

/**
 *  Disable whatever menu is currently on the top of the stack, and put this new menu onto the top
 *  ensuring it is enabled.
 */
- (void) pushMenu:(CCMenu*)menu {
    if (_stack.count > 0) {
        ((CCMenu*)[_stack lastObject]).enabled = NO;
    }
    
    // In an ideal world, this check wouldn't be needed, but due to the fact that cleanup of nodes can happen out of
    // sequence with what is happening on screen, we do.
    //
    if ([_stack containsObject:menu] == NO) {
        [_stack addObject:menu];
    }

    NSLog(@"pushMenu, remaining: %lu", (unsigned long)_stack.count);
    
    menu.enabled = YES;
}

/**
 *  Pop the current menu off the stack, and enable the menu that is then on the top.
 */
- (CCMenu*) popMenu {
    [_stack removeLastObject];
    
    NSLog(@"popMenu, remaining: %lu", (unsigned long)_stack.count);
    
    CCMenu *newMenu = ((CCMenu*)[_stack lastObject]);
    
    if (newMenu != nil) {
        newMenu.enabled = YES;
    
        return newMenu;
    } else {
        NSAssert(false, @"CCTVMenuStack exhausted.");
    }
    
    return nil;
}

@end
