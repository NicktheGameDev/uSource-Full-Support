Shader "HDRP/DecalModulate"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "RenderType" = "Transparent" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Declare matrices for transformations
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            // Declare textures and samplers
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            float4 _BaseColor;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform object-space position to clip-space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Pass through UV coordinates
                output.uv = input.uv;

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base texture
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv) * _BaseColor;

                // Return modulated color
                return float4(baseColor.rgb, baseColor.a);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
