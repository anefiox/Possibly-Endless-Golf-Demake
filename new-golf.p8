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
        lvl_no =  1
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
__label__
00000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088888888888888888888888888888888888888888888888888888888888888888888888888888888888887888888880000000000000000000000000000000
00088888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000
00088888888888788888888888888888888888888888888888888888888888888888888888888888888888888888888880000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000007000000000000000
00000000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700007000070000000000000000000000000000000000000000700000000000000000000000000000000000000000000700000000000000000000000000000
00700000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007770000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007700707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777007000700707000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00070007000700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000007770007000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007770000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000000000000
00707007007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777007007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000070000000000000000000000000000000000000000000000000700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000007700003777077007070777070707770770007700000777070707770777000007770770077007000777007700770777000000000000000
00000000700000777070000003737070707070070070700700707070000000700070707000707000007000707070707000700070007000007000000000000000
00000000000000070077700003777070707770070077700700707070000000770070707700770000007700707070707000770077707770077000000000000000
00000000000000070000700030707070700070070070700700707070700000700077707000707000007000707070707000700000700070000000000000000000
00000000000000777077000030707070707770070070707770707077700000777007007770707000007770707077707770777077007700070000000000000000
00000000000000000000000070003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000300300300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000
00000000000000000000000300330300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000003003003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000003030003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000003030000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccc
0000000000000000000003030000030300000000000000070000000000000000000000000000000000000000000000000000000000000000000000000ccccccc
0000000000000000000003030000003300000000000000070000000000000000000000000000000000000000000000000000000000000000000000cccccccccc
000000000000000000000330003000330000000000000000000000000000000000000000000000000000000000000000000000000000000000cccccccccccccc
000000000000000000003030030300033000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccc
0000000000000000000aaa0003030008880000000000000000000000000000000000000000000000000000000000000000000000000ccccccccccccccccccccc
000000000000000000aaaaa03000308888800000000000000000000000000000000000000000000000000000000000000000700ccccccccccccccccccccccccc
000000000000000000aaaaa30000038888800000000000000000000000000000000000000000000000000000000000000000cccccccccccccccccccccccccccc
000000000000000000aaaaa3000003888880000000000000000000000000000000000000000070000000000000000000cccccccccccccccccccccccccccccccc
0000000000000000000aaa30000000388800000000000000000000000000009998000000000000000000000000000ccccccccccccccccccccccccccccccccccc
00000000000000000033030000000003003000000000000000000000000000999800000000000000000000000ccccccccccccccccccccccccccccccccccccccc
0000000000000000003333333333333333300000000000000000000000000099980000000000000000000ccccccccccccccccccccccccccccccccccccccccccc
0000000000000000003030000000000030030000000000000000000000000099980000000000000000cccccccccccccccccccccccccccccccccccccccccccccc
0000000000000000030300000aaa00000303000000000000000000000000000008000000000000cccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000003030000aaaaa0000300300000000000000000000000000008000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000030300000aaaaa000003030000000000000000000000000000800000000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000000033000000aaaaa000000303000000000000000000000000000800000000cccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000003030000000aaa00000003030000000000000000000000000008300000007ccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000003300000000000000000003030000000000000000000000000cc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000033333333333333333333333330000000000000000000000ccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000000003000000000000000000000300000000000000000000cccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000000003eee00000000000000000999300000000000000000cccccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000003eeeee0000000000000009999930000000000000ccccccccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000003eeeee0000000000000009799930000000000cccccccccccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000000030eeeee00000000000000099999030000000cccccccccccccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000008000eee000000000000000009990003000ccccccccccccccccccccc300000003ccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000008000000000000000007000000000003cccccccccccccccccccccccc3ccccccc3ccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000038333333333334444444333333333ccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccc
0000000000080000000000044444440000000cccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000000800000000000044444440000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0000000007870000000000044444440cccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000778770000000000444444ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000778770000000000444cccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
00000000777770000000007ccccccccccccc7ccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
000000000777000000000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0cccccccccccccccccccccccccccccccccccccccccccccccc7cccccccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccccccc
07cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccc7ccccccccccccccccc7ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
0ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__sfx__
0001000027650196500d650076500465006650086500a650006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00050000297501e75020756227602c7500e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e000208060000000e000e0002000000000
00100000225602256022560000001d5701d5701d570000001a5601a5601a560000001d5601d5601d5601d5601d560000001b5601b560185501855018550000001656016560165601656016560165600000000000
001000001d0601d0601d060000001a0601a0601a06000000160601606016060000001806018060180601806018060000001805018050150601506015060000001105011050110501105011050110500000000000
001000001a5601a5601d5601d5602257022570225702257022570225702257022570225702257000000000001d5601d5601d5601d5601d560000001f5501f5501d5601d5601d560000001a5701a5701a5701a570
0010000016050160501a0501a0501d0501d0501d0501d0501d0501d0501d0501d0501d0501d05000000000001a0601a0601a0601a0601a060000001b0601b0601a0601a0601a0600000016050160501605016050
001000001a5701a5701a5701a5701a5701a57000000000001d5601d5601d5601d5601d560000001f5601f5601d5601d5601d560000001a5701a5701a5701a5701a5701a5701a5701a5701a5701a5700000000000
0010000016050160501605016050160501605000000000001a0501a0501a0501a0501a050000001b0601b0601a0601a0601a06000000160601606016060160601606016060160601606016060160600000000000
001000002456024560245602456024560245600000000000245602456024560000002156021560215602156021560215602156021560215602156000000000002256022560225602256022560225600000000000
001000002106021060210602106021060210600000000000210602106021060000001b0601b0601b0601b0601b0601b0601b0601b0601b0601b06000000000001d0601d0601d0601d0601d0601d0600000000000
00100000225602256022560000001d5701d5701d5701d5701d5701d5701d5701d5701d5701d5701d570000001f5601f5601f5601f5601f5601f56000000000001f5601f5601f5600000022560225602256022560
001000001d0501d0501d050000001a0601a0601a0601a0601a0601a0601a0601a0601a0601a0601a060000001b0601b0601b0601b0601b0601b06000000000001b0501b0501b050000001f0601f0601f0601f060
00100000225600000021560215601f5601f5601f560000001d5601d5601d5601d5601d560000001f5601f5601d5601d5601d560000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a5600000000000
001000001f060000001b0601b0601b0601b0601b060000001a0501a0501a0501a0501a050000001b0501b0501a0501a0501a05000000160501605016050160501605016050160501605016050160500000000000
001000001f5601f5601f5601f5601f5601f56000000000001f5701f5701f5700000022560225602256022560225600000021560215601f5601f5601f560000001d5601d5601d5601d5601d560000001f5501f550
001000001b0501b0501b0501b0501b0501b05000000000001b0501b0501b050000001f0601f0601f0601f0601f060000001b0601b0601b0601b0601b060000001a0601a0601a0601a0601a060000001b0501b050
001000001d5701d5701d570000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a560000000000024550245502455024550245502455000000000002456024560245600000027560275602756027560
001000001a0501a0501a0500000016060160601606016060160601606016060160601606016060000000000021050210502105021050210502105000000000002106021060210600000024060240602406024060
001000002756000000245702457021560215602156000000225702257022570225702257022570225702257022570225700000000000265502655026550265502655026550265502655026550265500000000000
00100000240600000021050210501b0601b0601b060000001d0501d0501d0501d0501d0501d0501d0501d0501d0501d0500000000000220602206022060220602206022060220602206022060220600000000000
00100000225602256022560000001d5601d5601d560000001a5601a5601a560000001d5601d5601d5601d5601d560000001b5701b570185701857018570000001656016560165601656016560165601656016560
001000001d0501d0501d050000001a0601a0601a06000000160601606016060000001806018060180601806018060000001805018050150501505015050000001105011050110501105011050110501105011050
0010000016560165601656016560165601656016560165601656016560165601656016560165601656000000225602256022560000001d5601d5601d560000001a5601a5601a560000001d5601d5601d5601d560
00100000110501105011050110501105011050110501105011050110501105011050110501105011050000001d0601d0601d060000001a0501a0501a050000001605016050160500000018050180501805018050
001000001d560000001b5701b5702455024550245500000022560225602256000000115601156016560165601a5601a5601d5601d560225602256022560225602256022560225602256022560225600000000000
0010000018050000001805018050210602106021060000001d0601d0601d060000000e0500e050110601106016060160601a0601a0601d0501d0501d0501d0501d0501d0501d0501d0501d0501d0500000000000
001000001d5501d5501d5501d5501d550000001f5601f5601d5601d5601d560000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a56000000000001d5601d5601d5600000000000000001f5601f560
001000001a0601a0601a0601a0601a060000001b0601b0601a0601a0601a060000001605016050160501605016050160501605016050160501605000000000001a0501a0501a0500000000000000001b0501b050
001000001d5601d5601d560000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a560000000000024560245602456024560245602456000000000002456024560245600000021560215602156021560
001000001a0601a0601a060000001606016060160601606016060160601606016060160601606000000000002105021050210502105021050210500000000000210602106021060000001b0501b0501b0501b050
0010000021560215602156021560215602156000000000002256022560225602256022560225600000000000225602256022560000001d5701d5701d5701d5701d5701d5701d5701d5701d5701d5700000000000
001000001b0501b0501b0501b0501b0501b05000000000001d0501d0501d0501d0501d0501d05000000000001d0501d0501d050000001a0601a0601a0601a0601a0601a0601a0601a0601a0601a0600000000000
001000001f5601f5601f5601f5601f5601f56000000000001f5601f5601f5600000022570225702257022570225700000021560215601f5601f5601f560000001d5601d5601d5601d5601d560000001f5601f560
001000001b0501b0501b0501b0501b0501b05000000000001b0601b0601b060000001f0501f0501f0501f0501f050000001b0601b0601b0601b0601b060000001a0501a0501a0501a0501a050000001b0501b050
001000001d5601d5601d560000001a5701a5701a5701a5701a5701a5701a5701a5701a5701a57000000000001f5701f5701f5701f5701f5701f57000000000001f5601f5601f5600000022560225602256022560
001000001a0601a0601a060000001605016050160501605016050160501605016050160501605000000000001b0501b0501b0501b0501b0501b05000000000001b0501b0501b050000001f0601f0601f0601f060
001000001f060000001b0601b0601b0501b0501b050000001a0501a0501a0501a0501a050000001b0601b0601a0501a0501a05000000160601606016060160601606016060160601606016060160600000000000
001000002456024560245602456024560245600000000000245602456024560000002757027570275702757027570000002456024560215602156021560000002256022560225602256022560225602256022560
0010000021050210502105021050210502105000000000002106021060210600000024060240602406024060240600000021050210501b0601b0601b060000001d0501d0501d0501d0501d0501d0501d0501d050
0010000022560225600000000000265602656026560265602656026560265602656026560265600000000000225602256022560000001d5601d5601d560000001a5601a5601a560000001d5601d5601d5601d560
001000001d0501d05000000000002205022050220502205022050220502205022050220502205000000000001d0601d0601d060000001a0501a0501a050000001606016060160600000018060180601806018060
001000001d560000001b5601b56018560185601856000000165601656016560165601656016560165601656016560165601656016560165601656016560165601656016560165601656016560165601656000000
001000001806000000180501805015050150501505000000110501105011050110501105011050110501105011050110501105011050110501105011050110501105011050110501105011050110501105000000
00100000225602256022560000001d5601d5601d560000001a5601a5601a560000001d5701d5701d5701d5701d570000001b5601b560185701857018570000001656016560165601656016560165600000000000
001000001d0601d0601d060000001a0501a0501a05000000160601606016060000001805018050180501805018050000001805018050150601506015060000001105011050110501105011050110500000000000
001000001a5701a5701d5501d5502257022570225702257022570225702257022570225702257022570000001d5601d5601d5601d5601d560000001f5601f5601d5701d5701d570000001a5601a5601a5601a560
0010000016060160601a0501a0501d0501d0501d0501d0501d0501d0501d0501d0501d0501d0501d050000001a0601a0601a0601a0601a060000001b0601b0601a0601a0601a0600000016050160501605016050
001000001a5601a5601a5601a5601a5601a56000000000001d5701d5701d5701d5701d570000001f5601f5601d5601d5601d560000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a5600000000000
0010000016050160501605016050160501605000000000001a0601a0601a0601a0601a060000001b0501b0501a0601a0601a06000000160601606016060160601606016060160601606016060160600000000000
001000002105021050210502105021050210500000000000210602106021060000001b0601b0601b0601b0601b0601b0601b0601b0601b0601b06000000000001d0601d0601d0601d0601d0601d0600000000000
00100000225602256022560000001d5601d5601d5601d5601d5601d5601d5601d5601d5601d5601d560000001f5601f5601f5601f5601f5601f56000000000001f5601f5601f5600000022560225602256022560
001000001d0601d0601d060000001a0601a0601a0601a0601a0601a0601a0601a0601a0601a0601a060000001b0601b0601b0601b0601b0601b06000000000001b0501b0501b050000001f0601f0601f0601f060
00100000225600000021570215701f5601f5601f560000001d5601d5601d5601d5601d560000001f5601f5601d5601d5601d560000001a5701a5701a5701a5701a5701a5701a5701a5701a5701a5700000000000
001000001f060000001b0501b0501b0501b0501b050000001a0601a0601a0601a0601a060000001b0501b0501a0501a0501a05000000160601606016060160601606016060160601606016060160600000000000
001000001f5701f5701f5701f5701f5701f57000000000001f5601f5601f5600000022560225602256022560225600000021560215601f5601f5601f560000001d5601d5601d5601d5601d560000001f5701f570
001000001b0501b0501b0501b0501b0501b05000000000001b0501b0501b050000001f0501f0501f0501f0501f050000001b0601b0601b0601b0601b060000001a0501a0501a0501a0501a050000001b0601b060
001000001d5701d5701d570000001a5601a5601a5601a5601a5601a5601a5601a5601a5601a560000000000024560245602456024560245602456000000000002456024560245600000027560275602756027560
001000001a0501a0501a0500000016060160601606016060160601606016060160601606016060000000000021050210502105021050210502105000000000002105021050210500000024050240502405024050
001000002756000000245602456021560215602156000000225702257022570225702257022570225702257022570225700000000000265602656026560265602656026560265602656026560265600000000000
00100000240500000021060210601b0601b0601b060000001d0501d0501d0501d0501d0501d0501d0501d0501d0501d0500000000000220602206022060220602206022060220602206022060220600000000000
00100000225702257022570000001d5601d5601d560000001a5601a5601a560000001d5701d5701d5701d5701d570000001b5601b560185501855018550000001656016560165601656016560165601656016560
001000001d0601d0601d060000001a0601a0601a06000000160501605016050000001806018060180601806018060000001805018050150601506015060000001106011060110601106011060110601106011060
00100000165601656016560165601656016560165601656016560165601656016560165601656016560000001b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b5601b560
001000001106011060110601106011060110601106011060110601106011060110601106011060110600000016060160601606016060160601606016060160601606016060160601606016060160601606016060
__music__
00 02034040
00 04054040
00 06074040
00 08094040
00 0a0b4040
00 0c0d4040
00 0e0f4040
00 10114040
00 12134040
00 14154040
00 16174040
00 18194040
00 1a1b4040
00 1c1d4040
00 1e1f4040
00 20214040
00 22234040
00 0c244040
00 25264040
00 27284040
00 292a4040
00 2b2c4040
00 2d2e4040
00 2f304040
00 08314040
00 32334040
00 34354040
00 36374040
00 38394040
00 3a3b4040
00 3c3d4040
00 3e3f4040
04 80804040

