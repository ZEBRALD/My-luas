-- #includes
local vector = require 'vector';
local ent = require 'gamesense/entity';
local csgo_weapons = require 'gamesense/csgo_weapons';

-- declares
local f = string.format;
local math_sin, math_cos, math_rad, math_abs = math.sin, math.cos, math.rad, math.abs;
local client_set_event_callback, client_camera_angles, client_current_threat, client_trace_bullet = client.set_event_callback, client.camera_angles, client.current_threat, client.trace_bullet;
local globals_curtime, globals_realtime = globals.curtime, globals.realtime;
local entity_get_prop, entity_get_local_player, entity_get_player_weapon, entity_get_origin = entity.get_prop, entity.get_local_player, entity.get_player_weapon, entity.get_origin;
local ui_reference, ui_set_callback, ui_get, ui_set, ui_set_visible, ui_new_checkbox, ui_new_slider, ui_new_hotkey, ui_new_label, ui_new_color_picker = ui.reference, ui.set_callback, ui.get, ui.set, ui.set_visible, ui.new_checkbox, ui.new_slider, ui.new_hotkey, ui.new_label, ui.new_color_picker;
local renderer_indicator = renderer.indicator;

-- <headers>
local function angle_to_forward(angle_x, angle_y)
    local sy = math_sin(math_rad(angle_y));
    local cy = math_cos(math_rad(angle_y));
    local sp = math_sin(math_rad(angle_x));
    local cp = math_cos(math_rad(angle_x));
    return cp * cy, cp * sy, -sp
end

local function entity_is_ready(ent)
    return globals_curtime() >= entity_get_prop(ent, 'm_flNextAttack')
end

local function entity_can_fire(ent)
    return globals_curtime() >= entity_get_prop(ent, 'm_flNextPrimaryAttack')
end

local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
    local output = ''
    local len = #text - 1
    if len <= 0 then return ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text) end
    local rinc = (r2 - r1) / len
    local ginc = (g2 - g1) / len
    local binc = (b2 - b1) / len
    local ainc = (a2 - a1) / len
    for i=1, len+1 do
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
        r1 = r1 + rinc; g1 = g1 + ginc; b1 = b1 + binc; a1 = a1 + ainc
    end
    return output
end

local function ux_set_callback(ref, callback, force_call)
    ui_set_callback(ref, callback);
    if force_call then callback(ref) end
end

-- -----------------------------------------------------------------------------
-- 1. 原生引用 (Rage -> Aimbot)
-- -----------------------------------------------------------------------------
local ref_dt = ui_reference("RAGE", "Aimbot", "Double tap")
local ref_min_dmg = ui_reference("RAGE", "Aimbot", "Minimum damage")
local ref_min_dmg_ovr, ref_min_dmg_ovr_key, ref_min_dmg_ovr_val = ui_reference("RAGE", "Aimbot", "Minimum damage override")
local ref_air_strafe = ui_reference("Misc", "Movement", "Air strafe")

-- -----------------------------------------------------------------------------
-- 2. 菜单设置 (已移除调试滑块)
-- -----------------------------------------------------------------------------
local main = {
    tab = 'RAGE',
    container = 'Aimbot',
    tick = -1,
    height = 18,
    prev_strafe = nil,
    prediction_data = { velocity = vector() },
    
    -- Teleport 状态机
    tp_state = "IDLE", 
    tp_start_time = 0,
    tp_delay_fixed = 0.5 -- 你的测试最佳值：0.5秒
}

main.master = ui_new_checkbox (main.tab, main.container, 'Enable air-autostop')
main.master_key = ui_new_hotkey(main.tab, main.container, 'Enable air-autostop', true) 
main.teleport_on_stop = ui_new_checkbox(main.tab, main.container, 'Teleport on Autostop')

main.on_peak_of_height = ui_new_checkbox (main.tab, main.container, 'Only on peak of height')
main.autoscope = ui_new_checkbox (main.tab, main.container, 'Auto-scope')
main.distance = ui_new_slider(main.tab, main.container, 'Distance', 0, 1000, 350, true, 'u', 1, {[0] = '∞'})
main.delay = ui_new_slider(main.tab, main.container, 'Delay', 0, 16, 0, true, 't', 1, {[0] = 'Off'})
main.minimum_damage = ui_new_slider(main.tab, main.container, 'Minimum damage', -1, 130, -1, true, 'hp', 1, (function()
    local hint = { [ -1 ] = 'Inherited' }
    for i = 1, 30 do hint[ 100 + i ] = f('HP + %d', i) end
    return hint
end)())

main.label_col1 = ui_new_label(main.tab, main.container, 'Indicator Color 1')
main.col1 = ui_new_color_picker(main.tab, main.container, 'Indicator Color 1', 169, 0, 5, 255)
main.label_col2 = ui_new_label(main.tab, main.container, 'Indicator Color 2')
main.col2 = ui_new_color_picker(main.tab, main.container, 'Indicator Color 2', 255, 255, 255, 255)

ux_set_callback(main.master, function(self)
    local val = ui_get(self)
    local controls = {main.on_peak_of_height, main.autoscope, main.distance, main.delay, main.minimum_damage, main.label_col1, main.col1, main.label_col2, main.col2, main.teleport_on_stop}
    for _, c in ipairs(controls) do ui_set_visible(c, val) end
end, true)

