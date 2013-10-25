--[[ iLise by Apple ]]--

if myHero.charName ~= "Elise" then return end

if VIP_USER then require "Collision" end
if VIP_USER and FileExist(LIB_PATH.."Prodiction.lua") then require "Prodiction" end
require "iSAC"

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")               
local HK4 = string.byte("X")
local minHitChance = 0.3
local LeapW = false
local tpProMaxTick = 20

--[[ Constants ]]--

local QRange = 650
local WRange, WSpeed, WDelay, WWidth = 950, 1000, 0.250, 100
local ERange, ESpeed, EDelay, EWidth = 1050, 1300, 0.250, 70

local SpiderRange = 550

local AARange = 600

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST, 1200, DAMAGE_MAGIC, false)
local tpW = VIP_USER and TargetPredictionVIP(WRange, WSpeed, WDelay, WWidth) or TargetPrediction(WRange, WSpeed/1000, WDelay*1000, WWidth)
local tpWCollision = VIP_USER and Collision(WRange, WSpeed, WDelay, WWidth*2)
local tpE = VIP_USER and TargetPredictionVIP(ERange, ESpeed, EDelay, EWidth) or TargetPrediction(ERange, ESpeed/1000, EDelay*1000, EWidth)
local tpECollision = VIP_USER and Collision(ERange, ESpeed, EDelay, EWidth*2)
local tpProPos = { [_W] = {}, [_E] = {}, }
local tpPro = ProdictManager and ProdictManager.GetInstance() or nil
local tpProW = tpPro and tpPro:AddProdictionObject(_W, WRange, WSpeed, WDelay, WWidth, myHero, function(unit, pos, spell) if not unit or not pos then return end tpProPos[_W][unit.networkID] = {pos = pos, updateTick = GetTickCount()} end) or nil
local tpProE = tpPro and tpPro:AddProdictionObject(_E, ERange, ESpeed, EDelay, EWidth, myHero, function(unit, pos, spell) if not unit or not pos then return end tpProPos[_E][unit.networkID] = {pos = pos, updateTick = GetTickCount()} end) or nil
local iOW = iOrbWalker(AARange, true)
local iSum = iSummoners()

local Humanform = true
local igniteSlot = nil
local enemyMinions = {}
local JungleMobs = {}
local JungleFocusMobs = {}
local QCast = false
local nextSpiderQAvailable = 0

--[[ Predefined Tables ]]--

local JungleMobNames = { -- List stolen from SAC Revamped. Sorry, Sida!
	["wolf8.1.1"] = true,
	["wolf8.1.2"] = true,
	["YoungLizard7.1.2"] = true,
	["YoungLizard7.1.3"] = true,
	["LesserWraith9.1.1"] = true,
	["LesserWraith9.1.2"] = true,
	["LesserWraith9.1.4"] = true,
	["YoungLizard10.1.2"] = true,
	["YoungLizard10.1.3"] = true,
	["SmallGolem11.1.1"] = true,
	["wolf2.1.1"] = true,
	["wolf2.1.2"] = true,
	["YoungLizard1.1.2"] = true,
	["YoungLizard1.1.3"] = true,
	["LesserWraith3.1.1"] = true,
	["LesserWraith3.1.2"] = true,
	["LesserWraith3.1.4"] = true,
	["YoungLizard4.1.2"] = true,
	["YoungLizard4.1.3"] = true,
	["SmallGolem5.1.1"] = true,
}

local FocusJungleNames = {
	["Dragon6.1.1"] = true,
	["Worm12.1.1"] = true,
	["GiantWolf8.1.3"] = true,
	["AncientGolem7.1.1"] = true,
	["Wraith9.1.3"] = true,
	["LizardElder10.1.1"] = true,
	["Golem11.1.2"] = true,
	["GiantWolf2.1.3"] = true,
	["AncientGolem1.1.1"] = true,
	["Wraith3.1.3"] = true,
	["LizardElder4.1.1"] = true,
	["Golem5.1.2"] = true,
}

--[[ Core Callbacks ]]--

