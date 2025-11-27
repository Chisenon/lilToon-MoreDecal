//----------------------------------------------------------------------------------------------------------------------
// Decal Processing
//----------------------------------------------------------------------------------------------------------------------

// Helper function to blend colors based on blend mode
float3 lilMoreDecalBlendColor(float3 baseColor, float3 decalColor, float alpha, uint blendMode)
{
    // 0:Normal 1:Add 2:Screen 3:Multiply
    if(blendMode == 0) return lerp(baseColor, decalColor, alpha);
    if(blendMode == 1) return baseColor + decalColor * alpha;
    if(blendMode == 2) return lerp(baseColor, 1.0 - (1.0 - baseColor) * (1.0 - decalColor), alpha);
    if(blendMode == 3) return lerp(baseColor, baseColor * decalColor, alpha);
    return lerp(baseColor, decalColor, alpha);
}

// Apply decal to color
void lilApplyDecal(
    inout lilFragData fd,
    float2 uv,
    bool useDecal,
    float4 decalColor,
    TEXTURE2D(decalTex),
    float4 decalTex_ST,
    float4 decalTex_SR,
    float decalTexAngle,
    float4 decalDecalAnimation,
    float4 decalDecalSubParam,
    bool decalIsDecal,
    bool decalIsLeftOnly,
    bool decalIsRightOnly,
    bool decalShouldCopy,
    bool decalShouldFlipMirror,
    bool decalShouldFlipCopy,
    uint decalBlendMode
    LIL_SAMP_IN_FUNC(samp))
{
    if(!useDecal) return;
    
    float4 decalSample = lilGetSubTex(
        decalTex,
        decalTex_ST,
        decalTex_SR,
        decalTexAngle,
        uv,
        fd.nv,
        decalIsDecal,
        decalIsLeftOnly,
        decalIsRightOnly,
        decalShouldCopy,
        decalShouldFlipMirror,
        decalShouldFlipCopy,
        false, // isMSDF
        fd.isRightHand,
        decalDecalAnimation,
        decalDecalSubParam
        LIL_SAMP_IN(samp));
    
    float3 decalCol = decalSample.rgb * decalColor.rgb;
    float decalAlpha = decalSample.a * decalColor.a;
    
    if(decalAlpha > 0.001)
    {
        fd.col.rgb = lilMoreDecalBlendColor(fd.col.rgb, decalCol, decalAlpha, decalBlendMode);
    }
}

