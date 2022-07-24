-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      初期化
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- require(),loadfile()でも可だが、構文エラー時のログがアバウト
table = import("Lib/Table.lua")
BasicWalkerAction = import("Lib/WalkerAction.lua")

_G.rule = { name = "Layer1" }
_G.rule_info = {}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ルール説明
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

rule_info = {
    __rgui_folder_default_open = true,
}

rule_info._0_Title = "Layer1 - アイテムを使う"

rule_info._1_Description = {
    "出口に到着するとステージクリア",
    "ステージによっては行動回数制限あり",
    "鍵を使わないと出られない出口がある",
    "宝玉がセットされていない台座があると出口の錠を開けられない",
    "敵と重なる(同じマスに入る)とアウト",
    "銃の射程は2歩分先まで. 壁や敵を貫通しない. 弾数制限無し",
}

rule_info._2_MapCharacter = {
    "'#' = 壁           'D' = 出口",
    "'.' = 通路         '$' = 出口(施錠)",
    "'k' = Key(鍵)      'l' = 台座",
    "'o' = Orb(宝玉)    'i' = 台座(宝玉)",
    "'g' = Gun(銃)",
    "",
    "'0'~'9' = 敵",
    "",
    "-------- Walker視点のみ --------",
    "'@' = 自分         '!' = 何かある？",
    "                   '?' = 不明",
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストから参照するプロパティ
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ============================================================================
-- マップ変換
--
rule.mapchip = {
    -- MazeMap=>WalkerMap変換テーブル
    -- 変換前の"?"はエリア外またはエラー
    convert_table = {
        " @Oo?X", -- 先頭(idx:1)はWalkerViewの文字
        -- 1文字目がstage.maze.mapの文字,2文字以降がWalkerViewに対応する文字
        "??????", -- エリア外(配列外)
        "  ????", -- エリア外(空欄)
        "#####?", -- 壁
        ".....?", -- 通路
        "DDDD!?", -- 扉
        "$$$D!?", -- 扉  :施錠状態は分からない
        "llll!?", -- 台座
        "iiil!?", -- 台座:宝玉の有無は分からない
        "kkk!!?", -- 鍵
        "ooo!!?", -- 宝玉
        "ggg!!?", -- 銃
        "0000!?", -- 敵
        "1110!?", -- 敵
        "2220!?", -- 敵
        "3330!?", -- 敵
        "4440!?", -- 敵
        "5550!?", -- 敵
        "6660!?", -- 敵
        "7770!?", -- 敵
        "8880!?", -- 敵
        "9990!?", -- 敵
    },
}

-- ============================================================================
-- アイテム
--
-- ・アイテムは必ず取得可能(取得可能とするものをアイテムとして定義する)
--
rule.item_table = {
    -- mapchip : ユニークであること,1文字
    -- pickup  : 拾得後のmazemapのmapchip,1文字
    -- usable  : 使用できるmazemapのmapchip,該当文字全て
    Key = { mapchip = "k", pickup = ".", usable = "$" },
    Orb = { mapchip = "o", pickup = ".", usable = "l" },
    Gun = { mapchip = "g", pickup = ".", usable = ".$liko" },
}

-- ============================================================================
-- ステージ情報
--
-- ・クエスト開始時に_G.stageテーブルを初期化するための設定
--
rule.stage_src = {
    maze = {
        __rgui_folder_default_open = true,
        map = "",
    },
    walker = {
        __rgui_folder_default_open = true,
        pos = {
            __rgui_folder_default_open = true,
            -- __rgui_column_size = 3,
            x = 0,
            y = 0,
            d = 0
        }, -- pos.d : 向き(0:上,1:右,2:下,3:左)
    }
}

-- ============================================================================
-- Walker情報
--
-- ・クエスト開始時に_G.walkerテーブルを初期化するための設定
--
rule.walker_src = {
    actions = {},
    current_mapchip = "?",
    enterable_mapchip = "!.D$likog0123456789", -- 進入可能なマス
    inventory = { __rgui_folder_default_open = true },
    map = {},
    -- Walkerの認識テーブル
    -- 上向き時を基準に認識範囲を定義する
    --      @ : 正確に認識できる,Walker視点の基準位置
    --      O : 正確に認識できる
    --      o : なんとなく認識できる
    --      ? : 何かありそうなことはわかる
    --      X : 分からない(視野外)
    view = {
        "???ooo???",
        "??ooooo??",
        "?ooOOOoo?",
        "oooOOOooo",
        "ooOOOOOoo",
        "ooOOOOOoo",
        "ooOO@OOoo",
        "ooooooooo",
        "?ooooooo?",
    },
    state = {},
}

-- ルール特有項目 -------------------------------
rule.walker_src.state.life = 0

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストからCallされる関数(必須)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

-- ============================================================================
-- クエスト開始前の初期化
--
-- 戻り値 : true .... 正常終了,クエスト開始処理へ進む
--          false ... 異常終了,クエストを中断する
--
rule.QuestInit = function()
    -- クリア
    _G.stage = {}
    _G.walker = {}
    _G.stage = table.deepcopy(_G.rule.stage_src)
    _G.walker = table.deepcopy(_G.rule.walker_src)

    -- デフォルト関数のセット
    stage.QuestStart = rule.QuestStart
    stage.RoundSetup = rule.RoundSetup
    stage.RoundJudge = rule.RoundJudge
    stage.RoundAction = rule.RoundAction
    stage.RoundNext = rule.RoundNext
    stage.QuestStop = rule.QuestStop
    stage.QuestClear = rule.QuestClear
    stage.QuestFailure = rule.QuestFailure

    return true
end

-- ============================================================================
-- クエスト開始処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了,ラウンド処理へ進む
--          false ... 異常終了,クエストを中断する
--
rule.QuestStart = function(_si)
    if _si.count == 0 then
        log:Message("クエスト開始")
    end

    return theme.QuestStart(_si)
end

-- ============================================================================
-- Walker行動直前の処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
rule.RoundSetup = function(_si)
    -- クリア

    -- 更新 _____________________________________

    -- 必須項目

    cs.walker:UpdateWalkermap()

    _G.walker.actions = rule.RemakeWalkerActions()

    -- ルール特有

    -- 最後にLocalVMへコピー ____________________

    cs.assist:CopyTo("walker")

    return theme.RoundSetup(_si)
end


-- ============================================================================
-- クエストクリア/失敗判定
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : <is_success(bool)>, <next(string)>
--      is_success : 処理が問題無く終了したか？
--          true .... 正常終了,次のラウンドまたはクエストクリア/失敗
--          false ... 異常終了,クエストを中断する
--      next : 次の状態(is_successがtrueの時に有効)
--          "continue" .. フェーズ維持,現在の処理を継続する
--          "next" ...... クエスト継続,次のラウンド(Setup)に進む
--          "clear" ..... クエストクリア
--          "failure" ... クエスト失敗
--
rule.RoundJudge = function(_si)
    -- クエストクリア判定 _______________________

    if cs.walker.current_mapchip == "D" then
        return true, "clear"
    end

    -- クエスト失敗判定 _________________________

    if tonumber(cs.walker.current_mapchip) ~= nil then -- Prowlerと接触
        return true, "failure"
    end

    if walker.state.life == 0 then -- ライフゼロ
        return true, "failure"
    end

    --------------------------------------------- ラウンド継続

    return true
end


-- ============================================================================
-- 行動を処理する
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
rule.RoundAction = function(_si, _action, _object)
    if _si.count == 0 then
        -- action==nilならここで無効化
        if _action == nil then
            log:Warning("アクションが (nil) です. 行動できません.")
            return true
        end

        -- 行動回数のカウントダウン
        if 0 < walker.state.life then walker.state.life = walker.state.life - 1 end
    end

    -- 行動と関数のペアリスト
    local f_list = {
        MoveForward = BasicWalkerAction.MoveForward,
        TurnLeft    = BasicWalkerAction.TurnLeft,
        TurnRight   = BasicWalkerAction.TurnRight,
        Pickup      = BasicWalkerAction.Pickup,
        UseItem     = BasicWalkerAction.UseItem,
    }

    -- 行動振り分け
    local retcode = true
    local retinfo = nil
    local f = f_list[_action]
    if f ~= nil then
        retcode, retinfo = f(_si, _object)
    else
        log:Warning("アクション「 " .. _action .. " 」は登録されていません.")
    end

    return retcode, retinfo
end


-- ============================================================================
-- 次のラウンドへの更新or変化処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
rule.RoundNext = function(_si)
    -- 変化処理 _________________________________

    return true
end


-- ============================================================================
-- クエスト中断処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了,ラウンド処理へ進む
--          false ... 異常終了,クエストを中断する
--
rule.QuestStop = function(_si)
    if _si.count == 0 then
        log:Message("クエストを中断します.")
    end

    return theme.QuestStop(_si)
end

-- ============================================================================
-- クエストクリア処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
rule.QuestClear = function(_si)
    if _si.count == 0 then
        log:Message("クエストクリア！")
    end

    return theme.QuestClear(_si)
end

-- ============================================================================
-- クエスト失敗処理
--
-- _si : 処理情報
--      _si.count : フェーズ移行後何度目の呼び出しか(0スタート)
--      _si.delta_time : 更新間隔(sec,float)
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
rule.QuestFailure = function(_si)
    if _si.count == 0 then
        log:Message("クエスト失敗.")
    end

    return theme.QuestFailure(_si)
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

-- 選択可能な行動リストの再構成
rule.RemakeWalkerActions = function()
    -- 基本 -------------------------------------

    local actions = {
        MoveForward = {},
        TurnLeft = {},
        TurnRight = {},
    }

    -- Pickup -----------------------------------

    if cs.items:GetItemByMapchip(cs.walker.current_mapchip) ~= nil then
        actions["Pickup"] = {}
    end

    -- UseItem ----------------------------------

    if 0 < cs.walker.inventory.count then
        actions["UseItem"] = cs.walker.inventory:GetNameListTable()
    end

    -- Update -----------------------------------

    return actions
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      定義済み関数を必要とする初期化
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local Init = function()
end

Init()
