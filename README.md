# sx-toxiczone

A FiveM resource that creates **toxic zones** (PolyZone) applying **periodic damage**, **visual effects**, and **environment feedback** when players enter the area—unless they wear the configured **protective outfit**.

## Features

- **PolyZone Toxic Areas**: Define polygon zones with min/max Z
- **Periodic Damage**: Applies configurable damage ticks while in zone
- **Protective Outfit Check**: No damage / effects if the player wears the configured clothes (male/female support)
- **Visual Feedback**:
  - Timecycle effect when entering/leaving (fade in/out)
  - Toxic fog particles around zone boundaries
  - Optional “toxic eye” state management (apply/reset via events/export)
- **NUI Notification**: Displays an RP-style title/description on zone entry
- **Multi-language Support**: Uses an i18n system with default phrases

## Installation

1. Download the resource and place it in your `resources` folder
2. Add the resource to your `server.cfg`:
   ```
   ensure sxToxicZone
   ```
3. Restart your server or start the resource manually

## Configuration

Main configs are located in `srcs/shared/`.

### Zones Configuration

Edit `srcs/shared/zones.lua` to define your toxic areas:

- `id`: zone identifier
- `label`: zone display name (used in translations)
- `min_z` / `max_z`: vertical bounds
- `coords`: polygon points (`vector3(...)`)

Example:
```lua
SHARED.Zones = {
    {
        id = "grapseed_zone",
        label = "Grapseed",
        min_z = -100,
        max_z = 100,
        coords = {
            vector3(1707.76, 4612.58, 42.68),
            vector3(2001.96, 4638.24, 41.03),
            vector3(1998.88, 5086.47, 42.53),
            vector3(1819.73, 5071.56, 57.93),
            vector3(1582.62, 4930.79, 63.61)
        }
    },
}
```

### UI / Title Duration

Edit `srcs/shared/ui.lua`:
```lua
SHARED.Title_time = 5000
```

### Protective Clothes

Edit `srcs/shared/clothes.lua`.

This resource checks multiple components/props (torso, tshirt, arms, pants, shoes, helmet, etc.) and compares the player’s current variations to the configured values.

Structure:
- `[0]`: male freemode model
- `[1]`: female freemode model

Example:
```lua
SHARED.Clothes = {
    ['helmet'] = {
        [0] = { ['helmet_1'] = -1 },
        [1] = { ['helmet_1'] = 0 }
    },
    -- ...
}
```

## Default Behavior

- When a player enters a toxic zone:
  - A UI message is displayed (“enter zone” + description)
  - If the player is **not** wearing the protective outfit:
    - A timecycle modifier is applied
    - Damage is applied periodically (tick system)
- When a player leaves:
  - The timecycle modifier fades out
- Toxic fog particles are spawned around zone boundaries (performance-based distance checks)

## Translations

Default phrases are registered in `translations/sh_default.lua` (fallback):
- `enter_zone` (with `%s` placeholder for zone label)
- `description_zone`

You can add/extend translations under `translations/` (the resource loads `translations/sh_i18n.lua` and `translations/rp-translations/*.lua` too).

## Exports / Events

### Export
- `exports["sxToxicZone"]:ResetToxicEye()`  
  Triggers a server event to clear the toxic eye state.

### Client Events
- `sxZones_toxic:applyToxicEye`
- `sxZones_toxic:resetToxicEye`
- `sxZones_toxic:requestEyeState` (requested on resource start)

## Requirements

- FiveM Server
- Lua 5.4 enabled (`lua54 'yes'`)
- FX Version: `cerulean`
- Game: `gta5`

## Dependencies

- PolyZone scripts are included under:
  - `srcs/client/polyzone/*.lua`

## Technical Details

- **Resource Name**: sxToxicZone
- **Author**: sacha-development
- **UI Page**: `web/dist/index.html`
- **Assets**: sounds/mp3 + built web assets in `web/dist/`

## Support

For issues, suggestions, or contributions, please contact the author or open an issue on the repository.

## License

This resource is provided as-is. Please check with the author for licensing information.