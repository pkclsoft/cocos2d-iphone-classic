//
//  CCTVMenu.m
//
//  Created by Peter Easdown on 23/09/2015.
//

#import "CCTVMenu.h"
#import "CCTVMenuStack.h"
#import "cocos2d.h"

@interface CCTVMenu() <UIGestureRecognizerDelegate>

/**
 *  The pan recognizer for this menu - is used for all the focus management.
 */
@property (nonatomic, retain) UIPanGestureRecognizer *panRecognizer;

/**
 *  The tap recognizer - this handles presses on the touchpad itself.
 */
@property (nonatomic, retain) UITapGestureRecognizer *tapRecognizer;

/**
 *  A recognizer for the remote "menu" button.  This is only created if the
 *  backItem property is set.
 */
@property (nonatomic, retain) UITapGestureRecognizer *menuButtonRecognizer;

/**
 *  A recognizer for the remote "play/pause" button.  This is only created if the
 *  playPauseAssumesPanControl property is set to YES.
 */
@property (nonatomic, retain) UITapGestureRecognizer *playPauseButtonRecognizer;

/**
 *  This is a simple action to provide a visual indication that an item has focus.  It is only
 *  used for menu items that do not conform to the CCFocusableMenuItem protocol.
 */
@property (nonatomic, retain) CCRepeatForever *focusAction;

/**
 *  This is the scale of the focused item when it receives focus so that it can be restored
 *  when focus moves away.  It is only used for menu items that do not conform to the
 *  CCFocusableMenuItem protocol.
 */
@property (nonatomic) float focusedItemScale;

@end

@implementation CCTVMenu {
    
    /// The start point of a pan touch.
    CGPoint startPoint;
    
    /**
     *  These flags are initialised when a menu item is given focus as a way to simply
     *  know at any time what sort of item it is.
     */
    BOOL focusedItemWantsAngle;
    BOOL focusedItemIsFocusable;
    BOOL focusedItemIsItem;
}

/**
 *  Initialises the menu with defaults.
 */
- (id) init {
    self = [super init];
    
    if (self != nil) {
        _focusedItem = nil;
        focusedItemIsFocusable = NO;
        focusedItemWantsAngle = NO;
        focusedItemIsItem = NO;
        _focusAction = nil;
        _focusedItemScale = 1.0;
        _panControlActive = YES;
        _playPauseAction = kPlayPauseNone;
        
        [self addPanRecognizer];
        [self addTapRecognizers];
    }
    
    return self;
}

/**
 *  Initialises the menu and populates it with the specified array of menu items.
 *
 *  This subclass relaxes the rule regarding the need for the items to be subclasses of
 *  CCMenuItem.
 */
-(id) initWithArray:(NSArray *)arrayOfItems
{
    if( (self=[super initWithArray:arrayOfItems]) ) {
        [self addPanRecognizer];
        [self addTapRecognizers];
        
        _focusedItem = nil;
        focusedItemIsFocusable = NO;
        focusedItemWantsAngle = NO;
        focusedItemIsItem = NO;
        _focusAction = nil;
        _focusedItemScale = 1.0;
        _panControlActive = YES;
        _playPauseAction = kPlayPauseNone;
        
        [self findFirstFocusableItem];
    }
    
    return self;
}

/**
 *  Cleans up the menu prior to deallocation.
 */
- (void) cleanup {
    [super cleanup];
    
    [self removePanRecognizer];
    [self removeTapRecognizers];
    
    if (self.focusAction != nil) {
        [[self focusAction] stop];
        self.focusAction = nil;
    }
    
    if (self.backItem != nil) {
        _backItem = nil;
    }
    
    [[CCTVMenuStack sharedTVMenuStack] popMenu];
}

/**
 *  When the CCTVMenu is added to the node tree, push it onto the CCTVMenuStack.
 */
- (void) onEnter {
    [super onEnter];
    
    [[CCTVMenuStack sharedTVMenuStack] pushMenu:self];
}

/**
 *  Overrides addChild so that children are allowed to also implement the
 *  CCFocusableMenuITem protocol.
 */
-(void) addChild:(CCMenuItem*)child z:(NSInteger)z tag:(NSInteger) aTag
{
    NSAssert(([child isKindOfClass:[CCMenuItem class]] == YES) ||
             ([child conformsToProtocol:@protocol(CCFocusableMenuItem)] == YES),
             @"Menu only supports MenuItem objects as children");
    [super addChild:child z:z tag:aTag];
}

/**
 *  Overrides setEnabled: so that when the menu is re-enabled, it can re-apply focus to
 *  whatever item was in focus prior to the menu being disabled.
 */
