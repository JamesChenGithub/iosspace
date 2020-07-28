//
//  GLFilter.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/28.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLOutput.h"
#import "GLContext.h"
#import "GLFrameBuffer.h"
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#endif

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#define GLHashIdentifier #
#define GLWrappedLabel(x) x
#define GPEscapedHashIdentifier(a) GLWrappedLabel(GLHashIdentifier)a

extern NSString *const kGPUImageVertexShaderString;
extern NSString *const kGPUImagePassthroughFragmentShaderString;

typedef struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
}GPUVector4;

typedef struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
}GPUMatrix4x4;

typedef struct GPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
}GPUVector3;

typedef struct GPUMatrix3x3 {
    GPUVector3 one;
    GPUVector3 two;
    GPUVector3 three;
}GPUMatrix3x3;


@interface GLFilter : GLOutput<GLInput> {
    GLFrameBuffer   *_firstInputFramebuffer;
    GLProgram       *_filterProgram;
    GLint            _filterPositionAttribute;
    GLint            _filterTextureCoordinateAttribute;
    GLint            _filterInputTextureUniform;
    
    GLfloat         _backgroundColorRed;
    GLfloat         _backgroundColorGreen;
    GLfloat         _backgroundColorBlue;
    GLfloat         _backgroundColorAlpha;
    
    BOOL            _isEndProcessing;
    CGSize          _currentFilterSize;
    GLRotationMode  _inputRotation;
    BOOL            _currentlyReceivingMonochromeInput;
    NSMutableDictionary *_uniformStateRestorationBlocks;
    dispatch_semaphore_t _imageCaptureSemaphore;
}

@property(nonatomic, readonly) CVPixelBufferRef renderTarget;
@property(nonatomic, assign) BOOL preventRendering;
@property(nonatomic, assign) BOOL currentlyReceivingMonochromeInput;

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithFragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithFragmentShaderFromFile:(NSString *)fragmentShaderFilename;
- (void)initializeAttributes;
- (void)setupFilterForSize:(CGSize)filterFrameSize;
- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex;
- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(GLRotationMode)rotation;

- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(GLRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime;
- (CGSize)outputFrameSize;

/// @name Input parameters
- (void)setBackgroundColorRed:(GLfloat)redComponent green:(GLfloat)greenComponent blue:(GLfloat)blueComponent alpha:(GLfloat)alphaComponent;
- (void)setInteger:(GLint)newInteger forUniformName:(NSString *)uniformName;
- (void)setFloat:(GLfloat)newFloat forUniformName:(NSString *)uniformName;
- (void)setSize:(CGSize)newSize forUniformName:(NSString *)uniformName;
- (void)setPoint:(CGPoint)newPoint forUniformName:(NSString *)uniformName;
- (void)setFloatVec3:(GPUVector3)newVec3 forUniformName:(NSString *)uniformName;
- (void)setFloatVec4:(GPUVector4)newVec4 forUniform:(NSString *)uniformName;
- (void)setFloatArray:(GLfloat *)array length:(GLsizei)count forUniform:(NSString*)uniformName;

- (void)setMatrix3f:(GPUMatrix3x3)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setMatrix4f:(GPUMatrix4x4)matrix forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setPoint:(CGPoint)pointValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setSize:(CGSize)sizeValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setVec3:(GPUVector3)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setVec4:(GPUVector4)vectorValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setFloatArray:(GLfloat *)arrayValue length:(GLsizei)arrayLength forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setInteger:(GLint)intValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;


@end


