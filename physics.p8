--physics bootstrap
--by spratt
local pi = 3.141592653589793
actors={}

-- static only
walls={}
-- balls, enemies, etc. anything that will be mostly controlled by physics
objects={}

showlogs=true

function acos(x)
	return atan2(x,-sqrt(1-x*x))
end

function _clearPhysics()
	actors={}
	walls={}
	objects={}
end

function _init()
	-- _wall(0,0,127,0)
	-- _wall(0,0,0,84)
	-- _wall(127,0,127,84)
	-- _wall(0,84,20,127)
	-- _wall(127,84,107,127)
	-- _wall(20,127,107,127)
	for i=1,20 do
		ball=_circ(rnd(128),rnd(64)+10,rnd(10)+2,false)
	end 
end

function _update()
	--apply forces etc
	local sim=4
	for i=1,sim do
		for o in all(objects) do
			o:update(1/sim)
		end
	end
end

function _draw()
	cls()
	for w in all(walls) do
		w:draw()
	end
	for a in all(actors) do
		a:draw()
	end
	print((flr(stat(1)*1000)/10).."%",11)
	-- print(sqrt(ball.dx*ball.dx+ball.dy*ball.dy))
	--logging
	if showlogs then
		for l in all(logs) do
			print(l[2],l[3])
			l[1]-=1
			if (l[1]<=0) then
				del(logs,l)
			end
		end
	end
end
-->8
--actors

function _actor(_x,_y)
	local a={
		x=_x,
		y=_y
	}

	function a.draw(me)
		--basic draw function
			circfill(me.x,me.y,2,7)
	end
	
	function a.update(me)
		--basic update function
	end

	add(actors,a)

	return a
end
-->8
--objects

