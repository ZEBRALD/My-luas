local vector = require("vector")
local Fakelag = {
	FakelagOptions = ui.new_multiselect("AA", "Fake Lag", "\aA8A5F1FF£\aFFFFFFCE Options", {"Force Choked", "Break LC In Air", "Reset OS", "Optimize Modifier", "Force Discharge Scan"}),
	FakelagAmount = ui.new_combobox("AA", "Fake Lag", "Fakelag Amount", {"Dynamic", "Maximum", "Fluctuate"}),
	FakelagVariance = ui.new_slider("AA", "Fake Lag", "Fakelag Variance", 0, 100, 0, true, "%"),
	FakelagLimit = ui.new_slider("AA", "Fake Lag", "Fakelag Limit", 1, 17, 14),
	FakelagResetonshotStyle = ui.new_combobox("AA", "Fake Lag", "Reset On Shot", {"Default", "Safest", "Extended"})
}

local OverrideProcessticks = false;
local ShotFakelagReset = false;
local RestoredMaxProcessTicks = false;
local body_yaw = {ui.reference("AA", "Anti-aimbot angles", "Body yaw")}
local doubletap = {ui.reference("RAGE", "Aimbot", "Double tap")}
local fake_duck = ui.reference("RAGE", "Other", "Duck peek assist")
local onshot = {ui.reference("AA", "Other", "On shot anti-aim")}
local usrcmdprocessticks =  ui.reference("Misc", "Settings", "sv_maxusrcmdprocessticks2")
local usrcmdprocessticks_holdaim = ui.reference("Misc", "Settings", "sv_maxusrcmdprocessticks_holdaim")
local Contains = function(tab, this)
	for _, data in pairs(tab) do
		if data == this then
			return true
		end
	end

	return false
end 

local fakelag_limit = ui.reference("AA", "Fake lag", "Limit")
local fakelag_amount = ui.reference("AA", "Fake lag", "Amount")
local fakelag_variance = ui.reference("AA", "Fake lag", "Variance")
local fakelag_reference = ui.reference("AA", "Fake lag", "Enabled")
local ExtrapolatePosition = function(player, origin, ticks)
	local x, y, z = entity.get_prop(player, "m_vecVelocity")
	local vecVelocity = vector(
		x * globals.tickinterval() * ticks,
		y * globals.tickinterval() * ticks,
		z * globals.tickinterval() * ticks
	)

	return origin + vecVelocity
end

