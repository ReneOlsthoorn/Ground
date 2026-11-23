

class CpVect {
	f64 x;
	f64 y;
}
CpVect cpvzero = CpVect(0.0, 0.0);

class CpShapeFilter {
	int grp;
	int cat1;
	int cat2;
}

dll chipmunk function cpSpaceNew();
dll chipmunk function cpSpaceSetGravity(ptr space, CpVect gravity);

dll chipmunk function cpSegmentShapeNew(ptr cpBody, CpVect a, CpVect b, f64 radius);
dll chipmunk function cpSpaceGetStaticBody(ptr space);
dll chipmunk function cpShapeSetFriction(ptr shape, f64 friction);
dll chipmunk function cpShapeSetElasticity(ptr shape, f64 elasticity);
dll chipmunk function cpBoxShapeNew(ptr body, f64 width, f64 height, f64 radius) : ptr; //shape
dll chipmunk function cpSpaceReindexShapesForBody(ptr space, ptr body);

dll chipmunk function cpMomentForCircle(f64 mass, f64 innerRadius, f64 outerRadius, CpVect offset) : f64;

dll chipmunk function cpSpaceAddBody(ptr space, ptr body) : ptr;
dll chipmunk function cpBodyNew(f64 m, f64 i) : ptr;	// result: cpBody*
dll chipmunk function cpBodyNewKinematic();				// result: cpBody*
dll chipmunk function cpBodySetPosition(ptr cpBody, CpVect pos);
dll chipmunk function cpBodySetVelocity(ptr cpBody, CpVect velocity);
dll chipmunk function cpBodySetAngularVelocity(ptr cpBody, f64 angularVelocity);
dll chipmunk function cpBodySleep(ptr cpBody);
dll chipmunk function cpBodyIsSleeping(ptr cpBody);
dll chipmunk function cpBodyGetUserData(ptr cpBody) : int;
dll chipmunk function cpBodySetUserData(ptr cpBody, int data);
dll chipmunk function cpShapeFilterNew(int grp, int cat1, int cat2);
dll chipmunk function cpShapeSetFilter(ptr shape, ptr filter);
dll chipmunk function cpBodyNewStatic() : ptr;  //returns ptr body

dll chipmunk function cpCircleShapeNew(ptr cpBody, f64 radius, CpVect offset) : ptr;

dll chipmunk function cpBodyGetPosition(ptr cpBody) : CpVect;
dll chipmunk function cpBodyGetVelocity(ptr cpBody) : CpVect;
dll chipmunk function cpBodyGetAngle(ptr cpBody) : f64;
dll chipmunk function cpBodySetAngle(ptr cpBody, f64 angle);
dll chipmunk function cpSpaceStep(ptr space, f64 dt);
dll chipmunk function cpBodyApplyImpulseAtWorldPoint(ptr cpBody, CpVect impulse, CpVect point);
dll chipmunk function cpBodyApplyImpulseAtLocalPoint(ptr cpBody, CpVect impulse, CpVect point);

dll chipmunk function cpSpaceAddShape(ptr space, ptr shape) : ptr;
dll chipmunk function cpSpaceRemoveShape(ptr space, ptr shape);
dll chipmunk function cpShapeFree(ptr cpShape);
dll chipmunk function cpBodyFree(ptr cpBody);

dll chipmunk function cpSpaceFree(ptr cpSpace);
dll chipmunk function cpShapeGetSpace(ptr shape) : ptr;

