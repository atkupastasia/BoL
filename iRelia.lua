--[[ iRelia - Based on GRB's Irelia Power ]]--

if myHero.charName ~= "Irelia" then return end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")

local minHitChance = 0.3
local onlyQOutOfAARange = true

--[[ Constants ]]--

local QRange = 650
local WRange = 125
local ERange = 325

local RRange = 1200
local RSpeed = 750
local RDelay = 0

local AARange = myHero.range + GetDistance(myHero.minBBox)
local igniteRange = 600

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP_PRIORITY, QRange, DAMAGE_PHYSICAL, false)
local tpR = TargetPredictionVIP(RRange, RSpeed, RDelay)

local enemyMinions = {}
local updateTextTimers = {}
local igniteSlot = nil

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
	iReliaConfig = scriptConfig("iRelia", "iRelia")

	iReliaConfig:addParam("pewpew", "PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iReliaConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYTOGGLE, false, HK3)
	iReliaConfig:addParam("autoKS", "Auto KS with Q", SCRIPT_PARAM_ONOFF, true)

	iReliaConfig:permaShow("pewpew")
	iReliaConfig:permaShow("autoFarm")
	
	ts.name = "Irelia"
	iReliaConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, QRange, player, MINION_SORT_HEALTH_ASC)	
end

function OnTick()
	ts:update()
	enemyMinions:update()

	if not myHero.dead then
		autoIgnite()
		if iReliaConfig.autoKS then autoKS() end
		if iReliaConfig.pewpew then PewPew()
		elseif iReliaConfig.autoFarm then autoFarm() end
	end
end

function OnDraw()
	if not myHero.dead then
		if myHero:CanUseSpell(_Q) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x8080FF00) end
		if myHero:CanUseSpell(_E) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x8080FF00) end
		if myHero:CanUseSpell(_R) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0x8080FF00) end

		if ValidTarget(ts.target) then
			DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0xFFFF0000)
		end

		damageText()
	end
end

function OnProcessSpell(unit, spell)
	if unit.name == myHero.name and string.lower(spell.name):find("attack") then
		lastAA = GetTickCount()
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target) then return end
	local RPos = myHero:CanUseSpell(_R) == READY and GetRPrediction(ts.target) or nil
	local calcDmg = calculateDamage(ts.target, true, true)
	if TargetHaveBuff("ireliatranscendentbladesspell", myHero) and RPos then
		CastSpell(_R, RPos.x, RPos.z)
	end
	if calcDmg.Q > ts.target.health and myHero:CanUseSpell(_Q) == READY then
		CastSpell(_Q, ts.target)
	elseif (calcDmg.Q + calcDmg.E) > ts.target.health and myHero:CanUseSpell(_Q) == READY and myHero:CanUseSpell(_E) == READY then
		CastSpell(_Q, ts.target)
		CastSpell(_E, ts.target)
	elseif (calcDmg.R) > ts.target.health and RPos then
		CastSpell(_R, RPos.x, RPos.z)
	elseif (calcDmg.Q + calcDmg.E + calcDmg.ignite) > ts.target.health and igniteSlot and myHero:CanUseSpell(_Q) == READY and myHero:CanUseSpell(_E) == READY then
		CastSpell(_Q, ts.target)
		CastSpell(_E, ts.target)
		CastSpell(igniteSlot, ts.target)
	elseif (calcDmg.QWER) > ts.target.health and myHero:CanUseSpell(_Q) == READY and myHero:CanUseSpell(_E) == READY and RPos then
		CastSpell(_Q, ts.target)
		CastSpell(_E, ts.target)
		CastSpell(igniteSlot, ts.target)
		CastSpell(_R, RPos.x, RPos.z)
	else
		if myHero:CanUseSpell(_Q) == READY and (not onlyQOutOfAARange or GetDistance(ts.target) > AARange) then CastSpell(_Q, ts.target) end
		if myHero:CanUseSpell(_E) == READY and (ts.target.canMove or myHero.health > ts.target.health) then CastSpell(_E, ts.target) end
	end
	if GetDistance(ts.target) < AARange + 50 then CastSpell(_W) end
end

function autoKS()
	if myHero:CanUseSpell(_Q) ~= READY then return end
	for i = 1, heroManager.iCount do
		local enemy = heroManager:getHero(i)
		if ValidTarget(enemy, QRange) then
			if getDmg("Q", enemy, myHero) > enemy.health then
				CastSpell(_Q, enemy)
			end
		end
	end
end

