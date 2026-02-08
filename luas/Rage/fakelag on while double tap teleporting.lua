dt = { ui.reference("RAGE", "Aimbot", "Double tap") }

local vars = {
    shot_time = 0,
}

client.set_event_callback('bullet_impact', function(e)
    vars.shot_time = globals.realtime()
    if client.userid_to_entindex(e.userid) ~= entity.get_local_player() then
        return
    end
    vars.shot_time = globals.realtime()
    if vars.shot_time and ui.get(dt[2]) == true then
        ui.set(dt[1] ,false)

    client.delay_call(0.20, function()
        ui.set(dt[1], true)
    end)
    end
end)