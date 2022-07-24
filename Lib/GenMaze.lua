-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      単純迷路生成
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

table = import("Lib/Table.lua")

local m = {
    C_CharWall = '#', -- 設置確定の壁
    C_CharFloor = '.', -- 通路
    C_CharTemporaryWall = '*', -- 仮設置の壁
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

-- ============================================================================
-- 迷路生成
--
-- _w, _h : Walkerが停止するマスとしての縦横サイズ
--
m.GenerateMaze = function(_w, _h, _rand)
    _w = (_w < 2) and 2 or _w
    _h = (_h < 2) and 2 or _h

    local width, height = _w * 2 + 1, _h * 2 + 1 -- 実際の迷路サイズ

    m.rand = _rand
    m.map = cs.maze:CreateBlankMazemap(width, height, m.C_CharFloor, m.C_CharWall)

    local pillar_list = m.GenPillarList(width, height)

    -- 開始点リストを使い切るループ -------------
    while true do
        local sx, sy = m.RandomPickupPillar(pillar_list)
        if sx == nil and sy == nil then break end -- 終わり？

        if m.IsFloor(sx, sy) then -- 未設？
            if m.BuildTemporaryWallSnake(m.map, sx, sy) then
                m.FixTemporaryWall() -- 仮設置を確定させる
            else
                table.insert(pillar_list, { sx, sy }) -- 開始点をリストに戻す
                m.ClearTemporaryWall() -- 仮設置を解除する
            end
        end
    end

    return m.map
end

-- ============================================================================
-- Start, Goal地点を決定する
--
m.GetStartGoal = function(_map)
    local list = m.GenStartGoalList(_map)

    local si = m.rand:Next(#list) + 1
    local sx, sy = table.unpack(list[si]) -- Start

    -- local min_spc = math.floor((_map.width + _map.height) / 2)
    local min_spc = math.floor(#list / 4)
    local spc = min_spc + m.rand:Next(#list - min_spc * 2) - 1

    local gi = (si + spc) % #list + 1
    local gx, gy = table.unpack(list[gi]) -- Goal

    return sx, sy, gx, gy
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

-- ============================================================================
-- 仮設壁を生成する
--
-- 戻り値 : 仮設置に成功したらtrue
--
m.BuildTemporaryWallSnake = function(_map, _sx, _sy)
    m.SetTemporaryWall(_sx, _sy) -- 開始点

    local px, py = _sx, _sy

    -- 外壁or確定内壁まで伸びるループ -----------
    while true do
        local jx, jy = m.GetJumpDest(_map, px, py) -- ジャンプ可能先をゲット

        -- 有効なジャンプ先が無い？
        if jx == nil and jy == nil then return false end

        m.SetTemporaryWall((px + jx) / 2, (py + jy) / 2) -- 中間地点に仮設壁を配置

        -- 外壁or確定壁に到達したので成功
        if m.IsWall(jx, jy) then return true end

        m.SetTemporaryWall(jx, jy) -- ジャンプ先に仮設壁を配置

        -- next
        px, py = jx, jy
    end
end

-- ============================================================================
-- 開始点リストの生成(偶数座標格子点)
--
m.GenPillarList = function(_width, _height)
    local list = {}

    for x = 2, _width - 3, 2 do
        for y = 2, _height - 3, 2 do
            table.insert(list, { x, y })
        end
    end

    return list
end

-- ============================================================================
-- 移動(2歩先)方向をランダムで返す
--
m.GetRandomDirection = function()
    local dat = {
        { 0, -2 }, -- 上
        { 2, 0 }, -- 右
        { 0, 2 }, -- 下
        { -2, 0 } -- 左
    }

    local d = m.rand:Next(4) + 1

    return table.unpack(dat[d])
end

-- ============================================================================
-- 移動可能な方向の中からランダムで決定する
--
m.GetJumpDest = function(_map, _x, _y)
    local try_count = 0

    while try_count < 10 do
        local dx, dy = m.GetRandomDirection();
        local jx, jy = _x + dx, _y + dy

        if m.IsTemporaryWall(jx, jy) == false then -- 仮設壁でなければOK
            return jx, jy
        end

        try_count = try_count + 1
    end

    -- 有効な跳び先はないかも

    return nil, nil
end

-- ============================================================================
-- 開始点リストからランダムで選択する(選択した開始点はリストから除く)
--
m.RandomPickupPillar = function(_list)
    if #_list < 1 then -- もう無い？
        return nil, nil
    end

    local idx = m.rand:Next(#_list) + 1
    local x, y = table.unpack(_list[idx])

    table.remove(_list, idx)

    return x, y
end

-- ============================================================================
-- Start, Goal地点候補リスト
--
m.GenStartGoalList = function(_map)
    local w, h = _map.width, _map.height
    local list = {}

    -- 左上から時計回りにリストアップする
    for x = 1, w - 4, 2 do table.insert(list, { x, 1 }) end -- 上辺
    for y = 1, h - 4, 2 do table.insert(list, { w - 2, y }) end -- 右辺
    for x = w - 2, 3, -2 do table.insert(list, { x, h - 2 }) end -- 下辺
    for y = h - 2, 3, -2 do table.insert(list, { 1, y }) end -- 左辺

    return list
end

-- ============================================================================
-- 2点間の距離(歩数)を返す
-- * 広間やループできる形状の迷路では使用できない
--
-- _p1, _p2 : {x, y}形式の座標
--
m.GetStepCount = function(_p1, _p2)
    -- マップ外？
    if m.map:IsInside(_p1.x, _p1.y) == false or m.map:IsInside(_p2.x, _p2.y) == false then return -1 end

    local marks = {}

    return m.GetStepCount_R(_p1, _p2, 0, marks)
end

m.GetStepCount_R = function(_dst, _now, _step, _marks)
    if _dst.x == _now.x and _dst.y == _now.y then return _step end -- 到達

    local key = string.format("%d,%d", _now.x, _now.y)
    if _marks[key] ~= nil then return -1 end -- 探索済み
    _marks[key] = "@"

    local d = {
        { x = 0, y = -1 },
        { x = 1, y = 0 },
        { x = 0, y = 1 },
        { x = -1, y = 0 }
    }

    for i, v in ipairs(d) do
        local nx, ny = _now.x + v.x, _now.y + v.y
        if m.map:CanEnter(nx, ny) then
            local s = m.GetStepCount_R(_dst, { x = nx + v.x, y = ny + v.y }, _step + 1, _marks)
            if 0 <= s then return s end -- 見つけた
        end
    end

    return -1
end


-- ============================================================================
-- device,item,prowlerを配置できる場所をリストアップする
--
-- _src : 基準点 {x, y}
-- _num : リストアップするポイント数
-- 戻り値 : 配列型のテーブル
--          {
--              {key = "S000(0,0)", x = 0, y = 0},
--                  ...
--          }
--          key : 000部分は基準点からの距離(歩数)
--
m.GetRandomFloorPointList = function(_src, _num)
    local list_all = m.GetDeployablePointList(m.C_CharFloor)

    -- 基準点を排除
    for i, v in ipairs(list_all) do
        if _src.x == v.x and _src.y == v.y then
            table.remove(list_all, i)
            break
        end
    end

    -- 必要数リストアップされているか？
    if #list_all < _num then
        log:Error("GenMaze.GetRandomFloorPointList", "配置可能地点が確保できません")
        return nil
    end

    -- 基準点からの距離をキーとしたリストを作成する
    local list_pickup = {}
    local count = 0
    while count <= _num do
        local idx = m.rand:Next(#list_all) + 1
        local dst = list_all[idx]
        local step = m.GetStepCount(dst, _src)
        if step < 1 then
            log:Error("GenMaze.GetRandomFloorPointList", "到達できない座標があります")
            return nil
        end

        list_pickup[string.format("S%03d(%d,%d)", step, dst.x, dst.y)] = dst
        table.remove(list_all, idx)
        count = count + 1
    end

    -- ソートする
    local key_sorted = table.sorted_keys(list_pickup)
    local list_sorted = {}
    for _, k in ipairs(key_sorted) do
        local p = list_pickup[k]
        table.insert(list_sorted, { key = k, x = p.x, y = p.y })
    end

    return list_sorted
end



-- ============================================================================
-- walkerを配置できる座標のリストを得る(順序無視)
--
-- _mapchar : 配置先のマップチップ(1文字)
-- 戻り値 : 配列型のテーブル
--          {
--              {x = 0, y = 0},
--                  ...
--          }
--      * 要素数ゼロの場合もある
--      * nilになることはない
--
m.GetDeployablePointList = function(_mapchar)
    local list = {}

    for xx = 1, m.map.width - 2, 2 do
        for yy = 1, m.map.height - 2, 2 do
            if m.map:Get(xx, yy) == _mapchar then
                table.insert(list, { x = xx, y = yy })
            end
        end
    end

    return list
end

-- ============================================================================
-- 壁操作系
--
m.IsWall = function(_x, _y) return m.map:Get(_x, _y) == m.C_CharWall end
m.IsFloor = function(_x, _y) return m.map:Get(_x, _y) == m.C_CharFloor end
m.IsTemporaryWall = function(_x, _y) return m.map:Get(_x, _y) == m.C_CharTemporaryWall end
m.SetTemporaryWall = function(_x, _y) m.map:Set(_x, _y, m.C_CharTemporaryWall) end
m.FixTemporaryWall = function() m.map:Replace(m.C_CharTemporaryWall, m.C_CharWall) end
m.ClearTemporaryWall = function() m.map:Replace(m.C_CharTemporaryWall, m.C_CharFloor) end

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
