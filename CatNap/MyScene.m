//
//  MyScene.m
//  CatNap
//
//  Created by Xiaoqi Liu on 3/5/14.
//  Copyright (c) 2014 Xiaoqi Liu. All rights reserved.
//
#import "SKTAudio.h"
#import "MyScene.h"
#import "SKSpriteNode+DebugDraw.h"

typedef NS_OPTIONS(uint32_t, CNPhysicsCategory) {
    CNPhysicsCategoryCat = 1 << 0,
    CNPhysicsCategoryBlock  = 1 << 1,
    CNPhysicsCategoryBed = 1 << 2,
    CNPhysicsCategoryEdge = 1 << 3,
    CNPhysicsCategoryLabel = 1 << 4,
};

@interface MyScene()<SKPhysicsContactDelegate>
@end


@implementation MyScene
{
    SKNode *_gameNode;
    SKSpriteNode *_catNode;
    SKSpriteNode *_bedNode;
    
    int _currentLevel;
    
    
}

-(instancetype)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        [self initializeScene];
    }
    return self;
}

-(void)initializeScene
{
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsWorld.contactDelegate = self;
    self.physicsBody.categoryBitMask = CNPhysicsCategoryEdge;
    
    SKSpriteNode* bg = [SKSpriteNode spriteNodeWithImageNamed:@"background"];
    bg.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:bg];
    [self addCatBed];
    
    _gameNode = [SKNode node];
    [self addChild:_gameNode];
    
    _currentLevel = 1;
    [self setupLevel:_currentLevel];
}

-(void)addCatBed
{
    _bedNode = [SKSpriteNode spriteNodeWithImageNamed:@"cat_bed"];
    _bedNode.position = CGPointMake(270, 15);
   
    CGSize contactSize = CGSizeMake(40, 30);
    _bedNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:contactSize];
    _bedNode.physicsBody.dynamic = NO;
    [_bedNode attachDebugRectWithSize:contactSize];
    _bedNode.physicsBody.categoryBitMask = CNPhysicsCategoryBed;
     [self addChild:_bedNode];
}

-(void)addCatAtPosition:(CGPoint)pos
{
    _catNode = [SKSpriteNode spriteNodeWithImageNamed:@"cat_sleepy"];
    _catNode.position = pos;
    
    CGSize contactSize = CGSizeMake(_catNode.size.width-40, _catNode.size.height-10);
    
    _catNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:contactSize];
    [_catNode attachDebugRectWithSize:contactSize];
    _catNode.physicsBody.categoryBitMask = CNPhysicsCategoryCat;
    [_gameNode addChild:_catNode];
    _catNode.physicsBody.contactTestBitMask = CNPhysicsCategoryBed | CNPhysicsCategoryEdge;
    _catNode.physicsBody.collisionBitMask = CNPhysicsCategoryBlock | CNPhysicsCategoryEdge;
}

-(void)setupLevel:(int)levelNum
{
    NSString *fileName = [NSString stringWithFormat:@"level%i",levelNum];
    NSString *filePath = [[NSBundle mainBundle]pathForResource:fileName ofType:@"plist"];
    NSDictionary *level = [NSDictionary dictionaryWithContentsOfFile:filePath];
    [[SKTAudio sharedInstance] playBackgroundMusic:@"bgMusic.mp3"];
    [self addCatAtPosition:CGPointFromString(level[@"catPosition"])];
    [self addBlocksFromArray:level[@"blocks"]];
}

-(void)addBlocksFromArray:(NSArray*)blocks
{
    for (NSDictionary *block in blocks) {
        SKSpriteNode *blockSprite =
        [self addBlockWithRect:CGRectFromString(block[@"rect"])];
        
        blockSprite.physicsBody.categoryBitMask = CNPhysicsCategoryBlock;
        blockSprite.physicsBody.collisionBitMask = CNPhysicsCategoryBlock | CNPhysicsCategoryCat | CNPhysicsCategoryEdge;
        
        [_gameNode addChild:blockSprite];
    }
}

