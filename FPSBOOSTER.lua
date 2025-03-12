---@diagnostic disable: undefined-global
local ffi = require 'ffi'
local crr_t = ffi.typeof('void*(__thiscall*)(void*)')
local cr_t = ffi.typeof('void*(__thiscall*)(void*)')
local gm_t = ffi.typeof('const void*(__thiscall*)(void*)')
local gsa_t = ffi.typeof('int(__fastcall*)(void*, void*, int)')

ffi.cdef[[
    struct animation_layer_t {
        char  pad_0000[20];
        uint32_t m_nOrder; //0x0014
        uint32_t m_nSequence; //0x0018
        float m_flPrevCycle; //0x001C
        float m_flWeight; //0x0020
        float m_flWeightDeltaRate; //0x0024
        float m_flPlaybackRate; //0x0028
        float m_flCycle; //0x002C
        void *m_pOwner; //0x0030 // player's thisptr
        char  pad_0038[4]; //0x0034
    };

    struct animstate_t1 { 
        char pad[3];
        char m_bForceWeaponUpdate; //0x4
        char pad1[91];
        void* m_pBaseEntity; //0x60
        void* m_pActiveWeapon; //0x64
        void* m_pLastActiveWeapon; //0x68
        float m_flLastClientSideAnimationUpdateTime; //0x6C
        int m_iLastClientSideAnimationUpdateFramecount; //0x70
        float m_flAnimUpdateDelta; //0x74
        float m_flEyeYaw; //0x78
        float m_flPitch; //0x7C
        float m_flGoalFeetYaw; //0x80
        float m_flCurrentFeetYaw; //0x84
        float m_flCurrentTorsoYaw; //0x88
        float m_flUnknownVelocityLean; //0x8C
        float m_flLeanAmount; //0x90
        char pad2[4];
        float m_flFeetCycle; //0x98
        float m_flFeetYawRate; //0x9C
        char pad3[4];
        float m_fDuckAmount; //0xA4
        float m_fLandingDuckAdditiveSomething; //0xA8
        char pad4[4];
        float m_vOriginX; //0xB0
        float m_vOriginY; //0xB4
        float m_vOriginZ; //0xB8
        float m_vLastOriginX; //0xBC
        float m_vLastOriginY; //0xC0
        float m_vLastOriginZ; //0xC4
        float m_vVelocityX; //0xC8
        float m_vVelocityY; //0xCC
        char pad5[4];
        float m_flUnknownFloat1; //0xD4
        char pad6[8];
        float m_flUnknownFloat2; //0xE0
        float m_flUnknownFloat3; //0xE4
        float m_flUnknown; //0xE8
        float m_flSpeed2D; //0xEC
        float m_flUpVelocity; //0xF0
        float m_flSpeedNormalized; //0xF4
        float m_flFeetSpeedForwardsOrSideWays; //0xF8
        float m_flFeetSpeedUnknownForwardOrSideways; //0xFC
        float m_flTimeSinceStartedMoving; //0x100
        float m_flTimeSinceStoppedMoving; //0x104
        bool m_bOnGround; //0x108
        bool m_bInHitGroundAnimation; //0x109
        float m_flTimeSinceInAir; //0x10A
        float m_flLastOriginZ; //0x10E
        float m_flHeadHeightOrOffsetFromHittingGroundAnimation; //0x112
        float m_flStopToFullRunningFraction; //0x116
        char pad7[4]; //0x11A
        float m_flMagicFraction; //0x11E
        char pad8[60]; //0x122
        float m_flWorldForce; //0x15E
        char pad9[462]; //0x162
        float m_flMaxYaw; //0x334
    };
]]

local classptr = ffi.typeof('void***')
local rawientitylist = client.create_interface('client_panorama.dll', 'VClientEntityList003') or error('VClientEntityList003 wasn\'t found', 2)
local ientitylist = ffi.cast(classptr, rawientitylist) or error('rawientitylist is nil', 2)
local get_client_networkable = ffi.cast('void*(__thiscall*)(void*, int)', ientitylist[0][0]) or error('get_client_networkable_t is nil', 2)
local get_client_entity = ffi.cast('void*(__thiscall*)(void*, int)', ientitylist[0][3]) or error('get_client_entity is nil', 2)

local rawivmodelinfo = client.create_interface('engine.dll', 'VModelInfoClient004')
local ivmodelinfo = ffi.cast(classptr, rawivmodelinfo) or error('rawivmodelinfo is nil', 2)
local get_studio_model = ffi.cast('void*(__thiscall*)(void*, const void*)', ivmodelinfo[0][32])

local seq_activity_sig = client.find_signature('client_panorama.dll', '\x55\x8B\xEC\x53\x8B\x5D\x08\x56\x8B\xF1\x83')

local FL_ONGROUND = bit.lshift(1, 0)

local cache = {
    entities = {},
    last_update_time = 0,
    update_interval = 0.001,
    visible_players = {}
}

function get_model(b)
    if b then
        b = ffi.cast(classptr, b)
        local c = ffi.cast(crr_t, b[0][0])
        local d = c(b) or error('error getting client unknown', 2)
        if d then 
            d = ffi.cast(classptr, d)
            local e = ffi.cast(cr_t, d[0][5])(d) or error('error getting client renderable', 2)
            if e then 
                e = ffi.cast(classptr, e)
                return ffi.cast(gm_t, e[0][8])(e) or error('error getting model_t', 2)
            end 
        end
    end
