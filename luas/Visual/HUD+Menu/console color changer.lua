local enabled = ui.new_checkbox("misc", "settings", "Enable console color")
local recolor_console = ui.new_color_picker("misc", "settings", "Console color picker", 255,255,255,255)

local materials = { "vgui_white", "vgui/hud/800corner1", "vgui/hud/800corner2", "vgui/hud/800corner3", "vgui/hud/800corner4" }

client.set_event_callback("paint", function()
    local r, g, b, a = 255, 255, 255, 255

    if (ui.get(enabled) == true) then
        r, g, b, a = ui.get(recolor_console)
    end

    for i=1, #materials do 
        local mat = materials[i]

        materialsystem.find_material(mat):alpha_modulate(a)
        materialsystem.find_material(mat):color_modulate(r, g, b)
    end
end)