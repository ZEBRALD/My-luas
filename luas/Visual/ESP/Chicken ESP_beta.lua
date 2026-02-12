local vector = require 'vector'
local csgo_weapons = require "gamesense/csgo_weapons"
local ffi = require "ffi"

-- -----------------------------------------------------------------------------
-- 1. FFI 初始化
-- -----------------------------------------------------------------------------
ffi.cdef[[
    typedef void***(__thiscall* FindHudElement_t)(void*, const char*);
    typedef void(__cdecl* ChatPrintf_t)(void*, int, int, const char*, ...);
]]

local signature_gHud = "\xB9\xCC\xCC\xCC\xCC\x88\x46\x09"
local signature_FindElement = "\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x57\x8B\xF9\x33\xF6\x39\x77\x28"

local match = client.find_signature("client_panorama.dll", signature_gHud)
local hud = ffi.cast("void**", ffi.cast("char*", match) + 1)[0]
match = client.find_signature("client_panorama.dll", signature_FindElement)
local find_hud_element = ffi.cast("FindHudElement_t", match)
local hudchat = find_hud_element(hud, "CHudChat")
local chudchat_vtbl = hudchat[0]
local print_to_chat = ffi.cast("ChatPrintf_t", chudchat_vtbl[27])

-- -----------------------------------------------------------------------------
-- 2. UI 菜单
-- -----------------------------------------------------------------------------
local master_switch = ui.new_checkbox("LUA", "B", "Chicken ESP")
local spawn_chicken = ui.new_button("LUA", "B", "Spawn Chicken", function() client.exec("give chicken") end)

local rage_switch = ui.new_checkbox("LUA", "B", "Chickenbot") 
local rage_key = ui.new_hotkey("LUA", "B", "Chickenbot Key", true)
local rage_distance = ui.new_slider("LUA", "B", "Chickenbot Max Distance", 0, 1000, 400, true, "FT", 1, {[1000] = "Unlimited"})

local esp_options = ui.new_multiselect("LUA", "B", "ESP Elements", {"Box", "Name", "Dormant", "Health bar", "Flags", "Distance"})
local log_options = ui.new_multiselect("LUA", "B", "Death Log Output", {"Console", "Local Chat", "Public Chat"})

ui.new_label("LUA", "B", "ESP Color Settings")
local box_color_picker = ui.new_color_picker("LUA", "B", "Box Color", 255, 255, 255, 255)

local dormant_label = ui.new_label("LUA", "B", "Dormant Color Settings")
local dormant_color = ui.new_color_picker("LUA", "B", "Dormant Color Picker", 255, 255, 255, 190)

-- -----------------------------------------------------------------------------
-- 3. 辅助函数
-- -----------------------------------------------------------------------------
local chicken_cache = {}
local landed_ticks = 0 

local function table_contains(tbl, val)
    for i=1, #tbl do if tbl[i] == val then return true end end
    return false
end

local function draw_bounding_box(x, y, w, h, r, g, b, a)
    renderer.rectangle(x, y, w, 1, r, g, b, a)
    renderer.rectangle(x, y + h, w, 1, r, g, b, a)
    renderer.rectangle(x, y, 1, h, r, g, b, a)
    renderer.rectangle(x + w, y, 1, h + 1, r, g, b, a)
end

