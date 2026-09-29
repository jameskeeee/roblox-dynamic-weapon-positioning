-- CharacterWeaponDisplay.lua
-- ModuleScript: ReplicatedStorage.CharacterWeaponDisplay
--
-- Shared configuration and model-placement helpers for the server-side
-- character weapon display system. Models are cloned by the server so every
-- player can see them.

local CharacterWeaponDisplay = {}

CharacterWeaponDisplay.Config = {
	-- Put display models here. Each model must have the same name as its Tool.
	-- A Tool may also set a string OriginPath attribute, in which case the
	-- server can be extended to resolve that path before falling back to Name.
	ModelFolderName = "ToolCharacterModels",

	-- The part on the character used as the placement reference.
	PistolBodyPart = "UpperTorso",
	RifleBodyPart = "UpperTorso",

	-- CFrames are relative to the selected body part. Adjust these in Studio
	-- until the duplicated model is where you want it.
	Pistol = {
		Right = CFrame.new(0.9, -0.15, 0.15) * CFrame.Angles(math.rad(-90), 0, math.rad(8)),
		Left = CFrame.new(-0.9, -0.15, 0.15) * CFrame.Angles(math.rad(-90), 0, math.rad(-8)),
	},

	Rifle = {
		Fixed = CFrame.new(0.85, 0.05, 0.45) * CFrame.Angles(math.rad(-90), math.rad(8), math.rad(90)),
	},

	-- Optional per-tool overrides. The value is a CFrame relative to the
	-- configured body part and replaces the category offset.
	Overrides = {
		-- ["M1911"] = CFrame.new(0.9, -0.15, 0.15),
	},
}

function CharacterWeaponDisplay.GetCategory(tool, collectionService)
	if collectionService:HasTag(tool, "Pistol") then
		return "Pistol"
	end

	if collectionService:HasTag(tool, "Rifle") then
		return "Rifle"
	end

	return nil
end

function CharacterWeaponDisplay.GetBodyPart(character, category)
	local name = category == "Rifle"
		and CharacterWeaponDisplay.Config.RifleBodyPart
		or CharacterWeaponDisplay.Config.PistolBodyPart

	return character:FindFirstChild(name)
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
end

function CharacterWeaponDisplay.GetOffset(tool, category, side)
	local override = CharacterWeaponDisplay.Config.Overrides[tool.Name]
	if override then
		return override
	end

	if category == "Rifle" then
		return CharacterWeaponDisplay.Config.Rifle.Fixed
	end

	return CharacterWeaponDisplay.Config.Pistol[side]
end

return CharacterWeaponDisplay
