//
//  CCTVMenu.h
//
//  Created by Peter Easdown on 23/09/2015.
//

#import "CCMenu.h"

/**
 *  This protocol defines all of the properties and actions for a "focusable" menu item.  Typically, it will be
 *  implemented by a subclass of CCMenuItem but that isn't mandatory as CCTVMenu doesn't require that.
 */
@protocol CCFocusableMenuItem

/**
 *  Like anything else, if the item is enabled, this should be YES.
 */
@property (nonatomic) BOOL isEnabled;

/**
 *  Indicates whether the item is focused or not.  Override the setter if you want to implement a special animation or
 *  visual indication of selection to the user.  If you don't it won't be obvious that the item is selected.
 */
@property (nonatomic) BOOL focused;

/**
 *  Some menu items may be interested in knowing what the user is doing when they have focus.  For example, a slider, or
 *  a potentiometer might want to be able to respond to the user panning either for visual effect or for the purpose of
 *  changing internal state.
 *
 *  Set this to YES if the item is such a beast, and CCTVMenu will pass panning events through to the menu item whenever
 *  the method [wantsControlOfTouch:] returns YES.
 */
@property (nonatomic) BOOL wantsAngleOfTouch;

/**
 *  As per the property wantsAngleOfTouch, this method should return YES if the menu item wants control over the users
 *  panning.  This basically allows an item to wrestle control from the CCTVMenu when it needs to so that the CCTVMenu's
 *  handling of panning to another menu item doesn't interact with the items internal handler.
 *
 *  An example use of this is a potentiometer, used to set the volume of music.  The user would pan to focus the potentiometer
 *  click to activate it (which causes this method to return YES) and then pan to adjust the value of the volume.  Clicking 
 *  then deactivates and returns panning control back to the CCTVMenu instance.
 */
- (BOOL) wantsControlOfTouch;

/**
 *  This method is for those times when you have an animation to highlight focus of an item and you want to restart it without
 *  removing focus altogether.
 */
- (void) resetFocus;

/**
 *  The angle of touch is an angle in degrees (where 0 is north, moving CW) where the angle represents the direction the users
 *  touch on the remote in relation to the start of a pan gesture.  The position of touch is irrelevant as the remote doesn't
 *  have a meaningful coordinate system.  By using this angle, the menu item can then assume that the touch is inside its
 *  frame (bacause it has focus), and it can then apply actions based on the angle.  For example, you can calculate a point on
 *  a circle at a radius from the center of the menu item at the specified angle to indicate a relative position of touch
 *  so that the item can behave as if it would normally on iOS.
 *
 *  @param angleInDegrees is the angle
 *  @param firstAngle is YES if this is the first touch in a pan gesture.
 *  @param lastAngle is YES if this is the last touch in a pan gesture.
 */
- (void) setAngleOfTouch:(float)angleInDegrees firstTime:(BOOL)firstAngle lastTime:(BOOL)lastAngle;

/**
 *  Activates the item, just like any other menu item.  This was included to ensure that classes that <em>don't</em> subclass
 *  CCMenuItem support "activation" via a click.
 */
-(void) activate;

@end

/**
 *  A CCMenu subclass that provides a basic, yet functional focus management system for tvOS in Cocos2D.  It supports
 *  the use of CCMenuItem and it's subclasses, plus any objects that conform to the CCFocusableMenuItem protocol.
 *
 *  The menu is intended to provide behaviour similar to that provided by Apple's UIKit focus manager on tvOS in that
 *  menu items require focus to be given to them before they can be activated.
 *
 *  CCTVMenu works by allowing the user to pan from one menu item to another.  There is an internal distance threshold
 *  used to determine at what point in a straight-line pan the focus will move from one menu item to the next.  The 
 *  CCTVMenu uses the direction of the pan to determine which menu item is given focus.  It searches the enabled menu
 *  items for the closest menu item in a straight line within 25.0 degrees of the pan direction.
 *
 *  CCTVMenu also tried to respect Apple's UI Guidelines by using the Apple TV Remote's "menu" button to act as a
 *  trigger for the "back" button on your scene/layer/node.  By setting the backItem property, the CCTVMenu will hide
 *  that item from view, but will activate it if the "menu" button is pressed.  The backItem is also ignored for focus
 *  events.
 *
 *  Another class, CCTVMenuStack is used to manage CCTVMenu instances.  Typically (at least in my apps), I create a
 *  CCMenu instance on each distinct scene/layer that the user is to interact with.  If you use CCTVMenu instead for
 *  each scene, then as the menu is realised (via onEnter), it pushes itself onto the static stack object.  When it
 *  does this, any other CCTVMenu instances are disabled.  When a CCTVMenu is cleaned up (via cleanup), it pops itself
 *  off the stack.  This way the application doesn't need to manage the enabling and disabling of menus (which is needed
 *  if you add a layer to your main game node that has it's own menu) and it all happens smoothly with little or no
 *  change to the existing code.
 */
@interface CCTVMenu : CCMenu <UIGestureRecognizerDelegate>

/**
 *  This is the currently focused item in the menu.  Typically you won't need to examine this; it's used internally.
 */
@property (nonatomic, retain) id<CCFocusableMenuItem> focusedItem;

/**
 *  This is the nominated "back" button for the scene/layer that the menu is the UI for.  CCTVMenu will hide this 
 *  item from view and prevent it from receiving focus.  Pressing "menu" on the remote will activate this item.
 */
@property (nonatomic, retain) CCNode *backItem;

typedef enum {
    /**
     *  The play/pause button is not used.
     */
    kPlayPauseNone,
    
    /**
     *  This property offers a way for an app (probably a game) to have two modes of operation for the remote touchpad.
     *  If your game uses gesture recognizers to manipulate a character for example and you need be able to give give
     *  control to the player instead of focus management, then use this property.  Setting it to YES causes the CCTVMenu
     *  to recognise press events on the "play/pause" button on the remote.  When this button is pressed, it toggles
     *  the panControlActive property.  When that property is set to YES, CCTVMenu will ignore pan gestures, allowing your
     *  app to use it's own pan gesture recognizer for other things.
     */
    kPlayPauseTogglesPanControl,
    
    /**
     *  This property offers an alternative way to handle a situation where you have live action and the simultaneous need
     *  to be able to focus on, and activate buttons on the screen.  In this case, the play/pause button is used to move
     *  focus from one button to the next.  This means that panning doesn't need to swap from game action to menus and back
     *  again which might be difficult to use.
     */
    kPlayPauseShiftsFocus
    
} PlayPauseButtonAction;

@property (nonatomic) PlayPauseButtonAction playPauseAction;

/**
 *  This property, when YES causes the CCTVMenu instance to ignore pan gestures.
 */
@property (nonatomic) BOOL panControlActive;

/**
 *  Causes the CCTVMenu to search through it's children for the first item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *
 * @note This also sets panControlActive to YES.
 */
- (void) findFirstFocusableItem;

/**
 *  Causes the CCTVMenu to search through it's children for the next item that is:
 *
 *  1. enabled
 *  2. not the backItem
 *  3. not the currently focused item.
 */
- (void) findNextFocusableItem;

@end
