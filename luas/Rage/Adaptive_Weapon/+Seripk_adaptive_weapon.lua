--fix and new features by zebrald
local ref = ui.reference
local callback = client.set_event_callback
local set,get = ui.set,ui.get
local bit_band, bit_bend = bit.band, validate
local rage = {}
local damage_idx  = { [0] = "Auto",[101] = "HP+1", [102] = "HP+2", [103] = "HP+3", [104] = "HP+4", [105] = "HP+5", [106] = "HP+6", [107] = "HP+7", [108] = "HP+8", [109] = "HP+9", [110] = "HP+10", [111] = "HP+11", [112] = "HP+12", [113] = "HP+13", [114] = "HP+14", [115] = "HP+15", [116] = "HP+16", [117] = "HP+17", [118] = "HP+18", [119] = "HP+19",[120] = "HP+20", [121] = "HP+21", [122] = "HP+22", [123] = "HP+23", [124] = "HP+24", [125] = "HP+25", [126] = "HP+26" }
local override_dmg_first_key = ui.new_hotkey("Rage", "Other", "Override first dmg")
local override_dmg_second_key = ui.new_hotkey("Rage", "Other", "Override second dmg")
local show_status_ind = ui.new_checkbox("Rage", "Other", "Show status indicator")     -- 保留状态开关

local Weapon = {
    "Global", "Taser", "Heavy Pistol","Pistol", "Auto", "Scout", "AWP", "Rifle", "SMG", "Shotgun", "Desert Eagle"
}
local hitchance_status = "Default"
local damage_status = "Def"
local weapon_idx = { [1] = 11,[2] = 4,[3] = 4,[4] = 4,[7] = 8,[8] = 8,[9] = 7,[10] = 8,[11] = 5,[13] = 8,[14] = 8,[16] = 8,[17] = 9,[19] = 9,[23] = 9,[24] = 9,[25] = 10,[26] = 9,[27] = 10,[28] = 8,[29] = 10,[30] = 4,[31] = 2,  [32] = 4,[33] = 9,[34] = 9,[35] = 10,[36] = 4,[38] = 5,[39] = 8,[40] = 6,[60] = 8,[61] = 4,[63] = 4,[64] = 3}
local active_wpn = ui.new_combobox("Rage","Aimbot", "Weapon select", Weapon)

