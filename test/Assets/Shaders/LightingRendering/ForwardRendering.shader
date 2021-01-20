// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/ForwardRendering"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
			#include "Lighting.cginc"
		    #include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : NORMAL;
                float2 texcoord : TEXCOORD0;//纹理坐标
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            v2f vert (a2v v)
            {
                v2f o;
                //三维空间坐标投影到二维窗口
                o.pos = UnityObjectToClipPos(v.vertex);// mul(UNITY_MATRIX_MVP, IN.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//替换 o.worldNormal = mul(v.normal, unity_WorldToObject);

                o.texcoord = v.texcoord;
                //顶点在世界空间中的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o);

                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldNomal = normalize(i.worldNormal);
                
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNomal, worldLightDir));

                float4 texColor = tex2D(_MainTex, i.texcoord);

                 fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                fixed3 halfDir = normalize(worldLightDir + viewDir);

                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(worldNomal, halfDir)), _Gloss);

                fixed atten = 1.0;

                fixed shadow = SHADOW_ATTENUATION(i);

                fixed3 color = (ambient+(diffuse+specular)*atten*shadow)*texColor;

                return fixed4(color, 1);
            }
            ENDCG
        }
        
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            
            Blend One One
            
            CGPROGRAM
            
            #pragma multi_compile_fwdadd
            #pragma vertex vert
            #pragma fragment frag

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : NORMAL;
                float2 texcoord : TEXCOORD0;//纹理坐标
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (a2v v)
            {
                v2f o;
                //三维空间坐标投影到二维窗口
                o.pos = UnityObjectToClipPos(v.vertex);// mul(UNITY_MATRIX_MVP, IN.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//替换 o.worldNormal = mul(v.normal, unity_WorldToObject);

                o.texcoord = v.texcoord;
                //顶点在世界空间中的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldNomal = normalize(i.worldNormal);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNomal, worldLightDir));

                float4 texColor = tex2D(_MainTex, i.texcoord);

                 fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos)); //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                fixed3 halfDir = normalize(worldLightDir + viewDir);

                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(worldNomal, halfDir)), _Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
        //         	#if defined (POINT)
				    //     float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
				    //     fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    // #elif defined (SPOT)
				    //     float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				    //     fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    // #else
				    //     fixed atten = 1.0;
				    // #endif
                
                    // float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                    // fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;

                    float distance = length(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                    fixed atten = 1.0/distance;
                #endif
                
                fixed3 color = ((diffuse+specular)*atten)*texColor;
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
