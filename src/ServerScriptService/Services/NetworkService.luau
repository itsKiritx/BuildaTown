local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.Scripts.Network.Packets)
local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)

Packets.Init()

local NetworkService = {}

function NetworkService.OnServerEvent(PacketName: string, Callback: ({}, Player) -> nil)
	if not Packets then
		task.spawn(function()
			repeat
				task.wait()
			until Packets

			return NetworkService.OnServerEvent(PacketName, Callback)
		end)
		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`)
		return
	end

	Packet.listen(Callback)
end

function NetworkService.OnServerInvoke(PacketName: string, Callback: ({}, Player) -> any, ReturnTypes: any?)
	if not Packets then
		task.spawn(function()
			repeat
				task.wait()
			until Packets

			return NetworkService.OnServerInvoke(PacketName, Callback)
		end)
		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`)
		return
	end

	local ReturnPacket = Packets.getPackets()[PacketName .. "/Return"]
	if not ReturnPacket then
		warn(`Packet '{PacketName}/Return' not found`)
		return
	end

	Packet.listen(function(Data, Player)
		local Result = Callback(Data, Player)
		if typeof(Data) == "string" then
			warn(`Data for packet '{PacketName}' is not a table`)
		end
		Result.FetchId = Data.FetchId

		NetworkService:FireClient(PacketName .. "/Return", Player, Result)
	end)
end

function NetworkService:FireAllClients(PacketName: string, Arguments)
	if not Packets then
		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`)
		return
	end

	if Arguments and Arguments.Entity and Arguments.Entity < 0 then
		warn("Traceback:", debug.traceback("Invalid Entity ID"))
	end

	Packet.sendToAll(Arguments)
end

function NetworkService:FireClient(PacketName: string, Player: Player, Data: any)
	if not Packets then
		return
	end

	if not Player then
		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`)
		return
	end

	local Parameters = Packets.getParameters(PacketName)
	local Arguments = {}

	for _, Parameter in Parameters do
		Arguments[Parameter] = Data[Parameter]
	end

	Packet.sendTo(Arguments, Player)
end

function NetworkService:FeatherStart()
	-- local Events = ServerStorage.Events
	-- for _, Event in Events:GetChildren() do
	--     if Event.ClassName ~= "ModuleScript" then
	--         continue
	--     end

	--     Network.OnServerEvent(Event.Name, function(Data, Player)
	--         task.spawn(require(Event), Data, Player)
	--     end)
	-- end
end

return Feather.WrapService(NetworkService, script)
