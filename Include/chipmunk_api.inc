
  import  chipmunk, \
	chipmunk_cpArbiterCallWildcardBeginA,'cpArbiterCallWildcardBeginA',\
	chipmunk_cpArbiterCallWildcardBeginB,'cpArbiterCallWildcardBeginB',\
	chipmunk_cpArbiterCallWildcardPostSolveA,'cpArbiterCallWildcardPostSolveA',\
	chipmunk_cpArbiterCallWildcardPostSolveB,'cpArbiterCallWildcardPostSolveB',\
	chipmunk_cpArbiterCallWildcardPreSolveA,'cpArbiterCallWildcardPreSolveA',\
	chipmunk_cpArbiterCallWildcardPreSolveB,'cpArbiterCallWildcardPreSolveB',\
	chipmunk_cpArbiterCallWildcardSeparateA,'cpArbiterCallWildcardSeparateA',\
	chipmunk_cpArbiterCallWildcardSeparateB,'cpArbiterCallWildcardSeparateB',\
	chipmunk_cpArbiterGetBodies,'cpArbiterGetBodies',\
	chipmunk_cpArbiterGetContactPointSet,'cpArbiterGetContactPointSet',\
	chipmunk_cpArbiterGetCount,'cpArbiterGetCount',\
	chipmunk_cpArbiterGetDepth,'cpArbiterGetDepth',\
	chipmunk_cpArbiterGetFriction,'cpArbiterGetFriction',\
	chipmunk_cpArbiterGetNormal,'cpArbiterGetNormal',\
	chipmunk_cpArbiterGetPointA,'cpArbiterGetPointA',\
	chipmunk_cpArbiterGetPointB,'cpArbiterGetPointB',\
	chipmunk_cpArbiterGetRestitution,'cpArbiterGetRestitution',\
	chipmunk_cpArbiterGetShapes,'cpArbiterGetShapes',\
	chipmunk_cpArbiterGetSurfaceVelocity,'cpArbiterGetSurfaceVelocity',\
	chipmunk_cpArbiterGetUserData,'cpArbiterGetUserData',\
	chipmunk_cpArbiterIgnore,'cpArbiterIgnore',\
	chipmunk_cpArbiterIsFirstContact,'cpArbiterIsFirstContact',\
	chipmunk_cpArbiterIsRemoval,'cpArbiterIsRemoval',\
	chipmunk_cpArbiterSetContactPointSet,'cpArbiterSetContactPointSet',\
	chipmunk_cpArbiterSetFriction,'cpArbiterSetFriction',\
	chipmunk_cpArbiterSetRestitution,'cpArbiterSetRestitution',\
	chipmunk_cpArbiterSetSurfaceVelocity,'cpArbiterSetSurfaceVelocity',\
	chipmunk_cpArbiterSetUserData,'cpArbiterSetUserData',\
	chipmunk_cpArbiterTotalImpulse,'cpArbiterTotalImpulse',\
	chipmunk_cpArbiterTotalKE,'cpArbiterTotalKE',\
	chipmunk_cpAreaForCircle,'cpAreaForCircle',\
	chipmunk_cpAreaForPoly,'cpAreaForPoly',\
	chipmunk_cpAreaForSegment,'cpAreaForSegment',\
	chipmunk_cpBBTreeAlloc,'cpBBTreeAlloc',\
	chipmunk_cpBBTreeInit,'cpBBTreeInit',\
	chipmunk_cpBBTreeNew,'cpBBTreeNew',\
	chipmunk_cpBBTreeOptimize,'cpBBTreeOptimize',\
	chipmunk_cpBBTreeSetVelocityFunc,'cpBBTreeSetVelocityFunc',\
	chipmunk_cpBodyActivate,'cpBodyActivate',\
	chipmunk_cpBodyActivateStatic,'cpBodyActivateStatic',\
	chipmunk_cpBodyAlloc,'cpBodyAlloc',\
	chipmunk_cpBodyApplyForceAtLocalPoint,'cpBodyApplyForceAtLocalPoint',\
	chipmunk_cpBodyApplyForceAtWorldPoint,'cpBodyApplyForceAtWorldPoint',\
	chipmunk_cpBodyApplyImpulseAtLocalPoint,'cpBodyApplyImpulseAtLocalPoint',\
	chipmunk_cpBodyApplyImpulseAtWorldPoint,'cpBodyApplyImpulseAtWorldPoint',\
	chipmunk_cpBodyDestroy,'cpBodyDestroy',\
	chipmunk_cpBodyEachArbiter,'cpBodyEachArbiter',\
	chipmunk_cpBodyEachConstraint,'cpBodyEachConstraint',\
	chipmunk_cpBodyEachShape,'cpBodyEachShape',\
	chipmunk_cpBodyFree,'cpBodyFree',\
	chipmunk_cpBodyGetAngle,'cpBodyGetAngle',\
	chipmunk_cpBodyGetAngularVelocity,'cpBodyGetAngularVelocity',\
	chipmunk_cpBodyGetCenterOfGravity,'cpBodyGetCenterOfGravity',\
	chipmunk_cpBodyGetForce,'cpBodyGetForce',\
	chipmunk_cpBodyGetMass,'cpBodyGetMass',\
	chipmunk_cpBodyGetMoment,'cpBodyGetMoment',\
	chipmunk_cpBodyGetPosition,'cpBodyGetPosition',\
	chipmunk_cpBodyGetRotation,'cpBodyGetRotation',\
	chipmunk_cpBodyGetSpace,'cpBodyGetSpace',\
	chipmunk_cpBodyGetTorque,'cpBodyGetTorque',\
	chipmunk_cpBodyGetType,'cpBodyGetType',\
	chipmunk_cpBodyGetUserData,'cpBodyGetUserData',\
	chipmunk_cpBodyGetVelocity,'cpBodyGetVelocity',\
	chipmunk_cpBodyGetVelocityAtLocalPoint,'cpBodyGetVelocityAtLocalPoint',\
	chipmunk_cpBodyGetVelocityAtWorldPoint,'cpBodyGetVelocityAtWorldPoint',\
	chipmunk_cpBodyInit,'cpBodyInit',\
	chipmunk_cpBodyIsSleeping,'cpBodyIsSleeping',\
	chipmunk_cpBodyKineticEnergy,'cpBodyKineticEnergy',\
	chipmunk_cpBodyLocalToWorld,'cpBodyLocalToWorld',\
	chipmunk_cpBodyNew,'cpBodyNew',\
	chipmunk_cpBodyNewKinematic,'cpBodyNewKinematic',\
	chipmunk_cpBodyNewStatic,'cpBodyNewStatic',\
	chipmunk_cpBodySetAngle,'cpBodySetAngle',\
	chipmunk_cpBodySetAngularVelocity,'cpBodySetAngularVelocity',\
	chipmunk_cpBodySetCenterOfGravity,'cpBodySetCenterOfGravity',\
	chipmunk_cpBodySetForce,'cpBodySetForce',\
	chipmunk_cpBodySetMass,'cpBodySetMass',\
	chipmunk_cpBodySetMoment,'cpBodySetMoment',\
	chipmunk_cpBodySetPosition,'cpBodySetPosition',\
	chipmunk_cpBodySetPositionUpdateFunc,'cpBodySetPositionUpdateFunc',\
	chipmunk_cpBodySetTorque,'cpBodySetTorque',\
	chipmunk_cpBodySetType,'cpBodySetType',\
	chipmunk_cpBodySetUserData,'cpBodySetUserData',\
	chipmunk_cpBodySetVelocity,'cpBodySetVelocity',\
	chipmunk_cpBodySetVelocityUpdateFunc,'cpBodySetVelocityUpdateFunc',\
	chipmunk_cpBodySleep,'cpBodySleep',\
	chipmunk_cpBodySleepWithGroup,'cpBodySleepWithGroup',\
	chipmunk_cpBodyUpdatePosition,'cpBodyUpdatePosition',\
	chipmunk_cpBodyUpdateVelocity,'cpBodyUpdateVelocity',\
	chipmunk_cpBodyWorldToLocal,'cpBodyWorldToLocal',\
	chipmunk_cpBoxShapeInit,'cpBoxShapeInit',\
	chipmunk_cpBoxShapeInit2,'cpBoxShapeInit2',\
	chipmunk_cpBoxShapeNew,'cpBoxShapeNew',\
	chipmunk_cpBoxShapeNew2,'cpBoxShapeNew2',\
	chipmunk_cpCentroidForPoly,'cpCentroidForPoly',\
	chipmunk_cpCircleShapeAlloc,'cpCircleShapeAlloc',\
	chipmunk_cpCircleShapeGetOffset,'cpCircleShapeGetOffset',\
	chipmunk_cpCircleShapeGetRadius,'cpCircleShapeGetRadius',\
	chipmunk_cpCircleShapeInit,'cpCircleShapeInit',\
	chipmunk_cpCircleShapeNew,'cpCircleShapeNew',\
	chipmunk_cpCircleShapeSetOffset,'cpCircleShapeSetOffset',\
	chipmunk_cpCircleShapeSetRadius,'cpCircleShapeSetRadius',\
	chipmunk_cpConstraintDestroy,'cpConstraintDestroy',\
	chipmunk_cpConstraintFree,'cpConstraintFree',\
	chipmunk_cpConstraintGetBodyA,'cpConstraintGetBodyA',\
	chipmunk_cpConstraintGetBodyB,'cpConstraintGetBodyB',\
	chipmunk_cpConstraintGetCollideBodies,'cpConstraintGetCollideBodies',\
	chipmunk_cpConstraintGetErrorBias,'cpConstraintGetErrorBias',\
	chipmunk_cpConstraintGetImpulse,'cpConstraintGetImpulse',\
	chipmunk_cpConstraintGetMaxBias,'cpConstraintGetMaxBias',\
	chipmunk_cpConstraintGetMaxForce,'cpConstraintGetMaxForce',\
	chipmunk_cpConstraintGetPostSolveFunc,'cpConstraintGetPostSolveFunc',\
	chipmunk_cpConstraintGetPreSolveFunc,'cpConstraintGetPreSolveFunc',\
	chipmunk_cpConstraintGetSpace,'cpConstraintGetSpace',\
	chipmunk_cpConstraintGetUserData,'cpConstraintGetUserData',\
	chipmunk_cpConstraintIsDampedRotarySpring,'cpConstraintIsDampedRotarySpring',\
	chipmunk_cpConstraintIsDampedSpring,'cpConstraintIsDampedSpring',\
	chipmunk_cpConstraintIsGearJoint,'cpConstraintIsGearJoint',\
	chipmunk_cpConstraintIsGrooveJoint,'cpConstraintIsGrooveJoint',\
	chipmunk_cpConstraintIsPinJoint,'cpConstraintIsPinJoint',\
	chipmunk_cpConstraintIsPivotJoint,'cpConstraintIsPivotJoint',\
	chipmunk_cpConstraintIsRatchetJoint,'cpConstraintIsRatchetJoint',\
	chipmunk_cpConstraintIsRotaryLimitJoint,'cpConstraintIsRotaryLimitJoint',\
	chipmunk_cpConstraintIsSimpleMotor,'cpConstraintIsSimpleMotor',\
	chipmunk_cpConstraintIsSlideJoint,'cpConstraintIsSlideJoint',\
	chipmunk_cpConstraintSetCollideBodies,'cpConstraintSetCollideBodies',\
	chipmunk_cpConstraintSetErrorBias,'cpConstraintSetErrorBias',\
	chipmunk_cpConstraintSetMaxBias,'cpConstraintSetMaxBias',\
	chipmunk_cpConstraintSetMaxForce,'cpConstraintSetMaxForce',\
	chipmunk_cpConstraintSetPostSolveFunc,'cpConstraintSetPostSolveFunc',\
	chipmunk_cpConstraintSetPreSolveFunc,'cpConstraintSetPreSolveFunc',\
	chipmunk_cpConstraintSetUserData,'cpConstraintSetUserData',\
	chipmunk_cpConvexHull,'cpConvexHull',\
	chipmunk_cpDampedRotarySpringAlloc,'cpDampedRotarySpringAlloc',\
	chipmunk_cpDampedRotarySpringGetDamping,'cpDampedRotarySpringGetDamping',\
	chipmunk_cpDampedRotarySpringGetRestAngle,'cpDampedRotarySpringGetRestAngle',\
	chipmunk_cpDampedRotarySpringGetSpringTorqueFunc,'cpDampedRotarySpringGetSpringTorqueFunc',\
	chipmunk_cpDampedRotarySpringGetStiffness,'cpDampedRotarySpringGetStiffness',\
	chipmunk_cpDampedRotarySpringInit,'cpDampedRotarySpringInit',\
	chipmunk_cpDampedRotarySpringNew,'cpDampedRotarySpringNew',\
	chipmunk_cpDampedRotarySpringSetDamping,'cpDampedRotarySpringSetDamping',\
	chipmunk_cpDampedRotarySpringSetRestAngle,'cpDampedRotarySpringSetRestAngle',\
	chipmunk_cpDampedRotarySpringSetSpringTorqueFunc,'cpDampedRotarySpringSetSpringTorqueFunc',\
	chipmunk_cpDampedRotarySpringSetStiffness,'cpDampedRotarySpringSetStiffness',\
	chipmunk_cpDampedSpringAlloc,'cpDampedSpringAlloc',\
	chipmunk_cpDampedSpringGetAnchorA,'cpDampedSpringGetAnchorA',\
	chipmunk_cpDampedSpringGetAnchorB,'cpDampedSpringGetAnchorB',\
	chipmunk_cpDampedSpringGetDamping,'cpDampedSpringGetDamping',\
	chipmunk_cpDampedSpringGetRestLength,'cpDampedSpringGetRestLength',\
	chipmunk_cpDampedSpringGetSpringForceFunc,'cpDampedSpringGetSpringForceFunc',\
	chipmunk_cpDampedSpringGetStiffness,'cpDampedSpringGetStiffness',\
	chipmunk_cpDampedSpringInit,'cpDampedSpringInit',\
	chipmunk_cpDampedSpringNew,'cpDampedSpringNew',\
	chipmunk_cpDampedSpringSetAnchorA,'cpDampedSpringSetAnchorA',\
	chipmunk_cpDampedSpringSetAnchorB,'cpDampedSpringSetAnchorB',\
	chipmunk_cpDampedSpringSetDamping,'cpDampedSpringSetDamping',\
	chipmunk_cpDampedSpringSetRestLength,'cpDampedSpringSetRestLength',\
	chipmunk_cpDampedSpringSetSpringForceFunc,'cpDampedSpringSetSpringForceFunc',\
	chipmunk_cpDampedSpringSetStiffness,'cpDampedSpringSetStiffness',\
	chipmunk_cpGearJointAlloc,'cpGearJointAlloc',\
	chipmunk_cpGearJointGetPhase,'cpGearJointGetPhase',\
	chipmunk_cpGearJointGetRatio,'cpGearJointGetRatio',\
	chipmunk_cpGearJointInit,'cpGearJointInit',\
	chipmunk_cpGearJointNew,'cpGearJointNew',\
	chipmunk_cpGearJointSetPhase,'cpGearJointSetPhase',\
	chipmunk_cpGearJointSetRatio,'cpGearJointSetRatio',\
	chipmunk_cpGrooveJointAlloc,'cpGrooveJointAlloc',\
	chipmunk_cpGrooveJointGetAnchorB,'cpGrooveJointGetAnchorB',\
	chipmunk_cpGrooveJointGetGrooveA,'cpGrooveJointGetGrooveA',\
	chipmunk_cpGrooveJointGetGrooveB,'cpGrooveJointGetGrooveB',\
	chipmunk_cpGrooveJointInit,'cpGrooveJointInit',\
	chipmunk_cpGrooveJointNew,'cpGrooveJointNew',\
	chipmunk_cpGrooveJointSetAnchorB,'cpGrooveJointSetAnchorB',\
	chipmunk_cpGrooveJointSetGrooveA,'cpGrooveJointSetGrooveA',\
	chipmunk_cpGrooveJointSetGrooveB,'cpGrooveJointSetGrooveB',\
	chipmunk_cpMessage,'cpMessage',\
	chipmunk_cpMomentForBox,'cpMomentForBox',\
	chipmunk_cpMomentForBox2,'cpMomentForBox2',\
	chipmunk_cpMomentForCircle,'cpMomentForCircle',\
	chipmunk_cpMomentForPoly,'cpMomentForPoly',\
	chipmunk_cpMomentForSegment,'cpMomentForSegment',\
	chipmunk_cpPinJointAlloc,'cpPinJointAlloc',\
	chipmunk_cpPinJointGetAnchorA,'cpPinJointGetAnchorA',\
	chipmunk_cpPinJointGetAnchorB,'cpPinJointGetAnchorB',\
	chipmunk_cpPinJointGetDist,'cpPinJointGetDist',\
	chipmunk_cpPinJointInit,'cpPinJointInit',\
	chipmunk_cpPinJointNew,'cpPinJointNew',\
	chipmunk_cpPinJointSetAnchorA,'cpPinJointSetAnchorA',\
	chipmunk_cpPinJointSetAnchorB,'cpPinJointSetAnchorB',\
	chipmunk_cpPinJointSetDist,'cpPinJointSetDist',\
	chipmunk_cpPivotJointAlloc,'cpPivotJointAlloc',\
	chipmunk_cpPivotJointGetAnchorA,'cpPivotJointGetAnchorA',\
	chipmunk_cpPivotJointGetAnchorB,'cpPivotJointGetAnchorB',\
	chipmunk_cpPivotJointInit,'cpPivotJointInit',\
	chipmunk_cpPivotJointNew,'cpPivotJointNew',\
	chipmunk_cpPivotJointNew2,'cpPivotJointNew2',\
	chipmunk_cpPivotJointSetAnchorA,'cpPivotJointSetAnchorA',\
	chipmunk_cpPivotJointSetAnchorB,'cpPivotJointSetAnchorB',\
	chipmunk_cpPolyShapeAlloc,'cpPolyShapeAlloc',\
	chipmunk_cpPolyShapeGetCount,'cpPolyShapeGetCount',\
	chipmunk_cpPolyShapeGetRadius,'cpPolyShapeGetRadius',\
	chipmunk_cpPolyShapeGetVert,'cpPolyShapeGetVert',\
	chipmunk_cpPolyShapeInit,'cpPolyShapeInit',\
	chipmunk_cpPolyShapeInitRaw,'cpPolyShapeInitRaw',\
	chipmunk_cpPolyShapeNew,'cpPolyShapeNew',\
	chipmunk_cpPolyShapeNewRaw,'cpPolyShapeNewRaw',\
	chipmunk_cpPolyShapeSetRadius,'cpPolyShapeSetRadius',\
	chipmunk_cpPolyShapeSetVerts,'cpPolyShapeSetVerts',\
	chipmunk_cpPolyShapeSetVertsRaw,'cpPolyShapeSetVertsRaw',\
	chipmunk_cpRatchetJointAlloc,'cpRatchetJointAlloc',\
	chipmunk_cpRatchetJointGetAngle,'cpRatchetJointGetAngle',\
	chipmunk_cpRatchetJointGetPhase,'cpRatchetJointGetPhase',\
	chipmunk_cpRatchetJointGetRatchet,'cpRatchetJointGetRatchet',\
	chipmunk_cpRatchetJointInit,'cpRatchetJointInit',\
	chipmunk_cpRatchetJointNew,'cpRatchetJointNew',\
	chipmunk_cpRatchetJointSetAngle,'cpRatchetJointSetAngle',\
	chipmunk_cpRatchetJointSetPhase,'cpRatchetJointSetPhase',\
	chipmunk_cpRatchetJointSetRatchet,'cpRatchetJointSetRatchet',\
	chipmunk_cpRotaryLimitJointAlloc,'cpRotaryLimitJointAlloc',\
	chipmunk_cpRotaryLimitJointGetMax,'cpRotaryLimitJointGetMax',\
	chipmunk_cpRotaryLimitJointGetMin,'cpRotaryLimitJointGetMin',\
	chipmunk_cpRotaryLimitJointInit,'cpRotaryLimitJointInit',\
	chipmunk_cpRotaryLimitJointNew,'cpRotaryLimitJointNew',\
	chipmunk_cpRotaryLimitJointSetMax,'cpRotaryLimitJointSetMax',\
	chipmunk_cpRotaryLimitJointSetMin,'cpRotaryLimitJointSetMin',\
	chipmunk_cpSegmentShapeAlloc,'cpSegmentShapeAlloc',\
	chipmunk_cpSegmentShapeGetA,'cpSegmentShapeGetA',\
	chipmunk_cpSegmentShapeGetB,'cpSegmentShapeGetB',\
	chipmunk_cpSegmentShapeGetNormal,'cpSegmentShapeGetNormal',\
	chipmunk_cpSegmentShapeGetRadius,'cpSegmentShapeGetRadius',\
	chipmunk_cpSegmentShapeInit,'cpSegmentShapeInit',\
	chipmunk_cpSegmentShapeNew,'cpSegmentShapeNew',\
	chipmunk_cpSegmentShapeSetEndpoints,'cpSegmentShapeSetEndpoints',\
	chipmunk_cpSegmentShapeSetNeighbors,'cpSegmentShapeSetNeighbors',\
	chipmunk_cpSegmentShapeSetRadius,'cpSegmentShapeSetRadius',\
	chipmunk_cpShapeCacheBB,'cpShapeCacheBB',\
	chipmunk_cpShapeDestroy,'cpShapeDestroy',\
	chipmunk_cpShapeFree,'cpShapeFree',\
	chipmunk_cpShapeGetArea,'cpShapeGetArea',\
	chipmunk_cpShapeGetBB,'cpShapeGetBB',\
	chipmunk_cpShapeGetBody,'cpShapeGetBody',\
	chipmunk_cpShapeGetCenterOfGravity,'cpShapeGetCenterOfGravity',\
	chipmunk_cpShapeGetCollisionType,'cpShapeGetCollisionType',\
	chipmunk_cpShapeGetDensity,'cpShapeGetDensity',\
	chipmunk_cpShapeGetElasticity,'cpShapeGetElasticity',\
	chipmunk_cpShapeGetFilter,'cpShapeGetFilter',\
	chipmunk_cpShapeGetFriction,'cpShapeGetFriction',\
	chipmunk_cpShapeGetMass,'cpShapeGetMass',\
	chipmunk_cpShapeGetMoment,'cpShapeGetMoment',\
	chipmunk_cpShapeGetSensor,'cpShapeGetSensor',\
	chipmunk_cpShapeGetSpace,'cpShapeGetSpace',\
	chipmunk_cpShapeGetSurfaceVelocity,'cpShapeGetSurfaceVelocity',\
	chipmunk_cpShapeGetUserData,'cpShapeGetUserData',\
	chipmunk_cpShapePointQuery,'cpShapePointQuery',\
	chipmunk_cpShapeSegmentQuery,'cpShapeSegmentQuery',\
	chipmunk_cpShapeSetBody,'cpShapeSetBody',\
	chipmunk_cpShapeSetCollisionType,'cpShapeSetCollisionType',\
	chipmunk_cpShapeSetDensity,'cpShapeSetDensity',\
	chipmunk_cpShapeSetElasticity,'cpShapeSetElasticity',\
	chipmunk_cpShapeSetFilter,'cpShapeSetFilter',\
	chipmunk_cpShapeSetFriction,'cpShapeSetFriction',\
	chipmunk_cpShapeSetMass,'cpShapeSetMass',\
	chipmunk_cpShapeSetSensor,'cpShapeSetSensor',\
	chipmunk_cpShapeSetSurfaceVelocity,'cpShapeSetSurfaceVelocity',\
	chipmunk_cpShapeSetUserData,'cpShapeSetUserData',\
	chipmunk_cpShapeUpdate,'cpShapeUpdate',\
	chipmunk_cpShapesCollide,'cpShapesCollide',\
	chipmunk_cpSimpleMotorAlloc,'cpSimpleMotorAlloc',\
	chipmunk_cpSimpleMotorGetRate,'cpSimpleMotorGetRate',\
	chipmunk_cpSimpleMotorInit,'cpSimpleMotorInit',\
	chipmunk_cpSimpleMotorNew,'cpSimpleMotorNew',\
	chipmunk_cpSimpleMotorSetRate,'cpSimpleMotorSetRate',\
	chipmunk_cpSlideJointAlloc,'cpSlideJointAlloc',\
	chipmunk_cpSlideJointGetAnchorA,'cpSlideJointGetAnchorA',\
	chipmunk_cpSlideJointGetAnchorB,'cpSlideJointGetAnchorB',\
	chipmunk_cpSlideJointGetMax,'cpSlideJointGetMax',\
	chipmunk_cpSlideJointGetMin,'cpSlideJointGetMin',\
	chipmunk_cpSlideJointInit,'cpSlideJointInit',\
	chipmunk_cpSlideJointNew,'cpSlideJointNew',\
	chipmunk_cpSlideJointSetAnchorA,'cpSlideJointSetAnchorA',\
	chipmunk_cpSlideJointSetAnchorB,'cpSlideJointSetAnchorB',\
	chipmunk_cpSlideJointSetMax,'cpSlideJointSetMax',\
	chipmunk_cpSlideJointSetMin,'cpSlideJointSetMin',\
	chipmunk_cpSpaceAddBody,'cpSpaceAddBody',\
	chipmunk_cpSpaceAddCollisionHandler,'cpSpaceAddCollisionHandler',\
	chipmunk_cpSpaceAddConstraint,'cpSpaceAddConstraint',\
	chipmunk_cpSpaceAddDefaultCollisionHandler,'cpSpaceAddDefaultCollisionHandler',\
	chipmunk_cpSpaceAddPostStepCallback,'cpSpaceAddPostStepCallback',\
	chipmunk_cpSpaceAddShape,'cpSpaceAddShape',\
	chipmunk_cpSpaceAddWildcardHandler,'cpSpaceAddWildcardHandler',\
	chipmunk_cpSpaceAlloc,'cpSpaceAlloc',\
	chipmunk_cpSpaceBBQuery,'cpSpaceBBQuery',\
	chipmunk_cpSpaceContainsBody,'cpSpaceContainsBody',\
	chipmunk_cpSpaceContainsConstraint,'cpSpaceContainsConstraint',\
	chipmunk_cpSpaceContainsShape,'cpSpaceContainsShape',\
	chipmunk_cpSpaceDebugDraw,'cpSpaceDebugDraw',\
	chipmunk_cpSpaceDestroy,'cpSpaceDestroy',\
	chipmunk_cpSpaceEachBody,'cpSpaceEachBody',\
	chipmunk_cpSpaceEachConstraint,'cpSpaceEachConstraint',\
	chipmunk_cpSpaceEachShape,'cpSpaceEachShape',\
	chipmunk_cpSpaceFree,'cpSpaceFree',\
	chipmunk_cpSpaceGetCollisionBias,'cpSpaceGetCollisionBias',\
	chipmunk_cpSpaceGetCollisionPersistence,'cpSpaceGetCollisionPersistence',\
	chipmunk_cpSpaceGetCollisionSlop,'cpSpaceGetCollisionSlop',\
	chipmunk_cpSpaceGetCurrentTimeStep,'cpSpaceGetCurrentTimeStep',\
	chipmunk_cpSpaceGetDamping,'cpSpaceGetDamping',\
	chipmunk_cpSpaceGetGravity,'cpSpaceGetGravity',\
	chipmunk_cpSpaceGetIdleSpeedThreshold,'cpSpaceGetIdleSpeedThreshold',\
	chipmunk_cpSpaceGetIterations,'cpSpaceGetIterations',\
	chipmunk_cpSpaceGetSleepTimeThreshold,'cpSpaceGetSleepTimeThreshold',\
	chipmunk_cpSpaceGetStaticBody,'cpSpaceGetStaticBody',\
	chipmunk_cpSpaceGetUserData,'cpSpaceGetUserData',\
	chipmunk_cpSpaceHashAlloc,'cpSpaceHashAlloc',\
	chipmunk_cpSpaceHashInit,'cpSpaceHashInit',\
	chipmunk_cpSpaceHashNew,'cpSpaceHashNew',\
	chipmunk_cpSpaceHashResize,'cpSpaceHashResize',\
	chipmunk_cpSpaceInit,'cpSpaceInit',\
	chipmunk_cpSpaceIsLocked,'cpSpaceIsLocked',\
	chipmunk_cpSpaceNew,'cpSpaceNew',\
	chipmunk_cpSpacePointQuery,'cpSpacePointQuery',\
	chipmunk_cpSpacePointQueryNearest,'cpSpacePointQueryNearest',\
	chipmunk_cpSpaceReindexShape,'cpSpaceReindexShape',\
	chipmunk_cpSpaceReindexShapesForBody,'cpSpaceReindexShapesForBody',\
	chipmunk_cpSpaceReindexStatic,'cpSpaceReindexStatic',\
	chipmunk_cpSpaceRemoveBody,'cpSpaceRemoveBody',\
	chipmunk_cpSpaceRemoveConstraint,'cpSpaceRemoveConstraint',\
	chipmunk_cpSpaceRemoveShape,'cpSpaceRemoveShape',\
	chipmunk_cpSpaceSegmentQuery,'cpSpaceSegmentQuery',\
	chipmunk_cpSpaceSegmentQueryFirst,'cpSpaceSegmentQueryFirst',\
	chipmunk_cpSpaceSetCollisionBias,'cpSpaceSetCollisionBias',\
	chipmunk_cpSpaceSetCollisionPersistence,'cpSpaceSetCollisionPersistence',\
	chipmunk_cpSpaceSetCollisionSlop,'cpSpaceSetCollisionSlop',\
	chipmunk_cpSpaceSetDamping,'cpSpaceSetDamping',\
	chipmunk_cpSpaceSetGravity,'cpSpaceSetGravity',\
	chipmunk_cpSpaceSetIdleSpeedThreshold,'cpSpaceSetIdleSpeedThreshold',\
	chipmunk_cpSpaceSetIterations,'cpSpaceSetIterations',\
	chipmunk_cpSpaceSetSleepTimeThreshold,'cpSpaceSetSleepTimeThreshold',\
	chipmunk_cpSpaceSetUserData,'cpSpaceSetUserData',\
	chipmunk_cpSpaceShapeQuery,'cpSpaceShapeQuery',\
	chipmunk_cpSpaceStep,'cpSpaceStep',\
	chipmunk_cpSpaceUseSpatialHash,'cpSpaceUseSpatialHash',\
	chipmunk_cpSpatialIndexCollideStatic,'cpSpatialIndexCollideStatic',\
	chipmunk_cpSpatialIndexFree,'cpSpatialIndexFree',\
	chipmunk_cpSweep1DAlloc,'cpSweep1DAlloc',\
	chipmunk_cpSweep1DInit,'cpSweep1DInit',\
	chipmunk_cpSweep1DNew,'cpSweep1DNew',\
	chipmunk_cpVersionString,'cpVersionString'