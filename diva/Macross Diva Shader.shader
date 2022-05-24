Shader "MCRS/Diva/Opaque_High"
{
    Properties
    {
		_MainTex("Texture", 2D) = "white" {}
		_AlphaTex ("Alpha (A)", 2D) = "white" {}
		_Alpha ("Alpha", range(0,1)) = 1
		[Toggle] _AlphaMainTex("Alpha in Texture?", Float) = 0
		[Toggle] _UseColor("Ignore Light?", Float) = 0
		[Toggle] _OutlineToggle("Outline toggle", Float) = 1
		_Color ("Main Color", Color) = (1,1,1,1)
		[Toggle] _RimLightToggle("Rim toggle", Float) = 1
		[Toggle] _TangentToggle("(MGF ONLY) Tangent Toggle", Float) = 1
		_RimColor ("RimLight Color", Color) = (1,1,1,1)
		_RimLightPower("RimLight Power", Float) = 1
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0	
		_OutlineColor("Outline Color", Color)=(1,1,1,1)
		_OutlineSize("OutlineSize", Range(0.0,2))=1
    }
    SubShader
    {
	Tags {"Queue"="Geometry" "RenderType"="Geometry" "LightMode" = "Vertex"}
	Cull [_CullMode]
	Blend SrcAlpha OneMinusSrcAlpha
        Pass
        {
	Zwrite On
          CGPROGRAM 
          #pragma vertex vert
          #pragma fragment frag
          // make fog work
          #pragma multi_compile_fog

          #include "UnityCG.cginc"

          struct appdata
          {
              float4 vertex : POSITION;
			  half3 normal : NORMAL;
              float2 uv : TEXCOORD0;
			  float4 tangent : TANGENT;
          };

          struct v2f
          {
              float2 uv : TEXCOORD0;
              UNITY_FOG_COORDS(1)
              float4 vertex : SV_POSITION;
			  half3 normal : NORMAL;
			  float4 posWorld : TEXCOORD1;
          };

          float4 _Color;
          float4 _RimColor;
          float _RimLightToggle;
	  float _RimLightPower;
	  sampler2D _MainTex;
          sampler2D _AlphaTex;
          sampler2D _RimLightSampler;
          float4 _MainTex_ST;
          float4 _AlphaTex_ST;
          float4 _RimLightSampler_ST;
	  float _Alpha;
	  float _UseColor;

            v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		o.normal = normalize( mul ( float4(v.normal, 0.0), unity_WorldToObject).xyz);
		o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
				
        fixed4 col = tex2D(_MainTex, i.uv);
		col.a = tex2D(_AlphaTex, i.uv) * _Alpha * col.a;
		//Rimlight NEW
		
		float3 normalDir = i.normal;
		float3 viewDir = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz);
		float rimUV = saturate(pow(1.0 - dot(viewDir, normalDir), _RimLightPower));
		
		//subtex calls
		
		fixed4 Rim = tex2D(_RimLightSampler, rimUV).g * _RimLightToggle * _RimColor * _RimLightPower;
		fixed4 Rimmask = tex2D(_RimLightSampler, i.uv).r;
		
		// so i don't need to make so many return calls like before
		
		col.rgb = lerp(col.rgb, col.rgb + Rim, Rimmask);
		
		//light reaction
		if(_UseColor == 1)
		{
			col.rgb *= _Color;
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
		Pass
		{
			Cull Front
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
            #include "UnityCG.cginc"
			
			fixed4 _OutlineColor;
           	float _OutlineSize;
           	sampler2D _MainTex;
            sampler2D _OutlineMask;
            fixed4 _Color;
			float _OutlineIgnoreLight;
			float _OutlineToggle;
			float _UseColor;
			float _DistanceScale;
			
			struct appdata
			{
				float4 vertex : POSITION;
				half3 normal : NORMAL;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 position : SV_POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};
			
			v2f vert (appdata v)
            {
                v2f o = (v2f)0;
                o.uv = v.uv;
				o.color = v.color;
				//once again adjusted for asset ripper models and models scaled by 100
				v.vertex.xyz += v.normal.xyz * _OutlineSize * v.color * _OutlineToggle * 0.015;
				o.position = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv) * _OutlineColor * float4(0.8,0.8,0.8,1.0);
				
				//also light reaction
				if(_UseColor == 1)
				{
					col.rgb *= _Color;
				}
				else
				{
					col.rgb *= unity_LightColor[0].rgb;
				}
					col.a = _OutlineToggle;
				return col;
			}
			ENDCG
		}
    }
}
