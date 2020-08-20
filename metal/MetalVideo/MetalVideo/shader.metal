//
//  shader.metal
//  MetalVideo
//
//  Created by 陈耀武 on 2020/8/20.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut
{
    float4 position [[position]];
    float2 textureCoordinate;
};
vertex VertexOut texture_vertex (
    constant float4*vertex_array[[buffer(0)]],
    constant float2*textureCoord_array[[buffer(1)]],
    unsigned int vid[[vertex_id]]){

    VertexOut outputVertices;

    outputVertices.position = vertex_array[vid];
    outputVertices.textureCoordinate = textureCoord_array[vid];

    return outputVertices;
}

fragment float4 texture_fragment(VertexOut fragmentInput [[stage_in]],
                                 texture2d<float> inputTexture [[texture(0)]]) {
    constexpr sampler quadSampler;
    float4 color = inputTexture.sample(quadSampler, fragmentInput.textureCoordinate);

    return color;
}

fragment float4 nv12_fragment(VertexOut fragmentInput [[stage_in]],
                              texture2d<float> textureY [[texture(0)]],
                               texture2d<float> textureUV [[texture(1)]]) {
    constexpr sampler quadSampler;
    
    float y = textureY.sample(quadSampler,fragmentInput.textureCoordinate).r;
    float u = textureUV.sample(quadSampler, fragmentInput.textureCoordinate).r - 0.5;
    float v = textureUV.sample(quadSampler, fragmentInput.textureCoordinate).a - 0.5;
    
    float r = y +             1.400 * v;
    float g = y - 0.343 * u - 0.711 * v;
    float b = y + 1.765 * u;
    
    float4 color = float4(r,g,b,1.0);
    
    return color;
}
