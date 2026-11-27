-- Phantom Thieves of Hearts (Persona 5) (loaded from main.lua)
--
-- Nine LEGENDARY Jokers, so each one also joins the Oreo RPG roster automatically. Their RPG kits (stats and
-- moves) live in rpg.lua (KITS), next to the other Legendary Jokers.
--
--   Ren - Joker      "Take Your Heart"   defeating a Boss Blind creates a random Negative Joker
--   Morgana - Mona   "Mercurius' Luck"   doubles every probability, failed rolls pay $2
--   Ryuji - Skull    "Brawler"           High Card and Pair hands give X4 Mult
--   Ann - Panther    "Maragidyne"        Flush hands give X3 Mult, a random scored card becomes a Heart
--   Yusuke - Fox     "Aesthetic Eye"     scored Enhanced / Edition / Sealed cards retrigger 2 times
--   Makoto - Queen   "Royal Pair"        a hand with a King and a Queen gives X3 Mult
--   Futaba - Oracle  "Analyze + Hacking" +1 hand, Boss Blind effects disabled, free rerolls, +2 shop slots
--   Haru - Noir      "Heiress"           X0.1 Mult for every $10 held (no cap)
--   Kasumi - Violet  "Grand Finale + Encore" X4 (+X1 per unused discard) on the final hand,
--                                        new hand types retrigger every Joker. The strongest Thief.
--
--   Spectrals: Calling Card (random Thief) and Phone a Friend (a Thief of your choice), spectrals.png x=5 / x=6
--
-- Art: jokers.png -> x=62 Ren | x=63 Morgana | x=64 Ryuji | x=65 Ann | x=66 Yusuke | x=67 Makoto
--                    x=68 Futaba | x=69 Haru | x=70 Kasumi   (placeholder art, swap in the real cards any time)

local KEYS = {
    morgana = "j_ocafe_morgana",
    futaba = "j_ocafe_futaba",
}

-- format a number for display (1.30000000004 -> 1.3, 2.00 -> 2)
local function fmt(n)
    local s = string.format("%.2f", n):gsub("0+$", "")
    s = s:gsub("%.$", "")
    return s
end

