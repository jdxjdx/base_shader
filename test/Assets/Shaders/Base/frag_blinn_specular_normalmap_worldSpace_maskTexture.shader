// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/frag_blinn_specular_normalmap_worldSpace_maskTexture"
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
        
        _SpecularMask("Specular Mask", 2D) = "white"{}
        _SpecularScale("Specular Scale", Float) = 1.0
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

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;
            float _BumpScale;
            float4 _Color;

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
                float2 texcoord : TEXCOORD0;//纹理坐标
                float3 worldPos : TEXCOORD1;
                //法线
                float3 tangentDir : TEXCOORD3;
                fixed3 worldNormal : TEXCOORD2;
                float3 bitangentDir : TEXCOORD4;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            uniform sampler2D _BumpMap; uniform float4 _BumpMap_ST;

            uniform sampler2D _SpecularMask; uniform float4 _SpecularMask_ST;

            float4 _SpecularScale;


            v2f vert (a2v v)
            {
                v2f o;
                //三维空间坐标投影到二维窗口
                o.pos = UnityObjectToClipPos(v.vertex);// mul(UNITY_MATRIX_MVP, IN.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//替换 o.worldNormal = mul(v.normal, unity_WorldToObject);

                o.texcoord = v.texcoord;
                //顶点在世界空间中的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                
                o.bitangentDir = normalize(cross(o.worldNormal, o.tangentDir) * v.tangent.w);

                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                i.worldNormal = normalize(i.worldNormal);
                
                float3x3 tangentTransform = float3x3( i.tangentDir, i.bitangentDir, i.worldNormal);
                
                float3 viewDirection = normalize(UnityWorldSpaceViewDir(i.worldPos)); //_WorldSpaceCameraPos - i.worldPos
                
                float3 _BumpMap_var = UnpackNormal(tex2D(_BumpMap,TRANSFORM_TEX(i.texcoord, _BumpMap)));

                _BumpMap_var.xy *= _BumpScale;

                _BumpMap_var.z = sqrt(1.0- saturate((dot(_BumpMap_var.xy, _BumpMap_var.xy))));
                
                float3 normalLocal = _BumpMap_var.rgb;

                ///转到BTN坐标系下
                float3 normalDirection = normalize(mul(normalLocal, tangentTransform)); // Perturbed normals
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(normalDirection, worldLightDir));

                float4 texColor = tex2D(_MainTex,TRANSFORM_TEX( i.texcoord ,_BumpMap));

                fixed3 halfDir = normalize(worldLightDir + viewDirection);

                fixed specularMask = tex2D(_SpecularMask, TRANSFORM_TEX(i.texcoord, _SpecularMask)).r * _SpecularScale;

                fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(saturate(dot(normalDirection, halfDir)), _Gloss)*specularMask;
                
                fixed3 color = (ambient+diffuse+specular)*texColor.rgb;
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
