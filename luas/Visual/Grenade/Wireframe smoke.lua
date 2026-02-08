local find_material = materialsystem.find_material
local ui_set, ui_get, ui_reference, ui_set_visible, ui_set_callback = ui.set, ui.get, ui.reference, ui.set_visible, ui.set_callback

local enabled, ref_no_smoke

local materials = {
    "particle/vistasmokev1/vistasmokev1_fire",
    "particle/vistasmokev1/vistasmokev1_smokegrenade",
    "particle/vistasmokev1/vistasmokev1_emods",
    "particle/vistasmokev1/vistasmokev1_emods_impactdust"
}

local function on_smokegrenade_detonate(e)
    for _, v in pairs(materials) do
        local smoke = find_material(v)
        if smoke ~= nil then
            smoke:set_material_var_flag(2, false)    -- nodraw flag
            smoke:set_material_var_flag(28, true)    -- wireframe flag
        end
    end
end


local function on_enabled(ref)
    local state = ui_get(ref)
    local set_callback = state and client.set_event_callback or client.unset_event_callback

    ui_set_visible(ref_no_smoke, not state)
    ui_set(ref_no_smoke, not state)
    set_callback("smokegrenade_detonate", on_smokegrenade_detonate)
end

local function main()
    enabled = ui.new_checkbox("Visuals", "Effects", "Wireframe smoke grenades")
    ref_no_smoke = ui_reference("Visuals", "Effects", "Remove smoke grenades")

    on_enabled(enabled)
    ui_set_callback(enabled, on_enabled)
end

main()