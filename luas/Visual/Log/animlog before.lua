local pi, max = math.pi, math.max

-- 渲染与动画底层
local dynamic = {}
dynamic.__index = dynamic

function dynamic.new(f, z, r, xi)
   f = max(f, 0.001)
   z = max(z, 0)
   local pif = pi * f
   local twopif = 2 * pif
   return setmetatable({
      a = z / pif, b = 1 / ( twopif * twopif ), c = r * z / twopif,
      px = xi, y = xi, dy = 0
   }, dynamic)
end

function dynamic:update(dt, x, dx)
   if dx == nil then dx = ( x - self.px ) / dt self.px = x end
   self.y  = self.y + dt * self.dy
   self.dy = self.dy + dt * ( x + self.c * dx - self.y - self.a * self.dy ) / self.b
   return self
end

function dynamic:get() return self.y end

local function roundedRectangle(b, c, d, e, f, g, h, i, k)
    renderer.rectangle(b, c, d, e, f, g, h, i)
    renderer.circle(b, c, f, g, h, i, k, -180, 0.25)
    renderer.circle(b + d, c, f, g, h, i, k, 90, 0.25)
    renderer.rectangle(b, c - k, d, k, f, g, h, i)
    renderer.circle(b + d, c + e, f, g, h, i, k, 0, 0.25)
    renderer.circle(b, c + e, f, g, h, i, k, -90, 0.25)
    renderer.rectangle(b, c + e, d, k, f, g, h, i)
    renderer.rectangle(b - k, c, k, e, f, g, h, i)
    renderer.rectangle(b + d, c, k, e, f, g, h, i)
end

-- UI 菜单
ui.new_label("RAGE", "Other", "-----------------------------------------")
local menu = {
    enable = ui.new_checkbox("RAGE", "Other", "[Log] Enable Aimbot Logs"),
    style = ui.new_combobox("RAGE", "Other", "Log Style", {"Neurosama", "Seripk"}),
    
    log_features = ui.new_multiselect("RAGE", "Other", "Enabled Logs", {
        "Screen Fire Log", 
        "Screen Hitlog",      
        "Console Fire Log", 
        "Console Hit/Miss Log",
        "Chat Log"
    }),
    chat_log_miss_only = ui.new_checkbox("RAGE", "Other", "Chat Log: Miss/Bad Resolve Only"),

    y_offset = ui.new_slider("RAGE", "Other", "Log Vertical Offset", 0, 1000, 0), 
    seripk_spacing = ui.new_slider("RAGE", "Other", "Seripk Line Spacing", 15, 50, 15),
    log_time = ui.new_slider("RAGE", "Other", "Visible Time", 1, 10, 4, true, "s"),

    color_label = ui.new_label("RAGE", "Other", "Accent / Rect Color"),
    color = ui.new_color_picker("RAGE", "Other", "Accent Color", 147, 112, 219, 255),
    rect_color = ui.new_color_picker("RAGE", "Other", "Rect Color", 198, 160, 137, 100)
}
ui.new_label("RAGE", "Other", "-----------------------------------------")

local hitgroup_names = {'通用', '頭部', '胸部', '胃部', '左手', '右手', '左腿', '右腿', '脖子', '?', '装备'}
local logs = {}
local stored_shot = {}

-- [ 配置区 ] 空枪原因中文映射表
local reason_map = {
    ["resolver"]         = "解析器",
    ["spread"]           = "扩散",
    ["unregistered shot"] = "未注册镜头",
    ["occlusion"]        = "掩体阻挡",
    ["prediction error"] = "预测",
    ["clamped"]          = "角度限制",
    ["undefined"]        = "未知原因",
    ["death"]            = "目标已死"
}

local function contains(table, val)
    for i = 1, #table do
        if table[i] == val then return true end
    end
    return false
end

