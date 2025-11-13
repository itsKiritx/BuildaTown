--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)

Feather.StartServerAsync({
	ReplicatedStorage.Scripts.Components,
	ServerScriptService.Scripts.Services,
})