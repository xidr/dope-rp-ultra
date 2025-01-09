#ifndef COMMON_MATERIAL_INCLUDED
#define COMMON_MATERIAL_INCLUDED

#define MIN_N_DOT_V 1e-4

#define MIN_PERCEPTUAL_ROUGHNESS 0.089
#define MIN_ROUGHNESS            0.007921

float clampNoV(float NoV) {
    // Neubelt and Pettineo 2013, "Crafting a Next-gen Material Pipeline for The Order: 1886"
    return max(NoV, MIN_N_DOT_V);
}

float3 computeDiffuseColor(const float3 baseColor, float metallic) {
    return baseColor.rgb * (1 - metallic);
}

float perceptualRoughnessToRoughness(float perceptualRoughness) {
    perceptualRoughness = clamp(perceptualRoughness, MIN_PERCEPTUAL_ROUGHNESS, 1.0);
    return perceptualRoughness * perceptualRoughness;
}

float3 computeReflectance(const float4 baseColor, float metallic, float reflectance) {
    return baseColor.rgb * metallic + 0.16 * reflectance * reflectance * (1.0 - metallic);
}

float f0ToIor(float f0) {
    float r = sqrt(f0);
    return (1.0 + r) / (1.0 - r);
}

#endif