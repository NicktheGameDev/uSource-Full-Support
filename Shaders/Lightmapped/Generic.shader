Shader "HDRP/Lightmapped/GenericWithNormals"
{
    Properties
    {
        _BaseColor ("Main Color (RGBA)", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
        _IsTranslucent ("Is Translucent", Float) = 0
        _CullMode ("Cull State", Float) = 2
        _ZWrite ("Z-Buffer State", Float) = 1
        _AlphaTest ("Is AlphaTest", Float) = 0
        _DetailColor ("Detail Tint (RGBA)", Color) = (1,1,1,1)
        _DetailMap ("Base Detail (RGB)", 2D) = "white" {}
        _DetailFactor ("Factor of detail", Range(0,1)) = 0
        _DetailBlendMode ("Blend mode of detail", Float) = 0
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Map Scale", Float) = 1.0
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline" = "HDRenderPipeline" 
            "Queue" = "Geometry"
            "RenderType" = "Transparent"
        }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Matrices and helpers
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            // Texture declarations
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _DetailMap;
            SamplerState sampler_DetailMap;

            Texture2D _NormalMap;
            SamplerState sampler_NormalMap;

            float4 _BaseColor;
            float _IsTranslucent;
            float _CullMode;
            float _ZWrite;
            float _AlphaTest;
            float4 _DetailColor;
            float _DetailFactor;
            float _DetailBlendMode;
            float _NormalScale;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 normalWS : TEXCOORD2; // World space normal
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Transform normals to world space
                float3x3 objectToWorldNormal = (float3x3)_ObjectToWorld;
                output.normalWS = normalize(mul(objectToWorldNormal, input.normalOS));

                // UV transformations
                output.uv0 = input.uv0; // Base map UV
                output.uv2 = input.uv0; // Detail map UV

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and detail textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv0) * _BaseColor;
                float4 detailColor = _DetailMap.Sample(sampler_DetailMap, input.uv2) * _DetailColor;

                // Combine base and detail textures
                float3 combinedColor = lerp(baseColor.rgb, detailColor.rgb, _DetailFactor);
                baseColor.rgb = combinedColor;

                // Apply lighting using HDRP's built-in light probes and reflection probes
                float3 normalTS = _NormalMap.Sample(sampler_NormalMap, input.uv0).xyz * 2.0 - 1.0; // Tangent-space normal
                float3 normalWS = normalize(mul((float3x3)_ObjectToWorld, normalTS * _NormalScale)); // World-space normal

                // Apply light using the built-in HDRP lighting data
                float3 lightColor = float3(1.0, 1.0, 1.0); // Simplified white light
                float diffuse = saturate(dot(normalWS, normalize(float3(0, 1, 0)))); // Simplified light direction
                baseColor.rgb *= lightColor * diffuse;

                // Handle alpha and translucency
                if (_AlphaTest == 1.0)
                {
                    if (baseColor.a < 0.5)
                        discard; // Alpha test
                }

                if (_IsTranslucent == 1.0)
                {
                    baseColor.a *= 0.5; // Example translucency behavior
                }

                return baseColor;
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
