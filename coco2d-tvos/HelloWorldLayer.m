//
//  HelloWorldLayer.m
//  coco2d-tvos
//


// Import the interfaces
#import "HelloWorldLayer.h"
#import "ObjectAL.h"
#import "CCTVMenu.h"

// HelloWorldLayer implementation
@implementation HelloWorldLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		
		// create and initialize a Label
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Hello World" fontName:@"Helvetica" fontSize:64];

		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
	
		// position the label on the center of the screen
		label.position =  ccp( size.width /2 , size.height*0.75 );
        
        label.color = ccWHITE;
		
		// add the label as a child to this Layer
		[self addChild: label];
        
//        [[SimpleAudioEngine sharedEngine] playEffect:@"ping1.aiff"];
        
        
        CCMenuItemLabel *item1 = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Item 1" fontName:@"Helvetica" fontSize:66]];
        item1.position = CGPointMake(size.width * 0.25, size.height * 0.25);
        CCMenuItemLabel *item2 = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Item 2" fontName:@"Helvetica" fontSize:66]];
        item2.position = CGPointMake(size.width * 0.75, size.height * 0.25);
        CCMenuItemLabel *item3 = [CCMenuItemLabel itemWithLabel:[CCLabelTTF labelWithString:@"Item 3" fontName:@"Helvetica" fontSize:66]];
        item3.position = CGPointMake(size.width * 0.5, size.height * 0.5);
        
        [item3 setBlock:^(id sender) {
            [[OALSimpleAudio sharedInstance] playEffect:@"ping1.aiff" loop:NO];
        }];
        
        
        CCTVMenu *menu = [[CCTVMenu alloc] initWithArray:@[item1, item2, item3]];
        menu.position = CGPointZero;
        
        [self addChild:menu];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