function OnLoad()
	iLiseConfig = scriptConfig("iLise - Main", "iLise")

	iLiseConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iLiseConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iLiseConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)
	iLiseConfig:addParam("jungleFarm", "Munching Jungle", SCRIPT_PARAM_ONKEYDOWN, false, HK3)
	iLiseConfig:addParam("autoKS", "Auto Q KS", SCRIPT_PARAM_ONOFF, true)
	iLiseConfig:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	if tpPro then iLiseConfig:addParam("tpPro", "Use Prodiction", SCRIPT_PARAM_ONOFF, true) end

	iLiseConfig:permaShow("pewpew")
	iLiseConfig:permaShow("harass")
	iLiseConfig:permaShow("autoFarm")
	iLiseConfig:permaShow("jungleFarm")

	iLiseSpellConfig = scriptConfig("iLise - Spells", "iLiseSpells")
	iLiseSpellConfig:addParam("useHumanQ", "Use Human Q", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("useHumanW", "Use Human W", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("useHumanE", "Use Human E", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("useSpiderQ", "Use Spider Q", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("useSpiderW", "Use Spider W", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("useSpiderE", "Use Spider E", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("switchToSpider", "Switch to Spiderform", SCRIPT_PARAM_ONOFF, true)
	iLiseSpellConfig:addParam("switchToHuman", "Switch to Humanform", SCRIPT_PARAM_ONOFF, true)

	ts.name = "Elise"
	iLiseConfig:addTS(ts)
	iOW:addReset("EliseRSpider")
	iOW:addReset("EliseSpiderQCast")
	iOW:addReset("EliseSpiderW")
	iOW:addReset("EliseR")

	igniteSlot = (myHero:GetSpellData(SUMMONER_1).name == "SummonerDot" and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name == "SummonerDot" and SUMMONER_2) or nil
	enemyMinions = minionManager(MINION_ENEMY, WRange, myHero, MINION_SORT_HEALTH_ASC)

	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end

function OnTick()
	Humanform = myHero:GetSpellData(_Q).name == "EliseHumanQ"
	enemyMinions:update()
	AARange = GetDistance(myHero.minBBox) + myHero.range
	iOW.AARange = AARange
	ts.range = (Humanform or iLiseSpellConfig.useSpiderE) and 1200 or SpiderRange
	ts:update()

	if not myHero.dead then
		iSum:AutoIgnite()	
		if ValidTarget(ts.target) then if iLiseConfig.tpPro then tpProW:EnableTarget(ts.target, true) tpProE:EnableTarget(ts.target, true) end
		if iLiseConfig.autoKS then AutoKS() end
		if iLiseConfig.pewpew then PewPew() if iLiseConfig.Orbwalk then iOW:Orbwalk(mousePos, ts.target) end end
		if iLiseConfig.harass then Poke() end
		if iLiseConfig.jungleFarm then JungleFarm() end
		if iLiseConfig.autoFarm then Farm() end
	end
end

function OnCreateObj(object)
	if object.name == "Elise_human_Q_mis.troy" then
		QCast = true
	elseif FocusJungleNames[object.name] then
		table.insert(JungleFocusMobs, object)
	elseif JungleMobNames[object.name] then
		table.insert(JungleMobs, object)
	end
end

function OnDeleteObj(object)
	if object.name == "Elise_human_Q_mis.troy" then
		QCast = false
	else
		for i, Mob in pairs(JungleMobs) do
			if object.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in pairs(JungleFocusMobs) do
			if object.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target) then return end
	if Humanform then
		if myHero:CanUseSpell(_Q) == READY and iLiseSpellConfig.useHumanQ and GetDistance(ts.target) < QRange then
			CastSpell(_Q, ts.target)
		elseif not iLiseSpellConfig.useHumanQ or (not QCast or getDmg("Q", ts.target, myHero) < ts.target.health) then
			local EPos = myHero:CanUseSpell(_E) == READY and iLiseSpellConfig.useHumanE and GetDistance(ts.target) < ERange and GetEPrediction(ts.target) or nil
			local WPos = myHero:CanUseSpell(_W) == READY and iLiseSpellConfig.useHumanW and GetDistance(ts.target) < WRange and GetWPrediction(ts.target) or nil
			if EPos then
				CastSpell(_E, EPos.x, EPos.z)
			elseif LeapW and myHero:CanUseSpell(_W) == READY and myHero:CanUseSpell(_R) == READY and myHero:GetSpellData(_Q).level > 0 and GetTickCount() > nextSpiderQAvailable and GetDistance(ts.target) < SpiderRange then
				local WPos1 = {x = myHero.x + (myHero.x - ts.target.x) / GetDistance(ts.target) * WRange, y = myHero.y, z = myHero.z + (myHero.z - ts.target.z) / GetDistance(ts.target) * WRange}
				local willCollide, collideArray = tpWCollision:GetMinionCollision(myHero, WPos1)
				if not willCollide then
					CastSpell(_W, WPos1.x, WPos1.z)
					CastSpell(_R)
				elseif WPos then
					CastSpell(_W, WPos.x, WPos.z)
					CastSpell(_R)
				end
			elseif WPos then
				CastSpell(_W, WPos.x, WPos.z)
			elseif myHero:CanUseSpell(_R) == READY and iLiseSpellConfig.switchToSpider and (iLiseSpellConfig.useSpiderE or GetDistance(ts.target) < SpiderRange) then
				CastItem(3144, ts.target)
				CastItem(3153, ts.target)
				CastItem(3128, ts.target)
				CastItem(3146, ts.target)
				CastSpell(_R)
			end
		end
	else
		local inSpiderRange = GetDistance(ts.target) < SpiderRange
		if myHero:CanUseSpell(_Q) == READY and iLiseSpellConfig.useSpiderQ and inSpiderRange then
			CastSpell(_Q, ts.target)
			nextSpiderQAvailable = GetTickCount() + (myHero:GetSpellData(_Q).cd * (1 - myHero.cdr)) * 1000
		elseif getDmg("QM", ts.target, myHero) < ts.target.health then
			if myHero:CanUseSpell(_E) == READY and not inSpiderRange and iLiseSpellConfig.useSpiderE then
				CastSpell(_E, ts.target)
			elseif myHero:CanUseSpell(_W) == READY and iLiseSpellConfig.useSpiderW and inSpiderRange then
				CastSpell(_W)
			elseif myHero:CanUseSpell(_R) == READY and iLiseSpellConfig.switchToHuman and not TargetHaveBuff("EliseSpiderW", myHero) then
				CastSpell(_R)
			end
		end
	end
end

function AutoKS()
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if Humanform and GetDistance(enemy) < QRange and getDmg("Q", enemy, myHero) > enemy.health then
				CastSpell(_Q, enemy)
			elseif not Humanform and GetDistance(enemy) < SpiderRange and getDmg("QM", enemy, myHero) > enemy.health then
				CastSpell(_Q, enemy)
			end
		end
	end
end

function Poke()
	if ValidTarget(ts.target) and myHero:CanUseSpell(_Q) == READY then CastSpell(_Q, ts.target) iOW:Attack(ts.target) end
end

function JungleFarm()
	local Mob = GetJungleMob()
	if not Mob then return end
	if Humanform then
		if myHero:CanUseSpell(_Q) == READY then
			CastSpell(_Q, Mob)
		elseif myHero:CanUseSpell(_W) == READY then
			CastSpell(_W, Mob.x, Mob.z)
		elseif myHero:CanUseSpell(_R) == READY then
			CastSpell(_R)
		end
	elseif myHero:CanUseSpell(_Q) == READY then
		CastSpell(_Q, Mob)
	elseif myHero:CanUseSpell(_W) == READY then
		if GetDistance(Mob) < SpiderRange then
			CastSpell(_W)
		end
	end
	myHero:Attack(Mob)
	--if iLiseConfig.Orbwalk then iOW:Orbwalk(mousePos, Mob) end
end

function Farm()
	local BaseSpiderAD = myHero:GetSpellData(_R).level * 10 + 0.3 * myHero.ap
	for _, minion in ipairs(enemyMinions.objects) do
		if minion.health < (getDmg("AD", minion, myHero) + (Humanform and 0 or myHero:CalcMagicDamage(minion, BaseSpiderAD))) and iOW:GetStage() == STAGE_NONE then
			myHero:Attack(minion)
			return
		elseif iOW:GetStage() == STAGE_ORBWALK and myHero:CanUseSpell(_Q) == READY and (Humanform and getDmg("Q", minion, myHero) or getDmg("QM", minion, myHero) > minion.health) then
			CastSpell(_Q, minion)
			return
		end
	end
	if not GetJungleMob() then iOW:Move(mousePos) end
end

--[[ Predictions and Calculations ]]--

function GetWPrediction(enemy) 
	if iLiseConfig.tpPro then
		local tpProPosSub = tpProPos[_W][enemy.networkID]
		return tpProPosSub and CurrentTick - tpProPosSub.updateTick < tpProMaxTick and tpProPosSub.pos or nil
	elseif VIP_USER then
		if minHitChance ~= 0 and tpW:GetHitChance(enemy) < minHitChance then return nil end
		local WPos,_,_ = tpW:GetPrediction(enemy)
		local willCollide, collideArray = tpWCollision:GetMinionCollision(myHero, WPos)
		return not willCollide and WPos or nil
	else
		return tpW:GetPrediction(enemy)
	end
end

function GetEPrediction(enemy)
	if iLiseConfig.tpPro then
		local tpProPosSub = tpProPos[_E][enemy.networkID]
		return tpProPosSub and CurrentTick - tpProPosSub.updateTick < tpProMaxTick and tpProPosSub.pos or nil
	elseif VIP_USER then
		if minHitChance ~= 0 and tpE:GetHitChance(enemy) < minHitChance then return nil end
		local EPos,_,_ = tpE:GetPrediction(enemy)
		local willCollide, collideArray = tpECollision:GetMinionCollision(myHero, EPos)
		return not willCollide and EPos or nil
	else
		return tpE:GetPrediction(enemy)
	end
end

--[[ Garbage Bin ]]--

function GetJungleMob()
	for _, Mob in pairs(JungleFocusMobs) do
		if ValidTarget(Mob, WRange) then return Mob end
	end
	for _, Mob in pairs(JungleMobs) do
		if ValidTarget(Mob, WRange) then return Mob end
	end
end