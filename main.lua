-- 向游戏注册这个模组
local GamblingRoomExpansion = RegisterMod("Gambling Room Expansion", 1)

-- 必须与 content/entities2.xml 中的 name 完全一致
local SOUL_MACHINE_NAME = "GRE Soul Heart Machine"

-- 按名称取得游戏最终分配给魂心机器的 Variant
local SOUL_MACHINE_VARIANT =
    Isaac.GetEntityVariantByName(SOUL_MACHINE_NAME)

Isaac.DebugString("[Gambling Room Expansion] main.lua loaded successfully")

-- 玩家接触魂心机器时执行
local function OnSoulMachineCollision(_, slot, collider)
    -- 只处理我们的独立 Variant，其他机器不受影响
    if slot.Variant ~= SOUL_MACHINE_VARIANT then
        return
    end

    -- 只有玩家碰到机器时才处理
    if collider:ToPlayer() == nil then
        return
    end

    -- 暂时只保留碰撞，不扣血，也不给奖励
    return false
end

-- REPENTOGON：允许自定义机器在重新进入房间时恢复
local function OnIsPersistentRoomEntity(_, entityType, variant)
    if entityType == EntityType.ENTITY_SLOT
        and variant == SOUL_MACHINE_VARIANT then
        return true
    end
end

-- 处理控制台命令
local function OnExecuteCommand(_, command)
    if command ~= "spawnsoulmachine" then
        return
    end

    -- -1 表示 entities2.xml 中没有找到这个内部名称
    if SOUL_MACHINE_VARIANT == -1 then
        Isaac.DebugString(
            "[Gambling Room Expansion] soul machine entity was not found"
        )
        return
    end

    local player = Isaac.GetPlayer(0)

    Isaac.Spawn(
        EntityType.ENTITY_SLOT,
        SOUL_MACHINE_VARIANT,
        0,
        player.Position + Vector(80, 0),
        Vector.Zero,
        nil
    )

    Isaac.DebugString(
        "[Gambling Room Expansion] custom soul machine spawned"
    )
end

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_EXECUTE_CMD,
    OnExecuteCommand
)

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_PRE_SLOT_COLLISION,
    OnSoulMachineCollision
)

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_IS_PERSISTENT_ROOM_ENTITY,
    OnIsPersistentRoomEntity
)
