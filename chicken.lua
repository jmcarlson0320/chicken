--main
DEBUG = false
SUB_PIXEL = 8
CRAWL_SPEED = 5
WALK_SPEED = 20
RUN_SPEED = 36
WORLD_GRAVITY = 1
JUMP_GRAVITY = 1
FALL_GRAVITY = 3
JUMP_SPEED = 20
JUMP_BUFFER_TIME = 8

function _init()
	-- disable repeat buttons
	poke(0x5f5c,255)

	player = create_player(64, 0)
end

function _update()
	player_update(player)
end

function _draw()
	cls()
	map()
	player_draw(player)
end

--test box
function create_test_box(x, y)
	return {
		x = x,
		y = y,
		sub_x = 0,
		sub_y = 0,
		dx = 0,
		dy = 0,
		hitbox = {0, 0, 7, 7},
		collision_x = false,
		collision_y = false,
	}
end

function update_box(b)
	b.dx = 0
	b.dy = 0
	if btn(0) then b.dx = -1*SUB_PIXEL end
	if btn(1) then b.dx = 1*SUB_PIXEL end
	if btn(2) then b.dy = -1*SUB_PIXEL end
	if btn(3) then b.dy = 1*SUB_PIXEL end

	move_x(b, b.dx)
	move_y(b, b.dy)
end

function draw_box(b)
	print("sub_x "..b.sub_x)
	print("x     "..b.x)
	print("dx    "..b.dx)
	print("collision_x: "..tostr(b.collision_x))
	print("collision_y: "..tostr(b.collision_y))
	rect(b.x, b.y, b.x+7, b.y+7, 8)
end

function create_player(x, y)
	return {
		x = x,
		y = y,
		sub_x = 0,
		sub_y = 0,
		dx = 0,
		dy = 0,
		target_dx = 0,
		target_speed = WALK_SPEED,
		gravity = WORLD_GRAVITY,
		float_timer = 0,
		jump_buffer_timer = JUMP_BUFFER_TIME,
		on_ground = true,
		state = "idle",
		hitbox = {2, 1, 5, 7},
		facing = "right",
		current_animation = "standing",
		animations = {
			["standing"] = {
				frames = {50},
				rate = 0,
				t = 0,
			},
			["sitting"] = {
				frames = {52},
				rate = 0,
				t = 0,
			},
			["crawling"] = {
				frames = {49, 52, 51, 52},
				rate = 4,
				t = 0,
			},
			["walking"] = {
				frames = {49, 50, 51, 50},
				rate = 4,
				t = 0,
			},
			["running"] = {
				frames = {49, 50, 51, 50},
				rate = 2,
				t = 0,
			},
			["jumping"] = {
				frames = {49, 50, 51, 50},
				rate = 4,
				t = 0,
			},
		},
	}
end

