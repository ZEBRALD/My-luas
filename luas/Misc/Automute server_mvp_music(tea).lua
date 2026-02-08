local ui_new_checkbox = ui.new_checkbox
local ui_get = ui.get
local client_exec = client.exec
local client_delay_call = client.delay_call
local client_set_event_callback = client.set_event_callback

-- -----------------------------------------------------------------------------
-- UI 定义
-- -----------------------------------------------------------------------------
local master_switch = ui_new_checkbox("MISC", "Miscellaneous", "Mute MVPmusic")

-- -----------------------------------------------------------------------------
-- 逻辑处理
-- -----------------------------------------------------------------------------
local has_executed_on_this_map = false

local function run_mvp_sequence()
    -- 只有开关开启且本局还没执行过才运行
    if not ui_get(master_switch) then return end

    print("[MVP Fixer] Map loaded/Retry detected. Running fast sequence...")

    -- 1. 呼出菜单
    client_exec("say !mvp")

    -- 2. 选择第一项 (0.4秒后)
    client_delay_call(0.4, function()
        client_exec("menuselect 1")
        client_exec("slot1")
    end)

    -- 3. 再次选择第一项 (0.7秒后)
    client_delay_call(0.7, function()
        client_exec("menuselect 1")
        client_exec("slot1")
    end)

    -- 4. 选择第九项并关闭 (1.0秒后)
    client_delay_call(1.0, function()
        client_exec("menuselect 9")
        client_exec("slot9")
        client_exec("slot0")
    end)
    
    print("[MVP Fixer] Sequence completed.")
end

-- -----------------------------------------------------------------------------
-- 事件监听
-- -----------------------------------------------------------------------------

-- 核心修复：当关卡初始化（换图、retry、初次进入）时触发
client_set_event_callback("level_init", function()
    -- 重置标记位，允许在新地图或新链接中再次执行
    has_executed_on_this_map = false
end)

-- 监听玩家进入游戏
client_set_event_callback("player_connect_full", function(e)
    if not ui_get(master_switch) then return end
    
    -- 确认是本地玩家
    if client.userid_to_entindex(e.userid) == entity.get_local_player() then
        -- 如果本局还没执行
        if not has_executed_on_this_map then
            has_executed_on_this_map = true
            
            -- 加入游戏 5 秒后执行序列
            print("[MVP Fixer] Fully connected. Running in 5s...")
            client_delay_call(5.0, run_mvp_sequence)
        end
    end
end)

-- 额外的安全网：监听 client_disconnect 确保彻底清除
client_set_event_callback("client_disconnect", function()
    has_executed_on_this_map = false
end)