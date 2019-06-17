require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"

_LOCALPATH = "/minecraftbound/gunUI/"
function lp(var)
	if not var then return end
	if string.sub(var, 1,1) == "/" then
		return var 
	else 
		return _LOCALPATH..var
	end 
end

ISLOCAL = false
ownerID = nil

--

require(lp("moduleloader.lua"))
require(lp("util.lua"))
FX = loadModule(lp("uiclass.lua"))
FX.configPath = "FX.config"
localUI = nil

function init()

	entityID = animationConfig.animationParameter("entityID")
	if type(entityID) == "number" then
		ISLOCAL = world.sendEntityMessage(entityID, "isLocal"):finished()
	end
	FX:init()
end

function load_localUI()
	localUI = loadModule(lp("uiclass.lua"))
	localUI.configPath = "localUI.config"
	localUI:init() 
end 

function update()
	localAnimator.clearDrawables()
	localAnimator.clearLightSources()
	local dt = 1/62

	if ISLOCAL then
		if not localUI then load_localUI() end
		localUI:update(dt)
	end

	FX:update(dt)
end

function uninit()
	if localUI then
		localUI:uninit(dt)
	end

	FX:uninit(dt)
end