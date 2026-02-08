slot0 = client.screen_size
slot1 = entity.get_local_player
slot2 = entity.get_prop
slot3 = entity.is_alive
slot4 = globals.curtime
slot5 = math.abs
slot6 = math.floor
slot7 = renderer.indicator
slot8 = renderer.rectangle
slot9 = renderer.text
slot10 = string.format
slot11 = ui.get
slot13 = ui.reference
-- 获取警告图标
slot16 = require("gamesense/images").get_panorama_image("icons/ui/warning.svg")
slot18 = 0

-- --- 新增：动画与颜色控件变量 ---
local fade_alpha = 0
menu_item = ui.new_combobox("VISUALS", "Other ESP", "Slowdown indicator", "Off", "Bar", "Indicator")
color1_label = ui.new_label("VISUALS", "Other ESP", "Slowdown color 1")
color1 = ui.new_color_picker("VISUALS", "Other ESP", "Slowdown color 1", 0, 255, 0, 255)
color2_label = ui.new_label("VISUALS", "Other ESP", "Slowdown color 2")
color2 = ui.new_color_picker("VISUALS", "Other ESP", "Slowdown color 2", 255, 0, 0, 255)

-- 颜色插值逻辑：根据 modifier 在 color1 和 color2 之间过渡
function slot19(modifier)
    local r1, g1, b1 = ui.get(color1)
    local r2, g2, b2 = ui.get(color2)
    
    -- 当 modifier 为 1 (无减速) 时趋向颜色1，为 0 时趋向颜色2
    local r = r1 + (r2 - r1) * (1 - modifier)
    local g = g1 + (g2 - g1) * (1 - modifier)
    local b = b1 + (b2 - b1) * (1 - modifier)
    
    return r, g, b
end

-- 插值函数
function slot20(slot0, slot1, slot2, slot3, slot4, slot5)
    slot3 = slot3 or 0
    local slot6 = 0
    if slot5 ~= false then
        slot6 = math.min(1, math.max(0, (slot0 - slot3) / ((slot4 or 1) - slot3)))
    end

    return slot1 + (slot2 - slot1) * slot6
end

-- 画框函数
function slot21(slot0, slot1, slot2, slot3, slot4, slot5, slot6, slot7, slot8)
    slot8 = slot8 or 1
    slot8_rect = renderer.rectangle
    slot8_rect(slot0, slot1, slot2, slot8, slot4, slot5, slot6, slot7)
    slot8_rect(slot0, slot1 + slot3 - slot8, slot2, slot8, slot4, slot5, slot6, slot7)
    slot8_rect(slot0, slot1 + slot8, slot8, slot3 - slot8 * 2, slot4, slot5, slot6, slot7)
    slot8_rect(slot0 + slot2 - slot8, slot1 + slot8, slot8, slot3 - slot8 * 2, slot4, slot5, slot6, slot7)
end

-- 绘制 Bar 的主函数
function slot22(slot0, slot1, slot2, slot3, slot4, slot5)
    slot18 = slot18 + (1 - slot0) * 0.7 + 0.3
    local slot6 = slot5_abs(slot18 * 0.01 % 2 - 1) * 255
    local slot8, slot9 = slot0_screen()
    local slot12, slot13 = slot16:measure(nil, 35)

    local slot10 = slot8 / 2 - 95 - 3
    local slot11 = slot9 * 0.35 - 4

    slot16:draw(slot10, slot11, slot12 + 6, slot13 + 6, 16, 16, 16, 255 * slot4)

    if slot4 > 0.7 then
        slot8_rect(slot10 + 13, slot11 + 11, 8, 20, 16, 16, 16, 255 * slot4)
    end

    slot16:draw(slot10, slot11, nil, 35, slot1, slot2, slot3, slot6 * slot4)
    slot9_text(slot10 + slot12 + 8, slot11 + 3, 255, 255, 255, 255 * slot4, "b", 0, slot10_fmt("%s %d%%", slot5, slot0 * 100))

    local slot14 = slot10 + slot12 + 8
    local slot15 = slot11 + 3 + 17
    local slot16_w = 100 -- 宽度预设
    local slot17 = 12

    slot21(slot14, slot15, slot16_w, slot17, 0, 0, 0, 255 * slot4, 1)
    slot8_rect(slot14 + 1, slot15 + 1, slot16_w - 2, slot17 - 2, 16, 16, 16, 180 * slot4)
    slot8_rect(slot14 + 1, slot15 + 1, slot6_floor((slot16_w - 2) * slot0), slot17 - 2, slot1, slot2, slot3, 180 * slot4)
end

-- 绘图逻辑
function slot23()
    local local_player = slot1()
    if not local_player or not slot3(local_player) then
        fade_alpha = 0
        return
    end

    local modifier = slot2(local_player, "m_flVelocityModifier") or 1
    
    -- 动画目标值：有减速时为1，无减速时为0
    local target_alpha = (modifier < 1) and 1 or 0
    local frame_time = globals.frametime()
    
    if fade_alpha < target_alpha then
        fade_alpha = math.min(1, fade_alpha + frame_time * 5)
    elseif fade_alpha > target_alpha then
        fade_alpha = math.max(0, fade_alpha - frame_time * 3)
    end

    if fade_alpha > 0 then
        local r, g, b = slot19(modifier)
        local style = slot11(menu_item)

        if style == "Bar" then
            slot22(modifier, r, g, b, fade_alpha, "Slowed down")
        elseif style == "Indicator" then
            slot7(r, g, b, 255 * fade_alpha, "SLOW")
        end
    end
end

-- 处理 UI 可见性
local function handle_ui()
    local active = slot11(menu_item) ~= "Off"
    ui.set_visible(color1_label, active)
    ui.set_visible(color1, active)
    ui.set_visible(color2_label, active)
    ui.set_visible(color2, active)
end

-- 菜单回调
ui.set_callback(menu_item, function ()
    handle_ui()
    local status = slot11(menu_item)
    if status ~= "Off" then
        client.set_event_callback("paint", slot23)
    else
        client.unset_event_callback("paint", slot23)
        fade_alpha = 0
    end
end)

-- 初始化 UI 状态
handle_ui()

-- 别名映射
slot0_screen = slot0
slot5_abs = slot5
slot9_text = slot9
slot8_rect = slot8
slot10_fmt = slot10
slot6_floor = slot6