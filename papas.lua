-- Papa's Counter: customer orders minigame for Oreo Cafe Balatro (loaded from main.lua)
--
-- FLOW
--   Shop:    a new ORDERS tab (at the top of the shop box) opens the Order Counter. Three customers
--            (Jimbo in different outfits) each ask for ONE item from Papa's Pizzeria, Scooperia,
--            Donuteria, Cupcakeria or Freezeria. Take up to MAX_TAKEN orders. They are made in the
--            NEXT round (the one whose Blind you pick after leaving the shop).
--   Round:   the clocks start when the Blind starts. A KITCHEN button shows up next to the Sort
--            buttons (only while selecting a hand). Follow the ticket: pick the right ingredients,
--            time the oven / fryer / blender, then hit SERVE.
--   Reward:  serve before the clock runs out to get the reward. Serve with at least half the time
--            left for a RUSH (double reward). Running out of time never hurts you, you only miss out.
--   Round tie-ins:
--     * the clock only runs during the round, and the oven keeps cooking while you play cards
--       (go play a hand and the cupcakes can burn!)
--     * every hand you play makes the customers wait HAND_PATIENCE seconds longer
--     * Boss Blinds are grumpier (less time), Small Blinds are relaxed (more time), and the time
--       gets tighter every Ante
--     * rewards act on the round itself: +Hands, +Discards, chips toward the Blind, cash, Tarots
--   Vouchers (defined at the bottom of this file, art = vouchers.png):
--     v_ocafe_kitchen_timer  Kitchen Timer  - a bell rings when the oven / fryer / blender food is ready
--     v_ocafe_sous_chef      Sous Chef      - (needs Kitchen Timer) stations finish themselves, perfectly, no redo
--     v_ocafe_order_pad      Order Pad      - take up to 5 orders at once (5 customers per shop)
--     v_ocafe_dinner_rush    Dinner Rush    - (needs Order Pad) less time on every order, bigger rewards
--   State lives on G.GAME (saved with the run):
--     ocafe_customers  customers on offer in the current shop
--     ocafe_tickets    accepted orders being made this round
--     ocafe_live       the round is running and the clocks are ticking
--     ocafe_boss       The Rush boss is running: { goal, done, limit, left, seen, result }
--     ocafe_quota      { ante, served } orders served this Ante (Papa's Deck)
--   BOSS BLIND "The Rush" (bl_ocafe_rush, at the bottom of this file, art = blinds.png row y=0):
--     The Blind brings BOSS_ORDERS orders at once. There is ONE clock for the whole Blind (the orders
--     have no clock of their own), no order gives a reward, and serving the last one beats the Blind.
--     The score requirement never ends the round, it only sets how much time a hand buys:
--     every hand adds BOSS_SCORE_TIME seconds per 100% of the requirement it scores.
--     Clock at zero = the run is over.
--   PAPA'S DECK (b_ocafe_papas_deck, art = decks.png x=2): starts with the four vouchers above and every
--     Ante has an order quota. Orders served in the Boss Blind don't count. If the quota is not met when
--     the Boss Blind is beaten, the run ends.
--   Art (optional): assets/1x/customers.png and assets/2x/customers.png, one 71x95 cell per outfit in
--   the OUTFITS list below (x = 0 is Cowboy Jimbo...). Without it the vanilla Jimbo sprite is used.

----------------------------------------------------------------
-- TUNING KNOBS
----------------------------------------------------------------
local CUSTOMERS_PER_SHOP = 3     -- customers offered each shop (each one orders a different game)
local MAX_TAKEN = 3              -- orders you can take at once
local RUSH_FRACTION = 0.5        -- served with this share of the time left = RUSH (reward doubled)
local MISTAKE_COST = 3           -- seconds lost for a wrong ingredient
local RUIN_COST = 5              -- seconds lost for a raw / burnt batch (the step restarts)
local HAND_PATIENCE = 4          -- seconds each hand played adds to every open order
local BASE_TIME, PICK_TIME, STATION_TIME = 12, 6, 6   -- time budget: base + per ingredient + per station
local ANTE_SQUEEZE, MIN_TIME_FACTOR = 0.05, 0.6       -- budget x (1 - 0.05 per Ante above 1), never below x0.6
local SMALL_BLIND_TIME, BOSS_BLIND_TIME = 1.1, 0.85   -- budget multipliers by Blind
local PERFECT_LO, PERFECT_HI = 0.75, 1.0   -- station progress: perfect window
local OK_LO, OK_HI = 0.55, 1.15            -- station progress: "good enough" window
local MAXP = 1.35                          -- past this the batch burns by itself
local BAR_CELLS = 26

local WAIT_SCALE = 1.8     -- the oven / fryer / blender take this many times longer than they used to
local READY_P = PERFECT_LO -- Kitchen Timer rings when the food reaches this progress (perfect window opens)
local AUTO_P = 1.0         -- Sous Chef finishes the food by itself at this progress (exactly done = perfect)

-- vouchers
local ORDER_PAD_CUSTOMERS = 5    -- Order Pad: customers offered per shop ...
local ORDER_PAD_TAKEN = 5        -- ... and orders you can take at once
local DINNER_RUSH_TIME = 0.7     -- Dinner Rush: every order's time budget x 0.7
local DINNER_RUSH_REWARD = 1.5   -- Dinner Rush: every reward x 1.5
local V_TIMER, V_AUTO = "v_ocafe_kitchen_timer", "v_ocafe_sous_chef"
local V_PAD, V_RUSH = "v_ocafe_order_pad", "v_ocafe_dinner_rush"

-- boss blind (The Rush)
local BOSS_KEY = "bl_ocafe_rush"
local BOSS_ORDERS = 10           -- orders to serve to beat the Blind
local BOSS_BASE_TIME = 240       -- seconds on the one shared clock (tightened by the Ante, see ANTE_SQUEEZE)
local BOSS_SCORE_TIME = 30       -- seconds a hand adds per 100% of the Blind's requirement it scores

-- Papa's Deck
local QUOTA_DECK_KEY = "b_ocafe_papas_deck"
local QUOTA_GROWTH, QUOTA_MAX = 1.5, 12  -- quota = ceil(1.5 x Ante), at most 12 (Ante 1: 2, 4: 6, 6: 9, 8+: 12)
-- an Ante whose Boss is The Rush has no shop for the Boss round: only the Small and Big shops give
-- orders, so the quota there never asks for more than two shops can offer
local RUSH_ANTE_MAX = 2 * ORDER_PAD_TAKEN

-- reward kinds: weight = how often a customer offers it, base = amount (RUSH doubles it)
local REWARDS = {
    { kind = "cash",    weight = 4,   base = function(ante) return 3 + ante end },
    { kind = "chips",   weight = 3,   base = function() return 10 end },   -- % of the Blind's requirement
    { kind = "hand",    weight = 1.5, base = function() return 1 end },
    { kind = "discard", weight = 2,   base = function() return 2 end },
    { kind = "tarot",   weight = 2,   base = function() return 1 end },
}

----------------------------------------------------------------
-- CUSTOMER OUTFITS (Jimbo in disguise)
----------------------------------------------------------------
local OUTFITS = {
    { name = "Cowboy Jimbo",     colour = HEX("8B5A2B"), greet = "Howdy, partner! I'll have the..." },
    { name = "Pirate Jimbo",     colour = HEX("2F4F6F"), greet = "Yarr! Fetch me the..." },
    { name = "Wizard Jimbo",     colour = HEX("5B3E96"), greet = "Behold! Conjure me a..." },
    { name = "Astronaut Jimbo",  colour = HEX("8FA3BF"), greet = "Houston, we need a..." },
    { name = "Detective Jimbo",  colour = HEX("5A5A4E"), greet = "I'm on a case. Bring me a..." },
    { name = "Knight Jimbo",     colour = HEX("7C828C"), greet = "Good cook! For the realm, a..." },
    { name = "Rockstar Jimbo",   colour = HEX("B0245A"), greet = "Backstage needs a..." },
    { name = "Chef Jimbo",       colour = HEX("A89F86"), greet = "Let's see if you can cook. One..." },
    { name = "Lumberjack Jimbo", colour = HEX("A33B2B"), greet = "Long day of chopping. Gimme a..." },
    { name = "Ninja Jimbo",      colour = HEX("303030"), greet = "...You never saw me order a..." },
    { name = "Sailor Jimbo",     colour = HEX("2E6DA4"), greet = "Ahoy! Before the tide turns, a..." },
    { name = "Mime Jimbo",       colour = HEX("6A6A6A"), greet = "(gestures wildly at a...)" },
}

-- Optional portrait sheet: only registered if both art files exist
do
    local path = SMODS.current_mod and SMODS.current_mod.path
    if path and NFS and NFS.getInfo(path .. "assets/1x/customers.png") and NFS.getInfo(path .. "assets/2x/customers.png") then
        SMODS.Atlas { key = "customers", path = "customers.png", px = 71, py = 95 }
    end
end

----------------------------------------------------------------
-- THE FIVE GAMES
-- A recipe is a list of steps. "pick" steps need exactly the wanted ingredients (count = min/max the
-- customer asks for); "timed" steps run a station (dur = seconds until it is exactly done).
----------------------------------------------------------------
local function opts(names)
    local list = {}
    for i, n in ipairs(names) do
        list[i] = { id = (n:lower():gsub("[^%w]+", "_")), name = n }
    end
    return list
end

local function list_join(list)
    if #list <= 1 then return list[1] or "" end
    return table.concat(list, ", ", 1, #list - 1) .. " & " .. list[#list]
end

local GAMES = {
    pizzeria = {
        name = "Papa's Pizzeria", short = "Pizzeria",
        steps = {
            { id = "sauce",    label = "Sauce",    kind = "pick",  count = { 1, 1 }, options = opts { "Tomato", "Alfredo", "BBQ" } },
            { id = "cheese",   label = "Cheese",   kind = "pick",  count = { 1, 1 }, options = opts { "Mozzarella", "Cheddar", "Provolone" } },
            { id = "toppings", label = "Toppings", kind = "pick",  count = { 2, 3 }, options = opts {
                "Pepperoni", "Sausage", "Mushrooms", "Green Peppers", "Onions", "Black Olives", "Bacon", "Anchovies" } },
            { id = "bake",     label = "Oven",     kind = "timed", dur = 4.5 * WAIT_SCALE, verb = "BAKE", done = "baked" },
            { id = "cut",      label = "Cut",      kind = "pick",  count = { 1, 1 }, options = opts { "4 Slices", "6 Slices", "8 Slices" } },
        },
        title = function(n) return list_join(n("toppings")) .. " Pizza" end,
    },
    scooperia = {
        name = "Papa's Scooperia", short = "Scooperia",
        steps = {
            { id = "cone",     label = "Cone",     kind = "pick", count = { 1, 1 }, options = opts { "Waffle Cone", "Sugar Cone", "Cup", "Waffle Bowl" } },
            { id = "scoops",   label = "Scoops",   kind = "pick", count = { 2, 3 }, options = opts {
                "Vanilla", "Chocolate", "Strawberry", "Mint Chip", "Cookie Dough", "Rocky Road" } },
            { id = "syrup",    label = "Syrup",    kind = "pick", count = { 1, 1 }, options = opts {
                "Chocolate Syrup", "Caramel", "Strawberry Syrup", "Hot Fudge" } },
            { id = "toppings", label = "Toppings", kind = "pick", count = { 1, 2 }, options = opts {
                "Whipped Cream", "Rainbow Sprinkles", "Cherry", "Crushed Nuts", "Chocolate Chips" } },
        },
        title = function(n) return list_join(n("scoops")) .. " in a " .. (n("cone")[1] or "Cone") end,
    },
    donuteria = {
        name = "Papa's Donuteria", short = "Donuteria",
        steps = {
            { id = "dough",    label = "Dough",    kind = "pick",  count = { 1, 1 }, options = opts { "Ring Donut", "Long John", "Round Donut" } },
            { id = "fry",      label = "Fryer",    kind = "timed", dur = 4 * WAIT_SCALE, verb = "FRY", done = "fried" },
            { id = "icing",    label = "Icing",    kind = "pick",  count = { 1, 1 }, options = opts {
                "Chocolate", "Vanilla", "Strawberry", "Maple", "Blueberry" } },
            { id = "toppings", label = "Toppings", kind = "pick",  count = { 1, 2 }, options = opts {
                "Rainbow Sprinkles", "Chopped Peanuts", "Coconut", "Chocolate Drizzle", "Powdered Sugar" } },
        },
        title = function(n)
            return (n("icing")[1] or "") .. " " .. (n("dough")[1] or "Donut") .. " w/ " .. list_join(n("toppings"))
        end,
    },
    cupcakeria = {
        name = "Papa's Cupcakeria", short = "Cupcakeria",
        steps = {
            { id = "liner",    label = "Liner",    kind = "pick",  count = { 1, 1 }, options = opts { "Red Liner", "Blue Liner", "Pink Liner", "Gold Liner" } },
            { id = "cake",     label = "Cake",     kind = "pick",  count = { 1, 1 }, options = opts {
                "Vanilla", "Chocolate", "Strawberry", "Red Velvet", "Carrot" } },
            { id = "bake",     label = "Oven",     kind = "timed", dur = 4.2 * WAIT_SCALE, verb = "BAKE", done = "baked" },
            { id = "frosting", label = "Frosting", kind = "pick",  count = { 1, 1 }, options = opts {
                "Vanilla", "Chocolate", "Strawberry", "Cream Cheese", "Mint" } },
            { id = "toppings", label = "Toppings", kind = "pick",  count = { 1, 2 }, options = opts {
                "Sprinkles", "Cherry", "Chocolate Chips", "Marshmallows", "Crushed Cookie" } },
        },
        title = function(n)
            return (n("cake")[1] or "") .. " Cupcake, " .. (n("frosting")[1] or "") .. " Frosting"
        end,
    },
    freezeria = {
        name = "Papa's Freezeria", short = "Freezeria",
        steps = {
            { id = "cup",      label = "Cup",      kind = "pick",  count = { 1, 1 }, options = opts { "Small", "Medium", "Large" } },
            { id = "base",     label = "Base",     kind = "pick",  count = { 1, 1 }, options = opts { "Vanilla", "Chocolate", "Strawberry" } },
            { id = "mixins",   label = "Mix-ins",  kind = "pick",  count = { 1, 2 }, options = opts {
                "Cookie Dough", "Chocolate Chips", "Gummy Bears", "Peanut Butter Cups", "Brownie Bits", "Marshmallows" } },
            { id = "blend",    label = "Blender",  kind = "timed", dur = 3.5 * WAIT_SCALE, verb = "BLEND", done = "blended" },
            { id = "syrup",    label = "Syrup",    kind = "pick",  count = { 1, 1 }, options = opts {
                "Chocolate Syrup", "Caramel", "Strawberry Syrup" } },
            { id = "toppings", label = "Toppings", kind = "pick",  count = { 1, 2 }, options = opts {
                "Whipped Cream", "Cherry", "Rainbow Sprinkles", "Banana Slices" } },
        },
        title = function(n)
            return (n("cup")[1] or "") .. " " .. list_join(n("mixins")) .. " Shake"
        end,
    },
}
local GAME_ORDER = { "pizzeria", "scooperia", "donuteria", "cupcakeria", "freezeria" }

----------------------------------------------------------------
-- SMALL HELPERS
----------------------------------------------------------------
local K = {
    sel = 1,        -- ticket shown in the kitchen
    menu = nil,     -- the overlay that is the kitchen (so we can tell when it is open)
    ui = { kitchen_label = "", kitchen_sub = "", bar = "", zone = "", orders_label = "", boss_line = "" },
}

local function kitchen_open()
    return K.menu ~= nil and G.OVERLAY_MENU == K.menu
end

local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok and not K.err_logged then
        K.err_logged = true
        if sendDebugMessage then sendDebugMessage("papas.lua: " .. tostring(err), "OreoCafe") end
    end
    return ok
end

local function contains(list, v)
    for _, x in ipairs(list) do
        if x == v then return true end
    end
    return false
end

local function fmt_time(sec)
    sec = math.max(0, math.ceil(sec))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- own shuffle: the game's pseudoshuffle indexes list[1].sort_id, which breaks on plain numbers
local function shuffle(list, seed)
    for i = #list, 2, -1 do
        local j = pseudorandom(seed .. "_" .. i, 1, i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

local function plural(n, one, many)
    return n == 1 and one or many
end

local function has_voucher(key)
    return (G.GAME and G.GAME.used_vouchers and G.GAME.used_vouchers[key]) and true or false
end

-- how many customers a shop offers / how many orders you may take at once
local function customer_limit()
    return has_voucher(V_PAD) and ORDER_PAD_CUSTOMERS or CUSTOMERS_PER_SHOP
end

local function taken_limit()
    return has_voucher(V_PAD) and ORDER_PAD_TAKEN or MAX_TAKEN
end

-- Dinner Rush: read live (not baked into the customer), so it also applies to offers made before it was bought
local function time_mult()
    return has_voucher(V_RUSH) and DINNER_RUSH_TIME or 1
end

local function reward_n(r)
    if not has_voucher(V_RUSH) then return r.n end
    return math.max(r.n, math.floor(r.n * DINNER_RUSH_REWARD + 0.5))
end

local function tickets()
    return (G.GAME and G.GAME.ocafe_tickets) or {}
end

local function any_open()
    for _, t in ipairs(tickets()) do
        if t.status == "open" then return true end
    end
    return false
end

-- Papa's Deck: is it the deck in use?
local function quota_active()
    local back = G.GAME and G.GAME.selected_back
    local center = back and back.effect and back.effect.center
    return center ~= nil and center.key == QUOTA_DECK_KEY
end

local function current_ante()
    return (G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante) or 1
end

local function order_quota(ante)
    return math.min(QUOTA_MAX, math.ceil(QUOTA_GROWTH * ante))
end

-- orders served this Ante, and the quota for it
local function quota_info()
    local ante = current_ante()
    local need = order_quota(ante)
    local rr = G.GAME and G.GAME.round_resets
    if rr and rr.blind_choices and rr.blind_choices.Boss == BOSS_KEY then
        need = math.min(need, RUSH_ANTE_MAX)
    end
    local q = G.GAME and G.GAME.ocafe_quota
    if not q or q.ante ~= ante then return 0, need end
    return q.served, need
end

local function count_quota()
    local ante = current_ante()
    local q = G.GAME.ocafe_quota
    if not q or q.ante ~= ante then
        q = { ante = ante, served = 0 }
        G.GAME.ocafe_quota = q
    end
    q.served = q.served + 1
end

-- the next Blind to play is The Rush (it brings its own orders, so the shop takes none)
local function rush_next()
    local rr = G.GAME and G.GAME.round_resets
    return rr ~= nil and rr.blind_states ~= nil and rr.blind_states.Boss == "Select"
        and rr.blind_choices ~= nil and rr.blind_choices.Boss == BOSS_KEY
end

local function option_name(step, id)
    for _, o in ipairs(step.options or {}) do
        if o.id == id then return o.name end
    end
    return id
end

-- names of what was asked for in one step, by step id
local function names_for(game_key, order, step_id)
    local out = {}
    for i, step in ipairs(GAMES[game_key].steps) do
        if step.id == step_id then
            for _, oid in ipairs(order[i]) do out[#out + 1] = option_name(step, oid) end
        end
    end
    return out
end

local function reward_text(r, rush)
    local n = reward_n(r) * (rush and 2 or 1)
    if r.kind == "cash" then return "$" .. n end
    if r.kind == "chips" then return n .. "% of the Blind's score" end
    if r.kind == "hand" then return "+" .. n .. plural(n, " Hand", " Hands") end
    if r.kind == "discard" then return "+" .. n .. plural(n, " Discard", " Discards") end
    return n .. plural(n, " Tarot card", " Tarot cards")
end

local function consumable_room()
    return G.consumeables
        and (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0)) < G.consumeables.config.card_limit
end

----------------------------------------------------------------
-- CUSTOMERS AND ORDERS
----------------------------------------------------------------
local function make_customer(slot, game_key, outfit, ante)
    local game = GAMES[game_key]
    local cid = "c" .. (G.GAME.round or 0) .. "_" .. slot

    -- what the customer wants, per step (timed steps have nothing to pick)
    local order = {}
    for i, step in ipairs(game.steps) do
        if step.kind == "pick" then
            local n = step.count[1]
            if step.count[2] > n then
                n = pseudorandom("ocafe_papa_n" .. cid .. i, step.count[1], step.count[2])
            end
            local pool = {}
            for _, o in ipairs(step.options) do pool[#pool + 1] = o.id end
            shuffle(pool, "ocafe_papa_s" .. cid .. i)
            local want = {}
            for k = 1, n do want[k] = pool[k] end
            order[i] = want
        else
            order[i] = {}
        end
    end

    -- time budget (before the Blind's multiplier)
    local secs = BASE_TIME
    for i, step in ipairs(game.steps) do
        if step.kind == "pick" then
            secs = secs + PICK_TIME * #order[i]
        else
            secs = secs + step.dur + STATION_TIME
        end
    end
    secs = math.floor(secs * math.max(MIN_TIME_FACTOR, 1 - ANTE_SQUEEZE * (ante - 1)))

    -- reward
    local total = 0
    for _, r in ipairs(REWARDS) do total = total + r.weight end
    local roll = pseudorandom("ocafe_papa_reward" .. cid) * total
    local picked = REWARDS[1]
    for _, r in ipairs(REWARDS) do
        roll = roll - r.weight
        if roll <= 0 then picked = r break end
    end

    return {
        id = cid, outfit = outfit, game = game_key, order = order, budget = secs,
        title = game.title(function(step_id) return names_for(game_key, order, step_id) end),
        reward = { kind = picked.kind, n = picked.base(ante) },
        accepted = false,
    }
end

-- add customers (each with a game and an outfit nobody else has) until the list holds `limit`
local function add_customers(list, limit)
    local g = G.GAME
    local ante = (g.round_resets and g.round_resets.ante) or 1
    local used_games, used_outfits = {}, {}
    for _, c in ipairs(list) do
        used_games[c.game] = true
        used_outfits[c.outfit] = true
    end
    local games, outfits = {}, {}
    for _, k in ipairs(GAME_ORDER) do
        if not used_games[k] then games[#games + 1] = k end
    end
    for i = 1, #OUTFITS do
        if not used_outfits[i] then outfits[#outfits + 1] = i end
    end
    local tail = (#list > 0) and ("_" .. #list) or ""
    shuffle(games, "ocafe_papa_games" .. (g.round or 0) .. tail)
    shuffle(outfits, "ocafe_papa_outfits" .. (g.round or 0) .. tail)
    local i = 1
    while #list < limit and games[i] and outfits[i] do
        list[#list + 1] = make_customer(#list + 1, games[i], outfits[i], ante)
        i = i + 1
    end
end

local function ensure_offers()
    local g = G.GAME
    if not g or g.ocafe_customers then return end
    local list = {}
    add_customers(list, customer_limit())
    g.ocafe_customers = list
end

-- Order Pad bought while a shop is open: bring in the extra customers
local function top_up_offers()
    local g = G.GAME
    if g and g.ocafe_customers then add_customers(g.ocafe_customers, customer_limit()) end
end

local function count_taken()
    local n = 0
    for _, c in ipairs((G.GAME and G.GAME.ocafe_customers) or {}) do
        if c.accepted then n = n + 1 end
    end
    return n
end

-- The Rush: BOSS_ORDERS orders at once, no reward, no clock per order, ONE clock for the whole Blind
-- `challenge` ({ goal, secs }) turns this into a Map Deck Kitchen stop: fewer orders, and failing it
-- only drops the orders (the Blind is then played by score)
local function start_boss(challenge)
    local g = G.GAME
    local goal = challenge and challenge.goal or BOSS_ORDERS
    local title = challenge and "KITCHEN CHALLENGE" or "THE RUSH"
    local ante = current_ante()
    local round = g.round or 0

    local outfits = {}
    for i = 1, #OUTFITS do outfits[i] = i end
    shuffle(outfits, "ocafe_boss_outfits" .. round)

    local list = {}
    for i = 1, goal do
        local game_key = GAME_ORDER[pseudorandom("ocafe_boss_game" .. round .. "_" .. i, 1, #GAME_ORDER)]
        local c = make_customer(i, game_key, outfits[((i - 1) % #outfits) + 1], ante)
        c.reward, c.budget = nil, nil
        c.boss = true
        c.accepted = true
        c.status = "open"
        c.step = 1
        c.placed = {}
        c.stack = {}
        c.mistakes = 0
        c.msg = "Follow the ticket, then SERVE!"
        c.clock_text = "#" .. i
        list[#list + 1] = c
    end

    local base = challenge and challenge.secs or BOSS_BASE_TIME
    local secs = math.floor(base * math.max(MIN_TIME_FACTOR, 1 - ANTE_SQUEEZE * (ante - 1)))
    g.ocafe_boss = { goal = goal, done = 0, limit = secs, left = secs, seen = g.chips or 0,
        title = title, map = challenge and true or nil }
    g.ocafe_tickets = list
    g.ocafe_live = true
    K.sel = 1
    K.ui.boss_line = title .. "  -  0/" .. goal .. " served  -  " .. fmt_time(secs)

    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.8,
        func = function()
            safe(attention_text, {
                text = title .. "! " .. goal .. " ORDERS", scale = 0.8, hold = 1.6,
                align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
            })
            play_sound("coin1", 1, 0.6)
            return true
        end
    }))
end

-- the Blind was disabled (Chicot, Luchador): the orders vanish and the round plays by score again
local function drop_boss()
    local g = G.GAME
    if not (g and g.ocafe_boss) then return end
    g.ocafe_boss = nil
    g.ocafe_tickets = nil
    g.ocafe_live = nil
    if kitchen_open() and G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
end

OCAFE = OCAFE or {}
function OCAFE.kitchen_challenge(goal, secs)
    start_boss({ goal = goal, secs = secs })
end

-- a failed Map Deck challenge: the orders go away and the round carries on by score
local function fail_challenge()
    drop_boss()
    if OCAFE.kitchen_failed then OCAFE.kitchen_failed() end
    safe(attention_text, {
        text = "CHALLENGE FAILED - beat the score!", scale = 0.7, hold = 2,
        colour = G.C.RED, align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
    })
end

-- a Blind starts: the accepted orders become tickets and the clocks start
local function start_orders(blind)
    local g = G.GAME
    local offered = g.ocafe_customers
    g.ocafe_customers = nil
    g.ocafe_tickets = nil
    g.ocafe_live = nil
    g.ocafe_boss = nil
    if blind and blind.key == BOSS_KEY then
        start_boss()
        return
    end
    if not offered then return end

    local scale = 1
    if blind and blind.boss then
        scale = BOSS_BLIND_TIME
    elseif blind and blind.key == "bl_small" then
        scale = SMALL_BLIND_TIME
    end

    local list = {}
    for _, c in ipairs(offered) do
        if c.accepted then
            c.limit = math.max(10, math.floor(c.budget * scale * time_mult()))
            c.left = c.limit
            c.status = "open"       -- open | served | failed
            c.step = 1
            c.placed = {}
            c.stack = {}
            c.mistakes = 0
            c.msg = "Follow the ticket, then SERVE!"
            c.clock_text = fmt_time(c.left)
            list[#list + 1] = c
        end
    end
    if #list == 0 then return end

    g.ocafe_tickets = list
    g.ocafe_live = true
    K.sel = 1
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.8,
        func = function()
            safe(attention_text, {
                text = #list .. plural(#list, " ORDER UP!", " ORDERS UP!"), scale = 0.8, hold = 1.4,
                align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
            })
            play_sound("coin1", 1, 0.6)
            return true
        end
    }))
end

local function close_orders()
    local g = G.GAME
    if not (g and g.ocafe_tickets) then return end
    local served, total = 0, #g.ocafe_tickets
    for _, t in ipairs(g.ocafe_tickets) do
        if t.status == "served" then served = served + 1 end
    end
    local was_boss = g.ocafe_boss ~= nil
    g.ocafe_tickets = nil
    g.ocafe_live = nil
    g.ocafe_boss = nil
    if kitchen_open() and G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
    if total > 0 then
        local text = "Orders served: " .. served .. "/" .. total
        if quota_active() and not was_boss then
            local s, q = quota_info()
            text = text .. "   Quota: " .. s .. "/" .. q
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                safe(attention_text, {
                    text = text, scale = 0.7, hold = 1.6,
                    align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
                })
                return true
            end
        }))
    end
end

local function expire(t)
    t.status = "failed"
    t.station = nil
    t.clock_text = "LEFT"
    t.msg = "Out of time! The customer left."
    play_sound("cancel", 0.8, 0.6)
end

-- The Rush: the clock hit zero. Every open order fails; the run ends the next time the game is calm.
local function boss_fail()
    local b = G.GAME.ocafe_boss
    if not b or b.result then return end
    b.result = "lost"
    b.left = 0
    for _, t in ipairs(tickets()) do
        if t.status == "open" then
            t.status = "failed"
            t.station = nil
            t.clock_text = "LEFT"
            t.msg = "Time's up! The rush is over."
        end
    end
    play_sound("cancel", 0.8, 0.6)
end

-- lose seconds (a wrong ingredient, a burnt batch); returns true when the time is up
local function lose_time(t, secs)
    local b = G.GAME.ocafe_boss
    if t.boss and b then
        b.left = b.left - secs
        return b.left <= 0
    end
    t.left = t.left - secs
    return t.left <= 0
end

local function time_up(t)
    if t.boss then boss_fail() else expire(t) end
end

local function advance(t)
    t.step = t.step + 1
    t.placed = {}
    t.station = nil
    if t.step > #GAMES[t.game].steps then t.msg = "Order up! Hit SERVE!" end
end

-- a timed step is done (by the player, or by the Sous Chef voucher)
local function finish_station(t, step, quality, auto)
    t.station = nil
    t.stack[#t.stack + 1] = ((quality == "perfect") and "perfectly " or "") .. step.done
    advance(t)
    if t.step <= #GAMES[t.game].steps then
        if auto then
            t.msg = "The Sous Chef took care of it - perfect!"
        else
            t.msg = (quality == "perfect") and "Perfect timing!" or "Good enough!"
        end
    end
    play_sound((quality == "perfect") and "multhit2" or "chips1", 1, 0.6)
end

-- Kitchen Timer: the bell. Works from anywhere, including while you are playing cards.
local function ring_bell(t, step, finished)
    if t.station then t.station.alerted = true end
    local who = OUTFITS[t.outfit].name
    local text = finished and (who .. "'s order is " .. step.done .. "!") or (who .. "'s order is ready!")
    if not finished then t.msg = "DING! Take it out now!" end
    play_sound("timpani", 1.2, 0.8)
    play_sound("coin1", 1.4, 0.5)
    safe(attention_text, {
        text = text, scale = 0.55, hold = 1.6, colour = G.C.ORANGE,
        align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
    })
end

-- the reward for a served order; returns the text to show
local function pay_reward(t, rush)
    local r = t.reward
    local n = reward_n(r) * (rush and 2 or 1)
    local text = reward_text(r, rush)

    if r.kind == "cash" then
        ease_dollars(n)
    elseif r.kind == "chips" then
        local blind = G.GAME.blind
        local amount = math.floor(((blind and blind.chips) or 0) * n / 100)
        if amount > 0 then
            G.GAME.chips = G.GAME.chips + amount
            text = "+" .. number_format(amount) .. " chips"
        end
    elseif r.kind == "hand" then
        ease_hands_played(n)
    elseif r.kind == "discard" then
        ease_discard(n)
    else
        local made = 0
        for _ = 1, n do
            if consumable_room() then
                made = made + 1
                G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
                G.E_MANAGER:add_event(Event({
                    func = function()
                        SMODS.add_card { set = "Tarot" }
                        G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                        return true
                    end
                }))
            end
        end
        if made < n then
            -- no room for every Tarot: cash instead
            local cash = 3 * (n - made)
            ease_dollars(cash)
            text = (made > 0 and (made .. plural(made, " Tarot card", " Tarot cards") .. " + ") or "") .. "$" .. cash
        end
    end
    return text
end

----------------------------------------------------------------
-- STATIONS (oven / fryer / blender): progress p goes 0 -> 1 in `dur` seconds, and burns past MAXP
----------------------------------------------------------------
local function zone_of(p)
    if p < OK_LO then return "raw" end
    if p < PERFECT_LO then return "early" end
    if p <= PERFECT_HI then return "perfect" end
    if p <= OK_HI then return "late" end
    return "burnt"
end

local function quality_of(zone)
    if zone == "perfect" then return "perfect" end
    if zone == "early" or zone == "late" then return "ok" end
    return "ruined"
end

local function zone_info(zone)
    if zone == "perfect" then return "PERFECT!", G.C.GREEN end
    if zone == "burnt" then return "BURNING!", G.C.RED end
    if zone == "late" then return "TAKE IT OUT!", G.C.ORANGE end
    if zone == "early" then return "ALMOST...", G.C.ORANGE end
    return "RAW", G.C.GREY
end

local ZONE_CHAR = { raw = ".", early = "-", perfect = "*", late = "-", burnt = "!" }

local function bar_string(p)
    local filled = math.floor(math.min(p, MAXP) / MAXP * BAR_CELLS)
    local out = {}
    for i = 1, BAR_CELLS do
        if i <= filled then
            out[i] = "#"
        else
            out[i] = ZONE_CHAR[zone_of((i - 0.5) / BAR_CELLS * MAXP)]
        end
    end
    return table.concat(out)
end

local function refresh_station_ui(t)
    if not (t and t.station) then return end
    local label, colour = zone_info(zone_of(t.station.p))
    K.ui.bar = "[" .. bar_string(t.station.p) .. "]"
    K.ui.zone = label
    K.ui.zone_colour = colour
end

----------------------------------------------------------------
-- UI BUILDING BLOCKS
----------------------------------------------------------------
local function row(str, scale, colour, align, maxw)
    return { n = G.UIT.R, config = { align = align or "cm" }, nodes = {
        { n = G.UIT.T, config = { text = str, scale = scale or 0.3, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true, maxw = maxw } }
    } }
end

-- Text never wraps by itself in Balatro's UI, so long lines are split into several rows by hand,
-- and each row also gets maxw so it shrinks instead of ever running into its neighbour.
local function wrap_rows(str, scale, colour, align, maxw)
    local per_line = math.max(8, math.floor(maxw / (scale * 0.55)))
    local rows, line = {}, ""
    for word in tostring(str):gmatch("%S+") do
        if line ~= "" and #line + 1 + #word > per_line then
            rows[#rows + 1] = row(line, scale, colour, align, maxw)
            line = word
        else
            line = (line == "") and word or (line .. " " .. word)
        end
    end
    if line ~= "" then rows[#rows + 1] = row(line, scale, colour, align, maxw) end
    return rows
end

local function append_all(dst, src)
    for _, r in ipairs(src) do dst[#dst + 1] = r end
    return dst
end

local function big_button(label, button, ref, colour)
    return { n = G.UIT.R, config = { align = "cm", padding = 0.06 }, nodes = {
        { n = G.UIT.C, config = {
            align = "cm", padding = 0.12, minw = 3.6, minh = 0.8, r = 0.1, hover = true, shadow = true,
            colour = colour, button = button, ref_table = ref
        }, nodes = {
            { n = G.UIT.T, config = { text = label, scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
        } }
    } }
end

-- Jimbo's portrait: the optional customers.png cell for the outfit, otherwise vanilla Jimbo
local function portrait(idx, w, h)
    w, h = w or 0.9, h or 1.2
    local ok, node = pcall(function()
        local atlas = G.ASSET_ATLAS and G.ASSET_ATLAS["ocafe_customers"]
        local sprite
        if atlas then
            sprite = Sprite(0, 0, w, h, atlas, { x = idx - 1, y = 0 })
        else
            local jimbo = G.P_CENTERS.j_joker
            local jatlas = G.ASSET_ATLAS[jimbo.atlas or jimbo.set] or G.ASSET_ATLAS["Joker"]
            sprite = Sprite(0, 0, w, h, jatlas, jimbo.pos or { x = 0, y = 0 })
        end
        if sprite.states and sprite.states.drag then sprite.states.drag.can = false end
        return { n = G.UIT.O, config = { object = sprite } }
    end)
    if ok then return node end
    if sendDebugMessage then sendDebugMessage("papas.lua portrait: " .. tostring(node), "OreoCafe") end
    return { n = G.UIT.B, config = { w = w, h = h, r = 0.1, colour = G.C.JOKER_GREY or G.C.GREY } }
end

-- an area inside an overlay whose content can be swapped without reopening the menu
local function holder(id, build)
    return { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
        { n = G.UIT.O, config = { id = id, object = UIBox {
            definition = { n = G.UIT.ROOT, config = { align = "cm", padding = 0.05, colour = G.C.CLEAR }, nodes = { build() } },
            config = { offset = { x = 0, y = 0 } }
        } } }
    } }
end

local function swap(id, build)
    if not G.OVERLAY_MENU then return end
    local spot = G.OVERLAY_MENU:get_UIE_by_ID(id)
    if not (spot and spot.config.object) then return end
    spot.config.object:remove()
    spot.config.object = UIBox {
        definition = { n = G.UIT.ROOT, config = { align = "cm", padding = 0.05, colour = G.C.CLEAR }, nodes = { build() } },
        config = { offset = { x = 0, y = 0 }, parent = spot, type = "cm" }
    }
    spot.UIBox:recalculate()
end

----------------------------------------------------------------
-- SHOP: THE ORDER COUNTER
----------------------------------------------------------------
local function customer_button(i, c, full, btn_w, label_scale)
    local label, colour, button
    if c.accepted then
        label, colour, button = "TAKEN", G.C.GREEN, "ocafe_toggle_order"
    elseif full then
        label, colour, button = (full == "boss") and "CLOSED" or "FULL", G.C.UI.BACKGROUND_INACTIVE, nil
    else
        label, colour, button = "TAKE ORDER", G.C.BLUE, "ocafe_toggle_order"
    end
    return { n = G.UIT.C, config = {
        align = "cm", padding = 0.1, minw = btn_w, minh = 0.7, r = 0.1, hover = button ~= nil, shadow = true,
        colour = colour, button = button, ref_table = { ci = i }
    }, nodes = {
        { n = G.UIT.T, config = { text = label, scale = label_scale, maxw = btn_w - 0.3, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
    } }
end

-- Order Pad (5 customers) needs a tighter layout so everything still fits on screen
local function customer_row_compact(i, c, full)
    local o = OUTFITS[c.outfit]
    local NAME_W, TEXT_W, BTN_W, GAP = 2.0, 5.6, 2.1, 0.2
    local TEXT_MAXW = TEXT_W - 0.4
    local function short(r, rush) return (reward_text(r, rush):gsub(" of the Blind's score", " score")) end

    local name_rows = { portrait(c.outfit, 0.6, 0.8), row(o.name, 0.21, G.C.WHITE, "cm", NAME_W - 0.3) }
    local text_rows = {}
    append_all(text_rows, wrap_rows(c.title, 0.3, G.C.WHITE, "cl", TEXT_MAXW))
    text_rows[#text_rows + 1] = row(GAMES[c.game].short .. "  -  about " .. math.floor(c.budget * time_mult()) .. "s", 0.22, G.C.UI.TEXT_INACTIVE, "cl", TEXT_MAXW)
    text_rows[#text_rows + 1] = row("Reward: " .. short(c.reward, false) .. "  |  RUSH: " .. short(c.reward, true), 0.22, G.C.GOLD, "cl", TEXT_MAXW)

    return { n = G.UIT.R, config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, minw = NAME_W + GAP + TEXT_W + BTN_W + 0.6 }, nodes = {
        { n = G.UIT.C, config = { align = "cm", padding = 0.03, r = 0.1, colour = o.colour, minw = NAME_W }, nodes = name_rows },
        { n = G.UIT.B, config = { w = GAP, h = 0.1 } },
        { n = G.UIT.C, config = { align = "cl", padding = 0.04, minw = TEXT_W }, nodes = text_rows },
        { n = G.UIT.C, config = { align = "cm", padding = 0.04, minw = BTN_W }, nodes = { customer_button(i, c, full, BTN_W, 0.36) } },
    } }
end

local function customer_row(i, c, full, compact)
    if compact then return customer_row_compact(i, c, full) end
    local o = OUTFITS[c.outfit]
    local NAME_W, TEXT_W, BTN_W, GAP = 2.2, 5.4, 2.1, 0.25
    local TEXT_MAXW = TEXT_W - 0.4   -- text stays well inside its column, padding included

    -- name column: one word per row ("Lumberjack" / "Jimbo") so it always fits its own box
    local name_rows = { portrait(c.outfit) }
    for word in o.name:gmatch("%S+") do name_rows[#name_rows + 1] = row(word, 0.24, G.C.WHITE, "cm", NAME_W - 0.5) end

    -- text column: every line wrapped to the column width
    local text_rows = {}
    append_all(text_rows, wrap_rows(o.greet, 0.27, G.C.UI.TEXT_INACTIVE, "cl", TEXT_MAXW))
    append_all(text_rows, wrap_rows(c.title, 0.34, G.C.WHITE, "cl", TEXT_MAXW))
    append_all(text_rows, wrap_rows(GAMES[c.game].name .. "  -  about " .. math.floor(c.budget * time_mult()) .. "s on the clock", 0.25, G.C.UI.TEXT_INACTIVE, "cl", TEXT_MAXW))
    append_all(text_rows, wrap_rows("Reward: " .. reward_text(c.reward, false), 0.28, G.C.GOLD, "cl", TEXT_MAXW))
    append_all(text_rows, wrap_rows("RUSH (half the time left): " .. reward_text(c.reward, true), 0.25, G.C.GOLD, "cl", TEXT_MAXW))

    return { n = G.UIT.R, config = { align = "cm", padding = 0.08, r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, minw = NAME_W + GAP + TEXT_W + BTN_W + 0.8 }, nodes = {
        { n = G.UIT.C, config = { align = "cm", padding = 0.06, r = 0.1, colour = o.colour, minw = NAME_W }, nodes = name_rows },
        { n = G.UIT.B, config = { w = GAP, h = 0.1 } },
        { n = G.UIT.C, config = { align = "cl", padding = 0.08, minw = TEXT_W }, nodes = text_rows },
        { n = G.UIT.C, config = { align = "cm", padding = 0.05, minw = BTN_W }, nodes = { customer_button(i, c, full, BTN_W, 0.38) } },
    } }
end

local function orders_body()
    local list = (G.GAME and G.GAME.ocafe_customers) or {}
    local taken = count_taken()
    local compact = #list > 3
    local rows = { row("ORDER COUNTER", compact and 0.5 or 0.6, G.C.WHITE) }
    if compact then
        rows[#rows + 1] = row("Take orders now - you cook them NEXT round. Half the time left = RUSH = double!", 0.26, G.C.UI.TEXT_INACTIVE, "cm", 9.6)
    else
        append_all(rows, wrap_rows("Take orders now - you cook them during the NEXT round.", 0.3, G.C.UI.TEXT_INACTIVE, "cm", 9.6))
        append_all(rows, wrap_rows("Serve before the clock runs out for the reward. Half the time left = RUSH = double!", 0.27, G.C.UI.TEXT_INACTIVE, "cm", 9.6))
    end
    rows[#rows + 1] = row("Orders taken: " .. taken .. " / " .. taken_limit(), 0.34, G.C.GOLD)
    if quota_active() then
        local s, q = quota_info()
        rows[#rows + 1] = row("Ante " .. current_ante() .. " quota: " .. s .. " / " .. q
            .. " served  (Boss orders don't count)", compact and 0.26 or 0.28, G.C.ORANGE, "cm", 9.6)
    end
    local locked = rush_next()
    if locked then
        append_all(rows, wrap_rows("The next Blind is THE RUSH. It brings its own orders, so none can be taken now.",
            0.27, G.C.RED, "cm", 9.6))
    end
    for i, c in ipairs(list) do
        rows[#rows + 1] = customer_row(i, c, locked and "boss" or (taken >= taken_limit()), compact)
    end
    return { n = G.UIT.C, config = { align = "cm", padding = compact and 0.03 or 0.06 }, nodes = rows }
end

local function show_error(title, err)
    local msg = tostring(err)
    if sendDebugMessage then sendDebugMessage("papas.lua " .. title .. ": " .. msg, "OreoCafe") end
    local lines = { row(title, 0.45, G.C.RED) }
    for i = 1, 3 do
        local chunk = msg:sub((i - 1) * 70 + 1, i * 70)
        if chunk ~= "" then lines[#lines + 1] = row(chunk, 0.24, G.C.WHITE) end
    end
    pcall(function()
        G.FUNCS.overlay_menu {
            definition = create_UIBox_generic_options { back_func = "exit_overlay_menu", contents = lines }
        }
    end)
end

G.FUNCS.ocafe_open_orders = function(e)
    local ok, err = pcall(function()
        ensure_offers()
        top_up_offers()
        G.FUNCS.overlay_menu {
            definition = create_UIBox_generic_options {
                back_func = "exit_overlay_menu",
                contents = { holder("ocafe_orders", orders_body) }
            }
        }
    end)
    if not ok then show_error("Orders failed to open", err) end
end

G.FUNCS.ocafe_toggle_order = function(e)
    local c = ((G.GAME and G.GAME.ocafe_customers) or {})[e.config.ref_table.ci]
    if not c then return end
    if c.accepted then
        c.accepted = false
        play_sound("cancel", 1, 0.5)
    elseif count_taken() < taken_limit() then
        c.accepted = true
        play_sound("coin1", 1, 0.6)
    else
        return
    end
    G.E_MANAGER:add_event(Event({
        trigger = "immediate", blocking = false,
        func = function()
            swap("ocafe_orders", orders_body)
            return true
        end
    }), "other")
end

-- the ORDERS tab at the top of the shop box. Its whole label is ONE text node ("ORDERS - 2 taken -
-- 3 customers"), so the pieces can never overlap, and maxw shrinks the text if it ever gets too long.
local function orders_label()
    local list = (G.GAME and G.GAME.ocafe_customers) or {}
    if quota_active() then
        local s, q = quota_info()
        return "ORDERS - " .. count_taken() .. " taken - quota " .. s .. "/" .. q
    end
    return "ORDERS - " .. count_taken() .. " taken - " .. #list .. (#list == 1 and " customer" or " customers")
end

G.FUNCS.ocafe_orders_btn = function(e)
    K.ui.orders_label = orders_label()
end

local TAB_W = 3.8   -- width of the tab in the shop box

local function orders_tab()
    K.ui.orders_label = orders_label()
    return { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        { n = G.UIT.R, config = {
            align = "cm", padding = 0.06, minw = TAB_W, minh = 0.5, r = 0.12, colour = G.C.ORANGE,
            hover = true, shadow = true, emboss = 0.05,
            button = "ocafe_open_orders", func = "ocafe_orders_btn"
        }, nodes = {
            { n = G.UIT.T, config = {
                ref_table = K.ui, ref_value = "orders_label", scale = 0.36, maxw = TAB_W - 0.5,
                colour = G.C.WHITE, shadow = true
            } }
        } }
    } }
end

----------------------------------------------------------------
-- ROUND: THE KITCHEN
----------------------------------------------------------------
local function receipt_rows(t)
    local rows = {}
    for si, step in ipairs(GAMES[t.game].steps) do
        local state = (t.step > si) and "done" or ((t.step == si) and "now" or "todo")
        local mark = (state == "done") and "[x] " or ((state == "now") and "[>] " or "[ ] ")
        local colour = (state == "done") and G.C.GREEN or ((state == "now") and G.C.GOLD or G.C.UI.TEXT_INACTIVE)
        local what
        if step.kind == "pick" then
            local names = {}
            for _, id in ipairs(t.order[si]) do names[#names + 1] = option_name(step, id) end
            what = table.concat(names, ", ")
        else
            what = step.verb:lower() .. " it"
        end
        rows[#rows + 1] = row(mark .. step.label .. ": " .. what, 0.27, colour, "cl")
    end
    return rows
end

local function option_button(ti, opt, placed)
    return { n = G.UIT.C, config = {
        align = "cm", padding = 0.07, minw = 1.9, minh = 0.5, r = 0.1, hover = not placed, shadow = true,
        colour = placed and G.C.UI.BACKGROUND_INACTIVE or G.C.BLUE,
        button = (not placed) and "ocafe_pick" or nil, ref_table = { ti = ti, opt = opt.id }
    }, nodes = {
        { n = G.UIT.T, config = { text = opt.name, scale = 0.27, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
    } }
end

local function option_grid(ti, t, step)
    local rows, cur = {}, nil
    for i, o in ipairs(step.options) do
        if (i - 1) % 3 == 0 then
            cur = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {} }
            rows[#rows + 1] = cur
        end
        cur.nodes[#cur.nodes + 1] = option_button(ti, o, contains(t.placed, o.id))
    end
    return rows
end

local function built_so_far(t)
    local list = t.stack
    local from = math.max(1, #list - 4)
    local text = table.concat(list, " > ", from, #list)
    if from > 1 then text = "... > " .. text end
    return row("Built: " .. (#list > 0 and text or "nothing yet"), 0.26, G.C.UI.TEXT_INACTIVE)
end

local function station_nodes(ti, t)
    local game = GAMES[t.game]
    local nodes = {}
    if t.msg and t.msg ~= "" then
        nodes[#nodes + 1] = row(t.msg, 0.32, (t.status == "failed") and G.C.RED or G.C.WHITE)
    end

    if t.status == "served" then
        nodes[#nodes + 1] = row(t.rush and "RUSH ORDER SERVED!" or "Order served!", 0.45, G.C.GOLD)
        nodes[#nodes + 1] = row("Pick another ticket above, or get back to the cards.", 0.27, G.C.UI.TEXT_INACTIVE)
    elseif t.status == "failed" then
        nodes[#nodes + 1] = row("No reward this time - back to the cards!", 0.3, G.C.UI.TEXT_INACTIVE)
    elseif t.step > #game.steps then
        nodes[#nodes + 1] = built_so_far(t)
        nodes[#nodes + 1] = big_button("SERVE!", "ocafe_serve", { ti = ti }, G.C.GREEN)
    else
        local step = game.steps[t.step]
        nodes[#nodes + 1] = built_so_far(t)
        if step.kind == "pick" then
            local want = t.order[t.step]
            nodes[#nodes + 1] = row(step.label .. " - pick " .. #want .. " (" .. #t.placed .. "/" .. #want .. ")", 0.34, G.C.GOLD)
            for _, r in ipairs(option_grid(ti, t, step)) do nodes[#nodes + 1] = r end
        elseif not t.station then
            nodes[#nodes + 1] = row(step.label .. ": " .. step.verb .. " it, then stop it in the PERFECT zone.", 0.29, G.C.GOLD)
            if has_voucher(V_AUTO) then
                nodes[#nodes + 1] = row("It finishes perfectly on its own - no babysitting!", 0.25, G.C.UI.TEXT_INACTIVE)
            elseif has_voucher(V_TIMER) then
                nodes[#nodes + 1] = row("It keeps cooking while you play cards - a bell rings when it's ready!", 0.25, G.C.UI.TEXT_INACTIVE)
            else
                nodes[#nodes + 1] = row("It keeps cooking even while you play cards!", 0.25, G.C.UI.TEXT_INACTIVE)
            end
            nodes[#nodes + 1] = big_button("START " .. step.verb, "ocafe_station_start", { ti = ti }, G.C.BLUE)
        else
            refresh_station_ui(t)
            nodes[#nodes + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
                { n = G.UIT.T, config = { ref_table = K.ui, ref_value = "bar", scale = 0.4, colour = G.C.WHITE, shadow = true } }
            } }
            nodes[#nodes + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
                { n = G.UIT.C, config = { align = "cm", padding = 0.08, minw = 3, r = 0.1, colour = G.C.GREY, func = "ocafe_zone_colour" }, nodes = {
                    { n = G.UIT.T, config = { ref_table = K.ui, ref_value = "zone", scale = 0.42, colour = G.C.WHITE, shadow = true } }
                } }
            } }
            if has_voucher(V_AUTO) then
                nodes[#nodes + 1] = row("The Sous Chef has it - it finishes by itself!", 0.3, G.C.GREEN)
            else
                nodes[#nodes + 1] = big_button("TAKE OUT!", "ocafe_station_stop", { ti = ti }, G.C.GREEN)
            end
        end
    end
    return nodes
end

local function ticket_panel(ti, t)
    if not t then
        return row("No orders this round.", 0.4, G.C.UI.TEXT_INACTIVE)
    end
    local o = OUTFITS[t.outfit]
    local left = {
        { n = G.UIT.R, config = { align = "cl", padding = 0.05 }, nodes = {
            { n = G.UIT.C, config = { align = "cm", padding = 0.04, r = 0.08, colour = o.colour }, nodes = { portrait(t.outfit) } },
            { n = G.UIT.C, config = { align = "cl", padding = 0.1 }, nodes = {
                row(o.name, 0.32, G.C.WHITE, "cl"),
                row(t.title, 0.27, G.C.GOLD, "cl"),
            } },
        } },
    }
    for _, r in ipairs(receipt_rows(t)) do left[#left + 1] = r end
    if t.boss then
        left[#left + 1] = row("No reward. Every order served", 0.25, G.C.GOLD, "cl", 5)
        left[#left + 1] = row("counts toward beating the Blind.", 0.25, G.C.GOLD, "cl", 5)
    else
        left[#left + 1] = row("Reward: " .. reward_text(t.reward, false), 0.27, G.C.GOLD, "cl")
        left[#left + 1] = row("RUSH (half time left): " .. reward_text(t.reward, true), 0.25, G.C.GOLD, "cl")
    end

    return { n = G.UIT.R, config = { align = "cm", padding = 0.06 }, nodes = {
        { n = G.UIT.C, config = { align = "tl", padding = 0.1, r = 0.1, colour = G.C.L_BLACK, minw = 5.4, minh = 4 }, nodes = left },
        { n = G.UIT.C, config = { align = "tm", padding = 0.1, r = 0.1, colour = G.C.L_BLACK, minw = 6.8, minh = 4 }, nodes = station_nodes(ti, t) },
    } }
end

local function ticket_tab(i, t)
    local colour
    if t.status == "served" then
        colour = G.C.GREEN
    elseif t.status == "failed" then
        colour = G.C.RED
    else
        colour = (i == K.sel) and G.C.BLUE or G.C.GREY
    end
    if t.boss then
        -- small tabs, no clock: the Blind has one clock for everything
        return { n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = {
            { n = G.UIT.C, config = {
                align = "cm", padding = 0.05, minw = 1.6, r = 0.1, hover = true, shadow = true,
                colour = colour, button = "ocafe_select_ticket", ref_table = { ti = i }
            }, nodes = {
                row("#" .. i .. " " .. GAMES[t.game].short, 0.24, G.C.WHITE, "cm", 1.5)
            } }
        } }
    end
    return { n = G.UIT.C, config = { align = "cm", padding = 0.06 }, nodes = {
        { n = G.UIT.C, config = {
            align = "cm", padding = 0.06, minw = 2.7, r = 0.1, hover = true, shadow = true,
            colour = colour, button = "ocafe_select_ticket", ref_table = { ti = i }
        }, nodes = {
            row(OUTFITS[t.outfit].name, 0.26, G.C.WHITE),
            row(GAMES[t.game].short, 0.24, G.C.UI.TEXT_INACTIVE),
            { n = G.UIT.R, config = { align = "cm" }, nodes = {
                { n = G.UIT.T, config = { ref_table = t, ref_value = "clock_text", scale = 0.4, colour = G.C.GOLD, shadow = true } }
            } },
        } }
    } }
end

local function kitchen_body()
    local g = G.GAME
    local list = g.ocafe_tickets or {}
    if not list[K.sel] then K.sel = 1 end
    g.chips_text = g.chips_text or number_format(g.chips)

    -- the Boss has many tickets: five tabs per row
    local rail_rows = {}
    if list[1] and list[1].boss then
        local cur
        for i, t in ipairs(list) do
            if (i - 1) % 5 == 0 then
                cur = { n = G.UIT.R, config = { align = "cm", padding = 0.01 }, nodes = {} }
                rail_rows[#rail_rows + 1] = cur
            end
            cur.nodes[#cur.nodes + 1] = ticket_tab(i, t)
        end
    else
        local rail = {}
        for i, t in ipairs(list) do rail[#rail + 1] = ticket_tab(i, t) end
        rail_rows[1] = { n = G.UIT.R, config = { align = "cm", padding = 0.02 }, nodes = rail }
    end

    local nodes = {
        row(g.ocafe_boss and (g.ocafe_boss.title or "THE RUSH") or "THE KITCHEN", 0.55, G.C.WHITE),
        { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
            { n = G.UIT.T, config = { text = "Hands ", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE, shadow = true } },
            { n = G.UIT.T, config = { ref_table = g.current_round, ref_value = "hands_left", scale = 0.3, colour = G.C.BLUE, shadow = true } },
            { n = G.UIT.T, config = { text = "    Discards ", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE, shadow = true } },
            { n = G.UIT.T, config = { ref_table = g.current_round, ref_value = "discards_left", scale = 0.3, colour = G.C.RED, shadow = true } },
            { n = G.UIT.T, config = { text = "    Score ", scale = 0.3, colour = G.C.UI.TEXT_INACTIVE, shadow = true } },
            { n = G.UIT.T, config = { ref_table = g, ref_value = "chips_text", scale = 0.3, colour = G.C.WHITE, shadow = true } },
            { n = G.UIT.T, config = { text = " / " .. number_format((g.blind and g.blind.chips) or 0), scale = 0.3, colour = G.C.UI.TEXT_INACTIVE, shadow = true } },
        } },
    }
    if g.ocafe_boss then
        nodes[#nodes + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
            { n = G.UIT.T, config = { ref_table = K.ui, ref_value = "boss_line", scale = 0.36, colour = G.C.GOLD, shadow = true } }
        } }
    elseif quota_active() then
        local s, q = quota_info()
        nodes[#nodes + 1] = row("Ante " .. current_ante() .. " quota: " .. s .. " / " .. q .. " orders served", 0.28, G.C.ORANGE)
    end
    for _, r in ipairs(rail_rows) do nodes[#nodes + 1] = r end
    nodes[#nodes + 1] = ticket_panel(K.sel, list[K.sel])
    return { n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = nodes }
end

-- rebuild the kitchen contents (from a tick: right away; from a button: next frame)
function K.refresh()
    if not kitchen_open() then return end
    swap("ocafe_kitchen", kitchen_body)
end

function K.refresh_later()
    G.E_MANAGER:add_event(Event({
        trigger = "immediate", blocking = false,
        func = function()
            K.refresh()
            return true
        end
    }), "other")
end

----------------------------------------------------------------
-- KITCHEN BUTTONS
----------------------------------------------------------------
local function get_ticket(e)
    local ref = e and e.config and e.config.ref_table
    return ref and tickets()[ref.ti] or nil, ref
end

G.FUNCS.ocafe_select_ticket = function(e)
    local _, ref = get_ticket(e)
    if not ref then return end
    K.sel = ref.ti
    K.refresh_later()
end

G.FUNCS.ocafe_pick = function(e)
    local t, ref = get_ticket(e)
    if not (t and t.status == "open") then return end
    local step = GAMES[t.game].steps[t.step]
    if not (step and step.kind == "pick") then return end
    local want = t.order[t.step]

    if contains(want, ref.opt) and not contains(t.placed, ref.opt) then
        t.placed[#t.placed + 1] = ref.opt
        t.stack[#t.stack + 1] = option_name(step, ref.opt)
        t.msg = ""
        play_sound("card1", 0.9 + 0.08 * #t.placed, 0.7)
        if #t.placed >= #want then advance(t) end
    else
        t.mistakes = t.mistakes + 1
        local out = lose_time(t, MISTAKE_COST)
        t.msg = "Wrong ingredient! -" .. MISTAKE_COST .. "s"
        play_sound("cancel", 1, 0.6)
        if out then time_up(t) end
    end
    K.refresh_later()
end

G.FUNCS.ocafe_station_start = function(e)
    local t = get_ticket(e)
    if not (t and t.status == "open" and not t.station) then return end
    local step = GAMES[t.game].steps[t.step]
    if not (step and step.kind == "timed") then return end
    t.station = { p = 0 }
    t.msg = ""
    play_sound("button", 1, 0.5)
    K.refresh_later()
end

G.FUNCS.ocafe_station_stop = function(e)
    local t = get_ticket(e)
    if not (t and t.status == "open" and t.station) then return end
    if has_voucher(V_AUTO) then return end   -- the Sous Chef does this
    local step = GAMES[t.game].steps[t.step]
    if not (step and step.kind == "timed") then return end

    local zone = zone_of(t.station.p)
    local quality = quality_of(zone)
    t.station = nil
    if quality == "ruined" then
        local out = lose_time(t, RUIN_COST)
        t.msg = ((zone == "raw") and "Still raw!" or "Burnt!") .. " Start over (-" .. RUIN_COST .. "s)"
        play_sound("cancel", 1, 0.6)
        if out then time_up(t) end
    else
        finish_station(t, step, quality, false)
    end
    K.refresh_later()
end

G.FUNCS.ocafe_serve = function(e)
    local t = get_ticket(e)
    if not (t and t.status == "open") then return end
    if t.step <= #GAMES[t.game].steps then return end

    -- The Rush: no reward, no clock of its own. Every order counts toward the Blind.
    if t.boss then
        local b = G.GAME.ocafe_boss
        if not b or b.result then return end
        t.status = "served"
        t.clock_text = "SERVED"
        b.done = b.done + 1
        t.msg = "Served! " .. b.done .. "/" .. b.goal
        play_sound("coin3", 1, 0.7)
        if b.done >= b.goal then
            b.result = "won"
        else
            -- jump to the next order that is still open
            local list = tickets()
            for step = 1, #list do
                local i = ((K.sel - 1 + step) % #list) + 1
                if list[i].status == "open" then
                    K.sel = i
                    break
                end
            end
        end
        K.refresh_later()
        return
    end

    if t.left <= 0 then
        expire(t)
        K.refresh_later()
        return
    end

    local rush = t.left >= t.limit * RUSH_FRACTION
    t.status = "served"
    t.rush = rush
    t.clock_text = rush and "RUSH!" or "SERVED"
    if quota_active() then count_quota() end
    t.msg = (rush and "RUSH! " or "Served! ") .. pay_reward(t, rush)
    play_sound("coin3", 1, 0.7)
    if rush then play_sound("multhit2", 1.1, 0.7) end
    K.refresh_later()
end

-- colour of the "RAW / PERFECT / BURNING" box follows the station
G.FUNCS.ocafe_zone_colour = function(e)
    e.config.colour = K.ui.zone_colour or G.C.GREY
end

-- the KITCHEN button next to the Sort buttons: hidden without orders, usable while selecting a hand
G.FUNCS.ocafe_kitchen_btn = function(e)
    if not any_open() or not (G.GAME and G.GAME.ocafe_live) then
        e.config.colour = G.C.CLEAR
        e.config.button = nil
    elseif G.STATE == G.STATES.SELECTING_HAND then
        e.config.colour = G.C.ORANGE
        e.config.button = "ocafe_open_kitchen"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

G.FUNCS.ocafe_open_kitchen = function(e)
    if G.STATE ~= G.STATES.SELECTING_HAND or not any_open() then return end
    local first
    for i, t in ipairs(tickets()) do
        if t.status == "open" then first = first or i end
    end
    if not (tickets()[K.sel] and tickets()[K.sel].status == "open") then K.sel = first or 1 end
    local ok, err = pcall(function()
        G.FUNCS.overlay_menu {
            definition = create_UIBox_generic_options {
                back_func = "exit_overlay_menu",
                contents = { holder("ocafe_kitchen", kitchen_body) }
            }
        }
        K.menu = G.OVERLAY_MENU
    end)
    if not ok then show_error("Kitchen failed to open", err) end
end

local function kitchen_button()
    return { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        { n = G.UIT.C, config = {
            align = "cm", padding = 0.06, r = 0.08, hover = true, colour = G.C.CLEAR, func = "ocafe_kitchen_btn"
        }, nodes = {
            { n = G.UIT.R, config = { align = "cm" }, nodes = {
                { n = G.UIT.T, config = { ref_table = K.ui, ref_value = "kitchen_label", scale = 0.32, colour = G.C.WHITE, shadow = true } }
            } },
            { n = G.UIT.R, config = { align = "cm" }, nodes = {
                { n = G.UIT.T, config = { ref_table = K.ui, ref_value = "kitchen_sub", scale = 0.24, colour = G.C.WHITE, shadow = true } }
            } },
        } }
    } }
end

----------------------------------------------------------------
-- CLOCKS
----------------------------------------------------------------
local function update_labels()
    local open, soonest, ready = 0, nil, false
    local boss = G.GAME and G.GAME.ocafe_boss
    if G.GAME and G.GAME.ocafe_live then
        for _, t in ipairs(tickets()) do
            if t.status == "open" then
                open = open + 1
                if not t.boss then soonest = soonest and math.min(soonest, t.left) or t.left end
                if t.station and t.station.alerted then ready = true end
            end
        end
    end
    if boss and open > 0 then
        K.ui.kitchen_label = ready and "KITCHEN - READY!" or "KITCHEN"
        K.ui.kitchen_sub = boss.done .. "/" .. boss.goal .. " served - " .. fmt_time(boss.left)
    elseif open > 0 then
        K.ui.kitchen_label = ready and "KITCHEN - READY!" or "KITCHEN"
        K.ui.kitchen_sub = open .. plural(open, " order - ", " orders - ") .. fmt_time(soonest)
    else
        K.ui.kitchen_label = ""
        K.ui.kitchen_sub = ""
    end
end

local function tick(dt)
    local g = G.GAME
    update_labels()
    if not (g.ocafe_live and g.ocafe_tickets) then return end
    -- the pause menu stops the clocks, the kitchen does not
    if G.SETTINGS.paused and not kitchen_open() then return end
    dt = math.min(dt, 0.1)

    local changed = false
    local boss = g.ocafe_boss
    for _, t in ipairs(g.ocafe_tickets) do
        if t.status == "open" then
            if not t.boss then t.left = t.left - dt end
            if t.station then
                local step = GAMES[t.game].steps[t.step]
                t.station.p = t.station.p + dt / ((step and step.dur) or 4)
                if step and has_voucher(V_AUTO) and t.station.p >= AUTO_P then
                    -- Sous Chef: done exactly on time, nothing to redo
                    finish_station(t, step, "perfect", true)
                    ring_bell(t, step, true)
                    changed = true
                elseif step and has_voucher(V_TIMER) and not t.station.alerted and t.station.p >= READY_P then
                    ring_bell(t, step, false)
                    changed = true
                end
            end
            if t.station then
                if t.station.p > MAXP then
                    -- left it in the oven too long
                    t.station = nil
                    local out = lose_time(t, RUIN_COST)
                    t.msg = "Burnt! Start over (-" .. RUIN_COST .. "s)"
                    play_sound("cancel", 1, 0.6)
                    changed = true
                    if out then time_up(t) end
                end
            end
            if not t.boss then
                if t.left <= 0 then
                    expire(t)
                    changed = true
                else
                    t.clock_text = fmt_time(t.left)
                end
            end
        end
    end

    -- The Rush: one clock for the whole Blind. Score buys time, in proportion to the requirement.
    if boss and not boss.result then
        boss.left = boss.left - dt
        local chips = g.chips or 0
        if type(chips) == "number" and type(boss.seen) == "number" and chips > boss.seen then
            local need = math.max(1, (g.blind and g.blind.chips) or 1)
            boss.left = boss.left + (chips - boss.seen) / need * BOSS_SCORE_TIME
        end
        boss.seen = chips
        if boss.left <= 0 then
            boss_fail()
            changed = true
        end
        K.ui.boss_line = (boss.title or "THE RUSH") .. "  -  " .. boss.done .. "/" .. boss.goal .. " served  -  " .. fmt_time(boss.left)
    end

    refresh_station_ui(g.ocafe_tickets[K.sel])
    if changed then K.refresh() end
end

local papas_update_ref = Game.update
function Game:update(dt)
    papas_update_ref(self, dt)
    if G.STAGE == G.STAGES.RUN and G.GAME then
        safe(tick, dt)
    end
end

----------------------------------------------------------------
-- HOOKS INTO THE ROUND
----------------------------------------------------------------
-- a new Blind starts: the orders you took in the shop begin now
local papas_set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, ...)
    local ret = papas_set_blind_ref(self, blind, reset, ...)
    if blind and not reset and G.GAME then
        safe(start_orders, blind)
    end
    return ret
end

-- the round is over: whatever wasn't served is lost
if type(end_round) == "function" then
    local end_round_ref = end_round
    end_round = function(...)
        safe(close_orders)

        -- Papa's Deck: the Boss Blind was beaten, but the Ante's order quota wasn't met
        local blind = G.GAME and G.GAME.blind
        if quota_active() and blind and blind.boss and (G.GAME.chips or 0) >= (blind.chips or 0) then
            local served, need = quota_info()
            if served < need then
                G.E_MANAGER:add_event(Event({
                    trigger = "after", delay = 0.3,
                    func = function()
                        safe(attention_text, {
                            text = "QUOTA NOT MET: " .. served .. "/" .. need, scale = 0.9, hold = 2.2,
                            colour = G.C.RED, align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
                        })
                        play_sound("cancel", 0.8, 0.8)
                        return true
                    end
                }))
                G.E_MANAGER:add_event(Event({
                    trigger = "after", delay = 2.4,
                    func = function()
                        G.STATE = G.STATES.GAME_OVER
                        G.STATE_COMPLETE = false
                        return true
                    end
                }))
                return
            end
        end

        return end_round_ref(...)
    end
end

-- The Rush: the score requirement never ends the round (only the orders, or the clock, do).
-- The game decides "round over" in update_new_round, so the cancel happens there: back to drawing.
if Game.update_new_round then
    local new_round_ref = Game.update_new_round
    function Game:update_new_round(dt, ...)
        local boss = G.GAME and G.GAME.ocafe_boss
        if boss and boss.map and boss.result == "lost" and not G.STATE_COMPLETE then
            fail_challenge() -- the normal rules decide how this round ends
        elseif boss and not G.STATE_COMPLETE then
            if not boss.result then
                G.STATE = G.STATES.DRAW_TO_HAND
                G.STATE_COMPLETE = false
                return
            elseif boss.result == "lost" then
                -- the clock ran out during the hand: even a high score can't save the run now
                boss.result = "dead"
                G.STATE = G.STATES.GAME_OVER
                G.STATE_COMPLETE = false
                return
            end
        end
        return new_round_ref(self, dt, ...)
    end
end

-- with no hands left in The Rush the player can still cook, but not play
if G.FUNCS.can_play then
    local can_play_ref = G.FUNCS.can_play
    G.FUNCS.can_play = function(e)
        can_play_ref(e)
        local b = G.GAME and G.GAME.ocafe_boss
        if b and not b.result and ((G.GAME.current_round and G.GAME.current_round.hands_left) or 0) < 1 then
            e.config.colour = G.C.UI.BACKGROUND_INACTIVE
            e.config.button = nil
        end
    end
end

-- The Rush is over: all orders served = the Blind is beaten, clock at zero = the run is over.
-- Both wait for a calm moment (choosing a hand) so scoring events can't undo them.
local rush_update_ref = Game.update
function Game:update(dt, ...)
    local g = G and G.GAME
    local boss = g and G.STAGE == G.STAGES.RUN and g.ocafe_boss
    if boss and boss.result and boss.result ~= "done" and boss.result ~= "dead"
        and G.STATE == G.STATES.SELECTING_HAND then
        if kitchen_open() and G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
        if G.hand then G.hand:unhighlight_all() end
        if boss.map and boss.result == "lost" then
            fail_challenge()
            -- already past the score, or out of hands: end the round under the normal rules
            if (g.chips or 0) >= ((g.blind and g.blind.chips) or 0)
                or ((g.current_round and g.current_round.hands_left) or 0) < 1 then
                G.STATE = G.STATES.NEW_ROUND
                G.STATE_COMPLETE = false
            end
        elseif boss.result == "won" then
            boss.result = "done"
            g.chips = math.max(g.chips or 0, (g.blind and g.blind.chips) or 0)
            g.chips_text = number_format(g.chips)
            G.STATE = G.STATES.NEW_ROUND
            G.STATE_COMPLETE = false
        else
            boss.result = "dead"
            G.STATE = G.STATES.GAME_OVER
            G.STATE_COMPLETE = false
        end
    end
    return rush_update_ref(self, dt, ...)
end

-- every hand you play makes the customers wait a little longer
if G.FUNCS.play_cards_from_highlighted then
    local play_ref = G.FUNCS.play_cards_from_highlighted
    G.FUNCS.play_cards_from_highlighted = function(e)
        if G.GAME and G.GAME.ocafe_live and G.hand and #G.hand.highlighted > 0 then
            -- (The Rush has no per-order clocks: its hands add time through their score, see tick)
            for _, t in ipairs(tickets()) do
                if t.status == "open" and not t.boss then
                    t.limit = t.limit + HAND_PATIENCE
                    t.left = t.left + HAND_PATIENCE
                end
            end
        end
        return play_ref(e)
    end
end

----------------------------------------------------------------
-- HOOKS INTO THE UI
----------------------------------------------------------------
-- the chain of nodes from the root down to the node with this id
local function find_path(node, id, path)
    if type(node) ~= "table" then return nil end
    path[#path + 1] = node
    if node.config and node.config.id == id then return path end
    for _, child in ipairs(node.nodes or {}) do
        local found = find_path(child, id, path)
        if found then return found end
    end
    path[#path] = nil
    return nil
end

-- put the ORDERS tab as the first row of the shop box (above the sign, Next Round, Reroll and the
-- cards). The shop box is the outermost column on the way to the Next Round button that stacks
-- several rows; if the layout isn't recognised, the first column under the root is used.
local function add_orders_tab(t)
    if OCAFE.map_active and OCAFE.map_active() then return end -- the Map Deck has no ORDERS tab
    local path = find_path(t, "next_round_button", {})
    if not path then return end
    local box
    for i = 2, #path - 1 do
        local node = path[i]
        if node.n == G.UIT.C and node.nodes and #node.nodes >= 2 then box = node break end
    end
    box = box or path[2]
    if box and box.nodes then table.insert(box.nodes, 1, orders_tab()) end
end

local function add_kitchen_button(t)
    local column = t.nodes and t.nodes[2]
    if column and column.n == G.UIT.C and column.nodes then
        column.nodes[#column.nodes + 1] = kitchen_button()
    else
        t.nodes[#t.nodes + 1] = { n = G.UIT.C, config = { align = "cm" }, nodes = { kitchen_button() } }
    end
end

-- The tab makes the shop box taller. Vanilla parks the open shop at offset.y = -5.3, so the whole
-- box is lifted by SHOP_LIFT to keep every row (the bottom boosters included) on screen.
local SHOP_LIFT = 0.9
local VANILLA_SHOP_Y = -5.3
local update_ref = Game.update
function Game:update(dt, ...)
    local ret = update_ref(self, dt, ...)
    local shop = G and G.shop
    local off = shop and shop.alignment and shop.alignment.offset
    if off and not (OCAFE.map_active and G.GAME and OCAFE.map_active())
        and type(off.y) == "number" and math.abs(off.y - VANILLA_SHOP_Y) < 0.001 then
        off.y = VANILLA_SHOP_Y - SHOP_LIFT
    end
    return ret
end

local installed = { shop = false, hud = false }

local function install_hooks()
    if not installed.shop and G and G.UIDEF and G.UIDEF.shop then
        local shop_ref = G.UIDEF.shop
        G.UIDEF.shop = function(...)
            safe(ensure_offers)
            local t = shop_ref(...)
            safe(add_orders_tab, t)
            return t
        end
        installed.shop = true
    end
    if not installed.hud and create_UIBox_buttons then
        local buttons_ref = create_UIBox_buttons
        create_UIBox_buttons = function(...)
            local t = buttons_ref(...)
            safe(add_kitchen_button, t)
            return t
        end
        installed.hud = true
    end
end

install_hooks()
local papas_start_run_ref = Game.start_run
function Game:start_run(args)
    install_hooks()
    return papas_start_run_ref(self, args)
end

----------------------------------------------------------------
-- VOUCHERS
-- Art: vouchers.png, one 71x95 cell per voucher, in assets/1x (284x95) and assets/2x (568x190):
--   x=0 Kitchen Timer | x=1 Sous Chef | x=2 Order Pad | x=3 Dinner Rush
----------------------------------------------------------------
SMODS.Atlas { key = "vouchers", path = "vouchers.png", px = 71, py = 95 }

SMODS.Voucher {
    key = "kitchen_timer",
    atlas = "vouchers", pos = { x = 0, y = 0 },
    cost = 10,
    loc_txt = {
        name = "Kitchen Timer",
        text = {
            "The {C:attention}oven{}, {C:attention}fryer{} and {C:attention}blender{}",
            "{C:attention}ring a bell{} as soon as the",
            "food is ready, even while",
            "you are playing cards",
        },
    },
}

SMODS.Voucher {
    key = "sous_chef",
    atlas = "vouchers", pos = { x = 1, y = 0 },
    cost = 10,
    requires = { V_TIMER },
    loc_txt = {
        name = "Sous Chef",
        text = {
            "The oven, fryer and blender",
            "{C:attention}finish by themselves{}, {C:attention}perfectly{},",
            "when the food is done -",
            "nothing burns, nothing to redo",
        },
    },
}

SMODS.Voucher {
    key = "order_pad",
    in_pool = function() return not (OCAFE.map_active and OCAFE.map_active()) end,
    atlas = "vouchers", pos = { x = 2, y = 0 },
    cost = 10,
    config = { extra = { orders = ORDER_PAD_TAKEN } },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.orders } }
    end,
    redeem = function(self, card)
        safe(top_up_offers)
    end,
    loc_txt = {
        name = "Order Pad",
        text = {
            "Take up to {C:attention}#1#{} orders",
            "at once in the Order Counter",
        },
    },
}

SMODS.Voucher {
    key = "dinner_rush",
    in_pool = function() return not (OCAFE.map_active and OCAFE.map_active()) end,
    atlas = "vouchers", pos = { x = 3, y = 0 },
    cost = 10,
    requires = { V_PAD },
    config = { extra = { time = DINNER_RUSH_TIME, reward = DINNER_RUSH_REWARD } },
    loc_vars = function(self, info_queue, card)
        local x = card.ability.extra
        return { vars = { math.floor((1 - x.time) * 100 + 0.5), x.reward } }
    end,
    loc_txt = {
        name = "Dinner Rush",
        text = {
            "All orders have {C:attention}#1#%{} less time,",
            "but all order rewards",
            "are {C:attention}X#2#{} bigger",
        },
    },
}

----------------------------------------------------------------
-- BOSS BLIND: THE RUSH
-- Built like the vanilla Boss Blinds: a "The ..." name, a two line description, a colour for the
-- background, an animated 34x34 chip (21 frames, row y=0 of the shared assets/1x/blinds.png declared in main.lua), the
-- usual 2X requirement and $5 payout. It can show up from Ante 2.
-- The rules live in the clock, tick and Game:update code above.
----------------------------------------------------------------
SMODS.Blind {
    key = "rush",
    atlas = "blinds",   -- the shared sheet declared in main.lua (row y=0 is The Rush)
    pos = { x = 0, y = 0 },
    boss = { min = 2 },
    boss_colour = HEX("D9792B"),
    mult = 2,
    dollars = 5,
    loc_txt = {
        name = "The Rush",
        text = {
            "Serve " .. BOSS_ORDERS .. " orders before the",
            "clock runs out",
        },
    },
    -- Chicot / Luchador: the orders vanish and the Blind is played by score
    disable = function(self)
        drop_boss()
    end,
}

----------------------------------------------------------------
-- PAPA'S DECK
-- Starts with the four vouchers (the Back's `vouchers` list redeems them at the start of the run).
-- The order quota is checked in the end_round hook above.
----------------------------------------------------------------
SMODS.Back {
    key = "papas_deck",
    atlas = "decks",   -- the shared deck sheet declared in main.lua (x=2 is Papa's Deck)
    pos = { x = 2, y = 0 },
    config = { vouchers = { V_TIMER, V_AUTO, V_PAD, V_RUSH } },
    loc_txt = {
        name = "Papa's Deck",
        text = {
            "Start with {C:attention}Kitchen Timer{}, {C:attention}Sous Chef{},",
            "{C:attention}Order Pad{} and {C:attention}Dinner Rush",
            "Each Ante has an {C:attention}order quota{}",
            "(" .. order_quota(1) .. " rising to " .. QUOTA_MAX .. "), miss it before the",
            "{C:attention}Boss Blind{} ends and the run is {C:red}over",
        },
    },
}
