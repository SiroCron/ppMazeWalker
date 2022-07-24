-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      行動処理関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local m = {}

-- ============================================================================
-- 行動処理
--

m.MoveForward = function(_si, _obj)
    if _si.count == 0 then
        if cs.walker:MoveForward(2) == false then
            log:Message("進めない！")
            return true
        end
    end

    return theme.Walker_MoveForward(_si)
end

m.TurnLeft = function(_si, _obj)
    if _si.count == 0 then
        cs.walker:TurnLeft()
    end

    return theme.Walker_TurnLeft(_si)
end

m.TurnRight = function(_si, _obj)
    if _si.count == 0 then
        cs.walker:TurnRight()
    end

    return theme.Walker_TurnRight(_si)
end

m.Pickup = function(_si, _obj)
    local walker = cs.walker

    if _si.count == 0 then
        local item = cs.items:GetItemByMapchip(walker.current_mapchip)

        -- アイテム落ちてる？
        if item == nil then
            log:Message("取れそうなアイテムは無いぞ.")
            return true
        end

        -- Mazemapの書換(アイテム消去)
        walker:SetMapchip(item.pickuped_mapchip)

        -- Inventoryに追加
        walker.inventory:Add(item.name, 1)
    end

    return theme.Walker_Pickup(_si)
end

m.UseItem = function(_si, _obj)
    -- アイテム使用可能チェック
    if _si.count == 0 and m.UseItem_Firstcheck(_obj) == false then return true end

    local result = m.use_item_repeat[_obj]()
    if result == nil then return true end -- 使用失敗等はここで終了

    local theme_procs = {
        Key = theme.Walker_UseItem_Key,
        Orb = theme.Walker_UseItem_Orb,
        Gun = theme.Walker_UseItem_Gun,
    }

    local retcode, contcode = theme_procs[_obj](_si, result)

    if retcode == false or contcode ~= "continue" then -- 異常終了か継続以外なら終了処理へ
        m.use_item_last[_obj](result)
    end

    return retcode, contcode
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

-- ==============================================
-- 方向毎のx,y移動量
--
m.dir_offset = {
    { x = 0, y = -1 },
    { x = 1, y = 0 },
    { x = 0, y = 1 },
    { x = -1, y = 0 }
}

-- ==============================================
-- アイテムが使用できるか？
--
m.UseItem_Firstcheck = function(_obj)
    -- アイテムが指定されていない？
    if _obj == nil or #_obj < 1 then
        return log:Message("どのアイテムを使うって？？？", false)
    end

    -- アイテムなのか？
    local item = cs.items:GetItemByName(_obj)
    if item == nil then
        return log:Message("'" .. _obj .. "'？ それはアイテムなのか？", false)
    end

    -- そのアイテムを持ってる？
    if cs.walker.inventory:IsExist(_obj) == false then
        return log:Message("'" .. _obj .. "'？ そんなアイテムは持っていない. ", false)
    end

    --------------------------------------------- 有効なアイテムが指定されている

    -- ここで使えるか？
    if item:IsUsable(cs.walker.current_mapchip) == false then
        return log:Message("ここで使う？ '" .. _obj .. "' を？", false)
    end

    --------------------------------------------- OK

    return true;
end

-- ==============================================
-- アイテム使用(初期処理)
--
-- 戻り値 : アイテムによって異なる,themeの対応関数へ渡される
--          nilの場合,使用失敗として即フェーズ終了
--
m.use_item_repeat = {}

m.use_item_repeat.Key = function()
    -- もし台座があるなら使用できない
    local map = cs.maze:GetMazemap()
    if map:IsContain("l") then
        log:Message("あれ？開かないぞ？")
        return nil
    end

    return true -- 特に渡す情報は無い
end

m.use_item_repeat.Orb = function()
    return true -- 特に渡す情報は無い
end

m.use_item_repeat.Gun = function() -- (毎度同じ処理なので無駄だけど)
    local map = cs.maze:GetMazemap()

    local xx, yy, d = cs.walker.x, cs.walker.y, cs.walker.d
    local range = 4
    while 0 < range do
        xx, yy = xx + m.dir_offset[d + 1].x, yy + m.dir_offset[d + 1].y
        range = range - 1

        local mc = map:Get(xx, yy)

        if mc == "#" then -- 壁
            return { x = xx, y = yy, mapchar = mc }
        end

        if tonumber(mc) ~= nil then -- 敵？
            return { x = xx, y = yy, mapchar = mc }
        end
    end

    --------------------------------------------- 壁,敵に当たらず

    return { x = xx, y = yy, mapchar = "." } -- 床を撃った
end

-- ==============================================
-- アイテム使用(最終処理)
--
-- map,walker情報を更新する
--
m.use_item_last = {}

m.use_item_last.Key = function(_result)
    cs.walker:SetMapchip("D")
    cs.walker.inventory:Consume("Key", 1)

    log:Message("開いた！")
end

m.use_item_last.Orb = function(_result)
    cs.walker:SetMapchip("i")
    cs.walker.inventory:Consume("Orb", 1)

    log:Message("置いたぞ！")
end

m.use_item_last.Gun = function(_r)
    if _r.mapchar == "#" then
        log:Message("壁に命中！")
    elseif tonumber(_r.mapchar) ~= nil then
        cs.maze:GetMazemap():Set(_r.x, _r.y, ".") -- 床にする
    else
        log:Message("やったか！？")
    end
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      おわり
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

return m
