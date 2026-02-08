local notify = {}
notify.__index = notify

notify.invoke_callback = function(timeout)
    return setmetatable({
        active = false,
        delay = 0,
        laycoffset = -11, 
        layboffset = -11
    }, notify)
end

notify.setup_color = function(color, sec_color)
    if type(color) ~= 'table' then
        notify:setup()
        return
    end

    if notify.color == nil then notify:setup() end

    if color ~= nil then notify.color[1] = color end
    if sec_color ~= nil then notify.color[2] = sec_color end
end

notify.add = function(time, is_right, ...)
    if notify.color == nil then
        notify:setup()
    end

    table.insert(notify.__list, {
        ["tick"] = globals.tickcount(),
        ["invoke"] = notify.invoke_callback(),
        ["text"] = { ... }, ["time"] = time,
        ["color"] = notify.color,
        ["right"] = is_right,
        ["first"] = false
    })
end

function notify:setup()
    notify.color = { 
        { 150, 185, 1 },
        { 0, 0, 0 }
    }

    if notify.__list == nil then
        notify.__list = {}
        client.delay_call(0.05, function()

            notify.add(3, false, { 150, 185, 1, "[Gamesense]" }, { 255, 106, 106 , "  歡 迎 回 來" })
        end)
    end
end

function notify:listener()
    local count_left = 0
    local count_right = 0
    local old_tick = 0

    if notify.__list == nil then
        notify:setup()
    end

    for i=1, #notify.__list do
        local layer = notify.__list[i]
        if layer.tick ~= old_tick then
            notify:setup()
        end

        if layer.right == true then
            layer.invoke:show_right(count_right, layer.color, layer.text)
            if layer.invoke.active then
                count_right = count_right + 1
            end
        else
            layer.invoke:show(count_left, layer.color, layer.text)
            if layer.invoke.active then
                count_left = count_left + 1
            end
        end

        if layer.first == false then
            layer.invoke:start(layer.time)
            notify.__list[i]["first"] = true
        end

        old_tick = layer.tick
    end
end

function notify:start(timeout)
    self.active = true
    self.delay = globals.realtime() + timeout
end

function notify:get_text_size(lines_combo)
    local x_offset_text = 0

    for i=1, #lines_combo do
        local r, g, b, message = unpack(lines_combo[i])
        local width, height = renderer.measure_text("", message)
        x_offset_text = x_offset_text + width
    end

    return x_offset_text
end

function notify:string_ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

function notify:multicolor_text(x, y, flags, lines_combo)
    local line_height_temp = 0
    local x_offset_text = 0
    local y_offset = 0

    for i=1, #lines_combo do
        local r, g, b, message = unpack(lines_combo[i])

        message = message .. "\0"
        renderer.text(x + x_offset_text, y + y_offset, r, g, b, 255, flags, 0, message)

        if self:string_ends_with(message, "\0") then
            local width, height = renderer.measure_text(flags, message)
            x_offset_text = x_offset_text + width
        else
            x_offset_text = 0
            y_offset = y_offset + line_height_temp
        end
    end
end

function notify:show(count, color, text)
    if self.active ~= true then
        return
    end

    local x, y = client.screen_size()
    local y = 5 + (27 * count)
    local text_w, text_h = self:get_text_size(text)
    
    local max_width = text_w 
    local max_width = max_width < 150 and 150 or max_width 

    if color == nil then color = self.color end
    local factor = 255 / 25 * globals.frametime()

    if globals.realtime() < self.delay then
        if self.laycoffset < max_width then self.laycoffset = self.laycoffset + (max_width - self.laycoffset) * factor end
        if self.laycoffset > max_width then self.laycoffset = max_width end
        if self.laycoffset > max_width / 1.09 then
            if self.layboffset < max_width - 6 then
                self.layboffset = self.layboffset + ((max_width - 6) - self.layboffset) * factor
            end
        end

        if self.layboffset > max_width - 6 then
            self.layboffset = max_width - 6
        end
    else
        if self.layboffset > -11 then
            self.layboffset = self.layboffset - (((max_width-5)-self.layboffset) * factor) + 0.01
        end

        if self.layboffset < (max_width - 11) and self.laycoffset >= 0 then
            self.laycoffset = self.laycoffset - (((max_width + 1) - self.laycoffset) * factor) + 0.01
        end

        if self.laycoffset < 0 then 
            self.active = false
        end
    end

    renderer.rectangle(self.laycoffset - self.laycoffset, y, self.laycoffset + 16, 25, color[1][1], color[1][2], color[1][3], 255)
    renderer.rectangle(self.layboffset - self.laycoffset, y, self.layboffset + 22, 25, color[2][1], color[2][2], color[2][3], 255)
    self:multicolor_text(self.layboffset - max_width + 11, y + 6, "", text)
