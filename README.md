# Roblox Dynamic Weapon Positioning

This adds server-created weapon displays to the custom hotbar setup.

## Installation

1. Create `ReplicatedStorage.ToolCharacterModels`.
2. Put one display `Model` per weapon in that folder. Each model must have the exact same name as its Tool and a `PrimaryPart`.
3. Create a ModuleScript named `CharacterWeaponDisplay` in `ReplicatedStorage` and paste in `src/CharacterWeaponDisplay.lua`.
4. Create a Script named `WeaponDisplayServer` in `ServerScriptService` and paste in `src/WeaponDisplay.server.lua`.
5. Ensure your Tools are tagged `Pistol` or `Rifle`, as they already are for the hotbar.
6. Tune the CFrames in `CharacterWeaponDisplay.Config`.

No client-side hotbar rewrite is required: Roblox's replicated Tool parent changes are observed by the server. Your existing `humanoid:EquipTool(tool)` calls therefore automatically trigger the display system.

## Behavior

- The first currently equipped Pistol is placed using `Pistol.Right`.
- The second currently equipped Pistol is placed using `Pistol.Left`.
- A Rifle always uses `Rifle.Fixed`.
- If a pistol is unequipped, the remaining pistol becomes the first pistol and is rebuilt on the right side.
- Models are cloned and welded by the server, so they replicate to all clients.
- The gameplay Tool remains unchanged; these are visual display clones.

## Model requirements

Set a `PrimaryPart` on every display Model. The script disables collision/touch/query and welds the PrimaryPart to `UpperTorso` by default. R15 uses `UpperTorso`; R6 falls back to `Torso`.

If the weapon points the wrong direction, adjust the relevant `CFrame.Angles(...)` values in the module. If it is too far from or inside the body, adjust the `CFrame.new(x, y, z)` values.

## Optional per-tool override

Add an entry to `Config.Overrides`:

```lua
Overrides = {
    M1911 = CFrame.new(0.9, -0.15, 0.15) * CFrame.Angles(0, math.rad(90), 0),
}
```

The override replaces the category placement for that Tool, while still following pistol equip-order side selection only when no override is present.