for i = 1,#Weapon do
    rage[i] = {
        target = ui.new_combobox("Rage","Aimbot", string.format("[%s]Target",Weapon[i]), {"Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance"}),
        hitbox = ui.new_multiselect("Rage","Aimbot", string.format("[%s]Hitbox",Weapon[i]), {"Head","Chest","Stomach","Arms","Legs","Feet"}),
        multi = ui.new_multiselect("Rage","Aimbot", string.format("[%s]Multi-point",Weapon[i]), {"Head","Chest","Stomach","Arms","Legs","Feet"}),
        multi_scale = ui.new_slider("Rage", "Aimbot", string.format("[%s]Multi-point scale",Weapon[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"}),
        avoid = ui.new_multiselect("Rage","Aimbot", string.format("[%s]avoid-hitbox",Weapon[i]), {"Head","Chest","Stomach","Arms","Legs","Feet"}),
        acc = ui.new_combobox("Rage", "Aimbot", string.format("[%s]Accuracy boost",Weapon[i]), {"Off","Low","Medium","High","Maximum"}),
        quick = ui.new_multiselect("Rage", "Aimbot", string.format("[%s]Quick stop options",Weapon[i]), {"Early", "Slow motion", "Duck", "Fake duck","Move between shots", "Ignore molotov","Taser"}),
        pbaim_disable = ui.new_multiselect("Rage", "Aimbot", string.format("[%s]Prefer baim disable",Weapon[i]),{"Low inaccuracy", "Target shot fired", "Target resolved", "Safe point headshot", "Low damage"}),
        hc = ui.new_slider("Rage", "Aimbot", string.format("[%s]Hitchance",Weapon[i]), 0, 100, 50,true,"%",1,{[0]="Off"}),
        hitchance_air = ui.new_slider("Rage", "Aimbot", string.format("[%s]Air Hitchance",Weapon[i]), 0, 100, 50, true, "%", 1, {[0]="Off"}),
        hitchance_scope = ui.new_slider("Rage", "Aimbot", string.format("[%s]Scope Hitchance",Weapon[i]), 0, 100, 50, true, "%", 1, {[0]="Off"}),
        dmg = ui.new_slider("Rage", "Aimbot", string.format("[%s]Damage",Weapon[i]), 0,126,20,true,"",1,damage_idx),
        airdmg = ui.new_slider("Rage", "Aimbot", string.format("[%s]Air Damage",Weapon[i]), 0,126,20,true,"",1,damage_idx),
        presafe = ui.new_checkbox("Rage", "Aimbot",string.format("[%s]Prefer safepoint",Weapon[i])),
        scope = ui.new_checkbox("Rage", "Aimbot", string.format("[%s]Automatic scope",Weapon[i])),
        delay = ui.new_checkbox("Rage", "Aimbot",string.format("[%s]Delay shot",Weapon[i])),
        pbaim = ui.new_checkbox("Rage", "Aimbot", string.format("[%s]Prefer baim",Weapon[i])),
        dt_hitchance = ui.new_slider("Rage", "Other", string.format("[%s]DT Hitchance",Weapon[i]), 0,100,20,true,"%",1,damage_idx), 
        dt_quick = ui.new_multiselect("Rage", "Other", string.format("[%s]DT Quick stop",Weapon[i]), {"Slow motion", "Duck", "Move between shots",}),
        ov_first = ui.new_slider("Rage", "Other", string.format("[%s]Override first dmg",Weapon[i]), 0,126,20,true,"",1,damage_idx),
        ov_second = ui.new_slider("Rage", "Other", string.format("[%s]Override second dmg",Weapon[i]), 0,126,20,true,"",1,damage_idx),
    }
end

local ref_enable, ref_enable_key                                = ref("RAGE", "Aimbot", "Enabled")
local ref_quickstop                                             = {ref("RAGE", "Aimbot", "Quick stop") }
local ref_antiaim_correction                                    = ref("RAGE", "Other", "Anti-aim correction")
local ref_target                                                = ref("RAGE", "Aimbot", "Target selection")
local ref_hitbox                                                = ref("RAGE", "Aimbot", "Target hitbox")
local ref_multipoint, ref_multipointkey, ref_multipoint_mode    = ref("RAGE", "Aimbot", "Multi-point")
local ref_multipoint_scale                                      = ref("RAGE", "Aimbot", "Multi-point scale")
local ref_prefer_safepoint                                      = ref("RAGE", "Aimbot", "Prefer safe point")
local ref_force_safepoint                                       = ref("RAGE", "Aimbot", "Force safe point")
local ref_avoid_hitbox                                          = ref("Rage", "Aimbot","Avoid unsafe hitboxes")
local ref_hitchance                                             = ref("RAGE", "Aimbot", "Minimum hit chance")
local ref_mindamage                                             = ref("RAGE", "Aimbot", "Minimum damage")
local ref_automatic_scope                                       = ref("RAGE", "Aimbot", "Automatic scope")
local ref_max_fov                                               = ref("Rage", "Other","Maximum FOV")
local ref_reduce_aimstep                                        = ref("RAGE", "Other", "Reduce aim step")
local ref_automatic_fire                                        = ref("RAGE", "Other", "Automatic fire")
local ref_automatic_penetration                                 = ref("RAGE", "Other", "Automatic penetration")
local ref_silent_aim                                            = ref("RAGE", "Other", "Silent aim")
local ref_log_spread                                            = ref("RAGE", "Other", "Log misses due to spread")
local ref_low_fps_mitigations                                   = ref("RAGE", "Other", "Low FPS mitigations")
local ref_remove_recoil                                         = ref("RAGE", "Other", "Remove recoil")
local ref_accuracy_boost                                        = ref("RAGE", "Other", "Accuracy boost")
local ref_delay_shot                                            = ref("RAGE", "Other", "Delay shot")
local ref_quick_peek , ref_quick_peek_key                       = ref("Rage", "Other","Quick peek assist")
local ref_prefer_bodyaim                                        = ref("RAGE", "Aimbot", "Prefer body aim")
local ref_prefer_bodyaim_disablers                              = ref("RAGE", "Aimbot", "Prefer body aim disablers")
local ref_force_bodyaim                                         = ref("RAGE", "Aimbot", "Force body aim")
local doubletap_hitchance                                       = ref("RAGE", "Aimbot", "Double tap hit chance")
local doubletap_quickstop                                       = ref("RAGE", "Aimbot", "Double tap quick stop")
local dt = {ref("Rage","Aimbot","Double tap") } 

local rage_idx = 1
local last_weapon = 1
local close_ui = false

local function refresh_ui()
    for i = 1,#Weapon do
        local show = ui.get(active_wpn) == Weapon[i]
        for _ ,idx in pairs(rage[i]) do
           ui.set_visible(idx, show)
        end
    end
    local aimbot_visible = false
    local other_visible = false
    if close_ui then other_visible = true;aimbot_visible = true end
    ui.set_visible(ref_target ,aimbot_visible)
    ui.set_visible(ref_hitbox           ,           aimbot_visible)
    ui.set_visible(ref_multipoint       ,           aimbot_visible)
    ui.set_visible(ref_multipointkey    ,           aimbot_visible)
    ui.set_visible(ref_multipoint_scale ,           aimbot_visible)
    ui.set_visible(ref_prefer_safepoint ,           aimbot_visible)
    ui.set_visible(ref_avoid_hitbox     ,           aimbot_visible)
    ui.set_visible(ref_automatic_fire   ,           aimbot_visible)
    ui.set_visible(ref_automatic_penetration    ,   aimbot_visible)
    ui.set_visible(ref_silent_aim       ,           aimbot_visible)
    ui.set_visible(ref_hitchance        ,           aimbot_visible)
    ui.set_visible(ref_mindamage        ,           aimbot_visible)
    ui.set_visible(ref_automatic_scope  ,           aimbot_visible)
    ui.set_visible(ref_reduce_aimstep   ,           aimbot_visible)
    ui.set_visible(ref_max_fov           ,           aimbot_visible)
    ui.set_visible(ref_log_spread       ,           aimbot_visible)
    ui.set_visible(ref_low_fps_mitigations  ,       aimbot_visible)
    ui.set_visible(ref_antiaim_correction,           other_visible)
    ui.set_visible(ref_remove_recoil    ,           other_visible)
    ui.set_visible(ref_accuracy_boost   ,           other_visible)
    ui.set_visible(ref_delay_shot       ,           other_visible)
    ui.set_visible(ref_quickstop[1]     ,           other_visible)
    ui.set_visible(ref_quickstop[2]     ,           other_visible)
    ui.set_visible(ref_quickstop[3],                other_visible)
    ui.set_visible(ref_prefer_bodyaim,              other_visible)
    ui.set_visible(ref_prefer_bodyaim_disablers,    other_visible)
    ui.set_visible(doubletap_quickstop,             other_visible)
    ui.set_visible(doubletap_hitchance,             other_visible)
end

local function gradient_text(r1, g1, b1, a1, r2, g2, b2, a2, text)
    local output = ''
    local len = #text-1
    local rinc = (r2 - r1) / len
    local ginc = (g2 - g1) / len
    local binc = (b2 - b1) / len
    local ainc = (a2 - a1) / len
    for i=1, len+1 do
        output = output .. ('\a%02x%02x%02x%02x%s'):format(r1, g1, b1, a1, text:sub(i, i))
        r1 = r1 + rinc
        g1 = g1 + ginc
        b1 = b1 + binc
        a1 = a1 + ainc
    end
    return output
end

local function in_air()
    local pl = entity.get_local_player()
    if pl == nil then return false end
    return (bit.band(entity.get_prop(pl, "m_fFlags"), 1) == 0)
end

local function run()
    callback("setup_command", function (e)
        local plocal = entity.get_local_player()
        if plocal == nil or not entity.is_alive(plocal) then return end
        
        local weapon_ent = entity.get_player_weapon(plocal)
        if weapon_ent == nil then return end 

        local weapon_prop = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
        if weapon_prop == nil then return end 

        local weapon_id = bit.band(weapon_prop, 0xFFFF)
        local wpn_text = Weapon[weapon_idx[weapon_id]]
        
        if wpn_text ~= nil then
            if last_weapon ~= weapon_id then
                ui.set(active_wpn, wpn_text)
                last_weapon = weapon_id
            end
            rage_idx = weapon_idx[weapon_id] 
        else
            if last_weapon ~= weapon_id then
                ui.set(active_wpn, "Global")
                last_weapon = weapon_id
            end
            rage_idx = 1
        end
        set(ref_enable,true)
        set(ref_enable_key,"Always on")
        set(ref_multipointkey,"Always on")
        set(ref_automatic_fire,true)
        set(ref_automatic_penetration,true)
        set(ref_silent_aim,true)
        set(ref_reduce_aimstep,false)
        set(ref_max_fov,180)
        set(ref_log_spread,true)
        set(ref_low_fps_mitigations,{})
        set(ref_remove_recoil,true)
        set(ref_quickstop[1],true)
        set(ref_quickstop[2],"Always on")
        set(ref_quick_peek,true)
        set(ref_antiaim_correction,true)
    end)

    callback("paint_ui",function ()
        refresh_ui()
        local pl = entity.get_local_player()
        if pl == nil or not entity.is_alive(pl) then
            return
        end
        local i = rage_idx
        local me = pl
        local is_scoped_val = entity.get_prop(me, "m_bIsScoped")
        local jumping = (bit.band(entity.get_prop(me, 'm_fFlags'), 1) == 0)
        
        local set_damage = 0
        if get(override_dmg_second_key) then
            set_damage = get(rage[i].ov_second)
            damage_status = "Key2"
        elseif get(override_dmg_first_key) then
            set_damage = get(rage[i].ov_first)
            damage_status = "Key"
        elseif jumping then 
            set_damage = get(rage[i].airdmg)
            damage_status = "Air"
        else
            set_damage = get(rage[i].dmg)
            damage_status = "Def"
        end

        local hc_val = 0
        if jumping then 
            hc_val = get(rage[i].hitchance_air)
            hitchance_status = "Air"
        elseif is_scoped_val == 1 then
            hc_val = get(rage[i].hitchance_scope)
            hitchance_status = "Sco"
        else
            hc_val = get(rage[i].hc)
            hitchance_status = "Def"
        end

        set(ref_target,get(rage[i].target))
        set(ref_hitbox,#get(rage[i].hitbox) ==  0 and "Head" or get(rage[i].hitbox))
        set(ref_multipoint,get(rage[i].multi))
        set(ref_multipoint_scale,get(rage[i].multi_scale))
        set(ref_avoid_hitbox,get(rage[i].avoid))
        set(ref_quickstop[3],get(rage[i].quick))
        set(ref_prefer_bodyaim_disablers,get(rage[i].pbaim_disable))    
        set(doubletap_hitchance, get(rage[i].dt_hitchance))
        set(ref_hitchance,hc_val)
        set(ref_mindamage,set_damage)
        set(ref_prefer_safepoint,get(rage[i].presafe))
        set(ref_automatic_scope,get(rage[i].scope))
        set(ref_delay_shot,get(rage[i].delay))
        set(ref_prefer_bodyaim,get(rage[i].pbaim))
        set(doubletap_quickstop ,get(rage[i].dt_quick))
    end)

    -- 这里保留你的颜色控件
    ui.new_label("Rage", "Other", "Status Color 1")
    local color_1 = ui.new_color_picker("Rage", "Other", "Color1", 255, 255, 255, 255)
    ui.new_label("Rage", "Other", "Status Color 2")
    local color_2 = ui.new_color_picker("Rage", "Other", "Color2", 255, 255, 255, 255)

    callback("paint",function ()
        local lp = entity.get_local_player()
        if lp == nil or not entity.is_alive(lp) then
            return
        end
        
        local c1 = {ui.get(color_1)}
        local c2 = {ui.get(color_2)}

        -- 这里应用颜色至 status indicator，并删除了原 script name 指示器
        if ui.get(show_status_ind) then
            local text = "D:"..damage_status.." H:"..hitchance_status
            renderer.indicator(255, 255, 255, 255, gradient_text(c1[1],c1[2],c1[3],c1[4],c2[1],c2[2],c2[3],c2[4], text))
        end
    end)

    callback("shutdown",function ()
        close_ui = true
        refresh_ui()
    end)
end
run()

----------------------------------------------------------------------------------------DMG IND
local dmg_ref = ui.reference("RAGE", "Aimbot", "Minimum damage")
client.set_event_callback("paint", function()
    local lp = entity.get_local_player()
    if lp == nil or not entity.is_alive(lp) then return end

    local i = rage_idx
    if i == nil or rage[i] == nil then return end

    local on_1 = ui.get(override_dmg_first_key)
    local on_2 = ui.get(override_dmg_second_key)

    if on_1 or on_2 then
        local xx, yy = client.screen_size()
        local x, y = xx / 2, yy / 2
        local val = ui.get(dmg_ref)
        renderer.text(x + 2, y - 14, 255, 255, 255, 255, "d", 0, val)
    end
end)