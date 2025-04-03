local RSGCore = exports['rsg-core']:GetCoreObject()
local isProspecting = false
local cooldown = 0
local shovelObject = nil




local function IsOnCooldown()
    return GetGameTimer() < cooldown
end


local function PlayDiggingAnimation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local animDict = Config.Dig.anim[1]
    local animName = Config.Dig.anim[2]
    local animDuration = 15000  -- Your desired duration (e.g., 15 seconds)
    
    
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    
    
    RequestAnimDict(animDict)
    local timeout = 1000
    while not HasAnimDictLoaded(animDict) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end
    
    if not HasAnimDictLoaded(animDict) then
        lib.notify({ title = "Prospector's Kit", description = "Failed to load animation!", type = "error" })
        return false
    end

    
    local model = Config.Dig.shovel
    RequestModel(GetHashKey(model))
    timeout = 1000
    while not HasModelLoaded(GetHashKey(model)) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end
    
    if HasModelLoaded(GetHashKey(model)) then
        shovelObject = CreateObject(GetHashKey(model), playerCoords.x, playerCoords.y, playerCoords.z, true, true, true)
        
        local boneIndex = GetEntityBoneIndexByName(playerPed, Config.Dig.bone)
        local attachPos = Config.Dig.pos
        AttachEntityToEntity(
            shovelObject, 
            playerPed, 
            boneIndex, 
            attachPos[1], attachPos[2], attachPos[3],
            attachPos[4], attachPos[5], attachPos[6],
            false, false, false, false, 2, true
        )
        
        
        DisableControlAction(0, 0xB238FE0B, true)
        TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, animDuration, 1, 0, false, false, false)
        Wait(animDuration)  
        
        
        ClearPedTasks(playerPed)
        
        
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
        DisableControlAction(0, 0xB238FE0B, false)
        RemoveAnimDict(animDict)
        SetModelAsNoLongerNeeded(GetHashKey(model))
        return true
    else
        lib.notify({ title = "Prospector's Kit", description = "Failed to load shovel prop!", type = "error" })
        return false
    end
end


local function StartProspecting()
    if isProspecting then
        lib.notify({ title = "Prospector's Kit", description = "You're already prospecting!", type = "error" })
        return
    end

    if IsOnCooldown() then
        local timeLeft = math.ceil((cooldown - GetGameTimer()) / 1000)
        lib.notify({ title = "Prospector's Kit", description = "Wait " .. timeLeft .. " seconds before prospecting again!", type = "warning" })
        return
    end

    
    ExecuteCommand('closeInv')
    
   
    Wait(300)
    
    
    LocalPlayer.state:set('inv_busy', true, true)
    
    isProspecting = true
    lib.notify({ title = "Prospector's Kit", description = "You start digging in the dirt...", type = "info" })
    
    if PlayDiggingAnimation() then
        TriggerServerEvent('rsg_prospectors_kit:prospect')
        cooldown = GetGameTimer() + 300000 -- 5-minute cooldown
    end
    
    isProspecting = false
   
    LocalPlayer.state:set('inv_busy', false, true)
end


RegisterNetEvent('rsg_prospectors_kit:useKit')
AddEventHandler('rsg_prospectors_kit:useKit', function()
    
    Citizen.CreateThread(function()
        StartProspecting()
    end)
end)


RegisterNetEvent('rsg_prospectors_kit:prospectResult')
AddEventHandler('rsg_prospectors_kit:prospectResult', function(item, amount)
    if item then
        lib.notify({ 
            title = "Prospector's Kit", 
            description = "You found " .. amount .. "x " .. item .. "!", 
            type = "success" 
        })
    else
        lib.notify({ 
            title = "Prospector's Kit", 
            description = "You didn't find anything this time.", 
            type = "error" 
        })
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
end)