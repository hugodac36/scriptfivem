AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    local identifier = xPlayer.identifier

    if not playerId or not identifier then
        print("Erreur : playerId ou identifier est nil.")
        return
    end

    -- Charger les implants du joueur
    MySQL.Async.fetchAll('SELECT * FROM user_implants WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(result)
        local implants = {}
        for _, row in ipairs(result) do
            implants[row.implant_slot] = {
                type = row.implant_type,
                level = row.implant_level,
                degradation = row.implant_health
            }
        end

        -- Charger la charge ImmuNeuro du joueur
        MySQL.Async.fetchScalar('SELECT charge_immuneuro FROM user_syringes WHERE identifier = @identifier', {
            ['@identifier'] = identifier
        }, function(chargeImmuNeuro)
            if playerId then
                TriggerClientEvent('implant:load', playerId, implants, chargeImmuNeuro or 0)
            else
                print("Erreur : playerId est nil lors de l'envoi à TriggerClientEvent.")
            end
        end)
    end)
end)

AddEventHandler('esx:playerDropped', function(playerId)
    if not playerId then
        print("Erreur : playerId est nil.")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        print("Erreur : xPlayer est nil.")
        return
    end

    local identifier = xPlayer.identifier
    if not identifier then
        print("Erreur : identifier est nil.")
        return
    end

    -- Cet événement est appelé après que les données client sont envoyées, on doit donc s'assurer que les implants sont récupérés avant de sauvegarder.
    TriggerClientEvent('implant:requestSave', playerId, identifier)
end)

RegisterServerEvent('implant:save')
AddEventHandler('implant:save', function(implants, chargeImmuNeuro, identifier)
    if not identifier then
        print("Erreur : identifier est nil.")
        return
    end

    -- Supprimer les implants existants pour cet identifiant
    MySQL.Async.execute('DELETE FROM user_implants WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function()
        -- Réinsérer les implants mis à jour
        for _, implant in ipairs(implants) do
            MySQL.Async.execute('INSERT INTO user_implants (identifier, implant_slot, implant_type, implant_level, implant_health, install_date) VALUES (@identifier, @implant_slot, @implant_type, @implant_level, @implant_health, NOW())', {
                ['@identifier'] = identifier,
                ['@implant_slot'] = implant.implant_slot,
                ['@implant_type'] = implant.implant_type,
                ['@implant_level'] = implant.implant_level,
                ['@implant_health'] = implant.implant_health
            })
        end

        -- Mise à jour ou insertion de la charge ImmuNeuro
        MySQL.Async.execute('INSERT INTO user_syringes (identifier, charge_immuneuro, last_usage) VALUES (@identifier, @charge_immuneuro, NOW()) ON DUPLICATE KEY UPDATE charge_immuneuro = VALUES(charge_immuneuro), last_usage = NOW()', {
            ['@identifier'] = identifier,
            ['@charge_immuneuro'] = chargeImmuNeuro
        })
    end)
end)

-- Fonction auxiliaire pour afficher une table sous forme de chaîne de caractères
function TableToString(tbl)
    local result = ""
    for k, v in pairs(tbl) do
        result = result .. k .. ": " .. tostring(v) .. "\n"
    end
    return result
end

ESX.RegisterServerCallback('implant:checkPlayerImplant', function(source, cb, targetPlayerId, implantType)
    local xPlayer = ESX.GetPlayerFromId(targetPlayerId)
    if not xPlayer then
        print("Erreur : xPlayer est nil.")
        cb(false)
        return
    end

    local identifier = xPlayer.identifier
    if not identifier then
        print("Erreur : identifier est nil.")
        cb(false)
        return
    end

    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM user_implants WHERE identifier = @identifier AND implant_type = @implantType', {
        ['@identifier'] = identifier,
        ['@implantType'] = implantType
    }, function(count)
        if count > 0 then
            cb(true)
        else
            cb(false)
        end
    end)
end)

