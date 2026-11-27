-- Map Deck (loaded from main.lua, AFTER papas.lua, rpg.lua and arcade.lua)
--
--  * Ante 1 is a normal road: Round > Shop > Round > Shop > Boss > Shop.
--  * Every time an Ante is finished you pick 1 of 2-3 paths for the next one. A path says what the
--    Small and Big Blind stops are, and where the shops are (shops are not guaranteed).
--      Round     a normal Blind
--      Kitchen   serve a batch of orders on one clock to beat the Blind (extra cash)
--      Oreo RPG  win a free battle to beat the Blind (extra cash)
--    The Boss Blind is always the Boss Blind. Failing or turning down a challenge costs nothing extra:
--    the stop just becomes a normal Blind that you beat by score.
--  * To make up for missing shops: more money, 4 shop card slots (both Overstocks), $1 rerolls (both
--    Reroll vouchers), 3 vouchers and 3 booster packs per shop.
--  * The ORDERS and Oreo RPG shop tabs are removed with this deck.
--  Saved on G.GAME.ocafe_map: path, choices (waiting to be picked), slot (stop being played), picks
--  Uses OCAFE.kitchen_challenge (papas.lua) and OCAFE.rpg_challenge / rpg_pending / open_rpg (rpg.lua).
--  Art: x=4 of the shared deck sheet (atlas "decks", declared in main.lua).

OCAFE = OCAFE or {}

