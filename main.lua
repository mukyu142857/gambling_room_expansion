-- 向游戏注册这个模组
local GamblingRoomExpansion = RegisterMod("Gambling Room Expansion", 1)

-- 负责播放游戏音效；只需要创建一次，之后重复使用
local SFX_MANAGER = SFXManager()

-- 必须与 content/entities2.xml 中的 name 完全一致
local SOUL_MACHINE_NAME = "GRE Soul Heart Machine"

-- 按名称取得游戏最终分配给魂心机器的 Variant
local SOUL_MACHINE_VARIANT =
    Isaac.GetEntityVariantByName(SOUL_MACHINE_NAME)

-- 每次普通支付后，生成魂心奖励的概率为 1/8
local SOUL_HEART_DROP_CHANCE_DENOMINATOR = 8

-- 每次成功献血有 1/15 的概率让机器爆炸并给出最终奖励
local SOUL_MACHINE_BREAK_CHANCE = 15

-- 两次使用之间至少间隔 30 帧，避免接触一瞬间连续扣血
local SOUL_MACHINE_USE_COOLDOWN = 30

-- 这些名称来自目前借用的原版献血机 anm2
local SOUL_MACHINE_USE_ANIMATION = "Prize"
local SOUL_MACHINE_IDLE_ANIMATION = "Idle"

-- 让机器造成一次红心伤害，并且不影响恶魔房/天使房概率
local SOUL_MACHINE_DAMAGE_FLAGS = (
    DamageFlag.DAMAGE_RED_HEARTS
    | DamageFlag.DAMAGE_INVINCIBLE
    | DamageFlag.DAMAGE_NO_PENALTIES
)

Isaac.DebugString("[Gambling Room Expansion] main.lua loaded successfully")

-- 进行一次 10% 的奖励判定
local function TrySpawnSoulHeart(slot)
    local rng = slot:GetDropRNG()

    -- RandomInt(8) 会得到 0 到 7；只有得到 0 才算成功
    if rng:RandomInt(SOUL_HEART_DROP_CHANCE_DENOMINATOR) ~= 0 then
        return
    end

    -- 成功后，完整魂心和半魂心各占一半
    local heartSubType = HeartSubType.HEART_SOUL

    if rng:RandomInt(2) == 0 then
        heartSubType = HeartSubType.HEART_HALF_SOUL
    end

    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_HEART,
        heartSubType,
        slot.Position,
        Vector(0, 3),
        slot
    )
end

-- 播放一次献血反馈：机器动画、献血机音效和血液飞溅
local function PlaySoulMachineUseEffect(slot)
    local sprite = slot:GetSprite()

    sprite:Play(SOUL_MACHINE_USE_ANIMATION, true)

    SFX_MANAGER:Play(
        SoundEffect.SOUND_BLOODBANK_SPAWN,
        1,
        2,
        false,
        1
    )

    local bloodEffect = Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.BLOOD_EXPLOSION,
        3,
        slot.Position,
        Vector.Zero,
        slot
    )

    bloodEffect:GetSprite().Offset = Vector(0, -2)
    bloodEffect.DepthOffset = 5
end

-- 判定机器是否爆炸；成功时掉落魂心吊坠并返回 true
local function TryBreakSoulMachine(slot)
    local rng = slot:GetDropRNG()

    -- RandomInt(15) 会得到 0 到 14，只有得到 0 才爆炸
    if rng:RandomInt(SOUL_MACHINE_BREAK_CHANCE) ~= 0 then
        return false
    end

    local machinePosition = slot.Position

    -- 道具已经由机器生成，因此把它从本局普通道具池中移除
    Game():GetItemPool():RemoveCollectible(
        CollectibleType.COLLECTIBLE_SOUL_LOCKET
    )

    -- 这是不会额外伤害玩家的爆炸画面
    Isaac.Spawn(
        EntityType.ENTITY_EFFECT,
        EffectVariant.BOMB_EXPLOSION,
        0,
        machinePosition,
        Vector.Zero,
        nil
    )

    Isaac.Spawn(
        EntityType.ENTITY_PICKUP,
        PickupVariant.PICKUP_COLLECTIBLE,
        CollectibleType.COLLECTIBLE_SOUL_LOCKET,
        machinePosition,
        Vector.Zero,
        nil
    )

    -- 最终奖励出现后，移除完整的机器实体
    slot:Remove()

    return true
