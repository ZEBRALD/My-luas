local g_esp_data = { }
local g_sim_ticks, g_net_data = { }, { }

local globals_tickinterval = globals.tickinterval
local entity_is_enemy = entity.is_enemy
local entity_get_prop = entity.get_prop
local entity_is_dormant = entity.is_dormant
local entity_is_alive = entity.is_alive
local entity_get_origin = entity.get_origin
local entity_get_local_player = entity.get_local_player
local entity_get_player_resource = entity.get_player_resource
local entity_get_bounding_box = entity.get_bounding_box
local entity_get_player_name = entity.get_player_name
local renderer_text = renderer.text
local w2s = renderer.world_to_screen
local line = renderer.line
local table_insert = table.insert
local client_trace_line = client.trace_line
local math_floor = math.floor
local globals_frametime = globals.frametime

local sv_gravity = cvar.sv_gravity
local sv_jump_impulse = cvar.sv_jump_impulse

--region [ UI 控件定义 ]
local master_switch = ui.new_checkbox("VISUALS", "Other ESP", "Exploit Detector")

local c_box_label = ui.new_label("VISUALS", "Other ESP", "Lagcomp Box Color")
local c_box = ui.new_color_picker("VISUALS", "Other ESP", "Lagcomp Box Color", 47, 117, 221, 255)

local c_lc_label = ui.new_label("VISUALS", "Other ESP", "Lagcomp Breaker Color")
local c_lc = ui.new_color_picker("VISUALS", "Other ESP", "Lagcomp Breaker Color", 255, 45, 45, 255)

local c_tb_label = ui.new_label("VISUALS", "Other ESP", "Tickbase Shift Color")
local c_tb = ui.new_color_picker("VISUALS", "Other ESP", "Tickbase Shift Color", 255, 200, 0, 255)

-- 处理 UI 显示/隐藏逻辑
local function handle_menu()
    local active = ui.get(master_switch)
    ui.set_visible(c_box_label, active)
    ui.set_visible(c_box, active)
    ui.set_visible(c_lc_label, active)
    ui.set_visible(c_lc, active)
    ui.set_visible(c_tb_label, active)
    ui.set_visible(c_tb, active)
end

ui.set_callback(master_switch, handle_menu)
handle_menu() -- 初始化执行一次
--endregion

local time_to_ticks = function(t) return math_floor(0.5 + (t / globals_tickinterval())) end
local vec_substract = function(a, b) return { a[1] - b[1], a[2] - b[2], a[3] - b[3] } end
local vec_add = function(a, b) return { a[1] + b[1], a[2] + b[2], a[3] + b[3] } end
local vec_lenght = function(x, y) return (x * x + y * y) end

local get_entities = function(enemy_only, alive_only)
    local enemy_only = enemy_only ~= nil and enemy_only or false
    local alive_only = alive_only ~= nil and alive_only or true
    local result = {}
    for player = 1, globals.maxplayers() do
        local is_enemy, is_alive = true, true
        if enemy_only and not entity_is_enemy(player) then is_enemy = false end
        if is_enemy then
            if alive_only and not entity_is_alive(player) then is_alive = false end
            if is_alive then table_insert(result, player) end
        end
    end
    return result
end

local extrapolate = function(ent, origin, flags, ticks)
    local tickinterval = globals_tickinterval()
    local sv_gravity_val = sv_gravity:get_float() * tickinterval
    local sv_jump_val = sv_jump_impulse:get_float() * tickinterval
    local p_origin, prev_origin = origin, origin
    local velocity = { entity_get_prop(ent, 'm_vecVelocity') }
    local gravity = velocity[3] > 0 and -sv_gravity_val or sv_jump_val
    for i=1, ticks do
        prev_origin = p_origin
        p_origin = {
            p_origin[1] + (velocity[1] * tickinterval),
            p_origin[2] + (velocity[2] * tickinterval),
            p_origin[3] + (velocity[3]+gravity) * tickinterval,
        }
        local fraction = client_trace_line(-1, prev_origin[1], prev_origin[2], prev_origin[3], p_origin[1], p_origin[2], p_origin[3])
        if fraction <= 0.99 then return prev_origin end
    end
    return p_origin
end

