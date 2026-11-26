-- Oreo Cafe Balatro
-- Objects are auto-prefixed with "ocafe" (from metadata.json):
--   Enhancements: m_ocafe_red_antiseptic, m_ocafe_meteor, m_ocafe_camo
--   Jokers (common -> legendary):
--                 j_ocafe_coin_flip, j_ocafe_cursed_coin, j_ocafe_encrusted_arrowhead,
--                 j_ocafe_las_vegas, j_ocafe_uss_wichita, j_ocafe_score_chains,
--                 j_ocafe_povidone_cookie, j_ocafe_mini_oreo, j_ocafe_maxwell
--                 j_ocafe_mario_luigi
--                 j_ocafe_russian_roulette, j_ocafe_bonus_coin, j_ocafe_printer, j_ocafe_d20
--   Items:        c_ocafe_syrup, c_ocafe_super_syrup, c_ocafe_ultra_syrup, c_ocafe_max_syrup
--   Boosters:     p_ocafe_item_normal, p_ocafe_item_jumbo, p_ocafe_item_mega
--   Seals:        ocafe_bomb, ocafe_snack, ocafe_star
--   Tarots:       c_ocafe_encrustation, c_ocafe_omni_box
--   Spectral:     c_ocafe_mini_oreo774, c_ocafe_maxwellthegamer99, c_ocafe_warp_pipe
--   Decks:        b_ocafe_mini_oreo_deck, b_ocafe_maxwell_deck
--   Weapons:      c_ocafe_peashooter, spread, chaser, lobber, charge, roundabout,
--                 crackshot, converge, twist_up
--   Weapon packs: p_ocafe_weapon_normal, p_ocafe_weapon_jumbo, p_ocafe_weapon_mega
--   Stacking:     stack.lua draws neighbouring Negative copies of a Joker as one stack (visual only)
--   Papa's Counter: papas.lua adds an ORDERS button to the shop (customers = Jimbo in outfits) and a
--                 KITCHEN minigame during the next round (Pizzeria/Scooperia/Donuteria/Cupcakeria/Freezeria)
--   Girls und Panzer (everything lives in gup.lua, loaded at the bottom of this file):
--                 m_ocafe_plot_armor, c_ocafe_panzer_vor, c_ocafe_production, and 16 jokers
--                 (miho, mako, yukari, saori, hana, maho, erika, kay, anchovy, pepperoni,
--                  l3_33, katyusha, nonna, darjeeling, rosehip, crusader_iii)
--   Uma Musume (everything lives in uma.lua, loaded at the bottom of this file):
--                 m_ocafe_blessed, 7 Tarots (scout, goldships_shenanigans, turbos_charm, uraras_motivation,
--                 healthcare_coupon, shiraokis_blessing, digital_fan_club) and 20 jokers:
--                 Team Spica (special_week, silence_suzuka, daiwa_scarlet, vodka, gold_ship, tokai_teio,
--                 mejiro_mcqueen), Team Cannopus (nice_nature, matikanetannhauser, twin_turbo, ikuno_dictus),
--                 Others (agnes_tachyon, manhattan_cafe, jungle_pocket, tm_opera_o, meisho_doto,
--                 matikanefukukitaru, rice_shower, haru_urara, agnes_digital)
--                 Art: uma_jokers.png / uma_tarots.png / uma_enhancements.png (placeholder)

-- Crackshot needs Steamodded's Joker retriggering
SMODS.current_mod.optional_features = { retrigger_joker = true }

----------------------------------------------------------------
-- ATLASES  (assets/1x/<file> and assets/2x/<file>, 71x95 per cell)
----------------------------------------------------------------
-- jokers.png:       sorted by rarity (common -> uncommon -> rare -> legendary)
--                   Common:    x=0 L3/33 | x=1 Crusader III
--                   Uncommon:  x=2 Coin Flip | x=3 Cursed Coin | x=4 Bonus Coin | x=5 Mako | x=6 Yukari
--                              x=7 Saori | x=8 Hana | x=9 Erika | x=10 Kay | x=11 Pepperoni | x=12 Nonna
--                   Rare:      x=13 Encrusted Arrow Head | x=14 Las Vegas | x=15 USS Wichita | x=16 Score Chains
--                              x=17 Russian Roulette | x=18 Printer | x=19 D20 | x=20 Miho | x=21 Maho
--                              x=22 Anchovy | x=23 Katyusha | x=24 Darjeeling | x=25 Rosehip
--                   Legendary: x=26 Povidone-Iodine Cookie | x=27 Mini Oreo | x=28 Maxwell | x=29 Mario & Luigi
--                   (the Girls und Panzer jokers, L3/33 and Crusader III included, are placeholder art)
SMODS.Atlas { key = "jokers",       path = "jokers.png",       px = 71, py = 95 }
-- enhancements.png: x=0 Red Antiseptic | x=1 Meteor | x=2 Camo
--                   (Meteor and Camo hide the normal card face, so they need full-card art)
SMODS.Atlas { key = "enhancements", path = "enhancements.png", px = 71, py = 95 }
-- tarots.png:       x=0 Encrustation
SMODS.Atlas { key = "tarots",       path = "tarots.png",       px = 71, py = 95 }
-- spectrals.png:    x=0 Omni-Box (a Tarot, but its art lives in this sheet) | x=1 @mini_oreo774 | x=2 @maxwellthegamer99
--                   x=3 Warp Pipe (placeholder art)
SMODS.Atlas { key = "spectrals",    path = "spectrals.png",    px = 71, py = 95 }
-- decks.png:        x=0 Mini Oreo's Deck | x=1 Maxwell's Deck
SMODS.Atlas { key = "decks",        path = "decks.png",        px = 71, py = 95 }
-- items.png:        x=0 Syrup | x=1 Super Syrup | x=2 Ultra Syrup | x=3 Max Syrup   (placeholder art)
--                   x=4..12 weapons: Peashooter, Spread, Chaser, Lobber, Charge, Roundabout,
--                   Crackshot, Converge, Twist-Up                                   (placeholder art)
SMODS.Atlas { key = "items",        path = "items.png",        px = 71, py = 95 }
-- boosters.png:     x=0 Item Pack | x=1 Jumbo Item Pack | x=2 Mega Item Pack         (placeholder art)
--                   x=3 Weapon Pack | x=4 Jumbo Weapon Pack | x=5 Mega Weapon Pack  (placeholder art)
SMODS.Atlas { key = "boosters",     path = "boosters.png",     px = 71, py = 95 }
-- seals.png:        x=0 Bomb Seal | x=1 Snack Seal | x=2 Star Seal                   (placeholder art)
--                   (seals are drawn over the card face, so keep the rest transparent)
SMODS.Atlas { key = "seals",        path = "seals.png",        px = 71, py = 95 }

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local ANTISEPTIC_KEY = "m_ocafe_red_antiseptic"
local METEOR_KEY = "m_ocafe_meteor"
local CAMO_KEY = "m_ocafe_camo"

local function has_center_key(card, key)
    return card
        and card.config
        and card.config.center
        and card.config.center.key == key
end

local function is_antiseptic(card)
    return has_center_key(card, ANTISEPTIC_KEY)
end

local function count_antiseptic()
    local n = 0
    for _, c in ipairs(G.playing_cards or {}) do
        if is_antiseptic(c) then n = n + 1 end
    end
    return n
end

local function is_meteor(card)
    return has_center_key(card, METEOR_KEY)
end

-- Spade or Meteor Card (Wild cards count as Spades through is_suit)
local function is_spade_or_meteor(card)
    return card:is_suit("Spades") or SMODS.has_enhancement(card, METEOR_KEY)
end

local function maxwell_active()
    return G.jokers and next(SMODS.find_card("j_ocafe_maxwell")) ~= nil
end

-- a played card that hasn't been destroyed during scoring
local function card_alive(card)
    return card and not card.removed and not card.getting_sliced
        and not card.shattered and not card.destroyed
end