client.set_event_callback("paint_ui", function()
    local active = ui.get(menu.enable)
    local features = ui.get(menu.log_features)
    local chat_log_enabled = contains(features, "Chat Log")

    ui.set_visible(menu.style, active)
    ui.set_visible(menu.log_features, active)
    ui.set_visible(menu.y_offset, active)
    ui.set_visible(menu.log_time, active)
    ui.set_visible(menu.color_label, active)
    ui.set_visible(menu.seripk_spacing, active and ui.get(menu.style) == "Seripk")
    ui.set_visible(menu.chat_log_miss_only, active and chat_log_enabled)
end)

function fired(e)
    if not ui.get(menu.enable) then return end
    local features = ui.get(menu.log_features)
    local target_name = string.lower(entity.get_player_name(e.target))
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    stored_shot = { damage = e.damage, hitbox = group, lagcomp = e.teleported, backtrack = e.backtrack, hit_chance = e.hit_chance }
    local lc_stat = stored_shot.lagcomp and "on" or "off"

    if contains(features, "Screen Fire Log") then
        local screen_log = string.format("\a80dfd2C8➜ \aD5D5D5C8正在射擊 \ac6a089C8%s \aD5D5D5C8的 \aA90005C8%s \aD5D5D5C8預計 \aBFFF90C9%sHP \aD5D5D5C8(幾率: \aBFFF90C9%s%%, Bt: \aBFFF90C9%s, Lc: \a80dfd2C8%s)", target_name, group, e.damage, math.floor(e.hit_chance), e.backtrack, lc_stat)
        table.insert(logs, { text = screen_log, is_hit = true })
    end

    if contains(features, "Console Fire Log") then
        local r, g, b = ui.get(menu.color)
        client.color_log(128, 223, 210, "➜ \0")
        client.color_log(r, g, b, "「Evil」\0")
        client.color_log(213, 213, 213, "正在射击 \0")
        client.color_log(198, 160, 137, target_name .. "\0")
        client.color_log(213, 213, 213, " 的 \0")
        client.color_log(169, 0, 5, group .. "\0")
        client.color_log(213, 213, 213, " 预计伤害: \0")
        client.color_log(191, 255, 144, e.damage .. " \0")
        client.color_log(213, 213, 213, "命中率: \0")
        client.color_log(128, 223, 210, math.floor(e.hit_chance) .. "% \0")
        client.color_log(213, 213, 213, "回溯: \0")
        client.color_log(191, 255, 144, e.backtrack .. " ticks \0")
        client.color_log(213, 213, 213, "LC: \0")
        client.color_log(191, 255, 144, lc_stat)
    end
end