end

function notify:show_right(count, color, text)
    if self.active ~= true then
        return
    end

    local x, y = client.screen_size()
    local y = y - 68 - (27 * count)
    local text_w, text_h = self:get_text_size(text)
    
    local max_width = text_w + 22
    local max_width = max_width < 150 and 150 or max_width 

    if color == nil then color = self.color end
    local factor = 255 / 25 * globals.frametime()

    if globals.realtime() < self.delay then
        if self.laycoffset < max_width then self.laycoffset = self.laycoffset + (max_width - self.laycoffset) * factor end
        if self.laycoffset > max_width then self.laycoffset = max_width end
        if self.laycoffset > max_width / 1.09 then
            if self.layboffset < max_width - 6 then
                self.layboffset = self.layboffset + ((max_width - 6) - self.layboffset) * factor
            end
        end

        if self.layboffset > max_width - 6 then
            self.layboffset = max_width - 6
        end
    else
        if self.layboffset > 0 then
            self.layboffset = self.layboffset - (((max_width-5)-self.layboffset) * factor) + 0.01
        end

        if self.layboffset < (max_width - 11) and self.laycoffset >= 0 then
            self.laycoffset = self.laycoffset - (((max_width + 1) - self.laycoffset) * factor) + 0.01
        end

        if self.laycoffset < 0 then 
            self.active = false
        end
    end

    renderer.rectangle(x - self.laycoffset + 3, y, self.laycoffset + 3 + self.laycoffset, 25, color[1][1], color[1][2], color[1][3], 255)
    renderer.rectangle(x - self.layboffset + 3, y, self.layboffset + 3 + self.layboffset, 25, color[2][1], color[2][2], color[2][3], 255)
    self:multicolor_text(x - self.layboffset + 10, y + 6, "", text)
end

local aimbotlog_enable = ui.new_checkbox("Rage", "Other", "Hit Logs")
local on_fire_enable = ui.new_checkbox("Rage", "Other", "Fire log")
local on_fire_colour = ui.new_color_picker("Rage", "Other", "Fire log", 147, 112, 219, 255)
local on_miss_enable = ui.new_checkbox("Rage", "Other", "Miss log")
local on_miss_colour = ui.new_color_picker("Rage", "Other", "Miss log", 255, 253, 166, 255)
local on_damage_enable = ui.new_checkbox("Rage", "Other", "Damage log")
local on_damage_colour = ui.new_color_picker("Rage", "Other", "Damage log", 100, 149, 237, 255)

local function handle_menu()
	if ui.get(aimbotlog_enable) then
		ui.set_visible(on_fire_enable, true)
		ui.set_visible(on_fire_colour, true)
		ui.set_visible(on_miss_enable, true)
		ui.set_visible(on_miss_colour, true)
		ui.set_visible(on_damage_enable, true)
		ui.set_visible(on_damage_colour, true)
	else
		ui.set_visible(on_fire_enable, false)
		ui.set_visible(on_fire_colour, false)
		ui.set_visible(on_miss_enable, false)
		ui.set_visible(on_miss_colour, false)
		ui.set_visible(on_damage_enable, false)
		ui.set_visible(on_damage_colour, false)
	end
