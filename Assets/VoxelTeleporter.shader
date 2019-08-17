Shader "Geometry/VoxelTeleporter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		[HDR] _EmissionColor("EmissionColor", Color) = (0, 0, 0, 0)
		[HDR] _EdgeColor("EdgeColor", Color) = (0, 0, 0, 0)
		_Density("Density", Range(0.0, 1.0)) = 0.05
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
			#pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "VoxelTeleporter.cginc"
            ENDCG
        }
    }
}
