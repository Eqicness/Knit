--[=[
	@interface ServiceDef
	.Name string
	.Client table?
	.[any] any
	@within KnitServer
	Used to define a service when creating it in `CreateService`.
]=]
type ServiceDef = {
	Name: string,
	Client: {[any]: any}?,
	[any]: any,
}

--[=[
	@interface Service
	.Name string
	.Client ServiceClient
	.KnitComm Comm
	.[any] any
	@within KnitServer
]=]
type Service = {
	Name: string,
	Client: ServiceClient,
	KnitComm: any,
	[any]: any,
}

--[=[
	@interface ServiceClient
	.Server Service
	.[any] any
	@within KnitServer
]=]
type ServiceClient = {
	Server: Service,
	[any]: any,
}

--[=[
	@type ServerMiddlewareFn (player: Player, args: {any}) -> (shouldContinue: boolean, ...: any)
	@within KnitServer

	For more info, see [ServerComm](https://sleitnick.github.io/RbxUtil/api/ServerComm/) documentation.
]=]

--[=[
	@interface KnitOptions
	.InboundMiddleware ServerMiddlewareFn?
	.OutboundMiddleware ServerMiddlewareFn?
	@within KnitServer

	- `InboundMiddleware` and `OutboundMiddleware` default to `nil`.
]=]
type KnitOptions = {
	InboundMiddleware: {(...any) -> (boolean, ...any)}?,
	OutboundMiddleware: {(...any) -> (boolean, ...any)}?,
}

local defaultOptions: KnitOptions = {
	InboundMiddleware = nil;
	OutboundMiddleware = nil;
}

local selectedOptions = nil

--[=[
	@class KnitServer
	@server
	Knit server-side lets developers create services and expose methods and signals
	to the clients.

	```lua
	local Knit = require(somewhere.Knit)

	-- Load service modules within some folder:
	Knit.AddServices(somewhere.Services)

	-- Start Knit:
	Knit.Start():andThen(function()
		print("Knit started")
	end):catch(warn)
	```
]=]
local KnitServer = {}

--[=[
	@prop Util Folder
	@within KnitServer
	@readonly
	References the Util folder. Should only be accessed when using Knit as
	a standalone module. If using Knit from Wally, modules should just be
	pulled in via Wally instead of relying on Knit's Util folder, as this
	folder only contains what is necessary for Knit to run in Wally mode.
]=]
KnitServer.Util = script.Parent.Parent

local SIGNAL_MARKER = newproxy(true)
getmetatable(SIGNAL_MARKER).__tostring = function()
	return "SIGNAL_MARKER"
end

local PROPERTY_MARKER = newproxy(true)
getmetatable(PROPERTY_MARKER).__tostring = function()
	return "PROPERTY_MARKER"
end

local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"

local Promise = require(KnitServer.Util.Promise)
local Comm = require(KnitServer.Util.Comm)
local ServerComm = Comm.ServerComm

local services: {[string]: Service} = {}
local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function CreateRepFolder(serviceName: string): Instance
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	folder.Parent = knitRepServiceFolder
	return folder
end


local function DoesServiceExist(serviceName: string): boolean
	local service: Service? = services[serviceName]
	return service ~= nil
end


--[=[
	@param serviceDefinition ServiceDef
	@return Service
	Constructs a new service.

	:::caution
	Services must be created _before_ calling `Knit.Start()`.
	:::
	```lua
	-- Create a service
	local MyService = Knit.CreateService {
		Name = "MyService";
		Client = {};
	}

	-- Expose a ToAllCaps remote function to the clients
	function MyService.Client:ToAllCaps(player, msg)
		return msg:upper()
	end

	-- Knit will call KnitStart after all services have been initialized
	function MyService:KnitStart()
		print("MyService started")
	end

	-- Knit will call KnitInit when Knit is first started
	function MyService:KnitInit()
		print("MyService initialize")
	end
	```
]=]
function KnitServer.CreateService(serviceDef: ServiceDef): Service
	assert(type(serviceDef) == "table", "Service must be a table; got " .. type(serviceDef))
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string; got " .. type(serviceDef.Name))
	assert(#serviceDef.Name > 0, "Service.Name must be a non-empty string")
	assert(not DoesServiceExist(serviceDef.Name), "Service \"" .. serviceDef.Name .. "\" already exists")
	local service = serviceDef
	service.KnitComm = ServerComm.new(CreateRepFolder(serviceDef.Name))
	if type(service.Client) ~= "table" then
		service.Client = {Server = service}
	else
		if service.Client.Server ~= service then
			service.Client.Server = service
		end
	end
	services[service.Name] = service
	return service
end


--[=[
	@param parent Instance
	@return services: {Service}
	Requires all the modules that are children of the given parent. This is an easy
	way to quickly load all services that might be in a folder.
	```lua
	Knit.AddServices(somewhere.Services)
	```
]=]
function KnitServer.AddServices(parent: Instance): {Service}
	local addedServices = {}
	for _,v in ipairs(parent:GetChildren()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedServices, require(v))
	end
	return addedServices
end


--[=[
	@param parent Instance
	@return services: {Service}
	Requires all the modules that are descendants of the given parent.
]=]
function KnitServer.AddServicesDeep(parent: Instance): {Service}
	local addedServices = {}
	for _,v in ipairs(parent:GetDescendants()) do
		if not v:IsA("ModuleScript") then continue end
		table.insert(addedServices, require(v))
	end
	return addedServices
end


--[=[
	@param serviceName string
	@return Service
	Gets the service by name. Throws an error if the service is not found.
]=]
function KnitServer.GetService(serviceName: string): Service
	assert(started, "Cannot call GetService until Knit has been started")
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	return assert(services[serviceName], "Could not find service \"" .. serviceName .. "\"") :: Service
end


--[=[
	@return SIGNAL_MARKER
	Returns a marker that will transform the current key into
	a RemoteSignal once the service is created. Should only
	be called within the Client table of a service.

	See [RemoteSignal](https://sleitnick.github.io/RbxUtil/api/RemoteSignal)
	documentation for more info.
	```lua
	local MyService = Knit.CreateService {
		Name = "MyService";
		Client = {
			-- Create the signal marker, which will turn into a
			-- RemoteSignal when Knit.Start() is called:
			MySignal = Knit.CreateSignal()
		}
	}

	function MyService:KnitInit()
		-- Connect to the signal:
		self.Client.MySignal:Connect(function(player, ...) end)
	end
	```
]=]
function KnitServer.CreateSignal()
	return SIGNAL_MARKER
end


--[=[
	@param initialValue any
	@return PROPERTY_MARKER
	Returns a marker that will transform the current key into
	a RemoteProperty once the service is created. Should only
	be called within the Client table of a service. An initial
	value can be passed along as well.

	RemoteProperties are great for replicating data to all of
	the clients. Different data can also be set per client.

	See [RemoteProperty](https://sleitnick.github.io/RbxUtil/api/RemoteProperty)
	documentation for more info.

	```lua
	local MyService = Knit.CreateService {
		Name = "MyService";
		Client = {
			-- Create the property marker, which will turn into a
			-- RemoteProperty when Knit.Start() is called:
			MyProperty = Knit.CreateProperty("HelloWorld")
		}
	}

	function MyService:KnitInit()
		-- Change the value of the property:
		self.Client.MyProperty:Set("HelloWorldAgain")
	end
	```
]=]
function KnitServer.CreateProperty(initialValue: any)
	return {PROPERTY_MARKER, initialValue}
end


--[=[
	@param options KnitOptions?
	@return Promise
	Starts Knit. Should only be called once.

	Optionally, `KnitOptions` can be passed in order to set
	Knit's custom configurations.

	:::caution
	Be sure that all services have been created _before_
	calling `Start`. Services cannot be added later.
	:::

	```lua
	Knit.Start():andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
	
	Example of Knit started with options:
	```lua
	Knit.Start({
		InboundMiddleware: {
			function(player, args)
				print("Player is giving following args to server:", args)
				return true
			end
		}
	}):andThen(function()
		print("Knit started!")
	end):catch(warn)
	```
]=]
function KnitServer.Start(options: KnitOptions?)

	if started then
		return Promise.reject("Knit already started")
	end

	started = true

	if options == nil then
		selectedOptions = defaultOptions
	else
		assert(typeof(options) == "table", "KnitOptions should be a table or nil; got " .. typeof(options))
		selectedOptions = options
		for k,v in pairs(defaultOptions) do
			if selectedOptions[k] == nil then
				selectedOptions[k] = v
			end
		end
	end

	return Promise.new(function(resolve)

		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if type(v) == "function" then
					service.KnitComm:WrapMethod(service.Client, k, selectedOptions.InboundMiddleware, selectedOptions.OutboundMiddleware)
				elseif v == SIGNAL_MARKER then
					service.Client[k] = service.KnitComm:CreateSignal(k, selectedOptions.InboundMiddleware, selectedOptions.OutboundMiddleware)
				elseif type(v) == "table" and v[1] == PROPERTY_MARKER then
					service.Client[k] = service.KnitComm:CreateProperty(k, v[2], selectedOptions.InboundMiddleware, selectedOptions.OutboundMiddleware)
				end
			end
		end

		-- Init:
		local promisesInitServices = {}
		for _,service in pairs(services) do
			if type(service.KnitInit) == "function" then
				table.insert(promisesInitServices, Promise.new(function(r)
					service:KnitInit()
					r()
				end))
			end
		end

		resolve(Promise.all(promisesInitServices))

	end):andThen(function()

		-- Start:
		for _,service in pairs(services) do
			if type(service.KnitStart) == "function" then
				task.spawn(service.KnitStart, service)
			end
		end

		startedComplete = true
		onStartedComplete:Fire()

		task.defer(function()
			onStartedComplete:Destroy()
		end)

		-- Expose service remotes to everyone:
		knitRepServiceFolder.Parent = script.Parent

	end)

end


--[=[
	@return Promise
	Returns a promise that is resolved once Knit has started. This is useful
	for any code that needs to tie into Knit services but is not the script
	that called `Start`.
	```lua
	Knit.OnStart():andThen(function()
		local MyService = Knit.Services.MyService
		MyService:DoSomething()
	end):catch(warn)
	```
]=]
function KnitServer.OnStart()
	if startedComplete then
		return Promise.resolve()
	else
		return Promise.fromEvent(onStartedComplete.Event)
	end
end


return KnitServer
