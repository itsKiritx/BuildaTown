local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ByteNet = require(ReplicatedStorage.Scripts.Packages.ByteNet)

local Packets = {
	ArgumentStorage = {},
}

local ReliabilityTypes = {
	Events = "reliable",
	UnreliableEvents = "unreliable",
	Functions = "reliable",
}

function Packets.getPackets()
	local Events = Packets.Events

	for EventName, Event in Packets.UnreliableEvents do
		Events[EventName] = Event
	end

	for EventName, Event in Packets.Functions do
		Events[EventName] = Event
	end

	return Events
end

function Packets.definePackets(Packets)
	local PacketList = {}

	for _, PacketStruct in Packets do
		PacketList[PacketStruct.Name] = PacketStruct.Struct
	end

	return PacketList
end

function Packets.definePacket(PacketName, PacketStructure)
	Packets.ArgumentStorage[PacketName] = {}

	for Argument, _ in PacketStructure do
		table.insert(Packets.ArgumentStorage[PacketName], Argument)
	end

	local traceback = getfenv(debug.info(2, "f")).script.Name
	return {
		Name = PacketName,
		Struct = ByteNet.definePacket({
			value = ByteNet.struct(PacketStructure),
			reliabilityType = ReliabilityTypes[traceback] or "reliable",
		})
	}
end

function Packets.getParameters(PacketName)
	return Packets.ArgumentStorage[PacketName]
end

function Packets.Init()
	if RunService:IsClient() and not ReplicatedStorage:GetAttribute("ServerReady") then
		repeat 
			ReplicatedStorage:GetAttributeChangedSignal("ServerReady"):Wait()
		until ReplicatedStorage:GetAttribute("ServerReady")
	end

	if not Packets.Events then
		Packets.Events = require(ReplicatedStorage.Scripts.Network.Events)
	end

	if not Packets.UnreliableEvents then
		Packets.UnreliableEvents = require(ReplicatedStorage.Scripts.Network.UnreliableEvents)
	end

	if not Packets.Functions then
		Packets.Functions = require(ReplicatedStorage.Scripts.Network.Functions)
	end
	
	if RunService:IsServer() then
		ReplicatedStorage:SetAttribute("ServerReady", true)
	end
end

return Packets
