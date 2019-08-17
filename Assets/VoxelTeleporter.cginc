#ifndef VoxelTelepoter_INCLUDED
#define VoxelTelepoter_INCLUDED

#include "Common.cginc"
#include "SimplexNoise3D.hlsl"

sampler2D _MainTex;
float4 _MainTex_ST;
float4 _EmissionColor;
float4 _EdgeColor;
float _Density;
float4 _EffectVector;

struct appdata
{
	float4 vertex : POSITION;
	float2 uv : TEXCOORD0;
};

struct g2f 
{
	float4 vertex : SV_POSITION;
	float2 uv : TEXCOORD0;
	float4 edge : TEXCOORD1;
	float faceEmission : TEXCOORD2;
};

appdata vert(appdata v) {
	v.vertex = mul(unity_ObjectToWorld, v.vertex);
	return v;
}

g2f VertexOutput(float3 wpos, float2 uv, float4 edge = 0, float fm = 0)
{
	g2f o;
	o.vertex = UnityWorldToClipPos(float4(wpos, 1));
	o.uv = uv;
	o.edge = edge;
	o.faceEmission = fm;
	return o;
}

g2f CubeVertex(float3 wpos, float2 uv, float3 bary_tri, float2 bary_cube, float morph, float emission, float fm)
{
	float3 bary = lerp(bary_tri, float3(bary_cube, 0.5), morph);
	return VertexOutput(wpos, uv, float4(bary, emission), fm);
}

[maxvertexcount(24)]
void geom(triangle appdata input[3], uint pid : SV_PrimitiveID, inout TriangleStream<g2f> outStream)
{
	float3 p0 = input[0].vertex.xyz;
	float3 p1 = input[1].vertex.xyz;
	float3 p2 = input[2].vertex.xyz;

	float2 uv0 = input[0].uv;
	float2 uv1 = input[1].uv;
	float2 uv2 = input[2].uv;

	float3 center = (p0 + p1 + p2) / 3;

	float param = 1 + _EffectVector.w - dot(_EffectVector.xyz, center);

	if (param < 0) return;

	if (param >= 1) {
		outStream.Append(VertexOutput(p0, uv0));
		outStream.Append(VertexOutput(p1, uv1));
		outStream.Append(VertexOutput(p2, uv2));
		outStream.RestartStrip();
		return;
	}

	float seed = pid * 877;
	if (Random(seed) > _Density) return;

	param = saturate(1 - param);

	// Cube animation
	float rnd = Random(seed + 1); // random number, gradient noise
	float4 snoise = snoise_grad(float3(rnd * 2378.34, param * 0.8, 0));

	float move = saturate(param * 4 - 3); // stretch/move param
	move = move * move;

	float3 pos = center + snoise.xyz * 0.02; // cube position
	pos.y += move * rnd;

	float3 scale = float2(1 - move, 1 + move * 5).xyx; // cube scale anim
	scale *= 0.05 * saturate(1 + snoise.w * 2);

	float edge = 1 + 20 * smoothstep(0, 0.2, 0.2 - param); // Edge color(emission power);
	
	float fm = smoothstep(0.25, 0.5, param);
	fm *= 5 * (1 - smoothstep(0, 0.25, 0.5 - param));

	// Cube points calculation
	float morph = smoothstep(0.25, 0.5, param);
	float3 c_p0 = lerp(p2, pos + float3(-1, -1, -1) * scale, morph);
	float3 c_p1 = lerp(p2, pos + float3(+1, -1, -1) * scale, morph);
	float3 c_p2 = lerp(p0, pos + float3(-1, +1, -1) * scale, morph);
	float3 c_p3 = lerp(p1, pos + float3(+1, +1, -1) * scale, morph);
	float3 c_p4 = lerp(p2, pos + float3(-1, -1, +1) * scale, morph);
	float3 c_p5 = lerp(p2, pos + float3(+1, -1, +1) * scale, morph);
	float3 c_p6 = lerp(p0, pos + float3(-1, +1, +1) * scale, morph);
	float3 c_p7 = lerp(p1, pos + float3(+1, +1, +1) * scale, morph);

	// Vertex outputs
	outStream.Append(CubeVertex(c_p2, uv0, float3(0, 0, 1), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p0, uv2, float3(1, 0, 0), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p6, uv0, float3(0, 0, 1), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p4, uv2, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();

	outStream.Append(CubeVertex(c_p1, uv2, float3(0, 0, 1), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p3, uv1, float3(1, 0, 0), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p5, uv2, float3(0, 0, 1), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p7, uv1, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();		
									
	outStream.Append(CubeVertex(c_p0, uv2, float3(1, 0, 0), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p1, uv2, float3(1, 0, 0), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p4, uv2, float3(1, 0, 0), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p5, uv2, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();		
									
	outStream.Append(CubeVertex(c_p3, uv1, float3(0, 0, 1), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p2, uv0, float3(1, 0, 0), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p7, uv1, float3(0, 0, 1), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p6, uv0, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();		
									
	outStream.Append(CubeVertex(c_p1, uv2, float3(0, 0, 1), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p0, uv2, float3(0, 0, 1), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p3, uv1, float3(0, 1, 0), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p2, uv0, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();

	outStream.Append(CubeVertex(c_p4, uv2, float3(0, 0, 1), float2(0, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p5, uv2, float3(0, 0, 1), float2(1, 0), morph, edge, fm));
	outStream.Append(CubeVertex(c_p6, uv0, float3(0, 1, 0), float2(0, 1), morph, edge, fm));
	outStream.Append(CubeVertex(c_p7, uv1, float3(1, 0, 0), float2(1, 1), morph, edge, fm));
	outStream.RestartStrip();
}

fixed4 frag(g2f i) : SV_Target
{
	fixed4 col = tex2D(_MainTex, i.uv) + _EmissionColor * i.faceEmission;
	float3 bcc = i.edge.xyz;
	float3 fw = fwidth(bcc);
	float3 edge3 = min(smoothstep(fw / 2, fw, bcc), smoothstep(fw / 2, fw, 1 - bcc));
	float edge = 1 - min(min(edge3.x, edge3.y), edge3.z);

	col.xyz += _EdgeColor * i.edge.w * edge;
	return col;
}

#endif