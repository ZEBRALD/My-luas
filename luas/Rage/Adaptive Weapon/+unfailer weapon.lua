local vector = require('vector')
local clipboard = require 'gamesense/clipboard'
local ffi = require 'ffi'
local ffi_cast = ffi.cast
local bit_band = bit.band
local base64 = require 'gamesense/base64'

local plist = _G['plist']
local client_latency, client_set_clan_tag, client_log, client_timestamp, client_userid_to_entindex, client_trace_line, client_set_event_callback, client_screen_size, client_trace_bullet, client_color_log, client_system_time, client_delay_call, client_visible, client_exec, client_eye_position, client_set_cvar, client_scale_damage, client_draw_hitboxes, client_get_cvar, client_camera_angles, client_draw_debug_text, client_random_int, client_random_float = client.latency, client.set_clan_tag, client.log, client.timestamp, client.userid_to_entindex, client.trace_line, client.set_event_callback, client.screen_size, client.trace_bullet, client.color_log, client.system_time, client.delay_call, client.visible, client.exec, client.eye_position, client.set_cvar, client.scale_damage, client.draw_hitboxes, client.get_cvar, client.camera_angles, client.draw_debug_text, client.random_int, client.random_float
local entity_get_player_resource, entity_get_local_player, entity_is_enemy, entity_get_bounding_box, entity_is_dormant, entity_get_steam64, entity_get_player_name, entity_hitbox_position, entity_get_game_rules, entity_get_all, entity_set_prop, entity_is_alive, entity_get_player_weapon, entity_get_prop, entity_get_players, entity_get_classname = entity.get_player_resource, entity.get_local_player, entity.is_enemy, entity.get_bounding_box, entity.is_dormant, entity.get_steam64, entity.get_player_name, entity.hitbox_position, entity.get_game_rules, entity.get_all, entity.set_prop, entity.is_alive, entity.get_player_weapon, entity.get_prop, entity.get_players, entity.get_classname
local globals_realtime, globals_absoluteframetime, globals_tickcount, globals_lastoutgoingcommand, globals_curtime, globals_mapname, globals_tickinterval, globals_framecount, globals_frametime, globals_maxplayers = globals.realtime, globals.absoluteframetime, globals.tickcount, globals.lastoutgoingcommand, globals.curtime, globals.mapname, globals.tickinterval, globals.framecount, globals.frametime, globals.maxplayers
local ui_new_slider, ui_new_combobox, ui_reference, ui_is_menu_open, ui_set_visible, ui_new_textbox, ui_new_color_picker, ui_set_callback, ui_set, ui_new_checkbox, ui_new_hotkey, ui_new_button, ui_new_multiselect, ui_get = ui.new_slider, ui.new_combobox, ui.reference, ui.is_menu_open, ui.set_visible, ui.new_textbox, ui.new_color_picker, ui.set_callback, ui.set, ui.new_checkbox, ui.new_hotkey, ui.new_button, ui.new_multiselect, ui.get
local renderer_circle_outline, renderer_rectangle, renderer_gradient, renderer_circle, renderer_text, renderer_line, renderer_measure_text, renderer_indicator, renderer_world_to_screen = renderer.circle_outline, renderer.rectangle, renderer.gradient, renderer.circle, renderer.text, renderer.line, renderer.measure_text, renderer.indicator, renderer.world_to_screen
local math_ceil, math_tan, math_cos, math_sinh, math_pi, math_max, math_atan2, math_floor, math_sqrt, math_deg, math_atan, math_fmod, math_acos, math_pow, math_abs, math_min, math_sin, math_log, math_exp, math_cosh, math_asin, math_rad = math.ceil, math.tan, math.cos, math.sinh, math.pi, math.max, math.atan2, math.floor, math.sqrt, math.deg, math.atan, math.fmod, math.acos, math.pow, math.abs, math.min, math.sin, math.log, math.exp, math.cosh, math.asin, math.rad
local table_sort, table_remove, table_concat, table_insert = table.sort, table.remove, table.concat, table.insert
local find_material = materialsystem.find_material
local string_find, string_format, string_gsub, string_len, string_gmatch, string_match, string_reverse, string_upper, string_lower, string_sub = string.find, string.format, string.gsub, string.len, string.gmatch, string.match, string.reverse, string.upper, string.lower, string.sub
local ipairs, assert, pairs, next, tostring, tonumber, setmetatable, unpack, type, getmetatable, pcall, error = ipairs, assert, pairs, next, tostring, tonumber, setmetatable, unpack, type, getmetatable, pcall, error

ffi.cdef [[
	typedef int(__thiscall* get_clipboard_text_count)(void*);
	typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
	typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
]]
local VGUI_System010 =  client.create_interface("vgui2.dll", "VGUI_System010") or print( "Error finding VGUI_System010")
local VGUI_System = ffi_cast(ffi.typeof('void***'), VGUI_System010 )
local get_clipboard_text_count = ffi_cast( "get_clipboard_text_count", VGUI_System[ 0 ][ 7 ] ) or print( "get_clipboard_text_count Invalid")
local set_clipboard_text = ffi_cast( "set_clipboard_text", VGUI_System[ 0 ][ 9 ] ) or print( "set_clipboard_text Invalid")
local get_clipboard_text = ffi_cast( "get_clipboard_text", VGUI_System[ 0 ][ 11 ] ) or print( "get_clipboard_text Invalid")

