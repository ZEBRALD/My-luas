local gif_decoder = require "gamesense/gif_decoder"
local start_time = globals.realtime()

local client_log = client.log
local client_set_event_callback = client.set_event_callback
local client_timestamp = client.timestamp
local client_userid_to_entindex = client.userid_to_entindex

local renderer_world_to_screen = renderer.world_to_screen

local math_floor = math.floor
local math_huge = math.huge
local math_sqrt = math.sqrt
local math_random = math.random

local table_insert = table.insert 
local table_remove = table.remove

local entity_get_local_player = entity.get_local_player
local entity_get_prop = entity.get_prop

local ui_set_callback = ui.set_callback
local ui_get = ui.get
local ui_set_visible = ui.set_visible
local ui_new_checkbox = ui.new_checkbox
local ui_new_slider = ui.new_slider
local ui_new_color_picker = ui.new_color_picker
local ui_new_combobox = ui.new_combobox

--------------------------------------
--   Custom Font Hitmarker Thingy   --
--	       By Bassn / hitome56      --
--------------------------------------

local animlist = { "Up", "Down", "Left", "Right", "Random Angle" }
local fontlist = { "BitPap", "Comic", "DoomzDay", "Reglisse", "MoonCheese", "Custom" }

local pogu_enable = ui_new_checkbox("VISUALS", "Player ESP", "PogU Damage Marker")
local pogu_color = ui_new_color_picker("VISUALS", "Player ESP", "PogU Color", 0, 25, 255, 255)
local pogu_font = ui_new_combobox("VISUALS", "Player ESP", "Font", fontlist)
local pogu_enableanimated = ui_new_checkbox("VISUALS", "Player ESP", "Animated")
local pogu_animated = ui_new_combobox("VISUALS", "Player ESP", "Animated", animlist)
local pogu_animspeed = ui_new_slider("VISUALS", "Player ESP", "Animate Speed", 0, 20, 5, true, "px")
local pogu_size = ui_new_slider("VISUALS", "Player ESP", "Size", 1, 15, 15, true, "")
local pogu_time = ui_new_slider("VISUALS", "Player ESP", "Time", 0, 3000, 1000, true, "ms")
local pogu_fading = ui_new_slider("VISUALS", "Player ESP", "Fadeing", 1, 15, 5, true)

local function menu()
	poguenable = ui_get(pogu_enable)
	r, g, b, a = ui_get(pogu_color)
	pogufont = ui_get(pogu_font)
	poguenableanimated = ui_get(pogu_enableanimated)
	poguanimated = ui_get(pogu_animated)
	poguanimspeed = ui_get(pogu_animspeed)
	pogusize = ui_get(pogu_size)
	pogutime = ui_get(pogu_time)
	pogufading = ui_get(pogu_fading)

	ui_set_visible(pogu_font, poguenable)
	ui_set_visible(pogu_enableanimated, poguenable)
	ui_set_visible(pogu_animated, poguenable)
	ui_set_visible(pogu_animspeed, poguenable)
	ui_set_visible(pogu_size, poguenable)
	ui_set_visible(pogu_time, poguenable)
	ui_set_visible(pogu_fading, poguenable)
end

ui_set_callback(pogu_enable, menu)
ui_set_callback(pogu_font, menu)
ui_set_callback(pogu_color, menu)
ui_set_callback(pogu_enableanimated, menu)
ui_set_callback(pogu_animated, menu)
ui_set_callback(pogu_animspeed, menu)
ui_set_callback(pogu_size, menu)
ui_set_callback(pogu_time, menu)
ui_set_callback(pogu_fading, menu)

menu()

local preshots = {}
local shots = {}

