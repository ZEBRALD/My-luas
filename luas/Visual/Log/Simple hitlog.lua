local renderer_text = renderer.text
local renderer_rectangle = renderer.rectangle
local renderer_measure_text = renderer.measure_text
local client_screen_size = client.screen_size
local globals_curtime = globals.curtime
local table_insert = table.insert
local table_remove = table.remove

-- --- UI 菜单设置 (VISUALS -> Effects) ---
local master_switch = ui.new_checkbox("VISUALS", "Effects", "Enable Simple Hitlog")

-- 颜色及其文字说明
local label_name = ui.new_label("VISUALS", "Effects", "Target name color")
local menu_name_color = ui.new_color_picker("VISUALS", "Effects", "Target name color", 255, 255, 255, 255)

local label_normal = ui.new_label("VISUALS", "Effects", "Normal damage color")
-- 默认颜色 84D964FF (132, 217, 100)
local menu_normal_color = ui.new_color_picker("VISUALS", "Effects", "Normal damage color", 132, 217, 100, 255)

local label_hs = ui.new_label("VISUALS", "Effects", "Headshot damage color")
local menu_hs_color = ui.new_color_picker("VISUALS", "Effects", "Headshot damage color", 255, 255, 0, 255)

-- 调节控件
local menu_offset_y = ui.new_slider("VISUALS", "Effects", "Hitlog vertical offset", -500, 500, -100)
local menu_spacing_x = ui.new_slider("VISUALS", "Effects", "Hitlog spacing", 0, 50, 2)
local menu_display_time = ui.new_slider("VISUALS", "Effects", "Hitlog display time", 10, 100, 40, true, "s", 0.1)
local menu_disable_fade = ui.new_checkbox("VISUALS", "Effects", "Disable fade animation")
local menu_fade_time = ui.new_slider("VISUALS", "Effects", "Hitlog fade time", 1, 50, 5, true, "s", 0.1)

local MAX_LOGS = 8
local hit_logs = {}

-- 菜单联动逻辑
client.set_event_callback("paint_ui", function()
    local active = ui.get(master_switch)
    local fade_disabled = ui.get(menu_disable_fade)
    
    local items = {
        label_name, menu_name_color, label_normal, menu_normal_color, 
        label_hs, menu_hs_color, menu_offset_y, menu_spacing_x, 
        menu_display_time, menu_disable_fade
    }
    
    for i=1, #items do
        ui.set_visible(items[i], active)
    end
    
    -- 动画滑块显隐控制
    ui.set_visible(menu_fade_time, active and not fade_disabled)
end)

-- --- 核心渲染逻辑 ---
local function on_paint()
    if not ui.get(master_switch) then return end

    local screen_w, screen_h = client_screen_size()
    local offset_y = ui.get(menu_offset_y)
    local spacing_x = ui.get(menu_spacing_x)
    local display_duration = ui.get(menu_display_time) * 0.1
    local disable_fade = ui.get(menu_disable_fade)
    local fade_val = ui.get(menu_fade_time) * 0.1
    
    local cx, cy = screen_w / 2, screen_h / 2 + offset_y
    local cur_time = globals_curtime()

    for i = #hit_logs, 1, -1 do
        local log = hit_logs[i]
        local time_diff = cur_time - log.time

        -- 使用滑块控制的显示时长
        if time_diff > display_duration then
            table_remove(hit_logs, i)
            goto continue
        end

        -- 透明度处理
        local alpha = 255
        if not disable_fade then
            if time_diff > (display_duration - fade_val) then
                alpha = 255 * (display_duration - time_diff) / fade_val
            elseif time_diff < 0.1 then
                alpha = 255 * (time_diff / 0.1)
            end
        end

        if alpha <= 0 then goto continue end

        -- 1. 颜色与内容逻辑
        local nr, ng, nb, na = ui.get(menu_name_color)
        local dnr, dng, dnb, dna = ui.get(menu_normal_color)
        local hsr, hsg, hsb, hsa = ui.get(menu_hs_color)
        
        local dr, dg, db = dnr, dng, dnb 
        local left_content = ""
        local left_font_flag = "rd" -- 右对齐 + 阴影

        if log.hit then
            left_content = tostring(log.damage)
            if log.headshot then
                dr, dg, db = hsr, hsg, hsb
                left_font_flag = "rdb" -- 爆头加粗 + 阴影
            end
        else
            -- 空枪处理 (淡红色)
            left_content = log.reason
            dr, dg, db = 255, 105, 105 
            left_font_flag = "rd"
        end

        local line_y = cy + (i * 15)
        local name_str = log.name

        -- 2. 绘制左侧 (伤害或原因)
        renderer_text(cx - spacing_x, line_y, dr, dg, db, alpha, left_font_flag, 0, left_content)

        -- 3. 绘制右侧 (名字, 粗体 + 阴影 "bd")
        renderer_text(cx + spacing_x, line_y, nr, ng, nb, alpha, "bd", 0, name_str)

        -- 4. 击杀删除线
        if log.killed then
            local nw, nh = renderer_measure_text("bd", name_str)
            -- 颜色固定为淡红色
            renderer_rectangle(cx + spacing_x, line_y + 7, nw, 1, 255, 105, 105, alpha * 0.9)
        end

        ::continue::
    end
end

-- --- 事件回调 ---
client.set_event_callback("aim_hit", function(e)
    if not ui.get(master_switch) then return end
    local target_name = entity.get_player_name(e.target)
    local health = entity.get_prop(e.target, "m_iHealth")
    table_insert(hit_logs, 1, {
        name = target_name, damage = e.damage, hit = true, headshot = e.hitgroup == 1,
        killed = (health <= 0), time = globals_curtime()
    })
    if #hit_logs > MAX_LOGS then table_remove(hit_logs) end
end)

client.set_event_callback("aim_miss", function(e)
    if not ui.get(master_switch) then return end
    local target_name = entity.get_player_name(e.target)
    local reason = e.reason == "resolver" and "?" or e.reason
    table_insert(hit_logs, 1, {
        name = target_name, damage = 0, hit = false, headshot = false,
        killed = false, reason = reason, time = globals_curtime()
    })
    if #hit_logs > MAX_LOGS then table_remove(hit_logs) end
end)

local function clear_logs() hit_logs = {} end
client.set_event_callback("paint", on_paint)
client.set_event_callback("client_disconnect", clear_logs)
client.set_event_callback("game_newmap", clear_logs)