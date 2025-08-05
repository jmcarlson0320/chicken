TILE_SOLID  = 0
TILE_ONEWAY = 1

function move_and_slide(obj)
	if move_x(obj, obj.dx, on_collide_x) then
		obj.against_wall = false
	end
	if move_y(obj, obj.dy, on_collide_y) then
		obj.on_ground = false
	end
end

function on_collide_x(obj, tile_info)
	if fget(tile_info.tile, TILE_SOLID) then
		obj.dx = 0
		obj.sub_x = 0
		obj.against_wall = true
	elseif fget(tile_info.tile, TILE_ONEWAY) then
		return "ignore_collision"
	end
end

function on_collide_y(obj, tile_info)
	if fget(tile_info.tile, TILE_SOLID) then
		obj.dy = 0
		obj.sub_y = 0
		if obj.dy >= 0 then
			obj.on_ground = true
		end
	elseif fget(tile_info.tile, TILE_ONEWAY) then
		local obj_bottom = obj.y + obj.hitbox[4]
		local tile_top = tile_info.collider[2]
		if obj.dy >= 0 and obj_bottom < tile_top then
			obj.dy = 0
			obj.sub_y = 0
			obj.on_ground = true
		else
			return "ignore_collision"
		end
	end
end

function move_and_bounce(obj)
	move_x(obj, obj.dx, on_bounce_x)
	move_y(obj, obj.dy, on_bounce_y)
end

function on_bounce_x(obj, tile_info)
	if fget(tile_info.tile, TILE_SOLID) then
		obj.dx *= -1
	end
end

function on_bounce_y(obj, tile_info)
	if fget(tile_info.tile, TILE_SOLID) then
		obj.dy *= -1
	end
end

--core functions
function move_x(obj, dx, callback)
	obj.sub_x += dx
	local move_x = obj.sub_x \ 8
	local obj_moved = false
	if move_x ~= 0 then
		obj_moved = true
		obj.sub_x -= move_x * 8
		local sign = sgn(move_x)
		while move_x ~= 0 do
			local collider = make_collider(obj.x + sign, obj.y, obj.hitbox)
			local collision = collide_with_map(collider)
			if collision then
				if callback then
					local result = callback(obj, collision)
					if result ~= "ignore_collision" then
						return false
					end
				end
			end
			obj.x += sign
			move_x -= sign
		end
	end
	return obj_moved
end

function move_y(obj, dy, callback)
	obj.sub_y += dy
	local move_y = obj.sub_y \ 8
	local obj_moved = false
	if move_y ~= 0 then
		obj_moved = true
		obj.sub_y -= move_y * 8
		local sign = sgn(move_y)
		while move_y ~= 0 do
			local collider = make_collider(obj.x, obj.y + sign, obj.hitbox)
			local collision = collide_with_map(collider)
			if collision then
				if callback then
					local result = callback(obj, collision)
					if result ~= "ignore_collision" then
						return false
					end
				end
			end
			obj.y += sign
			move_y -= sign
		end
	end
	return obj_moved
end

function collide_with_map(collider)
	-- 3x3 grid of tiles around collider
	local x_min = collider[1] \ 8 - 1
	local x_max = collider[1] \ 8 + 1
	local y_min = collider[2] \ 8 - 1
	local y_max = collider[2] \ 8 + 1
	for x = x_min, x_max do
		for y = y_min, y_max do
			local tile = mget(x, y)
			if fget(tile) ~= 0 then
				local hitbox = {0, 0, 7, 7}
				local tile_collider = make_collider(x*8, y*8, hitbox)
				if collide(collider, tile_collider) then
					return {
						tile = tile,
						collider = tile_collider,
					}
				end
			end
		end
	end
	return nil
end

function make_collider(x, y, hitbox)
	return {
		x + hitbox[1],
		y + hitbox[2],
		x + hitbox[3],
		y + hitbox[4],
	}
end

function collide(a, b)
	if a[1] > b[3] then return false end
	if b[1] > a[3] then return false end
	if a[2] > b[4] then return false end
	if b[2] > a[4] then return false end
	return true
end

function draw_hitbox(e)
	local h = e.hitbox
	rect(h[1] + e.x, h[2] + e.y, h[3] + e.x, h[4] + e.y, 8)
end
