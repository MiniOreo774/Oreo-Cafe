-- Girls und Panzer content for Oreo Cafe Balatro (loaded from main.lua)
--   Enhancement: m_ocafe_plot_armor
--   Tarots:      c_ocafe_panzer_vor, c_ocafe_production
--   Jokers:      j_ocafe_ + miho, mako, yukari, saori, hana, maho, erika, kay, anchovy,
--                pepperoni, l3_33, katyusha, nonna, darjeeling, rosehip, crusader_iii
-- Art: the Jokers live in jokers.png (sorted by rarity, see main.lua). gup_tarots.png (x=0 Panzer Vor!,
--      x=1 Production) and gup_enhancements.png (x=0 Plot Armor). The GuP art is placeholder.

----------------------------------------------------------------
-- ATLASES
----------------------------------------------------------------
SMODS.Atlas { key = "gup_tarots",       path = "gup_tarots.png",       px = 71, py = 95 }
SMODS.Atlas { key = "gup_enhancements", path = "gup_enhancements.png", px = 71, py = 95 }

----------------------------------------------------------------
-- TUNING KNOBS
----------------------------------------------------------------
local CREW_XMULT = 1.5        -- X Mult per OTHER Anglerfish Crew member owned
local ARMOR_ODDS = 15         -- Miho / Crusader III: 1 in 15 Plot Armor
local PRODUCTION_ODDS = 15    -- Yukari: 1 in 15 Production Tarot (per hand played)
local PEPPERONI_ODDS = 15     -- Pepperoni: 1 in 15 Negative L3/33 (per round)
local ROSEHIP_ODDS = 25       -- Rosehip: 1 in 25 Crusader III (per round)
local DARJEELING_ODDS = 10    -- Darjeeling: 1 in 10 for non-allied GuP cards to count as allied
local KATYUSHA_LOSS = 0.2     -- Katyusha loses this much X Mult per round without Nonna
local ERIKA_XMULT = 1.2       -- Erika: X Mult per scoring Camo Card

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local PLOT_KEY = "m_ocafe_plot_armor"
local CAMO_KEY = "m_ocafe_camo"
local METEOR_KEY = "m_ocafe_meteor"
local PRODUCTION_KEY = "c_ocafe_production"

local function jk(id) return "j_ocafe_" .. id end

local function to_set(ids)
    local s = {}
    for _, id in ipairs(ids) do s[jk(id)] = true end
    return s
end

local CREW_IDS = { "miho", "mako", "yukari", "saori", "hana" }
local ALL_GUP_IDS = {
    "miho", "mako", "yukari", "saori", "hana", "maho", "erika", "kay", "anchovy",
    "pepperoni", "l3_33", "katyusha", "nonna", "darjeeling", "rosehip", "crusader_iii",
}
local VEHICLE_KEYS = { "j_ocafe_uss_wichita", jk("l3_33"), jk("crusader_iii") }

local CREW_SET = to_set(CREW_IDS)
local ALL_GUP_SET = to_set(ALL_GUP_IDS)
local KAY_ALLIES = to_set({ "katyusha", "nonna", "darjeeling", "rosehip" })
local DARJEELING_ALLIES = to_set({ "kay", "katyusha", "nonna", "rosehip" })

local function has_center_key(card, key)
    return card and card.config and card.config.center and card.config.center.key == key
end

local function owns(key)
    return G.jokers ~= nil and next(SMODS.find_card(key)) ~= nil
end

-- number of owned Jokers (not debuffed, not `except`) whose key is in `set`
local function count_in(set, except)
    local n = 0
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if j ~= except and not j.debuff and set[j.config.center.key] then n = n + 1 end
    end
    return n
end

local function r2(x) return math.floor(x * 100 + 0.5) / 100 end

local function joker_room()
    return G.jokers and (#G.jokers.cards + (G.GAME.joker_buffer or 0)) < G.jokers.config.card_limit
end

local function consumable_room(card)
    return G.consumeables and (
        (card and card.area == G.consumeables)
        or (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0)) < G.consumeables.config.card_limit)
end

-- create a Joker or consumable on the next event tick (reserves the slot first)
local function spawn_joker(key, edition)
    if not edition then G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1 end
    G.E_MANAGER:add_event(Event({
        func = function()
            SMODS.add_card { key = key, edition = edition }
            if not edition then G.GAME.joker_buffer = math.max(0, (G.GAME.joker_buffer or 1) - 1) end
            return true
        end
    }))
