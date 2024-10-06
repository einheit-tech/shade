#version 400
attribute vec3 gpu_Vertex;
attribute vec2 gpu_TexCoord;
uniform mat4 gpu_ModelViewProjectionMatrix;

varying vec2 texCoord;

void main(void) {
  texCoord = gpu_TexCoord;
  gl_Position = gpu_ModelViewProjectionMatrix * vec4(gpu_Vertex, 1.0);
}