local ragebot = {
    enabled = { ui_reference("RAGE", "Aimbot", "Enabled") },
    target_selection = ui_reference("RAGE", "Aimbot", "Target selection"),
    target_hitbox = ui_reference("RAGE", "Aimbot", "Target hitbox"),
    multipoint = { ui_reference("RAGE", "Aimbot", "Multi-point") },
    multipoint_scale = ui_reference("RAGE", "Aimbot", "Multi-point scale"),
    prefer_safepoint = ui_reference("RAGE", "Aimbot", "Prefer safe point"),
    force_safepoint = ui_reference("RAGE", "Aimbot", "Force safe point"),
    avoid_unsafe_hitboxes = ui_reference("RAGE", "Aimbot", "Avoid unsafe hitboxes"),
    automatic_fire = ui_reference("RAGE", "Other", "Automatic fire"),
    automatic_penetration = ui_reference("RAGE", "Other", "Automatic penetration"),
    silent_aim = ui_reference("RAGE", "Other", "Silent aim"),
    hitchance = ui_reference("RAGE", "Aimbot", "Minimum hit chance"),
    minimum_damage = ui_reference("RAGE", "Aimbot", "Minimum damage"),
    auto_scope = ui_reference("RAGE", "Aimbot", "Automatic scope"),
    reduce_aim_step = ui_reference("RAGE", "Other", "Reduce aim step"),
    maximum_fov = ui_reference("RAGE", "Other", "Maximum FOV"),
    log_misses_due_to_spread = ui_reference("RAGE", "Other", "Log misses due to spread"),
    low_fps_mitigations = ui_reference("RAGE", "Other", "Low FPS mitigations"),
    remove_recoil = ui_reference("RAGE", "Other", "Remove recoil"),
    accuracy_boost = ui_reference("RAGE", "Other", "Accuracy boost"),
    delay_shot = ui_reference("RAGE", "Other", "Delay shot"),
    quick_stop = { ui_reference("RAGE", "aimbot", "Quick stop") },
    quick_peek_assist = { ui_reference("RAGE", "Other", "Quick peek assist") },
    quick_peek_assist_mode = { ui_reference("RAGE", "Other", "Quick peek assist mode") },
    quick_peek_assist_distance = ui_reference("RAGE", "Other", "Quick peek assist distance"),
    resolver = ui_reference("RAGE", "Other", "Anti-aim correction"),
    -- resolver_override = ui_reference("RAGE", "aimbot", "Anti-aim correction override"),
    prefer_body_aim = ui_reference("RAGE", "aimbot", "Prefer body aim"),
    prefer_body_aim_disablers = ui_reference("RAGE", "aimbot", "Prefer body aim disablers"),
    force_body_aim = ui_reference("RAGE", "aimbot", "Force body aim"),
    duck_peek_assist = ui_reference("RAGE", "Other", "Duck peek assist"),
    double_tap  = { ui_reference("RAGE", "aimbot", "Double tap") },
   dta,dtb,double_tap_mode = ui_reference("RAGE", "aimbot", "Double tap"),
    double_tap_hitchance = ui_reference("RAGE", "aimbot", "Double tap hit chance"),
    double_tap_fake_lag_limit = ui_reference("RAGE", "aimbot", "Double tap fake lag limit"),
    double_tap_quick_stop = ui_reference("RAGE", "aimbot", "Double tap quick stop"),
    ping_spike = {ui_reference("MISC", "miscellaneous", "ping spike")},
    baim_hitboxes = {3,4,5,6},
    fake_lag_limit = ui_reference("AA", "Fake lag", "Limit") ,


}

local colorful_text = {}

colorful_text.lerp = function(self, from, to, duration)
    if type(from) == 'table' and type(to) == 'table' then
        return { 
            self:lerp(from[1], to[1], duration), 
            self:lerp(from[2], to[2], duration), 
            self:lerp(from[3], to[3], duration) 
        }
    end

    return from + (to - from) * duration;
end

