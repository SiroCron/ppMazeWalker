-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      Prowler
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local f = function(_event_table, _x, _y, _passage)
    local obj = {}

    obj._event_table = _event_table
    obj.x = _x
    obj.y = _y
    obj.mark = cs.maze:GetMazemap():Get(_x, _y) -- 現座標の文字が自分
    obj.passage = _passage

    -- ////////////////////////////////////////////////////////////////////////
    -- ///
    -- //
    -- /
    --      公開関数
    --                                                                        /
    --                                                                       //
    --                                                                      ///
    -- ////////////////////////////////////////////////////////////////////////

    -- ==============================================================
    -- 移動
    --
    -- 方向を指定した移動,移動しないときもある
    -- true:移動した, false:移動しなかった
    obj.Move = function(self, _d, _footprint)
        -- Walkerと同じ座標なら移動しない
        if self.x == cs.walker.x and self.y == cs.walkery then return false end

        -- その方向に移動できないならそのまま
        if self:_CanMove(_d) == false then return false end

        local map = cs.maze:GetMazemap()

        -- 現在地を通路に変更 ___________________

        map:Set(self.x, self.y, _footprint)

        -- 移動イベント発行 _____________________

        event:Enqueue(self:_UniqueName(),
            self._event_table.move,
            {
                x = self.x,
                y = self.y,
                d = _d,
            }
        )

        -- 移動、移動先にマークをセット _________

        local dst = self:_GetMoveDestCoord(_d, 2)
        self.x, self.y = dst.x, dst.y
        map:Set(self.x, self.y, self.mark)

        return true
    end

    -- ランダム移動
    obj.RandomMove = function(self, _footprint)
        local d = self:_GetRand():Next(4)

        return self:Move(d, _footprint)
    end

    -- ==============================================================
    -- 破壊(Walkerや何かによって)
    obj.Destroy = function(self)
        -- 破壊イベント発行 _____________________

        event:Enqueue(self:_UniqueName(),
            self._event_table.destroy,
            {
                x = self.x,
                y = self.y,
            }
        )

        self:Remove()
    end

    -- ==============================================================
    -- 削除(mazemapから消すだけ,イベント発行なし)
    obj.Remove = function(self)
        cs.maze:GetMazemap():Set(self.x, self.y, self.passage)
    end

    -- ////////////////////////////////////////////////////////////////////////
    -- ///
    -- //
    -- /
    --      内部関数
    --                                                                        /
    --                                                                       //
    --                                                                      ///
    -- ////////////////////////////////////////////////////////////////////////

    -- その方向に移動できるなら true を返す
    -- _d : 0~3
    obj._CanMove = function(self, _d)
        local map = cs.maze:GetMazemap()

        for i = 1, 2 do
            local dst = self:_GetMoveDestCoord(_d, i)
            if map:Get(dst.x, dst.y) ~= self.passage then return false end
        end

        return true
    end

    obj._GetMoveDestCoord = function(self, _d, _dist)
        local dir = {
            { x = self.x, y = self.y - _dist },
            { x = self.x + _dist, y = self.y },
            { x = self.x, y = self.y + _dist },
            { x = self.x - _dist, y = self.y }
        }

        return dir[_d + 1]
    end

    obj._GetRand = function()
        if _G.rand == nil then
            _G.rand = cs.assist:CreateRandom(config.stage_seed)
        end

        return _G.rand
    end

    obj._UniqueName = function(self)
        return self._event_table.sec_header .. "(" .. self.x .. "," .. self.y .. ")"
    end

    -- ========================================================================

    return obj
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

return f
