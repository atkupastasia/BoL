--[[ iCass Classic by Apple ]]--

if myHero.charName ~= "Cassiopeia" then return end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("C")
local HK3 = string.byte("T")

--[[ Constants ]]--

local QDelay = 0.500
local WDelay = 0.300
local QRange = 850
local ERange = 700

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP, QRange, DAMAGE_MAGIC, false)
local tpQ = TargetPredictionVIP(QRange, math.huge, QDelay, 130)
local tpW = TargetPredictionVIP(WRange, math.huge, WDelay, 300)
local PoisionTimers = {}

local itemsList = {
	{id = 3153, slot = nil, ready = false},
	{id = 3123, slot = nil, ready = false},
	{id = 3142, slot = nil, ready = false},
	{id = 3143, slot = nil, ready = false},
	{id = 3042, slot = nil, ready = false},
	{id = 3128, slot = nil, ready = false},
	{id = 3146, slot = nil, ready = false},
	{id = 3144, slot = nil, ready = false},
}


function OnLoad()
	iCCConfig = scriptConfig("iCass Classic", "iCass Classic")

	iCCConfig:addParam("pewpew", "PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iCCConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false,  HK2)
	iCCConfig:addParam("autoE", "Auto E", SCRIPT_PARAM_ONKEYTOGGLE, true, HK3)
	iCCConfig:addParam("increasedQRange", "Increased Q Range", SCRIPT_PARAM_ONOFF, true)
	iCCConfig:addParam("useItems", "Use Items", SCRIPT_PARAM_ONOFF, true)
	iCCConfig:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, false)
	iCCConfig:addParam("drawcircles","Draw Circles", SCRIPT_PARAM_ONOFF, true)

	iCCConfig:permaShow("pewpew")
	iCCConfig:permaShow("harass")
	iCCConfig:permaShow("autoE")

	ts.name = "Cassiopeia"
	iCCConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)

	PoisionTimers.enemies = GetEnemyHeroes()
	PoisionTimers.poison = {}
end

function OnTick()
	QRange = 850 + (iCCConfig.increasedQRange and 75 or 0)
	ts:update()
	updateItems()

	if not myHero.dead and ValidTarget(ts.target) then
		autoIgnite()
		if iCCConfig.pewpew then PewPew() end
		if iCCConfig.harass then Poke() end
		if iCCConfig.autoE or iCCConfig.pewpew then autoE() end
	end
	if (iCCConfig.pewpew or iCCConfig.harass) and iCCConfig.moveToMouse then
		myHero:MoveTo(mousePos.x, mousePos.z)
	end
end

function PewPew()
	if myHero:CanUseSpell(_Q) == READY then
		local _,_,QPos = tpQ:GetPrediction(ts.target)
		if QPos and tpQ:GetHitChance(ts.target) > 0.3 then
			if GetDistance(QPos) <= 850 or not iCCConfig.increasedQRange then
				CastSpell(_Q, QPos.x, QPos.z)
			elseif GetDistance(QPos) <= 925 then
				local castPos = Vector(QPos) + (Vector(QPos) - Vector(myHero)):normalized() * 850
				CastSpell(_Q, castPos.x, castPos.z)
			end
		end
	end
	if myHero:CanUseSpell(_W) == READY then
		local _,_,WPos = tpW:GetPrediction(ts.target)
		if WPos and tpQ:GetHitChance(ts.target) > 0.3 then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function Poke()
	if myHero:CanUseSpell(_Q) == READY then
		local _,_,QPos = tpQ:GetPrediction(ts.target)
		if QPos and tpQ:GetHitChance(ts.target) > 0.3 then
			if GetDistance(QPos) <= 850 or not iCCConfig.increasedQRange then
				CastSpell(_Q, QPos.x, QPos.z)
			elseif GetDistance(QPos) <= 925 then
				local castPos = Vector(QPos) + (Vector(QPos) - Vector(myHero)):normalized() * 850
				CastSpell(_Q, castPos.x, castPos.z)
			end
		end
	end
end

function autoE()
	if myHero:CanUseSpell(_E) == READY then
		if GetDistance(ts.target) < ERange and (isPoisoned(ts.target) or getDmg("E", ts.target, myHero) > ts.target.health) then
			if iCCConfig.useItems then
				for i, item in ipairs(itemsList) do
					if item.ready then
						CastSpell(item.slot, ts.target)
					end
				end
			end
			CastSpell(_E, ts.target)
		end
	end
end

function autoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, igniteRange) and enemy.health < getDmg("IGNITE", enemy, myHero) then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

function updateItems()
	for i, item in ipairs(itemsList) do
		item.slot = GetInventorySlotItem(item.id)
		item.ready = (item.slot and myHero:CanUseSpell(item.slot) == READY or false)
	end
end

function isPoisoned(enemy)
	for i, poison in ipairs(PoisionTimers.poison) do
		if not poison.object.valid then
			table.remove(PoisionTimers.poison, i)
		elseif GetDistance(enemy, poison.object) < 80 and GetTickCount() - poison.tick < 2700 then
			return true
		end
	end
	return false
end

function OnCreateObj(object)
	if string.lower(object.name):find("global_goison") then
		for i, enemy in ipairs(PoisionTimers.enemies) do
			if GetDistance(object, enemy) < 80 then
				table.insert(PoisionTimers.poison, {object = object, tick = GetTickCount()})
			end
		end
	end
end

function OnDeleteObj(object)
	if string.lower(object.name):find("global_goison") then
		for i, poison in ipairs(PoisionTimers.poison) do
			if object.rawHash == poison.rawHash then
				table.remove(PoisionTimers.poison, i)
			end
		end
	end
end

function OnDraw()
	if iCCConfig.drawcircles then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFF80FF00)
		if ValidTarget(ts.target) then
			DrawText("Targetting: " .. ts.target.charName, 18, 100, 100, 0xFFFF0000)
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0xFF80FF00)
		end
	end
end