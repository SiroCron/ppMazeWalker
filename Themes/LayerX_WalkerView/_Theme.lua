-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      初期化
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

LTC = import("Lib/LayerX_ThemeCommon.lua")
SimpleAnim = import("Lib/SimpleAnimation.lua")

_G.theme = {}

local C_CameraZ = -10
local C_MapchipSize = 12
local C_MapchipStartZ = 10
local C_MapchipOffsetZ = -0.1
local C_WalkerZ = 0

local C_TransparencyValue = 0.3

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストからCallされる関数(必須)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ============================================================================
-- 初期化,データの準備(読込)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Init = function()
    local ret = cs.assist:CreateIsSuccess()

    ret.b = theme.InitCamera()
    ret.b = theme.InitSprite()
    ret.b = LTC.InitSE()
    ret.b = LTC.InitBGM()

    if ret.is_success then
        cs.bgm:Play(true)
    end

    return ret.is_success
end


-- ============================================================================
-- 読み込んだデータの解放
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Term = function()
    -- Objectを先に解放する
    cs.sprite:DestroyObjectGroup()
    cs.sprite:FreeModelGroup()

    cs.se:StopAll()
    cs.se:FreeGroup()

    cs.bgm:FreeAll()

    return true
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ルールからCallされる関数(必須)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ============================================================================
-- (クエスト開始)迷路とウォーカーの表示オブジェクト生成
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.QuestStart = function(_si)
    local f = {
        function()
            cs.se:StopAll()

            return true
        end,
    }

    return f[_si.count + 1]()
end

-- ============================================================================
-- Walker行動直前の処理
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.RoundSetup = function(_si)
    -- 前回のビューオブジェクト解放 -----------------------

    cs.sprite:DestroyObjectGroup()

    -- 今回のビューオブジェクト生成 -----------------------

    local map = cs.walker:GetWalkermap()

    -- camera -----------------------------------

    local size = (map.width < map.height) and map.height or map.width
    size = (size < 7) and 7 or size

    cs.camera:SetOrthographic()
    cs.camera:SetOrthoSize(size * C_MapchipSize)
    cs.camera:SetPosition(0.0, 0.0, C_CameraZ)
    cs.camera:ResetRotation()

    -- maze -------------------------------------
    theme.Maze_BuildMap(map)

    -- walker -----------------------------------
    theme.Maze_GenWalker()

    return true
end

