local vector = require 'vector'

local ffi = require('ffi')
local ffi_cast = ffi.cast

ffi.cdef [[
	typedef int(__thiscall* get_clipboard_text_count)(void*);
	typedef void(__thiscall* set_clipboard_text)(void*, const char*, int);
	typedef void(__thiscall* get_clipboard_text)(void*, int, const char*, int);
]]

local dependencies = {
    ["gamesense/csgo_weapons"] = "https://gamesense.pub/forums/viewtopic.php?id=18807",
}

local missing_libs = { }

for i, v in pairs(dependencies) do
    if not pcall(require, i) then
        missing_libs[#missing_libs + 1] = dependencies[i]
    end
end

for i=1, #missing_libs do
    error("Miss the lib: \n" .. table_concat(missing_libs, ", \n"))
end

local csgo_weapons = require "gamesense/csgo_weapons"

local includes = function (table,key)
    for i=1, #table do
      if table[i] == key then
        return true;
      end; 
    end;
    return false;
end

local function vtable_thunk(index, typedef)
    return function(v0, ...)
        local instance = ffi.cast(ffi.typeof('void***'), v0)

        local tdef = nil

        if seen[typedef] then
            tdef = seen[typedef]
        else
            tdef = ffi.typeof(typedef)

            seen[typedef] = tdef
        end

        return ffi.cast(tdef, instance[0][index])(instance, ...)
    end
end

local function vtable_bind(interface, index, typedef)
    local instance = ffi.cast('void***', interface);

    return function(...)
        return ffi.cast(typedef, instance[0][index])(instance, ...)
    end
end

local VGUI_System010 =  client.create_interface("vgui2.dll", "VGUI_System010") or print( "Error finding VGUI_System010")
local VGUI_System = ffi_cast(ffi.typeof('void***'), VGUI_System010 )

local IEngineClient__GetNetChannelInfo = vtable_bind("engine.dll", "VEngineClient014", 78, "void* (__thiscall*)(void* ecx)")
local INetChannelInfo__GetAvgLoss = vtable_thunk(11, "float (__thiscall*)(void* ecx, int flow)")
local INetChannelInfo__GetAvgChoke = vtable_thunk(12, "float (__thiscall*)(void* ecx, int flow)")

local get_clipboard_text_count = ffi_cast( "get_clipboard_text_count", VGUI_System[ 0 ][ 7 ] ) or print( "get_clipboard_text_count Invalid")
local set_clipboard_text = ffi_cast( "set_clipboard_text", VGUI_System[ 0 ][ 9 ] ) or print( "set_clipboard_text Invalid")
local get_clipboard_text = ffi_cast( "get_clipboard_text", VGUI_System[ 0 ][ 11 ] ) or print( "get_clipboard_text Invalid")

local function clipboard_import( )
  	local clipboard_text_length = get_clipboard_text_count( VGUI_System )
	local clipboard_data = ""

	if clipboard_text_length > 0 then
		buffer = ffi.new("char[?]", clipboard_text_length)
		size = clipboard_text_length * ffi.sizeof("char[?]", clipboard_text_length)

		get_clipboard_text( VGUI_System, 0, buffer, size )

		clipboard_data = ffi.string( buffer, clipboard_text_length-1 )
	end
	return clipboard_data
end

local function clipboard_export(string)
	if string then
		set_clipboard_text(VGUI_System, string, string:len())
	end
end

local function arr_to_string(arr)
	arr = ui.get(arr)
	local str = ""
	for i=1, #arr do
		str = str .. arr[i] .. (i == #arr and "" or ",")
	end

	if str == "" then
		str = "-"
	end

	return str
end

local function str_to_sub(input, sep)
	local t = {}
	for str in string.gmatch(input, "([^"..sep.."]+)") do
		t[#t + 1] = string.gsub(str, "\n", "")
	end
	return t
end

local function to_boolean(str)
	if str == "true" or str == "false" then
		return (str == "true")
	else
		return str
	end
end

local Time = '2024.02.04'

local weapon_name = { "Global", "Taser", "Revolver", "Pistol", "Auto", "Scout", "AWP", "Rifle", "SMG", "Shotgun", "Deagle" }
local name_to_num = { ["Global"] = 1, ["Taser"] = 2, ["Revolver"] = 3, ["Pistol"] = 4, ["Auto"] = 5, ["Scout"] = 6, ["AWP"] = 7, ["Rifle"] = 8, ["SMG"] = 9, ["Shotgun"] = 10, ["Deagle"] = 11 }
local weapon_idx_list = { [1] = 11, [2] = 4,[3] = 4,[4] = 4,[7] = 8,[8] = 8,[9] = 7,[10] = 8,[11] = 5,[13] = 8,[14] = 8,[16] = 8,[17] = 9,[19] = 9,[23] = 9,[24] = 9,[25] = 10,[26] = 9,[27] = 10,[28] = 8,[29] = 10,[30] = 4,[31] = 2,  [32] = 4,[33] = 9,[34] = 9,[35] = 10,[36] = 4,[38] = 5,[39] = 8,[40] = 6,[60] = 8,[61] = 4,[63] = 4,[64] = 3}
local damage_idx  = { [0] = "Auto", [101] = "HP + 1", [102] = "HP + 2", [103] = "HP + 3", [104] = "HP + 4", [105] = "HP + 5", [106] = "HP + 6", [107] = "HP + 7", [108] = "HP + 8", [109] = "HP + 9", [110] = "HP + 10", [111] = "HP + 11", [112] = "HP + 12", [113] = "HP + 13", [114] = "HP + 14", [115] = "HP + 15", [116] = "HP + 16", [117] = "HP + 17", [118] = "HP + 18", [119] = "HP + 19", [120] = "HP + 20", [121] = "HP + 21", [122] = "HP + 22", [123] = "HP + 23", [124] = "HP + 24", [125] = "HP + 25", [126] = "HP + 26" }
local scoped_wpn_idx = {
    name_to_num["Scout"],
    name_to_num["Auto"],
    name_to_num["AWP"],
}
local screen_size_x,screen_size_y = client.screen_size()
local weapon = {
    top_aimbot_2 = ui.new_label("Lua", "A","\n"),
    top_aimbot = ui.new_label("Lua", "A","\aE39DFFFF z z Z"),
    top_extra = ui.new_label("Lua", "B","\n"),
    top_aimbot_2 = ui.new_label("Lua", "B","\aE39DFFFF z z Z"),
    main_switch = ui.new_checkbox("Lua", "A", "\a89FFC0FFAdaptive Weapon   Update Time:"..Time..''),
    lua_label = ui.new_combobox("Lua", "A","\a89FFC0FFMin DMG Indicator:",{'Screen center','Skeet indicator'}),
    lua_clr = ui.new_color_picker("Lua", "A", "\a89FFC0FFMin DMG Indicator", 100,149,237, 255),
    draw_panel = ui.new_checkbox("Lua", "A", "\a89FFC0FFWeapon Indicator"),
    x = ui.new_slider("Lua", "A", "X", 0, screen_size_x, screen_size_x/4, true, "", 1),
    y = ui.new_slider("Lua", "A", "Y", 0, screen_size_y, screen_size_y/2, true, "", 1),
    run_hide = ui.new_checkbox("Lua", "A", "Hide skeet Lua menu"),
    high_pro = ui.new_multiselect("Lua", "A","High priority target:",{'Bomb carrier','AWP user'}),
    adjust = ui.new_checkbox("Lua", "A", "Adjust weapon selection in menu not opened"),
    allow_fake_ping = ui.new_checkbox("Lua", "A", "Allow ping-spike adjustment in lua"),
    fake_ping_key = ui.new_hotkey("Lua", "A", "Ping spike"),
    key_text = ui.new_label("Lua", "A","\a89FFC0FFOverride keys:"),
    available = ui.new_multiselect("Lua", "A","Active keys:",{'Min DMG','Hit chance','Hitbox','Multipoint','Unsafe hitbox','Quick stop','Delay shot'}),
    ovr_dmg = ui.new_hotkey("Lua", "A", "Key to override min damage 1"),
    ovr_dmg_2 = ui.new_hotkey("Lua", "A", "Key to override min damage 2"),
    ovr_dmg_smart = ui.new_hotkey("Lua", "A", "Key to override smart penetration dmg"),
    ovr_hc = ui.new_hotkey("Lua", "A", "Key to override hitchance 1"),
    ovr_hc_2 = ui.new_hotkey("Lua", "A", "Key to override hitchance 2"),
    ovr_box = ui.new_hotkey("Lua", "A", "Key to override hitbox 1"),
    ovr_box_2 = ui.new_hotkey("Lua", "A", "Key to override hitbox 2"),
    ovr_multi = ui.new_hotkey("Lua", "A", "Key to override muti-point"),
    ovr_unsafe = ui.new_hotkey("Lua", "A", "Key to override unsafe hitbox"),
    ovr_stop = ui.new_hotkey("Lua", "A", "Key to override quick stop"),
    ovr_forcehead = ui.new_hotkey("Lua", "A", "Key to force head"),
    ovr_delay = ui.new_hotkey("Lua", "A", "Key to enable delay shot"),
    key_text_1 = ui.new_label("Lua", "A","\a89FFC0FFWeapon config:"),
    weapon_select = ui.new_combobox("Lua", "A", "Weapon:", weapon_name),
}

weapon.cfg = {}

for i,o in ipairs(weapon_name) do 
    weapon.cfg[i] = {
        enable = ui.new_checkbox("Lua", "A", "Enable "..o.." config"),
        extra_feature = ui.new_multiselect("Lua", "A","["..o.."] Available extra tweak",{'Hitbox','Muti-point','Unsafe hitbox','Hitchance','Damage','Quick stop'}),
        target_selection = ui.new_combobox("Lua", "A", "[" .. o .. "] Target selection", {"Cycle", "Cycle (2x)", "Near crosshair", "Highest damage","Best hit chance"}),
        hitbox_text = ui.new_label("Lua", "A","------ Hitbox ------"),
        hitbox_mode = ui.new_multiselect("Lua", "A","["..o.."] Extra hitbox tweak",{'Double-tap','In-air','Override 1','Override 2'}), 
        target_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target hitbox", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        dt_target_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target hitbox \a89FFC0FF[Double-tap]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        air_target_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target hitbox \a89FFC0FF[In-air]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        ovr_target_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target hitbox \a89FFC0FF[Override 1]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        ovr_target_hitbox_2 = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target hitbox \a89FFC0FF[Override 2]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        multi_text = ui.new_label("Lua", "A","------ Muti-point ------"),
        multi_mode = ui.new_multiselect("Lua", "A","["..o.."] Extra multi-point tweak",{'Ping-spike','Double-tap','In-air','Override'}),
        multi_complex = ui.new_slider("Lua", "A", "[" .. o .. "] Target multi-point complexity",0,1,0,true,'',1, {[0] = 'Original',[1] = 'Visible/Autowall'}),
        target_multi = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        multipoint_scale = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        multi_hitbox_v = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Visible]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        multipoint_scale_v = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Visible]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        multi_hitbox_a = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Autowall]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        multipoint_scale_a = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Autowall]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        ping_avilble = ui.new_slider("Lua", "A", "[" .. o .. "] Therehold value \a89FFC0FF[Ping-spike]", 0, 200, 100, true),
        ping_multi_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Ping-spike]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        ping_multipoint_scale = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Ping-spike]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        dt_multi_complex = ui.new_slider("Lua", "A", "[" .. o .. "] Target multi-point complexity \a89FFC0FF[Double-tap]",0,1,0,true,'',1, {[0] = 'Original',[1] = 'Visible/Autowall'}),
        dt_multi_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Double-tap]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        dt_multipoint_scale = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Double-tap]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        dt_multi_hitbox_v = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Visible] \a87CEEBFF[Double-tap]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        dt_multipoint_scale_v = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Visible] \a87CEEBFF[Double-tap]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        dt_multi_hitbox_a = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Autowall] \a87CEEBFF[Double-tap]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        dt_multipoint_scale_a = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Autowall] \a87CEEBFF[Double-tap]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        air_multi_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[In-air]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        air_multipoint_scale = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[In-air]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        ovr_multi_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Target multi-point \a89FFC0FF[Override]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        ovr_multipoint_scale = ui.new_slider("Lua", "A", "[" .. o .. "] Multi-point scale \a89FFC0FF[Override]", 24, 100, 60, true, "%", 1, { [24] = "Auto" }),
        unsafe_text = ui.new_label("Lua", "A","------ Unsafe hitbox ------"),
        unsafe_mode = ui.new_multiselect("Lua", "A","["..o.."] Extra unsafe hitbox tweak",{'Double-tap','In-air','Override'}),
        unsafe_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Unsafe hitbox", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        dt_unsafe_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Unsafe hitbox \a89FFC0FF[Double-tap]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        air_unsafe_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Unsafe hitbox \a89FFC0FF[In-air]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        ovr_unsafe_hitbox = ui.new_multiselect("Lua", "A", "[" .. o .. "] Unsafe hitbox \a89FFC0FF[Override]", { "Head", "Chest", "Arms", "Stomach", "Legs", "Feet" }),
        general_text = ui.new_label("Lua", "A","------ General ------"),
        safepoint = ui.new_multiselect("Lua", "A", "[" .. o .. "] Prefer safepoint", { 'In-air','Double-tap','Always on' }),
        automatic_fire = ui.new_checkbox("Lua", "A", "[" .. o .. "] Automatic fire"),
        automatic_penetration = ui.new_checkbox("Lua", "A", "[" .. o .. "] Automatic penetration"),
        automatic_scope_e = ui.new_checkbox("Lua", "A", "[" .. o .. "] Automatic scope"),
        automatic_scope = ui.new_multiselect("Lua", "A", "[" .. o .. "] Automatic scope disabler",{'In distance','On doubletap'}),
        autoscope_therehold = ui.new_slider("Lua", "A", "[" .. o .. "] Therehold for distance", 0, 3000, 500, true, "f", 1),
        silent_aim = ui.new_checkbox("Lua", "A", "[" .. o .. "] Silent aim"),
        max = ui.new_slider("Lua", "A", "[" .. o .. "] Maximum FOV", 1, 180, 180, true, "°", 1),
        fps_boost = ui.new_multiselect("Lua", "A", "[" .. o .. "] Low FPS mitigations",{'Force low accuracy boost','Disable multipoint: feet','Disable multipoint: arms','Disable multipoint: legs','Disable hitbox: feet','Lower hit chance precision','Limit targets per tick'}),
        hitchance_text = ui.new_label("Lua", "A","------ Hit chance ------"),
        hitchance_mode = ui.new_multiselect("Lua", "A","["..o.."] Extra hitchance tweak",{'Double-tap','On-shot','Fake duck','In-air','Unscoped','Crouching','Override 1','Override 2'}),
        hitchance = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance ", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_ovr = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Override 1]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_ovr_2 = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Override 2]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_air = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[In-air]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_os = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[On-shot]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_fd = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Fake-duck]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_usc = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Unscoped]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_dt = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Double-tap]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),
        hitchance_cro = ui.new_slider("Lua", "A", "[" .. o .. "] Hitchance \a89FFC0FF[Crouching]", 0, 100, 60, true, "%", 1, { [0] = "Off" }),  
        damage_text = ui.new_label("Lua", "B","------ Damage ------"),
        damage_mode = ui.new_multiselect("Lua", "B","["..o.."] Extra Damage tweak",{'Double-tap','On-shot','Fake duck','In-air','Unscoped','Override 1','Override 2'}),
        damage_complex = ui.new_combobox("Lua", "B", "[" .. o .. "] Damage complexity",{'Original','Visible/autowall'}), 
        damage = ui.new_slider("Lua", "B", "[" .. o .. "] Damage ", 0, 126, 60, true,nil,1,damage_idx),
        damage_cro = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Visible]", 0, 126, 60, true,nil,1,damage_idx),
        damage_aut = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Autowall]", 0, 126, 60, true,nil,1,damage_idx),
        damage_ovr = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Override 1]", 0, 126, 60, true,nil,1,damage_idx),
        damage_ovr_2 = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Override 2]", 0, 126, 60, true,nil,1,damage_idx),
        damage_air = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[In-air]", 0, 126, 60, true,nil,1,damage_idx),
        damage_os = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[On-shot]", 0, 126, 60, true,nil,1,damage_idx),
        damage_fd = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Fake-duck]", 0, 126, 60, true,nil,1,damage_idx),
        damage_usc = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Unscoped]", 0, 126, 60, true,nil,1,damage_idx),   
        damage_complex_dt = ui.new_combobox("Lua", "B", "[" .. o .. "] Damage complexity \a89FFC0FF[Double-tap]",{'Original','Visible/autowall'}), 
        damage_dt = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Double-tap]", 0, 126, 60, true,nil,1,damage_idx),
        damage_cro_dt = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Visible] \a89FFC0FF[Double-tap]", 0, 126, 60, true,nil,1,damage_idx),
        damage_aut_dt = ui.new_slider("Lua", "B", "[" .. o .. "] Damage \a89FFC0FF[Autowall] \a89FFC0FF[Double-tap]", 0, 126, 60, true,nil,1,damage_idx),
        c = ui.new_label("Lua", "B","\n"),
        accuarcy_boost = ui.new_combobox("Lua", "B", "[" .. o .. "] Accuracy boost",{'Low','Medium','High','Maximum'}),
        delay_shot = ui.new_multiselect("Lua", "B", "[" .. o .. "] Delay shot",{'On key','Always on'}),
        stop_text = ui.new_label("Lua", "B","------ Quick stop ------"),
        stop_mode = ui.new_multiselect("Lua", "B","["..o.."] Extra Quick stop tweak",{'Double-tap','Unscoped','Override'}),
        stop = ui.new_checkbox("Lua", "B", "[" .. o .. "] Quick stop"),
        stop_option = ui.new_multiselect("Lua", "B", "[" .. o .. "] Quick stop options", {'Early','Slow motion','Duck','Fake duck','Move between shots','Ignore molotov','Taser','Jump scout'}),
        stop_dt = ui.new_checkbox("Lua", "B", "[" .. o .. "] Quick stop \a89FFC0FF[Double-tap]"),
        stop_option_dt = ui.new_multiselect("Lua", "B", "[" .. o .. "] Quick stop options \a89FFC0FF[Double-tap]", {'Early','Slow motion','Duck','Fake duck','Move between shots','Ignore molotov','Taser','Jump scout'}),
        stop_unscoped = ui.new_checkbox("Lua", "B", "[" .. o .. "] Quick stop \a89FFC0FF[Unscoped]"),
        stop_option_unscoped = ui.new_multiselect("Lua", "B", "[" .. o .. "] Quick stop options \a89FFC0FF[Unscoped]", {'Early','Slow motion','Duck','Fake duck','Move between shots','Ignore molotov','Taser','Jump scout'}),
        stop_ovr = ui.new_checkbox("Lua", "B", "[" .. o .. "] Quick stop \a89FFC0FF[Override]"),
        stop_option_ovr = ui.new_multiselect("Lua", "B", "[" .. o .. "] Quick stop options \a89FFC0FF[Override]", {'Early','Slow motion','Duck','Fake duck','Move between shots','Ignore molotov','Taser','Jump scout'}),
        ext_text = ui.new_label("Lua", "B","------ EXTRA ------"),
        fp = ui.new_combobox("Lua", "B", "[" .. o .. "] Use ping-spike",{'On key','Always on'}),
        preferbm = ui.new_checkbox("Lua", "B", "[" .. o .. "] Prefer body aim"),
        lethal = ui.new_checkbox("Lua", "B", "[" .. o .. "] Prefer lethal baim"),
        prefer_baim_disablers = ui.new_multiselect("Lua", "B", "[" .. o .. "] Prefer body aim disablers", {"Low inaccuracy", "Target shot fired", "Target resolved", "Safe point headshot",'High pitch','Side way'}),
        dt = ui.new_multiselect("Lua", "B",'['..o..'] Available doubletap option',{'Doubletap mode','Doubletap hitchance','Doubletap quick stop','Doubletap fakelag'}),
        doubletap_mode =  ui.new_combobox("Lua", "B", "[" .. o .. "] Double tap mode",{'Offensive','Defensive'}),
        doubletap_hc = ui.new_slider("Lua", "B", "[" .. o .. "] Double tap hit chance", 0, 100, 0, true, "%", 1),
        doubletap_fl = ui.new_slider("Lua", "B", "[" .. o .. "] Double tap fake lag limit", 1, 10, 1),
        doubletap_stop = ui.new_multiselect("Lua", "B", "[" .. o .. "] Double tap quick stop", { "Slow motion", "Duck", "Move between shots" }),
    }
