//
//  sharder.metal
//  MetalImage
//
//  Created by 陈耀武 on 2020/8/19.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#include <metal_stdlib>
#import "YYImageShaderTypes.h"
using namespace metal;

// 定义了一个类型为RasterizerData的结构体，里面有一个float4向量和float2向量，其中float4被[[position]]修饰，其表示的变量为顶点

typedef struct {
    // float4 4维向量 clipSpacePosition参数名
    // position 修饰符的表示顶点 语法是[[position]]，这是苹果内置的语法和position关键字不能改变
    float4 clipSpacePosition [[position]];
    
    // float2 2维向量  表示纹理
    float2 textureCoordinate;
    
} RasterizerData;

// 顶点函数通过一个自定义的结构体，返回对应的数据，顶点函数的输入参数也可以是自定义结构体

// 顶点函数
// vertex 函数修饰符表示顶点函数，
// RasterizerData返回值类型，
// vertexImageShader函数名
// vertex_id 顶点id修饰符，苹果内置不可变，[[vertex_id]]
// buffer 缓存数据修饰符，苹果内置不可变，YYImageVertexInputIndexVertexs是索引
// [[buffer(YYImageVertexInputIndexVertexs)]]
// constant 变量类型修饰符，表示存储在device区域

vertex RasterizerData vertexImageShader(uint vertexID [[vertex_id]], constant YYVertex * vertexArray [[buffer(YYImageVertexInputIndexVertexs)]]) {
    
    RasterizerData outData;
    
    // 获取YYVertex里面的顶点坐标和纹理坐标
    outData.clipSpacePosition = vertexArray[vertexID].position;
    outData.textureCoordinate = vertexArray[vertexID].textureCoordinate;
    
    return outData;
}

// 片元函数
// fragment 函数修饰符表示片元函数 float4 返回值类型->颜色RGBA fragmentImageShader 函数名
// RasterizerData 参数类型 input 变量名
// [[stage_in] stage_in表示这个数据来自光栅化。（光栅化是顶点处理之后的步骤，业务层无法修改）
// texture2d 类型表示纹理 baseTexture 变量名
// [[ texture(index)]] 纹理修饰符
// 可以加索引 [[ texture(0)]]纹理0， [[ texture(1)]]纹理1
// YYImageTextureIndexBaseTexture表示纹理索引

fragment float4 fragmentImageShader(RasterizerData input [[stage_in]], texture2d<half> baseTexture [[ texture (YYImageTextureIndexBaseTexture) ]]) {
    
    // constexpr 修饰符
    // sampler 采样器
    // textureSampler 采样器变量名
    // mag_filter:: linear, min_filter:: linear 设置放大缩小过滤方式
    constexpr sampler textureSampler(mag_filter:: linear, min_filter:: linear);
    
    // 得到纹理对应位置的颜色
    half4 color = baseTexture.sample(textureSampler, input.textureCoordinate);
    
    // 返回颜色值
    return float4(color);
}