main.cl_sidespeed = cvar.cl_sidespeed

-- -----------------------------------------------------------------------------
-- 3. 核心逻辑
-- -----------------------------------------------------------------------------
function main:get_minimum_damage()
    local val = ui_get(main.minimum_damage)
    if val == -1 then
        if ui_get(ref_min_dmg_ovr) and ui_get(ref_min_dmg_ovr_key) then
            return ui_get(ref_min_dmg_ovr_val)
        end
        return ui_get(ref_min_dmg)
    end
    return val
end

function main:restore()
    if self.prev_strafe == nil then return end
    ui_set(ref_air_strafe, self.prev_strafe)
    self.prev_strafe = nil
end

client_set_event_callback('setup_command', function(cmd)
    local lp = entity_get_local_player()
    if lp == nil then return main:restore() end

    local cur_time = globals_realtime()

    -- [Teleport 状态机管理]
    if main.tp_state == "RECHARGING" then
        if cur_time - main.tp_start_time >= main.tp_delay_fixed then
            ui_set(ref_dt, true) -- 冷却 0.5s 结束，重新开启 DT 进行充电
            main.tp_state = "IDLE"
        else
            ui_set(ref_dt, false) -- 冷却中强制保持关闭，防止空中卡顿
        end
    end

    if not ui_get(main.master) or not ui_get(main.master_key) then
        return main:restore()
    end

    local threat = client_current_threat()
    if threat == nil then return main:restore() end

    local wpn = entity_get_player_weapon(lp)
    if wpn == nil or not entity_is_ready(lp) or not entity_can_fire(wpn) then
        return main:restore()
    end

    local origin = vector(entity_get_origin(lp))
    local pos = vector(entity_get_origin(threat))
    local distance = pos:dist(origin)
    if ui_get(main.distance) ~= 0 and distance > ui_get(main.distance) then
        return main:restore()
    end

    local velocity = vector(entity_get_prop(lp, 'm_vecVelocity'))
    local animstate = ent(lp):get_anim_state()
    if animstate == nil or animstate.on_ground then return main:restore() end

    -- 判定与 Tick 逻辑
    local tick = cmd.command_number
    local delay = ui_get(main.delay)
    local is_delaying = delay ~= 0
    local is_peaking = ui_get(main.on_peak_of_height)
    local is_scoped = entity_get_prop(lp, 'm_bIsScoped') ~= 0
    local is_force = is_delaying and (main.tick > tick) or true
    local is_peak = is_peaking and (math_abs(velocity.z) < main.height) or true
    local is_downgoing = origin.z < animstate.last_origin_z

    if not is_force then
        if is_downgoing or not is_peak then return main:restore() end
        if is_delaying then main.tick = tick + delay end
    end

    -- 伤害检测
    local max_damage = main:get_minimum_damage()
    local _, damage = client_trace_bullet(lp, origin.x, origin.y, origin.z, pos.x, pos.y, pos.z)
    local health = entity_get_prop(threat, 'm_iHealth')
    if max_damage > 100 then max_damage = health + (max_damage - 100) end

    -- 触发空中急停
    if damage >= max_damage then
        local data = csgo_weapons(wpn)
        local max_speed = (is_scoped and data.max_player_speed_alt or data.max_player_speed) * 0.34
        
        local speed = velocity:length2d()
        if speed >= max_speed then
            local direction = vector(velocity:angles())
            local real_view = vector(client_camera_angles())
            direction.y = real_view.y - direction.y
            local forward = vector(angle_to_forward(direction.x, direction.y))
            local negative_side_move = -main.cl_sidespeed:get_float()
            local negative_direction = negative_side_move * forward

            if main.prev_strafe == nil then main.prev_strafe = ui_get(ref_air_strafe) end
            ui_set(ref_air_strafe, false)
            cmd.in_speed = 1
            cmd.forwardmove = negative_direction.x
            cmd.sidemove = negative_direction.y

            -- [满足条件直接 Teleport]
            if ui_get(main.teleport_on_stop) and main.tp_state == "IDLE" then
                if ui_get(ref_dt) then
                    ui_set(ref_dt, false) -- 瞬间切断 DT 产生位移
                    main.tp_state = "RECHARGING"
                    main.tp_start_time = cur_time
                end
            end
        end

        if ui_get(main.autoscope) and not is_scoped then cmd.in_attack2 = 1 end
    else
        return main:restore()
    end
end)

client_set_event_callback('predict_command', function(cmd)
    local lp = entity_get_local_player()
    if lp == nil then return end
    main.prediction_data.velocity = vector(entity_get_prop(lp, 'm_vecVelocity'))
end)

client_set_event_callback('paint', function()
    if ui_get(main.master) and ui_get(main.master_key) then
        local r1, g1, b1, a1 = ui_get(main.col1)
        local r2, g2, b2, a2 = ui_get(main.col2)
        
        local text = "Quick"
        if ui_get(main.teleport_on_stop) then 
            if main.tp_state == "RECHARGING" then
                text = "X"
            else
                text = "JUMP + X" 
            end
        end
        
        renderer_indicator(255, 255, 255, 255, gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text))
    end
end)