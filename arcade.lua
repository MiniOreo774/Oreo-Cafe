-- Arcade Games (loaded from main.lua, AFTER papas.lua and rpg.lua)
--
-- An "Arcade Games" tab at the top of the shop, beside ORDERS and Oreo RPG.
--   Cookie Snake    steer the snake and eat cookies (arrows / WASD, or click where you want to turn)
--   Brick Breaker   keep the ball up and clear the wall (mouse or arrows)
--   Flappy Jimbo    flap between the pipes (Space / Up / click)
--   Whack-a-Jimbo   bonk Jimbos, leave the bombs alone (click, or keys 1-9 laid out like a numpad)
--  * Each shop gives MAX_PLAYS plays: the first FREE_PLAYS are free, the rest cost PLAY_COST.
--  * Your score earns a Bronze, Silver or Gold medal. Rewards are paid the moment the run ends.
--  * Esc (controller: B / Start) ends a run early and still pays the medal you have reached.
--  * The menu is a normal overlay. The game itself is drawn over the screen in love.draw, and while a
--    run is on, keyboard / mouse / controller presses go to the arcade instead of Balatro.
--  Saved on G.GAME.ocafe_arcade: round (shop the counter belongs to), used (plays this shop), best (per game).
-- All art is drawn with shapes, so no image files are needed.

----------------------------------------------------------------
-- TUNING
----------------------------------------------------------------
local MAX_PLAYS = 3                 -- plays per shop (all games share them)
local FREE_PLAYS = 1                -- how many of those are free
local PLAY_COST = 2                 -- price of every other play
local CASH = { 2, 4, 5 }            -- money for Bronze / Silver / Gold
local GOLD_CARDS = { "Tarot", "Planet" } -- Gold also gives one random card of one of these
local NO_ROOM_CASH = 3              -- paid instead when there is no consumable slot
local MEDALS = { "Bronze", "Silver", "Gold" }

local W, H, HUD = 480, 400, 40      -- virtual screen of the cabinet (play area: y = HUD .. H)

local Arcade = {}

local function rnd(a, b)
    local r = (love and love.math and love.math.random) or math.random
    return r(a, b)
end

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

----------------------------------------------------------------
-- DRAWING HELPERS
----------------------------------------------------------------
local fonts = {}
local view = { x = 0, y = 0, s = 1 }   -- where the virtual screen sits in the window

local function set_colour(r, g, b, a) love.graphics.setColor(r, g, b, a or 1) end
local function rect(x, y, w, h, r) love.graphics.rectangle("fill", x, y, w, h, r or 0, r or 0) end
local function circle(x, y, r) love.graphics.circle("fill", x, y, r) end

-- text centred on x; the font is made at the on-screen size so it stays sharp
local function text(str, x, y, size)
    local px = math.max(6, math.floor(size * view.s + 0.5))
    local font = fonts[px]
    if not font then
        font = love.graphics.newFont(px)
        fonts[px] = font
    end
    love.graphics.setFont(font)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(1 / view.s)
    love.graphics.print(str, -math.floor(font:getWidth(str) / 2), 0)
    love.graphics.pop()
end

local function cookie(x, y, r)
    set_colour(0.16, 0.10, 0.08); circle(x, y, r)
    set_colour(0.95, 0.93, 0.86); circle(x, y, r * 0.55)
    set_colour(0.16, 0.10, 0.08); circle(x, y, r * 0.25)
end

local function jimbo(x, y, r)
    set_colour(0.85, 0.2, 0.2)
    love.graphics.polygon("fill", x - r, y - r * 0.3, x - r * 1.1, y - r * 1.4, x, y - r * 0.6)
    set_colour(0.2, 0.45, 0.85)
    love.graphics.polygon("fill", x + r, y - r * 0.3, x + r * 1.1, y - r * 1.4, x, y - r * 0.6)
    set_colour(0.98, 0.93, 0.85); circle(x, y, r)
    set_colour(0.1, 0.1, 0.1); circle(x - r * 0.35, y - r * 0.2, r * 0.13); circle(x + r * 0.35, y - r * 0.2, r * 0.13)
    set_colour(0.85, 0.2, 0.2); circle(x, y + r * 0.1, r * 0.18)
    rect(x - r * 0.45, y + r * 0.45, r * 0.9, r * 0.14, r * 0.07)
end

----------------------------------------------------------------
-- GAMES
-- Each one: new() -> state; update(s, dt, input); press(s, key); click(s, x, y); draw(s)
-- A state has `score` and sets `over` when the run is finished.
-- input = { left, right (held keys), mx, my (mouse, virtual coords), mouse_moved }
-- keys are normalised to: up, down, left, right, action, "1".."9"
----------------------------------------------------------------
local SNAKE_CELL, SNAKE_COLS, SNAKE_ROWS = 24, 20, 15
local DIRS = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

