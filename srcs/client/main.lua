PlayerInZone = nil
ZonesList = {}
local FadeId = 0

local ToxicTickInterval = 1000 * 60
local ToxicDamagePerTick = 15
local ToxicEyeIndex = 10
local particleDict = "scr_prologue"
local particleName = "scr_prologue_vault_fog"
local smokeScale = 20.0
local smokeSpacing = 15.0
local density = 3
local SmokePositions = {}
local ParticlesHandles = {}


local componentMap = {
    torso = { type = "component", id = 11, field = "torso_1" },
    tshirt = { type = "component", id = 8, field = "tshirt_1" },
    arms = { type = "component", id = 3, field = "arms" },
    pants = { type = "component", id = 4, field = "pants_1" },
    shoes = { type = "component", id = 6, field = "shoes_1" },
    bags = { type = "component", id = 5, field = "bags_1" },
    mask = { type = "component", id = 1, field = "mask_1" },
    chain = { type = "component", id = 7, field = "chain_1" },
    bproof = { type = "component", id = 9, field = "bproof_1" }
}

local propMap = {
    helmet = { propIndex = 0, field = "helmet_1" },
    glasses = { propIndex = 1, field = "glasses_1" },
    ears = { propIndex = 2, field = "ears_1" },
    watches = { propIndex = 6, field = "watches_1" },
    bracelets = { propIndex = 7, field = "bracelets_1" }
}

local function GetPlayerGenderIndex()
    local model = GetEntityModel(PlayerPedId())
    if model == GetHashKey("mp_m_freemode_01") then
        return 0
    else
        return 1
    end
end

local function IsWearingProtectedClothes()
    if not SHARED or not SHARED.Clothes then
        return true
    end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return true
    end

    local genderIndex = GetPlayerGenderIndex()
    local clothesConfig = SHARED.Clothes

    for partName, cfg in pairs(componentMap) do
        local partDataByGender = clothesConfig[partName]
        local partData = partDataByGender and partDataByGender[genderIndex]

        if partData then
            local expected = partData[cfg.field]
            if expected ~= nil then
                local current = GetPedDrawableVariation(ped, cfg.id)
                if current ~= expected then
                    return false
                end
            end
        end
    end

    for partName, cfg in pairs(propMap) do
        local partDataByGender = clothesConfig[partName]
        local partData = partDataByGender and partDataByGender[genderIndex]

        if partData then
            local expected = partData[cfg.field]
            if expected ~= nil then
                local current = GetPedPropIndex(ped, cfg.propIndex)
                if current ~= expected then
                    return false
                end
            end
        end
    end

    return true
end

Citizen.CreateThread(function()
    while true do
        if PlayerInZone then
            local ped = PlayerPedId()
            if not IsEntityDead(ped) and not IsWearingProtectedClothes() then
                local health = GetEntityHealth(ped)
                if health > 0 then
                    local newHealth = health - ToxicDamagePerTick
                    if newHealth < 0 then newHealth = 0 end
                    SetEntityHealth(ped, newHealth)
                end
            end
            Citizen.Wait(ToxicTickInterval)
        else
            Citizen.Wait(1000)
        end
    end
end)


local function ApplyToxicEye()
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        SetPedEyeColor(ped, ToxicEyeIndex)
    end
end

local function ResetToxicEye(previousEye)
    local ped = PlayerPedId()
    if DoesEntityExist(ped) then
        if type(previousEye) == "number" then
            SetPedEyeColor(ped, previousEye)
        else
            SetPedEyeColor(ped, -1)
        end
    end
end

exports("ResetToxicEye", function()
    TriggerServerEvent("sxZones_toxic:clearToxicEye")
end)

RegisterNetEvent("sxZones_toxic:applyToxicEye", function()
    ApplyToxicEye()
end)

RegisterNetEvent("sxZones_toxic:resetToxicEye", function(previousEye)
    ResetToxicEye(previousEye)
end)

Citizen.CreateThread(function()
    TriggerServerEvent("sxZones_toxic:requestEyeState")
end)

function FadeTimeCycle(direction, modifier)
    FadeId = FadeId + 1
    local myId = FadeId
    
    Citizen.CreateThread(function()
        if direction then
            SetTimecycleModifier(modifier or "TrevorColorCodeBright")
            local strength = 0.0
            while strength <= 1.0 do
                if myId ~= FadeId then return end
                SetTimecycleModifierStrength(strength)
                strength = strength + 0.02
                Wait(0)
            end
            if myId == FadeId then
                SetTimecycleModifierStrength(1.0)
            end
        else
            local strength = 1.0
            while strength >= 0.0 do
                if myId ~= FadeId then return end
                SetTimecycleModifierStrength(strength)
                strength = strength - 0.02
                Wait(0)
            end
            if myId == FadeId then
                ClearTimecycleModifier()
            end
        end
    end)
