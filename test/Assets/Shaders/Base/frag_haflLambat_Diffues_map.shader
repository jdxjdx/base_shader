// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/frag_haflLambat_Diffues_map"
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
            float4 _Specular;
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
                float2 uv:TEXCOORD3;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;

            v2f vert (a2v v)
            {
                v2f o;
                //三维空间坐标投影到二维窗口
                o.pos = UnityObjectToClipPos(v.vertex);// mul(UNITY_MATRIX_MVP, IN.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);//替换 o.worldNormal = mul(v.normal, unity_WorldToObject);

                o.texcoord = v.texcoord;
                //顶点在世界空间中的坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }


            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldNomal = normalize(i.worldNormal);
                
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                fixed haflLambert = dot(worldNomal, worldLight)*0.5 + 0.5;

                float3 texColor = tex2D(_MainTex, fixed2(haflLambert, haflLambert)).rgb * _Specular.rgb;
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * haflLambert;
                
                fixed3 color = (ambient + diffuse) * texColor.rgb;
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
