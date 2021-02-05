//
//  MetalView.h
//  Rampage
//
//  Created by Nick Lockwood on 03/02/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

#ifndef MetalView_h
#define MetalView_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

#include <simd/simd.h>

typedef NS_ENUM(NSInteger, BufferIndex) {
    BufferIndexMeshPositions = 0,
    BufferIndexUniforms      = 1
};

typedef NS_ENUM(NSInteger, VertexAttribute) {
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
    VertexAttributeColor     = 2
};

typedef NS_ENUM(NSInteger, TextureIndex) {
    TextureIndexColor    = 0,
};

typedef struct {
    matrix_float4x4 projectionMatrix;
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 orthoMatrix;
} Uniforms;

#endif /* MetalView_h */
