-- #includes
local vector = require 'vector';
local ent = require 'gamesense/entity';
local csgo_weapons = require 'gamesense/csgo_weapons';

-- declares
local f = string.format;
local math_sin, math_cos, math_rad, math_abs, math_min, math_max, math_floor = math.sin, math.cos, math.rad, math.abs, math.min, math.max, math.floor;
local client_set_event_callback, client_camera_angles, client_current_threat, client_trace_bullet, client_random_int, client_random_float = client.set_event_callback, client.camera_angles, client.current_threat, client.trace_bullet, client.random_int, client.random_float;
local globals_curtime, globals_tickcount = globals.curtime, globals.tickcount;
local entity_get_prop, entity_get_local_player, entity_get_classname, entity_get_player_weapon, entity_get_origin, entity_is_dormant, entity_is_enemy = entity.get_prop, entity.get_local_player, entity.get_classname, entity.get_player_weapon, entity.get_origin, entity.is_dormant, entity.is_enemy;
local ui_reference, ui_set_callback, ui_get, ui_set_visible, ui_new_checkbox, ui_new_slider, ui_new_hotkey = ui.reference, ui.set_callback, ui.get, ui.set_visible, ui.new_checkbox, ui.new_slider, ui.new_hotkey;
local renderer_indicator = renderer.indicator;

-- 先定义main为空表，避免nil错误
local main = {}

-- 性能优化变量
local last_hitchance_check = 0
local hitchance_check_interval = 0.1 -- 每0.1秒检查一次命中率
local cached_hitchance_result = false
local cached_hitchance_time = 0

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

local function ux_set_callback(ref, callback, force_call)
    ui_set_callback(ref, callback);
    if force_call then
        callback(ref);
    end
end

-- 检查是否有有效的敌人存在
local function has_valid_enemies()
    local players = entity.get_players()
    if not players then return false end
    
    for _, player in ipairs(players) do
        if entity_is_enemy(player) and not entity_is_dormant(player) then
            local health = entity_get_prop(player, 'm_iHealth') or 0
            if health > 0 then
                return true
            end
        end
    end
    return false
end

-- 优化后的命中率检测函数 - 减少计算量
local function check_hitchance(lp, origin, target_pos, base_hitchance, health_factor)
    local current_time = globals_curtime()
    
    -- 使用缓存结果，避免频繁计算
    if current_time - cached_hitchance_time < hitchance_check_interval and last_hitchance_check > 0 then
        return cached_hitchance_result
    end
    
    last_hitchance_check = current_time
    
    local hit_count = 0
    local total_tests = 2  -- 减少测试次数以提高性能
    
    -- 根据血量调整测试次数
    local adjusted_tests = math_max(1, math_min(total_tests, math_floor(total_tests * health_factor)))
    
    -- 专注于头、胸、胃三个主要部位
    local hitbox_offsets = {
        {0, 0, 10},    -- 头部
        {0, 0, 5},     -- 胸部  
        {0, 0, 0},     -- 胃部
    }
    
    for i = 1, adjusted_tests do
        -- 为每个部位进行测试
        for _, offset in ipairs(hitbox_offsets) do
            -- 生成更精确的随机偏移
            local spread_x = client_random_float(-1.5, 1.5)
            local spread_y = client_random_float(-1.5, 1.5)
            local spread_z = client_random_float(-0.8, 0.8)
            
            local target_x = target_pos.x + offset[1] + spread_x
            local target_y = target_pos.y + offset[2] + spread_y
            local target_z = target_pos.z + offset[3] + spread_z
            
            local _, damage = client_trace_bullet(lp, origin.x, origin.y, origin.z, target_x, target_y, target_z)
            if damage and damage > 0 then
                hit_count = hit_count + 1
                break  -- 只要命中一个部位就计数
            end
        end
        
        -- 提前终止检查：如果已经达到足够的命中数
        if hit_count >= adjusted_tests * (base_hitchance / 100) * 0.8 then
            break
        end
    end
    
    local actual_hitchance = (hit_count / adjusted_tests) * 100
    cached_hitchance_result = actual_hitchance >= base_hitchance
    cached_hitchance_time = current_time
    
    return cached_hitchance_result
end

-- namespace
local reference = {};

-- 初始化main表的属性
main.tab = 'RAGE'
main.container = 'Aimbot'
main.tick = -1
main.height = 18
main.last_velocity_z = 0

-- main code
reference.minimum_damage = ui_reference('RAGE', 'Aimbot', 'Minimum damage');

function main.create_data(flags, velocity)
    return {
        flags = flags or 0,
        velocity = velocity or vector()
    }
end

-- 初始化prediction_data和setup_data
main.prediction_data = main.create_data(0, vector())
main.setup_data = main.create_data(0, vector())

