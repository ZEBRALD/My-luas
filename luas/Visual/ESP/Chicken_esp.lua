--created by zebrald with Gemini AI lmao

local ffi = require("ffi")

-- --- FFI 初始化 (用于本地彩色输出) ---
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

-- --- 控件初始化 ---
local master_switch = ui.new_checkbox("LUA", "B", "Neon Chicken ESP")
local esp_options = ui.new_multiselect("LUA", "B", "ESP Elements", {"Box", "Name", "Dormant", "Gradient Fade"})
local log_options = ui.new_multiselect("LUA", "B", "Death Log Output", {"Console", "Local Chat", "Public Chat"})

local label_color1 = ui.new_label("LUA", "B", "Primary Color")
local color1 = ui.new_color_picker("LUA", "B", "Chicken Color 1", 0, 255, 255, 255)

local label_color2 = ui.new_label("LUA", "B", "Gradient Color 2")
local color2 = ui.new_color_picker("LUA", "B", "Chicken Color 2", 255, 0, 255, 255)

local label_dormant = ui.new_label("LUA", "B", "Dormant Color")
local dormant_color = ui.new_color_picker("LUA", "B", "Dormant Color Picker", 150, 150, 150, 200)

-- --- 菜单显隐逻辑 ---
local function handle_menu()
    local active = ui.get(master_switch)
    local options = ui.get(esp_options)
    local is_gradient = false
    for i=1, #options do if options[i] == "Gradient Fade" then is_gradient = true end end

    ui.set_visible(esp_options, active)
    ui.set_visible(log_options, active)
    ui.set_visible(label_color1, active)
    ui.set_visible(color1, active)
    -- 只有总开关开启 且 勾选了渐变时，才显示 Color 2
    ui.set_visible(label_color2, active and is_gradient)
    ui.set_visible(color2, active and is_gradient)
    ui.set_visible(label_dormant, active)
    ui.set_visible(dormant_color, active)
end

handle_menu()
ui.set_callback(master_switch, handle_menu)
ui.set_callback(esp_options, handle_menu)

-- --- 数据缓存 ---
local chicken_cache = {}

-- --- 辅助函数 ---
local function table_contains(tbl, val)
    for i=1, #tbl do if tbl[i] == val then return true end end
    return false
end

local function lerp(a, b, t) return a + (b - a) * t end

local function get_flow_color(c1, c2, speed, offset, use_gradient)
    if not use_gradient then return c1[1], c1[2], c1[3], c1[4] end
    local factor = (math.sin(globals.realtime() * speed + offset) + 1) / 2
    return lerp(c1[1], c2[1], factor), lerp(c1[2], c2[2], factor), lerp(c1[3], c2[3], factor), c1[4]
end

-- --- 死亡事件逻辑 ---
client.set_event_callback("other_death", function(e)
    if not ui.get(master_switch) or e.othertype ~= "chicken" then return end
    if e.entindex then chicken_cache[e.entindex] = nil end

    local attacker_idx = client.userid_to_entindex(e.attacker)
    local attacker_name = attacker_idx ~= 0 and entity.get_player_name(attacker_idx) or "未知生物"
    local selected_logs = ui.get(log_options)

    local local_msg = string.format("\x01玩家 \x02%s \x01残忍地杀害了一只 \x04小鸡\x01!", attacker_name)
    local public_msg = string.format("玩家 %s 残忍地杀害了一只小鸡!", attacker_name)

    if table_contains(selected_logs, "Console") then client.log(public_msg) end
    if table_contains(selected_logs, "Local Chat") then print_to_chat(hudchat, 0, 0, local_msg) end
    if table_contains(selected_logs, "Public Chat") then client.exec(string.format('say "%s"', public_msg)) end
end)

client.set_event_callback("chicken_death", function(e) chicken_cache[e.chicken] = nil end)

-- --- 渲染回调 ---
client.set_event_callback("paint", function()
    if not ui.get(master_switch) then return end

    local options = ui.get(esp_options)
    local is_grad = table_contains(options, "Gradient Fade")
    local cp1, cp2, cd = {ui.get(color1)}, {ui.get(color2)}, {ui.get(dormant_color)}
    
    local live_chickens = entity.get_all("CChicken")
    local current_frame = {}

    for i=1, #live_chickens do
        local ent = live_chickens[i]
        local ox, oy, oz = entity.get_prop(ent, "m_vecOrigin")
        if ox ~= nil and not entity.is_dormant(ent) then
            chicken_cache[ent] = { x = ox, y = oy, z = oz }
            current_frame[ent] = true
        end
    end

    for ent, data in pairs(chicken_cache) do
        if entity.get_classname(ent) ~= "CChicken" then
            chicken_cache[ent] = nil
            goto next_ent
        end

        local dormant = (current_frame[ent] == nil)
        if dormant and not table_contains(options, "Dormant") then goto next_ent end

        local sx_f, sy_f = renderer.world_to_screen(data.x, data.y, data.z)
        local sx_h, sy_h = renderer.world_to_screen(data.x, data.y, data.z + 18)

        if sx_f and sx_h then
            local h, w = sy_f - sy_h, (sy_f - sy_h) * 0.9
            local x1, y1 = sx_h - w/2, sy_h
            
            -- 获取基础绘制颜色
            local r, g, b, a = cd[1], cd[2], cd[3], cd[4]
            if not dormant then 
                r, g, b, a = get_flow_color(cp1, cp2, 4, 0, is_grad) 
            end

            -- 1. 方框绘制
            if table_contains(options, "Box") then
                local r2, g2, b2 = r, g, b
                if not dormant and is_grad then 
                    r2, g2, b2 = get_flow_color(cp1, cp2, 4, 2, true) 
                end
                -- 如果没开渐变，r2/g2/b2 等于 r/g/b，gradient 函数会自动画出单色
                renderer.gradient(x1, y1, w, 1, r, g, b, a, r2, g2, b2, a, true)
                renderer.gradient(x1, sy_f, w, 1, r, g, b, a, r2, g2, b2, a, true)
                renderer.gradient(x1, y1, 1, h, r, g, b, a, r2, g2, b2, a, false)
                renderer.gradient(x1 + w, y1, 1, h + 1, r, g, b, a, r2, g2, b2, a, false)
            end

            -- 2. 名字绘制
            if table_contains(options, "Name") then
                local tag = dormant and "DORMANT" or "CHICKEN"
                local tx = x1 + w/2 - renderer.measure_text("bd", tag)/2
                for j = 1, #tag do
                    local char = tag:sub(j, j)
                    local lr, lg, lb = r, g, b
                    if not dormant and is_grad then 
                        lr, lg, lb = get_flow_color(cp1, cp2, 4, j * -0.2, true) 
                    end
                    renderer.text(tx, y1 - 15, lr, lg, lb, a, "bd", 0, char)
                    tx = tx + renderer.measure_text("bd", char)
                end
            end
        end
        ::next_ent::
    end
end)


client.set_event_callback("round_start", function() chicken_cache = {} end)
