//
//  MetalImageFilterView.m
//  MetalImage
//
//  Created by 陈耀武 on 2020/8/19.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "MetalImageFilterView.h"
#import <MetalKit/MetalKit.h>
#import <AVFoundation/AVFoundation.h>
#import "YYImageShaderTypes.h"

@interface MetalImageFilterView ()<MTKViewDelegate> {
    
    BOOL isChangeFillMode;
    CGSize imageSize;
    
}

@property (nonatomic, assign) vector_int2 viewportSize;

@property (nonatomic, strong) MTKView *mtkView;

@property (nonatomic, strong) id<MTLDevice> device;

@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@property (nonatomic, strong) id<MTLBuffer> vertexBuffer;

@property (nonatomic, strong) id<MTLTexture> texture;

@property (nonatomic, assign) NSUInteger vertexCount;





@end

@implementation MetalImageFilterView


- (void)createMTKView{
    MTKView *mtkView = [[MTKView alloc] initWithFrame:self.bounds];
    mtkView.delegate = self;
    mtkView.device = MTLCreateSystemDefaultDevice();
    self.device = mtkView.device;
    
    self.viewportSize = (vector_int2){mtkView.drawableSize.width, mtkView.drawableSize.height};
    self.mtkView = mtkView;
    [self addSubview:mtkView];
}

// 2.设置顶点
- (void)setupVertexs {
    // 1.顶点纹理数组
    // 顶点x,y,z,w  纹理x,y
//    YYVertex vertexArray[] = {
//        {{-1.0 * widthScaling, -1.0 * heightScaling, 0.0, 1.0}, {0.0, 0.0}},
//        {{1.0 * widthScaling, -1.0 * heightScaling, 0.0, 1.0}, {1.0, 0.0}},
//        {{-1.0 * widthScaling, 1.0 * heightScaling, 0.0, 1.0}, {0.0, 1.0}}, //左上
//        {{1.0 * widthScaling, 1.0 * heightScaling, 0.0, 1.0}, {1.0, 1.0}}, // 右上
//    };
    YYVertex vertexArray[] = {
        {{-1.0, -1.0, 0.0, 1.0}, {0.0, 0.0}}, // 左下
        {{1.0, -1.0, 0.0, 1.0}, {1.0, 0.0}}, // 右下
        {{-1.0, 1.0, 0.0, 1.0}, {0.0, 1.0}}, //左上
        {{1.0, 1.0, 0.0, 1.0}, {1.0, 1.0}}, // 右上
    };
    
    // 2.生成顶点缓存
    // MTLResourceStorageModeShared 属性可共享的，表示可以被顶点或者片元函数或者其他函数使用
    self.vertexBuffer = [self.device newBufferWithBytes:vertexArray length:sizeof(vertexArray) options:MTLResourceStorageModeShared];
    
    // 3.获取顶点数量
    self.vertexCount = sizeof(vertexArray) / sizeof(YYVertex);
}

// 图片加载为二进制数据
- (Byte *)loadImage:(UIImage *)image {
    CGImageRef spriteImage = image.CGImage;
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    Byte * spriteData = (Byte *)calloc(width * height * 4, sizeof(Byte));
    
    CGContextRef context = CGBitmapContextCreate(spriteData, width, height, 8, width *4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 纹理翻转
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), spriteImage);
    CFRelease(context);
    
    return spriteData;
}

