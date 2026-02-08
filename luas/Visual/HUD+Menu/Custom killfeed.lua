local images = require "gamesense/images"

local tab, container = "LUA", "B"

local gui = {
    main = ui.new_checkbox(tab, container, "activate killfeed"),
    text1 = ui.new_label(tab, container, "accent"),
    accent = ui.new_color_picker(tab, container, "\n", 227, 181, 255, 155),
    text2 = ui.new_label(tab, container, "ct accent"),
    ct_color = ui.new_color_picker(tab, container, "\n\n\n", 204, 204, 255, 155),
    text3 = ui.new_label(tab, container, "t accent"),
    t_color = ui.new_color_picker(tab, container, "\n\n\n\n", 255, 204, 204, 155),
    box_scale = ui.new_slider(tab, container, "box scale", 0, 100, 100, true, "%", 1, nil),
    max_logs = ui.new_slider(tab, container, "max logs", 4, 20, 0, true, "", 1, {[4] = "∞"}),
    max_time = ui.new_slider(tab, container, "max time", 0, 30, 0, true, "s", 1, {[0] = "∞"})
}

local cl_drawhud_force_deathnotices = cvar.cl_drawhud_force_deathnotices

local function set_visible()

    local main = ui.get(gui.main)

    ui.set_visible(gui.accent, main)
    ui.set_visible(gui.ct_color, main)
    ui.set_visible(gui.t_color, main)
    ui.set_visible(gui.text1, main)
    ui.set_visible(gui.text2, main)
    ui.set_visible(gui.text3, main)
    ui.set_visible(gui.box_scale, main)
    ui.set_visible(gui.max_logs, main)
    ui.set_visible(gui.max_time, main)

    cl_drawhud_force_deathnotices:set_int(main and -1 or 0)

end

set_visible()

ui.set_callback(gui.main, set_visible)

local data = {
    logs = {}
}

local hud_scaling = cvar.hud_scaling
local safezonex = cvar.safezonex
local safezoney = cvar.safezoney

client.set_event_callback("player_death", function(e)

    local me = entity.get_local_player()
   
    local attacker = client.userid_to_entindex(e.attacker)

    local target = client.userid_to_entindex(e.userid)

    if attacker ~= me and target ~= me then
        return
    end

    table.insert(data.logs, {
        attacker = entity.get_player_name(attacker),
        target = entity.get_player_name(target),
        hs = e.headshot,
        assister = entity.get_player_name(client.userid_to_entindex(e.assister)),
        penetrated = e.penetrated,
        noscope = e.noscope,
        weapon = "weapon_" .. e.weapon,
        time = globals.curtime(),
        teams = {
            entity.get_prop(target, "m_iTeamNum"),
            entity.get_prop(attacker, "m_iTeamNum")
        }
    })

end)

