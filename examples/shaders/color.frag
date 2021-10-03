#version 330

varying vec2 vertex;
varying vec2 texCoord;
varying vec4 color;

uniform sampler2D tex;
uniform float time;
uniform vec2 resolution;

void main(void)
{
  float halfT = time * 0.5;
  vec4 c = vec4(
    abs(sin(halfT)) * color.r,
    abs(cos(halfT)) * color.g,
    abs(tan(halfT)) * color.b,
    1.0
  );
  gl_FragColor = texture2D(tex, texCoord) * c;
}

