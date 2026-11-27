-- Azur Lane: Eagle Union (loaded from main.lua)
--   Jokers:  j_ocafe_ + enterprise, yorktown, hornet, new_jersey, north_carolina, washington, laffey, fletcher
--   Tarots:  c_ocafe_construction_eu, c_ocafe_us_industrial_power
--   Spectral: c_ocafe_grey_ghost (spectrals.png x=4)
--   Mechanic: KAMIKAZE
--   Blinds:   bl_ocafe_siren_curse, bl_ocafe_fleet_training (bottom of this file, blinds.png rows y=1 and y=2)
-- Art: the Jokers are in jokers.png (sorted by rarity, see main.lua): Fletcher x=2, Laffey x=14 and the six Rare ships
--      (Enterprise, Yorktown, Hornet, New Jersey, North Carolina, Washington) x=41..46.
--      The Tarots are tarots.png x=1 and x=2.
--
-- Every ship has a base of +50 Chips and +10 Mult. "Base stats" multipliers (Enterprise, Hornet, New Jersey,
-- North Carolina, Washington) multiply THOSE numbers (so X270 on New Jersey = +13500 Chips and +2700 Mult).
-- "X Mult" (Yorktown) is a real X Mult. Multipliers that say "per ..." stack by multiplying (X2 per carrier
-- with two carriers = X4).

----------------------------------------------------------------
-- TUNING KNOBS
----------------------------------------------------------------
local BASE_CHIPS, BASE_MULT = 50, 10
local CARRIER_BASE_X = 2       -- Enterprise: base stats X2 per other Eagle Union carrier
local ALONE_X = 30             -- Enterprise: base stats X30 when no other Eagle Union ship is owned
local YORKTOWN_X = 10          -- Yorktown: X10 Mult per other Eagle Union carrier
local HORNET_X = 2             -- Hornet: base stats X2 per other Eagle Union ship
local HORNET_ODDS = 20         -- Hornet: 1 in 20 US Industrial Power at end of round
local JERSEY_ALONE_X = 270     -- New Jersey: base stats X270 with no other Jokers at all
local JERSEY_PAIR_X = 5        -- New Jersey: base stats X5 with North Carolina or Washington
local NC_X = 10                -- North Carolina: base stats X10 with Washington
local WASH_PAIR_X = 10         -- Washington: base stats X10 with New Jersey or North Carolina
local WASH_BOTH_X = 45         -- Washington: base stats X45 with both
local LAFFEY_SLEEP_ODDS = 5    -- Laffey: 1 in 5 to sleep through a round
local LAFFEY_X2_ODDS = 10      -- Laffey: 1 in 10 to X2 her stats when she scores
local FLETCHER_BONUS = 50      -- Fletcher: extra Chips
local GHOST_X = 2              -- Grey Ghost: Enterprise's stats X2 per use
local KAMIKAZE_ODDS = 5        -- 1 in 5 per hand played that a Ship Joker is hit
local KAMIKAZE_KILL_ODDS = 10  -- 1 in 10 that the hit destroys it instead of debuffing it

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function jk(id) return "j_ocafe_" .. id end

local function to_set(ids)
    local s = {}
    for _, id in ipairs(ids) do s[jk(id)] = true end
    return s
end

local SHIP_IDS = { "enterprise", "yorktown", "hornet", "new_jersey", "north_carolina", "washington", "laffey", "fletcher" }
local SHIP_SET = to_set(SHIP_IDS)
local CARRIER_SET = to_set({ "enterprise", "yorktown", "hornet" })

local ENTERPRISE, YORKTOWN, HORNET = jk("enterprise"), jk("yorktown"), jk("hornet")
local JERSEY, CAROLINA, WASHINGTON = jk("new_jersey"), jk("north_carolina"), jk("washington")
local FLETCHER = jk("fletcher")
local INDUSTRIAL_KEY = "c_ocafe_us_industrial_power"

-- number of owned Jokers (not debuffed, not `except`) whose key is in `set`
local function count_in(set, except)
    local n = 0
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if j ~= except and not j.debuff and set[j.config.center.key] then n = n + 1 end
    end
    return n
end

local function owns(key)
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if not j.debuff and j.config.center.key == key then return true end
    end
    return false
end

local function consumable_room()
    return G.consumeables and (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0)) < G.consumeables.config.card_limit
end

