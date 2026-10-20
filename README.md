# heino_netscenes

Networked synchronized scenes for FiveM (heists, hacking, robberies, hand-offs and a truck scene).

## Install

1. Requires [ox_lib](https://github.com/overextended/ox_lib).
2. Put `heino_netscenes` in your resources folder.
3. Add `ensure heino_netscenes` to `server.cfg` after `ox_lib`.

## Usage

Every scene is a client export:

```lua
exports['heino_netscenes']:Thermite(...)
```

| Group | Exports |
| --- | --- |
| Breaching | `Thermite`, `PlantVaultBombs`, `DetonateVaultBombs`, `DetonateCharges`, `PlantCharge`, `Drill`, `VaultDrill` |
| Containers | `OpenContainer`, `OpenCrate`, `LootCrate` |
| Dumpsters | `GrabDumpster` |
| Electrical | `ElectricBox` |
| Hacking | `HackUSB`, `HackPhone`, `HackLaptop`, `CardSwipe` |
| Hand-off | `HandOff` |
| Lab | `TakeChemical` |
| Safes | `SafeCrack`, `CrackStrongbox` |
| Valuables | `StealPainting`, `CashTrolley`, `GlassCut`, `SmashCase`, `TableGrab` |
| Truck | `TruckScene`, `ClearTruckScene` |
| Helpers | `CreateVeh`, `CreateObj`, `CreateNPC`, `CheckSceneClips` |

Truck scene:

```lua
exports['heino_netscenes']:TruckScene({ Player = true, Camera = true }, function(Completed) end)
```

Set `Config.Debug = true` for debug output and test commands (`/truckscene`, `/truckscene_me`, `/truckscene_clear`).

## Optional

`heino_minigames`, `st_minigames`, `varhack` for the scenes that use them. Discord logs: set `Webhook` in `server/logs.lua`.

## License

AGPL-3.0. The truck scene is based on [empty-fivem/truck-scene](https://github.com/empty-fivem/truck-scene).
