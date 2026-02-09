--created by zebrald with Gemini AI lmao

local ref_dt = { ui.reference("RAGE", "Aimbot", "Double tap") }

-- UI 控件创建
local master_switch = ui.new_checkbox("RAGE", "Other", "Fakelag on while double tap teleporting")
local chk_custom_delay = ui.new_checkbox("RAGE", "Other", "Custom DT Recharge Delay")
local sli_delay_time = ui.new_slider("RAGE", "Other", "Recharge Delay Time", 1, 100, 20, true, "s", 0.01)
local lbl_info = ui.new_label("RAGE", "Other", "Skeet normal 0.4s but scout 0.3s better")

local mul_delay_weapons = ui.new_multiselect("RAGE", "Other", "Apply to Weapons", {
    "Auto (G3SG1/SCAR20)",
    "AWP",
    "Scout (SSG08)",
    "Pistol",
    "R8 Revolver",
    "Desert Eagle",
    "Zeus",
    "Shotgun",
    "Rifle",
    "SMG",
    "LMG"
})

-- -----------------------------------------------------------------------------
-- 区域功能：逻辑处理
-- -----------------------------------------------------------------------------
local function get_weapon_class(ent)
    local weapon_proc = entity.get_player_weapon(ent)
    if weapon_proc == nil then return nil end
    local item_index = bit.band(entity.get_prop(weapon_proc, "m_iItemDefinitionIndex"), 0xFFFF)
    
    local weapons = {
        [11] = "Auto (G3SG1/SCAR20)", [38] = "Auto (G3SG1/SCAR20)",
        [9] = "AWP", [40] = "Scout (SSG08)", [64] = "R8 Revolver", 
        [1] = "Desert Eagle", [31] = "Zeus", [14] = "LMG", [28] = "LMG",
        [25] = "Shotgun", [27] = "Shotgun", [29] = "Shotgun", [35] = "Shotgun",
        [13] = "Rifle", [10] = "Rifle", [7] = "Rifle", [16] = "Rifle", [39] = "Rifle", [60] = "Rifle",
        [17] = "SMG", [19] = "SMG", [23] = "SMG", [24] = "SMG", [26] = "SMG", [33] = "SMG", [34] = "SMG",
        [2] = "Pistol", [3] = "Pistol", [4] = "Pistol", [30] = "Pistol", [32] = "Pistol", [36] = "Pistol", [61] = "Pistol", [63] = "Pistol"
    }
    return weapons[item_index]
end

local function is_weapon_config_active(current_weapon_class)
    if not ui.get(chk_custom_delay) then return false end
    local selected = ui.get(mul_delay_weapons)
    for i=1, #selected do
        if selected[i] == current_weapon_class then return true end
    end
    return false
end

local last_shot_time = 0

client.set_event_callback('bullet_impact', function(e)
    if not ui.get(master_switch) then return end
    local me = entity.get_local_player()
    if client.userid_to_entindex(e.userid) ~= me then return end
    if globals.realtime() - last_shot_time < 0.05 then return end
    last_shot_time = globals.realtime()

    if ui.get(ref_dt[1]) and ui.get(ref_dt[2]) then
        local delay = 0.20
        local weapon_class = get_weapon_class(me)
        if is_weapon_config_active(weapon_class) then
            delay = ui.get(sli_delay_time) * 0.01
        end

        ui.set(ref_dt[1], false)
        client.delay_call(delay, function()
            if ui.get(master_switch) and not ui.get(ref_dt[1]) then
                ui.set(ref_dt[1], true)
            end
        end)
    end
end)

-- -----------------------------------------------------------------------------
-- 区域功能：修复与菜单控制
-- -----------------------------------------------------------------------------
client.set_event_callback("item_equip", function(e)
    if not ui.get(master_switch) then return end
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        client.delay_call(0.05, function()
            ui.set(ref_dt[1], true)
        end)
    end
end)

local function handle_menu_visibility()
    local master = ui.get(master_switch)
    local custom = ui.get(chk_custom_delay)
    ui.set_visible(chk_custom_delay, master)
    ui.set_visible(sli_delay_time, master and custom)
    ui.set_visible(lbl_info, master and custom)
    ui.set_visible(mul_delay_weapons, master and custom)
end

ui.set_callback(master_switch, handle_menu_visibility)
ui.set_callback(chk_custom_delay, handle_menu_visibility)
handle_menu_visibility()
