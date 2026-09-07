-- 向游戏注册这个模组
local GamblingRoomExpansion = RegisterMod("Gambling Room Expansion", 1)

Isaac.DebugString("[Gambling Room Expansion] main.lua loaded successfully")

-- 玩家接触测试机器时执行
local function OnSoulMachineCollision(_, slot, collider)
    local data = slot:GetData()

    -- 普通献血机不受影响
    if not data.IsSoulMachine then
        return
    end

    -- 检查碰到机器的实体是不是玩家
    local player = collider:ToPlayer()

    if player == nil then
        return
    end

    -- 第一次碰到时，把机器暂时染成绿色
    if not data.HasBeenTouched then
        data.HasBeenTouched = true

        slot:SetColor(
            Color(0.4, 1, 0.4, 1, 0, 0.3, 0),
            -1,
            1,
            false,
            false
        )

        Isaac.DebugString(
            "[Gambling Room Expansion] test soul machine touched"
        )
    end

    -- 保留实体碰撞，但阻止原版献血机的扣血和奖励代码
    return false
end

-- 处理控制台命令
local function OnExecuteCommand(_, command)
    if command ~= "spawnsoulmachine" then
        return
    end

    local player = Isaac.GetPlayer(0)

    local machine = Isaac.Spawn(
        EntityType.ENTITY_SLOT,
        SlotVariant.BLOOD_DONATION_MACHINE,
        0,
        player.Position + Vector(80, 0),
        Vector.Zero,
        nil
    )

    -- 临时染成蓝色
    machine:SetColor(
        Color(0.4, 0.7, 1, 1, 0, 0, 0.4),
        -1,
        1,
        false,
        false
    )

    -- 标记为我们的测试机器
    machine:GetData().IsSoulMachine = true

    Isaac.DebugString(
        "[Gambling Room Expansion] test soul machine spawned"
    )
end

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_EXECUTE_CMD,
    OnExecuteCommand
)

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_PRE_SLOT_COLLISION,
    OnSoulMachineCollision,
    SlotVariant.BLOOD_DONATION_MACHINE
)