end
handle_menu()
ui.set_callback(aimbotlog_enable, handle_menu)

client.set_event_callback("paint", function()
    notify:listener()
end)

local function on_aim_fire(e)
    if ui.get(aimbotlog_enable) and ui.get(on_fire_enable) and e ~= nil then
    	local r, g, b = ui.get(on_fire_colour)
        local hitgroup_names = { "Body", "Head", "Chest", "Stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }
        local group = hitgroup_names[e.hitgroup + 1] or "?"
        local tickrate = client.get_cvar("cl_cmdrate") or 64
        local target_name = entity.get_player_name(e.target)
        local ticks = math.floor((e.backtrack * tickrate) + 0.5)
        local flags = {
        e.teleported and 't' or '',
        e.interpolated and 'i' or '',
        e.extrapolated and 'e' or '',
        e.boosted and 'b' or '',
        e.high_priority and 'h' or ''
    	}

        notify.setup_color({ r, g, b })
        notify.add(5, false,
        { 255, 255, 255, "正在射击 " },
        { r, g, b, string.lower(target_name) },
        { 255, 255, 255, "的 " },
        { r, g, b, group },
        { 255, 255, 255, " 预计伤害 " },
        { r, g, b, e.damage },
        { 255, 255, 255, " 血 (" },
        { r, g, b, "Hc: " .. string.format("%d", e.hit_chance) },
        { 255, 255, 255, "%, " },
        { r, g, b, "Bt: " .. e.backtrack },
        { 255, 255, 255, " (" },
        { r, g, b, ticks .. "tks" },
        { 255, 255, 255, "), " },
        { r, g, b, "Flgs: " .. table.concat(flags) },
        { 255, 255, 255, ")" })
    end
end

local function on_player_hurt(e)
	if ui.get(aimbotlog_enable) and ui.get(on_damage_enable) then
    local attacker_id = client.userid_to_entindex(e.attacker)
    if attacker_id == nil then
        return
    end

    if attacker_id ~= entity.get_local_player() then
        return
    end

    local hitgroup_names = { "Body", "Head", "Chest", "Stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local target_id = client.userid_to_entindex(e.userid)
    local target_name = entity.get_player_name(target_id)

    local rhp = ""
    if e.health <= 0 then
        rhp = rhp .. " *掉!!!!!*"
    end

    local r, g, b = ui.get(on_damage_colour)
        notify.setup_color({ r, g, b })
        notify.add(5, false,
        { 255, 255, 255, "打中了 " },
        { r, g, b, string.lower(target_name) },
        { 255, 255, 255, "的 " },
        { r, g, b, group },
        { 255, 255, 255, " 掉了 " },
        { r, g, b, e.dmg_health },
        { 255, 255, 255, " 伤害 (" },
        { r, g, b, e.health .. " 血量剩余" },
        { 255, 255, 255, ")" },
        { 255, 255, 255, rhp })
    end
end

local function on_aim_miss(e)
	if ui.get(aimbotlog_enable) and ui.get(on_miss_enable) and e ~= nil then
	local r, g, b = ui.get(on_miss_colour)
    local hitgroup_names = { "Body", "Head", "Chest", "Stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local target_name = entity.get_player_name(e.target)
    local reason
    if e.reason == "?" then
    	reason = "解析器"
    else
    	reason = e.reason
    end

        notify.setup_color({ r, g, b })
        notify.add(5, false,
        { 255, 255, 255, "空了 " },
        { r, g, b, string.lower(target_name) },
        { 255, 255, 255, "的 " },
        { r, g, b, group },
        { 255, 255, 255, " 原因 " },
        { r, g, b, reason })
    end
end

client.set_event_callback('aim_fire', on_aim_fire)
client.set_event_callback('player_hurt', on_player_hurt)
client.set_event_callback('aim_miss', on_aim_miss)