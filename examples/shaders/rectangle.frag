#version 400

varying vec2 vertex;
varying vec2 texCoord;

uniform sampler2D tex;
uniform float time;
uniform vec2 resolution;

// See the "gl_FragCoord" section of https://thebookofshaders.com/03/
void main(void) {
  gl_FragColor = vec4(texCoord, 0.5, 1.0);
}