-- every working (not debuffed, not being destroyed) copy of a Joker
local function active(key)
    local out = {}
    for _, c in ipairs(G.jokers and SMODS.find_card(key) or {}) do
        if not c.debuff and not c.getting_sliced then out[#out + 1] = c end
    end
    return out
end

----------------------------------------------------------------
-- REN - JOKER: Take Your Heart
----------------------------------------------------------------
SMODS.Joker {
    key = "ren",
    atlas = "jokers",
    pos = { x = 62, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = false,
    loc_txt = {
        name = "Ren - Joker",
        text = {
            "When a {C:attention}Boss Blind{} is defeated,",
            "create a random {C:dark_edition}Negative{} Joker",
            "{C:inactive}(Never Legendary)",
            "{C:inactive}\"Take your time, take your heart.\""
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
    end,
    calculate = function(self, card, context)
        if context.end_of_round and context.main_eval and not context.game_over and not context.blueprint
            and G.GAME.blind and G.GAME.blind.boss then
            G.E_MANAGER:add_event(Event({
                func = function()
                    SMODS.add_card { set = "Joker", edition = "e_negative" }
                    return true
                end
            }))
            return { message = "Take your heart!", colour = G.C.DARK_EDITION }
        end
    end
}

----------------------------------------------------------------
-- MORGANA - MONA: Mercurius' Luck
--   doubles the numerator of every probability (Steamodded's mod_probability), and pays when a roll still fails.
--   The failure hook wraps SMODS.pseudorandom_probability the same way luck.lua does, so it judges the roll AFTER
--   every other modifier (Bonus Coin's forced failures count too).
----------------------------------------------------------------
SMODS.Joker {
    key = "morgana",
    atlas = "jokers",
    pos = { x = 63, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = false,
    config = { extra = { mult = 2, dollars = 2 } },
    loc_txt = {
        name = "Morgana - Mona",
        text = {
            "{C:green}Doubles{} all listed {C:green}probabilities",
            "Earn {C:money}$#2#{} whenever a",
            "{C:green}probability{} {C:red}fails",
            "{C:inactive}\"I'm not a cat!\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.dollars } }
    end,
    calculate = function(self, card, context)
        if context.mod_probability and not context.blueprint and not card.debuff and context.numerator then
            return { numerator = context.numerator * card.ability.extra.mult }
        end
    end
}

local probability_ref = SMODS.pseudorandom_probability
SMODS.pseudorandom_probability = function(trigger_obj, ...)
    local result = probability_ref(trigger_obj, ...)
    if result or not G.jokers then return result end
    for _, joker in ipairs(active(KEYS.morgana)) do
        local dollars = joker.ability.extra.dollars
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.2,
            func = function()
                if joker and not joker.removed then
                    card_eval_status_text(joker, "extra", nil, nil, nil,
                        { message = "$" .. dollars, colour = G.C.MONEY })
                    ease_dollars(dollars)
                end
                return true
            end
        }))
    end
    return result
end

----------------------------------------------------------------
-- RYUJI - SKULL: Brawler
----------------------------------------------------------------
SMODS.Joker {
    key = "ryuji",
    atlas = "jokers",
    pos = { x = 64, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = true,
    config = { extra = { xmult = 4 } },
    loc_txt = {
        name = "Ryuji - Skull",
        text = {
            "{C:attention}High Card{} and {C:attention}Pair{} hands",
            "give {X:mult,C:white}X#1#{} Mult",
            "{C:inactive}\"Never back down!\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and (context.scoring_name == "High Card" or context.scoring_name == "Pair") then
            return { xmult = card.ability.extra.xmult }
        end
    end
}

----------------------------------------------------------------
-- ANN - PANTHER: Maragidyne
----------------------------------------------------------------
SMODS.Joker {
    key = "ann",
    atlas = "jokers",
    pos = { x = 65, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = true,
    config = { extra = { xmult = 3 } },
    loc_txt = {
        name = "Ann - Panther",
        text = {
            "Hands containing a {C:attention}Flush{}",
            "give {X:mult,C:white}X#1#{} Mult",
            "Each hand, {C:attention}1{} random scored card",
            "turns into a {C:hearts}Heart",
            "{C:inactive}\"Time for a little fire!\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.before and not context.blueprint and context.scoring_hand then
            local pool = {}
            for _, c in ipairs(context.scoring_hand) do
                if c.base and c.base.suit ~= "Hearts" then pool[#pool + 1] = c end
            end
            if #pool > 0 then
                local target = pseudorandom_element(pool, pseudoseed("ocafe_maragidyne"))
                SMODS.change_base(target, "Hearts")
                target:juice_up()
                return { message = "Maragidyne!", colour = G.C.RED }
            end
        end
        if context.joker_main and context.poker_hands and next(context.poker_hands["Flush"]) then
            return { xmult = card.ability.extra.xmult }
        end
    end
}

----------------------------------------------------------------
-- YUSUKE - FOX: Aesthetic Eye
----------------------------------------------------------------
SMODS.Joker {
    key = "yusuke",
    atlas = "jokers",
    pos = { x = 66, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = true,
    config = { extra = { reps = 2 } },
    loc_txt = {
        name = "Yusuke - Fox",
        text = {
            "Scored cards with an {C:attention}Enhancement{},",
            "{C:attention}Edition{} or {C:attention}Seal{} are retriggered",
            "{C:attention}#1#{} additional times",
            "{C:inactive}\"True beauty needs no explanation.\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.reps } }
    end,
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play and context.other_card then
            local c = context.other_card
            if c.edition or c.seal or (c.ability and c.ability.set == "Enhanced") then
                return { repetitions = card.ability.extra.reps }
            end
        end
    end
}

----------------------------------------------------------------
-- MAKOTO - QUEEN: Royal Pair
----------------------------------------------------------------
SMODS.Joker {
    key = "makoto",
    atlas = "jokers",
    pos = { x = 67, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = true,
    config = { extra = { xmult = 3 } },
    loc_txt = {
        name = "Makoto - Queen",
        text = {
            "If played hand contains both a",
            "{C:attention}King{} and a {C:attention}Queen{}, gives",
            "{X:mult,C:white}X#1#{} Mult",
            "{C:inactive}\"Time to get serious.\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.joker_main and context.full_hand then
            local king, queen = false, false
            for _, c in ipairs(context.full_hand) do
                local id = c:get_id()
                if id == 13 then king = true elseif id == 12 then queen = true end
            end
            if king and queen then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end
}

----------------------------------------------------------------
-- FUTABA - ORACLE: Analyze + Hacking
--   Analyze: +1 hand every round, and every Boss Blind has its effect disabled
--   Hacking: rerolls cost nothing, and the shop has extra card slots
----------------------------------------------------------------
local function change_shop(n)
    if change_shop_size then
        change_shop_size(n)
    elseif G.GAME.shop then
        G.GAME.shop.joker_max = G.GAME.shop.joker_max + n
    end
end

-- refresh the reroll price once the Joker is really in (or out of) the Joker area
local function refresh_reroll_cost()
    G.E_MANAGER:add_event(Event({
        func = function()
            if calculate_reroll_cost then calculate_reroll_cost(true) end
            return true
        end
    }))
end

SMODS.Joker {
    key = "futaba",
    atlas = "jokers",
    pos = { x = 68, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = false,
    config = { extra = { hands = 1, slots = 2 } },
    loc_txt = {
        name = "Futaba - Oracle",
        text = {
            "{C:blue}+#1#{} hand every round",
            "Disables all {C:attention}Boss Blind{} effects",
            "{C:attention}Rerolls{} are free, shop has",
            "{C:attention}+#2#{} card slots",
            "{C:inactive}\"Leave the navigating to me!\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.hands, card.ability.extra.slots } }
    end,
    add_to_deck = function(self, card, from_debuff)
        local ex = card.ability.extra
        G.GAME.round_resets.hands = G.GAME.round_resets.hands + ex.hands
        ease_hands_played(ex.hands)
        change_shop(ex.slots)
        if G.GAME.current_round then G.GAME.current_round.reroll_cost = 0 end
        refresh_reroll_cost()
        -- already facing a Boss Blind: switch it off right away
        if G.GAME.blind and G.GAME.blind.boss and not G.GAME.blind.disabled then
            G.GAME.blind:disable()
            play_sound("timpani")
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        local ex = card.ability.extra
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - ex.hands
        ease_hands_played(-ex.hands)
        change_shop(-ex.slots)
        refresh_reroll_cost()
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint and context.blind and context.blind.boss then
            G.E_MANAGER:add_event(Event({
                func = function()
                    G.GAME.blind:disable()
                    play_sound("timpani")
                    return true
                end
            }))
            return { message = "Analyzed!", colour = G.C.BLUE }
        end
    end
}

-- Hacking: after the game works out the reroll price, a Futaba in play sets it to $0
if type(calculate_reroll_cost) == "function" then
    local reroll_ref = calculate_reroll_cost
    calculate_reroll_cost = function(...)
        local ret = reroll_ref(...)
        if G.GAME and G.GAME.current_round and #active(KEYS.futaba) > 0 then
            G.GAME.current_round.reroll_cost = 0
        end
        return ret
    end
end

----------------------------------------------------------------
-- HARU - NOIR: Heiress
----------------------------------------------------------------
local function dollars_held()
    local d = G.GAME and ((G.GAME.dollars or 0) + (G.GAME.dollar_buffer or 0)) or 0
    return math.max(0, d)
end

SMODS.Joker {
    key = "haru",
    atlas = "jokers",
    pos = { x = 69, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = true,
    config = { extra = { gain = 0.1, per = 10 } },
    loc_txt = {
        name = "Haru - Noir",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every {C:money}$#2#{} you have",
            "{C:inactive}(No cap)",
            "{C:inactive}(Currently {X:mult,C:white}X#3#{C:inactive} Mult)",
            "{C:inactive}\"Allow me to handle the finances.\""
        }
    },
    loc_vars = function(self, info_queue, card)
        local ex = card.ability.extra
        local now = 1 + ex.gain * math.floor(dollars_held() / ex.per)
        return { vars = { fmt(ex.gain), ex.per, fmt(now) } }
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local ex = card.ability.extra
            local x = 1 + ex.gain * math.floor(dollars_held() / ex.per)
            if x > 1 then return { xmult = x } end
        end
    end
}

----------------------------------------------------------------
-- KASUMI - VIOLET: Grand Finale + Encore  (the strongest Thief)
--   Grand Finale: X4 Mult on the FINAL hand of the round, +X1 for every unused discard
--   Encore:       playing a hand type you haven't played yet this round retriggers EVERY Joker once
--                 (herself included). Needs Joker retriggering, which main.lua turns on.
----------------------------------------------------------------
SMODS.Joker {
    key = "kasumi",
    atlas = "jokers",
    pos = { x = 70, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = false,
    config = { extra = { base = 4, per_discard = 1, encore = false } },
    loc_txt = {
        name = "Kasumi - Violet",
        text = {
            "{X:mult,C:white}X#1#{} Mult on the {C:attention}final hand{} of the",
            "round, plus {X:mult,C:white}X#2#{} per unused {C:attention}discard",
            "Playing a hand type you haven't",
            "played this round {C:attention}retriggers{}",
            "{C:attention}every Joker{} once",
            "{C:inactive}\"Now, for the grand finale!\""
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.base, card.ability.extra.per_discard } }
    end,
    calculate = function(self, card, context)
        local ex = card.ability.extra

        -- Encore: remember whether this hand type is new this round (counts it already, so "1" = first time)
        if context.before and context.scoring_name and G.GAME.hands[context.scoring_name] then
            ex.encore = G.GAME.hands[context.scoring_name].played_this_round == 1
            if ex.encore then
                return { message = "Encore!", colour = G.C.PURPLE }
            end
        end
        if context.after then
            ex.encore = false
        end
        if context.retrigger_joker_check and not context.retrigger_joker and ex.encore then
            return { repetitions = 1 }
        end

        -- Grand Finale
        if context.joker_main and G.GAME.current_round.hands_left == 0 then
            local discards = math.max(0, G.GAME.current_round.discards_left or 0)
            return { xmult = ex.base + ex.per_discard * discards }
        end
    end
}

----------------------------------------------------------------
-- CALLING CARD (Spectral): creates a Phantom Thief of Hearts
--   Art: spectrals.png x=5 (atlas "spectrals", declared in main.lua)
----------------------------------------------------------------

local THIEF_KEYS = {
    "j_ocafe_ren", "j_ocafe_morgana", "j_ocafe_ryuji", "j_ocafe_ann", "j_ocafe_yusuke",
    "j_ocafe_makoto", "j_ocafe_futaba", "j_ocafe_haru", "j_ocafe_kasumi",
}

-- free Joker slots, counting Jokers that other effects have already reserved
local function joker_room()
    if not (G.jokers and G.jokers.cards and G.jokers.config) then return 0 end
    return G.jokers.config.card_limit - #G.jokers.cards - ((G.GAME and G.GAME.joker_buffer) or 0)
end

SMODS.Consumable {
    key = "calling_card",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 5, y = 0 },
    cost = 4,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Calling Card",
        text = {
            "Creates a random",
            "{C:attention}Phantom Thief of Hearts",
            "{C:inactive}(Prefers Thieves you don't own)",
            "{C:inactive}(Must have room)"
        }
    },
    can_use = function(self, card)
        return joker_room() > 0
    end,
    use = function(self, card, area, copier)
        -- reserve the slot now: the Joker is only created after the delay below
        G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                G.GAME.joker_buffer = math.max(0, (G.GAME.joker_buffer or 0) - 1)
                local missing, all = {}, {}
                for _, key in ipairs(THIEF_KEYS) do
                    if G.P_CENTERS[key] then
                        all[#all + 1] = key
                        if next(SMODS.find_card(key)) == nil then missing[#missing + 1] = key end
                    end
                end
                local pool = #missing > 0 and missing or all
                if #pool > 0 then
                    play_sound("timpani")
                    SMODS.add_card { key = pseudorandom_element(pool, pseudoseed("ocafe_calling_card")) }
                end
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

----------------------------------------------------------------
-- PHONE A FRIEND (Spectral): creates the Phantom Thief of your choice
--   Opens a menu with all nine Thieves (same idea as the Gacha Ticket menu). Quitting while it is open brings
--   the menu back when the run is loaded again. Art: spectrals.png x=6
----------------------------------------------------------------
local phone_areas = {} -- card areas of the menu that is open right now

local function phone_clear_areas()
    for _, a in ipairs(phone_areas) do
        pcall(function() a:remove() end)
    end
    phone_areas = {}
end

local function thief_name(key)
    local ok, n = pcall(localize, { type = "name_text", set = "Joker", key = key })
    if ok and type(n) == "string" and n ~= "ERROR" then return n end
    return key
end

local function open_phone_menu()
    if not (G.GAME and G.GAME.ocafe_phone) then return end
    phone_clear_areas()

    local SCALE = 0.6  -- two rows of five must fit on screen with the title
    local PER_ROW = 5
    local rows, cur = {}, nil
    for i, key in ipairs(THIEF_KEYS) do
        if G.P_CENTERS[key] then
            if not cur or #cur.nodes >= PER_ROW then
                cur = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {} }
                rows[#rows + 1] = cur
            end
            local area = CardArea(0, 0, G.CARD_W * SCALE * 1.1, G.CARD_H * SCALE * 1.1,
                { card_limit = 1, type = "title", highlight_limit = 0 })
            phone_areas[#phone_areas + 1] = area
            local c = Card(area.T.x + area.T.w / 2 - G.CARD_W * SCALE / 2, area.T.y, G.CARD_W * SCALE, G.CARD_H * SCALE,
                G.P_CARDS.empty, G.P_CENTERS[key], { bypass_discovery_center = true, bypass_discovery_ui = true })
            area:emplace(c)
            local owned = next(SMODS.find_card(key)) ~= nil
            cur.nodes[#cur.nodes + 1] = { n = G.UIT.C, config = { align = "cm", padding = 0.08 }, nodes = {
                { n = G.UIT.R, config = { align = "cm", padding = 0.02 }, nodes = {
                    { n = G.UIT.O, config = { object = area } }
                } },
                { n = G.UIT.R, config = { align = "cm" }, nodes = {
                    { n = G.UIT.T, config = { text = thief_name(key) .. (owned and " (owned)" or ""), scale = 0.26,
                        colour = owned and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT, shadow = true, maxw = 2.0 } }
                } },
                { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
                    { n = G.UIT.C, config = {
                        align = "cm", minw = 1.6, minh = 0.45, r = 0.1, hover = true, shadow = true,
                        colour = G.C.GREEN, button = "ocafe_phone_pick", ref_table = { key = key }
                    }, nodes = {
                        { n = G.UIT.T, config = { text = "CALL", scale = 0.34, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
                    } }
                } }
            } }
        end
    end

    G.FUNCS.overlay_menu {
        definition = { n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = {
            { n = G.UIT.C, config = { align = "cm", padding = 0.2, r = 0.15, colour = G.C.L_BLACK, emboss = 0.05 }, nodes = {
                { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
                    { n = G.UIT.T, config = { text = "PHONE A FRIEND", scale = 0.6, colour = G.C.RED, shadow = true } }
                } },
                { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
                    { n = G.UIT.T, config = { text = "Choose a Phantom Thief to join you", scale = 0.4,
                        colour = G.C.UI.TEXT_LIGHT, shadow = true } }
                } },
                { n = G.UIT.R, config = { align = "cm" }, nodes = {
                    { n = G.UIT.C, config = { align = "cm" }, nodes = rows }
                } },
            } }
        } },
        no_esc = true
    }
end

G.FUNCS.ocafe_phone_pick = function(e)
    local p = G.GAME and G.GAME.ocafe_phone
    if not p or p.busy then return end
    local key = e.config and e.config.ref_table and e.config.ref_table.key
    if not key or not G.P_CENTERS[key] then return end
    p.busy = true
    -- the slot was free when the card was used; if something took it since, the Thief arrives Negative
    -- instead of being lost (the Phone a Friend card is already spent)
    local t = { key = key }
    if joker_room() <= 0 then t.edition = "e_negative" end
    SMODS.add_card(t)
    play_sound("timpani", 1, 0.7)
    G.GAME.ocafe_phone = nil
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.2,
        func = function()
            pcall(function() if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end end)
            phone_clear_areas() -- only after the menu is gone, so it never draws a removed area
            return true
        end
    }))
end

SMODS.Consumable {
    key = "phone_a_friend",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 6, y = 0 },
    cost = 8,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Phone a Friend",
        text = {
            "Creates the {C:attention}Phantom Thief",
            "{C:attention}of Hearts{} of your choice",
            "{C:inactive}(Must have room)"
        }
    },
    can_use = function(self, card)
        return joker_room() > 0 and not (G.GAME and G.GAME.ocafe_phone)
    end,
    use = function(self, card, area, copier)
        G.GAME.ocafe_phone = { busy = false }
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                card:juice_up(0.3, 0.5)
                open_phone_menu()
                return true
            end
        }))
        delay(0.6)
    end
}

-- quitting in the middle of the choice: bring the menu back when the run is loaded again
local phone_start_run_ref = Game.start_run
function Game:start_run(...)
    phone_clear_areas() -- areas of a menu from the previous run are gone with it
    local ret = phone_start_run_ref(self, ...)
    if G.GAME and G.GAME.ocafe_phone then
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 1,
            func = function()
                if G.GAME and G.GAME.ocafe_phone then
                    G.GAME.ocafe_phone.busy = false
                    open_phone_menu()
                end
                return true
            end
        }))
    end
    return ret
end
