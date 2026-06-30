/* ═════════════════════════════════════════════════════════════════════
   Prospyr SmartHUD — NUI Application Logic
   ═════════════════════════════════════════════════════════════════════
   Handles all NUI message routing, settings panel interactions, and
   live HUD updates. Pure vanilla JS — no frameworks.
   ═════════════════════════════════════════════════════════════════════ */

// ─── State ───
let settings = {};
let theme = {};
let barConfig = {};
let positions = {};
let barsFaded = false;

// ─── Utility: format money with commas ───
function formatMoney(val) {
    return '$' + (val || 0).toLocaleString('en-US');
}

// ─── Utility: apply CSS variables from theme ───
function applyTheme(t) {
    const root = document.documentElement;
    root.style.setProperty('--primary', '#' + (t.primary || '4f9eff'));
    root.style.setProperty('--secondary', '#' + (t.secondary || '2a2a2e'));
    root.style.setProperty('--background', '#' + (t.background || '1a1a1e'));
    root.style.setProperty('--text', '#' + (t.text || 'ffffff'));
    root.style.setProperty('--text-dim', '#' + (t.textDim || '9a9a9e'));
    root.style.setProperty('--success', '#' + (t.success || '4fff7a'));
    root.style.setProperty('--warning', '#' + (t.warning || 'ffb84f'));
    root.style.setProperty('--danger', '#' + (t.danger || 'ff4f6a'));
}

// ─── Utility: apply bar dimensions ───
function applyBars(b) {
    const root = document.documentElement;
    root.style.setProperty('--bar-width', (b.width || 180) + 'px');
    root.style.setProperty('--bar-height', (b.height || 8) + 'px');
    root.style.setProperty('--bar-radius', (b.radius || 4) + 'px');
    root.style.setProperty('--bar-margin', (b.margin || 4) + 'px');
}

// ─── Utility: position HUD elements ───
function applyPositions(p) {
    if (!p) return;

    // Status bars
    if (p.status) {
        const el = document.getElementById('status-bars');
        el.style.left = p.status.x + '%';
        el.style.top = p.status.y + '%';
        el.style.transform = p.status.anchor === 'center' ? 'translateX(-50%)' :
                             p.status.anchor === 'right' ? 'translateX(-100%)' : 'none';
    }

    // Money
    if (p.money) {
        const el = document.getElementById('money-display');
        el.style.left = p.money.x + '%';
        el.style.top = p.money.y + '%';
        el.style.transform = p.money.anchor === 'center' ? 'translateX(-50%)' :
                             p.money.anchor === 'right' ? 'translateX(-100%)' : 'none';
    }

    // Voice
    if (p.voice) {
        const el = document.getElementById('voice-indicator');
        el.style.left = p.voice.x + '%';
        el.style.top = p.voice.y + '%';
        el.style.transform = p.voice.anchor === 'center' ? 'translateX(-50%)' :
                             p.voice.anchor === 'right' ? 'translateX(-100%)' : 'none';
    }

    // Vehicle
    if (p.vehicle) {
        const el = document.getElementById('vehicle-hud');
        el.style.left = p.vehicle.x + '%';
        el.style.top = p.vehicle.y + '%';
        el.style.transform = p.vehicle.anchor === 'center' ? 'translateX(-50%)' :
                             p.vehicle.anchor === 'right' ? 'translateX(-100%)' : 'none';
    }
}

// ─── Utility: update a single bar ───
function updateBar(id, value) {
    const bar = document.getElementById('bar-' + id);
    if (!bar) return;

    const pct = Math.max(0, Math.min(100, value));
    bar.style.width = pct + '%';

    // Add low-value warning class
    if (pct < 25) {
        bar.classList.add('low');
    } else {
        bar.classList.remove('low');
    }
}

