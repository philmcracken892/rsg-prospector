local RSGCore = exports['rsg-core']:GetCoreObject()
local isProspecting = false
local cooldown = 0
local shovelObject = nil
local createdObjects = {} -- Table to track dirt piles

-- Check if player is too close to an existing dirt pile
local function IsNearDirtPile()
    local playerCoords = GetEntityCoords(PlayerPedId(), true)
    for _, obj in ipairs(createdObjects) do
        local objCoords = GetEntityCoords(obj)
        local distance = #(playerCoords - objCoords)
        if distance <= (Config.HoleDistance or 2.0) then
            return true
        end
    end
    return false
end

local function IsOnCooldown()
    return GetGameTimer() < cooldown
end

local function PlayDiggingAnimation()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local animDict = Config.Dig.anim[1]
    local animName = Config.Dig.anim[2]
    local animDuration = 15000

    -- Clean up existing shovel
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end

    -- Load animation
    RequestAnimDict(animDict)
    local timeout = 2000
    while not HasAnimDictLoaded(animDict) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end

    if not HasAnimDictLoaded(animDict) then
        lib.notify({ title = "Prospector's Kit", description = "Failed to load animation!", type = "error" })
        return false
    end

    -- Load shovel model
    local model = Config.Dig.shovel
    RequestModel(GetHashKey(model))
    timeout = 2000
    while not HasModelLoaded(GetHashKey(model)) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end

    if not HasModelLoaded(GetHashKey(model)) then
        lib.notify({ title = "Prospector's Kit", description = "Failed to load shovel prop!", type = "error" })
        return false
    end

    -- Create and attach shovel
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

    -- Play animation
    DisableControlAction(0, 0xB238FE0B, true)
    TaskPlayAnim(playerPed, animDict, animName, 8.0, -8.0, animDuration, 1, 0, false, false, false)
    Wait(animDuration)
    ClearPedTasks(playerPed)

    -- Clean up shovel
    if shovelObject then
        DeleteObject(shovelObject)
        SetEntityAsNoLongerNeeded(shovelObject)
        shovelObject = nil
    end
    DisableControlAction(0, 0xB238FE0B, false)
    RemoveAnimDict(animDict)
    SetModelAsNoLongerNeeded(GetHashKey(model))
    return true
end

local function CreateDirtPile()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerForwardVector = GetEntityForwardVector(playerPed)
    local dirtModel = Config.Dig.dirtModel or 'mp005_p_dirtpile_tall_unburied'

    -- Load dirt pile model
    RequestModel(dirtModel)
    local timeout = 2000
    while not HasModelLoaded(dirtModel) and timeout > 0 do
        Wait(100)
        timeout = timeout - 100
    end

    if not HasModelLoaded(dirtModel) then
        lib.notify({ title = "Prospector's Kit", description = "Failed to load dirt pile model!", type = "error" })
        return
    end

    -- Calculate dirt pile position (slightly in front of player)
    local offsetX = 0.6
    local objectX = playerCoords.x + playerForwardVector.x * offsetX
    local objectY = playerCoords.y + playerForwardVector.y * offsetX
    local objectZ = playerCoords.z - 1

    -- Create dirt pile
    local dirtObject = CreateObject(dirtModel, objectX, objectY, objectZ, true, true, false)
    table.insert(createdObjects, dirtObject)

    -- Optional: Auto-delete dirt pile after a delay to prevent clutter
    if Config.Dig.dirtPileDuration then
        Citizen.CreateThread(function()
            Wait(Config.Dig.dirtPileDuration)
            if DoesEntityExist(dirtObject) then
                DeleteObject(dirtObject)
                for i, obj in ipairs(createdObjects) do
                    if obj == dirtObject then
                        table.remove(createdObjects, i)
                        break
                    end
                end
            end
        end)
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

    if IsNearDirtPile() then
        lib.notify({ title = "Prospector's Kit", description = "You're too close to another dirt pile!", type = "info" })
        return
    end

    ExecuteCommand('closeInv')
    Wait(300)
    LocalPlayer.state:set('inv_busy', true, true)

    isProspecting = true
    lib.notify({ title = "Prospector's Kit", description = "You start digging in the dirt...", type = "info" })

    if PlayDiggingAnimation() then
        CreateDirtPile() -- Spawn dirt pile after successful animation
        TriggerServerEvent('rsg_prospectors_kit:prospect')
        cooldown = GetGameTimer() + 300000
    else
        LocalPlayer.state:set('inv_busy', false, true)
        isProspecting = false
        return
    end

    isProspecting = false
    LocalPlayer.state:set('inv_busy', false, true)
end

RegisterNetEvent('rsg_prospectors_kit:useKit')
AddEventHandler('rsg_prospectors_kit:useKit', StartProspecting)

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
    if resourceName == GetCurrentResourceName() then
        if shovelObject then
            DeleteObject(shovelObject)
            SetEntityAsNoLongerNeeded(shovelObject)
            shovelObject = nil
        end
        -- Clean up all dirt piles
        for _, obj in ipairs(createdObjects) do
            if DoesEntityExist(obj) then
                DeleteObject(obj)
            end
        end
        createdObjects = {}
    end
end)
