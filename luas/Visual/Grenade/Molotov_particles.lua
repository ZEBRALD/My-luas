local find_material = materialsystem.find_material
local ui_set, ui_get, ui_reference, ui_set_visible, ui_set_callback = ui.set, ui.get, ui.reference, ui.set_visible, ui.set_callback
 
local enabled, ref_no_smoke
 
local materials = {
    "particle/fire_burning_character/fire_env_fire_depthblend_oriented",
    "particle/fire_burning_character/fire_burning_character",
    "particle/fire_explosion_1/fire_explosion_1_oriented",
    "particle/fire_explosion_1/fire_explosion_1_bright",
    "particle/fire_burning_character/fire_burning_character_depthblend",
    "particle/fire_burning_character/fire_env_fire_depthblend",
}
 
local function on_molotov_detonate(e)
    for _, v in pairs(materials) do
        local molotov = find_material(v)
        if molotov ~= nil then
            molotov:set_material_var_flag(2, false)    -- nodraw flag
            molotov:set_material_var_flag(28, true)    -- wireframe flag
        end
    end
end
 
 
local function on_enabled(ref)
    local state = ui_get(ref)
    local set_callback = state and client.set_event_callback or client.unset_event_callback
    set_callback("molotov_detonate", on_molotov_detonate)
end
 
local function main()
    enabled = ui.new_checkbox("Visuals", "Effects", "Wireframe molotov")
    on_enabled(enabled)
    ui_set_callback(enabled, on_enabled)
end
 
main()