end

local function export_cfg()
	local str = ""

    for i,o in ipairs(weapon_name) do 
		str = str .. tostring(ui.get(weapon.cfg[i].enable)) .. "|"
		.. arr_to_string((weapon.cfg[i].extra_feature)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].target_selection)) .. "|"
		.. arr_to_string((weapon.cfg[i].hitbox_mode)) .. "|"
		.. arr_to_string((weapon.cfg[i].target_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].dt_target_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].air_target_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].ovr_target_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].ovr_target_hitbox_2)) .. "|"
		.. arr_to_string((weapon.cfg[i].multi_mode)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].multi_complex)) .. "|"
		.. arr_to_string((weapon.cfg[i].target_multi)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].multipoint_scale)) .. "|"
		.. arr_to_string((weapon.cfg[i].multi_hitbox_v)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].multipoint_scale_v)) .. "|"
		.. arr_to_string((weapon.cfg[i].multi_hitbox_a)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].multipoint_scale_a)) .. "|"

        .. tostring(ui.get(weapon.cfg[i].ping_avilble)) .. "|"
		.. arr_to_string((weapon.cfg[i].ping_multi_hitbox)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].ping_multipoint_scale)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].dt_multi_complex)) .. "|"
		.. arr_to_string((weapon.cfg[i].dt_multi_hitbox)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].dt_multipoint_scale)) .. "|"
		.. arr_to_string((weapon.cfg[i].dt_multi_hitbox_v)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].dt_multipoint_scale_v)) .. "|"
		.. arr_to_string((weapon.cfg[i].dt_multi_hitbox_a)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].dt_multipoint_scale_a)) .. "|"
		.. arr_to_string((weapon.cfg[i].air_multi_hitbox)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].air_multipoint_scale)) .. "|"
		.. arr_to_string((weapon.cfg[i].ovr_multi_hitbox)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].ovr_multipoint_scale)) .. "|"
		.. arr_to_string((weapon.cfg[i].unsafe_mode)) .. "|"
		.. arr_to_string((weapon.cfg[i].unsafe_hitbox)) .. "|"

        .. arr_to_string((weapon.cfg[i].dt_unsafe_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].ovr_unsafe_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].air_unsafe_hitbox)) .. "|"
		.. arr_to_string((weapon.cfg[i].safepoint)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].automatic_fire)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].automatic_penetration)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].automatic_scope_e)) .. "|"
		.. arr_to_string((weapon.cfg[i].automatic_scope)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].autoscope_therehold)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].silent_aim)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].max)) .. "|"
		.. arr_to_string((weapon.cfg[i].fps_boost)) .. "|"
		.. arr_to_string((weapon.cfg[i].hitchance_mode)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_ovr)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_ovr_2)) .. "|"

        .. tostring(ui.get(weapon.cfg[i].hitchance_air)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_os)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_fd)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_usc)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].hitchance_cro)) .. "|"
		.. arr_to_string((weapon.cfg[i].damage_mode)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].damage_complex)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_cro)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].damage_aut)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_ovr)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_ovr_2)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_air)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_os)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_fd)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_usc)) .. "|"

        .. tostring(ui.get(weapon.cfg[i].damage_complex_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_cro_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].damage_aut_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].accuarcy_boost)) .. "|"
		.. arr_to_string((weapon.cfg[i].delay_shot)) .. "|"
		.. arr_to_string((weapon.cfg[i].stop_mode)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].stop)) .. "|"
		.. arr_to_string((weapon.cfg[i].stop_option)) .. "|"
        .. tostring(ui.get(weapon.cfg[i].stop_dt)) .. "|"
		.. arr_to_string((weapon.cfg[i].stop_option_dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].stop_unscoped)) .. "|"
		.. arr_to_string((weapon.cfg[i].stop_option_unscoped)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].stop_ovr)) .. "|"
		.. arr_to_string((weapon.cfg[i].stop_option_ovr)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].fp)) .. "|"

        .. tostring(ui.get(weapon.cfg[i].preferbm)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].lethal)) .. "|"
		.. arr_to_string((weapon.cfg[i].prefer_baim_disablers)) .. "|"
		.. arr_to_string((weapon.cfg[i].dt)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].doubletap_mode)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].doubletap_hc)) .. "|"
		.. tostring(ui.get(weapon.cfg[i].doubletap_fl)) .. "|"
		.. arr_to_string((weapon.cfg[i].doubletap_stop)) .. "|"
	end

	clipboard_export(str)
