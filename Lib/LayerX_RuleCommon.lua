-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      LayerXX共用処理
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

table_ex = import("Lib/Table.lua")

local m = {
    event = {
        sec_phase = "theme_phase", -- フェーズ用
        sec_action = "theme_action", -- WalkerAction用

        quest_start = "theme.QuestStart",
        round_setup = "theme.RoundSetup",
        action = {
            move_forward = "theme.ActionMoveForward",
            move_backward = "theme.ActionMoveBackward",
            move_left = "theme.ActionMoveLeft",
            move_right = "theme.ActionMoveRight",
            turn_left = "theme.ActionTurnLeft",
            turn_right = "theme.ActionTurnRight",
            wait = "theme.ActionWait",
            pickup = "theme.ActionPickup",
            useitem = {
                key = "theme.ActionUseItem_Key",
                orb = "theme.ActionUseItem_Orb",
                gun = "theme.ActionUseItem_Gun",
            },
        },
        round_next = "theme.RoundNext",
        quest_stop = "theme.QuestStop",
        quest_clear = "theme.QuestClear",
        quest_failure = "theme.QuestFailure",

        prowler = {
            sec_header = "Prowler",
            born = "theme.ProwlerBorn", -- param = {x, y} 誕生座標
            move = "theme.ProwlerMove", -- param = {x, y, d} 移動元座標と移動方向
            destroy = "theme.ProwlerDestroy", -- param = {x, y} 現在座標
        },
    },
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      テーブル
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

m.rule = {}
m.rule_info = {
    __rgui_folder_default_open = true,
}

-- ==================================================================
-- コントロール
m.rule.control = {
    preset_buttons = {
        { -- 1行目
            { label = "Turn\nLeft", action = "TurnLeft", object = nil },
            { label = "Move\nForward", action = "MoveForward", object = nil },
            { label = "Turn\nRight", action = "TurnRight", object = nil },
        },
        {
            { label = "Pickup", action = "Pickup", object = nil },
        },
    },
    enable_use_item_control = true,
    enable_other_control = true,
}

-- ==================================================================
-- マップチップ
m.rule.mapchip = {}

-- ==================================================================
-- アイテム
--
-- ・アイテムは必ず取得可能(取得可能とするものをアイテムとして定義する)
--
m.rule.item_table = {}

-- ==================================================================
-- ステージ情報
--
-- ・クエスト開始時に_G.stageテーブルを初期化するための設定
-- ・Walkerスクリプトから見えてはいけない情報
--
m.rule.stage_src = {
    maze = {
        __rgui_folder_default_open = true,
        map = {},
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

-- ==================================================================
-- Walker情報
--
-- ・クエスト開始時に_G.walkerテーブルを初期化するための設定
-- ・Walkerスクリプトから見えてもいい情報
--
m.rule.walker_src = {
    actions = {},
    current_mapchip = "?",
    enterable_mapchip = "!.D", -- 進入可能なマス
    inventory = { __rgui_folder_default_open = true },
    map = {},
    prowler_mapchip = "E0123456789", -- 数値以外も入れておくこと
    state = {},
    -- Walkerの認識テーブル
    -- 上向き時を基準に認識範囲を定義する
    --      @ : 正確に認識できる,Walker視点の基準位置
    --      O : 正確に認識できる
    --      o : なんとなく認識できる
    --      ? : 何かありそうなことはわかる
    --      X : 分からない(視野外)
    view = {
        "???ooo???", -- Layer1の設定サンプル
        "??ooooo??",
        "?ooOOOoo?",
        "oooOOOooo",
        "ooOOOOOoo",
        "ooOOOOOoo",
        "ooOO@OOoo",
        "ooooooooo",
        "?ooooooo?",
    },
}

-- ==================================================================
-- Prowler関係
--
m.rule.prowlers = import("Lib/Prowlers.lua")
m.rule.prowlers.event_table = m.event.prowler

-- ==================================================================
-- ルール特有項目
--
m.rule.walker_src.state.life = 0

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
-- クエスト開始前の初期化
--
-- 戻り値 : true .... 正常終了,クエスト開始処理へ進む
--          false ... 異常終了,クエストを中断する
--
m.QuestInit = function()
    -- クリア
    _G.stage = {}
    _G.walker = {}
    _G.stage = table_ex.deepcopy(rule.stage_src)
    _G.walker = table_ex.deepcopy(rule.walker_src)

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
-- 戻り値 : true .... 正常終了,ラウンド処理へ進む
--          false ... 異常終了,クエストを中断する
--
m.QuestStart = function()
    log:Message("クエスト開始")

    event:Enqueue(m.event.sec_phase, m.event.quest_start, nil)

    return true
end

-- ============================================================================
-- Walker行動直前の処理
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
m.RoundSetup = function()
    -- Prowler情報更新 __________________________

    m.rule.prowlers:Update()

    -- Walker情報更新 ___________________________

    -- 必須項目

    cs.walker:UpdateWalkermap()

    _G.walker.actions = m._RemakeWalkerActions()

    -- ルール特有

    -- 最後にLocalVMへコピー ____________________

    cs.assist:CopyTo("walker")

    event:Enqueue(m.event.sec_phase, m.event.round_setup, nil)

    return true
end

-- ============================================================================
-- クエストクリア/失敗判定
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
m.RoundJudge = function(_si)
    local judge = state:Get("judge")

    -- クエストクリア判定 _______________________

    if cs.walker.current_mapchip == "D" then
        judge:Set("clear")
        return true
    end

    -- クエスト失敗判定 _________________________

    if cs.maze:IsProwler(cs.walker.current_mapchip) then -- Prowlerと接触
        judge:Set("failure")
        return true
    end

    if walker.state.life == 0 then -- ライフゼロ
        judge:Set("failure")
        return true
    end

    --------------------------------------------- ラウンド継続

    return true
end

-- ============================================================================
-- 行動を処理する
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
m.RoundAction = function(_action, _object)
    if _action == nil then
        log:Warning("アクションが (nil) です. 行動できません.")
        return true
    end

    -- 行動回数のカウントダウン
    if 0 < walker.state.life then walker.state.life = walker.state.life - 1 end

    -- 行動と関数のペアリスト
    local f_list = {
        MoveForward  = m._Action_MoveForward,
        MoveBackward = m._Action_MoveBackward,
        TurnLeft     = m._Action_TurnLeft,
        TurnRight    = m._Action_TurnRight,
        MoveLeft     = m._Action_MoveLeft,
        MoveRight    = m._Action_MoveRight,
        Wait         = m._Action_Wait,
        Pickup       = m._Action_Pickup,
        UseItem      = m._Action_UseItem,
    }

    -- 行動振り分け
    local f = f_list[_action]
    if f == nil then
        log:Warning("アクション「 " .. _action .. " 」は登録されていません.")
        return false
    end

    return f(_object)
end

-- ============================================================================
-- 次のラウンドへの更新or変化処理
--
-- 戻り値 : true .... 正常終了,次のラウンドへ処理を進める
--          false ... 異常終了,クエストを中断する
--
m.RoundNext = function()
    event:Enqueue(m.event.sec_phase, m.event.round_next, nil)

    -- Prowler __________________________________

    -- Layer2以降は移動する
    if rule.name ~= "Layer0" and rule.name ~= "Layer1" then
        m.rule.prowlers:MoveAll()
    end

    return true
end

-- ============================================================================
-- クエスト中断処理
--
-- 戻り値 : true .... 正常終了,ラウンド処理へ進む
--          false ... 異常終了,クエストを中断する
--
m.QuestStop = function()
    log:Message("クエストを中断します.")

    event:Enqueue(m.event.sec_phase, m.event.quest_stop, nil)

    return true
end

-- ============================================================================
-- クエストクリア処理
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
m.QuestClear = function()
    log:Message("クエストクリア！")

    event:Enqueue(m.event.sec_phase, m.event.quest_clear, nil)

    return true
end

-- ============================================================================
-- クエスト失敗処理
--
-- 戻り値 : true .... 正常終了
--          false ... 異常終了
--
m.QuestFailure = function(_si)
    log:Message("クエスト失敗.")

    event:Enqueue(m.event.sec_phase, m.event.quest_failure, nil)

    return true
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      内部関数(WalkerAction)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

m._Action_MoveForward = function(_obj)
    if cs.walker:MoveForward(2) == false then
        log:Message("進めない！")
        return true
    end

    event:Enqueue(m.event.sec_action, m.event.action.move_forward, nil)

    return true
end

m._Action_MoveBackward = function(_obj)
    if cs.walker:MoveBackward(2) == false then
        log:Message("進めない！")
        return true
    end

    event:Enqueue(m.event.sec_action, m.event.action.move_backward, nil)

    return true
end

m._Action_TurnLeft = function(_obj)
    cs.walker:TurnLeft()

    event:Enqueue(m.event.sec_action, m.event.action.turn_left, nil)

    return true
end

m._Action_TurnRight = function(_obj)
    cs.walker:TurnRight()

    event:Enqueue(m.event.sec_action, m.event.action.turn_right, nil)

    return true
end

m._Action_MoveLeft = function(_obj)
    if cs.walker:MoveLeft(2) == false then
        log:Message("進めない！")
        return true
    end

    event:Enqueue(m.event.sec_action, m.event.action.move_left, nil)

    return true
end

m._Action_MoveRight = function(_obj)
    if cs.walker:MoveRight(2) == false then
        log:Message("進めない！")
        return true
    end

    event:Enqueue(m.event.sec_action, m.event.action.move_right, nil)

    return true
end

m._Action_Wait = function(_obj)
    event:Enqueue(m.event.sec_action, m.event.action.wait, nil)

    return true
end

m._Action_Pickup = function(_obj)
    local walker = cs.walker

    local item = cs.items:GetItemByMapchip(walker.current_mapchip)

    -- アイテム落ちてる？
    if item == nil then
        log:Message("取れそうなアイテムは無いぞ.")
        return true
    end

    -- Mazemapの書換(アイテム消去)
    walker:SetMapchip(item.pickuped_mapchip)

    -- Inventoryに追加
    walker.inventory:Add(item.name, 1)

    event:Enqueue(m.event.sec_action, m.event.action.pickup, nil)

    return true
end

m._Action_UseItem = function(_obj)
    -- 使用可能か？ _____________________________

    if m._Action_CanUseItem(_obj) == false then return true end

    -- 使用 _____________________________________

    local use_procs = {
        Key = m._Action_UseItem_Key,
        Orb = m._Action_UseItem_Orb,
        Gun = m._Action_UseItem_Gun,
    }

    return use_procs[_obj]()
end

-- ============================================================================

-- ==============================================
-- アイテムが使用できるか？
--

m._Action_CanUseItem = function(_obj)
    -- アイテムが指定されていない？
    if _obj == nil or #_obj < 1 then
        return log:Message("どのアイテムを使うって？？？", false)
    end

    -- アイテムなのか？
    local item = cs.items:GetItemByName(_obj)
    if item == nil then
        return log:Message("'" .. _obj .. "'？ それはアイテムなのか？", false)
    end

    -- そのアイテムを持ってる？
    if cs.walker.inventory:IsExist(_obj) == false then
        return log:Message("'" .. _obj .. "'？ そんなアイテムは持っていない. ", false)
    end

    --------------------------------------------- 有効なアイテムが指定されている

    -- ここで使えるか？
    if item:IsUsable(cs.walker.current_mapchip) == false then
        return log:Message("ここで使う？ '" .. _obj .. "' を？", false)
    end

    --------------------------------------------- OK

    return true;
end

-- ==============================================
-- アイテム使用
--
m._Action_UseItem_Key = function()
    -- もし台座があるなら使用できない
    local map = cs.maze:GetMazemap()
    if map:IsContain("l") then
        return log:Message("あれ？開かないぞ？")
    end

    -- 使用 _____________________________________

    cs.walker:SetMapchip("D")
    cs.walker.inventory:Consume("Key", 1)

    -- イベント発行
    event:Enqueue(m.event.sec_action, m.event.action.useitem.key, nil)

    return log:Message("開いた！")
end

m._Action_UseItem_Orb = function()
    -- 使用 _____________________________________

    cs.walker:SetMapchip("i")
    cs.walker.inventory:Consume("Orb", 1)

    -- イベント発行
    event:Enqueue(m.event.sec_action, m.event.action.useitem.orb, nil)

    return log:Message("置いたぞ！")
end

m._Action_UseItem_Gun = function()
    -- イベント発行
    event:Enqueue(m.event.sec_action, m.event.action.useitem.gun, nil)

    local offset = {
        { x = 0, y = -1 },
        { x = 1, y = 0 },
        { x = 0, y = 1 },
        { x = -1, y = 0 }
    }

    local map = cs.maze:GetMazemap()

    local xx, yy, d = cs.walker.x, cs.walker.y, cs.walker.d
    local range = 4

    while 0 < range do
        xx, yy = xx + offset[d + 1].x, yy + offset[d + 1].y
        range = range - 1

        local mc = map:Get(xx, yy)

        if mc == "#" then -- 壁
            return log:Message("壁に命中！")
        end

        if cs.maze:IsProwler(mc) then -- 敵？
            m.rule.prowlers:Destroy(xx, yy)
            return true
        end
    end

    --------------------------------------------- 壁,敵に当たらなかった

    return log:Message("やったか！？")
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
m._RemakeWalkerActions = function()
    local actions = {}

    -- Move -------------------------------------

    if rule.name == "Layer0" or rule.name == "Layer1" then
        actions = {
            MoveForward = {},
            TurnLeft = {},
            TurnRight = {},
        }
    else
        actions = {
            MoveForward = {},
            MoveBackward = {},
            TurnLeft = {},
            TurnRight = {},
            MoveLeft = {},
            MoveRight = {},
            Wait = {},
        }
    end

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
--      おわり
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////
return m
