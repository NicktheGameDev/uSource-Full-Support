Shader "HDRP/WorldTwoTextureBlend"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BaseMap ("Base Map", 2D) = "white" {}
        _DetailMap ("Detail Map", 2D) = "white" {}
        _AlphaCutoff ("Alpha Cutoff", Range(0, 1)) = 0.5
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Map Scale", Float) = 1.0
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
            #pragma target 5.0

            // Required matrices
            float4x4 UNITY_MATRIX_MVP;
            float4x4 _ObjectToWorld;

            // Texture declarations
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _DetailMap;
            SamplerState sampler_DetailMap;

            Texture2D _NormalMap;
            SamplerState sampler_NormalMap;

            float4 _BaseColor;
            float _AlphaCutoff;
            float _NormalScale;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_DetailMap : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_DetailMap : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform object space position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_MVP, worldPos);

                // Pass UV coordinates
                output.uv_MainTex = input.uv_MainTex;
                output.uv_DetailMap = input.uv_DetailMap;

                // Pass normal mapping computation to the fragment shader for efficiency
                output.normalWS = normalize(mul((float3x3)_ObjectToWorld, float3(0.0, 0.0, 1.0)));

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and detail textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex) * _BaseColor;
                float4 detailColor = _DetailMap.Sample(sampler_DetailMap, input.uv_DetailMap);

                // Blend base and detail textures
                float3 blendedColor = lerp(baseColor.rgb, detailColor.rgb, detailColor.a);

                // Apply lighting with normal mapping
                float3 normalTS = _NormalMap.Sample(sampler_NormalMap, input.uv_MainTex).xyz * 2.0 - 1.0;
                float3 normalWS = normalize(mul((float3x3)_ObjectToWorld, normalTS * _NormalScale));

                float3 lightDir = normalize(float3(0.0, 1.0, 0.0)); // Simplified light direction
                float3 lightColor = float3(1.0, 1.0, 1.0);          // Simplified white light
                float diffuse = saturate(dot(normalWS, lightDir));

                float3 finalColor = blendedColor * diffuse;

                // Handle alpha cutoff
                if (baseColor.a < _AlphaCutoff)
                    discard;

                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
