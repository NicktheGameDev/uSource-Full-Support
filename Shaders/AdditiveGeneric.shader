Shader "HDRP/AdditiveGeneric"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
        _CullMode ("Cull State", Float) = 2
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Map Scale", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma target 4.5                   // Upgrade to Shader Model 4.5
            #pragma vertex vert
            #pragma fragment frag

            // Include required matrices
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            // Declare textures and samplers
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _BumpMap;
            SamplerState sampler_BumpMap;

            float4 _BaseColor;
            float _NormalScale;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float3 normalWS : TEXCOORD1; // World space normal for lighting
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Pass UV coordinates
                output.uv_MainTex = input.uv_MainTex;

                // Calculate world space normal (simplified)
                float3x3 objectToWorldNormal = (float3x3)_ObjectToWorld;
                output.normalWS = normalize(mul(objectToWorldNormal, float3(0, 0, 1))); // Default normal

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base texture
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex) * _BaseColor;

                // Sample and scale the normal map
                float3 normalTS = (_BumpMap.Sample(sampler_BumpMap, input.uv_MainTex).xyz * 2.0 - 1.0) * _NormalScale;
                float3x3 objectToWorldNormal = (float3x3)_ObjectToWorld;
                float3 normalWS = normalize(mul(objectToWorldNormal, normalTS));

                // Basic additive lighting with normal mapping
                float3 lightDir = normalize(float3(0.0, 1.0, 0.0)); // Simplified light direction
                float3 lightColor = float3(1.0, 1.0, 1.0);          // Simplified white light
                float3 diffuse = saturate(dot(normalWS, lightDir)) * lightColor;

                // Blend using additive transparency
                float3 finalColor = baseColor.rgb + (diffuse * 0.15);

                // Return final additive blend
                return float4(finalColor, baseColor.a);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
