-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      初期化
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

SimpleAnim = import("Lib/SimpleAnimation.lua")

_G.theme = {}

local C_AnimSec = 0.20
local C_MapchipSize = 16

local C_CameraX = 1 * C_MapchipSize
local C_CameraZ = -10
local C_FieldZ = 10
local C_ObjectZ = 8
local C_ObjectEffectZ = 6
local C_KnightZ = 4
local C_KnightEffectZ = 2

local C_GrpField = "Field"
local C_GrpObject = "Object"

local C_SeBgm = "BGM"
local C_SeEnding = "Ending"
local C_SeDead = "Dead"
local C_SeHeatBody = "HeatBody"
local C_SeDestroy = "Destroy"
local C_SePickupFood = "PickupFood"
local C_SePickupGem = "PickupGem"
local C_SeEat = "Eat"
local C_SeDispell = "Dispell"

local SpriteID = 0

local m = {
    obj = {
        knight = nil,
        heatbody = nil,
    },
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストからCallされる関数(必須)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

theme.Init = function()
    local ret = cs.assist:CreateIsSuccess()

    ret.b = theme._InitCamera()
    ret.b = theme._InitSprite()
    ret.b = theme._InitSE()

    return ret.is_success
end

theme.Term = function()
    theme._DestroySpriteObject()
    cs.sprite:FreeModelGroup()

    cs.se:Get(C_SeBgm):Stop()
    cs.se:FreeGroup()

    return true
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ルールからCallされるイベント(任意)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

theme.QuestStart = function(_si, _st, _rp)
    theme._ResetCamera()
    theme._DestroySpriteObject()
    cs.se:Get(C_SeBgm):Stop()

    cs.se:Play(C_SeBgm, true)

    return true
end

theme.RoundSetup = function(_si, _st, _rp)
    if walker.state.turn == 1 then
        theme._BuildField(cs.maze:GetMazemap())

        m.obj.knight = cs.sprite:CreateObject("Knight", "Knight")
        theme._SetSpritePos(m.obj.knight, cs.walker.x, cs.walker.y, C_KnightZ)

        m.obj.heatbody = cs.sprite:CreateObject("HeatBody", "HeatBody")
        theme._SetSpritePos(m.obj.heatbody, cs.walker.x, cs.walker.y, C_KnightEffectZ)
        m.obj.heatbody:Hide()
    else
        if event.is_first_call then
            theme._AddFieldLine(cs.maze:GetMazemap(), 0, -1)

            -- 解放
            theme._DestroyOutsideSpriteObjects()

            -- スクロール
            local dx = 0
            local dy = C_MapchipSize
            SimpleAnim.MoveCameraStart("CameraMove", dx, dy, 0.0, C_AnimSec)

            -- HeatBody
            if walker.state.charge < 1 then
                m.obj.heatbody:Hide()
            end
        end
        if SimpleAnim.Exec("CameraMove", _si) then
            event:SetRepeat(nil)
        end
    end

    return true
end

theme.ActionMove = function(_si, _st, _rp)
    if event.is_first_call then
        local dx = _st.x * C_MapchipSize
        local dy = _st.y * C_MapchipSize

        SimpleAnim.MoveSpriteStart("WalkerMove", m.obj.knight, false, dx, dy, 0.0, C_AnimSec)
        SimpleAnim.MoveSpriteStart("EffectMove", m.obj.heatbody, false, dx, dy, 0.0, C_AnimSec)
    end

    SimpleAnim.Exec("EffectMove", _si)
    if SimpleAnim.Exec("WalkerMove", _si) then
        event:SetRepeat(nil)
    end

    return true
end

theme.ActionPickup = function(_si, _st, _rp)
    if _st.name == "Food" then cs.se:Get(C_SePickupFood):Play() end
    if _st.name == "Gem" then cs.se:Get(C_SePickupGem):Play() end

    local p = theme._GetWorldPos(cs.walker.x, cs.walker.y, C_ObjectZ)
    local obj = cs.sprite:FindByPos(C_GrpObject, p.x, p.y, p.z, 1.0)
    obj:Hide()

    return true
end

theme.ActionEat = function(_si, _st, _rp)
    cs.se:Get(C_SeEat):Play()

    return true
end

theme.ActionHeatBody = function(_si, _st, _rp)
    cs.se:Get(C_SeHeatBody):Play()
    m.obj.heatbody:Show()

    return true
end

theme.RoundNext = function(_si, _st, _rp)
    return true
end

theme.QuestStop = function(_si, _st, _rp)
    cs.se:Get(C_SeBgm):Stop()

    return true
end

theme.QuestFailure = function(_si, _st, _rp)
    cs.se:Get(C_SeDead):Play()
    cs.se:Get(C_SeBgm):Stop()
    cs.se:Get(C_SeEnding):Play()

    return true
end

theme.Dispell = function(_si, _st, _rp)
    cs.se:Get(C_SeDispell):Play()
    return true
end

theme.Destroy = function(_si, _st, _rp)
    cs.se:Get(C_SeDestroy):Play()

    local p = theme._GetWorldPos(_st.x, _st.y, C_ObjectZ)
    local obj = cs.sprite:FindByPos(C_GrpObject, p.x, p.y, p.z, 1.0)
    obj:Hide()

    obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Burn")
    theme._SetSpritePos(obj, cs.walker.x, cs.walker.y, C_ObjectEffectZ)

    return true
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      内部関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

theme._InitCamera = function()
    cs.camera:SetShaderParam(true, 0.2, 3)
    cs.camera:SetBackgroundColor(0.1, 0.1, 0.2, 1.0)
    cs.camera:SetOrthographic()
    cs.camera:SetPosition(C_CameraX, 0, C_CameraZ)
    cs.camera:ResetRotation()

    cs.camera:SetOrthoSize(C_MapchipSize * 7)

    return true
end

theme._ResetCamera = function()
    cs.camera:SetPosition(C_CameraX, 0, C_CameraZ)
end

theme._InitSprite = function()
    local ret = cs.assist:CreateIsSuccess()

    local sprite_models = {
        "Boundary", "Burn", "Circle", "Food",
        "Gem", "Ground", "HeatBody", "Knight",
        "Obstacle", "Outside", "Prowler"
    }

    for i, name in ipairs(sprite_models) do
        ret.b = cs.sprite:LoadModel(name)
    end

    return ret.is_success
end

theme._InitSE = function()
    local ret = cs.assist:CreateIsSuccess()

    ret.b = cs.se:LoadAsBGM(C_SeBgm, "se/魔王魂 旧ゲーム音楽 ダンジョン03.ogg", 1.0)
    ret.b = cs.se:LoadAsBGM(C_SeEnding, "se/魔王魂  ジングル07.ogg", 1.0)

    local files = {
        { key = C_SeDead, file = "魔王魂  戦闘12.ogg", volume = 1.0 },
        { key = C_SeHeatBody, file = "魔王魂  炎08.ogg", volume = 1.0 },
        { key = C_SeDestroy, file = "魔王魂  爆発03.ogg", volume = 1.0 },
        { key = C_SePickupFood, file = "魔王魂 効果音 システム48.ogg", volume = 1.0 },
        { key = C_SePickupGem, file = "魔王魂 効果音 システム23.ogg", volume = 0.2 },
        { key = C_SeEat, file = "魔王魂 効果音 飲む01.ogg", volume = 1.0 },
        { key = C_SeDispell, file = "魔王魂 効果音 物音03.ogg", volume = 1.0 },
    }

    for _, v in ipairs(files) do
        ret.b = cs.se:Load(v.key, "se/" .. v.file, v.volume)
    end

    return ret.is_success
end

theme._DestroySpriteObject = function()
    cs.sprite:DestroyObjectGroup()
    cs.sprite:DestroyObjectGroup(C_GrpField)
    cs.sprite:DestroyObjectGroup(C_GrpObject)
end

theme._AddFieldLine = function(_map, _yi, _offset)
    local oyi = _yi + _offset

    for xi = 0, _map.width - 1 do
        local obj = cs.sprite:CreateObjectAt(C_GrpField, theme._SpriteID(), "Ground")
        theme._SetSpritePos(obj, xi, oyi, C_FieldZ)

        local c = _map:Get(xi, _yi)
        if c == " " then theme._GenOutside(xi, oyi)
        elseif c == "#" then theme._GenBoundary(xi, oyi)
        elseif c == "X" then theme._GenObstacle(xi, oyi)
        elseif c == "C" then theme._GenCircle(xi, oyi)
        elseif c == "G" then theme._GenGem(xi, oyi)
        elseif c == "f" then theme._GenFood(xi, oyi)
        elseif c == "E" then theme._GenProwler(xi, oyi)
        end
    end
end

theme._BuildField = function(_map)
    for yi = 0, _map.height - 1 do
        theme._AddFieldLine(_map, yi, 0)
    end
end

theme._GenOutside = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Outside")
    obj:SetState(_G.rand:Next(obj.state_count))

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenBoundary = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Boundary")

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenCircle = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Circle")
    obj:SetTransparency(0.5)

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenObstacle = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Obstacle")
    obj:SetState(_G.rand:Next(obj.state_count))

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenGem = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Gem")
    obj:SetState(_G.rand:Next(obj.state_count))

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenFood = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Food")
    obj:SetState(_G.rand:Next(obj.state_count))

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._GenProwler = function(_xi, _yi)
    local obj = cs.sprite:CreateObjectAt(C_GrpObject, theme._SpriteID(), "Prowler")
    obj:SetState(_G.rand:Next(obj.state_count))

    theme._SetSpritePos(obj, _xi, _yi, C_ObjectZ)
end

theme._DestroyOutsideSpriteObjects = function()
    local cpos = cs.camera:GetPosition()
    local y = cpos.y - 7 * C_MapchipSize

    cs.sprite:DestroyUnderY(C_GrpField, y)
    cs.sprite:DestroyUnderY(C_GrpObject, y)
end

theme._GetWorldPos = function(_xi, _yi, _z)
    local cpos = cs.camera:GetPosition()

    local x = (_xi - 6) * C_MapchipSize
    local y = (_yi - 6) * C_MapchipSize - cpos.y

    return { x = x, y = -y, z = _z }
end

theme._SetSpritePos = function(_obj, _mx, _my, _z)
    local p = theme._GetWorldPos(_mx, _my, _z)

    _obj:SetPosition(p.x, p.y, p.z)
    _obj:Show()
end

theme._SpriteID = function()
    SpriteID = SpriteID + 1
    if 10000 < SpriteID then SpriteID = 0 end

    return "ID" .. SpriteID
end
