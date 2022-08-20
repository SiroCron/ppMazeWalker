-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      初期化
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

_G.table_ex = import("Lib/Table.lua")

local m = {
    C_Food_CarryMax = 10,
    C_Food_Volume = 100, -- 増加じゃなくてこの値になる

    C_Gem_Score = 100,
    C_Kill_Score = 5,

    C_HeatBody_ChargeCost = 30, -- 腹減り度
    C_HeatBody_ChargeVolume = 10, -- 増加じゃなくてこの値になる

    event = {
        sec_phase = "theme_phase", -- フェーズ用
        sec_action = "theme_action", -- WalkerAction用
        sec_effect = "theme_effect",

        quest_start = "theme.QuestStart",
        round_setup = "theme.RoundSetup",
        action = {
            move = "theme.ActionMove",
            pickup = "theme.ActionPickup",
            eat = "theme.ActionEat",
            heatbody = "theme.ActionHeatBody",
        },
        round_next = "theme.RoundNext",
        quest_stop = "theme.QuestStop",
        quest_failure = "theme.QuestFailure",

        dispell = "theme.Dispell",
        destroy = "theme.Destroy",
    }
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ルール説明
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

_G.rule_info = {
    __rgui_folder_default_open = true,
    _0_Title = "KnightLeaper - チェスのナイト移動でサバイバル",
    _1_Description = {
        "生存距離を競うエンドレスゲーム.",
        "敵と重なる,フィールド外に出る,スタミナがゼロになる,とゲームオーバー.",
        "自機の移動はチェスのナイトと同じ.",
        "1行動につきスタミナが1減少する. 待機は減少しない.",
        "食料は10コまで所持できる. 食べるとスタミナが100に回復する.",
        "スタミナを30消費して魔法を発動できる. 効果は10ターン.",
        "魔法の発動中は敵と重なってもOK.",
        "魔法陣の上では魔法が使えず,発動中に乗った場合は魔法が消える.",
        "宝石の効果は得点アップのみ.",
    },
    _2_MapCharacter = {
        "'#' = 壁         ' ' = マップ外",
        "'X' = 障害物     '.' = 地面",
        "'E' = 敵         'C' = 魔法陣",
        "",
        "'f' = 食料       'G' = 宝石",
        "",
        "-------- Walker視点のみ --------",
        "'@' = 自分",
    },
    _3_KnightAction = {
        '"FFL" = 前前左の位置に跳ぶ  "FFR" = 前前右の位置に跳ぶ',
        '"LLF" = 左左前              "RRF" = 右右前',
        '"LLB" = 左左後              "RRB" = 右右後',
        '"BBL" = 後後左              "BBR" = 後後右',
        '',
        '"Pickup"   = 食料,宝石を拾う',
        '"Eat"      = 食料を食べる',
        '"HeatBody" = 魔法を使う',
        '"Wait"     = 何もしない',
        '',
        '※本ルールではActionしか使用しません',
        '  例) return "HeatBody"',
    },
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

_G.rule = {
    name = "KnightLeaper",

    control = {
        preset_buttons = {
            { {}, { label = "FFL", action = "FFL", object = nil }, {}, { label = "FFR", action = "FFR", object = nil },
                {} },
            { { label = "LLF", action = "LLF", object = nil }, {}, {}, {},
                { label = "RRF", action = "RRF", object = nil } },
            { {}, {}, { label = "Wait", action = "Wait", object = nil }, {}, {} },
            { { label = "LLB", action = "LLB", object = nil }, {}, {}, {},
                { label = "RRB", action = "RRB", object = nil } },
            { {}, { label = "BBL", action = "BBL", object = nil }, {}, { label = "BBR", action = "BBR", object = nil },
                {} },
            { { label = "Pickup", action = "Pickup", object = nil } },
            { { label = "Eat", action = "Eat", object = nil } },
            { { label = "HeatBody", action = "HeatBody", object = nil } },
        },
        enable_use_item_control = false,
        enable_other_control = false,
    },

    mapchip = {
        -- このルールでは認識変化無し
        convert_table = {
            " @o",
            "???",
            " ??",
            "###", -- 壁
            "XXX", -- 障害物
            "...", -- 地面
            "CCC", -- 魔法陣
            "fff", -- 食べ物
            "GGG", -- 宝石
            "EEE", -- 敵
        }
    },

    item_table = {
        Food = { mapchip = "f", pickup = ".", usable = "." },
        Gem = { mapchip = "G", pickup = ".", usable = "." },
    },

    stage_src = {
        maze = {
            __rgui_folder_default_open = true,
            map = {},
        },
        walker = {
            __rgui_folder_default_open = true,
            pos = {
                __rgui_folder_default_open = true,
                x = 0,
                y = 0,
                d = 0 -- 上向き固定
            },
        },
    },

    walker_src = {
        actions = {
            FFL = {}, FFR = {},
            LLF = {}, RRF = {},
            LLB = {}, RRB = {},
            BBL = {}, BBR = {},
            Wait = {},
            Pickup = {}, Eat = {},
            HeatBody = {}
        },
        current_mapchip = "?",
        enterable_mapchip = "C.fGE",
        inventory = { __rgui_folder_default_open = true },
        map = {},
        prowler_mapchip = "E", -- 数値以外も入れておくこと
        state = {
            charge = 0,
            kill = 0,
            score = -1,
            stamina = 101,
            turn = 0,
        },
        -- Walkerの認識テーブル
        -- 上向き時を基準に認識範囲を定義する
        --      @ : 正確に認識できる,Walker視点の基準位置
        --      o : 正確に認識できる
        view = { -- X:-4~+4, Y:+4~-4
            "ooooooooo",
            "ooooooooo",
            "ooooooooo",
            "ooooooooo",
            "oooo@oooo",
            "ooooooooo",
            "ooooooooo",
            "ooooooooo",
            "ooooooooo",
        },
    },
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      ホストからCallされる関数(必須)
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

rule.QuestInit = function()
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

rule.QuestStart = function()
    log:Message("クエスト開始")

    event:Enqueue(m.event.sec_phase, m.event.quest_start, nil)

    return true
end

rule.RoundSetup = function()
    -- 状態更新 ---------------------------------

    walker.state.score = walker.state.score + 1
    walker.state.turn = walker.state.turn + 1

    if 0 < walker.state.stamina then walker.state.stamina = walker.state.stamina - 1 end
    if 0 < walker.state.charge then walker.state.charge = walker.state.charge - 1 end

    aging:Elapse(walker.state.score)
    rule.field:Next()

    -- 位置更新
    stage.walker.pos.y = stage.walker.pos.y + 1

    ---------------------------------------------

    cs.walker:UpdateWalkermap()

    -- to LocalVM
    cs.assist:CopyTo("walker")

    event:Enqueue(m.event.sec_phase, m.event.round_setup, nil)

    return true
end

rule.RoundJudge = function()
    local judge = state:Get("judge")

    -- クエストクリア……は無い

    -- クエスト失敗判定 _________________________

    local map = cs.maze:GetMazemap()

    -- マップ外
    if map.height <= cs.walker.y then
        log:Message("『待って～～』")
        judge:Set("failure")
        return true
    end

    -- 敵と接触
    if cs.maze:IsProwler(cs.walker.current_mapchip) then
        log:Message("『ここまでか……』")
        judge:Set("failure")
        return true
    end

    -- 空腹限界
    if walker.state.stamina < 1 then
        log:Message("『最後にお腹いっぱい食べたかった……』")
        judge:Set("failure")
        return true
    end

    --------------------------------------------- ラウンド継続

    return true
end

rule.RoundAction = function(_action, _object)
    if _action == nil then
        log:Warning("アクションが (nil) です. 行動できません.")
        return true
    end

    -- 行動リスト
    local f_list = {
        FFL = m.Action_FFL,
        FFR = m.Action_FFR,
        LLF = m.Action_LLF,
        RRF = m.Action_RRF,
        LLB = m.Action_LLB,
        RRB = m.Action_RRB,
        BBL = m.Action_BBL,
        BBR = m.Action_BBR,
        Wait = m.Action_Wait,
        Pickup = m.Action_Pickup,
        Eat = m.Action_Eat,
        HeatBody = m.Action_HeatBody,
    }

    -- 行動振り分け
    local f = f_list[_action]
    if f == nil then
        log:Warning("アクション「 " .. _action .. " 」は登録されていません.")
        return false
    end

    return f(_object)
end

rule.RoundNext = function()
    event:Enqueue(m.event.sec_phase, m.event.round_next, nil)

    -- 当たり判定 -------------------------------

    local map = cs.maze:GetMazemap()

    -- 罠に接触
    if map:Get(cs.walker.x, cs.walker.y) == "C" then
        log:Message("『おおっと！』")
        walker.state.charge = 0
        event:Enqueue(m.event.sec_effect, m.event.dispell, nil)
        event:SetCrossPhases(m.event.sec_effect)
    end

    -- HeatBody中に敵と接触
    if 0 < walker.state.charge and map:IsProwler(cs.walker.x, cs.walker.y) then
        walker.state.kill = walker.state.kill + 1
        walker.state.score = walker.state.score + m.C_Kill_Score

        map:Set(cs.walker.x, cs.walker.y, ".")
        event:Enqueue(m.event.sec_effect, m.event.destroy, { x = cs.walker.x, y = cs.walker.y })
        event:SetCrossPhases(m.event.sec_effect)
    end

    return true
end

rule.QuestStop = function()
    log:Message("クエストを中断します.")

    event:Enqueue(m.event.sec_phase, m.event.quest_stop, nil)

    return true
end

rule.QuestFailure = function(_si)
    local inv = cs.walker.inventory
    local gem_count = 0
    if inv:IsExist("Gem") then gem_count = inv:GetItemCount("Gem") end

    log:Message("KnightLeaperは力尽きた……  Score=" .. walker.state.score .. ", Gem=" .. gem_count)

    event:Enqueue(m.event.sec_phase, m.event.quest_failure, nil)

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

m.Action_Move = function(_x, _y)
    -- 移動 -------------------------------------

    -- 移動先
    local nx = cs.walker.x + _x
    local ny = cs.walker.y - _y

    local map = cs.maze:GetMazemap()
    if map:CanEnter(nx, ny) == false then return log:Message("『進めない！』") end

    -- 位置更新
    cs.walker:SetPos(nx, ny, 0)

    event:Enqueue(m.event.sec_action, m.event.action.move, { x = _x, y = _y })
    event:SetCrossPhases(m.event.sec_action)

    return true
end

m.Action_FFL = function(_obj) return m.Action_Move(-1, 2) end
m.Action_FFR = function(_obj) return m.Action_Move(1, 2) end
m.Action_LLF = function(_obj) return m.Action_Move(-2, 1) end
m.Action_RRF = function(_obj) return m.Action_Move(2, 1) end
m.Action_LLB = function(_obj) return m.Action_Move(-2, -1) end
m.Action_RRB = function(_obj) return m.Action_Move(2, -1) end
m.Action_BBL = function(_obj) return m.Action_Move(-1, -2) end
m.Action_BBR = function(_obj) return m.Action_Move(1, -2) end

m.Action_Wait = function(_obj)
    log:Message("『ちょっと休憩』")

    walker.state.stamina = walker.state.stamina + 1

    return true
end

m.Action_Pickup = function(_obj)
    local item = cs.items:GetItemByMapchip(walker.current_mapchip)

    -- アイテム落ちてる？
    if item == nil then return log:Message("『何も落ちてないな』") end

    if item.name == "Gem" then
        walker.state.score = walker.state.score + m.C_Gem_Score
        log:Message("『宝石ゲット！』")
    elseif item.name == "Food" then
        if m.C_Food_CarryMax <= cs.walker.inventory:GetItemCount("Food") then
            return log:Message("『これ以上持てない』")
        end
    end

    -- Mazemapの書換(アイテム消去)
    cs.walker:SetMapchip(item.pickuped_mapchip)

    -- Inventoryに追加
    cs.walker.inventory:Add(item.name, 1)

    event:Enqueue(m.event.sec_action, m.event.action.pickup, { name = item.name })
    event:SetCrossPhases(m.event.sec_action)

    return true
end

m.Action_Eat = function(_obj)
    if cs.walker.inventory:IsExist("Food") == false then
        return log:Message("『さっき食べたのが最後だったか……』")
    end

    -- 使用 _____________________________________

    cs.walker.inventory:Consume("Food", 1)
    walker.state.stamina = m.C_Food_Volume + 1

    event:Enqueue(m.event.sec_action, m.event.action.eat, nil)
    event:SetCrossPhases(m.event.sec_action)

    local msg = {
        "『おいしい！これはアタリだ！』",
        "『うまいうまい』",
        "『味がしねえ』",
        "『うん！まずい！』",
        "『腐ってるじゃねぇか……』"
    }

    return log:Message(msg[_G.rand:Next(#msg) + 1])
end

m.Action_HeatBody = function(_obj)
    if walker.state.stamina < m.C_HeatBody_ChargeCost then
        return log:Message("『腹減った……』")
    end

    -- 魔法円？
    if cs.walker.current_mapchip == "C" then
        return log:Message("『ここでは使えない！』")
    end

    -- 使用 _____________________________________

    walker.state.stamina = walker.state.stamina - m.C_HeatBody_ChargeCost
    walker.state.charge = m.C_HeatBody_ChargeVolume + 1

    event:Enqueue(m.event.sec_action, m.event.action.heatbody, nil)
    event:SetCrossPhases(m.event.sec_action)

    return true
end

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      フィールド操作関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

rule.field = {
    -- AgingObjs --------------------------------

    obstacle_appear_prob = nil,
    circle_appear_prob = nil,
    food_appear_prob = nil,
    gem_appear_prob = nil,
    prowler_appear_prob = nil,

    width = 13,
    height = 13,

    blank = {
        left = 0,
        right = 0,
        max = 3,
    }
}

rule.field.Init = function(self, _x, _y)
    self.blank.left = 0
    self.blank.right = 0

    stage.maze.map = {}
    for i = 1, _y + 2 do
        table.insert(stage.maze.map, 1, self:_GenNextLine())
    end
    for i = 1, self.height - _y - 2 do
        table.insert(stage.maze.map, 1, self:_PlaceObjects(self:_GenNextLine()))
    end

    cs.walker:SetPos(_x, _y - 1)
end

rule.field.Next = function(self)
    table.remove(stage.maze.map, self.height)

    local line = self:_PlaceObjects(self:_GenNextLine())

    table.insert(stage.maze.map, 1, line)
end

---------------------------------------------------------------------

rule.field._GenNextLine = function(self)
    local NextVal = function(_v)
        _v = _v + _G.rand:Next(3) - 1 -- -1~+1
        if _v < 0 then _v = 0 end
        if self.blank.max < _v then _v = self.blank.max end
        return _v
    end

    self.blank.left = NextVal(self.blank.left)
    self.blank.right = NextVal(self.blank.right)

    local center = self.width - self.blank.left - 1 - 1 - self.blank.right

    return string.rep(" ", self.blank.left) .. "#" .. string.rep(".", center) .. "#" .. string.rep(" ", self.blank.right)
end

rule.field._PlaceObjects = function(self, _s)
    local TryAppear = function(_c, _prob, _obj_char)
        if _c ~= "." then return _c end
        if _G.rand:Next(10000) < _prob.val then _c = _obj_char end
        return _c
    end

    local s = ""
    for i = 1, string.len(_s) do
        local c = string.sub(_s, i, i)

        if c == "." then
            c = TryAppear(c, self.food_appear_prob, "f")
            c = TryAppear(c, self.circle_appear_prob, "C")
            c = TryAppear(c, self.obstacle_appear_prob, "X")
            c = TryAppear(c, self.gem_appear_prob, "G")
            c = TryAppear(c, self.prowler_appear_prob, "E")
        end

        s = s .. c
    end

    return s
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
