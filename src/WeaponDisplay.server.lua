-- WeaponDisplay.server.lua
-- Script: ServerScriptService.WeaponDisplayServer
--
-- Put character display models in ReplicatedStorage.ToolCharacterModels.
-- Each model should use the exact Tool name and contain at least one BasePart.
-- The server clones and welds the display to the character, making it visible
-- to every player. The Tool itself remains the equipped gameplay object.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Display = require(ReplicatedStorage:WaitForChild("CharacterWeaponDisplay"))
local config = Display.Config
local modelFolder = ReplicatedStorage:WaitForChild(config.ModelFolderName)

local DISPLAY_FOLDER_NAME = "CharacterWeaponDisplays"
local states = {}

local function getState(player)
	local state = states[player]
	if not state then
		state = { order = {}, character = nil }
		states[player] = state
	end
	return state
end

local function clearDisplay(character, tool)
	local folder = character and character:FindFirstChild(DISPLAY_FOLDER_NAME)
	local display = folder and folder:FindFirstChild(tool.Name)
	if display then
		display:Destroy()
	end
end

local function clearAllDisplays(character)
	local folder = character and character:FindFirstChild(DISPLAY_FOLDER_NAME)
	if folder then
		folder:Destroy()
	end
end

local function getTemplate(tool)
	local template = modelFolder:FindFirstChild(tool.Name)
	if template and (template:IsA("Model") or template:IsA("BasePart")) then
		return template
	end
	return nil
end

local function weldModel(model, bodyPart, offset)
	local primary = model:IsA("Model") and model.PrimaryPart or model
	if not primary or not primary:IsA("BasePart") then
		warn("[WeaponDisplay] Model needs a PrimaryPart: " .. model.Name)
		model:Destroy()
		return false
	end

	if model:IsA("Model") and not model.PrimaryPart then
		model.PrimaryPart = primary
	end

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end

	local target = bodyPart.CFrame * offset
	if model:IsA("Model") then
		model:PivotTo(target)
	else
		model.CFrame = target
	end

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = bodyPart
	weld.Part1 = primary
	weld.Parent = primary
	return true
end

local function displayTool(player, tool, category, side)
	local character = player.Character
	if not character then return end

	local bodyPart = Display.GetBodyPart(character, category)
	local template = getTemplate(tool)
	if not bodyPart or not template then return end

	clearDisplay(character, tool)

	local folder = character:FindFirstChild(DISPLAY_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = DISPLAY_FOLDER_NAME
		folder.Parent = character
	end

	local clone = template:Clone()
	clone.Name = tool.Name
	clone:SetAttribute("DisplayedTool", tool.Name)
	clone.Parent = folder

	local offset = Display.GetOffset(tool, category, side)
	if not weldModel(clone, bodyPart, offset) then
		return
	end
end

local function removeFromOrder(state, tool)
	for index = #state.order, 1, -1 do
		if state.order[index] == tool then
			table.remove(state.order, index)
		end
	end
end

local function rebuild(player)
	local state = getState(player)
	local character = player.Character
	if not character then return end

	clearAllDisplays(character)
	local seen = {}
	local pistolCount = 0

	for _, tool in ipairs(state.order) do
		if tool.Parent == character and not seen[tool] then
			seen[tool] = true
			local category = Display.GetCategory(tool, CollectionService)
			if category == "Pistol" then
				pistolCount += 1
				displayTool(player, tool, category, pistolCount == 1 and "Right" or "Left")
			elseif category == "Rifle" then
				displayTool(player, tool, category, "Fixed")
			end
		end
	end
end

local function toolEquipped(player, tool)
	local state = getState(player)
	removeFromOrder(state, tool)
	table.insert(state.order, tool)
	rebuild(player)
end

local function toolUnequipped(player, tool)
	local state = getState(player)
	removeFromOrder(state, tool)
	rebuild(player)
end

local function bindCharacter(player, character)
	local state = getState(player)
	state.character = character
	table.clear(state.order)
	clearAllDisplays(character)

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			toolEquipped(player, child)
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			-- Roblox can briefly reparent a Tool while swapping equipment.
			task.defer(function()
				if child.Parent ~= character then
					toolUnequipped(player, child)
				end
			end)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)
	if player.Character then
		bindCharacter(player, player.Character)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
	if player.Character then
		bindCharacter(player, player.Character)
	end
end
