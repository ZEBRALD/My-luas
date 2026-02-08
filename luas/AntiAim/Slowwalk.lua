local ui_get, ui_set, ui_ref = ui.get, ui.set, ui.reference
local client_get_cvar, client_set_cvar = client.get_cvar, client.set_cvar
local ent_get_prop, ent_get_local = entity.get_prop, entity.get_local_player
local globals_curtime = globals.curtime
local globals_tickcount = globals.tickcount
local entity_get_player_weapon = entity.get_player_weapon
local interval_per_tick = globals.tickinterval
local entity_get_players = entity.get_players

local chkbox_nervoswalk = ui.new_checkbox("lua", "b", "Slow Walk")
local hotkey_nervoswalk = ui.new_hotkey("lua", "b", "Key")
local slider_nervoswalk = ui.new_slider("lua", "b", "Speed", 1, 245, 40, true, "%")

local function setSpeed(newSpeed)
	if newSpeed == 245 then
		return
	end
	local LocalPlayer = ent_get_local
	local vx, vy = ent_get_prop(LocalPlayer(), "m_vecVelocity")
	local velocity = math.floor(math.min(10000, math.sqrt(vx*vx + vy*vy) + 0.5))
	--client.log(velocity)
	local maxvelo = newSpeed

	if(velocity<maxvelo) then
		client_set_cvar("cl_sidespeed", maxvelo)
		client_set_cvar("cl_forwardspeed", maxvelo)
		client_set_cvar("cl_backspeed", maxvelo)
	end

	if(velocity>=maxvelo) then
		local kat=math.atan2(client_get_cvar("cl_forwardspeed"), client_get_cvar("cl_sidespeed"))
		local forward=math.cos(kat)*maxvelo;
		local side=math.sin(kat)*maxvelo;
		client_set_cvar("cl_sidespeed", side)
		client_set_cvar("cl_forwardspeed", forward)
		client_set_cvar("cl_backspeed", forward)
	end
end


client.set_event_callback("run_command", function ()
	if not ui_get(chkbox_nervoswalk) then
		return
	end

	if not ui_get(hotkey_nervoswalk) then
		setSpeed(450)
	else
		setSpeed(ui_get(slider_nervoswalk))
	end
end) 