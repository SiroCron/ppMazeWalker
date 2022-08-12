-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      Prowlers
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local m = {
    event_table = {},
    list = {},

    _Create = import("Lib/Prowler.lua"),
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      公開関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ==================================================================
-- 更新 ( RoundSetup時にでも行うこと )
--
m.Update = function(self)
    local map = cs.maze:GetMazemap()

    -- 足跡を消す
    map:Replace("E", ".")

    self.list = {}

    for xi = 0, map.width do
        for yi = 0, map.height do
            if map:IsProwler(xi, yi) then
                table.insert(self.list, self._Create(self.event_table, xi, yi, "."))
            end
        end
    end

    return true
end

-- ==================================================================
-- 移動
--
m.MoveAll = function(self)
    for _, v in ipairs(self.list) do
        v:RandomMove("E")
    end
end

-- ==================================================================
-- 破壊
--
m.Destroy = function(self, _x, _y)
    local idx = self:_GetIdxFromCoord(_x, _y)
    if idx == nil then
        return log:Error("Prowlers.Destroy", "not exist. (" .. _x .. ", " .. _y .. ")")
    end

    -- 削除 _____________________________________

    self.list[idx]:Destroy()
    table.remove(self.list, idx)

    return true
end

-- ==================================================================
-- 削除
--
m.Remove = function(self, _x, _y)
    local idx = self:_GetIdxFromCoord(_x, _y)
    if idx == nil then
        return log:Error("Prowlers.Remove", "not exist. (" .. _x .. ", " .. _y .. ")")
    end

    -- 削除 _____________________________________

    self.list[idx]:Remove()
    table.remove(self.list, idx)

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

-- ==============================================
-- マップ座標からProwlerのインデックスを得る
-- 無い場合は nil を返す
m._GetIdxFromCoord = function(self, _x, _y)
    for i, v in ipairs(self.list) do
        if v.x == _x and v.y == _y then return i end
    end

    return nil
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