end

function get_sequence_activity(b, c, d)
    b = ffi.cast(classptr, b)
    local e = get_studio_model(ivmodelinfo, get_model(c))
    if e == nil then return -1 end
    local f = ffi.cast(gsa_t, seq_activity_sig)
    return f(b, e, d)
end

function get_anim_layer(b, c)
    c = c or 1
    b = ffi.cast(classptr, b)
    return ffi.cast('struct animation_layer_t**', ffi.cast('char*', b)+0x2990)[0][c]
end

function get_anim_state(entity_ptr)
    if entity_ptr then
        entity_ptr = ffi.cast(classptr, entity_ptr)
        return ffi.cast('struct animstate_t1*', ffi.cast('char*', entity_ptr) + 0x3914)
    end
    return nil
end

local Tools = {}

Tools.Clamp = function(n, mn, mx)
    if n > mx then
        return mx
    elseif n < mn then
        return mn
    else
        return n
    end
end

Tools.YawTo360 = function(yaw)
    if yaw < 0 then
        return 360 + yaw
    end
    return yaw
end

Tools.YawTo180 = function(yaw)
    yaw = (yaw + 180) % 360 - 180
    return yaw
end

Tools.YawNormalizer = function(yaw)
    if yaw > 360 then
        return yaw - 360
    elseif yaw < 0 then
        return 360 + yaw
    end
    return yaw
end

Tools.Distance = function(x1, y1, z1, x2, y2, z2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2)
end

Tools.IsMovingTowards = function(player_x, player_y, player_vel_x, player_vel_y, local_x, local_y)
    local dx = local_x - player_x
    local dy = local_y - player_y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist == 0 then return false end
    
    dx = dx / dist
    dy = dy / dist
    
    local dot = player_vel_x * dx + player_vel_y * dy
    
    return dot > 0
end

Tools.VectorDistance = function(v1, v2)
    return math.sqrt((v2.x - v1.x)^2 + (v2.y - v1.y)^2 + (v2.z - v1.z)^2)
end

Tools.VectorNormalize = function(v)
    local length = math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
    if length == 0 then return {x = 0, y = 0, z = 0} end
    return {x = v.x / length, y = v.y / length, z = v.z / length}
end

Tools.VectorAngles = function(forward)
    local tmp, yaw, pitch
    
    if forward.y == 0 and forward.x == 0 then
        yaw = 0
        if forward.z > 0 then
            pitch = 270
        else
            pitch = 90
        end
    else
        yaw = math.deg(math.atan2(forward.y, forward.x))
        
        tmp = math.sqrt(forward.x * forward.x + forward.y * forward.y)
        pitch = math.deg(math.atan2(-forward.z, tmp))
    end
    
    return {pitch = pitch, yaw = yaw}
end

local menu_color_picker = ui.new_color_picker("Rage", "Other", "Menu accent color", 160, 32, 240, 255)
local function get_menu_color()
    local r, g, b, a = ui.get(menu_color_picker)
    return r, g, b
end

