local ffi = require("ffi")
ffi.cdef[[
typedef void***(__thiscall* FindHudElement_t)(void*, const char*);
typedef void(__cdecl* ChatPrintf_t)(void*, int, int, const char*, ...);
]]

local signature_gHud = "\xB9\xCC\xCC\xCC\xCC\x88\x46\x09"
local signature_FindElement = "\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x57\x8B\xF9\x33\xF6\x39\x77\x28"

local match = client.find_signature("client_panorama.dll", signature_gHud) or error("sig1 not found")
local hud = ffi.cast("void**", ffi.cast("char*", match) + 1)[0] or error("hud is nil")

match = client.find_signature("client_panorama.dll", signature_FindElement) or error("FindHudElement not found")
local find_hud_element = ffi.cast("FindHudElement_t", match)
local hudchat = find_hud_element(hud, "CHudChat") or error("CHudChat not found")

local chudchat_vtbl = hudchat[0] or error("CHudChat instance vtable is nil")
local print_to_chat = ffi.cast("ChatPrintf_t", chudchat_vtbl[27])

local function print_chat(text)
	print_to_chat(hudchat, 0, 0, text)
end

local extra_log = function(fn,...)
	local data = { ... }
	
	for i=1, #data do
		if i==1 then
			local clr = {
				{ 171,217,53 },
				{ 255, 0, 0 },
			}

			client.color_log(clr[fn][1], clr[fn][2], clr[fn][3], '[gamesense] \0')
		end

		client.color_log(data[i][1], data[i][2], data[i][3],  string.format('%s\0', data[i][4]))
        
        if i == #data then
            client.color_log(255, 255, 255, ' ')
        end
	end
end
ui.new_label('lua', 'a', '-----------------------------------------')
local aimbot_log = ui.new_checkbox('lua', 'a', '[Seripk] Aimbot log')
local style = ui.new_combobox('lua', 'a', 'log style', {'gamesense','default','Seripk'})
ui.new_label('lua', 'a', 'aim hit color')
local hit_color = ui.new_color_picker('lua', 'a', 'aim hit color picker', 255, 255, 255, 255)

ui.new_label('lua', 'a', 'aim miss color')
local miss_color = ui.new_color_picker('lua', 'a', 'aim miss color picker', 255, 25, 25, 255)

local log_time = ui.new_slider('lua', 'a', 'visible time', 1, 10, 4, true)

local log_chat = ui.new_checkbox('lua', 'a', 'chat log - miss')

local console_chat = ui.new_checkbox('lua', 'a', 'console log - miss')

local notify = (function()
    local notify = {callback_registered = false, maximum_count = 15, data = {}}
    function notify:register_callback()
        if self.callback_registered then return end
        client.set_event_callback('paint_ui', function()
            
            local d = 5;
            local data = self.data;
            for f = #data, 1, -1 do
                data[f].time = data[f].time - globals.frametime() *2
                local alpha, h = 255, 0;
                local _data = data[f]
                if _data.time < 0 then
                    table.remove(data, f)
                else
                    local time_diff = _data.def_time - _data.time;
                    local time_diff = time_diff > 1 and 1 or time_diff;
                    if _data.time < 0.5 or time_diff < 0.5 then
                        h = (time_diff < 1 and time_diff or _data.time) / 0.5;
                        alpha = h * 255;
                        if h < 0.2 then
                            d = d + 15 * (1.0 - h / 0.2)
                        end
                    end
                    local text_data = {renderer.measure_text("", _data.draw)}
                    local x,y = client.screen_size()
                    
                    local r,g,b = 255,255,255
                    local hit = string.find(_data.draw,"Hit",1)
                    if hit ~= nil then
                        r,g,b = ui.get(hit_color)
                    else
                        r,g,b = ui.get(miss_color)
                    end
                    if ui.get(style) == 'gamesense' then
                        renderer.text(x/2-text_data[1]/2,y/2+20+d+y/4, r,g,b, alpha, '', nil, _data.draw)
                        
                    elseif ui.get(style) == 'Seripk' then
                        renderer.text(x/2-text_data[1]/2+5*alpha/255,y/2+20*alpha/255+d+y/4, r,g,b, alpha, '', nil, _data.draw)
                    else   
                        renderer.text(x/2-text_data[1]/2,y/2+20+d+y/4, r,g,b, alpha, 'b', nil, _data.draw)
                    end
                    
                    d = d + text_data[2] + 5
                end
            end
            self.callback_registered = true
        end)
    end
    
    function notify:paint(time, text)
        local timer = tonumber(time) + 1;
        for f = self.maximum_count, 2, -1 do
            self.data[f] = self.data[f - 1]
        end
        self.data[1] = {time = timer, def_time = timer, draw = text}
        self:register_callback()
    end
    return notify
end)()


