local entity = require("gamesense/entity")
local slider_sequence = ui.new_slider("Lua", "B", "sequence value", 0, 272, true)
local slider_cycle = ui.new_slider("Lua", "B", "cycle value", 0, 9, true, 0.1)

client.set_event_callback("pre_render", function()
    lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end
    anim_layer = lp:get_anim_overlay(0);
    anim_layer_second = lp:get_anim_overlay(4);
    anim_layer.sequence = ui.get(slider_sequence);
    anim_layer.cycle = ui.get(slider_cycle)/10;
    anim_layer_second.sequence = ui.get(slider_sequence);
    anim_layer_second.cycle = ui.get(slider_cycle)/10;
end)