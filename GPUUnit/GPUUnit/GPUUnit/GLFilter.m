//
//  GLFilter.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/28.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLFilter.h"
#import <AVFoundation/AVFoundation.h>
// Hardcode the vertex shader for standard filters, but this can be overridden
NSString *const kGLVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE

NSString *const kGLPassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

#else
NSString *const kGLPassthroughFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);
#endif

@implementation GLFilter

- (instancetype)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString {
    if (self = [super init]) {
        _uniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];
        _preventRendering = NO;
        _currentlyReceivingMonochromeInput = NO;
        _inputRotation = kGLNoRotation;
        _backgroundColorRed = 0.0f;
        _backgroundColorGreen = 0.0f;
        _backgroundColorBlue = 0.0f;
        _backgroundColorAlpha = 0.0f;
        _imageCaptureSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_imageCaptureSemaphore);
        
        runSynchronouslyOnVideoProcessingQueue(^{
            [GLContext useImageProcessingContext];
            self->_filterProgram = [[GLContext sharedImageProcessingContext] programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
            
            if (self->_filterProgram.initialized) {
                [self initializeAttributes];
                
                if (![self->_filterProgram link]) {
                    NSString *progLog = [self->_filterProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [self->_filterProgram fragShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [self->_filterProgram vertShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    self->_filterProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            self->_filterPositionAttribute = [self->_filterProgram attributeIndex:@"position"];
            self->_filterTextureCoordinateAttribute = [self->_filterProgram attributeIndex:@"inputTextureCoordinate"];
            self->_filterInputTextureUniform = [self->_filterProgram attributeIndex:@"inputImageTexture"];
            
            [GLContext setActiveShaderProgram:self->_filterProgram];
            
            glEnableVertexAttribArray(self->_filterPositionAttribute);
            glEnableVertexAttribArray(self->_filterTextureCoordinateAttribute);
            
        });
        
    }
    return self;
}

- (instancetype)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename {
    NSString *fragmentShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderFilename ofType:@"fsh"];
       NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragmentShaderPathname encoding:NSUTF8StringEncoding error:nil];
    return [self initWithVertexShaderFromString:kGLVertexShaderString fragmentShaderFromString:fragmentShaderString];
}

- (instancetype)initWithFragmentShaderFromString:(NSString *)fragmentShaderString {
    
    return [self initWithVertexShaderFromString:kGLVertexShaderString fragmentShaderFromString:fragmentShaderString];
}

- (instancetype)init {
    return [self initWithVertexShaderFromString:kGLVertexShaderString fragmentShaderFromString:kGLPassthroughFragmentShaderString];
}

- (void)initializeAttributes {
    [_filterProgram addAttribute:@"position"];
    [_filterProgram addAttribute:@"inputTextureCoordinate"];
}

- (void)setupFilterForSize:(CGSize)filterFrameSize {
    
}

- (void)dealloc {
#if !OS_OBJECT_USE_OBJC
    if (imageCaptureSemaphore != NULL) {
        dispatch_release(_imageCaptureSemaphore);
    }
#endif
}

- (void)useNextFrameForImageCapture {
    _usingNextFrameForImageCapture = YES;

    // Set the semaphore high, if it isn't already
    if (dispatch_semaphore_wait(_imageCaptureSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
}

- (CGImageRef)newCGImageFromCurrentlyProcessedOutput {
    double timeoutForImageCapture = 3.0;
    dispatch_time_t convertTimeout = dispatch_time(DISPATCH_TIME_NOW, timeoutForImageCapture * NSEC_PER_SEC);
    
    if (dispatch_semaphore_wait(_imageCaptureSemaphore, convertTimeout) != 0) {
        return NULL;
    }
    
    GLFrameBuffer *frameBuf = [self frameBufferOutput];
    _usingNextFrameForImageCapture = NO;
    dispatch_semaphore_signal(_imageCaptureSemaphore);
    CGImageRef img = [frameBuf newCGImageFromFramebufferContents];
    return img;
}

- (CGSize)sizeOfFBO {
    CGSize outputSize = [self maximumOutputSize];
    if (CGSizeEqualToSize(outputSize, CGSizeZero) || _inputTextureSize.width < outputSize.width) {
        return _inputTextureSize;
    } else {
        return outputSize;
    }
}

+ (const GLfloat *)textureCoordinatesForRotation:(GLRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode)
    {
        case kGLNoRotation: return noRotationTextureCoordinates;
        case kGLRotateLeft: return rotateLeftTextureCoordinates;
        case kGLRotateRight: return rotateRightTextureCoordinates;
        case kGLFlipVertical: return verticalFlipTextureCoordinates;
        case kGLFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kGLRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kGLRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kGLRotate180: return rotate180TextureCoordinates;
    }
}


- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    if (self.preventRendering) {
        [_firstInputFramebuffer unlock];
        return;
    }
    
    [GLContext setActiveShaderProgram:_filterProgram];
    _outputFrameBuffer = [[GLContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [_outputFrameBuffer activateFramebuffer];
    
    if (_usingNextFrameForImageCapture) {
        [_outputFrameBuffer lock];
    }
    
    [self setUniformsForProgramAtIndex:0];
    
    glClearColor(_backgroundColorRed, _backgroundColorGreen, _backgroundColorBlue, _backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [_firstInputFramebuffer texture]);
    
    glUniform1i(_filterInputTextureUniform, 2);
    glVertexAttribPointer(_filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(_filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [_firstInputFramebuffer unlock];
    
    if (_usingNextFrameForImageCapture) {
        dispatch_semaphore_signal(_imageCaptureSemaphore);
    }
    
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime {
    
    if (!self.frameProcessingCompletionBlock) {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    for (id<GLInput> currentTarget in _targets) {
        NSInteger indexOfObject = [_targets indexOfObject:currentTarget];
        NSInteger textureIndex = [[_targetTextureIndices objectAtIndex:indexOfObject] integerValue];

        [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
        [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
    }
    
    [[self frameBufferOutput] unlock];
    
    if (_usingNextFrameForImageCapture) {
        
    }else {
        [self removeOutputFrameBuffer];
    }
    
    for (id<GLInput> currentTarget in _targets) {
        if (currentTarget != self.targetToIgnoreForUpdates) {
            NSInteger indexOfObject = [_targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[_targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}


- (void)setInputFramebufferForTarget:(id<GLInput>)target atIndex:(NSInteger)inputTextureIndex;
{
    [target setInputFramebuffer:[self frameBufferOutput] atIndex:inputTextureIndex];
}

- (CGSize)outputFrameSize {
    return _inputTextureSize;
}

- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent {
    _backgroundColorRed = redComponent;
    _backgroundColorGreen = greenComponent;
    _backgroundColorBlue = blueComponent;
    _backgroundColorAlpha = alphaComponent;
}

- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName {
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setInteger:newInteger forUniform:uniformIndex program:_filterProgram];
}

- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName {
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setFloat:newFloat forUniform:uniformIndex program:_filterProgram];
}
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setSize:newSize forUniform:uniformIndex program:_filterProgram];
}

- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setPoint:newPoint forUniform:uniformIndex program:_filterProgram];
}

- (void)setFloatVec3:(GPUVector3)newVec3 forUniformName:(NSString *)uniformName;
{
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setVec3:newVec3 forUniform:uniformIndex program:_filterProgram];
}

- (void)setFloatVec4:(GPUVector4)newVec4 forUniform:(NSString *)uniformName;
{
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    [self setVec4:newVec4 forUniform:uniformIndex program:_filterProgram];
}

- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName
{
    GLint uniformIndex = [_filterProgram uniformIndex:uniformName];
    
    [self setFloatArray:array length:count forUniform:uniformIndex program:_filterProgram];
}


- (void)setMatrix3f:(GPUMatrix3x3)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix3fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setMatrix4f:(GPUMatrix4x4)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniformMatrix4fv(uniform, 1, GL_FALSE, (GLfloat *)&matrix);
        }];
    });
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1f(uniform, floatValue);
        }];
    });
}

- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat positionArray[2];
            positionArray[0] = pointValue.x;
            positionArray[1] = pointValue.y;
            
            glUniform2fv(uniform, 1, positionArray);
        }];
    });
}

- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            GLfloat sizeArray[2];
            sizeArray[0] = sizeValue.width;
            sizeArray[1] = sizeValue.height;
            
            glUniform2fv(uniform, 1, sizeArray);
        }];
    });
}

- (void)setVec3:(GPUVector3)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform3fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setVec4:(GPUVector4)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform4fv(uniform, 1, (GLfloat *)&vectorValue);
        }];
    });
}

- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    // Make a copy of the data, so it doesn't get overwritten before async call executes
    NSData* arrayData = [NSData dataWithBytes:arrayValue length:arrayLength * sizeof(arrayValue[0])];

    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1fv(uniform, arrayLength, [arrayData bytes]);
        }];
    });
}

- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
{
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];

        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1i(uniform, intValue);
        }];
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
{
    if (uniformStateBlock) {
    [_uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    uniformStateBlock();
    }
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [_uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_block_t currentBlock = obj;
        currentBlock();
    }];
}


#pragma mark -
#pragma mark GPUImageInput

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
{
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:_inputRotation]];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (NSInteger)nextAvailableTextureIndex;
{
    return 0;
}

