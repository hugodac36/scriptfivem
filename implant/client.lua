ImplantCapabilities = {}

-- Fonction pour réinitialiser les capacités
function ImplantCapabilities.ResetCapabilities()
    local playerPed = PlayerPedId()
    SetPedMoveRateOverride(playerPed, 1.0)  -- Réinitialiser la vitesse de course
    SetWeaponDamageModifierThisFrame(GetHashKey("WEAPON_UNARMED"), 7.0 / 26.0)  -- Réinitialiser les dégâts des poings à 7
    print("Toutes les capacités ont été réinitialisées.")
end

-- Initialisation de ESX via l'export
ESX = exports["es_extended"]:getSharedObject()


local playerChargeImmuNeuro = 0
local playerImplants = {}
local nonAffectVehicles = {
    GetHashKey("atlus"),
    GetHashKey("AMBULANCE"),
    -- Ajoutez ici d'autres modèles de véhicules non affectés par la capacité
}


local shieldLevel = 0  -- Variable pour stocker le niveau actuel du bouclier

-- Fonction pour vérifier si le joueur a l'implant requis
function ImplantCapabilities.HasImplant(requiredImplant)
    for slot, implant in pairs(playerImplants) do
        if implant.type == requiredImplant then
            return true
        end
    end
    return false
end

-- Commande pour enlever tous les implants
RegisterCommand("removeallimplants", function()
    playerImplants = {}  -- Réinitialiser les implants du joueur
    ImplantCapabilities.ResetCapabilities()  -- Réinitialiser toutes les capacités
    ESX.ShowNotification("Tous les implants ont été retirés.")
    print("Tous les implants ont été retirés, et les capacités ont été réinitialisées.")

    -- Réinitialiser l'armure
    local playerPed = PlayerPedId()
    shieldLevel = 0
    SetPedArmour(playerPed, 0)
    print("Armure réinitialisée après le retrait de tous les implants.")

    -- Sauvegarder les changements sur le serveur
    SavePlayerImplants(GetPlayerIdentifier())  -- Appel immédiat pour sauvegarder les changements

    -- Vérification après retrait des implants
    Citizen.SetTimeout(1000, function()
        ImplantCapabilities.ApplyPassiveEffects()
    end)
end, false)

-- Fonction pour activer les effets automatiques
function ImplantCapabilities.ApplyPassiveEffects()
    ImplantCapabilities.ResetCapabilities()  -- Réinitialiser d'abord les capacités
    local playerPed = PlayerPedId()

    ImplantCapabilities.IncreaseShield()

    -- Augmentation de la vitesse de course
    if ImplantCapabilities.HasImplant("jambe_guepard") then
        if playerImplants["jambes"] and playerImplants["jambes"].level then
            local level = playerImplants["jambes"].level
            local sprintMultiplier = 1.0 + (level * 0.16) -- Ajuste ce multiplicateur (Max 1.49)
            if sprintMultiplier > 1.49 then
                sprintMultiplier = 1.49
            end
            SetRunSprintMultiplierForPlayer(PlayerId(), sprintMultiplier)
            print("Multiplicateur de sprint réglé à " .. sprintMultiplier .. " grâce à l'implant jambe_guepard")
        else
            print("Erreur: Niveau de l'implant 'jambe_guepard' non défini.")
        end
    else
        -- Si aucun implant de vitesse n'est actif, désactiver l'augmentation de la vitesse
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        print("Multiplicateur de sprint réinitialisé à 1.0 car aucun implant 'jambe_guepard' n'est actif.")
    end

    -- Augmentation de la force des coups avec les poings
    if ImplantCapabilities.HasImplant("bras_gorille") then
        if playerImplants["bras"] and playerImplants["bras"].level then
            local level = playerImplants["bras"].level
            local damageMultiplier = 1.0 + (level * 0.3)
            SetWeaponDamageModifierThisFrame(GetHashKey("WEAPON_UNARMED"), damageMultiplier)
            print("Force des coups augmentée de " .. (level * 30) .. "% grâce à l'implant bras_gorille")
        else
            print("Erreur: Niveau de l'implant 'bras_gorille' non défini.")
        end
    else
        -- Si aucun implant de vitesse n'est actif, désactiver l'augmentation de la vitesse
        SetWeaponDamageModifierThisFrame(GetHashKey("WEAPON_UNARMED"),1)
        print("Multiplicateur de damage réinitialisé à 1.0 car aucun implant 'bras_gorille' n'est actif.")
    end

    -- Régénération de la santé
    if ImplantCapabilities.HasImplant("systeme_reconstitution") then
        if playerImplants["torse"] and playerImplants["torse"].level then
            local level = playerImplants["torse"].level
            
            -- Définir la vitesse de régénération
            local regenRate = 0.2 * level  -- Ajuster ce multiplicateur selon le niveau
            SetPlayerHealthRechargeMultiplier(PlayerId(), regenRate)
            
            -- Optionnel : Limiter la régénération de santé à 100% de la santé maximale
            SetPlayerHealthRechargeLimit(PlayerId(), 1.0)
    
            print("Multiplicateur de régénération de santé défini à " .. regenRate .. " grâce à l'implant systeme_reconstitution")
        else
            print("Erreur: Niveau de l'implant 'systeme_reconstitution' non défini.")
        end
    else
        -- Si aucun implant de régénération n'est actif, désactiver la régénération de la santé
        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
        print("La régénération de santé a été désactivée car aucun implant 'systeme_reconstitution' n'est actif.")
    end

    -- Vérification de l'implant armure_sous_cutanee (pas de modification de santé, uniquement pour le log)
    if ImplantCapabilities.HasImplant("armure_sous_cutanee") then
        print("L'implant armure_sous_cutanee est actif. La réduction des dégâts sera appliquée en fonction des attaques reçues.")
    else
        print("Aucun implant 'armure_sous_cutanee' actif.")
    end