end

-- 为炸毁机器后生成的掉落物计算一个随机飞出方向
local function GetExplosionDropVelocity(rng)
    local angle = rng:RandomFloat() * 360
    local speed = 2 + rng:RandomFloat() * 3

    return Vector.FromAngle(angle) * speed
end

-- REPENTOGON：替换魂心机器被炸弹摧毁时的普通掉落
local function OnSoulMachineExplosionDrops(_, slot)
    local rng = slot:GetDropRNG()

    -- 原版献血机先生成 1 到 2 组掉落
    local dropGroupCount = rng:RandomInt(2) + 1

    for _ = 1, dropGroupCount do
        local spawnSoulHeart = rng:RandomInt(2) == 0

        if spawnSoulHeart then
            -- 原版这里生成红心；我们的机器将其替换为完整魂心
            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_HEART,
                HeartSubType.HEART_SOUL,
                slot.Position,
                GetExplosionDropVelocity(rng),
                slot
            )
        else
            -- 金币组保持原版规则：生成 1 到 4 枚随机金币
            local coinCount = rng:RandomInt(4) + 1

            for _ = 1, coinCount do
                Isaac.Spawn(
                    EntityType.ENTITY_PICKUP,
                    PickupVariant.PICKUP_COIN,
                    0,
                    slot.Position,
                    GetExplosionDropVelocity(rng),
                    slot
                )
            end
        end
    end

    -- false 只阻止游戏再生成一遍原版掉落，不阻止机器被炸坏
    return false
end

-- 使用动画播完以后，让机器回到待机动画
local function OnSoulMachineUpdate(_, slot)
    if slot.Variant ~= SOUL_MACHINE_VARIANT then
        return
    end

    local sprite = slot:GetSprite()

    if sprite:IsFinished(SOUL_MACHINE_USE_ANIMATION) then
        sprite:Play(SOUL_MACHINE_IDLE_ANIMATION, true)
    end
end

-- 玩家接触魂心机器时执行
local function OnSoulMachineCollision(_, slot, collider)
    -- 只处理我们的独立 Variant，其他机器不受影响
    if slot.Variant ~= SOUL_MACHINE_VARIANT then
        return
    end

    -- 只有玩家碰到机器时才处理
    local player = collider:ToPlayer()

    if player == nil then
        return
    end

    -- 没有红心时不能使用，魂心不会被当作支付资源
    if player:GetHearts() < 1 then
        return false
    end

    local data = slot:GetData()
    local currentFrame = Game():GetFrameCount()

    -- 玩家持续贴着机器时，等冷却结束后才能再次使用
    if data.GRENextUseFrame ~= nil
        and currentFrame < data.GRENextUseFrame then
        return false
    end

    data.GRENextUseFrame = currentFrame + SOUL_MACHINE_USE_COOLDOWN

    -- 发起一次基础伤害；实际扣血量交给游戏和当前楼层、道具决定
    local damageWasTaken = player:TakeDamage(
        1,
        SOUL_MACHINE_DAMAGE_FLAGS,
        EntityRef(slot),
        SOUL_MACHINE_USE_COOLDOWN
    )

    if damageWasTaken then
        PlaySoulMachineUseEffect(slot)

        -- 爆炸属于最终奖励；爆炸时不再进行普通的 10% 魂心判定
        if not TryBreakSoulMachine(slot) then
            TrySpawnSoulHeart(slot)
        end
    else
        -- 没有真正支付时立即解除机器冷却
        data.GRENextUseFrame = nil
    end

    -- 保留物理碰撞，但不执行任何原版机器逻辑
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
    ModCallbacks.MC_POST_SLOT_UPDATE,
    OnSoulMachineUpdate,
    SOUL_MACHINE_VARIANT
)

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_PRE_SLOT_CREATE_EXPLOSION_DROPS,
    OnSoulMachineExplosionDrops,
    SOUL_MACHINE_VARIANT
)

GamblingRoomExpansion:AddCallback(
    ModCallbacks.MC_IS_PERSISTENT_ROOM_ENTITY,
    OnIsPersistentRoomEntity
)
