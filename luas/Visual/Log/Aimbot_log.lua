---for any question pls contect BaKa
local ffi = require("ffi")
ffi.cdef[[
typedef void***(__thiscall* FindHudElement_t)(void*, const char*);
typedef void(__cdecl* ChatPrintf_t)(void*, int, int, const char*, ...);
]]

local signature_gHud = "\xB9\xCC\xCC\xCC\xCC\x88\x46\x09"
local signature_FindElement = "\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x57\x8B\xF9\x33\xF6\x39\x77\x28"

local match = client.find_signature("client_panorama.dll", signature_gHud) or error("sig1 not found")
local hud = ffi.cast("void**", ffi.cast("char*", match) + 1)[0] or error("hud is nil")

match = client.find_signature("client_panorama.dll", signature_FindElement) or error("FindHudElement not found")
local find_hud_element = ffi.cast("FindHudElement_t", match)
local hudchat = find_hud_element(hud, "CHudChat") or error("CHudChat not found")

local chudchat_vtbl = hudchat[0] or error("CHudChat instance vtable is nil")
local print_to_chat = ffi.cast("ChatPrintf_t", chudchat_vtbl[27])
local function print_chat(text)
	print_to_chat(hudchat, 0, 0, text)
end
local misses = ui.new_checkbox("Rage", "Other", "修羅剣「現世妄執」 空槍日志")
local hits = ui.new_checkbox("Rage", "Other", "天界剣「七魄忌諱」 擊中日志")
local function on_aim_hit(e)
	if ui.get(hits) then

    local hitgroup_names = { "身體", "頭部", "胸部", "胃部", "胳膊", "胳膊", "腳", "腿", "脖子", "不知道", "gear" }
        local group = hitgroup_names[e.hitgroup + 1] or "?"

        local target_name = entity.get_player_name(e.target)
       
		local entityHealth = entity.get_prop(e.target, "m_iHealth")
        client.color_log(70,142,139,"✔ \0")
        client.color_log(255,255,255,"修羅剣\0")
        client.color_log(70,142,139,"「現世妄執」\0")
        client.color_log(213,213,213," 擊中 \0")
        client.color_log(70,142,139,string.lower(target_name).."\0")
        client.color_log(213,213,213," 的 \0")
        client.color_log(213,213,213,group.."\0")
        client.color_log(213,213,213," 剩余HP：\0")
        client.color_log(213,213,213,entityHealth.."\0")
        client.color_log(213,213,213," 命中率：\0")
        client.color_log(213,213,213,e.hit_chance)
    end
end

local function on_aim_miss(e)
	if ui.get(misses) and e ~= nil then

    local hitgroup_names = { "身體", "頭部", "胸部", "胃部", "胳膊", "胳膊", "腳", "腿", "脖子", "不知道", "gear" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local target_name = entity.get_player_name(e.target)
    local reason
	local entityHealth = entity.get_prop(e.target, "m_iHealth")
	if (entityHealth == nil) or (entityHealth <= 0) then
        client.color_log(70,142,139,"✘ \0")
        client.color_log(255,255,255,"修羅剣\0")
        client.color_log(70,142,139,"「現世妄執」\0")
        client.color_log(213,213,213," 在你的射擊注册之前玩家就被殺死了 \0")
	return
	end

    if e.reason == "?" then
    reason = "解析器"
    elseif e.reason == "spread" then
        reason = "擴散"
    elseif e.reason == "prediction error" then
        reason = "預判"
    elseif e.reason == "unregistered shot" then
        reason = "未註冊"
    elseif e.reason == "death" then
        reason = "死亡"
    else
        reason = e.reason
    end
	
        client.color_log(176,124,124,"✘ \0")
        client.color_log(255,255,255,"天界剣\0")
        client.color_log(70,142,139,"「七魄忌諱」\0")
        client.color_log(213,213,213," 空了 \0")
        client.color_log(176,124,124,string.lower(target_name).."\0")
        client.color_log(213,213,213," 的 \0")
        client.color_log(176,124,124,group.."\0")
        client.color_log(213,213,213," 原因：\0")
        client.color_log(176,124,124,reason.."\0")
        client.color_log(213,213,213," 命中率：\0")
        client.color_log(176,124,124,e.hit_chance)
    end
end


client.set_event_callback('aim_hit', on_aim_hit)
client.set_event_callback('aim_miss', on_aim_miss)