- (void)setupTexture {
    UIImage * image = [UIImage imageNamed:@"container.png"];
    
    // 1.创建纹理描述符
    MTLTextureDescriptor * textureDescriptor = [[MTLTextureDescriptor alloc] init];
    // 设置纹理描述符的宽，高，像素存储格式
    textureDescriptor.width = image.size.width;
    textureDescriptor.height = image.size.height;
    imageSize = image.size;
    //MTLPixelFormatRGBA8Unorm 表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1)
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    
    // 2.创建纹理对象
    id <MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    self.texture = texture;
    // id <MTLDevice> -> id <MTLTexture>
    
    // 3.将图片数据读取到纹理对象内
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {{0, 0, 0}, {image.size.width, image.size.height, 1}};
    
    // 图片的二进制数据 UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
    Byte * imageBytes = [self loadImage:image];
    
    // 将图片数据读取到纹理对象内
    // region 纹理区域
    // 0 mip贴图层次
    // imageBytes 图片二进制数据
    // image.size.width * 4 每一行字节数
    if (imageBytes) {
        [self.texture replaceRegion:region mipmapLevel:0 withBytes:imageBytes bytesPerRow:image.size.width * 4];
    }
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self createMTKView];
        
       // 1.创建 MTKView
        [self createMTKView];
        
        // 2.设置顶点 1.0和1.0表示宽高保持默认的拉伸状态，不去动态调整
        [self setupVertexs];
        
        // 3.设置纹理
        [self setupTexture];
        
        // 4.创建渲染管道
        [self createPipeLineState];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        
         [self createMTKView];
         
        // 1.创建 MTKView
         [self createMTKView];
         
         // 2.设置顶点 1.0和1.0表示宽高保持默认的拉伸状态，不去动态调整
         [self setupVertexs];
         
         // 3.设置纹理
         [self setupTexture];
         
         // 4.创建渲染管道
         [self createPipeLineState];
    }
    return self;
}

// 4.创建渲染管道
// 根据.metal里的函数名，使用MTLLibrary创建顶点函数和片元函数
// 从这里可以看出来，MTLLibrary里面包含所有.metal的文件，所以，不同的.metal里面的函数名不能相同
// id <MTLDevice> 创建library、MTLRenderPipelineState、MTLCommandQueue
- (void)createPipeLineState {
    
    // 1.从项目中加载.metal文件，创建一个library
    id <MTLLibrary> library = [self.device newDefaultLibrary];
    // id <MTLDevice> -> id <MTLLibrary>
    
    // 2.从库中MTLLibrary，加载顶点函数
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexImageShader"];
    
    // 3.从库中MTLLibrary，加载顶点函数
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentImageShader"];
    
    // 4.创建管道渲染管道描述符
    MTLRenderPipelineDescriptor * renderPipeDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    // 5.设置管道顶点函数和片元函数
    renderPipeDescriptor.vertexFunction = vertexFunction;
    renderPipeDescriptor.fragmentFunction = fragmentFunction;
    
    // 6.设置管道描述的关联颜色存储方式
    renderPipeDescriptor.colorAttachments[0].pixelFormat = self.mtkView.colorPixelFormat;

    NSError * error = nil;
    // 7.根据渲染管道描述符 创建渲染管道
    id <MTLRenderPipelineState> renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipeDescriptor error:&error];
    self.renderPipelineState = renderPipelineState;
    // id <MTLDevice> -> id <MTLRenderPipelineState>
    
    // 8. 创建渲染指令队列
    id <MTLCommandQueue> commondQueue = [self.device newCommandQueue];
    self.commandQueue = commondQueue;
    // id <MTLDevice> -> id <MTLCommandQueue>
}

- (void)setFillMode:(kMetalImageFilterViewFillModeType)fillMode {
    isChangeFillMode = YES;
    _fillMode = fillMode;
    [self resetVertexWithWidth:imageSize.width height:imageSize.height];
    isChangeFillMode = NO;
}