// ─── Message Handler ───
window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'init':
            settings = data.settings || {};
            theme = data.theme || {};
            barConfig = data.bars || {};
            positions = data.positions || {};
            applyTheme(theme);
            applyBars(barConfig);
            applyPositions(positions);
            updateElementVisibility();
            break;

        case 'toggle':
            document.getElementById('hud-container').style.display =
                data.visible ? 'block' : 'none';
            break;

        case 'updateStatus':
            if (data.health !== undefined)  updateBar('health', data.health);
            if (data.armor !== undefined)   updateBar('armor', data.armor);
            if (data.stamina !== undefined) updateBar('stamina', data.stamina);
            if (data.hunger !== undefined)  updateBar('hunger', data.hunger);
            if (data.thirst !== undefined)  updateBar('thirst', data.thirst);
            break;

        case 'updateMoney':
            document.getElementById('money-cash').textContent = formatMoney(data.cash);
            document.getElementById('money-bank').textContent = formatMoney(data.bank);
            document.getElementById('cash-display').style.display = data.showCash ? 'flex' : 'none';
            document.getElementById('bank-display').style.display = data.showBank ? 'flex' : 'none';
            break;

        case 'updateVoice':
            const voiceIcon = document.getElementById('voice-icon');
            const voiceText = document.getElementById('voice-range-text');
            const ranges = data.ranges || [2.0, 8.0, 14.0];
            const labels = ['Whisper', 'Normal', 'Shout'];

            if (data.active) {
                voiceIcon.classList.add('active');
            } else {
                voiceIcon.classList.remove('active');
            }

            const rangeIdx = data.range || 1;
            voiceText.textContent = labels[rangeIdx - 1] || 'Normal';
            break;

        case 'showVehicle':
            document.getElementById('vehicle-hud').classList.toggle('hidden', !data.visible);
            break;

        case 'updateVehicle':
            if (data.speed !== undefined) {
                document.getElementById('vehicle-speed').textContent = data.speed;
            }
            document.getElementById('vehicle-unit').textContent = data.unit || 'MPH';
            document.getElementById('vehicle-gear').textContent = data.gear || 'N';

            // Fuel bar
            const fuelFill = document.getElementById('vehicle-fuel');
            fuelFill.style.width = (data.fuel || 0) + '%';
            if ((data.fuel || 100) < 20) {
                fuelFill.classList.add('low');
            } else {
                fuelFill.classList.remove('low');
            }

            // Damage percentage (average of engine + body)
            const dmg = Math.round(((data.engineHealth || 100) + (data.bodyHealth || 100)) / 2);
            document.getElementById('vehicle-damage').textContent = dmg + '%';
            break;

        case 'fadeBars':
            const shouldFade = data.opacity < 1.0;
            document.querySelectorAll('.bar-group').forEach(el => {
                el.style.opacity = data.opacity;
            });
            barsFaded = shouldFade;
            break;

        case 'openSettings':
            openSettingsPanel(data);
            break;

        case 'closeSettings':
            closeSettingsPanel();
            break;

        case 'updateSettings':
            settings = data.settings || settings;
            updateElementVisibility();
            break;
    }
});

// ─── Element Visibility ───
function updateElementVisibility() {
    document.getElementById('status-bars').style.display =
        (settings.showHealth || settings.showArmor || settings.showStamina ||
         settings.showHunger || settings.showThirst) ? 'flex' : 'none';
    document.getElementById('money-display').style.display = settings.showMoney ? 'flex' : 'none';
    document.getElementById('voice-indicator').style.display = settings.showVoice ? 'flex' : 'none';

    // Individual bar groups
    toggleBarGroup('health', settings.showHealth);
    toggleBarGroup('armor', settings.showArmor);
    toggleBarGroup('stamina', settings.showStamina);
    toggleBarGroup('hunger', settings.showHunger);
    toggleBarGroup('thirst', settings.showThirst);
}

function toggleBarGroup(type, show) {
    const el = document.querySelector(`.bar-group[data-type="${type}"]`);
    if (el) el.style.display = show ? 'flex' : 'none';
}

