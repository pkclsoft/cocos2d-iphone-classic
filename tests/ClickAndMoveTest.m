//
// Click and Move demo
// a cocos2d example
// http://www.cocos2d-iphone.org
//

#import "ClickAndMoveTest.h"

enum
{
	kTagSprite = 1,
};

@implementation MainLayer
-(id) init
{
	if( ( self=[super init] ))
	{
		self.isTouchEnabled = YES;
		
		CCSprite *sprite = [CCSprite spriteWithFile: @"grossini.png"];
		
		id layer = [CCLayerColor layerWithColor: ccc4(255,255,0,255)];
		[self addChild: layer z:-1];
			
		[self addChild: sprite z:0 tag:kTagSprite];
		[sprite setPosition: ccp(20,150)];
		
		[sprite runAction: [CCJumpTo actionWithDuration:4 position:ccp(300,48) height:100 jumps:4] ];
		
		[layer runAction: [CCRepeatForever actionWithAction: 
									[CCSequence actions:
									[CCFadeIn actionWithDuration:1],
									[CCFadeOut actionWithDuration:1],
									nil]
						] ];
	}	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	
	CGPoint location = [touch locationInView: [touch view]];
	CGPoint convertedLocation = [[CCDirector sharedDirector] convertToGL:location];

	CCNode *s = [self getChildByTag:kTagSprite];
	[s stopAllActions];
	[s runAction: [CCMoveTo actionWithDuration:1 position:ccp(convertedLocation.x, convertedLocation.y)]];
	float o = convertedLocation.x - [s position].x;
	float a = convertedLocation.y - [s position].y;
	float at = (float) CC_RADIANS_TO_DEGREES( atanf( o/a) );
	
	if( a < 0 ) {
		if(  o < 0 )
			at = 180 + abs(at);
		else
			at = 180 - abs(at);	
	}
	
	[s runAction: [CCRotateTo actionWithDuration:1 angle: at]];	
}
@end

// CLASS IMPLEMENTATIONS
@implementation AppController

@synthesize window=window_, viewController=viewController_, navigationController=navigationController_;

- (void) applicationDidFinishLaunching:(UIApplication*)application
{
	
	UIAlertView*			alertView;
	alertView = [[UIAlertView alloc] initWithTitle:@"Welcome" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Start", nil];
	[alertView setMessage:[NSString stringWithFormat:@"Click on the screen\nto move and rotate Grossini", [[UIDevice currentDevice] model]]];
	[alertView show];
	[alertView release];

	// CC_DIRECTOR_INIT()
	//
	// 1. Initializes an EAGLView with 0-bit depth format, and RGB565 render buffer
	// 2. EAGLView multiple touches: disabled
	// 3. creates a UIWindow, and assign it to the "window" var (it must already be declared)
	// 4. Parents EAGLView to the newly created window
	// 5. Creates Display Link Director
	// 6. It will try to run at 60 FPS
	// 7. Display FPS: NO
	// 8. Will create a CCDirector and will associate the view with the director
	// 9. Will create a UINavigationControlView with the director.
	CC_DIRECTOR_INIT();
	
	// Turn on display FPS
	[director_ setDisplayStats:kCCDirectorStatsFPS];
	
	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices
	if( ! [director_ enableRetinaDisplay:YES] )
		CCLOG(@"Retina Display Not supported");
	
	// Set multiple touches on
	[[director_ view] setMultipleTouchEnabled:YES];	
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	
	// When in iPad / RetinaDisplay mode, CCFileUtils will append the "-ipad" / "-hd" to all loaded files
	// If the -ipad  / -hdfile is not found, it will load the non-suffixed version
	[CCFileUtils setiPadSuffix:@"-ipad"];			// Default on iPad is "" (empty string)
	[CCFileUtils setRetinaDisplaySuffix:@"-hd"];	// Default on RetinaDisplay is "-hd"
	
	CCScene *scene = [CCScene node];
	MainLayer * mainLayer =[MainLayer node];	
	[scene addChild: mainLayer z:2];
	
	[director_ pushScene: scene];
}

// getting a call, pause the game
-(void) applicationWillResignActive:(UIApplication *)application
{
	AppController *app = [[UIApplication sharedApplication] delegate];
	UINavigationController *nav = [app navigationController];
	
	if( [nav visibleViewController] == viewController_ )
		[[CCDirector sharedDirector] pause];
}

// call got rejected
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	AppController *app = [[UIApplication sharedApplication] delegate];
	UINavigationController *nav = [app navigationController];	
	
	if( [nav visibleViewController] == viewController_ )
		[[CCDirector sharedDirector] resume];
}

-(void) applicationDidEnterBackground:(UIApplication*)application
{
	AppController *app = [[UIApplication sharedApplication] delegate];
	UINavigationController *nav = [app navigationController];	
	
	if( [nav visibleViewController] == viewController_ )
		[[CCDirector sharedDirector] stopAnimation];
}

-(void) applicationWillEnterForeground:(UIApplication*)application
{
	AppController *app = [[UIApplication sharedApplication] delegate];
	UINavigationController *nav = [app navigationController];	
	
	if( [nav visibleViewController] == viewController_ )
		[[CCDirector sharedDirector] startAnimation];
}

// application will be killed
- (void)applicationWillTerminate:(UIApplication *)application
{	
	CC_DIRECTOR_END();
}

// purge memroy
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[CCDirector sharedDirector] purgeCachedData];
}

// next delta time will be zero
-(void) applicationSignificantTimeChange:(UIApplication *)application
{
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

- (void) dealloc
{
	[viewController_ release];
	[window_ release];
	[super dealloc];
}

@end
