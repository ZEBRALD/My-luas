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
local console_cmd = client.exec

local bt, pred_damage

local function aim_fire(e)
    pred_damage = e.damage
    bt = globals.tickcount() - e.tick
end

local function on_aim_hit(e)
    local hitgroup_names = { "不知道", "头部", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local target_name = entity.get_player_name(e.target)
    local damage = e.damage
    local entityHealth = entity.get_prop(e.target, "m_iHealth")

    -- 新增击杀日志，覆盖命中日志
    if entityHealth <= 0 then
        local kill_message = string.format(
            "\x08[\x01\x04樱岛妈逼\x01] \x01击杀\x04 %s\x01 的 \x04%s\x01  伤害:\x04%d\x01  剩余hp: \x04%d\x01 命中率: \x04%d%% 回溯: \x04%d tick",
            string.lower(target_name),
            group,
            damage,
            entityHealth,
            e.hit_chance,
            bt
        )
        console_cmd(string.format('say "%s"', kill_message))
    else
        -- 打印到全体频道
        local broadcast_message = string.format(
            "\x08[\x01\x04樱岛妈逼\x01] \x01命中\x06 %s\x01 的 \x06%s\x01  伤害:\x06%d\x01  剩余hp: \x06%d\x01 命中率: \x06%d%% 回溯: \x06%d tick",
            string.lower(target_name),
            group,
            damage,
            entityHealth,
            e.hit_chance,
            bt
        )
        console_cmd(string.format('say "%s"', broadcast_message))
    end
end

local function on_aim_miss(e)
    if not e then return end

    local hitgroup_names = {  "不知道", "头部", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道", "不知道" }
    local group = hitgroup_names[e.hitgroup + 1] or "?"
    local target_name = entity.get_player_name(e.target)
    local reason
    local damage = e.damage
    local entityHealth = entity.get_prop(e.target, "m_iHealth")

    if (entityHealth == nil) or (entityHealth <= 0) then
        client.log(string.lower(target_name) .. "本地死亡")
        return
    end

    if e.reason == "?" then
        reason = "解析睡觉ing"
    elseif e.reason == "spread" then
        reason = "扩散错误"
    elseif e.reason == "prediction error" then
        reason = "软脚虾"
    elseif e.reason == "unregistered shot" then
        reason = "未注册子弹"
    elseif e.reason == "death" then
        reason = "本地死亡"
    else
        reason = e.reason
    end

    -- 打印到全体频道
    local broadcast_message = string.format(
        "\x08[\x01\x04樱岛妈逼\x01] \x01空了 \x02%s\x01 的 \x02%s\x01 原因 \x02%s\x01 预计伤害\x02%d\x01 命中率\x02%d%% 回溯: \x02%d tick",
        string.lower(target_name),
        group,
        reason,
        pred_damage,
        e.hit_chance,
        bt
    )
    console_cmd(string.format('say "%s"', broadcast_message))
end

client.set_event_callback("aim_fire", aim_fire)
client.set_event_callback('aim_hit', on_aim_hit)
client.set_event_callback('aim_miss', on_aim_miss)