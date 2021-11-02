#version 330 core
layout(location = 0) out vec4 FragColor;

in vec2 TextureCoordinate;
in vec3 rawPosition;
in vec3 normal;
// in vec3 V;

uniform sampler2D diffuseTexture;
uniform samplerCube diffuseCubeTexture;
// precomputed shadow
// Hint: You may want to uncomment this to use shader map texture.
// uniform sampler2DShadow shadowMap;
uniform int isCube;

layout (std140) uniform light {
  // Projection * View matrix
  mat4 lightSpaceMatrix;
  // Position or direction of the light
  vec4 lightVector;
  // inner cutoff, outer cutoff, isSpotlight, isDirectionalLight
  vec4 coefficients;
};

layout (std140) uniform camera {
  // Projection * View matrix
  mat4 viewProjectionMatrix;
  // Position of the camera
  vec4 viewPosition;
};

void main() {
  vec4 diffuseTextureColor = texture(diffuseTexture, TextureCoordinate);
  vec4 diffuseCubeTextureColor = texture(diffuseCubeTexture, rawPosition);
  vec3 color = isCube == 1 ? diffuseCubeTextureColor.rgb : diffuseTextureColor.rgb;
  // Ambient intensity
  float ambient = 0.1;
  float ks = 0.75;
  float kd = 0.75;
  // TODO: vertex shader / fragment shader
  // Hint:
  //       1. how to write a vertex shader:
  //          a. The output is gl_Position and anything you want to pass to the fragment shader. (Apply matrix multiplication yourself)
  //       2. how to write a fragment shader:
  //          a. The output is FragColor (any var is OK)
  //       3. colors
  //          a. For point light & directional light, lighting = ambient + attenuation * shadow * (diffuse + specular)
  //          b. If you want to implement multiple light sources, you may want to use lighting = shadow * attenuation * (ambient + (diffuse + specular))
  //       4. attenuation
  //          a. spotlight & pointlight: see spec
  //          b. directional light = no
  //          c. Use formula from slides 'shading.ppt' page 20
  //       5. spotlight cutoff: inner and outer from coefficients.x and coefficients.y
  //       6. diffuse = kd * max(normal vector dot light direction, 0.0)
  //       7. specular = ks * pow(max(normal vector dot halfway direction), 0.0), 8.0);
  //       8. notice the difference of light direction & distance between directional light & point light
  //       9. we've set ambient & color for you
  vec3 result = vec3(0);
  float cutoff = coefficients.y;

  vec3 L = vec3(0);
  float theta = 0.0;
  float intensity = 1.0;
  float constant = 1.0; 
  float linear;
  float quadratic;
  float attenuation;
  float dist = length(vec3(lightVector) - rawPosition);
  if (coefficients.w == 1) {  // Direct light
    L = normalize(vec3(lightVector));
    attenuation = 1;
  } else if (coefficients.z == 1) {  // Spotlight
    L = normalize(vec3(viewPosition) - rawPosition);
    theta = dot(-L, vec3(lightVector));
    float epsilon = coefficients.x - coefficients.y;
    intensity = clamp((theta - coefficients.y) / epsilon, 0.0, 1.0);

    linear = 0.027;
    quadratic = 0.0028;
    attenuation = 1.0 / (constant + dist * linear + dist * dist * quadratic);
  } else {  // Point light
    L = normalize(vec3(lightVector) - rawPosition);
    linear = 0.014;
    quadratic = 0.007;
    attenuation = 1.0 / (constant + dist * linear + dist * dist * quadratic);
  }

  vec3 light = vec3(1.0, 1.0, 1.0);
  vec3 ambientLight = light * ambient;
  if ((theta > cutoff && coefficients.z == 1) || coefficients.z != 1) {
    vec3 V = normalize(vec3(viewPosition.x, viewPosition.y, viewPosition.z) - rawPosition);
    vec3 R = normalize(reflect(-L, normal));

    vec3 diffuseLight = light * kd * max(dot(L, normal), 0.0) * intensity * attenuation;
    vec3 specularLight = light * ks * pow(max(dot(R, V), 0.0), 8) * intensity * attenuation;

    result = diffuseLight;
  } else {
    result = ambientLight;
  }

  FragColor = vec4(color * result, 1.0);
}
