Shader "HDRP/UnlitGeneric"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _BaseMap ("Base Map", 2D) = "white" {}
        _DetailMap ("Detail Map", 2D) = "white" {}
        _DetailFactor ("Detail Factor", Range(0,1)) = 0
        _DetailBlendMode ("Detail Blend Mode", Int) = 0
    }
    
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
           
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;   // Object space position
                float2 uv : TEXCOORD0;         // UV coordinates
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION; // Clip space position
                float2 uv : TEXCOORD0;          // UV coordinates
                float fogCoord : TEXCOORD1;     // Fog coordinate
            };

            float4 _BaseColor;
            float4 _BaseMap_ST;
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_DetailMap);
            SAMPLER(sampler_DetailMap);

            float _DetailFactor;
            float _DetailBlendMode;

            // Custom fog function
            float ComputeFogFactor(float z, float fogStart, float fogEnd)
            {
                return saturate((z - fogStart) / (fogEnd - fogStart));
            }

            Varyings vert(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                output.positionCS = TransformWorldToHClip(positionWS); // Fixed truncation issue
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                
                // Compute fog coordinate manually
                output.fogCoord = output.positionCS.z;
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float4 baseColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv) * _BaseColor;
                float4 detailColor = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, input.uv);

                // Apply fog manually using custom function
                float fogStart = 10.0; // Start of fog
                float fogEnd = 50.0;   // End of fog
                float fogFactor = ComputeFogFactor(input.fogCoord, fogStart, fogEnd);
                baseColor.rgb = lerp(baseColor.rgb, float3(0, 0, 0), fogFactor); // Blend with black fog

                // Blend detail map and fix type mismatch
                baseColor = float4(baseColor.rgb * lerp(float3(1, 1, 1), 2.0 * detailColor.rgb, _DetailFactor), baseColor.a);

                return baseColor;
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