- (void) setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    
    if (enabled == YES) {
        [self startFocus];
    }
    
    NSLog(@"Menu Enabled: %@ in parent: %@", (enabled ? @"YES" : @"NO"), [[self.parent class] description]);
}

/**
 *  Sets the "back" or "close" button that will be activated when the user presses the "menu"
 *  button on the remote.
 */
- (void) setBackItem:(id)backItem {
    _backItem = backItem;
    
    _backItem.visible = NO;
    
    [self addTapRecognizers];
}

/**
 *  Sets the action desired when the user presses the play/pause button.  This is provided so
 *  that you have a way to use the play/pause button in a way that suites your app.
 */
- (void) setPlayPauseAction:(PlayPauseButtonAction)playPauseAction {
    if (playPauseAction != _playPauseAction) {
        _playPauseAction = playPauseAction;
        
        // By default, a CCTVMenu will have control over pan gestures, regardless of the action type.
        //
        _panControlActive = YES;
    }
}

/**
 *  Returns the menu item that currently has focus as a CCMenuItem.
 */
- (CCMenuItem<CCFocusableMenuItem>*) focusedMenuItem {
    return (CCMenuItem<CCFocusableMenuItem>*)_focusedItem;
}

/**
 *  Returns the menu item that currently has focus as a CCFocusableMenuItem.
 */
- (NSObject<CCFocusableMenuItem>*) focusedObject {
    return (NSObject<CCFocusableMenuItem>*)_focusedItem;
}

/**
 *  Returns the menu item that currently has focus as a CCNode
 */
- (CCNode*) focusedNode {
    return (CCNode*)_focusedItem;
}

/**
 *  Causes the CCTVMenu to search through it's children for the first item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *
 * @note This also sets panControlActive to YES.
 */
- (void) findFirstFocusableItem {
    CCMenuItem<CCFocusableMenuItem>* item;
    BOOL done = NO;
    
    CCARRAY_FOREACH(_children, item){
        if ((done == NO) && (item != _backItem) && (item.isEnabled == YES)) {
            [self setFocusedItem:item];
            done = YES;
        }
    }
    
    // Assume that if the app wants an item to be focused, then the menu gets control of panning
    //
    _panControlActive = YES;
}

/**
 *  Causes the CCTVMenu to search through it's children for the next item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *  3. not the currently focused item.
 */
- (void) findNextFocusableItem {
    if (_focusedItem == nil) {
        [self findFirstFocusableItem];
    } else {
        // Where is the current focused item?
        //
        NSUInteger currentIndex = [_children indexOfObject:_focusedItem];
        NSUInteger searchIndex = currentIndex + 1;
        
        if (currentIndex == _children.count-1) {
            // It is the last item in the array, so in that case, find the first focusable item.
            //
            [self findFirstFocusableItem];
        } else {
            // Not the last, so search forward, wrapping around at the end, and finish if we get
            // back to the same point.
            //
            NSUInteger newIndex = NSNotFound;
            
            while ((newIndex == NSNotFound) && (searchIndex != currentIndex)) {
                // If the search has gone beyond the end of the array, then loop back to the start.
                //
                if (searchIndex >= _children.count) {
                    searchIndex = 0;
                }
                
                CCMenuItem<CCFocusableMenuItem>* item = [_children objectAtIndex:searchIndex];
                
                if (item == _focusedItem) {
                    // This shouldn't be necessary, but as a protection...
                    //
                    searchIndex = currentIndex;
                } else if ((item != _backItem) && (item.isEnabled == YES)) {
                    newIndex = searchIndex;
                } else {
                    searchIndex++;
                }
            }
            
            // Found one, so move focus to it.
            //
            if (newIndex != NSNotFound) {
                [self setFocusedItem:[_children objectAtIndex:newIndex]];
            }
        }
    }
}

/**
 *  Sets the currently focused item, shifting focus visually as required.
 */
- (void) setFocusedItem:(id<CCFocusableMenuItem>)focusedItem {
    if (_focusedItem != focusedItem) {
        if (_focusedItem != nil) {
            [self resetFocus];
        }
        
        _focusedItem = focusedItem;
        
        if (_focusedItem != nil) {
            focusedItemIsFocusable = [[self focusedObject] conformsToProtocol:@protocol(CCFocusableMenuItem)];
            
            focusedItemWantsAngle = focusedItemIsFocusable ? [self focusedObject].wantsAngleOfTouch : NO;
            
            focusedItemIsItem = [[self focusedObject] isKindOfClass:[CCMenuItem class]];
            
            [self startFocus];
        }
    }
}

/**
 *  Gives focus to the focused item.  If the item implements CCFocusableMenuItem, then
 *  the item is told that is is focused.
 *
 *  If the item is a regular CCMenuItem then the focus os visually indicated using a simple
 *  scale-wobble.
 */
