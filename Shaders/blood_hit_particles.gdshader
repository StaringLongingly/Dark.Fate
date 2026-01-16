// blood_hit_particles.gdshader
shader_type particles;
uniform vec3 target_position;
uniform vec3 emitter_position;
uniform vec3 emission_direction;
uniform float emission_direction_angle;
uniform float attraction_strength = 5.0;
uniform float max_speed = 10.0;
uniform float damping = 0.98;
uniform float initial_speed = 2.0;
uniform float stretch_factor = 2.0;
uniform float despawn_distance = 0.2;
uniform vec3 emission_box_extents = vec3(1.0, 1.0, 1.0);

// Random function for particle spawning
float rand_from_seed(inout uint seed) {
    int k;
    int s = int(seed);
    if (s == 0)
        s = 305420679;
    k = s / 127773;
    s = 16807 * (s - k * 127773) - 2836 * k;
    if (s < 0)
        s += 2147483647;
    seed = uint(s);
    return float(seed % uint(65536)) / 65535.0;
}

// Rotate a vector around an axis by an angle
vec3 rotate_around_axis(vec3 v, vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    mat3 rot = mat3(
        vec3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y + axis.z * s,  oc * axis.z * axis.x - axis.y * s),
        vec3(oc * axis.x * axis.y - axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z + axis.x * s),
        vec3(oc * axis.z * axis.x + axis.y * s,  oc * axis.y * axis.z - axis.x * s,  oc * axis.z * axis.z + c)
    );
    
    return rot * v;
}

void start() {
    uint alt_seed = RANDOM_SEED + uint(NUMBER);
    
    // Spawn exactly at emitter position (no random offset)
    TRANSFORM[3].xyz = emitter_position;
    
    // Start with identity rotation (will align to velocity in process)
    TRANSFORM[0] = vec4(1.0, 0.0, 0.0, 0.0);
    TRANSFORM[1] = vec4(0.0, 1.0, 0.0, 0.0);
    TRANSFORM[2] = vec4(0.0, 0.0, 1.0, 0.0);
    
    // Randomize emission direction within the cone angle
    vec3 randomized_direction = emission_direction;
    
    if (emission_direction_angle > 0.0) {
        // Get random angle within the cone
        float random_angle = rand_from_seed(alt_seed) * emission_direction_angle;
        // Get random rotation around the emission direction axis
        float random_rotation = rand_from_seed(alt_seed) * 6.28318530718; // 2*PI
        
        // Find a perpendicular vector to emission_direction
        vec3 perp;
        if (abs(emission_direction.y) < 0.99) {
            perp = normalize(cross(emission_direction, vec3(0.0, 1.0, 0.0)));
        } else {
            perp = normalize(cross(emission_direction, vec3(1.0, 0.0, 0.0)));
        }
        
        // First rotate by the cone angle around the perpendicular axis
        randomized_direction = rotate_around_axis(emission_direction, perp, random_angle);
        
        // Then rotate around the original emission direction axis
        randomized_direction = rotate_around_axis(randomized_direction, emission_direction, random_rotation);
    }
    
    // Apply randomized direction with initial speed
    VELOCITY = randomized_direction * initial_speed;
    
    // Use CUSTOM.x to track if particle is disabled (0.0 = active, 1.0 = disabled)
    CUSTOM.x = 0.0;
}

void process() {
    // Check if particle was already disabled
    if (CUSTOM.x > 0.5) {
        // Keep it invisible and stationary
        TRANSFORM[0] = vec4(0.0, 0.0, 0.0, 0.0);
        TRANSFORM[1] = vec4(0.0, 0.0, 0.0, 0.0);
        TRANSFORM[2] = vec4(0.0, 0.0, 0.0, 0.0);
        VELOCITY = vec3(0.0);
        TRANSFORM[3].xyz += VELOCITY * DELTA;
    } else {
        // Get current particle position
        vec3 particle_pos = TRANSFORM[3].xyz;
        
        // Calculate direction to target
        vec3 direction = target_position - particle_pos;
        float distance = length(direction);
        
        // Despawn if close enough to target (scale to zero and mark as disabled)
        if (distance < despawn_distance) {
            TRANSFORM[0] = vec4(0.0, 0.0, 0.0, 0.0);
            TRANSFORM[1] = vec4(0.0, 0.0, 0.0, 0.0);
            TRANSFORM[2] = vec4(0.0, 0.0, 0.0, 0.0);
            VELOCITY = vec3(0.0);
            CUSTOM.x = 1.0;  // Mark as permanently disabled
        } else {
            // Scale particle based on distance (smaller when closer)
            float scale_factor = clamp(distance / 2.0, 0.1, 1.0);
            
            // Only apply attraction if not too close (prevents orbiting)
            if (distance > 0.5) {
                direction = normalize(direction);
                
                // Apply attraction force
                VELOCITY += direction * attraction_strength * DELTA;
                
                // Apply damping to prevent excessive speed
                VELOCITY *= damping;
                
                // Clamp velocity to max speed
                float speed = length(VELOCITY);
                if (speed > max_speed) {
                    VELOCITY = normalize(VELOCITY) * max_speed;
                }
            } else {
                // Slow down when very close to target
                VELOCITY *= 0.9;
            }
            
            // Stretch particle along velocity direction (teardrop shape)
            float speed = length(VELOCITY);
            if (speed > 0.1) {
                vec3 vel_dir = normalize(VELOCITY);
                
                // Create orientation matrix aligned to velocity
                vec3 up = abs(vel_dir.y) < 0.99 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
                vec3 right = normalize(cross(up, vel_dir));
                up = cross(vel_dir, right);
                
                // Apply stretch based on speed
                float stretch = 1.0 + (speed / max_speed) * stretch_factor;
                
                // Apply scale factor to all axes
                TRANSFORM[0] = vec4(right * scale_factor, 0.0);
                TRANSFORM[1] = vec4(up * scale_factor, 0.0);
                TRANSFORM[2] = vec4(vel_dir * stretch * scale_factor, 0.0);  // Stretch along velocity
            } else {
                // If not moving fast, just apply uniform scale
                TRANSFORM[0] = vec4(scale_factor, 0.0, 0.0, 0.0);
                TRANSFORM[1] = vec4(0.0, scale_factor, 0.0, 0.0);
                TRANSFORM[2] = vec4(0.0, 0.0, scale_factor, 0.0);
            }
        }
        
        // Update position
        TRANSFORM[3].xyz += VELOCITY * DELTA;
    }
}