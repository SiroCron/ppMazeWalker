-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ロード時のテーブル設定
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- stage(_G.stage)は初期化しないこと！(直前にWorldRule.luaのrule.QuestInit()で初期化しているため)
_G.stage_info = {}

local GenMaze = import("Lib/GenMaze.lua")

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      説明,ヒント,解答など
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

stage_info._0_Title = "Stage05 広い迷路で試してみる"

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

    cs.walker:SetPos(sx, sy, rand:Next(4))
    map:Set(gx, gy, "D")

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