- (void) startFocus {
    if (focusedItemIsFocusable == YES) {
        _focusedItem.focused = YES;
    } else {
        // This is an non-focusable menu item, so simply scale it up.
        //
        _focusedItemScale = [self focusedNode].scale;
        
        self.focusAction = [CCRepeatForever actionWithAction:
                        [CCSequence actions:
                         [CCScaleTo actionWithDuration:0.5 scale:_focusedItemScale * 1.2],
                         [CCScaleTo actionWithDuration:0.5 scale:_focusedItemScale * 1.15],
                         nil]];
        
        [[self focusedNode] runAction:_focusAction];
    }
    
    if ((focusedItemIsItem == YES) && (self.parent != nil)) {
        [[self focusedMenuItem] selected];
    }
}

/**
 *  Resets the focus of the focused item, effectively turning the focus animation off.
 */
- (void) resetFocus {
    if (focusedItemIsFocusable == YES) {
        _focusedItem.focused = NO;
    } else {
        [[self focusedNode] stopAllActions];
        self.focusAction = nil;
        
        [[self focusedNode] runAction:[CCScaleTo actionWithDuration:0.4 scale:_focusedItemScale]];
    }
    
    if ((focusedItemIsItem == YES) && (self.parent != nil)) {
        [[self focusedMenuItem] unselected];
    }
}

/**
 * Override normal CCMenu behaviour.
 */
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return NO;
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
}

/**
 * Override normal CCMenu behaviour.
 */
-(void) ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
}

#pragma mark -
#pragma mark Gesture code

// Ensures that the menu still works with the gesture recognizer.
//
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    if (_enabled == YES) {
        return ((gestureRecognizer == _panRecognizer) && (_panControlActive == YES)) ||
                (gestureRecognizer == _tapRecognizer) ||
                (gestureRecognizer == _menuButtonRecognizer) ||
                (gestureRecognizer == _playPauseButtonRecognizer);
    } else {
        return NO;
    }
}

/**
 *  Important that if you are handling press events, this returns YES.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    return YES;
}

/**
 *  This is essential if you want a Pan gesture recognizer to work alongside a press or tap recognizer.
 */
- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma mark - Pan Gesture code

- (float) angleFromPoint:(CGPoint)from toPoint:(CGPoint)to {
    CGPoint pnormal = ccpSub(to, from);
    float radians = atan2f(pnormal.x, pnormal.y);
    
    return radians;
}

