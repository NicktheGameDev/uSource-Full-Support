Shader "HDRP/CutoutGeneric"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB) Trans (A)", 2D) = "white" {}
        _AlphaCutoff ("Alpha Cutoff", Range(0,1)) = 0.5
        _CullMode ("Cull State", Float) = 2
        _BumpMap ("Normal Map", 2D) = "bump" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Declare matrices and properties
            float4x4 _ObjectToWorld;
            float4x4 UNITY_MATRIX_VP;

            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _BumpMap;
            SamplerState sampler_BumpMap;

            float4 _BaseColor;
            float _AlphaCutoff;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1; // World space normal for bump mapping
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                float4 worldPos = mul(_ObjectToWorld, float4(input.positionOS, 1.0));
                output.positionCS = mul(UNITY_MATRIX_VP, worldPos);

                // Pass UV and transform normals to world space
                output.uv = input.uv;
                float3x3 objectToWorldNormal = (float3x3)_ObjectToWorld;
                output.normalWS = normalize(mul(objectToWorldNormal, float3(0, 0, 1))); // Placeholder normal

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base color
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv) * _BaseColor;

                // Apply alpha cutoff
                if (baseColor.a < _AlphaCutoff)
                    discard;

                // Sample normal map and calculate world space normal
                float3 normalTS = _BumpMap.Sample(sampler_BumpMap, input.uv).xyz * 2.0 - 1.0;
                float3 normalWS = normalize(mul((float3x3)_ObjectToWorld, normalTS));

                // Apply simple lighting
                float3 lightDir = normalize(float3(0.0, 1.0, 0.0)); // Simplified light direction
                float3 lightColor = float3(1.0, 1.0, 1.0);          // White light
                float3 diffuse = saturate(dot(normalWS, lightDir)) * lightColor;

                // Output final color with lighting applied
                return float4(baseColor.rgb * diffuse, baseColor.a);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
