//
//  YYImageShaderTypes.h
//  MetalImage
//
//  Created by 陈耀武 on 2020/8/19.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#ifndef YYImageShaderTypes_h
#define YYImageShaderTypes_h

// 这个simd.h文件里有一些桥接的数据类型
//#include <simd/simd.h>

// 存储数据的自定义结构，用于桥接OC和Metal代码
// YYVertex结构体类型

typedef struct {
    // 顶点坐标 4维向量
    vector_float4 position;
    
    // 纹理坐标
    vector_float2 textureCoordinate;
    
} YYVertex;


// 自定义枚举，用于桥接OC和Metal代码
// 顶点的桥接枚举值 YYImageVertexInputIndexVertexs
typedef enum {
    
    YYImageVertexInputIndexVertexs = 0,
    
} YYImageVertexInputIndex;


// 纹理的桥接枚举值 YYImageTextureIndexBaseTexture
typedef enum {
    
    YYImageTextureIndexBaseTexture = 0,
    
} YYImageTextureIndex;

#endif /* YYImageShaderTypes_h */