end

-- Fonction pour initier l'analyse
function ImplantCapabilities.InitiateOracleScan(targetPlayer)
    local targetPed = GetPlayerPed(targetPlayer)
    local playerPed = PlayerPedId()

    -- Vérifiez si la cible est masquée
    if IsPedWearingHelmet(targetPed) or GetPedDrawableVariation(targetPed, 1) ~= 0 then
        ESX.ShowNotification("Impossible d'identifier la personne, elle porte un masque.")
        return
    end

    -- Vérifier si la cible a l'implant de camouflage facial
    if IsEntityVisible(targetPed) and not ImplantCapabilities.HasImplant("camouflage_facial") then
        -- Démarrer l'analyse (10 secondes)
        ESX.ShowNotification("Analyse en cours... Restez proche de la cible.")
        Citizen.Wait(10000)  -- Attendre 10 secondes

        -- Vérifier que le joueur est toujours proche
        if #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) <= 5.0 then
            local targetIdentifier = GetPlayerIdentifier(targetPlayer)
            ESX.ShowNotification("Analyse réussie. Identité : " .. targetIdentifier)
        else
            ESX.ShowNotification("Analyse échouée, vous êtes trop loin de la cible.")
        end
    else
        -- Échec de l'analyse avec effet de flou
        ESX.ShowNotification("Erreur lors de l'analyse, la cible a un camouflage facial.")
        StartScreenEffect("DeathFailMPIn", 0, true)
        Citizen.Wait(5000)
        StopScreenEffect("DeathFailMPIn")
    end

    -- Appliquer la dégradation de l'implant
    ImplantCapabilities.DegradeImplant("tete", "implant_oracle", 2)
end

-- Ajout de l'option ox_target pour électrocuter un joueur proche avec implants
exports.ox_target:addGlobalPlayer({
    {
        name = 'electrocute_player',
        label = 'Électrocuter',
        icon = 'fas fa-bolt',
        distance = 5.0,
        canInteract = function(entity, distance, coords, name, bone)
            local targetPlayer = GetPlayerFromServerId(entity)
            return isElectrocuteActive and HasImplants(targetPlayer)  -- Affiche uniquement si la capacité est activée et que le joueur a des implants
        end,
        onSelect = function(data)
            local targetPlayer = data.entity
            if targetPlayer and targetPlayer ~= PlayerId() then
                -- Démarrer l'électrocution
                ElectrocutePlayer(targetPlayer)
            end
        end
    }
})

-- Ajout de l'option ox_target pour identifier une personne proche
exports.ox_target:addGlobalPlayer({
    {
        name = 'oracle_scan',
        label = 'Identifier avec Oracle',
        icon = 'fas fa-eye',
        distance = 5.0,
        canInteract = function(entity, distance, coords, name, bone)
            return ImplantCapabilities.HasImplant("implant_oracle")
        end,
        onSelect = function(data)
            local targetPlayer = data.entity
            if targetPlayer and targetPlayer ~= PlayerId() then
                -- Démarrer le scan Oracle
                ImplantCapabilities.InitiateOracleScan(targetPlayer)
            end
        end
    }
})

-- Fonction pour augmenter le bouclier basé sur les implants
function ImplantCapabilities.IncreaseShield()
    local playerPed = PlayerPedId()
    local player = PlayerId()

    local maxShield = 0

    -- Gestion de l'implant armure_sous_cutanee
    if ImplantCapabilities.HasImplant("armure_sous_cutanee") then
        local level = playerImplants["torse"].level
        maxShield = maxShield + math.floor(100 * (1 + 0.4 * level))  -- Bouclier max = 100 + 40% par niveau
    end

    -- Gestion de l'implant plaque_faciale_renforcee
    if ImplantCapabilities.HasImplant("plaque_faciale_renforcee") then
        local level = playerImplants["tete"].level
        maxShield = maxShield + (40 * level)  -- Ajoute 40 points de shield par niveau
    end

    -- Appliquer le nouveau bouclier
    if GetPedArmour(playerPed) < maxShield then
        shieldLevel = maxShield
        SetPlayerMaxArmour(player, shieldLevel)
        SetPedArmour(playerPed, shieldLevel)
        print("Bouclier augmenté à " .. shieldLevel .. " points.")
    else
        print("Bouclier déjà au maximum.")
    end
end

-- Gestion des meurtres pour l'implant mort_d'adrenaline
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == "CEventNetworkEntityKilled" then
        local victim = args[1]
        local killer = args[2]

        -- Vérifiez si le joueur est le tueur
        if killer == PlayerPedId() and ImplantCapabilities.HasImplant("mort_d'adrenaline") then
            local level = playerImplants["tete"].level
            local maxHealth = GetEntityMaxHealth(killer)
            local healthGain = maxHealth * (0.18 * level)  -- Gagne 18% de la santé maximale par niveau

            -- Applique le gain de santé
            local currentHealth = GetEntityHealth(killer)
            SetEntityHealth(killer, math.min(currentHealth + healthGain, maxHealth))
            print("Santé augmentée de " .. healthGain .. " points grâce à l'implant mort_d'adrenaline.")

            -- Applique la dégradation de l'implant
            ImplantCapabilities.DegradeImplant("tete", "mort_d'adrenaline", 3)
        end
    end
end)

--netrunner
local isOnCooldown = false

