// Adelson's Checkerboard Shadow Illusion — Raymarched
//
// Copyright (c) 2025-2026 Alexander Forsythe and Brian Funt
// Simon Fraser University, Burnaby, British Columbia, Canada
//
// Licensed under MIT. See LICENSE file for details.

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURF_DIST 0.01

// SDFs

float sdCappedCylinder( vec3 p, float h, float r ) {
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(r,h);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

// Scene is a cylinder on a checkerboard slab
// Returns vec2(distance, materialID)  — 1.0 = floor, 2.0 = cylinder
vec2 map(vec3 p) {
    vec3 cylinderPos = p - vec3(1.2, 1.0, 1.2);
    float cylinder = sdCappedCylinder(cylinderPos, 1.0, 0.8);

    vec3 floorPos = p - vec3(0.0, -0.1, 0.0);
    float floorObj = sdBox(floorPos, vec3(2.5, 0.1, 2.5));

    if (cylinder < floorObj) {
        return vec2(cylinder, 2.0);
    } else {
        return vec2(floorObj, 1.0);
    }
}

vec2 rayMarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    float m = 0.0;

    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        vec2 dS = map(p);
        dO += dS.x;
        m = dS.y;
        if(dO > MAX_DIST || dS.x < SURF_DIST) break;
    }
    return vec2(dO, m);
}

vec3 GetNormal(vec3 p) {
    float d = map(p).x;
    vec2 e = vec2(0.01, 0);
    vec3 n = d - vec3(
        map(p-e.xyy).x,
        map(p-e.yxy).x,
        map(p-e.yyx).x);
    return normalize(n);
}

// Soft shadows — hard shadows break the illusion
float softShadow(vec3 ro, vec3 rd, float k) {
    float res = 1.0;
    float ph = 1e20;
    for(float t=0.1; t<10.0; ) {
        float h = map(ro + rd*t).x;
        if(h<0.001) return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord-.5*iResolution.xy)/iResolution.y;
    uv *= 0.22; // Zoom — smaller = wider FOV, larger = tighter crop

    // Camera — ro = eye position, lookAt = target point
    // Try ro = vec3(0, 10, -0.1) for a top-down view
    vec3 ro = vec3(15.0, 10.0, -15.0);
    vec3 lookAt = vec3(0.5, 0.0, 0.5);

    vec3 f = normalize(lookAt - ro);
    vec3 r = normalize(cross(vec3(0,1,0), f));
    vec3 u = cross(f, r);
    vec3 rd = normalize(f + uv.x*r + uv.y*u);

    vec2 d = rayMarch(ro, rd);

    vec3 col = vec3(1.0);

    // Light — move X/Z to shift the shadow across the board
    vec3 lightPos = vec3(20.0, 8.0, 20.0);

    if(d.x < MAX_DIST) {
        vec3 p = ro + rd * d.x;
        vec3 n = GetNormal(p);
        vec3 lightDir = normalize(lightPos - p);

        vec3 albedo = vec3(0.0);

        // Tile values chosen so lit dark ≈ shadowed light ≈ 0.18
        vec3 DARK_TILE = vec3(0.225);
        vec3 LIGHT_TILE = vec3(0.9);

        if (d.y == 1.0) {
            // scale — raise for smaller/denser tiles, lowfer for bigger ones
            float scale = 1.48;
            float fCheck = mod(floor(p.x * scale) + floor(p.z * scale), 2.0);
            albedo = (fCheck < 0.5) ? DARK_TILE : LIGHT_TILE;
        }
        else if (d.y == 2.0) {
            albedo = vec3(0.2, 0.6, 0.3);
        }

        // Lighting
        float diff = max(dot(n, lightDir), 0.0);
        float shadow = softShadow(p + n*0.02, lightDir, 6.0);

        // Tweak these together to keep the illusion balanced
        float ambient = 0.2;
        float lightIntensity = 2.2;

        vec3 diffuseLight = diff * shadow * lightIntensity * vec3(1.0);

        col = albedo * (diffuseLight + ambient);
    }

    // Inverse simple EOTF
    col = pow(col, vec3(1.0/2.2));

    fragColor = vec4(col, 1.0);
}
