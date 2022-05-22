Shader "MCRS/Diva/Mikumo Hair"
// Update 1.2: Blackjack added
{
	Properties
	{
		_MainTexture("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		[Toggle] _UseColor("Ignore Light?", Float) = 0
		_Alpha ("Alpha", range(0,1)) = 1
	}
	SubShader
	{
		Tags {"Queue"="Geometry" "RenderType"="Geometry" "LightMode" = "Vertex"}
		
		ZWrite On
		Blend SrcAlpha OneMinusSrcAlpha
		
		Pass
		{
			CGPROGRAM
			
			// unity just requires this
			
			#pragma vertex vertexFunc
			#pragma fragment fragmentFunc

			
			
			#include "UnityCG.cginc"
			
			struct appdata{
				float4 vertex : POSITION;
                half4 color : COLOR;
				float2 uv : TEXCOORD;
				
			};
			
			struct v2f {
				float4 position : SV_POSITION;
                half4 color    : COLOR;
				float2 uv : TEXCOORD;
			};
			
			
			// main tex stuff
			fixed4 _Color;
			sampler2D _MainTexture;
			float4 _MainTexture_ST;
			float _Alpha;
			float _UseColor;
			
			v2f vertexFunc(appdata IN)
			{
				v2f OUT = (v2f)0;
				OUT.position = UnityObjectToClipPos(IN.vertex);
				// this just makes it so when the "game" is playing it moves up static cause uta doesnt really make this move at different speeds much
				OUT.uv=(IN.uv*_MainTexture_ST.xy)+float2(0, -0.1)*_Time.y;
				//vertex color call don't make the same mistake I did and do OUT.color.rgb; for some reason
				OUT.color = IN.color;

				
			return OUT;
			}
			
            fixed4 fragmentFunc(v2f IN) : SV_Target
			{
				//Unlit Texture stuff nothing special
				fixed4 pixelColor = tex2D(_MainTexture, IN.uv) + (IN.color - 0.6);
                if(_UseColor == 1){
                    pixelColor.rgb *= _Color.rgb;
                }else{
                    pixelColor.rgb *= unity_LightColor[0];
                }
    			//Vertex alpha
				pixelColor.a = IN.color * _Alpha;
				
				return pixelColor;
			}
			ENDCG


		}
	}
}
