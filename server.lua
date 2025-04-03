local RSGCore = exports['rsg-core']:GetCoreObject()

RSGCore.Functions.CreateUseableItem("prospectors_kit", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    TriggerClientEvent('rsg_prospectors_kit:useKit', source)
end)

RegisterNetEvent('rsg_prospectors_kit:prospect')
AddEventHandler('rsg_prospectors_kit:prospect', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    if Player.Functions.GetItemByName('prospectors_kit') == nil then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Prospector\'s Kit', description = 'You don\'t have a kit!', type = 'error' })
        return
    end
    
    local chance = math.random(1, 100)
    local totalChance = 0
    
    for _, loot in pairs(Config.LootTable) do
        totalChance = totalChance + loot.chance
        if chance <= totalChance then
            if loot.item then
                Player.Functions.AddItem(loot.item, loot.amount)
                TriggerClientEvent('rsg_prospectors_kit:prospectResult', src, loot.item, loot.amount)
            else
                TriggerClientEvent('rsg_prospectors_kit:prospectResult', src, nil, 0)
            end
            break
        end
    end
end)