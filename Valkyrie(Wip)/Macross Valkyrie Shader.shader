Shader "MCRS/ValkyrieMulti_High"
{
    Properties
    {
        _VAL_col ("VAL_col", 2D) = "white" { }
        _Frenel_slider ("Frenel_slider", Range(-0.5, 1)) = 0
        _Cube_map ("Cube_map", Cube) = "_Skybox" { }
        _VAL_mask ("VAL_mask", 2D) = "white" { }
        _Brightnessmulti ("Brightness(multi)", Range(0, 2)) = 1
        _Saturationpower ("Saturation (power)", Range(0, 2)) = 1
        _IBL_color ("IBL_color", Color) = (0.5,0.5,0.5,1)
        _speed ("speed", Float) = 10
        _DamageColor ("DamageColor", Color) = (0,0,0,1)
        _MuzzleColor ("MuzzleColor", Color) = (0.5019608,0.5019608,0.5019608,1)
        _VAL_col2 ("VAL_col2", 2D) = "white" { }
        _VAL_mask2 ("VAL_mask2", 2D) = "white" { }
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "LIGHTMODE" = "FORWARDBASE" "RenderType" = "Opaque" "SHADOWSUPPORT" = "true" }

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
                float2 uv2 : TEXCOORD1;
                half3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 posWorld : TEXCOORD2;
                float3 texcoord : TEXCOORD3;
                float4 vertex : SV_POSITION;
                half3 normal : NORMAL;
            };

            sampler2D _VAL_col;
            sampler2D _VAL_col2;
            sampler2D _VAL_mask;
            sampler2D _VAL_mask2;
            samplerCUBE _Cube_map;
            float4 _VAL_col_ST;
            float4 _VAL_col2_ST;
            float4 _VAL_mask_ST;
            float4 _VAL_mask2_ST;
            float _Brightnessmulti;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, o.vertex);
                o.normal = normalize( mul ( float4(v.normal, 0.0), unity_WorldToObject).xyz);;
                o.uv = TRANSFORM_TEX(v.uv, _VAL_col);
                o.uv2 = v.uv2;
                o.texcoord = o.normal;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_VAL_col, i.uv);
                fixed4 col2 = tex2D(_VAL_col2, i.uv2);
                fixed4 mask = tex2D(_VAL_mask, i.uv);
                fixed4 mask2 = tex2D(_VAL_mask2, i.uv2);
                fixed4 CUBE = texCUBE(_Cube_map, i.texcoord) * _Brightnessmulti * mask;
                CUBE * _Brightnessmulti;
                col = lerp(col, col2, mask2); 
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col + CUBE;
            }
            ENDCG
        }
    }
}
