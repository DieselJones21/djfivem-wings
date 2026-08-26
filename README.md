# djfivem-wings

FiveM resource for wearable props (wings, shoulder pets, and anything else you stream). Using an inventory item attaches the prop to the player. **Every nearby player sees it.** A live editor lets you nudge position and rotation until it sits right on your ped.

## Features

- Inventory use to equip / unequip (ox_inventory, QB-Core, ESX, or standalone commands)
- One prop per slot so wings and a shoulder pet can be worn together
- State-bag sync — no networked objects, no spam events
- Distance culling, vehicle hide, first-person hide
- Placement editor (`F7` / `/wingeditor`) with live preview, bone picker, and Copy Lua
- Saved placements and equipped loadout per character (resource KVP)
- Optimized single reconcile loop instead of a thread per player

## Install

1. Drop this folder into `resources` as `djfivem-wings`.
2. Add to `server.cfg`:

```cfg
ensure djfivem-wings
add_ace group.admin djwings.admin allow
```

3. Add the items from `install/` to your inventory/framework:
   - ox_inventory → `install/ox_inventory_items.lua`
   - QB-Core → `install/qb_items.lua`
   - ESX → `install/esx_items.sql`
4. Stream your props (next section).
5. Restart the server (or `ensure djfivem-wings`).

The resource auto-detects ox_inventory, qb-core / qbx_core, then es_extended.

## Add your props

The script does not include the 3D models. Put your files in `stream/`:

```
stream/
  your_wings.ydr
  your_wings.ytd
  your_wings.ytyp
```

In `fxmanifest.lua` uncomment and point at **your** ytyp:

```lua
data_file 'DLC_ITYP_REQUEST' 'stream/your_wings.ytyp'
```

In `config.lua`, set `model` to the ydr spawn name (filename without extension):

```lua
ate_wings_a = {
    label = 'Wings A',
    model = 'ate_wings_a', -- must match a name inside the ytyp
    slot = 'wings',
    bone = 24818,          -- SKEL_Spine3, upper back
    default = { x = 0.00, y = -0.18, z = 0.02, rx = 0.00, ry = 90.00, rz = 180.00 },
},
```

Starter entries (back / Spine3):

| Item | Slot | Bone | Model |
| --- | --- | --- | --- |
| `ate_wings_a` | `wings` | 24818 Spine3 | `ate_wings_a` |
| `ate_wings_b` | `wings` | 24818 Spine3 | `ate_wings_b` |
| `ate_wings_c` | `wings` | 24818 Spine3 | `ate_wings_c` |
| `ate_wings_d` | `wings` | 24818 Spine3 | `ate_wings_d` |

Copy a `Config.Props` block to add more styles. Item name = table key. The spawn name must exist **inside** `ate_wings.ytyp`, not only as a `.ydr` filename.

If the models are not streamed yet, set `Config.DebugPlaceholder = true` to test attach / sync / editor with a vanilla bag.

## In game

| Action | How |
| --- | --- |
| Equip / remove | Use the item in inventory |
| Admin / standalone test | `/wingtest ate_wings_a` |
| List ids | `/wings` |
| Remove all | `/wingsoff` |
| Placement editor | `F7` or `/wingeditor` (wear the prop first) |
| Edit a specific slot | `/wingeditor shoulder` |

Editor keys: numpad moves position, arrows / Q E rotate, Z C spin the ped, Shift fine, Ctrl coarse, Enter save, Esc cancel. **Copy Lua** writes a `default = { ... }` table you can paste back into `config.lua`.

Saved placements replicate to every player.

## Inventory notes

- Items are **not consumed**. Use toggles the prop.
- `Config.RequireItem = true` (default) blocks equip if the player does not have the item. Dropping it and relogging will not restore it.
- ox_inventory: this resource registers a `usingItem` hook. Keep `consume = 0`.
- Any other inventory can call:

```lua
exports['djfivem-wings']:toggle(source, 'ate_wings_a')
-- or
TriggerEvent('djwings:internalToggle', source, 'ate_wings_a')
```

## Exports

**Server**

```lua
exports['djfivem-wings']:toggle(src, 'ate_wings_a')
exports['djfivem-wings']:clear(src)
exports['djfivem-wings']:getEquipped(src)
```

**Client**

```lua
exports['djfivem-wings']:getEquipped()
exports['djfivem-wings']:isWearing('ate_wings_a')
```

## Tuning

| Config | Default | What it does |
| --- | --- | --- |
| `RenderDistance` | 48 | Other players' props spawn only inside this range |
| `SyncMs` | 500 | Reconcile interval (stream-in, ped swap, distance) |
| `MaxOffset` | 0.85 | Editor clamp so props cannot be placed across the map |
| `HideInVehicle` | true | Hides props in vehicles |
| `HideInFirstPerson` | true | Hides *your* props in first person |
| `Persist` | true | Remembers loadout + offsets on reconnect |

If a wing mesh is exported with a different up-axis, use the editor and paste the copied `default` table into config so every new player starts with the correct fit.
