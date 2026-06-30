# SmartSpawn — User Guide

A practical guide for server owners and players using SmartSpawn.

---

## For Server Owners

### Quick Start

1. Drop `qol-smartspawn` into your `resources` folder
2. Add `ensure qol-smartspawn` to `server.cfg`
3. Restart your server
4. Players can immediately use `/spawn <model>` in chat

### Setting Up Permission Tiers

SmartSpawn uses FiveM's built-in ACE permission system. You don't need any additional framework.

**1. Assign tiers in `server.cfg`:**

```cfg
# All players get default tier automatically
# Assign VIP tier to specific players:
add_principal identifier.steam:11000010abcdef smartspawn.tier.vip

# Assign admin tier (vMenu, Badger, or manual):
add_principal group.admin smartspawn.tier.admin
```

**2. Configure allowed categories in `shared/config.lua`:**

```lua
-- VIP can spawn everything except military/emergency
Config.TierCategories.vip = {'compacts', 'sedans', 'suv', 'sports', 'super', 'muscle', 'motorcycles', 'offroad', 'vans', 'cycles', 'helicopters', 'planes', 'boats'}

-- Default players can only spawn everyday vehicles
Config.TierCategories.default = {'compacts', 'sedans', 'suv', 'muscle', 'motorcycles', 'offroad', 'vans', 'cycles'}
```

### Customizing Cooldowns

```lua
Config.Cooldown = {
    enabled  = true,
    default  = 30,   -- Normal players wait 30s
    vip      = 10,   -- VIPs wait 10s
    admin    = 0,    -- Admins: no cooldown
}
```

### Creating No-Spawn Zones

Prevent spawning in specific areas (useful for event zones, admin areas, etc.):

```lua
Config.NoSpawnZones = {
    { vec3(-1037.0, -2737.0, 20.0), 50.0 },  -- LSIA Airport
    { vec3(215.0, -808.0, 30.0), 30.0 },      -- Legion Square
    { vec3(-1388.0, -584.0, 31.0), 40.0 },    -- Vinewood PD
}
```

### Adding a Vehicle Blocklist

Prevent specific vehicles from being spawned by anyone:

```lua
Config.Blocklist = {
    'rhino',     -- Tank
    'hydra',    -- Jet
    'lazer',    -- Fighter jet
    'valkyrie', -- Attack helicopter
}
```

### Changing the Command

If `/spawn` conflicts with another resource, change it:

```lua
Config.Command = 'vspawn'  -- Players will use /vspawn sultan
```

### Using with Other Resources

SmartSpawn exports server-side functions:

```lua
-- Check if a player is on cooldown
local cd = exports['qol-smartspawn']:getCooldown(source)
if cd > 0 then
    print("Player has " .. cd .. "s cooldown remaining")
end

-- Clear a player's cooldown (e.g., after completing a quest)
exports['qol-smartspawn']:clearCooldown(source)

-- Get vehicles spawned by a player
local vehicles = exports['qol-smartspawn']:getPlayerVehicles(source)
for i, netId in ipairs(vehicles.netIds) do
    print("Vehicle " .. vehicles.models[i] .. " netId: " .. netId)
end
```

### Multi-Language Setup

```lua
Config.Language = 'es'  -- Spanish
```

To add a new language, copy the English table in `shared/util.lua` and translate the values.

---

## For Players

### How to Spawn a Vehicle

Type in chat:
```
/spawn sultan
```

The vehicle will appear in front of you and you'll be automatically seated.

### Common Vehicle Names

| Vehicle | Command |
|---------|---------|
| Sultan RS | `/spawn sultan` |
| Bati 801 (motorcycle) | `/spawn bati` |
| Sanchez (dirt bike) | `/spawn sanchez` |
| Dominator (muscle) | `/spawn dominator` |
| Sentinel (sports) | `/spawn sentinel` |
| Brioso (compact) | `/spawn brioso` |
| Granger (SUV) | `/spawn granger` |
| Rat Loader (utility) | `/spawn ratloader` |
| Bifta (off-road) | `/spawn bifta` |
| Akuma (motorcycle) | `/spawn akuma` |

> **Tip:** You can find any vehicle model name on [GTA Wiki](https://gta.fandom.com/wiki/Vehicles_in_GTA_V) or by using the FiveM native `GetEntityModel(entity)`.

### Why Can't I Spawn a Certain Vehicle?

There are several reasons a vehicle might be denied:

1. **Wrong category for your tier** — Your tier doesn't allow that vehicle class (e.g., Default tier can't spawn Super cars)
2. **Blocklisted** — The vehicle is on the server's blocklist
3. **Cooldown active** — You're on cooldown. Wait or ask an admin to clear it
4. **No-spawn zone** — You're in an area where spawning is disabled. Move to a different location
5. **Max vehicles reached** — You have too many vehicles spawned. Delete one or ask an admin
6. **Invalid model** — The model name doesn't exist in GTA V. Check spelling

### Admin Commands

If you're an admin:

| Command | Description |
|---------|-------------|
| `/spawnclear` | Clear your own cooldown |
| `/spawnclear <playerId>` | Clear another player's cooldown |

---

## Troubleshooting

### The command isn't working

**Check:**
1. Is the resource running? Type `/refresh` then `ensure qol-smartspawn` in server console
2. Is `Config.Enabled` set to `true` in `shared/config.lua`?
3. Are you typing the correct command? (Default: `/spawn`)

### Vehicle doesn't appear

**Possible causes:**
- You're in a no-spawn zone (move to an open area)
- The model name is misspelled (check [GTA Wiki](https://gta.fandom.com/wiki/Vehicles_in_GTA_V))
- There's not enough space in front of you (try in an open area)

### "Your tier does not allow spawning vehicles in this category"

Your permission tier doesn't include that vehicle category. Ask an admin to adjust `Config.TierCategories` or upgrade your tier.

### Notifications not showing

If you're not seeing notifications:
1. Check if you have ox_lib installed — SmartSpawn uses it if available
2. Without ox_lib, SmartSpawn uses native GTA V notifications which always appear
3. Check `Config.NotifyDuration` in the config (default: 5000ms)

### Performance

SmartSpawn is lightweight:
- No loops on the client (event-driven)
- Server cleanup thread runs every 5 minutes only
- No database required
- No framework dependency

---

## Best Practices for Server Owners

1. **Start with default config** — Test before changing anything
2. **Set reasonable cooldowns** — 30s for default is a good balance
3. **Limit max vehicles** — 3 is plenty for most servers
4. **Use no-spawn zones** — Protect event areas and spawn points
5. **Keep the blocklist small** — Only block truly problematic vehicles
6. **Test permission tiers** — Verify each tier works before going live