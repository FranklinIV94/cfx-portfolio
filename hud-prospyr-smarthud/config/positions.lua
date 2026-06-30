-- ═════════════════════════════════════════════════════════════════════
-- Prospyr SmartHUD — Element Positions
-- ═════════════════════════════════════════════════════════════════════
-- Screen positions for HUD elements. Players can drag elements in the
-- settings panel; these are the defaults. Coordinates are percentages
-- of viewport (0-100), with (0,0) = top-left.
-- ═════════════════════════════════════════════════════════════════════

Config.Positions = {
    -- Status bars (health, armor, stamina, hunger, thirst)
    -- Stacked vertically, anchored from a single position
    status = {
        x = 1.5,    -- % from left
        y = 70.0,   -- % from top
        anchor = 'left',  -- 'left' | 'right' | 'center'
    },

    -- Money display
    money = {
        x = 1.5,
        y = 88.0,
        anchor = 'left',
    },

    -- Voice indicator
    voice = {
        x = 1.5,
        y = 60.0,
        anchor = 'left',
    },

    -- Vehicle speedometer (appears when driving)
    vehicle = {
        x = 50.0,
        y = 92.0,
        anchor = 'center',
    },

    -- Settings panel (centered by default)
    settings = {
        x = 50.0,
        y = 50.0,
        anchor = 'center',
    },
}