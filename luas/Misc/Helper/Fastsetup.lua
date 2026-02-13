--created by zebrald with Gemini AI lmao

local ffi = require("ffi")

-- -----------------------------------------------------------------------------
-- 1. 状态追踪变量 (用于实现交替切换)
-- -----------------------------------------------------------------------------
local swap_states = {
    ["r8_deagle"] = false, -- false = Deagle, true = R8
    ["usp_p2000"] = false  -- false = P2000, true = USP
}

-- -----------------------------------------------------------------------------
-- 2. 纯净日志系统 (不带 [gamesense] 前缀)
-- -----------------------------------------------------------------------------
local function fast_log(msg)
    client.color_log(150, 200, 255, "[FastSetup] ")
    client.color_log(255, 255, 255, msg)
end

-- -----------------------------------------------------------------------------
-- 3. 指令结构与配置
-- -----------------------------------------------------------------------------
local menu_structure = {
    -- Local Server 环境分类
    ["Config/Init"] = {
        { 
            type = "button", name = "Load HVH Practice Config", 
            desc = "Infinite ammo, 60k money, 120 AA, Respawn ON.",
            cmd = "sv_cheats 1;sv_infinite_ammo 1;mp_roundtime_defuse 60;mp_roundtime 60;bot_stop 1;mp_freezetime 0;mp_buy_anywhere 1;mp_buytime 99999;mp_startmoney 60000;mp_maxmoney 60000;mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 1;mp_respawnwavetime_t 1;mp_ignore_round_win_conditions 1;mp_limitteams 0;mp_autoteambalance 0;sv_airaccelerate 120;sv_autobunnyhopping 1;mp_warmup_end;buddha 1;" 
        },
        { type = "button", name = "Restart Match", desc = "Instant round restart.", cmd = "mp_restartgame 1" },
        { type = "checkbox", name = "God Mode (Buddha)", desc = "Take damage but never die.", cmd = "buddha", default = true },
        { type = "checkbox", name = "Free Armor", desc = "Auto spawn with Kevlar + Helmet.", cmd = "mp_free_armor", val_on = 2, val_off = 0, default = true }
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
            { type = "button", name = "Add T Bot", desc = "Add one T bot.", cmd = "bot_add_t" },
            { type = "checkbox", name = "Nav Edit Mode", desc = "Show/Edit navigation mesh.", cmd = "nav_edit", default = false }
        }
    },
    ["Grenades"] = {
        { type = "hotkey", name = "Rethrow Last", desc = "Rethrow your last grenade.", cmd = "sv_rethrow_last_grenade" },
        { type = "button", name = "Give All Grenades", desc = "Get Smoke, Molotov, HE, Flash.", cmd = "give weapon_hegrenade; give weapon_smokegrenade; give weapon_flashbang; give weapon_molotov" },
        { type = "button", name = "Clear All Smokes", desc = "Instantly kill all smoke particles.", cmd = "ent_fire smokegrenade_projectile kill" },
        { type = "button", name = "Extinguish Fires", desc = "Kill all molotovs and infernos.", cmd = "ent_fire molotov_projectile kill; ent_fire inferno kill" },
        { type = "button", name = "Clear Decals", desc = "Clear blood and bullet holes.", cmd = "r_cleardecals" }
    },
    ["Movement/World"] = {
        { type = "hotkey", name = "Noclip Toggle", desc = "Fly through walls.", cmd = "noclip" },
        { type = "slider", name = "Air Accelerate", desc = "HvH Standard is 120.", cmd = "sv_airaccelerate", min = 10, max = 1000, default = 120 },
        { type = "slider", name = "Gravity", desc = "Default is 800.", cmd = "sv_gravity", min = 1, max = 1000, default = 800 },
        { type = "checkbox", name = "Auto Bunnyhop", desc = "Server-side BHOP.", cmd = "sv_autobunnyhopping", default = true },
        { type = "checkbox", name = "Bullet Penetration Data", desc = "Show wall penetration depth/damage.", cmd = "sv_showimpacts_penetration", default = false },
        { type = "checkbox", name = "Show Bullet Hits", desc = "Show server-side hit registration.", cmd = "sv_showbullethits", default = false }
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

    -- Private Server (SM) 环境分类
    ["Private Server (SM)"] = {
        { type = "button", name = "Setup Menu", desc = "Open setup plugin menu.", cmd = "sm_setup" },
        { type = "button", name = "Match: Ready", desc = "Mark yourself as ready.", cmd = "sm_ready" },
        { type = "button", name = "Match: Unready", desc = "Cancel your ready status.", cmd = "sm_notready" },
        { type = "button", name = "Force End Match", desc = "Instantly end the current match.", cmd = "sm_forceend" },
        { type = "button", name = "Pause Match", desc = "Pause current game.", cmd = "sm_pause" },
        { type = "button", name = "Unpause Match", desc = "Resume current game.", cmd = "sm_unpause" },
        -- 修复后的 Swap 逻辑按钮
        { 
            type = "swap_button", 
            name = "Swap: R8 / Deagle", 
            desc = "Toggle between R8 Revolver and Desert Eagle.", 
            id = "r8_deagle",
            cmds = {"say_team !deagle", "say_team !r8"},
            names = {"Deagle", "R8"}
        },
        { 
            type = "swap_button", 
            name = "Swap: USP / P2000", 
            desc = "Toggle between USP-S and P2000.", 
            id = "usp_p2000",
            cmds = {"say_team !p2000", "say_team !usp"},
            names = {"P2000", "USP-S"}
        },
        { type = "button", name = "10-Man Config", desc = "Apply standard 10-man HvH configuration.", cmd = "sm_10man" }
    }
}