local function joker_room()
    return G.jokers and (#G.jokers.cards + (G.GAME.joker_buffer or 0)) < G.jokers.config.card_limit
end

local function say(card, text, colour)
    G.E_MANAGER:add_event(Event({
        func = function()
            if card and not card.removed then
                pcall(card_eval_status_text, card, "extra", nil, nil, nil, { message = text, colour = colour or G.C.FILTER })
            end
            return true
        end
    }))
end

----------------------------------------------------------------
-- HOOKS: Enterprise / Hornet can be protected from destruction
--  * North Carolina: Enterprise can't be destroyed by anything.
--  * Yorktown: if Enterprise or Hornet would be destroyed, Yorktown is destroyed instead.
-- Selling is not destruction (Card:sell_card marks the card first).
----------------------------------------------------------------
local sell_card_ref = Card.sell_card
function Card:sell_card(...)
    self.ocafe_selling = true
    return sell_card_ref(self, ...)
end

-- true = this destruction is cancelled
local function intercept(card)
    local center = card and card.config and card.config.center
    if not center or (center.key ~= ENTERPRISE and center.key ~= HORNET) then return false end
    if card.ocafe_selling or card.ocafe_forced or card.area ~= G.jokers then return false end

    if center.key == ENTERPRISE and owns(CAROLINA) then
        card.getting_sliced, card.destroyed = nil, nil
        card:juice_up(0.3, 0.4)
        say(card, "Unsinkable!", G.C.BLUE)
        return true
    end

    for _, y in ipairs(SMODS.find_card(YORKTOWN)) do
        if y ~= card and not y.getting_sliced then
            card.getting_sliced, card.destroyed = nil, nil
            y.getting_sliced = true
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.3,
                func = function()
                    play_sound("tarot1")
                    y:start_dissolve()
                    return true
                end
            }))
            say(card, "Yorktown sacrifices!", G.C.RED)
            return true
        end
    end
    return false
end

local start_dissolve_ref = Card.start_dissolve
function Card:start_dissolve(...)
    if intercept(self) then return end
    return start_dissolve_ref(self, ...)
end

