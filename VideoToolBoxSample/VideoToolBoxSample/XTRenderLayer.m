//
//  XTRenderLayer.m
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/4.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XTRenderLayer.h"
#import <UIKit/UIScreen.h>
#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import <AVFoundation/AVUtilities.h>
enum {
    UNIFORM_Y,
    UNIFORM_UV,
    UNIFORM_ROTATION_ANGLE,
    UNIFORM_COLOR_CONVERSION_MATRIX,
    NUM_UNIFORMS
};

GLint uniforms[NUM_UNIFORMS];

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
    NUM_ATTRIBUTES,
};

// Color Conversion Constants (YUV to RGB) including adjustment from 16-235/16-240 (video range)

// BT.601, which is the standard for SDTV.
static const GLfloat kColorConversion601[] = {
    1.164,  1.164, 1.164,
    0.0, -0.392, 2.017,
    1.596, -0.813,   0.0,
};

// BT.709, which is the standard for HDTV.
static const GLfloat kColorConversion709[] = {
    1.164,  1.164, 1.164,
    0.0, -0.213, 2.112,
    1.793, -0.533,   0.0,
};

@interface XTRenderLayer () {
    GLint  _backingWidth;
    GLint  _backingHeight;
    
    EAGLContext *_context;
    CVOpenGLESTextureRef _lumaTexture;
    CVOpenGLESTextureRef _chromaTexture;
    
    GLuint _frameBufferHandle;
    GLuint _colorBufferHandle;
    
    const GLfloat *_preferredConversion;
    
}

@property (nonatomic, assign) GLuint program;

@end

@implementation XTRenderLayer

@synthesize pixelBuffer = _pixelBuffer;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        CGFloat scale = [[UIScreen mainScreen] scale];
        self.contentsScale = scale;
        
        self.opaque = YES;
        self.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@(YES)};
        
        self.frame = frame;
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (_context == nil) {
            return nil;
        }
        
        _preferredConversion = kColorConversion709;
        
        [self setupGL];
    }
    return self;
    
}

- (void)setupBuffers{
    glDisable(GL_DEPTH_TEST);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(GLfloat), 0);
    
    [self createBuffers];
}
- (void)createBuffers{
    glGenBuffers(1, &_frameBufferHandle);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    
    glGenRenderbuffers(1, &_colorBufferHandle);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorBufferHandle);
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)releaseBuffers {
    if (_frameBufferHandle) {
        glDeleteBuffers(1, &_frameBufferHandle);
        _frameBufferHandle = 0;
    }
    
    if (_colorBufferHandle) {
        glDeleteBuffers(1, &_colorBufferHandle);
        _colorBufferHandle = 0;
    }
}

const GLchar *shader_fsh = (const GLchar*)"varying highp vec2 texCoordVarying;"
"precision mediump float;"
"uniform sampler2D SamplerY;"
"uniform sampler2D SamplerUV;"
"uniform mat3 colorConversionMatrix;"
"void main()"
"{"
"    mediump vec3 yuv;"
"    lowp vec3 rgb;"
//   Subtract constants to map the video range start at 0
"    yuv.x = (texture2D(SamplerY, texCoordVarying).r - (16.0/250.0));"
"    yuv.yz = (texture2D(SamplerUV, texCoordVarying).rg - vec2(0.5, 0.5));"
"    rgb = colorConversionMatrix * yuv;"
"    gl_FragColor = vec4(rgb, 1);"
"}";

const GLchar *shader_vsh = (const GLchar*)"attribute vec4 position;"
"attribute vec2 texCoord;"
"uniform float preferredRotation;"
"varying vec2 texCoordVarying;"
"void main()"
"{"
"    mat4 rotationMatrix = mat4(cos(preferredRotation), -sin(preferredRotation), 0.0, 0.0,"
"                               sin(preferredRotation),  cos(preferredRotation), 0.0, 0.0,"
"                               0.0,                        0.0, 1.0, 0.0,"
"                               0.0,                        0.0, 0.0, 1.0);"
"    gl_Position = position * rotationMatrix;"
"    texCoordVarying = texCoord;"
"}";


