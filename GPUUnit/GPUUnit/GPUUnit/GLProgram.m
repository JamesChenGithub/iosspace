//
//  GLProgram.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLProgram.h"

typedef void (*GLInfoBlock) (GLuint program, GLenum pname, GLint *params);
typedef void (*GLLogBlock) (GLuint program, GLsizei bufsize, GLsizei* length, GLchar* infolog);

@interface GLProgram ()

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString;

@end

@implementation GLProgram

- (void)dealloc
{
    if (_vertShader) {
        glDeleteShader(_vertShader);
        _vertShader = 0;
    }
    
    if (_fragShader) {
        glDeleteShader(_fragShader);
        _fragShader = 0;
    }
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString {
    if (self = [super init]) {
        _initialized = NO;
        _attributes = [[NSMutableArray alloc] init];
        _uniforms = [[NSMutableArray alloc] init];
        _program = glCreateProgram();
        
        if (![self compileShader:&_vertShader type:GL_VERTEX_SHADER string:vShaderString]) {
            NSLog(@"Failed to compile vertex shader");
        }
        
        if (![self compileShader:&_fragShader type:GL_FRAGMENT_SHADER string:fShaderString]) {
            NSLog(@"Failed to compile vertex shader");
        }
        
        glAttachShader(_program, _vertShader);
        glAttachShader(_program, _fragShader);
    }
    return self;
}
- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderFilename:(NSString *)fShaderFilename {
    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];
    return [self initWithVertexShaderString:vShaderString fragmentShaderString:fragmentShaderString];
}
- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename {
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vShaderFilename ofType:@"vsh"];
    NSString *vertexShaderString = [NSString stringWithContentsOfFile:vertShaderPathname encoding:NSUTF8StringEncoding error:nil];

    NSString *fragShaderPathname = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];

    return [self initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
}


- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString {
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (source == NULL) {
        NSLog(@"failed to load %d shader", type);
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLen;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLen);
        if (logLen > 0) {
            GLchar *log = (GLchar *)malloc(logLen);
            glGetShaderInfoLog(*shader, logLen, &logLen, log);
            if (shader == &_vertShader) {
                self.vertShaderLog = [NSString stringWithFormat:@"%s", log];
            } else {
                self.fragShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            
            free(log);
        }
    }
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Compiled in %f ms", linkTime * 1000.0);
    return status == GL_TRUE;
}


- (void)addAttribute:(NSString *)attributeName{
    if (![_attributes containsObject:attributeName]) {
        [_attributes addObject:attributeName];
        GLuint indx = (GLuint)[_attributes indexOfObject:attributeName];
        const GLchar *name = (GLchar *)[attributeName UTF8String];
        glBindAttribLocation(_program, indx, name);
    }
}
- (GLuint)attributeIndex:(NSString *)attributeName {
    GLuint indx = (GLuint)[_attributes indexOfObject:attributeName];
    return indx;
}
- (GLuint)uniformIndex:(NSString *)uniformName {
    GLuint indx = glGetUniformLocation(_program, uniformName.UTF8String);
    return indx;
}
- (BOOL)link {
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    GLint status;
    
    glLinkProgram(_program);
    glGetProgramiv(_program, GL_LINK_STATUS, &status);
    
    if (status == GL_FALSE) {
        CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
        NSLog(@"Linked in %f ms", linkTime * 1000.0);
        return NO;
    }
    
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    NSLog(@"Linked in %f ms", linkTime * 1000.0);
    
    if (_vertShader) {
        glDeleteShader(_vertShader);
        _vertShader = 0;
    }
    
    if (_fragShader) {
        glDeleteShader(_fragShader);
        _fragShader = 0;
    }
    self.initialized = YES;
    return TRUE;
}
- (void)use {
    glUseProgram(_program);
}
- (void)validate {
    GLint length;
    glValidateProgram(_program);
    glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &length);
    if (length > 0) {
        GLchar *log = (GLchar *)malloc(length);
        glGetShaderInfoLog(_program, length, &length, log);
        _programLog = [NSString stringWithFormat:@"%s", log];
        free(log);
    }
}

@end
