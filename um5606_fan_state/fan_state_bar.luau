-- Scripted widget port of the asus_um5606_fan_state plugin.
-- Cycles through fan states on left click, polls current state on a timer.

local STATES = {
    [0] = { label = "Standard",         glyph = "car-fan",   color = "on_surface" },
    [1] = { label = "Quiet",            glyph = "car-fan-1", color = "secondary"  },
    [2] = { label = "High-Performance", glyph = "car-fan-2", color = "tertiary"   },
    [3] = { label = "Full",             glyph = "car-fan-3", color = "primary"    },
}

local fanState = -1

local function applyState(state)
    local info = STATES[state]
    if not info then
        barWidget.setGlyph("car-fan")
        -- barWidget.setText("Unknown")
        barWidget.setGlyphColor("on_surface")
        barWidget.setColor("on_surface")
        return
    end
    barWidget.setGlyph(info.glyph)
    -- barWidget.setText(info.label)
    barWidget.setGlyphColor(info.color)
    barWidget.setColor(info.color)
end

local function refreshFanState()
    local ok = noctalia.runAsync("fan_state get --int", function(result)
        if result.exitCode ~= 0 then
            noctalia.log("fan_control: failed to get fan state")
            return
        end

        local parsed = tonumber(result.stdout:match("^%s*(.-)%s*$"))
        if parsed == nil then
            noctalia.log("fan_control: failed to parse fan state")
            return
        end

        if parsed ~= fanState then
            fanState = parsed
            applyState(fanState)
        end
    end)

    if not ok then
        noctalia.log("fan_control: failed to start fan state command")
    end
end

-- initial setup
local pollInterval = tonumber(barWidget.getConfig("poll_interval", 2000)) or 2000
barWidget.setUpdateInterval(pollInterval)
applyState(-1)
refreshFanState()

function update()
    refreshFanState()
end

function onClick()
    local next = (fanState + 1) % 4
    noctalia.runAsync("fan_state set " .. tostring(next))
    fanState = next
    applyState(fanState)
end
