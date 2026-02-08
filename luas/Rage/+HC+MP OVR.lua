local bit = require 'bit'

-- 1. 引用 Gamesense 原生控件 (修复多返回值引用)
local md_ref = ui.reference("RAGE", "Aimbot", "Minimum damage")
-- dmg_ovr_key 是热键状态(idx 2), dmg_ovr_val 是数值滑块(idx 3)
local _, dmg_ovr_key, dmg_ovr_val = ui.reference("RAGE", "Aimbot", "Minimum damage override")

local hc_ref = ui.reference('RAGE', 'Aimbot', 'Minimum hit chance')
local mp_ref = ui.reference('RAGE', 'Aimbot', 'Multi-point scale')

-- 2. UI 控件定义
local feature = {
    -- 核心控制
    enabled_funcs = ui.new_multiselect('RAGE', 'Other', 'Enable Overrides', 'Hit Chance', 'Multi-point', 'Damage Indicator'),
    link_with_md = ui.new_multiselect('RAGE', 'Other', 'Link with MD', 'Hit Chance', 'Multi-point', 'Damage Indicator'),
    
    -- 指示器开关 (HC 和 MP 专用)
    show_hc_indicator = ui.new_checkbox('RAGE', 'Other', 'Show Hit Chance Indicator'),
    show_mp_indicator = ui.new_checkbox('RAGE', 'Other', 'Show Multi-point Indicator'),

    -- 热键控件 (HC 和 MP 专用)
    hc_ovr_key = ui.new_hotkey('RAGE', 'Other', 'Hit Chance Override Key', false),
    mp_ovr_key = ui.new_hotkey('RAGE', 'Other', 'Multi-point Override Key', false),

    -- Aimbot 栏目数值调节 (HC 和 MP)
    def_hc = ui.new_slider('RAGE', 'Aimbot', 'Default hit chance', 0, 100, 50, true, '%'),
    hc_in_air = ui.new_checkbox('RAGE', 'Aimbot', 'Hit chance in air'),
    hit_chance_in_air = ui.new_slider('RAGE', 'Aimbot', '\ninairhc', 0, 100, 50, true, '%'),
    hit_chance_ovr = ui.new_slider('RAGE', 'Aimbot', 'Hit chance override', 0, 100, 50, true, '%'),

    def_mp = ui.new_slider('RAGE', 'Aimbot', 'Default multi-point', 0, 100, 50, true, '%'),
    mp_ovr = ui.new_slider('RAGE', 'Aimbot', 'Multi-point override', 0, 100, 50, true, '%'),

    -- 颜色
    label_col = ui.new_label('RAGE', 'Other', 'Indicator Gradient Colors'),
    col1 = ui.new_color_picker('RAGE', 'Other', 'Indicator Color 1', 169, 0, 5, 255),
    col2 = ui.new_color_picker('RAGE', 'Other', 'Indicator Color 2', 255, 255, 255, 255)
}

-- -----------------------------------------------------------------------------
-- 3. 辅助函数
-- -----------------------------------------------------------------------------
local function contains(control, val)
    local tbl = ui.get(control)
    for i=1, #tbl do if tbl[i] == val then return true end end
    return false
end

local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
    local output = ''
    local len = #text - 1
    if len <= 0 then return ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text) end
    local rinc, ginc, binc, ainc = (r2-r1)/len, (g2-g1)/len, (b2-b1)/len, (a2-a1)/len
    for i=1, len+1 do
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
        r1, g1, b1, a1 = r1+rinc, g1+ginc, b1+binc, a1+ainc
    end
    return output
end

