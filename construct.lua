-- ==================================================================
--

-- xxx_menu:AddFolder(<title>, <vm-no>, <table-path>, <function-include>, <folder-open>)
--      vm-no ... 1:WorldVM, 2:LocalVM

-- Left Block ___________________________________

left_menu:AddFolder("ルール説明", 1, "_G.rule_info", false, false)
left_menu:AddFolder("ステージ説明＆ヒント", 1, "_G.stage_info", false, false)

-- VMの状態を見るなら必要な場所に応じてコメントを解除
-- left_menu:AddFolder("WorldVM:rule", 1, "_G.rule", false, false)
-- left_menu:AddFolder("WorldVM:stage", 1, "_G.stage", false, false)
-- left_menu:AddFolder("WorldVM:walker", 1, "_G.walker", false, false)
-- left_menu:AddFolder("LocalVM:walker", 2, "_G.walker", false, false)
-- left_menu:AddFolder("for debugging", 1, "_G.debug", true, false)

-- Right Block __________________________________

right_menu:AddFolder("State", 2, "_G.walker.state", false, true)
right_menu:AddFolder("WalkerMap", 2, "_G.walker.map", false, true)
right_menu:AddFolder("Inventory", 2, "_G.walker.inventory", false, true)
