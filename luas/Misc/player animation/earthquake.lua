local ffi = require("ffi")

-- --- FFI 基础指针获取 ---
local native_GetClientEntity = vtable_bind("client.dll", "VClientEntityList003", 3, "void*(__thiscall*)(void*, int)")

local memory = {}
memory.animlayers = {} do
    if not pcall(ffi.typeof, 'bt_animlayer_t') then
        ffi.cdef[[
            typedef struct {
                float   anim_time;
                float   fade_out_time;
                int     nil;
                int     activty;
                int     priority;
                int     order;
                int     sequence;
                float   prev_cycle;
                float   weight;
                float   weight_delta_rate;
                float   playback_rate;
                float   cycle;
                int     owner;
                int     bits;
            } bt_animlayer_t, *pbt_animlayer_t;
        ]]
    end

    -- 查找动画层偏移
    local sig = client.find_signature('client.dll', '\x8B\x89\xCC\xCC\xCC\xCC\x8D\x0C\xD1')
    if sig then
        memory.animlayers.offset = ffi.cast('int*', ffi.cast('uintptr_t', sig) + 2)[0]
    end

    -- 获取动画层指针函数
    memory.animlayers.get = function (ent_index)
        if not memory.animlayers.offset then return nil end
        local client_entity = native_GetClientEntity(ent_index)
        if client_entity == nil then return nil end
        return ffi.cast('pbt_animlayer_t*', ffi.cast('uintptr_t', client_entity) + memory.animlayers.offset)[0]
    end
end

-- --- UI 菜单 ---
local earthquake_switch = ui.new_checkbox("AA", "Other", "Earthquake (FFI)")
local min_magnitude = ui.new_slider("AA", "Other", "Earthquake Min", -200, 200, -30, true, "f", 0.01)
local max_magnitude = ui.new_slider("AA", "Other", "Earthquake Max", -200, 200, 75, true, "f", 0.01)

-- 菜单联动显示
local function handle_ui()
    local active = ui.get(earthquake_switch)
    ui.set_visible(min_magnitude, active)
    ui.set_visible(max_magnitude, active)
end
ui.set_callback(earthquake_switch, handle_ui)
handle_ui()

-- --- 核心逻辑 ---
client.set_event_callback("pre_render", function()
    if not ui.get(earthquake_switch) then return end

    local me = entity.get_local_player()
    if not me or not entity.is_alive(me) then return end

    local layers = memory.animlayers.get(me)
    if layers ~= nil then
        -- 从滑块获取实时数值并转换回原始比例
        local min_val = ui.get(min_magnitude) * 0.01
        local max_val = ui.get(max_magnitude) * 0.01

        -- 修改 Lean 层 (Layer 12) 权重实现“地震”
        layers[12].weight = client.random_float(min_val, max_val)
    end
end)