function player_update(p)
	if p.jump_buffer_timer > 0 then
		p.jump_buffer_timer -= 1
	end

	local move_dir = 0
	if btn(0) then
		move_dir -= 1
		p.facing = "left"
	end
	if btn(1) then
		move_dir += 1
		p.facing = "right"
	end

	if p.state == "idle" then
		if move_dir ~= 0 then
			p.target_speed = WALK_SPEED
			p.current_animation = "walking"
			p.state = "walk"
		end
		if btn(3) then
			p.target_speed = CRAWL_SPEED
			p.current_animation = "sitting"
			p.state = "crawl"
		end
		if btnp(4) or p.jump_buffer_timer > 0 then
			p.dy = -JUMP_SPEED
			p.on_ground = false
			p.gravity = JUMP_GRAVITY
			p.float_timer = 20
			p.current_animation = "jumping"
			p.target_speed = WALK_SPEED
			p.state = "jump"
		end
	elseif p.state == "walk" then
		if (move_dir == 0) and (p.dx == 0) then
			p.current_animation = "standing"
			p.state = "idle"
		end
		if (move_dir ~= 0) and btn(5) then
			p.target_speed = RUN_SPEED
			p.current_animation = "running"
			p.state = "run"
		end
		if btn(3) then
			p.target_speed = CRAWL_SPEED
			p.current_animation = "sitting"
			p.state = "crawl"
		end
		if not p.on_ground then
			p.gravity = FALL_GRAVITY
			p.state = "fall"
		end
		if btnp(4) or p.jump_buffer_timer > 0 then
			p.dy = -JUMP_SPEED
			p.on_ground = false
			p.gravity = JUMP_GRAVITY
			p.float_timer = 20
			p.current_animation = "jumping"
			p.target_speed = WALK_SPEED
			p.state = "jump"
		end
	elseif p.state == "run" then
		if (move_dir == 0) or (not btn(5)) then
			p.target_speed = WALK_SPEED
			p.current_animation = "walking"
			p.state = "walk"
		end
		if btn(3) then
			p.target_speed = CRAWL_SPEED
			p.current_animation = "sitting"
			p.state = "crawl"
		end
		if not p.on_ground then
			p.gravity = FALL_GRAVITY
			p.state = "fall"
		end
		if btnp(4) or p.jump_buffer_timer > 0 then
			p.dy = -JUMP_SPEED
			p.on_ground = false
			p.gravity = JUMP_GRAVITY
			p.float_timer = 20
			p.current_animation = "jumping"
			p.target_speed = RUN_SPEED
			p.state = "jump"
		end
	elseif p.state == "crawl" then
		if move_dir ~= 0 and abs(p.dx) <= abs(p.target_dx) then
			p.current_animation = "crawling"
		else
			p.current_animation = "sitting"
		end
		if not p.on_ground then
			p.gravity = FALL_GRAVITY
			p.state = "fall"
		end
		if not btn(3) then
			p.target_speed = WALK_SPEED
			p.current_animation = "walking"
			p.state = "walk"
		end
	elseif p.state == "jump" then
		if p.float_timer > 0 then
			p.float_timer -= 1
		end
		if p.float_timer <= 0 then
			p.gravity = FALL_GRAVITY
		end
		if not btn(4) then
			p.gravity = FALL_GRAVITY
		end
		if btnp(4) then 
			p.jump_buffer_timer = JUMP_BUFFER_TIME
		end
		if not btn(5) then
			p.target_speed = WALK_SPEED
		end
		if p.on_ground and (btnp(4) or p.jump_buffer_timer > 0) and btn(5) then
			p.dy = -JUMP_SPEED
			p.on_ground = false
			p.gravity = JUMP_GRAVITY
			p.target_speed = RUN_SPEED
			p.float_timer = 20
		elseif p.on_ground then
			p.gravity = WORLD_GRAVITY
			p.current_animation = "walking"
			p.state = "walk"
		end
	elseif p.state == "fall" then
		if btnp(4) then 
			p.jump_buffer_timer = JUMP_BUFFER_TIME
		end
		if not btn(5) then
			p.target_speed = WALK_SPEED
		end
		if p.on_ground and (btnp(4) or (p.jump_buffer_timer > 0)) and btn(5) then
			p.dy = -JUMP_SPEED
			p.on_ground = false
			p.gravity = JUMP_GRAVITY
			p.target_speed = RUN_SPEED
			p.float_timer = 20
		elseif p.on_ground then
			p.gravity = WORLD_GRAVITY
			p.current_animation = "walking"
			p.state = "walk"
		end
	end

	-- X movement
	p.target_dx = move_dir * p.target_speed
	if p.target_dx - p.dx ~= 0 then
		local acc = sgn(p.target_dx - p.dx)
		-- apply brakes
		if (p.target_dx > 0 and p.dx < 0) or (p.target_dx < 0 and p.dx > 0) then
			acc *= 2
		end
		p.dx += acc -- vel += acc

	end

	move_x(p, p.dx)

	-- wrap around screen
	if p.x < -7 then p.x = 127 end
	if p.x > 127 then p.x = -7 end

	--Y movement
	p.dy += p.gravity

	move_y(p, p.dy)