-- Fonction pour activer le mode de désactivation de véhicule
function ActivateVehicleDisablingMode()
    if not ImplantCapabilities.HasImplant("puce_net_runner") then
        ESX.ShowNotification("Vous n'avez pas l'implant nécessaire pour utiliser cette capacité.")
        return
    end

    exports.ox_target:addGlobalVehicle({
        {
            name = 'disable_vehicle',
            label = 'Désactiver le véhicule',
            icon = 'fas fa-car-crash',
            distance = 20.0,
            canInteract = function(entity)
                return isVehicleDisablingActive and not IsVehicleNonAffect(entity) and not isOnCooldown
            end,
            onSelect = function(data)
                print("Tentative de désactivation du véhicule : isOnCooldown = " .. tostring(isOnCooldown))
                
                if isOnCooldown then
                    ESX.ShowNotification("Vous ne pouvez pas utiliser cette capacité pour le moment. Attendez la fin du cooldown.")
                    return
                end

                local vehicle = data.entity
                if vehicle then
                    -- Désactiver le véhicule
                    SetVehicleUndriveable(vehicle, true)
                    ESX.ShowNotification("Le véhicule a été désactivé.")

                    -- Forcer le freinage si un conducteur est à l'intérieur
                    local driver = GetPedInVehicleSeat(vehicle, -1)
                    if driver and driver ~= 0 then
                        TaskVehicleTempAction(driver, vehicle, 6, 30000) -- Freinage fort pendant 3 secondes
                    end
                    
                    -- Optionnel : Réactiver le véhicule après 30 secondes
                    Citizen.SetTimeout(30000, function()
                        if DoesEntityExist(vehicle) then
                            SetVehicleUndriveable(vehicle, false)
                            ESX.ShowNotification("Le véhicule a été réactivé.")
                        end
                    end)

                    -- Démarrer le cooldown après l'utilisation de la capacité
                    print("Démarrage du cooldown...")
                    StartCooldown()
                else
                    ESX.ShowNotification("Aucun véhicule trouvé.")
                end
            end
        }
    })
end

function ElectrocutePlayer(targetPlayer)
    if not ImplantCapabilities.HasImplant("puce_net_runner") then
        ESX.ShowNotification("Vous n'avez pas l'implant nécessaire pour utiliser cette capacité.")
        return
    end
    print("Tentative d'utilisation de la capacité Électrocute : isOnCooldown = " .. tostring(isOnCooldown))

    if isOnCooldown then
        ESX.ShowNotification("Vous ne pouvez pas utiliser cette capacité pour le moment. Attendez la fin du cooldown.")
        return
    end

    -- Vérifier si la cible a l'implant protection_piratage via le serveur
    ESX.TriggerServerCallback('implant:checkPlayerImplant', function(hasImplant)
        if hasImplant then
            ESX.ShowNotification("Électrocution renvoyée ! Le joueur cible a une protection contre le piratage.")

            -- Appliquer l'électrocution à soi-même
            local playerPed = PlayerPedId()

            -- Appliquer l'effet de tremblement de la caméra
            ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 1.0)

            -- Mettre le joueur en ragdoll pendant 2 secondes
            SetPedToRagdoll(playerPed, 2000, 2000, 0, true, true, false)

            -- Notifier le joueur
            ESX.ShowNotification("Vous vous êtes électrocuté en essayant d'électrocuter quelqu'un avec une protection.")
        else
            -- Récupérer le Ped du joueur ciblé
            local targetPed = GetPlayerPed(targetPlayer)

            -- Appliquer l'effet de tremblement de la caméra
            ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 1.0)

            -- Mettre le joueur en ragdoll pendant 2 secondes
            SetPedToRagdoll(targetPed, 2000, 2000, 0, true, true, false)

            -- Notifier le joueur
            ESX.ShowNotification("Le joueur a été électrocuté avec succès.")
        end

        -- Démarrer le cooldown après l'utilisation de la capacité
        StartCooldown()
    end, GetPlayerServerId(targetPlayer), "protection_piratage")
end


--fonction pour gérer le cooldown
function StartCooldown()
    isOnCooldown = true
    print("Cooldown activé. isOnCooldown = " .. tostring(isOnCooldown))
    ESX.ShowNotification("Capacité en cooldown. Vous devez attendre 1 minute avant de réutiliser une capacité.")

    Citizen.SetTimeout(60000, function()  -- 60000 millisecondes = 1 minute
        isOnCooldown = false
        print("Cooldown terminé. isOnCooldown = " .. tostring(isOnCooldown))
        ESX.ShowNotification("Vous pouvez maintenant utiliser une nouvelle capacité.")
    end)
end

-- Vérifie si le joueur possède l'implant puce_net_runner avant d'ouvrir le menu
function CanOpenNetRunnerMenu()
    if ImplantCapabilities.HasImplant("puce_net_runner") then
        return true
    else
        ESX.ShowNotification("Vous n'avez pas l'implant nécessaire pour ouvrir le menu Net Runner.")
        return false
    end
end

-- Fonction pour ouvrir le menu Net Runner
function OpenNetRunnerMenu()
    local elements = {
        {label = 'Électrocuter un joueur', value = 'electrocute'},
        {label = 'Désactiver un véhicule', value = 'disable_vehicle'}
        -- Tu peux ajouter d'autres éléments ici
    }

    -- Envoie les éléments au NUI
    SendNUIMessage({
        action = 'showMenu',
        elements = elements
    })

    -- Active l'interface NUI
    SetNuiFocus(true, true)
end

RegisterNUICallback('selectItem', function(data, cb)
    -- Désactiver toutes les capacités avant d'en activer une nouvelle
    isElectrocuteActive = false
    isVehicleDisablingActive = false
    isImplantDisablingActive = false

    local selectedItem = data.item

    if selectedItem == 'item1' then  -- Remplace 'item1' par l'ID de l'item correspondant
        if isOnCooldown then
            ESX.ShowNotification("Vous ne pouvez pas utiliser cette capacité pour le moment. Attendez la fin du cooldown.")
        else
            isElectrocuteActive = true  -- Activer la capacité
            ESX.ShowNotification("Capacité 'Électrocuter un joueur' activée.")
        end
    elseif selectedItem == 'item2' then  -- Remplace 'item2' par l'ID de l'item correspondant
        if isOnCooldown then
            ESX.ShowNotification("Vous ne pouvez pas utiliser cette capacité pour le moment. Attendez la fin du cooldown.")
        else
            isVehicleDisablingActive = true  -- Activer la capacité désactiver un véhicule
            ESX.ShowNotification("Sélectionnez un véhicule à désactiver.")
            ActivateVehicleDisablingMode()
        end
    end

    -- Fermer le menu après la sélection
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideMenu' })
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    -- Fermer le menu
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideMenu' })
    cb('ok')
end)

