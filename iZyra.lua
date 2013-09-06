--[[ iZyra by Apple ]]--

if myHero.charName ~= "Zyra" then return end

require "2DGeometry"

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")
local HK4 = string.byte("X")
local minHitChance = 0.3

--[[ Constants ]]--

local QRange, QSpeed, QDelay, QRadius = 825, math.huge, 0.500, 85
local WRange, WSpeed, WDelay, WRadius = 825, math.huge, 0.2432, 10
local ERange, ESpeed, EDelay, EWidth = 1100, 1150, 0.250, 140
local RRange, RSpeed, RDelay, RRadius = 700, math.huge, 0.500, 500
local PRange, PSpeed, PDelay, PWidth = 1400, 1850, 0.500, 50

local igniteRange = 600

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST,QRange,DAMAGE_MAGIC,false)
local tpQ = TargetPredictionVIP(QRange, QSpeed, QDelay, QRadius*2)
local tpE = TargetPredictionVIP(ERange, ESpeed, EDelay, EWidth)
local tpR = TargetPredictionVIP(RRange, RSpeed, RDelay, RRadius*2)
local tpP = TargetPredictionVIP(PRange, PSpeed, PDelay, PWidth)

local igniteSlot

local lastE = 0

local updateTextTimers = {}
local enemyMinions = {}

--[[ Predefined Tables ]]--

--[[ Core Callbacks ]]--

function OnLoad()
	iZyraConfig = scriptConfig("iZyra", "iZyra")

	iZyraConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iZyraConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iZyraConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)

	iZyraConfig:addParam("ultOnFive", "Ult Enemy Team", SCRIPT_PARAM_ONOFF, true)
	iZyraConfig:addParam("minionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	iZyraConfig:addParam("autoPassive", "Auto Passive", SCRIPT_PARAM_ONOFF, true)

	iZyraConfig:permaShow("pewpew")
	iZyraConfig:permaShow("harass")
	iZyraConfig:permaShow("autoFarm")

	ts.name = "Zyra"
	iZyraConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts:update()
	updateItems()
	if myHero:GetSpellData(_Q).name == myHero:GetSpellData(_W).name then
		if myHero:CanUseSpell(_Q) == READY and iZyraConfig.autoPassive then
			autoPassive()
		end
	elseif not myHero.dead then
		autoIgnite()
		if iZyraConfig.pewpew then PewPew() end
		if iZyraConfig.harass then Poke() end
		if iZyraConfig.autoFarm then autoFarm() end
	end
end

function OnDraw()
	if not myHero.dead then
		if myHero:CanUseSpell(_Q) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0x8080FF00) end
		if myHero:CanUseSpell(_E) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x8080FF00) end

		if iZyraConfig.minionMarker then
			if not iZyraConfig.autoFarm then enemyMinions:update() end
			for _, minion in ipairs(enemyMinions.objects) do
				if ValidTarget(minion) and getDmg("Q", minion, myHero) > minion.health then
					for i = 1, 5 do
						DrawCircle(minion.x, minion.y, minion.z, 50+i, (getDmg("AD", minion, myHero) * 1.1 > minion.health and 0x8080FF00 or 0xFFFF0000))
					end
				end
			end
		end
	end
end

function OnCreateObj(object)

end

function OnDeleteObj(object)

end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name == myHero:GetSpellData(_E).name then
		if spell.endPos then
			if ValidTarget(ts.target) then
				local EPos,_,_ = tpE:GetPrediction(ts.target)
				if EPos then
					local intersection = LineSegment(Point(myHero.x, myHero.z), Point(spell.endPos.x, spell.endPos.z)):intersectionPoints(LineSegment(Point(ts.target.x, ts.target.z), Point(EPos.x, EPos.z)))[1]
					if intersection and GetDistance(intersection) < QRange then
						if myHero:CanUseSpell(_Q) == READY then
							CastSpell(_Q, intersection.x, intersection.y)
						end
						if myHero:CanUseSpell(_W) == READY then
							CastSpell(_W, intersection.x, intersection.y)
							CastSpell(_W, intersection.x, intersection.y)
						end
					elseif myHero:CanUseSpell(_W) == READY then
						Packet("S_CAST", {spellId = _W, fromX = spell.endPos.x, fromY = spell.endPos.z, toX = spell.endPos.x, toY = spell.endPos.z}):send()
						Packet("S_CAST", {spellId = _W, fromX = spell.endPos.x, fromY = spell.endPos.z, toX = spell.endPos.x, toY = spell.endPos.z}):send()
						--CastSpell(_W, spell.endPos.x, spell.endPos.z)
						--CastSpell(_W, spell.endPos.x, spell.endPos.z)
					end
				end
			end
		end
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target) then return end
	if myHero:CanUseSpell(_E) == READY then
		local EPos = GetEPrediction(ts.target)
		if EPos then
			CastSpell(_E, EPos.x, EPos.z)
			Packet("S_CAST", {spellId = _W, fromX = EPos.x, fromY = EPos.z, toX = EPos.x, toY = EPos.z}):send()
		end
	end
	if myHero:CanUseSpell(_Q) == READY then
		if not ts.target.canMove then
			CastSpell(_Q, ts.target.x, ts.target.z)
		elseif (myHero:CanUseSpell(_E) == COOLDOWN and (myHero:GetSpellData(_E).cd - myHero:GetSpellData(_E).currentCd > 1.5)) or myHero:CanUseSpell(_E) == NOTLEARNED then
			local QPos = GetQPrediction(ts.target)
			if QPos then
				CastSpell(_Q, QPos.x, QPos.z)
			end
		end
	end
	if myHero:CanUseSpell(_Q) ~= READY and myHero:CanUseSpell(_E) ~= READY and myHero:CanUseSpell(_R) == READY then
		--finishUlt()
	end
	if iZyraConfig.ultOnFive and myHero:CanUseSpell(_R) == READY then
		ultOnFive()
	end
