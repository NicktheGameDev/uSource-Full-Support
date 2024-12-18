Shader "HDRP/Lightmapped/WorldVertexTransition"
{
    Properties
    {
        _BaseColor ("Main Color", Color) = (1,1,1,1)
        _BaseMap ("Base (RGB)", 2D) = "white" {}
        _SecondMap ("Second Base (RGB)", 2D) = "white" {}
        _BumpMap ("Normal Map", 2D) = "bump" {}
        _NormalScale ("Normal Map Scale", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "HDRenderPipeline" "RenderType" = "Opaque" }
        LOD 200

        Pass
        {
            HLSLPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            // Matrices
            float4x4 UNITY_MATRIX_MVP;
            float3x3 UNITY_MATRIX_IT_MV; // Inverse transposed model-view matrix for normals

            // Textures and samplers
            Texture2D _BaseMap;
            SamplerState sampler_BaseMap;

            Texture2D _SecondMap;
            SamplerState sampler_SecondMap;

            Texture2D _BumpMap;
            SamplerState sampler_BumpMap;

            // Shader properties
            float4 _BaseColor;
            float _NormalScale;

            struct Attributes
            {
                float3 positionOS : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_SecondTex : TEXCOORD1;
                float4 color : COLOR;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_SecondTex : TEXCOORD1;
                float4 color : COLOR;
                float3 normalVS : TEXCOORD2; // Normal in view space
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Transform position to clip space
                output.positionCS = mul(UNITY_MATRIX_MVP, float4(input.positionOS, 1.0));

                // Pass UVs and vertex color directly
                output.uv_MainTex = input.uv_MainTex;
                output.uv_SecondTex = input.uv_SecondTex;
                output.color = input.color;

                // Pass normals as-is; offload normal mapping to fragment shader
                output.normalVS = normalize(mul(UNITY_MATRIX_IT_MV, float3(0.0, 0.0, 1.0))); // Default normal

                return output;
            }

            float4 frag(Varyings input) : SV_Target
            {
                // Sample base and second textures
                float4 baseColor = _BaseMap.Sample(sampler_BaseMap, input.uv_MainTex);
                float4 secondColor = _SecondMap.Sample(sampler_SecondMap, input.uv_SecondTex);

                // Perform vertex color-based interpolation
                float3 blendedColor = lerp(baseColor.rgb, secondColor.rgb, input.color.a);

                // Sample normal map
                float3 normalTS = _BumpMap.Sample(sampler_BumpMap, input.uv_MainTex).xyz * 2.0 - 1.0;
                float3 normalVS = normalize(normalTS * _NormalScale);

                // Apply simplified Lambertian lighting
                float3 lightDir = normalize(float3(0.0, 1.0, 0.0)); // Simplified light direction
                float3 lightColor = float3(1.0, 1.0, 1.0); // White light
                float diffuse = max(dot(normalVS, lightDir), 0.0);

                float3 finalColor = blendedColor * diffuse * _BaseColor.rgb;

                return float4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
    CustomEditor "UnityEditor.Rendering.HighDefinition.HDLitGUI"
}
