pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

#include physics.p8
#include text.p8
-- define terrain and player
local terrain = {}
local hole_width = 8
local hole_depth = 4
player = {x=10, y=0, vy=0, vx=0, angle=0.75, power=0, grounded=true}
local player_ball
local lvl_no = 1
local time_in_hole = 0
local holeCol = 5
-- Time delta (dt) can adjust for frame rate variability
local dt = 1/30 
local debugDraw = false
local MAX_POWER = 8  -- Adjust the subtraction for some padding if needed.
--
local increased_hole_depth = hole_depth + 5
local hole_y = nil -- We will set this when we encounter the hole start

-- Constants
local screen_width = 128  -- PICO-8 screen width
local char_width = 4      -- Width of a character in pixels
local messageShown = false
local tree_x = rnd(128)  -- Random X position
local tree_y = 84  -- Y position at ground level
local MIN_DISTANCE_FROM_HOLE = 20 -- Minimum distance from the hole to draw the tree
local cable_y = 10  -- Y-position of the cable
local light_spacing = 8  -- Spacing between lights
local light_radius = 1  -- Radius of each light
local cable_length = 127  -- Length of the cable
local draw_decorations = false
local draw_tree = false

function should_draw_decorations()
    -- Generate a random number between 0 and 1
    local chance = rnd(1)
    
    -- If the chance is less than or equal to 0.25, return true
    return chance <= 0.25
end

function should_draw_tree()
    -- Generate a random number between 0 and 1
    local chance = rnd(1)
    
    -- If the chance is less than or equal to 0.25, return true
    return chance <= 0.25
end

-- Function to draw cables and lights
function draw_cables_and_lights()
    local cable_start_x = 0
    local cable_start_y = 115
    local segment_length = 20
    local segment_height = 5
    local cable_color = 7
    local pole_color = 8
    local light_color_1 = 9
    local light_color_2 = 10
    local num_segments = 7

    for i = 0, num_segments - 1 do
        local x1 = cable_start_x + i * segment_length
        local y1 = cable_start_y + (i % 2) * segment_height
        local x2 = x1 + segment_length
        local y2 = cable_start_y + ((i + 1) % 2) * segment_height

        -- Draw cable segment
        line(x1, y1, x2, y2, cable_color)

        -- Draw pole at the start of the segment
        circfill(x1, y1, 2, pole_color)

        local light_spacing = 5
        for light_x = x1, x2, light_spacing do
            local light_y = y1 + ((light_x - x1) / (x2 - x1)) * (y2 - y1)
            local light_color = (light_x / light_spacing) % 2 == 0 and light_color_1 or light_color_2
            circfill(light_x, light_y, 1, light_color)
        end
    end

    -- Draw final pole
    local final_x = cable_start_x + num_segments * segment_length
    local final_y = cable_start_y + (num_segments % 2) * segment_height
    circfill(final_x, final_y, 2, pole_color)
end

-- Main draw function
function _draw()
    -- Other drawing code...

    draw_cables_and_lights()

    -- More drawing code...
end


-- Example usage in _draw() function
function _draw()
    cls() -- Clear the screen
    draw_cables_and_lights()
    -- Other drawing code goes here
end

