Shader "Hidden/Test_2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha//開啓透明通道混合
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;

            // Plot a line on Y using a value between 0.0-1.0
            fixed plot(fixed2 st) {    
                return smoothstep(0.02, 0.0, abs(st.y - st.x));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //fixed4 col = tex2D(_MainTex, i.uv);
                // just invert the colors
                //col.rgb = 1 - col.rgb;
                //return col;
                fixed y =  i.uv.x;

                    // Plot a line
                fixed pct = plot(i.uv);
                fixed4 color = y;
                color = (1.0-pct)*color+pct*fixed4(0,1,0,1);

                return color;
            }
            ENDCG
        }
    }
}
