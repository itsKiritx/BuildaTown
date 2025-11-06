local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ByteNet = require(ReplicatedStorage.Scripts.Packages.ByteNet)
local Packets = require(ReplicatedStorage.Scripts.Network.Packets)

return ByteNet.defineNamespace("UnreliableEvents", function()
	return Packets.definePackets({
		-- Debug
		Packets.definePacket("TellServerToPrint2", {
			Message = ByteNet.string,
		}),
	})
end)