main.master = ui_new_checkbox(main.tab, main.container, 'Enable air-autostop');
main.keybind = ui_new_hotkey(main.tab, main.container, 'Air-autostop key', false);
main.on_peak_of_height = ui_new_checkbox(main.tab, main.container, 'Only on peak of height');
main.autoscope = ui_new_checkbox(main.tab, main.container, 'Auto-scope');
main.distance = ui_new_slider(main.tab, main.container, 'Distance', 0, 1000, 350, true, 'u', 1, {[0] = '∞'});
main.delay = ui_new_slider(main.tab, main.container, 'Delay', 0, 16, 0, true, 't', 1, {[0] = 'Off'});
main.minimum_damage = ui_new_slider(main.tab, main.container, 'Minimum damage', -1, 130, -1, true, 'hp', 1, (function()
    local hint = {
        [ -1 ] = 'Inherited'
    };
    for i = 1, 30 do
        hint[ 100 + i ] = f('HP + %d', i)
    end
    return hint
end)());
-- 添加空速限制滑块
main.max_airspeed = ui_new_slider(main.tab, main.container, 'Max airspeed', 0, 500, 200, true, 'u/s', 1, {[0] = 'No limit'});
-- 添加休眠检测选项
main.disable_on_dormant = ui_new_checkbox(main.tab, main.container, 'Disable on dormant enemies');
-- 添加命中率相关选项
main.enable_hitchance = ui_new_checkbox(main.tab, main.container, 'Enable dynamic hitchance');
main.base_hitchance = ui_new_slider(main.tab, main.container, 'Base hitchance', 0, 100, 50, true, '%', 1);
main.hitchance_health_threshold = ui_new_slider(main.tab, main.container, 'Hitchance health threshold', 0, 100, 30, true, 'hp', 1, {[0] = 'Always check'});

-- 更新UI回调函数
ux_set_callback(main.master, function(self)
    local val = ui_get(self);
    ui_set_visible(main.keybind, val);
    ui_set_visible(main.on_peak_of_height, val);
    ui_set_visible(main.autoscope, val);
    ui_set_visible(main.distance, val);
    ui_set_visible(main.delay, val);
    ui_set_visible(main.minimum_damage, val);
    ui_set_visible(main.max_airspeed, val);
    ui_set_visible(main.disable_on_dormant, val);
    ui_set_visible(main.enable_hitchance, val);
    ui_set_visible(main.base_hitchance, val);
    ui_set_visible(main.hitchance_health_threshold, val);
end, true);

main.cl_sidespeed = cvar.cl_sidespeed;

function main.get_minimum_damage()
    local val = ui_get(main.minimum_damage);
    if val == -1 then
        return ui_get(reference.minimum_damage)
    end
    return val
end

function main.get_minimum_hitchance()
    return ui_get(main.base_hitchance)  -- 使用自定义的基础命中率
end

function main.autostop(cmd, minimum)
    local lp = entity_get_local_player();
    if lp == nil then
        return
    end

    local velocity = main.prediction_data.velocity;
    local speed = velocity:length2d();

    if minimum ~= nil and speed < minimum then
        return
    end

    local direction = vector(velocity:angles());
    local real_view = vector(client_camera_angles());
    direction.y = real_view.y - direction.y;
    local forward = vector(angle_to_forward(direction.x, direction.y));

    local negative_side_move = -main.cl_sidespeed:get_float();
    local negative_direction = negative_side_move * forward;

    cmd.in_speed = 1;
    cmd.forwardmove = negative_direction.x;
    cmd.sidemove = negative_direction.y;
end

function main.predict_command(cmd)
    local lp = entity_get_local_player();
    if lp == nil then
        return
    end

    local flags = entity_get_prop(lp, 'm_fFlags');
    local velocity = vector(entity_get_prop(lp, 'm_vecVelocity'));
    main.prediction_data = main.create_data(flags, velocity);
end

