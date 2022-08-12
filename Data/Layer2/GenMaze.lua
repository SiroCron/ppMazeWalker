-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      Layer2迷路生成共用
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local GenMaze = import("Lib/GenMaze.lua")

local m = {}

local f = function(_seed, _w, _h, _prowler_count, _prowler_dist, _gun_dist)
    m.rand = cs.assist:CreateRandom(_seed)

    local size_w = m.Rand(_w)
    local size_h = m.Rand(_h)
    local map = GenMaze.GenerateMaze(size_w, size_h, m.rand)

    -- Walker
    local walker_pos = GenMaze.GetDeployablePoint(".", m.rand)
    cs.walker:SetPos(walker_pos.x, walker_pos.y, m.rand:Next(4))

    -- Prowlers
    local p_count = m.Rand(_prowler_count)
    for i = 1, p_count do
        local p = GenMaze.GetSameDistPoint(walker_pos, _prowler_dist[1], _prowler_dist[2], m.rand)
        if p == nil then
            log:Warning("配置可能な場所がありませんでした")
        else
            map:Set(p.x, p.y, "0")
        end
    end

    -- Gun
    local p = GenMaze.GetSameDistPoint(walker_pos, _gun_dist[1], _gun_dist[2], m.rand)
    map:Set(p.x, p.y, "g")

    -- Goal, Key, Pedestal, Orb
    local list = GenMaze.GetDeployablePointList(".")
    -- Goal
    local idx = 1 + m.rand:Next(#list)
    map:Set(list[idx].x, list[idx].y, "$")
    table.remove(list, idx)
    -- Key
    local idx = 1 + m.rand:Next(#list)
    map:Set(list[idx].x, list[idx].y, "k")
    table.remove(list, idx)
    -- Pedestal
    local idx = 1 + m.rand:Next(#list)
    map:Set(list[idx].x, list[idx].y, "l")
    table.remove(list, idx)
    -- Orb
    local idx = 1 + m.rand:Next(#list)
    map:Set(list[idx].x, list[idx].y, "o")
    table.remove(list, idx)

    walker.state.life = -1 -- 行動回数無制限

    return true
end

m.Rand = function(_minmax)
    return _minmax[1] + m.rand:Next(_minmax[2] - _minmax[1] + 1)
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