end

local function load_cfg()
	local tbl = str_to_sub(clipboard_import(), "|")

    for i,o in ipairs(weapon_name) do 
		ui.set(weapon.cfg[i].enable, to_boolean(tbl[1 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].extra_feature, str_to_sub(tbl[2 + (90 * (i - 1))],","))
        ui.set(weapon.cfg[i].target_selection, tbl[3 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].hitbox_mode, str_to_sub(tbl[4 + (90 * (i - 1))], ","))
        ui.set(weapon.cfg[i].target_hitbox, str_to_sub(tbl[5 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].dt_target_hitbox, str_to_sub(tbl[6 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].air_target_hitbox, str_to_sub(tbl[7 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].ovr_target_hitbox, str_to_sub(tbl[8 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].ovr_target_hitbox_2, str_to_sub(tbl[9 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].multi_mode, str_to_sub(tbl[10 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].multi_complex, tbl[11 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].target_multi, str_to_sub(tbl[12 + (90 * (i - 1))], ","))	
		ui.set(weapon.cfg[i].multipoint_scale, tbl[13 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].multi_hitbox_v, str_to_sub(tbl[14 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].multipoint_scale_v, tbl[15 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].multi_hitbox_a, str_to_sub(tbl[16 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].multipoint_scale_a, tbl[17 + (90 * (i - 1))])

		ui.set(weapon.cfg[i].ping_avilble, (tbl[18 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].ping_multi_hitbox, str_to_sub(tbl[19 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].ping_multipoint_scale, (tbl[20 + (90 * (i - 1))]))	
		ui.set(weapon.cfg[i].dt_multi_complex, tbl[21 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].dt_multi_hitbox, str_to_sub(tbl[22 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].dt_multipoint_scale, tbl[23 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].dt_multi_hitbox_v, str_to_sub(tbl[24 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].dt_multipoint_scale_v, tbl[25 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].dt_multi_hitbox_a, str_to_sub(tbl[26 + (90 * (i - 1))], ","))
        ui.set(weapon.cfg[i].dt_multipoint_scale_a, (tbl[27 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].air_multi_hitbox, str_to_sub(tbl[28 + (90 * (i - 1))], ","))	
		ui.set(weapon.cfg[i].air_multipoint_scale, tbl[29 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].ovr_multi_hitbox, str_to_sub(tbl[30 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].ovr_multipoint_scale, tbl[31 + (90 * (i - 1))])
		ui.set(weapon.cfg[i].unsafe_mode, str_to_sub(tbl[32 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].unsafe_hitbox, str_to_sub(tbl[33 + (90 * (i - 1))], ","))

		ui.set(weapon.cfg[i].dt_unsafe_hitbox, str_to_sub(tbl[34 + (90 * (i - 1))], ","))
        ui.set(weapon.cfg[i].air_unsafe_hitbox, str_to_sub(tbl[35 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].ovr_unsafe_hitbox, str_to_sub(tbl[36 + (90 * (i - 1))], ","))	
		ui.set(weapon.cfg[i].safepoint, to_boolean(tbl[37 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].automatic_fire, to_boolean(tbl[38 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].automatic_penetration, to_boolean(tbl[39 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].automatic_scope_e, to_boolean(tbl[40 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].automatic_scope, str_to_sub(tbl[41 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].autoscope_therehold, (tbl[42 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].silent_aim, to_boolean(tbl[43 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].max, (tbl[44 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].fps_boost, str_to_sub(tbl[45 + (90 * (i - 1))], ","))
        ui.set(weapon.cfg[i].hitchance_mode, str_to_sub(tbl[46 + (90 * (i - 1))], ","))	
		ui.set(weapon.cfg[i].hitchance, (tbl[47 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].hitchance_ovr, (tbl[48 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].hitchance_ovr_2, (tbl[49 + (90 * (i - 1))]))

		ui.set(weapon.cfg[i].hitchance_air, (tbl[50 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].hitchance_os, (tbl[51 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].hitchance_fd, (tbl[52 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].hitchance_usc, (tbl[53 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].hitchance_dt, (tbl[54 + (90 * (i - 1))]))	
		ui.set(weapon.cfg[i].hitchance_cro, (tbl[55 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_mode, str_to_sub(tbl[56 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].damage_complex, (tbl[57 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage, (tbl[58 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_cro, (tbl[59 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_aut, (tbl[60 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].damage_ovr, (tbl[61 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_ovr_2, (tbl[62 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_air, (tbl[63 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].damage_os, (tbl[64 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_fd, (tbl[65 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_usc, (tbl[66 + (90 * (i - 1))]))

        ui.set(weapon.cfg[i].damage_complex_dt, (tbl[67 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_dt, (tbl[68 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].damage_cro_dt, (tbl[69 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].damage_aut_dt, (tbl[70 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].accuarcy_boost, (tbl[71 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].delay_shot, str_to_sub(tbl[72 + (90 * (i - 1))], ","))	
		ui.set(weapon.cfg[i].stop_mode, str_to_sub(tbl[73 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].stop, to_boolean(tbl[74 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].stop_option, str_to_sub(tbl[75 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].stop_dt, to_boolean(tbl[76 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].stop_option_dt, str_to_sub(tbl[77 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].stop_unscoped, to_boolean(tbl[78 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].stop_option_unscoped, str_to_sub(tbl[79 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].stop_ovr, to_boolean(tbl[80 + (90 * (i - 1))]))	
		ui.set(weapon.cfg[i].stop_option_ovr, str_to_sub(tbl[81 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].fp, (tbl[82 + (90 * (i - 1))]))

		ui.set(weapon.cfg[i].preferbm, to_boolean(tbl[83 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].lethal, to_boolean(tbl[84 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].prefer_baim_disablers, str_to_sub(tbl[85 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].dt, str_to_sub(tbl[86 + (90 * (i - 1))], ","))
		ui.set(weapon.cfg[i].doubletap_mode, (tbl[87 + (90 * (i - 1))]))
        ui.set(weapon.cfg[i].doubletap_hc, (tbl[88 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].doubletap_fl, (tbl[89 + (90 * (i - 1))]))
		ui.set(weapon.cfg[i].doubletap_stop, str_to_sub(tbl[90 + (90 * (i - 1))], ","))
	end


end

ui.new_label("Lua", "A","\n")
ui.new_label("Lua", "B","\n")
local cfg1 = ui.new_label("Lua", "B","Configuration ->")
local cfg2 = ui.new_button("Lua", "B",'\a89FFC0FFExport CFG',export_cfg)
local cfg3 = ui.new_button("Lua", "B",'\a89FFC0FFImport CFG',load_cfg)

local ref_enabled, ref_enabledkey = ui.reference("RAGE", "Aimbot", "Enabled")
local ref_fov = ui.reference("RAGE", "Other", "Maximum FOV")
local ref_target_selection = ui.reference("RAGE", "Aimbot", "Target selection")
local ref_target_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local ref_multipoint, ref_multipointkey = ui.reference("RAGE", "Aimbot", "Multi-point")
local ref_unsafe = ui.reference("RAGE", "Aimbot", "Avoid unsafe hitboxes")
local ref_multipoint_scale = ui.reference("RAGE", "Aimbot", "Multi-point scale")
local ref_prefer_safepoint = ui.reference("RAGE", "Aimbot", "Prefer safe point")
local ref_force_safepoint = ui.reference("RAGE", "Aimbot", "Force safe point")
local ref_automatic_fire = ui.reference("RAGE", "Other", "Automatic fire")
local ref_automatic_penetration = ui.reference("RAGE", "Other", "Automatic penetration")
local ref_silent_aim = ui.reference("RAGE", "Other", "Silent aim")
local ref_hitchance = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
local ref_mindamage = ui.reference("RAGE", "Aimbot", "Minimum damage")
local ref_automatic_scope = ui.reference("RAGE", "Aimbot", "Automatic scope")
local ref_reduce_aimstep = ui.reference("RAGE", "Other", "Reduce aim step")
local ref_log_spread = ui.reference("RAGE", "Other", "Log misses due to spread")
local ref_low_fps_mitigations = ui.reference("RAGE", "Other", "Low FPS mitigations")
local ref_remove_recoil = ui.reference("RAGE", "Other", "Remove recoil")
local ref_accuracy_boost = ui.reference("RAGE", "Other", "Accuracy boost")
local ref_delay_shot = ui.reference("RAGE", "Other", "Delay shot")
local ref_quickstop, ref_quickstopkey, ref_quickstop_options= ui.reference("RAGE", "Aimbot", "Quick stop")
local ref_quickpeek, ref_quickpeek_key, ref_quickpeek_mode = ui.reference("RAGE", "Other", "Quick peek assist")
local ref_antiaim_correction = ui.reference("RAGE", "Other", "Anti-aim correction")
local ref_prefer_bodyaim = ui.reference("RAGE", "Aimbot", "Prefer body aim")
local ref_prefer_bodyaim_disablers = ui.reference("RAGE", "Aimbot", "Prefer body aim disablers")
local ref_force_bodyaim = ui.reference("RAGE", "Aimbot", "Force body aim")
local ref_duck_peek_assist = ui.reference("RAGE", "Other", "Duck peek assist")
local ref_doubletap, ref_doubletapkey,ref_doubletap_mode = ui.reference("RAGE", "Aimbot", "Double tap")
local ref_slowwalk, ref_slowwalk_key = ui.reference("AA", "Other", "Slow motion")
local ref_osaa, ref_osaakey = ui.reference("AA", "Other", "On shot anti-aim")
local ref_doubletap_hc = ui.reference("RAGE", "Aimbot", "Double tap hit chance")
local ref_doubletap_stop = ui.reference("RAGE", "Aimbot", "Double tap quick stop")
local ref_doubletap_fl = ui.reference("RAGE", "Aimbot", "Double tap fake lag limit")
local ping_spike = { ui.reference("MISC", "Miscellaneous", "Ping spike") }

local function hide_skeet()
    local disable_show = not ui.get(weapon.run_hide)
    ui.set_visible(ref_enabled,disable_show)
    ui.set_visible(ref_log_spread,disable_show)
    ui.set_visible(ref_fov,disable_show)
    ui.set_visible(ref_enabledkey,disable_show)
    ui.set_visible(ref_remove_recoil,disable_show)
    ui.set_visible(ref_reduce_aimstep,disable_show)
    ui.set_visible(ref_target_selection,disable_show)
    ui.set_visible(ref_target_hitbox,disable_show)
    ui.set_visible(ref_multipoint,disable_show)
    ui.set_visible(ref_multipointkey,disable_show)
    ui.set_visible(ref_unsafe,disable_show)
    ui.set_visible(ref_multipoint_scale,disable_show)
    ui.set_visible(ref_prefer_safepoint,disable_show)
    ui.set_visible(ref_automatic_fire,disable_show)
    ui.set_visible(ref_automatic_penetration,disable_show)
    ui.set_visible(ref_silent_aim,disable_show)
    ui.set_visible(ref_hitchance,disable_show)
    ui.set_visible(ref_mindamage,disable_show)
    ui.set_visible(ref_automatic_scope,disable_show)
    ui.set_visible(ref_low_fps_mitigations,disable_show)
    ui.set_visible(ref_accuracy_boost,disable_show)
    ui.set_visible(ref_delay_shot,disable_show)
    ui.set_visible(ref_doubletap_fl,disable_show)
    ui.set_visible(ref_quickstop,disable_show)
    ui.set_visible(ref_quickstopkey,disable_show)
    ui.set_visible(ref_quickstop_options,disable_show)
    ui.set_visible(ref_prefer_bodyaim,disable_show)
    ui.set_visible(ref_prefer_bodyaim_disablers,disable_show)
    ui.set_visible(ref_doubletap_hc,disable_show)
    ui.set_visible(ref_doubletap_stop,disable_show)
    ui.set_visible(ref_doubletap_mode,disable_show)
end

local function in_air()
    if entity.get_local_player( ) == nil then return false end
    return bit.band( entity.get_prop( entity.get_local_player( ), "m_fFlags" ), 1 ) == 0
end

local check = {0,3,8}

local function enemy_visible(idx)

    if idx == nil then return false end

    for k, v in pairs(check) do

        local cx, cy, cz = entity.hitbox_position(idx, v)
        if client.visible(cx, cy, cz) then
            return true
        end

    end
    return false
end

local vector_angles = function(x1, y1, z1, x2, y2, z2)
    local origin_x, origin_y, origin_z
    local target_x, target_y, target_z
    if x2 == nil then
        target_x, target_y, target_z = x1, y1, z1
        origin_x, origin_y, origin_z = client.eye_position()
        if origin_x == nil then
            return
        end
    else
        origin_x, origin_y, origin_z = x1, y1, z1
        target_x, target_y, target_z = x2, y2, z2
    end

    local delta_x, delta_y, delta_z = target_x-origin_x, target_y-origin_y, target_z-origin_z

    if delta_x == 0 and delta_y == 0 then
        return (delta_z > 0 and 270 or 90), 0
    else

        local yaw = math.deg(math.atan2(delta_y, delta_x))


        local hyp = math.sqrt(delta_x*delta_x + delta_y*delta_y)
        local pitch = math.deg(math.atan2(-delta_z, hyp))

        return pitch, yaw
    end
end

local normalize_yaw = function(yaw)
    while yaw > 180 do yaw = yaw - 360 end
    while yaw < -180 do yaw = yaw + 360 end

    return yaw
end

local is_player_moving = function(ent)
    local vec_vel = { entity.get_prop(ent, 'm_vecVelocity') }
    local velocity = math.floor(math.sqrt(vec_vel[1]^2 + vec_vel[2]^2) + 0.5)

    return velocity > 1
end

local predict_positions = function(posx, posy, posz, ticks, ent)
    local x, y, z = entity.get_prop(ent, 'm_vecVelocity')

    for i = 0, ticks, 1 do
        posx = posx + x * globals.tickinterval()
        posy = posy + y * globals.tickinterval()
        posz = posz + z * globals.tickinterval() + 9.81 * globals.tickinterval() * globals.tickinterval() / 2
    end

    return posx, posy, posz
end

local calculate_damage = function(local_player, target, predictive)

    local entindex, dmg = -1, -1
    local lx, ly, lz = client.eye_position()

    local px, py, pz = entity.hitbox_position(target, 6) -- middle chest
    local px1, py1, pz1 = entity.hitbox_position(target, 4) -- upper chest
    local px2, py2, pz2 = entity.hitbox_position(target, 2) -- pelvis

    if predictive and is_player_moving(local_player) then
        lx, ly, lz = predict_positions(lx, ly, lz, 20, local_player)
    end
    
    for i=0, 2 do
        if i == 0 then
            entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px, py, pz)
        else 
            if i==1 then
                entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px1, py1, pz1)
            else
                entindex, dmg = client.trace_bullet(local_player, lx, ly, lz, px2, py2, pz2)
            end
        end

        if entindex == nil or entindex == local_player or not entity.is_enemy(entindex) then
            return -1
        end
        
        return dmg
    end

    return -1
end

local clamp = function(v, min, max)
    return ((v > max) and max) or ((v < min) and min or v)
end

local function angle_forward(angle) 
    local sin_pitch = math.sin(math.rad(angle[1]))
    local cos_pitch = math.cos(math.rad(angle[1]))
    local sin_yaw = math.sin(math.rad(angle[2]))
    local cos_yaw = math.cos(math.rad(angle[2]))

    return {        
        cos_pitch * cos_yaw,
        cos_pitch * sin_yaw,
        -sin_pitch
    }
end

function weapon:get_weapon_idx()
    local local_player = entity.get_local_player()
    if local_player == nil then return nil end
    local weapon_ent = entity.get_player_weapon(local_player)
    if weapon_ent == nil then return nil end
    local weapon_idx = bit.band(entity.get_prop(weapon_ent, "m_iItemDefinitionIndex"), 0xFFFF)
    if weapon_idx == nil then return nil end
    local get_idx = weapon_idx_list[weapon_idx] ~= nil and weapon_idx_list[weapon_idx] or 1
    return get_idx
end

function weapon:recorrect()
    local idx = self:get_weapon_idx()
    if idx == nil then return 1 end
    if ui.get(self.cfg[idx].enable) then
        return idx
    else     
        return 1
    end
end

function weapon:get_hitbox(idx)
    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Hitbox')
    if ui.get(self.ovr_forcehead) and includes(ui.get(self.available),'Hitbox') then
        return {'Head'}
    elseif ui.get(self.ovr_box) and includes(ui.get(self.available),'Hitbox') and includes(ui.get(self.cfg[idx].hitbox_mode),'Override 1') and complex then
        return ui.get(self.cfg[idx].ovr_target_hitbox) -- override 1
    elseif ui.get(self.ovr_box_2) and includes(ui.get(self.available),'Hitbox') and includes(ui.get(self.cfg[idx].hitbox_mode),'Override 2') and complex then
        return ui.get(self.cfg[idx].ovr_target_hitbox_2) -- override 2
    elseif in_air() and includes(ui.get(self.cfg[idx].hitbox_mode),'In-air') and complex then
        return ui.get(self.cfg[idx].air_target_hitbox) -- air
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].hitbox_mode),'Double-tap') and complex then
        return ui.get(self.cfg[idx].dt_target_hitbox) -- dt
    end
    return ui.get(self.cfg[idx].target_hitbox) -- global
end

local is_visible = false

function weapon:get_multipoint(idx)
    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Muti-point')

    if ui.get(self.ovr_multi) and includes(ui.get(self.available),'Multipoint') and includes(ui.get(self.cfg[idx].multi_mode),'Override') and complex then
        return { [1] = ui.get(self.cfg[idx].ovr_multi_hitbox) , [2] = ui.get(self.cfg[idx].ovr_multipoint_scale) } -- override
    elseif ui.get(ping_spike[1]) and ui.get(ping_spike[2]) and ui.get(ping_spike[3]) >= ui.get(self.cfg[idx].ping_avilble) and includes(ui.get(weapon.cfg[idx].multi_mode),'Ping-spike') and complex then
        return { [1] = ui.get(self.cfg[idx].ping_multi_hitbox) , [2] = ui.get(self.cfg[idx].ping_multipoint_scale)} -- ping spike
    elseif in_air() and includes(ui.get(self.cfg[idx].multi_mode),'In-air') and complex then
        return { [1] = ui.get(self.cfg[idx].air_multi_hitbox) , [2] = ui.get(self.cfg[idx].air_multipoint_scale)} -- inair
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].multi_mode),'Double-tap') and complex then
        if ui.get(self.cfg[idx].dt_multi_complex) == 0 then
            return { [1] = ui.get(self.cfg[idx].dt_multi_hitbox) , [2] = ui.get(self.cfg[idx].dt_multipoint_scale) } -- dt
        elseif ui.get(self.cfg[idx].dt_multi_complex) == 1 and is_visible then
            return { [1] = ui.get(self.cfg[idx].dt_multi_hitbox_v) , [2] = ui.get(self.cfg[idx].dt_multipoint_scale_v) } -- dt
        elseif ui.get(self.cfg[idx].dt_multi_complex) == 1 and not is_visible then
            return { [1] = ui.get(self.cfg[idx].dt_multi_hitbox_a) , [2] = ui.get(self.cfg[idx].dt_multipoint_scale_a) } -- dt
        end
    end
    if ui.get(self.cfg[idx].multi_complex) == 0  or not includes(ui.get(weapon.cfg[idx].extra_feature),'Muti-point') then
        return { [1] = ui.get(self.cfg[idx].target_multi) , [2] = ui.get(self.cfg[idx].multipoint_scale) } -- dt
    elseif ui.get(self.cfg[idx].multi_complex) == 1 and is_visible then
        return { [1] = ui.get(self.cfg[idx].multi_hitbox_v) , [2] = ui.get(self.cfg[idx].multipoint_scale_v) } -- dt
    elseif ui.get(self.cfg[idx].multi_complex) == 1 and not is_visible then
        return { [1] = ui.get(self.cfg[idx].multi_hitbox_a) , [2] = ui.get(self.cfg[idx].multipoint_scale_a) } -- dt
    end
end

function weapon:get_unsafe_hitbox(idx)
    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Unsafe hitbox')
    if ui.get(self.ovr_unsafe) and includes(ui.get(self.available),'Unsafe hitbox') and includes(ui.get(self.cfg[idx].unsafe_mode),'Override') and complex then
        return ui.get(self.cfg[idx].ovr_unsafe_hitbox) -- override
    elseif in_air() and includes(ui.get(self.cfg[idx].unsafe_mode),'In-air') and complex then
        return ui.get(self.cfg[idx].air_unsafe_hitbox) -- inair
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].unsafe_mode),'Double-tap') and complex then
        return ui.get(self.cfg[idx].dt_unsafe_hitbox) -- dt
    end
    return ui.get(self.cfg[idx].unsafe_hitbox) -- global
end

function weapon:get_prefer_safe_point(idx)
    if includes(ui.get(self.cfg[idx].safepoint),'Always on') then
        return true
    elseif includes(ui.get(self.cfg[idx].safepoint),'In-air') and in_air() then
        return true
    elseif includes(ui.get(self.cfg[idx].safepoint),'Double-tap') and ui.get(ref_doubletap) and ui.get(ref_doubletapkey) then
        return true
    end
    return false
end

function weapon:get_dis()
    local target = client.current_threat()
    if target == nil then return 99999999 end
    local target_vector = vector(entity.get_origin(target))

    local local_player = entity.get_local_player()
    if local_player == nil then return 99999999 end
    local local_vector = vector(entity.get_origin(local_player))

    local dis = local_vector:dist(target_vector)
    return dis
end

function weapon:get_scope(idx)
    if not ui.get(self.cfg[idx].automatic_scope_e) then
        return false
    end
    local dis = self:get_dis()
    if includes(ui.get(self.cfg[idx].automatic_scope),'In distance') and dis < ui.get(self.cfg[idx].autoscope_therehold) then
        return false
    elseif includes(ui.get(self.cfg[idx].automatic_scope),'On doubletap') and ui.get(ref_doubletap) and ui.get(ref_doubletapkey) then
        return false
    end
    return true
end

function weapon:get_hitchance(idx)

    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Hitchance')
    if ui.get(self.ovr_hc) and includes(ui.get(self.available),'Hit chance') and includes(ui.get(self.cfg[idx].hitchance_mode),'Override 1') and complex then
        return ui.get(self.cfg[idx].hitchance_ovr) -- override 1
    elseif ui.get(self.ovr_hc_2) and includes(ui.get(self.available),'Hit chance') and includes(ui.get(self.cfg[idx].hitchance_mode),'Override 2') and complex then
        return ui.get(self.cfg[idx].hitchance_ovr_2) -- override 2
    elseif in_air() and includes(ui.get(self.cfg[idx].hitchance_mode),'In-air') and complex then
        return ui.get(self.cfg[idx].hitchance_air) -- air
    elseif ui.get(ref_duck_peek_assist) and includes(ui.get(self.cfg[idx].hitchance_mode),'Fake duck') and complex then
        return ui.get(self.cfg[idx].hitchance_fd) -- fd
    elseif ui.get(ref_osaa) and ui.get(ref_osaakey) and includes(ui.get(self.cfg[idx].hitchance_mode),'On-shot') and complex then
        return ui.get(self.cfg[idx].hitchance_os) -- os
    elseif entity.get_prop(entity.get_local_player(),'m_bIsScoped') == 0 and includes(ui.get(self.cfg[idx].hitchance_mode),'Unscoped') and complex and includes(scoped_wpn_idx,idx) then
        return ui.get(self.cfg[idx].hitchance_usc) -- scope
    elseif entity.get_prop(entity.get_local_player(), "m_flDuckAmount") > 0.8 and includes(ui.get(self.cfg[idx].hitchance_mode),'Crouching') and complex then
        return ui.get(self.cfg[idx].hitchance_cro) -- duck
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].hitchance_mode),'Double-tap') and complex then
        return ui.get(self.cfg[idx].hitchance_dt) -- dt
    end
    return ui.get(self.cfg[idx].hitchance) -- global

end

function weapon:get_damage(idx)

    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Damage')
    if ui.get(self.ovr_dmg) and includes(ui.get(self.available),'Min DMG') and includes(ui.get(self.cfg[idx].damage_mode),'Override 1') and complex then
        return ui.get(self.cfg[idx].damage_ovr)
    elseif ui.get(self.ovr_dmg_2) and includes(ui.get(self.available),'Min DMG') and includes(ui.get(self.cfg[idx].damage_mode),'Override 2') and complex then
        return ui.get(self.cfg[idx].damage_ovr_2)
    elseif in_air() and includes(ui.get(self.cfg[idx].damage_mode),'In-air') and complex then
        return ui.get(self.cfg[idx].damage_air) -- air
    elseif ui.get(ref_duck_peek_assist) and includes(ui.get(self.cfg[idx].damage_mode),'Fake duck') and complex then
        return ui.get(self.cfg[idx].damage_fd) -- fd
    elseif ui.get(ref_osaa) and ui.get(ref_osaakey) and includes(ui.get(self.cfg[idx].damage_mode),'On-shot') and complex then
        return ui.get(self.cfg[idx].damage_os) -- os
    elseif includes(ui.get(self.cfg[idx].damage_mode),'Unscoped') and entity.get_prop(entity.get_local_player(),'m_bIsScoped') == 0 and complex and includes(scoped_wpn_idx,idx) then
        return ui.get(self.cfg[idx].damage_usc) -- scope
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].damage_mode),'Double-tap') and complex then
        
        if ui.get(self.cfg[idx].damage_complex_dt) == 'Original' then
            return ui.get(self.cfg[idx].damage_dt)
        elseif ui.get(self.cfg[idx].damage_complex_dt) == 'Visible/autowall' and is_visible then
            return ui.get(self.cfg[idx].damage_cro_dt)
        elseif ui.get(self.cfg[idx].damage_complex_dt) == 'Visible/autowall' and not is_visible then
            return ui.get(self.cfg[idx].damage_aut_dt)
        end
    end

    if ui.get(self.cfg[idx].damage_complex) == 'Original' or not includes(ui.get(self.cfg[idx].extra_feature),'Damage') then
        return ui.get(self.cfg[idx].damage)
    elseif ui.get(self.cfg[idx].damage_complex) == 'Visible/autowall' and is_visible then
        return ui.get(self.cfg[idx].damage_cro)
    elseif ui.get(self.cfg[idx].damage_complex) == 'Visible/autowall' and not is_visible then
        return ui.get(self.cfg[idx].damage_aut)
    end

end

function weapon:get_delay(idx)
    if includes(ui.get(self.cfg[idx].delay_shot),'Always on') then
        return true
    elseif includes(ui.get(self.cfg[idx].delay_shot),'On key') and includes(ui.get(self.available),'Delay shot') and ui.get(self.ovr_delay) then
        return true
    end
    return false
end

function weapon:get_stop(idx)
    local complex = includes(ui.get(self.cfg[idx].extra_feature),'Quick stop')

    if ui.get(self.ovr_stop) and includes(ui.get(self.available),'Quick stop') and includes(ui.get(self.cfg[idx].stop_mode),'Override') and complex then
        return { [1] = ui.get(self.cfg[idx].stop_ovr) , [2] = ui.get(self.cfg[idx].stop_option_ovr) }
    elseif entity.get_prop(entity.get_local_player(),'m_bIsScoped') == 0 and includes(ui.get(self.cfg[idx].stop_mode),'Unscoped') and complex and includes(scoped_wpn_idx,idx) then
        return { [1] = ui.get(self.cfg[idx].stop_unscoped) , [2] = ui.get(self.cfg[idx].stop_option_unscoped) }
    elseif ui.get(ref_doubletap) and ui.get(ref_doubletapkey) and includes(ui.get(self.cfg[idx].stop_mode),'Double-tap') and complex then
        return { [1] = ui.get(self.cfg[idx].stop_dt) , [2] = ui.get(self.cfg[idx].stop_option_dt) }
    end
    return { [1] = ui.get(self.cfg[idx].stop) , [2] = ui.get(self.cfg[idx].stop_option) }
end

function weapon:get_baim(idx)
    if ui.get(self.ovr_forcehead) and includes(ui.get(self.available),'Hitbox') then
        return false
    end
    return ui.get(self.cfg[idx].preferbm)
end

function weapon:disabler(idx)

    local disable_list = {}

    if includes(ui.get(self.cfg[idx].prefer_baim_disablers),"Low inaccuracy") then
        table.insert(disable_list,"Low inaccuracy")
    end

    if includes(ui.get(self.cfg[idx].prefer_baim_disablers),"Target shot fired") then
        table.insert(disable_list,"Target shot fired")
    end

    if includes(ui.get(self.cfg[idx].prefer_baim_disablers),"Target resolved") then
        table.insert(disable_list,"Target resolved")
    end

    if includes(ui.get(self.cfg[idx].prefer_baim_disablers),"Safe point headshot") then
        table.insert(disable_list,"Safe point headshot")
    end

    ui.set(ref_prefer_bodyaim_disablers,disable_list)

    is_visible = false

    local me = entity.get_local_player() 
    for _, players in pairs(entity.get_players(true)) do

        plist.set(players, "High priority",false)

        if enemy_visible(players) then
            is_visible = true
        end

        if includes(ui.get(self.high_pro),'AWP user') then
            local weapon = entity.get_player_weapon(players)
            if weapon ~= nil then
                plist.set(players, "High priority", entity.get_classname(weapon) == "CWeaponAWP")
            end
        end

        if includes(ui.get(self.high_pro),'Bomb carrier') then
            for i = 64 , 0 , -1 do
                local idx = entity.get_prop(entity.get_prop(players, "m_hMyWeapons", i), "m_iItemDefinitionIndex")
                if idx == 49 then
                    plist.set(players, "High priority", true)
                end
            end
        end

        local me_origin = { entity.get_prop(me, 'm_vecAbsOrigin') }
        local e_wpn = entity.get_player_weapon(players)
        local shot_time = globals.tickinterval() * 14
        local vec_vel = { entity.get_prop(players, 'm_vecVelocity') }
        local eye_pos = { client.eye_position() }
        local abs_origin = { entity.get_prop(players, 'm_vecAbsOrigin') }
        local ang_abs = { entity.get_prop(players, 'm_angAbsRotation') }
        local pitch, yaw = vector_angles(abs_origin[1], abs_origin[2], abs_origin[2], eye_pos[1], eye_pos[2], eye_pos[3])
        local yaw_degress = math.floor(math.abs(normalize_yaw(yaw - ang_abs[2])))

        local health = entity.get_prop(players, "m_iHealth")
        local g_damage = calculate_damage(me, players, true)

        if includes(ui.get(self.cfg[idx].prefer_baim_disablers),'High pitch') and ui.get(ref_prefer_bodyaim) then
            if me_origin[3] > abs_origin[3] and math.abs(me_origin[3] - abs_origin[3]) > 30 or false then
                plist.set(players, "Override prefer body aim","Off" )
            end
        end

        if includes(ui.get(self.cfg[idx].prefer_baim_disablers),'Side way') and ui.get(ref_prefer_bodyaim) then
            if yaw_degress > 90 + 20 or yaw_degress < 90 - 20 then
                plist.set(players, "Override prefer body aim","Off" ) 
            end
        end

        if ui.get(self.cfg[idx].lethal) then
            if g_damage >= health then
                plist.set(players, "Override prefer body aim","Force" )
            end
        end

        plist.set(players, "Override prefer body aim","-" )
    end
end

function weapon:get_ping(idx)
    if ui.get(self.allow_fake_ping) == false then return end

    if (ui.get(self.cfg[idx].fp) == 'Always on') then
        ui.set(ping_spike[1],true)
    elseif (ui.get(self.cfg[idx].fp) == 'On key') and ui.get(self.fake_ping_key) then
        ui.set(ping_spike[1],true)
    else
        ui.set(ping_spike[1],false)
    end

    ui.set(ping_spike[2],'Always on')
end

local wpn_ignored = {
	'CKnife',
	'CWeaponTaser',
	'CC4',
	'CHEGrenade',
	'CSmokeGrenade',
	'CMolotovGrenade',
	'CSensorGrenade',
	'CFlashbang',
	'CDecoyGrenade',
	'CIncendiaryGrenade'
}

function weapon:main_funcs()

    if ui.get(self.main_switch) == false then return end

    local local_player = entity.get_local_player()

    local weapon_d = entity.get_player_weapon(local_player)

    if weapon_d == nil then return end
    
    local weapon_id = self:recorrect()

    if weapon_id == nil then weapon_id = 1 end

    local allow_use_pene = false
    local dmg_out = 0

    if weapon_d ~= nil and not includes(wpn_ignored, entity.get_classname(weapon_d)) then

        if  ui.get(self.ovr_dmg_smart) and includes(ui.get(self.available),'Min DMG') then

            local pitch, yaw = client.camera_angles()
            local fwd = angle_forward({ pitch, yaw, 0 })
            local start_pos = { client.eye_position() }
            
            local fraction = client.trace_line(local_player, start_pos[1], start_pos[2], start_pos[3], start_pos[1] + (fwd[1] * 8192), start_pos[2] + (fwd[2] * 8192), start_pos[3] + (fwd[3] * 8192))

            if fraction < 1 then
                local end_pos = {
                    start_pos[1] + (fwd[1] * (8192 * fraction + 128)),
                    start_pos[2] + (fwd[2] * (8192 * fraction + 128)),
                    start_pos[3] + (fwd[3] * (8192 * fraction + 128)),
                }

                local ent, dmg = client.trace_bullet(local_player, start_pos[1], start_pos[2], start_pos[3], end_pos[1], end_pos[2], end_pos[3])

                if ent == nil then
                    ent = -1
                end

                if dmg > 0 and ui.get(self.ovr_dmg_smart) and includes(ui.get(self.available),'Min DMG') then
                    allow_use_pene = true
                    dmg_out = dmg
                end
            end
        end
    end     

    ui.set(ref_target_selection,ui.get(self.cfg[weapon_id].target_selection))

    local target_hitbox = self:get_hitbox(weapon_id)
    if #target_hitbox == 0 then
        target_hitbox = {'Head'}
    end

    ui.set(ref_target_hitbox,target_hitbox)
    ui.set(ref_multipoint,self:get_multipoint(weapon_id)[1])
    ui.set(ref_multipointkey,'Always on')
    ui.set(ref_multipoint_scale,self:get_multipoint(weapon_id)[2])
    ui.set(ref_unsafe,self:get_unsafe_hitbox(weapon_id))
    ui.set(ref_prefer_safepoint,self:get_prefer_safe_point(weapon_id))
    ui.set(ref_automatic_fire,ui.get(self.cfg[weapon_id].automatic_fire))
    ui.set(ref_automatic_penetration,ui.get(self.cfg[weapon_id].automatic_penetration))
    ui.set(ref_automatic_scope,self:get_scope(weapon_id))
    ui.set(ref_silent_aim,ui.get(self.cfg[weapon_id].silent_aim))
    ui.set(ref_fov,ui.get(self.cfg[weapon_id].max))
    ui.set(ref_low_fps_mitigations,ui.get(self.cfg[weapon_id].fps_boost))
    ui.set(ref_hitchance,self:get_hitchance(weapon_id) )
    ui.set(ref_mindamage,allow_use_pene and clamp(dmg_out,0,126) or self:get_damage(weapon_id) )
    ui.set(ref_accuracy_boost,ui.get(self.cfg[weapon_id].accuarcy_boost) )
    ui.set(ref_delay_shot,self:get_delay(weapon_id) )
    ui.set(ref_quickstop,self:get_stop(weapon_id)[1] )
    ui.set(ref_quickstopkey,'Always on')
    ui.set(ref_quickstop_options,self:get_stop(weapon_id)[2])
    ui.set(ref_prefer_bodyaim,self:get_baim(weapon_id))
    self:disabler(weapon_id)
    self:get_ping(weapon_id)

    if includes(ui.get(self.cfg[weapon_id].dt),'Doubletap mode') then
        ui.set(ref_doubletap_mode,ui.get(self.cfg[weapon_id].doubletap_mode))
    end

    if includes(ui.get(self.cfg[weapon_id].dt),'Doubletap quick stop') then
        ui.set(ref_doubletap_stop,ui.get(self.cfg[weapon_id].doubletap_stop))
    end
    
    if includes(ui.get(self.cfg[weapon_id].dt),'Doubletap hitchance') then
        ui.set(ref_doubletap_hc,ui.get(self.cfg[weapon_id].doubletap_hc))
    end

    if includes(ui.get(self.cfg[weapon_id].dt),'Doubletap fakelag') then
        ui.set(ref_doubletap_fl,ui.get(self.cfg[weapon_id].doubletap_fl))
    end
end

local function invisible()
    local vis = ui.is_menu_open()
    if vis == false and ui.get(weapon.adjust) then
        local id = weapon:recorrect()
        if id == nil then id = 1 end
        ui.set(weapon.weapon_select,weapon_name[id])
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

local function indicator()
    local screen_size_x,screen_size_y = client.screen_size()
    local local_player = entity.get_local_player()
    if local_player == nil then return end
    local color = {ui.get(weapon.lua_clr)}
    local test = gradient_text(176,196,222, 255,color[1],color[2],color[3],color[4], "DMG -> "..ui.get(ref_mindamage))

    local id = weapon:recorrect()
    if id == nil then id = 1 end
    if ui.get(weapon.ovr_dmg_smart) and includes(ui.get(weapon.available),'Min DMG') then
        renderer.indicator(100,220,220,255, 'AUTO PENETRATION')
    end

    if ui.get(weapon.ovr_dmg) and includes(ui.get(weapon.available),'Min DMG') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].damage_mode),'Override 1') and 255 or 150, 'MD')
    end

    if ui.get(weapon.ovr_dmg_2) and includes(ui.get(weapon.available),'Min DMG') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].damage_mode),'Override 2') and (not (ui.get(weapon.ovr_dmg) and includes(ui.get(weapon.cfg[id].damage_mode),'Override 1')) and 255 or 150) or 150, 'OD 2')
    end

    if ui.get(weapon.ovr_hc) and includes(ui.get(weapon.available),'Hit chance') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].hitchance_mode),'Override 1') and 255 or 150, '')
    end

    if ui.get(weapon.ovr_hc_2) and includes(ui.get(weapon.available),'Hit chance') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].hitchance_mode),'Override 2') and (not (ui.get(weapon.ovr_hc) and includes(ui.get(weapon.cfg[id].hitchance_mode),'Override 1')) and 255 or 150) or 150, 'OVR HITCHANCE 2')
    end

    if ui.get(weapon.ovr_box) and includes(ui.get(weapon.available),'Hitbox') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].hitbox_mode),'Override 1') and 255 or 150, 'OVR HITBOX 1')
    end

    if ui.get(weapon.ovr_box_2) and includes(ui.get(weapon.available),'Hitbox') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].hitbox_mode),'Override 2') and (not (ui.get(weapon.ovr_box) and includes(ui.get(weapon.cfg[id].hitbox_mode),'Override 1')) and 255 or 150) or 150, 'OVR HITBOX 2')
    end

    if ui.get(weapon.ovr_multi) and includes(ui.get(weapon.available),'Multipoint') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].multi_mode),'Override') and 255 or 150, '')
    end

    if ui.get(weapon.ovr_unsafe) and includes(ui.get(weapon.available),'Unsafe hitbox') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].unsafe_mode),'Override') and 255 or 150, '')
    end

    if ui.get(weapon.ovr_stop) and  includes(ui.get(weapon.available),'Quick stop') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].stop_mode),'Override') and 255 or 150, '')
    end

    if ui.get(weapon.ovr_delay) and includes(ui.get(weapon.available),'Delay shot') then
        renderer.indicator(220,220,220,includes(ui.get(weapon.cfg[id].delay_shot),'On key') and 255 or 150, '')
    end

    if ui.get(weapon.ovr_forcehead) and includes(ui.get(weapon.available),'Hitbox') then
        renderer.indicator(220,0,0,255, 'FORCE HEAD')
    end

    if ui.get(weapon.lua_label) == 'Skeet indicator' then
        renderer.indicator(100,149,237,255, test)
    else
        local size_x,size_y = renderer.measure_text('',ui.get(ref_mindamage))
        renderer.text(screen_size_x/2-size_x,screen_size_y/2-size_y,color[1],color[2],color[3],color[4],'',0,ui.get(ref_mindamage))
    end

    
end

local function draw_ind()

    if ui.get(weapon.draw_panel) == false then return end

    local screen_size_x,screen_size_y = client.screen_size()

    local x,y = ui.get(weapon.x),ui.get(weapon.y)

    renderer.circle_outline(x,y,142,165,229,100,4,0,0.25,1.5)
    renderer.gradient(x+4-1,y-80,1.5,80,142,165,229,255,142,165,229,100,false)
    renderer.circle_outline(x,y-80,142,165,229,255,4,270,0.25,1.5)
    renderer.gradient(x+4-1 - 70,y-80 -4,17-3,1.5,142,165,229,255,142,165,229,255,false)
    renderer.gradient(x+4-1-3 ,y-80 -4,-(17-3),1.5,142,165,229,255,142,165,229,255,false)
    renderer.circle_outline(x-1 - 70+4,y-80,142,165,229,255,4,180,0.25,1.5)
    renderer.gradient(x+4-1 - 70-4,y-80,1.5,80,142,165,229,255,142,165,229,100,false)
    renderer.circle_outline(x-1 - 70+4,y,142,165,229,100,4,90,0.25,1.5)
    renderer.gradient(x+4-1 - 70,y+3,70-3,1.5,142,165,229,100,142,165,229,100,false)
    renderer.gradient(x+4-1 - 70,y+3-80-6,70-3,86,0,0,0,90,0,0,0,90,false)
    renderer.gradient(x+4-1 - 70 - 3,y+3-80-3,3,80,0,0,0,90,0,0,0,90,false)
    renderer.gradient(x+4-1-70-3+70,y+3-80-3,3,80,0,0,0,90,0,0,0,90,false)
    renderer.circle(x+4-1-70-3+70,y+3-80-3,0,0,0,90,2.5,90,0.25)
    renderer.circle(x+4-1-70-3+70,y+3-3,0,0,0,90,2.5,0,0.25)
    renderer.circle(x+4-1 - 70,y,0,0,0,90,2.5,270,0.25)
    renderer.circle(x+4-1 - 70,y-80,0,0,0,90,2.5,180,0.25)

    local test = gradient_text(176,196,222, 255,142,165,229,255,'STATUS')
    renderer.text(x - 35 ,y -84,255,255,255,255,'c-',0,test)
    local h_index = 0 
    local size_x,size_y = renderer.measure_text('c-','    DMG:')

    renderer.text(x - 55 ,y -70 + h_index*12,176,196,222,255,'c-',0,'    DMG:')
    renderer.text(x - 55+size_x/2+5 ,y -70 + h_index*12,220,220,220,255,'c-',0,ui.get(ref_mindamage))
    h_index = h_index + 1
    local size_x,size_y = renderer.measure_text('c-','    HC:')
    renderer.text(x - 58 ,y -70 + h_index*12,176,196,222,255,'c-',0,'    HC:')
    renderer.text(x - 55 + size_x/2 + 3 ,y -70 + h_index*12,220,220,220,255,'c-',0,ui.get(ref_hitchance))
    h_index = h_index + 1
    renderer.text(x - 55 + 3 + 3 + 14 - 8 ,y -70 + h_index*12,176,196,222,ui.get(ping_spike[1]) and 255 or 100,'c-',0,'PING SPIKE')
    h_index = h_index + 1
    renderer.text(x - 55 + 3 + 3 + 14 - 6 - 12 ,y -70 + h_index*12,176,196,222,ui.get(ref_force_safepoint) and 255 or 100,'c-',0,'SAFE')
    h_index = h_index + 1
    renderer.text(x - 55 + 3 + 3 + 14 - 6 - 12,y -70 + h_index*12,176,196,222,ui.get(ref_force_bodyaim) and 255 or 100,'c-',0,'BAIM')
    h_index = h_index + 1
    renderer.text(x - 55 + 3 + 3 + 14 ,y -70 + h_index*12,176,196,222,is_visible and 255 or 100,'c-',0,'TARGET VISIBLE')

end



local function hide_menu()

    local main = ui.get(weapon.main_switch)
    local select = ui.get(weapon.weapon_select)

    for i=1, #weapon_name do
        local condition = main and weapon_name[i] == select
        ui.set_visible(weapon.cfg[i].enable,condition)
        ui.set_visible(weapon.cfg[i].extra_feature,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].target_selection,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitbox_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitbox_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitbox') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].target_hitbox,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].dt_target_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitbox') and includes(ui.get(weapon.cfg[i].hitbox_mode),'Double-tap') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].air_target_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitbox') and includes(ui.get(weapon.cfg[i].hitbox_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].ovr_target_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitbox') and includes(ui.get(weapon.cfg[i].hitbox_mode),'Override 1')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Hitbox'))
        ui.set_visible(weapon.cfg[i].ovr_target_hitbox_2,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitbox') and includes(ui.get(weapon.cfg[i].hitbox_mode),'Override 2')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Hitbox'))
        ui.set_visible(weapon.cfg[i].multi_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].multi_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].multi_complex,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') )
        if includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') then
            ui.set_visible(weapon.cfg[i].target_multi,condition and ui.get(weapon.cfg[i].enable) and (ui.get(weapon.cfg[i].multi_complex) == 0))
            ui.set_visible(weapon.cfg[i].multipoint_scale,condition and ui.get(weapon.cfg[i].enable) and (ui.get(weapon.cfg[i].multi_complex) == 0))
        else
            ui.set_visible(weapon.cfg[i].target_multi,condition and ui.get(weapon.cfg[i].enable))
            ui.set_visible(weapon.cfg[i].multipoint_scale,condition and ui.get(weapon.cfg[i].enable))
        end
        ui.set_visible(weapon.cfg[i].multi_hitbox_v,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].multi_complex) == 1  and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point'))
        ui.set_visible(weapon.cfg[i].multipoint_scale_v,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].multi_complex) == 1 and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point'))
        ui.set_visible(weapon.cfg[i].multi_hitbox_a,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].multi_complex) == 1 and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point'))
        ui.set_visible(weapon.cfg[i].multipoint_scale_a,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].multi_complex) == 1 and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point'))

        ui.set_visible(weapon.cfg[i].dt_multi_complex,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].dt_multi_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 0)
        ui.set_visible(weapon.cfg[i].dt_multipoint_scale,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 0)
        ui.set_visible(weapon.cfg[i].dt_multi_hitbox_v,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 1)
        ui.set_visible(weapon.cfg[i].dt_multipoint_scale_v,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 1)
        ui.set_visible(weapon.cfg[i].dt_multi_hitbox_a,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 1)
        ui.set_visible(weapon.cfg[i].dt_multipoint_scale_a,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].dt_multi_complex) == 1)
        ui.set_visible(weapon.cfg[i].ping_avilble,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Ping-spike')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].ping_multi_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Ping-spike')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].ping_multipoint_scale,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Ping-spike')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].air_multi_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].air_multipoint_scale,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].ovr_multi_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Override')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Multipoint'))
        ui.set_visible(weapon.cfg[i].ovr_multipoint_scale,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Muti-point') and includes(ui.get(weapon.cfg[i].multi_mode),'Override')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Multipoint'))
        ui.set_visible(weapon.cfg[i].unsafe_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].unsafe_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Unsafe hitbox') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].unsafe_hitbox,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].dt_unsafe_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Unsafe hitbox') and includes(ui.get(weapon.cfg[i].unsafe_mode),'Double-tap') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].air_unsafe_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Unsafe hitbox') and includes(ui.get(weapon.cfg[i].unsafe_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].ovr_unsafe_hitbox,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Unsafe hitbox') and includes(ui.get(weapon.cfg[i].unsafe_mode),'Override')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Unsafe hitbox'))
        ui.set_visible(weapon.cfg[i].general_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].safepoint,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].automatic_fire,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].automatic_penetration,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].automatic_scope_e,condition and ui.get(weapon.cfg[i].enable) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].automatic_scope,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].automatic_scope_e) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].autoscope_therehold,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].automatic_scope),'In distance') and ui.get(weapon.cfg[i].automatic_scope_e) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].silent_aim,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].max,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].fps_boost,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_ovr,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Override 1') and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Hit chance'))
        ui.set_visible(weapon.cfg[i].hitchance_air,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_usc,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Unscoped')  and ui.get(weapon.cfg[i].enable) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].hitchance_cro,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Crouching')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_fd,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Fake duck')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_os,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'On-shot')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].hitchance_ovr_2,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Hitchance') and includes(ui.get(weapon.cfg[i].hitchance_mode),'Override 2')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Hit chance'))
        ui.set_visible(weapon.cfg[i].damage_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and ui.get(weapon.cfg[i].enable))
        if includes(ui.get(weapon.cfg[i].extra_feature),'Damage') then
            ui.set_visible(weapon.cfg[i].damage,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].damage_complex) == 'Original')
        else
            ui.set_visible(weapon.cfg[i].damage,condition and ui.get(weapon.cfg[i].enable))
        end
        ui.set_visible(weapon.cfg[i].damage_complex,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].extra_feature),'Damage'))
        ui.set_visible(weapon.cfg[i].damage_cro,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and ui.get(weapon.cfg[i].damage_complex) == 'Visible/autowall' and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_aut,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and ui.get(weapon.cfg[i].damage_complex) == 'Visible/autowall' and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_ovr,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Override 1') and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Min DMG'))
        ui.set_visible(weapon.cfg[i].damage_air,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'In-air')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_usc,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Unscoped')  and ui.get(weapon.cfg[i].enable) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].damage_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].damage_complex_dt) == 'Original')
        ui.set_visible(weapon.cfg[i].damage_complex_dt,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Double-tap'))
        ui.set_visible(weapon.cfg[i].damage_cro_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and ui.get(weapon.cfg[i].damage_complex_dt) == 'Visible/autowall' and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].damage_mode),'Double-tap'))
        ui.set_visible(weapon.cfg[i].damage_aut_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and ui.get(weapon.cfg[i].damage_complex_dt) == 'Visible/autowall' and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].damage_mode),'Double-tap'))
        ui.set_visible(weapon.cfg[i].damage_fd,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Fake duck')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_os,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'On-shot')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].damage_ovr_2,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Damage') and includes(ui.get(weapon.cfg[i].damage_mode),'Override 2')  and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.available),'Min DMG'))
        ui.set_visible(weapon.cfg[i].delay_shot,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].accuarcy_boost,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].c,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_mode,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_option,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Double-tap') and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_option_dt,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Double-tap')  and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].stop_unscoped,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Unscoped')  and ui.get(weapon.cfg[i].enable) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].stop_option_unscoped,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Unscoped')  and ui.get(weapon.cfg[i].enable) and includes(scoped_wpn_idx,i))
        ui.set_visible(weapon.cfg[i].stop_ovr,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Override')  and ui.get(weapon.cfg[i].enable)  and includes(ui.get(weapon.available),'Quick stop'))
        ui.set_visible(weapon.cfg[i].stop_option_ovr,condition and includes(ui.get(weapon.cfg[i].extra_feature),'Quick stop') and includes(ui.get(weapon.cfg[i].stop_mode),'Override')  and ui.get(weapon.cfg[i].enable)  and includes(ui.get(weapon.available),'Quick stop'))
        ui.set_visible(weapon.cfg[i].ext_text,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].fp,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.allow_fake_ping))
        ui.set_visible(weapon.cfg[i].preferbm,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].prefer_baim_disablers,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].preferbm))
        ui.set_visible(weapon.cfg[i].lethal,condition and ui.get(weapon.cfg[i].enable) and ui.get(weapon.cfg[i].preferbm))
        ui.set_visible(weapon.cfg[i].dt,condition and ui.get(weapon.cfg[i].enable))
        ui.set_visible(weapon.cfg[i].doubletap_hc,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].dt),'Doubletap hitchance'))
        ui.set_visible(weapon.cfg[i].doubletap_stop,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].dt),'Doubletap quick stop'))
        ui.set_visible(weapon.cfg[i].doubletap_fl,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].dt),'Doubletap fakelag'))
        ui.set_visible(weapon.cfg[i].doubletap_mode,condition and ui.get(weapon.cfg[i].enable) and includes(ui.get(weapon.cfg[i].dt),'Doubletap mode'))
        if includes(ui.get(weapon.cfg[i].delay_shot),'Always on') and not includes(ui.get(weapon.available),'Delay shot') then
            ui.set(weapon.cfg[i].delay_shot,{'Always on'})
        elseif not includes(ui.get(weapon.cfg[i].delay_shot),'Always on') and not includes(ui.get(weapon.available),'Delay shot') then
            ui.set(weapon.cfg[i].delay_shot,{})
        end

    end

    ui.set_visible(weapon.weapon_select,main)
    ui.set_visible(weapon.key_text,main)
    ui.set_visible(weapon.lua_label,main)
    ui.set_visible(weapon.lua_clr,main)
    ui.set_visible(weapon.high_pro,main)
    ui.set_visible(weapon.available,main)
    ui.set_visible(weapon.draw_panel,main)
    ui.set_visible(weapon.ovr_dmg,main and includes(ui.get(weapon.available),'Min DMG'))
    ui.set_visible(weapon.ovr_dmg_smart,main and includes(ui.get(weapon.available),'Min DMG'))
    ui.set_visible(weapon.ovr_dmg_2,main and includes(ui.get(weapon.available),'Min DMG'))
    ui.set_visible(weapon.ovr_hc,main and includes(ui.get(weapon.available),'Hit chance'))
    ui.set_visible(weapon.ovr_hc_2,main and includes(ui.get(weapon.available),'Hit chance'))
    ui.set_visible(weapon.ovr_box,main and includes(ui.get(weapon.available),'Hitbox'))
    ui.set_visible(weapon.ovr_box_2,main and includes(ui.get(weapon.available),'Hitbox'))
    ui.set_visible(weapon.ovr_unsafe,main and includes(ui.get(weapon.available),'Unsafe hitbox'))
    ui.set_visible(weapon.ovr_stop,main and  includes(ui.get(weapon.available),'Quick stop'))
    ui.set_visible(weapon.key_text,main)
    ui.set_visible(weapon.key_text_1,main)
    ui.set_visible(weapon.adjust,main)
    ui.set_visible(weapon.ovr_forcehead,main and includes(ui.get(weapon.available),'Hitbox'))
    ui.set_visible(weapon.ovr_delay,main and includes(ui.get(weapon.available),'Delay shot'))
    ui.set_visible(weapon.ovr_multi,main and includes(ui.get(weapon.available),'Multipoint'))

    ui.set_visible(weapon.run_hide,main)

    ui.set_visible(weapon.x,main and ui.get(weapon.draw_panel))
    ui.set_visible(weapon.y,main and ui.get(weapon.draw_panel))

    ui.set_visible(weapon.allow_fake_ping,main)
    ui.set_visible(weapon.fake_ping_key,main and ui.get(weapon.allow_fake_ping))

    ui.set_visible(weapon.cfg[1].enable,false)
    ui.set(weapon.cfg[1].enable,true)