function HasImplants(targetPlayer)
    -- Supposons que vous puissiez obtenir les implants d'un autre joueur via un événement ou une méthode
    local targetImplants = {} -- Remplacez cela par la méthode réelle pour obtenir les implants du joueur ciblé
    -- Exemple d'appel de méthode pour obtenir les implants du joueur cible
    -- targetImplants = GetPlayerImplants(targetPlayer) -- Vous devrez créer cette méthode côté serveur
    return targetImplants and next(targetImplants) ~= nil
end

-- Associer la touche 'i' à l'ouverture du menu Net Runner
RegisterCommand('openNetRunnerMenu', function()
    if CanOpenNetRunnerMenu() then
        OpenNetRunnerMenu()
    end
end, false)

-- Enregistrer la touche 'i' comme raccourci pour la commande openNetRunnerMenu
RegisterKeyMapping('openNetRunnerMenu', 'Ouvrir le menu Net Runner', 'keyboard', 'i')

--verifier si un vehicule est sur la liste noirs
function IsVehicleNonAffect(vehicle)
    if not DoesEntityExist(vehicle) then
        print("Erreur : Le véhicule n'existe pas.")
        return false
    end

    local model = GetEntityModel(vehicle)
    for _, v in ipairs(nonAffectVehicles) do
        if model == v then
            return true
        end
    end
    return false
end

-- Fonction pour dégrader l'implant
function ImplantCapabilities.DegradeImplant(slot, implantType, amount)
    if playerImplants[slot] and playerImplants[slot].type == implantType then
        -- Si `degradation` ou `side_effect_threshold` est nil, les initialiser avec des valeurs par défaut
        if playerImplants[slot].degradation == nil then
            playerImplants[slot].degradation = 100
        end

        if playerImplants[slot].side_effect_threshold == nil then
            playerImplants[slot].side_effect_threshold = Config.Implants[implantType].side_effect_threshold or 20
        end

        local currentDegradation = playerImplants[slot].degradation
        local sideEffectThreshold = playerImplants[slot].side_effect_threshold

        playerImplants[slot].degradation = math.max(currentDegradation - amount, 0)

        -- Vérifiez si des effets secondaires doivent être appliqués
        if playerImplants[slot].degradation <= sideEffectThreshold then
            ESX.ShowNotification("Vous commencez à ressentir des effets secondaires en raison de la dégradation de votre implant " .. implantType .. ".")
            print("Effets secondaires appliqués pour l'implant " .. implantType .. " (slot: " .. slot .. ").")
        end

        -- Sauvegarder les implants après la dégradation
        SavePlayerImplants(GetPlayerIdentifier())
    end
end

-- Gestion des dégâts reçus
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local attacker = args[2]
        local bone, damage = GetPedLastDamageBone(victim), args[6]

        if victim == PlayerPedId() then
            local currentShield = GetPedArmour(victim)
            print("Bouclier restant: " .. currentShield .. " points.")

            -- Vérifier si le coup a touché la tête
            if bone == 31086 and ImplantCapabilities.HasImplant("plaque_faciale_renforcee") then
                -- Restituer la moitié des dégâts reçus à la tête en santé
                local healthRegen = damage / 2
                local currentHealth = GetEntityHealth(victim)
                SetEntityHealth(victim, math.min(currentHealth + healthRegen, GetEntityMaxHealth(victim)))
                print("Santé régénérée de " .. healthRegen .. " points grâce à l'implant plaque_faciale_renforcee.")
            end

            -- Déclencher la régénération du bouclier uniquement si le bouclier est épuisé
            if currentShield > 0 and currentShield < shieldLevel then
                ImplantCapabilities.StartShieldRegen()
            elseif currentShield <= 0 then
                print("Bouclier à zéro, régénération nécessaire.")
            end
        end
    end
end)

-- Fonction pour régénérer le bouclier après 1 minute sans combat
function ImplantCapabilities.StartShieldRegen()
    Citizen.CreateThread(function()
        Citizen.Wait(60000)  -- Attendre 1 minute après avoir reçu des dégâts

        local playerPed = PlayerPedId()

        -- Vérifiez si le joueur est toujours en combat
        if not IsPedInCombat(playerPed) then
            -- Vérifiez si l'implant armure_sous_cutanee ou plaque_faciale_renforcee est toujours actif
            if ImplantCapabilities.HasImplant("armure_sous_cutanee") or ImplantCapabilities.HasImplant("plaque_faciale_renforcee") then
                local currentShield = GetPedArmour(playerPed)

                -- Vérifiez si le bouclier actuel est inférieur au maximum
                if currentShield < shieldLevel then
                    local newShield = math.min(shieldLevel, currentShield + 10)  -- Régénérer 10 points à la fois
                    SetPedArmour(playerPed, newShield)
                    print("Bouclier régénéré à " .. newShield .. " points.")
                else
                    print("Bouclier déjà au maximum.")
                end
            else
                print("Régénération annulée : aucun implant armure_sous_cutanee ou plaque_faciale_renforcee actif.")
            end
        else
            print("Régénération du bouclier annulée, le joueur est encore en combat.")
        end
    end)
end

-- Boucle pour afficher la vitesse actuelle du joueur lorsqu'il court
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Ajuste ce délai selon tes besoins
        local playerPed = PlayerPedId()
        if IsPedSprinting(playerPed) then
            local currentSpeed = GetEntitySpeed(playerPed)
            local currentHealth = GetEntityHealth(playerPed)
            print("Vitesse actuelle: " .. currentSpeed * 3.6 .. " km/h")
            print("Santé actuelle: " .. currentHealth .. " / " .. GetEntityMaxHealth(playerPed))
        end
    end
