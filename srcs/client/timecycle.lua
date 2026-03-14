
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