end

hide_menu()

local function menu_adjust()
    for i=1, #weapon_name do
        ui.set_callback(weapon.cfg[i].enable,hide_menu)
        ui.set_callback(weapon.cfg[i].extra_feature,hide_menu)
        ui.set_callback(weapon.cfg[i].target_selection,hide_menu)
        ui.set_callback(weapon.cfg[i].hitbox_text,hide_menu)
        ui.set_callback(weapon.cfg[i].hitbox_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].target_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_target_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].air_target_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].ovr_target_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].ovr_target_hitbox_2,hide_menu)
        ui.set_callback(weapon.cfg[i].multi_text,hide_menu)
        ui.set_callback(weapon.cfg[i].lethal,hide_menu)
        ui.set_callback(weapon.cfg[i].multi_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].multi_complex,hide_menu)
        ui.set_callback(weapon.cfg[i].target_multi,hide_menu)
        ui.set_callback(weapon.cfg[i].multipoint_scale,hide_menu)
        ui.set_callback(weapon.cfg[i].multi_hitbox_v,hide_menu)
        ui.set_callback(weapon.cfg[i].multipoint_scale_v,hide_menu)
        ui.set_callback(weapon.cfg[i].multi_hitbox_a,hide_menu)
        ui.set_callback(weapon.cfg[i].multipoint_scale_a,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multi_complex,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multi_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multipoint_scale,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multi_hitbox_v,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multipoint_scale_v,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multi_hitbox_a,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_multipoint_scale_a,hide_menu)

        ui.set_callback(weapon.cfg[i].ping_avilble,hide_menu)
        ui.set_callback(weapon.cfg[i].ping_multi_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].ping_multipoint_scale,hide_menu)
        ui.set_callback(weapon.cfg[i].air_multi_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].air_multipoint_scale,hide_menu)
        ui.set_callback(weapon.cfg[i].c,hide_menu)
        ui.set_callback(weapon.cfg[i].ovr_multi_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].ovr_multipoint_scale,hide_menu)
        ui.set_callback(weapon.cfg[i].unsafe_text,hide_menu)
        ui.set_callback(weapon.cfg[i].unsafe_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].unsafe_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].dt_unsafe_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].air_unsafe_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].ovr_unsafe_hitbox,hide_menu)
        ui.set_callback(weapon.cfg[i].safepoint,hide_menu)
        ui.set_callback(weapon.cfg[i].automatic_fire,hide_menu)
        ui.set_callback(weapon.cfg[i].automatic_penetration,hide_menu)
        ui.set_callback(weapon.cfg[i].automatic_scope,hide_menu)
        ui.set_callback(weapon.cfg[i].automatic_scope_e,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_complex,hide_menu)
        ui.set_callback(weapon.cfg[i].autoscope_therehold,hide_menu)
        ui.set_callback(weapon.cfg[i].silent_aim,hide_menu)
        ui.set_callback(weapon.cfg[i].max,hide_menu)
        ui.set_callback(weapon.cfg[i].fps_boost,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_text,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_ovr,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_air,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_usc,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_cro,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_fd,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_os,hide_menu)
        ui.set_callback(weapon.cfg[i].hitchance_ovr_2,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_text,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].damage,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_ovr,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_air,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_usc,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_cro,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_complex_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_cro_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_aut_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_aut,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_fd,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_os,hide_menu)
        ui.set_callback(weapon.cfg[i].damage_ovr_2,hide_menu)
        ui.set_callback(weapon.cfg[i].accuarcy_boost,hide_menu)
        ui.set_callback(weapon.cfg[i].delay_shot,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_text,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_mode,hide_menu)
        ui.set_callback(weapon.cfg[i].stop,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_option,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_option_dt,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_unscoped,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_option_unscoped,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_ovr,hide_menu)
        ui.set_callback(weapon.cfg[i].stop_option_ovr,hide_menu)
        ui.set_callback(weapon.cfg[i].ext_text,hide_menu)
        ui.set_callback(weapon.cfg[i].preferbm,hide_menu)
        ui.set_callback(weapon.cfg[i].prefer_baim_disablers,hide_menu)
        ui.set_callback(weapon.cfg[i].doubletap_hc,hide_menu)
        ui.set_callback(weapon.cfg[i].doubletap_stop,hide_menu)
        ui.set_callback(weapon.cfg[i].dt,hide_menu)
        ui.set_callback(weapon.cfg[i].doubletap_fl,hide_menu)
        ui.set_callback(weapon.cfg[i].doubletap_mode,hide_menu)
    end
    ui.set_callback(weapon.main_switch,hide_menu)
    ui.set_callback(weapon.weapon_select,hide_menu)
    ui.set_callback(weapon.available,hide_menu)
    ui.set_callback(weapon.key_text,hide_menu)
    ui.set_callback(weapon.ovr_dmg,hide_menu)
    ui.set_callback(weapon.ovr_dmg_2,hide_menu)
    ui.set_callback(weapon.ovr_dmg_smart,hide_menu)
    ui.set_callback(weapon.ovr_hc,hide_menu)
    ui.set_callback(weapon.ovr_hc_2,hide_menu)
    ui.set_callback(weapon.ovr_box,hide_menu)
    ui.set_callback(weapon.ovr_box_2,hide_menu)
    ui.set_callback(weapon.ovr_unsafe,hide_menu)
    ui.set_callback(weapon.high_pro,hide_menu)
    ui.set_callback(weapon.ovr_stop,hide_menu)
    ui.set_callback(weapon.key_text,hide_menu)
    ui.set_callback(weapon.draw_panel,hide_menu)
    ui.set_callback(weapon.key_text_1,hide_menu)
    ui.set_callback(weapon.ovr_forcehead,hide_menu)
    ui.set_callback(weapon.run_hide,hide_menu)
    ui.set_callback(weapon.adjust,hide_menu)

    ui.set_callback(weapon.allow_fake_ping,hide_menu)
    ui.set_callback(weapon.fake_ping_key,hide_menu)

    ui.set_callback(weapon.lua_label,hide_menu)
    ui.set_callback(weapon.lua_clr,hide_menu)
    
    ui.set_callback(weapon.x,hide_menu)
    ui.set_callback(weapon.y,hide_menu)
end


menu_adjust()

local function paint()

    local local_player = entity.get_local_player()
    if local_player == nil then return end
    if entity.is_alive(local_player) == false then return end
    invisible()
    hide_skeet()
    weapon:main_funcs()
    indicator()
    draw_ind()
    
end

client.set_event_callback('paint', paint)
