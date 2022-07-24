-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      LayerXX共用処理
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local m = {
    SE_Pickup = "Pickup",
    SE_UseItem = "UseItem",
    SE_UseItem_Gun = "UseItem_Gun",
    SE_QuestClear = "QuestClear",
    SE_QuestFailure = "QuestFailure",
}

-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      公開関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

m.InitSE = function()
    local files_table = {
        { key = m.SE_Pickup, file = "Get.mp3", volume = 1.0 },
        { key = m.SE_UseItem, file = "Use.mp3", volume = 1.0 },
        { key = m.SE_UseItem_Gun, file = "Fire.mp3", volume = 1.0 },
        { key = m.SE_QuestClear, file = "OK.mp3", volume = 1.0 },
        { key = m.SE_QuestFailure, file = "NG.mp3", volume = 1.0 },
    }

    local ret = cs.assist:CreateIsSuccess()

    for _, v in ipairs(files_table) do
        ret.b = cs.se:Load(v.key, "../LayerX_CommonData/se/" .. v.file, v.volume)
    end

    return ret.is_success
end

m.InitBGM = function()
    local layers_files_table = {
        Layer0 = {
            { file = "WhiteBatAudio_Archetype.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Drifter.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_FromBeneath.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_LoneSurvivor.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Sycophant.mp3", volume = 1.0 },
        },
        Layer1 = {
            { file = "WhiteBatAudio_AfterTheWar.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Dredd.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Invader.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_MidnightEmpire.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Surveillance.mp3", volume = 1.0 },
        },
        Layer2 = {
            { file = "WhiteBatAudio_BadTrip.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_HuntedByMachines.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Inception.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_Scanner.mp3", volume = 1.0 },
            { file = "WhiteBatAudio_SubwayChase.mp3", volume = 1.0 },
        },
    }

    local files_table = layers_files_table[rule.name]
    if files_table == nil then files_table = layers_files_table["Layer0"] end

    local ret = cs.assist:CreateIsSuccess()

    for _, v in ipairs(files_table) do
        ret.b = cs.bgm:Load("../LayerX_CommonData/bgm/" .. v.file, v.volume)
    end

    return ret.is_success
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