local function on_paint()
	if pogu_enable then
		if #shots ~= 0 then
			for i = 1, #shots do
				if shots[i] ~= nil then
					if client_timestamp() - shots[i][4] > pogutime then
						table_remove(shots, i)
						i = i - 1
					end
				end
			end
			for i = 1, #shots do
				local x = shots[i][1]
				local y = shots[i][2]
				local z = shots[i][3]
				local time = shots[i][4]
				local damage = shots[i][5]
				local damageS = tostring(damage)
				local alive = shots[i][6]
				local slideX = shots[i][8] 
				local slideY = shots[i][9] 
				local sx, sy = renderer_world_to_screen(x, y, z)
				local alpha = a - a * ((client_timestamp() - time)^pogufading / pogutime^pogufading)
				local skoot = 0
				local skoot2 = 0
				if sx ~= nil and sy ~= nil then
					for j = 1, #damageS do
						local ratio = pogusize / 30
						local num = damageS:sub(j,j)
						local numPic = gif_decoder.load_gif(readfile("CustomFont/" .. pogufont .. "/" .. num ..".gif") or error("file " .. num .." doesn't exist"))
						resizeX, resizeY = numPic.width*ratio, numPic.height*ratio
						skoot2 = skoot2 + resizeX / 2		
					end
					for j = 1, #damageS do
						local num = damageS:sub(j,j)
						local ratio = pogusize / 30

						local numPic = gif_decoder.load_gif(readfile("CustomFont/" .. pogufont .. "/" .. num ..".gif") or error("file " .. num .." doesn't exist"))
						resizeX, resizeY = numPic.width*ratio, numPic.height*ratio
                        numPic:drawframe(1,sx+skoot-skoot2+slideX,sy-slideY,resizeX,resizeY, r, g, b, alpha)

						skoot = skoot + resizeX
						if     poguanimated == "Right"    then shots[i][8] = slideX + (poguanimspeed / 5)
						elseif poguanimated == "Left"  then shots[i][8] = slideX - (poguanimspeed / 5)
						elseif poguanimated == "Down"  then shots[i][9] = slideY - (poguanimspeed / 5)
						elseif poguanimated == "Up" then shots[i][9] = slideY + (poguanimspeed / 5)
						elseif poguanimated == "Random Angle" then
							if shots[i][10] == 1 then 
								shots[i][8] = slideX + (poguanimspeed / 5)--Up
								shots[i][9] = slideY - (poguanimspeed / 5)--Left
							elseif shots[i][10] == 2 then 
								shots[i][8] = slideX + (poguanimspeed / 5)--Up
								shots[i][9] = slideY + (poguanimspeed / 5)--Right
							elseif shots[i][10] == 3 then 
								shots[i][8] = slideX - (poguanimspeed / 5)--Down
								shots[i][9] = slideY - (poguanimspeed / 5)--Left
							elseif shots[i][10] == 4 then 
								shots[i][8] = slideX - (poguanimspeed / 5)--Down
								shots[i][9] = slideY + (poguanimspeed / 5)--Right
							end
						end
					end
				end
			end		
		end
	end
end

local function on_player_hurt(e)
	if poguenable then
		if client_userid_to_entindex(e.attacker) == entity_get_local_player() then
			if e.weapon == "inferno" then
				local targetX, targetY, targetZ = entity_get_prop(client_userid_to_entindex(e.userid), "m_vecOrigin")
				table_insert(shots, {targetX, targetY, targetZ, client_timestamp(), e.dmg_health, e.health > 0, client_userid_to_entindex(e.userid), 0, 0, math_random(1,4) })
			else
				if #preshots ~= 0 then
					local best = math_huge
					local result = -1
					local targetX, targetY, targetZ = entity_get_prop(client_userid_to_entindex(e.userid), "m_vecOrigin")
					targetZ = targetZ + 38
					for i = 1, #preshots do
						local impactX, impactY, impactZ = preshots[i][1], preshots[i][2], preshots[i][3]
						local dist = (targetX - impactX)^2 + (targetY - impactY)^2 + (targetZ - impactZ)^2
						dist = math_sqrt(dist)
						if dist < best then
							best = dist
							result = i
						end
					end
					if result ~= -1 then	
						table_insert(shots, {preshots[result][1], preshots[result][2], preshots[result][3], client_timestamp(), e.dmg_health, e.health > 0, client_userid_to_entindex(e.userid), 0, 0, math_random(1,4) })
					else
						local targetX, targetY, targetZ = entity_get_prop(client_userid_to_entindex(e.userid), "m_vecOrigin")
						table_insert(shots, {targetX, targetY, targetZ + 36, client_timestamp(), e.dmg_health, e.health > 0, client_userid_to_entindex(e.userid), 0, 0, math_random(1,4) })
					end
				else
					local targetX, targetY, targetZ = entity_get_prop(client_userid_to_entindex(e.userid), "m_vecOrigin")
					table_insert(shots, {targetX, targetY, targetZ + 36, client_timestamp(), e.dmg_health, e.health > 0, client_userid_to_entindex(e.userid), 0, 0, math_random(1,4) })
				end
			end
		end
	end
end

local function on_bullet_impact(e)
	if poguenable then
		if client_userid_to_entindex(e.userid) == entity_get_local_player() then		
			table_insert(preshots, {e.x, e.y, e.z})				
		end
	end
end

client_set_event_callback("paint", on_paint)
client_set_event_callback("player_hurt", on_player_hurt)
client_set_event_callback("bullet_impact", on_bullet_impact)