- (void)setInputFramebuffer:(GLFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
{
    _firstInputFramebuffer = newInputFramebuffer;
    [_firstInputFramebuffer lock];
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
{
    CGSize rotatedSize = sizeToRotate;
    
    if (GPUUnitRotationSwapsWidthAndHeight(_inputRotation))
    {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize;
}

- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(GLRotationMode)rotation;
{
    CGPoint rotatedPoint;
    switch(rotation)
    {
        case kGLNoRotation: return pointToRotate; break;
        case kGLFlipHorizonal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = pointToRotate.y;
        }; break;
        case kGLFlipVertical:
        {
            rotatedPoint.x = pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
        case kGLRotateLeft:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGLRotateRight:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGLRotateRightFlipVertical:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGLRotateRightFlipHorizontal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGLRotate180:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
    }
    
    return rotatedPoint;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
{
    if (self.preventRendering)
    {
        return;
    }
    
    if (_overrideInputSize)
    {
        if (CGSizeEqualToSize(_forcedMaximumSize, CGSizeZero))
        {
        }
        else
        {
            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, _forcedMaximumSize.width, _forcedMaximumSize.height));
            _inputTextureSize = insetRect.size;
        }
    }
    else
    {
        CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
        
        if (CGSizeEqualToSize(rotatedSize, CGSizeZero))
        {
            _inputTextureSize = rotatedSize;
        }
        else if (!CGSizeEqualToSize(_inputTextureSize, rotatedSize))
        {
            _inputTextureSize = rotatedSize;
        }
    }
    
    [self setupFilterForSize:[self sizeOfFBO]];
}

- (void)setInputRotation:(GLRotationMode)newInputRotation atIndex:(NSInteger)textureIndex
{
    _inputRotation = newInputRotation;
}

- (void)forceProcessingAtSize:(CGSize)frameSize
{
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        _overrideInputSize = NO;
    }
    else
    {
        _overrideInputSize = YES;
        _inputTextureSize = frameSize;
        _forcedMaximumSize = CGSizeZero;
    }
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;
{
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        _overrideInputSize = NO;
        _inputTextureSize = CGSizeZero;
        _forcedMaximumSize = CGSizeZero;
    }
    else
    {
        _overrideInputSize = YES;
        _forcedMaximumSize = frameSize;
    }
}

- (CGSize)maximumOutputSize;
{
    // I'm temporarily disabling adjustments for smaller output sizes until I figure out how to make this work better
    return CGSizeZero;

    /*
    if (CGSizeEqualToSize(cachedMaximumOutputSize, CGSizeZero))
    {
        for (id<GPUImageInput> currentTarget in targets)
        {
            if ([currentTarget maximumOutputSize].width > cachedMaximumOutputSize.width)
            {
                cachedMaximumOutputSize = [currentTarget maximumOutputSize];
            }
        }
    }
    
    return cachedMaximumOutputSize;
     */
}

- (void)endProcessing
{
    if (!_isEndProcessing)
    {
        _isEndProcessing = YES;
        
        for (id<GLInput> currentTarget in _targets)
        {
            [currentTarget endProcessing];
        }
    }
}

- (BOOL)wantsMonochromeInput;
{
    return NO;
}

#pragma mark -
#pragma mark Accessors



@end
