local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Scripts.Packages.ByteNet)
local Packets = require(ReplicatedStorage.Scripts.Network.Packets) :: any


return ByteNet.defineNamespace("Functions", function()
	return Packets.definePackets({
		Packets.definePacket("FetchData", {
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
		Packets.definePacket("FetchData/Return", {
			DataString = ByteNet.string,
			FetchId = ByteNet.optional(ByteNet.int8),
		}),
	})
end)