-- -----------------------------------------------------------------------------
-- 4. Chickenbot
-- -----------------------------------------------------------------------------
local function chicken_aimbot(cmd)
    if not ui.get(master_switch) or not ui.get(rage_switch) or not ui.get(rage_key) then return end
    
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end
    
    local weapon_ent = entity.get_player_weapon(lp)
    if not weapon_ent then return end

    local weapon_id = bit.band(entity.get_prop(weapon_ent, "m_iItemDefinitionIndex"), 0xFFFF)
    local is_knife = (weapon_id >= 74 and weapon_id <= 80) or weapon_id >= 500 or weapon_id == 42 or weapon_id == 59
    local is_grenade = (weapon_id >= 43 and weapon_id <= 48)
    if is_knife or is_grenade or weapon_id == 49 or weapon_id == 31 then return end

    local next_attack = entity.get_prop(weapon_ent, "m_flNextPrimaryAttack")
    if next_attack ~= nil and next_attack > globals.curtime() then return end

    local flags = entity.get_prop(lp, "m_fFlags")
    if bit.band(flags, 1) == 0 then landed_ticks = 0 return else landed_ticks = landed_ticks + 1 end
    if landed_ticks < 5 then return end

    local eye_pos = vector(client.eye_position())
    local best_target, min_dist = nil, 99999
    local slider_limit = ui.get(rage_distance)

    for _, ent in ipairs(entity.get_all("CChicken")) do
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin")
        if ox then
            local target_pos = vector(ox, oy, oz + 9)
            local dist = eye_pos:dist(target_pos)
            if slider_limit == 1000 or (dist * 0.082) <= slider_limit then
                if dist < min_dist then
                    local frac, hit_ent = client.trace_line(lp, eye_pos.x, eye_pos.y, eye_pos.z, target_pos.x, target_pos.y, target_pos.z)
                    if hit_ent == ent or frac > 0.85 then
                        min_dist = dist
                        best_target = target_pos
                    end
                end
            end
        end
    end

    if best_target ~= nil then
        local vx, vy = entity.get_prop(lp, "m_vecVelocity[0]"), entity.get_prop(lp, "m_vecVelocity[1]")
        local velocity = math.sqrt(vx*vx + vy*vy)

        if velocity > 5 then
            local direction = vector(vx, vy, 0)
            local view_angles = vector(client.camera_angles())
            local direction_angles = vector(direction:angles())
            local direction_yaw = direction_angles.y - view_angles.y
            local rad = math.rad(direction_yaw)
            cmd.forwardmove = -math.cos(rad) * 450
            cmd.sidemove = math.sin(rad) * 450
        else
            cmd.forwardmove, cmd.sidemove = 0, 0
        end

        local p, y = eye_pos:to(best_target):angles()
        cmd.pitch, cmd.yaw = p, y
        if velocity < 20 then cmd.in_attack = 1 end
    end
end

-- -----------------------------------------------------------------------------
-- 5. ESP 渲染 (复刻 fishesp 逻辑)
-- -----------------------------------------------------------------------------
client.set_event_callback("paint", function()
    if not ui.get(master_switch) then return end
    local opt = ui.get(esp_options)
    local br, bg, bb, ba = ui.get(box_color_picker)
    local dr, dg, db, da = ui.get(dormant_color)
    local lp_origin = vector(entity.get_origin(entity.get_local_player()) or 0,0,0)
    
    local chickens, cur_frame = entity.get_all("CChicken"), {}
    for _, ent in ipairs(chickens) do
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin")
        if ox and not entity.is_dormant(ent) then chicken_cache[ent], cur_frame[ent] = {x=ox, y=oy, z=oz}, true end
    end

    for ent, data in pairs(chicken_cache) do
        if entity.get_classname(ent) ~= "CChicken" then chicken_cache[ent] = nil goto next end
        local is_dormant = (cur_frame[ent] == nil)
        if is_dormant and not table_contains(opt, "Dormant") then goto next end

        local sx_f, sy_f = renderer.world_to_screen(data.x, data.y, data.z)
        local sx_h, sy_h = renderer.world_to_screen(data.x, data.y, data.z + 18)

        if sx_f and sx_h then
            local h, w = sy_f - sy_h, (sy_f - sy_h) * 0.9
            local x1, y1 = sx_h - w/2, sy_h
            local x2 = x1 + w
            local cr, cg, cb, ca = is_dormant and dr or br, is_dormant and dg or bg, is_dormant and db or bb, is_dormant and da or ba

            -- Box
            if table_contains(opt, "Box") then
                draw_bounding_box(x1-1, y1-1, w+2, h+2, 0, 0, 0, ca*0.6)
                draw_bounding_box(x1, y1, w, h, cr, cg, cb, ca)
            end

            -- Name (复刻高度 -8)
            if table_contains(opt, "Name") then
                renderer.text(x1 + w/2, y1 - 8, 255, 255, 255, math.floor(ca * 0.85), "c", 0, is_dormant and "DORMANT" or "Chicken")
            end

            -- Health bar
            if table_contains(opt, "Health bar") then
                renderer.rectangle(x1 - 6, y1 - 1, 4, h + 2, 0, 0, 0, ca*0.6)
                renderer.rectangle(x1 - 5, y1, 2, h, 124, 195, 13, ca)
            end

            -- Flags (复刻顺序: $0 -> FLY -> LEAD，复刻色彩与间距)
            if table_contains(opt, "Flags") then
                local flags_to_draw = {}
                
                -- 1. $0 (鱼 ESP 绿色)
                table.insert(flags_to_draw, {text = "$0", r = 132, g = 192, b = 43})
                
                -- 2. FLY (鱼 ESP 蓝色: 212, 241, 249)
                local f_val = entity.get_prop(ent, "m_fFlags")
                if f_val and bit.band(f_val, 1) == 0 then 
                    table.insert(flags_to_draw, {text = "FLY", r = 212, g = 241, b = 249}) 
                end
                
                -- 3. LEAD (白色)
                if entity.get_prop(ent, "m_leader") ~= -1 then 
                    table.insert(flags_to_draw, {text = "LEAD", r = 255, g = 255, b = 255}) 
                end

                for i, f_info in ipairs(flags_to_draw) do
                    -- 鱼 ESP 水平偏移为 +2，间隔为 10
                    renderer.text(x2 + 2, y1 + (i-1)*10, f_info.r, f_info.g, f_info.b, ca, "-", 0, f_info.text)
                end
            end

            -- Distance (复刻高度 +6 及取整逻辑)
            if table_contains(opt, "Distance") then
                local feet = lp_origin:dist(vector(data.x, data.y, data.z)) * 0.082 + 0.5
                -- 鱼 ESP 取整逻辑: feet = round(feet) - round(feet) % 5
                local feet_rounded = math.floor(feet + 0.5)
                feet_rounded = feet_rounded - (feet_rounded % 5)
                
                renderer.text(x1 + w/2, sy_f + 6, 255, 255, 255, ca, "c-", 0, string.format("%sFT", feet_rounded))
            end
        end
        ::next::
    end
end)

