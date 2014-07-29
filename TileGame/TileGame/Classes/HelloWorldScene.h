//
//  HelloWorldScene.h
//  TileGame
//
//  Created by Tracy on 14-7-29.
//  Copyright DD 2014年. All rights reserved.
//
// -----------------------------------------------------------------------

// Importing cocos2d.h and cocos2d-ui.h, will import anything you need to start using Cocos2D v3
#import "cocos2d.h"
#import "cocos2d-ui.h"
#import "CCTiledMap.h"

// Before HelloWorld class declaration
@interface HelloWorldHud : CCScene
{
    CCLabelTTF *label;
}

- (void)numCollectedChanged:(int)numCollected;
@end
// -----------------------------------------------------------------------

/**
 *  The main scene
 */
@interface HelloWorldScene : CCScene {
    CCTiledMap *_tileMap;
    CCTiledMapLayer *_background;
}
@property (nonatomic, strong) CCSprite *player;

@property (nonatomic, strong) CCTiledMapLayer *meta;

@property (nonatomic, strong) CCTiledMapLayer *foreground;

@property (nonatomic, assign) int numCollected;
@property (nonatomic, strong) HelloWorldHud *hud;

@property (nonatomic, strong) CCScene *moveScene;
// -----------------------------------------------------------------------

+ (HelloWorldScene *)scene;
- (id)init;

// -----------------------------------------------------------------------
@end