Shader "HDRP/TranslucentGeneric"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB) Trans (A)", 2D) = "white" {}
        _CullMode ("Cull State", Float) = 2
        _DetailMap ("Base Detail (RGB)", 2D) = "white" {}
        _DetailFactor ("Factor of detail", Range(0,1)) = 0
        _DetailBlendMode ("Blend mode of detail", Float) = 0
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Float) = 1
        _BaseMap_ST ("Base Map UV Transform", Vector) = (1,1,0,0)
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Declare transformation matrices
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            // Declare textures and samplers
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _DetailMap;
            SamplerState sampler_DetailMap;

            Texture2D _BumpMap;
            SamplerState sampler_BumpMap;

            // Declare UV transform
            float4 _BaseMap_ST;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_Detail : TEXCOORD1;
                float3 normalWS : TEXCOORD2; // World space normal
            };

            // Shader properties
            float4 _BaseColor;
            float _DetailFactor;
            float _DetailBlendMode;
            float _BumpScale;

            // Vertex shader
            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Transform normals to world space
                float3x3 objectToWorldNormal = (float3x3)_ObjectToWorld;
                output.normalWS = normalize(mul(objectToWorldNormal, input.normalOS));

                // Calculate UVs using _BaseMap_ST
                output.uv_MainTex = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                output.uv_Detail = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                return output;
            }

            // Fragment shader
            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and detail textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex) * _BaseColor;
                float4 detailColor = _DetailMap.Sample(sampler_DetailMap, input.uv_Detail);

                // Sample normal map
                float3 normalTS = _BumpMap.Sample(sampler_BumpMap, input.uv_MainTex).xyz;
                float3 normalWS = normalize(mul((float3x3)_ObjectToWorld, normalTS * 2.0 - 1.0));

                // Combine textures
                float3 combinedAlbedo = lerp(baseColor.rgb, detailColor.rgb, _DetailFactor);

                // Apply normal-mapped lighting (simplified Lambertian reflection)
                float3 lightDirWS = normalize(float3(0, 1, 0)); // Simplified light direction
                float lightIntensity = saturate(dot(normalWS, lightDirWS));
                float3 finalColor = combinedAlbedo * lightIntensity;

                // Return final color with alpha
                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
