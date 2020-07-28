//
//  GLRenderView.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/28.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLRenderView.h"
#import "GLOutput.h"
#import <OpenGLES/EAGLDrawable.h>
#import <QuartzCore/QuartzCore.h>
#import "GLContext.h"
#import <AVFoundation/AVFoundation.h>

@interface GLRenderView () {
    
    GLFrameBuffer       *_inputFramebufferForDisplay;
    GLuint              _displayRenderbuffer;
    GLuint              _displayFramebuffer;
    
    GLProgram           *_displayProgram;
    GLint               _displayPositionAttribute;
    GLint               _displayTextureCoordinateAttribute;
    GLint               _displayInputTextureUniform;
    
    
    CGSize              _inputImageSize;
    GLfloat             _imageVertices[8];
    
    GLfloat             _backgroundColorRed;
    GLfloat             _backgroundColorGreen;
    GLfloat             _backgroundColorBlue;
    GLfloat             _backgroundColorAlpha;
    
    CGSize              _boundsSizeAtFrameBufferEpoch;
    
}

@property (nonatomic, assign) NSUInteger aspectRatio;
@property (nonatomic, assign) CGSize sizeInPixels;

- (void)commonInit;


- (void)createDisplayFramebuffer;
- (void)destroyDisplayFramebuffer;


- (void)recalculateViewGeometry;

@end

@implementation GLRenderView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    _inputRotation = kGLNoRotation;
    
    self.opaque = YES;
    self.hidden = NO;
    
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:@(NO),kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
    self.enabled = YES;
    
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        
//        _displayProgram = GP
    });
    
}

@end
