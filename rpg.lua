-- Oreo RPG (loaded from main.lua)
--
-- A turn-based RPG minigame that lives in a tab at the top of the shop, next to ORDERS.
--  * Party: pick up to 5 slots of this mod's LEGENDARY Jokers (rarity 4, found automatically).
--    Each one has its own stats, role and 4 moves (see KITS below).
--  * Card art is read from the Joker's own atlas (jokers.png), so the portraits always
--    match the real cards. Enemies are drawn the same way, from the mod's other Jokers.
--  * Starting a battle costs money. The fee and the enemies get stronger with every
--    clear. Losing (or retreating) loses the fee, so a retry costs the same fee again.
--  * A win pays out money, levels the party up, and every 3rd win (and every boss) also
--    gives a Tag.
--
--  * OREO RPG DECK (bottom of this file): beating the Ante-8 Boss Blind no longer wins the run. A FINAL BOSS
--    unlocks in this tab and defeating it is the win. Every Blind you clear trains the party (Training) and
--    leftover hands become Rations (extra starting SP), so playing Balatro well makes the RPG fights easier.
--
-- Everything that must survive saving/loading is plain data in G.GAME.ocafe_rpg:
--    cleared  battles won so far        party   keys of the chosen Jokers
--    battle   the fight in progress     last    result of the previous fight (for the lobby)

----------------------------------------------------------------
-- TUNING
----------------------------------------------------------------
local MAX_PARTY = 5          -- party slots (Mario & Luigi use two)
local MAX_FOES = 4           -- most foes in one fight
local ROSTER_PAGE = 8        -- roster cards per lobby page
local SP_REGEN = 2            -- SP a party member regains at the start of each of its turns
local BOSS_EVERY = 5          -- every Nth battle is a boss fight
local MAP_REWARD = 4          -- cash for winning a Map Deck challenge battle (no entry fee)
local REQUIRE_OWNED = false   -- true: only Legendary Jokers you currently own can join the party

local function cost_for(n) return 6 + 3 * n + math.floor(n * n / 5) end   -- entry fee
local function is_boss(n) return (n + 1) % BOSS_EVERY == 0 end
local function reward_for(n)                                              -- money for a win
    local r = cost_for(n) + 3 + n
    if is_boss(n) then r = math.floor(r * 1.5) end
    return r
end

local TAGS = { "tag_investment", "tag_voucher", "tag_charm", "tag_buffoon", "tag_standard",
    "tag_meteor", "tag_ethereal", "tag_coupon", "tag_economy", "tag_juggle" }
local BOSS_TAGS = { "tag_rare", "tag_negative", "tag_polychrome", "tag_holo", "tag_foil" }

