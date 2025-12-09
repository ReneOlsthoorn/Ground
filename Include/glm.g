
dll glm function glmc_mat4_copy(ptr mat4_src, ptr mat4_dst);
dll glm function glmc_mat4_identity(ptr mat4);
dll glm function glmc_rotate(ptr mat4, f32 angle, ptr vec3_axis);
dll glm function glmc_mat4_zero(ptr mat4);
dll glm function glmc_mat4_scale(ptr mat4, f32 s);
dll glm function glmc_mat4_mulv(ptr mat4, ptr vec4_v, ptr vec4_dest);
dll glm function glmc_perspective(f32 fovy, f32 aspect, f32 nearZ, f32 farZ, ptr mat4_dest);
dll glm function glmc_lookat(ptr vec3_eye, ptr vec3_center, ptr vec3_up, ptr mat4_dest);
dll glm function glmc_mat4_mulN(ptr mat4Array, u32 lenArray, ptr mat4_dest);
dll glm function glmc_vec4(ptr vec3_v3, f32 last, ptr vec4_dest);
dll glm function glmc_vec4_zero(ptr vec4_v);
dll glm function glmc_vec4_copy(ptr vec4_v, ptr vec4_dest);
dll glm function glmc_rotate_x(ptr mat4_m, f32 rad, ptr mat4_dest);
dll glm function glmc_rotate_y(ptr mat4_m, f32 rad, ptr mat4_dest);
dll glm function glmc_rotate_z(ptr mat4_m, f32 rad, ptr mat4_dest);

#define VEC3 3
#define VEC4 4
#define MAT4 16
