//----------------------------------------------------------------------------------------------------------------------
// Decal Processing
//----------------------------------------------------------------------------------------------------------------------

// Helper function to rotate 2D vector
float2 lilMoreDecalRotate2D(float2 v, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float2(v.x * c - v.y * s, v.x * s + v.y * c);
}

// Inverse affine transform: applies translate, rotate, scale in reverse order
// This allows rotation center to follow position while preserving aspect ratio
float2 lilMoreDecalInvAffineTransform(float2 uv, float2 translate, float angle, float2 scale)
{
    scale = max(scale, float2(0.001, 0.001));
    return lilMoreDecalRotate2D(uv - 0.5 - translate, -angle) / scale + 0.5;
}

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

// Custom decal UV calculation using inverse affine transform
// This approach allows rotation center to follow Position X/Y while preserving aspect ratio
float2 lilMoreDecalCalcUV(
    float2 uv,
    float4 uv_ST,
    float angle,
    bool isLeftOnly,
    bool isRightOnly,
    bool shouldCopy,
    bool shouldFlipMirror,
    bool shouldFlipCopy,
    bool isRightHand)
{
    float2 outUV = uv;

    // Copy (same as lilCalcDecalUV)
    if(shouldCopy) outUV.x = abs(outUV.x - 0.5) + 0.5;

    // Convert uv_ST to translate and scale
    // uv_ST.xy = scale (inverted: 1/displayScale)
    // uv_ST.zw = offset (calculated: -posX*scaleX+0.5)
    // We need to extract: translate (position) and scale (1/uv_ST.xy)
    float2 scale = float2(1.0, 1.0) / max(abs(uv_ST.xy), float2(0.001, 0.001));
    float2 translate = (float2(0.5, 0.5) - uv_ST.zw) / uv_ST.xy;
    
    // Apply inverse affine transform: translate → rotate → scale
    outUV = lilMoreDecalInvAffineTransform(outUV, translate, angle, scale);

    // Flip (same as lilCalcDecalUV)
    if(shouldFlipCopy && uv.x < 0.5) outUV.x = 1.0 - outUV.x;
    if(shouldFlipMirror && isRightHand) outUV.x = 1.0 - outUV.x;

    // Hide (same as lilCalcDecalUV)
    if(isLeftOnly && isRightHand) outUV.x = -1.0;
    if(isRightOnly && !isRightHand) outUV.x = -1.0;

    return outUV;
}

// Apply decal to color
void lilApplyDecal(
    inout lilFragData fd,
    float2 uv,
    bool useDecal,
    float4 decalColor,
    TEXTURE2D(decalTex),
    float4 decalTex_ST,
    float decalTexAngle,
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
    
    // Calculate UV with custom rotation (around texture center)
    float2 decalUV = lilMoreDecalCalcUV(
        uv,
        decalTex_ST,
        decalTexAngle,
        decalIsLeftOnly,
        decalIsRightOnly,
        decalShouldCopy,
        decalShouldFlipMirror,
        decalShouldFlipCopy,
        fd.isRightHand);
    
    // Sample texture
    float4 decalSample = LIL_SAMPLE_2D(decalTex, samp, decalUV);
    
    // Apply decal masking if enabled
    if(decalIsDecal)
    {
        // Check if UV is in 0-1 range (with small tolerance based on normal view)
        float mask = saturate(0.5 - abs(decalUV.x - 0.5));
        mask *= saturate(0.5 - abs(decalUV.y - 0.5));
        mask = saturate(mask / clamp(fwidth(mask), 0.0001, saturate(fd.nv - 0.05)));
        decalSample.a *= mask;
    }
    
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
                _Decal1TexAngle, \
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
                _Decal2TexAngle, \
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
                _Decal3TexAngle, \
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
                _Decal4TexAngle, \
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
                _Decal5TexAngle, \
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
                _Decal6TexAngle, \
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
                _Decal7TexAngle, \
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
                _Decal8TexAngle, \
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
                _Decal9TexAngle, \
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
                _Decal10TexAngle, \
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