local MenuV = {}
MenuV["Anti-Aim Correction"] = ui.reference("Rage", "Other", "Anti-Aim Correction")
MenuV["ResetAll"] = ui.reference("Players", "Players", "Reset All")
MenuV["ForceBodyYaw"] = ui.reference("Players", "Adjustments", "Force Body Yaw")
MenuV["CorrectionActive"] = ui.reference("Players", "Adjustments", "Correction Active")
local MenuC = {}
MenuC["header1"] = ui.new_label("Rage", "Other", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
local r, g, b = get_menu_color()
MenuC["header2"] = ui.new_label("Rage", "Other", string.format("\a%02X%02X%02XFF魔 Angel's Sigma Resolver 魔", r, g, b))
MenuC["Enable"] = ui.new_checkbox("Rage", "Other", string.format("Enable \a%02X%02X%02XFF⛧Resolver⛧", r, g, b))
MenuC["DebugLogs"] = ui.new_checkbox("Rage", "Other", "> Debug " .. string.format("\a%02X%02X%02XFFLogs", r, g, b))
MenuC["Flag"] = ui.new_checkbox("Rage", "Other", "> Resolver " .. string.format("\a%02X%02X%02XFFFlags", r, g, b))
MenuC["ForceBacktrackHit"] = ui.new_checkbox("Rage", "Other", "> Force " .. string.format("\a%02X%02X%02XFFBacktrack Hit", r, g, b))
MenuC["spacer1"] = ui.new_label("Rage", "Other", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
MenuC["header3"] = ui.new_label("Rage", "Other", string.format("\a%02X%02X%02XFF◈ State Detection ◈", r, g, b))
MenuC["AutoOffsets"] = ui.new_checkbox("Rage", "Other", string.format("⚙ Auto-Determine \a%02X%02X%02XFFOffsets", r, g, b))
MenuC["ShowOffsetData"] = ui.new_checkbox("Rage", "Other", "Show Offset " .. string.format("\a%02X%02X%02XFFLearning Data", r, g, b))
MenuC["AdaptiveSpeed"] = ui.new_slider("Rage", "Other", "⟳ Learning " .. string.format("\a%02X%02X%02XFFSpeed", r, g, b), 1, 100, 50, true, "%")
MenuC["AirResolve"] = ui.new_checkbox("Rage", "Other", string.format("➜ Air \a%02X%02X%02XFFState Resolver", r, g, b))
MenuC["AirYawOffset"] = ui.new_slider("Rage", "Other", "↔ Air Offset", -58, 58, 35, true, "°")
MenuC["CrouchResolve"] = ui.new_checkbox("Rage", "Other", string.format("➜ Crouch \a%02X%02X%02XFFState Resolver", r, g, b))
MenuC["CrouchYawOffset"] = ui.new_slider("Rage", "Other", "↔ Crouch Offset", -58, 58, -35, true, "°")
MenuC["AirCrouchResolve"] = ui.new_checkbox("Rage", "Other", string.format("➜ Air+Crouch \a%02X%02X%02XFFState Resolver", r, g, b))
MenuC["BhopResolve"] = ui.new_checkbox("Rage", "Other", string.format("➜ Anti Rush (Zeus DT) \a%02X%02X%02XFFResolver", r, g, b))
MenuC["BhopYawOffset"] = ui.new_slider("Rage", "Other", "↔ Bhop Offset", -58, 58, 0, true, "°")
MenuC["spacer2"] = ui.new_label("Rage", "Other", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
MenuC["header4"] = ui.new_label("Rage", "Other", string.format("\a%02X%02X%02XFF⚙ Performance Optimization ⚙", r, g, b))
MenuC["FastResolve"] = ui.new_checkbox("Rage", "Other", string.format("Fast \a%02X%02X%02XFFResolver", r, g, b))
MenuC["UpdateFrequency"] = ui.new_slider("Rage", "Other", "⏱ Update " .. string.format("\a%02X%02X%02XFFRate", r, g, b), 1, 128, 64, true, "tick")
MenuC["PredictiveAim"] = ui.new_checkbox("Rage", "Other", string.format("Predictive \a%02X%02X%02XFFAim", r, g, b))
MenuC["PredictionStrength"] = ui.new_slider("Rage", "Other", "Prediction " .. string.format("\a%02X%02X%02XFFStrength", r, g, b), 0, 100, 50, true, "%")
MenuC["PrioritizeVisible"] = ui.new_checkbox("Rage", "Other", string.format("Prioritize \a%02X%02X%02XFFVisible Players", r, g, b))
MenuC["spacer3"] = ui.new_label("Rage", "Other", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
MenuC["spacer4"] = ui.new_label("Rage", "Other", string.format("Join our community: \a%02X%02X%02XFFdiscord.gg/FepGKGmcuZ", r, g, b))

local function update_menu_colors()
    local r, g, b = get_menu_color()
    
    ui.set(MenuC["header2"], string.format("\a%02X%02X%02XFF魔 Angel's Sigma Resolver 魔", r, g, b))
    ui.set(MenuC["Enable"], string.format("Enable \a%02X%02X%02XFF⛧Resolver⛧", r, g, b))
    ui.set(MenuC["DebugLogs"], string.format("Debug \a%02X%02X%02XFFLogs", r, g, b))
    ui.set(MenuC["Flag"], string.format("Resolver \a%02X%02X%02XFFFlags", r, g, b))
    ui.set(MenuC["ForceBacktrackHit"], string.format("⟲ Force \a%02X%02X%02XFFBacktrack Hit", r, g, b))
    
    ui.set(MenuC["header3"], string.format("\a%02X%02X%02XFFState Detection", r, g, b))
    ui.set(MenuC["AutoOffsets"], string.format("⚙ Auto-Determine \a%02X%02X%02XFFOffsets", r, g, b))
    ui.set(MenuC["ShowOffsetData"], string.format("⊞ Show Offset \a%02X%02X%02XFFLearning Data", r, g, b))
    ui.set(MenuC["AdaptiveSpeed"], string.format("⟳ Learning \a%02X%02X%02XFFSpeed", r, g, b))
    
    ui.set(MenuC["AirResolve"], string.format("➜ Air \a%02X%02X%02XFFState Resolver", r, g, b))
    ui.set(MenuC["CrouchResolve"], string.format("➜ Crouch \a%02X%02X%02XFFState Resolver", r, g, b))
    ui.set(MenuC["AirCrouchResolve"], string.format("➜ Air+Crouch \a%02X%02X%02XFFState Resolver", r, g, b))
    ui.set(MenuC["BhopResolve"], string.format("➜ Anti Rush (Zeus DT) \a%02X%02X%02XFFResolver", r, g, b))
    
    ui.set(MenuC["header4"], string.format("\a%02X%02X%02XFF⚙ Performance Optimization ⚙", r, g, b))
    ui.set(MenuC["FastResolve"], string.format("Fast \a%02X%02X%02XFFResolver", r, g, b))
    ui.set(MenuC["UpdateFrequency"], string.format("⏱ Update \a%02X%02X%02XFFRate", r, g, b))
    ui.set(MenuC["PredictiveAim"], string.format("Predictive \a%02X%02X%02XFFAim", r, g, b))
    ui.set(MenuC["PredictionStrength"], string.format("Prediction \a%02X%02X%02XFFStrength", r, g, b))
    ui.set(MenuC["PrioritizeVisible"], string.format("Prioritize \a%02X%02X%02XFFVisible Players", r, g, b))
    
    ui.set(MenuC["spacer4"], string.format("Join our community: \a%02X%02X%02XFFdiscord.gg/FepGKGmcuZ", r, g, b))
end

local AutoOffsets = {
    air = { values = {}, current = 35 },
    crouch = { values = {}, current = -35 },
    airCrouch = { values = {}, current = 0 },
    bhopRush = { values = {}, current = 0 },
}

local PlayerOptimalOffsets = {}

function InitPlayerOptimalOffsets(player)
    if not PlayerOptimalOffsets[player] then
        PlayerOptimalOffsets[player] = {
            air = { sum = 0, count = 0, current = AutoOffsets.air.current },
            crouch = { sum = 0, count = 0, current = AutoOffsets.crouch.current },
            airCrouch = { sum = 0, count = 0, current = AutoOffsets.airCrouch.current },
            bhopRush = { sum = 0, count = 0, current = AutoOffsets.bhopRush.current },
            lastState = "",
            lastOffset = 0
        }
    end
    return PlayerOptimalOffsets[player]
end

function UpdateOffsetMenus()
    ui.set(MenuC["AirYawOffset"], AutoOffsets.air.current)
    ui.set(MenuC["CrouchYawOffset"], AutoOffsets.crouch.current)
    ui.set(MenuC["BhopYawOffset"], AutoOffsets.bhopRush.current)
end

function CalculateOptimalOffset(values, min_val, max_val)
    if #values == 0 then return (min_val + max_val) / 2 end
    
    local sum_weight = 0
    local sum_weighted_value = 0
    
    for i, entry in ipairs(values) do
        local weight = math.pow(i, 1.5)
        sum_weighted_value = sum_weighted_value + (entry.value * weight)
        sum_weight = sum_weight + weight
    end
    
    if sum_weight == 0 then return (min_val + max_val) / 2 end
    return sum_weighted_value / sum_weight
end

function UpdateGlobalAutoOffsets()
    local states = {"air", "crouch", "airCrouch", "bhopRush"}
    
    for _, state in ipairs(states) do
        AutoOffsets[state].values = {}
        
        for player, offsets in pairs(PlayerOptimalOffsets) do
            if offsets[state].count > 0 then
                local avg = offsets[state].sum / offsets[state].count
                table.insert(AutoOffsets[state].values, {
                    value = avg,
                    timestamp = globals.realtime()
                })
            end
        end
        
        if #AutoOffsets[state].values > 0 then
            local min_val = -58
            local max_val = 58
            AutoOffsets[state].current = Tools.Clamp(
                CalculateOptimalOffset(AutoOffsets[state].values, min_val, max_val),
                min_val, max_val
            )
        end
    end
    
    if ui.get(MenuC["AutoOffsets"]) then
        UpdateOffsetMenus()
    end
end

function Enable_Update()
    local enabled = ui.get(MenuC["Enable"])
    local r, g, b = get_menu_color()

    ui.set(MenuC["header2"], string.format("\a%02X%02X%02XFF魔 Angel's Sigma Resolver 魔", r, g, b))
    ui.set(MenuC["header3"], string.format("\a%02X%02X%02XFF◈ State Detection ◈", r, g, b))
    ui.set(MenuC["header4"], string.format("\a%02X%02X%02XFF⚙ Performance Optimization ⚙", r, g, b))
    
    ui.set_visible(MenuC["header1"], enabled)
    ui.set_visible(MenuC["header2"], enabled)
    ui.set_visible(MenuC["DebugLogs"], enabled)
    ui.set_visible(MenuC["Flag"], enabled)
    ui.set_visible(MenuC["ForceBacktrackHit"], enabled)
    
    ui.set_visible(MenuC["spacer1"], enabled)
    ui.set_visible(MenuC["header3"], enabled)
    
    ui.set_visible(MenuC["AutoOffsets"], enabled)
    ui.set_visible(MenuC["ShowOffsetData"], enabled and ui.get(MenuC["AutoOffsets"]))
    ui.set_visible(MenuC["AdaptiveSpeed"], enabled and ui.get(MenuC["AutoOffsets"]))
    
    ui.set_visible(MenuC["AirResolve"], enabled)
    ui.set_visible(MenuC["CrouchResolve"], enabled)
    ui.set_visible(MenuC["AirCrouchResolve"], enabled)
    ui.set_visible(MenuC["BhopResolve"], enabled)
    
    local manual_visible = enabled and not ui.get(MenuC["AutoOffsets"])
    ui.set_visible(MenuC["AirYawOffset"], manual_visible and ui.get(MenuC["AirResolve"]))
    ui.set_visible(MenuC["CrouchYawOffset"], manual_visible and ui.get(MenuC["CrouchResolve"]))
    ui.set_visible(MenuC["BhopYawOffset"], manual_visible and ui.get(MenuC["BhopResolve"]))
    
    ui.set_visible(MenuC["spacer2"], enabled)
    ui.set_visible(MenuC["header4"], enabled)
    ui.set_visible(MenuC["FastResolve"], enabled)
    ui.set_visible(MenuC["PredictiveAim"], enabled)
    ui.set_visible(MenuC["PrioritizeVisible"], enabled)
    
    ui.set_visible(MenuC["UpdateFrequency"], enabled and ui.get(MenuC["FastResolve"]))
    ui.set_visible(MenuC["PredictionStrength"], enabled and ui.get(MenuC["PredictiveAim"]))
    
    ui.set_visible(MenuC["spacer3"], enabled)
    ui.set_visible(MenuC["spacer4"], enabled)
    
    ui.set_visible(MenuV["ForceBodyYaw"], not enabled)
    ui.set_visible(MenuV["CorrectionActive"], not enabled)
    
    if not enabled then
        ui.set(MenuV["ResetAll"], true)
    end
end

Enable_Update()

ui.set_callback(menu_color_picker, function()
    if ui.get(MenuC["Enable"]) then
        Enable_Update()
    end
end)

ui.set_callback(MenuC["Enable"], Enable_Update)
ui.set_callback(MenuC["AirResolve"], Enable_Update)
ui.set_callback(MenuC["CrouchResolve"], Enable_Update)
ui.set_callback(MenuC["BhopResolve"], Enable_Update)
ui.set_callback(MenuC["FastResolve"], Enable_Update)
ui.set_callback(MenuC["PredictiveAim"], Enable_Update)
ui.set_callback(MenuC["AutoOffsets"], Enable_Update)

local ResolvedState = {}
local ResolvedYaw = {}
local PlayerStateData = {}
local ResolveHistory = {}
local PredictedPositions = {}

function InitPlayerStateData(player)
    if not PlayerStateData[player] then
        PlayerStateData[player] = {
            onGroundTime = 0,
            inAirTime = 0,
            jumpCount = 0,
            lastJumpTime = 0,
            lastPos = {x = 0, y = 0, z = 0},
            lastVelocity = {x = 0, y = 0, z = 0},
            isInAir = false,
            isCrouching = false,
            isAirCrouching = false,
            isBhopRushing = false,
            lastGroundState = true,
            lastUpdateTime = 0,
            isVisible = false,
            inCrosshair = false,
            lastVisibleTime = 0,
            lastResolvedValues = {},
            resolveConfidence = 0
        }
    end
    return PlayerStateData[player]
end

function InitResolveHistory(player)
    if not ResolveHistory[player] then
        ResolveHistory[player] = {
            hits = 0,
            misses = 0,
            total_shots = 0,
            last_hit_yaw = 0,
            last_hit_state = "",
            successful_yaws = {},
            failed_yaws = {}
        }
    end
    return ResolveHistory[player]
end

function IsPlayerTargetable(player)
    local local_player = entity.get_local_player()
    if not local_player then return false end
    for i = 0, 18 do
        local hitbox_pos = {entity.hitbox_position(player, i)}
        if #hitbox_pos == 3 then
            if client.visible(hitbox_pos[1], hitbox_pos[2], hitbox_pos[3]) then
                return true
            end
        end
    end
    return false
end

function GetPlayerVelocity(player)
    local vel_x = entity.get_prop(player, "m_vecVelocity[0]") or 0
    local vel_y = entity.get_prop(player, "m_vecVelocity[1]") or 0
    local vel_z = entity.get_prop(player, "m_vecVelocity[2]") or 0
    return {x = vel_x, y = vel_y, z = vel_z}
end

function PredictPlayerPosition(player, prediction_time)
    local origin = {entity.get_origin(player)}
    if not origin or #origin < 3 then return nil end
    
    local velocity = GetPlayerVelocity(player)

    local predicted = {
        x = origin[1] + velocity.x * prediction_time,
        y = origin[2] + velocity.y * prediction_time,
        z = origin[3] + velocity.z * prediction_time
    }
    
    return predicted
end

function DetectPlayerStates(player, playerEntity)
    local state = InitPlayerStateData(player)
    local curTime = globals.curtime()
    
    if ui.get(MenuC["FastResolve"]) then
        local update_rate = 1.0 / ui.get(MenuC["UpdateFrequency"])
        if curTime - state.lastUpdateTime < update_rate then
            return state
        end
    end
    
    local animState = get_anim_state(playerEntity)
    if not animState then return state end
    
    local flags = entity.get_prop(player, "m_fFlags") or 0
    local velocity = {
        x = animState.m_vVelocityX,
        y = animState.m_vVelocityY,
        z = animState.m_flUpVelocity
    }
    local speed2D = animState.m_flSpeed2D
    local onGround = bit.band(flags, FL_ONGROUND) ~= 0
    
    local origin = {entity.get_origin(player)}
    local pos = {x = origin[1], y = origin[2], z = origin[3]}
    
    state.isVisible = IsPlayerTargetable(player)
    if state.isVisible then
        state.lastVisibleTime = curTime
        if ui.get(MenuC["PrioritizeVisible"]) then
            cache.visible_players[player] = true
        end
    elseif cache.visible_players[player] and curTime - state.lastVisibleTime > 1.0 then
        cache.visible_players[player] = nil
    end
    
    state.isInAir = not onGround
    
    state.isAirCrouching = state.isInAir and state.isCrouching
    

    if onGround ~= state.lastGroundState then
        if not onGround and state.lastGroundState then
            state.jumpCount = state.jumpCount + 1
            state.lastJumpTime = curTime
        end
        state.lastGroundState = onGround
    end
    
    if curTime - state.lastJumpTime > 0.7 then
        state.jumpCount = 0
    end
    
    local localPlayer = entity.get_local_player()
    local localOrigin = {entity.get_origin(localPlayer)}
    
    local isMovingTowards = Tools.IsMovingTowards(
        pos.x, pos.y, 
        velocity.x, velocity.y,
        localOrigin[1], localOrigin[2]
    )
    
    local distanceToLocal = Tools.Distance(
        pos.x, pos.y, pos.z,
        localOrigin[1], localOrigin[2], localOrigin[3]
    )
    
    state.isBhopRushing = state.jumpCount >= 2 and 
    isMovingTowards and 
    speed2D > 100 and 
    distanceToLocal < 800
    
    if ui.get(MenuC["PredictiveAim"]) then
        local prediction_time = 0.05 * (ui.get(MenuC["PredictionStrength"]) / 100)
        PredictedPositions[player] = PredictPlayerPosition(player, prediction_time)
    end
    
    state.lastPos = pos
    state.lastVelocity = velocity
    state.lastUpdateTime = curTime
    
    return state
end

function AnalyzeResolveSuccess(player, hit_success, headshot)
    local history = InitResolveHistory(player)
    local state = PlayerStateData[player]
    local offsets = InitPlayerOptimalOffsets(player)
    local current_yaw = ResolvedYaw[player] or 0
    local lower_body_yaw = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    
    local applied_offset = Tools.YawTo180(current_yaw - lower_body_yaw)
    
    history.total_shots = history.total_shots + 1
    
    local state_string = "Default"
    if state.isBhopRushing then state_string = "bhopRush"
    elseif state.isAirCrouching then state_string = "airCrouch"
    elseif state.isInAir then state_string = "air"
    elseif state.isCrouching then state_string = "crouch"
    end
    
    offsets.lastState = state_string
    offsets.lastOffset = applied_offset
    
    if hit_success then
        history.hits = history.hits + 1
        history.last_hit_yaw = current_yaw
        history.last_hit_state = state_string
        
        local weight = headshot and 2.0 or 1.0
        
        if offsets[state_string] then
            offsets[state_string].sum = offsets[state_string].sum + (applied_offset * weight)
            offsets[state_string].count = offsets[state_string].count + weight
            offsets[state_string].current = offsets[state_string].sum / offsets[state_string].count
        end
        
        table.insert(history.successful_yaws, {
            yaw = current_yaw,
            offset = applied_offset,
            state = state_string,
            time = globals.realtime(),
            headshot = headshot
        })
        
        state.resolveConfidence = math.min(100, state.resolveConfidence + (headshot and 20 or 10))
        
        UpdateGlobalAutoOffsets()
    else
        history.misses = history.misses + 1
        
        table.insert(history.failed_yaws, {
            yaw = current_yaw,
            offset = applied_offset,
            state = state_string,
            time = globals.realtime()
        })
        
        state.resolveConfidence = math.max(0, state.resolveConfidence - 20)

        local learning_speed = ui.get(MenuC["AdaptiveSpeed"]) / 100
        if offsets[state_string] and offsets[state_string].count > 0 then
            local adjustment = -applied_offset * 0.2 * learning_speed
            offsets[state_string].sum = offsets[state_string].sum + adjustment
            offsets[state_string].count = offsets[state_string].count + 0.2
            offsets[state_string].current = offsets[state_string].sum / offsets[state_string].count
        end
    end
    
    while #history.successful_yaws > 10 do
        table.remove(history.successful_yaws, 1)
    end
    while #history.failed_yaws > 10 do
        table.remove(history.failed_yaws, 1)
    end
end

function GetOptimalOffset(player, state_string)
    if ui.get(MenuC["AutoOffsets"]) then
        local player_offsets = PlayerOptimalOffsets[player]
        if player_offsets and player_offsets[state_string] and player_offsets[state_string].count > 0 then
            return player_offsets[state_string].current
        end
        
        if AutoOffsets[state_string] then
            return AutoOffsets[state_string].current
        end
    end
    
    if state_string == "air" then return ui.get(MenuC["AirYawOffset"])
    elseif state_string == "crouch" then return ui.get(MenuC["CrouchYawOffset"])
    elseif state_string == "bhopRush" then return ui.get(MenuC["BhopYawOffset"])
    else return 0 end
end

function FastResolver()
    if not ui.get(MenuC["Enable"]) then
        return
    end

    local current_time = globals.realtime()
    local tick_count = globals.tickcount()
    
    local should_full_update = true
    if ui.get(MenuC["FastResolve"]) then
        local update_rate = ui.get(MenuC["UpdateFrequency"])
        should_full_update = tick_count % math.ceil(64 / update_rate) == 0
    end
    
    local visible_players = {}
    local other_players = {}
    
    local all_players = entity.get_players(true)
    for i, player in pairs(all_players) do
        if cache.visible_players[player] then
            table.insert(visible_players, player)
        else
            table.insert(other_players, player)
        end
    end

    local players_to_process = {}
    for _, player in ipairs(visible_players) do
        table.insert(players_to_process, player)
    end
    for _, player in ipairs(other_players) do
        table.insert(players_to_process, player)
    end
    
    for _, player in ipairs(players_to_process) do
        local playerEntity = get_client_entity(ientitylist, player)
        if playerEntity then
            plist.set(player, "Force Body Yaw", true)
            
            local lower_body_yaw = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
            
            local eye_angles = entity.get_prop(player, "m_angEyeAngles")
            local eye_pitch, eye_yaw = 0, 0
            if type(eye_angles) == "table" then
                eye_pitch = eye_angles[1] or 0
                eye_yaw = eye_angles[2] or 0
            else
                eye_yaw = eye_angles or 0
            end
            
            if eye_pitch < -89 or eye_pitch > 89 then
                plist.set(player, "Force Pitch", true)
                plist.set(player, "Force Pitch Value", 0)
            else
                plist.set(player, "Force Pitch", false)
            end
            
            if ui.get(MenuC["ForceBacktrackHit"]) then
                plist.set(player, "Force Backtrack", true)
            end
            
            if should_full_update or cache.visible_players[player] then
                local playerState = DetectPlayerStates(player, playerEntity)
                local diff = Tools.YawTo180(eye_yaw - lower_body_yaw)
                
                local resolved_yaw = 0
                local state_string = "Default"
                
                local history = ResolveHistory[player]
                local use_history = false
                
                if history and history.hits > 0 and playerState.resolveConfidence > 30 then
                    for _, entry in ipairs(history.successful_yaws) do
                        if entry.state == state_string and current_time - entry.time < 5.0 then
                            resolved_yaw = entry.yaw
                            use_history = true
                            break
                        end
                    end
                end
                
                if not use_history then
                    if playerState.isBhopRushing and ui.get(MenuC["BhopResolve"]) then
                        local offset = GetOptimalOffset(player, "bhopRush")
                        resolved_yaw = eye_yaw + offset
                        state_string = "BhopRush"
                    elseif playerState.isAirCrouching and ui.get(MenuC["AirCrouchResolve"]) then
                        local airOffset = GetOptimalOffset(player, "air") * 0.5
                        local crouchOffset = GetOptimalOffset(player, "crouch") * 0.5
                        resolved_yaw = lower_body_yaw + airOffset + crouchOffset
                        state_string = "AirCrouch"
                    elseif playerState.isInAir and ui.get(MenuC["AirResolve"]) then
                        local offset = GetOptimalOffset(player, "air")
                        resolved_yaw = lower_body_yaw + offset
                        state_string = "Air"
                    elseif playerState.isCrouching and ui.get(MenuC["CrouchResolve"]) then
                        local offset = GetOptimalOffset(player, "crouch")
                        resolved_yaw = lower_body_yaw + offset
                        state_string = "Crouch"
                    else
                        if math.abs(diff) < 15 then
                            resolved_yaw = eye_yaw
                        else
                            local jitter = math.sin(current_time * 20) * math.abs(diff) * 0.5
                            if diff > 0 then
                                resolved_yaw = lower_body_yaw + jitter
                            else
                                resolved_yaw = lower_body_yaw - jitter
                            end
                        end
                    end
                end
                
                resolved_yaw = Tools.YawTo180(resolved_yaw)
                ResolvedYaw[player] = resolved_yaw

                ResolvedState[player] = state_string
                
                plist.set(player, "force body yaw value", resolved_yaw)
                
                if not playerState.lastResolvedValues then
                    playerState.lastResolvedValues = {}
                end
                
                table.insert(playerState.lastResolvedValues, resolved_yaw)
                while #playerState.lastResolvedValues > 5 do
                    table.remove(playerState.lastResolvedValues, 1)
                end
                
                if ui.get(MenuC["DebugLogs"]) then
                    client.log(string.format("Resolver | %s [%s]: LBY: %.2f, EyeYaw: %.2f, Diff: %.2f, Resolved: %.2f, Conf: %d%%", 
                        entity.get_player_name(player) or "unknown", 
                        state_string,
                        lower_body_yaw, eye_yaw, diff, resolved_yaw,
                        playerState.resolveConfidence))
                end
            else
                if ResolvedYaw[player] then
                    plist.set(player, "force body yaw value", ResolvedYaw[player])
                end
            end
        end
    end
end

client.set_event_callback("bullet_impact", function(e)
    if not ui.get(MenuC["Enable"]) then return end
    
    local shooter = client.userid_to_entindex(e.userid)
    if not shooter or shooter ~= entity.get_local_player() then return end
    
    local closest_player = nil
    local closest_dist = 100
    
    local impact_pos = {e.x, e.y, e.z}
    local shooters_pos = {entity.get_origin(shooter)}
    
    local ray_dir = {
        x = impact_pos[1] - shooters_pos[1],
        y = impact_pos[2] - shooters_pos[2],
        z = impact_pos[3] - shooters_pos[3]
    }
    
    local len = math.sqrt(ray_dir.x^2 + ray_dir.y^2 + ray_dir.z^2)
    if len > 0 then
        ray_dir.x = ray_dir.x / len
        ray_dir.y = ray_dir.y / len
        ray_dir.z = ray_dir.z / len
    end
    
    local players = entity.get_players(true)
    for i, player in pairs(players) do
        local player_pos = {entity.hitbox_position(player, 0)}
        
        local to_player = {
            x = player_pos[1] - shooters_pos[1],
            y = player_pos[2] - shooters_pos[2],
            z = player_pos[3] - shooters_pos[3]
        }
        
        local proj = to_player.x * ray_dir.x + to_player.y * ray_dir.y + to_player.z * ray_dir.z
        
        if proj > 0 then
            local point_on_ray = {
                x = shooters_pos[1] + ray_dir.x * proj,
                y = shooters_pos[2] + ray_dir.y * proj,
                z = shooters_pos[3] + ray_dir.z * proj
            }
            
            local dist_to_ray = math.sqrt(
                (point_on_ray.x - player_pos[1])^2 +
                (point_on_ray.y - player_pos[2])^2 +
                (point_on_ray.z - player_pos[3])^2
            )
            
            if dist_to_ray < closest_dist then
                closest_dist = dist_to_ray
                closest_player = player
            end
        end
    end
    
    if closest_player then
        AnalyzeResolveSuccess(closest_player, false)
    end
end)

client.set_event_callback("player_hurt", function(e)
    if not ui.get(MenuC["Enable"]) then return end
    
    local attacker = client.userid_to_entindex(e.attacker)
    local victim = client.userid_to_entindex(e.userid)
    
    if attacker and victim and attacker == entity.get_local_player() then
        local is_headshot = e.hitgroup == 1
        AnalyzeResolveSuccess(victim, true, is_headshot)
    end
end)

function DrawLine()
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["DebugLogs"]) then return end
    
    local localPlayer = entity.get_local_player()
    if not localPlayer then return end
    
    local localOrigin = {entity.get_origin(localPlayer)}
    if not localOrigin or #localOrigin < 3 then return end
    
    local visible_players = entity.get_players(true)
    for i, player in pairs(visible_players) do
        if cache.visible_players[player] then
            local enemyOrigin = {entity.get_origin(player)}
            local enemyHead = {entity.hitbox_position(player, 1)}
            
            if enemyOrigin and enemyHead and #enemyOrigin >= 3 and #enemyHead >= 3 then
                local screenLocal = {renderer.world_to_screen(localOrigin[1], localOrigin[2], localOrigin[3] + 62)}
                local screenHead = {renderer.world_to_screen(enemyHead[1], enemyHead[2], enemyHead[3])}
                local screenEnemy = {renderer.world_to_screen(enemyOrigin[1], enemyOrigin[2], enemyOrigin[3] + 56)}
                
                if screenLocal[1] and screenHead[1] and screenEnemy[1] then
                    local state = PlayerStateData[player]
                    local confidence = state and state.resolveConfidence or 0
                    local r, g, b, a = 255, 255, 255, 255
                    if confidence > 70 then
                        r, g, b = 0, 255, 0
                    elseif confidence > 30 then
                        r, g, b = 255, 255, 0
                    else
                        r, g, b = 255, 0, 0
                    end
                    
                    renderer.line(screenLocal[1], screenLocal[2], screenHead[1], screenHead[2], r, g, b, a)
                    renderer.line(screenLocal[1], screenLocal[2], screenEnemy[1], screenEnemy[2], r, g, b, a)

                    if ui.get(MenuC["PredictiveAim"]) and PredictedPositions[player] then
                        local pred = PredictedPositions[player]
                        local screenPred = {renderer.world_to_screen(pred.x, pred.y, pred.z)}
                        
                        if screenPred[1] then
                            renderer.circle_outline(screenPred[1], screenPred[2], 255, 0, 255, 200, 5, 0, 1, 1)
                        end
                    end
                end
            end
        end
    end
end

client.set_event_callback("pre_render", FastResolver)
client.set_event_callback("net_update_end", FastResolver)

client.register_esp_flag("R", 255, 255, 255, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then
        return false
    end
    local res_yaw = ResolvedYaw[player] or 0
    local lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    if res_yaw >= lby then
        return true
    end
    return false
end)

client.register_esp_flag("L", 255, 255, 255, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then
        return false
    end
    local res_yaw = ResolvedYaw[player] or 0
    local lby = entity.get_prop(player, "m_flLowerBodyYawTarget") or 0
    if res_yaw < lby then
        return true
    end
    return false
end)

client.register_esp_flag("AIR", 173, 216, 230, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then return false end
    return PlayerStateData[player] and PlayerStateData[player].isInAir and not PlayerStateData[player].isCrouching
end)

client.register_esp_flag("CRCH", 144, 238, 144, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then return false end
    return PlayerStateData[player] and PlayerStateData[player].isCrouching and not PlayerStateData[player].isInAir
end)

client.register_esp_flag("A+C", 255, 165, 0, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then return false end
    return PlayerStateData[player] and PlayerStateData[player].isAirCrouching
end)

client.register_esp_flag("BHOP", 255, 105, 180, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then return false end
    return PlayerStateData[player] and PlayerStateData[player].isBhopRushing
end)

client.register_esp_flag("CONF", 255, 255, 255, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then return false end
    local state = PlayerStateData[player]
    if state and state.resolveConfidence then
        return string.format("%d%%", state.resolveConfidence)
    end
    return false
end)

client.register_esp_flag("RESOLVING", 0, 255, 255, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then 
        return false 
    end
    return ResolvedYaw[player] == nil
end)

client.register_esp_flag("RESOLVED", 0, 255, 128, function(player)
    if not ui.get(MenuC["Enable"]) or not ui.get(MenuC["Flag"]) then 
        return false 
    end
    return ResolvedYaw[player] ~= nil and (ResolvedState[player] == "Default" or ResolvedState[player] == nil)
end)

client.set_event_callback('shutdown', function()
    ui.set_visible(MenuV["ForceBodyYaw"], true)
    ui.set_visible(MenuV["CorrectionActive"], true)
    ui.set(MenuV["ResetAll"], true)
end)

--// Debug line
client.set_event_callback("paint", DrawLine)
