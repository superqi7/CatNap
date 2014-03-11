//
//  SKSpriteNode+DebugDraw.h
//  CatNap
//
//  Created by Xiaoqi Liu on 3/5/14.
//  Copyright (c) 2014 Xiaoqi Liu. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKSpriteNode (DebugDraw)

-(void)attachDebugRectWithSize:(CGSize)s;
-(void)attachDebugFrameFromPath:(CGPathRef)bodyPath;
@end
