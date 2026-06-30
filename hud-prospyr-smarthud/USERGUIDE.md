# Prospyr SmartHUD — Player Guide

**Welcome to SmartHUD!** This guide covers everything players need to use the HUD on your server.

---

## Getting Started

When you join a server running Prospyr SmartHUD, you'll see status bars in the bottom-left corner of your screen. Here's what each one means:

| Icon | Bar | What It Means |
|---|---|---|
| ❤️ | Health | Your current health (red when low) |
| 🛡️ | Armor | Body armor (if equipped) |
| ⚡ | Stamina | Sprint/swim energy |
| 🍖 | Hunger | How full you are (requires ox_status) |
| 💧 | Thirst | Hydration level (requires ox_status) |
| 💵 | Money | Cash on hand + bank balance |
| 🎤 | Voice | Current voice range + talking indicator |

---

## Opening the Settings Panel

Press **F7** (default) to open the SmartHUD settings panel. You can also type `/hudsettings` in chat.

The settings panel lets you:

- **Toggle elements** — show or hide any HUD element
- **Change colors** — customize the theme (primary, background, text, etc.)
- **Adjust bar size** — make bars wider, taller, or change spacing
- **Reposition elements** — drag bars to where you want them
- **Change speed unit** — switch between MPH and KM/H
- **Reset to defaults** — one click to restore original settings

All settings are **saved automatically** and persist across sessions. Your customization follows you.

---

## HUD Elements Explained

### Status Bars

The five status bars (health, armor, stamina, hunger, thirst) show your current condition:

- **Green** = healthy/full
- **Yellow** = moderate
- **Red** = critical — eat, drink, or heal soon!

Bars fade out after 5 seconds of inactivity (by default) to keep your screen clean. They reappear when values change.

### Money Display

Shows your cash and bank balance. The display updates every 2 seconds. Cash is shown in green, bank in blue (by default — you can change this in settings).

### Voice Indicator

Shows your current voice range:

| Indicator | Range | Use |
|---|---|---|
| 🔇 | Whisper (2m) | Quiet conversations |
| 🗣️ | Normal (8m) | Regular talking |
| 📢 | Shout (14m) | Yelling across distances |

The indicator lights up when you're actively speaking. Cycle voice ranges with your server's voice keybind (typically mapped by pma-voice).

### Vehicle Speedometer

When you enter a vehicle, a speedometer appears at the bottom-center of your screen:

- **Speed** — current speed in MPH or KM/H (configurable)
- **Fuel** — fuel level (if your server supports vehicle fuel)
- **Gear** — current gear (P, R, N, 1-6)
- **Damage** — vehicle condition indicator

The speedometer disappears automatically when you exit the vehicle.

### Minimap

Use the settings panel to toggle minimap visibility or change its size:

- **Small** — 150×150px
- **Normal** — 200×200px (default)
- **Large** — 260×260px

---

## Commands

| Command | Description |
|---|---|
| `/hudsettings` | Open the settings panel |
| `/hudtoggle` | Toggle the entire HUD on/off |

You can also bind keys to these commands via FiveM's keybind settings (Settings → Key Bindings → FiveM).

---

## Tips

- **Drag to reposition:** In the settings panel, click and drag any element to move it
- **Hide what you don't use:** If your server doesn't use hunger/thirst, just toggle them off
- **Performance:** The HUD is designed to be lightweight, but if you have a slow PC, try increasing update intervals in the config (ask your server admin)
- **Color matching:** Set the primary color to match your server's brand for a cohesive look
- **Reset button:** If you mess up your layout, hit reset in the settings panel to start fresh

---

## FAQ

**Q: My hunger/thirst bars are stuck at 100%. Why?**  
A: Your server needs `ox_status` installed for hunger/thirst to work. If it's not installed, these bars will always show full. You can hide them in settings.

**Q: Can I move the HUD to the right side?**  
A: Yes! Open settings (F7), switch to the Position tab, and drag elements where you want them.

**Q: My settings reset every time I rejoin.**  
A: This shouldn't happen — settings save automatically. If it does, tell your server admin to check that KVP storage is working.

**Q: The speedometer shows KM/H but I want MPH.**  
A: Open settings (F7) and change the speed unit dropdown to MPH.

**Q: Can other players see my HUD?**  
A: No. The HUD is entirely client-side — only you can see your own HUD layout.

---

*Prospyr SmartHUD — Built by Prospyr 305*