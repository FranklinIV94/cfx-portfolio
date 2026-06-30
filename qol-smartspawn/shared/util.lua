-- ═══════════════════════════════════════════════════════════════════════════════
-- SmartSpawn — Shared Utilities
-- shared/util.lua
-- Functions used by both client and server.
-- ═══════════════════════════════════════════════════════════════════════════════

Util = {}

--- Check if a vehicle model exists in the game by attempting to load it.
--- Called on the client side (server can't load models).
--- @param model string|number The model name (hash) or model hash
--- @return boolean valid Whether the model exists and is a vehicle
function Util.IsValidVehicleModel(model)
    if type(model) == 'string' then
        model = joaat(model)
    end

    if not IsModelInCdimage(model) then
        return false
    end
    if not IsModelAVehicle(model) then
        return false
    end

    return true
end

--- Get the vehicle category from the game's classification.
--- @param model number The vehicle model hash
--- @return string category The category name
function Util.GetVehicleCategory(model)
    local classNum = GetVehicleClassFromName(model)
    local categories = {
        [0]  = 'compacts',
        [1]  = 'sedans',
        [2]  = 'suv',
        [3]  = 'sports',
        [4]  = 'sportsclassics',
        [5]  = 'super',
        [6]  = 'muscle',
        [7]  = 'sportsclassics',
        [8]  = 'motorcycles',
        [9]  = 'offroad',
        [10] = 'industrial',
        [11] = 'utility',
        [12] = 'vans',
        [13] = 'cycles',
        [14] = 'boats',
        [15] = 'helicopters',
        [16] = 'planes',
        [17] = 'service',
        [18] = 'emergency',
        [19] = 'military',
        [20] = 'commercial',
        [21] = 'trains',
    }
    return categories[classNum] or 'unknown'
end

--- Check whether a category is allowed for a given tier.
--- @param category string The vehicle category
--- @param tier string The player's tier
--- @return boolean allowed
function Util.IsCategoryAllowed(category, tier)
    local allowed = Config.TierCategories[tier]
    if not allowed then return false end
    if allowed == 'all' then return true end
    for _, cat in ipairs(allowed) do
        if cat == category then
            return true
        end
    end
    return false
end

--- Check if a model is on the blocklist.
--- @param model string The model name
--- @return boolean blocked
function Util.IsBlocklisted(model)
    for _, blocked in ipairs(Config.Blocklist) do
        if blocked == model then
            return true
        end
    end
    return false
end

--- Check if a position falls within any no-spawn zone.
--- @param coords vec3 The position to check
--- @return boolean inZone, vec3|nil zoneCenter
function Util.IsInNoSpawnZone(coords)
    for _, zone in ipairs(Config.NoSpawnZones) do
        local center, radius = zone[1], zone[2]
        local dist = #(coords - center)
        if dist <= radius then
            return true, center
        end
    end
    return false, nil
end

--- Localized strings. Extend with new languages as needed.
Util.Locales = {
    ['en'] = {
        ['resource_disabled']  = 'SmartSpawn is currently disabled.',
        ['invalid_model']       = 'Vehicle model "%s" does not exist.',
        ['blocklisted']         = 'This vehicle is blocklisted and cannot be spawned.',
        ['cooldown_active']     = 'Please wait %d seconds before spawning another vehicle.',
        ['category_denied']     = 'Your tier does not allow spawning vehicles in the "%s" category.',
        ['max_vehicles']        = 'You have reached the max vehicle limit (%d). Delete one first.',
        ['no_spawn_zone']      = 'You cannot spawn vehicles in this area.',
        ['spawned']             = 'Vehicle spawned: %s',
        ['deleted_previous']    = 'Previous vehicle removed.',
        ['no_permission']      = 'You do not have permission to use this command.',
        ['usage']               = 'Usage: /%s <model_name>',
    },
    ['es'] = {
        ['resource_disabled']  = 'SmartSpawn está deshabilitado.',
        ['invalid_model']       = 'El modelo de vehículo "%s" no existe.',
        ['blocklisted']         = 'Este vehículo está bloqueado y no puede ser generado.',
        ['cooldown_active']     = 'Espera %d segundos antes de generar otro vehículo.',
        ['category_denied']     = 'Tu nivel no permite generar vehículos de la categoría "%s".',
        ['max_vehicles']        = 'Has alcanzado el límite de vehículos (%d). Elimina uno primero.',
        ['no_spawn_zone']      = 'No puedes generar vehículos en esta área.',
        ['spawned']             = 'Vehículo generado: %s',
        ['deleted_previous']    = 'Vehículo anterior eliminado.',
        ['no_permission']      = 'No tienes permiso para usar este comando.',
        ['usage']               = 'Uso: /%s <nombre_modelo>',
    },
}

--- Get a localized string.
--- @param key string The locale key
--- @param ... any Format arguments
--- @return string The localized string
function Util.L(key, ...)
    local lang = Config.Language or 'en'
    local str = (Util.Locales[lang] and Util.Locales[lang][key]) or Util.Locales['en'][key] or key
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end