colorful_text.console = function(self, ...)
    for i, v in ipairs({ ... }) do
        if type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
            for k = 1, #v[3] do
                local l = self:lerp(v[1], v[2], k / #v[3]);
                client_color_log(l[1], l[2], l[3], v[3]:sub(k, k) .. '\0')
            end
        elseif type(v[1]) == 'table' and type(v[2]) == 'string' then
            client_color_log(v[1][1], v[1][2], v[1][3], v[2] .. '\0')
        end
    end
end

colorful_text.text = function(self, ...)
    local menu = false
    local alpha = 255
    local f = ''
    
    for i, v in ipairs({ ... }) do
        if type(v) == 'boolean' then
            menu = v;
        elseif type(v) == 'number' then
            alpha = v;
        elseif type(v) == 'string' then
            f = f .. v;
        elseif type(v) == 'table' then
            if type(v[1]) == 'table' and type(v[2]) == 'string' then
                f = f .. ('\a%02x%02x%02x%02x'):format(v[1][1], v[1][2], v[1][3], alpha) .. v[2]
            elseif type(v[1]) == 'table' and type(v[2]) == 'table' and type(v[3]) == 'string' then
                for k = 1, #v[3] do
                    local g = self:lerp(v[1], v[2], k / #v[3])
                    f = f .. ('\a%02x%02x%02x%02x'):format(g[1], g[2], g[3], alpha) .. v[3]:sub(k, k)
                end
            end
        end
    end

    return ('%s\a%s%02x'):format(f, (menu) and 'cdcdcd' or 'ffffff', alpha)
end

colorful_text.log = function(self, ...)
    for i, v in ipairs({ ... }) do
        if type(v) == 'table' then
            if type(v[1]) == 'table' then
                if type(v[2]) == 'string' then
                    self:console({ v[1], v[1], v[2] })
                    if (v[3]) then
                        self:console({ { 255, 255, 255 }, '\n' })
                    end
                elseif type(v[2]) == 'table' then
                    self:console({ v[1], v[2], v[3] })
                    if v[4] then
                        self:console({ { 255, 255, 255 }, '\n' })
                    end
                end
            elseif type(v[1]) == 'string' then
                self:console({ { 205, 205, 205 }, v[1] });
                if v[2] then
                    self:console({ { 255, 255, 255 }, '\n' })
                end
            end
        end
    end
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

local log = function( ...)
    local ret = { ... };

    local rs, gs,bs,as = 250,211,128,255
    
    colorful_text:log(
        { { rs, gs,bs }, {bs, gs,rs }, "unfailer adaptive" },
        { { 100, 100, 100 }, " >> "},
        { { 255, 255, 255 }, string.format(unpack(ret)),true }
    )

end

local __main__ = function()
    local str_to_sub = function(input, sep)
        local t = {}
        for str in string.gmatch(input, "([^"..sep.."]+)") do
            t[#t + 1] = string.gsub(str, "\n", "")
        end
        return t
    end
    
    local arr_to_string = function(arr)
        arr = ui_get(arr)
        local str = ""
        for i=1, #arr do
            str = str .. arr[i] .. (i == #arr and "" or ",")
        end
    
        if str == "" then
            str = "-"
        end
    
        return str
    end

    local to_boolean = function(str)
        if str == "true" or str == "false" then
            return (str == "true")
        else
            return str
        end
    end
    
    local table_contains = function(tbl, val)
        for i=1,#tbl do
            if tbl[i] == val then
                return true
            end
        end
        return false
    end

    local screen = {client_screen_size()}
    local sx,sy = screen[1],screen[2]
    local cx,cy =  sx/2,sy/2 

    local function set_og_menu(state)
        ui_set_visible(ragebot.target_selection,state)
        ui_set_visible(ragebot.target_hitbox,state)
        ui_set_visible(ragebot.multipoint[1],state)
        ui_set_visible(ragebot.multipoint_scale,state)
        ui_set_visible(ragebot.prefer_safepoint,state)
        ui_set_visible(ragebot.force_safepoint,state)
        ui_set_visible(ragebot.avoid_unsafe_hitboxes,state)
        ui_set_visible(ragebot.automatic_fire,state)
        ui_set_visible(ragebot.automatic_penetration,state)
        ui_set_visible(ragebot.silent_aim,state)
        ui_set_visible(ragebot.hitchance,state)
        ui_set_visible(ragebot.minimum_damage,state)
        ui_set_visible(ragebot.auto_scope,state)
        ui_set_visible(ragebot.automatic_penetration,state)
        ui_set_visible(ragebot.reduce_aim_step,state)
        ui_set_visible(ragebot.maximum_fov,state)
        ui_set_visible(ragebot.quick_stop[1],state)
        ui_set_visible(ragebot.delay_shot,state)
        ui_set_visible(ragebot.quick_stop_options,state)
        ui_set_visible(ragebot.double_tap_quick_stop,state)
        ui_set_visible(ragebot.prefer_body_aim,state)
        ui_set_visible(ragebot.prefer_body_aim_disablers,state)
    end

    local u = {}
    u.call = {}
    u.export = {
        ['number'] = {},
        ['boolean'] = {},
        ['table'] = {},
        ['string'] = {}
    }
    local active_idx = 1
    local weapon_list = {
        "Global", 
        "Taser", 
        "Revolver",
        "Pistol", 
        "Auto", 
        "Scout", 
        "AWP",
        "Rifle", 
        "SMG", 
        "Shotgun", 
        "Deagle"
    }
    local weapon_idx = { [1] = 11,[2] = 4,[3] = 4,[4] = 4,[7] = 8,[8] = 8,[9] = 7,[10] = 8,[11] = 5,[13] = 8,[14] = 8,[16] = 8,[17] = 9,[19] = 9,[23] = 9,[24] = 9,[25] = 10,[26] = 9,[27] = 10,[28] = 8,[29] = 10,[30] = 4,[31] = 2,  [32] = 4,[33] = 9,[34] = 9,[35] = 10,[36] = 4,[38] = 5,[39] = 8,[40] = 6,[60] = 8,[61] = 4,[63] = 4,[64] = 3}
    local damage_idx  = { [0] = "Auto", [101] = "HP + 1", [102] = "HP + 2", [103] = "HP + 3", [104] = "HP + 4", [105] = "HP + 5", [106] = "HP + 6", [107] = "HP + 7", [108] = "HP + 8", [109] = "HP + 9", [110] = "HP + 10", [111] = "HP + 11", [112] = "HP + 12", [113] = "HP + 13", [114] = "HP + 14", [115] = "HP + 15", [116] = "HP + 16", [117] = "HP + 17", [118] = "HP + 18", [119] = "HP + 19", [120] = "HP + 20", [121] = "HP + 21", [122] = "HP + 22", [123] = "HP + 23", [124] = "HP + 24", [125] = "HP + 25", [126] = "HP + 26" }
    local name_to_num = { ["Global"] = 1, ["Taser"] = 2, ["Revolver"] = 3, ["Pistol"] = 4, ["Auto"] = 5, ["Scout"] = 6, ["AWP"] = 7, ["Rifle"] = 8, ["SMG"] = 9, ["Shotgun"] = 10, ["Deagle"] = 11 }

    local scoped_wpn_idx = {
        name_to_num["Scout"],
        name_to_num["Auto"],
        name_to_num["AWP"],
        

    }
    local sc_weapon = { name_to_num["Scout"], name_to_num["Auto"], name_to_num["AWP"] }

    local min_damage, last_weapon = "default", 0

    local clipboard_import = function( )
        local clipboard_text_length = get_clipboard_text_count( VGUI_System )
        local clipboard_data = ""
    
        if clipboard_text_length > 0 then
            buffer = ffi.new("char[?]", clipboard_text_length)
            size = clipboard_text_length * ffi.sizeof("char[?]", clipboard_text_length)
    
            get_clipboard_text( VGUI_System, 0, buffer, size )
    
            clipboard_data = ffi.string( buffer, clipboard_text_length-1 )
        end
        return base64.decode(clipboard_data)
    end
    
    local clipboard_export = function(string)
        if string then
            set_clipboard_text(VGUI_System, string, string:len())
        end
    end
    local plist_set, plist_get = plist.set, plist.get

    --#region rev lethal
    local function Vector(x,y,z) 
        return {x=x or 0,y=y or 0,z=z or 0} 
    end

    local function Distance(from_x,from_y,from_z,to_x,to_y,to_z)  
    return math_ceil(math_sqrt(math_pow(from_x - to_x, 2) + math_pow(from_y - to_y, 2) + math_pow(from_z - to_z, 2)))
    end

    local function extrapolate_position(xpos,ypos,zpos,ticks,player)
        local x,y,z = entity.get_prop(player, "m_vecVelocity")
        for i = 0, ticks do
            xpos =  xpos + (x * globals.tickinterval())
            ypos =  ypos + (y * globals.tickinterval())
            zpos =  zpos + (z * globals.tickinterval())
        end
        return xpos,ypos,zpos
    end


    local is_baimable = function(ent, localplayer)
        local final_damage  = 0
    
        local eyepos_x, eyepos_y, eyepos_z = client.eye_position()
        local  fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z
    
        eyepos_x, eyepos_y, eyepos_z = extrapolate_position(eyepos_x, eyepos_y, eyepos_z, 20, localplayer)
    
        fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z = eyepos_x, eyepos_y, eyepos_z
        for k,v in pairs(ragebot.baim_hitboxes) do
            local hitbox    = vector(entity.hitbox_position(ent, v))
            local ___, dmg  = client.trace_bullet(localplayer, fs_stored_eyepos_x, fs_stored_eyepos_y, fs_stored_eyepos_z, hitbox.x, hitbox.y, hitbox.z, true)
    
            if ( dmg > final_damage) then
                final_damage = dmg
            end
        end
    
        return final_damage
    end

    local contains = function(table, val)
        if #table > 0 then
            for i=1, #table do
                if table[i] == val then
                    return true
                end
            end
        end
        return false
    end





    local new = function(register)
        if type(register) ~= 'number' then
            log('unable to create new register,register should be a number')
        end

        if type(register) == 'number' then
            table_insert(u.export[type(ui.get(register))],register)
        end

         if type(register) == 'number' then
             table_insert(u.call,register)
        end
        
        return register
    end
    local load_config = function()
        local tbl = str_to_sub(base64.decode(clipboard.get(), 'base64'), "|")
        local p = 1
        for i,o in pairs(u.export['number']) do
            ui_set(o,tonumber(tbl[p]))
            p = p + 1
        end
        for i,o in pairs(u.export['string']) do
            ui_set(o,tbl[p])
            p = p + 1
        end
        for i,o in pairs(u.export['boolean']) do
            ui_set(o,to_boolean(tbl[p]))
            p = p + 1
        end
        for i,o in pairs(u.export['table']) do
            ui_set(o,str_to_sub(tbl[p],','))
            p = p + 1
        end
    end

    local export_config = function()
        local str = ""
        for i,o in pairs(u.export['number']) do
            str = str .. tostring(ui_get(o)) .. '|'
        end
        for i,o in pairs(u.export['string']) do
            str = str .. (ui_get(o)) .. '|'
        end
        for i,o in pairs(u.export['boolean']) do
            str = str .. tostring(ui_get(o)) .. '|'
        end
        for i,o in pairs(u.export['table']) do
            str = str .. arr_to_string(o) .. '|'
        end
        print(str)
        clipboard.set(base64.encode(str, 'base64'))
    end

    u.g_menu = {}
    u.weapon = {}
    local g_handle_menu = {
        create = function(self)
            local g = u.g_menu
            local w = u.weapon
            local tab1,tab2,tab3 = "RAGE","Aimbot","Other"
          
          
            g.master_switch =      new(ui_new_checkbox(tab1,tab2,"\aF8F884D1unfailer weapon config"))
            g.override_dmg =     ui_new_hotkey(tab1,tab2,"Damage override")
            g.override_hitchance = ui_new_hotkey(tab1,tab2,"Hitchance override")
            g.override_hitbox =    ui_new_hotkey(tab1,tab2,"Hitboxes override")
            g.target_override =     new(ui.new_multiselect(tab1,tab2, string.format("[%s] Target hitbox selection override","Global"), {"Head","Chest","Stomach","Arms","Legs","Feet"}))
            g.weapon_select =      new(ui_new_combobox(tab1,tab2,"Select weapon",weapon_list))

            w.rage = {}
            for i, v in pairs(weapon_list) do
                w.rage[i] = {
                    enable_weapon =     new(ui.new_checkbox(tab1,tab2, string.format("\a389FFCC8 %s config",weapon_list[i]))),
                    acc =               new(ui.new_combobox(tab1,tab2, string.format("[%s] Accuracy boost",weapon_list[i]), {"Low","Medium","High","Maximum"})),
                    target_selection =  new(ui_new_combobox(tab1,tab2, string.format("[%s] Target selection",weapon_list[i]), {"Cycle", "Cycle (2x)", "Near crosshair", "Highest damage", "Lowest ping", "Best K/D ratio", "Best hit chance"})),
                    target_hitbox =     new(ui.new_multiselect(tab1,tab2, string.format("[%s] Target hitbox selection",weapon_list[i]), "Head","Chest","Stomach","Arms","Legs","Feet")),
                    avoid =             new(ui.new_multiselect(tab1,tab2, string.format("[%s] Force safepoint hitbox",weapon_list[i]), "Head","Chest","Stomach","Arms","Legs","Feet")),
                    mp_select =         new(ui.new_multiselect(tab1,tab2, string.format("[%s] Multi-point",weapon_list[i]), "Head","Chest","Stomach","Arms","Legs","Feet")),
                    mp_select_override =new(ui.new_multiselect(tab1,tab2, string.format("[%s] Multi-point [Override]",weapon_list[i]), "Head","Chest","Stomach","Arms","Legs","Feet")),

                    mp_mode =           new(ui_new_combobox(tab1,tab2, string.format("[%s] Multi-point mode",weapon_list[i]), {"Default","Step","Random"})),
                    mp_default =        new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Default]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),
                    mp_step_min =       new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Step Min]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),
                    mp_step_max =       new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Step Max]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),
                    mp_random_min =     new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Random Min]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),
                    mp_random_max =     new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Random Max]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),
                    mp_override =       new(ui.new_slider(tab1,tab3, string.format("[%s] Multi-point scale [Override]",weapon_list[i]), 24, 100, 50,true, "%", 1, {[24]="Auto"})),

                    hc =                new(ui.new_slider(tab1,tab3, string.format("[%s] Hitchance [Default]",weapon_list[i]), 0, 100, 50,true,"%",1,{[0]="Off"})),
                    hc_air =            new(ui.new_slider(tab1,tab3, string.format("[%s] Hitchance [In Air]",weapon_list[i]), 0, 100, 50, true, "%", 1, {[0]="Off"})),
                    hc_nosp =           new(ui.new_slider(tab1,tab3, string.format("[%s] Hitchance [No Scoped]",weapon_list[i]), 0, 100, 50, true, "%", 1, {[0]="Off"})),
                    hc_ov =             new(ui.new_slider(tab1,tab3, string.format("[%s] Hitchance [Override]",weapon_list[i]), 0, 100, 50, true, "%", 1, {[0]="Off"})),
                    hc_dt =             new(ui.new_slider(tab1,tab3, string.format("[%s] Hitchance [Double Tap]",weapon_list[i]), 0, 100, 50, true, "%", 1, {[0]="Off"})),

                    dmg =               new(ui.new_slider(tab1,tab3, string.format("[%s] Minimum damage [Default]",weapon_list[i]), 0,126,20,true,"",1,damage_idx)),
                    ov_first =          new(ui.new_slider(tab1,tab3,  string.format("[%s] Minimum damage [Override 1]",weapon_list[i]), 0,126,20,true,"",1,damage_idx)),
                    ov_second =         new(ui.new_slider(tab1,tab3,  string.format("[%s] Minimum damage [Override 2]",weapon_list[i]), -1, 126, -1, true, nil, 1, {[-1] = "Disabled", unpack(damage_idx)})),

                    quick =             new(ui.new_checkbox(tab1,tab2, string.format("[%s] Quick stop",weapon_list[i]))),
                    quick_options =     new(ui.new_multiselect(tab1,tab2, string.format("[%s] Quick stop options",weapon_list[i]), "Early", "Slow motion", "Duck", "Fake duck","Move between shots", "Ignore molotov","Taser")),
                    quick_dt_options =  new(ui.new_multiselect(tab1,tab2, string.format("[%s] Quick stop options [Double Tap]",weapon_list[i]),   "Slow motion", "Duck", "Move between shots" )),
                    quick_nosp =        new(ui.new_checkbox(tab1,tab2, string.format("[%s] Quick stop [No Scoped]",weapon_list[i]))),
                    quick_nosp_options =new(ui.new_multiselect(tab1,tab2, string.format("[%s] Quick stop options [No Scoped]",weapon_list[i]),   "Early", "Slow motion", "Duck", "Fake duck","Move between shots", "Ignore molotov","Taser" )),
                    quick_dt_nosp_options =new(ui.new_multiselect(tab1,tab2, string.format("[%s] Quick stop options [No Scoped/Double Tap]",weapon_list[i]),  "Slow motion", "Duck", "Move between shots" )),

                    pbaim =             new(ui.new_checkbox(tab1,tab2, string.format("[%s] Prefer body aim",weapon_list[i]))),
                    pbaim_disable =     new(ui.new_multiselect(tab1,tab2, string.format("[%s] Prefer baim disablers",weapon_list[i]),"Low inaccuracy", "Target shot fired", "Target resolved", "Safe point headshot")),
                    presafe =           new(ui.new_checkbox(tab1,tab2,string.format("[%s] Prefer safepoint [Default]",weapon_list[i]))),
                    presafe_dt =        new(ui.new_checkbox(tab1,tab2,string.format("[%s] Prefer safepoint [Double Tap]",weapon_list[i]))),
                    auto_fire =         new(ui.new_checkbox(tab1,tab2, string.format("[%s] Automatic Fire",weapon_list[i]))),
                    auto_scope =        new(ui.new_checkbox(tab1,tab2, string.format("[%s] Automatic Scope",weapon_list[i]))),
                    auto_wall =         new(ui.new_checkbox(tab1,tab2, string.format("[%s] Automatic Penetration",weapon_list[i]))),
                    delay_shot =        new(ui.new_checkbox(tab1,tab2,string.format("[%s] Delay shot",weapon_list[i]))),
     
                }

        
            end

            g.forcebaim_onlethal = new(ui.new_checkbox(tab1,tab2,'Force Baim If Lethal'))
            g.damage_indicator =    new(ui_new_combobox(tab1,tab3,"Select Damage Indicator states",{"Always on","Override states","Only override","Only Scoped","Off"}))
            g.damage_flag =    new(ui_new_combobox(tab1,tab3,"Select Damage Indicator fonts",{"Normal",'Bold','Pixel'}))
            g.panel = new(ui.new_checkbox(tab1,tab3,"Switch Panel"))

            g.color1 = new(ui_new_color_picker(tab1,tab3,"Color 1"))
            g.color2 = new(ui_new_color_picker(tab1,tab3,"Color 2"))

            g.load_config = ui.new_button('RAGE','Other',"Load config from clipboard",function()
                load_config()
                log("loaded config from clipboard")
            end)
            g.export_config = ui.new_button('RAGE','Other',"Export config to clipboard",function()
                export_config()
                log("Exported config from clipboard")

            end)
  

            g.temp_x = new(ui_new_slider(tab1,tab3,"TEMP_X",0,sx,sx/2 + 20))
            g.temp_y = new(ui_new_slider(tab1,tab3,"TEMP_Y",0,sy,sy/2 + 20))

            g.ptemp_x = new(ui_new_slider(tab1,tab3,"PANEL_TEMP_X",0,sx,sx/2 + 20))
            g.ptemp_y = new(ui_new_slider(tab1,tab3,"PANEL_TEMP_Y",0,sy,sy/2 + 20))

        end,

        visible = function(self)
            local g = u.g_menu

            local show = ui_get(g.master_switch)
            ui_set_visible(g.override_dmg,show)
            ui_set_visible(g.override_hitchance,show)
            ui_set_visible(g.override_hitbox,show)
            ui_set_visible(g.weapon_select,show)
            ui_set_visible(g.load_config,show)
            ui_set_visible(g.export_config,show)
            ui_set_visible(g.target_override,show)
            ui_set_visible(g.temp_y,show)
            ui_set_visible(g.temp_x,show)
            ui_set_visible(g.color1,show)
            ui_set_visible(g.color2,show)
            for k, v in pairs(weapon_list) do
                for i, o in pairs(u.weapon.rage[k]) do
                    ui_set_visible(o,show and ui_get(g.weapon_select) == weapon_list[k])
                end
            end
        end,
        
    }
    g_handle_menu:create()
    g_handle_menu:visible()

    local ovr_key_state
    local ovr_selected = 0
    local ovr_add_disabled

    local handle_ovr = function()
        local ovr_k_temp = ui_get(u.g_menu.override_dmg)

        if ovr_k_temp ~= ovr_key_state then 
            if ovr_add_disabled then 
                ovr_selected = ovr_selected == 0 and 1 or 0
            else
                ovr_selected = ovr_selected ~= 2 and ovr_selected + 1 or 0
            end
            ovr_key_state = ovr_k_temp
        end
    end

    local lethal_rev_active

    local run_adjustments = function()
        local players = entity_get_players(true)
        if #players == 0 then
            min_damage = "default"
            return
        end
        lethal_rev_active = false
        min_damage = "default"
    end

    local jitter = (function()
        local aa = {}

        local clamp = function(num, min, max)
            if num < min then
                num = min
            elseif num > max then
                num = max
            end
            return num
        end
        
  


        local return_value = 0

        aa.step = function(min,max,step_v,step_t)
            local step_min = min
            local step_max = max
            local step_v = step_v
            local step_ticks = globals_tickcount() % step_t

            if step_ticks == step_t - 1 then
                if return_value < step_max then
                    return_value = return_value + step_v
                elseif return_value >= step_max then
                    return_value = step_min
                end
            end
            
            return clamp(return_value,step_min,step_max)
        end

        return aa
    end)()

    local animate = (function()
        local anim = {}
        local anim_speed = 16

        local lerp = function(start, vend)
            return start + (vend - start) * (globals_frametime() * anim_speed)
        end

        anim.new = function(value,startpos,endpos,condition)
            if condition ~= nil then
                if condition then
                    return lerp(value,startpos)
                else
                    return lerp(value,endpos)
                end

            else
                return lerp(value,startpos)
            end

        end

        anim.new_color = function(color,color2,end_value,condition)
            if condition ~= nil then
                if condition then
                    color.r = lerp(color.r,color2.r)
                    color.g = lerp(color.g,color2.g)
                    color.b = lerp(color.b,color2.b)
                    color.a = lerp(color.a,color2.a)
                else
                    color.r = lerp(color.r,end_value.r)
                    color.g = lerp(color.g,end_value.g)
                    color.b = lerp(color.b,end_value.b)
                    color.a = lerp(color.a,end_value.a)
                end
            else
                color.r = lerp(color.r,color2.r)
                color.g = lerp(color.g,color2.g)
                color.b = lerp(color.b,color2.b)
                color.a = lerp(color.a,color2.a)
            end

            return { r = color.r , g = color.g , b = color.b , a = color.a }
        end

        anim.new_flash = function(cur,min,max,target,step,speed)
            local step = step or 1
            local speed = speed or 0.1

            if cur < min + step then
                target = max
            elseif cur > max - step then
                target = min
            end
            
            cur = cur + (target - cur) * speed * (globals_absoluteframetime()*10)
            return cur
        end

        return anim
    end)()

    local csgo_weapons = require("gamesense/csgo_weapons")


    local is_lethal = function(player)
        local local_player = entity.get_local_player()
        if local_player == nil or not entity.is_alive(local_player) then return end
        local local_origin = vector(entity.get_prop(local_player, "m_vecAbsOrigin"))
        local distance = local_origin:dist(vector(entity.get_prop(player, "m_vecOrigin")))
        local enemy_health = entity.get_prop(player, "m_iHealth")
    
        local weapon_ent = entity.get_player_weapon(entity.get_local_player())
        if weapon_ent == nil then return end
        
        local weapon_idx = entity.get_prop(weapon_ent, "m_iItemDefinitionIndex")
        if weapon_idx == nil then return end
        
        local weapon = csgo_weapons[weapon_idx]
        if weapon == nil then return end
    
        if not ui_get(u.g_menu.forcebaim_onlethal) then return end
    
        local dmg_after_range = (weapon.damage * math.pow(weapon.range_modifier, (distance * 0.002))) * 1.25
        local armor = entity.get_prop(player,"m_ArmorValue")
        local newdmg = dmg_after_range * (weapon.armor_ratio * 0.5)
        if dmg_after_range - (dmg_after_range * (weapon.armor_ratio * 0.5)) * 0.5 > armor then
            newdmg = dmg_after_range - (armor / 0.5)
        end
        return newdmg >= enemy_health
    end


    local set_config = function(args)
        local rage = u.weapon.rage
        local g = u.g_menu
        local i = ui_get(rage[args].enable_weapon) and args or 1 
        local target_hitbox = ui_get(rage[i].target_hitbox)
        local target_hitbox_over = ui_get(g.target_override)

        if #target_hitbox == 0 then
            ui_set(rage[i].target_hitbox,"Head")
        end

        if #target_hitbox_over == 0 then
            ui_set(g.target_override,"Head")
        end

        local onground = (bit.band(entity.get_prop(entity.get_local_player(), "m_fFlags"), 1) == 1)
        local is_scoped = entity.get_prop(entity.get_player_weapon(entity.get_local_player()), "m_zoomLevel" ) 
        local hitchance = 
        ui_get(u.g_menu.override_hitchance) and ui_get(rage[i].hc_ov) or --Override hitchance
        not onground and ui_get(rage[i].hc_air)  or -- air hitchance
        (is_scoped == 0 and contains(sc_weapon,i) and ui_get(rage[i].hc_nosp)) or -- noscoped hitchance 
        ui_get(rage[i].hc) -- hitchance                                             
        local is_dt = ui_get(ragebot.double_tap[1]) and ui_get(ragebot.double_tap[2])
        local mp = 
        (ovr_selected ~= 0 and ui_get(rage[i].mp_select_override)) or
        ui_get(rage[i].mp_select) 
        local default_mp,step_mp,random_mp = ui_get(rage[i].mp_mode) == "Default",ui_get(rage[i].mp_mode) == "Step",ui_get(rage[i].mp_mode) == "Random"
        local get_step_value = jitter.step(ui_get(rage[i].mp_step_min),ui_get(rage[i].mp_step_max),1,2)
        local get_random_value = math.random(ui_get(rage[i].mp_random_min),ui_get(rage[i].mp_random_max))
        local mp_value = 
        (step_mp and get_step_value) or
        (random_mp and get_random_value) or 
        (ovr_selected ~= 0 and ui_get(rage[i].mp_override)) or
        ui_get(rage[i].mp_default) 

        local dt_presafe = ui_get(rage[i].presafe_dt) and is_dt
        local presafe = ui_get(rage[i].presafe) and not is_dt or dt_presafe
     

        local avoid_hitbox = ui_get(rage[i].avoid)
        local quick_stop_value = {ui.get(rage[i].quick),ui.get(rage[i].quick_options) }
        local quick_stop_value_dt = ui.get(rage[i].quick_dt_options)

        if i == sc_weapon[2] then
            quick_stop_value = is_scoped == 0 
            and 
            {ui.get(rage[i].quick_nosp),ui.get(rage[i].quick_nosp_options)} 
            or {ui.get(rage[i].quick),ui.get(rage[i].quick_options)}
            quick_stop_value_dt = is_scoped == 0 and ui.get(rage[i].quick_dt_nosp_options) or ui.get(rage[i].quick_dt_options)
        end
        local damage_val = ui_get(rage[i].dmg)

        if ovr_selected == 0 then
            damage_val = ui_get(rage[i].dmg)
        else
            ovr_add_disabled = ui_get(rage[i].ov_second) == -1 
            damage_val = ovr_add_disabled and ui_get(rage[i].ov_first) or 
            (ovr_selected == 1 and ui_get(rage[i].ov_first) or ui_get(rage[i].ov_second))
        end

        ui_set(ragebot.target_selection, ui_get(rage[i].target_selection))
        ui_set(ragebot.automatic_fire, ui_get(rage[i].auto_fire))
        ui_set(ragebot.automatic_penetration, ui_get(rage[i].auto_wall))
        ui_set(ragebot.silent_aim ,true)
        ui_set(ragebot.accuracy_boost, ui_get(rage[i].acc))
        local thb_val = ui_get(g.override_hitbox) and ui_get(g.target_override) or ui_get(rage[i].target_hitbox)

        ui.set(ragebot.target_hitbox, thb_val)
        ui.set(ragebot.multipoint[1], mp)
        ui.set(ragebot.multipoint_scale, mp_value)
        ui.set(ragebot.avoid_unsafe_hitboxes, avoid_hitbox)
        ui.set(ragebot.prefer_safepoint, presafe)
        ui.set(ragebot.auto_scope, ui.get(rage[i].auto_scope))
        ui.set(ragebot.hitchance, hitchance)
        ui.set(ragebot.minimum_damage, damage_val)
        ui.set(ragebot.quick_stop[1],quick_stop_value[1])
        ui.set(ragebot.quick_stop[2], quick_stop_value[2])
        ui.set(ragebot.double_tap_quick_stop, quick_stop_value_dt)
        ui.set(ragebot.prefer_body_aim, ui.get(rage[i].pbaim))
        ui.set(ragebot.prefer_body_aim_disablers, ui.get(rage[i].pbaim_disable))
        ui.set(ragebot.delay_shot, ui.get(rage[i].delay_shot))
        ui.set(ragebot.double_tap_hitchance, ui.get(rage[i].hc_dt))

        
        active_idx = i

    end
    local local_player
    local setup = function(cmd)
        local_player = entity_get_local_player()

        if entity_is_alive(local_player) then run_adjustments() end
    
        local weapon_id = bit_band(entity_get_prop(entity_get_player_weapon(local_player), "m_iItemDefinitionIndex"), 0xFFFF)

        if weapon_id == nil then
            return
        end

        local wpn_text = weapon_list[weapon_idx[weapon_id]]
        local g = u.g_menu
 

        if wpn_text ~= nil then
            if last_weapon ~= weapon_id then
                ui_set(g.weapon_select, ui_get(u.weapon.rage[weapon_idx[weapon_id]].enable_weapon) and wpn_text or "Global")
                last_weapon = weapon_id
            end
            set_config(weapon_idx[weapon_id])
        else
            if last_weapon ~= weapon_id then
                ui_set(g.weapon_select, "Global")
                last_weapon = weapon_id
            end
            set_config(1)
        end
    end

    local values = {
        0,0,0,0
    }
    local g_paint = {
        vars = {
            alpha1 = 0,
            alpha2 = 0,
            alpha3 = 0,
            alpha4 = 0,
            pX = 0,
            pY = 0,
            pW = 0

        },
        on_render = function(self)
            local xd = u.g_menu
            local always,override,o_override,o_scoped,off = ui_get(xd.damage_indicator) == "Always on",ui_get(xd.damage_indicator) == "Override states",ui_get(xd.damage_indicator) == "Only override",ui_get(xd.damage_indicator) == "Only Scoped",ui_get(xd.damage_indicator) == "Off"
            local mouse_x,mouse_y = ui.mouse_position()
            local x,y = ui_get(xd.temp_x),ui_get(xd.temp_y)
            local px,py = ui_get(xd.ptemp_x),ui_get(xd.ptemp_y)

            if ui_is_menu_open() and client.key_state(0x1) and mouse_x > x and mouse_x < x + 100 and mouse_y > y and mouse_y < y + 25 then
                ui_set(xd.temp_x,mouse_x - 50)
                ui_set(xd.temp_y,mouse_y - 12)
            end

            if ui_is_menu_open() and client.key_state(0x1) and mouse_x > px and mouse_x < px + 100 and mouse_y > py and mouse_y < py + 25 then
                ui_set(xd.ptemp_x,mouse_x - 50)
                ui_set(xd.ptemp_y,mouse_y - 12)
            end

            local is_scoped = entity.get_prop(entity.get_player_weapon(entity.get_local_player()), "m_zoomLevel" ) ~= 0
            local damage = ui_get(ragebot.minimum_damage)
            local hitchance = ui_get(ragebot.hitchance)
            local r,g,b,a = ui_get(xd.color1)
            local r1,g1,b1,a1 = ui_get(xd.color2)

            self.vars.alpha3 = animate.new(self.vars.alpha3,1,0,is_scoped or ovr_selected ~= 0)
            if damage == 0 then
                damage = "Auto"
            end

            if hitchance == 0 then
                hitchance = "Off"
            end

            local flags = (ui_get(xd.damage_flag) == 'Normal' and '') or (ui_get(xd.damage_flag) == 'Bold' and 'b') or (ui_get(xd.damage_flag) == 'Pixel' and '-')
            local text_sizex , text_sizey = renderer_measure_text(flags,'DMG:')
            if not off then
                if always then
                    renderer_text(x,y,255,255,255,255,flags,0,damage)
                elseif override then
                    renderer_text(x,y,r,g,b,255,flags,0,ovr_selected)
                    renderer_text(x + 35,y,255,255,255,255,flags,0,damage)
                elseif o_override then
                    if ovr_selected ~= 0 then
                        renderer_text(x + 35,y,255,255,255,255,flags,0,damage)
                    end
                elseif o_scoped then
                    
                    renderer_text(cx +5,cy - 15,r,g,b,self.vars.alpha3 * 255,flags,0,'DMG:')
                    renderer_text(cx + 5 + text_sizex + 3,cy - 15,255,255,255,self.vars.alpha3 * 255,flags,0,damage)

                    renderer_text(cx +5,cy - 15 -math_floor(12 * self.vars.alpha3),r,g,b,self.vars.alpha3 * 255,flags,0,'HC:')
                    renderer_text(cx + text_sizex,cy - 15-math_floor(12 * self.vars.alpha3),255,255,255,self.vars.alpha3 * 255,flags,0,hitchance)

                end
            end

            self.vars.alpha1 = animate.new(self.vars.alpha1,1,0,ui_get(xd.override_hitchance))
            self.vars.alpha2 = animate.new(self.vars.alpha2,1,0,ui_get(xd.override_hitbox))

            local text_1 = gradient_text(r,g,b,a*self.vars.alpha1,r1,g1,b1,a1*self.vars.alpha1,"HITCHANCE OVER")
            local text_2 = gradient_text(r,g,b,a*self.vars.alpha2,r1,g1,b1,a1*self.vars.alpha2,"HITBOX OVER")
            
            if self.vars.alpha2 >= 0.01 then
                renderer_indicator(255,255,255,255 * self.vars.alpha2,text_2)

            end
            if self.vars.alpha1 >= 0.01 then
                renderer_indicator(255,255,255,255 * self.vars.alpha1,text_1)
            end


            self.vars.alpha4 = animate.new(self.vars.alpha4,1,0,ui_get(xd.panel))

            self.vars.pX ,self.vars.pY = animate.new(self.vars.pX,px),animate.new(self.vars.pY,py)
            
            local render_rounded_rectangle = function(x, y, w, h, r, g, b, a, radius)
                y = y + radius
                local datacircle = {
                    {x + radius, y, 180},
                    {x + w - radius, y, 90},
                    {x + radius, y + h - radius * 2, 270},
                    {x + w - radius, y + h - radius * 2, 0},
                }
            
                local data = {
                    {x + radius, y, w - radius * 2, h - radius * 2},
                    {x + radius, y - radius, w - radius * 2, radius},
                    {x + radius, y + h - radius * 2, w - radius * 2, radius},
                    {x, y, radius, h - radius * 2},
                    {x + w - radius, y, radius, h - radius * 2},
                }
            
                for _, data in pairs(datacircle) do
                    renderer.circle(data[1], data[2], r, g, b, a, radius, data[3], 0.25)
                end
            
                for _, data in pairs(data) do
                   renderer.rectangle(data[1], data[2], data[3], data[4], r, g, b, a)
                end
            end

            local render_glow_rectangle = function(x,y,w,h,r,g,b,a,round,size,g_w)
                for i = 1 , size , 0.3 do 
                    local fixpositon = (i  - 1) * 2	 
                    local fixi = i  - 1
                    render_rounded_rectangle(x - fixi, y - fixi, w + fixpositon , h + fixpositon , r , g ,b , (a -  i * g_w) ,round)	
                end
            end


            -- back ground 

            for radius = 4, 12 do
                local radius = radius / 2;
                render_rounded_rectangle(self.vars.pX - 3 -4 - radius, self.vars.pY - radius, math_floor(66) + 8 + radius * 2,30 + radius * 2, r, g, b,
                            (12 - radius * 2)*self.vars.alpha4, radius)
            end
            

            render_rounded_rectangle(self.vars.pX - 3,self.vars.pY, 60 + 6 ,30,17,17,17,150 * self.vars.alpha4,6)

            --upper rect
            renderer_gradient(self.vars.pX,self.vars.pY,60,2,r,g,b,255 * self.vars.alpha4,r1,g1,b1,255 * self.vars.alpha4,true)

            --left O
            renderer_circle_outline(self.vars.pX, self.vars.pY+6, r, g, b, self.vars.alpha4*255,6,180,0.25,2)

            --bottm left 
            renderer_circle_outline(self.vars.pX, self.vars.pY+6 + 20, r,g,b, self.vars.alpha4*255,6,90,0.25,2)

            --right O
            renderer_circle_outline(self.vars.pX +60, self.vars.pY+6, r1,g1,b1, self.vars.alpha4*255,6,270,0.25,2)

            --bottom right
            renderer_circle_outline(self.vars.pX +60, self.vars.pY+6 + 20, r1,g1,b1, self.vars.alpha4*255,6,0,0.25,2)

            --left | rect
            renderer_rectangle(self.vars.pX - 6 , self.vars.pY+6 , 2,20,r,g,b,self.vars.alpha4*255)

            --right | rect
            renderer_rectangle(self.vars.pX - 6 + 66 + 4 , self.vars.pY+6 , 2,20,r1,g1,b1,self.vars.alpha4*255)

            --bottom rect
            renderer_gradient(self.vars.pX,self.vars.pY + 30,60,2,r,g,b,255 * self.vars.alpha4,r1,g1,b1,255 * self.vars.alpha4,true)

            local ind_offset = 0


            local keys = {
                [1] = {
                    ['condition'] = ui_get(u.g_menu.override_dmg),
                    ['text'] = 'OVERRIDE DMG',
                    ['color'] = {r,g,b,255 * self.vars.alpha4}
                
                },
   
                [2] = {
                    ['condition'] = ui_get(u.g_menu.override_hitchance),
                    ['text'] = 'OVER HC',
                    ['color'] = {r,g,b,255 * self.vars.alpha4}
                
                },
            }
            
            -- for k, items in pairs(keys) do
            --     local flags = '-'
            --     local text_width , text_height = renderer_measure_text(flags,items['text'])
            --     local key = items['condition'] and 1 or 0

            --     values[k] = animate.new(values[k],key)
            --     if k == 2 then
            --         ind_offset = ind_offset + 1 
            --     end
                
            --     local x , y = self.vars.pX,self.vars.pY

            --     renderer_text( 
            --         x,
            --         y +  ind_offset * values[k],
            --         items['color'][1],items['color'][2],items['color'][3],items['color'][4] * values[k] ,
            --         flags,
            --         text_width * values[k] + 3,
            --         items['text']
            --     )
        
        
            --     ind_offset = ind_offset + 9 * values[k]
            -- end

        end,

        register = function(self)
            self:on_render()
        end
    }

    local setup_force = function()
        local enemies = entity.get_players(true)
        for i = 1, #enemies do
            if enemies[i] == nil then return end
            local value = is_lethal(enemies[i]) and "Force" or "-"
            plist.set(enemies[i], "Override prefer body aim", value)
        end
    end

 
    local g_handle_callback = {
        on_paint_ui = function(self)
            handle_ovr()
            if not entity.is_alive(entity.get_local_player()) then return end
            g_paint:register()
        end,
        on_setup_command = function(self,cmd)
            setup(cmd)
        end,
        on_run_command = function(self,cmd)
            setup_force()
        end,
        on_call = function(self)
            local d = 0
            for k, v in pairs(u.call) do
                ui_set_callback(v,g_handle_menu.visible)
                d = k
            end
            ui_set_callback(u.g_menu.load_config,g_handle_menu.visible)
            ui_set_callback(u.g_menu.export_config,g_handle_menu.visible)
            ui_set_callback(u.g_menu.load_config,load_config)
            ui_set_callback(u.g_menu.export_config,export_config)

           

        end,
        register = function(self)
            self:on_call()
            client_set_event_callback('paint_ui',self.on_paint_ui)
            client_set_event_callback('setup_command',self.on_setup_command)
            client_set_event_callback('run_command',self.on_run_command)
        end

    }
    
    client.register_esp_flag("FORCE", 114,156,191, function(ent)
        return is_lethal(ent)
    end)
    g_handle_callback:register()
end

local http = require('gamesense/http')
http.get("https://pastebin.com/raw/kRMqsN5S",function(s,r)
    if not s or r.status ~= 200 then
        log("please check your Internet-work")
        log("QQ:3370971436")

        client_delay_call(
            1,
            function()
                log("please check your Internet-work")
            end
        )
        client_delay_call(
            2,
            function()
                log("please check your Internet-work")
            end
        )

        return
    end
    if r.body == "false" then
        log("closed")
        return
    end
end)
__main__()
