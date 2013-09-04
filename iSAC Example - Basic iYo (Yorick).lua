--[[ iYo by Apple ]]--

if myHero.charName ~= "Yorick" then return end

require "iSAC"

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")

--[[ Constants ]]--

local AARange = myHero.range

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 600, DAMAGE_PHYSICAL, true)
local iOW = iOrbWalker(AARange)
local QSpell = iCaster(_Q, math.huge, SPELL_SELF)
local WSpell = iCaster(_W, 600, SPELL_CIRCLE, math.huge, 0.250, 200)
local ESpell = iCaster(_E, 550, SPELL_TARGETED)
local RSpell = iCaster(_R, 850, SPELL_TARGETED_FRIENDLY)
local iSum = iSummoners()
--local iMinions = iMinions(1000, iOW)

--[[ Core Callbacks ]]--

function OnLoad()
	iYoConfig = scriptConfig("iYo - Main","iYo")
	iYoConfigUltimate = scriptConfig("iYo - Ultimate", "iYoUlt")
	iYoConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iYoConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
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

	iOW:addAA("attack")
	iOW:addReset(QSpell.spellData.name)
end

function OnTick()
	ts.range = WSpell.range
	ts:update()
	iSum:AutoAll()
	AARange = myHero.range + GetDistance(myHero.minBBox)
	iOW.AARange = AARange

	if not myHero.dead then
		if iYoConfig.pewpew then
			PewPew()
		elseif not ValidTarget(ts.target) then
			MuramanaOff()
		end
		if iYoConfig.harass then Poke() end
		if iYoConfigUltimate.autoUlt then autoUlt() end
		--if iYoConfig.autoFarm then iMinions:LastHit(AARange, mousePos, iOW) end
	end
end

function OnDraw()
	if myHero.dead then return end
	if WSpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, WSpell.range, 0x80408000) end
	if ESpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, ESpell.range, 0x80408000) end
	if RSpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, RSpell.range, 0x80408000) end
	if ValidTarget(ts.target) then for i = 1, 10 do DrawCircle(ts.target.x, ts.target.y, ts.target.z, 90+i, 0xFFFF0000) end end
	--if iYoConfig.minionMarker then iMinions:Marker(50, 0x80408000, 5)end
	if iYoConfig.minionMarker then
		for _, minion in ipairs(getEnemyMinions()) do
			if ValidTarget(minion, AARange) then
				if getDmg("AD", minion, myHero) > minion.health then
					for i = 1, 5 do DrawCircle(minion.x, minion.y, minion.z, 50+i, 0xFFFF0000) end
				end
			end
		end
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if ValidTarget(ts.target) then MuramanaOn() else MuramanaOff() end
	ESpell:Cast(ts.target)
	if ESpell:Data().mana + WSpell:Data().mana < myHero.mana then WSpell:Cast(ts.target) end

	-- Melee Part
	ts.range = AARange
	ts:update()
	if ValidTarget(ts.target) then QSpell:AACast(iOW) end
	if iYoConfig.orbWalk then iOW:Orbwalk(mousePos, ts.target) end
end

function Poke()
	ESpell:Cast(ts.target)
	WSpell:Cast(ts.target)
end

function autoUlt()
	if RSpell:Ready() then
		local ultTarget
		if myHero.health / myHero.maxHealth < 0.2 and CountEnemies(1000, myHero) > 0 then
			ultTarget = myHero
		end
		for _, ally in ipairs(GetAllyHeroes()) do
			if iYoConfigUltimate[ally.charName] and ally.health / ally.maxHealth < 0.2 and GetDistance(ally) <= RSpell.range and CountEnemies(1000, ally) > 0 then
				if not ultTarget or ultTarget.health > ally.health then
					ultTarget = ally
				end
			end
		end
		if ultTarget then RSpell:Cast(ultTarget) end
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
