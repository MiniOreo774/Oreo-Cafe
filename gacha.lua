-- Gacha Ticket (loaded from main.lua)
--
-- Legendary Joker. When SOLD you get to pick one NEGATIVE Joker of this mod from each rarity: three
-- choices of a Common, then three of an Uncommon, then three of a Rare (one pick per rarity).
-- Its RPG kit ("Lets go gambling!") lives in rpg.lua.

local TICKET_KEY = "j_ocafe_gacha_ticket"
local OPTIONS_PER_STAGE = 3
local STAGES = {
    { rarity = 1, name = "Common" },
    { rarity = 2, name = "Uncommon" },
    { rarity = 3, name = "Rare" },
}

-- every Joker of this mod with the given rarity (the ticket itself is Legendary, so it never shows up)
local function pool_for(rarity)
    local keys = {}
    for _, c in ipairs((G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker) or {}) do
        if c.rarity == rarity and type(c.key) == "string" and c.key:find("^j_ocafe_") and c.key ~= TICKET_KEY then
            keys[#keys + 1] = c.key
        end
    end
    table.sort(keys)
    return keys
end

-- up to 3 different Jokers (fewer if the mod doesn't have 3 of that rarity)
local function roll_options(rarity)
    local pool = pool_for(rarity)
    local picks = {}
    while #picks < OPTIONS_PER_STAGE and #pool > 0 do
        local i = pseudorandom("ocafe_gacha_" .. rarity .. "_" .. #picks, 1, #pool)
        picks[#picks + 1] = table.remove(pool, i)
    end
    return picks
end

local areas = {} -- card areas of the menu that is open right now

local function clear_areas()
    for _, a in ipairs(areas) do
        pcall(function() a:remove() end)
    end
    areas = {}
end

local function text_row(str, scale, colour)
    return { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = {
        { n = G.UIT.T, config = { text = str, scale = scale, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true } }
    } }
end

local open_stage
function open_stage()
    local g = G.GAME and G.GAME.ocafe_gacha
    if not g then return end
    local stage = STAGES[g.stage]
    if not stage then -- all three picks made
        G.GAME.ocafe_gacha = nil
        clear_areas()
        pcall(function() if G.FUNCS.exit_overlay_menu then G.FUNCS.exit_overlay_menu() end end)
        return
    end
    local keys = g.options[g.stage] or {}
    if #keys == 0 then -- nothing of this rarity to offer
        g.stage = g.stage + 1
        return open_stage()
    end

    clear_areas()
    local cols = {}
    for _, key in ipairs(keys) do
        local area = CardArea(0, 0, G.CARD_W * 1.1, G.CARD_H * 1.1,
            { card_limit = 1, type = "title", highlight_limit = 0 })
        areas[#areas + 1] = area
        local card = Card(area.T.x + area.T.w / 2 - G.CARD_W / 2, area.T.y, G.CARD_W, G.CARD_H,
            G.P_CARDS.empty, G.P_CENTERS[key], { bypass_discovery_center = true, bypass_discovery_ui = true })
        card:set_edition({ negative = true }, true, true)
        area:emplace(card)
        cols[#cols + 1] = { n = G.UIT.C, config = { align = "cm", padding = 0.12 }, nodes = {
            { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
                { n = G.UIT.O, config = { object = area } }
            } },
            { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {
                { n = G.UIT.C, config = {
                    align = "cm", minw = 2.0, minh = 0.6, r = 0.1, hover = true, shadow = true,
                    colour = G.C.GREEN, button = "ocafe_gacha_pick", ref_table = { key = key }
                }, nodes = {
                    { n = G.UIT.T, config = { text = "TAKE", scale = 0.42, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
                } }
            } }
        } }
    end

    G.FUNCS.overlay_menu {
        definition = { n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR }, nodes = {
            { n = G.UIT.C, config = { align = "cm", padding = 0.25, r = 0.15, colour = G.C.L_BLACK, emboss = 0.05 }, nodes = {
                text_row("GACHA TICKET", 0.7, G.C.GOLD),
                text_row("Choose 1 Negative " .. stage.name .. " Joker  (" .. g.stage .. "/" .. #STAGES .. ")", 0.45),
                { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = cols },
            } }
        } },
        no_esc = true
    }
end

G.FUNCS.ocafe_gacha_pick = function(e)
    local g = G.GAME and G.GAME.ocafe_gacha
    if not g or g.busy then return end
    g.busy = true
    SMODS.add_card { key = e.config.ref_table.key, edition = "e_negative" }
    play_sound("card1", 1, 0.6)
    g.stage = g.stage + 1
    G.E_MANAGER:add_event(Event {
        trigger = "after", delay = 0.25,
        func = function()
            g.busy = false
            open_stage()
            return true
        end
    })
end

local function begin_gacha()
    local opts = {}
    for i, st in ipairs(STAGES) do opts[i] = roll_options(st.rarity) end
    G.GAME.ocafe_gacha = { stage = 1, options = opts }
    open_stage()
end

-- quitting in the middle of the picks: bring the menu back when the run is loaded again
local start_run_ref = Game.start_run
function Game:start_run(...)
    local ret = start_run_ref(self, ...)
    if G.GAME and G.GAME.ocafe_gacha then
        G.E_MANAGER:add_event(Event {
            trigger = "after", delay = 1,
            func = function()
                if G.GAME and G.GAME.ocafe_gacha then
                    G.GAME.ocafe_gacha.busy = false
                    open_stage()
                end
                return true
            end
        })
    end
    return ret
end

SMODS.Joker {
    key = "gacha_ticket",
    atlas = "jokers",
    pos = { x = 61, y = 0 },
    rarity = 4, -- Legendary
    cost = 10,
    blueprint_compat = false,
    eternal_compat = false, -- it only does something when sold
    loc_txt = {
        name = "Gacha Ticket",
        text = {
            "When sold, choose {C:attention}1{} {C:dark_edition}Negative{} Joker",
            "from this mod of each rarity:",
            "{C:blue}Common{}, {C:green}Uncommon{} and {C:red}Rare",
            "{C:inactive}(3 options per rarity)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
    end,
    calculate = function(self, card, context)
        if context.selling_self and not context.blueprint then
            G.E_MANAGER:add_event(Event {
                trigger = "after", delay = 0.3,
                func = function()
                    begin_gacha()
                    return true
                end
            })
        end
    end
}
