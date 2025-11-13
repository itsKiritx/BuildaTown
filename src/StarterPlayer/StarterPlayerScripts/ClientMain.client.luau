--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)

Feather.StartClientAsync({
	ReplicatedStorage.Scripts.Controllers,
	ReplicatedStorage.Scripts.Components,
})
