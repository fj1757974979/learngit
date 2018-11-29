
-- set the proxy
b2Vec2.__proxy_class = puppy.physics.phy_vec2
b2BodyDef.__proxy_class = puppy.physics.phy_body_def
b2World = puppy.physics.b2World_wrap
b2World.__proxy_class = puppy.physics.phy_world
b2PolygonShape.__proxy_class = puppy.physics.phy_polygon_shape
b2CircleShape.__proxy_class = puppy.physics.phy_circle_shape
b2FixtureDef.__proxy_class = puppy.physics.phy_fixture_def
b2EdgeShape.__proxy_class = puppy.physics.phy_edge_shape
b2JointDef.__proxy_class = puppy.physics.phy_joint_def
b2DistanceJointDef.__proxy_class = puppy.physics.phy_distance_joint_def
b2MouseJointDef.__proxy_class = puppy.physics.phy_mouse_joint_def

b2Vec2.init = function(self, x, y)
	self:x(x or 0)
	self:y(y or 0)
end

function create_op(op)
	return function(self, vec, y)
		if is_type_of(vec, b2Vec2) then
			self:x(op(self:x(),vec:x()))
			self:y(op(self:y(),vec:y()))
		else
			self:x(op(self:x(),vec))
			self:y(op(self:y(),y))
		end
	end
end
make_b2Vec2_property = function(cfun)
	return function(self, set)
		if set then
			local v = cfun(self)
			v:x(set:x())
			v:y(set:y())
		else
			return cfun(self)
		end
	end
end

b2Vec2.sub = create_op(sub)
b2Vec2.add = create_op(add)
b2Vec2.set = create_op(snd)

b2BodyDef.position = make_b2Vec2_property(b2BodyDef_position)

b2PolygonShape.SetAsBox = function(self, hx, hy, center, angle)
	if not center then
		b2PolygonShape_SetAsBox2(self, hx, hy)
	else
		b2PolygonShape_SetAsBox4(self, hx, hy, center, angle)
	end
end

b2EdgeShape.Set = b2EdgeShape_Set2

b2Body.CreateFixture = function(self, arg1, arg2)
	if is_type_of(arg1, b2Shape) then
		b2Body_CreateFixture2(self, arg1, arg2)
	else
		b2Body_CreateFixture1(self, arg1)
	end
end

b2Body.GetPosition = b2Body_GetPosition
b2Body.GetWorldPoint = b2Body_GetWorldPoint
b2Body.SetTransform = b2Body_SetTransform
b2Body.ApplyForceToCenter = b2Body_ApplyForceToCenter
b2Body.ApplyForce = b2Body_ApplyForce
b2DistanceJointDef.localAnchorA = make_b2Vec2_property(b2DistanceJointDef_localAnchorA)
b2DistanceJointDef.localAnchorB = make_b2Vec2_property(b2DistanceJointDef_localAnchorB)
b2MouseJointDef.target = make_b2Vec2_property(b2MouseJointDef_target)
b2MouseJoint.GetTarget = b2MouseJoint_GetTarget
b2MouseJoint.SetTarget = b2MouseJoint_SetTarget

box2d2world = function(b2Pos)
	local x = b2Pos[1]
	local y = b2Pos[2]
	local rx = x * 30 + gGameWidth/2
	local ry = - y * 30 + 100 + gGameHeight/2
	return {rx, ry}
end

world2box2d = function(pos)
	local x = pos[1]
	local y = pos[2]
	local rx = (x - gGameWidth/2) / 30;
	local ry = - (y - 100 - gGameHeight/2) / 30;
	return {rx, ry}
end

pixels2meter = function(pixels)
	return pixels / 30;
end

meter2pixels = function(meter)
	return meter * 30;
end

__init__ = function(module)
	loadglobally(module)
	--export("b2World", b2World)
end
