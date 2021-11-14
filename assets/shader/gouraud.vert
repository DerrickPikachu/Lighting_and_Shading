#version 330 core
// x, y, z
layout(location = 0) in vec3 Position_in;
// x, y, z
layout(location = 1) in vec3 Normal_in;
// u, v
layout(location = 2) in vec2 TextureCoordinate_in;
// Hint: Gouraud shading calculates per vertex color, interpolate in fs
// You may want to add some out here
out vec3 rawPosition;
out vec2 TextureCoordinate;
out vec3 lightColor;
/*out vec3 ambientLight;
out vec3 cameraPos;
out vec3 lightDirection;
out float isSpotlight;
out float cutoff;*/

// Uniform blocks
// https://www.khronos.org/opengl/wiki/Interface_Block_(GLSL)

layout (std140) uniform model {
  // Model matrix
  mat4 modelMatrix;
  // mat4(inverse(transpose(mat3(modelMatrix)))), precalculate using CPU for efficiency
  mat4 normalMatrix;
};

layout (std140) uniform camera {
  // Camera's projection * view matrix
  mat4 viewProjectionMatrix;
  // Position of the camera
  vec4 viewPosition;
};

layout (std140) uniform light {
  // Light's projection * view matrix
  // Hint: If you want to implement shadow, you may use this.
  mat4 lightSpaceMatrix;
  // Position or direction of the light
  vec4 lightVector;
  // inner cutoff, outer cutoff, isSpotlight, isDirectionalLight
  vec4 coefficients;
};

// precomputed shadow
// Hint: You may want to uncomment this to use shader map texture.
// uniform sampler2DShadow shadowMap;

void main() {
  TextureCoordinate = TextureCoordinate_in;
  rawPosition = mat3(modelMatrix) * Position_in;
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
  // Example without lighting :)
  gl_Position = viewProjectionMatrix * modelMatrix * vec4(Position_in, 1.0);

  /*cameraPos = vec3(viewPosition);
  lightDirection = vec3(lightVector);
  isSpotlight = coefficients.z;
  cutoff = coefficients.y;*/
  vec4 tem = modelMatrix * vec4(Position_in, 1.0);
  vec3 vertexPosition = vec3(tem.x / tem.w, tem.y / tem.w, tem.z / tem.w);
  vec3 result = vec3(0);
  float cutoff = coefficients.y;

  vec3 L = vec3(0);
  float theta = 0.0;
  float intensity = 1.0;
  float constant = 1.0; 
  float linear;
  float quadratic;
  float attenuation;
  float dist = length(vec3(lightVector) - vertexPosition);
  if (coefficients.w == 1) {  // Direct light
    L = normalize(vec3(lightVector));
    attenuation = 0.65;
  } else if (coefficients.z == 1) {  // Spot light
    L = normalize(vec3(viewPosition) - vertexPosition);
    theta = dot(-L, normalize(vec3(lightVector)));
    float epsilon = coefficients.x - coefficients.y;
    intensity = clamp((theta - coefficients.y) / epsilon, 0.0, 1.0);

    linear = 0.027;
    quadratic = 0.0028;
    attenuation = 1.0 / (constant + dist * linear + dist * dist * quadratic);
  } else {  // Point light
    L = normalize(vec3(lightVector) - vertexPosition);
    linear = 0.014;
    quadratic = 0.007;
    attenuation = 1.0 / (constant + dist * linear + dist * dist * quadratic);
  }

  vec3 light = vec3(1.0, 1.0, 1.0);
  vec3 ambientLight = light * ambient;
  vec3 N = normalize(vec3(normalMatrix * vec4(Normal_in, 1.0)));
  vec3 V = normalize(vec3(viewPosition.x, viewPosition.y, viewPosition.z) - vertexPosition);
  vec3 R = normalize(reflect(-L, N));

  vec3 diffuseLight = light * kd * max(dot(N, L), 0.0) * intensity * attenuation;
  vec3 specularLight = light * ks * pow(max(dot(R, V), 0), 8) * intensity * attenuation;

  result = (ambientLight + diffuseLight + specularLight);

  lightColor = result;
}
