//
//  GLRenderView.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/28.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "GLContext.h"

typedef NS_ENUM(NSUInteger, GLRenderFillModeType) {
    kGLRenderFillModeStretch,                       // Stretch to fill the full view, which may distort the image outside of its normal aspect ratio
    kGLRenderFillModePreserveAspectRatio,           // Maintains the aspect ratio of the source image, adding bars of the specified background color
    kGLRenderFillModePreserveAspectRatioAndFill     // Maintains the aspect ratio of the source image, zooming in on its center to fill the view
};

@interface GLRenderView : UIView<GLInput> {
    GLRotationMode  _inputRotation;
}

@property (nonatomic, assign) GLRenderFillModeType fillMode;
@property (nonatomic, readonly) CGSize sizeInPixels;
@property (nonatomic, assign) BOOL enabled;


- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;

@end