end)



function DisplayDamageDealt(damage)
    lastDamageDealt = damage
    print("Dégâts infligés: " .. lastDamageDealt)
    -- Vous pouvez également afficher cette information à l'écran via une notification ESX ou un autre moyen
    ESX.ShowNotification("Dégâts infligés: " .. lastDamageDealt)
end

-- Écouter l'événement de coup
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if IsPedInMeleeCombat(PlayerPedId()) then
            local playerPed = PlayerPedId()
            local targetPed = GetMeleeTargetForPed(playerPed)
            if targetPed and DoesEntityExist(targetPed) then
                -- Calculer les dégâts infligés (exemple simple)
                local currentHealth = GetEntityHealth(targetPed)
                Citizen.Wait(100) -- Attendre un court instant pour capturer les dégâts après l'impact
                local newHealth = GetEntityHealth(targetPed)
                local damageDealt = currentHealth - newHealth

                if damageDealt > 0 then
                    DisplayDamageDealt(damageDealt)
                end
            end
        end
    end
end)

-- Fonction pour gérer les effets automatiques dans une boucle
function ImplantCapabilities.ManagePassiveEffects()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0) -- Chaque frame

            -- Réinitialiser les capacités d'abord
            ImplantCapabilities.ResetCapabilities()

            -- Appliquer les capacités basées sur les implants actuels
            local activeCapabilities = {}

            -- Appliquer les effets si les implants sont présents
            if ImplantCapabilities.HasImplant("jambe_guepard") then
                local level = playerImplants["jambes"].level
                local moveRateOverride = 1.0 + (level * 2) -- Ajustez ce multiplicateur selon vos besoins (Max 10.0)
                SetPedMoveRateOverride(PlayerPedId(), moveRateOverride)
                table.insert(activeCapabilities, "Vitesse de course augmentée (jambe_guepard)")
                print("Vitesse de course augmentée de " .. (level * 200) .. "% grâce à l'implant jambe_guepard")
            end

            if ImplantCapabilities.HasImplant("bras_gorille") then
                local level = playerImplants["bras"].level
                local damageMultiplier = 1.0 + (level * 0.3)
                SetWeaponDamageModifierThisFrame(GetHashKey("WEAPON_UNARMED"), damageMultiplier)
                table.insert(activeCapabilities, "Force des coups augmentée (bras_gorille)")
                print("Force des coups augmentée de " .. (level * 30) .. "% grâce à l'implant bras_gorille")
            end

            if ImplantCapabilities.HasImplant("systeme_reconstitution") then
                local level = playerImplants["torse"].level
                local maxHealth = GetEntityMaxHealth(PlayerPedId())
                local healthRegen = (maxHealth * 0.002) * level
                local currentHealth = GetEntityHealth(PlayerPedId())
                SetEntityHealth(PlayerPedId(), math.min(currentHealth + healthRegen, maxHealth))
                table.insert(activeCapabilities, "Régénération de la santé (systeme_reconstitution)")
                print("Santé régénérée de " .. healthRegen .. " points grâce à l'implant systeme_reconstitution")
            end

            -- Vérifier si aucune capacité n'est active
            if #activeCapabilities == 0 then
                print("Aucune capacité active.")
            else
                print("Capacités actives : " .. table.concat(activeCapabilities, ", "))
            end
        end
    end)
end

function StartArmorRegen()
    Citizen.CreateThread(function()
        Citizen.Wait(60000)  -- Attendre 1 minute après avoir reçu des dégâts
        local playerPed = PlayerPedId()
        local currentHealth = GetEntityHealth(playerPed)
        local maxHealth = GetEntityMaxHealth(playerPed)

        -- Vérifier si le joueur est à 200 HP et a un implant armure_sous_cutanee
        if currentHealth == 200 and ImplantCapabilities.HasImplant("armure_sous_cutanee") then
            if playerImplants["torse"] and playerImplants["torse"].level then
                local level = playerImplants["torse"].level
                local additionalHealth = math.floor(maxHealth * 0.2 * level)  -- Calcul de l'augmentation de la santé

                while currentHealth < (200 + additionalHealth) do
                    currentHealth = GetEntityHealth(playerPed)
                    if currentHealth < 200 then
                        break  -- Arrêter la régénération si la santé du joueur est inférieure à 200
                    end
                    -- Régénérer l'armure petit à petit
                    SetEntityHealth(playerPed, math.min(currentHealth + 5, 200 + additionalHealth))
                    Citizen.Wait(1000)  -- Attendre 1 seconde entre chaque régénération
                end

                print("Régénération d'armure jusqu'à " .. (200 + additionalHealth) .. " points grâce à l'implant armure_sous_cutanee")
            end
        end
    end)
end

-- Fonctions pour les capacités manuelles (exemple seulement)
function ImplantCapabilities.ActivateNightVision()
    if ImplantCapabilities.HasImplant("vision_nocturne") then
        SetNightvision(true)
        print("Vision nocturne activée grâce à l'implant vision_nocturne")
    else
        print("Le joueur n'a pas l'implant requis pour cette capacité.")
    end
end

-- Chargement des implants et activation des capacités automatiques
RegisterNetEvent('implant:load')
AddEventHandler('implant:load', function(implants, chargeImmuNeuro)
    playerImplants = implants or {}
    playerChargeImmuNeuro = chargeImmuNeuro or 0

    -- Attendre 1 minute avant d'appliquer les effets
    Citizen.SetTimeout(60000, function()
        print("Vérification des implants 1 minute après la connexion.")
        ImplantCapabilities.ApplyPassiveEffects()
    end)
end)

