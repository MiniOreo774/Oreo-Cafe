-- Backlash, Optimist and Clown Car (loaded from main.lua)
--
--   Backlash  (Rare): whenever a probability FAILS, destroy the card that triggered it and gain X1 Mult
--   Optimist  (Rare): whenever a probability FAILS, gain X1 Chips
--   Clown Car (Rare): end of round: 50% two Negative Common Jokers / 50% one Negative Uncommon Joker.
--                     1 in 50 to self destruct, +1 to the numerator for every Joker it has created
--
-- "Fails" means a roll that goes through Steamodded's probability system (same rule as Cursed Coin),
-- judged AFTER every other modifier, so Bonus Coin's forced failures count too. This file is loaded last
-- from main.lua so its hook wraps the Bonus Coin and Cursed Coin hooks.
--
-- Art: jokers.png (sorted by rarity, see main.lua) -> x=38 Backlash | x=39 Optimist | x=40 Clown Car

local BACKLASH_KEY = "j_ocafe_backlash"
local OPTIMIST_KEY = "j_ocafe_optimist"

-- destroy a Joker that used itself up (same as main.lua)
local function self_destruct(card)
    card.getting_sliced = true
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.3,
        func = function()
            play_sound("tarot1")
            card:start_dissolve()
            return true
        end
    }))
end

-- same rules as Cursed Coin: Jokers and playing cards only, never Red Antiseptic Cards,
-- never anything marked cursed_coin_immune (Mini Oreo, consumables, ...)
local function can_destroy(obj)
    if type(obj) ~= "table" or not obj.is or not obj:is(Card) then return false end
    if obj.ocafe_doomed or obj.getting_sliced then return false end
    local center = obj.config and obj.config.center
    if center and (center.cursed_coin_immune or center.key == "m_ocafe_red_antiseptic") then return false end
    return obj.ability and (obj.ability.set == "Joker" or obj.playing_card ~= nil)
end

local function active(key)
    local out = {}
    for _, c in ipairs(G.jokers and SMODS.find_card(key) or {}) do
        if not c.debuff and not c.getting_sliced then out[#out + 1] = c end
    end
    return out
end

local function upgrade_message(card, text, colour)
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.2,
        func = function()
            if card and not card.removed then
                card_eval_status_text(card, "extra", nil, nil, nil, { message = text, colour = colour })
            end
            return true
        end
    }))
end

----------------------------------------------------------------
-- HOOK: a probability failed
----------------------------------------------------------------
local probability_ref = SMODS.pseudorandom_probability
SMODS.pseudorandom_probability = function(trigger_obj, ...)
    local result = probability_ref(trigger_obj, ...)
    if result or not G.jokers then return result end

    for _, joker in ipairs(active(OPTIMIST_KEY)) do
        local ex = joker.ability.extra
        ex.xchips = ex.xchips + ex.gain
        upgrade_message(joker, "X" .. ex.xchips .. " Chips", G.C.CHIPS)
    end

    local backlashes = active(BACKLASH_KEY)
    for _, joker in ipairs(backlashes) do
        local ex = joker.ability.extra
        ex.xmult = ex.xmult + ex.gain
        upgrade_message(joker, "X" .. ex.xmult .. " Mult", G.C.MULT)
    end

    if #backlashes > 0 and can_destroy(trigger_obj) then
        trigger_obj.ocafe_doomed = true
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.3,
            func = function()
                if SMODS.destroy_cards then
                    SMODS.destroy_cards(trigger_obj)
                else
                    trigger_obj:start_dissolve()
                end
                trigger_obj.ocafe_doomed = nil
                return true
            end
        }))
    end
    return result
end

----------------------------------------------------------------
-- JOKERS
----------------------------------------------------------------
SMODS.Joker {
    key = "backlash",
    atlas = "jokers",
    pos = { x = 38, y = 0 },
    rarity = 3, -- Rare
    cost = 8,
    blueprint_compat = true,
    config = { extra = { gain = 1, xmult = 1 } },
    loc_txt = {
        name = "Backlash",
        text = {
            "Whenever a {C:green}probability{} {C:red}fails{},",
            "{C:red}destroy{} the card that triggered it",
            "and gain {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.gain, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.xmult > 1 then
            return { xmult = card.ability.extra.xmult }
        end
    end
}

SMODS.Joker {
    key = "optimist",
    atlas = "jokers",
    pos = { x = 39, y = 0 },
    rarity = 3, -- Rare
    cost = 8,
    blueprint_compat = true,
    config = { extra = { gain = 1, xchips = 1 } },
    loc_txt = {
        name = "Optimist",
        text = {
            "Whenever a {C:green}probability{} {C:red}fails{},",
            "gain {X:chips,C:white}X#1#{} Chips",
            "{C:inactive}(Currently {X:chips,C:white}X#2#{C:inactive} Chips)"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.gain, card.ability.extra.xchips } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.xchips > 1 then
            return { xchips = card.ability.extra.xchips }
        end
    end
}

SMODS.Joker {
    key = "clown_car",
    atlas = "jokers",
    pos = { x = 40, y = 0 },
    rarity = 3, -- Rare
    cost = 8,
    blueprint_compat = false,
    eternal_compat = false, -- it can destroy itself
    config = { extra = { pick_odds = 2, odds = 50, created = 0 } },
    loc_txt = {
        name = "Clown Car",
        text = {
            "At end of round, {C:green}#1# in #2#{} chance to create",
            "{C:attention}2{} {C:dark_edition}Negative{} {C:blue}Common{} Jokers, otherwise",
            "create a {C:dark_edition}Negative{} {C:green}Uncommon{} Joker",
            "{C:green}#3# in #4#{} chance to {C:red}self destruct{}, +{C:green}1{} to the",
            "chance for every Joker this Joker creates",
            "{C:inactive}(Created #5# so far)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        local pn, pd = SMODS.get_probability_vars(card, 1, ex.pick_odds, "ocafe_clown_car_pick")
        local n, d = SMODS.get_probability_vars(card, 1 + ex.created, ex.odds, "ocafe_clown_car")
        return { vars = { pn, pd, n, d, ex.created } }
    end,
    calculate = function(self, card, context)
        if not (context.end_of_round and context.main_eval and not context.game_over)
            or context.blueprint or card.getting_sliced then
            return
        end
        local ex = card.ability.extra

        local commons = SMODS.pseudorandom_probability(card, "ocafe_clown_car_pick", 1, ex.pick_odds, "ocafe_clown_car_pick")
        local rarity, amount = commons and "Common" or "Uncommon", commons and 2 or 1
        for _ = 1, amount do
            G.E_MANAGER:add_event(Event({
                func = function()
                    SMODS.add_card { set = "Joker", rarity = rarity, edition = "e_negative" }
                    return true
                end
            }))
        end
        ex.created = ex.created + amount

        -- rolled after the new Jokers are counted
        if SMODS.pseudorandom_probability(card, "ocafe_clown_car", 1 + ex.created, ex.odds, "ocafe_clown_car") then
            self_destruct(card)
            return { message = "Honk! Honk!", colour = G.C.RED }
        end
        return { message = commons and "Clowns!" or "Surprise!", colour = G.C.FILTER }
    end
}