function _circ(_x,_y,_r,_s)
	local c = _actor(_x,_y)
	c.r=_r
	c.static =_s or false
	c.dx=0
	c.dy=0
	c.m=1
	c.clr=_s and 13 or 7

	function c.draw(me)
		--basic draw function
			circfill(me.x,me.y,me.r,me.clr)
	end
	
	function c.update(me,ts)
		--basic update function

		--should maybe do all the gravity at once..?
		me.dy+=0.3*ts
		me.x+=me.dx*ts
		me.y+=me.dy*ts

		local staticcols = {}
		local dynamiccols = {}
		for i=1,5 do
			--collide with walls
			local dx,dy
			--deepest collision
			local dpst={0}
			for w in all(walls) do
				--get closest point on wall
				local tx,ty=w.x2-w.x1,w.y2-w.y1
				if ((me.x-w.x1)*tx+(me.y-w.y1)*ty<=0) then
					dx,dy=me.x-w.x1,me.y-w.y1
				elseif ((me.x-w.x2)*tx+(me.y-w.y2)*ty>=0) then
					dx,dy=me.x-w.x2,me.y-w.y2
				else
					tx/=w.len
					ty/=w.len
					local k=tx*(me.x-w.x1)+ty*(me.y-w.y1)
					dx,dy=me.x-w.x1-tx*k,me.y-w.y1-ty*k
				end

				if (dx*dx+dy*dy<me.r*me.r) then
					--collision!
					local d=sqrt(dx*dx+dy*dy)
					if (dpst[1]<me.r-d) then
						dpst={me.r-d,dx/d,dy/d,w}
					end
				end
			end
			--collide with other objects
			for o in all(objects) do
				if (o != me) then
					dx,dy=me.x-o.x,me.y-o.y
					r=me.r+o.r
					if (dx*dx+dy*dy<r*r) then
						--collision!
						local d=sqrt(dx*dx+dy*dy)
						if (dpst[1]<r-d) then
							dpst={r-d,dx/d,dy/d,o}
						end
					end
				end
			end

			--if collision depth = 0, then break
			if (dpst[1]==0) then
				break
			else
				me.x+=dpst[1]*dpst[2]
				me.y+=dpst[1]*dpst[3]
				
				--put collision info into buffer, removing duplicates if any
				if (dpst[4].static) then
					for n in all(staticcols) do
						if (dpst[4] == n[4]) then
							del(staticcols,n)
						end
					end
					add(staticcols,dpst)
				else
					for n in all(dynamiccols) do
						if (dpst[4] == n[4]) then
							del(dynamiccols,n)
						end
					end
					add(dynamiccols,dpst)
				end

				dpst[4]:oncollide(me)
			end
		end
		--static collisions
		if #staticcols>0 then
			--average all collision normals
			local rx,ry=0,0
			for n in all(staticcols) do
				if n[4].static then 
					rx+=n[2]
					ry+=n[3]
				end
			end
			local d=sqrt(rx*rx+ry*ry)
			rx/=d
			ry/=d
			local k=2*(me.dx*rx+me.dy*ry)
			me.dx-=k*rx
			me.dy-=k*ry
		end
		--dynamic collisions
		if #dynamiccols>0 then
			for n in all(dynamiccols) do
				local o=n[4]			
				local d2=(me.r+o.r)*(me.r+o.r)
				local k=2*((me.dx-o.dx)*(me.x-o.x)+(me.dy-o.dy)*(me.y-o.y))/(me.m+o.m)/d2

				me.dx-=k*o.m*(me.x-o.x)
				me.dy-=k*o.m*(me.y-o.y)

				o.dx-=k*me.m*(o.x-me.x)
				o.dy-=k*me.m*(o.y-me.y)
			end
		end

		-- Apply damping to reduce energy over time
		-- Apply horizontal damping (less than vertical damping to allow for a natural arc)
		local horizontal_damping = 0.99  -- Adjust this value as needed
		me.dx *= horizontal_damping
	
		-- Apply vertical damping
		local vertical_damping = 0.97  -- Adjust this value as needed
		me.dy *= vertical_damping

		player.grounded = false  -- Reset grounded state
		local vertical_axis = {x = 0, y = 1}  -- Vertical axis for comparison
		
	
		-- After collision detection and response
		for col in all(staticcols) do
			local isVerticalWall = false
			local normal = {x = col[3], y = -col[2]}  -- This is the normal vector of the collision
			local friction_coefficient = 8  -- High friction coefficient
			
			-- Calculate the normal force (component of gravity perpendicular to the surface)
			local gravity = 0.3 * ts  -- Adjust the gravity if needed
			local normal_force = gravity * normal.y
			
			-- The friction force is the normal force times the friction coefficient
			local friction_force = friction_coefficient * normal_force
			
			-- Calculate the component of the ball's velocity parallel to the surface
			local parallel_velocity = me.dx * normal.y - me.dy * normal.x
			
			-- Apply friction in the direction opposite to the ball's parallel velocity
			local friction_direction = parallel_velocity > 0 and -1 or 1
			me.dx += friction_direction * normal.y * friction_force
			me.dy -= friction_direction * normal.x * friction_force
			
			-- Calculate the slope angle (the angle between the normal and the vertical axis)
			local slope_angle = acos(normal.y)
		
			-- Stop the ball if the velocity is below a threshold and the slope is not too steep
			local velocity_threshold = 0.1  -- Adjust as needed
			local max_slope_angle = acos(normal.y) / (pi * 2) * 360  -- Convert to degrees
			
			-- Check if the ball's parallel velocity is below the threshold and the slope is gentle
			if abs(parallel_velocity) < velocity_threshold and slope_angle < max_slope_angle then
				me.dx = 0
				me.dy = 0
			end
			
			-- Adjust restitution if needed
			local restitution = 0.9
			me.dy *= -restitution
			
			-- If the ball is nearly stopped on a slope, prevent it from sliding down
			--printh('me.dx: ' .. me.dx .. ' me.dy: ' .. me.dy)
			-- if me.dx < 0.2 and abs(slope_angle) < max_slope_angle then
			-- 	printh('stopped slope')
			-- 	me.dy = 0
			-- end
			local grounded_angle_threshold = 3
			-- Check if the ball is grounded
			local collision_normal = {x = col[2], y = col[3]}
			local angle_with_vertical = angleBetween(collision_normal, vertical_axis)
			if angle_with_vertical < grounded_angle_threshold then
				player.grounded = true
			end
		end
	end

	function c.oncollide(me,you)
		--called when something collides with it
	end

	add(objects,c)
	return c
end
-->8
--walls

function _wall(_x1,_y1,_x2,_y2)
	local w={
		x1=_x1,
		y1=_y1,
		x2=_x2,
		y2=_y2,
		static=true, --walls are always static
		r=1,
		len=sqrt((_x2-_x1)*(_x2-_x1) + (_y2-_y1)*(_y2-_y1))
	}

	function w.draw(me)
		--basic draw function
		line(me.x1,me.y1,me.x2,me.y2,15)
	end
	
	function w.update(me)
		--basic update function
	end

	function w.oncollide(me,you)
		--called when something collides with it
	end
	
	add(walls,w)
	
 return w
end
-->8
--utils

--logging
logs={}
lcol=true
function log(txt)
	if (#logs>=20) then
		del(logs,logs[1])
	end
	lcol=not lcol
	add(logs,{120,txt,lcol and 6 or 7})
end

function angleBetween(v1, v2)
    local dot = v1.x * v2.x + v1.y * v2.y
    local len_v1 = sqrt(v1.x * v1.x + v1.y * v1.y)
    local len_v2 = sqrt(v2.x * v2.x + v2.y * v2.y)
    return acos(dot / (len_v1 * len_v2))
end

--basic insertion sort with comparator function input
function sort(a,cmp)
  for i=1,#a do
    local j = i
    while j > 1 and cmp(a[j-1],a[j]) do
        a[j],a[j-1] = a[j-1],a[j]
    j = j - 1
    end
  end
end