end

function player_draw(p)
	local anim = p.animations[p.current_animation]
	local index = flr(anim.t / anim.rate % #anim.frames) + 1
	local sprite = anim.frames[index]
	local flip_x = p.facing == "left"
	spr(sprite, p.x, p.y, 1, 1, flip_x)
	anim.t += 1
	if DEBUG then
		color(7)
		print("subx:      "..p.sub_x)
		print("x:         "..p.x)
		print("dx:        "..p.dx)
		print("target_dx: "..p.target_dx)
		print("suby:      "..p.sub_y)
		print("y:         "..p.y)
		print("dy:        "..p.dy)
		print("grav:      "..p.gravity)
		print("flt_timer: "..p.float_timer)
		print("jmp_b_time:"..p.jump_buffer_timer)
		print("btn:       "..btn())
		print("state:     "..p.state)
		print("on_gnd:    "..tostr(p.on_ground))
		draw_hitbox(p)
	end
end

function move_x(obj, dx)
	obj.sub_x += dx
	local move_x = obj.sub_x \ SUB_PIXEL
	if move_x ~= 0 then
		obj.sub_x -= move_x * SUB_PIXEL
		local sign = sgn(move_x)
		while move_x ~= 0 do
			local collider = make_collider(obj.x + sign, obj.y, obj.hitbox)
			local collision = collide_with_map(collider)
			if collision then
				if not fget(collision.tile, 1) then
					obj.dx = 0
					obj.sub_x = 0
					break
				end
			end
			obj.x += sign
			move_x -= sign
		end

	end
end

function move_y(obj, dy)
	obj.sub_y += dy
	local move_y = obj.sub_y \ SUB_PIXEL
	if move_y ~= 0 then
		obj.sub_y -= move_y * SUB_PIXEL
		local sign = sgn(move_y)
		while move_y ~= 0 do
			local collider = make_collider(obj.x, obj.y + sign, obj.hitbox)
			local collision = collide_with_map(collider)
			if collision then
				if fget(collision.tile, 1) then -- one-way
					local obj_bottom = obj.y + obj.hitbox[4]
					local tile_top = collision.collider[2]
					if dy > 0 and obj_bottom < tile_top then
						obj.dy = 0
						obj.sub_y = 0
						obj.on_ground = true
						break
					end
				elseif fget(collision.tile, 0) then -- solid
					obj.dy = 0
					obj.sub_y = 0
					if dy > 0 then
						obj.on_ground = true
					end
					break
				end
			end
			obj.y += sign
			move_y -= sign
			obj.on_ground = false
		end
	end
end

function collide_with_map(collider)
	for x = 0, 15 do
		for y = 0, 15 do
			local tile = mget(x, y)
			if fget(tile) ~= 0 then -- solid
				local tile_collider = get_collider_from_tile(x, y)
				if collide(collider, tile_collider) then
					return {
						tile = tile,
						collider = tile_collider
					}
				end
			end
		end
	end
	return nil
end

function get_collider(obj)
	return {
		obj.x + obj.hitbox[1],
		obj.y + obj.hitbox[2],
		obj.x + obj.hitbox[3],
		obj.y + obj.hitbox[4],
	}
end

function make_collider(x, y, hitbox)
	return {
		x + hitbox[1],
		y + hitbox[2],
		x + hitbox[3],
		y + hitbox[4],
	}
end

function get_collider_from_tile(map_x, map_y)
	local x = map_x * 8
	local y = map_y * 8
	local hitbox = {0, 0, 7, 7}
	return make_collider(x, y, hitbox)
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

--mouse
function mouse_init()
	-- enable mouse
	poke(0x5f2d, 1)
end

function mouse_pos()
	local x = stat(32) - 1
	local y = stat(33) - 1
	return x, y
end

function mouse_button()
	return stat(34)
end
