//
//  GLProgram.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#else
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#endif


@interface GLProgram : NSObject
{
    NSMutableArray  *_attributes;
    NSMutableArray  *_uniforms;
    GLuint          _program;
    GLuint          _vertShader;
    GLuint          _fragShader;
}

@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, copy) NSString *vertShaderLog;
@property (nonatomic, copy) NSString *fragShaderLog;
@property (nonatomic, copy) NSString *programLog;


- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString;
- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderFilename:(NSString *)fShaderFilename;
- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename;
- (void)addAttribute:(NSString *)attributeName;
- (GLuint)attributeIndex:(NSString *)attributeName;
- (GLuint)uniformIndex:(NSString *)uniformName;
- (BOOL)link;
- (void)use;
- (void)validate;


@end


