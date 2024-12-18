Shader "HDRP/DetailGeneric"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
        _CullMode ("Cull State", Float) = 2
        _DetailMap ("Detail (RGB)", 2D) = "white" {}
        _DetailFactor ("Detail Blend Factor", Range(0,1)) = 0
        _DetailBlendMode ("Detail Blend Mode", Float) = 0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Declare required matrices and resources
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _DetailMap;
            SamplerState sampler_DetailMap;

            float4 _BaseColor;
            float _CullMode;
            float _DetailFactor;
            float _DetailBlendMode;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_Detail : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_Detail : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Pass through UV coordinates
                output.uv_MainTex = input.uv_MainTex;
                output.uv_Detail = input.uv_Detail;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and detail textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex);
                float4 detailColor = _DetailMap.Sample(sampler_DetailMap, input.uv_Detail);

                // Blend base and detail textures
                float3 combinedColor = lerp(baseColor.rgb, detailColor.rgb, _DetailFactor);

                // Return final color multiplied by base color
                return float4(combinedColor * _BaseColor.rgb, 1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
