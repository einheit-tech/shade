#version 140

varying vec2 vertex;
varying vec4 color;
varying vec2 texCoord;

uniform float time;
uniform vec2 resolution;

uniform vec3 bgColor = vec3(0.906, 0.661, .212);
uniform vec3 borderColor = vec3(0.148, 0.125, .182);
uniform float hexagonSize = 1.;
uniform float xSpeed = -0.04;
uniform float ySpeed = 0.;

// 1.73 is a distance factor for a hexagon.
const vec2 hexRatio = vec2(1.0, 1.73);
const vec2 halfRatio = hexRatio * 0.5;

float hexDist(vec2 p) {
  p = abs(p);
  float c = dot(p, normalize(hexRatio));
  return max(c, p.x);
}

vec4 hexCoords(vec2 uv) {
  vec2 a = mod(uv, hexRatio) - halfRatio;
  vec2 b = mod(uv - halfRatio, hexRatio) - halfRatio;
  vec2 gv = dot(a, a) < dot(b, b) ? a : b;
  vec2 id = uv - gv;
  return vec4(gv.x, gv.y, id.x, id.y);
}

void main(void) {
  vec3 col = bgColor;
  vec2 uv = (gl_FragCoord.xy - resolution * 0.5) / resolution.y;
  uv *= 10.0 / hexagonSize;

  vec4 coord = hexCoords(uv + time * vec2(xSpeed, ySpeed));
  float x = atan(coord.x, coord.y);
  float y = 0.5 - hexDist(coord.xy);
  vec4 hc = vec4(x, y, coord.z, coord.w);

  float sand =
    (0.5 * sin(hc.z) + 0.5) * 0.1 +
    (0.5 * sin(hc.z + cos(hc.z - time * ySpeed) + hc.w - time * 0.8) + 0.5) * 0.15;

  float c = smoothstep(0.0, 1.0, sand);
  col += c;
  gl_FragColor = vec4(col, 1.0);
}

