"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[824],{19077:function(e){e.exports=JSON.parse('{"functions":[{"name":"CreateService","desc":"Constructs a new service.\\n\\n:::caution\\nServices must be created _before_ calling `Knit.Start()`.\\n:::\\n```lua\\n-- Create a service\\nlocal MyService = Knit.CreateService {\\n\\tName = \\"MyService\\";\\n\\tClient = {};\\n}\\n\\n-- Expose a ToAllCaps remote function to the clients\\nfunction MyService.Client:ToAllCaps(player, msg)\\n\\treturn msg:upper()\\nend\\n\\n-- Knit will call KnitStart after all services have been initialized\\nfunction MyService:KnitStart()\\n\\tprint(\\"MyService started\\")\\nend\\n\\n-- Knit will call KnitInit when Knit is first started\\nfunction MyService:KnitInit()\\n\\tprint(\\"MyService initialize\\")\\nend\\n```","params":[{"name":"serviceDefinition","desc":"","lua_type":"ServiceDef"}],"returns":[{"desc":"","lua_type":"Service"}],"function_type":"static","source":{"line":162,"path":"src/KnitServer.lua"}},{"name":"AddServices","desc":"Requires all the modules that are children of the given parent. This is an easy\\nway to quickly load all services that might be in a folder.\\n```lua\\nKnit.AddServices(somewhere.Services)\\n```","params":[{"name":"parent","desc":"","lua_type":"Instance"}],"returns":[{"desc":"","lua_type":"services: {Service}"}],"function_type":"static","source":{"line":195,"path":"src/KnitServer.lua"}},{"name":"AddServicesDeep","desc":"Requires all the modules that are descendants of the given parent.","params":[{"name":"parent","desc":"","lua_type":"Instance"}],"returns":[{"desc":"","lua_type":"services: {Service}"}],"function_type":"static","source":{"line":210,"path":"src/KnitServer.lua"}},{"name":"GetService","desc":"Gets the service by name. Throws an error if the service is not found.","params":[{"name":"serviceName","desc":"","lua_type":"string"}],"returns":[{"desc":"","lua_type":"Service"}],"function_type":"static","source":{"line":225,"path":"src/KnitServer.lua"}},{"name":"CreateSignal","desc":"Returns a marker that will transform the current key into\\na RemoteSignal once the service is created. Should only\\nbe called within the Client table of a service.\\n\\nSee [RemoteSignal](https://sleitnick.github.io/RbxUtil/api/RemoteSignal)\\ndocumentation for more info.\\n```lua\\nlocal MyService = Knit.CreateService {\\n\\tName = \\"MyService\\";\\n\\tClient = {\\n\\t\\tMySignal = Knit.CreateSignal(); -- Create the signal marker\\n\\t}\\n}\\n\\n-- Connect to the signal:\\nMyService.Client.MySignal:Connect(function(player, ...) end)\\n```","params":[],"returns":[{"desc":"","lua_type":"SIGNAL_MARKER"}],"function_type":"static","source":{"line":252,"path":"src/KnitServer.lua"}},{"name":"Start","desc":"Starts Knit. Should only be called once.\\n\\nOptionally, `KnitOptions` can be passed in order to set\\nKnit\'s custom configurations.\\n\\n:::caution\\nBe sure that all services have been created _before_ calling `Start`. Services cannot be added later.\\n:::\\n\\n```lua\\nKnit.Start():andThen(function()\\n\\tprint(\\"Knit started!\\")\\nend):catch(warn)\\n```\\n\\nExample of Knit started with options:\\n```lua\\nKnit.Start({\\n\\tInboundMiddleware: {\\n\\t\\tfunction(player, args)\\n\\t\\t\\tprint(\\"Player is giving following args to server:\\", args)\\n\\t\\t\\treturn true\\n\\t\\tend\\n\\t}\\n}):andThen(function()\\n\\tprint(\\"Knit started!\\")\\nend):catch(warn)\\n```","params":[{"name":"options","desc":"","lua_type":"KnitOptions?"}],"returns":[{"desc":"","lua_type":"Promise"}],"function_type":"static","source":{"line":289,"path":"src/KnitServer.lua"}},{"name":"OnStart","desc":"Returns a promise that is resolved once Knit has started. This is useful\\nfor any code that needs to tie into Knit services but is not the script\\nthat called `Start`.\\n```lua\\nKnit.OnStart():andThen(function()\\n\\tlocal MyService = Knit.Services.MyService\\n\\tMyService:DoSomething()\\nend):catch(warn)\\n```","params":[],"returns":[{"desc":"","lua_type":"Promise"}],"function_type":"static","source":{"line":371,"path":"src/KnitServer.lua"}}],"properties":[{"name":"Util","desc":"References the Util folder. Should only be accessed when using Knit as\\na standalone module. If using Knit from Wally, modules should just be\\npulled in via Wally instead of relying on Knit\'s Util folder, as this\\nfolder only contains what is necessary for Knit to run in Wally mode.","lua_type":"Folder","readonly":true,"source":{"line":97,"path":"src/KnitServer.lua"}}],"types":[{"name":"ServiceDef","desc":"Used to define a service when creating it in `CreateService`.","fields":[{"name":"Name","lua_type":"string","desc":""},{"name":"Client","lua_type":"table?","desc":""},{"name":"[any]","lua_type":"any","desc":""}],"source":{"line":9,"path":"src/KnitServer.lua"}},{"name":"Service","desc":"","fields":[{"name":"Name","lua_type":"string","desc":""},{"name":"Client","lua_type":"ServiceClient","desc":""},{"name":"KnitComm","lua_type":"Comm","desc":""},{"name":"[any]","lua_type":"any","desc":""}],"source":{"line":23,"path":"src/KnitServer.lua"}},{"name":"ServiceClient","desc":"","fields":[{"name":"Server","lua_type":"Service","desc":""},{"name":"[any]","lua_type":"any","desc":""}],"source":{"line":36,"path":"src/KnitServer.lua"}},{"name":"ServerMiddlewareFn","desc":"For more info, see [ServerComm](https://sleitnick.github.io/RbxUtil/api/ServerComm/) documentation.","lua_type":"(player: Player, args: {any}) -> (shouldContinue: boolean, ...: any)","source":{"line":47,"path":"src/KnitServer.lua"}},{"name":"KnitOptions","desc":"- `InboundMiddleware` and `OutboundMiddleware` default to `nil`.","fields":[{"name":"InboundMiddleware","lua_type":"ServerMiddlewareFn?","desc":""},{"name":"OutboundMiddleware","lua_type":"ServerMiddlewareFn?","desc":""}],"source":{"line":56,"path":"src/KnitServer.lua"}}],"name":"KnitServer","desc":"Knit server-side lets developers create services and expose methods and signals\\nto the clients.\\n\\n```lua\\nlocal Knit = require(somewhere.Knit)\\n\\n-- Load service modules within some folder:\\nKnit.AddServices(somewhere.Services)\\n\\n-- Start Knit:\\nKnit.Start():andThen(function()\\n\\tprint(\\"Knit started\\")\\nend):catch(warn)\\n```","realm":["Server"],"source":{"line":86,"path":"src/KnitServer.lua"}}')}}]);