----------------
local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
	local output = ''

	local len = #text-1

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
local last_damage = 0
local function player_hurt(e)
    local attacker_id = client.userid_to_entindex(e.attacker)

    if attacker_id == nil then
        return
    end

    if attacker_id ~= entity.get_local_player() then
        return
    end
    local target_id = client.userid_to_entindex(e.userid)
    local enemy_health = entity.get_prop(target_id, "m_iHealth")
    local rem_health = enemy_health - e.dmg_health
    if rem_health <= 0 then
        rem_health = 0
    end
    last_damage = rem_health
end
local function aim_miss(e)
    if not ui.get(aimbot_log) then
        return
    end
    local name = entity.get_player_name(e.target)
    local hitgroup_names = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local resolver = ""
    if e.reason == "?" then
    	resolver = "resolver"
    else
    	resolver = e.reason
    end
    local health = entity.get_prop(e.target, "m_iHealth")
    
    if ui.get(console_chat) then
        extra_log(1,{251,251,149,resolver},{255,255,255," - "},{255,5,5,name},{255,255,255," miss in the "},{168,230,255,group},{255,255,255," | health: "..health.." hitchance: "..e.hit_chance.."%"})
    end
        --[[
\x01 - white
\x02 - red
\x03 - purple
\x04 - green
\x05 - yellow green
\x06 - light green
\x07 - light red
\x08 - gray
\x09 - light yellow
\x0A - gray
\x0C - dark blue
\x10 - gold
]]
    if ui.get(log_chat) then
	    print_chat(" \x06[Game6sense] \x01-\x09 " .. resolver.."\x01 名字: \x02" .. name .. "\x01 部位: \x0C" .. group .. "\x01 生命值: \x04" .. health .. "\x01 命中率: \x04" .. e.hit_chance)
    end

    if ui.get(style) == 'gamesense' then
        local h = {ui.get(miss_color)}
        
        local gradient_skeet = gradient_text(171,217,53,255,171,217,53,255,'[gamesense] ')
        
        local info_text = string.format('✘ Missed %s %s(%s%%) due to %s',name,group,resolver)
        local gradient_info = gradient_text(h[1],h[2],h[3],h[4],h[1],h[2],h[3],h[4],info_text)
        local text = gradient_skeet..gradient_info

        notify:paint(ui.get(log_time),text)
    elseif ui.get(style) == 'default' then
        notify:paint(ui.get(log_time),string.format('✘ Missed %s %s due to %s',name,group,resolver))
    elseif ui.get(style) == 'Seripk' then
        notify:paint(ui.get(log_time),string.format('✘ Missed %s %s due to %s',name,group,resolver))
    end
    
end
local function aim_hit(e)
    if not ui.get(aimbot_log) then
        return
    end
    local hitgroup_names = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?", "gear" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local name = entity.get_player_name(e.target)
    -- ,'default','Seripk'
    if ui.get(style) == 'gamesense' then
        
        local h = {ui.get(hit_color)}
        local gradient_skeet = gradient_text(171,217,53,255,171,217,53,255,'[gamesense] ')
        local info_text = string.format('✔ Hit %s in the %s for %s',name,group,e.damage)
        local gradient_info = gradient_text(h[1],h[2],h[3],h[4],h[1],h[2],h[3],h[4],info_text)
        local text = gradient_skeet..gradient_info

        notify:paint(ui.get(log_time),text)
    elseif ui.get(style) == 'default' then
        notify:paint(ui.get(log_time),string.format('✔ Hit %s in the %s for %s',name,group,e.damage))
    elseif ui.get(style) == 'Seripk' then
        notify:paint(ui.get(log_time),string.format('✔ Hit %s in the %s for %s',name,group,e.damage))
    end
    
end

client.set_event_callback("aim_miss", aim_miss)
client.set_event_callback('aim_hit', aim_hit)

