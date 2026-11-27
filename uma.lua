-- Uma Musume content for Oreo Cafe Balatro (loaded from main.lua)
--   Enhancement: m_ocafe_blessed
--   Tarots:  c_ocafe_scout, goldships_shenanigans, turbos_charm, uraras_motivation,
--            healthcare_coupon, shiraokis_blessing, digital_fan_club
--   Jokers:  j_ocafe_ +
--     Team Spica:    special_week, silence_suzuka, daiwa_scarlet, vodka, gold_ship, tokai_teio, mejiro_mcqueen
--     Team Cannopus: nice_nature, matikanetannhauser, twin_turbo, ikuno_dictus
--     Others:        agnes_tachyon, manhattan_cafe, jungle_pocket, tm_opera_o, meisho_doto,
--                    matikanefukukitaru, rice_shower, haru_urara, agnes_digital
-- Art: the Jokers live in jokers.png (every Joker of the mod in one sheet, sorted by rarity, see main.lua).
--      uma_tarots.png    x=0 Scout, 1 Goldship's Shenanigans, 2 Turbo's Charm, 3 Urara's Motivation,
--                        4 Healthcare Coupon, 5 Shiraoki's Blessing, 6 Digital Fan Club
--      uma_enhancements.png  x=0 Blessed          (all art is placeholder)
--
-- "Base Chips and Mult" means the Joker's own +Chips / +Mult is multiplied, so
-- "X5 Base" on a +50 Chips, +15 Mult Joker gives +250 Chips and +75 Mult.

----------------------------------------------------------------
-- ATLASES
----------------------------------------------------------------
SMODS.Atlas { key = "uma_tarots",       path = "uma_tarots.png",       px = 71, py = 95 }
SMODS.Atlas { key = "uma_enhancements", path = "uma_enhancements.png", px = 71, py = 95 }

----------------------------------------------------------------
-- TUNING KNOBS
----------------------------------------------------------------
-- base Chips / Mult of each group (Mejiro McQueen overrides her own)
local BASES = { spica = { 50, 15 }, cannopus = { 30, 10 }, other = { 40, 7 } }
local MCQUEEN_CHIPS, MCQUEEN_MULT = 750, 75
local MCQUEEN_LOSS_CHIPS, MCQUEEN_LOSS_MULT = 25, 5   -- per round without Tokai Teio

-- Team Spica
local SPECIAL_WEEK_X, SUZUKA_X, DUO_X, TEIO_X = 5, 2, 3, 7.5
local DROPKICK_ODDS, INJURY_ODDS, DESTROY_ODDS = 15, 15, 30
-- Team Cannopus
local NICE_NATURE_X = 10
local TURBO_PAIR_X = 3          -- Matikanetannhauser with Twin Turbo
local NOSEBLEED_ODDS = 10       -- per round
local TWIN_TURBO_ODDS, TWIN_TURBO_X = 5, 15
local IKUNO_X = 5               -- with no other Cannopus member
-- Others
local TACHYON_CAFE_X = 2
local TACHYON_LUCKY_ODDS, TACHYON_LUCKY_X = 10, 50
local TACHYON_BOOM_ODDS = 50              -- explodes, destroying only herself
local TACHYON_BIG_BOOM_ODDS = 500         -- explodes, destroying herself and 2 other Jokers
local CAFE_X, CAFE_DEATH_ODDS = 30, 100
local JUNGLE_ONE_X, JUNGLE_BOTH_X = 10, 50
local OPERA_ODDS, OPERA_DOTO_ODDS, OPERA_X = 50, 25, 100
local DOTO_FALL_ODDS, DOTO_LUCKY_ODDS, DOTO_X = 10, 20, 50
local RICE_CHIPS, RICE_DUO_CHIPS = 100, 500
local HARU_MULT, HARU_DUO_MULT = 10, 25
local DIGITAL_TRIPLE_ODDS, DIGITAL_CLUB_ODDS = 5, 50
-- Matikanefukukitaru: { name, odds } in the order they are rolled each hand
local FUKU = {
    { "x5", 5 }, { "blessing", 15 }, { "blessed_one", 25 }, { "x50", 30 }, { "die", 50 },
    { "x10_all", 75 }, { "cash", 100 }, { "blessed_all", 150 }, { "win", 500 },
}
local FUKU_ODDS = {}
for _, r in ipairs(FUKU) do FUKU_ODDS[r[1]] = r[2] end

----------------------------------------------------------------
-- JOKER LISTS
----------------------------------------------------------------
local function jk(id) return "j_ocafe_" .. id end

