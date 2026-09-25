#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;


layout(set = 1, binding = 3) restrict readonly buffer params {
    float dt;
};

layout(set = 1, binding = 4) uniform sampler2D input_texture;

layout(set = 1, binding = 5) writeonly uniform image2D output_texture;

void main() {
    uint r = gl_GlobalInvocationID.x;
    uint theta = gl_GlobalInvocationID.y;
    
    if (r > theta/6) {
        vec4 mixture;
        vec2 velocity;
        ivec2 position = ivec2(r,theta);
        float wait_time;

        int radius = textureSize(input_texture, 0).x;
        int circumference = textureSize(input_texture, 0).y;

        mixture = texture(input_texture, vec2(r, theta));

        velocity.r = texture(input_texture, vec2(radius - r, circumference - theta)).r * 2 - 1;
        velocity.t = texture(input_texture, vec2(radius - r, circumference - theta)).g * 2 - 1;
    
        wait_time = texture(input_texture, vec2(radius - r, circumference - theta)).a;


        if (abs(velocity.r) > 1 / wait_time) {
            position.r += int(sign(velocity.r));
            position.t += 6 * int(sign(velocity.r));
        }
        if (abs(velocity.t) > 1 / wait_time) {
            position.t += int(sign(velocity.t));
            position.t = position.t % (6 * position.r);
        }
        
        if ((position == uvec2(r,theta))) {
            wait_time += dt;
        }

        imageStore(output_texture, ivec2(position), mixture);
        imageStore(output_texture, ivec2(radius - position.r, circumference - position.t), vec4(velocity, 0.0, wait_time));
    }
    
}