----------------------------------------------------------------
-- TUNING
----------------------------------------------------------------
local BLIND_BONUS = 3          -- extra $ on every Blind's payout
local KITCHEN_BONUS = 4        -- extra $ on top of that for beating a Kitchen stop
-- (the Oreo RPG stop's extra cash is MAP_REWARD in rpg.lua)
local HAND_MONEY = 2           -- $ per unused hand (normally 1)
local EXTRA_VOUCHERS = 2       -- 1 + 2 = 3 vouchers per shop
local EXTRA_BOOSTERS = 1       -- 2 + 1 = 3 booster packs per shop
local MIN_PATHS, MAX_PATHS = 2, 3
local SHOP_CHANCE = 50         -- % chance of a shop after each of the three stops
local WEIGHTS = { { "round", 45 }, { "kitchen", 30 }, { "rpg", 25 } }
local KITCHEN_ORDERS, KITCHEN_MAX_ORDERS = 3, 6   -- orders: 3, one more every 3 Antes, at most 6
local KITCHEN_SECONDS = 35     -- seconds on the clock per order (before the Ante squeeze in papas.lua)

local DECK_KEY = "b_ocafe_map_deck"
local NAMES = { round = "Round", kitchen = "Kitchen", rpg = "Oreo RPG" }
local SLOTS = { "Small", "Big" }

local function active()
    local back = G.GAME and G.GAME.selected_back
    local center = back and back.effect and back.effect.center
    return center ~= nil and center.key == DECK_KEY
end
OCAFE.map_active = active

local function starting_path()
    return { stops = { Small = { type = "round", shop = true }, Big = { type = "round", shop = true } }, boss_shop = true }
end

local function S()
    local g = G.GAME
    g.ocafe_map = g.ocafe_map or { path = starting_path(), picks = 0 }
    return g.ocafe_map
end

----------------------------------------------------------------
-- PATHS
----------------------------------------------------------------
local function roll_type(seed)
    local total = 0
    for _, w in ipairs(WEIGHTS) do total = total + w[2] end
    local r = pseudorandom(seed, 1, total)
    for _, w in ipairs(WEIGHTS) do
        r = r - w[2]
        if r <= 0 then return w[1] end
    end
    return "round"
end

local function roll_path(seed)
    local p = { stops = {} }
    for _, slot in ipairs(SLOTS) do
        p.stops[slot] = {
            type = roll_type(seed .. slot),
            shop = pseudorandom(seed .. slot .. "_shop", 1, 100) <= SHOP_CHANCE,
        }
    end
    p.boss_shop = pseudorandom(seed .. "_boss_shop", 1, 100) <= SHOP_CHANCE
    return p
end

local function signature(p)
    local s = {}
    for _, slot in ipairs(SLOTS) do s[#s + 1] = p.stops[slot].type .. tostring(p.stops[slot].shop) end
    return table.concat(s) .. tostring(p.boss_shop)
end

local function shop_count(p)
    local n = p.boss_shop and 1 or 0
    for _, slot in ipairs(SLOTS) do
        if p.stops[slot].shop then n = n + 1 end
    end
    return n
end

local function make_choices()
    local m = S()
    local seed = "ocafe_map" .. (m.picks or 0) .. "_"
    local want = pseudorandom(seed .. "count", MIN_PATHS, MAX_PATHS)
    local list, seen = {}, {}
    for try = 1, 60 do
        if #list >= want then break end
        local p = roll_path(seed .. try .. "_")
        if not seen[signature(p)] then
            seen[signature(p)] = true
            list[#list + 1] = p
        end
    end
    -- there is always at least one road with a shop on it
    local any = false
    for _, p in ipairs(list) do any = any or shop_count(p) > 0 end
    if not any then list[1].stops.Big.shop = true end
    return list
end

----------------------------------------------------------------
-- THE MAP SCREEN
----------------------------------------------------------------
local function line(str, scale, colour, maxw)
    return { n = G.UIT.R, config = { align = "cm", padding = 0.02 }, nodes = {
        { n = G.UIT.T, config = { text = str, scale = scale, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true, maxw = maxw } }
    } }
end

local function box(label, colour)
    return { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
        { n = G.UIT.C, config = { align = "cm", padding = 0.06, minw = 2.5, minh = 0.5, r = 0.1, colour = colour, emboss = 0.05 }, nodes = {
            { n = G.UIT.T, config = { text = label, scale = 0.34, maxw = 2.3, colour = G.C.WHITE, shadow = true } }
        } }
    } }
end

local function path_column(i, p)
    local colours = { round = G.C.BLUE, kitchen = G.C.ORANGE, rpg = G.C.PURPLE }
    local nodes = { line("PATH " .. i, 0.45, G.C.GOLD) }
    local function step(label, colour)
        if #nodes > 1 then nodes[#nodes + 1] = line("v", 0.22, G.C.UI.TEXT_INACTIVE) end
        nodes[#nodes + 1] = box(label, colour)
    end
    for _, slot in ipairs(SLOTS) do
        local stop = p.stops[slot]
        step(NAMES[stop.type], colours[stop.type])
        if stop.shop then step("Shop", G.C.GREEN) end
    end
    step("Boss Blind", G.C.RED)
    if p.boss_shop then step("Shop", G.C.GREEN) end
    local n = shop_count(p)
    return { n = G.UIT.C, config = { align = "tm", padding = 0.1 }, nodes = {
        { n = G.UIT.R, config = { align = "tm", padding = 0.1, r = 0.1, minw = 2.9, minh = 5.2, colour = G.C.L_BLACK, emboss = 0.05 }, nodes = {
            { n = G.UIT.C, config = { align = "tm" }, nodes = nodes }
        } },
        line(n .. (n == 1 and " shop" or " shops"), 0.3, G.C.UI.TEXT_LIGHT),
        { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
            { n = G.UIT.C, config = { align = "cm", padding = 0.1, minw = 2.4, minh = 0.7, r = 0.1, hover = true, shadow = true,
                colour = G.C.BLUE, button = "ocafe_map_pick", ref_table = { i = i } }, nodes = {
                { n = G.UIT.T, config = { text = "TAKE PATH", scale = 0.38, colour = G.C.WHITE, shadow = true } }
            } }
        } },
    } }
end

local map_menu -- the overlay that is the map

local function open_map()
    local m = S()
    local cols = {}
    for i, p in ipairs(m.choices) do cols[#cols + 1] = path_column(i, p) end
    G.FUNCS.overlay_menu {
        definition = { n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = {
            { n = G.UIT.C, config = { align = "cm", padding = 0.2, r = 0.15, colour = G.C.BLACK, emboss = 0.05 }, nodes = {
                line("THE MAP", 0.7, G.C.GOLD),
                line("Ante " .. ((G.GAME.round_resets and G.GAME.round_resets.ante) or 1) .. " - choose your path", 0.38),
                { n = G.UIT.R, config = { align = "tm", padding = 0.05 }, nodes = cols },
                { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
                    { n = G.UIT.C, config = { align = "cm", padding = 0.07, minw = 2, r = 0.1, hover = true,
                        colour = G.C.GREY, button = "go_to_menu" }, nodes = {
                        { n = G.UIT.T, config = { text = "Main Menu", scale = 0.28, colour = G.C.WHITE, shadow = true } }
                    } }
                } },
            } }
        } },
        no_esc = true
    }
    map_menu = G.OVERLAY_MENU
end

G.FUNCS.ocafe_map_pick = function(e)
    local m = S()
    local p = m.choices and m.choices[e.config.ref_table.i]
    if not p then return end
    m.path, m.choices = p, nil
    m.picks = (m.picks or 0) + 1
    map_menu = nil
    play_sound("card1", 0.9, 0.7)
    G.FUNCS.exit_overlay_menu()
    if type(save_run) == "function" then pcall(save_run) end
end

----------------------------------------------------------------
-- LABELS on the blind select cards, and the CHALLENGE button during an RPG stop
----------------------------------------------------------------
local labels = { Small = "", Big = "", Boss = "" }

local function update_labels()
    local m = S()
    for _, slot in ipairs(SLOTS) do
        local stop = m.path.stops[slot]
        labels[slot] = NAMES[stop.type] .. (stop.shop and " > Shop" or " > no shop")
    end
    labels.Boss = "Boss" .. (m.path.boss_shop and " > Shop" or " > no shop")
end

local function add_blind_label(t, slot)
    local card = t and t.nodes and t.nodes[1]
    if not (card and card.nodes and labels[slot]) then return end
    update_labels()
    table.insert(card.nodes, 1, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        { n = G.UIT.T, config = { ref_table = labels, ref_value = slot, scale = 0.3, colour = G.C.GOLD, shadow = true } }
    } })