client.set_event_callback("paint", function()

    if not ui.get(gui.main) then
        return
    end

    local me = entity.get_local_player()

    local x, y = client.screen_size()

    local scale = 0.45

    local max_logs = ui.get(gui.max_logs)

    local max_time = ui.get(gui.max_time)

    local r, g, b, a = ui.get(gui.accent)

    local safezone = {
        x = safezonex:get_float(),
        y = safezoney:get_float()
    }

    local padding = {
        x = -5,
        y = 40
    }

    local headshot_image = images.get_panorama_image("hud/deathnotice/icon_headshot.svg")

    local wallbang_image = images.get_panorama_image("hud/deathnotice/penetrate.svg")

    local noscope_image = images.get_panorama_image("hud/deathnotice/noscope.svg")

    local suicide_image = images.get_panorama_image("hud/deathnotice/icon_suicide.svg")
   
    for i, shot in ipairs(data.logs) do

        local alpha = math.min((globals.curtime() - shot.time)/(max_time / 5),1)

        if max_time == 0 then

            alpha = math.min((globals.curtime() - shot.time)*2,1)

        end

        local xoffset = (18 + 8) * (i - 1)

        local attacker_string = shot.attacker .. ((shot.assister == "unknown") and "" or (" + " .. shot.assister))

        local attacker_size = renderer.measure_text(nil, attacker_string)

        local size = attacker_size + 4

        if shot.hs then

            local w, h = headshot_image:measure()

            size = size + w*scale

        end

        if shot.penetrated > 0 then

            local w, h = wallbang_image:measure()

            size = size + w*scale

        end

        if shot.noscope then

            local w, h = noscope_image:measure()

            size = size + w * scale 

        end

        if shot.target == shot.attacker then

            local w, h = suicide_image:measure()

            size = size + w*scale
            
        else

            local weapon_icon = images.get_weapon_icon(shot.weapon)

            local w, h = weapon_icon:measure()

            size = size + w*scale + 2

        end

        local target_size = renderer.measure_text("", shot.target)

        size = size + target_size + 8

        -- actual rendering

        renderer.gradient(x/2 + (x/2 * safezone.x) + padding.x - (size * alpha * ui.get(gui.box_scale)/100), y/2 * (1 - safezone.y) + padding.y - 2 + xoffset, size * alpha * ui.get(gui.box_scale)/100, 18, r, g, b, 0, r, g, b, a, true)

        local offset = 4

        local r, g, b, a = 200, 200, 200, 255

        if shot.teams[1] == 3 then -- ct

            r, g, b, a = ui.get(gui.ct_color)

        elseif shot.teams[1] == 2 then

            r, g, b, a = ui.get(gui.t_color)

        end

        renderer.text(x/2 + (x/2 * safezone.x) + padding.x - offset, y/2 * (1 - safezone.y) + padding.y + xoffset, r, g, b, a * alpha, "r", 0, shot.target)

        offset = offset + 2

        if shot.hs then

            local w, h = headshot_image:measure()

            headshot_image:draw(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size - w*scale, y/2 * (1 - safezone.y) + padding.y + xoffset, w*scale, h*scale , 255, 255, 255, 255 * alpha, true)

            offset = offset + w*scale

        end

        if shot.penetrated > 0 then

            local w, h = wallbang_image:measure()

            wallbang_image:draw(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size - w*scale, y/2 * (1 - safezone.y) + padding.y + xoffset, w*scale, h*scale , 255, 255, 255, 255 * alpha, true)

            offset = offset + w*scale

        end

        if shot.noscope then

            local w, h = noscope_image:measure()

            noscope_image:draw(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size - w*scale, y/2 * (1 - safezone.y) + padding.y + xoffset, w*scale, h*scale , 255, 255, 255, 255 * alpha, true)

            offset = offset + w*scale

        end

        if shot.target == shot.attacker then

            local w, h = suicide_image:measure()

            suicide_image:draw(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size - w*scale, y/2 * (1 - safezone.y) + padding.y + xoffset, w*scale, h*scale , 255, 255, 255, 255 * alpha, true)

            offset = offset + w*scale + 2
            
        else

            local weapon_icon = images.get_weapon_icon(shot.weapon)

            local w, h = weapon_icon:measure()
        
            weapon_icon:draw(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size - w*scale, y/2 * (1 - safezone.y) + padding.y + xoffset, w*scale, h*scale , 255, 255, 255, 255 * alpha, true)

            offset = offset + w*scale + 4

        end

        if shot.teams[2] == 3 then -- ct

            r, g, b, a = ui.get(gui.ct_color)

        elseif shot.teams[2] == 2 then

            r, g, b, a = ui.get(gui.t_color)

        end

        renderer.text(x/2 + (x/2 * safezone.x) + padding.x - offset - target_size , y/2 * (1 - safezone.y) + padding.y + xoffset, r, g, b, a * alpha, "r", 0, attacker_string)

        if max_logs ~= 4 and #data.logs > max_logs then

            table.remove(data.logs, i)

        end

        if max_time ~= 0 and shot.time + max_time - globals.curtime() <= 0 then

            table.remove(data.logs, i)

        end

    end

end)

client.set_event_callback("round_start", function()
   
    data.logs = {}

end)