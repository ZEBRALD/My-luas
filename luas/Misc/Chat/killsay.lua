local first = {
    '不像演的', '不像演的' }

local userid_to_entindex, get_local_player, is_enemy, console_cmd = client.userid_to_entindex, entity.get_local_player, entity.is_enemy, client.exec

local function on_player_death(e)
    local victim_userid, attacker_userid = e.userid, e.attacker
    if victim_userid == nil or attacker_userid == nil then
        return
    end

    local victim_entindex = userid_to_entindex(victim_userid)
    local attacker_entindex = userid_to_entindex(attacker_userid)

    if attacker_entindex == get_local_player() and is_enemy(victim_entindex) then
        client.exec('say ' ..first[math.random(0, #first)])
    end
end
client.set_event_callback("player_death", on_player_death)