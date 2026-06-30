-- ═══════════════════════════════════════════════════════════════════════════════
-- ATM System — Client Blips
-- client/blips.lua
--
-- Creates bank blips on the map. ATMs do not get blips by default.
-- ═══════════════════════════════════════════════════════════════════════════════

CreateThread(function()
    if not Config.Enabled then return end

    for _, bank in ipairs(Config.BankBlips) do
        local blip = AddBlipForCoord(bank.coords.x, bank.coords.y, bank.coords.z)
        SetBlipSprite(blip, Config.BankBlipSprite)
        SetBlipColour(blip, Config.BankBlipColor)
        SetBlipScale(blip, Config.BankBlipScale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(bank.name)
        EndTextCommandSetBlipName(blip)
    end
end)