function hit(e)
    if not ui.get(menu.enable) then return end
    local features = ui.get(menu.log_features)
    local name = string.lower(entity.get_player_name(e.target))
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    local lc_stat = (stored_shot.lagcomp or e.teleported) and "on" or "off"
    
    local predicted_group = stored_shot.hitbox or "?"
    local is_hitbox_mismatch = (predicted_group ~= group) and (predicted_group ~= "?")

    local screen_symbol = is_hitbox_mismatch and "\aA90005C8✘" or "\a80dfd2C8✔"
    local console_symbol = is_hitbox_mismatch and "✘" or "✔"

    if contains(features, "Screen Hitlog") then
        local screen_log = string.format("%s \aD5D5D5C8擊中 \ac6a089C8 %s \aD5D5D5C8的 \aA90005C8%s \aD5D5D5C8掉了 \aBFFF90C9%sHP \aD5D5D5C8「\aD5D5D5C8幾率: \aBFFF90C9%s, \aD5D5D5C8回溯: \aBFFF90C9%s, \aD5D5D5C8lc: \a80dfd2C8%s 」", screen_symbol, name, group, e.damage, math.floor(e.hit_chance).."%", (stored_shot.backtrack or 0), lc_stat)
        table.insert(logs, { text = screen_log, is_hit = true }) 
    end

    if contains(features, "Console Hit/Miss Log") then
        local r, g, b = ui.get(menu.color)
        client.color_log(is_hitbox_mismatch and 169 or 255, is_hitbox_mismatch and 0 or 169, is_hitbox_mismatch and 5 or 175, console_symbol .. " \0")
        client.color_log(r, g, b, "「Evil」\0")
        client.color_log(213, 213, 213, "击中 \0")
        client.color_log(198, 160, 137, name .. "\0")
        client.color_log(213, 213, 213, " 的 \0")
        client.color_log(169, 0, 5, group .. "\0")
        client.color_log(128, 223, 210, "「"..(stored_shot.hitbox or "?").."」\0")
        client.color_log(213, 213, 213, "伤害了: \0")
        client.color_log(191, 255, 144, e.damage .. " \0")
        client.color_log(128, 223, 210, "「"..(stored_shot.damage or 0).."」\0")
        client.color_log(191, 255, 144, " HP \0")
        client.color_log(213, 213, 213, "命中率: \0")
        client.color_log(128, 223, 210, math.floor(e.hit_chance) .. "% \0")
        client.color_log(213, 213, 213, "回溯：\0")
        client.color_log(191, 255, 144, (stored_shot.backtrack or 0) .. " ticks \0")
        client.color_log(213, 213, 213, "LC: \0")
        client.color_log(191, 255, 144, lc_stat)
    end

    if contains(features, "Chat Log") then
        if not ui.get(menu.chat_log_miss_only) or is_hitbox_mismatch then
            local chat_msg = string.format("%s 击中 %s 的 %s「%s」伤害了: %s 「%s」 HP 命中率: %s%% 回溯：%s ticks LC: %s", 
                console_symbol, name, group, (stored_shot.hitbox or "?"), e.damage, (stored_shot.damage or 0), math.floor(e.hit_chance), (stored_shot.backtrack or 0), lc_stat)
            client.exec("say ", chat_msg)
        end
    end
end

function missed(e)    
    if not ui.get(menu.enable) then return end
    local features = ui.get(menu.log_features)
    local name = string.lower(entity.get_player_name(e.target))
    local group = hitgroup_names[e.hitgroup + 1] or '?'
    
    -- --- 使用映射表将原因转为中文 ---
    local raw_reason = e.reason == "?" and "resolver" or e.reason
    local display_reason = reason_map[raw_reason] or raw_reason
    -- ----------------------------

    local lc_stat = (stored_shot.lagcomp or e.teleported) and "on" or "off"
    
    if contains(features, "Screen Hitlog") then
        local screen_log = string.format("\aA90005C8✘ \aD5D5D5C8空了 \ac6a089C8%s \aD5D5D5C8的 \aA90005C8%s \aD5D5D5C8原因: \aA90005C8%s \ac6a089C8「\aD5D5D5C8幾率: \ac6a089C8%s, \aD5D5D5C8回溯: \ac6a089C8%s, \aD5D5D5C8lc: \ac6a089C8%s」", name, (stored_shot.hitbox or "?"), display_reason, math.floor(e.hit_chance).."%", (stored_shot.backtrack or 0), lc_stat)
        table.insert(logs, { text = screen_log, is_hit = false })
    end

    if contains(features, "Console Hit/Miss Log") then
        local r, g, b = ui.get(menu.color)
        client.color_log(169, 0, 5, "✘ \0")
        client.color_log(r, g, b, "「Evil」\0")
        client.color_log(213, 213, 213, "空了 \0")
        client.color_log(198, 160, 137, name .. "\0")
        client.color_log(213, 213, 213, " 的 \0")
        client.color_log(169, 0, 5, group .. "\0")
        client.color_log(128, 223, 210, "「"..(stored_shot.hitbox or "?").."」\0")
        client.color_log(213, 213, 213, "原因: \0")
        client.color_log(169, 0, 5, display_reason .. "\0")
        client.color_log(213, 213, 213, " 预测伤害: \0")
        client.color_log(198, 160, 137, (stored_shot.damage or 0) .. " \0")
        client.color_log(191, 255, 144, " HP \0")
        client.color_log(213, 213, 213, "命中率: \0")
        client.color_log(198, 160, 137, math.floor(e.hit_chance) .. "% \0")
        client.color_log(213, 213, 213, " 回溯：\0")
        client.color_log(191, 255, 144, (stored_shot.backtrack or 0) .. " ticks \0")
        client.color_log(213, 213, 213, "LC: \0")
        client.color_log(191, 255, 144, lc_stat)
    end

    if contains(features, "Chat Log") then
        local chat_msg = string.format("✘ 空了 %s 的 %s「%s」原因: %s 「几率: %s%%, 回溯: %s, LC: %s」", 
            name, group, (stored_shot.hitbox or "?"), display_reason, math.floor(e.hit_chance), (stored_shot.backtrack or 0), lc_stat)
        client.exec("say ", chat_msg)
    end
