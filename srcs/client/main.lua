PlayerInZone = nil
ZonesList = {}
local FadeId = 0

local ToxicTickInterval = 1000 * 60
local ToxicDamagePerTick = 15


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


