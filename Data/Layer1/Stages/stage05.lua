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

stage_info._0_Title = "Stage05 壁越しの敵を撃たないようにする"

stage_info._1_StageRule = {
    "Walkerの行動可能回数は9",
    __rgui_folder_default_open = true,
}

stage_info._2_Hint = { 'Walkerと敵との間に壁が無いことをチェックする' }
stage_info._3_Hint = { '「1歩先への敵に攻撃する」状況とは\n  ⇒「銃を所持」「前方に壁が無い」「1歩先に敵がいる」' }
stage_info._4_Hint = { '「2歩先への敵に攻撃する」状況とは\n  ⇒「銃を所持」「前方に壁が無い」「1歩先前方に壁が無い」「2歩先に敵がいる」' }

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
    stage.maze.map = {
        "  ###  ",
        "  #1#  ",
        "#####  ",
        "#D..#  ",
        "###.###",
        "  #.#0#",
        "  #.###",
        "  #..g#",
        "  ###.#",
        "    #.#",
        "    ###",
    }

    cs.walker:SetPos(5, 9, 0)
    walker.state.life = 9

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
