-- created by zebrald with Gemini AI (Optimized: Single Map List Version)

local ffi = require("ffi")

-- -----------------------------------------------------------------------------
-- 1. 状态追踪与基础变量
-- -----------------------------------------------------------------------------
local swap_states = {
    ["r8_deagle"] = false, -- false = Deagle, true = R8
    ["usp_p2000"] = false  -- false = P2000, true = USP
}

-- 合并所有地图并去重
local all_maps_raw = {
    "de_mirage", "de_inferno", "de_overpass", "de_vertigo", "de_nuke", "de_ancient", "de_anubis", 
    "de_dust2", "de_train", "de_cache", "de_cbble", "de_shortnuke", "de_lake", "de_boyard", 
    "de_chalice", "cs_agency", "cs_office", "de_stmarc", "de_safehouse", "de_bank", 
    "de_lunacy", "ar_baggage", "ar_monastery", "ar_shoots", "dz_sirocco", "dz_blacksite", 
    "dz_vineyard", "dz_ember"
}
table.sort(all_maps_raw) -- 字母排序方便查找

-- -----------------------------------------------------------------------------
-- 2. 增强型日志系统
-- -----------------------------------------------------------------------------
local function fast_log(msg, r, g, b)
    r, g, b = r or 150, g or 200, b or 255
    client.color_log(r, g, b, "[FastSetup] ")
    client.color_log(255, 255, 255, msg)
end

client.set_event_callback("console_log", function(text)
    if text:find("Unknown command:") then
        fast_log("当前服务器不支持此命令 (Unknown Command)\n", 255, 100, 100)
    elseif text:find("%[SM%] You do not have access to this command") then
        fast_log("你没有权限使用此命令 (No Permission)\n", 255, 100, 100)
    end
end)