-- Exemple d'activation d'une capacité manuelle
RegisterCommand("nightvision", function()
    ImplantCapabilities.ActivateNightVision()
end, false)

-- Exemple d'activation d'une capacité manuelle
RegisterCommand("nightvision", function()
    ImplantCapabilities.ActivateNightVision()
end, false)

-- Commande pour utiliser une seringue
RegisterCommand("usesyringe", function(source, args)
    local reductionAmount = tonumber(args[1]) or 10
    DecreaseChargeImmuNeuro(reductionAmount)
    ESX.ShowNotification("Vous avez utilisé une seringue. Charge ImmuNeuro réduite de " .. reductionAmount .. "%.")
end, false)

-- Commande pour donner un implant
RegisterCommand("giveimplant", function(source, args)
    local implantType = args[1]
    local level = tonumber(args[2]) or 1
    local playerId = GetPlayerServerId(PlayerId())

    if Config.Implants[implantType] then
        InstallImplant(playerId, implantType, level)
        ESX.ShowNotification("Vous avez reçu l'implant " .. implantType .. " au niveau " .. level)
    else
        ESX.ShowNotification("Type d'implant invalide.")
    end
end, false)

-- Fonction pour récupérer l'identifiant du joueur
function GetPlayerIdentifier()
    return ESX.GetPlayerData().identifier
end

-- Fonction pour sauvegarder les implants du joueur
function SavePlayerImplants(identifier)
    local implants = {}

    for slot, implant in pairs(playerImplants) do
        implants[#implants + 1] = {
            implant_slot = slot,
            implant_type = implant.type,
            implant_level = implant.level,
            implant_health = implant.degradation
        }
    end

    TriggerServerEvent('implant:save', implants, playerChargeImmuNeuro, identifier)
end

-- Vérification après ajout d'un implant
function InstallImplant(playerId, implantType, level)
    local implantData = Config.Implants[implantType]
    if implantData then
        local slot = implantData.slot

        -- Vérifier si l'implant est déjà installé
        if playerImplants[slot] and playerImplants[slot].type == implantType then
            ESX.ShowNotification("Cet implant est déjà installé.")
            return  -- Arrêter la fonction si l'implant est déjà installé
        end

        -- Réinitialiser les capacités si un implant est remplacé
        if playerImplants[slot] then
            ImplantCapabilities.ResetCapabilities()
        end

        -- Installer le nouvel implant
        playerImplants[slot] = {
            type = implantType,
            level = level,
            degradation = 100,
            side_effect_threshold = implantData.side_effect_threshold or 20  -- Utilise la valeur définie dans Config ou 20 par défaut
        }

        IncreaseChargeImmuNeuro(25)
        ESX.ShowNotification("Vous avez installé l'implant " .. implantType .. " au niveau " .. level)
        SavePlayerImplants(GetPlayerIdentifier())

        -- Appliquer les capacités immédiatement après l'installation de l'implant
        ImplantCapabilities.ApplyPassiveEffects()
    else
        ESX.ShowNotification("Type d'implant invalide.")
    end
end

-- Événement pour sauvegarder les implants à la demande du serveur
RegisterNetEvent('implant:requestSave')
AddEventHandler('implant:requestSave', function(identifier)
    SavePlayerImplants(identifier)
end)

-- Fonction pour augmenter la charge ImmuNeuro
function IncreaseChargeImmuNeuro(amount)
    playerChargeImmuNeuro = playerChargeImmuNeuro + amount
    if playerChargeImmuNeuro > 100 then
        playerChargeImmuNeuro = 100
    end
    CheckImmuNeuroEffects()
end

-- Fonction pour diminuer la charge ImmuNeuro
function DecreaseChargeImmuNeuro(amount)
    playerChargeImmuNeuro = playerChargeImmuNeuro - amount
    if playerChargeImmuNeuro < 0 then
        playerChargeImmuNeuro = 0
    end

    -- Ajoutez ce print pour vérifier la valeur de charge après réduction
    print("Nouvelle valeur de charge ImmuNeuro après réduction: " .. playerChargeImmuNeuro)

    -- Mise à jour de la base de données
    TriggerServerEvent('implant:updateChargeImmuNeuro', playerChargeImmuNeuro)
end


function RandomRange(min, max)
    return math.random() * (max - min) + min
end

-- Fonction pour vérifier les effets secondaires de la charge ImmuNeuro
function CheckImmuNeuroEffects()
    if playerChargeImmuNeuro >= 50 then
        ESX.ShowNotification("Vous commencez à ressentir les effets secondaires des implants.")
    end
end

--chargeImmuNeuro

-- Chargement des implants et activation des capacités automatiques
RegisterNetEvent('implant:load')
AddEventHandler('implant:load', function(implants, chargeImmuNeuro)
    playerImplants = implants or {}
    playerChargeImmuNeuro = chargeImmuNeuro or 0

    -- Appliquer les effets liés à la charge ImmuNeuro dès le chargement
    CheckImmuNeuroEffects()

    -- Attendre 1 minute avant d'appliquer les effets des implants
    Citizen.SetTimeout(60000, function()
        print("Vérification des implants 1 minute après la connexion.")
        ImplantCapabilities.ApplyPassiveEffects()
    end)
end)

-- Commande pour définir la charge ImmuNeuro du joueur
RegisterCommand("charge", function(source, args)
    local newCharge = tonumber(args[1])
    if newCharge then
        SetImmuNeuroCharge(newCharge)
        ESX.ShowNotification("Votre charge ImmuNeuro a été définie à " .. newCharge .. "%.")
    else
        ESX.ShowNotification("Valeur invalide. Veuillez entrer un nombre.")
    end
end, false)