-- -----------------------------------------------------------------------------
-- 4. 界面显隐
-- -----------------------------------------------------------------------------
local function handle_menu()
    local enabled = ui.get(feature.enabled_funcs)
    local hc_on = contains(feature.enabled_funcs, 'Hit Chance')
    local mp_on = contains(feature.enabled_funcs, 'Multi-point')
    local dmg_on = contains(feature.enabled_funcs, 'Damage Indicator')

    ui.set_visible(feature.def_hc, hc_on)
    ui.set_visible(feature.hc_in_air, hc_on)
    ui.set_visible(feature.hit_chance_in_air, hc_on and ui.get(feature.hc_in_air))
    ui.set_visible(feature.hit_chance_ovr, hc_on)
    ui.set_visible(feature.hc_ovr_key, hc_on)
    ui.set_visible(feature.show_hc_indicator, hc_on)

    ui.set_visible(feature.def_mp, mp_on)
    ui.set_visible(feature.mp_ovr, mp_on)
    ui.set_visible(feature.mp_ovr_key, mp_on)
    ui.set_visible(feature.show_mp_indicator, mp_on)
    
    local any_on = hc_on or mp_on or dmg_on
    ui.set_visible(feature.link_with_md, any_on)
    ui.set_visible(feature.label_col, any_on)
    ui.set_visible(feature.col1, any_on)
    ui.set_visible(feature.col2, any_on)
end

ui.set_callback(feature.enabled_funcs, handle_menu)
ui.set_callback(feature.hc_in_air, handle_menu)
handle_menu()

-- -----------------------------------------------------------------------------
-- 5. 执行逻辑
-- -----------------------------------------------------------------------------

client.set_event_callback('setup_command', function()
    local lp = entity.get_local_player()
    if lp == nil or (not entity.is_alive(lp)) then return end
    
    local flags = entity.get_prop(lp, 'm_fFlags')
    local in_air = bit.band(flags, 1) ~= 1
    local md_active = ui.get(dmg_ovr_key)

    -- --- Hit Chance ---
    if contains(feature.enabled_funcs, 'Hit Chance') then
        local final_hc = ui.get(feature.def_hc)
        if in_air and ui.get(feature.hc_in_air) then final_hc = ui.get(feature.hit_chance_in_air) end
        
        local hc_link = (contains(feature.link_with_md, 'Hit Chance') and md_active)
        if hc_link or ui.get(feature.hc_ovr_key) then
            final_hc = ui.get(feature.hit_chance_ovr)
        end
        ui.set(hc_ref, final_hc)
    end

    -- --- Multi-point ---
    if contains(feature.enabled_funcs, 'Multi-point') then
        local final_mp = ui.get(feature.def_mp)
        local mp_link = (contains(feature.link_with_md, 'Multi-point') and md_active)
        if mp_link or ui.get(feature.mp_ovr_key) then
            final_mp = ui.get(feature.mp_ovr)
        end
        ui.set(mp_ref, final_mp)
    end
end)

client.set_event_callback('paint', function()
    local lp = entity.get_local_player(); if lp == nil or not entity.is_alive(lp) then return end

    local r1, g1, b1, a1 = ui.get(feature.col1)
    local r2, g2, b2, a2 = ui.get(feature.col2)
    local md_active = ui.get(dmg_ovr_key)

    -- --- Damage Indicator (核心逻辑修复) ---
    if contains(feature.enabled_funcs, 'Damage Indicator') then
        local is_linked = contains(feature.link_with_md, 'Damage Indicator')
        
        -- Link 逻辑判断：Link了且没按热键就不显示
        if not is_linked or (is_linked and md_active) then
            local sw, sh = client.screen_size()
            local x, y = sw / 2, sh / 2
            
            -- 如果热键激活，读 idx 3 (dmg_ovr_val)，否则读原生 MD
            local val = md_active and ui.get(dmg_ovr_val) or ui.get(md_ref)
            renderer.text(x + 2, y - 14, 255, 255, 255, 255, "d", 0, val)
        end
    end

    -- --- Indicators ---
    local hc_link = (contains(feature.link_with_md, 'Hit Chance') and md_active)
    if (hc_link or ui.get(feature.hc_ovr_key)) and ui.get(feature.show_hc_indicator) then
        renderer.indicator(255, 255, 255, 255, gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, "md? evil time~"))
    end

    local mp_link = (contains(feature.link_with_md, 'Multi-point') and md_active)
    if (mp_link or ui.get(feature.mp_ovr_key)) and ui.get(feature.show_mp_indicator) then
        renderer.indicator(255, 255, 255, 255, gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, "mp? h$!"))
    end
end)