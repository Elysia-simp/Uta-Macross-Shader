Shader "MCRS/Diva/Opaque"{
	//thank mrpolarbear for the edgeline help
    Properties {
		_MainTex("Texture", 2D) = "white" {}
        _AlphaTex ("Alpha (A)", 2D) = "white" {}
        _Alpha ("Alpha", range(0,1)) = 1
        [Toggle] _AlphaMainTex("Alpha in Texture?", Float) = 0
        [Toggle] _OutlineIgnoreLight("Should outline ignore the light?", Float) = 0
        [Toggle] _UseColor("Ignore Light?", Float) = 0
        [Toggle] _OutlineToggle("Outline toggle", Float) = 1
		_Color ("Main Color", Color) = (1,1,1,1)
		[Toggle] _RimLightToggle("Rim toggle", Float) = 1
		_RimColor ("RimLight Color", Color) = (1,1,1,1)
		_RimLightPower("RimLight Power", Float) = 1
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Int) = 0	
        _OutlineColor("Outline Color", Color)=(1,1,1,1)
        _OutlineSize("OutlineSize", Range(0.0,2))=1
    }

	Subshader{
    Tags {"Queue"="Geometry" "RenderType"="Geometry" "LightMode" = "Vertex"}
	Cull [_CullMode]

	Blend SrcAlpha OneMinusSrcAlpha
        //RimLight + Main Tex
        pass{
			Zwrite On
            CGPROGRAM
            #pragma vertex vertexFunc
            #pragma fragment fragmentFunc
                
            #include "UnityCG.cginc"

            // main tex stuff
            fixed4 _Color;
            sampler2D _MainTex;
			float4 _MainTex_ST;
            float _Alpha;
            sampler2D _AlphaTex;
            //RimLight stuff
            fixed4 _RimColor;
            float _RimLightPower;
            sampler2D _RimLightSampler;
            float _UseColor;
            float _AlphaMainTex;
            float _RimLightToggle;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
                float3 normal : NORMAL;
                float4 posWorld : TEXCOORD1;
				float2 texcoord : TEXCOORD2;
            };
			
            struct v2f
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
                half3 normal : NORMAL;
                float4 posWorld : TEXCOORD1;
                float4 color : COLOR;
				half2 texcoord : TEXCOORD2;
            };

            v2f vertexFunc(appdata IN){
				v2f OUT = (v2f)0;
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				// even more RimLight stuff
				OUT.posWorld = mul(unity_ObjectToWorld, IN.vertex);
                OUT.normal = normalize( mul ( float4(IN.normal, 0.0), unity_WorldToObject).xyz);
                IN.texcoord = TRANSFORM_TEX(OUT.texcoord, _MainTex);
                UNITY_TRANSFER_FOG(OUT, OUT.pos);
                OUT.position = UnityObjectToClipPos(IN.vertex);

		return OUT;
			}

            fixed4 fragmentFunc(v2f IN) : SV_Target{
                //Unlit Texture stuff nothing special
				fixed4 pixelColor = tex2D(_MainTex, IN.uv);
				pixelColor.a = tex2D(_AlphaTex, IN.uv) * _Alpha;
                
                if(_UseColor == 1)
					{
                    pixelColor.rgb *= _Color.rgb;
					}
				else{
                    pixelColor.rgb *= unity_LightColor[0].rgb;
					}
				
				if(_AlphaMainTex == 1){
					
                 pixelColor.a = tex2D(_MainTex, IN.uv).a * _Alpha;
                }
				else{
                 pixelColor.a = tex2D(_AlphaTex, IN.uv) * _Alpha ;
                }

				
		//subtex
		float3 Rimmask = tex2D(_RimLightSampler, IN.uv);
				
		//Rimlighting
				
               float3 normalDir = IN.normal;
		 
               float3 viewDir = normalize( _WorldSpaceCameraPos.xyz - IN.posWorld.xyz);
               float rimUV = 1.0 - saturate ( dot(viewDir, normalDir) );
			   float3 Rim = tex2D(_RimLightSampler, rimUV).g; // rim uv affecting the g map rather than the regular uv
				 
		//a massive fucking headache
                 float3 rimLight =  pow(rimUV, (_RimLightPower * -1)) * _RimColor * Rimmask.r * Rim * _RimLightToggle ;
                return float4(pixelColor + rimLight, pixelColor.a);
            }
            ENDCG
        }

        Pass
        {
            // Stencil {
	    // 	Ref 1
	    // 	Comp NotEqual
	    // }

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
            
            struct appdata
            {
                float4 vertex:POSITION;
                half3 normal : NORMAL;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
            
            };
            
            struct v2f
            {
                float4 position : SV_POSITION;
                float4 color    : COLOR;
                float2 uv : TEXCOORD0;
            };
            
            v2f vert (appdata IN)
            {
                v2f OUT = (v2f)0;
				OUT.uv = IN.uv;
				OUT.color = IN.color;
				// adjusted for Asset ripper Models If you want to use FBX scale your model by 100 in any 3d program
				if(_OutlineToggle == 1)
				{
					IN.vertex.xyz += IN.normal.xyz * _OutlineSize * IN.color * 0.015;
				}
				else
				{
					IN.vertex = IN.vertex;
				}
                //outline related things
				OUT.position = UnityObjectToClipPos(IN.vertex);
				//outlinemask

                

                
                return OUT;
            }
            
            fixed4 frag (v2f IN) : SV_Target
            {
				fixed4 pixelColor = tex2D(_MainTex, IN.uv) * _OutlineColor * float4(0.8,0.8,0.8,1.0);
				if(_OutlineIgnoreLight == 1) // channeling my inner copy and paste with this one
				{
					pixelColor.rgb *= _Color.rgb;
				}
				else
				{
					pixelColor.rgb *= unity_LightColor[0].rgb;
                }
				if(_OutlineToggle == 1)
				{
					pixelColor.a = 1 * _OutlineColor;
				}
				else
				{
					pixelColor.a = 0 * _OutlineColor;
				}
                return pixelColor;
            }
            ENDCG
        }
    }
}
