Shader "MCRS/Diva/Blush"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		_AlphaMask ("Alpha (A)", 2D) = "white" {}
		_Alpha ("Alpha", Range(0, 1)) = 0
		[Toggle] _UseColor("Ignore Light?", Float) = 0
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "RenderType"="Geometry" "LightMode" = "Vertex"}
		Blend SrcAlpha OneMinusSrcAlpha

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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            sampler2D _AlphaMask;
            float4 _AlphaMask_ST;
			float _Alpha;
			float _UseColor;
		

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				col.a = tex2D(_AlphaMask, i.uv) * _Alpha;
				if(_UseColor == 1)
				{
                   col.rgb *= _Color.rgb;
				}
				else
				{
                   col.rgb *= unity_LightColor[0].rgb;
				}				
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
