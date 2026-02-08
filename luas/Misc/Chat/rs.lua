-- 引用 UI API
local ui_new_checkbox = ui.new_checkbox
local ui_get = ui.get
local client_exec = client.exec
local globals_curtime = globals.curtime

-- -----------------------------------------------------------------------------
-- UI 定义
-- -----------------------------------------------------------------------------
local rs_spammer = ui_new_checkbox("MISC", "Miscellaneous", "Infinite RS Spammer")

-- -----------------------------------------------------------------------------
-- 逻辑处理
-- -----------------------------------------------------------------------------
local last_send_time = 0

local function on_paint()
    -- 如果控件未启用，则跳过
    if not ui_get(rs_spammer) then
        return
    end

    local current_time = globals_curtime()

    -- 设置发送频率：0.1 秒发送一次，防止控制台溢出导致卡顿
    -- 如果你想更疯狂一点，可以把 0.1 改成更小的值
    if current_time - last_send_time >= 0.1 then
        client_exec("rs")
        last_send_time = current_time
    end
end

-- -----------------------------------------------------------------------------
-- 注册回调
-- -----------------------------------------------------------------------------
-- 使用 paint 回调以确保脚本在开启时能持续运行
client.set_event_callback("paint", on_paint)