function main.setup_command(cmd)
    -- 检查主开关
    if not ui_get(main.master) or not ui_get(main.keybind) then
        return
    end

    -- 首先检查是否有有效的敌人存在
    if not has_valid_enemies() then
        return
    end

    local lp = entity_get_local_player();
    local threat = client_current_threat();

    -- 确保有有效的威胁目标
    if lp == nil or threat == nil then
        return
    end

    -- 检查威胁目标是否有效（活着且是敌人）
    local threat_health = entity_get_prop(threat, 'm_iHealth') or 0
    if threat_health <= 0 or not entity_is_enemy(threat) then
        return
    end

    -- 修复休眠检测
    if ui_get(main.disable_on_dormant) and entity_is_dormant(threat) then
        return
    end

    local wpn = entity_get_player_weapon(lp);
    if wpn == nil then
        return
    end

    local wpn_class = entity_get_classname(wpn);
    if wpn_class ~= 'CWeaponSSG08' then
        return
    end

    if not entity_is_ready(lp) or not entity_can_fire(wpn) then
        return
    end

    local origin = vector(entity_get_origin(lp));
    local pos = vector(entity_get_origin(threat));
    local distance = pos:dist(origin);
    local max_distance = ui_get(main.distance);

    if max_distance ~= 0 and distance > max_distance then
        return
    end

    -- 提前进行命中率检测（提高优先级）
    if ui_get(main.enable_hitchance) then
        local health = entity_get_prop(threat, 'm_iHealth') or 100
        local health_threshold = ui_get(main.hitchance_health_threshold)
        
        -- 只有在血量高于阈值时才检查命中率
        if health_threshold == 0 or health > health_threshold then
            local base_hitchance = main.get_minimum_hitchance()
            -- 根据血量调整命中率要求
            local health_factor = math_max(0.4, health / 100)  -- 提高最低要求到40%
            local adjusted_hitchance = base_hitchance * health_factor
            
            -- 提前检查命中率，使用优化后的函数
            if not check_hitchance(lp, origin, pos, adjusted_hitchance, health_factor) then
                return
            end
        end
    end

    local velocity = vector(entity_get_prop(lp, 'm_vecVelocity'));
    local flags = entity_get_prop(lp, 'm_fFlags');
    
    -- 检查是否在空中
    local in_air = flags and bit.band(flags, 1) == 0
    if not in_air then
        return
    end

    -- 空速检测
    local current_speed = velocity:length2d()
    local max_airspeed = ui_get(main.max_airspeed)
    if max_airspeed > 0 and current_speed > max_airspeed then
        return
    end

    local tick = globals_tickcount();
    local delay = ui_get(main.delay);
    local is_delaying = delay ~= 0;
    local is_peaking_enabled = ui_get(main.on_peak_of_height);
    local is_scoped = entity_get_prop(lp, 'm_bIsScoped') ~= 0;
    
    -- 修复逻辑判断
    local is_force = not is_delaying or (main.tick <= tick);
    
    -- 修复峰值检测逻辑
    local is_at_peak = true
    if is_peaking_enabled then
        is_at_peak = velocity.z <= 5 and velocity.z >= -5
    end

    if not is_force then
        if not is_at_peak then
            return
        end
        if is_delaying then
            main.tick = tick + delay;
        end
    end

    -- 获取敌人血量
    local health = entity_get_prop(threat, 'm_iHealth') or 100;
    
    -- 根据敌人血量动态调整伤害要求
    local max_damage = main.get_minimum_damage();
    
    if max_damage > 100 then
        max_damage = health + (max_damage - 100);
    else
        local health_factor = health / 100
        max_damage = max_damage * health_factor
    end

    -- 检测头、胸、胃三个主要部位
    local max_damage_found = 0
    local hit_positions = {
        {0, 0, 10},    -- 头部
        {0, 0, 5},     -- 胸部
        {0, 0, 0},     -- 胃部
    }

    -- 检查主要部位的伤害
    for _, offset in ipairs(hit_positions) do
        local target_x = pos.x + offset[1]
        local target_y = pos.y + offset[2]
        local target_z = pos.z + offset[3]
        
        local _, damage = client_trace_bullet(lp, origin.x, origin.y, origin.z, target_x, target_y, target_z)
        if damage and damage > max_damage_found then
            max_damage_found = damage
        end
    end

    -- 伤害检查
    if max_damage_found < max_damage - 15 then
        return
    end

    local data = csgo_weapons(wpn);
    local max_speed = is_scoped and data.max_player_speed_alt or data.max_player_speed;
    max_speed = max_speed * 0.34;

    if ui_get(main.autoscope) and not is_scoped then
        cmd.in_attack2 = 1;
    end

    main.autostop(cmd, max_speed);
end

-- 确保所有函数都定义后再注册事件回调
client_set_event_callback('predict_command', function(cmd)
    main.predict_command(cmd);
end);

client_set_event_callback('setup_command', function(cmd)
    main.setup_command(cmd);
end);

-- 优化后的paint事件处理 - 简化指示器显示逻辑
client_set_event_callback('paint', function()
    if not ui_get(main.master) then return end
    
    local lp = entity_get_local_player();
    if lp then
        -- 如果按键被按下，显示指示器（只检查按键状态）
        if ui_get(main.keybind) then
            renderer_indicator(255, 255, 255, 255, "Quick")
        end
    end
end);

-- shutdown事件
client_set_event_callback('shutdown', function()
    -- 清理代码
end);