local function g_net_update()
    if not ui.get(master_switch) then return end -- 总开关判断

    local players = get_entities(true, true)
    for i=1, #players do
        local idx = players[i]
        local prev_tick = g_sim_ticks[idx]
        if entity_is_dormant(idx) or not entity_is_alive(idx) then
            g_sim_ticks[idx] = nil
            g_net_data[idx] = nil
            g_esp_data[idx] = nil
        else
            local player_origin = { entity_get_origin(idx) }
            local simulation_time = time_to_ticks(entity_get_prop(idx, 'm_flSimulationTime'))
            if prev_tick ~= nil then
                local delta = simulation_time - prev_tick.tick
                if delta < 0 or (delta > 0 and delta <= 64) then
                    local m_fFlags = entity_get_prop(idx, 'm_fFlags')
                    local diff_origin = vec_substract(player_origin, prev_tick.origin)
                    local teleport_distance = vec_lenght(diff_origin[1], diff_origin[2])
                    local extrapolated = extrapolate(idx, player_origin, m_fFlags, delta-1)
                    if delta < 0 then g_esp_data[idx] = 1 end
                    g_net_data[idx] = {
                        tick = delta-1,
                        origin = player_origin,
                        predicted_origin = extrapolated,
                        tickbase = delta < 0,
                        lagcomp = teleport_distance > 4096,
                    }
                end
            end
            if g_esp_data[idx] == nil then g_esp_data[idx] = 0 end
            g_sim_ticks[idx] = { tick = simulation_time, origin = player_origin }
        end
    end
end

local function g_paint_handler()
    if not ui.get(master_switch) then return end -- 总开关判断

    local me = entity_get_local_player()
    if not me or not entity_is_alive(me) then return end

    for idx, net_data in pairs(g_net_data) do
        if entity_is_alive(idx) and entity_is_enemy(idx) and net_data ~= nil then
            
            -- 获取 3D 预测框颜色
            local rb, gb, bb, ab = ui.get(c_box)

            if net_data.lagcomp then
                local predicted_pos = net_data.predicted_origin
                local min = vec_add({ entity_get_prop(idx, 'm_vecMins') }, predicted_pos)
                local max = vec_add({ entity_get_prop(idx, 'm_vecMaxs') }, predicted_pos)
                local points = {
                    {min[1], min[2], min[3]}, {min[1], max[2], min[3]},
                    {max[1], max[2], min[3]}, {max[1], min[2], min[3]},
                    {min[1], min[2], max[3]}, {min[1], max[2], max[3]},
                    {max[1], max[2], max[3]}, {max[1], min[2], max[3]},
                }
                local edges = {
                    {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- bottom
                    {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- top
                    {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- sides
                }

                -- 绘制连线
                local origin = { entity_get_origin(idx) }
                local origin_w2s = { w2s(origin[1], origin[2], origin[3]) }
                local min_w2s = { w2s(min[1], min[2], min[3]) }
                if origin_w2s[1] ~= nil and min_w2s[1] ~= nil then
                    line(origin_w2s[1], origin_w2s[2], min_w2s[1], min_w2s[2], rb, gb, bb, ab)
                end

                -- 绘制预测框
                for i = 1, #edges do
                    local p1_raw = points[edges[i][1]]
                    local p2_raw = points[edges[i][2]]
                    local p1 = { w2s(p1_raw[1], p1_raw[2], p1_raw[3]) }
                    local p2 = { w2s(p2_raw[1], p2_raw[2], p2_raw[3]) }
                    if p1[1] ~= nil and p2[1] ~= nil then
                        line(p1[1], p1[2], p2[1], p2[2], rb, gb, bb, ab)
                    end
                end
            end

            -- 文字提示与动画
            local text_map = { [0] = '', [1] = 'LAG COMP BREAKER', [2] = 'SHIFTING TICKBASE' }
            local x1, y1, x2, y2, a = entity_get_bounding_box(idx)
            
            if x1 ~= nil and a > 0 then
                local palpha = 0
                if g_esp_data[idx] > 0 then
                    g_esp_data[idx] = g_esp_data[idx] - globals_frametime()*2
                    g_esp_data[idx] = math.max(0, g_esp_data[idx])
                    palpha = g_esp_data[idx]
                end

                local tb = net_data.tickbase or g_esp_data[idx] > 0
                local lc = net_data.lagcomp
                if not tb or lc then palpha = a end

                -- 根据状态应用颜色控件
                local tr, tg, tb_c, ta = 255, 255, 255, 255
                if tb then
                    tr, tg, tb_c, ta = ui.get(c_tb)
                elseif lc then
                    tr, tg, tb_c, ta = ui.get(c_lc)
                end

                local final_alpha = (ta / 255) * (palpha * 255)
                local name = entity_get_player_name(idx)
                local y_offset = name == '' and -8 or 0

                renderer_text(x1 + (x2-x1)/2, y1 - 18 + y_offset, tr, tg, tb_c, final_alpha, 'c', 0, text_map[tb and 2 or (lc and 1 or 0)])
            end
        end
    end
end

client.set_event_callback('paint', g_paint_handler)
client.set_event_callback('net_update_end', g_net_update)