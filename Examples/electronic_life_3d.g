

// Following 2 functions are also in utils.g
function DegreeToRadians(float angle_deg) : float {
	return angle_deg * MATH_PI / 180.0;
}
function ValidRadian_f32(f32 radian) : f32 {
	f32 valid = radian;
	while (valid >= MATH_2PI)
		valid = valid - MATH_2PI;
	f32 floorValue = 0.0;
	while (valid < floorValue)
		valid = valid + MATH_2PI;
	return valid;
}

#define CUBE_SIZE 24

f32[] cube = [ -0.5,-0.5,-0.5,1.0,  0.5,-0.5,-0.5,1.0,
			    0.5, 0.5,-0.5,1.0,  -0.5,0.5,-0.5,1.0,
               -0.5,-0.5, 0.5,1.0,  0.5,-0.5, 0.5,1.0,
                0.5, 0.5, 0.5,1.0, -0.5, 0.5, 0.5,1.0,

			   -0.4,-0.4,-0.4,1.0,  0.4,-0.4,-0.4,1.0,
			    0.4, 0.4,-0.4,1.0, -0.4, 0.4,-0.4,1.0,
               -0.4,-0.4, 0.4,1.0,  0.4,-0.4, 0.4,1.0,
                0.4, 0.4, 0.4,1.0, -0.4, 0.4, 0.4,1.0,

			   -0.2,-0.2,-0.2,1.0,  0.2,-0.2,-0.2,1.0,
			    0.2, 0.2,-0.2,1.0, -0.2, 0.2,-0.2,1.0,
               -0.2,-0.2, 0.2,1.0,  0.2,-0.2, 0.2,1.0,
                0.2, 0.2, 0.2,1.0, -0.2, 0.2, 0.2,1.0 ] asm; 


f32[CUBE_SIZE*VEC3] ndcCube = [ ] asm;


f32[16] model = [ ] asm;
f32[16] view = [ ] asm;
f32[16] proj = [ ] asm;
f32[16] mvp = [ ] asm;
ptr[3] matrixArray = [ proj, view, model ];

/*
Local -> Model -> World
World -> View  -> View/Eye
View  -> Proj  -> Clip
Clip  / w      -> NDC (Normalized Device Coordinates)
NDC  -> Viewport -> Screencoordinates

final_clip_pos   = proj x view x model x local_position;   ->  Clip Space
final_ndc        = final_clip_pos / final_clip_pos.w;      ->  NDC
final_screen_pos = viewport_transform(final_ndc);          ->  Screen Space
*/


// Model
//glm.glmc_mat4_identity(model);
//f32[3] vec3_1 = [ 1.0, 0.0, 0.0 ] asm;
//f32[3] vec3_2 = [ 0.0, 1.0, 0.0 ] asm;
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_1);
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_2);
//glm_translate(model, (vec3){0.0f, 0.0f, -3.0f});


// View
f32[3] vec3_eye = [ 0.0, 0.0, 8.5 ] asm;
f32[3] vec3_center = [ 0.0, 0.0, 0.0 ] asm;
f32[3] vec3_up = [ 0.0, 1.0, 0.0 ] asm;
glm.glmc_mat4_identity(view);
glm.glmc_lookat(vec3_eye, vec3_center, vec3_up, view);


// Projection
glm.glmc_mat4_identity(proj);
glm.glmc_perspective(DegreeToRadians(60.0), 1280.0 / 720.0, 0.1, 100.0, proj);


// mvp matrix is the multiplication of the proj, view and model matrices.
glm.glmc_mat4_mulN(matrixArray, 3, mvp);


// Below is the Compare function for the qsort of the ndcCube.
asm procedures {
ndcCube_Compare:
; rcx = ptr to element 1 (element is vec3) , rdx = pointer to element 2
  xor	eax, eax
  mov	eax, dword [rcx+8]	; retrieve the f32 Z in vec3
  sub	rsp, 8
  mov	[rsp], eax
  movss	xmm0, dword [rsp]
  mov	eax, dword [rdx+8]
  mov	[rsp], eax
  movss	xmm1, dword [rsp]
  add	rsp, 8
  ucomiss xmm0, xmm1		; compare the two z f32's.
  jb    .exitLess
  ja    .exitGreater
  xor	eax, eax        ; eax = 0
  ret
.exitLess:
  mov	eax, -1
  ret
.exitGreater:
  mov	eax, 1
  ret
}


ptr[CUBE_SIZE] cubePointBodies = [];
ptr[CUBE_SIZE] cubePointShapes = [];


f32[VEC4] tmpVec4 = [] asm;
f32 cube_XRotation = 0.0;
f32 cube_YRotation = 0.0;
f32 cube_ZRotation = 0.0;

function RenderCube() {
	
	cube_XRotation = cube_XRotation + 0.01;
	cube_XRotation = ValidRadian_f32(cube_XRotation);
	cube_YRotation = cube_YRotation + 0.02;
	cube_YRotation = ValidRadian_f32(cube_YRotation);
	//cube_ZRotation = cube_ZRotation + 0.02;
	//cube_ZRotation = ValidRadian_f32(cube_ZRotation);

	glm.glmc_mat4_identity(model);
	glm.glmc_rotate_x(model, cube_XRotation, model);
	glm.glmc_rotate_y(model, cube_YRotation, model);
	glm.glmc_rotate_z(model, cube_ZRotation, model);

	glm.glmc_mat4_mulN(matrixArray, 3, mvp);

	for (i in 0 ..< CUBE_SIZE) {
		glm.glmc_mat4_mulv(mvp, &cube[i*VEC4], tmpVec4);

		float ndc_x = tmpVec4[0] / tmpVec4[3];
		float ndc_y = tmpVec4[1] / tmpVec4[3];
		float ndc_z = tmpVec4[2] / tmpVec4[3];   // depth

		ndcCube[i*VEC3] = ndc_x;
		ndcCube[i*VEC3+1] = ndc_y;
		ndcCube[i*VEC3+2] = ndc_z;
	}

	sdl3.SDL_qsort(ndcCube, CUBE_SIZE, 3*sizeof(f32), g.ndcCube_Compare);

	for (i in 0 ..< CUBE_SIZE) {
		float x = ((ndcCube[i*VEC3] + 0.5) * 1280.0) - 420.0;
		float y = ((ndcCube[i*VEC3+1] + 0.5) * 720.0) + -36.0;

		//float ballSize = (0.99 - ndcCube[i*VEC3+2]) * 1500.0;

		cpv.x = x;
		cpv.y = y;
		chipmunk.cpBodySetPosition(cubePointBodies[i], cpv);
	}
}