-(SKSpriteNode*)addBlockWithRect:(CGRect)blockRect
{
    NSString *textureName = [NSString stringWithFormat:@"%.fx%.f.png",blockRect.size.width,blockRect.size.height];
    
    SKSpriteNode *blockSprite = [SKSpriteNode spriteNodeWithImageNamed:textureName];
    blockSprite.position = blockRect.origin;
    
    CGRect bodyRect = CGRectInset(blockRect, 2, 2);
    blockSprite.physicsBody =[SKPhysicsBody bodyWithRectangleOfSize:bodyRect.size];
     
     [blockSprite attachDebugRectWithSize:blockSprite.size];
     
     return blockSprite;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    [self.physicsWorld enumerateBodiesAtPoint:location usingBlock:^(SKPhysicsBody *body, BOOL *stop) {
        if (body.categoryBitMask == CNPhysicsCategoryBlock) {
            [body.node removeFromParent];
            *stop = YES;
            
            [self runAction:[SKAction playSoundFileNamed:@"pop.mp3" waitForCompletion:NO]];
        }
    }];
}

-(void)didBeginContact:(SKPhysicsContact *)contact
{
    uint32_t collision = (contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask);
    
    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryBed)) {
        [self win];
    }
    if (collision == (CNPhysicsCategoryCat | CNPhysicsCategoryEdge)) {
        [self lose];
    }
    if (collision == (CNPhysicsCategoryLabel | CNPhysicsCategoryEdge)) {
        SKLabelNode *label = (contact.bodyA.categoryBitMask == CNPhysicsCategoryLabel)?(SKLabelNode*)contact.bodyA.node:(SKLabelNode*)contact.bodyB.node;
        
        if (label.userData==nil) {
            label.userData = [@{@"bounceCount":@0} mutableCopy];
        }
        
        int newBounceCount = [label.userData[@"bounceCount"] intValue]+1;
        NSLog(@"bounce: %i", newBounceCount);
        if (newBounceCount==4) {
            [label removeFromParent];
        } else {
            label.userData = [@{@"bounceCount":@(newBounceCount)} mutableCopy];
        }
        
    }
}

-(void)inGameMessage:(NSString*)text
{
    SKLabelNode *label = [SKLabelNode labelNodeWithFontNamed:@"AvenirNext-Regular"];
    label.text = text;
    label.fontSize = 64.0;
    label.color = [SKColor whiteColor];
    
    label.position = CGPointMake(self.frame.size.width/2, self.frame.size.height -10);
    
    label.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:10];
    label.physicsBody.collisionBitMask = CNPhysicsCategoryEdge;
    label.physicsBody.categoryBitMask = CNPhysicsCategoryLabel;
    label.physicsBody.contactTestBitMask = CNPhysicsCategoryEdge;
    label.physicsBody.restitution = 0.7;
    
    [_gameNode addChild:label];
    
//    [label runAction:[SKAction sequence:@[[SKAction waitForDuration:3.0],[SKAction removeFromParent]]]];
}

-(void)newGame
{
    [_gameNode removeAllChildren];
    [self setupLevel:_currentLevel];
    [self inGameMessage:[NSString stringWithFormat:@"Level %i",_currentLevel]];
}

-(void)lose
{
    _catNode.physicsBody.contactTestBitMask = 0;
    [_catNode setTexture:[SKTexture textureWithImageNamed:@"cat_awake"]];
    
    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:[SKAction playSoundFileNamed:@"lose.mp3" waitForCompletion:NO]];
    
    [self inGameMessage:@"Try again ..."];
    
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:5.0],[SKAction performSelector:@selector(newGame) onTarget:self]]]];
}
-(void)win
{
    _catNode.physicsBody = nil;
    
    CGFloat curlY = _bedNode.position.y+_catNode.size.height/2;
    CGPoint curlPoint = CGPointMake(_bedNode.position.x, curlY);
    
    [_catNode runAction:[SKAction group:@[[SKAction moveTo:curlPoint duration:0.66],[SKAction rotateToAngle:0 duration:0.5]]]];
    
    [self inGameMessage:@"Good job!"];
    
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:5.0],[SKAction performSelector:@selector(newGame) onTarget:self]]]];
    
    [_catNode runAction:[SKAction animateWithTextures:@[[SKTexture textureWithImageNamed:@"cat_curlup1"],[SKTexture textureWithImageNamed:@"cat_curlup2"],[SKTexture textureWithImageNamed:@"cat_curlup3"]] timePerFrame:0.25]];
    
    [[SKTAudio sharedInstance] pauseBackgroundMusic];
    [self runAction:[SKAction playSoundFileNamed:@"win.mp3" waitForCompletion:NO]];
    
    
}

@end