if SMODS.destroy_cards then
    local destroy_cards_ref = SMODS.destroy_cards
    SMODS.destroy_cards = function(cards, ...)
        local list = cards
        if type(cards) == "table" and cards.is and cards:is(Card) then list = { cards } end
        if type(list) ~= "table" then return destroy_cards_ref(cards, ...) end
        local keep, changed = {}, false
        for _, c in ipairs(list) do
            if intercept(c) then changed = true else keep[#keep + 1] = c end
        end
        if not changed then return destroy_cards_ref(cards, ...) end
        if #keep == 0 then return keep end
        return destroy_cards_ref(keep, ...)
    end
end

----------------------------------------------------------------
-- THE SHIPS
-- scale(card)  -> multiplier applied to the ship's base Chips and Mult
-- xmult(card)  -> real X Mult (Yorktown only)
----------------------------------------------------------------
local DEFS = {}

local function stats(card)
    local d = DEFS[card.config.center.key]
    local s = d.scale and d.scale(card) or 1
    local x = d.xmult and d.xmult(card) or 1
    return BASE_CHIPS * s + (d.bonus_chips or 0), BASE_MULT * s, x
end

local function ship(d)
    DEFS[jk(d.id)] = d
    local text = { "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult" }
    for _, line in ipairs(d.text) do text[#text + 1] = line end
    text[#text + 1] = "{C:inactive}(Eagle Union)"

    SMODS.Joker {
        key = d.id,
        atlas = "jokers",
        pos = { x = d.x, y = 0 },
        rarity = d.rarity,
        cost = d.cost,
        blueprint_compat = true,
        config = { extra = { asleep = false, ghost = 1 } },
        loc_txt = { name = d.name, text = text },
        loc_vars = function(self, info_queue, card)
            if d.info then
                local c = G.P_CENTERS[d.info]
                if c then info_queue[#info_queue + 1] = c end
            end
            -- tooltips and collection previews pass a stub card without `config`, so fall back to the definition
            local real = card and card.config and card.config.center
            local c = real and card or { config = { center = self }, ability = { extra = self.config.extra } }
            local ex = (c.ability and c.ability.extra) or self.config.extra
            local chips, mult, x = stats(c)
            local status = ex.asleep and "Asleep, Zzz..." or "Awake"
            local vars = { chips, mult, x, status }
            vars[9] = ex.ghost or 1
            if d.odds_a then
                vars[5], vars[6] = SMODS.get_probability_vars(c, 1, d.odds_a, "ocafe_" .. d.id .. "_a")
            end
            if d.odds_b then
                vars[7], vars[8] = SMODS.get_probability_vars(c, 1, d.odds_b, "ocafe_" .. d.id .. "_b")
            end
            return { vars = vars }
        end,
        calculate = function(self, card, context)
            if d.on_calc then
                local r = d.on_calc(card, context)
                if r then return r end
            end
            if context.joker_main then
                if card.ability.extra.asleep then return end
                local chips, mult, x = stats(card)
                local ret = { chips = chips, mult = mult }
                if x > 1 then ret.xmult = x end
                if d.on_main then ret = d.on_main(card, ret, chips, mult) or ret end
                return ret
            end
        end
    }
end

ship {
    id = "enterprise", name = "Enterprise", x = 41, rarity = 3, cost = 10,
    text = {
        "{C:attention}X" .. CARRIER_BASE_X .. "{} base stats per other Eagle Union",
        "{C:attention}Aircraft Carrier{} ({C:attention}Yorktown{}, {C:attention}Hornet{})",
        "{C:attention}X" .. ALONE_X .. "{} base stats if you own no other",
        "Eagle Union ship",
        "Cannot be destroyed while you own",
        "{C:attention}North Carolina",
        "{C:inactive}(Grey Ghost bonus: {C:attention}X#9#{C:inactive})",
    },
    scale = function(card)
        local ghost = (card.ability and card.ability.extra and card.ability.extra.ghost) or 1
        if count_in(SHIP_SET, card) == 0 then return ALONE_X * ghost end
        return CARRIER_BASE_X ^ count_in(CARRIER_SET, card) * ghost
    end
}

ship {
    id = "yorktown", name = "Yorktown", x = 42, rarity = 3, cost = 8,
    text = {
        "{X:mult,C:white}X" .. YORKTOWN_X .. "{} Mult per other Eagle Union",
        "{C:attention}Aircraft Carrier",
        "If {C:attention}Enterprise{} or {C:attention}Hornet{} would be",
        "{C:red}destroyed{}, sacrifice this Joker instead",
        "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
    },
    xmult = function(card) return YORKTOWN_X ^ count_in(CARRIER_SET, card) end
}

ship {
    id = "hornet", name = "Hornet", x = 43, rarity = 3, cost = 8,
    info = INDUSTRIAL_KEY,
    text = {
        "{C:attention}X" .. HORNET_X .. "{} base stats per other Eagle Union Joker",
        "{C:green}#5# in #6#{} chance to create a {C:tarot}US Industrial",
        "{C:tarot}Power{} at end of round {C:inactive}(Must have room)",
    },
    odds_a = HORNET_ODDS,
    scale = function(card) return HORNET_X ^ count_in(SHIP_SET, card) end,
    on_calc = function(card, context)
        if context.end_of_round and context.main_eval and not context.game_over and not context.blueprint
            and consumable_room()
            and SMODS.pseudorandom_probability(card, "ocafe_hornet_a", 1, HORNET_ODDS, "ocafe_hornet_a") then
            G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
            G.E_MANAGER:add_event(Event({
                func = function()
                    SMODS.add_card { key = INDUSTRIAL_KEY }
                    G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                    return true
                end
            }))
            return { message = "Industry!", colour = G.C.SECONDARY_SET.Tarot }
        end
    end
}

ship {
    id = "new_jersey", name = "New Jersey", x = 44, rarity = 3, cost = 10,
    text = {
        "{C:attention}X" .. JERSEY_ALONE_X .. "{} base stats if you own no other Jokers",
        "{C:attention}X" .. JERSEY_PAIR_X .. "{} base stats if you own",
        "{C:attention}North Carolina{} or {C:attention}Washington",
    },
    scale = function(card)
        if G.jokers and #G.jokers.cards <= 1 then return JERSEY_ALONE_X end
        if owns(CAROLINA) or owns(WASHINGTON) then return JERSEY_PAIR_X end
        return 1
    end
}

ship {
    id = "north_carolina", name = "North Carolina", x = 45, rarity = 3, cost = 8,
    text = {
        "{C:attention}X" .. NC_X .. "{} base stats if you own {C:attention}Washington",
        "While you own this, {C:attention}Enterprise",
        "can't be {C:red}destroyed{} by anything",
    },
    scale = function(card) return owns(WASHINGTON) and NC_X or 1 end
}

ship {
    id = "washington", name = "Washington", x = 46, rarity = 3, cost = 8,
    text = {
        "{C:attention}X" .. WASH_PAIR_X .. "{} base stats with {C:attention}New Jersey{} or",
        "{C:attention}North Carolina{}, {C:attention}X" .. WASH_BOTH_X .. "{} with both",
    },
    scale = function(card)
        local nj, nc = owns(JERSEY), owns(CAROLINA)
        if nj and nc then return WASH_BOTH_X end
        if nj or nc then return WASH_PAIR_X end
        return 1
    end
}

ship {
    id = "laffey", name = "Laffey", x = 14, rarity = 2, cost = 5,
    odds_a = LAFFEY_SLEEP_ODDS, odds_b = LAFFEY_X2_ODDS,
    text = {
        "{C:green}#5# in #6#{} chance to fall asleep and do",
        "nothing for the round",
        "{C:green}#7# in #8#{} chance to {C:attention}X2{} her stats when she scores",
        "{C:inactive}(#4#)",
    },
    on_calc = function(card, context)
        if context.blueprint then return end
        if context.setting_blind and not card.ability.extra.asleep
            and SMODS.pseudorandom_probability(card, "ocafe_laffey_a", 1, LAFFEY_SLEEP_ODDS, "ocafe_laffey_a") then
            card.ability.extra.asleep = true
            return { message = "Zzz...", colour = G.C.BLUE }
        end
        if context.end_of_round and context.main_eval and card.ability.extra.asleep then
            card.ability.extra.asleep = false
            return { message = "Awake!", colour = G.C.FILTER }
        end
    end,
    on_main = function(card, ret, chips, mult)
        if SMODS.pseudorandom_probability(card, "ocafe_laffey_b", 1, LAFFEY_X2_ODDS, "ocafe_laffey_b") then
            return { message = "X2!", colour = G.C.GOLD, extra = { chips = chips * 2, mult = mult * 2 } }
        end
    end
}

ship {
    id = "fletcher", name = "Fletcher", x = 2, rarity = 1, cost = 4,
    bonus_chips = FLETCHER_BONUS,
    text = { "{C:chips}+" .. FLETCHER_BONUS .. "{} more Chips" },
}

----------------------------------------------------------------
-- TAROTS
----------------------------------------------------------------
SMODS.Consumable {
    key = "construction_eu",
    set = "Tarot",
    atlas = "tarots",
    pos = { x = 1, y = 0 },
    cost = 3,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Construction (EU)",
        text = {
            "Creates a random {C:attention}Eagle Union",
            "{C:attention}Azur Lane{} Joker",
            "{C:inactive}(Must have room)"
        }
    },
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards < G.jokers.config.card_limit
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                local keys = {}
                for _, id in ipairs(SHIP_IDS) do keys[#keys + 1] = jk(id) end
                play_sound("timpani")
                SMODS.add_card { key = pseudorandom_element(keys, pseudoseed("ocafe_construction")) }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

SMODS.Consumable {
    key = "us_industrial_power",
    set = "Tarot",
    atlas = "tarots",
    pos = { x = 2, y = 0 },
    cost = 4,
    cursed_coin_immune = true,
    loc_txt = {
        name = "US Industrial Power",
        text = {
            "Summons a {C:dark_edition}Negative{} {C:attention}Fletcher"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        info_queue[#info_queue + 1] = G.P_CENTERS[FLETCHER]
        return {}
    end,
    can_use = function(self, card)
        return G.jokers ~= nil
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = FLETCHER, edition = "e_negative" }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

-- Grey Ghost (spectral): sacrifices the other carriers to power up Enterprise
SMODS.Consumable {
    key = "grey_ghost",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 4, y = 0 },
    cost = 4,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Grey Ghost",
        text = {
            "{C:red}Destroys{} every Eagle Union {C:attention}Aircraft Carrier",
            "except {C:attention}Enterprise{} ({C:attention}Yorktown{}, {C:attention}Hornet{})",
            "In return, {C:attention}Enterprise{}'s stats get {C:attention}X" .. GHOST_X,
            "{C:inactive}(Does nothing if there are no other Carriers)",
            "{C:inactive}(Needs Enterprise)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[ENTERPRISE]
        return {}
    end,
    in_pool = function(self, args)
        return owns(ENTERPRISE)
    end,
    can_use = function(self, card)
        return G.jokers ~= nil and next(SMODS.find_card(ENTERPRISE)) ~= nil
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                local carriers, enterprises = {}, {}
                for _, j in ipairs(G.jokers.cards) do
                    local k = j.config.center.key
                    if not j.getting_sliced then
                        if k == YORKTOWN or k == HORNET then carriers[#carriers + 1] = j end
                        if k == ENTERPRISE then enterprises[#enterprises + 1] = j end
                    end
                end
                if #carriers == 0 or #enterprises == 0 then
                    card:juice_up(0.3, 0.3)
                    say(enterprises[1] or card, "Nothing to sacrifice", G.C.UI.TEXT_INACTIVE)
                    return true
                end
                play_sound("tarot1")
                card:juice_up(0.3, 0.5)
                for _, c in ipairs(carriers) do
                    c.ocafe_forced = true        -- Yorktown's sacrifice rule must not catch this
                    c.getting_sliced = true
                    c:start_dissolve()
                    say(c, "Sacrificed!", G.C.RED)
                end
                for _, e in ipairs(enterprises) do
                    e.ability.extra.ghost = (e.ability.extra.ghost or 1) * GHOST_X
                    e:juice_up(0.6, 0.6)
                    say(e, "Grey Ghost! X" .. e.ability.extra.ghost, G.C.GOLD)
                end
                return true
            end
        }))
        delay(0.6)
    end
}

----------------------------------------------------------------
-- KAMIKAZE
-- Every hand played: 1 in 5 that a random Ship Joker (any Azur Lane Joker or USS Wichita) is hit.
-- A hit debuffs it until a Boss Blind is beaten; 1 in 10 hits destroy it instead.
--  * Uses plain random numbers, so probability Jokers (Oops! All 6s, Las Vegas, Coin Flip...) don't change it.
--  * Destruction goes through the normal rules: North Carolina still protects Enterprise, Yorktown still
--    sacrifices herself for Hornet / Enterprise, Eternal Jokers are debuffed instead.
--  * A hit shows a big KAMIKAZE! banner, shakes the screen, and the Joker keeps a red KAMIKAZE tag
--    for as long as it is debuffed.
----------------------------------------------------------------
local WICHITA = "j_ocafe_uss_wichita"

local function is_ship(card)
    local key = card and card.config and card.config.center and card.config.center.key
    return key and (SHIP_SET[key] or key == WICHITA)
end

-- the debuff sticks no matter what recalculates the Joker's debuff
local set_debuff_ref = Card.set_debuff
function Card:set_debuff(should_debuff)
    if self.ability and self.ability.ocafe_kamikaze then should_debuff = true end
    return set_debuff_ref(self, should_debuff)
end

local function banner(text, colour)
    pcall(function()
        attention_text({
            text = text, scale = 1.4, hold = 1.6, align = "cm",
            offset = { x = 0, y = -2.2 }, major = G.play or G.ROOM_ATTACH, colour = colour or G.C.RED
        })
    end)
    pcall(function() G.ROOM.jiggle = (G.ROOM.jiggle or 0) + 2.5 end)
end

local function kamikaze_roll()
    if not G.jokers then return end
    local pool = {}
    for _, j in ipairs(G.jokers.cards) do
        if is_ship(j) and not j.ability.ocafe_kamikaze and not j.getting_sliced then pool[#pool + 1] = j end
    end
    if #pool == 0 then return end
    if pseudorandom("ocafe_kamikaze") >= 1 / KAMIKAZE_ODDS then return end

    local target = pseudorandom_element(pool, pseudoseed("ocafe_kamikaze_pick"))
    local kill = pseudorandom("ocafe_kamikaze_kill") < 1 / KAMIKAZE_KILL_ODDS and not target.ability.eternal

    -- takes effect right away, so the ship does not score this hand
    target.ability.ocafe_kamikaze = true
    target:set_debuff(true)

    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.2,
        func = function()
            play_sound("cancel", 0.7, 1)
            play_sound("tarot2", 0.6, 0.8)
            banner("KAMIKAZE!", G.C.RED)
            return true
        end
    }))
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.5,
        func = function()
            if target.removed then return true end
            target:juice_up(1, 1)
            if kill then
                say(target, "DIRECT HIT!", G.C.RED)
                if SMODS.destroy_cards then
                    SMODS.destroy_cards(target)
                else
                    target.getting_sliced = true
                    target:start_dissolve()
                end
                -- protected (North Carolina / Yorktown): it only gets the debuff
            else
                say(target, "Kamikaze hit!", G.C.RED)
            end
            return true
        end
    }))
end

local function kamikaze_clear()
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if j.ability and j.ability.ocafe_kamikaze then
            j.ability.ocafe_kamikaze = nil
            j:set_debuff(false)
            j:juice_up(0.4, 0.4)
            say(j, "Repaired!", G.C.GREEN)
        end
    end
end

-- once per hand, before scoring
local calculate_context_ref = SMODS.calculate_context
SMODS.calculate_context = function(context, ...)
    if type(context) == "table" and context.before and context.full_hand and context.scoring_hand
        and not context.blueprint then
        kamikaze_roll()
    end
    return calculate_context_ref(context, ...)
end

-- beating a Boss Blind repairs everything
local defeat_ref = Blind.defeat
function Blind:defeat(...)
    if self.boss then kamikaze_clear() end
    return defeat_ref(self, ...)
end

-- red KAMIKAZE tag on a hit Joker (also rebuilt after loading a save)
local card_update_ref = Card.update
function Card:update(dt)
    card_update_ref(self, dt)
    local hit = self.ability and self.ability.ocafe_kamikaze and not self.removed and not self.getting_sliced
    local tag = self.children and self.children.ocafe_kamikaze
    if hit and not tag and self.area == G.jokers then
        self.children.ocafe_kamikaze = UIBox {
            definition = {
                n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR },
                nodes = { { n = G.UIT.R, config = { align = "cm", r = 0.1, padding = 0.06, colour = G.C.RED, emboss = 0.05 }, nodes = {
                    { n = G.UIT.T, config = { text = "KAMIKAZE", scale = 0.34, colour = G.C.WHITE, shadow = true } }
                } } }
            },
            config = { align = "cm", offset = { x = 0, y = -self.T.h * 0.12 }, major = self, parent = self }
        }
    elseif tag and not hit then
        tag:remove()
        self.children.ocafe_kamikaze = nil
    end
end

----------------------------------------------------------------
-- BLINDS (art: the shared blinds.png declared in main.lua, one row per Blind)
--   The Siren's Curse  (y=1): No Ship Jokers allowed. Every Ship Joker is debuffed.
--   The Fleet Training (y=2): Only Ship Jokers allowed. Every other Joker is debuffed. It can only show up
--                             when you own a Ship Joker, and its requirement is X0.5 instead of X2.
-- "Ship Joker" is the same set Kamikaze hits (every Azur Lane Joker plus USS Wichita).
-- Debuffs are lifted again when the Blind is beaten or disabled (Chicot, Luchador).
----------------------------------------------------------------
local function owns_ship()
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if is_ship(j) then return true end
    end
    return false
end

-- Chicot / Luchador: put every Joker's debuff back to normal once the Blind is switched off
local function refresh_joker_debuffs()
    G.E_MANAGER:add_event(Event({
        func = function()
            for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
                pcall(function() G.GAME.blind:debuff_card(j) end)
            end
            return true
        end
    }))
end

SMODS.Blind {
    key = "siren_curse",
    atlas = "blinds",
    pos = { x = 0, y = 1 },
    boss = { min = 1 },
    boss_colour = HEX("5B2A86"),
    mult = 2,
    dollars = 5,
    loc_txt = {
        name = "The Siren's Curse",
        text = {
            "No Ship Jokers",
            "allowed",
        },
    },
    recalc_debuff = function(self, card, from_blind)
        return card.area == G.jokers and is_ship(card) and true or false
    end,
    disable = refresh_joker_debuffs,
}

SMODS.Blind {
    key = "fleet_training",
    atlas = "blinds",
    pos = { x = 0, y = 2 },
    boss = { min = 1 },
    boss_colour = HEX("2B5FA8"),
    mult = 0.5,
    dollars = 5,
    loc_txt = {
        name = "The Fleet Training",
        text = {
            "Only Ship Jokers",
            "allowed",
        },
    },
    -- only rolled while a Ship Joker is owned
    in_pool = function(self)
        return owns_ship()
    end,
    recalc_debuff = function(self, card, from_blind)
        return card.area == G.jokers and not is_ship(card) and true or false
    end,
    disable = refresh_joker_debuffs,
}