end

-- 渲染逻辑保持不变...
function logging()
    if not ui.get(menu.enable) then return end
    local screen = {client.screen_size()}
    local cur_style = ui.get(menu.style)
    local max_time = ui.get(menu.log_time) * 64
    local user_y_offset = ui.get(menu.y_offset)

    for i = #logs, 1, -1 do
        local log = logs[i]
        
        if not log.init then
            log.y = dynamic.new(2, 1, 1, -30)
            log.time = globals.tickcount() + max_time
            log.max_time = max_time
            log.init = true
        end

        local r, g, b, a = ui.get(menu.color)
        local rb, gb, bb, ab = ui.get(menu.rect_color)
        
        local remaining_ticks = log.time - globals.tickcount()
        local is_expired = remaining_ticks <= 0
        local anim_y = log.y:get()
        local base_y = screen[2] - anim_y - user_y_offset

        if cur_style == "Neurosama" then
            local string_size = renderer.measure_text("c", log.text)
            roundedRectangle(screen[1]/2 - string_size/2 - 25, base_y, string_size + 30, 16, rb, gb, bb, ab, 4)
            renderer.text(screen[1]/2 - 20, base_y + 8, 255, 255, 255, 255, "c", 0, log.text)
            renderer.circle_outline(screen[1]/2 + string_size/2 - 6, base_y + 8, 13, 13, 13, 200, 7, 0, 1, 4)
            local progress = is_expired and 0 or (remaining_ticks / log.max_time)
            renderer.circle_outline(screen[1]/2 + string_size/2 - 6, base_y + 8, r, g, b, a, 6, 0, progress, 2)

            if is_expired then
                if anim_y < -30 then
                    table.remove(logs, i)
                else
                    log.y:update(globals.frametime(), -50, nil)
                end
            else
                log.y:update(globals.frametime(), 20 + (i * 28), nil)
            end

        elseif cur_style == "Seripk" then
            local fade_duration = 20
            local string_size = renderer.measure_text("", log.text)
            local x_pos = screen[1]/2 - string_size/2
            
            local tr, tg, tb = 255, 255, 255
            if not log.is_hit then tr, tg, tb = 255, 50, 50 end 

            local alpha = 255
            local offset_x = 0
            
            if is_expired then
                local exit_progress = math.abs(remaining_ticks) / fade_duration
                if exit_progress >= 1 then
                    table.remove(logs, i)
                    goto continue
                end
                alpha = max(0, 255 * (1 - exit_progress))
                offset_x = 50 * exit_progress
            end

            local hex_alpha = string.format("%02x", alpha)
            local faded_text = log.text:gsub("(\a%x%x%x%x%x%x)%x%x", "%1" .. hex_alpha)

            renderer.text(x_pos + offset_x, base_y + 8, tr, tg, tb, alpha, "", 0, faded_text)
            log.y:update(globals.frametime(), 20 + (i * ui.get(menu.seripk_spacing)), nil)
        end
        ::continue::
    end
end

client.set_event_callback('paint', logging)
client.set_event_callback("aim_fire", fired)
client.set_event_callback("aim_hit", hit)
client.set_event_callback("aim_miss", missed)