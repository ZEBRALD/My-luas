local ffi = require("ffi")

-- -----------------------------------------------------------------------------
-- 1. FFI 接口定义
-- -----------------------------------------------------------------------------
local filesystem = client.create_interface("filesystem_stdio.dll", "VFileSystem017")
local find_first = ffi.cast(ffi.typeof("const char* (__thiscall*)(void*, const char*, const char*, int*)"), ffi.cast("void***", filesystem)[0][32])
local find_next = ffi.cast(ffi.typeof("const char* (__thiscall*)(void*, int)"), ffi.cast("void***", filesystem)[0][33])
local find_close = ffi.cast(ffi.typeof("void (__thiscall*)(void*, int)"), ffi.cast("void***", filesystem)[0][35])

local surface_interface = client.create_interface("vguimatsurface.dll", "VGUI_Surface031")
local native_Surface_PlaySound = ffi.cast(ffi.typeof("void(__thiscall*)(void*, const char*)"), ffi.cast("void***", surface_interface)[0][82])

-- -----------------------------------------------------------------------------
-- 2. 音效库扫描
-- -----------------------------------------------------------------------------
local function get_all_sounds()
    local files = { "None", "Wood stop", "Wood strain", "Wood plank impact", "Warning" }
    local internal_paths = {
        ["Wood stop"] = "doors/wood_stop1.wav",
        ["Wood strain"] = "physics/wood/wood_strain7.wav",
        ["Wood plank impact"] = "physics/wood/wood_plank_impact_hard4.wav",
        ["Warning"] = "resource/warning.wav"
    }

    local handle_ptr = ffi.new("int[1]")
    local file = find_first(filesystem, "sound/hitsounds/*", "GAME", handle_ptr)
    if handle_ptr[0] ~= -1 then
        while file ~= nil do
            local filename = ffi.string(file)
            if filename ~= "." and filename ~= ".." then
                local lower_name = filename:lower()
                if lower_name:find(".wav") or lower_name:find(".mp3") then 
                    table.insert(files, filename) 
                end
            end
            file = find_next(filesystem, handle_ptr[0])
        end
        find_close(filesystem, handle_ptr[0])
    end
    return files, internal_paths
end

local sound_list, internal_paths = get_all_sounds()

-- -----------------------------------------------------------------------------
-- 3. UI 菜单构建
-- -----------------------------------------------------------------------------
local master_switch = ui.new_checkbox("LUA", "B", "Ultimate Sound System")
local show_config = ui.new_checkbox("LUA", "B", "Show detailed settings")

local active_features = ui.new_multiselect("LUA", "B", "Active features", {
    "Headshot", "Bodyshot", "Kill", "Death", 
    "Round Win", "Round Loss", "Match Win", "Match Loss", "Menu Open"
})

local config = {}
local function create_config_group(name)
    config[name] = {
        label = ui.new_label("LUA", "B", "--- " .. name .. " ---"),
        sound = ui.new_combobox("LUA", "B", "\n" .. name .. "_file", sound_list),
        -- 所有音量默认值设为 100，当达到 100 时显示 "Instantly"
        vol   = ui.new_slider("LUA", "B", name .. " Volume", 0, 100, 100, true, "%", 1, {[100] = "Instantly"})
    }
end

local features = {"Headshot", "Bodyshot", "Kill", "Death", "Round Win", "Round Loss", "Match Win", "Match Loss", "Menu Open"}
for i=1, #features do create_config_group(features[i]) end

-- 菜单末尾的说明文字
ui.new_label("LUA", "B", " ")
local info_label = ui.new_label("LUA", "B", "💡 [Tip] Set Volume to 'Instantly' for Zero-Latency.")

local function update_ui_visibility()
    local is_master = ui.get(master_switch)
    local is_config = ui.get(show_config)
    local selected = ui.get(active_features)
    
    ui.set_visible(show_config, is_master)
    ui.set_visible(active_features, is_master)
    ui.set_visible(info_label, is_master and is_config)

    for name, widgets in pairs(config) do
        local is_feature_active = false
        for i=1, #selected do if selected[i] == name then is_feature_active = true break end end
        local visible = is_master and is_config and is_feature_active
        ui.set_visible(widgets.label, visible)
        ui.set_visible(widgets.sound, visible)
        ui.set_visible(widgets.vol, visible)
    end
end

ui.set_callback(master_switch, update_ui_visibility)
ui.set_callback(show_config, update_ui_visibility)
ui.set_callback(active_features, update_ui_visibility)
update_ui_visibility()

-- -----------------------------------------------------------------------------
-- 4. 混合智能引擎逻辑 (核心改动)
-- -----------------------------------------------------------------------------
local function get_path(selection)
    return internal_paths[selection] or ("hitsounds/" .. selection)
end

local function play_hybrid(name)
    local sel = ui.get(config[name].sound)
    local vol = ui.get(config[name].vol)
    if sel == "None" then return end

    local path = get_path(sel)

    if vol >= 100 then
        -- 极速模式：音量 100 时切换底层接口实现零延迟
        native_Surface_PlaySound(surface_interface, path)
    else
        -- 调节模式：音量 < 100 时切换标准接口以支持音量缩放
        client.exec(string.format("playvol \"%s\" %.2f", path, vol / 100))
    end
end

local function is_active(name)
    local selected = ui.get(active_features)
    for i=1, #selected do if selected[i] == name then return true end end
    return false
end

-- -----------------------------------------------------------------------------
-- 5. 事件分发 (全部接入 Hybrid 引擎)
-- -----------------------------------------------------------------------------

client.set_event_callback("player_hurt", function(e)
    if not ui.get(master_switch) then return end
    local lp = entity.get_local_player()
    if client.userid_to_entindex(e.attacker) == lp and client.userid_to_entindex(e.userid) ~= lp then
        if e.hitgroup == 1 and is_active("Headshot") then play_hybrid("Headshot")
        elseif is_active("Bodyshot") then play_hybrid("Bodyshot") end
    end
end)

client.set_event_callback("player_death", function(e)
    if not ui.get(master_switch) then return end
    local lp = entity.get_local_player()
    local victim = client.userid_to_entindex(e.userid)
    local attacker = client.userid_to_entindex(e.attacker)
    if attacker == lp and victim ~= lp and is_active("Kill") then play_hybrid("Kill") end
    if victim == lp and is_active("Death") then play_hybrid("Death") end
end)

client.set_event_callback("round_end", function(e)
    if not ui.get(master_switch) then return end
    local lp = entity.get_local_player()
    if lp == nil then return end
    local is_win = (entity.get_prop(lp, "m_iTeamNum") == e.winner)
    
    if e.reason == 16 then 
        if is_win and is_active("Match Win") then play_hybrid("Match Win")
        elseif not is_win and is_active("Match Loss") then play_hybrid("Match Loss") end
    else 
        if is_win and is_active("Round Win") then play_hybrid("Round Win")
        elseif not is_win and is_active("Round Loss") then play_hybrid("Round Loss") end
    end
end)

local last_menu_state = false
client.set_event_callback("paint_ui", function()
    if not ui.get(master_switch) then return end
    local current_state = ui.is_menu_open()
    if current_state and not last_menu_state then
        if is_active("Menu Open") then play_hybrid("Menu Open") end
    end
    last_menu_state = current_state
end)