-- Fonction pour définir la charge ImmuNeuro
function SetImmuNeuroCharge(amount)
    playerChargeImmuNeuro = math.min(100, math.max(0, amount)) -- S'assurer que la charge est entre 0 et 100
    CheckImmuNeuroEffects() -- Vérifier et appliquer les effets en fonction de la nouvelle charge
    
    -- Envoyer la nouvelle valeur au serveur pour sauvegarde
    TriggerServerEvent('implant:updateChargeImmuNeuro', playerChargeImmuNeuro)
end

function ApplyLightEffects()
    local duration = RandomRange(5000, 3000)  -- Durée aléatoire entre 0.5 et 3 secondes
    StartScreenEffect("HeistLocate", duration, true)
    ESX.ShowNotification("Votre charge ImmuNeuro commence a augmenter")
    Citizen.Wait(duration)
    StopScreenEffect("HeistLocate")
end

function ApplyModerateEffects()
    local duration = RandomRange(1500, 4500)  -- Durée aléatoire entre 1.5 et 4.5 secondes
    StartScreenEffect("HeistLocate", duration, true)
    Citizen.Wait(duration)
    StopScreenEffect("HeistLocate")

    TaskPlayAnim(PlayerPedId(), "anim@scripted@ulp_missions@injured_agent@", "vomit", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(7000)
    TaskPlayAnim(PlayerPedId(), "misscarsteal4@actor", "confused", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(7000)
end

function ApplySevereEffects()
    local duration = RandomRange(1500, 45000)  -- Durée aléatoire entre 4.5 et 45 secondes
    StartScreenEffect("HeistLocate", duration, true)
    Citizen.Wait(duration)
    StopScreenEffect("HeistLocate")

    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
    TaskPlayAnim(PlayerPedId(), "drunk_driver_stand_loop_dd1", "confused_small", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(7000)
    TaskPlayAnim(PlayerPedId(), "sleep_loop", "sleeping", 8.0, -8.0, -1, 1, 0, false, false, false)
    Citizen.Wait(7000)
end

-- Fonction pour charger un modèle
function LoadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Citizen.Wait(0)
    end
end

function SpawnPanicEnemies()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local pedModel = GetHashKey("a_m_m_acult_01")  -- Modèle de pédestre

    LoadModel(pedModel)  -- Charger le modèle

    print("Coordonnées du joueur:", playerCoords.x, playerCoords.y, playerCoords.z)

    for i = 1, 3 do
        local spawnX = playerCoords.x + math.random(-3, 3)
        local spawnY = playerCoords.y + math.random(-3, 3)
        local spawnZ = playerCoords.z + 1.0  -- Légèrement au-dessus du sol
        print("Tentative de spawn de l'ennemi", i, "à", spawnX, spawnY, spawnZ)

        -- Créer l'ennemi
        local enemy = CreatePed(4, pedModel, spawnX, spawnY, spawnZ, 0.0, false, false)

        if DoesEntityExist(enemy) then
            print("Ennemi", i, "créé avec succès")
            TaskCombatPed(enemy, playerPed, 0, 16)
            SetPedAsEnemy(enemy, true)

            -- Rendre le PNJ invulnérable à tout sauf aux balles
            SetEntityProofs(enemy, false, true, true, true, true, true, true, false)

            -- Surveiller la mort du PNJ
            MonitorEnemyDeath(enemy)
        else
            print("Échec de la création de l'ennemi", i)
        end
    end

    -- Libérer le modèle après utilisation
    SetModelAsNoLongerNeeded(pedModel)
end

-- Fonction pour surveiller et gérer la mort du PNJ
function MonitorEnemyDeath(enemy)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            if IsEntityDead(enemy) then
                print("Ennemi mort, suppression...")
                DeleteEntity(enemy)  -- Supprime le PNJ de l'existence
                break
            end
        end
    end)
end

function ApplyCyberpsychosisEffects()
    StartScreenEffect("DeathFailOut", 0, true)
    Citizen.Wait(20000)
    StopScreenEffect("DeathFailOut")

    SpawnPanicEnemies()
end

-- Fonction pour appliquer les effets légers en boucle
function ApplyLightEffectsLoop()
    Citizen.CreateThread(function()
        while playerChargeImmuNeuro >= 50 and playerChargeImmuNeuro < 71 do
            ApplyLightEffects()
            Citizen.Wait(math.random(180, 360) * 1000)  -- Attendre entre 3 et 6 minutes avant de réappliquer les effets
        end
    end)
end

-- Fonction pour appliquer les effets modérés en boucle
function ApplyModerateEffectsLoop()
    Citizen.CreateThread(function()
        while playerChargeImmuNeuro >= 71 and playerChargeImmuNeuro < 86 do
            ApplyModerateEffects()
            Citizen.Wait(math.random(120, 260) * 1000)  -- Attendre entre 2 et 4.3 minutes avant de réappliquer les effets
        end
    end)
end

-- Fonction pour appliquer les effets sévères en boucle
function ApplySevereEffectsLoop()
    Citizen.CreateThread(function()
        while playerChargeImmuNeuro >= 86 and playerChargeImmuNeuro < 97 do
            ApplySevereEffects()
            Citizen.Wait(math.random(30, 45) * 1000)  -- Attendre entre 1 et 1.3 minutes avant de réappliquer les effets
        end
    end)
end

-- Fonction pour vérifier et appliquer les effets en fonction de la charge ImmuNeuro
function CheckImmuNeuroEffects()
    Citizen.CreateThread(function()
        while playerChargeImmuNeuro >= 50 do
            if playerChargeImmuNeuro >= 97 then
                ApplyCyberpsychosisEffects()
                Citizen.Wait(math.random(60, 120) * 1000)  -- Attendre entre 1 et 2 minutes avant de réappliquer les effets pour la cyberpsychose
            elseif playerChargeImmuNeuro >= 86 then
                ApplySevereEffectsLoop()
                -- La fonction ApplySevereEffectsLoop gère déjà la boucle et l'attente
                break -- Sortir de la boucle principale pour laisser ApplySevereEffectsLoop gérer les effets
            elseif playerChargeImmuNeuro >= 71 then
                ApplyModerateEffectsLoop()
                -- La fonction ApplyModerateEffectsLoop gère déjà la boucle et l'attente
                break -- Sortir de la boucle principale pour laisser ApplyModerateEffectsLoop gérer les effets
            elseif playerChargeImmuNeuro >= 50 then
                ApplyLightEffectsLoop()
                -- La fonction ApplyLightEffectsLoop gère déjà la boucle et l'attente
                break -- Sortir de la boucle principale pour laisser ApplyLightEffectsLoop gérer les effets
            end

            -- Re-check the charge level to ensure the loop continues correctly
            if playerChargeImmuNeuro < 50 then
                ESX.ShowNotification("Les effets secondaires ont disparu car la charge ImmuNeuro est inférieure à 50%.")
                break
            end
        end
    end)
end

-- Callback pour l'immunosuppresseur standard
exports('useImmunosuppresseur', function(data, slot)
    local playerPed = PlayerPedId()
    local chargeImmuNeuro = GetPlayerChargeImmuNeuro() -- Remplacez par la méthode pour obtenir la charge ImmuNeuro actuelle du joueur

    if chargeImmuNeuro > 97 then
        lib.notify({type = 'error', description = "Votre charge ImmuNeuro est trop élevée pour utiliser cet item."})
        return
    end

    exports.ox_inventory:useItem(data, function(data)
        if data then
            -- Réduire la charge ImmuNeuro
            DecreaseChargeImmuNeuro(15)
            lib.notify({description = "Votre charge ImmuNeuro a été réduite de 15%."})
        end
    end)
end)

-- Callback pour l'immunosuppresseur avancé
exports('useImmunosuppresseurAvance', function(data, slot)
    local playerPed = PlayerPedId()
    local chargeImmuNeuro = GetPlayerChargeImmuNeuro() -- Remplacez par la méthode pour obtenir la charge ImmuNeuro actuelle du joueur

    if chargeImmuNeuro > 97 then
        lib.notify({type = 'error', description = "Votre charge ImmuNeuro est trop élevée pour utiliser cet item."})
        return
    end

    exports.ox_inventory:useItem(data, function(data)
        if data then
            -- Réduire la charge ImmuNeuro
            DecreaseChargeImmuNeuro(25)
            lib.notify({description = "Votre charge ImmuNeuro a été réduite de 25%."})
        end
    end)
end)

function GetPlayerChargeImmuNeuro()
    return playerChargeImmuNeuro
end


--charcudocjob

-- Ajout d'une option 'examiner le patient' avec ox_target
exports.ox_target:addGlobalPlayer({
    {
        name = 'examine_patient',
        label = 'Examiner le patient',
        icon = 'fas fa-user-md',
        distance = 2.5,
     --  items = 'item_medical', -- Remplacez 'item_medical' par l'item que le Charcudoc doit avoir pour utiliser cette option.
        canInteract = function(entity, distance, coords, name, bone)
            local xPlayer = ESX.GetPlayerData()
            return xPlayer.job.name == 'charcudoc'
        end,
        onSelect = function(data)
            local targetPlayer = data.entity
            if targetPlayer and targetPlayer ~= PlayerId() then
                -- Ouvrir le menu d'examen du patient
                OpenPatientExaminationMenu(targetPlayer)
            end
        end
    }
})

-- Fonction pour ouvrir le menu d'examen du patient
function OpenPatientExaminationMenu(targetPlayer)
    -- Obtenir les implants du joueur cible depuis le serveur
    ESX.TriggerServerCallback('implant:getPlayerImplants', function(implants)
        local elements = {}

        -- Ajouter les implants au menu
        for slot, implant in pairs(implants) do
            table.insert(elements, {label = slot .. ": " .. (implant.type or "Aucun implant"), value = implant.type})
        end

        -- Ajouter les options de mise en place et de retrait d'implants
        table.insert(elements, {label = "Mettre un implant", value = "add_implant"})
        table.insert(elements, {label = "Enlever l'implant", value = "remove_implant"})

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'patient_examination', {
            title = "Examen du patient",
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            if data.current.value == "add_implant" then
                OpenAddImplantMenu(targetPlayer)
            elseif data.current.value == "remove_implant" then
                OpenRemoveImplantMenu(targetPlayer)
            end
        end, function(data, menu)
            menu.close()
        end)
    end, GetPlayerServerId(targetPlayer))
end

-- Fonction pour ouvrir le menu de mise en place d'un implant
function OpenAddImplantMenu(targetPlayer)
    ESX.TriggerServerCallback('implant:getAvailableImplants', function(availableImplants)
        local elements = {}

        for _, implant in pairs(availableImplants) do
            table.insert(elements, {label = implant.label, value = implant.type})
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'add_implant', {
            title = "Mettre un implant",
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            -- Confirmation de la mise en place de l'implant
            ESX.UI.Menu.CloseAll()
            TriggerServerEvent('implant:addImplant', GetPlayerServerId(targetPlayer), data.current.value)
        end, function(data, menu)
            menu.close()
        end)
    end)
end

-- Fonction pour ouvrir le menu de retrait d'un implant
function OpenRemoveImplantMenu(targetPlayer)
    ESX.TriggerServerCallback('implant:getPlayerImplants', function(implants)
        local elements = {}

        for slot, implant in pairs(implants) do
            if implant.type then
                table.insert(elements, {label = slot .. ": " .. implant.type, value = implant.type})
            end
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'remove_implant', {
            title = "Enlever un implant",
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            -- Confirmation du retrait de l'implant
            ESX.UI.Menu.CloseAll()
            TriggerServerEvent('implant:removeImplant', GetPlayerServerId(targetPlayer), data.current.value)
        end, function(data, menu)
            menu.close()
        end)
    end, GetPlayerServerId(targetPlayer))
end
