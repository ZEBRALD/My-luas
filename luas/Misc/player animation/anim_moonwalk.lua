client.exec("clear")

local ent = require "gamesense/entity"

local lib = {
    ['gamesense/entity'] = 'https://gamesense.pub/forums/viewtopic.php?id=27529',
}


local lib_notsub = { }

for i, v in pairs(lib) do
    if not pcall(require, i) then
        lib_notsub[#lib_notsub + 1] = lib[i]
    end
end

for i=1, #lib_notsub do
    error("请订阅库 \n" .. table.concat(lib_notsub, ", \n"))
end

local info = ui.new_label("lua","b","Reax")
local legs_Air = ui.new_checkbox("lua","b","\aA9f6F8F5仙-跳蹲")
local legs_Ground = ui.new_checkbox("lua","b","\aA9f6F8F5仙-行走")

local function Animation_Breaker()

    if not entity.is_alive(entity.get_local_player()) then
        return
    end
    local me = ent.get_local_player()
    local m_fFlags = me:get_prop("m_fFlags")
    local is_onground = bit.band(m_fFlags, 1) ~= 0

    if ui.get(legs_Air) then
        if not is_onground then
            local my_animlayer = me:get_anim_overlay(6) 
            my_animlayer.weight = 1
        end
    end
    if ui.get(legs_Ground) then
        entity.set_prop(entity.get_local_player(), "m_flPoseParameter", 0, 7)
    end
end

client.set_event_callback("pre_render",Animation_Breaker)