-- -----------------------------------------------------------------------------
-- 3. 指令结构与配置 (保留所有逻辑)
-- -----------------------------------------------------------------------------
local menu_structure = {
    ["Config/Init"] = {
        { type = "button", name = "Load HVH Practice Config", desc = "Infinite ammo, 60k money, 120 AA, Respawn ON.", cmd = "sv_cheats 1;sv_infinite_ammo 1;mp_roundtime_defuse 60;mp_roundtime 60;bot_stop 1;mp_freezetime 0;mp_buy_anywhere 1;mp_buytime 99999;mp_startmoney 60000;mp_maxmoney 60000;mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 1;mp_respawnwavetime_t 1;mp_ignore_round_win_conditions 1;mp_limitteams 0;mp_autoteambalance 0;sv_airaccelerate 120;sv_autobunnyhopping 1;mp_warmup_end;buddha 1;" },
        { type = "button", name = "Restart Match", desc = "Instant round restart.", cmd = "mp_restartgame 1" },
        { type = "checkbox", name = "God Mode (Buddha)", desc = "Take damage but never die.", cmd = "buddha", default = true },
        { type = "checkbox", name = "Free Armor", desc = "Auto spawn with Kevlar + Helmet.", cmd = "mp_free_armor", val_on = 2, val_off = 0, default = true }
    },
    ["Movement/World"] = {
        { type = "hotkey", name = "Noclip Toggle", desc = "Fly through walls.", cmd = "noclip" },
        { type = "slider", name = "Air Accelerate", desc = "HvH Standard is 120.", cmd = "sv_airaccelerate", min = 10, max = 1000, default = 120 },
        { type = "slider", name = "Gravity", desc = "Default is 800.", cmd = "sv_gravity", min = 1, max = 1000, default = 800 },
        { type = "checkbox", name = "Auto Bunnyhop", desc = "Server-side BHOP.", cmd = "sv_autobunnyhopping", default = true },
        { type = "checkbox", name = "Bullet Penetration Data", desc = "Show wall penetration depth/damage.", cmd = "sv_showimpacts_penetration", default = false },
        { type = "checkbox", name = "Show Bullet Hits", desc = "Show server-side hit registration.", cmd = "sv_showbullethits", default = false }
    },
    ["Bot"] = {
        ["Behavior"] = {
            { type = "checkbox", name = "Bot Stop", desc = "Freeze all bot processing.", cmd = "bot_stop", default = true },
            { type = "checkbox", name = "Bot Freeze", desc = "Strictly freeze bot models in place.", cmd = "bot_freeze", default = false },
            { type = "checkbox", name = "Bot Don't Shoot", desc = "Bots will not fire weapons.", cmd = "bot_dont_shoot", default = true },
            { type = "checkbox", name = "Bot Zombie", desc = "Bots won't move or react.", cmd = "bot_zombie", default = false },
            { type = "checkbox", name = "Bot Crouch", desc = "Force all bots to crouch.", cmd = "bot_crouch", default = false },
            { type = "checkbox", name = "Bot Mimic", desc = "Bots copy your movements.", cmd = "bot_mimic", default = false },
            { type = "slider", name = "Mimic Yaw Offset", desc = "180 = Bot faces you.", cmd = "bot_mimic_yaw_offset", min = 0, max = 360, default = 180 }
        },
        ["Combat/HvH"] = {
            { type = "button", name = "Loadout: M4A1 & SSG08", desc = "Give bots specific weapons.", cmd = "bot_loadout \"m4a1 ssg08\"" },
            { type = "button", name = "Bots: Knives Only", desc = "Force bots to use knives.", cmd = "bot_knives_only" },
            { type = "button", name = "Bots: Pistols Only", desc = "Force bots to use pistols.", cmd = "bot_pistols_only" },
            { type = "button", name = "Bots: All Weapons", desc = "Restore bot weapon usage.", cmd = "bot_all_weapons" },
            { type = "checkbox", name = "No Weapon Drop", desc = "Bots don't drop guns on death.", cmd = "mp_death_drop_gun", default = true },
            { type = "checkbox", name = "Regeneration", desc = "Forced health regeneration.", cmd = "sv_regeneration_force_on", default = false },
            { type = "checkbox", name = "Headshot Only", desc = "Only headshots deal damage.", cmd = "mp_damage_headshot_only", default = false }
        },
        ["Positioning"] = {
            { type = "hotkey", name = "Place Bot", desc = "Teleport bot to your crosshair.", cmd = "bot_place" },
            { type = "button", name = "Kick All Bots", desc = "Clear all bots.", cmd = "bot_kick" },
            { type = "button", name = "Add CT Bot", desc = "Add one CT bot.", cmd = "bot_add_ct" },
            { type = "button", name = "Add T Bot", desc = "Add one T bot.", cmd = "bot_add_t" }
        }
    },
    ["Grenades"] = {
        { type = "hotkey", name = "Rethrow Last", desc = "Rethrow your last grenade.", cmd = "sv_rethrow_last_grenade" },
        { type = "button", name = "Give All Grenades", desc = "Get Smoke, Molotov, HE, Flash.", cmd = "give weapon_hegrenade; give weapon_smokegrenade; give weapon_flashbang; give weapon_molotov" },
        { type = "button", name = "Clear All Smokes", desc = "Instantly kill all smoke particles.", cmd = "ent_fire smokegrenade_projectile kill" },
        { type = "button", name = "Extinguish Fires", desc = "Kill all molotovs and infernos.", cmd = "ent_fire molotov_projectile kill; ent_fire inferno kill" },
        { type = "button", name = "Clear Decals", desc = "Clear blood and bullet holes.", cmd = "r_cleardecals" }
    },
    ["HUD/Visuals"] = {
        { 
            type = "checkbox", name = "Movie HUD Mode", 
            desc = "Only show Deathnotices (for recording).", 
            cmd = "cl_draw_only_Deathnotices", 
            custom_logic = function(val)
                if val == 1 then
                    client.exec("cl_draw_only_Deathnotices 1; cl_drawhud_force_deathnotices -1; net_graph 0")
                else
                    client.exec("cl_draw_only_Deathnotices 0; cl_drawhud_force_deathnotices 0; net_graph 1")
                end
            end
        },
        { type = "checkbox", name = "Show Battlefront", desc = "Show where bots are engaging.", cmd = "bot_show_battlefront", default = false },
        { type = "slider", name = "Timescale", desc = "Host speed (0.5 = Slowmo).", cmd = "host_timescale", min = 10, max = 200, default = 100, scale = 0.01 }
    },

    ["Match (SM)"] = {
        { type = "button", name = "PUG Setup", desc = "Open PugSetup Menu.", cmd = "sm_setup" },
        { type = "button", name = "Force Start", desc = "Force start the game.", cmd = "sm_forcestart" },
        { type = "button", name = "10-Man Setup", desc = "Fast 10-man gather config.", cmd = "sm_10man" },
        { type = "button", name = "Match Ready", desc = "Set ready status.", cmd = "sm_ready" },
        { type = "button", name = "Match Unready", desc = "Set not ready status.", cmd = "sm_notready" },
        { type = "button", name = "Knife Round", desc = "Start knife round.", cmd = "sm_knives" },
        { type = "button", name = "Pistol Round", desc = "Start pistol round.", cmd = "sm_pistols" },
        { type = "button", name = "Pause", desc = "Pause match.", cmd = "sm_pause" },
        { type = "button", name = "Unpause", desc = "Unpause match.", cmd = "sm_unpause" },
        { type = "button", name = "Force End", desc = "Pre-emptively ends the match.", cmd = "sm_forceend" }
    },
    ["Players (SM)"] = {
        { type = "player_list", name = "Target Player", desc = "Select a player for admin actions." },
        { type = "player_action", name = "Slay Player", cmd = "sm_slay" },
        { type = "player_action", name = "Slap (0 HP)", cmd = "sm_slap" },
        { type = "player_action", name = "Respawn", cmd = "sm_respawn" },
        { type = "player_action", name = "Toggle Noclip", cmd = "sm_noclip" },
        { type = "player_action", name = "Mute Voice", cmd = "sm_mute" },
        { type = "player_action", name = "Gag Chat", cmd = "sm_gag" },
        { type = "player_action", name = "Beacon Player", cmd = "sm_beacon" },
        { type = "player_action", name = "Drug Player", cmd = "sm_drug" },
        { type = "player_action", name = "Kick Player", cmd = "sm_kick" }
    },
    ["Server (SM)"] = {
        { type = "map_manager", name = "Map Manager", desc = "Select a map and click Change." },
        { type = "swap_button", name = "Swap: R8 / Deagle", id = "r8_deagle", cmds = {"say /deagle", "say /r8"}, names = {"Deagle", "R8"}, desc = "Toggle between R8 and Deagle." },
        { type = "swap_button", name = "Swap: USP / P2000", id = "usp_p2000", cmds = {"say /p2000", "say /usp"}, names = {"P2000", "USP-S"}, desc = "Toggle between USP and P2000." },
        { type = "button", name = "Reload Restrictions", desc = "Fix weapon restriction issues.", cmd = "sm_reload_restrictions" }
    },
    ["Broadcast (SM)"] = {
        { type = "button", name = "Say 'LIVE!'", desc = "Center screen message.", cmd = "sm_csay LIVE LIVE LIVE!" },
        { type = "button", name = "Say 'READY UP!'", desc = "Hint message.", cmd = "sm_hsay PLEASE .READY UP!" },
        { type = "button", name = "Admin Say", desc = "Standard chat broadcast.", cmd = "sm_say Admin is here." }
    }
}