// Insert decal processing after Main3rd (similar to DecalHeartRate)
#if !defined(BEFORE_MAIN3RD)
    #define BEFORE_MAIN3RD \
        if(_UseDecal1 && _DecalCount >= 1) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal1Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal1Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal1Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal1, \
                _Decal1Color, \
                _Decal1Tex, \
                _Decal1Tex_ST, \
                _Decal1Tex_SR, \
                _Decal1TexAngle, \
                _Decal1DecalAnimation, \
                _Decal1DecalSubParam, \
                _Decal1IsDecal, \
                _Decal1IsLeftOnly, \
                _Decal1IsRightOnly, \
                _Decal1ShouldCopy, \
                _Decal1ShouldFlipMirror, \
                _Decal1ShouldFlipCopy, \
                _Decal1BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal2 && _DecalCount >= 2) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal2Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal2Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal2Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal2, \
                _Decal2Color, \
                _Decal2Tex, \
                _Decal2Tex_ST, \
                _Decal2Tex_SR, \
                _Decal2TexAngle, \
                _Decal2DecalAnimation, \
                _Decal2DecalSubParam, \
                _Decal2IsDecal, \
                _Decal2IsLeftOnly, \
                _Decal2IsRightOnly, \
                _Decal2ShouldCopy, \
                _Decal2ShouldFlipMirror, \
                _Decal2ShouldFlipCopy, \
                _Decal2BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal3 && _DecalCount >= 3) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal3Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal3Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal3Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal3, \
                _Decal3Color, \
                _Decal3Tex, \
                _Decal3Tex_ST, \
                _Decal3Tex_SR, \
                _Decal3TexAngle, \
                _Decal3DecalAnimation, \
                _Decal3DecalSubParam, \
                _Decal3IsDecal, \
                _Decal3IsLeftOnly, \
                _Decal3IsRightOnly, \
                _Decal3ShouldCopy, \
                _Decal3ShouldFlipMirror, \
                _Decal3ShouldFlipCopy, \
                _Decal3BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal4 && _DecalCount >= 4) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal4Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal4Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal4Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal4, \
                _Decal4Color, \
                _Decal4Tex, \
                _Decal4Tex_ST, \
                _Decal4Tex_SR, \
                _Decal4TexAngle, \
                _Decal4DecalAnimation, \
                _Decal4DecalSubParam, \
                _Decal4IsDecal, \
                _Decal4IsLeftOnly, \
                _Decal4IsRightOnly, \
                _Decal4ShouldCopy, \
                _Decal4ShouldFlipMirror, \
                _Decal4ShouldFlipCopy, \
                _Decal4BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal5 && _DecalCount >= 5) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal5Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal5Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal5Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal5, \
                _Decal5Color, \
                _Decal5Tex, \
                _Decal5Tex_ST, \
                _Decal5Tex_SR, \
                _Decal5TexAngle, \
                _Decal5DecalAnimation, \
                _Decal5DecalSubParam, \
                _Decal5IsDecal, \
                _Decal5IsLeftOnly, \
                _Decal5IsRightOnly, \
                _Decal5ShouldCopy, \
                _Decal5ShouldFlipMirror, \
                _Decal5ShouldFlipCopy, \
                _Decal5BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal6 && _DecalCount >= 6) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal6Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal6Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal6Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal6, \
                _Decal6Color, \
                _Decal6Tex, \
                _Decal6Tex_ST, \
                _Decal6Tex_SR, \
                _Decal6TexAngle, \
                _Decal6DecalAnimation, \
                _Decal6DecalSubParam, \
                _Decal6IsDecal, \
                _Decal6IsLeftOnly, \
                _Decal6IsRightOnly, \
                _Decal6ShouldCopy, \
                _Decal6ShouldFlipMirror, \
                _Decal6ShouldFlipCopy, \
                _Decal6BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal7 && _DecalCount >= 7) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal7Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal7Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal7Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal7, \
                _Decal7Color, \
                _Decal7Tex, \
                _Decal7Tex_ST, \
                _Decal7Tex_SR, \
                _Decal7TexAngle, \
                _Decal7DecalAnimation, \
                _Decal7DecalSubParam, \
                _Decal7IsDecal, \
                _Decal7IsLeftOnly, \
                _Decal7IsRightOnly, \
                _Decal7ShouldCopy, \
                _Decal7ShouldFlipMirror, \
                _Decal7ShouldFlipCopy, \
                _Decal7BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal8 && _DecalCount >= 8) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal8Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal8Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal8Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal8, \
                _Decal8Color, \
                _Decal8Tex, \
                _Decal8Tex_ST, \
                _Decal8Tex_SR, \
                _Decal8TexAngle, \
                _Decal8DecalAnimation, \
                _Decal8DecalSubParam, \
                _Decal8IsDecal, \
                _Decal8IsLeftOnly, \
                _Decal8IsRightOnly, \
                _Decal8ShouldCopy, \
                _Decal8ShouldFlipMirror, \
                _Decal8ShouldFlipCopy, \
                _Decal8BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal9 && _DecalCount >= 9) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal9Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal9Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal9Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal9, \
                _Decal9Color, \
                _Decal9Tex, \
                _Decal9Tex_ST, \
                _Decal9Tex_SR, \
                _Decal9TexAngle, \
                _Decal9DecalAnimation, \
                _Decal9DecalSubParam, \
                _Decal9IsDecal, \
                _Decal9IsLeftOnly, \
                _Decal9IsRightOnly, \
                _Decal9ShouldCopy, \
                _Decal9ShouldFlipMirror, \
                _Decal9ShouldFlipCopy, \
                _Decal9BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        } \
        if(_UseDecal10 && _DecalCount >= 10) \
        { \
            float2 decalUV = fd.uv0; \
            if(_Decal10Tex_UVMode == 1) decalUV = fd.uv1; \
            if(_Decal10Tex_UVMode == 2) decalUV = fd.uv2; \
            if(_Decal10Tex_UVMode == 3) decalUV = fd.uv3; \
            lilApplyDecal( \
                fd, \
                decalUV, \
                _UseDecal10, \
                _Decal10Color, \
                _Decal10Tex, \
                _Decal10Tex_ST, \
                _Decal10Tex_SR, \
                _Decal10TexAngle, \
                _Decal10DecalAnimation, \
                _Decal10DecalSubParam, \
                _Decal10IsDecal, \
                _Decal10IsLeftOnly, \
                _Decal10IsRightOnly, \
                _Decal10ShouldCopy, \
                _Decal10ShouldFlipMirror, \
                _Decal10ShouldFlipCopy, \
                _Decal10BlendMode \
                LIL_SAMP_IN(sampler_DecalTex)); \
        }
#endif