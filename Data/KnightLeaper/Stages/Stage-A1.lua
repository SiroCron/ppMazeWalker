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

stage_info._0_Title = "ステージA1"

stage_info._1_StageRule = {
    "KnightLeaper基本ステージ",
    "最初からクライマックス",
    "食料10コ所持",
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
    -- 必ずセット
    _G.rand = cs.assist:CreateRandom(_seed)

    -- ステージパラメータ -----------------------

    -- 食べ物出現率, 10.00% => 3.00%
    rule.field.food_appear_prob = aging:CreateObj("food_appear_prob",
        0300, -1, 0300, 1000)

    -- 魔法陣出現率, 1.00% => 5.00%
    rule.field.circle_appear_prob = aging:CreateObj("circle_appear_prob",
        0500, 0.02, 0100, 0500)

    -- 障害物出現率, 1.00% => 3.00%
    rule.field.obstacle_appear_prob = aging:CreateObj("obstacle_appear_prob",
        0300, 0.02, 0100, 0300)

    -- 宝石出現率, 7.00% => 1.00%
    rule.field.gem_appear_prob = aging:CreateObj("gem_appear_prob",
        0100, -0.1, 0100, 0700)

    -- 敵出現率, 5.00% => 99.99%
    rule.field.prowler_appear_prob = aging:CreateObj("prowler_appear_prob",
        9999, 1, 0500, 9999)

    -- ステージ生成 -----------------------------

    rule.field:Init(6, 6)

    cs.walker.inventory:Add("Food", 10)

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
