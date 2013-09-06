--[[ iFizz - Based on Tux's Fizz Something Fishy ]]--

if myHero.charName ~= "Fizz" then return end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")

local minHitChance = 0.3

--[[ Constants ]]--

local AARange = 200

local QRange = 550

local ERange = 400
local EDelay = 0.500
local ERadius = 250

local RRange = 1300
local RSpeed = 1200
local RDelay = 0.500
local RWidth = 80

local igniteRange = 600
local defaultItemRange = 500

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST, 700, DAMAGE_MAGIC, false)
local tpE = TargetPredictionVIP(ERange, math.huge, EDelay, ERadius*2)
local tpR = TargetPredictionVIP(RRange, RSpeed, RDelay, RWidth)

local igniteSlot = nil
local enemyMinions = {}
local updateTextTimers = {}

local items = {
	itemsList = {
		["BRK"] = {id = 3153, slot = nil, ready = false, useOnKill = false},
		["EXEC"] = {id = 3123, slot = nil, ready = false, useOnKill = false},
		["YOGH"] = {id = 3142, slot = nil, ready = false, useOnKill = false},
		["RANO"] = {id = 3143, slot = nil, ready = false, useOnKill = false},
		["MARU"] = {id = 3042, slot = nil, ready = false, useOnKill = false},
	
		["DFG"] = {id = 3128, slot = nil, ready = false, useOnKill = true},
		["HXG"] = {id = 3146, slot = nil, ready = false, useOnKill = true},
		["BWC"] = {id = 3144, slot = nil, ready = false, useOnKill = true},
	},
	passiveItemsList = {
		["LIANDRYS"] = {id = 3151, slot = nil},
		["BLACKFIRE"] = {id = 3188, slot = nil},
	},
}

--[[ Core Callbacks ]]--

function OnLoad()
	iFizzConfig = scriptConfig("iJizz", "iFizz")

	iFizzConfig:addParam("pewpew", "PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iFizzConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iFizzConfig:addParam("autoKS", "Auto KS", SCRIPT_PARAM_ONOFF, true)
	iFizzConfig:addParam("comboE", "Use E", SCRIPT_PARAM_ONOFF, true)
	iFizzConfig:addParam("comboUlt", "Use Ult", SCRIPT_PARAM_ONOFF, true)
	iFizzConfig:addParam("minionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)

	iFizzConfig:permaShow("pewpew")
	iFizzConfig:permaShow("harass")

	ts.name = "Fizz"
	iFizzConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts:update()
	updateItems()
	if iFizzConfig.minionMarker then enemyMinions:update() end

	if not myHero.dead then
		if iFizzConfig.pewpew then PewPew() end
		if iFizzConfig.autoKS then autoKS() end
	end
end

function OnDraw()
	if not myHero.dead then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x8080FF00)

		damageText()
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target, QRange) then return end
	UseItems(ts.target)
	local EPos = myHero:CanUseSpell(_E) == READY and GetEPrediction(ts.target)
	local RPos = myHero:CanUseSpell(_R) == READY and GetRPrediction(ts.target)
	local calcDmg = calculateDamage(ts.target, true, true)
	if calcDmg.Q > ts.target.health then
		CastSpell(_Q, ts.target)
	elseif calcDmg.W > ts.target.health and GetDistance(ts.target) < AARange then
		CastSpell(_W)
		myHero:Attack(ts.target)
	elseif iFizzConfig.comboE and EPos and calcDmg.E > ts.target.health then
		CastSpell(_E, EPos.x, EPos.z)
	elseif (calcDmg.W + calcDmg.Q) > ts.target.health then
		CastSpell(_Q, ts.target)
		CastSpell(_W, ts.target)
		myHero:Attack(ts.target)
	elseif iFizzConfig.comboE and EPos and (calcDmg.Q + calcDmg.E) > ts.target.health then
		CastSpell(_Q, ts.target)
		CastSpell(_E, EPos.x, EPos.z)
	elseif iFizzConfig.comboE and EPos and calcDmg.QWE > ts.target.health then
		CastSpell(_Q, ts.target)
		CastSpell(_E, EPos.x, EPos.z)
		CastSpell(_W)
		myHero:Attack(ts.target)
	elseif iFizzConfig.comboE and EPos and ((items.itemsList["DFG"].ready and 1.2 or 1) * calcDmg.QWE + calcDmg.items + calcDmg.ignite) > ts.target.health then
		UseItems(ts.target)
		CastSpell(_Q, ts.target)
		CastSpell(_E, EPos.x, EPos.z)
		CastSpell(_W)
		CastSpell(igniteSlot, ts.target)
		myHero:Attack(ts.target)
	elseif iFizzConfig.comboE and comboUlt and EPos and RPos and calcDmg.QWER > ts.target.health then
		CastSpell(_Q, ts.target)
		CastSpell(_E, EPos.x, EPos.z)
		CastSpell(_W)
		CastSpell(_R, RPos.x, RPos.z)
		myHero:Attack(ts.target)
	end
end

function Poke()
	if not validTarget(ts.target, QRange) then return end
	CastSpell(_W)
	CastSpell(_Q, ts.target)
	myHero:Attack(ts.target)
end

function autoKS()
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		if ValidTarget(enemy, QRange) then
			local QDmg = myHero:CanUseSpell(_Q) == READY and getDmg("Q", enemy, myHero) or 0
			local WDmg = myHero:CanUseSpell(_W) == READY and getDmg("W", enemy, myHero, (myHero:CanUseSpell(_W) == READY and 1 or 2)) or 0
			--local EDmg = myHero:CanUseSpell(_E) == READY and getDmg("E", enemy, myHero) or 0
			local ignDmg = igniteSlot and myHero:CanUseSpell(igniteSlot) == READY and getDmg("IGNITE", enemy, myHero) or 0
			if QDmg > enemy.health then
				CastSpell(_Q, enemy)
			elseif (QDmg + ignDmg) > enemy.health then
				CastSpell(_Q, enemy)
				CastSpell(igniteSlot, enemy)
			elseif (QDmg + WDmg) > enemy.health then
				CastSpell(_Q, enemy)
				CastSpell(_W)
				myHero:Attack(enemy)
			elseif (QDmg + WDmg + ignDmg) > enemy.health then
				CastSpell(_Q, enemy)
				CastSpell(_W)
				CastSpell(igniteSlot, enemy)
				myHero:Attack(enemy)
			end
		end
	end
end

function AutoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			local igniteDmg = getDmg("IGNITE", enemy, myHero)
			if ValidTarget(enemy, igniteRange) and enemy.health < igniteDmg then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

function UseItems(enemy)
	for _, item in ipairs(items.itemsList) do
		if item.ready then
			CastSpell(item.slot, enemy)
		end
	end
end

--[[ Predictions and Calculations ]]--

function GetEPrediction(enemy)
	if minHitChance ~= 0 and tpE:GetHitChance(enemy) < minHitChance then return nil end
	local _,_,EPos = tpE:GetPrediction(enemy)
	return EPos
end

function GetRPrediction(enemy)
	if minHitChance ~= 0 and tpR:GetHitChance(enemy) < minHitChance then return nil end
	local _,_,RPos = tpR:GetPrediction(enemy)
	return RPos
end

function calculateDamage(enemy, checkRange, readyCheck)
	local returnDamage = {}
	returnDamage.Qbase = (( (myHero:CanUseSpell(_Q) == READY or not readyCheck) and (GetDistance(enemy) < QRange or not checkRange) and getDmg("Q", enemy, myHero)) or 0)
	returnDamage.Wbase = (myHero:GetSpellData(_W).level > 0 and getDmg("W", enemy, myHero, (myHero:CanUseSpell(_W) == READY and 1 or 2)) or 0)
	returnDamage.Ebase = (( (myHero:CanUseSpell(_E) == READY or not readyCheck) and (GetDistance(enemy) < ERange or not checkRange) and getDmg("E", enemy, myHero)) or 0)
	returnDamage.Rbase = (( (myHero:CanUseSpell(_R) == READY or not readyCheck) and (GetDistance(enemy) < RRange or not checkRange) and getDmg("R", enemy, myHero)) or 0 )
	returnDamage.DFG = (( (items.itemsList["DFG"].ready or (items.itemsList["DFG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("DFG", enemy, myHero)) or 0 )
	returnDamage.HXG = (( (items.itemsList["HXG"].ready or (items.itemsList["HXG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("HXG", enemy, myHero)) or 0 )
	returnDamage.BWC = (( (items.itemsList["BWC"].ready or (items.itemsList["BWC"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("BWC", enemy, myHero)) or 0 )
	returnDamage.LIANDRYS = (( items.passiveItemsList["LIANDRYS"].slot and getDmg("LIANDRYS", enemy, myHero)) or 0)
	returnDamage.BLACKFIRE = (( items.passiveItemsList["BLACKFIRE"].slot and getDmg("BLACKFIRE", enemy, myHero)) or 0)
	returnDamage.ignite = (( igniteSlot and (myHero:CanUseSpell(igniteSlot) == READY or not readyCheck) and (GetDistance(enemy) < igniteRange or not checkRange) and getDmg("IGNITE", enemy, myHero)) or 0)

	returnDamage.onSpell = (returnDamage.LIANDRYS + returnDamage.BLACKFIRE) 
	returnDamage.Q = (returnDamage.Qbase + returnDamage.onSpell)
	returnDamage.W = (returnDamage.Wbase + returnDamage.onSpell)
	returnDamage.E = (returnDamage.Ebase + returnDamage.onSpell)
	returnDamage.R = (returnDamage.Rbase + returnDamage.onSpell)
	returnDamage.QWE = returnDamage.Q + returnDamage.W + returnDamage.E
	returnDamage.QWER = returnDamage.QWE + returnDamage.R
	returnDamage.items = (returnDamage.DFG + returnDamage.HXG + returnDamage.BWC)

	returnDamage.total = ((returnDamage.DFG > 0 and 1.2 * returnDamage.QWER or returnDamage.QWER) + returnDamage.items + returnDamage.ignite)

	returnDamage.charName = enemy.charName
	return returnDamage
end

function damageText()
	local damageTextList = {"Poor Enemy", "Ultimate!", "Nuke!", "Risky", "Weakling, u no can touch him!"}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if updateTextTimers[enemy.charName] == nil then
				updateTextTimers[enemy.charName] = 30
			elseif updateTextTimers[enemy.charName] > 1 then
				updateTextTimers[enemy.charName] = updateTextTimers[enemy.charName] - 1
			elseif updateTextTimers[enemy.charName] == 1 then			
				local calcDmg = calculateDamage(enemy, false, true)
				local killMode = (calcDmg.QWE > enemy.health and 1) or (calcDmg.R > enemy.health and 2) or (calcDmg.QWER > enemy.health and 3) or (calcDmg.total > enemy.health and 4) or 5
				if killMode > 0 then PrintFloatText(enemy, 0, damageTextList[killMode]) end
				updateTextTimers[enemy.charName] = 30
			end
		end
	end
end

--[[ Garbage Bin ]]--

function updateItems()
	for item, itemInfo in pairs(items.itemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)		
		itemInfo.ready = (itemInfo.slot and myHero:CanUseSpell(itemInfo.slot) == READY or false)
	end
	for item, itemInfo in pairs(items.passiveItemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)
	end
end