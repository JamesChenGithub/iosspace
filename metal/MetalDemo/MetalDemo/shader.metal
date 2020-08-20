//
//  shader.metal
//  MetalDemo
//
//  Created by 陈耀武 on 2020/8/18.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 basic_vertext(constant packed_float3* vertext_array[[buffer(0)]], unsigned int vid[[vertex_id]])
{
    return float4(vertext_array[vid], 1.0);
}

fragment float4 basic_fragment() {
    return float4(0.5, 1.0, 0.5, 0.2);
}

