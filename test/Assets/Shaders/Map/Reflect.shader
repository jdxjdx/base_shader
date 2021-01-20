Shader "Unlit/Reflect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ReflectColor("Reflect Color", Color) = (1,1,1,1)
        _Color("Color", Color) = (1,1,1,1)
        _Cubemap("Reflect Cubemap", Cube) = "_Skybox" {}
        _ReflectAmount("Reflect Amount", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				fixed3 worldViewDir : TEXCOORD2;
				fixed3 worldRefl : TEXCOORD3;
				SHADOW_COORDS(4)
			};

			fixed4 _Color;
			fixed4 _ReflectColor;
			fixed _ReflectAmount;
			samplerCUBE _Cubemap;

            v2f vert (a2v v)
            {
                v2f o;
                //三维空间坐标投影到二维窗口
                o.pos = UnityObjectToClipPos(v.vertex);// mul(UNITY_MATRIX_MVP, IN.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//替换 o.worldNormal = mul(v.normal, unity_WorldToObject);

                //顶点在世界空间中的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

            	o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

            	TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

            	fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

            	fixed3 worldViewDir = normalize(i.worldViewDir);

            	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

            	fixed3 diffuse = _LightColor0 * _Color * saturate(dot(worldNormal, worldLightDir));

            	fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

            	UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

            	fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
            	
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
