-- ////////////////////////////////////////////////////////////////////////////
-- ///
-- //
-- /
--      単純なアニメーション
--                                                                            /
--                                                                           //
--                                                                          ///
-- ////////////////////////////////////////////////////////////////////////////

local m = {
    co_table = {},
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

-- ============================================================================
-- アニメーションの実動作呼出し
--
-- ・xxxxStart()で開始した co_name のアニメーションを動作させる
-- ・false が返ってきたらアニメーション終了(したところ),もしくは co_name が nil
--
m.Exec = function(_co_name, _si)
    local co = m.co_table[_co_name]

    if co == nil then -- 生成されてるよね？
        return log:Error("(Lib)SimpleAnimation.Exec",
            "存在しないコルーチンが指定されています. co_name=" .. _co_name)
    end

    local co_state, ret_code = coroutine.resume(co, _si)
    local ret = co_state and ret_code

    if ret == false then -- 異常終了またはアニメーション終了
        m.co_table[_co_name] = nil -- クリアしておく
    end

    return ret
end

-- ============================================================================
-- SpriteObjectの移動
--
m.MoveSpriteStart = function(_co_name, _sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)
    m.co_table[_co_name] = m.GenMoveSpriteCoroutine()

    local co_state, ret_code = coroutine.resume(m.co_table[_co_name], _sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)

    return co_state and ret_code -- 必ず true, true
end

-- ============================================================================
-- SpriteObjectの回転
--

m.RotateSpriteStart = function(_co_name, _sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)
    m.co_table[_co_name] = m.GenRotateSpriteCoroutine()

    local co_state, ret_code = coroutine.resume(m.co_table[_co_name], _sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)

    return co_state and ret_code -- 必ず true, true
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

m.GenMoveSpriteCoroutine = function()
    return coroutine.create(function(_sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)
        local spr_pos = _sprite_obj:GetPosition()
        local cam_pos = cs.camera:GetPosition()
        local past_sec = 0.0

        coroutine.yield(true) -- Init時

        while past_sec < _sec do
            local si = coroutine.yield(true) -- 初回は何もすることなく終わる
            past_sec = past_sec + si.delta_time
            if _sec < past_sec then past_sec = _sec end

            local perc = past_sec / _sec
            local mx, my, mz = _dx * perc, _dy * perc, _dz * perc
            _sprite_obj:SetPosition(spr_pos.x + mx, spr_pos.y + my, spr_pos.z + mz)
            if _camera_sync then
                cs.camera:SetPosition(cam_pos.x + mx, cam_pos.y + my, cam_pos.z + mz)
            end
        end

        return false -- 終了
    end)
end

m.GenRotateSpriteCoroutine = function()
    return coroutine.create(function(_sprite_obj, _camera_sync, _dx, _dy, _dz, _sec)
        local spr_rot = _sprite_obj:GetRotation()
        local cam_rot = cs.camera:GetRotation()
        local past_sec = 0.0

        coroutine.yield(true) -- Init時

        while past_sec < _sec do
            local si = coroutine.yield(true) -- 初回は何もすることなく終わる
            past_sec = past_sec + si.delta_time
            if _sec < past_sec then past_sec = _sec end

            local perc = past_sec / _sec
            local mx, my, mz = _dx * perc, _dy * perc, _dz * perc
            _sprite_obj:SetRotation(spr_rot.x + mx, spr_rot.y + my, spr_rot.z + mz)
            if _camera_sync then
                cs.camera:SetRotation(cam_rot.x + mx, cam_rot.y + my, cam_rot.z + mz)
            end
        end

        return false -- 終了
    end)
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