end

Citizen.CreateThread(function()
    print("Initializing Zones...")
    for i = 1, #SHARED.Zones do
        local zone = SHARED.Zones[i]
        zone.PolyZone = PolyZone:Create(zone.coords, {
            name = zone.id,
            minZ = zone.min_z,
            maxZ = zone.max_z,
            debugGrid = false,
            gridDivisions = 25
        })
    end

    Citizen.CreateThread(function()
        while true do
            local wasInZone = PlayerInZone ~= nil
            local currentZone = nil
            local playerCoords = GetEntityCoords(PlayerPedId())
    
            for i = 1, #SHARED.Zones do
                if SHARED.Zones[i].PolyZone and SHARED.Zones[i].PolyZone:isPointInside(playerCoords) then
                    currentZone = i
                    break
                end
            end
    
            if currentZone and PlayerInZone ~= currentZone then
                local justEntered = not wasInZone
                PlayerInZone = currentZone
                SendNUIMessage({
                    type = "SET_ROLEPLAY_HUD_TITLE",
                    module = "none",
                    payload = {
                        title = GetPhrase("enter_zone", SHARED.Zones[currentZone].label),
                        description = GetPhrase("description_zone"),
                        time = SHARED.Title_time
                    }
                })
                local protected = IsWearingProtectedClothes()
                if not protected then
                    if justEntered then
                        FadeTimeCycle(true, "TrevorColorCodeBright")
                    else
                        SetTimecycleModifier("TrevorColorCodeBright")
                        SetTimecycleModifierStrength(1.0)
                    end
                else
                    ClearTimecycleModifier()
                end
            elseif not currentZone and wasInZone then
                PlayerInZone = nil
                FadeTimeCycle(false)
            end
            
            Wait(500)
        end
    end)
   
end)


function GetZoneFromCoords(coords)

    local x = coords.x or (coords[1] and coords[1].x) or nil
    local y = coords.y or (coords[1] and coords[1].y) or nil
    local z = coords.z or (coords[1] and coords[1].z) or 50.0

    if not x or not y then return nil end

    local point = vector3(x, y, z)

    for i = 1, #SHARED.Zones do
        if SHARED.Zones[i].PolyZone and SHARED.Zones[i].PolyZone:isPointInside(point) then
            return i
        end
    end

    return nil
end

local function GenerateWallPoints(p1, p2)
    local dist = #(p1 - p2)
    local direction = (p2 - p1) / dist
    local numPoints = math.floor(dist / smokeSpacing)

    for i = 0, numPoints do
        local newPos = p1 + (direction * (i * smokeSpacing))
        table.insert(SmokePositions, vector3(newPos.x, newPos.y, newPos.z or zoneZ))
    end
end

Citizen.CreateThread(function()
    for i = 1, #SHARED.Zones do
        for k = 1, #SHARED.Zones[i].coords do
            local p1 = SHARED.Zones[i].coords[k]
            local p2 = SHARED.Zones[i].coords[k + 1] or SHARED.Zones[i].coords[1]
            GenerateWallPoints(p1, p2)
        end
    end
end)

Citizen.CreateThread(function()
    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do Wait(10) end

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local letSleep = true
        
        for i, pos in ipairs(SmokePositions) do
            local dist = #(playerCoords - pos)
            for _ = 1, density do
                if dist < 500.0 then
                    letSleep = false
                    if not ParticlesHandles[i] or not DoesParticleFxLoopedExist(ParticlesHandles[i]) then
                        UseParticleFxAssetNextCall(particleDict)
                        ParticlesHandles[i] = StartParticleFxLoopedAtCoord(
                            particleName,
                            pos.x, pos.y, pos.z,
                            0.0, 0.0, 0.0,
                            smokeScale,
                            false, false, false, false
                        )
                        SetParticleFxLoopedAlpha(ParticlesHandles[i], 1.0)
                        SetParticleFxLoopedColour(ParticlesHandles[i], 0.0, 1.0, 0.0, 0)
                    end
                else
                    if ParticlesHandles[i] and DoesParticleFxLoopedExist(ParticlesHandles[i]) then
                        StopParticleFxLooped(ParticlesHandles[i], false)
                        ParticlesHandles[i] = nil
                    end
                end
            end
        end

        if letSleep then
            Citizen.Wait(500)
        else
            Citizen.Wait(1)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, handle in pairs(ParticlesHandles) do
        if DoesParticleFxLoopedExist(handle) then StopParticleFxLooped(handle, false) end
    end
end)