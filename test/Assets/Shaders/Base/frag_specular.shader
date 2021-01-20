﻿// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/frag_specular"
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

        Pass
        {
            Tags{ "LightingMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

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
                float3 worldPos : TEXCOORD1;
                float2 uv:TEXCOORD2;
            };

            sampler2D _MainTex; float4  _MainTex_ST;

            v2f vert (a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = mul(v.normal, unity_WorldToObject);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldNomal = normalize(i.worldNormal);
                
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNomal, worldLightDir));

                float4 texColor = tex2D(_MainTex, i.uv);

                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNomal));

                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(reflectDir, viewDir)), _Gloss);
                
                fixed3 color = (ambient+diffuse+specular)*texColor;
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}