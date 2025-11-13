local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local NetworkController = require(ReplicatedStorage.Scripts.Controllers.NetworkController)
local UtilComponent = require(ReplicatedStorage.Scripts.Components.UtilComponent)
local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)

local SoundController = {}

local SoundProperties = {
	LoopRegion = true,
	Looped = true,
	Name = true,
	PlayOnRemove = true,
	PlaybackRegion = true,
	PlaybackRegionsEnabled = true,
	PlaybackSpeed = true,
	Playing = true,
	RollOffMaxDistance = true,
	RollOffMinDistance = true,
	RollOffMode = true,
	SoundGroup = true,
	SoundId = true,
	TimePosition = true,
	Volume = true,
	Parent = true,
}

function SoundController:GetDataByPath(Path, Type)
	local parts = string.split(Path, "/")
	local currentNode = Type == "Sound" and self.Sounds

	for _, part in parts do
		if currentNode[part] then
			currentNode = currentNode[part]
		else
			return nil, "Path not found: " .. Path
		end
	end

	return currentNode
end

function SoundController:GetSound(Path, Properties)
	if not self.Loaded then
		error("SoundController not loaded")
	end

	local Sound = self.Sounds[Path]
	if not Sound then
		return
	end

	Properties.RollOffMaxDistance = Properties.RollOffMaxDistance or 100
	Properties.RollOffMinDistance = Properties.RollOffMinDistance or 5

	-- Create Sound Instance
	local Sound = Sound:Clone()

	-- Set All Sound Properties
	for Property, Value in Properties do
		if SoundProperties[Property] then
			Sound[Property] = Value
		end
	end

	if Properties.Play then
		Sound:Play()
	end

	if not Properties.Keep and not Properties.Looped then
		if Sound.PlaybackSpeed ~= 0 then
			Debris:AddItem(Sound, Sound.TimeLength / Sound.PlaybackSpeed + 2)
		end
	end

	return Sound
end

function SoundController:FeatherStart()
	local SoundsFolder = ReplicatedStorage.Assets.Sounds
	task.spawn(function()
		ContentProvider:PreloadAsync({SoundsFolder})
	end)
	
	local SoundChecks = {
		Sound = function(Sound)
			return Sound
		end
	}

	self.Sounds = UtilComponent:FolderToStringedTable(SoundsFolder, SoundChecks)
	self.Loaded = true

	NetworkController.OnClientEvent("Sound/PlaySound", function(Data)
		if not Data.Properties.Parent then Data.Properties.Parent = workspace.CurrentCamera end
		self:GetSound(Data.Path, Data.Properties)
	end)
end

return Feather.WrapController(SoundController, script)