-- -----------------------------------------------------------------------------
-- 4. UI 核心控件
-- -----------------------------------------------------------------------------
local master_switch = ui.new_checkbox("LUA", "B", "FastSetup [Server Manager]")
local env_types = {"Local Server", "Private Server (SM)"}
local env_select = ui.new_combobox("LUA", "B", "Environment", env_types)

local local_cats = {"Config/Init", "Movement/World", "Bot", "Grenades", "HUD/Visuals"}
local local_cat_select = ui.new_combobox("LUA", "B", "Local Features", local_cats)

local sm_cats = {"Match (SM)", "Players (SM)", "Server (SM)", "Broadcast (SM)"}
local sm_cat_select = ui.new_combobox("LUA", "B", "Server Features", sm_cats)

local bot_sub_cats = {"Behavior", "Combat/HvH", "Positioning"}
local bot_sub_select = ui.new_combobox("LUA", "B", "Bot Settings Group", bot_sub_cats)

local player_listbox = ui.new_listbox("LUA", "B", "Player Select", {"Refresh to load..."})

-- 地图管理器：移除 Mode，直接使用单一列表
local map_select = ui.new_combobox("LUA", "B", "Select Map", all_maps_raw)

local ui_elements = {}

-- -----------------------------------------------------------------------------
-- 5. 执行与构建函数
-- -----------------------------------------------------------------------------
local function exec_cmd(name, cmd, val)
    local final_cmd = val ~= nil and (cmd .. " " .. tostring(val)) or cmd
    client.exec(final_cmd)
    fast_log(string.format("Action: %s (%s)\n", name, tostring(val or "Sent")))
end

