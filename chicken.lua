--constants
DEBUG = true
SUB_PIXEL = 8
CRAWL_SPEED = 5
WALK_SPEED = 20
RUN_SPEED = 36
WORLD_GRAVITY = 1
JUMP_GRAVITY = 1
FALL_GRAVITY = 3
JUMP_SPEED = 20
JUMP_BUFFER_TIME = 8

--main
function _init()
	-- disable repeat buttons
	poke(0x5f5c,255)

	my_entities = {}
	add(my_entities, create_player(64, 0))
end

function _update()
	update_all(my_entities)
end

function _draw()
	cls()
	map()
	draw_all(my_entities)
end

--systems
function update_all(entities)
	for e in all(entities) do
		if e.update then
			e:update()
		end
	end
end

function draw_all(entities)
	for e in all(entities) do
		if e.draw then
			e:draw()
		end
	end
end

--entities
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
		dynamic = true,
		update = update_box,
		draw = draw_box,
	}
end

function update_box(b)
	b.dx = 0
	b.dy = 0
	if btn(0) then b.dx = -1*SUB_PIXEL end
	if btn(1) then b.dx = 1*SUB_PIXEL end
	if btn(2) then b.dy = -1*SUB_PIXEL end
	if btn(3) then b.dy = 1*SUB_PIXEL end

	move_and_slide(b)
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
		dynamic = true,
		target_dx = 0,
		target_speed = WALK_SPEED,
		gravity = WORLD_GRAVITY,
		float_timer = 0,
		jump_buffer_timer = JUMP_BUFFER_TIME,
		on_ground = false,
		state = "fall",
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

		-- standard entity functions
		update = player_update,
		draw = player_draw,
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

	-- X velocity
	p.target_dx = move_dir * p.target_speed
	if p.target_dx - p.dx ~= 0 then
		local acc = sgn(p.target_dx - p.dx)
		-- apply brakes
		if (p.target_dx > 0 and p.dx < 0) or (p.target_dx < 0 and p.dx > 0) then
			acc *= 2
		end
		p.dx += acc
	end

	-- Y velocity
	p.dy += p.gravity

	move_and_slide(p)
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