client.set_event_callback("setup_command", function(e)
	local local_player = entity.get_local_player()
	if not entity.is_alive(local_player) then
		if RestoredMaxProcessTicks then
			RestoredMaxProcessTicks = false
			ui.set(usrcmdprocessticks, 16)
			ui.set(usrcmdprocessticks_holdaim, true)
		end

		if ShotFakelagReset then
			ShotFakelagReset = false
			ui.set(body_yaw[1], "Static")
		end

		return
	end

	local OnPeekTrigger = false
	local Weapon = entity.get_player_weapon(local_player)
	local Jumping =  bit.band(entity.get_prop(local_player, "m_fFlags"), 1) == 0
	local Velocity = vector(entity.get_prop(local_player, "m_vecVelocity")):length2d()


	local FakeDuck = ui.get(fake_duck)


	local FakelagLimit = ui.get(Fakelag.FakelagLimit)
	local FakelagAmount = ui.get(Fakelag.FakelagAmount)
	local FakelagVariance = ui.get(Fakelag.FakelagVariance)
	local FakelagonshotStyle = ui.get(Fakelag.FakelagResetonshotStyle)
	local onshot = ui.get(onshot[1]) and ui.get(onshot[2]) and not FakeDuck
	local DoubleTap = ui.get(doubletap[1]) and ui.get(doubletap[2]) and not FakeDuck
	if Contains(ui.get(Fakelag.FakelagOptions), "Optimize Modifier") and not onshot and not DoubleTap then
		local EyePosition = ExtrapolatePosition(local_player, vector(client.eye_position()), 14)
		for _, ptr in pairs(entity.get_players(true)) do
			if entity.is_alive(ptr) then
				local TargetPosition = vector(entity.get_origin(ptr))
				local Fraction, _ = client.trace_line(local_player, EyePosition.x, EyePosition.y, EyePosition.z, TargetPosition.x, TargetPosition.y, TargetPosition.z)
				local _, Damage = client.trace_bullet(ptr, EyePosition.x, EyePosition.y, EyePosition.z, TargetPosition.x, TargetPosition.y, TargetPosition.z)
				if Damage > 0 and Fraction < 0.8 then
					OnPeekTrigger = true
					break
				end
			end
		end

		if OnPeekTrigger then
			FakelagLimit = math.random(14,16)
			FakelagVariance = 27
			FakelagAmount = "Maximum"
		elseif Velocity > 20 and not Jumping then
			FakelagLimit = math.random(14,16)
			FakelagVariance = 24
			FakelagAmount = "Maximum"
		elseif Jumping then
			FakelagLimit = math.random(14,16)
			FakelagVariance = 39
			FakelagAmount = "Maximum"
		end
	end

	if Contains(ui.get(Fakelag.FakelagOptions), "Break LC In Air") and Jumping and not onshot and not DoubleTap then
		FakelagVariance = math.random(21,28)
		FakelagAmount = "Fluctuate"
	end

	if Contains(ui.get(Fakelag.FakelagOptions), "Reset OS") and Weapon and not FakeDuck and not onshot and not DoubleTap then
		local LastShotTimer = entity.get_prop(Weapon, "m_fLastShotTime")
		local EyePosition = ExtrapolatePosition(local_player, vector(client.eye_position()), 14)
		if math.abs(toticks(globals.curtime() - LastShotTimer)) < 6 then
			local BreakLC = false
			for _, ptr in pairs(entity.get_players(true)) do
				if entity.is_alive(ptr) then
					local TargetPosition = vector(entity.get_origin(ptr))
					local _, Damage = client.trace_bullet(ptr, EyePosition.x, EyePosition.y, EyePosition.z, TargetPosition.x, TargetPosition.y, TargetPosition.z)
					if Damage > 0 then
						BreakLC = true
						break	
					end
				end
			end

			if BreakLC then
				FakelagVariance = 26
				FakelagAmount = "Fluctuate"
			end
		end

		if math.abs(toticks(globals.curtime() - LastShotTimer)) < (FakelagonshotStyle == "Default" and 3 or FakelagonshotStyle == "Safest" and 4 or 5) then
			FakelagLimit = 1
			e.no_choke = true
			ShotFakelagReset = true
			ui.set(body_yaw[1], "Off")
			ui.set(usrcmdprocessticks_holdaim, false)
		elseif ShotFakelagReset then
			ShotFakelagReset = false
			ui.set(body_yaw[1], "Static")
			ui.set(usrcmdprocessticks_holdaim, true)
		end

	elseif ShotFakelagReset then
		ShotFakelagReset = false
		ui.set(body_yaw[1], "Static")
		ui.set(usrcmdprocessticks_holdaim, true)
	end

	if FakeDuck or onshot or (DoubleTap and DoubleTapBoost == "Off") then
		FakelagLimit = 15
		FakelagVariance = 0
		OverrideProcessticks = true
		ui.set(usrcmdprocessticks, 16)
	elseif not FakeDuck and not onshot and not DoubleTap and OverrideProcessticks then
		OverrideProcessticks = false
		if FakelagLimit > (ui.get(usrcmdprocessticks) - 1) then
			ui.set(usrcmdprocessticks, FakelagLimit + 1)
		end
	end

	if Contains(ui.get(Fakelag.FakelagOptions), "Force Choked") and not Jumping and not onshot and not DoubleTap then
		e.allow_send_packet = e.chokedcommands >= FakelagLimit
	end

	RestoredMaxProcessTicks = true
	ui.set( fakelag_reference, true)
	ui.set( fakelag_amount, FakelagAmount)
	ui.set( fakelag_variance, FakelagVariance)
	ui.set( fakelag_limit, math.min(math.max(FakelagLimit, 1), ui.get(usrcmdprocessticks) - 1))
end)