RegisterServerEvent('implant:updateChargeImmuNeuro')
AddEventHandler('implant:updateChargeImmuNeuro', function(newCharge)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print("Erreur : xPlayer est nil.")
        return
    end

    local identifier = xPlayer.identifier
    if not identifier then
        print("Erreur : identifier est nil.")
        return
    end

    -- Mise à jour de la charge ImmuNeuro dans la base de données
    MySQL.Async.execute('UPDATE user_syringes SET charge_immuneuro = @charge_immuneuro, last_usage = NOW() WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
        ['@charge_immuneuro'] = newCharge
    }, function(affectedRows)
        if affectedRows > 0 then
            print("Charge ImmuNeuro mise à jour avec succès pour le joueur " .. identifier .. " : " .. newCharge)
        else
            print("Échec de la mise à jour de la charge ImmuNeuro pour le joueur " .. identifier)
        end
    end)

    -- Si vous avez d'autres opérations à effectuer après la mise à jour de la charge ImmuNeuro, vous pouvez les ajouter ici.
end)

--chracudocjob

-- Callback pour obtenir les implants d'un joueur
ESX.RegisterServerCallback('implant:getPlayerImplants', function(source, cb, targetPlayerId)
    local xPlayer = ESX.GetPlayerFromId(targetPlayerId)
    if not xPlayer then
        cb({})
        return
    end

    MySQL.Async.fetchAll('SELECT * FROM user_implants WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        local implants = {}
        for _, row in ipairs(result) do
            implants[row.implant_slot] = {
                type = row.implant_type,
                level = row.implant_level,
                degradation = row.implant_health
            }
        end
        cb(implants)
    end)
end)

-- Callback pour obtenir les implants disponibles dans l'inventaire du Charcudoc
ESX.RegisterServerCallback('implant:getAvailableImplants', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local implants = xPlayer.getInventoryItem('implant_item') -- Remplacez 'implant_item' par l'item d'implant spécifique

    if implants.count > 0 then
        local availableImplants = {}

        -- Supposons que chaque item 'implant_item' a un type spécifique d'implant.
        table.insert(availableImplants, {label = implants.label, type = implants.name})
        
        cb(availableImplants)
    else
        cb({})
    end
end)

-- Event pour ajouter un implant
RegisterServerEvent('implant:addImplant')
AddEventHandler('implant:addImplant', function(targetPlayerId, implantType)
    local xTargetPlayer = ESX.GetPlayerFromId(targetPlayerId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Vérifier si le joueur a l'implant dans son inventaire
    local implantItem = xPlayer.getInventoryItem(implantType)
    if implantItem.count > 0 then
        -- Ajouter l'implant au joueur cible
        MySQL.Async.execute('INSERT INTO user_implants (identifier, implant_slot, implant_type, implant_level, implant_health, install_date) VALUES (@identifier, @implant_slot, @implant_type, @implant_level, @implant_health, NOW())', {
            ['@identifier'] = xTargetPlayer.identifier,
            ['@implant_slot'] = implantType,  -- Supposez que le slot est déterminé par le type
            ['@implant_type'] = implantType,
            ['@implant_level'] = 1,
            ['@implant_health'] = 100
        })

        -- Retirer l'implant de l'inventaire du charcudoc
        xPlayer.removeInventoryItem(implantType, 1)
        TriggerClientEvent('esx:showNotification', source, "Vous avez installé un implant.")
    else
        TriggerClientEvent('esx:showNotification', source, "Vous n'avez pas cet implant.")
    end
end)

-- Event pour retirer un implant
RegisterServerEvent('implant:removeImplant')
AddEventHandler('implant:removeImplant', function(targetPlayerId, implantType)
    local xTargetPlayer = ESX.GetPlayerFromId(targetPlayerId)

    -- Retirer l'implant du joueur cible
    MySQL.Async.execute('DELETE FROM user_implants WHERE identifier = @identifier AND implant_type = @implant_type', {
        ['@identifier'] = xTargetPlayer.identifier,
        ['@implant_type'] = implantType
    })

    -- Ajoutez une notification pour informer du retrait de l'implant
    TriggerClientEvent('esx:showNotification', source, "Vous avez retiré un implant.")
end)
