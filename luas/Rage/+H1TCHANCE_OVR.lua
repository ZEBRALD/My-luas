local bit = require'bit'
-- 1. 引用 Gamesense 原生 Minimum Damage Override 控件
-- 注意：原生 MD Override 通常返回两个引用：一个是开关本身，一个是热键
local md_ref, md_key = ui.reference("RAGE", "Aimbot", "Minimum damage override")
local hc_ref = ui.reference('rage', 'aimbot', 'minimum hit chance')
ui.set_visible(hc_ref, false)

-- 2. UI 控件定义
local feature = {
    def_hc = ui.new_slider('rage', 'aimbot', 'Default hit chance', 0, 100, 50, true, '%'),
    hc_in_air = ui.new_checkbox('rage', 'aimbot', 'Hit chance in air'),
    hit_chance_in_air = ui.new_slider('rage', 'aimbot', '\ninairhc', 0, 100, 50, true, '%'),
    hit_chance_ovr = ui.new_slider('rage', 'aimbot', 'Hit chance override', 0, 100, 50, true, '%'),
    hc_ovr_key = ui.new_hotkey('rage', 'other', 'Hit chance override', false),
    
    -- 修改：与 Minimum Damage Override 联动开关
    link_md = ui.new_checkbox('rage', 'other', 'Link with MD'),

    label_col1 = ui.new_label('rage', 'other', 'Indicator Color 1'),
    col1 = ui.new_color_picker('rage', 'other', 'Indicator Color 1', 169, 0, 5, 255),
    
    label_col2 = ui.new_label('rage', 'other', 'Indicator Color 2'),
    col2 = ui.new_color_picker('rage', 'other', 'Indicator Color 2', 255, 255, 255, 255)
}

-- -----------------------------------------------------------------------------
-- 3. 辅助函数
-- -----------------------------------------------------------------------------
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
        r1 = r1 + rinc
        g1 = g1 + ginc
        b1 = b1 + binc
        a1 = a1 + ainc
    end
    return output
end

-- 获取当前功能是否应该开启的逻辑判断
local function is_feature_active()
    if ui.get(feature.link_md) then
        -- 开启联动时，监听原生 Min Damage Override 的热键状态
        -- 注意：md_key 返回的是热键是否按下/激活的状态
        return ui.get(md_key)
    else
        -- 否则恢复使用脚本自带的热键判断
        return ui.get(feature.hc_ovr_key)
    end
end

-- -----------------------------------------------------------------------------
-- 4. 事件回调
-- -----------------------------------------------------------------------------

client.set_event_callback('setup_command', function()
    local lp = entity.get_local_player(); if lp == nil or (not entity.is_alive(lp)) then return end
    local flags = entity.get_prop(lp, 'm_fFlags')
    local in_air = bit.band(flags, 1) ~= 1

    -- 应用默认命中率
    ui.set(hc_ref, ui.get(feature.def_hc))

    -- 空中命中率优先判断
    if in_air and ui.get(feature.hc_in_air) then
        ui.set(hc_ref, ui.get(feature.hit_chance_in_air))
    end
    
    -- 如果功能激活（无论是通过 MD 联动还是脚本热键），覆盖命中率
    if is_feature_active() then
        ui.set(hc_ref, ui.get(feature.hit_chance_ovr))
    end
end)

client.set_event_callback('paint', function()
    -- 如果功能激活，显示渐变指示器
    if is_feature_active() then
        local r1, g1, b1, a1 = ui.get(feature.col1)
        local r2, g2, b2, a2 = ui.get(feature.col2)
        
        renderer.indicator(255, 255, 255, 255, gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, "md? evil time~"))
    end
end)

client.set_event_callback('shutdown', function()
    ui.set_visible(hc_ref, true)
end)

-- 5. 界面交互
local ui_vis = function(self)
    ui.set_visible(feature.hit_chance_in_air, ui.get(self))
end
ui.set_callback(feature.hc_in_air, ui_vis); ui_vis(feature.hc_in_air)