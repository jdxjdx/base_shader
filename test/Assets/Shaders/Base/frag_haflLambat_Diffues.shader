// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Hidden/frag_haflLambat_Diffues"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Diffuse("Diffuse", Color) = (1,1,1,1)
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

            struct a2v
            {
                float4 vertex : POSITION;
                fixed3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : NORMAL;
            };

            v2f vert (a2v v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = mul(v.normal, unity_WorldToObject);

                return o;
            }

            sampler2D _MainTex;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                fixed3 worldNomal = normalize(i.worldNormal);
                
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                fixed haflLambert = dot(worldNomal, worldLight)*0.5 + 0.5;
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * haflLambert;
                
                fixed3 color = ambient + diffuse;
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
