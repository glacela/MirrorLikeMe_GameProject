﻿Shader "Unlit/RainyWindow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Size ("Size", float) = 1
        _T ("Time", float) = 1    
        _Distortion ("Distortion", range(-5, 5)) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #define S(a, b, t) smoothstep(a, b, t)
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Size, _T, _Distortion;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float N21(float2 p) {
                p = frac(p * float2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x * p.y);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float t = fmod(_Time.y + _T, 3600);
                float4 col = 0;

                float2 aspect = float2(2, 1);
                float2 uv = i.uv * _Size * aspect;
                uv.y += t * .25;
                float2 gv = frac(uv) - .5;
                float2 id = floor(uv);

                float n = N21(id);
                t += n * 6.2831;
                
                float w = i.uv.y * 10;
                
                float x = .8 * (n - .5);
                x += (.4 - abs(x)) * sin(3 * w) * pow(sin(w), 6) * .45;
                
                float y = -sin(t + sin(t) * .8) * .45;
                y -= (gv.x - x) * (gv.x - x);

                float2 dropPos = (gv - float2(x, y)) / aspect;
                float drop = S(.04, .03, length(dropPos));

                float2 trailPos = (gv - float2(x, t * .25)) / aspect;
                trailPos.y = frac(trailPos.y * 8) / 8;
                float trail = S(.03, .01, length(trailPos));
                float fogTrail = S(-.05, .05, dropPos.y);
                fogTrail *= S(.5, y, gv.y);
                trail *= fogTrail;
                fogTrail *= S(.05, .04, abs(dropPos.x));

                col += fogTrail * .5;
                col += trail;
                col += drop;

                float2 offs = drop + trail;
                //if (gv.x > .48 || gv.y > .49) col = float4(1, 0, 0, 1);
                //col *= 0; col += N21(id);// col.rg = id * .1;
                col = tex2Dlod(_MainTex, float4(i.uv + offs * _Distortion, 0, 6));

                return col;
            }
            ENDCG
        }
    }
}
