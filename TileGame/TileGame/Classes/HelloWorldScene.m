//
//  HelloWorldScene.m
//  TileGame
//
//  Created by Tracy on 14-7-29.
//  Copyright DD 2014年. All rights reserved.
//
// -----------------------------------------------------------------------

#import "HelloWorldScene.h"
#import "IntroScene.h"
#import "OALSimpleAudio.h"

// At top of file
@implementation HelloWorldHud

-(id) init
{
    if ((self = [super init])) {
        CGSize winSize = [[CCDirector sharedDirector] viewSize];
        label = [CCLabelTTF labelWithString:@"0" fontName:@"Verdana-Bold" fontSize:18];
        label.color = [CCColor colorWithRed:0 green:0 blue:0 alpha:1];
        int margin = 10;
        label.position = ccp(winSize.width - (label.contentSize.width/2)
                             - margin, label.contentSize.height/2 + margin);
        [self addChild:label];
    }
    return self;
}

- (void)numCollectedChanged:(int)numCollected {
    [label setString:[NSString stringWithFormat:@"%d", numCollected]];
}

@end

// -----------------------------------------------------------------------
#pragma mark - HelloWorldScene
// -----------------------------------------------------------------------

@implementation HelloWorldScene {
    CCSprite *_sprite;
    int totalNumber;
}

// -----------------------------------------------------------------------
#pragma mark - Create & Destroy
// -----------------------------------------------------------------------

+ (HelloWorldScene *)scene
{
    HelloWorldScene *scene = [[self alloc] init];
    HelloWorldHud *hud = [HelloWorldHud node];
    [scene addChild: hud];
    scene.hud = hud;
    return scene;
}

- (id)init
{
    // Apple recommend assigning self with supers return value
    self = [super init];
    if (!self) return(nil);
    
    [[OALSimpleAudio sharedInstance] preloadEffect:@"pickup.caf"];
    [[OALSimpleAudio sharedInstance] preloadEffect:@"hit.caf"];
    [[OALSimpleAudio sharedInstance] preloadEffect:@"move.caf"];
    [[OALSimpleAudio sharedInstance] playBg:@"TileMap.caf" loop:YES];
    
    // Enable touch handling on scene node
    self.userInteractionEnabled = YES;
    

    
    _tileMap = [CCTiledMap tiledMapWithFile:@"TileMap.tmx"];
    _background = [_tileMap layerNamed:@"Background"];
    _meta = [_tileMap layerNamed:@"Meta"];
    _foreground = [_tileMap layerNamed:@"Foreground"];
    _meta.visible = NO;
    
    // 扩大Scene的区域 以便于扩大点击响应区域
    self.contentSize = _tileMap.contentSize;
    _moveScene = [[CCScene alloc] init];
    _moveScene.color = [CCColor colorWithRed:155 green:155 blue:155 alpha:1];
    [self addChild:_moveScene];
    _moveScene.contentSize = _tileMap.contentSize;
    
    
    [_moveScene addChild:_tileMap z:-1];
    

    
    CCTiledMapObjectGroup *objects = [_tileMap objectGroupNamed:@"Objects"];
    NSAssert(objects != nil, @"Objects group not found");
    NSMutableDictionary *spawnPoint = [objects objectNamed:@"SpawnPoint"];
    int x = [[spawnPoint objectForKey:@"x"] intValue];
    int y = [[spawnPoint objectForKey:@"y"] intValue];
    
    self.player = [CCSprite spriteWithImageNamed:@"Player.png"];
    _player.position = ccp(x, y);
    [_moveScene addChild:_player];
    
    [self setViewpointCenter:_player.position];
    
    // done
	return self;
}

// -----------------------------------------------------------------------

- (CGPoint)tileCoordForPosition:(CGPoint)position {
    int x = position.x / _tileMap.tileSize.width;
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x, y);
}

-(void)setViewpointCenter:(CGPoint) position {
    
    CGSize winSize = [[CCDirector sharedDirector] viewSize];
    
    int x = MAX(position.x, winSize.width / 2);
    int y = MAX(position.y, winSize.height / 2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width)
            - winSize.width / 2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height)
            - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    _moveScene.position = viewPoint;
}

// -----------------------------------------------------------------------

- (void)dealloc
{
    // clean up code goes here
}

// -----------------------------------------------------------------------
#pragma mark - Enter & Exit
// -----------------------------------------------------------------------

- (void)onEnter
{
    // always call super onEnter first
    [super onEnter];

    // In pre-v3, touch enable and scheduleUpdate was called here
    // In v3, touch is enabled by setting userInteractionEnabled for the individual nodes
    // Per frame update is automatically enabled, if update is overridden
    
}

// -----------------------------------------------------------------------

- (void)onExit
{
    // always call super onExit last
    [super onExit];
}

- (void)numCollectedChanged:(int)numCollected {

}

// -----------------------------------------------------------------------
#pragma mark - Touch Handler
// -----------------------------------------------------------------------

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{

}

-(void)setPlayerPosition:(CGPoint)position {
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];
    if (tileGid) {
        NSDictionary *properties = [_tileMap propertiesForGID:tileGid];
        if (properties) {
            NSString *collision = [properties valueForKey:@"Collidable"];
            if (collision && [collision compare:@"True"] == NSOrderedSame) {
                [[OALSimpleAudio sharedInstance] playEffect:@"hit.caf"];
                return;
            }
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame) {
                [[OALSimpleAudio sharedInstance] playEffect:@"pickup.caf"];
                self.numCollected++;
                [_hud numCollectedChanged:_numCollected];
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
            }
        }
    }
    [[OALSimpleAudio sharedInstance] playEffect:@"move.caf"];
    _player.position = position;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    
    CGPoint touchLocation = [touch locationInView: [touch view]];
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    touchLocation = [_moveScene convertToNodeSpace:touchLocation];
    
    CGPoint playerPos = _player.position;
    CGPoint diff = ccpSub(touchLocation, playerPos);
    if (abs(diff.x) > abs(diff.y)) {
        if (diff.x > 0) {
            playerPos.x += _tileMap.tileSize.width;
        } else {
            playerPos.x -= _tileMap.tileSize.width;
        }
    } else {
        if (diff.y > 0) {
            playerPos.y += _tileMap.tileSize.height;
        } else {
            playerPos.y -= _tileMap.tileSize.height;
        }
    }
    
    if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
        playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
        playerPos.y >= 0 &&
        playerPos.x >= 0 )
    {
        [self setPlayerPosition:playerPos];
    }
    
    [self setViewpointCenter:_player.position];
    
}

// -----------------------------------------------------------------------
#pragma mark - Button Callbacks
// -----------------------------------------------------------------------

- (void)onBackClicked:(id)sender
{
    // back to intro scene with transition
    [[CCDirector sharedDirector] replaceScene:[IntroScene scene]
                               withTransition:[CCTransition transitionPushWithDirection:CCTransitionDirectionRight duration:1.0f]];
}

// -----------------------------------------------------------------------
@end