end

function Poke()
	if not ValidTarget(ts.target) then return end
	if myHero:CanUseSpell(_Q) == READY then
		local QPos = GetQPrediction(ts.target)
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	end
end

function autoFarm()
	enemyMinions:update()
	for _, minion in ipairs(enemyMinions.objects) do
		if ValidTarget(minion) then
			if getDmg("AD", minion, myHero) * 1.1 > minion.health then
				myHero:Attack(minion)
			elseif getDmg("Q", minion, myHero) > minion.health then
				CastSpell(_Q, minion.x, minion.z)
			end
		end
	end
end

function autoPassive()
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, PRange) and getDmg("P", enemy, myHero) > enemy.health then
			local PPos = GetPPrediction(enemy)
			if PPos then
				CastSpell(_Q, PPos.x, PPos.z)
				return
			end
		end
	end
	if ValidTarget(ts.target, PRange) then
		local PPos = GetPPrediction(ts.target)
		if PPos then
			CastSpell(_Q, PPos.x, PPos.z)
		end
	end
end

function ultOnFive()
	local ultEnemies = GetEnemyHeroes()
	for i, enemy in ipairs(ultEnemies) do
		if not ValidTarget(enemy, (RRadius + RRange)) then return end
	end
	local ultPos = GetMEC(RRadius, RRange)
	for _, enemy in ipairs(ultEnemies) do
		if GetDistance(ultPos.point or ultPos.center, enemy) < RRange then return end
	end
	CastSpell(_R, ultPos.center.x, ultPos.center.z)
end

function finishUlt()
	local killableEnemies, killableArray = {}, {}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if getDmg("R", enemy, myHero) > enemy.health then
			killableEnemies[#killableEnemies+1] = enemy
			killableArray[i] = true
		else
			killableArray[i] = false
		end
	end
	local ultPosKillable, killPosCount = MEC(killableEnemies):Compute(), 0
	local ultPosEnemies, enemiesPosCount, enemiesKillPosCount = MEC(GetEnemyHeroes()):Compute(), 0, 0
	if ultPosKillable and ultPosEnemies then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if GetDistance(ultPosKillable.point or ultPosKillable.center, enemy) < RRange then killPosCount = killPosCount + 1 end
			if GetDistance(ultPosEnemies.point or ultPosEnemies.center, enemy) < RRange then enemiesPosCount = enemiesPosCount + 1 if killableArray[i] then enemiesKillPosCount = enemiesKillPosCount + 1 end end
		end
		if enemiesKillPosCount >= killPosCount and enemiesKillPosCount > 0 then
			CastSpell(_R, ultPosEnemies.x, ultPosEnemies.z)
		elseif killPosCount > 0 and killPosCount > enemiesKillPosCount then
			CastSpell(_R, ultPosKillable.x, ultPosKillable.z)
		elseif enemiesKillPosCount > 0 and enemiesPosCount > enemiesKillPosCount then
			CastSpell(_R, ultPosEnemies.x, ultPosEnemies.z)
		end
	end
end

function autoIgnite()
	if not igniteSlot or  myHero:CanUseSpell(igniteSlot) ~= READY then return end
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy, igniteRange) and enemy.health < getDmg("IGNITE", enemy, myHero) then
			CastSpell(igniteSlot, enemy)
		end
	end
end

--[[ Predictions and Calculations ]]--

function GetQPrediction(enemy)
	if not ValidTarget(enemy) or (minHitChance > 0 and tpQ:GetHitChance(enemy) < minHitChance) then return end
	local _,_,QPos = tpQ:GetPrediction(enemy)
	return QPos
end

function GetEPrediction(enemy)
	if not ValidTarget(enemy) or (minHitChance > 0 and tpE:GetHitChance(enemy) < minHitChance) then return end
	local _,_,EPos = tpE:GetPrediction(enemy)
	return EPos
end

function GetPPrediction(enemy)
	if not ValidTarget(enemy) or (minHitChance > 0 and tpP:GetHitChance(enemy) < minHitChance) then return end
	local PPos,_ = tpP:GetPrediction(enemy)
	return PPos
end


--[[ Garbage Bin ]]--

function updateItems()

end

--function LazyDrawCircle(unit, radius, colour)
--	DrawCircle(unit.x, unit.y, unit.z, radius, colour)
--end