-- -----------------------------------------------------------------------------
-- 4. UI 核心逻辑引擎
-- -----------------------------------------------------------------------------
local master_switch = ui.new_checkbox("LUA", "B", "Local Server FastSetup")
local env_types = {"Local Server", "Private Server (SM)"}
local env_select = ui.new_combobox("LUA", "B", "Environment", env_types)

local local_cats = {"Config/Init", "Bot", "Grenades", "Movement/World", "HUD/Visuals"}
local category_select = ui.new_combobox("LUA", "B", "Feature Category", local_cats)

local bot_sub_cats = {"Behavior", "Combat/HvH", "Positioning"}
local bot_sub_select = ui.new_combobox("LUA", "B", "Bot Settings Group", bot_sub_cats)

local ui_elements = {}

local function exec_cmd(name, cmd, val)
    local final_cmd = val ~= nil and (cmd .. " " .. tostring(val)) or cmd
    client.exec(final_cmd)
    fast_log(string.format("Active: %s -> %s\n", name, tostring(val or "Executed")))
end

-- -----------------------------------------------------------------------------
-- 5. 统一构建 UI 控件
-- -----------------------------------------------------------------------------
local function create_item(cat_key, sub_key, item)
    local storage_key = sub_key and (cat_key .. sub_key) or cat_key
    if not ui_elements[storage_key] then ui_elements[storage_key] = {} end

    local label = ui.new_label("LUA", "B", "» " .. item.desc)
    local ctrl = nil

    if item.type == "button" then
        ctrl = ui.new_button("LUA", "B", item.name, function() exec_cmd(item.name, item.cmd) end)
    
    elseif item.type == "swap_button" then
        ctrl = ui.new_button("LUA", "B", item.name, function()
            swap_states[item.id] = not swap_states[item.id]
            local idx = swap_states[item.id] and 2 or 1
            local target_cmd = item.cmds[idx]
            local target_name = item.names[idx]
            client.exec(target_cmd)
            fast_log(string.format("Swapped to: %s (Executed %s)\n", target_name, target_cmd))
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
                if now - last_t > 0.25 then exec_cmd(item.name, item.cmd); last_t = now end
            end
        end)
    end
    table.insert(ui_elements[storage_key], label)
    table.insert(ui_elements[storage_key], ctrl)
end

-- 初始化所有 UI
for k, v in pairs(menu_structure) do
    if k == "Bot" then
        for sub_k, sub_v in pairs(v) do for _, item in ipairs(sub_v) do create_item(k, sub_k, item) end end
    else
        for _, item in ipairs(v) do create_item(k, nil, item) end
    end
end

-- -----------------------------------------------------------------------------
-- 6. 显隐控制逻辑
-- -----------------------------------------------------------------------------
local function update_ui()
    local m_on = ui.get(master_switch)
    local env = ui.get(env_select)
    local cur_cat = ui.get(category_select)
    
    ui.set_visible(env_select, m_on)
    local is_local = (env == "Local Server")
    ui.set_visible(category_select, m_on and is_local)
    local is_bot = is_local and (cur_cat == "Bot")
    ui.set_visible(bot_sub_select, m_on and is_bot)

    for key, elms in pairs(ui_elements) do
        local should_show = false
        if m_on then
            if env == "Private Server (SM)" then
                if key == "Private Server (SM)" then should_show = true end
            else
                if is_bot then
                    if key == ("Bot" .. ui.get(bot_sub_select)) then should_show = true end
                else
                    if key == cur_cat then should_show = true end
                end
            end
        end
        for _, e in ipairs(elms) do ui.set_visible(e, should_show) end
    end
end

ui.set_callback(master_switch, update_ui)
ui.set_callback(env_select, update_ui)
ui.set_callback(category_select, update_ui)
ui.set_callback(bot_sub_select, update_ui)
update_ui()

fast_log("Server Manager Pro Loaded. Choose Environment to start.\n")