end

local challenge_ui = { label = "" }

G.FUNCS.ocafe_map_rpg_btn = function(e)
    local show = G.GAME and active() and OCAFE.rpg_pending and OCAFE.rpg_pending()
    challenge_ui.label = show and "RPG CHALLENGE" or ""
    if show and G.STATE == G.STATES.SELECTING_HAND then
        e.config.colour, e.config.button = G.C.PURPLE, "ocafe_map_open_rpg"
    else
        e.config.colour, e.config.button = show and G.C.UI.BACKGROUND_INACTIVE or G.C.CLEAR, nil
    end
end

G.FUNCS.ocafe_map_open_rpg = function(e)
    if G.STATE == G.STATES.SELECTING_HAND then OCAFE.open_rpg() end
end

local function add_rpg_button(t)
    local node = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        { n = G.UIT.C, config = { align = "cm", padding = 0.06, r = 0.08, hover = true, colour = G.C.CLEAR, func = "ocafe_map_rpg_btn" }, nodes = {
            { n = G.UIT.T, config = { ref_table = challenge_ui, ref_value = "label", scale = 0.3, colour = G.C.WHITE, shadow = true } }
        } }
    } }
    local column = t.nodes and t.nodes[2]
    if column and column.n == G.UIT.C and column.nodes then
        column.nodes[#column.nodes + 1] = node
    elseif t.nodes then
        t.nodes[#t.nodes + 1] = { n = G.UIT.C, config = { align = "cm" }, nodes = { node } }
    end
end

----------------------------------------------------------------
-- HOOKS INTO THE RUN
----------------------------------------------------------------
local function log(where, err)
    if sendDebugMessage then sendDebugMessage("map.lua " .. where .. ": " .. tostring(err), "OreoCafe") end
end

-- a Blind starts: pay bonus, and turn it into a challenge if the path says so
local function start_stop(self, blind)
    local m = S()
    local slot = (blind.key == "bl_small" and "Small") or (blind.key == "bl_big" and "Big") or "Boss"
    m.slot = slot
    local stop = m.path.stops[slot]
    local bonus = BLIND_BONUS + ((stop and stop.type == "kitchen") and KITCHEN_BONUS or 0)
    -- (the Kitchen bonus is taken back by OCAFE.kitchen_failed if the challenge is failed)
    m.kitchen_bonus = (stop and stop.type == "kitchen") and KITCHEN_BONUS or nil
    self.dollars = (self.dollars or 0) + bonus
    if G.GAME.current_round then
        G.GAME.current_round.dollars_to_be_earned = string.rep("$", self.dollars)
    end
    if not stop then return end
    if stop.type == "kitchen" then
        local ante = (G.GAME.round_resets and G.GAME.round_resets.ante) or 1
        local orders = math.min(KITCHEN_MAX_ORDERS, KITCHEN_ORDERS + math.floor((ante - 1) / 3))
        OCAFE.kitchen_challenge(orders, orders * KITCHEN_SECONDS)
    elseif stop.type == "rpg" then
        OCAFE.rpg_challenge()
    end
end

local set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, ...)
    local ret = set_blind_ref(self, blind, reset, ...)
    if blind and not reset and G.GAME and active() then
        local ok, err = pcall(start_stop, self, blind)
        if not ok then log("set_blind", err) end
    end
    return ret
end

-- a failed Kitchen stop pays like an ordinary round
function OCAFE.kitchen_failed()
    local m = S()
    local blind = G.GAME.blind
    if not (m.kitchen_bonus and blind) then return end
    blind.dollars = math.max(0, (blind.dollars or 0) - m.kitchen_bonus)
    G.GAME.current_round.dollars_to_be_earned = string.rep("$", blind.dollars)
    m.kitchen_bonus = nil
end

-- after the cash out the game heads for the shop: skip it when the path has none there
if Game.update_shop then
    local update_shop_ref = Game.update_shop
    function Game:update_shop(dt, ...)
        if G.GAME and not G.STATE_COMPLETE and active() and S().slot then
            local m = S()
            local slot = m.slot
            m.slot = nil
            local shop
            if slot == "Boss" then
                shop = m.path.boss_shop
                m.choices = make_choices() -- the Ante is complete
            else
                shop = m.path.stops[slot].shop
            end
            if not shop then
                G.STATE = G.STATES.BLIND_SELECT
                G.STATE_COMPLETE = false
                return
            end
        end
        return update_shop_ref(self, dt, ...)
    end
end

local function tick()
    local m = S()
    update_labels()
    -- the map appears at the Blind select screen once the Ante (and its shop) is over
    if m.choices and G.STATE == G.STATES.BLIND_SELECT and G.STATE_COMPLETE and G.blind_select
        and (not G.OVERLAY_MENU) then
        open_map()
    end
    if G.STATE == G.STATES.SELECTING_HAND and OCAFE.rpg_tick then OCAFE.rpg_tick() end
end

local update_ref = Game.update
function Game:update(dt, ...)
    local ret = update_ref(self, dt, ...)
    if G.STAGE == G.STAGES.RUN and G.GAME and active() then
        local ok, err = pcall(tick)
        if not ok and not OCAFE.map_logged then
            OCAFE.map_logged = true
            log("update", err)
        end
    end
    return ret
end

local installed = { select = false, hud = false }

local function install_hooks()
    if not installed.select and create_UIBox_blind_choice then
        local choice_ref = create_UIBox_blind_choice
        create_UIBox_blind_choice = function(type_, run_info, ...)
            local t = choice_ref(type_, run_info, ...)
            if not run_info and G.GAME and active() then
                local ok, err = pcall(add_blind_label, t, type_)
                if not ok then log("blind label", err) end
            end
            return t
        end
        installed.select = true
    end
    if not installed.hud and create_UIBox_buttons then
        local buttons_ref = create_UIBox_buttons
        create_UIBox_buttons = function(...)
            local t = buttons_ref(...)
            if G.GAME and active() then
                local ok, err = pcall(add_rpg_button, t)
                if not ok then log("rpg button", err) end
            end
            return t
        end
        installed.hud = true
    end
end

install_hooks()
local start_run_ref = Game.start_run
function Game:start_run(args)
    map_menu = nil
    install_hooks()
    return start_run_ref(self, args)
end

----------------------------------------------------------------
-- THE DECK
----------------------------------------------------------------
SMODS.Back {
    key = "map_deck",
    atlas = "decks", -- the shared deck sheet declared in main.lua (x=4 is the Map Deck)
    pos = { x = 4, y = 0 },
    config = {
        vouchers = { "v_reroll_surplus", "v_reroll_glut", "v_overstock_norm", "v_overstock_plus" },
        extra_hand_bonus = HAND_MONEY,
    },
    loc_txt = {
        name = "Map",
        text = {
            "After each Ante, choose a {C:attention}path",
            "of {C:attention}Rounds{}, {C:attention}Kitchen{} and {C:attention}Oreo RPG",
            "challenges. {C:red}Shops aren't guaranteed",
            "Earn more {C:money}money{}, shops have",
            "{C:attention}4{} cards, {C:attention}3{} vouchers, {C:attention}3{} packs",
            "and {C:money}$1{} rerolls"
        }
    },
    apply = function(self, back)
        -- called directly (not in an event) so the first shop already has them
        if SMODS.change_voucher_limit then SMODS.change_voucher_limit(EXTRA_VOUCHERS) end
        if SMODS.change_booster_limit then SMODS.change_booster_limit(EXTRA_BOOSTERS) end
    end
}
