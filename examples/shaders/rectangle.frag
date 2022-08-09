#version 330

varying vec2 vertex;
varying vec2 texCoord;
varying vec4 color;

uniform sampler2D tex;
uniform float time;
uniform vec2 resolution;

// See the "gl_FragCoord" section of https://thebookofshaders.com/03/
void main(void) {
  vec2 st = gl_FragCoord.xy / resolution;
  gl_FragColor = vec4(st.x, st.y, 0.0, 1.0);
}

