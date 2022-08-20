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

    ret.b = theme._InitCamera()
    ret.b = theme._InitSprite()
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
--      ルールからCallされるイベント(任意)
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
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.QuestStart = function(_si, _st, _rp)
    -- 解放 -------------------------------------

    cs.se:StopAll()
    cs.sprite:DestroyObjectGroup()

    -- 生成 -------------------------------------

    local map = cs.maze:GetMazemap()

    -- camera -----------------------------------

    -- size
    local size = (map.width < map.height) and map.height or map.width
    size = (7 < size) and 7 or size
    cs.camera:SetOrthographic()
    cs.camera:SetOrthoSize(size * C_MapchipSize)

    -- position
    cs.camera:SetPosition(cs.walker.x * C_MapchipSize, cs.walker.y * C_MapchipSize * (-1), C_CameraZ)

    -- maze -------------------------------------

    theme._Maze_BuildMap(map)

    -- walker -----------------------------------

    theme._Maze_GenWalker(cs.walker)

    return true
end

-- ============================================================================
-- Walker行動直前の処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.RoundSetup = function(_si, _st, _rp)
    return true
end

-- ============================================================================
-- Walker前進
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionMoveForward = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        local dx_list = { 0, C_MapchipSize * 2, 0, C_MapchipSize * -2 }
        local dy_list = { C_MapchipSize * 2, 0, C_MapchipSize * -2, 0 }
        local dx = dx_list[cs.walker.d + 1]
        local dy = dy_list[cs.walker.d + 1]

        SimpleAnim.MoveSpriteStart("WalkerAction", sprite_obj, true, dx, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    end

    return true
end

-- ============================================================================
-- Walker後退
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionMoveBackward = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        local dx_list = { 0, C_MapchipSize * -2, 0, C_MapchipSize * 2 }
        local dy_list = { C_MapchipSize * -2, 0, C_MapchipSize * 2, 0 }
        local dx = dx_list[cs.walker.d + 1]
        local dy = dy_list[cs.walker.d + 1]

        SimpleAnim.MoveSpriteStart("WalkerAction", sprite_obj, true, dx, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    end

    return true
end

-- ============================================================================
-- Walker左移動
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionMoveLeft = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        local dx_list = { C_MapchipSize * -2, 0, C_MapchipSize * 2, 0 }
        local dy_list = { 0, C_MapchipSize * 2, 0, C_MapchipSize * -2 }
        local dx = dx_list[cs.walker.d + 1]
        local dy = dy_list[cs.walker.d + 1]

        SimpleAnim.MoveSpriteStart("WalkerAction", sprite_obj, true, dx, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    end

    return true
end

-- ============================================================================
-- Walker右移動
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionMoveRight = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        local dx_list = { C_MapchipSize * 2, 0, C_MapchipSize * -2, 0 }
        local dy_list = { 0, C_MapchipSize * -2, 0, C_MapchipSize * 2 }
        local dx = dx_list[cs.walker.d + 1]
        local dy = dy_list[cs.walker.d + 1]

        SimpleAnim.MoveSpriteStart("WalkerAction", sprite_obj, true, dx, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    end

    return true
end

-- ============================================================================
-- Walker回転
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionTurnLeft = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        SimpleAnim.RotateSpriteStart("WalkerAction", sprite_obj, false, 0.0, 0.0, 90.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    else
        local wobj = cs.sprite:GetObject("Walker")
        wobj:SetState(cs.walker.d)
        wobj:ResetRotation()
    end

    return true
end

theme.ActionTurnRight = function(_si, _st, _rp)
    if event.is_first_call then
        local sprite_obj = cs.sprite:GetObject("Walker")
        SimpleAnim.RotateSpriteStart("WalkerAction", sprite_obj, false, 0.0, 0.0, -90.0, 0.5)
    end

    if SimpleAnim.Exec("WalkerAction", _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    else
        local wobj = cs.sprite:GetObject("Walker")
        wobj:SetState(cs.walker.d)
        wobj:ResetRotation()
    end

    return true
end

-- ============================================================================
-- 待機
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionWait = function(_si, _st, _rp)
    return true
end

-- ============================================================================
-- アイテム取得
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionPickup = function(_si, _st, _rp)
    local obj_name = theme._GenerateObjectName("Item", cs.walker.x, cs.walker.y)
    local obj = cs.sprite:GetObject(obj_name)
    if obj == nil then return false end

    obj:Hide()

    -- SE
    cs.se:Get(LTC.SE_Pickup):Play()

    return true
end

-- ============================================================================
-- アイテム使用 - 鍵
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionUseItem_Key = function(_si, _st, _rp)
    local obj = cs.sprite:GetObject(theme._GenerateObjectName("Goal", cs.walker.x, cs.walker.y))
    if obj == nil then return false end

    obj:SetState(0)

    return true
end

-- ============================================================================
-- アイテム使用 - 宝玉
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionUseItem_Orb = function(_si, _st, _rp)
    -- SE
    cs.se:Get(LTC.SE_UseItem):Play()

    local obj = cs.sprite:GetObject(theme._GenerateObjectName("Pedestal", cs.walker.x, cs.walker.y))
    if obj == nil then return false end

    obj:SetState(1)

    return true
end

-- ============================================================================
-- アイテム使用 - 銃
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.ActionUseItem_Gun = function(_si, _st, _rp)
    -- SE
    cs.se:Get(LTC.SE_UseItem_Gun):Play()

    return true
end

-- ============================================================================
-- ラウンド移行
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.RoundNext = function(_si, _st, _rp)
    return true
end

-- ============================================================================
-- クエストの中断/成功/失敗
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
theme.QuestStop = function(_si, _st, _rp)
    cs.se:StopAll()
    return true
end

theme.QuestClear = function(_si, _st, _rp)
    cs.se:StopAll()
    cs.se:Get(LTC.SE_QuestClear):Play()
    return true
end

theme.QuestFailure = function(_si, _st, _rp)
    cs.se:StopAll()
    cs.se:Get(LTC.SE_QuestFailure):Play()
    return true
end

-- ============================================================================
-- Prowler
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
-- _st : 開始パラメータテーブル
-- _rp : リピートパラメータテーブル(初回はnil)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
-- theme.ProwlerBorn = function(_si, _st, _rp)
-- end

theme.ProwlerMove = function(_si, _st, _rp)
    local sprite_name = theme._GenerateObjectName("Prowler", _st.x, _st.y)

    if event.is_first_call then
        local dx_list = { 0, C_MapchipSize * 2, 0, C_MapchipSize * -2 }
        local dy_list = { C_MapchipSize * 2, 0, C_MapchipSize * -2, 0 }
        local dx = dx_list[_st.d + 1]
        local dy = dy_list[_st.d + 1]

        -- アニメーション
        SimpleAnim.MoveSpriteStart(event.section_name, cs.sprite:GetObject(sprite_name), false, dx, dy, 0.0, 0.5)
    end

    if SimpleAnim.Exec(event.section_name, _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    else -- 移動終了したらリネーム
        local mapdx_list = { 0, 2, 0, -2 }
        local mapdy_list = { -2, 0, 2, 0 }
        local mapdx = mapdx_list[_st.d + 1]
        local mapdy = mapdy_list[_st.d + 1]
        local new_sprite_name = theme._GenerateObjectName("Prowler", _st.x + mapdx, _st.y + mapdy)
        cs.sprite:Rename(sprite_name, new_sprite_name)
    end

    return true
end

theme.ProwlerDestroy = function(_si, _st, _rp)
    local sprite_name = theme._GenerateObjectName("Prowler", _st.x, _st.y)

    if event.is_first_call then
        -- アニメーション
        SimpleAnim.RotateSpriteStart(event.section_name, cs.sprite:GetObject(sprite_name), false, 90.0, 0.0, 0.0, 0.5)
    end

    if SimpleAnim.Exec(event.section_name, _si) then -- 終わってないなら繰り返す
        event:SetRepeat(nil)
    else
        cs.sprite:DestroyObject(sprite_name)
    end

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
    cs.camera:SetShaderParam(true, 1.0, 2)
    cs.camera:SetBackgroundColor(0.1, 0.1, 0.2, 1.0)
    cs.camera:SetOrthographic()
    cs.camera:SetPosition(0, 0, C_CameraZ)
    cs.camera:ResetRotation()

    return true
end

theme._InitSprite = function()
    local ret = cs.assist:CreateIsSuccess()

    local mapchip_sprites = {
        "Floor", "FloorC", "FloorH", "FloorV",
        "Goal",
        "Item_Key", "Item_Orb", "Item_Gun",
        "Pedestal",
        "Prowler_Enemy",
        "Walker",
        "WallC", "WallH", "WallV"
    }

    for i, name in ipairs(mapchip_sprites) do
        ret.b = cs.sprite:LoadModel(name)
    end

    return ret.is_success
end

-- maze -------------------------------------------------------------

theme._Maze_BuildMap = function(_map)
    for yi = 0, _map.height - 1 do
        for xi = 0, _map.width - 1 do
            local objs = theme._Maze_CreateMapchip(xi, yi, _map:Get(xi, yi))
            if objs == nil then
                return false
            else
                for i, v in ipairs(objs) do
                    v:SetPosition(xi * C_MapchipSize, -yi * C_MapchipSize, C_MapchipStartZ + (i * C_MapchipOffsetZ))
                    v:Show()
                end
            end
        end
    end

    return true
end

theme._Maze_CreateMapchip = function(_xi, _yi, _char)
    local objs = theme._Maze_CreateMapchip_Floor(_xi, _yi)
    if objs == nil then return nil end

    local obj = nil

    if _char == "#" then
        obj = theme._Maze_CreateMapchip_Wall(_xi, _yi)
    elseif _char == "D" or _char == "$" then
        obj = theme._Maze_CreateMapchip_Goal(_xi, _yi, _char)
    elseif _char == "l" or _char == "i" then
        obj = theme._Maze_CreateMapchip_Pedestal(_xi, _yi, _char)
    elseif _char == "k" or _char == "o" or _char == "g" then
        obj = theme._Maze_CreateMapchip_Item(_xi, _yi, _char)
    else -- 最後
        obj = theme._Maze_CreateMapchip_Prowler(_xi, _yi, _char)
    end

    if obj ~= nil then table.insert(objs, obj) end

    return objs
end

theme._Maze_CreateMapchip_Floor = function(_xi, _yi)
    local key = ((_xi % 2) == 0 and "I" or "O") .. ((_yi % 2) == 0 and "I" or "O")
    local floors = {
        II = "FloorC",
        IO = "FloorV",
        OI = "FloorH",
        OO = "Floor"
    }

    -- Floor
    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Floor", _xi, _yi), floors[key])
    if obj == nil then return nil end

    return { obj }
end

theme._Maze_CreateMapchip_Wall = function(_xi, _yi)
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
    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Wall", _xi, _yi), wall_name)
    if obj == nil then return nil end

    if wall_name ~= "WallC" then
        obj:SetState(1)
    end

    return obj
end

theme._Maze_CreateMapchip_Goal = function(_xi, _yi, _char)
    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Goal", _xi, _yi), "Goal")
    if obj == nil then return nil end

    if _char == "D" then obj:SetState(0)
    elseif _char == "$" then obj:SetState(1) end

    return obj
end

theme._Maze_CreateMapchip_Pedestal = function(_xi, _yi, _char)
    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Pedestal", _xi, _yi), "Pedestal")
    if obj == nil then return nil end

    if _char == "l" then obj:SetState(0)
    elseif _char == "i" then obj:SetState(1) end

    return obj
end

theme._Maze_CreateMapchip_Item = function(_xi, _yi, _char)
    local items = {
        k = "Item_Key",
        o = "Item_Orb",
        g = "Item_Gun",
    }

    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Item", _xi, _yi), items[_char])
    if obj == nil then return nil end

    return obj
end

theme._Maze_CreateMapchip_Prowler = function(_xi, _yi, _char)
    if cs.maze:IsProwler(_char) == false then return nil end

    local obj = cs.sprite:CreateObject(theme._GenerateObjectName("Prowler", _xi, _yi), "Prowler_Enemy")
    if obj == nil then return nil end

    return obj
end

-- Walker -----------------------------------------------------------

theme._Maze_GenWalker = function(_walker)
    local obj = cs.sprite:CreateObject("Walker", "Walker")
    if obj == nil then return false end

    obj:SetPosition(_walker.x * C_MapchipSize, _walker.y * C_MapchipSize * (-1), C_WalkerZ)
    obj:SetState(_walker.d)
    obj:Show()

    return true
end

-- etc --------------------------------------------------------------

theme._GenerateObjectName = function(_name, _xi, _yi)
    return _name .. string.format("_%03d%03d", _xi, _yi)
end