local function create_item(cat_key, sub_key, item)
    local storage_key = sub_key and (cat_key .. sub_key) or cat_key
    if not ui_elements[storage_key] then ui_elements[storage_key] = {} end

    if item.desc then
        local label = ui.new_label("LUA", "B", "» " .. item.desc)
        table.insert(ui_elements[storage_key], label)
    end
    
    local ctrl = nil
    if item.type == "button" then
        ctrl = ui.new_button("LUA", "B", item.name, function() exec_cmd(item.name, item.cmd) end)
    elseif item.type == "swap_button" then
        ctrl = ui.new_button("LUA", "B", item.name, function()
            swap_states[item.id] = not swap_states[item.id]
            local idx = swap_states[item.id] and 2 or 1
            client.exec(item.cmds[idx])
            fast_log(string.format("Swapped to: %s\n", item.names[idx]))
        end)
    elseif item.type == "checkbox" then
        ctrl = ui.new_checkbox("LUA", "B", item.name)
        if item.default then ui.set(ctrl, true) end
        ui.set_callback(ctrl, function(ref)
            local val = ui.get(ref) and (item.val_on or 1) or (item.val_off or 0)
            if item.custom_logic then item.custom_logic(val) else exec_cmd(item.name, item.cmd, val) end
        end)
    elseif item.type == "slider" then
        ctrl = ui.new_slider("LUA", "B", item.name, item.min, item.max, item.default, true, "", item.scale or 1)
        ui.set_callback(ctrl, function(ref)
            local val = ui.get(ref) * (item.scale or 1)
            exec_cmd(item.name, item.cmd, val)
        end)
    elseif item.type == "hotkey" then
        ctrl = ui.new_hotkey("LUA", "B", item.name, true)
        local last_t = 0
        client.set_event_callback("paint", function()
            if ui.get(master_switch) and ui.get(ctrl) then
                local now = globals.realtime()
                if now - last_t > 0.3 then exec_cmd(item.name, item.cmd); last_t = now end
            end
        end)
    elseif item.type == "player_list" then
        ctrl = ui.new_button("LUA", "B", "Refresh Players", function()
            local players = {}
            local player_indices = entity.get_players()
            for _, idx in ipairs(player_indices) do table.insert(players, entity.get_player_name(idx)) end
            ui.update(player_listbox, #players > 0 and players or {"No Players Found"})
        end)
    elseif item.type == "player_action" then
        ctrl = ui.new_button("LUA", "B", item.name, function()
            local selected = ui.get(player_listbox)
            local players = entity.get_players()
            if players[selected + 1] then
                local name = entity.get_player_name(players[selected + 1])
                exec_cmd(item.name, item.cmd .. " \"" .. name .. "\"")
            end
        end)
    elseif item.type == "map_manager" then
        ctrl = ui.new_button("LUA", "B", "Change Map (sm_map)", function()
            local map_name = ui.get(map_select) 
            client.exec("sm_map " .. map_name)
            fast_log("Command sent: sm_map " .. map_name .. "\n")
        end)
    end
    
    if ctrl then table.insert(ui_elements[storage_key], ctrl) end
end

-- -----------------------------------------------------------------------------
-- 6. 初始化与显隐控制
-- -----------------------------------------------------------------------------
for k, v in pairs(menu_structure) do
    if k == "Bot" then
        for sub_k, sub_v in pairs(v) do for _, item in ipairs(sub_v) do create_item(k, sub_k, item) end end
    else
        for _, item in ipairs(v) do create_item(k, nil, item) end
    end
end

local function update_ui()
    local m_on = ui.get(master_switch)
    local env = ui.get(env_select)
    ui.set_visible(env_select, m_on)
    
    local is_local = (m_on and env == "Local Server")
    local is_sm = (m_on and env == "Private Server (SM)")

    ui.set_visible(local_cat_select, is_local)
    ui.set_visible(sm_cat_select, is_sm)

    local cur_local = ui.get(local_cat_select)
    local cur_sm = ui.get(sm_cat_select)

    -- 子菜单/特殊组件显隐
    ui.set_visible(bot_sub_select, is_local and cur_local == "Bot")
    ui.set_visible(player_listbox, is_sm and cur_sm == "Players (SM)")
    ui.set_visible(map_select, is_sm and cur_sm == "Server (SM)")

    -- 循环控制所有动态生成的组件
    for key, elms in pairs(ui_elements) do
        local show = false
        if is_local then
            if cur_local == "Bot" then
                if key == ("Bot" .. ui.get(bot_sub_select)) then show = true end
            elseif key == cur_local then show = true end
        elseif is_sm and key == cur_sm then
            show = true
        end
        for _, e in ipairs(elms) do ui.set_visible(e, show) end
    end
end

-- 绑定回调
ui.set_callback(master_switch, update_ui)
ui.set_callback(env_select, update_ui)
ui.set_callback(local_cat_select, update_ui)
ui.set_callback(sm_cat_select, update_ui)
ui.set_callback(bot_sub_select, update_ui)

-- 初始执行
update_ui()
fast_log("Server Manager Pro V2.2 Loaded. Single Map List active.\n")