end

local function spawn_consumable(key)
    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        func = function()
            SMODS.add_card { key = key }
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
            return true
        end
    }))
end

----------------------------------------------------------------
-- PLOT ARMOR: survives being destroyed once, then the enhancement is used up
----------------------------------------------------------------
local function spend_plot_armor(card)
    card.getting_sliced, card.destroyed, card.shattered = nil, nil, nil
    card:set_ability(G.P_CENTERS.c_base, nil, true)
    G.E_MANAGER:add_event(Event({
        func = function()
            card:juice_up(0.4, 0.5)
            play_sound("tarot2", 0.9, 0.6)
            pcall(card_eval_status_text, card, "extra", nil, nil, nil,
                { message = "Plot Armor!", colour = G.C.GOLD })
            return true
        end
    }))
end

-- fallback for any destruction path that doesn't go through SMODS.destroy_cards
local gup_start_dissolve_ref = Card.start_dissolve
function Card:start_dissolve(...)
    if has_center_key(self, PLOT_KEY) then
        spend_plot_armor(self)
        return
    end
    return gup_start_dissolve_ref(self, ...)
end

local gup_shatter_ref = Card.shatter
function Card:shatter(...)
    if has_center_key(self, PLOT_KEY) then
        spend_plot_armor(self)
        return
    end
    return gup_shatter_ref(self, ...)
end

