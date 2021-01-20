Shader "Unlit/TestNPR_noRampMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)
        _SpecularScale("Specular Scale", Range(0, 1)) = 0.01
        _Gloss("Gloss", Range(8.0, 256)) = 20
        _BumpMap("Normal Map", 2D) = "bump"{}
        _BumpScale("Bump Scale", Float) = 1.0
 
        _Outline("Outline", Range(0, 1)) = 0.1
        _OutlineColor("Outline Color", Color) = (1,1,1,1)
        _Threshold("Threshold", Range(0, 1)) = 0.8
        
        _ShadowColor ("Shadow Color", Color) = (0.7, 0.7, 0.8)
	    _ShadowRange ("Shadow Range", Range(0, 1)) = 0.5
        _ShadowSmooth("Shadow Smooth", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            NAME "OUTLINE"
            
            Cull Front
            Zwrite off
             CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            fixed _Outline;
            fixed4 _OutlineColor;

            v2f vert (a2v v)
            {
                v2f o;

                float4 pos = mul(UNITY_MATRIX_MV, v.vertex);

                float3 normal = mul(UNITY_MATRIX_MV, v.normal);

                normal.z = -0.5;

                pos = pos + float4(normalize(normal), 0) * _Outline;

                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }
             
            fixed4 frag (v2f i) : SV_Target
            {
                return float4(_OutlineColor.rgb,1);
            }
             
            ENDCG
        }

        Pass
        {
            Tags{ "LightingMode" = "ForwardBase" }
            
            CGPROGRAM
            
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
                fixed4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;//纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 texcoord : TEXCOORD0;//纹理坐标
                float3 worldPos : TEXCOORD1;
                fixed3 worldNormal : TEXCOORD2;
                fixed3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;float4 _MainTex_ST;
            sampler2D _BumpMap;float4 _BumpMap_ST;

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            float _BumpScale;
            float4 _Color;
            float _Threshold;
            float _SpecularScale;
	        half3 _ShadowColor;
            half _ShadowRange;
            half  _ShadowSmooth;
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);

                o.bitangentDir = normalize(cross(o.worldNormal, o.tangentDir)*v.tangent.w);
                
                o.texcoord = v.texcoord;

                TRANSFER_SHADOW(o);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                i.worldNormal = normalize(i.worldNormal);

                i.tangentDir = normalize(i.tangentDir);
                
                i.bitangentDir = normalize(i.bitangentDir);

                float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.worldNormal);

                float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPos));

                float3 _BumpMap_Var = UnpackNormal(tex2D(_BumpMap, TRANSFORM_TEX(i.texcoord,_BumpMap)));

                _BumpMap_Var.xy *= _BumpScale;
                
                _BumpMap_Var.z = sqrt(1.0 - saturate(dot(_BumpMap_Var.xy, _BumpMap_Var.xy)));

                float3 normalLocal  = _BumpMap_Var.rgb;

                float3 normalDirection = normalize(mul(normalLocal, tangentTransform));

                float4 texColor = tex2D(_MainTex,TRANSFORM_TEX( i.texcoord ,_MainTex));

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * texColor.rgb * atten;

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed diff = dot(normalDirection, worldLightDir);

                ///halfLambat
                diff = (diff*0.5 + 0.5) * atten;

                half ramp = smoothstep(0, _ShadowSmooth, diff - _ShadowRange);

                //fixed3 diffuse = diff > _ShadowRange ? _Diffuse.rgb : _ShadowColor;
                fixed3 diffuse = lerp(_ShadowColor, texColor, ramp);
                
                diffuse = texColor * diffuse * _LightColor0;

                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(normalDirection, worldLightDir)) * texColor;
                
                fixed3 halfDir = normalize(worldLightDir + viewDirection);

                float spec = dot(normalDirection, halfDir);
                
                float w = fwidth(spec) * 2.0;
                
                spec = lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(normalDirection, halfDir)),_Gloss) * texColor;
                
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * spec * texColor;
                
                fixed4 col = fixed4((ambient + diffuse + specular), 1.0);
                
                return col;
            }
            
            ENDCG
        }
    }
}
