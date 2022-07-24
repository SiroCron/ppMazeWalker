-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      table.xxx に追加する関数
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local m = _G.table

m.deepcopy = function(_src)
    if type(_src) ~= "table" then return _src end -- テーブル以外はそのまま(値型)返す

    local dst = {}
    for key, value in next, _src, nil do
        dst[key] = m.deepcopy(value)
    end

    return dst
end

m.sorted_keys = function(_t)
    if type(_t) ~= "table" then return nil end

    local keys = {}
    for k, _ in pairs(_t) do table.insert(keys, k) end

    table.sort(keys, function(_k1, _k2) return _k1 < _k2 end)

    return keys
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
