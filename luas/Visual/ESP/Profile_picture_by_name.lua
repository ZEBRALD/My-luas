local vector = require 'vector'
local images = require 'gamesense/images'

local tab, container = 'VISUALS', 'Player ESP'
local reference = {
	teammates = ui.reference(tab, container, 'Teammates')
}
local interface = {
	enabled = ui.new_checkbox(tab, container, 'Profile picture'),
	side = ui.new_combobox(tab, container, '\n', 'Left', 'Right'),
}

local get_players = function(only_enemies)
	local result = {}

	local maxplayers = globals.maxplayers()
	local player_resource = entity.get_player_resource()

	for player = 1, maxplayers do
		local enemy = entity.is_enemy(player)
		local alive = entity.is_alive(player)

		if (not only_enemies or enemy) and alive then
			table.insert(result, player)
		end
	end

	return result
end

local on_paint = function()
	local players = get_players(not ui.get(reference.teammates))

	local side = ui.get(interface.side) == 'Left'

	for i=1, #players do
		local player = players[i]

		local x1, y1, x2, y2, alpha_multiplier = entity.get_bounding_box(player)

		if x1 and alpha_multiplier > 0 then
			local steamid3 = entity.get_steam64(player) --liar
			local avatar = images.get_steam_avatar(steamid3)

			if avatar then
				local pos = vector(x1/2 + x2/2, y1 - 7)
				local name = entity.get_player_name(player)
				local size = vector(renderer.measure_text('c', name))
				local offset = side and (- size.x/2 - 15) or (size.x/2 + 2)

				avatar:draw(pos.x + offset, pos.y - size.y/2, nil, size.y)
			end
		end
	end
end

local handle_callbacks = function(self)
	local handle = ui.get(self) and client.set_event_callback or client.unset_event_callback
	handle('paint', on_paint)
end

handle_callbacks(interface.enabled)
ui.set_callback(interface.enabled, handle_callbacks)