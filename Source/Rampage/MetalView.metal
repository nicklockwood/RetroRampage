//
//  Shaders.metal
//  Rampage
//
//  Created by Nick Lockwood on 03/02/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "MetalView.h"

using namespace metal;

typedef struct {
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
    uchar4 color [[attribute(VertexAttributeColor)]];
} Vertex;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
    uchar4 color;
} ColorInOut;

vertex ColorInOut vertexShader(
    device const Vertex *in [[buffer(BufferIndexMeshPositions)]],
    constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
    const uint vid [[vertex_id]]
) {
    ColorInOut out;

    float4 position = float4(in[vid].position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in[vid].texCoord;
    out.color = in[vid].color;

    return out;
}

vertex ColorInOut orthoVertexShader(
    device const Vertex *in [[buffer(BufferIndexMeshPositions)]],
    constant Uniforms & uniforms [[buffer(BufferIndexUniforms)]],
    const uint vid [[vertex_id]]
) {
    ColorInOut out;

    float4 position = float4(in[vid].position, 1.0);
    out.position = uniforms.orthoMatrix * position;
    out.texCoord = in[vid].texCoord;
    out.color = in[vid].color;

    return out;
}

constexpr sampler colorSampler(mip_filter::linear,
                               mag_filter::nearest,
                               min_filter::linear);

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               texture2d<half> colorMap [[texture(TextureIndexColor)]]) {
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy);
    return float4(colorSample) * float4(in.color) / 255;
}

fragment float4 effectFragmentShader(ColorInOut in [[stage_in]]) {
    return float4(in.color) / 255;
}

fragment float4 fizzleFragmentShader(ColorInOut in [[stage_in]],
                                     texture2d<half> colorMap [[texture(TextureIndexColor)]]) {
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord);
    float4 colorIn = float4(in.color) / 255;
    return colorSample.a * 0.99 < colorIn.a ? float4(colorIn.rgb, 1.0) : float4(0);
}