function autoFarm()
	for _, minion in pairs(enemyMinions.objects) do
		if ValidTarget(minion, AARange) and getDmg("AD", minion, myHero) > minion.health and GetTickCount() - lastAA > ((625-0.665*375)/(myHero.attackSpeed*0.665*0.665)) then
			myHero:Attack(minion)
			return
		elseif myHero:CanUseSpell(_Q) == READY and ValidTarget(minion, QRange) and getDmg("Q", minion, myHero) > minion.health then
			CastSpell(_Q, minion)
			return
		end
	end
end

function autoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			local igniteDmg = getDmg("IGNITE", enemy, myHero)
			if ValidTarget(enemy, igniteRange) and enemy.health < igniteDmg then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

--[[ Predictions and Calculations ]]--

function GetRPrediction(enemy)
	if minHitChance ~= 0 and tpR:GetHitChance(enemy) < minHitChance then return nil end
	local RPos,_,_ = tpR:GetPrediction(enemy)
	return RPos
end

function calculateDamage(enemy, checkRange, readyCheck)
	local returnDamage = {}
	returnDamage.Qbase = (( (myHero:CanUseSpell(_Q) == READY or not readyCheck) and (GetDistance(enemy) < QRange or not checkRange) and getDmg("Q", enemy, myHero)) or 0 )
	--returnDamage.Wbase = (( (myHero:CanUseSpell(_W) == READY or not readyCheck) and (GetDistance(enemy) < WRange or not checkRange) and getDmg("W", enemy, myHero)) or 0 )
	returnDamage.Ebase = (( (myHero:CanUseSpell(_E) == READY or not readyCheck) and (GetDistance(enemy) < ERange or not checkRange) and getDmg("E", enemy, myHero)) or 0 )
	returnDamage.Rbase = (( (myHero:CanUseSpell(_R) == READY or not readyCheck) and (GetDistance(enemy) < RRange or not checkRange) and getDmg("R", enemy, myHero)) or 0 )
	returnDamage.DFG = (( (items.itemsList["DFG"].ready or (items.itemsList["DFG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("DFG", enemy, myHero)) or 0 )
	returnDamage.HXG = (( (items.itemsList["HXG"].ready or (items.itemsList["HXG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("HXG", enemy, myHero)) or 0 )
	returnDamage.BWC = (( (items.itemsList["BWC"].ready or (items.itemsList["BWC"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("BWC", enemy, myHero)) or 0 )
	returnDamage.LIANDRYS = (( items.passiveItemsList["LIANDRYS"].slot and getDmg("LIANDRYS", enemy, myHero)) or 0)
	returnDamage.BLACKFIRE = (( items.passiveItemsList["BLACKFIRE"].slot and getDmg("BLACKFIRE", enemy, myHero)) or 0)
	returnDamage.ignite = (( igniteSlot and (myHero:CanUseSpell(igniteSlot) == READY or not readyCheck) and (GetDistance(enemy) < igniteRange or not checkRange) and getDmg("IGNITE", enemy, myHero)) or 0)
	returnDamage.AD = (GetDistance(enemy) < AARange + 50 or not checkRange) and getDmg("AD", enemy, myHero) or 0

	returnDamage.onSpell = (returnDamage.LIANDRYS + returnDamage.BLACKFIRE)
	returnDamage.Q = (returnDamage.Qbase + returnDamage.onSpell)
	returnDamage.W = 0 --(returnDamage.Wbase + returnDamage.onSpell)
	returnDamage.E = (returnDamage.Ebase + returnDamage.onSpell)
	returnDamage.R = (returnDamage.Rbase + returnDamage.onSpell) * 4
	returnDamage.QWE = returnDamage.Q + returnDamage.W + returnDamage.E
	returnDamage.QWER = returnDamage.QWE + returnDamage.R
	returnDamage.items = (returnDamage.DFG + returnDamage.HXG + returnDamage.BWC)

	returnDamage.total = ((returnDamage.DFG > 0 and 1.2 * returnDamage.QWER or returnDamage.QWER) + returnDamage.AD + returnDamage.items + returnDamage.ignite)

	return returnDamage
end

function damageText()
	local damageTextList = {"Poor Enemy", "Ultimate!", "Nuke!", "Risky", "Derp..."}
	for _, enemy in ipairs(GetEnemyHeroes()) do
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
			if myHero:CanUseSpell(_E) == READY and enemy.health > myHero.health then
				for i = 0, 5 do
					DrawCircle(enemy.x, enemy.y, enemy.z, 50+i, 0x8080FF00)
				end
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