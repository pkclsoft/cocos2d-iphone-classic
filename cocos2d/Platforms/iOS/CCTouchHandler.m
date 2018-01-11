/*
 * cocos2d for iPhone: http://www.cocos2d-iphone.org
 *
 * Copyright (c) 2009 Valentin Milea
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */


// Only compile this code on iOS. These files should NOT be included on your Mac project.
// But in case they are included, it won't be compiled.
#import "../../ccMacros.h"
#ifdef __CC_PLATFORM_IOS

/*
 * This file contains the delegates of the touches
 * There are 2 possible delegates:
 *   - CCStandardTouchHandler: propagates all the events at once
 *   - CCTargetedTouchHandler: propagates 1 event at the time
 */

#import "CCTouchHandler.h"
#import "../../ccMacros.h"

#pragma mark -
#pragma mark TouchHandler
@implementation CCTouchHandler

@synthesize delegate=_delegate, priority=_priority;
@synthesize enabledSelectors=_enabledSelectors;

+ (id)handlerWithDelegate:(id) aDelegate priority:(NSInteger)aPriority
{
	return [[[self alloc] initWithDelegate:aDelegate priority:aPriority] autorelease];
}

- (id)initWithDelegate:(id) aDelegate priority:(NSInteger)aPriority
{
	NSAssert(aDelegate != nil, @"Touch delegate may not be nil");

	if ((self = [super init])) {
		self.delegate = aDelegate;
		_priority = aPriority;
		_enabledSelectors = 0;
	}

	return self;
}

- (void)dealloc {
	CCLOGINFO(@"cocos2d: deallocing %@", self);
	[_delegate release];
	[super dealloc];
}
@end

#pragma mark -
#pragma mark StandardTouchHandler
@implementation CCStandardTouchHandler
-(id) initWithDelegate:(id)del priority:(NSInteger)pri
{
	if( (self=[super initWithDelegate:del priority:pri]) ) {
		if( [del respondsToSelector:@selector(ccTouchesBegan:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorBeganBit;
		if( [del respondsToSelector:@selector(ccTouchesMoved:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorMovedBit;
		if( [del respondsToSelector:@selector(ccTouchesEnded:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorEndedBit;
		if( [del respondsToSelector:@selector(ccTouchesCancelled:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorCancelledBit;
#ifdef __TV_OS_VERSION_MAX_ALLOWED
		if ( [del respondsToSelector:@selector(ccPressesBegan:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorBeganBit;
		if ( [del respondsToSelector:@selector(ccPressesEnded:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorEndedBit;
		if ( [del respondsToSelector:@selector(ccPressesChanged:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorChangedBit;
#endif
	}
	return self;
}
@end

#pragma mark -
#pragma mark TargetedTouchHandler

@interface CCTargetedTouchHandler (private)
-(void) updateKnownTouches:(NSMutableSet *)touches withEvent:(UIEvent *)event selector:(SEL)selector unclaim:(BOOL)doUnclaim;
@end

@implementation CCTargetedTouchHandler

@synthesize swallowsTouches=_swallowsTouches, claimedTouches=_claimedTouches;

+ (id)handlerWithDelegate:(id)aDelegate priority:(NSInteger)priority swallowsTouches:(BOOL)swallow
{
	return [[[self alloc] initWithDelegate:aDelegate priority:priority swallowsTouches:swallow] autorelease];
}

- (id)initWithDelegate:(id)aDelegate priority:(NSInteger)aPriority swallowsTouches:(BOOL)swallow
{
	if ((self = [super initWithDelegate:aDelegate priority:aPriority])) {
		_claimedTouches = [[NSMutableSet alloc] initWithCapacity:2];
		_swallowsTouches = swallow;

		if( [aDelegate respondsToSelector:@selector(ccTouchBegan:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorBeganBit;
		if( [aDelegate respondsToSelector:@selector(ccTouchMoved:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorMovedBit;
		if( [aDelegate respondsToSelector:@selector(ccTouchEnded:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorEndedBit;
		if( [aDelegate respondsToSelector:@selector(ccTouchCancelled:withEvent:)] )
			_enabledSelectors |= kCCTouchSelectorCancelledBit;
#ifdef __TV_OS_VERSION_MAX_ALLOWED
		if ( [aDelegate respondsToSelector:@selector(ccPressBegan:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorBeganBit;
		if ( [aDelegate respondsToSelector:@selector(ccPressEnded:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorEndedBit;
		if ( [aDelegate respondsToSelector:@selector(ccPressChanged:withEvent:)] )
			_enabledSelectors |= kCCPressSelectorChangedBit;
#endif
	}

	return self;
}

- (void)dealloc {
	[_claimedTouches release];
	[super dealloc];
}
@end


#endif // __CC_PLATFORM_IOS
