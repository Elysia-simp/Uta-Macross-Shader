Shader "MCRS/Stage/AdditiveDst"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _AlphaSlider ("Alpha fade", Range (0, 1)) = 1
        _AlphaTex ("Alpha Mask", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
        _Power ("Power", Float) = 1
        [Toggle] _UseColor("Ignore Light?", Float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0	
        [Enum(UnityEngine.Rendering.BlendMode)] _Src ("Source Blending", Float) = 3
        [Enum(UnityEngine.Rendering.BlendMode)] _Dst ("Destination Blending", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Geometry" "LightMode" = "Vertex"}
        Zwrite Off
        Cull [_CullMode]
        Blend [_Src] [_Dst]
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;

                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 position : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _AlphaTex;
            float4 _MainTex_ST;
            float4 _AlphaTex_ST;
            float4 _Color;
            float _AlphaSlider;
            float _UseColor;
            float _Power;

            v2f vert (appdata v)
            {
                v2f o;
                o.position = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _AlphaSlider * _Power;

                if(_UseColor == 1)
                {
                   col.rgb *= _Color.rgb;
                }
                else
                {
                   col.rgb *= unity_LightColor[0].rgb;
                }
                fixed4 mask = tex2D(_AlphaTex, i.uv);
                col.a = mask * _Power;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