- (void) panned:(UIPanGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    CGPoint b = [[CCDirector sharedDirector] convertToGL:[recognizer locationInView:recognizer.view]];
    
    float angle = fmodf((360.0 + CC_RADIANS_TO_DEGREES([self angleFromPoint:startPoint toPoint:b])), 360.0);
    
    if([recognizer state] == UIGestureRecognizerStateBegan) {
        startPoint = b;

        if (focusedItemWantsAngle == YES) {
            [[self focusedObject] setAngleOfTouch:angle firstTime:YES lastTime:NO];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        BOOL itemChanged = [self handlePanInDirection:angle
                                         withDistance:ccpDistance(b, startPoint)];
        
        if (itemChanged == YES) {
            startPoint = b;
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (focusedItemWantsAngle == YES) {
            [[self focusedObject] setAngleOfTouch:angle firstTime:NO lastTime:YES];
        }
    }
}

/// A distance that the pan must traverse in a straight line for a focus change to occur.
#define NEXT_ITEM_THRESHOLD (350.0)

/// This is the maximum variance between the direction of the pan, and the direction from the start of the pan
/// to the item being examined as a candidate for the next focus.
#define PAN_DIRECTION_PROXIMITY (25.0)

- (BOOL) handlePanInDirection:(float)direction withDistance:(float)distance {
    if (_focusedItem != nil) {
        // If the item is interested in tracking the touch, and actively wants control of the touch, then
        // give this touch to the item.
        //
        if ((focusedItemWantsAngle == YES) && ([self focusedObject].wantsControlOfTouch == YES)) {
            
            [[self focusedObject] setAngleOfTouch:direction firstTime:NO lastTime:NO];
            
            // Otherwise, if the item isn't currently interested, and the touch is in a straight line, then see if there is
            // another item in that direction.
            //
        } else if (distance > NEXT_ITEM_THRESHOLD) {
            if ((focusedItemWantsAngle == NO) ||
                ((focusedItemWantsAngle == YES) && ([self focusedObject].wantsControlOfTouch == NO))) {
                return [self findNextItemInDirection:direction];
            }
        }
    }
    
    return NO;
}

/**
 *  Searches for other menu items in the direction specified, and locates the closest.
 */
- (BOOL) findNextItemInDirection:(float)direction {
    CCMenuItem<CCFocusableMenuItem> *nextItem = nil;
    float bestDistance = MAXFLOAT;
    float bestAngle = MAXFLOAT;
    
    CCMenuItem<CCFocusableMenuItem>* item;
    CCARRAY_FOREACH(_children, item){
        if ((item != _backItem) && (item != _focusedItem) && (item.isEnabled == YES)) {
            float angleToItem = fmodf((360.0 + CC_RADIANS_TO_DEGREES([self angleFromPoint:[self focusedNode].position toPoint:item.position])), 360.0);
            float distanceToItem = ccpDistance([self focusedNode].position, item.position);
            float angleDelta = fabsf(fabsf(angleToItem) - fabsf(direction));
            
            if ((angleDelta <= PAN_DIRECTION_PROXIMITY) &&
                (angleDelta <= bestAngle) &&
                (distanceToItem < bestDistance)) {
                nextItem = item;
                bestDistance = distanceToItem;
                bestAngle = angleDelta;
            }
        }
    }
    
    if ((nextItem != nil) && (nextItem != _focusedItem)) {
        [self setFocusedItem:nextItem];
        
        return YES;
    } else {
        return NO;
    }
}

- (void) addPanRecognizer {
    if (_panRecognizer != nil) {
        [self removePanRecognizer];
    }
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    _panRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [_panRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_panRecognizer];
    
    NSLog(@"CCTVMenu Pan recognizer added");
}

- (void) removePanRecognizer {
    if (_panRecognizer != nil) {
        [_panRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_panRecognizer];
        [_panRecognizer release];
        _panRecognizer = nil;
        
        NSLog(@"CCTVMenu Pan recognizer removed");
    }
}

#pragma mark - Tap Gesture code

- (void) tapped:(UITapGestureRecognizer*)recognizer {
    if ((_enabled == NO) || ([[self focusedMenuItem] isEnabled] == NO)) {
        return;
    }
    
    if (focusedItemIsItem == YES) {
        [[self focusedMenuItem] activate];
    } else if (focusedItemIsFocusable == YES) {
        [[self focusedObject] activate];
    }
}

- (void) menuPressed:(UITapGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    if (_backItem != nil) {
        if ([_backItem conformsToProtocol:@protocol(CCFocusableMenuItem)] == YES) {
            [((CCNode<CCFocusableMenuItem>*) _backItem) activate];
        } else if ([_backItem isKindOfClass:[CCMenuItem class]] == YES) {
            [(CCMenuItem*)_backItem activate];
        }
    }
}

- (void) playPausePressed:(UITapGestureRecognizer*)recognizer {
    if (_enabled == NO) {
        return;
    }
    
    switch (_playPauseAction) {
        case kPlayPauseTogglesPanControl: {
            if (_panControlActive == YES) {
                _panControlActive = NO;
            } else {
                _panControlActive = YES;
            }
        }
            break;
        case kPlayPauseShiftsFocus: {
            [self findNextFocusableItem];
        }
            break;
            
        case kPlayPauseNone:
            break;
    }
}

- (void) addTapRecognizers {
    if (_tapRecognizer != nil) {
        [self removeTapRecognizers];
    }
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    _tapRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeSelect]];
    [_tapRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_tapRecognizer];
    
    _playPauseButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPausePressed:)];
    _playPauseButtonRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypePlayPause]];
    [_playPauseButtonRecognizer setDelegate:self];
    
    [[CCDirector sharedDirector].view addGestureRecognizer:_playPauseButtonRecognizer];
    
    if (_backItem != nil) {
        _menuButtonRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(menuPressed:)];
        _menuButtonRecognizer.allowedPressTypes = @[[NSNumber numberWithInteger:UIPressTypeMenu]];
        [_menuButtonRecognizer setDelegate:self];
        
        [[CCDirector sharedDirector].view addGestureRecognizer:_menuButtonRecognizer];
    }
    
    NSLog(@"CCTVMenu Tap/press recognizers added");
}

- (void) removeTapRecognizers {
    if (_tapRecognizer != nil) {
        [_tapRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_tapRecognizer];
        [_tapRecognizer release];
        
        NSLog(@"CCTVMenu Tap recognizer removed");
    }
    
    if (_playPauseButtonRecognizer != nil) {
        [_playPauseButtonRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_playPauseButtonRecognizer];
        [_playPauseButtonRecognizer release];
        
        NSLog(@"CCTVMenu playpause button recognizer removed");
    }
    
    if (_menuButtonRecognizer != nil) {
        [_menuButtonRecognizer setDelegate:nil];
        [[CCDirector sharedDirector].view removeGestureRecognizer:_menuButtonRecognizer];
        [_menuButtonRecognizer release];
        
        NSLog(@"CCTVMenu menu button recognizer removed");
    }
}

@end
