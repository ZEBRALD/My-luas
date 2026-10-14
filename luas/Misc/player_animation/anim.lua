local master_switch = ui.new_checkbox('AA', 'Other', 'leg animation')
local anim_type = ui.new_combobox('AA', 'Other', 'animation type', 'Random', 'Constant')
local anim_slider = ui.new_slider('AA', 'Other', 'Value', 0, 10, 0, true, '%', 0.1)


local ref = {
    leg_movement = ui.reference('AA', 'Other', 'Leg movement')
}

local anim_breaker = {}

anim_breaker.pre_render = function()
    local local_player = entity.get_local_player()
    if not entity.is_alive(local_player) then return end

    if ui.get(anim_type) == 'Random' then
        entity.set_prop(local_player, "m_flPoseParameter", client.random_float(ui.get(anim_slider)/10, 1), 0)
        ui.set(ref.leg_movement, client.random_int(1, 2) == 1 and "Off" or "Always slide")
    elseif ui.get(anim_type) == 'Constant' then
        entity.set_prop(local_player, 'm_flPoseParameter', 1, globals.chokedcommands() % 7 == 0 and 1 or 0)
    end
end

anim_breaker.setup_command = function(e)
    local local_player = entity.get_local_player()
    if not entity.is_alive(local_player) then return end

    ui.set(ref.leg_movement, 'Always slide')
end

local ui_callback = function(c)
    local enabled, addr = ui.get(c), ''

    if not enabled then
        addr = 'un'
    end
    
    local _func = client[addr .. 'set_event_callback']

    _func('pre_render', anim_breaker.pre_render)
    _func('setup_command', anim_breaker.setup_command)
end

ui.set_callback(master_switch, ui_callback)
ui_callback(master_switch)