-- -----------------------------------------------------------------------------
-- 6. Death Logs
-- -----------------------------------------------------------------------------
client.set_event_callback("other_death", function(e)
    if not ui.get(master_switch) or e.othertype ~= "chicken" then return end
    local attacker_idx = client.userid_to_entindex(e.attacker)
    local attacker_name = attacker_idx ~= 0 and entity.get_player_name(attacker_idx) or "未知玩家"
    local selected_logs = ui.get(log_options)

    local local_msg = string.format("\x01[\x04杀鸡通报\x01] 玩家 \x02%s \x01残忍杀害了一只 \x04小鸡\x01!", attacker_name)
    local public_msg = string.format("玩家 %s 杀害了一只小鸡!", attacker_name)

    if table_contains(selected_logs, "Console") then client.log(public_msg) end
    if table_contains(selected_logs, "Local Chat") then print_to_chat(hudchat, 0, 0, local_msg) end
    if table_contains(selected_logs, "Public Chat") then client.exec(string.format('say "%s"', public_msg)) end
end)

-- -----------------------------------------------------------------------------
-- 7. UI 显隐逻辑
-- -----------------------------------------------------------------------------
local function handle_vis()
    local s = ui.get(master_switch)
    local opt = ui.get(esp_options)
    local d_on = table_contains(opt, "Dormant")
    local r_on = ui.get(rage_switch)
    
    ui.set_visible(spawn_chicken, s)
    ui.set_visible(rage_switch, s)
    ui.set_visible(rage_key, s and r_on)
    ui.set_visible(rage_distance, s and r_on)
    ui.set_visible(esp_options, s)
    ui.set_visible(log_options, s)
    ui.set_visible(box_color_picker, s)
    ui.set_visible(dormant_label, s and d_on)
    ui.set_visible(dormant_color, s and d_on)
end

ui.set_callback(master_switch, handle_vis)
ui.set_callback(rage_switch, handle_vis)
ui.set_callback(esp_options, handle_vis)
handle_vis()

client.set_event_callback("setup_command", chicken_aimbot)
client.set_event_callback("round_start", function() chicken_cache = {}; landed_ticks = 0 end)
