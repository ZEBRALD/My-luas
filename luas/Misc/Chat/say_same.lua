local ui_get = ui.get
local console_cmd = client.exec
local ui_new_checkbox = ui.new_checkbox

local say_same = ui_new_checkbox("Misc", "Miscellaneous", "Say same")
local function on_player_chat(e)
    if not ui_get(say_same) then return end
	if e.teamonly == false then
		console_cmd("say "..e.text)
	end
end

client.set_event_callback("player_chat", on_player_chat)