local function snake_free(s, x, y)
    for _, p in ipairs(s.body) do
        if p[1] == x and p[2] == y then return false end
    end
    return true
end

local function snake_food(s)
    local free = {}
    for x = 0, SNAKE_COLS - 1 do
        for y = 0, SNAKE_ROWS - 1 do
            if snake_free(s, x, y) then free[#free + 1] = { x, y } end
        end
    end
    s.food = (#free > 0) and free[rnd(1, #free)] or nil
    if not s.food then s.over = true end
end

local function snake_turn(s, name)
    local d = DIRS[name]
    if not d or #s.turns >= 2 then return end
    local last = s.turns[#s.turns] or s.dir
    -- no standing still on the same heading, and no turning straight back into yourself
    if (d[1] == last[1] and d[2] == last[2]) or (d[1] == -last[1] and d[2] == -last[2]) then return end
    s.turns[#s.turns + 1] = d
end

local snake = {
    id = "snake", name = "Cookie Snake", goals = { 5, 10, 18 }, unit = "cookies",
    help = "Eat cookies. Don't hit the walls or yourself.",
    controls = "Arrows / WASD, or click toward where you want to turn",
    new = function()
        local s = { score = 0, body = { { 5, 7 }, { 4, 7 }, { 3, 7 } }, dir = DIRS.right, turns = {}, clock = 0 }
        snake_food(s)
        return s
    end,
    press = function(s, key) snake_turn(s, key) end,
    click = function(s, x, y)
        local head, last = s.body[1], s.turns[#s.turns] or s.dir
        local dx = x - (head[1] + 0.5) * SNAKE_CELL
        local dy = y - HUD - (head[2] + 0.5) * SNAKE_CELL
        if last[1] ~= 0 then
            snake_turn(s, dy < 0 and "up" or "down")
        else
            snake_turn(s, dx < 0 and "left" or "right")
        end
    end,
    update = function(s, dt)
        s.clock = s.clock + dt
        local step = math.max(0.08, 0.15 - 0.004 * s.score)
        while s.clock >= step and not s.over do
            s.clock = s.clock - step
            if #s.turns > 0 then s.dir = table.remove(s.turns, 1) end
            local x, y = s.body[1][1] + s.dir[1], s.body[1][2] + s.dir[2]
            local eats = s.food and x == s.food[1] and y == s.food[2]
            -- the tail moves out of the way unless the snake is growing
            local tail = (not eats) and table.remove(s.body) or nil
            if x < 0 or y < 0 or x >= SNAKE_COLS or y >= SNAKE_ROWS or not snake_free(s, x, y) then
                if tail then s.body[#s.body + 1] = tail end
                s.over = true
            else
                table.insert(s.body, 1, { x, y })
                if eats then
                    s.score = s.score + 1
                    snake_food(s)
                end
            end
        end
    end,
    draw = function(s)
        for i = #s.body, 1, -1 do
            local p = s.body[i]
            if i == 1 then set_colour(0.55, 0.95, 0.45) else set_colour(0.3, 0.72, 0.35) end
            rect(p[1] * SNAKE_CELL + 1, HUD + p[2] * SNAKE_CELL + 1, SNAKE_CELL - 2, SNAKE_CELL - 2, 5)
        end
        if s.food then
            cookie((s.food[1] + 0.5) * SNAKE_CELL, HUD + (s.food[2] + 0.5) * SNAKE_CELL, SNAKE_CELL * 0.45)
        end
    end,
}

local PAD_W, PAD_Y, BALL_R = 80, 376, 6
local BRICK_COLS, BRICK_ROWS, BRICK_W, BRICK_H = 8, 5, 56, 16
local BREAK_TIME = 120

local function breaker_serve(s)
    s.stuck = true
    s.bx, s.by = s.px, PAD_Y - BALL_R
end

local function breaker_launch(s)
    if not s.stuck then return end
    s.stuck = false
    local speed = math.min(370, 240 + 3 * s.score)
    local angle = math.rad(rnd(-35, 35))
    s.vx, s.vy = speed * math.sin(angle), -speed * math.cos(angle)
end

local function breaker_step(s, dt)
    local ox, oy = s.bx, s.by
    s.bx, s.by = s.bx + s.vx * dt, s.by + s.vy * dt
    if s.bx < BALL_R then s.bx, s.vx = BALL_R, math.abs(s.vx) end
    if s.bx > W - BALL_R then s.bx, s.vx = W - BALL_R, -math.abs(s.vx) end
    if s.by < HUD + BALL_R then s.by, s.vy = HUD + BALL_R, math.abs(s.vy) end

    -- paddle: where the ball lands decides the angle it leaves at
    if s.vy > 0 and oy <= PAD_Y - BALL_R + 4 and s.by >= PAD_Y - BALL_R
        and math.abs(s.bx - s.px) <= PAD_W / 2 + BALL_R then
        local speed = math.min(370, 240 + 3 * s.score)
        local angle = clamp((s.bx - s.px) / (PAD_W / 2), -1, 1) * math.rad(60)
        s.vx, s.vy = speed * math.sin(angle), -speed * math.cos(angle)
        s.by = PAD_Y - BALL_R
    end

    for i, b in ipairs(s.bricks) do
        if s.bx + BALL_R > b.x and s.bx - BALL_R < b.x + BRICK_W
            and s.by + BALL_R > b.y and s.by - BALL_R < b.y + BRICK_H then
            -- came from the side if it was clear of the brick horizontally a moment ago
            if ox + BALL_R <= b.x or ox - BALL_R >= b.x + BRICK_W then
                s.vx = -s.vx
            else
                s.vy = -s.vy
            end
            s.bx, s.by = ox, oy
            table.remove(s.bricks, i)
            s.score = s.score + 1
            if #s.bricks == 0 then s.over = true end
            break
        end
    end

    if s.by > H + BALL_R then
        s.lives = s.lives - 1
        if s.lives <= 0 then s.over = true else breaker_serve(s) end
    end
end

local breaker = {
    id = "breaker", name = "Brick Breaker", goals = { 15, 28, 40 }, unit = "bricks",
    help = "3 balls, 2 minutes. Break all 40 bricks for Gold.",
    controls = "Mouse or arrows to move, click / Space to launch",
    new = function()
        local s = { score = 0, lives = 3, px = W / 2, time = BREAK_TIME, bricks = {} }
        for row = 0, BRICK_ROWS - 1 do
            for col = 0, BRICK_COLS - 1 do
                s.bricks[#s.bricks + 1] = { x = 9 + col * (BRICK_W + 2), y = HUD + 30 + row * (BRICK_H + 4), row = row }
            end
        end
        breaker_serve(s)
        return s
    end,
    press = function(s, key)
        if key == "action" or key == "up" then breaker_launch(s) end
    end,
    click = function(s) breaker_launch(s) end,
    update = function(s, dt, input)
        if input.mouse_moved then s.px = input.mx end
        if input.left then s.px = s.px - 360 * dt end
        if input.right then s.px = s.px + 360 * dt end
        s.px = clamp(s.px, PAD_W / 2, W - PAD_W / 2)
        s.time = s.time - dt
        if s.time <= 0 then
            s.time, s.over = 0, true
            return
        end
        if s.stuck then
            s.bx = s.px
            return
        end
        -- small sub-steps so the ball can't jump through a brick
        local n = math.max(1, math.ceil(dt / 0.008))
        for _ = 1, n do
            if s.over or s.stuck then break end
            breaker_step(s, dt / n)
        end
    end,
    draw = function(s)
        local cols = { { 0.9, 0.3, 0.3 }, { 0.95, 0.6, 0.2 }, { 0.95, 0.85, 0.25 }, { 0.35, 0.8, 0.4 }, { 0.3, 0.6, 0.95 } }
        for _, b in ipairs(s.bricks) do
            local c = cols[b.row + 1]
            set_colour(c[1], c[2], c[3]); rect(b.x, b.y, BRICK_W, BRICK_H, 3)
        end
        set_colour(0.9, 0.9, 0.95); rect(s.px - PAD_W / 2, PAD_Y, PAD_W, 10, 5)
        cookie(s.bx, s.by, BALL_R)
        set_colour(0.75, 0.75, 0.8)
        text("Balls " .. s.lives .. "    Time " .. math.ceil(s.time), W / 2, HUD + 6, 14)
    end,
}

local BIRD_X, BIRD_R, PIPE_W, PIPE_GAP, PIPE_SPACE = 120, 12, 52, 128, 210

local function add_pipe(s, x)
    -- the next gap is never too far from the last one to reach
    local y = clamp((s.last_gap or 220) + rnd(-100, 100), HUD + 90, H - 90)
    s.last_gap = y
    s.pipes[#s.pipes + 1] = { x = x, y = y }
end

local function flap(s) s.vy = -280 end

local flappy = {
    id = "flappy", name = "Flappy Jimbo", goals = { 5, 12, 20 }, unit = "pipes",
    help = "Fly Jimbo through the gaps.",
    controls = "Space / Up / click to flap",
    new = function()
        local s = { score = 0, y = 220, vy = 0, pipes = {} }
        for i = 0, 2 do add_pipe(s, W + 40 + i * PIPE_SPACE) end
        return s
    end,
    press = function(s, key)
        if key == "action" or key == "up" then flap(s) end
    end,
    click = function(s) flap(s) end,
    update = function(s, dt)
        s.vy = math.min(420, s.vy + 850 * dt)
        s.y = s.y + s.vy * dt
        if s.y < HUD + BIRD_R then s.y, s.vy = HUD + BIRD_R, 0 end
        local speed = math.min(185, 140 + 2 * s.score)
        for _, p in ipairs(s.pipes) do
            p.x = p.x - speed * dt
            if not p.passed and p.x + PIPE_W < BIRD_X - BIRD_R then
                p.passed = true
                s.score = s.score + 1
            end
            -- the hit box is a little smaller than the drawing, so near misses feel fair
            local r = BIRD_R - 2
            if BIRD_X + r > p.x and BIRD_X - r < p.x + PIPE_W
                and (s.y - r < p.y - PIPE_GAP / 2 or s.y + r > p.y + PIPE_GAP / 2) then
                s.over = true
            end
        end
        if s.y + BIRD_R >= H then s.over = true end
        if s.pipes[1] and s.pipes[1].x + PIPE_W < 0 then
            table.remove(s.pipes, 1)
            add_pipe(s, s.pipes[#s.pipes].x + PIPE_SPACE)
        end
    end,
    draw = function(s)
        for _, p in ipairs(s.pipes) do
            local top, bottom = p.y - PIPE_GAP / 2, p.y + PIPE_GAP / 2
            set_colour(0.25, 0.7, 0.35)
            rect(p.x, HUD, PIPE_W, top - HUD)
            rect(p.x, bottom, PIPE_W, H - bottom)
            set_colour(0.45, 0.88, 0.5)
            rect(p.x - 3, top - 10, PIPE_W + 6, 10, 2)
            rect(p.x - 3, bottom, PIPE_W + 6, 10, 2)
        end
        jimbo(BIRD_X, s.y, BIRD_R)
    end,
}

local WHACK_TIME = 30
local NUMPAD = { ["7"] = 1, ["8"] = 2, ["9"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["1"] = 7, ["2"] = 8, ["3"] = 9 }

local function hole_pos(i)
    return 120 + ((i - 1) % 3) * 120, HUD + 80 + math.floor((i - 1) / 3) * 105
end

local function whack(s, i)
    local h = s.holes[i]
    if not h or not h.who or h.hit then return end
    if h.who == "jimbo" then
        s.score = s.score + 1
    else
        s.score = math.max(0, s.score - 3)
    end
    h.hit, h.ttl = true, 0.18
end

local whacker = {
    id = "whack", name = "Whack-a-Jimbo", goals = { 12, 20, 27 }, unit = "points",
    help = "30 seconds. Jimbo +1, bomb -3.",
    controls = "Click, or keys 1-9 (numpad layout)",
    new = function()
        local s = { score = 0, time = WHACK_TIME, next_spawn = 0.3, holes = {} }
        for i = 1, 9 do s.holes[i] = { ttl = 0 } end
        return s
    end,
    press = function(s, key)
        if NUMPAD[key] then whack(s, NUMPAD[key]) end
    end,
    click = function(s, x, y)
        for i = 1, 9 do
            local hx, hy = hole_pos(i)
            if (x - hx) ^ 2 + (y - hy) ^ 2 <= 46 ^ 2 then
                whack(s, i)
                return
            end
        end
    end,
    update = function(s, dt)
        s.time = s.time - dt
        if s.time <= 0 then
            s.time, s.over = 0, true
            return
        end
        for _, h in ipairs(s.holes) do
            if h.who then
                h.ttl = h.ttl - dt
                if h.ttl <= 0 then h.who, h.hit = nil, nil end
            end
        end
        s.next_spawn = s.next_spawn - dt
        if s.next_spawn <= 0 then
            local progress = 1 - s.time / WHACK_TIME
            s.next_spawn = s.next_spawn + 0.8 - 0.38 * progress
            local free = {}
            for i, h in ipairs(s.holes) do
                if not h.who then free[#free + 1] = i end
            end
            if #free > 0 then
                local h = s.holes[free[rnd(1, #free)]]
                h.who = (rnd(1, 5) == 1) and "bomb" or "jimbo"
                h.ttl = 1.15 - 0.4 * progress
            end
        end
    end,
    draw = function(s)
        for i = 1, 9 do
            local x, y = hole_pos(i)
            local h = s.holes[i]
            set_colour(0.08, 0.06, 0.08); love.graphics.ellipse("fill", x, y + 24, 46, 18)
            if h.who == "jimbo" then
                jimbo(x, y, 28)
            elseif h.who == "bomb" then
                set_colour(0.22, 0.22, 0.26); circle(x, y, 28)
                set_colour(0.6, 0.45, 0.3); rect(x - 4, y - 38, 8, 12, 2)
                set_colour(1, 0.7, 0.2); circle(x, y - 40, 5)
            end
            if h.hit then
                set_colour(1, 1, 1)
                text(h.who == "jimbo" and "+1" or "-3", x, y - 14, 28)
            end
            set_colour(0.6, 0.6, 0.65)
            for key, hole in pairs(NUMPAD) do
                if hole == i then text(key, x + 50, y + 16, 12) end
            end
        end
        set_colour(0.75, 0.75, 0.8)
        text("Time " .. math.ceil(s.time), W / 2, HUD + 4, 14)
    end,
}

local GAMES = { snake, breaker, flappy, whacker }
local BY_ID = {}
for _, g in ipairs(GAMES) do BY_ID[g.id] = g end

----------------------------------------------------------------
-- PLAYS, MEDALS AND REWARDS
----------------------------------------------------------------
local function S()
    local g = G.GAME
    local s = g.ocafe_arcade
    if not s then
        s = { round = g.round or 0, used = 0, best = {} }
        g.ocafe_arcade = s
    end
    -- a new round means a new shop: the plays come back
    if s.round ~= (g.round or 0) then s.round, s.used = g.round or 0, 0 end
    return s
end

local function next_cost()
    return S().used < FREE_PLAYS and 0 or PLAY_COST
end

local function plays_left()
    return math.max(0, MAX_PLAYS - S().used)
end

local function can_afford(cost)
    return cost == 0 or (G.GAME.dollars or 0) - cost >= (G.GAME.bankrupt_at or 0)
end

local function medal_for(game, score)
    local medal = 0
    for i, goal in ipairs(game.goals) do
        if score >= goal then medal = i end
    end
    return medal
end

local function save()
    if type(save_run) == "function" then pcall(save_run) end
end

local function pay(medal)
    if medal == 0 then return "No medal this time" end
    local cash, card_text = CASH[medal], nil
    if medal == 3 then
        local set = GOLD_CARDS[rnd(1, #GOLD_CARDS)]
        local room = G.consumeables
            and (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0)) < G.consumeables.config.card_limit
        if room and pcall(SMODS.add_card, { set = set, key_append = "ocafe_arcade" }) then
            card_text = " + a " .. set .. " card"
        else
            cash = cash + NO_ROOM_CASH
        end
    end
    ease_dollars(cash, true)
    return "+$" .. cash .. (card_text or "")
end

----------------------------------------------------------------
-- A RUN
----------------------------------------------------------------
local session            -- the run on screen right now (nil = none)
local held_keys, held_buttons = {}, {}   -- presses we swallowed, so their releases are swallowed too

local function sfx(name, pitch, vol)
    if play_sound then pcall(play_sound, name, pitch, vol) end
end

local function finish()
    local s = session
    if not s or s.phase == "done" then return end
    s.phase, s.wait = "done", 0.7
    local game, score = s.game, s.state.score
    local medal = medal_for(game, score)
    local store = S()
    s.new_best = score > (store.best[game.id] or 0)
    if s.new_best then store.best[game.id] = score end
    s.medal = medal
    s.reward = pay(medal)
    sfx(medal > 0 and "coin3" or "cancel", 1, 0.7)
    save()
end

local function start_run(id)
    local game = BY_ID[id]
    if session or not game or plays_left() <= 0 then return false end
    local cost = next_cost()
    if not can_afford(cost) then return false end
    local store = S()
    store.used = store.used + 1
    if cost > 0 then ease_dollars(-cost, true) end
    save()
    session = { game = game, state = game.new(), phase = "ready", menu = G.OVERLAY_MENU, mouse = nil }
    sfx("coin1", 1, 0.6)
    return true
end

local open_menu

local function leave_results()
    if not session or session.phase ~= "done" or session.wait > 0 then return end
    session = nil
    open_menu()
end

-- one normalised press ("up", "action", "quit", a digit...)
local function on_press(key)
    local s = session
    if not s then return end
    if s.phase == "done" then
        if key == "action" or key == "quit" then leave_results() end
    elseif key == "quit" then
        finish()
    elseif s.phase == "ready" then
        s.phase = "play"
        s.game.press(s.state, key)
    else
        s.game.press(s.state, key)
    end
end

local function on_click(x, y)
    local s = session
    if not s then return end
    if s.phase == "done" then
        leave_results()
        return
    end
    -- the END button in the top right corner
    if x >= W - 56 and y >= 0 and y <= HUD then
        finish()
        return
    end
    if s.phase == "ready" then s.phase = "play" end
    s.game.click(s.state, x, y)
end

local function to_virtual(x, y)
    return (x - view.x) / view.s, (y - view.y) / view.s
end

local function layout()
    local w, h = love.graphics.getDimensions()
    view.s = math.min(w * 0.92 / W, h * 0.92 / H)
    view.x, view.y = (w - W * view.s) / 2, (h - H * view.s) / 2
end

local function key_down(...)
    return love.keyboard and love.keyboard.isDown(...) or false
end

local function pad_down(button)
    if not (love.joystick and love.joystick.getJoysticks) then return false end
    for _, j in ipairs(love.joystick.getJoysticks()) do
        if j:isGamepad() and j:isGamepadDown(button) then return true end
    end
    return false
end

local function tick(dt)
    local s = session
    if not s then return end
    -- the run or the menu disappeared underneath us
    if G.STAGE ~= G.STAGES.RUN or not G.GAME then
        session = nil
        return
    end
    if G.OVERLAY_MENU ~= s.menu then
        finish()
        session = nil
        return
    end
    dt = math.min(dt, 0.05)
    if s.phase == "done" then
        s.wait = math.max(0, s.wait - dt)
        return
    end
    if s.phase ~= "play" then return end

    layout()
    local mx, my, moved = 0, 0, false
    if love.mouse then
        local rx, ry = love.mouse.getPosition()
        mx, my = to_virtual(rx, ry)
        -- the mouse only takes the paddle over when it actually moves, so the keys work too
        moved = s.mouse ~= nil and (s.mouse[1] ~= rx or s.mouse[2] ~= ry)
        s.mouse = { rx, ry }
    end
    s.game.update(s.state, dt, {
        left = key_down("left", "a") or pad_down("dpleft"),
        right = key_down("right", "d") or pad_down("dpright"),
        mx = mx, my = my, mouse_moved = moved,
    })
    if s.state.over then finish() end
end

local function draw()
    local s = session
    if not s then return end
    layout()
    local sw, sh = love.graphics.getDimensions()
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setCanvas()
    love.graphics.setShader()
    love.graphics.setScissor()
    love.graphics.setBlendMode("alpha")

    set_colour(0, 0, 0, 0.82); rect(0, 0, sw, sh)
    love.graphics.translate(view.x, view.y)
    love.graphics.scale(view.s)

    set_colour(0.95, 0.55, 0.15); rect(-8, -8, W + 16, H + 16, 12)
    set_colour(0.11, 0.12, 0.17); rect(0, 0, W, H)
    love.graphics.setScissor(view.x, view.y, W * view.s, H * view.s)
    s.game.draw(s.state)

    set_colour(0.2, 0.21, 0.28); rect(0, 0, W, HUD)
    local medal = medal_for(s.game, s.state.score)
    local goal = s.game.goals[medal + 1]
    set_colour(1, 1, 1)
    text(s.game.name, 90, 11, 16)
    text("Score " .. s.state.score, 220, 11, 16)
    set_colour(1, 0.82, 0.3)
    text(goal and (MEDALS[medal + 1] .. " at " .. goal) or "GOLD!", 348, 11, 16)
    if s.phase ~= "done" then
        set_colour(0.8, 0.28, 0.28); rect(W - 52, 7, 44, 26, 5)
        set_colour(1, 1, 1); text("END", W - 30, 12, 13)
    end

    if s.phase == "ready" then
        set_colour(0, 0, 0, 0.75); rect(30, 130, W - 60, 150, 10)
        set_colour(1, 1, 1)
        text(s.game.help, W / 2, 148, 17)
        text(s.game.controls, W / 2, 180, 14)
        set_colour(1, 0.82, 0.3)
        text("Click or press Space to start", W / 2, 218, 18)
        set_colour(0.7, 0.7, 0.75)
        text("Esc ends the run and pays the medal you reached", W / 2, 252, 12)
    elseif s.phase == "done" then
        set_colour(0, 0, 0, 0.85); rect(60, 110, W - 120, 190, 10)
        set_colour(1, 1, 1)
        text(s.medal > 0 and (MEDALS[s.medal] .. " medal!") or "Game over", W / 2, 130, 28)
        text(s.state.score .. " " .. s.game.unit .. (s.new_best and "  -  new best!" or ""), W / 2, 178, 16)
        set_colour(1, 0.82, 0.3)
        text(s.reward, W / 2, 210, 22)
        set_colour(0.7, 0.7, 0.75)
        text(s.wait > 0 and "..." or "Click or press Space to go back", W / 2, 262, 14)
    end
    love.graphics.pop()
end

----------------------------------------------------------------
-- MENU
----------------------------------------------------------------
local function line(str, scale, colour, align, maxw)
    return { n = G.UIT.R, config = { align = align or "cm" }, nodes = {
        { n = G.UIT.T, config = { text = str, scale = scale, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true, maxw = maxw } }
    } }
end

local function game_row(game, enabled, cost)
    local g = game.goals
    return { n = G.UIT.R, config = { align = "cm", padding = 0.07, r = 0.1, colour = G.C.L_BLACK, emboss = 0.05 }, nodes = {
        { n = G.UIT.C, config = { align = "cl", padding = 0.04, minw = 6.6 }, nodes = {
            line(game.name, 0.42, G.C.WHITE, "cl", 6.4),
            line(game.help, 0.27, G.C.UI.TEXT_INACTIVE, "cl", 6.4),
            line("Bronze " .. g[1] .. "  |  Silver " .. g[2] .. "  |  Gold " .. g[3] .. " " .. game.unit
                .. "     Best: " .. (S().best[game.id] or 0), 0.26, G.C.GOLD, "cl", 6.4),
        } },
        { n = G.UIT.C, config = { align = "cm", padding = 0.05, minw = 2.3 }, nodes = {
            { n = G.UIT.R, config = {
                align = "cm", padding = 0.08, minw = 2.1, minh = 0.75, r = 0.1, hover = enabled, shadow = true,
                colour = enabled and G.C.BLUE or G.C.UI.BACKGROUND_INACTIVE,
                button = enabled and "ocafe_arcade_play" or nil, ref_table = { id = game.id }
            }, nodes = {
                { n = G.UIT.T, config = {
                    text = (plays_left() <= 0) and "NO PLAYS" or (cost == 0 and "PLAY (free)" or ("PLAY $" .. cost)),
                    scale = 0.36, maxw = 1.9, colour = G.C.UI.TEXT_LIGHT, shadow = true
                } }
            } }
        } },
    } }
end

open_menu = function()
    local ok, err = pcall(function()
        local cost, left = next_cost(), plays_left()
        local enabled = left > 0 and can_afford(cost)
        local rows = {
            line("ARCADE GAMES", 0.55, G.C.WHITE),
            line("Plays left this shop: " .. left .. " / " .. MAX_PLAYS, 0.32, G.C.GOLD),
            line("Rewards: Bronze $" .. CASH[1] .. "  |  Silver $" .. CASH[2] .. "  |  Gold $" .. CASH[3]
                .. " + a Tarot or Planet card", 0.28, G.C.UI.TEXT_INACTIVE, "cm", 9),
        }
        for _, game in ipairs(GAMES) do rows[#rows + 1] = game_row(game, enabled, cost) end
        G.FUNCS.overlay_menu {
            definition = create_UIBox_generic_options { back_func = "exit_overlay_menu", contents = rows }
        }
    end)
    if not ok and sendDebugMessage then sendDebugMessage("arcade.lua menu: " .. tostring(err), "OreoCafe") end
end

G.FUNCS.ocafe_open_arcade = function(e) open_menu() end

G.FUNCS.ocafe_arcade_play = function(e)
    start_run(e.config.ref_table.id)
end

----------------------------------------------------------------
-- HOOKS: update, draw and input
----------------------------------------------------------------
local update_ref = Game.update
function Game:update(dt, ...)
    local ret = update_ref(self, dt, ...)
    if session then
        local ok, err = pcall(tick, dt)
        if not ok then
            session = nil -- never leave the player stuck behind a broken game
            if sendDebugMessage then sendDebugMessage("arcade.lua tick: " .. tostring(err), "OreoCafe") end
        end
    end
    return ret
end

local draw_ref = love.draw
function love.draw(...)
    if draw_ref then draw_ref(...) end
    if session then
        local ok, err = pcall(draw)
        if not ok then
            pcall(love.graphics.pop)
            session = nil
            if sendDebugMessage then sendDebugMessage("arcade.lua draw: " .. tostring(err), "OreoCafe") end
        end
    end
end

local KEYS = {
    up = "up", w = "up", down = "down", s = "down", left = "left", a = "left", right = "right", d = "right",
    space = "action", ["return"] = "action", kpenter = "action", escape = "quit",
}
for i = 1, 9 do
    KEYS[tostring(i)] = tostring(i)
    KEYS["kp" .. i] = tostring(i)
end

local PAD = {
    dpup = "up", dpdown = "down", dpleft = "left", dpright = "right", a = "action", b = "quit", start = "quit",
}

-- wrap a pair of love callbacks: while a run is on, presses are ours and the game never sees them
local function capture(press_name, release_name, held, id_of, handle)
    local press_ref, release_ref = love[press_name], love[release_name]
    love[press_name] = function(...)
        if session then
            held[id_of(...)] = true
            local ok, err = pcall(handle, ...)
            if not ok then
                session = nil
                if sendDebugMessage then sendDebugMessage("arcade.lua input: " .. tostring(err), "OreoCafe") end
            end
            return
        end
        if press_ref then return press_ref(...) end
    end
    love[release_name] = function(...)
        local id = id_of(...)
        if held[id] then
            held[id] = nil
            return
        end
        if release_ref then return release_ref(...) end
    end
end

capture("keypressed", "keyreleased", held_keys,
    function(key) return key end,
    function(key) if KEYS[key] then on_press(KEYS[key]) end end)

capture("mousepressed", "mousereleased", held_buttons,
    function(_, _, button) return button end,
    function(x, y, button)
        if button == 1 then
            layout()
            on_click(to_virtual(x, y))
        end
    end)

local held_pad = {}
capture("gamepadpressed", "gamepadreleased", held_pad,
    function(_, button) return button end,
    function(_, button) if PAD[button] then on_press(PAD[button]) end end)

----------------------------------------------------------------
-- SHOP TAB
----------------------------------------------------------------
local TAB_W = 2.4

local function arcade_tab()
    return { n = G.UIT.R, config = {
        align = "cm", padding = 0.06, minw = TAB_W, minh = 0.5, r = 0.12, colour = G.C.GREEN,
        hover = true, shadow = true, emboss = 0.05, button = "ocafe_open_arcade"
    }, nodes = {
        { n = G.UIT.T, config = { text = "Arcade Games", scale = 0.36, maxw = TAB_W - 0.2, colour = G.C.WHITE, shadow = true } }
    } }
end

-- the node holding a child that matches, plus the chain of parents above it
local function find_node(node, pred, parents)
    if pred(node) then return node, parents end
    for _, child in ipairs(node.nodes or {}) do
        parents[#parents + 1] = node
        local found = find_node(child, pred, parents)
        if found then return found, parents end
        parents[#parents] = nil
    end
end

local function index_of(list, v)
    for i, x in ipairs(list) do
        if x == v then return i end
    end
end

local fallback_lift = false

local function add_arcade_tab(t)
    fallback_lift = false
    local column = { n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = { arcade_tab() } }
    -- join the row of tabs: after Oreo RPG (which sits in its own column), otherwise after ORDERS
    for _, button in ipairs { "ocafe_open_rpg", "ocafe_open_orders" } do
        local tab, parents = find_node(t, function(n) return n.config and n.config.button == button end, {})
        if tab then
            local child = tab
            for i = #parents, 1, -1 do
                local parent = parents[i]
                local first = parent.nodes[1]
                -- the tab row is the first row whose children are columns
                if parent.n == G.UIT.R and first and first.n == G.UIT.C then
                    table.insert(parent.nodes, index_of(parent.nodes, child) + 1, column)
                    return
                end
                child = parent
            end
            -- a lone tab in a plain row: split that row into columns
            local parent = parents[#parents]
            if parent and parent.n == G.UIT.R then
                local i = index_of(parent.nodes, tab)
                parent.nodes[i] = { n = G.UIT.C, config = { align = "cm" }, nodes = { tab } }
                table.insert(parent.nodes, i + 1, column)
                return
            end
        end
    end
    -- no other tabs: our own row at the top of the shop box
    local box = t.nodes and t.nodes[1]
    if box and box.n == G.UIT.C and box.nodes then
        table.insert(box.nodes, 1, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = { arcade_tab() } })
        fallback_lift = true
    end
end

-- only used by the fallback above: the extra row pushes the shop box down, so lift it back up
local VANILLA_SHOP_Y, FALLBACK_LIFT = -5.3, 0.6
local lift_update_ref = Game.update
function Game:update(dt, ...)
    local ret = lift_update_ref(self, dt, ...)
    if fallback_lift then
        local off = G and G.shop and G.shop.alignment and G.shop.alignment.offset
        if off and type(off.y) == "number" and math.abs(off.y - VANILLA_SHOP_Y) < 0.001 then
            off.y = VANILLA_SHOP_Y - FALLBACK_LIFT
        end
    end
    return ret
end

local installed = false

local function install_hooks()
    if installed or not (G and G.UIDEF and G.UIDEF.shop) then return end
    local shop_ref = G.UIDEF.shop
    G.UIDEF.shop = function(...)
        local t = shop_ref(...)
        local ok, err = pcall(add_arcade_tab, t)
        if not ok and sendDebugMessage then sendDebugMessage("arcade.lua tab: " .. tostring(err), "OreoCafe") end
        return t
    end
    installed = true
end

install_hooks()
local start_run_ref = Game.start_run
function Game:start_run(args)
    session = nil
    local ret = start_run_ref(self, args)
    install_hooks() -- after the other tabs have installed theirs, so ours is added last
    return ret
end

-- for testing
Arcade.games = BY_ID
Arcade.session = function() return session end
Arcade.add_tab = add_arcade_tab
return Arcade