-- ============================================================================
-- Walker前進
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_MoveForward = function(_si)
    if _si.count == 0 then
        local sprite_obj = cs.sprite:GetObject("Walker")
        local dy = C_MapchipSize * 2
        SimpleAnim.MoveSpriteStart("MoveWalker", sprite_obj, true, 0.0, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec("MoveWalker", _si) then
        return true, "continue"
    else
        return true, nil
    end
end

-- ============================================================================
-- Walker回転
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_TurnLeft = function(_si)
    if _si.count == 0 then
        local sprite_obj = cs.sprite:GetObject("Walker")
        SimpleAnim.RotateSpriteStart("RotateWalker", sprite_obj, true, 0.0, 0.0, 90.0, 0.5)
    end

    if SimpleAnim.Exec("RotateWalker", _si) then
        return true, "continue"
    else
        return true, nil
    end
end

theme.Walker_TurnRight = function(_si)
    if _si.count == 0 then
        local sprite_obj = cs.sprite:GetObject("Walker")
        SimpleAnim.RotateSpriteStart("RotateWalker", sprite_obj, true, 0.0, 0.0, -90.0, 0.5)
    end

    if SimpleAnim.Exec("RotateWalker", _si) then
        return true, "continue"
    else
        return true, nil
    end
end

-- ============================================================================
-- アイテム取得
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_Pickup = function(_si)
    -- SE
    if _si.count == 0 then cs.se:Get(LTC.SE_Pickup):Play() end

    return true
end

-- ============================================================================
-- アイテム使用 - 鍵
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_UseItem_Key = function(_si)
    return true
end

-- ============================================================================
-- アイテム使用 - 宝玉
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_UseItem_Orb = function(_si)
    -- SE
    if _si.count == 0 then cs.se:Get(LTC.SE_UseItem):Play() end

    return true
end

-- ============================================================================
-- アイテム使用 - 銃
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.Walker_UseItem_Gun = function(_si, _r)
    -- SE
    if _si.count == 0 then cs.se:Get(LTC.SE_UseItem_Gun):Play() end

    -- 敵に当たってない？
    if tonumber(_r.mapchar) == nil then return true end

    -- アニメーション ---------------------------

    local lloc = theme.ConvertToLocalLoc(_r)
    local sprite_name = theme.GenerateObjectName("Prowler", lloc.x + 1, lloc.y + 1)

    if _si.count == 0 then
        SimpleAnim.RotateSpriteStart("Prowler", cs.sprite:GetObject(sprite_name), false, 90.0, 0.0, 0.0, 0.5)
    end

    if SimpleAnim.Exec("Prowler", _si) then
        return true, "continue"
    else
        cs.sprite:DestroyObject(sprite_name)
        return true, nil
    end
end

-- ============================================================================
-- クエストの中断/成功/失敗
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.QuestStop = function(_si)
    cs.se:StopAll()
    return true
end

theme.QuestClear = function(_si)
    cs.se:StopAll()
    cs.se:Get(LTC.SE_QuestClear):Play()
    return true
end

theme.QuestFailure = function(_si)
    cs.se:StopAll()
    cs.se:Get(LTC.SE_QuestFailure):Play()
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

theme.InitCamera = function()
    cs.camera:SetBackgroundColor(0.1, 0.1, 0.2, 1.0)
    cs.camera:SetOrthographic()
    cs.camera:SetPosition(0, 0, C_CameraZ)
    cs.camera:ResetRotation()

    return true
end

theme.InitSprite = function()
    local ret = cs.assist:CreateIsSuccess()

    local mapchip_sprites = {
        "Floor", "FloorC", "FloorH", "FloorV",
        "Goal",
        "Item_Key", "Item_Orb",
        "Pedestal",
        "Prowler_Enemy",
        "Walker",
        "WallC", "WallH", "WallV"
    }

    for i, name in ipairs(mapchip_sprites) do
        ret.b = cs.sprite:LoadModel("../LayerX_TopView/" .. name)
    end

    -- CharSprites
    local char_sprites = {
        "CharExclamation", "CharFloor", "CharGoal0", "CharGoal1",
        "CharKey", "CharOrb", "CharGun",
        "CharPedestal0", "CharPedestal1",
        "CharProwler",
        "CharQuestion", "CharWall"
    }

    for i, name in ipairs(char_sprites) do
        ret.b = cs.sprite:LoadModel(name)
    end

    return ret.is_success
end

-- maze -------------------------------------------------------------

theme.Maze_BuildMap = function(_map)
    local cx, cy = theme.Maze_GetMapCenter(_map)

    for yi = 0, _map.height - 1 do
        for xi = 0, _map.width - 1 do
            local x, y = xi - cx, yi - cy
            local char = _map:Get(xi, yi)
            if x == 0 and y == 0 then
                char = cs.walker.current_mapchip
            end

            local objs = theme.Maze_CreateMapchip(x + 1, y + 1, char)
            if objs == nil then
                return false
            else
                for i, v in ipairs(objs) do
                    v:SetPosition(x * C_MapchipSize, -y * C_MapchipSize, C_MapchipStartZ + (i * C_MapchipOffsetZ))
                    v:Show()
                end
            end
        end
    end

    return true
end

theme.Maze_GetMapCenter = function(_map)
    for yi = 0, _map.height - 1 do
        for xi = 0, _map.width - 1 do
            if _map:Get(xi, yi) == "@" then return xi, yi end
        end
    end

    return 0, 0
end

theme.Maze_CreateMapchip = function(_xi, _yi, _char)
    local objs = theme.Maze_CreateMapchip_Floor(_xi, _yi)
    if objs == nil then return nil end

    local obj = nil

    if _char == "#" then
        obj = theme.Maze_CreateMapchip_Wall(_xi, _yi)
    elseif _char == "D" or _char == "$" then
        obj = theme.Maze_CreateMapchip_Goal(_xi, _yi, _char)
    elseif _char == "l" or _char == "i" then
        obj = theme.Maze_CreateMapchip_Pedestal(_xi, _yi, _char)
    elseif _char == "k" or _char == "o" then
        obj = theme.Maze_CreateMapchip_Item(_xi, _yi, _char)
    else -- 最後
        obj = theme.Maze_CreateMapchip_Prowler(_xi, _yi, _char)
    end

    if obj ~= nil then table.insert(objs, obj) end

    -- CharSprites ------------------------------

    obj = nil
    local cname = theme.GenerateObjectName("Char", _xi, _yi)

    if _char == "!" then
        obj = cs.sprite:CreateObject(cname, "CharExclamation")
    elseif _char == "." then
        obj = cs.sprite:CreateObject(cname, "CharFloor")
    elseif _char == "D" then
        obj = cs.sprite:CreateObject(cname, "CharGoal0")
    elseif _char == "$" then
        obj = cs.sprite:CreateObject(cname, "CharGoal1")
    elseif _char == "k" then
        obj = cs.sprite:CreateObject(cname, "CharKey")
    elseif _char == "o" then
        obj = cs.sprite:CreateObject(cname, "CharOrb")
    elseif _char == "g" then
        obj = cs.sprite:CreateObject(cname, "CharGun")
    elseif _char == "l" then
        obj = cs.sprite:CreateObject(cname, "CharPedestal0")
    elseif _char == "i" then
        obj = cs.sprite:CreateObject(cname, "CharPedestal1")
    elseif _char == "?" then
        obj = cs.sprite:CreateObject(cname, "CharQuestion")
    elseif _char == "#" then
        obj = cs.sprite:CreateObject(cname, "CharWall")
    else -- 最後
        local no = tonumber(_char)
        if no ~= nil then
            obj = cs.sprite:CreateObject(cname, "CharProwler")
            if obj ~= nil then obj:SetState(no) end
        end
    end

    if obj ~= nil then table.insert(objs, obj) end

    return objs
end

theme.Maze_CreateMapchip_Floor = function(_xi, _yi)
    local key = ((_xi % 2) == 0 and "I" or "O") .. ((_yi % 2) == 0 and "I" or "O")
    local floors = {
        II = "FloorC",
        IO = "FloorV",
        OI = "FloorH",
        OO = "Floor"
    }

    -- Floor
    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Floor", _xi, _yi), floors[key])
    if obj == nil then return nil end

    obj:SetTransparency(C_TransparencyValue)

    return { obj }
end

theme.Maze_CreateMapchip_Wall = function(_xi, _yi)
    local key = ((_xi % 2) == 0 and "I" or "O") .. ((_yi % 2) == 0 and "I" or "O")
    local walls = {
        II = "WallC",
        IO = "WallV",
        OI = "WallH",
        OO = nil
    }

    local wall_name = walls[key]
    if wall_name == nil then return nil end

    -- Wall
    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Wall", _xi, _yi), wall_name)
    if obj == nil then return nil end

    if wall_name ~= "WallC" then
        obj:SetState(1)
    end

    obj:SetTransparency(C_TransparencyValue)

    return obj
end

theme.Maze_CreateMapchip_Goal = function(_xi, _yi, _char)
    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Goal", _xi, _yi), "Goal")
    if obj == nil then return nil end

    if _char == "D" then obj:SetState(0)
    elseif _char == "$" then obj:SetState(1) end

    obj:SetTransparency(C_TransparencyValue)

    return obj
end

theme.Maze_CreateMapchip_Pedestal = function(_xi, _yi, _char)
    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Pedestal", _xi, _yi), "Pedestal")
    if obj == nil then return nil end

    if _char == "l" then obj:SetState(0)
    elseif _char == "i" then obj:SetState(1) end

    obj:SetTransparency(C_TransparencyValue)

    return obj
end

theme.Maze_CreateMapchip_Item = function(_xi, _yi, _char)
    local items = {
        k = "Item_Key",
        o = "Item_Orb"
    }

    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Item", _xi, _yi), items[_char])
    if obj == nil then return nil end

    obj:SetTransparency(C_TransparencyValue)

    return obj
end

theme.Maze_CreateMapchip_Prowler = function(_xi, _yi, _char)
    local no = tonumber(_char)
    if no == nil then return nil end

    local obj = cs.sprite:CreateObject(theme.GenerateObjectName("Prowler", _xi, _yi), "Prowler_Enemy")
    if obj == nil then return nil end

    obj:SetTransparency(C_TransparencyValue)

    return obj
end

-- Walker -----------------------------------------------------------

theme.Maze_GenWalker = function()
    local obj = cs.sprite:CreateObject("Walker", "Walker")
    if obj == nil then return false end

    obj:SetTransparency(C_TransparencyValue)
    obj:SetPosition(0.0, 0.0, C_WalkerZ)
    obj:SetState(0)
    obj:Show()

    return true
end

-- etc --------------------------------------------------------------

theme.GenerateObjectName = function(_name, _xi, _yi)
    return _name .. string.format("_%03d%03d", _xi, _yi)
end

theme.ConvertToLocalLoc = function(_wloc)
    local x, y = _wloc.x - cs.walker.x, _wloc.y - cs.walker.y

    local d = {
        { x = x, y = y },
        { x = y, y = -x },
        { x = -x, y = -y },
        { x = -y, y = x }
    }

    return d[cs.walker.d + 1]
end
