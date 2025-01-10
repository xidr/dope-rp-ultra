#ifndef SURFACE_DATA_INCLUDED
#define SURFACE_DATA_INCLUDED

struct SurfaceData {
	float3 normal;
	float3 viewDirection;
	float3 color;
	float3 positionWS;
	float alpha;
	float metallic;
	float roughness;
	float3 f0;
	float depth;
	float3 specular;
	// float dither;
	bool isMetal;
	
	
	// // #if defined(MATERIAL_HAS_REFRACTION)
	// 	float etaRI;
	// 	float etaIR;
	// 	float transmission;
	// 	float uThickness;
	// 	float3  absorption;
	// // #endif
};

// TODO: make a dedicated structure for PBR material?

#endif