// ─── Settings Panel ───
function openSettingsPanel(data) {
    settings = data.settings || settings;
    theme = data.theme || theme;
    barConfig = data.bars || barConfig;
    positions = data.positions || positions;

    const panel = document.getElementById('settings-panel');
    panel.classList.remove('hidden');

    // Populate toggles
    const toggles = document.querySelectorAll('.toggle-item input[type="checkbox"]');
    toggles.forEach(input => {
        const element = input.dataset.element;
        if (element) {
            const key = 'show' + element;
            input.checked = settings[key] !== false;
        }
    });

    // Populate colors
    const colors = document.querySelectorAll('.color-item input[type="color"]');
    colors.forEach(input => {
        const key = input.dataset.colorkey;
        if (key && theme[key]) {
            input.value = '#' + theme[key];
        }
    });

    // Populate bar sliders
    document.getElementById('bar-width').value = barConfig.width || 180;
    document.getElementById('bar-width-val').textContent = barConfig.width || 180;
    document.getElementById('bar-height').value = barConfig.height || 8;
    document.getElementById('bar-height-val').textContent = barConfig.height || 8;
    document.getElementById('bar-radius').value = barConfig.radius || 4;
    document.getElementById('bar-radius-val').textContent = barConfig.radius || 4;
    document.getElementById('toggle-fade').checked = barConfig.animateFade !== false;

    // Minimap size radios
    const minimapRadios = document.querySelectorAll('input[name="minimap-size"]');
    minimapRadios.forEach(r => { r.checked = (r.value === (settings.minimapSize || 'normal')); });

    // Speed unit radios
    const speedRadios = document.querySelectorAll('input[name="speed-unit"]');
    speedRadios.forEach(r => { r.checked = (r.value === (settings.speedUnit || 'mph')); });
}

function closeSettingsPanel() {
    document.getElementById('settings-panel').classList.add('hidden');
    fetchNui('closeSettings', {});
}

// ─── NUI Fetch Helper ───
function fetchNui(action, data) {
    return fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).then(r => r.json()).catch(e => console.error('NUI fetch error:', e));
}

// ─── Event Listeners ───

// Close button
document.getElementById('close-btn').addEventListener('click', function() {
    closeSettingsPanel();
});

// Save button
document.getElementById('save-btn').addEventListener('click', function() {
    // Gather all settings from the panel
    const newSettings = { ...settings };

    // Element toggles
    document.querySelectorAll('.toggle-item input[type="checkbox"]').forEach(input => {
        const element = input.dataset.element;
        if (element) newSettings['show' + element] = input.checked;
    });

    // Colors
    const newTheme = { ...theme };
    document.querySelectorAll('.color-item input[type="color"]').forEach(input => {
        const key = input.dataset.colorkey;
        if (key) newTheme[key] = input.value.replace('#', '');
    });
    newSettings.theme = newTheme;

    // Bars
    const newBars = { ...barConfig };
    newBars.width = parseInt(document.getElementById('bar-width').value);
    newBars.height = parseInt(document.getElementById('bar-height').value);
    newBars.radius = parseInt(document.getElementById('bar-radius').value);
    newBars.animateFade = document.getElementById('toggle-fade').checked;
    newSettings.bars = newBars;

    // Minimap
    const minimapSelected = document.querySelector('input[name="minimap-size"]:checked');
    if (minimapSelected) newSettings.minimapSize = minimapSelected.value;

    // Speed unit
    const speedSelected = document.querySelector('input[name="speed-unit"]:checked');
    if (speedSelected) newSettings.speedUnit = speedSelected.value;

    // Apply visually
    applyTheme(newTheme);
    applyBars(newBars);
    settings = newSettings;
    updateElementVisibility();

    // Save via NUI callback
    fetchNui('saveSettings', { settings: newSettings });
    closeSettingsPanel();
});

// Reset button
document.getElementById('reset-btn').addEventListener('click', function() {
    fetchNui('resetSettings', {}).then(response => {
        if (response && response.settings) {
            settings = response.settings;
            theme = settings.theme || theme;
            barConfig = settings.bars || barConfig;
            applyTheme(theme);
            applyBars(barConfig);
            updateElementVisibility();
            openSettingsPanel({ settings, theme, bars: barConfig, positions });
        }
    });
});

// Live slider value updates
document.getElementById('bar-width').addEventListener('input', function() {
    document.getElementById('bar-width-val').textContent = this.value;
});
document.getElementById('bar-height').addEventListener('input', function() {
    document.getElementById('bar-height-val').textContent = this.value;
});
document.getElementById('bar-radius').addEventListener('input', function() {
    document.getElementById('bar-radius-val').textContent = this.value;
});

// Live color preview
document.querySelectorAll('.color-item input[type="color"]').forEach(input => {
    input.addEventListener('input', function() {
        const key = input.dataset.colorkey;
        if (key) {
            const val = this.value.replace('#', '');
            const root = document.documentElement;
            root.style.setProperty('--' + key, '#' + val);
        }
    });
});

// Escape key closes settings
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        closeSettingsPanel();
    }
});