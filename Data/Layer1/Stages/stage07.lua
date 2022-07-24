-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ロード時のテーブル設定
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local GenMaze = import("Lib/GenMaze.lua")

-- stage(_G.stage)は初期化しないこと！(直前にWorldRule.luaのrule.QuestInit()で初期化しているため)
_G.stage_info = {}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      説明,ヒント,解答など
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

stage_info._0_Title = "Stage07 ランダム迷路で試す"

stage_info._1_StageRule = {
    "Walkerの行動可能回数無し",
    __rgui_folder_default_open = true,
}


-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストからCallされる関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ============================================================================
-- 迷路生成
--
-- 戻り値 : true .... 正常終了(迷路ができたよ！遊べるかは知らんけど！)
--          false ... 異常終了
--
-- ※ホストからはプレイできる迷路が生成されているかどうかの判定を行っていない
--
stage.GenerateMaze = function(_seed)
    local rand = cs.assist:CreateRandom(_seed)

    local w, h = 5 + rand:Next(10), 5 + rand:Next(10)
    local map = GenMaze.GenerateMaze(w, h, rand)
    local sx, sy, gx, gy = GenMaze.GetStartGoal(map)
    local x, y

    -- Walker
    cs.walker:SetPos(sx, sy, rand:Next(4))
    local wpos = { x = sx, y = sy }

    -- Goal
    map:Set(gx, gy, "$")

    -- device, item, prowler
    local list = GenMaze.GetRandomFloorPointList(wpos, 14)

    -- Key
    map:Set(list[1].x, list[1].y, "k")
    table.remove(list, 1)

    -- Pedestal
    map:Set(list[1].x, list[1].y, "l")
    table.remove(list, 1)

    -- Gun
    map:Set(list[1].x, list[1].y, "g")
    table.remove(list, 1)

    -- Prowler
    for no = 0, 9 do
        map:Set(list[1].x, list[1].y, "" .. no)
        table.remove(list, 1)
    end

    -- Orb
    map:Set(list[1].x, list[1].y, "o")
    table.remove(list, 1)

    walker.state.life = -1 -- 行動回数無制限

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
