local round = function(b) return math.floor(b + 0.5) end
local contains = function(b,c)for d=1,#b do if b[d]==c then return true end end;return false end

local tab, container = 'VISUALS', 'Player ESP'
local reference = {
    name = ui.reference(tab, container, 'Name')
}
local interface = {
    enabled = ui.new_checkbox(tab, container, 'Dormant last seen'),
    decrement = ui.new_color_picker(tab, container, 'Decrement', 255, 255, 255, 255),
    bounding = ui.new_color_picker(tab, container, 'Disappeared', 255, 255, 255, 255),
    options = ui.new_multiselect(tab, container, '\n', 'Decrement', 'Disappeared')
}

local get_players = function(enemies_only)
    local result = {}

    local maxplayers = globals.maxplayers()
    local player_resource = entity.get_player_resource()
    
	for player = 1, maxplayers do
        local enemy = entity.is_enemy(player)
        local alive = entity.get_prop(player_resource, 'm_bAlive', player)

        if (not enemy and enemies_only) or alive ~= 1 then goto skip end

        table.insert(result, player) 

        ::skip::
	end

	return result
end

local paint_box = function(x, y, w, h, r, g, b, a)
    renderer.rectangle(x + 1, y, w - 1, 1, r, g, b, a)
    renderer.rectangle(x + w - 1, y + 1, 1, h - 1, r, g, b, a)
    renderer.rectangle(x, y + h - 1, w - 1, 1, r, g, b, a)
    renderer.rectangle(x, y, 1, h - 1, r, g, b, a)
end

local on_paint = function()
    local local_player = entity.get_local_player()
    local is_alive = entity.is_alive(local_player)
    
    if not local_player or not is_alive then return end

    players = get_players(true)

    local name = ui.get(reference.name)
    local color = { 
        { ui.get(interface.decrement) },
        { ui.get(interface.bounding) }
    }
    local options = ui.get(interface.options)

    for i, player in pairs(players) do
        local box = { entity.get_bounding_box(player) }
        local height = name and 16 or 8
        local alpha, decrement = box[5]*255, round(box[5]*10)
        local is_dormant = entity.is_dormant(player)
        local is_alive = entity.is_alive(player)

        if box[1] and box[5] > 0 and is_dormant and contains(options, 'Decrement') and is_alive then
            renderer.text(box[1]/2 + box[3]/2, box[2] - height, color[1][1], color[1][2], color[1][3], alpha, 'cb', 0, string.format('DORMANT (%s0%%)', decrement))
        elseif box[1] and box[5] == 0 and is_dormant and contains(options, 'Disappeared') and is_alive then
            renderer.text(box[1]/2 + box[3]/2, box[2] - 8, color[2][1], color[2][2], color[2][3], color[2][4], 'cb', 0, 'LAST SEEN')
            paint_box(box[1] + 1, box[2] + 1, box[3] - box[1] - 2, box[4] - box[2] - 2, 0, 0, 0, color[2][4])
            paint_box(box[1], box[2], box[3] - box[1], box[4] - box[2], color[2][1], color[2][2], color[2][3], color[2][4])
            paint_box(box[1] - 1, box[2] - 1, box[3] - box[1] + 2, box[4] - box[2] + 2, 0, 0, 0, color[2][4])
        end
    end
end

local handle_callback = function(event)
	local handle = event and client.set_event_callback or client.unset_event_callback

	handle('paint', on_paint)
end

ui.set_callback(interface.enabled, function()
	local enabled = ui.get(interface.enabled)
	handle_callback(enabled)
end)