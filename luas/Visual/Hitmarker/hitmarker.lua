local client_log = client.log
local client_set_event_callback = client.set_event_callback
local client_timestamp = client.timestamp
local client_userid_to_entindex = client.userid_to_entindex

local renderer_world_to_screen = renderer.world_to_screen
local renderer_line = renderer.line
local renderer_circle = renderer.circle
local renderer_circle_outline = renderer.circle_outline
local renderer_rectangle = renderer.rectangle

local table_insert = table.insert 
local table_remove = table.remove

local entity_get_local_player = entity.get_local_player

local ui_set_callback = ui.set_callback
local ui_get = ui.get
local ui_set_visible = ui.set_visible
local ui_new_checkbox = ui.new_checkbox
local ui_new_slider = ui.new_slider
local ui_new_color_picker = ui.new_color_picker
local ui_new_combobox = ui.new_combobox

local list = { "Default", "Ratio", "Circle", "Circle Outline", "Cross", }

local hitmark_enable = ui_new_checkbox("VISUALS", "Player ESP", "World Hitmarker")
local hitmark_combo = ui_new_combobox("VISUALS", "Player ESP", "World Hitmarker Style", list)
local hitmark_color = ui_new_color_picker("VISUALS", "Player ESP", "World Hitmarker Color", 0, 25, 255, 255)
local hitmark_time = ui_new_slider("VISUALS", "Player ESP", "World Hitmarker Time", 0, 5000, 850, true, "ms")
local hitmark_legnth = ui_new_slider("VISUALS", "Player ESP", "Hitmarker Size", 0, 15, 9, true, "")
local hitmark_thicc = ui_new_slider("VISUALS", "Player ESP", "Hitmarker Thiccness", 0, 10, 2, true, "")

local hitmarkenable, hitmarkcombo, r, g, b, a, hitmarktime, hitmarksize, hitmarkthicc

local function menu()
	hitmarkenable = ui_get(hitmark_enable)
	hitmarkcombo = ui_get(hitmark_combo)
	r, g, b, a = ui_get(hitmark_color)
	hitmarktime = ui_get(hitmark_time)
	hitmarksize = ui_get(hitmark_legnth)
	hitmarkthicc = ui_get(hitmark_thicc)
	
	ui_set_visible(hitmark_color, hitmarkenable)
	ui_set_visible(hitmark_time, hitmarkenable)
	ui_set_visible(hitmark_legnth, hitmarkenable)
	ui_set_visible(hitmark_thicc, hitmarkenable)
	ui_set_visible(hitmark_combo, hitmarkenable)
end

ui_set_callback(hitmark_enable, menu)
ui_set_callback(hitmark_combo, menu)
ui_set_callback(hitmark_color, menu)
ui_set_callback(hitmark_time, menu)
ui_set_callback(hitmark_legnth, menu)
ui_set_callback(hitmark_thicc, menu)

menu()

local dt = {}
local function on_paint()
	if hitmarkenable then	
		if hitmarkcombo == "Circle" or hitmarkcombo == "Default" then
			ui_set_visible(hitmark_thicc, false)
		else
			ui_set_visible(hitmark_thicc, hitmarkenable)
		end
		if #dt ~= 0 then
			for i = 1, #dt do
				if dt[i] ~= nil then
					if client_timestamp() - dt[i][4] > ui_get(hitmark_time) then
						table_remove(dt, i)
						i = i - 1
					end
				end
			end
			for i = 1, #dt do
				local x, y, z, time = dt[i][1], dt[i][2], dt[i][3], dt[i][4]
				local sx, sy = renderer_world_to_screen(x, y, z)
				if sx ~= nil and sy ~= nil then
					if hitmarkcombo == "Default" then
						local f1, f2 = 2, hitmarksize
						renderer.line(sx+f1, sy-f1, sx+f2, sy-f2, r, g, b, a)--1
						renderer.line(sx-f1, sy-f1, sx-f2, sy-f2, r, g, b, a)--2
						renderer.line(sx-f1, sy+f1, sx-f2, sy+f2, r, g, b, a)--3
						renderer.line(sx+f1, sy+f1, sx+f2, sy+f2, r, g, b, a)--4
					end
					if hitmarkcombo == "Ratio" then
						for j=1, 4 do
							renderer_circle(sx, sy, r, g, b, a, hitmarksize, (j*90)+43, hitmarkthicc / 100)
						end
					end
					if hitmarkcombo == "Circle" then
						renderer_circle(sx, sy, r, g, b, a, hitmarksize, 0, 1)
					end
					if hitmarkcombo == "Circle Outline" then
						renderer_circle_outline(sx, sy, r, g, b, a, hitmarksize, 0, 1, hitmarkthicc)
					end
					if hitmarkcombo == "Cross" then
						renderer_rectangle(sx-hitmarkthicc, sy-hitmarksize, hitmarkthicc*2, hitmarksize*2, r, g, b, a)--  |
						renderer_rectangle(sx-hitmarksize, sy-hitmarkthicc, hitmarksize*2, hitmarkthicc*2, r, g, b, a)--  -
					end
				end
			end
		end
	end
end

local function on_bullet_impact(e)
	if ui_get(hitmark_enable) then
		if client_userid_to_entindex(e.userid) == entity_get_local_player() then
			table_insert(dt, {e.x, e.y, e.z, client_timestamp()})
		end
	end
end

client_set_event_callback("paint", on_paint)
client_set_event_callback("bullet_impact", on_bullet_impact)