-- Turn cards into Camo Cards (Meteor Cards can't be changed, so they're skipped).
-- Returns the list of cards that were affected.
local function make_camo(cards)
    local affected = {}
    for _, c in ipairs(cards) do
        if card_alive(c) and not is_meteor(c) then
            if not has_center_key(c, CAMO_KEY) then
                c:set_ability(G.P_CENTERS[CAMO_KEY], nil, true)
            end
            c:juice_up(0.3, 0.5)
            affected[#affected + 1] = c
        end
    end
    return affected
end

-- Copy cards into the deck (same approach as DNA / Familiar)
local function duplicate_cards_to_deck(cards)
    local copies = {}
    for _, c in ipairs(cards) do
        G.playing_card = (G.playing_card and G.playing_card + 1) or 1
        local copy = copy_card(c, nil, nil, G.playing_card)
        copy:add_to_deck()
        G.deck.config.card_limit = G.deck.config.card_limit + 1
        table.insert(G.playing_cards, copy)
        G.deck:emplace(copy)
        copies[#copies + 1] = copy
    end
    if #copies > 0 then
        SMODS.calculate_context({ playing_card_added = true, cards = copies })
    end
    return copies
end

-- Weapon helpers used by hooks throughout the file (the rest is at the bottom)
local Weapons = {}

function Weapons.has(card, id)
    for _, w in ipairs(card and card.ability and card.ability.ocafe_weapons or {}) do
        if w == id then return true end
    end
    return false
end

-- a Joker with Charge does nothing during hands until activated
function Weapons.dormant(card)
    return Weapons.has(card, "charge") and not card.ability.ocafe_armed
end

-- 1X, +0.5X per hand spent charging, max 3X
function Weapons.boost(card)
    if not Weapons.has(card, "charge") then return 1 end
    return math.min(3, 1 + 0.5 * (card.ability.ocafe_charge or 0))
end

-- move Chips and Mult part of the way (0 to 1) toward their average
local function balance_part(pct)
    local avg = (hand_chips + mult) / 2
    hand_chips = mod_chips(math.floor(hand_chips + (avg - hand_chips) * pct))
    mult = mod_mult(math.floor(mult + (avg - mult) * pct))
    update_hand_text({ delay = 0 }, { chips = hand_chips, mult = mult })
end

-- destroy a Joker that used itself up
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

-- Russian Roulette overrides the 1 in 2 coins, whatever the Joker order
local function roulette_active()
    for _, c in ipairs(G.jokers and SMODS.find_card("j_ocafe_russian_roulette") or {}) do
        if not (G.STATE == G.STATES.HAND_PLAYED and Weapons.dormant(c)) then return true end
    end
    return false
end

----------------------------------------------------------------
-- HOOKS: Red Antiseptic can't be debuffed or destroyed
----------------------------------------------------------------
local set_debuff_ref = Card.set_debuff
function Card:set_debuff(should_debuff)
    if is_antiseptic(self) then
        should_debuff = false
    end
    return set_debuff_ref(self, should_debuff)
end

local start_dissolve_ref = Card.start_dissolve
function Card:start_dissolve(...)
    if is_antiseptic(self) then return end
    return start_dissolve_ref(self, ...)
end

local shatter_ref = Card.shatter
function Card:shatter(...)
    if is_antiseptic(self) then return end
    return shatter_ref(self, ...)
end

----------------------------------------------------------------
-- HOOK: a Meteor Card's enhancement cannot be changed
----------------------------------------------------------------
local set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
    -- `initial` is true while a card is first being created, which we always allow
    if not initial and is_meteor(self) then
        local new_key = type(center) == "string" and center or (center and center.key)
        if new_key ~= METEOR_KEY then
            return
        end
    end
    return set_ability_ref(self, center, initial, delay_sprites)
end

----------------------------------------------------------------
-- HOOK: Cursed Coin
-- When a "1 in X" roll FAILS while a Cursed Coin is owned, destroy the card
-- that triggered the roll. Only rolls that go through Steamodded's probability
-- system count, so random effects like The Emperor are untouched. Omni-Box does use it, but it
-- (and the cards it makes) are Cursed Coin immune, and consumables are never targeted.
----------------------------------------------------------------
local function cursed_coin_active()
    return G.jokers and next(SMODS.find_card("j_ocafe_cursed_coin")) ~= nil
end

local function cursed_coin_can_destroy(obj)
    if type(obj) ~= "table" or not obj.is or not obj:is(Card) then return false end
    if obj.ocafe_doomed or obj.getting_sliced then return false end
    if is_antiseptic(obj) then return false end
    local center = obj.config and obj.config.center
    if center and center.cursed_coin_immune then return false end
    -- only Jokers and playing cards (consumables are already being used up)
    return obj.ability and (obj.ability.set == "Joker" or obj.playing_card ~= nil)
end

-- Bonus Coin: the next roll succeeds (left-most) or fails (right-most), then the
-- coin is destroyed. Defined before the Cursed Coin hook so that a forced failure
-- still counts as a failure there.
local function ready_bonus_coin()
    local cards = G.jokers and G.jokers.cards
    if not cards or #cards == 0 then return nil end
    local function ready(c)
        return c and c.config and c.config.center.key == "j_ocafe_bonus_coin" and not c.debuff and not c.getting_sliced
            and not (G.STATE == G.STATES.HAND_PLAYED and Weapons.dormant(c))
    end
    -- left-most is checked first, so a lone Bonus Coin guarantees success
    if ready(cards[1]) then return cards[1], true end
    if ready(cards[#cards]) then return cards[#cards], false end
end

local bonus_probability_ref = SMODS.pseudorandom_probability
SMODS.pseudorandom_probability = function(trigger_obj, ...)
    local result = bonus_probability_ref(trigger_obj, ...)
    local coin, forced = ready_bonus_coin()
    if not coin then return result end
    local roll = SMODS.post_prob and SMODS.post_prob[#SMODS.post_prob]
    if roll then
        roll.result, roll.numerator, roll.denominator = forced, forced and 1 or 0, 1
    end
    card_eval_status_text(coin, "extra", nil, nil, nil,
        { message = forced and "Success!" or "Fail!", colour = forced and G.C.GREEN or G.C.RED })
    self_destruct(coin)
    return forced
end

local pseudorandom_probability_ref = SMODS.pseudorandom_probability
SMODS.pseudorandom_probability = function(trigger_obj, ...)
    local result = pseudorandom_probability_ref(trigger_obj, ...)
    if not result and cursed_coin_active() and cursed_coin_can_destroy(trigger_obj) then
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
-- CAMO CARDS: hidden suit
--  * The suit is real (flushes, suit Jokers and boss blinds all use it) but it
--    is re-rolled at the start of every round, and the card face never shows it
--    (the enhancement uses replace_base_card, see below).
--  * The deck screen lists Camo Cards like Meteor/Stone Cards (no rank, no suit),
--    so neither the suit rows nor the suit totals can give them away.
----------------------------------------------------------------
local CAMO_SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }

local function reroll_camo_suits()
    for _, c in ipairs(G.playing_cards or {}) do
        if has_center_key(c, CAMO_KEY) then
            SMODS.change_base(c, pseudorandom_element(CAMO_SUITS, pseudoseed("ocafe_camo")))
        end
    end
end

-- A blind is being set for a new round (not the "reset" calls at run start/end).
-- Every card is still in the deck at this point, so nothing is visibly changing.
local set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, ...)
    if blind and not reset then
        reroll_camo_suits()
        -- Mario & Luigi: one Bros. Attack per round
        if G.GAME then
            G.GAME.ocafe_bros_used = false
            G.GAME.ocafe_roundabout_used = 0
        end
    end
    return set_blind_ref(self, blind, reset, ...)
end

-- While the deck screen is being built, Camo Cards report "no suit, no rank".
local camo_hiding = false

if SMODS.has_no_suit then
    local has_no_suit_ref = SMODS.has_no_suit
    SMODS.has_no_suit = function(card, ...)
        if camo_hiding and has_center_key(card, CAMO_KEY) then return true end
        return has_no_suit_ref(card, ...)
    end
end

if SMODS.has_no_rank then
    local has_no_rank_ref = SMODS.has_no_rank
    SMODS.has_no_rank = function(card, ...)
        if camo_hiding and has_center_key(card, CAMO_KEY) then return true end
        return has_no_rank_ref(card, ...)
    end
end

local camo_hook_installed = false

local function install_camo_hook()
    if camo_hook_installed then return end
    if not (G and G.UIDEF and G.UIDEF.view_deck) then return end

    local view_deck_ref = G.UIDEF.view_deck
    G.UIDEF.view_deck = function(...)
        camo_hiding = true
        local ok, ui = pcall(view_deck_ref, ...)
        camo_hiding = false
        if not ok then error(ui) end
        return ui
    end

    camo_hook_installed = true
    if sendDebugMessage then
        sendDebugMessage("Camo deck-view hook installed", "OreoCafe")
    end
end

-- Try now; if the game isn't ready yet, install the moment a run starts.
install_camo_hook()
local start_run_ref = Game.start_run
function Game:start_run(args)
    install_camo_hook()
    return start_run_ref(self, args)
end

----------------------------------------------------------------
-- HOOK: Maxwell applies Four Fingers
----------------------------------------------------------------
if SMODS.four_fingers then
    local four_fingers_ref = SMODS.four_fingers
    SMODS.four_fingers = function(...)
        local result = four_fingers_ref(...)
        if maxwell_active() then
            if type(result) == "number" then return math.min(result, 4) end
            return true
        end
        return result
    end
else
    -- older Steamodded: Four Fingers is a plain find_joker("Four Fingers") check
    local find_joker_ref = find_joker
    function find_joker(name, ...)
        local found = find_joker_ref(name, ...)
        if name == "Four Fingers" and #found == 0 then
            local maxwells = SMODS.find_card("j_ocafe_maxwell")
            if #maxwells > 0 then return maxwells end
        end
        return found
    end
end

----------------------------------------------------------------
-- HOOK: Score Chains
-- Whenever +Chips are added, add +Mult too, and vice versa.
-- (The amount copied over is multiplied by the joker's `ratio`, default 1.)
----------------------------------------------------------------
local CHIP_KEYS = { chips = true, h_chips = true, chip_mod = true }
local MULT_KEYS = { mult = true, h_mult = true, mult_mod = true }
local in_score_chain = false

local calc_individual_ref = SMODS.calculate_individual_effect
SMODS.calculate_individual_effect = function(effect, scored_card, key, amount, from_edition)
    local ret = calc_individual_ref(effect, scored_card, key, amount, from_edition)
    if not in_score_chain
        and type(amount) == "number" and amount > 0
        and (CHIP_KEYS[key] or MULT_KEYS[key])
        and G.jokers then
        local chains = SMODS.find_card("j_ocafe_score_chains")
        local chain
        for _, c in ipairs(chains) do
            if not Weapons.dormant(c) then chain = c break end
        end
        if chain then
            local other = CHIP_KEYS[key] and "mult" or "chips"
            local ratio = (chain.ability.extra.ratio or 1) * Weapons.boost(chain)
            in_score_chain = true
            local ok, err = pcall(calc_individual_ref, effect, scored_card, other, amount * ratio, from_edition)
            in_score_chain = false
            if not ok then error(err) end
        end
    end
    return ret
end

----------------------------------------------------------------
-- ENHANCEMENTS
----------------------------------------------------------------
SMODS.Enhancement {
    key = "red_antiseptic",
    atlas = "enhancements",
    pos = { x = 0, y = 0 },
    always_scores = true,
    config = { extra = { chip_gain = 10, balance_pct = 20 } },
    loc_txt = {
        name = "Red Antiseptic Card",
        text = {
            "Cannot be {C:attention}debuffed{} or {C:attention}destroyed",
            "Always scores",
            "Gains {C:chips}+#1#{} Chips every time it scores",
            "{C:attention}Balances{} {C:chips}Chips{} and {C:mult}Mult{} by {C:attention}#2#%",
            "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.chip_gain, extra.balance_pct, card.ability.perma_bonus or 0 } }
    end,
    calculate = function(self, card, context)
        -- belt-and-braces with the set_debuff hook above
        if context.debuff_card and context.debuff_card == card then
            return { prevent_debuff = true }
        end

        if context.main_scoring and context.cardarea == G.play then
            -- permanent chips, same system Hiker uses
            card.ability.perma_bonus = (card.ability.perma_bonus or 0) + card.ability.extra.chip_gain

            local pct = card.ability.extra.balance_pct / 100
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.CHIPS,
                message_card = card,
                extra = {
                    func = function()
                        -- Plasma-Deck-style balance, but only 20% of the way to the average
                        balance_part(pct)
                    end
                }
            }
        end
    end
}

-- Built like a Stone Card: no rank, no suit, always scores, and (having no rank
-- or suit) it doesn't count toward what hand you played. The "enhancement can't
-- be changed" rule is enforced by the Card:set_ability hook above.
SMODS.Enhancement {
    key = "meteor",
    atlas = "enhancements",
    pos = { x = 1, y = 0 },
    replace_base_card = true,
    no_rank = true,
    no_suit = true,
    overrides_base_rank = true,
    always_scores = true,
    config = { bonus = 100 },
    loc_txt = {
        name = "Meteor Card",
        text = {
            "{C:chips}+#1#{} Chips",
            "No rank or suit",
            "Always scores, does not affect hand",
            "Enhancement cannot be changed"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.bonus } }
    end
}

-- Camo: replace_base_card hides the card's normal face, so its suit can't be read.
-- The suit re-roll and the deck-screen hiding are the hooks above.
SMODS.Enhancement {
    key = "camo",
    atlas = "enhancements",
    pos = { x = 2, y = 0 },
    replace_base_card = true,
    config = { bonus = 100, extra = { xmult = 2 } },
    loc_txt = {
        name = "Camo Card",
        text = {
            "{C:chips}+#1#{} Chips",
            "{X:mult,C:white}X#2#{} Mult if played hand",
            "contains a {C:attention}Flush",
            "Suit is hidden and",
            "changes every round"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.bonus, card.ability.extra.xmult } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local flush = context.poker_hands and context.poker_hands["Flush"]
            if flush and next(flush) then
                return { xmult = card.ability.extra.xmult }
            end
        end
    end
}

----------------------------------------------------------------
-- JOKERS
----------------------------------------------------------------
-- Coin Flip / Cursed Coin only touch "1 in X" rolls (anything that goes through
-- Steamodded's probability system). `fix_probability` runs after every other
-- modifier (like Oops! All 6s), so the result is always exactly 1 in 2.
SMODS.Joker {
    key = "coin_flip",
    atlas = "jokers",
    pos = { x = 2, y = 0 },
    rarity = 2,
    cost = 5,
    blueprint_compat = false,
    loc_txt = {
        name = "Coin Flip",
        text = {
            "All {C:green}probabilities{} become",
            "{C:green}1 in 2"
        }
    },
    calculate = function(self, card, context)
        if (context.mod_probability or context.fix_probability) and not roulette_active() then
            return { numerator = 1, denominator = 2 }
        end
    end
}

SMODS.Joker {
    key = "cursed_coin",
    atlas = "jokers",
    pos = { x = 3, y = 0 },
    rarity = 2,
    cost = 4,
    blueprint_compat = false,
    loc_txt = {
        name = "Cursed Coin",
        text = {
            "All {C:green}probabilities{} become",
            "{C:green}1 in 2{}, but if a probability",
            "{C:red}fails{}, destroy the card",
            "that triggered it"
        }
    },
    calculate = function(self, card, context)
        if (context.mod_probability or context.fix_probability) and not roulette_active() then
            return { numerator = 1, denominator = 2 }
        end
    end
}

SMODS.Joker {
    key = "encrusted_arrowhead",
    atlas = "jokers",
    pos = { x = 13, y = 0 },
    rarity = 3, -- Rare
    cost = 8,
    blueprint_compat = true,
    config = { extra = { chips = 50, chip_gain = 10 } },
    loc_txt = {
        name = "Encrusted Arrow Head",
        text = {
            "{C:chips}+#1#{} Chips for each scored",
            "{C:spades}Spade{} or {C:attention}Meteor Card",
            "Gains {C:chips}+#2#{} Chips if played hand only",
            "consists of scoring {C:spades}Spades{} and/or",
            "{C:attention}Meteor Cards"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[METEOR_KEY]
        return { vars = { card.ability.extra.chips, card.ability.extra.chip_gain } }
    end,
    calculate = function(self, card, context)
        -- Upgrade check: every played card scores and is a Spade or Meteor Card
        if context.before and not context.blueprint then
            local pure = #context.scoring_hand == #context.full_hand
            if pure then
                for _, c in ipairs(context.scoring_hand) do
                    if not is_spade_or_meteor(c) then
                        pure = false
                        break
                    end
                end
            end
            if pure then
                card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain
                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.CHIPS,
                    message_card = card
                }
            end
        end

        -- +Chips per scored Spade / Meteor Card
        if context.individual and context.cardarea == G.play then
            if is_spade_or_meteor(context.other_card) then
                return { chips = card.ability.extra.chips }
            end
        end
    end
}

SMODS.Joker {
    key = "las_vegas",
    atlas = "jokers",
    pos = { x = 14, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    config = { extra = { luck = 0, min_gain = 1, max_gain = 3 } },
    loc_txt = {
        name = "Las Vegas",
        text = {
            "Gains a random {C:green}+#1# to +#2# Luck",
            "at end of round",
            "{C:green}Luck{} is added to the numerator",
            "of every {C:green}probability",
            "{C:inactive}(Currently {C:green}+#3#{C:inactive} Luck)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local extra = card.ability.extra
        return { vars = { extra.min_gain, extra.max_gain, extra.luck } }
    end,
    calculate = function(self, card, context)
        if context.end_of_round and context.main_eval and not context.game_over and not context.blueprint then
            local extra = card.ability.extra
            local gain = pseudorandom("ocafe_las_vegas", extra.min_gain, extra.max_gain)
            extra.luck = extra.luck + gain
            return { message = "+" .. gain .. " Luck", colour = G.C.GREEN }
        end

        if context.mod_probability and card.ability.extra.luck > 0 then
            return { numerator = context.numerator + card.ability.extra.luck }
        end
    end
}

SMODS.Joker {
    key = "uss_wichita",
    atlas = "jokers",
    pos = { x = 15, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    config = {
        extra = {
            chips = 50, mult = 5, guns = 3,
            one_odds = 5, two_odds = 15, broadside_odds = 25, camo_odds = 5
        }
    },
    loc_txt = {
        name = "USS Wichita",
        text = {
            "{C:green}#1# in #2#{} chance to fire one turret (3 guns)",
            "{C:green}#3# in #4#{} chance to fire two turrets",
            "{C:green}#5# in #6#{} chance to fire a broadside (3 turrets)",
            "Each gun hits a scoring card: {C:chips}+#7#{} Chips,",
            "{C:mult}+#8#{} Mult per card hit",
            "{C:green}#9# in #10#{} chance for a hit card to become {C:attention}Camo"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[CAMO_KEY]
        local ex = card.ability.extra
        local n1, d1 = SMODS.get_probability_vars(card, 1, ex.one_odds, "ocafe_wichita_one")
        local n2, d2 = SMODS.get_probability_vars(card, 1, ex.two_odds, "ocafe_wichita_two")
        local n3, d3 = SMODS.get_probability_vars(card, 1, ex.broadside_odds, "ocafe_wichita_broadside")
        local n4, d4 = SMODS.get_probability_vars(card, 1, ex.camo_odds, "ocafe_wichita_camo")
        return { vars = { n1, d1, n2, d2, n3, d3, ex.chips, ex.mult, n4, d4 } }
    end,
    calculate = function(self, card, context)
        local ex = card.ability.extra

        -- Fire! The three rolls are independent and their turrets add up.
        if context.before and not context.blueprint then
            local turrets = 0
            if SMODS.pseudorandom_probability(card, "ocafe_wichita_one", 1, ex.one_odds, "ocafe_wichita_one") then
                turrets = turrets + 1
            end
            if SMODS.pseudorandom_probability(card, "ocafe_wichita_two", 1, ex.two_odds, "ocafe_wichita_two") then
                turrets = turrets + 2
            end
            if SMODS.pseudorandom_probability(card, "ocafe_wichita_broadside", 1, ex.broadside_odds, "ocafe_wichita_broadside") then
                turrets = turrets + 3
            end
            if turrets > 0 then
                -- every gun hits a different scoring card, up to the number of cards
                local pool = {}
                for _, c in ipairs(context.scoring_hand) do pool[#pool + 1] = c end
                pseudoshuffle(pool, pseudoseed("ocafe_wichita_aim"))
                local shots = math.min(turrets * ex.guns, #pool)
                for i = 1, shots do
                    pool[i].ocafe_hit = true
                end
                return { message = turrets >= 3 and "Broadside!" or "Fire!", colour = G.C.RED }
            end
        end

        -- Hit cards give their bonus when they score
        if context.individual and context.cardarea == G.play
            and context.other_card and context.other_card.ocafe_hit then
            return { chips = ex.chips, mult = ex.mult }
        end

        -- After scoring: hit cards may turn into Camo Cards, and the marks are cleared
        if context.after and not context.blueprint then
            local to_camo = {}
            for _, c in ipairs(context.scoring_hand) do
                if c.ocafe_hit then
                    c.ocafe_hit = nil
                    if SMODS.pseudorandom_probability(card, "ocafe_wichita_camo", 1, ex.camo_odds, "ocafe_wichita_camo")
                        and card_alive(c) and not is_meteor(c) then
                        to_camo[#to_camo + 1] = c
                    end
                end
            end
            if #to_camo > 0 then
                G.E_MANAGER:add_event(Event({
                    func = function()
                        make_camo(to_camo)
                        return true
                    end
                }))
            end
        end
    end
}

SMODS.Joker {
    key = "score_chains",
    atlas = "jokers",
    pos = { x = 16, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    -- ratio: how much of the amount is copied across (0.5 = half the amount)
    config = { extra = { ratio = 0.5 } },
    loc_txt = {
        name = "Score Chains",
        text = {
            "Whenever {C:chips}Chips{} increase, {C:mult}Mult",
            "increases by half that amount",
            "and vice versa"
        }
    }
    -- the effect itself lives in the SMODS.calculate_individual_effect hook near the top
}

SMODS.Joker {
    key = "povidone_cookie",
    atlas = "jokers",
    pos = { x = 26, y = 0 },
    rarity = 4, -- Legendary
    cost = 8,
    blueprint_compat = true,
    config = { extra = { xchips_per = 0.5, xmult_per = 0.25 } },
    loc_txt = {
        name = "Povidone-Iodine Cookie",
        text = {
            "{C:attention}Splash{} effect: all played cards score",
            "If played hand has {C:attention}5{} cards, turn the",
            "{C:attention}first{} card into a {C:attention}Red Antiseptic Card",
            "{X:chips,C:white}+X#1#{} Chips and {X:mult,C:white}+X#2#{} Mult per",
            "{C:attention}Red Antiseptic Card{} in full deck",
            "{C:inactive}(Currently {X:chips,C:white}X#3#{C:inactive} Chips, {X:mult,C:white}X#4#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[ANTISEPTIC_KEY]
        local extra = card.ability.extra
        local n = count_antiseptic()
        return {
            vars = {
                extra.xchips_per,
                extra.xmult_per,
                1 + extra.xchips_per * n,
                1 + extra.xmult_per * n
            }
        }
    end,
    calculate = function(self, card, context)
        -- Splash: every played card scores
        if context.modify_scoring_hand then
            return { add_to_hand = true }
        end

        -- Convert the first played card when exactly 5 cards are played
        if context.before and not context.blueprint and #context.full_hand == 5 then
            local first = context.full_hand[1]
            -- a Meteor Card's enhancement can't be changed, so it is skipped
            if not is_antiseptic(first) and not is_meteor(first) then
                first:set_ability(G.P_CENTERS[ANTISEPTIC_KEY], nil, true)
                G.E_MANAGER:add_event(Event({
                    func = function()
                        first:juice_up(0.3, 0.5)
                        return true
                    end
                }))
                return { message = "Antiseptic!", colour = G.C.RED }
            end
        end

        -- Scaling X Chips / X Mult
        if context.joker_main then
            local n = count_antiseptic()
            if n > 0 then
                local extra = card.ability.extra
                return {
                    xchips = 1 + extra.xchips_per * n,
                    xmult = 1 + extra.xmult_per * n
                }
            end
        end
    end
}

SMODS.Joker {
    key = "mini_oreo",
    atlas = "jokers",
    pos = { x = 27, y = 0 },
    rarity = 4, -- Legendary
    cost = 20,
    blueprint_compat = true,
    -- read by the Cursed Coin hook near the top of this file
    cursed_coin_immune = true,
    config = { extra = { odds = 5, meteor_mult = 50 } },
    loc_txt = {
        name = "Mini Oreo",
        text = {
            "{C:attention}Splash{} effect: all played cards score",
            "Each scoring {C:attention}Meteor Card{} gives {C:mult}+#3#{} Mult",
            "At end of round, create a",
            "{C:dark_edition}Negative{} {C:tarot}Encrustation",
            "{C:green}#1# in #2#{} chance to create a",
            "{C:dark_edition}Negative{} {C:tarot}Omni-Box{} instead",
            "Cannot be destroyed by {C:attention}Cursed Coin"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        info_queue[#info_queue + 1] = G.P_CENTERS.c_ocafe_encrustation
        info_queue[#info_queue + 1] = G.P_CENTERS.c_ocafe_omni_box
        info_queue[#info_queue + 1] = G.P_CENTERS[METEOR_KEY]
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "ocafe_mini_oreo")
        return { vars = { numerator, denominator, card.ability.extra.meteor_mult } }
    end,
    calculate = function(self, card, context)
        -- Splash: every played card scores
        if context.modify_scoring_hand then
            return { add_to_hand = true }
        end

        -- each scoring Meteor Card gives +Mult
        if context.individual and context.cardarea == G.play and is_meteor(context.other_card) then
            return { mult = card.ability.extra.meteor_mult }
        end

        if context.end_of_round and context.main_eval and not context.game_over then
            local omni = SMODS.pseudorandom_probability(card, "ocafe_mini_oreo", 1, card.ability.extra.odds, "ocafe_mini_oreo")
            local key = omni and "c_ocafe_omni_box" or "c_ocafe_encrustation"
            G.E_MANAGER:add_event(Event({
                func = function()
                    SMODS.add_card { key = key, edition = "e_negative" }
                    return true
                end
            }))
            return {
                message = omni and "Omni-Box!" or "Encrustation!",
                colour = omni and G.C.SECONDARY_SET.Spectral or G.C.SECONDARY_SET.Tarot
            }
        end
    end
}

SMODS.Joker {
    key = "maxwell",
    atlas = "jokers",
    pos = { x = 28, y = 0 },
    rarity = 4, -- Legendary
    cost = 20,
    blueprint_compat = false,
    loc_txt = {
        name = "Maxwell",
        text = {
            "After the {C:attention}final hand{} of each round,",
            "turn its scoring cards into {C:attention}Camo Cards",
            "Also applies {C:attention}Four Fingers",
            "{C:inactive}Duplicates those cards if you own",
            "{C:inactive}{C:attention}USS Wichita"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[CAMO_KEY]
        info_queue[#info_queue + 1] = G.P_CENTERS.j_four_fingers
        return {}
    end,
    calculate = function(self, card, context)
        -- hands_left is already 0 while the final hand of the round is being scored
        if context.after and not context.blueprint and G.GAME.current_round.hands_left == 0 then
            local targets = {}
            for _, c in ipairs(context.scoring_hand) do
                if card_alive(c) and not is_meteor(c) then
                    targets[#targets + 1] = c
                end
            end
            if #targets > 0 then
                local duplicate = next(SMODS.find_card("j_ocafe_uss_wichita")) ~= nil
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local affected = make_camo(targets)
                        if duplicate then
                            duplicate_cards_to_deck(affected)
                        end
                        return true
                    end
                }))
                return { message = duplicate and "Camo + Copies!" or "Camo!", colour = G.C.GREEN }
            end
        end
    end
}

----------------------------------------------------------------
-- MARIO & LUIGI
--  * BP (max 50) lives on the joker. Bros. Attacks spend it, Syrups refill it.
--  * Bros. Attacks are used from a "BROS." button on the joker (during a blind),
--    one per round, and hand out three new Seals.
--  * Items are a new consumable type that only exists in Item Packs, and Item
--    Packs only show up in the shop while Mario & Luigi is owned.
--  State that isn't tied to one card is kept on G.GAME (saved with the run):
--    ocafe_bros_used    a Bros. Attack was used this round
--    ocafe_snack_active a Snack Basket batch is still out in the deck
--    ocafe_star_rounds  rounds left on Falling Star (nil = not active)
--    ocafe_star_played  Star Seals scored since Falling Star was used
----------------------------------------------------------------
local ML_KEY = "j_ocafe_mario_luigi"
local SEAL_BOMB, SEAL_SNACK, SEAL_STAR = "ocafe_bomb", "ocafe_snack", "ocafe_star"

-- Tuning knobs
local ML_MAX_BP = 50
local BOMB_XMULT = 2        -- Bomb Seal: X Mult when it scores
local SNACK_XMULT = 5       -- X Mult on the next hand once every Snack Seal is gone
local STAR_X_PER = 1        -- X Chips and X Mult gained per Star Seal played (total = 1 + this * stars)
local STAR_ROUNDS = 5       -- the round Falling Star is used in counts as round 1

local BROS = {
    bomb_derby   = { name = "Bomb Derby",   cost = 20, desc = "Give 10 cards in your full deck a Bomb Seal" },
    snack_basket = { name = "Snack Basket", cost = 10, desc = "Give 5 cards in your full deck a Snack Seal" },
    falling_star = { name = "Falling Star", cost = 40, desc = "Give all cards in your full deck a Star Seal" },
}
local BROS_ORDER = { "bomb_derby", "snack_basket", "falling_star" }

local function find_ml()
    if not G.jokers then return nil end
    return SMODS.find_card(ML_KEY)[1]
end

local function count_seal(key)
    local n = 0
    for _, c in ipairs(G.playing_cards or {}) do
        if c.seal == key then n = n + 1 end
    end
    return n
end

-- Give a seal to `amount` random cards of the full deck (nil = every card).
-- The seal always replaces whatever seal a card already has (Red, Gold, other
-- Mario & Luigi seals...). Cards that already carry this exact seal are skipped
-- so every pick is a real change. Returns how many cards were chosen.
local function give_seals(seal_key, amount)
    local pool = {}
    for _, c in ipairs(G.playing_cards or {}) do
        if c.seal ~= seal_key then pool[#pool + 1] = c end
    end
    local targets = pool
    if amount then
        pseudoshuffle(pool, pseudoseed("ocafe_seal_" .. seal_key))
        targets = {}
        for i = 1, math.min(amount, #pool) do targets[i] = pool[i] end
    end
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.3,
        func = function()
            play_sound("gold_seal", 1.2, 0.4)
            for _, c in ipairs(targets) do
                if card_alive(c) then
                    c:set_seal(seal_key, true, true)
                    if c.area == G.hand then c:juice_up(0.3, 0.4) end
                end
            end
            -- Falling Star can paint over the last Snack Seals: cancel that batch
            -- (no payout) so it can't count as "all Snack Seals removed"
            if seal_key ~= SEAL_SNACK and G.GAME.ocafe_snack_active and count_seal(SEAL_SNACK) == 0 then
                G.GAME.ocafe_snack_active = false
            end
            return true
        end
    }))
    return #targets
end

local function pop_seal(card)
    card:set_seal(nil, true, true)
    card:juice_up(0.3, 0.5)
end

----------------------------------------------------------------
-- SEALS
----------------------------------------------------------------
SMODS.Seal {
    key = "bomb",
    atlas = "seals",
    pos = { x = 0, y = 0 },
    badge_colour = HEX("2B2B2B"),
    loc_txt = {
        label = "Bomb Seal",
        name = "Bomb Seal",
        text = {
            "{X:mult,C:white}X#1#{} Mult when this card",
            "scores, then remove this seal"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { BOMB_XMULT } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            pop_seal(card)
            return { xmult = BOMB_XMULT }
        end
    end
}

SMODS.Seal {
    key = "snack",
    atlas = "seals",
    pos = { x = 1, y = 0 },
    badge_colour = HEX("E88C28"),
    loc_txt = {
        label = "Snack Seal",
        name = "Snack Seal",
        text = {
            "Removed when this card scores",
            "Once {C:attention}all{} Snack Seals are gone,",
            "{C:attention}Mario & Luigi{} give {X:mult,C:white}X#1#{} Mult",
            "on the next hand played"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { SNACK_XMULT } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            pop_seal(card)
            return { message = "Yum!", colour = G.C.FILTER }
        end
    end
}

SMODS.Seal {
    key = "star",
    atlas = "seals",
    pos = { x = 2, y = 0 },
    badge_colour = HEX("F2C230"),
    loc_txt = {
        label = "Star Seal",
        name = "Star Seal",
        text = {
            "Removed when this card scores",
            "After {C:attention}#1#{} rounds, remove all Star Seals",
            "{C:attention}Mario & Luigi{} gain {X:chips,C:white}X#2#{} Chips and {X:mult,C:white}X#2#{} Mult",
            "per Star Seal played, on the next hand"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { STAR_ROUNDS, STAR_X_PER } }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            G.GAME.ocafe_star_played = (G.GAME.ocafe_star_played or 0) + 1
            pop_seal(card)
            return { message = "Star!", colour = G.C.GOLD }
        end
    end
}

----------------------------------------------------------------
-- ITEMS (consumable type only found in Item Packs, see BOOSTER PACKS at the bottom)
----------------------------------------------------------------
SMODS.ConsumableType {
    key = "MLItem",
    primary_colour = HEX("D9402F"),
    secondary_colour = HEX("2F9E4F"),
    collection_rows = { 4 },
    shop_rate = 0, -- never shows up as a shop card, only inside Item Packs
    default = "c_ocafe_syrup",
    loc_txt = {
        name = "Item",
        collection = "Items",
        undiscovered = {
            name = "Not Discovered",
            text = { "Purchase or use this", "card in an unseeded run", "to learn what it does" }
        }
    }
}

local SYRUPS = {
    { key = "syrup",       name = "Syrup",       bp = 10,  x = 0, cost = 3 },
    { key = "super_syrup", name = "Super Syrup", bp = 20,  x = 1, cost = 4 },
    { key = "ultra_syrup", name = "Ultra Syrup", bp = 35,  x = 2, cost = 5 },
    { key = "max_syrup",   name = "Max Syrup",   bp = nil, x = 3, cost = 6 }, -- nil = all BP
}

for _, s in ipairs(SYRUPS) do
    SMODS.Consumable {
        key = s.key,
        set = "MLItem",
        atlas = "items",
        pos = { x = s.x, y = 0 },
        cost = s.cost,
        cursed_coin_immune = true,
        loc_txt = {
            name = s.name,
            text = {
                s.bp and ("Regain {C:attention}" .. s.bp .. "{} BP") or "Regain {C:attention}all{} BP",
                "{C:inactive}(Needs Mario & Luigi)"
            }
        },
        loc_vars = function(self, info_queue, card)
            info_queue[#info_queue + 1] = G.P_CENTERS[ML_KEY]
            return {}
        end,
        can_use = function(self, card)
            return find_ml() ~= nil
        end,
        use = function(self, card, area, copier)
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.4,
                func = function()
                    local ml = find_ml()
                    if ml then
                        local ex = ml.ability.extra
                        local before = ex.bp
                        ex.bp = s.bp and math.min(ex.max_bp, ex.bp + s.bp) or ex.max_bp
                        play_sound("timpani")
                        ml:juice_up(0.3, 0.5)
                        card_eval_status_text(ml, "extra", nil, nil, nil,
                            { message = "+" .. (ex.bp - before) .. " BP", colour = G.C.GREEN })
                    end
                    return true
                end
            }))
            delay(0.6)
        end
    }
end

----------------------------------------------------------------
-- BROS. ATTACK BUTTON + MENU
----------------------------------------------------------------
-- Why an attack can't be used right now (nil = it can)
local function attack_block_reason(key)
    local ml = find_ml()
    if not ml then return "No Mario & Luigi" end
    if G.STATE ~= G.STATES.SELECTING_HAND then return "Only during a blind" end
    if G.GAME.ocafe_bros_used then return "Already used this round" end
    if ml.ability.extra.bp < BROS[key].cost then return "Not enough BP" end
    if key == "snack_basket" and G.GAME.ocafe_snack_active then return "Snack Seals still in the deck" end
    if key == "falling_star" and G.GAME.ocafe_star_rounds then return "Stars are still falling" end
    return nil
end

G.FUNCS.ocafe_can_open_bros = function(e)
    if G.STATE == G.STATES.SELECTING_HAND and not G.GAME.ocafe_bros_used then
        e.config.colour = G.C.RED
        e.config.button = "ocafe_bros_menu"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

G.FUNCS.ocafe_can_attack = function(e)
    if not attack_block_reason(e.config.ref_table.attack) then
        e.config.colour = G.C.RED
        e.config.button = "ocafe_bros_attack"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

local function text_row(str, scale, colour)
    return { n = G.UIT.R, config = { align = "cm" }, nodes = {
        { n = G.UIT.T, config = { text = str, scale = scale, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true } }
    } }
end

local function attack_button(key)
    local atk = BROS[key]
    return { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
        { n = G.UIT.C, config = {
            align = "cm", minw = 6, minh = 1, padding = 0.1, r = 0.1, hover = true, shadow = true,
            colour = G.C.RED, button = "ocafe_bros_attack", func = "ocafe_can_attack",
            ref_table = { attack = key }
        }, nodes = {
            text_row(atk.name .. "  (" .. atk.cost .. " BP)", 0.45),
            text_row(atk.desc, 0.3)
        } }
    } }
end

G.FUNCS.ocafe_bros_menu = function(e)
    local ml = e.config.ref_table
    local ex = ml.ability.extra
    local contents = {
        text_row("Bros. Attack", 0.7),
        text_row("BP: " .. ex.bp .. " / " .. ex.max_bp .. "  (one attack per round)", 0.4),
    }
    for _, key in ipairs(BROS_ORDER) do
        contents[#contents + 1] = attack_button(key)
    end
    G.FUNCS.overlay_menu {
        definition = create_UIBox_generic_options { back_func = "exit_overlay_menu", contents = contents }
    }
end

G.FUNCS.ocafe_bros_attack = function(e)
    local key = e.config.ref_table.attack
    if attack_block_reason(key) then return end
    local ml = find_ml()
    G.FUNCS.exit_overlay_menu()

    ml.ability.extra.bp = ml.ability.extra.bp - BROS[key].cost
    G.GAME.ocafe_bros_used = true

    if key == "bomb_derby" then
        give_seals(SEAL_BOMB, 10)
    elseif key == "snack_basket" then
        if give_seals(SEAL_SNACK, 5) > 0 then G.GAME.ocafe_snack_active = true end
    else -- falling_star
        give_seals(SEAL_STAR)
        G.GAME.ocafe_star_rounds = STAR_ROUNDS
        G.GAME.ocafe_star_played = 0
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.2,
        func = function()
            ml:juice_up(0.4, 0.6)
            card_eval_status_text(ml, "extra", nil, nil, nil, { message = BROS[key].name .. "!", colour = G.C.RED })
            return true
        end
    }))
end

-- Add the BROS. button next to Sell when Mario & Luigi is selected
local function bros_button(card)
    return { n = G.UIT.R, config = { align = "cl" }, nodes = {
        { n = G.UIT.C, config = {
            ref_table = card, align = "cr", padding = 0.1, r = 0.08, minw = 1.25, hover = true, shadow = true,
            colour = G.C.RED, button = "ocafe_bros_menu", func = "ocafe_can_open_bros"
        }, nodes = {
            { n = G.UIT.B, config = { w = 0.1, h = 0.6 } },
            { n = G.UIT.C, config = { align = "tm" }, nodes = {
                { n = G.UIT.R, config = { align = "cm", maxw = 1.25 }, nodes = {
                    { n = G.UIT.T, config = { text = "BROS.", colour = G.C.UI.TEXT_LIGHT, scale = 0.4, shadow = true } }
                } }
            } }
        } }
    } }
end

local ml_ui_hook_installed = false

local function install_ml_ui_hook()
    if ml_ui_hook_installed then return end
    if not (G and G.UIDEF and G.UIDEF.use_and_sell_buttons) then return end

    local use_and_sell_ref = G.UIDEF.use_and_sell_buttons
    G.UIDEF.use_and_sell_buttons = function(card, ...)
        local t = use_and_sell_ref(card, ...)
        if card and card.config and card.config.center and card.config.center.key == ML_KEY
            and card.area == G.jokers then
            local ok, rows = pcall(function() return t.nodes[1].nodes end)
            if ok and type(rows) == "table" then
                rows[#rows + 1] = bros_button(card)
            end
        end
        return t
    end
    ml_ui_hook_installed = true
end

install_ml_ui_hook()
local ml_start_run_ref = Game.start_run
function Game:start_run(args)
    install_ml_ui_hook()
    return ml_start_run_ref(self, args)
end

----------------------------------------------------------------
-- THE JOKER
----------------------------------------------------------------
-- Small status lines under the description (BP is shown in the text itself)
local function ml_status_rows(card)
    local rows = {}
    local function add(str)
        rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm" }, nodes = {
            { n = G.UIT.T, config = { text = str, colour = G.C.UI.TEXT_INACTIVE, scale = 0.28 } }
        } }
    end
    local ex = card.ability.extra
    local g = G.GAME
    if ex.snack_pending then
        add("Next hand: X" .. SNACK_XMULT .. " Mult")
    elseif g and g.ocafe_snack_active then
        add("Snack Seals left: " .. count_seal(SEAL_SNACK))
    end
    if ex.star_pending and ex.star_pending > 0 then
        local x = 1 + STAR_X_PER * ex.star_pending
        add("Next hand: X" .. x .. " Chips & Mult")
    elseif g and g.ocafe_star_rounds then
        add("Falling Star: " .. g.ocafe_star_rounds .. " rd left, " .. (g.ocafe_star_played or 0) .. " played")
    end
    if g and g.ocafe_bros_used then
        add("Bros. Attack used this round")
    end
    if #rows == 0 then return nil end
    return { { n = G.UIT.C, config = { align = "bm", minh = 0.4 }, nodes = rows } }
end

SMODS.Joker {
    key = "mario_luigi",
    atlas = "jokers",
    pos = { x = 29, y = 0 },
    rarity = 4, -- Legendary
    cost = 20,
    blueprint_compat = false,
    config = { extra = { bp = ML_MAX_BP, max_bp = ML_MAX_BP, snack_pending = false, star_pending = 0 } },
    loc_txt = {
        name = "Mario & Luigi",
        text = {
            "{C:attention}BP{}: {C:attention}#1#{} / {C:attention}#2#",
            "Use one {C:attention}Bros. Attack{} per round",
            "{C:attention}Bomb Derby{} ({C:attention}#3#{} BP), {C:attention}Snack Basket{}",
            "({C:attention}#4#{} BP), {C:attention}Falling Star{} ({C:attention}#5#{} BP)",
            "{C:attention}Item Packs{} can appear in the shop"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_SEALS[SEAL_BOMB]
        info_queue[#info_queue + 1] = G.P_SEALS[SEAL_SNACK]
        info_queue[#info_queue + 1] = G.P_SEALS[SEAL_STAR]
        local ex = card.ability.extra
        return {
            vars = { ex.bp, ex.max_bp, BROS.bomb_derby.cost, BROS.snack_basket.cost, BROS.falling_star.cost },
            main_end = ml_status_rows(card)
        }
    end,
    calculate = function(self, card, context)
        if context.blueprint then return end
        local ex = card.ability.extra

        -- The stored bonuses pay out on the next hand played
        if context.joker_main then
            local effects = {}
            if ex.snack_pending then
                ex.snack_pending = false
                effects[#effects + 1] = { xmult = SNACK_XMULT }
            end
            if ex.star_pending > 0 then
                local x = 1 + STAR_X_PER * ex.star_pending
                ex.star_pending = 0
                effects[#effects + 1] = { xchips = x }
                effects[#effects + 1] = { xmult = x }
            end
            if #effects > 0 then
                for i = 1, #effects - 1 do effects[i].extra = effects[i + 1] end
                return effects[1]
            end
            return
        end

        -- Bookkeeping only runs on one Mario & Luigi
        if find_ml() ~= card then return end

        -- Every Snack Seal is gone (scored or destroyed): bank X Mult for the next hand.
        -- Checked after scoring so the bonus lands on the *next* hand, not this one.
        local function snack_done()
            return G.GAME.ocafe_snack_active and count_seal(SEAL_SNACK) == 0
        end

        if context.after and snack_done() then
            G.GAME.ocafe_snack_active = false
            ex.snack_pending = true
            return { message = "Snack time!", colour = G.C.FILTER }
        end

        if context.end_of_round and context.main_eval and not context.game_over then
            local msgs = {}
            if snack_done() then
                G.GAME.ocafe_snack_active = false
                ex.snack_pending = true
                msgs[#msgs + 1] = "Snack time!"
            end
            if G.GAME.ocafe_star_rounds then
                G.GAME.ocafe_star_rounds = G.GAME.ocafe_star_rounds - 1
                if G.GAME.ocafe_star_rounds <= 0 then
                    -- time's up: strip the leftover Star Seals, bank the stars that were played
                    for _, c in ipairs(G.playing_cards or {}) do
                        if c.seal == SEAL_STAR then c:set_seal(nil, true, true) end
                    end
                    ex.star_pending = G.GAME.ocafe_star_played or 0
                    G.GAME.ocafe_star_rounds = nil
                    G.GAME.ocafe_star_played = 0
                    if ex.star_pending > 0 then msgs[#msgs + 1] = "Starlight!" end
                end
            end
            if #msgs > 0 then
                return { message = table.concat(msgs, " "), colour = G.C.GOLD }
            end
        end
    end
}

----------------------------------------------------------------
-- LUCK JOKERS
----------------------------------------------------------------
local ROULETTE_ODDS = 100

SMODS.Joker {
    key = "russian_roulette",
    atlas = "jokers",
    pos = { x = 17, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    loc_txt = {
        name = "Russian Roulette",
        text = {
            "All {C:green}probabilities{} become",
            "{C:green}1 in 1",
            "After each hand, a {C:attention}1 in #1#",
            "chance to {C:red}end the game"
        }
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { ROULETTE_ODDS } }
    end,
    calculate = function(self, card, context)
        if context.mod_probability or context.fix_probability then
            return { numerator = 1, denominator = 1 }
        end
        -- a plain random number, so nothing that changes probabilities can touch it
        if context.after and not context.blueprint and not context.retrigger_joker then
            if pseudorandom("ocafe_roulette", 1, ROULETTE_ODDS) == 1 then
                G.GAME.ocafe_roulette_dead = true
                return { message = "BANG!", colour = G.C.RED }
            end
            return { message = "Click", colour = G.C.UI.TEXT_INACTIVE }
        end
    end
}

-- The game ends at the next calm moment, so scoring events can't undo it
local roulette_update_ref = Game.update
function Game:update(dt)
    roulette_update_ref(self, dt)
    if G.STAGE == G.STAGES.RUN and G.GAME and G.GAME.ocafe_roulette_dead
        and (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.SHOP
            or G.STATE == G.STATES.BLIND_SELECT) then
        G.GAME.ocafe_roulette_dead = nil
        G.STATE = G.STATES.GAME_OVER
        G.STATE_COMPLETE = false
    end
end

SMODS.Joker {
    key = "bonus_coin",
    atlas = "jokers",
    pos = { x = 4, y = 0 },
    rarity = 2,
    cost = 5,
    blueprint_compat = false,
    eternal_compat = false,
    loc_txt = {
        name = "Bonus Coin",
        text = {
            "{C:attention}Left-most{}: the next {C:green}probability",
            "is guaranteed to {C:green}succeed",
            "{C:attention}Right-most{}: the next {C:green}probability",
            "is guaranteed to {C:red}fail",
            "{C:red}Self destructs{} after use"
        }
    }
    -- the effect lives in the SMODS.pseudorandom_probability hook near the top
}

SMODS.Joker {
    key = "printer",
    atlas = "jokers",
    pos = { x = 18, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = false,
    config = { extra = { copies = 2, odds = 4 } },
    loc_txt = {
        name = "Printer",
        text = {
            "When another Joker is {C:attention}sold{},",
            "create {C:attention}#1#{} copies of it",
            "{C:inactive}(Must have room)",
            "{C:green}#2# in #3#{} chance to",
            "{C:red}self destruct{} after printing"
        }
    },
    loc_vars = function(self, info_queue, card)
        local n, d = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "ocafe_printer")
        return { vars = { card.ability.extra.copies, n, d } }
    end,
    calculate = function(self, card, context)
        local sold = context.selling_card and context.card
        if not sold or sold == card or context.blueprint or card.getting_sliced
            or not (sold.ability and sold.ability.set == "Joker") then
            return
        end
        -- copy now, while the sold Joker still exists
        local copies = {}
        for i = 1, card.ability.extra.copies do copies[i] = copy_card(sold) end
        G.E_MANAGER:add_event(Event({
            blocking = false,
            func = function()
                -- wait for the sold Joker to leave, so its slot is free
                if not sold.removed and sold.area == G.jokers then return false end
                local made = 0
                for _, copy in ipairs(copies) do
                    local negative = copy.edition and copy.edition.negative
                    if not card.getting_sliced
                        and (negative or #G.jokers.cards < G.jokers.config.card_limit) then
                        copy:add_to_deck()
                        G.jokers:emplace(copy)
                        copy:start_materialize()
                        made = made + 1
                    else
                        copy:remove()
                    end
                end
                if made > 0 then
                    card_eval_status_text(card, "extra", nil, nil, nil, { message = "Printed!", colour = G.C.FILTER })
                    if SMODS.pseudorandom_probability(card, "ocafe_printer", 1, card.ability.extra.odds, "ocafe_printer") then
                        self_destruct(card)
                    end
                end
                return true
            end
        }))
    end
}

-- Rolls with a plain random number, so probability changes don't affect it
SMODS.Joker {
    key = "d20",
    atlas = "jokers",
    pos = { x = 19, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    loc_txt = {
        name = "D20",
        text = {
            "Rolls a {C:attention}20-sided die{} every hand",
            "{C:attention}1{}: hand is not scored",
            "{C:attention}2-10{}: halve {C:chips}Chips{} and {C:mult}Mult",
            "{C:attention}11-19{}: double {C:chips}Chips{} and {C:mult}Mult",
            "{C:attention}20{}: win the round",
            "{C:inactive}(Ignores probability changes)"
        }
    },
    calculate = function(self, card, context)
        if context.blueprint or context.retrigger_joker then return end

        -- rolled when the hand is played (check = true is only the preview)
        if context.debuff_hand then
            if not context.check then
                card.ocafe_roll = pseudorandom("ocafe_d20", 1, 20)
            end
            if not context.check and card.ocafe_roll == 1 then
                return { debuff = true, debuff_text = "D20 rolled a 1!" }
            end
            return
        end

        if context.before and card.ocafe_roll then
            return { message = "Rolled " .. card.ocafe_roll, colour = G.C.PURPLE }
        end

        if context.final_scoring_step and card.ocafe_roll then
            local roll = card.ocafe_roll
            if roll == 20 then
                return {
                    message = "Natural 20!", colour = G.C.GOLD,
                    extra = { score = math.max(0, G.GAME.blind.chips - G.GAME.chips) }
                }
            elseif roll > 1 then
                local x = roll >= 11 and 2 or 0.5
                return { xchips = x, extra = { xmult = x } }
            end
        end

        if context.after then card.ocafe_roll = nil end
    end
}

----------------------------------------------------------------
-- TAROTS
----------------------------------------------------------------
SMODS.Consumable {
    key = "encrustation",
    set = "Tarot",
    atlas = "tarots",
    pos = { x = 0, y = 0 },
    cost = 3,
    cursed_coin_immune = true,
    config = { max_highlighted = 2 },
    loc_txt = {
        name = "Encrustation",
        text = {
            "Turns up to {C:attention}#1#{} selected",
            "cards into {C:attention}Meteor Cards"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[METEOR_KEY]
        return { vars = { card.ability.max_highlighted } }
    end,
    can_use = function(self, card)
        return G.hand
            and #G.hand.highlighted >= 1
            and #G.hand.highlighted <= card.ability.max_highlighted
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("tarot1")
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        local count = #G.hand.highlighted
        for i = 1, count do
            local percent = 1.15 - (i - 0.999) / (count - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.15,
                func = function()
                    G.hand.highlighted[i]:flip()
                    play_sound("card1", percent)
                    G.hand.highlighted[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        delay(0.2)
        for i = 1, count do
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.1,
                func = function()
                    G.hand.highlighted[i]:set_ability(G.P_CENTERS[METEOR_KEY])
                    return true
                end
            }))
        end
        for i = 1, count do
            local percent = 0.85 + (i - 0.999) / (count - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.15,
                func = function()
                    G.hand.highlighted[i]:flip()
                    play_sound("tarot2", percent, 0.6)
                    G.hand.highlighted[i]:juice_up(0.3, 0.3)
                    return true
                end
            }))
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.2,
            func = function()
                G.hand:unhighlight_all()
                return true
            end
        }))
        delay(0.5)
    end
}

SMODS.Consumable {
    key = "mini_oreo774",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 1, y = 0 },
    cost = 3,
    cursed_coin_immune = true,
    loc_txt = {
        name = "@mini_oreo774",
        text = {
            "Creates {C:attention}Mini Oreo",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.j_ocafe_mini_oreo
        return {}
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards < G.jokers.config.card_limit
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = "j_ocafe_mini_oreo" }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

SMODS.Consumable {
    key = "maxwellthegamer99",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 2, y = 0 },
    cost = 3,
    cursed_coin_immune = true,
    loc_txt = {
        name = "@maxwellthegamer99",
        text = {
            "Creates {C:attention}Maxwell",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.j_ocafe_maxwell
        return {}
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards < G.jokers.config.card_limit
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = "j_ocafe_maxwell" }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

SMODS.Consumable {
    key = "warp_pipe",
    set = "Spectral",
    atlas = "spectrals",
    pos = { x = 3, y = 0 },
    cost = 4,
    cursed_coin_immune = true,
    loc_txt = {
        name = "Warp Pipe",
        text = {
            "Creates {C:attention}Mario & Luigi",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[ML_KEY]
        return {}
    end,
    can_use = function(self, card)
        return G.jokers and #G.jokers.cards < G.jokers.config.card_limit
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                play_sound("timpani")
                SMODS.add_card { key = ML_KEY }
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

----------------------------------------------------------------
-- SPECTRAL
----------------------------------------------------------------
SMODS.Consumable {
    key = "omni_box",
    set = "Tarot",
    atlas = "spectrals",
    pos = { x = 0, y = 0 },
    cost = 4,
    -- read by the Cursed Coin hook near the top of this file
    cursed_coin_immune = true,
    config = { extra = { odds = 10 } },
    loc_txt = {
        name = "Omni-Box",
        text = {
            "Creates a random {C:tarot}Tarot{} card",
            "added by this mod",
            "{C:green}#1# in #2#{} chance to create a {C:spectral}Spectral",
            "card added by this mod instead",
            "{C:inactive}(Must have room)"
        }
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "ocafe_omni_box")
        return { vars = { numerator, denominator } }
    end,
    can_use = function(self, card)
        return G.consumeables
            and (#G.consumeables.cards < G.consumeables.config.card_limit or card.area == G.consumeables)
    end,
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.4,
            func = function()
                -- 1 in 10 for a Spectral, otherwise a Tarot (this mod's cards only, never the Omni-Box itself)
                local want_spectral = SMODS.pseudorandom_probability(card, "ocafe_omni_box", 1, card.ability.extra.odds, "ocafe_omni_box")
                local function build_pool(set)
                    local pool = {}
                    for _, center in ipairs(G.P_CENTER_POOLS[set] or {}) do
                        if center.key:find("^c_ocafe_") and center.key ~= "c_ocafe_omni_box" then
                            pool[#pool + 1] = center.key
                        end
                    end
                    return pool
                end
                local pool = build_pool(want_spectral and "Spectral" or "Tarot")
                if #pool == 0 then pool = build_pool(want_spectral and "Tarot" or "Spectral") end
                if #pool > 0 then
                    play_sound("timpani")
                    SMODS.add_card { key = pseudorandom_element(pool, pseudoseed("ocafe_omni_box")) }
                end
                card:juice_up(0.3, 0.5)
                return true
            end
        }))
        delay(0.6)
    end
}

----------------------------------------------------------------
-- DECK
----------------------------------------------------------------
SMODS.Back {
    key = "mini_oreo_deck",
    atlas = "decks",
    pos = { x = 0, y = 0 },
    config = { consumables = { "c_ocafe_mini_oreo774" } },
    loc_txt = {
        name = "Mini Oreo's Deck",
        text = {
            "Start with {C:attention}26{} cards:",
            "{C:attention}13{} {C:spades}Spades{} and {C:attention}13{} other cards",
            "Non-Spades become {C:attention}Meteor Cards",
            "Start with an {C:spectral}@mini_oreo774"
        }
    },
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                -- Keep all 13 Spades, plus exactly one non-Spade per rank
                -- (the suit cycles Hearts/Clubs/Diamonds by rank).
                local other_suits = { "Hearts", "Clubs", "Diamonds" }
                for _, c in ipairs(G.playing_cards) do
                    if c.base.suit == "Spades" then
                        -- keep as-is
                    elseif c.base.suit == other_suits[(c.base.id % 3) + 1] then
                        c:set_ability(G.P_CENTERS[METEOR_KEY], true)
                    else
                        c.to_remove = true
                    end
                end
                local i = 1
                while i <= #G.playing_cards do
                    if G.playing_cards[i].to_remove then
                        G.playing_cards[i]:remove()
                    else
                        i = i + 1
                    end
                end
                G.GAME.starting_deck_size = #G.playing_cards
                return true
            end
        }))
    end
}

SMODS.Back {
    key = "maxwell_deck",
    atlas = "decks",
    pos = { x = 1, y = 0 },
    config = { consumables = { "c_ocafe_maxwellthegamer99" } },
    loc_txt = {
        name = "Maxwell's Deck",
        text = {
            "Start with {C:attention}40{} cards ({C:attention}10{} per suit)",
            "{C:hearts}Hearts{} and {C:diamonds}Diamonds{} grant {C:mult}+10{} Mult",
            "{C:spades}Spades{} and {C:clubs}Clubs{} grant {C:chips}+100{} Chips",
            "Start with an {C:spectral}@maxwellthegamer99"
        }
    },
    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                -- 40 cards, 10 per suit: no Jacks, Queens or Kings (like Abandoned Deck)
                for _, c in ipairs(G.playing_cards) do
                    local id = c.base.id
                    if id == 11 or id == 12 or id == 13 then
                        c.to_remove = true
                    end
                end
                local i = 1
                while i <= #G.playing_cards do
                    if G.playing_cards[i].to_remove then
                        G.playing_cards[i]:remove()
                    else
                        i = i + 1
                    end
                end
                G.GAME.starting_deck_size = #G.playing_cards
                return true
            end
        }))
    end,
    calculate = function(self, back, context)
        if context.individual and context.cardarea == G.play and context.other_card then
            local c = context.other_card
            local ret = {}
            if c:is_suit("Hearts") or c:is_suit("Diamonds") then
                ret.mult = 10
            end
            if c:is_suit("Spades") or c:is_suit("Clubs") then
                ret.chips = 100
            end
            if next(ret) then return ret end
        end
    end
}

----------------------------------------------------------------
-- WEAPONS (potions that attach to Jokers, sold in the packs further down)
----------------------------------------------------------------
--  * Weapons only come from Emporium Packs. Select one Joker, then use the potion.
--  * A Joker holds up to 2 (duplicates allowed); a third replaces the oldest.
--  * Weapons are saved on the Joker, so they're sold or destroyed with it.
--  Saved on card.ability:
--    ocafe_weapons  list of weapon ids
--    ocafe_armed    ACTIVATE is switched on for the next hand
--    ocafe_charge   hands spent charging
--    ocafe_twist    Twist-Up triggers this round
--    ocafe_stored   score banked by Roundabout
do

-- Tuning knobs
local PEA_PCT = 0.05
local SPREAD_PCT, SPREAD_MAX = 0.20, 5
local CHASER_CHIPS, CHASER_MULT = 30, 10
local LOBBER_CHIPS, LOBBER_BOUNCES, LOBBER_ODDS = 60, 4, 2
local ROUNDABOUT_CAP = 0.99
local CRACK_ODDS = 2
local CONVERGE_CARDS, CONVERGE_XMULT, CONVERGE_CHIPS = 3, 2, 30
local TWIST_CHIPS = 20
local WEAPON_COST = 4 -- each weapon adds half of this to the Joker's sell value

local LIST = {
    { id = "peashooter", name = "Peashooter", text = {
        "Adds {C:attention}" .. (PEA_PCT * 100) .. "%{} of the Blind's",
        "requirement every hand played" } },
    { id = "spread", name = "Spread", text = {
        "After this Joker triggers, {C:attention}balance",
        "{C:attention}" .. (SPREAD_PCT * 100) .. "%{} of {C:chips}Chips{} and {C:mult}Mult",
        "{C:inactive}(Max " .. SPREAD_MAX .. " times per hand)" } },
    { id = "chaser", name = "Chaser", text = {
        "{C:chips}+" .. CHASER_CHIPS .. "{} Chips and {C:mult}+" .. CHASER_MULT .. "{} Mult",
        "for each played card",
        "that doesn't score" } },
    { id = "lobber", name = "Lobber", text = {
        "After this Joker triggers, {C:chips}+" .. LOBBER_CHIPS .. "{} Chips",
        "Chance to bounce for another {C:chips}+" .. LOBBER_CHIPS,
        "{C:green}1 in " .. LOBBER_ODDS .. "{} (base), up to {C:attention}" .. LOBBER_BOUNCES .. "{} bounces" } },
    { id = "charge", name = "Charge", text = {
        "This Joker does nothing during hands",
        "until {C:attention}activated",
        "{C:attention}+50%{} effect per hand spent",
        "charging, max {C:attention}3X" } },
    { id = "roundabout", name = "Roundabout", text = {
        "Stores excess score from Blinds",
        "{C:attention}Activate{} to add it to a hand",
        "{C:inactive}(Max " .. (ROUNDABOUT_CAP * 100) .. "% of the Blind)" } },
    { id = "crackshot", name = "Crackshot", text = {
        "{C:green}1 in " .. CRACK_ODDS .. "{} (base) chance to",
        "{C:attention}retrigger{} this Joker" } },
    { id = "converge", name = "Converge", text = {
        "{X:mult,C:white}X" .. CONVERGE_XMULT .. "{} Mult if {C:attention}" .. CONVERGE_CARDS .. "{} or fewer",
        "cards score, otherwise",
        "{C:chips}+" .. CONVERGE_CHIPS .. "{} Chips" } },
    { id = "twist_up", name = "Twist-Up", text = {
        "Each time this Joker triggers,",
        "gain {C:chips}+" .. TWIST_CHIPS .. "{} Chips",
        "Resets at end of round" } },
}

local BY_ID = {}
for i, w in ipairs(LIST) do
    w.index = i - 1
    w.key = "c_ocafe_" .. w.id
    BY_ID[w.id] = w
end

-- row 0 = first weapon slot (bottom left), row 1 = second slot (bottom right)
SMODS.Atlas { key = "weapon_icons", path = "weapon_icons.png", px = 71, py = 95 }

----------------------------------------------------------------
-- Attaching
----------------------------------------------------------------
local function attach(joker, id)
    local a = joker.ability
    a.ocafe_weapons = a.ocafe_weapons or {}
    local value = math.floor(WEAPON_COST / 2)
    if #a.ocafe_weapons >= 2 then
        table.remove(a.ocafe_weapons, 1)
        a.extra_value = (a.extra_value or 0) - value
    end
    table.insert(a.ocafe_weapons, id)
    a.extra_value = (a.extra_value or 0) + value
    -- drop state belonging to a weapon that was just replaced
    if not Weapons.has(joker, "charge") then a.ocafe_charge = nil end
    if not Weapons.has(joker, "roundabout") then a.ocafe_stored = nil end
    if not Weapons.has(joker, "twist_up") then a.ocafe_twist = nil end
    if not (Weapons.has(joker, "charge") or Weapons.has(joker, "roundabout")) then a.ocafe_armed = nil end
    joker:set_cost()
end

SMODS.ConsumableType {
    key = "CupWeapon",
    primary_colour = HEX("7B4FB5"),
    secondary_colour = HEX("B5652F"),
    collection_rows = { 5, 4 },
    shop_rate = 0, -- only inside Emporium Packs
    default = "c_ocafe_peashooter",
    loc_txt = {
        name = "Weapon",
        collection = "Weapons",
        undiscovered = {
            name = "Not Discovered",
            text = { "Purchase or use this", "card in an unseeded run", "to learn what it does" }
        }
    }
}

for _, w in ipairs(LIST) do
    local text = {}
    for _, line in ipairs(w.text) do text[#text + 1] = line end

    SMODS.Consumable {
        key = w.id,
        set = "CupWeapon",
        atlas = "items",
        pos = { x = 4 + w.index, y = 0 },
        cost = WEAPON_COST,
        discovered = true,
        cursed_coin_immune = true,
        loc_txt = { name = w.name, text = text },
        can_use = function(self, card)
            return G.jokers ~= nil and #G.jokers.highlighted == 1
        end,
        use = function(self, card, area, copier)
            local target = G.jokers.highlighted[1]
            if not target then return end
            G.E_MANAGER:add_event(Event({
                trigger = "after", delay = 0.4,
                func = function()
                    attach(target, w.id)
                    play_sound("tarot1")
                    target:juice_up(0.4, 0.5)
                    card_eval_status_text(target, "extra", nil, nil, nil,
                        { message = w.name .. "!", colour = G.C.PURPLE })
                    G.jokers:unhighlight_all()
                    return true
                end
            }))
            delay(0.6)
        end
    }
end

----------------------------------------------------------------
-- Effects
----------------------------------------------------------------
local function count_weapon(card, id)
    local n = 0
    for _, w in ipairs(card.ability.ocafe_weapons or {}) do
        if w == id then n = n + 1 end
    end
    return n
end

-- contexts where "this Joker triggered" means something
local function is_trigger_context(context)
    return context and not context.end_of_round
        and (context.before or context.individual or context.repetition
            or context.joker_main or context.other_joker) and true or false
end

-- contexts a charging Joker sits out
local function is_hand_context(context)
    if context.end_of_round then return false end
    if is_trigger_context(context) or context.after or context.final_scoring_step
        or context.destroying_card or context.destroy_card
        or context.modify_scoring_hand or context.evaluate_poker_hand or context.debuff_hand then
        return true
    end
    return (context.mod_probability or context.fix_probability) and G.STATE == G.STATES.HAND_PLAYED
end

-- shallow copy of an effect and its `extra` chain, so we never edit a Joker's own table
local function copy_chain(effect)
    local copy = {}
    for k, v in pairs(effect) do copy[k] = v end
    if type(copy.extra) == "table" then copy.extra = copy_chain(copy.extra) end
    return copy
end

local function join(effects)
    local head, tail
    for _, e in ipairs(effects) do
        if head then tail.extra = e else head = e end
        tail = e
        while type(tail.extra) == "table" do tail = tail.extra end
    end
    return head
end

local ADD_KEYS = { "chips", "h_chips", "chip_mod", "mult", "h_mult", "mult_mod", "dollars", "p_dollars", "h_dollars" }
local X_KEYS = { "x_chips", "xchips", "Xchip_mod", "x_mult", "Xmult", "xmult", "x_mult_mod", "Xmult_mod" }
local MESSAGE_KEYS = { chip_mod = "a_chips", mult_mod = "a_mult", Xmult_mod = "a_xmult" }

-- Charge: flat bonuses are multiplied; for X effects only the part above X1 is
-- (X2 at 3X charge becomes X4)
local function boost_chain(effect, m)
    local node = effect
    while type(node) == "table" do
        for _, k in ipairs(ADD_KEYS) do
            if type(node[k]) == "number" then
                node[k] = node[k] * m
                if k:find("dollars") then node[k] = math.floor(node[k]) end
            end
        end
        for _, k in ipairs(X_KEYS) do
            if type(node[k]) == "number" and node[k] > 1 then node[k] = 1 + (node[k] - 1) * m end
        end
        if node.message then
            for k, loc in pairs(MESSAGE_KEYS) do
                if node[k] then node.message = localize { type = "variable", key = loc, vars = { node[k] } } end
            end
        end
        node = node.extra
    end
end

local function tagged(joker, effect)
    effect.card = joker
    effect.message_card = joker
    return effect
end

-- Spread, Lobber and Twist-Up: bonuses earned each time the Joker triggers
local function trigger_bonuses(joker)
    local out = {}
    for _, id in ipairs(joker.ability.ocafe_weapons) do
        if id == "spread" then
            if (joker.ocafe_spread_uses or 0) < SPREAD_MAX * count_weapon(joker, "spread") then
                joker.ocafe_spread_uses = (joker.ocafe_spread_uses or 0) + 1
                out[#out + 1] = tagged(joker, {
                    message = "Spread!", colour = G.C.PURPLE,
                    extra = { func = function() balance_part(SPREAD_PCT) end }
                })
            end
        elseif id == "lobber" then
            out[#out + 1] = tagged(joker, { chips = LOBBER_CHIPS })
            for _ = 1, LOBBER_BOUNCES do
                if not SMODS.pseudorandom_probability(joker, "ocafe_lobber", 1, LOBBER_ODDS, "ocafe_lobber") then break end
                out[#out + 1] = tagged(joker, { chips = LOBBER_CHIPS })
            end
        elseif id == "twist_up" then
            joker.ability.ocafe_twist = (joker.ability.ocafe_twist or 0) + 1
            out[#out + 1] = tagged(joker, { chips = TWIST_CHIPS * joker.ability.ocafe_twist })
        end
    end
    return out
end

-- Peashooter, Chaser, Roundabout and Converge: once per hand, on the Joker's turn
local function hand_bonuses(joker, context)
    local out = {}
    local a = joker.ability
    for _, id in ipairs(a.ocafe_weapons) do
        if id == "peashooter" then
            local amount = math.floor(G.GAME.blind.chips * PEA_PCT)
            out[#out + 1] = tagged(joker, { score = amount })
        elseif id == "chaser" then
            local missed = #context.full_hand - #context.scoring_hand
            if missed > 0 then
                out[#out + 1] = tagged(joker, { chips = CHASER_CHIPS * missed, extra = tagged(joker, { mult = CHASER_MULT * missed }) })
            end
        elseif id == "converge" then
            if #context.scoring_hand <= CONVERGE_CARDS then
                out[#out + 1] = tagged(joker, { xmult = CONVERGE_XMULT })
            else
                out[#out + 1] = tagged(joker, { chips = CONVERGE_CHIPS })
            end
        elseif id == "roundabout" and a.ocafe_armed and (a.ocafe_stored or 0) > 0 then
            -- the cap is shared by every Roundabout for the whole Blind
            local room = math.floor(G.GAME.blind.chips * ROUNDABOUT_CAP) - (G.GAME.ocafe_roundabout_used or 0)
            local amount = math.min(a.ocafe_stored, math.max(0, room))
            if amount > 0 then
                G.GAME.ocafe_roundabout_used = (G.GAME.ocafe_roundabout_used or 0) + amount
                a.ocafe_stored = 0 -- anything over the cap is lost
                out[#out + 1] = tagged(joker, { score = amount })
            end
        end
    end
    return out
end

local function end_hand(joker)
    local a = joker.ability
    if Weapons.has(joker, "charge") then
        a.ocafe_charge = a.ocafe_armed and 0 or math.min(4, (a.ocafe_charge or 0) + 1)
    end
    a.ocafe_armed = nil
    joker.ocafe_pending = nil
end

local function end_round(joker, context)
    local a = joker.ability
    if Weapons.has(joker, "twist_up") then a.ocafe_twist = 0 end
    joker.ocafe_spread_uses = 0
    joker.ocafe_pending = nil
    if Weapons.has(joker, "roundabout") and not context.game_over then
        local excess = math.floor(G.GAME.chips - G.GAME.blind.chips)
        if excess > 0 then
            a.ocafe_stored = (a.ocafe_stored or 0) + excess
            card_eval_status_text(joker, "extra", nil, nil, nil, { message = "Stored!", colour = G.C.PURPLE })
        end
    end
end

local calculate_joker_ref = Card.calculate_joker
function Card:calculate_joker(context)
    local list = self.ability and self.ability.ocafe_weapons
    if not (list and list[1]) or self.area ~= G.jokers or self.debuff then
        return calculate_joker_ref(self, context)
    end

    local main_copy = not context.blueprint and not context.retrigger_joker

    if main_copy and context.before then
        self.ocafe_spread_uses = 0
        self.ocafe_pending = nil
    end

    if Weapons.dormant(self) and is_hand_context(context) then
        if main_copy and context.after then end_hand(self) end
        return nil
    end

    local ret, triggered = calculate_joker_ref(self, context)

    -- Crackshot
    if context.retrigger_joker_check then
        if context.other_card == self and is_trigger_context(context.other_context) then
            local effects = {}
            if type(ret) == "table" then effects[1] = copy_chain(ret) end
            for _ = 1, count_weapon(self, "crackshot") do
                if SMODS.pseudorandom_probability(self, "ocafe_crackshot", 1, CRACK_ODDS, "ocafe_crackshot") then
                    effects[#effects + 1] = { repetitions = 1, message = "Crackshot!", card = self }
                end
            end
            if #effects > 0 then return join(effects), triggered end
        end
        return ret, triggered
    end

    if context.blueprint then return ret, triggered end -- copies don't copy weapons

    if type(ret) == "table" and Weapons.has(self, "charge") and is_hand_context(context) then
        ret = copy_chain(ret)
        boost_chain(ret, Weapons.boost(self))
    end

    local after_effects = {}
    if is_trigger_context(context) and (ret or triggered) and ret ~= true then
        after_effects = trigger_bonuses(self)
        -- Chips added before scoring starts (or during a retrigger check) would be
        -- lost, so they're held until the Joker's own turn
        if context.before or context.repetition then
            self.ocafe_pending = self.ocafe_pending or {}
            for _, e in ipairs(after_effects) do table.insert(self.ocafe_pending, e) end
            after_effects = {}
        end
    end

    local chain = {}
    if context.joker_main then
        for _, e in ipairs(self.ocafe_pending or {}) do chain[#chain + 1] = e end
        self.ocafe_pending = nil
    end
    if type(ret) == "table" and (#chain > 0 or #after_effects > 0 or context.joker_main) then
        chain[#chain + 1] = copy_chain(ret)
    end
    for _, e in ipairs(after_effects) do chain[#chain + 1] = e end
    if context.joker_main and not context.retrigger_joker then
        for _, e in ipairs(hand_bonuses(self, context)) do chain[#chain + 1] = e end
    end
    if #chain > 0 then ret = join(chain) end

    if main_copy then
        if context.after then end_hand(self) end
        if context.end_of_round and context.main_eval and not context.individual and not context.repetition then
            end_round(self, context)
        end
    end

    return ret, triggered
end

----------------------------------------------------------------
-- ACTIVATE button (Charge / Roundabout)
----------------------------------------------------------------
G.FUNCS.ocafe_can_activate = function(e)
    local card = e.config.ref_table
    local a = card.ability
    local status = {}
    if Weapons.has(card, "charge") then status[#status + 1] = "X" .. Weapons.boost(card) end
    if Weapons.has(card, "roundabout") then status[#status + 1] = number_format(a.ocafe_stored or 0) end
    card.ocafe_ui = card.ocafe_ui or {}
    card.ocafe_ui.label = a.ocafe_armed and "ARMED" or "ACTIVATE"
    card.ocafe_ui.status = table.concat(status, " | ")
    if G.STATE == G.STATES.SELECTING_HAND then
        e.config.colour = a.ocafe_armed and G.C.GREEN or G.C.PURPLE
        e.config.button = "ocafe_toggle_activate"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

-- press again before playing the hand to cancel
G.FUNCS.ocafe_toggle_activate = function(e)
    local card = e.config.ref_table
    card.ability.ocafe_armed = not card.ability.ocafe_armed or nil
    play_sound("tarot1")
    card:juice_up(0.3, 0.4)
end

local function activate_button(card)
    card.ocafe_ui = { label = "ACTIVATE", status = "" }
    local function line(field, scale)
        return { n = G.UIT.R, config = { align = "cm", maxw = 1.25 }, nodes = {
            { n = G.UIT.T, config = { ref_table = card.ocafe_ui, ref_value = field, colour = G.C.UI.TEXT_LIGHT, scale = scale, shadow = true } }
        } }
    end
    return { n = G.UIT.R, config = { align = "cl" }, nodes = {
        { n = G.UIT.C, config = {
            ref_table = card, align = "cr", padding = 0.1, r = 0.08, minw = 1.25, hover = true, shadow = true,
            colour = G.C.PURPLE, button = "ocafe_toggle_activate", func = "ocafe_can_activate"
        }, nodes = {
            { n = G.UIT.B, config = { w = 0.1, h = 0.6 } },
            { n = G.UIT.C, config = { align = "tm" }, nodes = { line("label", 0.35), line("status", 0.3) } }
        } }
    } }
end

----------------------------------------------------------------
-- UI: button, tooltips and bottle icons
----------------------------------------------------------------
local ui_installed = false

local function install_weapon_ui()
    if ui_installed then return end
    if not (G and G.UIDEF and G.UIDEF.use_and_sell_buttons) then return end

    local use_and_sell_ref = G.UIDEF.use_and_sell_buttons
    G.UIDEF.use_and_sell_buttons = function(card, ...)
        local t = use_and_sell_ref(card, ...)
        if card and card.area == G.jokers and (Weapons.has(card, "charge") or Weapons.has(card, "roundabout")) then
            local ok, rows = pcall(function() return t.nodes[1].nodes end)
            if ok and type(rows) == "table" then rows[#rows + 1] = activate_button(card) end
        end
        return t
    end
    ui_installed = true
end

install_weapon_ui()
local weapon_start_run_ref = Game.start_run
function Game:start_run(args)
    install_weapon_ui()
    return weapon_start_run_ref(self, args)
end

-- hovering a Joker also describes its weapons
local ability_table_ref = Card.generate_UIBox_ability_table
function Card:generate_UIBox_ability_table(...)
    local ret = ability_table_ref(self, ...)
    local list = self.ability and self.ability.ocafe_weapons
    if list and type(ret) == "table" and ret.info then
        for _, id in ipairs(list) do
            if BY_ID[id] then generate_card_ui(G.P_CENTERS[BY_ID[id].key], ret) end
        end
    end
    return ret
end

local icon_sprites = {}
SMODS.DrawStep {
    key = "weapon_icons",
    order = 55,
    func = function(card, layer)
        local list = card.ability and card.ability.ocafe_weapons
        if not list then return end
        local atlas = G.ASSET_ATLAS["ocafe_weapon_icons"]
        for slot, id in ipairs(list) do
            local w = BY_ID[id]
            if w and atlas then
                local cache = w.index .. "_" .. slot
                local sprite = icon_sprites[cache]
                -- rebuilt if the textures are reloaded (e.g. graphics settings)
                if not sprite or sprite.atlas ~= atlas then
                    sprite = Sprite(0, 0, G.CARD_W, G.CARD_H, atlas, { x = w.index, y = slot - 1 })
                    icon_sprites[cache] = sprite
                end
                sprite.role.draw_major = card
                sprite:draw_shader("dissolve", nil, nil, nil, card.children.center)
            end
        end
    end,
    conditions = { vortex = false, facing = "front" }
}

end

----------------------------------------------------------------
-- BOOSTER PACKS (boosters.png)
----------------------------------------------------------------
-- Item Packs only appear while Mario & Luigi is owned. Porkrind's Emporium
-- (weapon) packs can appear in any run.
do

local function ml_present()
    return G.jokers and next(SMODS.find_card("j_ocafe_mario_luigi")) ~= nil
end

local KINDS = {
    item = {
        set = "MLItem", group = "Item Pack", key_append = "ocafe_item_pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Item{} cards" },
        colour = "C0392B", special = "2E8B57",
        available = ml_present
    },
    weapon = {
        set = "CupWeapon", group = "Porkrind's Emporium", key_append = "ocafe_weapon_pack",
        text = { "Choose {C:attention}#1#{} of up to", "{C:attention}#2#{} {C:attention}Weapon{} potions",
            "{C:inactive}(Select a Joker to equip)" },
        colour = "6B3FA0", special = "3A2415"
    }
}

-- key, kind, name, cost, weight, choose, cards shown, column in boosters.png
local PACKS = {
    { "item_normal",   "item",   "Item Pack",         4, 2,    1, 3, 0 },
    { "item_jumbo",    "item",   "Jumbo Item Pack",   6, 1,    1, 5, 1 },
    { "item_mega",     "item",   "Mega Item Pack",    8, 0.5,  2, 5, 2 },
    { "weapon_normal", "weapon", "Weapon Pack",       4, 0.6,  1, 2, 3 },
    { "weapon_jumbo",  "weapon", "Jumbo Weapon Pack", 6, 0.3,  1, 4, 4 },
    { "weapon_mega",   "weapon", "Mega Weapon Pack",  8, 0.15, 2, 4, 5 },
}

for _, p in ipairs(PACKS) do
    local key, kind, name, cost, weight, choose, extra, x = unpack(p)
    local k = KINDS[kind]
    SMODS.Booster {
        key = key,
        kind = k.set,
        atlas = "boosters",
        pos = { x = x, y = 0 },
        cost = cost,
        weight = weight,
        discovered = kind == "weapon",
        config = { extra = extra, choose = choose },
        draw_hand = false,
        loc_txt = { name = name, text = k.text, group_name = k.group },
        loc_vars = function(self, info_queue, card)
            local cfg = (card and card.ability) or self.config
            return { vars = { cfg.choose, cfg.extra } }
        end,
        -- in_pool and a 0 weight are both used so it works on any Steamodded version
        in_pool = function(self, args)
            return not k.available or k.available()
        end,
        get_weight = function(self)
            return (not k.available or k.available()) and self.weight or 0
        end,
        create_card = function(self, card, i)
            return { set = k.set, area = G.pack_cards, skip_materialize = true, soulable = false, key_append = k.key_append }
        end,
        ease_background_colour = function(self)
            ease_background_colour { new_colour = HEX(k.colour), special_colour = HEX(k.special), contrast = 2 }
        end
    }
end

end

----------------------------------------------------------------
-- GIRLS UND PANZER (gup.lua)
----------------------------------------------------------------
assert(SMODS.load_file("gup.lua"))()

----------------------------------------------------------------
-- UMA MUSUME (uma.lua)
----------------------------------------------------------------
assert(SMODS.load_file("uma.lua"))()

----------------------------------------------------------------
-- NEGATIVE JOKER STACKING (stack.lua)
----------------------------------------------------------------
assert(SMODS.load_file("stack.lua"))()

----------------------------------------------------------------
-- PAPA'S COUNTER (papas.lua)
----------------------------------------------------------------
assert(SMODS.load_file("papas.lua"))()
