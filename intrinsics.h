#include <emmintrin.h>

inline void add3xf32(f32 sum[3], f32 f1, f32 f2, f32 f3, 
                                 f32 g1, f32 g2, f32 g3){
    __m128 s = _mm_add_ps(_mm_set_ps(f1, f2, f3, 0), _mm_set_ps(g1, g2, g3, 0));
    sum[0] = s[3];
    sum[1] = s[2];
    sum[2] = s[1];
}

inline void add4xf32(f32 sum[4], f32 f1, f32 f2, f32 f3, f32 f4, 
                                 f32 g1, f32 g2, f32 g3, f32 g4){
    __m128 s = _mm_add_ps(_mm_set_ps(f1, f2, f3, f4), _mm_set_ps(g1, g2, g3, g4));
    sum[0] = s[3];
    sum[1] = s[2];
    sum[2] = s[1];
    sum[3] = s[0];
}

inline void subtract3xf32(f32 product[3], f32 f1, f32 f2, f32 f3, 
                                          f32 g1, f32 g2, f32 g3){
    __m128 prod = _mm_sub_ps(_mm_set_ps(f1, f2, f3, 0), _mm_set_ps(g1, g2, g3, 0));
    product[0] = prod[3];
    product[1] = prod[2];
    product[2] = prod[1];
}

inline void subtractxf32(f32 product[4], f32 f1, f32 f2, f32 f3, f32 f4, 
                                         f32 g1, f32 g2, f32 g3, f32 g4){
    __m128 prod = _mm_sub_ps(_mm_set_ps(f1, f2, f3, f4), _mm_set_ps(g1, g2, g3, g4));
    product[0] = prod[3];
    product[1] = prod[2];
    product[2] = prod[1];
    product[3] = prod[0];
}

inline void multiply3xf32(f32 product[3], f32 f1, f32 f2, f32 f3, 
                                          f32 g1, f32 g2, f32 g3){
    __m128 prod = _mm_mul_ps(_mm_set_ps(f1, f2, f3, 0), _mm_set_ps(g1, g2, g3, 0));
    product[0] = prod[3];
    product[1] = prod[2];
    product[2] = prod[1];
}

inline void multiply4xf32(f32 product[4], f32 f1, f32 f2, f32 f3, f32 f4, 
                                          f32 g1, f32 g2, f32 g3, f32 g4){
    __m128 prod = _mm_mul_ps(_mm_set_ps(f1, f2, f3, f4), _mm_set_ps(g1, g2, g3, g4));
    product[0] = prod[3];
    product[1] = prod[2];
    product[2] = prod[1];
    product[3] = prod[0];
}