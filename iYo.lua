--[[ iYo by Apple ]]--

if myHero.charName ~= "Yorick" then return end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")
local HK4 = string.byte("X")

--[[ Constants ]]--

local AARange = myHero.range
local WRange, WSpeed, WDelay, WRadius = 600, math.huge, 0.250, 100
local ERange = 550
local RRange = 850
local igniteRange = 600

local AABase = 0.908333333

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP_PRIORITY,WRange,DAMAGE_PHYSICAL,false)
local tpW = TargetPredictionVIP(WRange, WSpeed, WDelay, WRadius*2)

local igniteSlot
local ultClone

local lastAA = 0
local AADelay = 0

local enemyMinions = {}
local updateTextTimers = {}

--[[ Predefined Tables ]]--

--[[ Core Callbacks ]]--

function OnLoad()
	iYoConfig = scriptConfig("iYo - Main","iYo")
	iYoConfigUltimate = scriptConfig("iYo - Ultimate", "iYoUlt")

	iYoConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iYoConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)

	iYoConfig:addParam("minionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	iYoConfig:addParam("orbWalk", "Orb Walking", SCRIPT_PARAM_ONOFF, false)

	iYoConfig:permaShow("pewpew")
	iYoConfig:permaShow("autoFarm")

	ts.name = "Yorick"
	iYoConfig:addTS(ts)

	iYoConfigUltimate:addParam("autoUlt", "Auto Ultimate", SCRIPT_PARAM_ONOFF, true)
	for _, ally in ipairs(GetAllyHeroes()) do
		iYoConfigUltimate:addParam(ally.charName, ally.charName, SCRIPT_PARAM_ONOFF, true)
	end

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, RRange, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts:update()
	--updateItems()
	AARange = myHero.range + GetDistance(myHero.minBBox)
	AADelay = (1000/(0.625*myHero.attackSpeed) + GetLatency())
	if ultClone and not ultClone.valid then ultClone = nil end

	if not myHero.dead then
		autoIgnite()
		if iYoConfig.pewpew then PewPew()
		elseif iYoConfig.autoFarm then autoFarm() end
		if iYoConfig.harass then Poke() end
		if iYoConfigUltimate.autoUlt then autoUlt() end
	end
end

function OnDraw()
	if myHero.dead then return end
	if myHero:CanUseSpell(_W) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0x80408000) end
	if myHero:CanUseSpell(_E) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0x80408000) end
	if myHero:CanUseSpell(_R) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0x80408000) end
	if ValidTarget(ts.target) then for i = 1, 10 do DrawCircle(ts.target.x, ts.target.y, ts.target.z, 90+i, 0xFFFF0000) end end

	if iYoConfig.minionMarker then
		if not iYoConfig.autoFarm then enemyMinions:update() end
		--local ADHigher = (myHero.totalDamage > (myHero.ap+25+35*myHero:GetSpellData(_W).level))
		for _, minion in ipairs(enemyMinions.objects) do
			if ValidTarget(minion) then
				if minion.health < getDmg("AD", minion, myHero) then
					for i = 1, 10 do DrawCircle(minion.x, minion.y, minion.z, 50+i, 0xFF80FF00) end
				elseif minion.health < getDmg("W", minion, myHero) then
					for i = 1, 10 do DrawCircle(minion.x, minion.y, minion.z, 50+i, 0xFFFF0000) end
				end
			end
		end
	end
end

function OnProcessSpell(unit, spell)
	if unit.isMe and spell.name:lower():find("attack") then
		lastAA = GetTickCount()
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target) then MuramanaOff() if iYoConfig.orbWalk then myHero:MoveTo(mousePos.x, mousePos.z) end return end
	MuramanaOn()
	if myHero:CanUseSpell(_E) == READY then CastSpell(_E, ts.target) end
	if myHero:CanUseSpell(_W) == READY then
		local _,_,WPos = tpW:GetPrediction(ts.target)
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
	if iYoConfig.orbWalk then
		if GetDistance(ts.target) < AARange then
			if GetTickCount() - lastAA > AADelay / 2 and GetTickCount() < lastAA + AADelay then
				if myHero:CanUseSpell(_Q) == READY then
					CastSpell(_Q)
					myHero:Attack(ts.target)
				else
					myHero:MoveTo(mousePos.x, mousePos.z)
				end
			elseif GetTickCount() - lastAA > AADelay then
				myHero:Attack(ts.target)
			end
		else
			myHero:MoveTo(mousePos.x, mousePos.z)
		end
	elseif myHero:CanUseSpell(_Q) == READY and GetDistance(ts.target) < AARange and GetTickCount() - lastAA > AADelay / 2 and GetTickCount() < lastAA + AADelay then
		CastSpell(_Q)
	end
end

function Poke()
	if not ValidTarget(ts.target) then return end
	if myHero:CanUseSpell(_E) == READY then CastSpell(_E, ts.target) end
	if myHero:CanUseSpell(_W) == READY then
		local _,_,WPos = tpW:GetPrediction(ts.target)
		if WPos then
			CastSpell(_W, WPos.x, WPos.z)
		end
	end
end

function autoUlt()
	if not myHero:CanUseSpell(_R) == READY then return end
	local ultTarget
	for _, ally in ipairs(GetAllyHeroes()) do
		if iYoConfigUltimate[ally.charName] and ally.health / ally.maxHealth < 0.2 and GetDistance(ally) <= RRange and CountEnemies(1000, ally) > 0 then
			if not ultTarget or ultTarget.health > ally.health then
				ultTarget = ally
			end
		end
	end
	if ultTarget then CastSpell(_R, ultTarget) end
end

function autoFarm()
	enemyMinions:update()
	local ADMinions, WMinions = {}, {}
	for _, minion in ipairs(enemyMinions.objects) do
		if ValidTarget(minion) then
			if minion.health < getDmg("AD", minion, myHero) then ADMinions[#ADMinions+1] = minion end
			if minion.health < getDmg("W", minion, myHero) then WMinions[#WMinions+1] = minion end
		end
	end
	if myHero:CanUseSpell(_W) == READY and #WMinions > 2 then
		local spellPos, minionsInRange = MEC(WMinions):Compute().center, 0
		for _, minion in ipairs(WMinions) do
			if GetDistance(minion, spellPos) < WRadius then
				minionsInRange = minionsInRange + 1
				if minionsInRange > 2 then
					CastSpell(_W, spellPos.x, spellPos.z)
					return
				end
			end
		end
	end
	for _, minion in ipairs(ADMinions) do
		if ValidTarget(minion, AARange*2) then
			myHero:Attack(minion)
			return
		end
	end
end

function autoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) == READY then
		for _, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, igniteRange) and enemy.health < getDmg("IGNITE", enemy, myHero) then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

--[[ Garbage Bin ]]--

function CountEnemies(range, unit)
    local Enemies = 0
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) and GetDistance(enemy, unit) < (range or math.huge) then
            Enemies = Enemies + 1
        end
    end
    return Enemies
end