- (BOOL)loadShaders{
    GLuint verShader = 0, fragShader = 0;
    
    _program = glCreateProgram();
    if (![self compileShaderString:&verShader type:GL_VERTEX_SHADER shaderString:shader_vsh]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    if (![self compileShaderString:&fragShader type:GL_FRAGMENT_SHADER shaderString:shader_fsh]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    glAttachShader(_program, verShader);
    glAttachShader(_program, fragShader);
    
    glBindAttribLocation(_program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "texCoord");
    
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (verShader) {
            glDeleteShader(verShader);
            verShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        return NO;
    }
    
    uniforms[UNIFORM_Y] = glGetUniformLocation(_program, "SamplerY");
    uniforms[UNIFORM_UV] = glGetUniformLocation(_program, "SamplerUV");
    uniforms[UNIFORM_ROTATION_ANGLE] = glGetUniformLocation(_program, "preferredRotation");
    uniforms[UNIFORM_COLOR_CONVERSION_MATRIX] = glGetUniformLocation(_program, "colorConversionMatrix");
    
    if (verShader) {
        glDeleteShader(verShader);
        verShader = 0;
    }
    
    if (fragShader) {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    return YES;
    
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)compileShaderString:(GLuint *)shader type:(GLenum)type shaderString:(const GLchar*)shaderString
{
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &shaderString, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    GLint status = 0;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}
- (void)setupGL {
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        return;
    }
    
    [self setupBuffers];
    [self loadShaders];
    
    glUseProgram(self.program);
    glUniform1i(uniforms[UNIFORM_Y], 0);
    glUniform1i(uniforms[UNIFORM_UV], 1);
    glUniform1f(uniforms[UNIFORM_ROTATION_ANGLE], 0);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
}

- (CVPixelBufferRef)pixelBuffer {
    return _pixelBuffer;
}

- (void) resetRenderBuffer
{
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        return;
    }
    
    [self releaseBuffers];
    [self createBuffers];
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_pixelBuffer) {
        CVPixelBufferRelease(pixelBuffer);
    }
    
    _pixelBuffer = CVPixelBufferRetain(pixelBuffer);
    
    int frameWidth =(int)CVPixelBufferGetWidth(_pixelBuffer);
    int frameHeight =(int)CVPixelBufferGetHeight(_pixelBuffer);
    [self displayPixelBuffer:_pixelBuffer width:frameWidth height:frameHeight];
    
}
- (void)displayPixelBuffer:(CVPixelBufferRef)pixelBuffer width:(uint32_t)frameWidth height:(uint32_t)frameHeigh {
    if (!_context || ![EAGLContext setCurrentContext:_context]) {
        return;
    }
    
    if(pixelBuffer == NULL) {
        NSLog(@"Pixel buffer is null");
        return;
    }
    CVReturn err;
    
    size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);
    
    if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0)) {
        _preferredConversion = kColorConversion601;
    } else {
        _preferredConversion = kColorConversion709;
    }
    
    CVOpenGLESTextureCacheRef _videoTextureCache;
    err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_videoTextureCache);
    
    if (err != noErr) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        return;
    }
    
    glActiveTexture(GL_TEXTURE0);
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _videoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RED_EXT, frameWidth, frameHeigh, GL_RED_EXT, GL_UNSIGNED_BYTE, 0, &_lumaTexture);
    
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    glBindTexture(CVOpenGLESTextureGetTarget(_lumaTexture), CVOpenGLESTextureGetName(_lumaTexture));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    if(planeCount == 2) {
        glActiveTexture(GL_TEXTURE1);
        
        err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
        _videoTextureCache,
        pixelBuffer,
        NULL,
        GL_TEXTURE_2D,
        GL_RG_EXT,
        frameWidth / 2,
        frameHeigh / 2,
        GL_RG_EXT,
        GL_UNSIGNED_BYTE,
        1,
        &_chromaTexture);
        
        if (err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        }
        
        glBindTexture(CVOpenGLESTextureGetTarget(_chromaTexture), CVOpenGLESTextureGetName(_chromaTexture));
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBufferHandle);
    glViewport(0, 0, _backingWidth, _backingHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(self.program);
    glUniform1f(uniforms[UNIFORM_ROTATION_ANGLE], 0);
    glUniformMatrix3fv(uniforms[UNIFORM_COLOR_CONVERSION_MATRIX], 1, GL_FALSE, _preferredConversion);
    
    CGRect viewBounds = self.bounds;
    CGSize contentSize = CGSizeMake(frameWidth, frameHeigh);
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(contentSize, viewBounds);
    
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/viewBounds.size.width,
                                        vertexSamplingRect.size.height/viewBounds.size.height);
    // Normalize the quad vertices.
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = cropScaleAmount.width/cropScaleAmount.height;
        normalizedSamplingSize.height = 1.0;;
    }
    
    /*
     The quad vertex data defines the region of 2D plane onto which we draw our pixel buffers.
     Vertex data formed using (-1,-1) and (1,1) as the bottom left and top right coordinates respectively, covers the entire screen.
     */
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    
    // Update attribute values.
       glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, quadVertexData);
       glEnableVertexAttribArray(ATTRIB_VERTEX);
    
    /*
     The texture vertices are set up such that we flip the texture vertically. This is so that our top left origin buffers match OpenGL's bottom left texture coordinate system.
     */
    CGRect textureSamplingRect = CGRectMake(0, 0, 1, 1);
    GLfloat quadTextureData[] =  {
        CGRectGetMinX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMaxY(textureSamplingRect),
        CGRectGetMinX(textureSamplingRect), CGRectGetMinY(textureSamplingRect),
        CGRectGetMaxX(textureSamplingRect), CGRectGetMinY(textureSamplingRect)
    };
    
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
       glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferHandle);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
    [self cleanUpTextures];
    // Periodic texture cache flush every frame
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    
    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
    }
}

- (void) cleanUpTextures
{
    if (_lumaTexture) {
        CFRelease(_lumaTexture);
        _lumaTexture = NULL;
    }
    
    if (_chromaTexture) {
        CFRelease(_chromaTexture);
        _chromaTexture = NULL;
    }
}

@end
