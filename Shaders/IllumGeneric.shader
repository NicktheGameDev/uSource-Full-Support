Shader "HDRP/IllumGeneric"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
        _UseAlphaMask ("Use Mask", Float) = 0
        _MaskMap ("Mask (A)", 2D) = "white" {}
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

            // Manually declare transformation matrices
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            // Declare textures and samplers
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _MaskMap;
            SamplerState sampler_MaskMap;

            float4 _BaseColor;
            float _UseAlphaMask;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_MaskTex : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_MaskTex : TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Pass through UVs
                output.uv_MainTex = input.uv_MainTex;
                output.uv_MaskTex = input.uv_MaskTex;
                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and mask textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex) * _BaseColor;
                float4 maskColor = _MaskMap.Sample(sampler_MaskMap, input.uv_MaskTex);

                float3 finalEmission;
                if (_UseAlphaMask == 1.0)
                {
                    finalEmission = baseColor.rgb * (baseColor.a * maskColor.rgb);
                }
                else
                {
                    finalEmission = baseColor.rgb * baseColor.a;
                }

                // Return the final color and emission
                return float4(finalEmission, 1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
