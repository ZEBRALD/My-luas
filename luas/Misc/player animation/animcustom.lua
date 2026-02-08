local aa, bb, cc, dd, ee, ff, gg, hh = ui.reference, ui.new_checkbox, ui.new_combobox, ui.new_multiselect, ui.new_slider, client.set_event_callback, ui.get, ui.set_visible
local a = require "gamesense/antiaim_funcs"
local b = function(c, d)
    for e = 1, #c do
        if c[e] == d then
            return true
        end
    end
    return false
end
local f = {aa("AA", "Other", "On shot anti-aim")}
local g = aa("Rage", "Other", "Duck peek assist")
local h = bb("MISC", "Miscellaneous", "\aFF2222FF⚠ POSE EDITAR ⚠")
local i = cc("MISC", "Miscellaneous", "State", {"Fakelag", "Always"})
local j = dd("MISC", "Miscellaneous", "Indexs", {"8", "10", "16", "17"})
local k = ee("MISC", "Miscellaneous", "Magnitude", 0, 100, 10, true, nil, 0.01)
local l = ee("MISC", "Miscellaneous", "Speed", 1, 5, 3)
ff(
    "pre_render",
    function()
        if gg(h) then
            hh(i, true)
            hh(j, true)
            hh(k, true)
            hh(l, true)
            local m = entity.get_local_player()
            if m and entity.is_alive(m) then
                local n = math.floor(globals.curtime() * ui.get(l) * 8) % 2 == 0
                local o = {entity.get_prop(m, "m_vecVelocity")}
                local p = math.abs(o[1]) > 5 or math.abs(o[2]) > 5 or math.abs(o[3]) > 5
                local q = ui.get(f[1]) and ui.get(f[2])
                local r = ui.get(g)
                local s = entity.get_prop(m, "m_flDuckAmount") > 0.5
                if (not a.get_double_tap() and not q and not r and p or ui.get(i) == "Always") and not s then
                    local t = ui.get(k)
                    local u = ui.get(j)
                    for v, w in ipairs(u) do
                        entity.set_prop(m, "m_flPoseParameter", n and t * 0.01 or 0, tonumber(w))
                    end
                end
            end
        else
            hh(i, false)
            hh(j, false)
            hh(k, false)
            hh(l, false)
        end
    end
)