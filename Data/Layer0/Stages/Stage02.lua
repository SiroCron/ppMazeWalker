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

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      説明,ヒント,解答など
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

stage_info._0_Title = "Stage02 前に進めないなら右に曲がる"

stage_info._1_StageRule = {
    "Walkerの行動可能回数は3",
    __rgui_folder_default_open = true,
}

stage_info._2_Hint = { '前に進めないなら右に曲がる' }
stage_info._3_Hint = { '前に進めるかどうか\n  map:CanEnter(0, 1)' }
stage_info._4_Hint = { '前に進めない？\n  map:CanEnter(0, 1) == false' }
stage_info._5_Hint = { '右に曲がる\n  "TurnRight"' }
stage_info._6_Hint = { 'もし A なら B する\n  if A then B end' }


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
        "#####",
        "#..D#",
        "#.###",
        "#.#  ",
        "###  "
    }

    cs.walker:SetPos(1, 3, 0)

    walker.state.life = 3

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