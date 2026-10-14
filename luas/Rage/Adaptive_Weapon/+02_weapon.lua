local clipboard = require('gamesense/clipboard') or error("https://gamesense.pub/forums/viewtopic.php?id=28678")
local base64 = require 'gamesense/base64' or error("https://gamesense.pub/forums/viewtopic.php?id=21619")
local real_dist = 0
local is_longdistmode_and_target_not_nil = false
local target_name=""
local ui_dist = 0
local name_to_num = {
    [1] = "weapon",
    [2] = "Global",
    [3] = "Taser",
    [4] = "Heavy Pistol",
    [5] = "Pistol",
    [6] = "Auto",
    [7] = "Scout",
    [8] = "AWP",
    [9] = "Rifle",
    [10] = "SMG",
    [11] = "Shotgun",
    [12] = "Desert Eagle"
}
local name_to_num2 = {
    [1] = "weapon",
    [2] = "global",
    [3] = "taser",
    [4] = "revolver",
    [5] = "pistol",
    [6] = "auto",
    [7] = "scout",
    [8] = "awp",
    [9] = "rife",
    [10] = "smg",
    [11] = "shotgun",
    [12] = "deagle"
}
local air_strafe = ui.reference("Misc", "Movement", "Air strafe")
local function arr_to_string(arr)
    arr = ui.get(arr)
    local str = ""
    for i = 1, #arr do
        str = str .. arr[i] .. (i == #arr and "" or ",")
    end

    if str == "" then
        str = "-"
    end

    return str
end
local function str_to_sub(input, sep)
    local t = {}
    for str in string.gmatch(input, "([^" .. sep .. "]+)") do
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
to_exp = {
    weapon = {},
    global = {},
    taser = {},
    revolver = {},
    pistol = {},
    auto = {},
    scout = {},
    awp = {},
    rife = {},
    smg = {},
    shotgun = {},
    deagle = {}
}
weapon_imp_exp_func = {
    [1] = {
        imp = nil,
        exp = nil
    },
    [2] = {
        imp = nil,
        exp = nil
    },
    [3] = {
        imp = nil,
        exp = nil
    },
    [4] = {
        imp = nil,
        exp = nil
    },
    [5] = {
        imp = nil,
        exp = nil
    },
    [6] = {
        imp = nil,
        exp = nil
    },
    [7] = {
        imp = nil,
        exp = nil
    },
    [8] = {
        imp = nil,
        exp = nil
    },
    [9] = {
        imp = nil,
        exp = nil
    },
    [10] = {
        imp = nil,
        exp = nil
    },
    [11] = {
        imp = nil,
        exp = nil
    }
}
for i = 1, 11, 1 do
    weapon_imp_exp_func[i].imp = function(tbl, name)
        local index = i + 1
        local tbl = to_exp[name_to_num2[index]]
        local name = name_to_num[index]
        local clipboard_txt = clipboard.get()
        local pos = string.find(clipboard_txt, "weapon")
        local temp = string.sub(clipboard_txt, 1, pos - 1)
        local real_clipboard_txt = (string.sub(clipboard_txt, pos + 6))
        if tostring(temp) ~= tostring(index) then
            client.color_log(255, 0, 0, "[Adaptive Weapon] Current tab is not *" .. name_to_num[tonumber(temp)] .. "*!")
            return
        end
        local table_ = str_to_sub(base64.decode(real_clipboard_txt, 'base64'), "|")
        local p = 1
        for i, o in pairs(tbl['number']) do
            ui.set(o, table_[p])
            p = p + 1
        end
        for i, o in pairs(tbl['string']) do
            ui.set(o, (table_[p]))
            p = p + 1
        end
        for i, o in pairs(tbl['boolean']) do
            ui.set(o, to_boolean(table_[p]))
            p = p + 1
        end
        for i, o in pairs(tbl['table']) do
            ui.set(o, str_to_sub(table_[p], ','))
            p = p + 1
        end
        client.color_log(255, 233, 120, "[Adaptive Weapon] Imported " .. name .. " config from clipboard")
    end
    weapon_imp_exp_func[i].exp = function()
        -- tbl = to_exp[name_to_num2[i]]
        local index = i + 1
        local tbl = to_exp[name_to_num2[index]]
        local name = name_to_num[index]
        local str = ""
        for i, o in pairs(tbl['number']) do
            str = str .. tostring(ui.get(o)) .. '|'
        end
        for i, o in pairs(tbl['string']) do
            str = str .. ui.get(o) .. '|'
        end
        for i, o in pairs(tbl['boolean']) do
            str = str .. tostring(ui.get(o)) .. '|'
        end
        for i, o in pairs(tbl['table']) do
            str = str .. arr_to_string(o) .. '|'
        end
        clipboard.set(index .. "weapon" .. (base64.encode(str, 'base64')))
        client.color_log(255, 233, 120, "[Adaptive Weapon] Exported " .. name .. " config from clipboard")
    end
end
for i = 1, 12, 1 do
    to_exp[name_to_num2[i]] = {
        ['number'] = {},
        ['string'] = {},
        ['boolean'] = {},
        ['table'] = {},
        import = nil,
        export = nil,
        lmao = "lmao"
    }
end
local function createElement(element, boolean_weapon, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
    shotgun, deagle, ...)
    local elem = element
    if boolean_weapon then
        if type(elem) == 'number' then
            table.insert(to_exp.weapon[type(ui.get(elem))], elem)
        end
    end
    if global ~= nil then
        if global then
            if type(elem) == 'number' then
                table.insert(to_exp.global[type(ui.get(elem))], elem)
            end
        end
        if taser then
            if type(elem) == 'number' then
                table.insert(to_exp.taser[type(ui.get(elem))], elem)
            end
        end
        if revolver then
            if type(elem) == 'number' then
                table.insert(to_exp.revolver[type(ui.get(elem))], elem)
            end
        end
        if pistol then
            if type(elem) == 'number' then
                table.insert(to_exp.pistol[type(ui.get(elem))], elem)
            end
        end
        if auto then
            if type(elem) == 'number' then
                table.insert(to_exp.auto[type(ui.get(elem))], elem)
            end
        end
        if scout then
            if type(elem) == 'number' then
                table.insert(to_exp.scout[type(ui.get(elem))], elem)
            end
        end
        if awp then
            if type(elem) == 'number' then
                table.insert(to_exp.awp[type(ui.get(elem))], elem)
            end
        end
        if rife then
            if type(elem) == 'number' then
                table.insert(to_exp.rife[type(ui.get(elem))], elem)
            end
        end
        if smg then
            if type(elem) == 'number' then
                table.insert(to_exp.smg[type(ui.get(elem))], elem)
            end
        end
        if shotgun then
            if type(elem) == 'number' then
                table.insert(to_exp.shotgun[type(ui.get(elem))], elem)
            end
        end
        if deagle then
            if type(elem) == 'number' then
                table.insert(to_exp.deagle[type(ui.get(elem))], elem)
            end
        end
    end
    return elem
end
local Hitboxx
local UnsafeHitboxx
local MultiPointScalee
local Hitchancee
local DMG3
local DMG2
local NOTPREBAIMM
local sloww, slow = ui.reference("AA", "Other", "Slow motion")
local config_names = {"Global", "Taser", "Heavy Pistol", "Pistol", "Auto", "Scout", "AWP", "Rifle", "SMG", "Shotgun",
                      "Desert Eagle"}

local weapon_idx = {
    [1] = 11,
    [2] = 4,
    [3] = 4,
    [4] = 4,
    [7] = 8,
    [8] = 8,
    [9] = 7,
    [10] = 8,
    [11] = 5,
    [13] = 8,
    [14] = 8,
    [16] = 8,
    [17] = 9,
    [19] = 9,
    [23] = 9,
    [24] = 9,
    [25] = 10,
    [26] = 9,
    [27] = 10,
    [28] = 8,
    [29] = 10,
    [30] = 4,
    [31] = 2,
    [32] = 4,
    [33] = 9,
    [34] = 9,
    [35] = 10,
    [36] = 4,
    [38] = 5,
    [39] = 8,
    [40] = 6,
    [60] = 8,
    [61] = 4,
    [63] = 4,
    [64] = 3
}
local damage_idx = {
    [0] = "Auto",
    [101] = "HP + 1",
    [102] = "HP + 2",
    [103] = "HP + 3",
    [104] = "HP + 4",
    [105] = "HP + 5",
    [106] = "HP + 6",
    [107] = "HP + 7",
    [108] = "HP + 8",
    [109] = "HP + 9",
    [110] = "HP + 10",
    [111] = "HP + 11",
    [112] = "HP + 12",
    [113] = "HP + 13",
    [114] = "HP + 14",
    [115] = "HP + 15",
    [116] = "HP + 16",
    [117] = "HP + 17",
    [118] = "HP + 18",
    [119] = "HP + 19",
    [120] = "HP + 20",
    [121] = "HP + 21",
    [122] = "HP + 22",
    [123] = "HP + 23",
    [124] = "HP + 24",
    [125] = "HP + 25",
    [126] = "HP + 26"
}
local last_weapon = 0
local close_ui = false
local get_local_player, get_prop = entity.get_local_player, entity.get_prop
local debug_ui = ui.new_multiselect("Rage", "Aimbot", "Debug tab", "Aimbot", "Other","Distance indicator")
local active_wpn = ui.new_combobox("Rage", "Aimbot", "Weapon select", config_names)
local override_hitbox_key = ui.new_hotkey("Rage", "Aimbot", "Override hitbox")
local override_unsafehitboxes_key = ui.new_hotkey("Rage", "Aimbot", "Override Unsafe hitboxes")
local override_multi_point_key = ui.new_hotkey("Rage", "Aimbot", "Override Mulit-Point")
local override_hitchance_key = ui.new_hotkey("Rage", "Aimbot", "Override hitchance")
local override_dmg_1 = ui.new_hotkey("Rage", "Aimbot", "Override 1 dmg")
local override_dmg_2 = ui.new_hotkey("Rage", "Aimbot", "Override 2 dmg")
local override_dmg_3 = ui.new_hotkey("Rage", "Aimbot", "Override 3 dmg")
local override_prebaim = ui.new_hotkey("Rage", "Aimbot", "Prefer baim off");
local rage = {}
function test()

end
local active_idx = 1
for i = 1, #config_names do
    local index = i + 1
    local global = index == 2
    local taser = index == 3
    local revolver = index == 4
    local pistol = index == 5
    local auto = index == 6
    local scout = index == 7
    local awp = index == 8
    local rife = index == 9
    local smg = index == 10
    local shotgun = index == 11
    local deagle = index == 12
    rage[i] = {
        enabled = createElement(ui.new_checkbox("Rage", "Aimbot", "Enable " .. config_names[i] .. " config"), true,
            global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        target_selection = createElement(ui.new_combobox("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Target sledction", {"Cycle", "Cycle (2x)", "Near crosshair", "Highest damage",
                                                             "Lowest ping", "Best K/D ratio", "Best hit chance"}), true,
            global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        target_hitbox = createElement(ui.new_multiselect("Rage", "Aimbot", "[" .. config_names[i] .. "] Target hitbox",
            {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        multipoint = createElement(ui.new_multiselect("Rage", "Aimbot", "[" .. config_names[i] .. "] Multi-point",
            {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        multipoint_scale = createElement(ui.new_slider("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Multi-point scale", 24, 100, 60, true, "%", 1, {
                [24] = "Auto"
            }), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        prefer_safe_point = createElement(ui.new_checkbox("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Prefer safe point"), true, global, taser, revolver, pistol, auto, scout, awp,
            rife, smg, shotgun, deagle),
        avoid_unsafe_hitbox = createElement(ui.new_multiselect("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Avoid unsafe hitboxes", {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}),
            true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        automatic_scope = createElement(
            ui.new_checkbox("Rage", "Aimbot", "[" .. config_names[i] .. "] Automatic scope"), true, global, taser,
            revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),

        hitchance = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Minimum hit chance", 0,
            100, 60, true, "%", 1, {"Off"}), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        min_damage = createElement(
            ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Default Minimum damage", 0, 126, 20, true, nil,
                1, damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),

        extend_aimbot = createElement(ui.new_multiselect("Rage", "Aimbot", "[" .. config_names[i] .. "] Extend aimbot",
            {"Override hitbox", "No scope HC", "Jump HC", "Override HC", "Visible dmg", "No scope dmg", "Jump dmg",
             "Override 1 dmg", "Override 2 dmg", "Override 3 dmg", "Override Mulit-Point", "Override Unsafe hitboxes",
             "NOT PREBAIM"}), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),

        ov_hitbox = createElement(ui.new_multiselect("Rage", "Aimbot", "[" .. config_names[i] .. "] Override hitbox",
            {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        ov_avoid_unsafe_hitbox = createElement(ui.new_multiselect("Rage", "Aimbot", "[" .. config_names[i] ..
            "] Override unsafe hitboxes", {"Head", "Chest", "Stomach", "Arms", "Legs", "Feet"}), true, global, taser,
            revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        override_multi_point = createElement(ui.new_slider("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Override Multi-point scale", 24, 100, 60, true, "%", 1, {
                [24] = "Auto"
            }), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        noscope_hitchance = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] No scope hc", 0,
            100, 40, true, "%", 1, {"Off"}), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        jp_hitchance = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Jump hc", 0, 100, 40,
            true, "%", 1, {"Off"}), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        jp_hitchance_shift = createElement(ui.new_slider("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Jump hc [shift]", 0, 100, 40, true, "%", 1, {"Off"}), true, global, taser,
            revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        jp_hc_lowspeedchange = createElement(ui.new_checkbox("Rage", "Aimbot",
            "[" .. config_names[i] .. "] Jump hc in lowspeed"), true, global, taser, revolver, pistol, auto, scout, awp,
            rife, smg, shotgun, deagle),
        override_hitchance = createElement(
            ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Override hc", 0, 100, 40, true, "%", 1, {"Off"}),
            true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        vs_min_damage = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Visible damage", 0,
            126, 1, true, nil, 1, damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        noscope_min_damage = createElement(ui.new_slider("Rage", "Aimbot",
            "[" .. config_names[i] .. "] No scope damage", 0, 126, 1, true, nil, 1, damage_idx), true, global, taser,
            revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        jp_min_damage = createElement(
            ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Jump damage", 0, 126, 1, true, nil, 1,
                damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        ov1_min_damage = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Override-1 damage",
            0, 126, 1, true, nil, 1, damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        ov2_min_damage = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Override-2 damage",
            0, 126, 1, true, nil, 1, damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        ov3_min_damage = createElement(ui.new_slider("Rage", "Aimbot", "[" .. config_names[i] .. "] Override-3 damage",
            0, 126, 1, true, nil, 1, damage_idx), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),

        accuracy_boost = createElement(ui.new_combobox("Rage", "Other", "[" .. config_names[i] .. "] Accuracy boost",
            {"Low", "Medium", "High", "Maximum"}), true, global, taser, revolver, pistol, auto, scout, awp, rife, smg,
            shotgun, deagle),
        delay_shot = createElement(ui.new_checkbox("Rage", "Other", "[" .. config_names[i] .. "] Delay shot"), true,
            global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        quick_stop = createElement(ui.new_checkbox("Rage", "Other", "[" .. config_names[i] .. "] Quick stop"), true,
            global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        quick_stop_options = createElement(ui.new_multiselect("Rage", "Other",
            "[" .. config_names[i] .. "] Quick stop options", {"Early", "Slow motion", "Duck", "Fake duck",
                                                               "Move between shots", "Ignore molotov", "Taser", "Jump scout"}), true, global,
            taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        quick_stop_longdist = createElement(ui.new_checkbox("Rage", "Other", "[" .. config_names[i] .. "] Long distance quick stop"), true,global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        quick_stop_longdist_distance = createElement(ui.new_slider("Rage", "Other", "[" .. config_names[i] .. "] Distance",600,1500,900,true,"m",0.1), true,global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        quick_stop_longdist_mode =  createElement(ui.new_multiselect("Rage", "Other",
        "[" .. config_names[i] .. "] Long distance quick stop options", {"Early", "Slow motion", "Duck", "Fake duck",
                                                           "Move between shots", "Ignore molotov", "Taser", "Jump scout"}), true, global,
        taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        
        noscope_quick_stop = createElement(ui.new_checkbox("Rage", "Other",
            "[" .. config_names[i] .. "] No scope quick stop"), true, global, taser, revolver, pistol, auto, scout, awp,
            rife, smg, shotgun, deagle),
        noscope_quick_stop_options = createElement(ui.new_multiselect("Rage", "Other", "[" .. config_names[i] ..
            "] No scope quick stop options", {"Early", "Slow motion", "Duck", "Fake duck", "Move between shots",
                                              "Ignore molotov"}), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        prefer_baim = createElement(ui.new_checkbox("Rage", "Other", "[" .. config_names[i] .. "] Prefer body aim"),
            true, global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        prefer_baim_disablers = createElement(ui.new_multiselect("Rage", "Other", "[" .. config_names[i] ..
            "] Prefer body aim disablers", {"Low inaccuracy", "Target shot fired", "Target resolved",
                                            "Safe point headshot"}), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        force_bodyaim_onpeek = createElement(ui.new_checkbox("Rage", "Other",
            "[" .. config_names[i] .. "] Force body aim on peek"), true, global, taser, revolver, pistol, auto, scout,
            awp, rife, smg, shotgun, deagle),
        dt = createElement(ui.new_checkbox("Rage", "Other", "[" .. config_names[i] .. "] Double Tap"), true, global,
            taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        doubletap_hitchance = createElement(ui.new_slider("Rage", "Other",
            "[" .. config_names[i] .. "] Double tap hit chance", 0, 100, 60, true, "%", 1, {"Off"}), true, global,
            taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        doubletap_stop = createElement(ui.new_multiselect("Rage", "Other",
            "[" .. config_names[i] .. "] Double tap quick stop", {"Slow motion", "Duck", "Move between shots"}), true,
            global, taser, revolver, pistol, auto, scout, awp, rife, smg, shotgun, deagle),
        -- SK菜单bug ui太多 必须在最后加菜单项 前面才能点 // 不能设置visible false
        fixmenu = ui.new_button("RAGE", "Aimbot", "End", test),
        nil_label = ui.new_label("RAGE", "Other", "\n"),
        text_label = ui.new_label("RAGE", "Other", "\affffffffConfiguration System")
    }
    local name = name_to_num[index]
    to_exp[name_to_num2[index]].import = ui.new_button("RAGE", "Other", "\aD2D2D2FFImport \aFFE978FF" ..
        name_to_num[index] .. " \aD2D2D2FFConfig", weapon_imp_exp_func[i].imp)
    to_exp[name_to_num2[index]].export = ui.new_button("RAGE", "Other", "\aD2D2D2FFExport \aFFE978FF" ..
        name_to_num[index] .. " \aD2D2D2FFConfig", weapon_imp_exp_func[i].exp)
end

local ref_enable, ref_enable_key = ui.reference("RAGE", "Aimbot", "Enabled")
local ref_target = ui.reference("RAGE", "Aimbot", "Target selection")
local ref_hitbox = ui.reference("RAGE", "Aimbot", "Target hitbox")
local ref_multipoint, ref_multipointkey = ui.reference("RAGE", "Aimbot", "Multi-point")
local ref_multipoint_scale = ui.reference("RAGE", "Aimbot", "Multi-point scale")
local ref_prefer_safepoint = ui.reference("RAGE", "Aimbot", "Prefer safe point")
local ref_force_safepoint = ui.reference("RAGE", "Aimbot", "Force safe point")
local ref_avoid_hitbox = ui.reference("Rage", "Aimbot", "Avoid unsafe hitboxes")
local ref_automatic_fire = ui.reference("RAGE", "Other", "Automatic fire")
local ref_automatic_penetration = ui.reference("RAGE", "Other", "Automatic penetration")
local ref_silent_aim = ui.reference("RAGE", "Other", "Silent aim")
local ref_hitchance = ui.reference("RAGE", "Aimbot", "Minimum hit chance")
local ref_mindamage = ui.reference("RAGE", "Aimbot", "Minimum damage")
local ref_automatic_scope = ui.reference("RAGE", "Aimbot", "Automatic scope")
local ref_reduce_aimstep = ui.reference("RAGE", "Other", "Reduce aim step")
local ref_max_fov = ui.reference("Rage", "Other", "Maximum FOV")
local ref_log_spread = ui.reference("RAGE", "Other", "Log misses due to spread")
local ref_low_fps_mitigations = ui.reference("RAGE", "Other", "Low FPS mitigations")
local ref_remove_recoil = ui.reference("RAGE", "Other", "Remove recoil")
local ref_accuracy_boost = ui.reference("RAGE", "Other", "Accuracy boost")
local ref_delay_shot = ui.reference("RAGE", "Other", "Delay shot")
local ref_quickstop, ref_quickstopkey,ref_quickstop_options = ui.reference("RAGE", "Aimbot", "Quick stop")
-- local ref_quickstop_options = ui.reference("RAGE", "Aimbot", "Quick stop options")
local ref_quick_peek, ref_quick_peek_key = ui.reference("Rage", "Other", "Quick peek assist")
local ref_antiaim_correction = ui.reference("RAGE", "Other", "Anti-aim correction")
-- local ref_antiaim_correction_override = ui.reference("RAGE", "Other", "Anti-aim correction override")
local ref_prefer_bodyaim = ui.reference("RAGE", "Aimbot", "Prefer body aim")
local ref_prefer_bodyaim_disablers = ui.reference("RAGE", "Aimbot", "Prefer body aim disablers")
local ref_force_bodyaim = ui.reference("RAGE", "Aimbot", "Force body aim")
local ref_force_bodyaim_onpeek = ui.reference("RAGE", "Aimbot", "Force body aim on peek")
local fd_key = ui.reference("RAGE", "Other", "Duck peek assist")
local dt, dt_key,dt_mode = ui.reference("RAGE", "Aimbot", "Double tap")
-- local dt_mode = ui.reference("RAGE", "Aimbot", "Double tap mode")
local ref_doubletap_hitchance = ui.reference("rage", "Aimbot", "Double tap hit chance")
local ref_doubletap_stop = ui.reference("RAGE", "Aimbot", "Double tap quick stop")
local function contains(table, val)
    if #table > 0 then
        for i = 1, #table do
            if table[i] == val then
                return true
            end
        end
    end
    return false
end
local function avoid_hitbox()
    local avoid_list = {}
    if #ui.get(rage[active_idx].target_hitbox) > 0 then
        for i = 1, #ui.get(rage[active_idx].target_hitbox) do
            if ui.get(rage[active_idx].target_hitbox)[i] == "Head" or ui.get(rage[active_idx].target_hitbox)[i] ==
                "Chest" or ui.get(rage[active_idx].target_hitbox)[i] == "Stomach" then
                avoid_list[i] = ui.get(rage[active_idx].target_hitbox)[i]
            end
        end
        if #avoid_list == 0 then
            avoid_list[1] = "Head"
        end
    end
    return avoid_list
end
local function get_distance(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end
local function get_closest_player()
    local local_player = entity.get_local_player()
    local lx, ly, lz = entity.get_prop(local_player, "m_vecOrigin")
    local players = entity.get_players(true)
    if #players == 0 then
        return 0, 0, 0, 0
    end
    local close_idx
    local closest_distance = math.huge
    for i = 1, #players do
        local ent = players[i]
        local x, y, z = entity.get_prop(ent, "m_vecOrigin")
        local distance = get_distance(lx, ly, lz, x, y, z)
        if distance <= closest_distance then
            close_idx = ent
            closest_distance = distance
        end
    end
    local close_name = entity.get_player_name(close_idx)
    local vec_vel = {entity.get_prop(close_idx, 'm_vecVelocity')}
    local close_vel = math.floor(math.sqrt(vec_vel[1] ^ 2 + vec_vel[2] ^ 2) + 0.5)
    local flags = entity.get_prop(close_idx, "m_fFlags")
    local close_jump = bit.band(flags, 1) ~= 1
    return close_idx, close_name, close_vel, close_jump
end
local function refresh_ui()
    for i = 1, #config_names do
        local show = ui.get(active_wpn) == config_names[i]
        ui.set_visible(rage[i].enabled, show and i > 1)
        ui.set_visible(rage[i].fixmenu, show)
        ui.set_visible(rage[i].nil_label, show)
        ui.set_visible(rage[i].text_label, show)
        ui.set_visible(to_exp[name_to_num2[i + 1]].import, show)
        ui.set_visible(to_exp[name_to_num2[i + 1]].export, show)
        ui.set_visible(rage[i].target_selection, show)
        ui.set_visible(rage[i].target_hitbox, show)
        ui.set_visible(rage[i].multipoint, show)
        ui.set_visible(rage[i].multipoint_scale, show and #{ui.get(rage[i].multipoint)} > 0)
        ui.set_visible(rage[i].prefer_safe_point, show)
        ui.set_visible(rage[i].avoid_unsafe_hitbox, show)
        ui.set_visible(rage[i].hitchance, show)
        ui.set_visible(rage[i].min_damage, show)
        ui.set_visible(rage[i].automatic_scope, show)
        ui.set_visible(rage[i].extend_aimbot, show)
        ui.set_visible(rage[i].ov_hitbox, show)
        ui.set_visible(rage[i].ov_avoid_unsafe_hitbox, show)
        local ex_table = ui.get(rage[i].extend_aimbot)
        ui.set_visible(rage[i].ov_hitbox, show and contains(ex_table, "Override hitbox"))
        ui.set_visible(rage[i].ov_avoid_unsafe_hitbox, show and contains(ex_table, "Override Unsafe hitboxes"))
        ui.set_visible(rage[i].override_multi_point, show and contains(ex_table, "Override Mulit-Point"))
        ui.set_visible(rage[i].noscope_hitchance, show and contains(ex_table, "No scope HC"))
        local jumphchaha = contains(ex_table, "Jump HC")
        ui.set_visible(rage[i].jp_hitchance, show and jumphchaha)
        ui.set_visible(rage[i].jp_hitchance_shift, show and jumphchaha)
        ui.set_visible(rage[i].jp_hc_lowspeedchange, show and jumphchaha)
        ui.set_visible(rage[i].override_hitchance, show and contains(ex_table, "Override HC"))
        ui.set_visible(rage[i].vs_min_damage, show and contains(ex_table, "Visible dmg"))
        ui.set_visible(rage[i].noscope_min_damage, show and contains(ex_table, "No scope dmg"))
        ui.set_visible(rage[i].jp_min_damage, show and contains(ex_table, "Jump dmg"))
        ui.set_visible(rage[i].ov1_min_damage, show and contains(ex_table, "Override 1 dmg"))
        ui.set_visible(rage[i].ov2_min_damage, show and contains(ex_table, "Override 2 dmg"))
        ui.set_visible(rage[i].ov3_min_damage, show and contains(ex_table, "Override 3 dmg"))

        ui.set_visible(rage[i].accuracy_boost, show)
        ui.set_visible(rage[i].delay_shot, show)
        ui.set_visible(rage[i].force_bodyaim_onpeek, show)
        ui.set_visible(rage[i].quick_stop, show)
        ui.set_visible(rage[i].quick_stop_options, show and ui.get(rage[i].quick_stop))
        ui.set_visible(rage[i].noscope_quick_stop, show)
        ui.set_visible(rage[i].quick_stop_longdist, show)
        ui.set_visible(rage[i].quick_stop_longdist_distance, show and ui.get(rage[i].quick_stop_longdist))
        ui.set_visible(rage[i].quick_stop_longdist_mode, show and ui.get(rage[i].quick_stop_longdist))
        ui.set_visible(rage[i].noscope_quick_stop_options, show and ui.get(rage[i].noscope_quick_stop))
        ui.set_visible(rage[i].prefer_baim, show)
        ui.set_visible(rage[i].prefer_baim_disablers, show and ui.get(rage[i].prefer_baim))
        ui.set_visible(rage[i].dt, show)
        ui.set_visible(rage[i].doubletap_hitchance, show and ui.get(rage[i].dt))
        ui.set_visible(rage[i].doubletap_stop, show and ui.get(rage[i].dt))
    end
    local aimbot_visible = contains(ui.get(debug_ui), "Aimbot") or false
    local other_visible = contains(ui.get(debug_ui), "Other") or false
    if close_ui then
        other_visible = true;
        aimbot_visible = true
    end
    ui.set_visible(ref_target, aimbot_visible)
    ui.set_visible(ref_hitbox, aimbot_visible)
    ui.set_visible(ref_multipoint, aimbot_visible)
    ui.set_visible(ref_multipointkey, aimbot_visible)
    ui.set_visible(ref_multipoint_scale, aimbot_visible)
    ui.set_visible(ref_prefer_safepoint, aimbot_visible)
    ui.set_visible(ref_avoid_hitbox, aimbot_visible)
    ui.set_visible(ref_automatic_fire, aimbot_visible)
    ui.set_visible(ref_automatic_penetration, aimbot_visible)
    ui.set_visible(ref_silent_aim, aimbot_visible)
    ui.set_visible(ref_hitchance, aimbot_visible)
    ui.set_visible(ref_mindamage, aimbot_visible)
    ui.set_visible(ref_automatic_scope, aimbot_visible)
    ui.set_visible(ref_reduce_aimstep, aimbot_visible)
    ui.set_visible(ref_max_fov, aimbot_visible)
    ui.set_visible(ref_log_spread, aimbot_visible)
    ui.set_visible(ref_low_fps_mitigations, aimbot_visible)
    ui.set_visible(ref_remove_recoil, other_visible)
    ui.set_visible(ref_accuracy_boost, other_visible)
    ui.set_visible(ref_delay_shot, other_visible)
    ui.set_visible(ref_force_bodyaim_onpeek, other_visible)
    ui.set_visible(ref_quickstop, other_visible)
    ui.set_visible(ref_quickstopkey, other_visible)
    ui.set_visible(ref_quickstop_options, other_visible)
    ui.set_visible(ref_prefer_bodyaim, other_visible)
    ui.set_visible(ref_prefer_bodyaim_disablers, other_visible)
    ui.set_visible(ref_doubletap_stop, other_visible)
end
local function enemy_visible()
    for _, idx in pairs(entity.get_players(true)) do
        for i = 0, 18 do
            local cx, cy, cz = entity.hitbox_position(idx, i)
            if client.visible(cx, cy, cz) then
                return true
            end
        end
    end
    return false
end
local function tointeger(n)
    return math.floor(n + 0.5)
end
local function get_speed(t)
    local vx, vy = get_prop(get_local_player(), "m_vecVelocity")
    return vx and tointeger(math.min(10000, math.sqrt(vx * vx + vy * vy))) or 0
end
local function set_config(idx)
    local localp = entity.get_local_player()
    local i = ui.get(rage[idx].enabled) and idx or 1
    local rage_hitboxes = ui.get(rage[i].target_hitbox)
    if #rage_hitboxes == 0 then
        ui.set(rage[i].target_hitbox, "Head")
    end
    local scoped = entity.get_prop(localp, 'm_bIsScoped') == 1
    local close_idx, close_name, close_vel, close_jump = get_closest_player()
    ui.set(ref_target, ui.get(rage[i].target_selection))

    local hitbox = {}
    local damage = 0
    local hitchance = 0
    local muilts = 50
    local ex_table = ui.get(rage[i].extend_aimbot)

    local flags = entity.get_prop(localp, "m_fFlags")
    local jump = bit.band(flags, 1) ~= 1
    local vis_damage = false
    local enemys = entity.get_players(true)
    local enable_visidmg = contains(ex_table, "Visible dmg")
    local earlymode = ui.get(rage[i].quick_stop_longdist)
    local target = client.current_threat()
    if target then
        ui_dist = ui.get(rage[i].quick_stop_longdist_distance)
        local lx, ly, lz = entity.get_prop(localp, "m_vecOrigin")
        local x, y, z = entity.get_prop(target, "m_vecOrigin")
        real_dist = math.floor(get_distance(lx, ly, lz, x, y, z))
        target_name = entity.get_player_name(target)
        is_longdistmode_and_target_not_nil = earlymode and real_dist > ui_dist
    else
        is_longdistmode_and_target_not_nil = false
    end
    if enable_visidmg then
        for _, idx in pairs(enemys) do
            for i = 0, 18 do
                local cx, cy, cz = entity.hitbox_position(idx, i)
                if client.visible(cx, cy, cz) then
                    vis_damage = true
                end
            end
        end
    end
    if ui.get(override_hitbox_key) and contains(ex_table, "Override hitbox") then
        hitbox = #ui.get(rage[i].ov_hitbox) == 0 and {"Head"} or ui.get(rage[i].ov_hitbox)
        Hitboxx = true
    else
        hitbox = ui.get(rage[i].target_hitbox)
        Hitboxx = false
    end
    local hchhhaah = contains(ex_table, "Jump HC")
    if contains(ex_table, "Override HC") and ui.get(override_hitchance_key) then
        Hitchancee = true
        hitchance = ui.get(rage[i].override_hitchance)
        -- elseif contains(ex_table, "Jump HC") and jump and ui.get(rage[i].jp_hc_lowspeedchange) and
    elseif hchhhaah and ui.get(slow) and jump then
        hitchance = ui.get(rage[i].jp_hitchance_shift)
    elseif hchhhaah and jump and ui.get(rage[i].jp_hc_lowspeedchange) and -- 鸟狙
    ((get_speed() < 200) or ui.get(slow)) then
        hitchance = ui.get(rage[i].jp_hitchance)
    elseif hchhhaah and jump and not ui.get(rage[i].jp_hc_lowspeedchange) then
        hitchance = ui.get(rage[i].jp_hitchance)
    elseif not scoped and contains(ex_table, "No scope HC") then
        hitchance = ui.get(rage[i].noscope_hitchance)
    else
        Hitchancee = false
        hitchance = ui.get(rage[i].hitchance)
    end
    if contains(ex_table, "Override 3 dmg") and ui.get(override_dmg_3) then
        damage = ui.get(rage[i].ov3_min_damage)
    elseif contains(ex_table, "Override 2 dmg") and ui.get(override_dmg_2) then
        damage = ui.get(rage[i].ov2_min_damage)
    elseif contains(ex_table, "Override 1 dmg") and ui.get(override_dmg_1) then
        damage = ui.get(rage[i].ov1_min_damage)
    elseif contains(ex_table, "Jump dmg") and jump then
        damage = ui.get(rage[i].jp_min_damage)
    elseif not scoped and contains(ex_table, "No scope dmg") then
        damage = ui.get(rage[i].noscope_min_damage)
    elseif enable_visidmg and vis_damage then
        damage = ui.get(rage[i].vs_min_damage)
    else
        damage = ui.get(rage[i].min_damage)
    end
    ui.set(ref_hitbox, hitbox)
    ui.set(ref_multipoint, ui.get(rage[i].multipoint))
    ui.set(ref_prefer_safepoint, ui.get(rage[i].prefer_safe_point))

    ui.set(ref_automatic_fire, true)
    ui.set(ref_automatic_penetration, true)
    ui.set(ref_silent_aim, true)

    if ui.get(override_multi_point_key) and contains(ex_table, "Override Mulit-Point") then
        ui.set(ref_multipoint_scale, ui.get(rage[i].override_multi_point))
        MultiPointScalee = true
    else
        ui.set(ref_multipoint_scale, ui.get(rage[i].multipoint_scale))
        MultiPointScalee = false
    end
    if ui.get(override_unsafehitboxes_key) and contains(ex_table, "Override Unsafe hitboxes") then
        ui.set(ref_avoid_hitbox, ui.get(rage[i].ov_avoid_unsafe_hitbox))
        UnsafeHitboxx = true
    else
        ui.set(ref_avoid_hitbox, ui.get(rage[i].avoid_unsafe_hitbox))
        UnsafeHitboxx = false
    end
    ui.set(ref_hitchance, hitchance)
    ui.set(ref_mindamage, damage)
    ui.set(ref_automatic_scope, ui.get(rage[i].automatic_scope))
    ui.set(ref_accuracy_boost, ui.get(rage[i].accuracy_boost))
    ui.set(ref_delay_shot, ui.get(rage[i].delay_shot))
    ui.set(ref_force_bodyaim_onpeek, ui.get(rage[i].force_bodyaim_onpeek))
    ui.set(ref_quickstop, ui.get(rage[i].quick_stop))
    if ui.get(rage[i].noscope_quick_stop) then
        ui.set(ref_quickstop_options,
            scoped and (is_longdistmode_and_target_not_nil and ui.get(rage[i].quick_stop_longdist_mode) or ui.get(rage[i].quick_stop_options)) or ui.get(rage[i].noscope_quick_stop_options))
    else
        ui.set(ref_quickstop_options, (is_longdistmode_and_target_not_nil and ui.get(rage[i].quick_stop_longdist_mode) or ui.get(rage[i].quick_stop_options)))
    end
    if contains(ex_table, "NOT PREBAIM") and ui.get(override_prebaim) then
        NOTPREBAIMM = true
        ui.set(ref_prefer_bodyaim, false)
    else
        ui.set(ref_prefer_bodyaim, ui.get(rage[i].prefer_baim))
        NOTPREBAIMM = false
    end
    DMG3 = contains(ex_table, "Override 3 dmg") and ui.get(override_dmg_3)
    DMG2 = contains(ex_table, "Override 2 dmg") and ui.get(override_dmg_2)
    -- ui.set(ref_prefer_bodyaim, ui.get(rage[i].prefer_baim))
    ui.set(ref_prefer_bodyaim_disablers, ui.get(rage[i].prefer_baim_disablers))
    ui.set(dt, ui.get(rage[i].dt))
    ui.set(ref_doubletap_hitchance, ui.get(rage[i].doubletap_hitchance))
    ui.set(ref_doubletap_stop, ui.get(rage[i].doubletap_stop))
    ui.set(ref_remove_recoil, true)

    active_idx = i
end
local airstrafe = ui.new_checkbox("misc", "movement", "Air strafe fix")
local function sadap_commado(c)
    local plocal = entity.get_local_player()
    local weapon = entity.get_player_weapon(plocal)
    if airstrafe then
        local weaponclass = entity.get_classname(weapon)
        local vel_x, vel_y = entity.get_prop(plocal, "m_vecVelocity")
        local vel = math.sqrt(vel_x ^ 2 + vel_y ^ 2)
        local strafe_off = ((weaponclass == "CWeaponSSG08" or weaponclass == "CHEGrenade" or weaponclass ==
                               "CSmokeGrenade" or weaponclass == "CIncendiaryGrenade" or weaponclass ==
                               "CMolotovGrenade") and c.in_jump and (vel < 10))
        ui.set(air_strafe, (not strafe_off) or ui.is_menu_open())
    end

    local cool_fix = entity.get_prop(weapon, "m_iItemDefinitionIndex")
    if cool_fix == nil then return end

    local weapon_id = bit.band(cool_fix, 0xFFFF)

    local wpn_text = config_names[weapon_idx[weapon_id]]

    if wpn_text ~= nil then
        if last_weapon ~= weapon_id then
            ui.set(active_wpn, ui.get(rage[weapon_idx[weapon_id]].enabled) and wpn_text or "Global")
            last_weapon = weapon_id
        end
        set_config(weapon_idx[weapon_id])
    else
        if last_weapon ~= weapon_id then
            ui.set(active_wpn, "Global")
            last_weapon = weapon_id
        end
        set_config(1)
    end
end

local function run_visuals()
    refresh_ui()
    if not ui.get(ref_enable) then
        return
    end
    if not ui.get(ref_enable_key) then
        return
    end
    local x, y = client.screen_size()
    if contains(ui.get(debug_ui), "Distance indicator") then
        renderer.indicator(255,255,255,255,"\aFFFFFFCFTarget: "..target_name)
        local dist = real_dist/10
        if is_longdistmode_and_target_not_nil then
            -- UI的比实际的低 override
            -- UI的比实际的高 not ovr
            local clr = real_dist < ui_dist and {220,220,220} or  {188, 245, 69}
            local text  = real_dist < ui_dist and " (-" .. (ui_dist - real_dist)/10 ..")" or " (+" .. (real_dist - ui_dist)/10 .. ")"
        renderer.indicator(clr[1],clr[2],clr[3],255,"Distance: ".. dist .. text)
        else
        renderer.indicator(220,220,220,255,"Distance: "..dist)
        end
    end
    local dmg_type = 0
    local a = (DMG3 or DMG2) and 255 or 120
    local mindmgtext = ui.get(ref_mindamage)
    local ui_dmg3 = ui.get(override_dmg_3)
    local ui_dmg2 = ui.get(override_dmg_2)
    local dmgtypetext = ui_dmg3 and "[type S3]" or (ui_dmg2 and "[type 2]" or "")

    -- if ui_dmg3 then
    --     renderer.text(x / 2 + 8, y / 2 - 29, 255, 255, 255, a, "", 0, dmgtypetext)
    --     renderer.text(x / 2 + 8, y / 2 - 19, 255, 255, 255, 255, "", 0, mindmgtext)
    --     dmg_type = 3
    -- elseif ui_dmg2 then
    --     renderer.text(x / 2 + 8, y / 2 - 29, 255, 255, 255, a, "", 0, dmgtypetext)
    --     renderer.text(x / 2 + 8, y / 2 - 19, 255, 255, 255, 255, "", 0, mindmgtext)
    --     dmg_type = 2
    -- elseif ui.get(override_dmg_1) then
    --     renderer.text(x / 2 + 8, y / 2 - 29, 255, 255, 255, a, "", 0, dmgtypetext)
    --     renderer.text(x / 2 + 8, y / 2 - 19, 255, 255, 255, 255, "", 0, mindmgtext)
    --     dmg_type = 1
    -- end
    if DMG2 then
        renderer.indicator(202,202,202, 255, "Override Damage 2")
    end
    if DMG3 then
        renderer.indicator(202,202,202, 255, "Override Damage 3")
    end
    if Hitboxx then
        renderer.indicator(202,202,202, 255, "Override Hitbox")
    end
    if UnsafeHitboxx then
        renderer.indicator(202,202,202, 255, "Override Unsafe Hitbox")
    end
    if MultiPointScalee then
        renderer.indicator(202,202,202, 255, "Override Multi-Point")
    end
    if NOTPREBAIMM then
        renderer.indicator(202,202,202, 255, "Prefer baim off")
    end

    if ui.get(override_hitchance_key) then
		renderer.indicator(255,255,255,255,"HITCHANCE OVR")
	end
end

client.set_event_callback("setup_command", sadap_commado)
client.set_event_callback("paint_ui", run_visuals)
client.set_event_callback("shutdown", function()
    close_ui = true
    ui.set(air_strafe, true)
    refresh_ui()
end)
local import_weapon = function()
    local table_ = str_to_sub(base64.decode(clipboard.get(), 'base64'), "|")
    local p = 1
    for i, o in pairs(to_exp.weapon['number']) do
        ui.set(o, table_[p])
        p = p + 1
    end
    for i, o in pairs(to_exp.weapon['string']) do
        ui.set(o, (table_[p]))
        p = p + 1
    end
    for i, o in pairs(to_exp.weapon['boolean']) do
        ui.set(o, to_boolean(table_[p]))
        p = p + 1
    end
    for i, o in pairs(to_exp.weapon['table']) do
        ui.set(o, str_to_sub(table_[p], ','))
        p = p + 1
    end
    client.color_log(156, 225, 81, "[Adaptive Weapon] Imported config from clipboard")
end
local export_weapon = function()
    local str = ""
    for i, o in pairs(to_exp.weapon['number']) do
        str = str .. tostring(ui.get(o)) .. '|'
    end
    for i, o in pairs(to_exp.weapon['string']) do
        -- print(ui.get(o))
        str = str .. ui.get(o) .. '|'
    end
    for i, o in pairs(to_exp.weapon['boolean']) do
        str = str .. tostring(ui.get(o)) .. '|'
    end
    for i, o in pairs(to_exp.weapon['table']) do
        str = str .. arr_to_string(o) .. '|'
    end
    clipboard.set(base64.encode(str, 'base64'))
    client.color_log(156, 225, 81, "[Adaptive Weapon] Exported config from clipboard")
end
ui.new_label("rage", "other", "\aA4EE54FFAdaptive Weapons Config")
local import_weaponcfg = ui.new_button("rage", "other", "\aD2D2D2FFImport \aA4EE54FFAdaptive \aD2D2D2FFConfig",
    import_weapon)
local export_weaponcfg = ui.new_button("rage", "other", "\aD2D2D2FFExport \aA4EE54FFAdaptive \aD2D2D2FFConfig",
    export_weapon)
