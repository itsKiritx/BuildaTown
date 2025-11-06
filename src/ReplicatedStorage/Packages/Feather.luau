--!strict
--!native
--!optimize 2

type FeatherStruct = {
	FeatherStart: ((self: any) -> ())?
}

type FeatherModule = {
	Script: LuaSourceContainer,
	Return: FeatherStruct
}

local Services: {FeatherModule} = {}
local Controllers: {FeatherModule} = {}
local Components: {FeatherModule} = {}

local Deferred: {[LuaSourceContainer]: any} = {}

local Ran = {}
local Required = {}
local lastRan = nil

local function Require(target: LuaSourceContainer): any
	local box = Deferred[target]
	if box then
		return box
	else
		-- print(`Importing '{target.Name}'`)
		box = require(target) :: any
		Deferred[target] = box
		return box
	end
end

local function Ignite(target: LuaSourceContainer): ()
	local box = Deferred[target]
	if not box then
		-- print(`Importing '{target.Name}'`)
		box = require(target) :: any
		Deferred[target] = box
	end
end

local function StartAsync(parents: {Instance}, shouldWait: boolean): ()
	local t = os.clock()
	local threads: {thread} = {}

	-- Initialize all modules at once
	for _, parent in parents do
		for _, v in parent:GetDescendants() do
			if v:IsA("ModuleScript") then
				table.insert(threads, task.defer(Ignite, v))
				table.insert(Required, v.Name)
			end
		end
	end

	-- Wait for all modules to initialize, if there is code that awaits for something,
	-- it will cause the game to hang indefinitely, effectively preventing it from loading.
	-- This is intentional design to discourge yielding at a top level.
	while true do
		local isReady = true
		for _, thread in threads do
			if coroutine.status(thread) ~= "dead" then
				isReady = false
				break
			end
		end
		if isReady then
			break
		else
			task.wait()
		end
	end

	-- To "fix" server loading. This is a temporary workaround
	-- until proper fix is applied to the server code.
	if shouldWait then
		task.wait(0.25)
	end

	-- Start modules in a specified order
	for _, container in { Services, Controllers, Components } do
		for _, module in container do
			-- Only call start if it is present
			if module.Return.FeatherStart then
				-- Basicaly equivalent of `module:FeatherStart()` but more explicit
				local start = os.clock()
				task.spawn(function()
					module.Return.FeatherStart(module.Return)
				end)
				table.insert(Ran, module.Script.Name)
				lastRan = module.Script
			end
		end
	end

	print(string.format("Started in %.2f ms", (os.clock() - t) * 1000))
end

local function WrapService<T>(
	module: T & FeatherStruct,
	script: LuaSourceContainer
): T
	table.insert(Services, {
		Script = script,
		Return = module
	})
	return module
end

local function WrapController<T>(
	module: T & FeatherStruct,
	script: LuaSourceContainer
): T
	table.insert(Controllers, {
		Script = script,
		Return = module
	})
	return module
end

local function WrapComponent<T>(
	module: T & FeatherStruct,
	script: LuaSourceContainer
): T
	table.insert(Components, {
		Script = script,
		Return = module
	})
	return module
end


local function DeferRequire(target: ModuleScript): any
	local out = { Content = nil }

	task.defer(function()
		out.Content = Require(target)
	end)

	return setmetatable({}, {
		__index = function(t, k)
			assert(out.Content)
			return out.Content[k]
		end
	})
end

local function StartServerAsync(parents: {Instance}): ()
	StartAsync(parents, true)
	workspace:SetAttribute("IsServerLoaded", true)
end

local function StartClientAsync(parents: {Instance}): ()
	-- Wait for server to load. This mostly happens in studio
	while workspace:GetAttribute("IsServerLoaded") ~= true do
		task.wait()
	end
	StartAsync(parents, false)
end

return {
	StartServerAsync = StartServerAsync,
	StartClientAsync = StartClientAsync,
	DeferRequire = DeferRequire,
	WrapComponent = WrapComponent,
	WrapController = WrapController,
	WrapService = WrapService
}
