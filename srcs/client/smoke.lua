local particleDict = "scr_prologue"
local particleName = "scr_prologue_vault_fog"
local smokeScale = 20.0
local smokeSpacing = 15.0
local density = 3
local SmokePositions = {}
local ParticlesHandles = {}

local function GenerateWallPoints(p1, p2)
    local dist = #(p1 - p2)
    local direction = (p2 - p1) / dist
    local numPoints = math.floor(dist / smokeSpacing)

    for i = 0, numPoints do
        local newPos = p1 + (direction * (i * smokeSpacing))
        local z = newPos.z

        if not z then
            local found, groundZ = GetGroundZFor_3dCoord(newPos.x, newPos.y, 1000.0, false)
            if found and groundZ then
                z = groundZ
            else
                z = 50.0
            end
        end

        table.insert(SmokePositions, vector3(newPos.x, newPos.y, z))
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