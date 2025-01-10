#ifndef COMMON_MATH_INCLUDED
#define COMMON_MATH_INCLUDED

// #define PI 3.141592

static const half  HALF_POINT_ONE   = half(0.1);
static const half  HALF_MINUS_ONE   = half(-1.0);
static const half  HALF_ZERO        = half(0.0);
static const half  HALF_HALF        = half(0.5);
static const half  HALF_ONE         = half(1.0);
static const half4 HALF4_ONE        = half4(1.0, 1.0, 1.0, 1.0);
static const half  HALF_TWO         = half(2.0);
static const half  HALF_TWO_PI      = half(6.28318530717958647693);
static const half  HALF_FOUR        = half(4.0);
static const half  HALF_NINE        = half(9.0);
static const half  HALF_HUNDRED     = half(100.0);

/**
 * Computes x^5 using only multiply operations.
 *
 * @public-api
 */

// float pow_v(float3 x, float y)
// {
// 	return float3(pow(x.x, y), pow(x.y, y), pow(x.z, y));
// }



// float pow(float x, float y)
// {
// 	return exp(log(x) * y);
// }

float pow2(float x) {
	return x * x;
}

float pow4(float x) {
	float x2 = x * x;
	return x2 * x2;
}

float pow5(float x) {
	float x2 = x * x;
	return x2 * x2 * x;
}

float Square (float v) {
	return v * v;
}

float DistanceSquared(float3 pA, float3 pB) {
	return dot(pA - pB, pA - pB);
}

// Logical operations

float4 when_eq(float4 x, float4 y) {
	return 1.0 - abs(sign(x - y));
}

float4 when_neq(float4 x, float4 y) {
	return abs(sign(x - y));
}

float4 when_gt(float4 x, float4 y) {
	return max(sign(x - y), 0.0);
}

float4 when_lt(float4 x, float4 y) {
	return max(sign(y - x), 0.0);
}

float4 when_ge(float4 x, float4 y) {
	return 1.0 - when_lt(x, y);
}

float4 when_le(float4 x, float4 y) {
	return 1.0 - when_gt(x, y);
}

// For usage with outputs from the comparisons above

float4 and(float4 a, float4 b) {
	return a * b;
}

float4 or(float4 a, float4 b) {
	return min(a + b, 1.0);
}

float4 xor(float4 a, float4 b) {
	return (a + b) % 2.0;
}

float4 not(float4 a) {
	return 1.0 - a;
}

// float4 FindTangentFromNormalWS(float3 nowmalWS, float incodedTangent)
// {
// 	float3 rot = float3(1/PI, incodedTangent * PI, 0);
// 	float rotY;
// 	float rotX;
// 	float rotZ;
// 	float4x4 a = ((cos(rotY) * cos(rotZ), sin(rotX) * sin(rotY) * cos)
//
// 	float3x3 RotX = 
// }


#endif