local SPICA_IDS = {
    "special_week", "silence_suzuka", "daiwa_scarlet", "vodka",
    "gold_ship", "tokai_teio", "mejiro_mcqueen",
}
local CANNOPUS_IDS = { "nice_nature", "matikanetannhauser", "twin_turbo", "ikuno_dictus" }
local OTHER_IDS = {
    "agnes_tachyon", "manhattan_cafe", "jungle_pocket", "tm_opera_o", "meisho_doto",
    "matikanefukukitaru", "rice_shower", "haru_urara", "agnes_digital",
}
local UMA_IDS = {}
for _, list in ipairs({ SPICA_IDS, CANNOPUS_IDS, OTHER_IDS }) do
    for _, id in ipairs(list) do UMA_IDS[#UMA_IDS + 1] = id end
end

local function keys_of(ids)
    local keys, set = {}, {}
    for _, id in ipairs(ids) do
        keys[#keys + 1] = jk(id)
        set[jk(id)] = true
    end
    return keys, set
end

local SPICA_KEYS, SPICA_SET = keys_of(SPICA_IDS)
local CANNOPUS_KEYS, CANNOPUS_SET = keys_of(CANNOPUS_IDS)
local OTHER_KEYS = keys_of(OTHER_IDS)
local UMA_KEYS, UMA_SET = keys_of(UMA_IDS)

local BLESSED_KEY = "m_ocafe_blessed"
local METEOR_KEY = "m_ocafe_meteor"
local BLESSING_KEY = "c_ocafe_shiraokis_blessing"
local FAN_CLUB_KEY = "c_ocafe_digital_fan_club"

----------------------------------------------------------------
-- TOOLTIP LINKS
-- A card's tooltip can show other cards ("info" links). If card A shows B and B
-- shows A (or any longer loop), hovering overflows the stack and the game crashes.
-- Every link in the list below goes through link(), which REFUSES a link that would
-- close a loop, so no list edit can ever bring that crash back. Links are tried in
-- order, so for a pair like Agnes Tachyon <-> Manhattan Cafe the first one wins.
----------------------------------------------------------------
local INFO = {}   -- center key -> list of center keys to show

local function reaches(from, target, seen)
    if from == target then return true end
    seen = seen or {}
    if seen[from] then return false end
    seen[from] = true
    for _, nxt in ipairs(INFO[from] or {}) do
        if reaches(nxt, target, seen) then return true end
    end
    return false
end

local function link(from, to)
    if from == to or reaches(to, from) then
        if sendDebugMessage then
            sendDebugMessage("Skipped tooltip link " .. from .. " -> " .. to .. " (would loop)", "OreoCafe")
        end
        return
    end
    INFO[from] = INFO[from] or {}
    table.insert(INFO[from], to)
end

local LINKS = {
    -- Team Spica
    { jk("special_week"), jk("silence_suzuka") },
    { jk("daiwa_scarlet"), jk("vodka") },
    { jk("gold_ship"), jk("tokai_teio") },
    { jk("tokai_teio"), jk("mejiro_mcqueen") },
    -- Team Cannopus
    { jk("matikanetannhauser"), jk("twin_turbo") },
    -- Others
    { jk("agnes_tachyon"), jk("manhattan_cafe") },
    { jk("jungle_pocket"), jk("agnes_tachyon") },
    { jk("jungle_pocket"), jk("manhattan_cafe") },
    { jk("tm_opera_o"), jk("meisho_doto") },
    { jk("rice_shower"), jk("haru_urara") },
    { jk("matikanefukukitaru"), BLESSING_KEY },
    { jk("matikanefukukitaru"), BLESSED_KEY },
    { jk("agnes_digital"), FAN_CLUB_KEY },
    -- Tarots (these two point back at their Joker, so they are refused: no loop)
    { BLESSING_KEY, jk("matikanefukukitaru") },
    { FAN_CLUB_KEY, jk("agnes_digital") },
    { "c_ocafe_healthcare_coupon", jk("agnes_tachyon") },
}
for _, l in ipairs(LINKS) do link(l[1], l[2]) end

local function add_info(key, info_queue)
    for _, to in ipairs(INFO[key] or {}) do
        local center = G.P_CENTERS[to]
        if center then info_queue[#info_queue + 1] = center end
    end
end

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function has_center_key(card, key)
    return card and card.config and card.config.center and card.config.center.key == key
end

-- is an un-debuffed copy of this Joker owned?
local function owns(id)
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if not j.debuff and j.config.center.key == jk(id) then return true end
    end
    return false
end

-- number of other un-debuffed owned Jokers whose key is in `set`
local function count_others(set, except)
    local n = 0
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if j ~= except and not j.debuff and set[j.config.center.key] then n = n + 1 end
    end
    return n
end

-- Silence Suzuka "activated first": she is the left-most Team Spica Joker
local function is_first_spica(card)
    for _, j in ipairs(G.jokers and G.jokers.cards or {}) do
        if not j.debuff and SPICA_SET[j.config.center.key] then
            return j == card
        end
    end
    return false
end

local function joker_room()
    return G.jokers and (#G.jokers.cards + (G.GAME.joker_buffer or 0)) < G.jokers.config.card_limit
end

local function consumable_room()
    return G.consumeables
        and (#G.consumeables.cards + (G.GAME.consumeable_buffer or 0)) < G.consumeables.config.card_limit
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

local function roll(card, seed, odds)
    return SMODS.pseudorandom_probability(card, seed, 1, odds, seed)
end

local function odds_vars(card, seed, odds)
    return SMODS.get_probability_vars(card, 1, odds, seed)
end

-- an id for "this hand": it changes every hand, so per-hand marks expire by themselves
-- (even if the Joker that set them was destroyed before it could clean up)
local function hand_token()
    return (G.GAME.round or 0) .. ":" .. (G.GAME.current_round and G.GAME.current_round.hands_played or 0)
end

-- destroy a Joker (Eternal Jokers shrug it off). Returns true if it was destroyed.
local function destroy_joker(j)
    if j.ability.eternal or j.getting_sliced then return false end
    j.getting_sliced = true
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.3,
        func = function()
            play_sound("tarot1")
            j:start_dissolve()
            return true
        end
    }))
    return true
end

local function joker_name(j)
    local ok, name = pcall(localize, { type = "name_text", set = "Joker", key = j.config.center.key })
    return ok and name or "Joker"
end

-- result tables ---------------------------------------------------------
local function ret_of(chips, mult)
    local r = {}
    if chips ~= 0 then r.chips = chips end
    if mult ~= 0 then r.mult = mult end
    return r
end

local function base_ret(card, f)
    local ex = card.ability.extra
    return ret_of(ex.chips * f, ex.mult * f)
end

-- show a message first, then give the effect
local function announce(msg, colour, ret)
    return { message = msg, colour = colour, extra = ret }
end

-- several messages in a row: list of { text, colour }
local function chain(msgs)
    local head, tail
    for _, m in ipairs(msgs) do
        local node = { message = m[1], colour = m[2] or G.C.FILTER }
        if tail then tail.extra = node else head = node end
        tail = node
    end
    return head
end

-- Blessed: used by Matikanefukukitaru
local function bless_cards(cards)
    for _, c in ipairs(cards) do
        if c and not c.removed and not c.getting_sliced and not c.destroyed
            and not has_center_key(c, BLESSED_KEY) and not has_center_key(c, METEOR_KEY) then
            c:set_ability(G.P_CENTERS[BLESSED_KEY], nil, true)
            G.E_MANAGER:add_event(Event({
                func = function()
                    c:juice_up(0.3, 0.5)
                    return true
                end
            }))
        end
    end
end

----------------------------------------------------------------
-- ENHANCEMENT
----------------------------------------------------------------
SMODS.Enhancement {
    key = "blessed",
    atlas = "uma_enhancements",
    pos = { x = 0, y = 0 },
    config = { bonus = 250, extra = { xmult = 1.5 } },
    loc_txt = {
        name = "Blessed Card",
        text = {
            "{C:chips}+#1#{} Chips",
            "{X:mult,C:white}X#2#{} Mult",
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.bonus, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            return { xmult = card.ability.extra.xmult }
        end
    end
}

----------------------------------------------------------------
-- GLOBAL HOOK: Nice Nature (muting), Matikanefukukitaru (X10 every Joker) and
-- Agnes Digital (triple). All of them are marked with the hand token, so they
-- can never leak into a later hand.
--   card.ocafe_mute_token     this Joker's ability is prevented during that hand
--   G.GAME.ocafe_all_x        { x, token }: every Joker's Chips/Mult are multiplied
--   G.GAME.ocafe_digital      token: the next Uma Musume Joker to activate is tripled
----------------------------------------------------------------
local NUM_KEYS = { "chips", "mult", "h_chips", "h_mult", "dollars",
    "xmult", "x_mult", "Xmult", "xchips", "x_chips" }
local TRIPLE_ADD = { "chips", "mult", "h_chips", "h_mult", "dollars" }
local TRIPLE_X = { "xmult", "x_mult", "Xmult", "xchips", "x_chips" }

-- copy of an effect and its `extra` chain, so a Joker's own table is never edited
local function copy_chain(effect)
    local copy = {}
    for k, v in pairs(effect) do copy[k] = v end
    if type(copy.extra) == "table" then copy.extra = copy_chain(copy.extra) end
    return copy
end

local function each_node(ret, fn)
    local node = ret
    while type(node) == "table" do
        fn(node)
        node = node.extra
    end
end

local function has_numbers(ret)
    local found = false
    each_node(ret, function(n)
        for _, k in ipairs(NUM_KEYS) do
            if type(n[k]) == "number" then found = true end
        end
    end)
    return found
end

local function triple(ret)
    each_node(ret, function(n)
        for _, k in ipairs(TRIPLE_ADD) do
            if type(n[k]) == "number" then n[k] = n[k] * 3 end
        end
        for _, k in ipairs(TRIPLE_X) do
            if type(n[k]) == "number" and n[k] > 1 then n[k] = 1 + (n[k] - 1) * 3 end
        end
    end)
end

local calculate_joker_ref = Card.calculate_joker
function Card:calculate_joker(context)
    if not G.GAME then return calculate_joker_ref(self, context) end
    local token = hand_token()

    -- Nice Nature: the Joker does nothing while the hand is being scored
    if self.ocafe_mute_token == token and G.STATE == G.STATES.HAND_PLAYED and not context.end_of_round then
        return nil
    end

    local ret, triggered = calculate_joker_ref(self, context)
    if context.blueprint or type(ret) ~= "table" then return ret, triggered end

    local scoring = context.joker_main or (context.individual and context.cardarea == G.play)
    if not scoring then return ret, triggered end

    local key = self.config and self.config.center and self.config.center.key
    local all_x = G.GAME.ocafe_all_x
    all_x = (all_x and all_x.token == token) and all_x.x or nil
    local digital = context.joker_main and G.GAME.ocafe_digital == token
        and UMA_SET[key] and key ~= jk("agnes_digital") and has_numbers(ret)
    if not (all_x or digital) then return ret, triggered end

    ret = copy_chain(ret)
    if digital then
        G.GAME.ocafe_digital = nil
        triple(ret)
        ret = announce("Triple!", G.C.PURPLE, ret)
    end
    if all_x then
        each_node(ret, function(n)
            if type(n.chips) == "number" then n.chips = n.chips * all_x end
            if type(n.mult) == "number" then n.mult = n.mult * all_x end
        end)
    end
    return ret, triggered
end

----------------------------------------------------------------
-- UMA MUSUME JOKERS
-- Every Joker has config.extra = { chips, mult } and gives them on joker_main,
-- multiplied by its own `factor`. Gold Ship's dropkick doubles extra.mult for good,
-- which is why `mult` is stored.
-- Optional fields: factor(card), extra_stats(card) -> flat chips, flat mult added on top,
--   blocked(card) -> text (the Joker sits this hand out), score(card, context) (custom
--   scoring), on_before / on_after / on_setting_blind / on_round_end(card, context),
--   vars(card) (extra loc_vars from #5), no_current (hide the "Currently" line),
--   blueprint = false.
----------------------------------------------------------------
local function uma_joker(a)
    local b = BASES[a.group]
    local text = { "{C:chips}+#1#{} Chips, {C:mult}+#2#{} Mult" }
    for _, line in ipairs(a.text or {}) do text[#text + 1] = line end
    if not a.no_current then
        text[#text + 1] = "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips, {C:mult}+#4#{C:inactive} Mult)"
    end

    local function factor(card)
        return a.factor and a.factor(card) or 1
    end

    local function totals(card)
        local ex = card.ability.extra
        local f = factor(card)
        local add_c, add_m = 0, 0
        if a.extra_stats then add_c, add_m = a.extra_stats(card) end
        return ex.chips * f + add_c, ex.mult * f + add_m
    end

    SMODS.Joker {
        key = a.id,
        atlas = "jokers",   -- the shared jokers.png declared in main.lua
        pos = { x = a.x, y = 0 },
        rarity = a.rarity,
        cost = a.cost,
        blueprint_compat = a.blueprint ~= false,
        config = { extra = {
            chips = a.chips or b[1], mult = a.mult or b[2],
            injured = false, nosebleed = false, muting = false, fx = 1,
        } },
        loc_txt = { name = a.name, text = text },
        loc_vars = function(self, info_queue, card)
            add_info(jk(a.id), info_queue)
            local ex = card.ability.extra
            local tc, tm = totals(card)
            local vars = { ex.chips, ex.mult, tc, tm }
            for _, v in ipairs(a.vars and a.vars(card) or {}) do vars[#vars + 1] = v end
            return { vars = vars }
        end,
        calculate = function(self, card, context)
            if not context.blueprint then
                if context.before and a.on_before then
                    return a.on_before(card, context)
                end
                if context.after and a.on_after then
                    return a.on_after(card, context)
                end
                if context.setting_blind and a.on_setting_blind then
                    return a.on_setting_blind(card, context)
                end
                if context.end_of_round and context.main_eval and not context.game_over and a.on_round_end then
                    return a.on_round_end(card, context)
                end
            end

            if context.joker_main then
                if card.getting_sliced then return end   -- exploded / self destructed this hand
                local why = a.blocked and a.blocked(card)
                if why then return { message = why, colour = G.C.RED } end
                if a.score then return a.score(card, context) end
                local tc, tm = totals(card)
                return ret_of(tc, tm)
            end
        end
    }
end

----------------------------------------------------------------
-- TEAM SPICA  (+50 Chips, +15 Mult base; Mejiro McQueen has her own)
----------------------------------------------------------------
uma_joker {
    id = "special_week", name = "Special Week", group = "spica", x = 47, rarity = 3, cost = 8,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you",
        "own {C:attention}Silence Suzuka",
    },
    vars = function() return { SPECIAL_WEEK_X } end,
    factor = function() return owns("silence_suzuka") and SPECIAL_WEEK_X or 1 end,
}

uma_joker {
    id = "silence_suzuka", name = "Silence Suzuka", group = "spica", x = 48, rarity = 3, cost = 8,
    text = {
        "{C:attention}Doubles{} Base Chips and Mult",
        "if she is activated first",
        "{C:inactive}(Left-most Team Spica Joker)",
    },
    factor = function(card) return is_first_spica(card) and SUZUKA_X or 1 end,
}

uma_joker {
    id = "daiwa_scarlet", name = "Daiwa Scarlet", group = "spica", x = 15, rarity = 2, cost = 6,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you",
        "own {C:attention}Vodka",
    },
    vars = function() return { DUO_X } end,
    factor = function() return owns("vodka") and DUO_X or 1 end,
}

uma_joker {
    id = "vodka", name = "Vodka", group = "spica", x = 16, rarity = 2, cost = 6,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you",
        "own {C:attention}Daiwa Scarlet",
    },
    vars = function() return { DUO_X } end,
    factor = function() return owns("daiwa_scarlet") and DUO_X or 1 end,
}

uma_joker {
    id = "gold_ship", name = "Gold Ship", group = "spica", x = 17, rarity = 2, cost = 6,
    text = {
        "{C:green}#5# in #6#{} chance each hand to {C:attention}dropkick",
        "an {C:attention}Uma Musume{} Joker: its Mult is {C:attention}doubled",
        "{C:red}Destroys{} {C:attention}Tokai Teio{} instead",
    },
    vars = function(card)
        local n, d = odds_vars(card, "ocafe_gold_ship", DROPKICK_ODDS)
        return { n, d }
    end,
    on_before = function(card, context)
        local pool = {}
        for _, j in ipairs(G.jokers.cards) do
            if j ~= card and UMA_SET[j.config.center.key] and not j.getting_sliced then
                pool[#pool + 1] = j
            end
        end
        if #pool == 0 then return end
        if not roll(card, "ocafe_gold_ship", DROPKICK_ODDS) then return end

        local target = pseudorandom_element(pool, pseudoseed("ocafe_gold_ship_target"))
        if target.config.center.key == jk("tokai_teio") then
            destroy_joker(target)
            return { message = "Dropkick!", colour = G.C.RED }
        end
        target.ability.extra.mult = target.ability.extra.mult * 2
        G.E_MANAGER:add_event(Event({
            func = function()
                target:juice_up(0.5, 0.6)
                return true
            end
        }))
        return { message = "Dropkick!", colour = G.C.RED }
    end,
}

-- Injured: she scores nothing until the end of the round.
uma_joker {
    id = "tokai_teio", name = "Tokai Teio", group = "spica", x = 49, rarity = 3, cost = 8,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you",
        "own {C:attention}Mejiro McQueen",
        "{C:green}#6# in #7#{} chance each hand to {C:red}injure{} herself",
        "(no score until end of round), then",
        "{C:green}#8# in #9#{} chance to {C:red}self destruct",
        "{C:red}#10#",
    },
    vars = function(card)
        local n1, d1 = odds_vars(card, "ocafe_teio_injury", INJURY_ODDS)
        local n2, d2 = odds_vars(card, "ocafe_teio_destroy", DESTROY_ODDS)
        return { TEIO_X, n1, d1, n2, d2, card.ability.extra.injured and "Currently injured!" or "" }
    end,
    factor = function() return owns("mejiro_mcqueen") and TEIO_X or 1 end,
    blocked = function(card) return card.ability.extra.injured and "Injured!" or nil end,
    on_before = function(card, context)
        local ex = card.ability.extra
        if ex.injured then return end
        if not roll(card, "ocafe_teio_injury", INJURY_ODDS) then return end
        ex.injured = true
        if roll(card, "ocafe_teio_destroy", DESTROY_ODDS) and destroy_joker(card) then
            return { message = "Destroyed!", colour = G.C.RED }
        end
        return { message = "Injured!", colour = G.C.RED }
    end,
    on_round_end = function(card)
        if card.ability.extra.injured then
            card.ability.extra.injured = false
            return { message = "Recovered!", colour = G.C.GREEN }
        end
    end,
}

uma_joker {
    id = "mejiro_mcqueen", name = "Mejiro McQueen", group = "spica", x = 50, rarity = 3, cost = 10,
    chips = MCQUEEN_CHIPS, mult = MCQUEEN_MULT,
    text = {
        "Loses {C:chips}#5#{} Chips and {C:mult}#6#{} Mult at end",
        "of round if you don't own {C:attention}Tokai Teio",
    },
    vars = function() return { MCQUEEN_LOSS_CHIPS, MCQUEEN_LOSS_MULT } end,
    on_round_end = function(card)
        if owns("tokai_teio") then return end
        local ex = card.ability.extra
        if ex.chips <= 0 and ex.mult <= 0 then return end
        ex.chips = math.max(0, ex.chips - MCQUEEN_LOSS_CHIPS)
        ex.mult = math.max(0, ex.mult - MCQUEEN_LOSS_MULT)
        return { message = "Tired...", colour = G.C.RED }
    end,
}

----------------------------------------------------------------
-- TEAM CANNOPUS  (+30 Chips, +10 Mult base)
----------------------------------------------------------------
-- Each hand she silences a random OTHER Joker (see the global hook above) and, in
-- return, gives X10 base. With nobody to silence, she gives no bonus.
uma_joker {
    id = "nice_nature", name = "Nice Nature", group = "cannopus", x = 51, rarity = 3, cost = 8,
    text = {
        "Each hand, {C:attention}prevents{} the ability of a",
        "random other Joker and in return",
        "gives {C:attention}Base Chips and Mult X#5#",
    },
    vars = function() return { NICE_NATURE_X } end,
    factor = function(card) return card.ability.extra.muting and NICE_NATURE_X or 1 end,
    no_current = true,
    on_before = function(card, context)
        local ex = card.ability.extra
        local pool = {}
        for _, j in ipairs(G.jokers.cards) do
            if j ~= card and not j.debuff and not j.getting_sliced then pool[#pool + 1] = j end
        end
        ex.muting = false
        if #pool == 0 then return end
        local target = pseudorandom_element(pool, pseudoseed("ocafe_nice_nature"))
        target.ocafe_mute_token = hand_token()
        ex.muting = true
        G.E_MANAGER:add_event(Event({
            func = function()
                target:juice_up(0.3, 0.4)
                return true
            end
        }))
        return { message = "Blocked: " .. joker_name(target), colour = G.C.RED }
    end,
    on_round_end = function(card) card.ability.extra.muting = false end,
}

uma_joker {
    id = "matikanetannhauser", name = "Matikanetannhauser", group = "cannopus", x = 18, rarity = 2, cost = 6,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you",
        "own {C:attention}Twin Turbo",
        "{C:green}#6# in #7#{} chance each round to get a",
        "{C:red}nosebleed{} and not activate that round",
        "{C:red}#8#",
    },
    vars = function(card)
        local n, d = odds_vars(card, "ocafe_nosebleed", NOSEBLEED_ODDS)
        return { TURBO_PAIR_X, n, d, card.ability.extra.nosebleed and "Currently has a nosebleed!" or "" }
    end,
    factor = function() return owns("twin_turbo") and TURBO_PAIR_X or 1 end,
    blocked = function(card) return card.ability.extra.nosebleed and "Nosebleed!" or nil end,
    on_setting_blind = function(card, context)
        local ex = card.ability.extra
        ex.nosebleed = false
        if roll(card, "ocafe_nosebleed", NOSEBLEED_ODDS) then
            ex.nosebleed = true
            return { message = "Nosebleed!", colour = G.C.RED }
        end
    end,
    on_round_end = function(card) card.ability.extra.nosebleed = false end,
}

uma_joker {
    id = "twin_turbo", name = "Twin Turbo", group = "cannopus", x = 19, rarity = 2, cost = 6,
    text = {
        "{C:green}#5# in #6#{} chance for {C:attention}Base Chips",
        "{C:attention}and Mult X#7#{}, otherwise does nothing",
    },
    vars = function(card)
        local n, d = odds_vars(card, "ocafe_twin_turbo", TWIN_TURBO_ODDS)
        return { n, d, TWIN_TURBO_X }
    end,
    no_current = true,
    score = function(card)
        if roll(card, "ocafe_twin_turbo", TWIN_TURBO_ODDS) then
            return announce("X" .. TWIN_TURBO_X .. "!", G.C.GOLD, base_ret(card, TWIN_TURBO_X))
        end
    end,
}

uma_joker {
    id = "ikuno_dictus", name = "Ikuno Dictus", group = "cannopus", x = 20, rarity = 2, cost = 5,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} if you own",
        "no other {C:attention}Team Cannopus{} members",
        "{C:inactive}(Nice Nature, Matikanetannhauser,",
        "{C:inactive}Twin Turbo)",
    },
    vars = function() return { IKUNO_X } end,
    factor = function(card) return count_others(CANNOPUS_SET, card) == 0 and IKUNO_X or 1 end,
}

----------------------------------------------------------------
-- OTHER UMA MUSUME  (+40 Chips, +7 Mult base)
----------------------------------------------------------------
-- Her bad rolls can be cancelled by Healthcare Coupons (G.GAME.ocafe_coupons).
uma_joker {
    id = "agnes_tachyon", name = "Agnes Tachyon", group = "other", x = 52, rarity = 3, cost = 8,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} with {C:attention}Manhattan Cafe",
        "{C:green}#6# in #7#{} chance for {C:attention}Base X#8#",
        "{C:green}#9# in #10#{} chance to {C:red}explode{} and self destruct",
        "{C:green}#11# in #12#{} chance to {C:red}explode{} and destroy",
        "two other Jokers along with herself",
        "{C:inactive}#13#",
    },
    vars = function(card)
        local n1, d1 = odds_vars(card, "ocafe_tachyon_lucky", TACHYON_LUCKY_ODDS)
        local n2, d2 = odds_vars(card, "ocafe_tachyon_boom", TACHYON_BOOM_ODDS)
        local n3, d3 = odds_vars(card, "ocafe_tachyon_big", TACHYON_BIG_BOOM_ODDS)
        return { TACHYON_CAFE_X, n1, d1, TACHYON_LUCKY_X, n2, d2, n3, d3,
            "Healthcare Coupons: " .. ((G.GAME and G.GAME.ocafe_coupons) or 0) }
    end,
    no_current = true,
    blueprint = false,
    on_before = function(card, context)
        local function coupon()
            if (G.GAME.ocafe_coupons or 0) > 0 then
                G.GAME.ocafe_coupons = G.GAME.ocafe_coupons - 1
                return true
            end
        end

        local boom, big
        if roll(card, "ocafe_tachyon_big", TACHYON_BIG_BOOM_ODDS) then
            if coupon() then return { message = "Healthcare Coupon!", colour = G.C.GREEN } end
            boom, big = true, true
        elseif roll(card, "ocafe_tachyon_boom", TACHYON_BOOM_ODDS) then
            if coupon() then return { message = "Healthcare Coupon!", colour = G.C.GREEN } end
            boom = true
        end
        if not boom then return end

        if big then
            local pool = {}
            for _, j in ipairs(G.jokers.cards) do
                if j ~= card and not j.ability.eternal and not j.getting_sliced then pool[#pool + 1] = j end
            end
            pseudoshuffle(pool, pseudoseed("ocafe_tachyon_victims"))
            for i = 1, math.min(2, #pool) do destroy_joker(pool[i]) end
        end
        destroy_joker(card)
        return { message = big and "BIG EXPLOSION!" or "Explosion!", colour = G.C.RED }
    end,
    score = function(card)
        local f = owns("manhattan_cafe") and TACHYON_CAFE_X or 1
        if roll(card, "ocafe_tachyon_lucky", TACHYON_LUCKY_ODDS) then
            return announce("X" .. TACHYON_LUCKY_X .. "!", G.C.GOLD, base_ret(card, f * TACHYON_LUCKY_X))
        end
        return base_ret(card, f)
    end,
}

uma_joker {
    id = "manhattan_cafe", name = "Manhattan Cafe", group = "other", x = 53, rarity = 3, cost = 8,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} with {C:attention}Agnes Tachyon",
        "{C:green}#6# in #7#{} chance each hand to {C:red}self destruct",
        "while you own {C:attention}Agnes Tachyon",
    },
    vars = function(card)
        local n, d = odds_vars(card, "ocafe_cafe_death", CAFE_DEATH_ODDS)
        return { CAFE_X, n, d }
    end,
    factor = function() return owns("agnes_tachyon") and CAFE_X or 1 end,
    blueprint = false,
    on_before = function(card, context)
        if owns("agnes_tachyon") and roll(card, "ocafe_cafe_death", CAFE_DEATH_ODDS) and destroy_joker(card) then
            return { message = "Self destructed!", colour = G.C.RED }
        end
    end,
}

uma_joker {
    id = "jungle_pocket", name = "Jungle Pocket", group = "other", x = 21, rarity = 2, cost = 6,
    text = {
        "{C:attention}Base Chips and Mult X#5#{} with {C:attention}Agnes Tachyon",
        "or {C:attention}Manhattan Cafe{}, {C:attention}X#6#{} with both",
    },
    vars = function() return { JUNGLE_ONE_X, JUNGLE_BOTH_X } end,
    factor = function()
        local a, c = owns("agnes_tachyon"), owns("manhattan_cafe")
        if a and c then return JUNGLE_BOTH_X end
        if a or c then return JUNGLE_ONE_X end
        return 1
    end,
}

uma_joker {
    id = "tm_opera_o", name = "T.M Opera O", group = "other", x = 54, rarity = 3, cost = 8,
    text = {
        "{C:green}#5# in #6#{} chance for {C:attention}Base Chips and Mult X#7#",
        "{C:green}#8# in #9#{} chance instead if you own {C:attention}Meisho Doto",
    },
    vars = function(card)
        local n1, d1 = odds_vars(card, "ocafe_opera", OPERA_ODDS)
        local n2, d2 = odds_vars(card, "ocafe_opera_doto", OPERA_DOTO_ODDS)
        return { n1, d1, OPERA_X, n2, d2 }
    end,
    no_current = true,
    score = function(card)
        local doto = owns("meisho_doto")
        local seed = doto and "ocafe_opera_doto" or "ocafe_opera"
        if roll(card, seed, doto and OPERA_DOTO_ODDS or OPERA_ODDS) then
            return announce("X" .. OPERA_X .. "!", G.C.GOLD, base_ret(card, OPERA_X))
        end
        return base_ret(card, 1)
    end,
}

uma_joker {
    id = "meisho_doto", name = "Meisho Doto", group = "other", x = 22, rarity = 2, cost = 6,
    text = {
        "{C:green}#5# in #6#{} chance to {C:red}fall{} and not activate",
        "that hand",
        "{C:green}#7# in #8#{} chance for {C:attention}Base Chips and Mult X#9#",
    },
    vars = function(card)
        local n1, d1 = odds_vars(card, "ocafe_doto_fall", DOTO_FALL_ODDS)
        local n2, d2 = odds_vars(card, "ocafe_doto_lucky", DOTO_LUCKY_ODDS)
        return { n1, d1, n2, d2, DOTO_X }
    end,
    no_current = true,
    score = function(card)
        if roll(card, "ocafe_doto_fall", DOTO_FALL_ODDS) then
            return { message = "Fell!", colour = G.C.RED }
        end
        if roll(card, "ocafe_doto_lucky", DOTO_LUCKY_ODDS) then
            return announce("X" .. DOTO_X .. "!", G.C.GOLD, base_ret(card, DOTO_X))
        end
        return base_ret(card, 1)
    end,
}

-- Many independent rolls each hand. Board changes happen in `before`; the scoring
-- results are saved in extra.fx / cash / win and paid out when she scores.
uma_joker {
    id = "matikanefukukitaru", name = "Matikanefukukitaru", group = "other", x = 55, rarity = 3, cost = 10,
    text = {
        "{C:green}#5# in #6#{}: {C:attention}Base Chips and Mult X5",
        "{C:green}#7# in #8#{}: create {C:attention}Shiraoki's Blessing",
        "{C:green}#9# in #10#{}: {C:attention}Blessed{} on a random played card",
        "{C:green}#11# in #12#{}: {C:attention}Base Chips and Mult X50",
        "{C:green}#13# in #14#{}: {C:red}self destruct",
        "{C:green}#15# in #16#{}: {C:attention}X10 Base{} for {C:attention}every{} Joker",
        "{C:green}#17# in #18#{}: gain {C:money}$30",
        "{C:green}#19# in #20#{}: {C:attention}Blessed{} on every played card",
        "{C:green}#21# in #22#{}: {C:attention}win the round",
    },
    vars = function(card)
        local vars = {}
        for _, r in ipairs(FUKU) do
            local n, d = odds_vars(card, "ocafe_fuku_" .. r[1], r[2])
            vars[#vars + 1] = n
            vars[#vars + 1] = d
        end
        return vars
    end,
    no_current = true,
    blueprint = false,
    on_before = function(card, context)
        local ex = card.ability.extra
        ex.fx, ex.cash, ex.win = 1, false, false
        local function hit(name) return roll(card, "ocafe_fuku_" .. name, FUKU_ODDS[name]) end
        local msgs = {}
        local hand = {}
        for _, c in ipairs(context.full_hand or {}) do hand[#hand + 1] = c end

        if hit("x5") then
            ex.fx = ex.fx * 5
            msgs[#msgs + 1] = { "X5!", G.C.GOLD }
        end
        if hit("blessing") and consumable_room() then
            spawn_consumable(BLESSING_KEY)
            msgs[#msgs + 1] = { "Blessing!", G.C.SECONDARY_SET.Tarot }
        end
        if hit("blessed_one") and #hand > 0 then
            bless_cards({ pseudorandom_element(hand, pseudoseed("ocafe_fuku_pick")) })
            msgs[#msgs + 1] = { "Blessed!", G.C.GOLD }
        end
        if hit("x50") then
            ex.fx = ex.fx * 50
            msgs[#msgs + 1] = { "X50!", G.C.GOLD }
        end
        if hit("die") and destroy_joker(card) then
            msgs[#msgs + 1] = { "Gone...", G.C.RED }
        end
        if hit("x10_all") then
            G.GAME.ocafe_all_x = { x = 10, token = hand_token() }
            msgs[#msgs + 1] = { "X10 for all!", G.C.GOLD }
        end
        if hit("cash") then ex.cash = true end
        if hit("blessed_all") then
            bless_cards(hand)
            msgs[#msgs + 1] = { "Blessed all!", G.C.GOLD }
        end
        if hit("win") then ex.win = true end
        return chain(msgs)
    end,
    score = function(card)
        local ex = card.ability.extra
        local ret = base_ret(card, ex.fx or 1)
        if ex.cash then ret.dollars = 30 end
        if ex.win then
            local needed = math.max(0, G.GAME.blind.chips - G.GAME.chips)
            ret.extra = { message = "Fate!", colour = G.C.GOLD, extra = { score = needed } }
        end
        if (ex.fx or 1) > 1 then
            ret = announce("X" .. ex.fx .. "!", G.C.GOLD, ret)
        end
        return ret
    end,
}

uma_joker {
    id = "rice_shower", name = "Rice Shower", group = "other", x = 23, rarity = 2, cost = 5,
    text = {
        "{C:chips}+#5#{} more Chips per hand",
        "{C:chips}+#6#{} instead if you own {C:attention}Haru Urara",
    },
    vars = function() return { RICE_CHIPS, RICE_DUO_CHIPS } end,
    extra_stats = function() return owns("haru_urara") and RICE_DUO_CHIPS or RICE_CHIPS, 0 end,
}

uma_joker {
    id = "haru_urara", name = "Haru Urara", group = "other", x = 24, rarity = 2, cost = 5,
    text = {
        "{C:mult}+#5#{} more Mult per hand",
        "{C:mult}+#6#{} instead if you own {C:attention}Rice Shower",
    },
    vars = function() return { HARU_MULT, HARU_DUO_MULT } end,
    extra_stats = function() return 0, owns("rice_shower") and HARU_DUO_MULT or HARU_MULT end,
}

-- Triples the first Uma Musume Joker that activates after a successful roll (see the
-- global hook above).
uma_joker {
    id = "agnes_digital", name = "Agnes Digital", group = "other", x = 56, rarity = 3, cost = 8,
    text = {
        "{C:green}#5# in #6#{} chance each hand to {C:attention}triple{} the",
        "ability of the first {C:attention}Uma Musume{} Joker to activate",
        "{C:green}#7# in #8#{} chance each hand to create a",
        "{C:tarot}Digital Fan Club{} {C:inactive}(Must have room)",
    },
    vars = function(card)
        local n1, d1 = odds_vars(card, "ocafe_digital_triple", DIGITAL_TRIPLE_ODDS)
        local n2, d2 = odds_vars(card, "ocafe_digital_club", DIGITAL_CLUB_ODDS)
        return { n1, d1, n2, d2 }
    end,
    blueprint = false,
    on_before = function(card, context)
        local msgs = {}
        if roll(card, "ocafe_digital_triple", DIGITAL_TRIPLE_ODDS) then
            local other = false
            for _, j in ipairs(G.jokers.cards) do
                if j ~= card and not j.debuff and UMA_SET[j.config.center.key] then other = true end
            end
            if other then
                G.GAME.ocafe_digital = hand_token()
                msgs[#msgs + 1] = { "Triple!", G.C.PURPLE }
            end
        end
        if roll(card, "ocafe_digital_club", DIGITAL_CLUB_ODDS) and consumable_room() then
            spawn_consumable(FAN_CLUB_KEY)
            msgs[#msgs + 1] = { "Fan Club!", G.C.SECONDARY_SET.Tarot }
        end
        return chain(msgs)
    end,
}

----------------------------------------------------------------
-- TAROTS
-- a.pool: creates a random Joker from that list (needs a free Joker slot)
-- a.hidden: never appears in shops or packs (the Omni-Box can still make it)
----------------------------------------------------------------
local function uma_tarot(a)
    SMODS.Consumable {
        key = a.id,
        set = "Tarot",
        atlas = "uma_tarots",
        pos = { x = a.x, y = 0 },
        cost = a.cost,
        cursed_coin_immune = true,
        in_pool = a.hidden and function() return false end or nil,
        loc_txt = { name = a.name, text = a.text },
        loc_vars = function(self, info_queue, card)
            add_info("c_ocafe_" .. a.id, info_queue)
            return {}
        end,
        can_use = a.can_use or function(self, card)
            return joker_room() and true or false
        end,
        use = a.use or function(self, card, area, copier)
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.4,
                func = function()
                    play_sound("timpani")
                    SMODS.add_card { key = pseudorandom_element(a.pool, pseudoseed("ocafe_" .. a.id)) }
                    card:juice_up(0.3, 0.5)
                    return true
                end
            }))
            delay(0.6)
        end
    }
end

-- a Tarot that summons one Negative Joker (no room needed)
local function summon_use(joker_key)
    return function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = joker_key, edition = "e_negative" }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
end

uma_tarot {
    id = "scout", name = "Scout", x = 0, cost = 3, pool = UMA_KEYS,
    text = { "Creates a random {C:attention}Uma Musume", "Joker", "{C:inactive}(Must have room)" },
}

uma_tarot {
    id = "goldships_shenanigans", name = "Goldship's Shenanigans", x = 1, cost = 3, pool = SPICA_KEYS,
    text = { "Creates a random {C:attention}Team Spica", "Joker", "{C:inactive}(Must have room)" },
}

uma_tarot {
    id = "turbos_charm", name = "Turbo's Charm", x = 2, cost = 3, pool = CANNOPUS_KEYS,
    text = { "Creates a random {C:attention}Team Cannopus", "Joker", "{C:inactive}(Must have room)" },
}

uma_tarot {
    id = "uraras_motivation", name = "Urara's Motivation", x = 3, cost = 3, pool = OTHER_KEYS,
    text = { "Creates a random {C:attention}Other", "{C:attention}Uma Musume{} Joker", "{C:inactive}(Must have room)" },
}

uma_tarot {
    id = "healthcare_coupon", name = "Healthcare Coupon", x = 4, cost = 3,
    text = {
        "Negates one {C:red}bad roll{} (explosion)",
        "of {C:attention}Agnes Tachyon",
        "{C:inactive}(Needs Agnes Tachyon)",
    },
    can_use = function(self, card)
        return G.jokers and next(SMODS.find_card(jk("agnes_tachyon"))) ~= nil
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                G.GAME.ocafe_coupons = (G.GAME.ocafe_coupons or 0) + 1
                play_sound("timpani")
                card:juice_up(0.3, 0.5)
                local tachyon = SMODS.find_card(jk("agnes_tachyon"))[1]
                if tachyon then
                    card_eval_status_text(tachyon, "extra", nil, nil, nil,
                        { message = "Covered!", colour = G.C.GREEN })
                end
                return true
            end
        }))
        delay(0.6)
    end
}

uma_tarot {
    id = "shiraokis_blessing", name = "Shiraoki's Blessing", x = 5, cost = 4, hidden = true,
    text = { "Summons a {C:dark_edition}Negative", "{C:attention}Matikanefukukitaru" },
    can_use = function(self, card) return G.jokers ~= nil end,
    use = summon_use(jk("matikanefukukitaru")),
}

uma_tarot {
    id = "digital_fan_club", name = "Digital Fan Club", x = 6, cost = 4, hidden = true,
    text = { "Summons a {C:dark_edition}Negative", "{C:attention}Agnes Digital" },
    can_use = function(self, card) return G.jokers ~= nil end,
    use = summon_use(jk("agnes_digital")),
}
