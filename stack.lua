-- Visual stacking of Negative duplicate Jokers (loaded from main.lua)
--
-- Purely cosmetic: every copy is still its own Joker (scoring, selling, order and
-- effects are untouched). A run of NEIGHBOURING Negative Jokers with the same key
-- is drawn overlapped, so it takes up about one card of space, and the top copy
-- gets an "xN" badge. Copies that aren't next to each other aren't stacked, so the
-- left-to-right order you see is always the real order.

local STACK_OFFSET = 0.18   -- how far each extra copy peeks out, in card slots

local function stackable(card)
    return card and card.edition and card.edition.negative
        and card.config and card.config.center
        and card.states and not card.states.drag.is
        and not card.getting_sliced
end

local function same_stack(a, b)
    return stackable(a) and stackable(b) and a.config.center.key == b.config.center.key
end

-- "xN" badge on the top copy of a stack (removed when it isn't a stack any more)
local function set_badge(card, count)
    local have = card.children.ocafe_stack
    if (card.ocafe_stack_n or 1) == count and (count <= 1 or have) then return end
    if have then
        have:remove()
        card.children.ocafe_stack = nil
    end
    card.ocafe_stack_n = count
    if count > 1 then
        card.children.ocafe_stack = UIBox {
            definition = {
                n = G.UIT.ROOT, config = { align = "cm", colour = G.C.CLEAR },
                nodes = {
                    { n = G.UIT.R, config = { align = "cm", r = 0.1, padding = 0.05, colour = G.C.BLACK }, nodes = {
                        { n = G.UIT.T, config = { text = "x" .. count, scale = 0.4, colour = G.C.WHITE, shadow = true } }
                    } }
                }
            },
            -- bottom-right corner of the card
            config = {
                align = "cm", offset = { x = card.T.w * 0.28, y = card.T.h * 0.36 },
                major = card, parent = card
            }
        }
    end
end

local align_cards_ref = CardArea.align_cards
function CardArea:align_cards(...)
    local ret = align_cards_ref(self, ...)
    if self ~= G.jokers then return ret end

    local cards = self.cards
    local n = #cards
    local pos, size_at_top = {}, {}
    local cursor, any = 0, false
    local i = 1
    while i <= n do
        local j = i
        while j < n and same_stack(cards[j], cards[j + 1]) do j = j + 1 end
        local count = j - i + 1
        for k = 0, count - 1 do pos[i + k] = cursor + STACK_OFFSET * k end
        cursor = cursor + 1 + STACK_OFFSET * (count - 1)
        size_at_top[j] = count
        if count > 1 then any = true end
        i = j + 1
    end

    for k, card in ipairs(cards) do
        set_badge(card, size_at_top[k] or 1)
    end
    if not any then return ret end -- no stacks: the normal layout stays as it is

    -- Same spacing rule as the normal joker layout, but measured in "slots" so a
    -- stack only counts as one slot plus its small offsets.
    local max_cards = math.max(cursor, self.config.temp_limit or self.config.card_limit or n)
    local denom = math.max(max_cards - 1, 1)
    for k, card in ipairs(cards) do
        if not card.states.drag.is then
            card.T.x = self.T.x
                + (self.T.w - self.card_w) * (pos[k] / denom - 0.5 * (cursor - max_cards) / denom)
                + 0.5 * (self.card_w - card.T.w)
                + (card.shadow_parrallax and card.shadow_parrallax.x / 30 or 0)
        end
    end
    return ret
end