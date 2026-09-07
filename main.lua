-- 向游戏注册这个模组
local GamblingRoomExpansion = RegisterMod("Gambling Room Expansion", 1)

-- 在游戏日志中留下加载成功的信息
Isaac.DebugString("[Gambling Room Expansion] main.lua loaded successfully")

-- 处理控制台命令
local function OnExecuteCommand(_, command)
    -- 如果输入的不是我们的命令，就不执行后面的内容
    if command ~= "spawnsoulmachine" then
        return
    end

    local player = Isaac.GetPlayer(0)

    -- 在角色右边生成一台献血机
    local machine = Isaac.Spawn(
        EntityType.ENTITY_SLOT,
        SlotVariant.BLOOD_DONATION_MACHINE,
        0,
        player.Position + Vector(80, 0),
        Vector.Zero,
        nil
    )

    -- 暂时关闭碰撞，防止它执行原版献血机功能
    machine.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE

    -- 临时染成蓝色，方便辨认
    machine:SetColor(
        Color(0.4, 0.7, 1, 1, 0, 0, 0.4),
        -1,
        1,
        false,
        false
    )

    -- 给它添加一个隐藏标记，供后续代码识别
    machine:GetData().IsSoulMachine = true

    Isaac.DebugString("[Gambling Room Expansion] test soul machine spawned")
end

-- 输入控制台命令时，执行上面的函数
GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_EXECUTE_CMD,
    OnExecuteCommand
)