local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        float x, y, z;
    } Vector;
    typedef void (__fastcall *Spawn_Electric_Spark)(const Vector &pos, int nMagnitude, int nTrailLength, const Vector *vecDir);
]]

local match = client.find_signature("client.dll", "\x55\x8B\xEC\x83\xEC\x3C\x53\x8B\xD9\x89\x55\xFC\x8B\x0D\xCC\xCC\xCC\xCC\x56\x57") or error("sign not found")
local ElectricSpark = ffi.cast("Spawn_Electric_Spark", match)

local enabled = ui.new_checkbox("VISUALS", "Effects", "\aFDD6C8FF Enable Hit Spark")
local Spark_Number = ui.new_slider("VISUALS", "Effects", "\aEDA390FF Spark Number", 1, 10, 3)
local Spark_Length = ui.new_slider("VISUALS", "Effects", "\aEDA390FF Spark Length", 1, 10, 5)
local Spark_Pos, null_pos = ffi.new("Vector")

local function bullet_impact(e)
    if not ui.get(enabled) then return end
    Spark_Pos.x = e.x
    Spark_Pos.y = e.y
    Spark_Pos.z = e.z
    ElectricSpark(Spark_Pos, ui.get(Spark_Number), ui.get(Spark_Length), null_pos)
end

client.set_event_callback("bullet_impact", bullet_impact)