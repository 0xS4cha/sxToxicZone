local ToxicEyeIndex = 10

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

function IsWearingProtectedClothes()
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