----------------------------------------------------------------
-- PARTY KITS: stats, role and moves for every Legendary Joker
-- Move fields: cost (SP), target (enemy|enemies|ally|allies|self|random),
--   kind (hit|multi|heal|buff|gamble), power, hits, crit, stun (chance), shield (fraction of max HP),
--   fx (status turns applied to the targets: atk, def, taunt, stun)
--   extras: pierce (fraction of DEF ignored), drain (fraction of damage healed), weak (turns of "DMG dealt down"
--   on each foe hit), bite (Vampiric Bite stacks, bleeds each turn), seal (lowest-HP foe can't guard),
--   rx (turns of Experimental Prescription on the other allies), shield_self (fraction of max HP)
-- Kit fields: passive ("scalpel"), dr (flat damage reduction), counter (return-fire power while taunting),
--   units + order (one Joker that fights as several separate units, e.g. Mario & Luigi; each costs a party slot)
----------------------------------------------------------------
local KITS = {
    -- Povidone-Iodine Cookie (Cookie Run: Kingdom, Super Epic Bomber, Steel): SCOOP R&D's "Raging Scalpel".
    -- Her real skill sprays Red Antiseptic, saws foes with Vampiric Bite, then shields herself, heals the team
    -- and hands them Experimental Prescription. Her passive opens with a big shield and keeps patching herself up.
    j_ocafe_povidone_cookie = {
        role = "Battle Surgeon", hp = 100, atk = 17, def = 9, spd = 10, sp = 10, passive = "scalpel",
        moves = {
            { name = "Powerful Sawing", cost = 0, target = "enemy", kind = "hit", hits = 5, power = 0.24,
                drain = 0.3, bite = 1, biteturns = 3, tip = "5 saw cuts, drains HP, bleed" },
            { name = "Red Antiseptic", cost = 3, target = "enemies", kind = "hit", power = 0.45, stun = 0.6,
                weak = 3, seal = true, tip = "All: stun, DMG down, seals weakest" },
            { name = "Experimental Rx", cost = 4, target = "allies", kind = "heal", power = 1.2, rx = 3,
                shield_self = 0.3, tip = "Heal party, allies DMG+ DEF+, self shield" },
            { name = "Ambiguous Experiments", cost = 8, target = "enemy", kind = "experiment",
                tip = "Spray all, saw + Saw Strike, shield, heal, Rx" },
        },
    },
    -- Gacha Ticket: a one-shot gambler. 1 HP, one move, and it is spent the moment it is used.
    j_ocafe_gacha_ticket = {
        role = "One-Shot Gambler", hp = 1, fixed_hp = true, atk = 10, def = 0, spd = 14, sp = 1,
        moves = {
            { name = "Lets go gambling!", cost = 0, target = "self", kind = "gacha",
                tip = "50% JACKPOT / 50% BANKRUPT, then it's gone" },
        },
    },

    ----------------------------------------------------------------
    -- PHANTOM THIEVES OF HEARTS (phantom.lua): Persona 5. Each Thief has a free basic attack, two Persona skills
    -- and a finisher. Ren's All-Out Attack makes every living party member strike every foe.
    ----------------------------------------------------------------
    j_ocafe_ren = {
        role = "Wild Card", hp = 92, atk = 22, def = 8, spd = 13, sp = 11,
        moves = {
            { name = "Gun Barrage", cost = 0, target = "random", kind = "multi", hits = 3, power = 0.42,
                tip = "3 shots at random foes" },
            { name = "Eiha", cost = 3, target = "enemy", kind = "hit", power = 1.9, stun = 0.35, crit = 0.15,
                tip = "Curse hit, 35% stun" },
            { name = "Baton Pass", cost = 2, target = "ally", kind = "heal", power = 0.5, sp = 3, fx = { atk = 2 },
                tip = "Ally: small heal, ATK up, +3 SP" },
            { name = "All-Out Attack", cost = 8, target = "enemies", kind = "allout", power = 0.45, stun = 0.25,
                tip = "Whole party hits all foes" },
        },
    },
    j_ocafe_morgana = {
        role = "Healer / Wind", hp = 82, atk = 16, def = 8, spd = 15, sp = 12,
        moves = {
            { name = "Slingshot", cost = 0, target = "enemy", kind = "hit", power = 1.0, crit = 0.25,
                tip = "Quick shot, high crit" },
            { name = "Garula", cost = 3, target = "enemies", kind = "hit", power = 0.72, tip = "Wind hits all foes" },
            { name = "Mediarama", cost = 4, target = "allies", kind = "heal", power = 1.1, tip = "Heal the whole party" },
            { name = "Heat Riser", cost = 5, target = "allies", kind = "buff", fx = { atk = 3, def = 3 },
                tip = "Party ATK and DEF up" },
        },
    },
    j_ocafe_ryuji = {
        role = "Bruiser / Elec", hp = 110, atk = 24, def = 10, spd = 10, sp = 9,
        moves = {
            { name = "Pipe Swing", cost = 0, target = "enemy", kind = "hit", power = 1.15, tip = "Swing at one foe" },
            { name = "Skull Cracker", cost = 3, target = "enemy", kind = "hit", power = 1.9, stun = 0.4,
                tip = "Heavy hit, 40% stun" },
            { name = "Charge", cost = 3, target = "self", kind = "buff", fx = { atk = 3 }, shield = 0.1,
                tip = "ATK up, small shield" },
            { name = "Thunder Reign", cost = 7, target = "enemies", kind = "hit", power = 0.95, stun = 0.35,
                tip = "Shock all foes, 35% stun" },
        },
    },
    j_ocafe_ann = {
        role = "Glass Cannon / Fire", hp = 76, atk = 26, def = 5, spd = 12, sp = 12,
        moves = {
            { name = "Whip Lash", cost = 0, target = "enemy", kind = "hit", power = 1.05, tip = "Whip one foe" },
            { name = "Agi", cost = 2, target = "enemy", kind = "hit", power = 1.7, crit = 0.2,
                tip = "Fire, good crit chance" },
            { name = "Maragi", cost = 4, target = "enemies", kind = "hit", power = 0.85, tip = "Fire on all foes" },
            { name = "Maragidyne", cost = 7, target = "enemies", kind = "hit", power = 1.2, crit = 0.25,
                tip = "Huge fire on all foes" },
        },
    },
    j_ocafe_yusuke = {
        role = "Swordsman / Ice", hp = 86, atk = 22, def = 7, spd = 14, sp = 11,
        moves = {
            { name = "Katana Slash", cost = 0, target = "enemy", kind = "hit", power = 1.1, crit = 0.2,
                tip = "Quick slash, 20% crit" },
            { name = "Bufu", cost = 2, target = "enemy", kind = "hit", power = 1.45, stun = 0.3,
                tip = "Ice, 30% to freeze (stun)" },
            { name = "Swift Strike", cost = 4, target = "enemy", kind = "hit", hits = 2, power = 1.15, crit = 0.3,
                tip = "2 slashes, high crit" },
            { name = "Mabufula", cost = 5, target = "enemies", kind = "hit", power = 0.8, stun = 0.3,
                tip = "Ice on all foes, may freeze" },
        },
    },
    j_ocafe_makoto = {
        role = "Tank / Nuclear", hp = 108, atk = 21, def = 14, spd = 9, sp = 10,
        moves = {
            { name = "Knuckle Strike", cost = 0, target = "enemy", kind = "hit", power = 1.05, tip = "Punch one foe" },
            { name = "Rakukaja", cost = 3, target = "allies", kind = "buff", fx = { def = 3 }, shield = 0.1,
                tip = "Party DEF up, small shield" },
            { name = "Freila", cost = 4, target = "enemy", kind = "hit", power = 2.0, pierce = 0.3,
                tip = "Nuclear blast, pierces DEF" },
            { name = "Atomic Flare", cost = 8, target = "enemy", kind = "hit", power = 3.5, pierce = 0.6, crit = 0.25,
                tip = "Massive, ignores 60% DEF" },
        },
    },
    j_ocafe_futaba = {
        role = "Navigator / Support", hp = 68, atk = 15, def = 5, spd = 11, sp = 14,
        moves = {
            { name = "Pulse Scan", cost = 0, target = "enemy", kind = "hit", power = 0.85, weak = 2,
                tip = "Light hit, foe DMG down" },
            { name = "Analyze", cost = 2, target = "enemies", kind = "hit", power = 0.25, weak = 3, seal = true,
                tip = "All DMG down, seals weakest" },
            { name = "Oracle Support", cost = 5, target = "allies", kind = "heal", power = 0.8, sp = 2, fx = { atk = 2 },
                tip = "Heal party, +2 SP, ATK up" },
            { name = "Perfect Plan", cost = 7, target = "allies", kind = "buff", fx = { atk = 3, def = 3 }, shield = 0.15,
                tip = "Party ATK, DEF up, shield" },
        },
    },
    j_ocafe_haru = {
        role = "Heavy / Axe", hp = 102, atk = 23, def = 9, spd = 8, sp = 9,
        moves = {
            { name = "Axe Chop", cost = 0, target = "enemy", kind = "hit", power = 1.2, tip = "Chop one foe" },
            { name = "Gourmet Coffee", cost = 3, target = "ally", kind = "heal", power = 1.3, sp = 2,
                tip = "Heal 1 ally, +2 SP" },
            { name = "Rampage Swing", cost = 4, target = "enemies", kind = "hit", power = 0.8,
                tip = "Axe sweep hits all foes" },
            { name = "Executioner", cost = 7, target = "enemy", kind = "hit", power = 3.0, crit = 0.3,
                tip = "Heavy axe, high crit" },
        },
    },
    j_ocafe_kasumi = {
        role = "Gymnast / Speed", hp = 76, atk = 21, def = 6, spd = 16, sp = 11,
        moves = {
            { name = "Rapier Thrust", cost = 0, target = "enemy", kind = "hit", power = 1.0, crit = 0.2,
                tip = "Fast thrust, 20% crit" },
            { name = "Ribbon Flurry", cost = 3, target = "random", kind = "multi", hits = 4, power = 0.38,
                tip = "4 ribbon hits, random foes" },
            { name = "Graceful Guard", cost = 3, target = "self", kind = "buff", fx = { def = 3 }, shield = 0.2,
                tip = "DEF up, shield" },
            { name = "Grand Finale", cost = 7, target = "enemy", kind = "hit", hits = 3, power = 1.0, crit = 0.3,
                tip = "3 hits, high crit" },
        },
    },
    j_ocafe_mini_oreo = {
        role = "Striker", hp = 70, atk = 26, def = 4, spd = 14, sp = 10,
        moves = {
            { name = "Pounce", cost = 0, target = "enemy", kind = "hit", power = 1.1, tip = "Quick single hit" },
            { name = "Meteor Strike", cost = 4, target = "enemy", kind = "hit", power = 2.3, crit = 0.35,
                tip = "Heavy hit, high crit" },
            { name = "Meteor Shower", cost = 5, target = "enemies", kind = "hit", power = 0.8, tip = "Hits all foes" },
            { name = "Omni-Box", cost = 4, target = "self", kind = "gamble", tip = "Random surprise" },
        },
    },
    -- Maxwell: armor and fleet. Reinforced armor trims every hit, and while Hull Down is up his taunt
    -- makes him return fire at whatever hits him.
    j_ocafe_maxwell = {
        role = "Armor / Fleet", hp = 130, atk = 15, def = 16, spd = 7, sp = 8, dr = 0.12, counter = 0.45,
        moves = {
            { name = "Coaxial MG", cost = 0, target = "random", kind = "multi", hits = 4, power = 0.3,
                tip = "4 MG bursts, random foes" },
            { name = "Hull Down", cost = 2, target = "self", kind = "buff", fx = { def = 3, taunt = 2 }, shield = 0.25,
                tip = "Taunt, DEF up, shield, return fire" },
            { name = "AP Shell", cost = 3, target = "enemy", kind = "hit", power = 2.0, pierce = 0.6, crit = 0.2,
                tip = "Armor-piercing, ignores 60% DEF" },
            { name = "Wichita Broadside", cost = 6, target = "enemies", kind = "hit", power = 0.95, stun = 0.3,
                tip = "Cruiser broadside, 30% stun" },
        },
    },
    -- Mario & Luigi: ONE Joker, TWO fighters. Each has their own HP, SP, speed, turn and moves (and each takes
    -- one party slot), so the bros. act, get hurt and get KO'd independently.
    j_ocafe_mario_luigi = {
        role = "Bros.  (2 slots)", order = { "mario", "luigi" },
        units = {
            mario = {
                name = "Mario", role = "Striker", hp = 82, atk = 23, def = 7, spd = 12, sp = 9,
                moves = {
                    { name = "Jump", cost = 0, target = "enemy", kind = "hit", power = 1.1, tip = "Stomp one foe" },
                    { name = "Fire Flower", cost = 3, target = "enemies", kind = "hit", power = 0.65,
                        tip = "Fireballs hit all foes" },
                    { name = "Hammer Smash", cost = 4, target = "enemy", kind = "hit", power = 2.1, stun = 0.4,
                        tip = "Heavy hit, 40% stun" },
                    { name = "Super Jump", cost = 7, target = "enemy", kind = "hit", power = 3.1, crit = 0.3,
                        tip = "Huge hit, high crit" },
                },
            },
            luigi = {
                name = "Luigi", role = "Support", hp = 92, atk = 17, def = 10, spd = 11, sp = 11,
                moves = {
                    { name = "Stomp", cost = 0, target = "enemy", kind = "hit", power = 1.0, tip = "Hop on one foe" },
                    { name = "Thunderhand", cost = 3, target = "enemy", kind = "hit", power = 1.5, stun = 0.35,
                        tip = "Shock 1 foe, 35% stun" },
                    { name = "1-Up Snack", cost = 4, target = "ally", kind = "heal", power = 1.5, fx = { def = 2 },
                        tip = "Heal 1 ally, DEF up" },
                    { name = "Poltergust", cost = 5, target = "enemies", kind = "hit", power = 0.5, weak = 3,
                        tip = "Hits all, foes DMG down" },
                },
            },
        },
    },
}

-- Any future Legendary Joker without its own kit still works with this one
local GENERIC_KIT = {
    role = "Fighter", hp = 90, atk = 18, def = 8, spd = 10, sp = 10,
    moves = {
        { name = "Strike", cost = 0, target = "enemy", kind = "hit", power = 1.0, tip = "Single hit" },
        { name = "Power Strike", cost = 4, target = "enemy", kind = "hit", power = 2.0, tip = "Heavy hit" },
        { name = "Volley", cost = 4, target = "enemies", kind = "hit", power = 0.7, tip = "Hits all foes" },
        { name = "Mend", cost = 3, target = "ally", kind = "heal", power = 2.0, tip = "Heal 1 ally" },
    },
}

local TARGET_TEXT = { enemy = "1 foe", enemies = "all foes", ally = "1 ally", allies = "party",
    self = "self", random = "random foes" }

local function kit_for(key) return KITS[key] or GENERIC_KIT end

-- the kit of one BATTLE unit (a Joker like Mario & Luigi fights as several units, told apart by u.sub)
local function kit_of(u)
    local k = kit_for(u.key)
    if k.units then return k.units[u.sub or k.order[1]] end
    return k
end

local function slots_of(key)
    local k = kit_for(key)
    return k.order and #k.order or 1
end

-- enemy archetypes (picked from the Joker's position in jokers.png, so a Joker is always the same type)
local ARCH_ORDER = { "brawler", "tank", "sniper" }
local ARCH = {
    brawler = { label = "Brawler", hp = 1.0, atk = 1.15, def = 0.9, spd = 1.0 },   -- heavy swing every 3rd turn
    tank = { label = "Guardian", hp = 1.35, atk = 0.85, def = 1.5, spd = 0.8 },    -- shields itself every 3rd turn
    sniper = { label = "Sniper", hp = 0.8, atk = 1.3, def = 0.8, spd = 1.25 },     -- hunts the weakest every 3rd turn
}

----------------------------------------------------------------
-- SMALL HELPERS
----------------------------------------------------------------
local function sfx(name, pitch, vol)
    if play_sound then pcall(play_sound, name, pitch or 1, vol or 0.5) end
end

local function S()
    local g = G.GAME
    g.ocafe_rpg = g.ocafe_rpg or { cleared = 0, party = {} }
    g.ocafe_rpg.party = g.ocafe_rpg.party or {}
    return g.ocafe_rpg
end

-- Oreo RPG Deck: extra state lives in the same table (prep, rations, bosses, final_open, final_won, final_cleared)
local DECK_KEY = "b_ocafe_oreo_rpg_deck"
local RATION_CAP = 8        -- most Rations you can bank (1 per unused hand)
local TRAIN_PER = 0.02      -- party HP/ATK bonus per Training point
local TRAIN_MAX = 1.5       -- Training stops at +150%

local function deck_active()
    local back = G.GAME and G.GAME.selected_back
    local center = back and back.effect and back.effect.center
    return center ~= nil and center.key == DECK_KEY
end

local function training()
    if not (G.GAME and deck_active()) then return 0 end
    return math.min(TRAIN_MAX, TRAIN_PER * (S().prep or 0))
end

local function joker_name(center)
    local ok, n = pcall(localize, { type = "name_text", set = "Joker", key = center.key })
    if ok and type(n) == "string" and n ~= "ERROR" then return n end
    return center.name or center.key
end

-- Every Legendary Joker of this mod, in the order they appear in jokers.png
local function roster()
    local list = {}
    for _, c in ipairs((G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker) or {}) do
        if c.rarity == 4 and type(c.key) == "string" and c.key:find("^j_ocafe_") then list[#list + 1] = c end
    end
    table.sort(list, function(a, b) return ((a.pos and a.pos.x) or 0) < ((b.pos and b.pos.x) or 0) end)
    return list
end

-- Enemy art/names come from the mod's non-Legendary Jokers
local function enemy_pool()
    local list = {}
    for _, c in ipairs((G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker) or {}) do
        if c.rarity ~= 4 and type(c.key) == "string" and c.key:find("^j_ocafe_") then list[#list + 1] = c end
    end
    table.sort(list, function(a, b) return ((a.pos and a.pos.x) or 0) < ((b.pos and b.pos.x) or 0) end)
    if #list == 0 and G.P_CENTERS.j_joker then list[1] = G.P_CENTERS.j_joker end
    return list
end

local function owned(key)
    return G.jokers and next(SMODS.find_card(key)) ~= nil
end

local function party_keys()
    local keys = {}
    for _, key in ipairs(S().party) do
        if G.P_CENTERS[key] and (not REQUIRE_OWNED or owned(key)) then keys[#keys + 1] = key end
    end
    return keys
end

local function party_slots()
    local n = 0
    for _, key in ipairs(party_keys()) do n = n + slots_of(key) end
    return n
end

----------------------------------------------------------------
-- BATTLE LOGIC (plain data only, so a fight in progress is saved with the run)
----------------------------------------------------------------
local function say(b, str)
    b.log[#b.log + 1] = str
    while #b.log > 14 do table.remove(b.log, 1) end
end

local function alive(u) return u and u.hp > 0 end

local function living(list)
    local r = {}
    for i, u in ipairs(list) do if u.hp > 0 then r[#r + 1] = i end end
    return r
end

-- np = party size: a bigger party means tougher foes
local function make_enemy(center, n, boss, arch_id, np)
    local a = ARCH[arch_id]
    np = math.max(1, np or 1)
    local hp = math.floor(65 * (1 + 0.32 * n) * (1 + 0.10 * (np - 1)) * a.hp * (boss and 3.6 or 1))
    return {
        key = center.key, name = joker_name(center), arch = arch_id, boss = boss or nil,
        maxhp = hp, hp = hp,
        atk = math.floor(15 * (1 + 0.17 * n) * (1 + 0.04 * (np - 1)) * a.atk * (boss and 1.3 or 1)),
        def = math.floor(6 * (1 + 0.09 * n) * a.def),
        spd = math.max(1, math.floor(10 * a.spd * (boss and 0.9 or 1))),
        t = 0, st = {},
    }
end

local function ally_stats(key, n, sub)
    local k = kit_for(key)
    if k.units then k = k.units[sub or k.order[1]] end
    local m = 1 + 0.065 * n
    return {
        maxhp = k.fixed_hp and k.hp or math.floor(k.hp * m * (1 + training())), atk = math.floor(k.atk * m * (1 + training())),
        def = math.floor(k.def * (1 + 0.04 * n)),
        spd = k.spd, maxsp = k.sp,
    }
end

local function new_battle(final)
    local s = S()
    local n = s.cleared
    local fn = final and math.max(n, 8) or n   -- level used for the fee and the foes
    local boss = final or is_boss(n)
    local keys = party_keys()
    local b = {
        n = n, boss = boss or nil, final = final or nil, cost = cost_for(fn),
        reward = final and (reward_for(fn) * 2) or reward_for(n),
        allies = {}, enemies = {}, queue = {}, qi = 0, round = 0, log = {}, phase = "move",
    }

    -- Oreo RPG Deck: banked Rations become extra starting SP (up to +4), then they're used up
    local ration_sp = deck_active() and math.min(4, math.floor((s.rations or 0) / 2)) or 0
    for _, key in ipairs(keys) do
        local k = kit_for(key)
        for _, sub in ipairs(k.order or { false }) do
            local sk = sub and k.units[sub] or k
            local st = ally_stats(key, n, sub or nil)
            local a = {
                key = key, sub = sub or nil, name = sk.name or joker_name(G.P_CENTERS[key]), role = sk.role,
                maxhp = st.maxhp, hp = st.maxhp, atk = st.atk, def = st.def, spd = st.spd,
                maxsp = st.maxsp, sp = math.min(st.maxsp, math.floor(st.maxsp / 2) + ration_sp), st = {},
                dr = sk.dr, counter = sk.counter, passive = sk.passive,
            }
            if a.passive == "scalpel" then a.st.shield = math.floor(a.maxhp * 0.6) end
            b.allies[#b.allies + 1] = a
        end
    end

    local pool = enemy_pool()
    local function pick(i)
        local c = pool[pseudorandom("ocafe_rpg_foe" .. i, 1, #pool)]
        return c, ARCH_ORDER[(((c.pos and c.pos.x) or 0) % #ARCH_ORDER) + 1]
    end
    local count
    if boss then
        local c, arch = pick(1)
        if final then
            c = pool[#pool]
            arch = ARCH_ORDER[(((c.pos and c.pos.x) or 0) % #ARCH_ORDER) + 1]
        end
        b.enemies[1] = make_enemy(c, final and (fn + 2) or n, true, arch, #b.allies)
        if final then
            local e = b.enemies[1]
            e.final = true
            e.maxhp = math.floor(e.maxhp * 1.4)
            e.hp = e.maxhp
            e.name = "FINAL " .. e.name
        end
        -- the boss brings bodyguards: more of them for a bigger party
        count = math.min(MAX_FOES, (final and 2 or 1) + math.ceil(#b.allies / 2))
    else
        count = math.max(1, math.min(#b.allies + 1, MAX_FOES, 1 + math.ceil((n + 1) / 2)))
    end
    for i = #b.enemies + 1, count do
        local c, arch = pick(i + 1)
        b.enemies[i] = make_enemy(c, final and fn or n, false, arch, #b.allies)
    end
    -- same name twice: tell them apart with a letter
    local seen = {}
    for _, e in ipairs(b.enemies) do seen[e.name] = (seen[e.name] or 0) + 1 end
    local used = {}
    for _, e in ipairs(b.enemies) do
        if seen[e.name] > 1 then
            used[e.name] = (used[e.name] or 0) + 1
            e.name = e.name .. " " .. string.char(64 + used[e.name])
        end
    end

    say(b, (final and "FINAL BOSS BATTLE!" or (boss and "BOSS BATTLE!" or "Battle start!")))
    if deck_active() then
        say(b, "Training +" .. math.floor(training() * 100 + 0.5) .. "% HP/ATK"
            .. (ration_sp > 0 and (", Rations +" .. ration_sp .. " SP") or ""))
        s.rations = 0
    end
    for _, a in ipairs(b.allies) do
        if a.passive == "scalpel" then say(b, a.name .. "'s Raging Scalpel: opens with a big shield!") end
    end
    return b
end

-- damage: power * ATK, softened by DEF, with a little variance and crits
-- weak = "DMG dealt down", rx = Experimental Prescription (DMG up, DEF up), pierce = share of DEF ignored
local function calc_dmg(att, def, power, crit_chance, pierce)
    local atk = att.atk * (((att.st.atk or 0) > 0) and 1.3 or 1) * (((att.st.weak or 0) > 0) and 0.65 or 1)
        * (((att.st.rx or 0) > 0) and 1.35 or 1)
    local d = def.def * (((def.st.def or 0) > 0) and 1.5 or 1) * (((def.st.rx or 0) > 0) and 1.3 or 1)
        * (1 - (pierce or 0))
    local roll = 0.9 + 0.2 * pseudorandom("ocafe_rpg_roll")
    local crit = pseudorandom("ocafe_rpg_crit") < (crit_chance or 0.1)
    local dmg = power * atk * roll * (100 / (100 + d)) * (crit and 1.5 or 1)
    return math.max(1, math.floor(dmg + 0.5)), crit
end

-- shields soak damage first (armored units trim every hit before that)
local function hurt(u, dmg)
    if u.dr then dmg = math.max(1, math.floor(dmg * (1 - u.dr) + 0.5)) end
    local soak = math.min(u.st.shield or 0, dmg)
    if soak > 0 then u.st.shield = u.st.shield - soak end
    u.hp = math.max(0, u.hp - (dmg - soak))
end

local function deal(att, tgt, power, crit_chance, pierce)
    local d, crit = calc_dmg(att, tgt, power, crit_chance, pierce)
    hurt(tgt, d)
    return d, crit
end

local function heal(u, amount) u.hp = math.min(u.maxhp, u.hp + amount) end

local function apply_fx(u, fx)
    for k, v in pairs(fx or {}) do u.st[k] = math.max(u.st[k] or 0, v) end
end

-- Vampiric Bite: stacks (up to 15) that bleed the foe at the end of each of its turns
local function apply_bite(t, stacks, turns, src)
    t.st.bite = math.min(15, (t.st.bite or 0) + stacks)
    t.st.bite_t = math.max(t.st.bite_t or 0, turns)
    t.st.bite_atk = math.max(t.st.bite_atk or 0, src.atk)
end

-- end of a unit's turn: bleed, then count statuses down
local function tick(u, b)
    if b and (u.st.bite or 0) > 0 and (u.st.bite_t or 0) > 0 and u.hp > 0 then
        local d = math.max(1, math.floor(u.st.bite * 0.2 * (u.st.bite_atk or 10)))
        u.hp = math.max(0, u.hp - d)
        say(b, u.name .. " bleeds (bite x" .. u.st.bite .. "): -" .. d)
        if u.hp <= 0 then say(b, u.name .. " is down!") end
    end
    for _, k in ipairs({ "atk", "def", "taunt", "stun", "weak", "seal", "rx", "bite_t" }) do
        if (u.st[k] or 0) > 0 then u.st[k] = u.st[k] - 1 end
    end
    if (u.st.bite_t or 0) <= 0 then u.st.bite = nil end
end

-- "Healing Prevention": the weakest living foe can't use its guard (shield) for a couple of turns
local function seal_lowest(b)
    local low
    for _, i in ipairs(living(b.enemies)) do
        local e = b.enemies[i]
        if not low or e.hp < low.hp then low = e end
    end
    if low then
        low.st.seal = math.max(low.st.seal or 0, 2)
        say(b, low.name .. " is sealed (can't guard)!")
    end
end

local function try_stun(b, t, chance)
    if not chance or t.hp <= 0 then return end
    if t.boss then
        if chance >= 1 then say(b, t.name .. " resists the stun!") end
    elseif pseudorandom("ocafe_rpg_stun") < chance then
        t.st.stun = math.max(t.st.stun or 0, 1)
        say(b, t.name .. " is stunned!")
    end
end

local function down_note(b, t)
    if t.hp <= 0 then say(b, t.name .. " is down!") end
end

-- a party member's move
local function run_move(b, u, mv, ti)
    say(b, u.name .. " uses " .. mv.name .. "!")
    local kind, tg = mv.kind, mv.target

    local targets = {}
    if tg == "enemy" then
        local x = b.enemies[ti]
        if not alive(x) then x = b.enemies[living(b.enemies)[1]] end
        targets = { x }
    elseif tg == "enemies" then
        for _, i in ipairs(living(b.enemies)) do targets[#targets + 1] = b.enemies[i] end
    elseif tg == "ally" then
        local x = b.allies[ti]
        if not alive(x) then x = u end
        targets = { x }
    elseif tg == "allies" then
        for _, i in ipairs(living(b.allies)) do targets[#targets + 1] = b.allies[i] end
    elseif tg == "self" then
        targets = { u }
    end

    if kind == "hit" then
        sfx("multhit1", 0.9 + 0.2 * pseudorandom("ocafe_rpg_pitch"), 0.5)
        for _, t in ipairs(targets) do
            local total, crit = 0, false
            for _ = 1, (mv.hits or 1) do
                if t.hp > 0 then
                    local d, c = deal(u, t, mv.power, mv.crit, mv.pierce)
                    total, crit = total + d, crit or c
                end
            end
            say(b, "> " .. t.name .. " -" .. total .. (crit and " CRIT!" or ""))
            if mv.drain and total > 0 then
                local before = u.hp
                heal(u, math.floor(total * mv.drain))
                if u.hp > before then say(b, "> " .. u.name .. " drains " .. (u.hp - before) .. " HP") end
            end
            down_note(b, t)
            try_stun(b, t, mv.stun)
            if t.hp > 0 then
                if mv.weak then apply_fx(t, { weak = mv.weak }) end
                if mv.bite then apply_bite(t, mv.bite, mv.biteturns or 3, u) end
            end
        end
        if mv.seal then seal_lowest(b) end
    elseif kind == "multi" then
        sfx("multhit2", 0.9 + 0.2 * pseudorandom("ocafe_rpg_pitch"), 0.5)
        local tally, crit = {}, {}
        for _ = 1, (mv.hits or 1) do
            local live = living(b.enemies)
            if #live == 0 then break end
            local t = b.enemies[live[pseudorandom("ocafe_rpg_multi", 1, #live)]]
            local d, c = deal(u, t, mv.power, mv.crit, mv.pierce)
            tally[t] = (tally[t] or 0) + d
            crit[t] = crit[t] or c
        end
        for _, t in ipairs(b.enemies) do
            if tally[t] then
                say(b, "> " .. t.name .. " -" .. tally[t] .. (crit[t] and " CRIT!" or ""))
                down_note(b, t)
                try_stun(b, t, mv.stun)
            end
        end
    elseif kind == "heal" then
        sfx("tarot1", 1.1, 0.5)
        for _, t in ipairs(targets) do
            local amount = math.floor(mv.power * u.atk * 1.8)
            heal(t, amount)
            apply_fx(t, mv.fx)
            say(b, "> " .. t.name .. " +" .. amount .. " HP")
            if mv.sp then
                t.sp = math.min(t.maxsp, t.sp + mv.sp)
                say(b, "> " .. t.name .. " +" .. mv.sp .. " SP")
            end
        end
        if mv.rx then
            for _, i in ipairs(living(b.allies)) do
                if b.allies[i] ~= u then apply_fx(b.allies[i], { rx = mv.rx }) end
            end
            say(b, "Allies take the Prescription: DMG up, DEF up")
        end
        if mv.shield_self then
            u.st.shield = (u.st.shield or 0) + math.floor(u.maxhp * mv.shield_self)
            say(b, "> " .. u.name .. " shields herself")
        end
    elseif kind == "allout" then
        -- All-Out Attack: every living party member strikes every living foe
        sfx("multhit2", 0.75, 0.7)
        say(b, "ALL-OUT ATTACK!")
        local tally = {}
        for _, i in ipairs(living(b.allies)) do
            local a = b.allies[i]
            for _, j in ipairs(living(b.enemies)) do
                local t = b.enemies[j]
                tally[t] = (tally[t] or 0) + (deal(a, t, mv.power, mv.crit or 0.1))
            end
        end
        for _, t in ipairs(b.enemies) do
            if tally[t] then
                say(b, "> " .. t.name .. " -" .. tally[t])
                down_note(b, t)
                try_stun(b, t, mv.stun)
            end
        end
    elseif kind == "experiment" then
        -- Ethically Ambiguous Experiments: Red Antiseptic on everyone, Powerful Sawing + Saw Strike on one foe,
        -- then a shield for the surgeon, a heal for the team and Experimental Prescription for the others
        sfx("multhit2", 0.8, 0.6)
        say(b, "Red Antiseptic sprays the whole room!")
        for _, i in ipairs(living(b.enemies)) do
            local t = b.enemies[i]
            local d = deal(u, t, 0.5, 0.05)
            say(b, "> " .. t.name .. " -" .. d)
            down_note(b, t)
            try_stun(b, t, 0.5)
            if t.hp > 0 then apply_fx(t, { weak = 3 }) end
        end
        seal_lowest(b)
        local t = targets[1]
        if not alive(t) then
            local idx = living(b.enemies)[1]
            t = idx and b.enemies[idx] or nil
        end
        if t then
            local total = 0
            for _ = 1, 5 do
                if t.hp > 0 then
                    local d = deal(u, t, 0.3, 0.1)
                    total = total + d
                end
            end
            if t.hp > 0 then
                local d, c = deal(u, t, 2.2, 0.15)
                total = total + d
                say(b, "Saw Strike! > " .. t.name .. " -" .. total .. (c and " CRIT!" or ""))
                apply_bite(t, 3, 4, u)
            else
                say(b, "> " .. t.name .. " -" .. total)
            end
            down_note(b, t)
            local before = u.hp
            heal(u, math.floor(total * 0.35))
            if u.hp > before then say(b, "> " .. u.name .. " drains " .. (u.hp - before) .. " HP") end
        end
        u.st.shield = (u.st.shield or 0) + math.floor(u.maxhp * 0.4)
        for _, i in ipairs(living(b.allies)) do
            local a = b.allies[i]
            heal(a, math.floor(0.8 * u.atk * 1.8))
            if a ~= u then apply_fx(a, { rx = 3 }) end
        end
        say(b, "Shielded, party healed, Rx given!")
    elseif kind == "buff" then
        sfx("tarot2", 1, 0.5)
        for _, t in ipairs(targets) do
            apply_fx(t, mv.fx)
            if mv.shield then t.st.shield = (t.st.shield or 0) + math.floor(t.maxhp * mv.shield) end
            say(b, "> " .. t.name .. " is fortified")
        end
    elseif kind == "gacha" then
        -- Lets go gambling!: 50% JACKPOT, 50% BANKRUPT. Either way the ticket is spent.
        sfx("timpani", 1, 0.6)
        if pseudorandom("ocafe_rpg_gacha") < 0.5 then
            say(b, "JACKPOT!!! The whole party is saved!")
            for _, a in ipairs(b.allies) do
                if a ~= u then
                    if a.hp <= 0 then say(b, "> " .. a.name .. " is revived!") end
                    a.hp, a.sp = a.maxhp, a.maxsp
                    apply_fx(a, { atk = 3, def = 3 })
                end
            end
            for _, i in ipairs(living(b.enemies)) do
                local e = b.enemies[i]
                local loss = math.floor(e.maxhp * (e.boss and 0.2 or 0.35))
                e.hp = math.max(0, e.hp - loss)
                say(b, "> " .. e.name .. " -" .. loss)
                down_note(b, e)
            end
            say(b, "Party fully healed, SP full, ATK and DEF up!")
        else
            say(b, "BANKRUPT!!! The ticket was a dud...")
            for _, a in ipairs(b.allies) do
                if a ~= u and a.hp > 0 then
                    local loss = math.min(a.hp - 1, math.floor(a.maxhp * 0.4))
                    a.hp = a.hp - loss
                    a.sp = 0
                    say(b, "> " .. a.name .. " -" .. loss .. " HP and loses all SP")
                end
            end
            for _, i in ipairs(living(b.enemies)) do
                local e = b.enemies[i]
                heal(e, math.floor(e.maxhp * 0.25))
                apply_fx(e, { atk = 4 })
            end
            say(b, "Foes recover and hit harder!")
        end
        u.hp, u.st.shield = 0, 0
        say(b, u.name .. " is spent and vanishes!")
    elseif kind == "gamble" then
        -- Omni-Box: one of four surprises
        local roll = pseudorandom("ocafe_rpg_omni", 1, 4)
        if roll == 1 then
            local live = living(b.enemies)
            local t = b.enemies[live[pseudorandom("ocafe_rpg_omni_t", 1, #live)]]
            local d, c = deal(u, t, 2.0, 0.1)
            say(b, "Meteor inside! > " .. t.name .. " -" .. d .. (c and " CRIT!" or ""))
            down_note(b, t)
        elseif roll == 2 then
            for _, i in ipairs(living(b.allies)) do
                local t = b.allies[i]
                local amount = math.floor(u.atk * 1.8)
                heal(t, amount)
            end
            say(b, "Encrustation! The party is healed")
        elseif roll == 3 then
            for _, i in ipairs(living(b.allies)) do apply_fx(b.allies[i], { atk = 3 }) end
            say(b, "Power surge! Party ATK up")
        else
            for _, i in ipairs(living(b.allies)) do
                local t = b.allies[i]
                t.sp = math.min(t.maxsp, t.sp + 3)
            end
            say(b, "Snacks! Party gains 3 SP")
        end
        sfx("timpani", 1, 0.5)
    end
end

-- enemy turn
local function pick_target(b, ignore_taunt, weakest)
    local live = living(b.allies)
    if #live == 0 then return nil end
    if not ignore_taunt then
        for _, i in ipairs(live) do
            if (b.allies[i].st.taunt or 0) > 0 then return b.allies[i] end
        end
    end
    if weakest then
        local best = b.allies[live[1]]
        for _, i in ipairs(live) do
            if b.allies[i].hp < best.hp then best = b.allies[i] end
        end
        return best
    end
    return b.allies[live[pseudorandom("ocafe_rpg_aim", 1, #live)]]
end

local function enemy_hit(b, e, t, power, verb)
    local d, c = deal(e, t, power, 0.12)
    say(b, e.name .. " " .. verb .. " " .. t.name .. ": -" .. d .. (c and " CRIT!" or ""))
    down_note(b, t)
    -- return fire: a taunting unit with a counter shoots back at whoever hit it
    if t.counter and t.hp > 0 and e.hp > 0 and (t.st.taunt or 0) > 0 then
        local cd = deal(t, e, t.counter, 0.05)
        say(b, "> " .. t.name .. " returns fire at " .. e.name .. ": -" .. cd)
        down_note(b, e)
    end
end

local function enemy_act(b, e)
    e.t = (e.t or 0) + 1
    if e.final and not e.enraged and e.hp <= e.maxhp / 2 then
        e.enraged = true
        e.atk = math.floor(e.atk * 1.4)
        say(b, e.name .. " is ENRAGED!")
    end
    local special = e.t % (e.enraged and 2 or 3) == 0
    local arch = e.arch
    sfx("chips1", 0.8 + 0.2 * pseudorandom("ocafe_rpg_pitch"), 0.4)
    if e.boss and special then
        say(b, e.name .. " unleashes a quake!")
        for _, i in ipairs(living(b.allies)) do
            local d, c = deal(e, b.allies[i], e.enraged and 1.3 or 1.0, 0.05)
            say(b, "> " .. b.allies[i].name .. " -" .. d .. (c and " CRIT!" or ""))
            down_note(b, b.allies[i])
        end
    elseif special and arch == "tank" then
        if (e.st.seal or 0) > 0 then
            say(b, e.name .. " tries to guard, but it is sealed!")
        else
            e.st.shield = (e.st.shield or 0) + math.floor(e.maxhp * 0.3)
            say(b, e.name .. " raises its guard!")
        end
    elseif special and arch == "sniper" then
        local t = pick_target(b, true, true)
        if t then enemy_hit(b, e, t, 1.8, "snipes") end
    elseif special and arch == "brawler" then
        local t = pick_target(b)
        if t then enemy_hit(b, e, t, 2.1, "smashes") end
    else
        local t = pick_target(b)
        if t then enemy_hit(b, e, t, 1.0, "hits") end
    end
end

-- turn order: fastest first, rebuilt every round
local function new_round(b)
    b.round = b.round + 1
    local q = {}
    for i, u in ipairs(b.allies) do if u.hp > 0 then q[#q + 1] = { s = "a", i = i, spd = u.spd } end end
    for i, u in ipairs(b.enemies) do if u.hp > 0 then q[#q + 1] = { s = "e", i = i, spd = u.spd } end end
    table.sort(q, function(x, y)
        if x.spd ~= y.spd then return x.spd > y.spd end
        if x.s ~= y.s then return x.s == "a" end
        return x.i < y.i
    end)
    b.queue = q
    say(b, "-- Round " .. b.round .. " --")
end

local function unit_of(b, e) return (e.s == "a" and b.allies or b.enemies)[e.i] end

local function give_tag(key)
    if not (G.P_TAGS and G.P_TAGS[key] and add_tag and Tag) then return nil end
    local ok = pcall(function() add_tag(Tag(key)) end)
    if not ok then return nil end
    local nm = G.P_TAGS[key].name or key
    local ok2, loc = pcall(localize, { type = "name_text", set = "Tag", key = key })
    if ok2 and type(loc) == "string" and loc ~= "ERROR" then nm = loc end
    return nm
end

local function finish(b, result)
    local s = S()
    b.phase = result
    b.cur = nil
    b.pending = nil
    if result == "won" then
        s.cleared = s.cleared + 1
        ease_dollars(b.reward, true)
        local tag
        if b.boss then
            tag = give_tag(BOSS_TAGS[pseudorandom("ocafe_rpg_tag", 1, #BOSS_TAGS)])
        elseif s.cleared % 3 == 0 then
            tag = give_tag(TAGS[pseudorandom("ocafe_rpg_tag", 1, #TAGS)])
        end
        s.last = { result = "won", reward = b.reward, tag = tag, level = 1 + s.cleared, final = b.final }
        if b.final then s.final_won = true end
        say(b, "VICTORY! +$" .. b.reward)
        sfx("timpani", 1.2, 0.6)
    else
        s.last = { result = "lost", fee = b.cost }
        say(b, "Your party was defeated...")
        sfx("negative", 0.8, 0.5)
    end
end

local function check_end(b)
    if #living(b.enemies) == 0 then return "won" end
    if #living(b.allies) == 0 then return "lost" end
end

-- run turns until a party member needs input (or the fight ends)
local function advance(b)
    for _ = 1, 400 do
        local r = check_end(b)
        if r then finish(b, r) return end
        b.qi = b.qi + 1
        if b.qi > #b.queue then
            new_round(b)
            b.qi = 1
        end
        local entry = b.queue[b.qi]
        local u = unit_of(b, entry)
        if alive(u) then
            -- Raging Scalpel: every 3rd turn the surgeon patches herself up (more when hurt) and shakes off debuffs
            if entry.s == "a" and u.passive == "scalpel" then
                u.pt = (u.pt or 0) + 1
                if u.pt % 3 == 0 then
                    local missing = (1 - u.hp / u.maxhp) * 100
                    local amount = math.floor(u.atk * 2.2 + u.atk * 0.035 * missing)
                    heal(u, amount)
                    u.st.stun, u.st.weak = nil, nil
                    say(b, u.name .. " patches herself up: +" .. amount .. " HP")
                end
            end
            if (u.st.stun or 0) > 0 then
                say(b, u.name .. " is stunned and can't move!")
                tick(u, b)
            elseif entry.s == "e" then
                enemy_act(b, u)
                tick(u, b)
            else
                u.sp = math.min(u.maxsp, u.sp + SP_REGEN)
                b.cur = entry.i
                b.phase = "move"
                b.pending = nil
                return
            end
        end
    end
end

----------------------------------------------------------------
-- UI BUILDING BLOCKS
-- Layout rule used everywhere: a Row (R) holds Columns (C) side by side, and a Column holds Rows stacked.
----------------------------------------------------------------
local function line(str, scale, colour, align, maxw)
    return { n = G.UIT.R, config = { align = align or "cm" }, nodes = {
        { n = G.UIT.T, config = { text = tostring(str), scale = scale or 0.3, colour = colour or G.C.UI.TEXT_LIGHT,
            shadow = true, maxw = maxw } }
    } }
end

-- text never wraps by itself in Balatro's UI, so long lines are split by hand
local function wrap_rows(str, scale, colour, align, maxw)
    local per_line = math.max(8, math.floor(maxw / (scale * 0.55)))
    local rows, cur = {}, ""
    for word in tostring(str):gmatch("%S+") do
        if cur ~= "" and #cur + 1 + #word > per_line then
            rows[#rows + 1] = line(cur, scale, colour, align, maxw)
            cur = word
        else
            cur = (cur == "") and word or (cur .. " " .. word)
        end
    end
    if cur ~= "" then rows[#rows + 1] = line(cur, scale, colour, align, maxw) end
    return rows
end

-- A card's own art, read from its atlas (jokers.png for this mod's Jokers)
local function art(key, w, h)
    local ok, node = pcall(function()
        local c = G.P_CENTERS[key]
        local atlas = G.ASSET_ATLAS[c.atlas or "Joker"]
        local sprite = Sprite(0, 0, w, h, atlas, c.pos or { x = 0, y = 0 })
        if sprite.states then
            for _, st in ipairs({ "drag", "hover", "click" }) do
                if sprite.states[st] then sprite.states[st].can = false end
            end
        end
        return { n = G.UIT.O, config = { object = sprite } }
    end)
    if ok then return node end
    if sendDebugMessage then sendDebugMessage("rpg.lua art: " .. tostring(node), "OreoCafe") end
    return { n = G.UIT.B, config = { w = w, h = h, r = 0.1, colour = G.C.JOKER_GREY or G.C.GREY } }
end

local function button(label, fn, ref, colour, w, h, scale)
    local enabled = fn ~= nil
    return { n = G.UIT.C, config = {
        align = "cm", padding = 0.08, minw = w or 3, minh = h or 0.6, r = 0.1, hover = enabled, shadow = true,
        colour = enabled and colour or G.C.UI.BACKGROUND_INACTIVE, button = fn, ref_table = ref
    }, nodes = {
        line(label, scale or 0.4, G.C.UI.TEXT_LIGHT, "cm", (w or 3) - 0.2)
    } }
end

-- a bar split into a filled part and an empty part
local function bar(frac, w, colour)
    frac = math.max(0, math.min(1, frac))
    local fw = w * frac
    local cols = {}
    if fw > 0.02 then cols[#cols + 1] = { n = G.UIT.C, config = { align = "cl" }, nodes = {
        { n = G.UIT.B, config = { w = fw, h = 0.14, r = 0.04, colour = colour } } } } end
    if w - fw > 0.02 then cols[#cols + 1] = { n = G.UIT.C, config = { align = "cl" }, nodes = {
        { n = G.UIT.B, config = { w = w - fw, h = 0.14, r = 0.04, colour = G.C.BLACK } } } } end
    return { n = G.UIT.R, config = { align = "cl" }, nodes = cols }
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

local body -- defined below

local function swap(id)
    if not G.OVERLAY_MENU then return end
    local spot = G.OVERLAY_MENU:get_UIE_by_ID(id)
    if not (spot and spot.config.object) then return end
    spot.config.object:remove()
    spot.config.object = UIBox {
        definition = { n = G.UIT.ROOT, config = { align = "cm", padding = 0.05, colour = G.C.CLEAR }, nodes = { body() } },
        config = { offset = { x = 0, y = 0 }, parent = spot, type = "cm" }
    }
    spot.UIBox:recalculate()
end

local function refresh()
    G.E_MANAGER:add_event(Event({
        trigger = "immediate", blocking = false,
        func = function()
            swap("ocafe_rpg")
            return true
        end
    }), "other")
end

----------------------------------------------------------------
-- LOBBY (party select + start)
----------------------------------------------------------------
local function in_party(key)
    for _, k in ipairs(S().party) do if k == key then return true end end
    return false
end

local function stat_line(key, n)
    local k = kit_for(key)
    if k.order then
        local out = {}
        for _, sub in ipairs(k.order) do
            local st = ally_stats(key, n, sub)
            out[#out + 1] = k.units[sub].name .. "  HP " .. st.maxhp .. "  ATK " .. st.atk .. "  SPD " .. st.spd
        end
        return out[1], out[2] or " "
    end
    local st = ally_stats(key, n)
    return "HP " .. st.maxhp .. "  ATK " .. st.atk, "DEF " .. st.def .. "  SPD " .. st.spd .. "  SP " .. st.maxsp
end

local function roster_card(center, n)
    local key = center.key
    local kit = kit_for(key)
    local picked = in_party(key)
    local s1, s2 = stat_line(key, n)
    local locked = REQUIRE_OWNED and not owned(key)
    local nodes = {
        { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = { art(key, 0.9, 1.2) } },
        line(joker_name(center), 0.3, picked and G.C.GOLD or G.C.UI.TEXT_LIGHT, "cm", 2.6),
        line(kit.role, 0.24, G.C.ORANGE, "cm", 2.6),
        line(s1, 0.22, G.C.UI.TEXT_LIGHT, "cm", 2.6),
        line(s2, 0.22, G.C.UI.TEXT_LIGHT, "cm", 2.6),
    }
    -- moves, two per line (a multi-unit Joker lists each fighter's moves on one line)
    if kit.order then
        for _, sub in ipairs(kit.order) do
            local names = {}
            for _, mv in ipairs(kit.units[sub].moves) do names[#names + 1] = mv.name end
            nodes[#nodes + 1] = line(kit.units[sub].name .. ": " .. table.concat(names, " / "), 0.17,
                G.C.UI.TEXT_INACTIVE, "cm", 2.6)
        end
    else
        for i = 1, #kit.moves, 2 do
            local a, bb = kit.moves[i], kit.moves[i + 1]
            nodes[#nodes + 1] = line(a.name .. (bb and (" / " .. bb.name) or ""), 0.19, G.C.UI.TEXT_INACTIVE, "cm", 2.6)
        end
    end
    local label, fn, colour
    if locked then
        label, fn = "NOT OWNED", nil
    elseif picked then
        label, fn, colour = "IN PARTY", "ocafe_rpg_toggle", G.C.GREEN
    else
        label, fn, colour = "SELECT", "ocafe_rpg_toggle", G.C.BLUE
    end
    nodes[#nodes + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        button(label, fn, { key = key }, colour, 1.9, 0.4, 0.3)
    } }
    return { n = G.UIT.C, config = {
        align = "cm", padding = 0.05, r = 0.1, minw = 2.8, colour = picked and G.C.DARK_EDITION or G.C.L_BLACK, emboss = 0.05
    }, nodes = nodes }
end

local function lobby_body()
    local s = S()
    local n = s.cleared
    local cost, reward = cost_for(n), reward_for(n)
    local boss = is_boss(n)
    local keys = party_keys()
    local money = G.GAME.dollars or 0
    local can_afford = money - cost >= (G.GAME.bankrupt_at or 0)
    if s.challenge then cost, reward, can_afford = 0, MAP_REWARD, true end

    local rows = {}
    rows[#rows + 1] = line("Oreo RPG   -   Battle " .. (n + 1) .. "   -   Party Lv " .. (n + 1)
        .. (boss and "   -   BOSS FIGHT" or ""), 0.5, boss and G.C.RED or G.C.GOLD)

    -- roster (rows of 4, ROSTER_PAGE cards per page)
    local list = roster()
    local pages = math.max(1, math.ceil(#list / ROSTER_PAGE))
    s.page = math.max(1, math.min(s.page or 1, pages))
    local first = (s.page - 1) * ROSTER_PAGE
    local cur
    for i = first + 1, math.min(#list, first + ROSTER_PAGE) do
        if (i - first - 1) % 4 == 0 then
            cur = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {} }
            rows[#rows + 1] = cur
        end
        cur.nodes[#cur.nodes + 1] = roster_card(list[i], n)
    end
    if #list == 0 then
        rows[#rows + 1] = line("No Legendary Jokers found.", 0.35, G.C.RED)
    end
    if pages > 1 then
        rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.03 }, nodes = {
            button("< PREV", s.page > 1 and "ocafe_rpg_page" or nil, { d = -1 }, G.C.BLUE, 1.6, 0.4, 0.3),
            { n = G.UIT.C, config = { align = "cm", padding = 0.12 }, nodes = {
                { n = G.UIT.T, config = { text = "Roster  " .. s.page .. " / " .. pages, scale = 0.3,
                    colour = G.C.UI.TEXT_LIGHT, shadow = true } }
            } },
            button("NEXT >", s.page < pages and "ocafe_rpg_page" or nil, { d = 1 }, G.C.BLUE, 1.6, 0.4, 0.3),
        } }
    end
    if #keys > 0 then
        local names = {}
        for _, key in ipairs(keys) do names[#names + 1] = joker_name(G.P_CENTERS[key]) end
        rows[#rows + 1] = line("Party: " .. table.concat(names, ",  "), 0.22, G.C.ORANGE, "cm", 11.5)
    end

    if deck_active() then
        rows[#rows + 1] = line("Oreo RPG Deck   |   Training +" .. math.floor(training() * 100 + 0.5) .. "%   |   Rations "
            .. (s.rations or 0) .. "   |   Boss Blinds beaten " .. (s.bosses or 0) .. "/" .. (G.GAME.win_ante or 8),
            0.28, G.C.FILTER, "cm", 11.5)
    end

    -- result of the last fight
    local last = s.last
    if last and last.result == "won" then
        local msg = (last.final and "FINAL BOSS DEFEATED!  " or "Victory! ") .. "+$" .. last.reward .. " and your party reached Lv " .. last.level
        if last.tag then msg = msg .. "  |  Bonus: " .. last.tag .. " Tag" end
        rows[#rows + 1] = line(msg, 0.3, G.C.GREEN, "cm", 11)
    elseif last then
        rows[#rows + 1] = line("Defeated! The $" .. (last.fee or cost) .. " fee is gone - pay it again to retry.", 0.3, G.C.RED, "cm", 11)
    end

    rows[#rows + 1] = line("Party " .. party_slots() .. "/" .. MAX_PARTY .. " slots   |   Entry fee $" .. cost .. "   |   Reward $" .. reward
        .. ((boss or (n + 1) % 3 == 0) and " + Tag" or "") .. "   |   You have $" .. money,
        0.3, G.C.GOLD, "cm", 11.5)

    local label = ((last and last.result ~= "won") and "RETRY" or "START BATTLE") .. "  ($" .. cost .. ")"
    if s.challenge then label = "START CHALLENGE  (free)" end
    local ready = #keys > 0 and can_afford
    if #keys == 0 then label = "PICK A PARTY MEMBER"
    elseif not can_afford then label = "NEED $" .. cost end
    rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        button(label, ready and "ocafe_rpg_start" or nil, nil, G.C.RED, 4.4, 0.7, 0.45)
    } }
    if s.challenge then
        rows[#rows + 1] = line("Win to beat this Blind. Lose, and you play it by score instead.", 0.28, G.C.FILTER, "cm", 11)
        rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
            button("DECLINE  (play the Blind)", "ocafe_rpg_decline", nil, G.C.GREY, 4.4, 0.5, 0.32)
        } }
    end
    if deck_active() then
        local fcost = cost_for(math.max(n, 8))
        local flabel, ffn
        if s.final_won then
            flabel = "FINAL BOSS DEFEATED"
        elseif not s.final_open then
            flabel = "FINAL BOSS LOCKED  (beat the Ante " .. (G.GAME.win_ante or 8) .. " Boss Blind)"
        elseif #keys == 0 then
            flabel = "PICK A PARTY MEMBER"
        elseif money - fcost < (G.GAME.bankrupt_at or 0) then
            flabel = "FINAL BOSS  (need $" .. fcost .. ")"
        else
            flabel, ffn = "FINAL BOSS  ($" .. fcost .. ")", "ocafe_rpg_final"
        end
        rows[#rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
            button(flabel, ffn, nil, G.C.PURPLE, 6.4, 0.6, 0.38)
        } }
    end
    return { n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = rows }
end

----------------------------------------------------------------
-- BATTLE SCREEN
----------------------------------------------------------------
local function status_text(u)
    local t = {}
    if (u.st.atk or 0) > 0 then t[#t + 1] = "ATK+" end
    if (u.st.def or 0) > 0 then t[#t + 1] = "DEF+" end
    if (u.st.taunt or 0) > 0 then t[#t + 1] = "TAUNT" end
    if (u.st.stun or 0) > 0 then t[#t + 1] = "STUN" end
    if (u.st.weak or 0) > 0 then t[#t + 1] = "WEAK" end
    if (u.st.rx or 0) > 0 then t[#t + 1] = "Rx" end
    if (u.st.seal or 0) > 0 then t[#t + 1] = "SEALED" end
    if (u.st.bite or 0) > 0 then t[#t + 1] = "BITE x" .. u.st.bite end
    if (u.st.shield or 0) > 0 then t[#t + 1] = "SHD " .. u.st.shield end
    return #t > 0 and table.concat(t, " ") or " "
end

local function unit_panel(b, side, i, with_target)
    local list = side == "a" and b.allies or b.enemies
    local u = list[i]
    local c = #list >= 4   -- compact layout so 4-5 units still fit on the screen
    local down = u.hp <= 0
    local active = side == "a" and b.cur == i and (b.phase == "move" or b.phase == "target")
    local frac = u.hp / u.maxhp
    local hp_col = frac > 0.5 and G.C.GREEN or (frac > 0.25 and G.C.GOLD or G.C.RED)
    local name_col = down and G.C.UI.TEXT_INACTIVE or (active and G.C.GOLD or G.C.UI.TEXT_LIGHT)

    local sub
    if side == "a" then
        sub = u.role .. "   SP " .. u.sp .. "/" .. u.maxsp
    else
        sub = (u.boss and "BOSS  " or "") .. ARCH[u.arch].label
    end

    local w = c and 2.4 or 2.7
    local info = {
        line((active and "> " or "") .. u.name, c and 0.25 or 0.3, name_col, "cl", w),
        line(sub, c and 0.17 or 0.22, u.boss and G.C.RED or G.C.ORANGE, "cl", w),
        bar(frac, c and 2.2 or 2.6, hp_col),
        line(down and "KO" or ("HP " .. u.hp .. "/" .. u.maxhp), c and 0.2 or 0.24, down and G.C.RED or G.C.UI.TEXT_LIGHT, "cl", w),
    }
    if with_target and not down then
        -- while choosing a target, the button takes the status line's place so the panel keeps its height
        info[#info + 1] = { n = G.UIT.R, config = { align = "cl" }, nodes = {
            button("TARGET", "ocafe_rpg_target", { side = side, i = i }, G.C.RED, c and 1.4 or 1.6, c and 0.2 or 0.24, c and 0.2 or 0.24)
        } }
    else
        info[#info + 1] = line(status_text(u), c and 0.16 or 0.2, G.C.FILTER, "cl", w)
    end

    return { n = G.UIT.R, config = { align = "cm", padding = c and 0.03 or 0.05, r = 0.1, colour = G.C.L_BLACK, emboss = 0.05,
        minw = c and 3.5 or 4.0 }, nodes = {
        { n = G.UIT.C, config = { align = "cm", padding = 0.03 }, nodes = { art(u.key, c and 0.62 or 0.9, c and 0.82 or 1.2) } },
        { n = G.UIT.C, config = { align = "cl", padding = 0.03, minw = c and 2.4 or 2.8 }, nodes = info },
    } }
end

local function log_col(b)
    local W = 3.5
    local chosen, total = {}, 0
    for idx = #b.log, 1, -1 do
        local newest = (#b.log - idx) < 3
        local rows = wrap_rows(b.log[idx], 0.24, newest and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE, "cl", W)
        if total + #rows > 11 then break end
        total = total + #rows
        table.insert(chosen, 1, rows)
    end
    local nodes = { line("Battle Log", 0.28, G.C.GOLD, "cm") }
    for _, rows in ipairs(chosen) do
        for _, r in ipairs(rows) do nodes[#nodes + 1] = r end
    end
    return { n = G.UIT.C, config = { align = "tm", padding = 0.08, r = 0.1, colour = G.C.BLACK, minw = 3.7, minh = 4.3 }, nodes = nodes }
end

local function order_text(b)
    local names = {}
    for qi = b.qi, #b.queue do
        local e = b.queue[qi]
        local u = e and unit_of(b, e)
        if alive(u) then
            local first = u.name:match("%S+") or u.name
            names[#names + 1] = (e.s == "e") and ("[" .. first .. "]") or first
        end
        if #names >= 8 then break end
    end
    return "Turn order: " .. table.concat(names, " > ")
end

local function move_button(mi, mv, u)
    local enabled = u.sp >= mv.cost
    return { n = G.UIT.C, config = {
        align = "cm", padding = 0.05, minw = 2.7, minh = 1.05, r = 0.1, hover = enabled, shadow = true,
        colour = enabled and G.C.BLUE or G.C.UI.BACKGROUND_INACTIVE,
        button = enabled and "ocafe_rpg_move" or nil, ref_table = { mi = mi }
    }, nodes = {
        line(mv.name, 0.3, G.C.UI.TEXT_LIGHT, "cm", 2.55),
        line((mv.cost > 0 and (mv.cost .. " SP") or "Free") .. " | " .. TARGET_TEXT[mv.target], 0.21, G.C.GOLD, "cm", 2.55),
        line(mv.tip, 0.19, G.C.UI.TEXT_LIGHT, "cm", 2.55),
    } }
end

local function actions_col(b)
    if b.phase == "move" then
        local u = b.allies[b.cur]
        local btns = {}
        for mi, mv in ipairs(kit_of(u).moves) do btns[#btns + 1] = move_button(mi, mv, u) end
        return { n = G.UIT.C, config = { align = "cm", padding = 0.03 }, nodes = {
            line(u.name .. "'s turn", 0.32, G.C.GOLD),
            { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = btns },
            { n = G.UIT.R, config = { align = "cm", padding = 0.02 }, nodes = {
                button(b.challenge and "FORFEIT (play the Blind)" or "RETREAT (lose the fee)", "ocafe_rpg_retreat", nil, G.C.GREY, 3.2, 0.3, 0.24)
            } },
        } }
    elseif b.phase == "target" then
        local mv = kit_of(b.allies[b.cur]).moves[b.pending]
        return { n = G.UIT.C, config = { align = "cm", padding = 0.05 }, nodes = {
            line("Choose a target for " .. mv.name, 0.34, G.C.GOLD),
            { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
                button("CANCEL", "ocafe_rpg_cancel", nil, G.C.GREY, 2.4, 0.5, 0.35)
            } },
        } }
    end
    -- finished
    local won = b.phase == "won"
    local s = S()
    local lines_ = { line(won and (b.final and "FINAL BOSS DEFEATED!" or "VICTORY!") or "DEFEAT", 0.5, won and G.C.GREEN or G.C.RED) }
    if won and s.last then
        local msg = "+$" .. s.last.reward .. "   Party Lv " .. s.last.level
        if s.last.tag then msg = msg .. "   +" .. s.last.tag .. " Tag" end
        lines_[#lines_ + 1] = line(msg, 0.32, G.C.GOLD, "cm", 10)
    else
        lines_[#lines_ + 1] = line(b.challenge and "Beat the Blind by score instead." or "Retries cost the entry fee again.", 0.3, G.C.UI.TEXT_LIGHT)
    end
    lines_[#lines_ + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        button("CONTINUE", "ocafe_rpg_continue", nil, G.C.BLUE, 3.4, 0.6, 0.42)
    } }
    return { n = G.UIT.C, config = { align = "cm", padding = 0.03 }, nodes = lines_ }
end

local function battle_body(b)
    local target_foes = b.phase == "target" and (function()
        local t = kit_of(b.allies[b.cur]).moves[b.pending].target
        return t == "enemy"
    end)()
    local target_friends = b.phase == "target" and (function()
        local t = kit_of(b.allies[b.cur]).moves[b.pending].target
        return t == "ally"
    end)()

    local ally_nodes, enemy_nodes = {}, {}
    for i = 1, #b.allies do ally_nodes[#ally_nodes + 1] = unit_panel(b, "a", i, target_friends) end
    for i = 1, #b.enemies do enemy_nodes[#enemy_nodes + 1] = unit_panel(b, "e", i, target_foes) end

    local title = (b.final and "FINAL BOSS" or (b.boss and "BOSS BATTLE" or "Battle")) .. " " .. (b.n + 1) .. "   -   Round " .. math.max(1, b.round)
    return { n = G.UIT.C, config = { align = "cm", padding = 0.03 }, nodes = {
        line(title, 0.38, b.boss and G.C.RED or G.C.GOLD),
        { n = G.UIT.R, config = { align = "tm", padding = 0.05 }, nodes = {
            { n = G.UIT.C, config = { align = "tm", padding = 0.03 }, nodes = ally_nodes },
            log_col(b),
            { n = G.UIT.C, config = { align = "tm", padding = 0.03 }, nodes = enemy_nodes },
        } },
        line((b.phase == "move" or b.phase == "target") and order_text(b) or " ", 0.24, G.C.UI.TEXT_INACTIVE, "cm", 11),
        { n = G.UIT.R, config = { align = "cm" }, nodes = { actions_col(b) } },
    } }
end

body = function()
    local ok, node = pcall(function()
        local b = S().battle
        if b then return battle_body(b) end
        return lobby_body()
    end)
    if ok then return node end
    if sendDebugMessage then sendDebugMessage("rpg.lua body: " .. tostring(node), "OreoCafe") end
    return { n = G.UIT.C, config = { align = "cm", padding = 0.1 }, nodes = {
        line("Oreo RPG hit an error", 0.45, G.C.RED),
        line(tostring(node):sub(1, 80), 0.24, G.C.WHITE),
        line(tostring(node):sub(81, 160), 0.24, G.C.WHITE),
    } }
end

----------------------------------------------------------------
-- BUTTON HANDLERS
----------------------------------------------------------------
G.FUNCS.ocafe_open_rpg = function(e)
    local ok, err = pcall(function()
        S()
        G.FUNCS.overlay_menu {
            definition = create_UIBox_generic_options {
                back_func = "exit_overlay_menu",
                contents = { holder("ocafe_rpg", body) }
            }
        }
    end)
    if not ok and sendDebugMessage then sendDebugMessage("rpg.lua open: " .. tostring(err), "OreoCafe") end
end

G.FUNCS.ocafe_rpg_toggle = function(e)
    local s = S()
    if s.battle then return end
    local key = e.config.ref_table.key
    for i, k in ipairs(s.party) do
        if k == key then
            table.remove(s.party, i)
            sfx("cancel", 1, 0.4)
            refresh()
            return
        end
    end
    if party_slots() + slots_of(key) > MAX_PARTY then
        sfx("cancel", 1, 0.5)
        return
    end
    s.party[#s.party + 1] = key
    sfx("card1", 1, 0.5)
    refresh()
end

G.FUNCS.ocafe_rpg_page = function(e)
    local s = S()
    if s.battle then return end
    s.page = (s.page or 1) + e.config.ref_table.d
    sfx("highlight1", 1, 0.4)
    refresh()
end

G.FUNCS.ocafe_rpg_start = function(e)
    local s = S()
    if s.battle then return end
    local keys = party_keys()
    if #keys == 0 then return end
    local cost = s.challenge and 0 or cost_for(s.cleared)
    if cost > 0 and (G.GAME.dollars or 0) - cost < (G.GAME.bankrupt_at or 0) then
        sfx("cancel", 1, 0.5)
        return
    end
    if cost > 0 then ease_dollars(-cost, true) end
    s.last = nil
    s.battle = new_battle()
    if s.challenge then
        s.battle.challenge, s.battle.cost, s.battle.reward = true, 0, MAP_REWARD
    end
    sfx("coin1", 0.9, 0.5)
    advance(s.battle)
    refresh()
end

G.FUNCS.ocafe_rpg_final = function(e)
    local s = S()
    if s.battle or not deck_active() or not s.final_open or s.final_won then return end
    local keys = party_keys()
    if #keys == 0 then return end
    local cost = cost_for(math.max(s.cleared, 8))
    if (G.GAME.dollars or 0) - cost < (G.GAME.bankrupt_at or 0) then
        sfx("cancel", 1, 0.5)
        return
    end
    ease_dollars(-cost, true)
    s.last = nil
    s.battle = new_battle(true)
    sfx("coin1", 0.7, 0.6)
    advance(s.battle)
    refresh()
end

-- The Final Boss is down: close the RPG and let the (normally suppressed) win through
local function fire_win()
    local s = S()
    s.final_cleared = true
    pcall(function() if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end end)
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 0.5,
        func = function()
            if G.GAME then G.GAME.won = true end
            if type(win_game) == "function" then
                local ok, err = pcall(win_game)
                if not ok and sendDebugMessage then sendDebugMessage("rpg.lua win_game: " .. tostring(err), "OreoCafe") end
            end
            return true
        end
    }))
end

G.FUNCS.ocafe_rpg_move = function(e)
    local b = S().battle
    if not b or b.phase ~= "move" then return end
    local u = b.allies[b.cur]
    local mi = e.config.ref_table.mi
    local mv = kit_of(u).moves[mi]
    if not mv or u.sp < mv.cost then return end
    if mv.target == "enemy" or mv.target == "ally" then
        b.phase, b.pending = "target", mi
        sfx("highlight1", 1, 0.4)
    else
        u.sp = u.sp - mv.cost
        run_move(b, u, mv, nil)
        tick(u)
        advance(b)
    end
    refresh()
end

G.FUNCS.ocafe_rpg_target = function(e)
    local b = S().battle
    if not b or b.phase ~= "target" then return end
    local u = b.allies[b.cur]
    local mv = kit_of(u).moves[b.pending]
    if not mv then return end
    u.sp = u.sp - mv.cost
    b.pending = nil
    run_move(b, u, mv, e.config.ref_table.i)
    tick(u)
    advance(b)
    refresh()
end

G.FUNCS.ocafe_rpg_cancel = function(e)
    local b = S().battle
    if not b or b.phase ~= "target" then return end
    b.phase, b.pending = "move", nil
    sfx("cancel", 1, 0.4)
    refresh()
end

G.FUNCS.ocafe_rpg_retreat = function(e)
    local b = S().battle
    if not b or (b.phase ~= "move" and b.phase ~= "target") then return end
    say(b, "Your party retreats!")
    finish(b, "lost")
    refresh()
end

G.FUNCS.ocafe_rpg_continue = function(e)
    local s = S()
    if s.battle and s.battle.challenge and s.battle.phase == "won" then
        -- keep the result: OCAFE.rpg_tick ends the round once this screen is closed
        sfx("cancel", 1.2, 0.3)
        if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
        return
    end
    if s.battle and (s.battle.phase == "won" or s.battle.phase == "lost") then
        s.battle = nil
        sfx("cancel", 1.2, 0.3)
        if s.challenge then
            -- back to the table (map.lua ends the round if the battle was won)
            s.challenge, s.last = nil, nil
            if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
        elseif s.final_won and not s.final_cleared then
            fire_win()
        else
            refresh()
        end
    end
end

----------------------------------------------------------------
-- MAP DECK CHALLENGE (see map.lua): a free battle during a round. Winning beats the Blind.
--   s.challenge = "open" while the stop can still be won this way
----------------------------------------------------------------
OCAFE = OCAFE or {}

G.FUNCS.ocafe_rpg_decline = function(e)
    local s = S()
    if s.battle then return end
    s.challenge = nil
    if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end
end

function OCAFE.rpg_challenge()
    local s = S()
    s.battle, s.last = nil, nil
    s.challenge, s.challenge_shown = "open", nil
end

function OCAFE.rpg_pending()
    return G.GAME ~= nil and G.GAME.ocafe_rpg ~= nil and G.GAME.ocafe_rpg.challenge ~= nil
end

OCAFE.open_rpg = function() G.FUNCS.ocafe_open_rpg() end

-- called by map.lua while a hand is being chosen
function OCAFE.rpg_tick()
    local s = G.GAME.ocafe_rpg
    if not s then return end
    local b = s.battle
    -- won: beat the Blind once the battle screen is closed
    if b and b.challenge and b.phase == "won" then
        if not G.OVERLAY_MENU then
            s.battle, s.challenge, s.last = nil, nil, nil
            G.GAME.chips = math.max(G.GAME.chips or 0, (G.GAME.blind and G.GAME.blind.chips) or 0)
            G.GAME.chips_text = number_format(G.GAME.chips)
            G.STATE = G.STATES.NEW_ROUND
            G.STATE_COMPLETE = false
        end
        return
    end
    if b and b.challenge and b.phase == "lost" and not G.OVERLAY_MENU then
        s.battle, s.challenge, s.last = nil, nil, nil
        return
    end
    -- open the challenge by itself once, at the start of the round
    if s.challenge and not s.challenge_shown and not G.OVERLAY_MENU then
        s.challenge_shown = true
        OCAFE.open_rpg()
    end
end

----------------------------------------------------------------
-- SHOP TAB: "Oreo RPG", placed right beside the ORDERS tab
----------------------------------------------------------------
local function rpg_tab()
    return { n = G.UIT.R, config = {
        align = "cm", padding = 0.06, minw = 2.3, minh = 0.5, r = 0.12, colour = G.C.PURPLE,
        hover = true, shadow = true, emboss = 0.05, button = "ocafe_open_rpg"
    }, nodes = {
        { n = G.UIT.T, config = { text = "Oreo RPG", scale = 0.36, maxw = 2.1, colour = G.C.WHITE, shadow = true } }
    } }
end

local function find_child(node, pred)
    for i, child in ipairs(node.nodes or {}) do
        if pred(child) then return node, i end
        local p, j = find_child(child, pred)
        if p then return p, j end
    end
end

local fallback_lift = false

local function add_rpg_tab(t)
    fallback_lift = false
    if OCAFE.map_active and OCAFE.map_active() then return end -- the Map Deck has no Oreo RPG tab
    -- beside ORDERS (papas.lua): the ORDERS tab and ours become two columns of one row
    local parent, idx = find_child(t, function(n) return n.config and n.config.button == "ocafe_open_orders" end)
    if parent and parent.n == G.UIT.R then
        local orders = parent.nodes[idx]
        parent.nodes[idx] = { n = G.UIT.C, config = { align = "cm" }, nodes = { orders } }
        table.insert(parent.nodes, idx + 1, { n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = { rpg_tab() } })
        return
    end
    -- no ORDERS tab: put ours as the first row of the shop box
    local box = t.nodes and t.nodes[1]
    if box and box.n == G.UIT.C and box.nodes then
        table.insert(box.nodes, 1, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = { rpg_tab() } })
        fallback_lift = true
    end
end

-- only used by the fallback above: the extra row pushes the shop box down, so lift it back up
local VANILLA_SHOP_Y, FALLBACK_LIFT = -5.3, 0.6
local update_ref = Game.update
function Game:update(dt, ...)
    local ret = update_ref(self, dt, ...)
    if fallback_lift then
        local off = G and G.shop and G.shop.alignment and G.shop.alignment.offset
        if off and type(off.y) == "number" and math.abs(off.y - VANILLA_SHOP_Y) < 0.001 then
            off.y = VANILLA_SHOP_Y - FALLBACK_LIFT
        end
    end
    return ret
end

local challenge_set_blind_ref = Blind.set_blind
function Blind:set_blind(blind, reset, ...)
    local s = blind and not reset and G.GAME and G.GAME.ocafe_rpg
    if s and (s.challenge or (s.battle and s.battle.challenge)) then
        s.battle, s.challenge, s.last = nil, nil, nil
    end
    return challenge_set_blind_ref(self, blind, reset, ...)
end

local installed = false

local function install_hooks()
    if installed or not (G and G.UIDEF and G.UIDEF.shop) then return end
    local shop_ref = G.UIDEF.shop
    G.UIDEF.shop = function(...)
        local t = shop_ref(...)
        local ok, err = pcall(add_rpg_tab, t)
        if not ok and sendDebugMessage then sendDebugMessage("rpg.lua tab: " .. tostring(err), "OreoCafe") end
        return t
    end
    installed = true
end

install_hooks()
local rpg_start_run_ref = Game.start_run
function Game:start_run(args)
    install_hooks()
    return rpg_start_run_ref(self, args)
end

----------------------------------------------------------------
-- OREO RPG DECK
--  * The Ante-8 win is held back: when the game tries to announce the win, the deck opens the Final Boss in the
--    Oreo RPG tab instead and the run keeps going (endless Antes) until that boss is beaten.
--  * Each Blind you clear = Training (+2% party HP/ATK per point, max +150%): Small/Big +1, Boss +3, and +1
--    more for scoring double the requirement. Unused hands = Rations (up to 8): every 2 give each party
--    member +1 starting SP in the next RPG battle (max +4), then they are spent.
----------------------------------------------------------------
local function open_final(announce)
    local s = S()
    if s.final_open then return end
    s.final_open = true
    if announce and attention_text then
        pcall(attention_text, {
            text = "THE FINAL BOSS AWAITS!", scale = 0.9, hold = 2.6, colour = G.C.PURPLE,
            align = "cm", offset = { x = 0, y = -2.5 }, major = G.play
        })
        sfx("timpani", 0.8, 0.7)
    end
end

if type(win_game) == "function" then
    local win_game_ref = win_game
    win_game = function(...)
        if G.GAME and deck_active() and not S().final_cleared then
            if G.GAME then G.GAME.won = false end
            open_final(true)
            return
        end
        return win_game_ref(...)
    end
end

local function round_cleared()
    local s = S()
    local blind = G.GAME.blind
    if not (blind and (G.GAME.chips or 0) >= (blind.chips or 0)) then return end
    local gain = 1
    if blind.boss then
        gain = 3
        s.bosses = (s.bosses or 0) + 1
    end
    if (blind.chips or 0) > 0 and (G.GAME.chips or 0) >= blind.chips * 2 then gain = gain + 1 end
    s.prep = (s.prep or 0) + gain
    local hands = G.GAME.current_round and G.GAME.current_round.hands_left or 0
    s.rations = math.min(RATION_CAP, (s.rations or 0) + math.max(0, hands))
    if (s.bosses or 0) >= (G.GAME.win_ante or 8) then open_final(true) end
    if attention_text then
        pcall(attention_text, {
            text = "TRAINING +" .. gain, scale = 0.7, hold = 1.6, colour = G.C.PURPLE,
            align = "cm", offset = { x = 0, y = -1.8 }, major = G.play
        })
    end
end

SMODS.Back {
    key = "oreo_rpg_deck",
    atlas = "decks",   -- the shared deck sheet declared in main.lua (x=3 is the Oreo RPG Deck)
    pos = { x = 3, y = 0 },
    config = { dollars = 4 },
    loc_txt = {
        name = "Oreo RPG Deck",
        text = {
            "Beating {C:attention}Ante 8{} no longer wins",
            "Defeat the {C:attention}Final Boss{} in the",
            "{C:attention}Oreo RPG{} tab to win the run",
            "Each Blind cleared {C:attention}trains{} your party,",
            "unused hands become {C:attention}Rations",
            "Start with {C:money}$4{} extra"
        }
    },
    calculate = function(self, back, context)
        if context.end_of_round and context.main_eval and not context.game_over then
            local ok, err = pcall(round_cleared)
            if not ok and sendDebugMessage then sendDebugMessage("rpg.lua round_cleared: " .. tostring(err), "OreoCafe") end
        end
    end
}
