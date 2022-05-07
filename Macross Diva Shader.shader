Shader "MCRS/Diva/Opaque"{
	//thank mrpolarbear for the edgeline help
	//Update 1.1: hookers added
	//Update 1.2: Corrected error related to outline using MainTex as mask by accident
	//Update 1.3: Unity 2020 (also maybe 2021?) clarification errors fixed cause Unity moment
	//Update 1.4: Toggle for alpha being in Texture
	//Update 1.5: Rimlight Sampler G map actually works (don't judge me) also outlines are darker by default now
	
    Properties {
		_MainTexture("Texture", 2D) = "white" {}
        	_AlphaMask ("Alpha (A)", 2D) = "white" {}
        	_Alpha ("Alpha", range(0,1)) = 1
        	[Toggle] _AlphaMainTex("Alpha in Texture?", Float) = 0
        	[Toggle] _UseColor("Ignore Light?", Float) = 0
		_Color ("Main Color", Color) = (1,1,1,1)
		_FresnelColor ("Fresnel Color", Color) = (1,1,1,1)
		_FresnelPower ("Fresnel Power", Float) = 1
		_RimLightSampler ("RimLight Control", 2D) = "white" {}
	
        _OutlineColor("Outline Color", Color)=(1,1,1,1)
        _OutlineSize("OutlineSize", Range(0.0,2))=1
    }

	Subshader{
        Tags {"Queue"="Geometry" "RenderType"="Geometry" "LightMode" = "Vertex"}
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
        //Fresnel + Main Tex
        pass{

            CGPROGRAM
            #pragma vertex vertexFunc
            #pragma fragment fragmentFunc
                
            #include "UnityCG.cginc"

            // main tex stuff
            fixed4 _Color;
            sampler2D _MainTexture;
			float4 _MainTexture_ST;
            float _Alpha;
            sampler2D _AlphaMask;
            //Fresnel stuff
            fixed4 _FresnelColor;
            float _FresnelPower;
            sampler2D _RimLightSampler;
            float _UseColor;
            float _AlphaMainTex;

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
		// even more fresnel stuff
		OUT.posWorld = mul(unity_ObjectToWorld, IN.vertex);
                OUT.normal = normalize( mul ( float4(IN.normal, 0.0), unity_WorldToObject).xyz);
                IN.texcoord = TRANSFORM_TEX(OUT.texcoord, _MainTexture);
                UNITY_TRANSFER_FOG(OUT, OUT.pos);
                OUT.position = UnityObjectToClipPos(IN.vertex);

		return OUT;
			}

            fixed4 fragmentFunc(v2f IN) : SV_Target{
                //Unlit Texture stuff nothing special
		fixed4 pixelColor = tex2D(_MainTexture, IN.uv);
		pixelColor.a = tex2D(_AlphaMask, IN.uv) * _Alpha;
                
                if(_UseColor == 1)
				{
                    	pixelColor.rgb *= _Color.rgb;
                }
		else
		{
                    pixelColor.rgb *= unity_LightColor[0].rgb;
                }
				
		if(_AlphaMainTex == 1)
		{
					
                    pixelColor.a = tex2D(_MainTexture, IN.uv).a * _Alpha;
                }
		else{
                    pixelColor.a = tex2D(_AlphaMask, IN.uv) * _Alpha;
                }
				
		//subtex
		float3 Rimmask = tex2D(_RimLightSampler, IN.uv); //works like a regular tex
		
		//Rimlighting
				
                float3 normalDir = IN.normal;
				 
                float3 viewDir = normalize( _WorldSpaceCameraPos.xyz - IN.posWorld.xyz);
                float rimUV = 1.0 - saturate (dot(viewDir, normalDir));
				 
		float3 Rim = tex2D(_RimLightSampler, rimUV).g; //subtex except G is influenced by rimUV
				 
		//a massive fucking headache
                float3 rimLight =  pow(rimUV, _FresnelPower) * _FresnelColor * Rimmask.r * Rim  ;
            
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
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            fixed4 _OutlineColor;
            float _OutlineSize;
            sampler2D _MainTexture;
            sampler2D _OutlineMask;
            fixed4 _Color;
            
            struct appdata
            {
                float4 vertex:POSITION;
                half3 normal : NORMAL;
                half4 color : COLOR;
                float2 uv : TEXCOORD0;
            
            };
            
            struct v2f
            {
                float4 position : SV_POSITION;
                half4 color    : COLOR;
                float2 uv : TEXCOORD0;
            };
            
            v2f vert (appdata IN)
            {
                v2f OUT = (v2f)0;
		OUT.uv = IN.uv;
		OUT.color = IN.color;
		// adjusted for Asset ripper Models If you want to use FBX scale your model by 100 in any 3d program
                IN.vertex.xyz += IN.normal.xyz * _OutlineSize * IN.color * 0.015;
                //outline related things
		OUT.position = UnityObjectToClipPos(IN.vertex);
		
                return OUT;
            }
            
            fixed4 frag (v2f IN) : SV_Target
            {
	    //Take texture and darken them slightly
                fixed4 pixelColor = tex2D(_MainTexture, IN.uv) * _OutlineColor * float4(0.8,0.8,0.8,1.0);
                return pixelColor;
                
            }
            ENDCG
        }
    }
}
