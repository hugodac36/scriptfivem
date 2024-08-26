Config = {}

Config.Implants = {
    ["jambe_guepard"] = {
        slot = "jambes",
        effect = "Augmente la vitesse de course du joueur de 10% par niveau.",
        level_max = 3,
        health_degradation_rate = 2,  -- % par kilomètre parcouru
        charge_immuneuro = 1,         -- % par kilomètre parcouru
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["bras_gorille"] = {
        slot = "bras",
        effect = "Augmente la force des coups de 30% par niveau.",
        level_max = 3,
        health_degradation_rate = 3,  -- % par coup donné
        charge_immuneuro = 2,         -- % par 10 coups donnés
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["systeme_reconstitution"] = {
        slot = "torse",
        effect = "Régénère 2% de la santé totale par minute par niveau.",
        level_max = 4,
        health_degradation_rate = 1,  -- % par heure
        charge_immuneuro = 0.5,       -- % par heure
        side_effect_threshold = 20,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["armure_sous_cutanee"] = {
        slot = "torse",
        effect = "Augmente la sante de 20% par niveau.",
        level_max = 5,
        health_degradation_rate = 2,  -- % par 10 points de dégâts absorbés
        charge_immuneuro = 1,         -- % par 20 points de dégâts absorbés
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["plaque_faciale_renforcee"] = {
        slot = "tete",
        effect = "Augmente la résistance aux balles dans la tête, empêchant le joueur de mourir d'une seule balle.",
        level_max = 3,
        health_degradation_rate = 10, -- % par balle reçue à la tête
        charge_immuneuro = 5,         -- % par balle reçue à la tête
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["mort_d\'adrenaline"] = {
        slot = "tete",
        effect = "Gagne 18% de la santé maximale du joueur par niveau lorsqu'il tue une autre personne.",
        level_max = 3,
        health_degradation_rate = 3,  -- % par kill
        charge_immuneuro = 5,         -- % par kill
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["implant_oracle"] = {
        slot = "tete",
        effect = "Permet d'identifier une personne non masquée en l'analysant.",
        level_max = 3,
        health_degradation_rate = 2,  -- % par analyse
        charge_immuneuro = 1,         -- % par analyse
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["puce_net_runner"] = {
        slot = "tete",
        effect = "Capacités de piratage : électrocuter un joueur, désactiver un implant, désactiver un véhicule.",
        level_max = 3,
        health_degradation_rate = 4,  -- % par utilisation d'une capacité
        charge_immuneuro = 3,         -- % par utilisation d'une capacité
        side_effect_threshold = 20,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["protection_piratage"] = {
        slot = "torse",
        effect = "Annule les attaques des Net Runner (piratage) sur le joueur.",
        level_max = 3,
        health_degradation_rate = 1,  -- % par tentative de piratage bloquée
        charge_immuneuro = 1,         -- % par tentative de piratage bloquée
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["camouflage_facial"] = {
        slot = "tete",
        effect = "Empêche le joueur d'être analysé par l'implant Optique 'The Oracle'.",
        level_max = 1,
        health_degradation_rate = 1,  -- % par jour
        charge_immuneuro = 0.5,       -- % par jour
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["tendons_renforces"] = {
        slot = "jambes",
        effect = "Supprime les dégâts de chute.Petmet  de sauter plus haut",
        level_max = 1,
        health_degradation_rate = 5,  -- % par chute absorbée
        charge_immuneuro = 2,         -- % par chute absorbée
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["bras_serpent"] = {
        slot = "bras",
        effect = "Les coups empoisonnent les ennemis, infligeant 2% de leur santé maximale par seconde pendant 5 secondes.",
        level_max = 3,
        health_degradation_rate = 3,  -- % par coup donné
        charge_immuneuro = 2,         -- % par 5 coups donnés
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    },
    ["vision_nocturne"] = {
        slot = "tete",
        effect = "Permet de voir dans l'obscurité totale.",
        level_max = 1,
        health_degradation_rate = 2,  -- % par utilisation
        charge_immuneuro = 1,         -- % par utilisation
        side_effect_threshold = 25,   -- % de dégradation à partir duquel les effets secondaires apparaissent
    }
}
