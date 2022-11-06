#version 140

uniform sampler2D tex;

varying vec2 vertex;
varying vec4 color;
varying vec2 texCoord;

uniform float time;
uniform vec2 resolution;

uniform float force = 0.025;
uniform vec2 center = vec2(0.5, 0.5);
uniform float size = 0.5;
uniform float thickness = 0.5;

void main(void) {
  float ratio = resolution.x / resolution.y;
  vec2 scaledUV = (texCoord - vec2(0.5, 0.0)) / vec2(ratio, 1.0) + vec2(0.5, 0.0);

  float distFromCenter = length(scaledUV - center);
  float mask =
    (1.0 - smoothstep(size - 0.1, size, distFromCenter)) *
    smoothstep(size - thickness - 0.1, size - thickness, distFromCenter);

  vec2 displacement = normalize(scaledUV - center) * force * mask;
  gl_FragColor = texture2D(tex, texCoord - displacement);
}