if SMODS.destroy_cards then
    local destroy_cards_ref = SMODS.destroy_cards
    SMODS.destroy_cards = function(cards, ...)
        local list = cards
        if type(cards) == "table" and cards.is and cards:is(Card) then list = { cards } end
        if type(list) ~= "table" then return destroy_cards_ref(cards, ...) end

        local keep, protected = {}, false
        for _, c in ipairs(list) do
            if has_center_key(c, PLOT_KEY) then
                protected = true
                spend_plot_armor(c)
            else
                keep[#keep + 1] = c
            end
        end
        if not protected then return destroy_cards_ref(cards, ...) end
        if #keep == 0 then return keep end
        return destroy_cards_ref(keep, ...)
    end
end

SMODS.Enhancement {
    key = "plot_armor",
    atlas = "gup_enhancements",
    pos = { x = 0, y = 0 },
    loc_txt = {
        name = "Plot Armor",
        text = {
            "Protects this card from being",
            "{C:attention}destroyed{} {C:attention}1{} time, then",
            "this enhancement is {C:red}destroyed"
        }
    }
}

-- Put Plot Armor on a random card of the played hand (Miho, Crusader III)
local function try_plot_armor(card, context, seed, odds)
    if not (context.full_hand and #context.full_hand > 0) then return end
    if not SMODS.pseudorandom_probability(card, seed, 1, odds, seed) then return end
    local pool = {}
    for _, c in ipairs(context.full_hand) do
        if not c.removed and not c.getting_sliced and not c.destroyed
            and not has_center_key(c, PLOT_KEY) and not has_center_key(c, METEOR_KEY) then
            pool[#pool + 1] = c
        end
    end
    if #pool == 0 then return end
    local target = pseudorandom_element(pool, pseudoseed(seed .. "_pick"))
    target:set_ability(G.P_CENTERS[PLOT_KEY], nil, true)
    G.E_MANAGER:add_event(Event({
        func = function()
            target:juice_up(0.3, 0.5)
            return true
        end
    }))
    return { message = "Plot Armor!", colour = G.C.GOLD }
end

----------------------------------------------------------------
-- ANGLERFISH CREW  (Miho, Mako, Yukari, Saori, Hana)
-- All five give +Chips, +Mult and X1.5 Mult per OTHER crew member owned.
----------------------------------------------------------------
local function crew_joker(a)
    local text = {
        "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult",
        "{X:mult,C:white}X#3#{} Mult per other {C:attention}Anglerfish Crew",
        "{C:inactive}(Miho, Mako, Yukari, Saori, Hana)",
    }
    for _, line in ipairs(a.extra_text or {}) do text[#text + 1] = line end
    text[#text + 1] = "{C:inactive}(Currently {X:mult,C:white}X#4#{C:inactive} Mult)"

    SMODS.Joker {
        key = a.id,
        atlas = "jokers",
        pos = { x = a.x, y = 0 },
        rarity = a.rarity,
        cost = a.cost,
        blueprint_compat = true,
        config = { extra = { chips = a.chips, mult = a.mult, odds = a.odds } },
        loc_txt = { name = a.name, text = text },
        loc_vars = function(self, info_queue, card)
            if a.info then
                local c = G.P_CENTERS[a.info]
                if c then info_queue[#info_queue + 1] = c end
            end
            local ex = card.ability.extra
            local n, d = 1, ex.odds or 1
            if ex.odds then n, d = SMODS.get_probability_vars(card, 1, ex.odds, "ocafe_" .. a.id) end
            return { vars = { ex.chips, ex.mult, CREW_XMULT, r2(CREW_XMULT ^ count_in(CREW_SET, card)), n, d } }
        end,
        calculate = function(self, card, context)
            if context.before and a.on_before then
                return a.on_before(card, context)
            end
            if context.joker_main then
                local ex = card.ability.extra
                local ret = { chips = ex.chips, mult = ex.mult }
                local n = count_in(CREW_SET, card)
                if n > 0 then ret.xmult = CREW_XMULT ^ n end
                if a.on_main then a.on_main(card, ret) end
                return ret
            end
        end
    }
end

crew_joker {
    id = "miho", name = "Miho", x = 32, rarity = 3, cost = 8, chips = 50, mult = 10, odds = ARMOR_ODDS,
    info = PLOT_KEY,
    extra_text = {
        "{C:green}#5# in #6#{} chance to give a random",
        "played card {C:attention}Plot Armor",
    },
    on_before = function(card, context)
        return try_plot_armor(card, context, "ocafe_miho_armor", card.ability.extra.odds)
    end
}

crew_joker {
    id = "mako", name = "Mako", x = 6, rarity = 2, cost = 5, chips = 50, mult = 5,
}

crew_joker {
    id = "yukari", name = "Yukari", x = 7, rarity = 2, cost = 5, chips = 50, mult = 5, odds = PRODUCTION_ODDS,
    info = PRODUCTION_KEY,
    extra_text = {
        "{C:green}#5# in #6#{} chance to create a",
        "{C:tarot}Production{} Tarot each hand",
        "{C:inactive}(Must have room)",
    },
    on_main = function(card, ret)
        if consumable_room() and SMODS.pseudorandom_probability(card, "ocafe_yukari", 1, card.ability.extra.odds, "ocafe_yukari") then
            spawn_consumable(PRODUCTION_KEY)
            ret.extra = { message = "Production!", colour = G.C.SECONDARY_SET.Tarot }
        end
    end
}

crew_joker {
    id = "saori", name = "Saori", x = 8, rarity = 2, cost = 5, chips = 50, mult = 5,
}

crew_joker {
    id = "hana", name = "Hana", x = 9, rarity = 2, cost = 5, chips = 50, mult = 5,
}

----------------------------------------------------------------
-- OTHER JOKERS
----------------------------------------------------------------
SMODS.Joker {
    key = "maho",
    atlas = "jokers",
    pos = { x = 33, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    config = { extra = { mult = 15, bonus = 50 } },
    loc_txt = {
        name = "Maho",
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:mult}+#2#{} more Mult if you also own {C:attention}Miho",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        return { vars = { ex.mult, ex.bonus, ex.mult + (owns(jk("miho")) and ex.bonus or 0) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            return { mult = ex.mult + (owns(jk("miho")) and ex.bonus or 0) }
        end
    end
}

SMODS.Joker {
    key = "erika",
    atlas = "jokers",
    pos = { x = 10, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    config = { extra = { chips = 25, mult = 5 } },
    loc_txt = {
        name = "Erika",
        text = {
            "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult",
            "{X:mult,C:white}X#3#{} Mult for each scoring",
            "{C:attention}Camo Card"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[CAMO_KEY]
        local ex = card.ability.extra
        return { vars = { ex.chips, ex.mult, ERIKA_XMULT } }
    end,
    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play
            and SMODS.has_enhancement(context.other_card, CAMO_KEY) then
            return { xmult = ERIKA_XMULT }
        end
        if context.joker_main then
            local ex = card.ability.extra
            return { chips = ex.chips, mult = ex.mult }
        end
    end
}

SMODS.Joker {
    key = "kay",
    atlas = "jokers",
    pos = { x = 11, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    config = { extra = { mult = 15 } },
    loc_txt = {
        name = "Kay",
        text = {
            "{C:mult}+#1#{} Mult, {C:attention}doubled{} for each",
            "allied card owned",
            "{C:inactive}(Katyusha, Nonna, Darjeeling, Rosehip)",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        return { vars = { ex.mult, ex.mult * 2 ^ count_in(KAY_ALLIES, card) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            return { mult = ex.mult * 2 ^ count_in(KAY_ALLIES, card) }
        end
    end
}

SMODS.Joker {
    key = "anchovy",
    atlas = "jokers",
    pos = { x = 34, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    config = { extra = { chips = 50, mult = 15 } },
    loc_txt = {
        name = "Anchovy",
        text = {
            "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult",
            "These stats are {C:attention}doubled{} for",
            "each {C:attention}L3/33{} you have",
            "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips, {C:mult}+#4#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("l3_33")]
        local ex = card.ability.extra
        local m = G.jokers and 2 ^ #SMODS.find_card(jk("l3_33")) or 1
        return { vars = { ex.chips, ex.mult, ex.chips * m, ex.mult * m } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            local m = 2 ^ #SMODS.find_card(jk("l3_33"))
            return { chips = ex.chips * m, mult = ex.mult * m }
        end
    end
}

SMODS.Joker {
    key = "pepperoni",
    atlas = "jokers",
    pos = { x = 12, y = 0 },
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    config = { extra = { chips = 50, odds = PEPPERONI_ODDS } },
    loc_txt = {
        name = "Pepperoni",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:green}#2# in #3#{} chance at end of round",
            "to create a {C:dark_edition}Negative{} {C:attention}L3/33"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("l3_33")]
        local ex = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, ex.odds, "ocafe_pepperoni")
        return { vars = { ex.chips, n, d } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
        if context.end_of_round and context.main_eval and not context.game_over then
            if SMODS.pseudorandom_probability(card, "ocafe_pepperoni", 1, card.ability.extra.odds, "ocafe_pepperoni") then
                spawn_joker(jk("l3_33"), "e_negative")
                return { message = "L3/33!", colour = G.C.FILTER }
            end
        end
    end
}

-- Vehicle: only obtainable from Rosehip, Pepperoni, Production and Panzer Vor!
SMODS.Joker {
    key = "l3_33",
    atlas = "jokers",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 2,
    blueprint_compat = true,
    config = { extra = { chips = 10, mult = 2 } },
    in_pool = function(self, args) return false end,
    loc_txt = {
        name = "L3/33",
        text = { "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult" }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        return { vars = { ex.chips, ex.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            return { chips = ex.chips, mult = ex.mult }
        end
    end
}

SMODS.Joker {
    key = "katyusha",
    atlas = "jokers",
    pos = { x = 35, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    config = { extra = { xmult = 3, loss = KATYUSHA_LOSS, floor = 1 } },
    loc_txt = {
        name = "Katyusha",
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "Loses {X:mult,C:white}X#2#{} Mult at end of round",
            "if you don't own {C:attention}Nonna"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("nonna")]
        local ex = card.ability.extra
        return { vars = { ex.xmult, ex.loss } }
    end,
    calculate = function(self, card, context)
        local ex = card.ability.extra
        if context.joker_main and ex.xmult > 1 then
            return { xmult = ex.xmult }
        end
        if context.end_of_round and context.main_eval and not context.game_over and not context.blueprint then
            if not owns(jk("nonna")) and ex.xmult > ex.floor then
                ex.xmult = math.max(ex.floor, r2(ex.xmult - ex.loss))
                return { message = "-X" .. ex.loss, colour = G.C.RED }
            end
        end
    end
}

SMODS.Joker {
    key = "nonna",
    atlas = "jokers",
    pos = { x = 13, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    config = { extra = { chips = 100, mult = 10 } },
    loc_txt = {
        name = "Nonna",
        text = { "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult" }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        return { vars = { ex.chips, ex.mult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            return { chips = ex.chips, mult = ex.mult }
        end
    end
}

SMODS.Joker {
    key = "darjeeling",
    atlas = "jokers",
    pos = { x = 36, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    config = { extra = { mult = 15, odds = DARJEELING_ODDS } },
    loc_txt = {
        name = "Darjeeling",
        text = {
            "{C:mult}+#1#{} Mult, {C:attention}doubled{} for each",
            "allied card owned",
            "{C:inactive}(Kay, Katyusha, Nonna, Rosehip)",
            "{C:green}#3# in #4#{} chance for any other",
            "{C:attention}Girls und Panzer{} Joker to count too",
            "{C:inactive}(Allies alone: {C:mult}+#2#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, ex.odds, "ocafe_darjeeling")
        return { vars = { ex.mult, ex.mult * 2 ^ count_in(DARJEELING_ALLIES, card), n, d } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            local allies = count_in(DARJEELING_ALLIES, card)
            -- every other GuP Joker that isn't an ally gets its own roll
            for _, j in ipairs(G.jokers.cards) do
                local key = j.config.center.key
                if j ~= card and not j.debuff and ALL_GUP_SET[key] and not DARJEELING_ALLIES[key] then
                    if SMODS.pseudorandom_probability(card, "ocafe_darjeeling", 1, ex.odds, "ocafe_darjeeling") then
                        allies = allies + 1
                    end
                end
            end
            return { mult = ex.mult * 2 ^ allies }
        end
    end
}

SMODS.Joker {
    key = "rosehip",
    atlas = "jokers",
    pos = { x = 37, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    config = { extra = { chips = 300, odds = ROSEHIP_ODDS } },
    loc_txt = {
        name = "Rosehip",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:green}#2# in #3#{} chance at end of round",
            "to create a {C:attention}Crusader III",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("crusader_iii")]
        local ex = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, ex.odds, "ocafe_rosehip")
        return { vars = { ex.chips, n, d } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return { chips = card.ability.extra.chips }
        end
        if context.end_of_round and context.main_eval and not context.game_over and joker_room() then
            if SMODS.pseudorandom_probability(card, "ocafe_rosehip", 1, card.ability.extra.odds, "ocafe_rosehip") then
                spawn_joker(jk("crusader_iii"))
                return { message = "Crusader!", colour = G.C.FILTER }
            end
        end
    end
}

-- Vehicle: only obtainable from Rosehip, Production and Panzer Vor!
SMODS.Joker {
    key = "crusader_iii",
    atlas = "jokers",
    pos = { x = 1, y = 0 },
    rarity = 1,
    cost = 3,
    blueprint_compat = true,
    config = { extra = { mult = 5, odds = ARMOR_ODDS } },
    in_pool = function(self, args) return false end,
    loc_txt = {
        name = "Crusader III",
        text = {
            "{C:mult}+#1#{} Mult",
            "{C:green}#2# in #3#{} chance to give a random",
            "played card {C:attention}Plot Armor"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[PLOT_KEY]
        local ex = card.ability.extra
        local n, d = SMODS.get_probability_vars(card, 1, ex.odds, "ocafe_crusader_armor")
        return { vars = { ex.mult, n, d } }
    end,
    calculate = function(self, card, context)
        if context.before then
            return try_plot_armor(card, context, "ocafe_crusader_armor", card.ability.extra.odds)
        end
        if context.joker_main then
            return { mult = card.ability.extra.mult }
        end
    end
}

----------------------------------------------------------------
-- TAROTS
----------------------------------------------------------------
SMODS.Consumable {
    key = "production",
    set = "Tarot",
    atlas = "gup_tarots",
    pos = { x = 1, y = 0 },
    cost = 3,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Production",
        text = {
            "Creates a random vehicle",
            "{C:inactive}(USS Wichita, L3/33, Crusader III)",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.j_ocafe_uss_wichita
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("l3_33")]
        info_queue[#info_queue + 1] = G.P_CENTERS[jk("crusader_iii")]
        return {}
    end,
    can_use = function(self, card)
        return joker_room() and true or false
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = pseudorandom_element(VEHICLE_KEYS, pseudoseed("ocafe_production")) }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

SMODS.Consumable {
    key = "panzer_vor",
    set = "Tarot",
    atlas = "gup_tarots",
    pos = { x = 0, y = 0 },
    cost = 4,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Panzer Vor!",
        text = {
            "Creates a random {C:attention}Girls und Panzer",
            "Joker or Tarot",
            "{C:inactive}(Except this one, must have room)"
        }
    },
    can_use = function(self, card)
        return (joker_room() or consumable_room(card)) and true or false
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                -- the used Tarot has already left its slot, so plain counts are right here
                local pool = {}
                if G.jokers and #G.jokers.cards < G.jokers.config.card_limit then
                    for _, id in ipairs(ALL_GUP_IDS) do pool[#pool + 1] = jk(id) end
                end
                if G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                    pool[#pool + 1] = PRODUCTION_KEY
                end
                if #pool > 0 then
                    play_sound("timpani")
                    SMODS.add_card { key = pseudorandom_element(pool, pseudoseed("ocafe_panzer_vor")) }
                end
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}
