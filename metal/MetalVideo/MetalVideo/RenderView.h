//
//  RenderView.h
//  MetalVideo
//
//  Created by 陈耀武 on 2020/8/20.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RenderView : UIView

-(void)renderRGBAWith:(uint8_t*)RGBBuffer width:(int)width height:(int)height;
-(void)renderNV12With:(uint8_t*)yBuffer uvBuffer:(uint8_t*)uvBuffer width:(int)width height:(int)height;
@end

NS_ASSUME_NONNULL_END
