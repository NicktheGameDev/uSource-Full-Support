// Define macros for missing values
#define NORM_DECODE_NONE 0
#define NORM_DECODE_ATI2N 1
#define NORM_DECODE_ATI2N_ALPHA 2

#define TCOMBINE_RGB_EQUALS_BASE_x_DETAILx2 0
#define TCOMBINE_RGB_ADDITIVE 1
#define TCOMBINE_DETAIL_OVER_BASE 2
#define TCOMBINE_FADE 3
#define TCOMBINE_BASE_OVER_DETAIL 4
#define TCOMBINE_MULTIPLY 8
#define TCOMBINE_MASK_BASE_BY_DETAIL_ALPHA 9
#define TCOMBINE_SSBUMP_NOBUMP 11

// Lightmap decoding
inline float3 SourceDecodeLightmap(float4 color)
{
    return color.rgb; // Exposure handled by HDRP pipeline
}

// Declare textures and samplers
Texture2D NormalSampler;
SamplerState SamplerState_NormalSampler;

Texture2D AlphaSampler;
SamplerState SamplerState_AlphaSampler;

// Normal decoding
float4 DecompressNormal(float2 tc, int nDecompressionMode)
{
    float4 normalTexel = NormalSampler.Sample(SamplerState_NormalSampler, tc);
    float4 result;

    if (nDecompressionMode == NORM_DECODE_NONE)
    {
        result = float4(normalTexel.xyz * 2.0f - 1.0f, normalTexel.a);
    }
    else if (nDecompressionMode == NORM_DECODE_ATI2N)
    {
        result.xy = normalTexel.xy * 2.0f - 1.0f;
        result.z = sqrt(max(0.0f, 1.0f - dot(result.xy, result.xy)));
        result.a = 1.0f;
    }
    else // ATI2N plus ATI1N for alpha
    {
        result.xy = normalTexel.xy * 2.0f - 1.0f;
        result.z = sqrt(max(0.0f, 1.0f - dot(result.xy, result.xy)));
        float4 alphaTexel = AlphaSampler.Sample(SamplerState_AlphaSampler, tc);
        result.a = alphaTexel.x; // Alpha in X channel
    }

    return result;
}

// Texture combining for HDRP
inline float4 TextureCombine(float4 baseColor, float4 detailColor, int combine_mode, float fBlendFactor)
{
    float3 blendResult;

    if (combine_mode == TCOMBINE_RGB_EQUALS_BASE_x_DETAILx2)
    {
        blendResult = baseColor.rgb * lerp(float3(1, 1, 1), 2.0 * detailColor.rgb, fBlendFactor);
    }
    else if (combine_mode == TCOMBINE_RGB_ADDITIVE)
    {
        blendResult = baseColor.rgb + fBlendFactor * detailColor.rgb;
    }
    else if (combine_mode == TCOMBINE_DETAIL_OVER_BASE)
    {
        float fblend = fBlendFactor * detailColor.a;
        blendResult = lerp(baseColor.rgb, detailColor.rgb, fblend);
    }
    else if (combine_mode == TCOMBINE_FADE)
    {
        blendResult = lerp(baseColor.rgb, detailColor.rgb, fBlendFactor);
    }
    else if (combine_mode == TCOMBINE_BASE_OVER_DETAIL)
    {
        float fblend = fBlendFactor * (1.0 - baseColor.a);
        blendResult = lerp(baseColor.rgb, detailColor.rgb, fblend);
    }
    else if (combine_mode == TCOMBINE_MULTIPLY)
    {
        blendResult = lerp(baseColor.rgb, baseColor.rgb * detailColor.rgb, fBlendFactor);
    }
    else if (combine_mode == TCOMBINE_MASK_BASE_BY_DETAIL_ALPHA)
    {
        baseColor.a = lerp(baseColor.a, baseColor.a * detailColor.a, fBlendFactor);
        blendResult = baseColor.rgb;
    }
    else if (combine_mode == TCOMBINE_SSBUMP_NOBUMP)
    {
        blendResult = baseColor.rgb * dot(detailColor.rgb, float3(0.666, 0.666, 0.666));
    }
    else
    {
        blendResult = baseColor.rgb; // Fallback
    }

    return float4(blendResult, baseColor.a);
}
