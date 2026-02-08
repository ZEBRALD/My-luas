local vector = require 'vector'

-- --- 基础工具函数 ---
local function table_contains(tbl, val)
    for i=1, #tbl do if tbl[i] == val then return true end end
    return false
end

local function round(value) return math.floor(value + 0.5) end

-- --- 控件初始化 ---
local master_switch = ui.new_checkbox("LUA", "B", "Neon Chicken ESP [Fixed]")
local esp_options = ui.new_multiselect("LUA", "B", "ESP Elements", {"Box", "Name", "Health bar", "Flags", "Distance"})
local color_picker = ui.new_color_picker("LUA", "B", "ESP Color", 0, 255, 255, 255)

-- --- 渲染回调 ---
client.set_event_callback("paint", function()
    if not ui.get(master_switch) then return end

    local options = ui.get(esp_options)
    local r, g, b, a = ui.get(color_picker)
    local lp = entity.get_local_player()
    if not lp then return end
    local lp_origin = vector(entity.get_origin(lp))
    
    local live_chickens = entity.get_all("CChicken")

    for i=1, #live_chickens do
        local ent = live_chickens[i]
        
        -- 1. 严格同步：直接获取每一帧实时的 Origin
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin")
        if ox == nil or entity.is_dormant(ent) then goto next_ent end

        -- 2. 坐标计算：沿用原版 +18 锁定高度逻辑，确保框不随模型动画乱晃
        local sx_f, sy_f = renderer.world_to_screen(ox, oy, oz)
        local sx_h, sy_h = renderer.world_to_screen(ox, oy, oz + 18)

        if sx_f and sx_h then
            local h = sy_f - sy_h
            local w = h * 0.9
            local x1 = sx_h - w/2
            local y1 = sy_h
            
            -- --- 开始绘制 ---

            -- 1. 方框 (Box)
            if table_contains(options, "Box") then
                -- 绘制外边框阴影
                renderer.rectangle(x1 - 1, y1 - 1, w + 2, h + 2, 0, 0, 0, a * 0.6)
                -- 绘制主色调方框
                renderer.rectangle(x1, y1, w, 1, r, g, b, a) -- 顶
                renderer.rectangle(x1, sy_f, w, 1, r, g, b, a) -- 底
                renderer.rectangle(x1, y1, 1, h, r, g, b, a) -- 左
                renderer.rectangle(x1 + w, y1, 1, h + 1, r, g, b, a) -- 右
            end

            -- 2. 名字 (Name)
            if table_contains(options, "Name") then
                renderer.text(x1 + w/2, y1 - 12, r, g, b, a, "c", 0, "CHICKEN")
            end

            -- 3. 血条 (Health bar)
            if table_contains(options, "Health bar") then
                renderer.rectangle(x1 - 6, y1 - 1, 4, h + 2, 0, 0, 0, a * 0.6)
                renderer.rectangle(x1 - 5, y1, 2, h, 120, 225, 80, a)
            end

            -- 4. 距离 (Distance)
            if table_contains(options, "Distance") then
                local dist_ft = round(lp_origin:dist(vector(ox, oy, oz)) * 0.082)
                renderer.text(x1 + w/2, sy_f + 2, 255, 255, 255, a, "c-", 0, string.format("%dFT", dist_ft))
            end

            -- 5. 旗帜 (Flags)
            if table_contains(options, "Flags") then
                renderer.text(x1 + w + 3, y1, 132, 192, 43, a, "-", 0, "KFC")
                renderer.text(x1 + w + 3, y1 + 8, 255, 255, 255, a, "-", 0, "FLY")
            end
        end

        ::next_ent::
    end
end)