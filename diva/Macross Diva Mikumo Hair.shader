Shader "MCRS/Diva/Mikumo Hair"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Color ("Main Color", Color) = (1,1,1,1)
        [Toggle] _UseColor("Ignore Light?", Float) = 0
    }
    SubShader
    {
        Tags { "Queue"="Geometry+10"  "RenderType"="Opaque" "LightMode"="VERTEX" }
        Blend SrcAlpha One
        Cull Back
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
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _Color;
            float _Alpha;
            float4 _MainTex_ST;
            float _UseColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color;
                o.uv =(v.uv*_MainTex_ST.xy) + float2(0, -0.1) * _Time.y;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                col.a = i.color * 0.4;
                
                if(_UseColor == 1)
                {
                    col.rgb *= _Color;
                }
                else
                {
                    col.rgb *= unity_LightColor[0];
                }

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