-- Function to find a suitable position for the tree
function find_tree_position(hole_x, terrain)
    local tree_x = flr(rnd(#terrain))
    while abs(tree_x - hole_x) < MIN_DISTANCE_FROM_HOLE do
        tree_x = flr(rnd(#terrain))
    end
    return tree_x
end

function find_highest_point_for_tree(tree_start_x, tree_end_x)
    local highest_point = -1000

    for x = tree_start_x, tree_end_x do
        --printh("Terrain at " .. x)
        local i = flr(x)
        if terrain[i] then
            printh("Terrain at " .. i .. ": " .. terrain[i])
            if terrain[i] > highest_point then
                highest_point = terrain[i]
            end
        end
    end

    printh("Highest point: " .. highest_point)
    return highest_point
end

-- Snowflake structure
snowflakes = {}
local max_snowflakes = 100  -- Total number of snowflakes

-- Initialize snowflakes
for i=1,max_snowflakes do
    add(snowflakes, {
        x = rnd(128),         -- Random horizontal start
        y = rnd(-128, 0),     -- Start off-screen
        spd = rnd(0.5, 1.5)   -- Falling speed
    })
end

-- Update snowflakes
function update_snowflakes()
    for flake in all(snowflakes) do
        flake.y += flake.spd  -- Move down at flake's speed

        -- Reset snowflake to top of screen if it falls out
        if flake.y > 128 then
            flake.y = -8
            flake.x = rnd(128)
        end
    end
end

-- Draw snowflakes
function draw_snowflakes()
    for flake in all(snowflakes) do
        pset(flake.x, flake.y, 7)  -- Draw snowflake as a white pixel
    end
end

function draw_christmas_tree(x, y)
    -- Set color for tree foliage
    color(3) -- Green

    -- Tree top (triangle)
    line(x, y, x - 8, y + 24)
    line(x, y, x + 8, y + 24)
    line(x - 8, y + 24, x + 8, y + 24)

    -- Tree middle
    line(x, y + 8, x - 12, y + 32)
    line(x, y + 8, x + 12, y + 32)
    line(x - 12, y + 32, x + 12, y + 32)

    -- Tree bottom
    line(x, y + 16, x - 16, y + 40)
    line(x, y + 16, x + 16, y + 40)
    line(x - 16, y + 40, x + 16, y + 40)

    -- Tree trunk (rectangle)
    rectfill(x - 3, y + 40, x + 3, y + 48, 4)  -- Brown

    -- Add baubles
    local baubles = {{x-6, y+20}, {x+6, y+20}, {x, y+28}, {x-10, y+36}, {x+10, y+36}}
    for b in all(baubles) do
        local color_choices = {8, 9, 10, 12, 14}  -- Various colors for baubles
        circfill(b[1], b[2], 2, color_choices[flr(rnd(#color_choices)) + 1])
    end
end


function init_terrain()
    printh('init lvl_no: ' .. lvl_no)
    srand(lvl_no)
    hole_y = nil
    _clearPhysics()  -- Clear existing physics objects like walls
    terrain = {}
    
    -- Create a flat starting platform
    local starting_platform_width = 20  -- Adjust the width as necessary
    local starting_platform_height = 90  -- Fixed starting Y position for the terrain
    for x=1, starting_platform_width do
        terrain[x] = starting_platform_height
    end
    -- Add the wall for the starting platform to the physics engine
    _wall(-1, starting_platform_height, starting_platform_width, starting_platform_height)

    local segments = flr(rnd(11)) + 2 -- Between 2 and 12 segments
    local segment_width = (128 - starting_platform_width) / segments
    local last_x = starting_platform_width
    local last_y = starting_platform_height
    local next_y = last_y
    
    -- Determine hole position, ensure it's after the starting platform
    local min_hole_position = starting_platform_width + 32  -- Minimum distance after the platform
    hole_pos = flr(rnd(64 - hole_width)) + min_hole_position

    -- Adjust hole position if it's too close to a segment boundary
    while (hole_pos % segment_width) < hole_width or (hole_pos % segment_width) > (segment_width - hole_width) do
        hole_pos += 1
        -- To prevent infinite loops, we can add a safety check.
        -- For example, if hole_pos increments beyond a certain point without finding a valid position,
        -- the loop breaks and you can handle the error.
        if hole_pos > 115 then
            -- Handle error: reset hole_pos or break the loop
            break
        end
    end

    --printh('before loop')
    for s=1,segments do
        --printh('generating')
        local segment_start_x = last_x
        local segment_end_x = last_x + segment_width
        next_y = last_y + (flr(rnd(11)) - 5) * 5 -- Height variation of -25 to 25 pixels
        
        -- Clamp the terrain to ensure it doesn't go off-screen
        if next_y < 30 then next_y = 30 end
        if next_y > 110 then next_y = 110 end

        for x=flr(segment_start_x),flr(segment_end_x) do
            local t = (x - segment_start_x) / (segment_end_x - segment_start_x)
            local interpolated_y = (1 - t) * last_y + t * next_y

            -- Carve out the hole if x is within the hole's bounds
            if x >= hole_pos and x < hole_pos + hole_width then
                if not hole_y then
                    hole_y = interpolated_y
                end
                terrain[x] = hole_y + increased_hole_depth -- Use the increased hole depth here
            else
                terrain[x] = interpolated_y
            end
        end

        last_x = segment_end_x
        last_y = next_y

        draw_decorations = should_draw_decorations()
        draw_tree = should_draw_tree()
    end

    local wall_thickness = 5
    -- Add the walls for the hole sides, if the hole was created
    if hole_y then
        local hole_bottom_y = hole_y + increased_hole_depth
        _wall(hole_pos - 1, hole_y, hole_pos, hole_bottom_y)
        _wall(hole_pos + hole_width, hole_y, hole_pos + hole_width + 1, hole_bottom_y)
        
        -- Create the bottom wall for the hole
        _wall(hole_pos, hole_bottom_y, hole_pos + hole_width, hole_bottom_y)
    end

    tree_x = find_tree_position(hole_pos, terrain)
    tree_y = find_highest_point_for_tree(tree_x, tree_x+6)-45
end


function create_terrain_walls()
    printh('create_terrain_walls')
    local last_height = terrain[1] -- Assuming terrain[1] is the starting height
    for x=2,#terrain do
        _wall(x-1, last_height, x, terrain[x])
        last_height = terrain[x]
    end
end


function reset_player()
    printh('Resetting player - Last X: ' .. player.x .. ' Y: ' .. player.y .. ' vx: ' .. player.vx .. ' vy: ' .. player.vy)
    clearSaveData()
    player.x = 10
    player.y = terrain[flr(player.x)] - 5
    player.vx = 0
    player.vy = 0
    player.grounded = true
    player_ball = _circ(player.x, player.y, 2, false)
    player_ball.x = 10
    player_ball.y = terrain[flr(player.x)] - 5
    player_ball.dx = 0
    player_ball.dy = 0
    message_duration = 3 * 30
    message_timer = message_duration
end

function clearSaveData()
    for i=0,255 do
        dset(i, nil)
    end
end

function _init()
    cartdata("endless-golf")
    printh('dget(0): ' .. dget(0))
    if dget(0) == 0 then
        lvl_no =  2
    else
        lvl_no = dget(0)
    end    
    total_hits = dget(1) or 0
    hits_per_level = dget(2) or 0
    init_terrain()
    create_terrain_walls()
    reset_player()
end

function hit_ball(power, angle)
    -- Assuming the player's ball is an object with dx and dy for velocities
    local impulse_x = power * cos(angle)
    local impulse_y = power * sin(angle)

    player_ball.dx = impulse_x
    player_ball.dy = -impulse_y  -- negative because in many 2D engines, the y-axis is inverted
end

function _update()
    if not stat(57) then
        music(0)
      end
    if (btn(0)) then player.angle += 0.01 end -- left
    if (btn(1)) then player.angle -= 0.01 end -- right

    if (btn(2)) then -- up (increase power)
        player.power += 0.1
        if player.power > MAX_POWER then player.power = MAX_POWER end
    end
    if (btn(3)) then -- down (decrease power)
        player.power -= 0.1
        if player.power < 0 then player.power = 0 end
    end
    
    if (btnp(4) and player.grounded == true) then -- 'z' or 'c' (shoot)
        printh('player.power: ' .. tostring(player.power) .. ' angle: ' .. player.angle)
        hit_ball(player.power*2, player.angle)
        sfx(0)

        player.grounded = false

        total_hits += 1
        hits_per_level += 1
        save_game_data()
    end

    update_snowflakes()

    if message_timer > 0 then
        message_timer -= 1
    else
        messageShown = true    
    end

    -- Future positional checks
    local next_x, next_y = flr(player_ball.x + player_ball.dx), flr(player_ball.y + player_ball.dy)
    local tolerance = 3

    -- Check for ground beneath the current and next position
    local curr_x = flr(player.x)
    local curr_y = flr(player.y)
    local terrain_y_curr = terrain[curr_x]
    local terrain_y_next = terrain[next_x]

    -- Check if ball is in the hole
    if player_ball.x >= hole_pos and player_ball.x <= hole_pos + hole_width and player_ball.y >= terrain[hole_pos] - holeCol and player_ball.y < terrain[hole_pos] + hole_depth then
        time_in_hole += 1
    else
        time_in_hole = 0
    end

    -- If ball stays in the hole for a second
    if time_in_hole >=55 then
        sfx(1)
    end    

    if time_in_hole >= 60 then
        printh('in hole')
        lvl_no = lvl_no + 1
        reset_player()
        init_terrain()
        time_in_hole = 0
        hits_per_level = 0 -- Reset hits per level counter
        messageShown = false
        save_game_data()
        create_terrain_walls()
    end

    if player_ball.x < -2 or player_ball.x > 130 or player_ball.y > 128 then
        print('reset off left/right/bottom')
        reset_player()
    end

    if is_prime(lvl_no) then
        show_message(messages[lvl_no])
    end
    -- Update the physics for player_ball
    local sim = 4 -- Physics simulation steps
    for i=1,sim do
        player_ball:update(1/sim)
    end
end

function _draw()
    cls()
    if draw_tree then
        draw_christmas_tree(tree_x, tree_y)
    end

    -- Draw terrain
    for x=1,128 do
        line(x, terrain[x], x, 128, 12)
    end
    -- draw side walls if the hole was created
    if hole_y then
        -- left wall
        line(hole_pos, hole_y, hole_pos , hole_y + increased_hole_depth, 3) -- color 3 for green
        -- right wall
        line(hole_pos + hole_width, hole_y, hole_pos + hole_width, hole_y + increased_hole_depth, 3) 
    end
    
    if debugDraw then
        for i, y_val in pairs(terrain) do
            circ(i, y_val, 1, 8)  -- draw a small circle at each terrain point
        end
    end

    player_ball:draw()

    -- draw flag
    local flag_top = terrain[hole_pos] - 17
    line(hole_pos-1, flag_top, hole_pos-1, flag_top + 8, 8) -- flagpole
    rectfill(hole_pos - 4, flag_top, hole_pos - 2, flag_top + 3, 9) -- flag itself

    if player.grounded then
        line(player_ball.x, player_ball.y, player_ball.x + 8*cos(player.angle), player_ball.y - 8*sin(player.angle), 8) -- direction line
    end

    -- draw power bar
    rectfill(2, 2, 22, 6, 0)
    rectfill(3, 3, 2 + player.power*15, 5, 8)

    -- Display level number, total hits, and hits per level
    print("L:" .. lvl_no, 2, 8, 7)
    print("T:" .. total_hits, 2, 16, 7)
    print("H:" .. hits_per_level, 2, 24, 7)


    if draw_decorations then
        draw_cables_and_lights()
    end

    -- Draw the message if the timer is active
    if message_timer > 0 and is_prime(lvl_no) and messageShown == false then
        print_centered(auto_newline(prime_indexed_strings[lvl_no], 120), 44, 7)  -- Centered on screen
    end

    draw_snowflakes()
end

function check_if_grounded(player_ball)
    local ball_bottom_y = player_ball.y + player_ball.r -- Adjust for the radius of the ball
    local terrain_height_at_ball_x = terrain[flr(player_ball.x)]

    if terrain_height_at_ball_x ~= nil and (player_ball.x >= 0 or player_ball.x <= 128) then
        --printh('dy: ' .. player_ball.dy .. ' dx: ' .. player_ball.dx)
        if player_ball.dy <= 0.03 and player_ball.dx <= 0.03 then
            
            player.grounded = true
            -- Adjust player_ball's y to sit on the terrain
            player_ball.y = terrain_height_at_ball_x - player_ball.r
            -- You might also want to reset vertical velocity to 0 or a small bounce value depending on your game's physics
            player_ball.dy = 0
        else
            player.grounded = false
        end
    end
end

function save_game_data()
    dset(0, lvl_no)
    dset(1, total_hits)
    dset(2, hits_per_level)
end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000027650196500d650076500465006650086500a650006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00050000297501e75020756227602c7500e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e0002000000000
403200160816001e0016001208160816001e0016001208160816001e0016001208160816001e0016001208160816001e0016001208160816001e00160012081608160008070000011f0017001308170817001f00
000f00001604016040160401604016040160401604016040160401604016040160401604016040160401604016040160401604016040160401604016040160401604016040160401604016040160401604016040
000f00001a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a0401a040
000f00001d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d040
000f00001704017040170401704017040170401704017040170401704017040170401704017040170401704017040170401704017040170401704017040170401704017040170401704017040170401704017040
000f00001b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b0401b040
000f00002904029040290402904029040290402904029040290402904029040290402904029040290402904029040290402904029040290402904029040290402604026040260402604029040290402904029040
000f00002e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402c0402c0402c0402c0402c0402c0402c0402c0402a0402a0402a0402a0402a0402a0402a0402a040
000f00002904029040290402904029040290402904029040290402904029040290402904029040290402904027040270402704027040270402704027040270402604026040260402604029040290402904029040
000f00002704027040270402704027040270402704027040270402704027040270402704027040270402704022040220402204022040220402204022040220402004020040200402004020040200402004020040
000f00002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402004020040200402004022040220402204022040
000f00002304023040230402304023040230402304023040230402304023040230402504025040230402304022040220402204022040220402204022040220402004020040200402004020040200402004020040
000f00002204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040220402204022040
000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002704027040270402704027040270402704027040
000f00002604026040260402604026040260402604026040260402604026040260402604026040260402604022040220402204022040220402204022040220402204022040220402204022040220402204022040
000f00002304023040230402304023040230402304023040230402304023040230402304023040230402304027040270402704027040270402704027040270402a0402a0402a0402a0402a0402a0402a0402a040
000f00002e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402e0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f0402f040
000f000022040220402004020040220402204029040290402904029040220402204020040200401d0401d04022040220402004020040220402204029040290402904029040220402204020040200402204022040
000f00002c0402c0402a0402a04029040290402a0402a0402a0402a0402904029040270402704025040250402c0402c0402a0402a04029040290402a0402a0402a0402a040290402904025040250402304023040
000f00001d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401d0401a0401a0401d0401d04022040220402204022040220402204022040220402504025040250402504023040230402304023040
000f00002204022040220402204023040230402204022040220402204022040220401d0401d0401d0401d040200402004020040200401e0401e0401e0401e0401d0401d0401d0401d0401b0401b0401b0401b040
000f00002204022040220402204022040220402204022040220402204022040220402004020040220402204029040290402904029040290402904029040290402c0402c0402c0402c0402a0402a0402a0402a040
000f000029040290402904029040290402904029040290402e0402e0402e0402e040290402904029040290402c0402c0402c0402c0402a0402a0402a0402a0402904029040290402904027040270402704027040
000f00002604026040260402604026040260402604026040260402604026040260402404024040260402604029040290402904029040290402904029040290402e0402e0402e0402e0402f0402f0402f0402f040
000f00002e0402e0402e0402e0402e0402e0402e0402e0402c0402c0402c0402c0402e0402e0402e0402e0402c0402c0402c0402c0402a0402a0402a0402a040290402904029040290402a0402a0402a0402a040
000f00002c0402c0402904029040260402604029040290402604026040220402204020040200401d0401d0402c0402c0402904029040260402604029040290402604026040220402204026040260402904029040
000f00002a0402a040290402904027040270402504025040270402704025040250402304023040220402204020040200402204022040230402304022040220402004020040230402304022040220402004020040
__music__
00 03040540
00 06070540
00 03040540
00 06070540
00 03040540
00 06070540
00 03040540
00 06070540
00 03040540
00 06070540
00 03040540
00 06070540
00 03040508
00 06070509
00 03040508
00 06070509
00 0304050a
00 0607050b
00 0304050c
00 0607050d
00 0304050e
00 06070540
00 03040540
00 0607050f
00 03040510
00 06070511
00 03040508
00 06070512
00 13404040
00 13404040
00 13404040
00 13404040
00 13404013
00 14404014
00 15404013
00 15404014
00 15404013
00 15404014
00 15404013
00 15404014
00 03040515
00 06070516
00 03040517
00 06070518
00 03040519
00 0607051a
00 0304051b
00 0607051c
00 03040540
04 06070540

