//
//  triangle.metal
//  MetalRenderKit
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct MRKVertex
{
    float4 position [[position]];
    float4 color;
};

vertex MRKVertex triangle_vertex_main(device MRKVertex *ver)



