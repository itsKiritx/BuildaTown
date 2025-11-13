local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Feather = require(ReplicatedStorage.Scripts.Packages.Feather)
local Packets = require(ReplicatedStorage.Scripts.Network.Packets)

local NetworkController ={
	FetchIds = {},
}

function NetworkController:FireServer(PacketName: string, Data: any?)
	if not Packets then
		return
	end

	Data = Data or {}

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		--warn(`Packet '{PacketName}' not found`, Packets.getPackets())
		return
	end

	local Parameters = Packets.getParameters(PacketName)
	local Arguments  = {}

	for _, Parameter in Parameters do
		Arguments[Parameter] = Data[Parameter]
	end

	Packet.send(Arguments)
end

function NetworkController:InvokeServer(PacketName: string, Data: any?)
	if not Packets then
		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`, Packets.getPackets())
		return
	end

	local Parameters = Packets.getParameters(PacketName)
	local Arguments  = {}

	for _, Parameter in Parameters do
		Arguments[Parameter] = Data[Parameter]
	end

	local FetchId = math.random(-127, 127)
	while self.FetchIds[FetchId] do
		FetchId = math.random(-127, 127)
	end
	Arguments.FetchId = FetchId
	self.FetchIds[FetchId] = true

	local ReturnPacket = Packets.getPackets()[PacketName .. "/Return"]
	if not ReturnPacket then
		warn(`Packet '{PacketName}/Return' not found`)
		return
	end

	local AwaitEvent = Instance.new("BindableEvent")
	ReturnPacket.listen(function(...)
		local Data = ({...})[1]
		if tostring(Data.FetchId) ~= tostring(FetchId) then
			return
		end
		AwaitEvent:Fire(...)
	end)

	local listeners = ReturnPacket.getListeners()
	local listenerIndex = #listeners

	Packet.send(Arguments)

	local Response = AwaitEvent.Event:Wait()
	table.remove(listeners, listenerIndex)
	AwaitEvent:Destroy()
	self.FetchIds[FetchId] = nil

	return Response
end

function NetworkController.OnClientEvent(PacketName: string, Callback: (Data: any?) -> ())
	if not Packets then
		-- Wait for packets without yielding
		task.spawn(function()
			repeat
				task.wait(0.1)
			until Packets

			NetworkController.OnClientEvent(PacketName, Callback)
		end)

		return
	end

	local Packet = Packets.getPackets()[PacketName]
	if not Packet then
		warn(`Packet '{PacketName}' not found`, Packets.getPackets())
		return
	end

	Packet.listen(Callback)
end

Packets.Init()

function NetworkController:FeatherStart()
	
end

return Feather.WrapController(NetworkController, script)
