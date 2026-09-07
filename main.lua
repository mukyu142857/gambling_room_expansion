-- 向游戏注册这个模组
local GamblingRoomExpansion = RegisterMod("Gambling Room Expansion", 1)

-- 原型阶段用 SubType 100 区分魂心机器和普通献血机
local SOUL_MACHINE_SUBTYPE = 100

-- 魂心机器平时显示的蓝色
local SOUL_MACHINE_COLOR = Color(
    0.4,
    0.7,
    1,
    1,
    0,
    0,
    0.4
)

Isaac.DebugString("[Gambling Room Expansion] main.lua loaded successfully")

-- 当魂心机器生成或重新进入房间时，恢复它的蓝色外观
local function ApplySoulMachineAppearance(slot)
    -- 普通献血机不需要处理
    if slot.SubType ~= SOUL_MACHINE_SUBTYPE then
        return
    end

    local data = slot:GetData()

    -- MC_POST_SLOT_UPDATE 每秒会执行很多次，
    -- 所以每次实体生成后只染色一次
    if data.GREColorApplied then
        return
    end

    data.GREColorApplied = true

    slot:SetColor(
        SOUL_MACHINE_COLOR,
        -1,
        1,
        false,
        false
    )
end

-- 玩家接触测试机器时执行
local function OnSoulMachineCollision(_, slot, collider)
    -- 现在使用 SubType 判断身份，不再依赖临时的 IsSoulMachine
    if slot.SubType ~= SOUL_MACHINE_SUBTYPE then
        return
    end

    -- 检查碰到机器的实体是不是玩家
    local player = collider:ToPlayer()

    if player == nil then
        return
    end

    local data = slot:GetData()

    -- 每次进入这个房间后，第一次碰到机器时暂时染成绿色
    if not data.GREHasBeenTouched then
        data.GREHasBeenTouched = true

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

-- 每次槽机更新时，确认魂心机器的外观已经恢复
local function OnSoulMachineUpdate(_, slot)
    ApplySoulMachineAppearance(slot)
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
    SOUL_MACHINE_SUBTYPE,
    player.Position + Vector(80, 0),
    Vector.Zero,
    nil
)

-- 生成后立即应用魂心机器外观
ApplySoulMachineAppearance(machine)

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

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_POST_SLOT_UPDATE,
    OnSoulMachineUpdate,
    SlotVariant.BLOOD_DONATION_MACHINE
)