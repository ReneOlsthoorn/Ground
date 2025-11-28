
dll chipmunk function cpSpaceNew();
dll chipmunk function cpSpaceSetGravity(ptr space, ptr gravity);

dll chipmunk function cpSegmentShapeNew(ptr cpBody, ptr a, ptr b, float radius);
dll chipmunk function cpSpaceGetStaticBody(ptr space);
dll chipmunk function cpShapeSetFriction(ptr shape, float friction);
dll chipmunk function cpSpaceAddShape(ptr space, ptr shape);
dll chipmunk function cpShapeSetElasticity(ptr shape, float elasticity);

dll chipmunk function cpMomentForCircle(float mass, float innerRadius, float outerRadius, ptr cpVectOffset) : float;

dll chipmunk function cpSpaceAddBody(ptr space, ptr body);
dll chipmunk function cpBodyNew(float m, float i);		// result: cpBody*
dll chipmunk function cpBodySetPosition(ptr cpBody, ptr cpVectPosition);
dll chipmunk function cpBodySetVelocity(ptr cpBody, ptr cpv);
dll chipmunk function cpBodySleep(ptr cpBody);
dll chipmunk function cpBodyIsSleeping(ptr cpBody);
dll chipmunk function cpBodyGetUserData(ptr cpBody) : int;
dll chipmunk function cpBodySetUserData(ptr cpBody, int data);

dll chipmunk function cpCircleShapeNew(ptr cpBody, float radius, ptr cpVectOffset);		// result: cpShape*

dll chipmunk function cpBodyGetPosition(ptr cpvectresult, ptr cpBody);	// result: cpVect
dll chipmunk function cpBodyGetVelocity(ptr cpvectresult, ptr cpBody);	// result: cpVect
dll chipmunk function cpBodyGetAngle(ptr cpBody) : float;
dll chipmunk function cpSpaceStep(ptr space, float dt);

dll chipmunk function cpShapeFree(ptr cpShape);
dll chipmunk function cpBodyFree(ptr cpBody);

dll chipmunk function cpSpaceFree(ptr cpSpace);


class CpVect {
	float x;
	float y;
}
CpVect cpvzero = CpVect(0.0, 0.0);