- (void)resetVertexWithWidth:(CGFloat)width height:(CGFloat)height  {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGSize inputImageSize = CGSizeMake(width, height);
        CGFloat heightScaling = 1.0, widthScaling = 1.0;
        CGSize currentViewSize = self.bounds.size;
        
        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(inputImageSize, self.bounds);
        switch(self.fillMode)
        {
            case kMetalImageFilterViewFillModeStretch:
                
            {
                widthScaling = 1.0;
                heightScaling = 1.0;
            };
                break;
                
            case kMetalImageFilterViewFillModePreserveAspectRatio:
            {
                widthScaling = insetRect.size.width / currentViewSize.width;
                heightScaling = insetRect.size.height / currentViewSize.height;
            };
                break;
                
            case kMetalImageFilterViewFillModePreserveAspectRatioAndFill:
            {
                widthScaling = currentViewSize.height / insetRect.size.height;
                heightScaling = currentViewSize.width / insetRect.size.width;
            };
                break;
        }
        
        //        NSLog(@"widthScaling == %lf", widthScaling);
        //        NSLog(@"heightScaling == %lf", heightScaling);
        [self setupVertexsWithWidthScaling:widthScaling heightScaling:heightScaling];
    });
}

- (void)setupVertexsWithWidthScaling:(CGFloat)widthScaling heightScaling:(CGFloat)heightScaling {
    // 1.顶点纹理数组
    // 顶点x,y,z,w  纹理x,y
    // 因为图片和视频的默认纹理是反的 左上 00 右上10 左下 01 右下11
    // // 左下 右下
//    //定义顶点坐标
//    float[] coordinate = new float[]{
//        -1.0f, -1.0f,     //左下角坐标
//         1.0f, -1.0f,     //右下角坐标
//        -1.0f,  1.0f,     //左上角坐标
//         1.0f,  1.0f      //右上角坐标
//    }
//    float[] TEXTURE_NO_ROTATION[] = {
//            0.0f, 1.0f,//左上角
//            1.0f, 1.0f,//右上角
//            0.0f, 0.0f,//左下角
//            1.0f, 0.0f,//右下角
//    };
    YYVertex vertexArray[] = {
        {{-1.0 * widthScaling, -1.0 * heightScaling, 0.0, 1.0}, {0.0, 0.0}},
        {{1.0 * widthScaling, -1.0 * heightScaling, 0.0, 1.0}, {1.0, 0.0}},
        {{-1.0 * widthScaling, 1.0 * heightScaling, 0.0, 1.0}, {0.0, 1.0}}, //左上
        {{1.0 * widthScaling, 1.0 * heightScaling, 0.0, 1.0}, {1.0, 1.0}}, // 右上
    };
    
    // 2.生成顶点缓存
    // MTLResourceStorageModeShared 属性可共享的，表示可以被顶点或者片元函数或者其他函数使用
    self.vertexBuffer = [self.device newBufferWithBytes:vertexArray length:sizeof(vertexArray) options:MTLResourceStorageModeShared];
    
    // 3.获取顶点数量
    self.vertexCount = sizeof(vertexArray) / sizeof(YYVertex);
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size{
    self.viewportSize = (vector_int2){size.width, size.height};
}

/*!
 @method drawInMTKView:
 @abstract Called on the delegate when it is asked to render into the view
 @discussion Called on the delegate when it is asked to render into the view
 */
// MTKViewDelegate
- (void)drawInMTKView:(nonnull MTKView *)view {
    // 1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    
    //指定缓存区名称
    commandBuffer.label = @"EachCommand";
    
    // 2.获取渲染命令编码器 MTLRenderCommandEncoder的描述符
    // currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    MTLRenderPassDescriptor * renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        // 设置默认颜色 背景色
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0f);
        
        // 3.根据描述创建x 渲染命令编码器
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
//        typedef struct {
//            double originX, originY, width, height, znear, zfar;
//        } MTLViewport;
        // 4.设置绘制区域
        [renderEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0}];
        
        // 5.设置渲染管道
        [renderEncoder setRenderPipelineState:self.renderPipelineState];
        
        // 6.传递顶点缓存
        [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:YYImageVertexInputIndexVertexs];
        
        // 7.传递纹理缓存
        [renderEncoder setFragmentTexture:self.texture atIndex:YYImageTextureIndexBaseTexture];
        
        // 8.绘制
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:self.vertexCount];
        
        // 9.命令结束
        [renderEncoder endEncoding];
        
        // 10.显示
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    // 11. 提交
    [commandBuffer commit];
}
@end
