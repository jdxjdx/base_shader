﻿// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/frag_blinn_specular_normalmap"
{
   Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        
        _Color("Colot Tint", Color) = (1,1,1,1)
        _BumpMap("Normal Map", 2D) = "bump"{}
        _BumpScale("Bump Scale", Float) = 1.0
        _Specular("Specular", Color) = (1,1,1,1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags{"LightMode" = "ForwardBase"}

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"


            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                float3 lightDir: TEXCOORD2;
            };
            
            fixed4 _Diffuse;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Color;
            float4 _Specular;
            float _Gloss;

            v2f vert (a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                // o.worldNormal = mul(v.normal, unity_WorldToObject);
                //
                // o.worldPos = mul(unity_ObjectToWorld,v.vertex);

                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                // float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
                //
                // float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

                TANGENT_SPACE_ROTATION;

                o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));

                o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 tangentLightDir = normalize(i.lightDir);

                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);

                fixed3 tangentNormal = UnpackNormal(packedNormal);

                tangentNormal.xy *= _BumpScale;

                tangentNormal.z = sqrt(1.0- saturate((dot(tangentNormal.xy, tangentNormal.xy))));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

                fixed3 halfDir = normalize(tangentNormal + tangentViewDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                
                fixed3 color = (ambient+diffuse+specular);
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
