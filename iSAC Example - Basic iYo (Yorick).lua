--[[ iSAC Example - Basic iYo (Yorick) ]]--

if myHero.charName ~= "Yorick" then return end

require "iSAC"

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")

--[[ Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP_PRIORITY, WRange, DAMAGE_PHYSICAL, true)
local Orbwalker = iOrbWalker(AARange)
local QSpell = iCaster(_Q, math.huge, SPELL_SELF)
local WSpell = iCaster(_W, 600, SPELL_CIRCLE, math.huge, 0.250, 200)
local ESpell = iCaster(_E, 550, SPELL_TARGETED)
local RSpell = iCaster(_R, 850, SPELL_TARGETED_FRIENDLY)
local Summoners = iSummoners()
local Minions = iMinions(1000)

--[[ Core ]]--

function OnLoad()
	iYoConfig = scriptConfig("iSAC Example - Basic iYo","iYo")

	iYoConfig:addParam("pewpew", "PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iYoConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iYoConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK3)

	iYoConfig:addParam("minionMarker", "Minion Marker", SCRIPT_PARAM_ONOFF, true)
	iYoConfig:addParam("orbWalk", "Orb Walking", SCRIPT_PARAM_ONOFF, false)

	iYoConfig:permaShow("pewpew")
	iYoConfig:permaShow("harass")
	iYoConfig:permaShow("autoFarm")

	ts.name = "Yorick"
	iYoConfig:addTS(ts)

	Orbwalker:addAA()
	Orbwalker:addReset(QSpell.spellData.name)
end

function OnTick()
	AARange = myHero.range + GetDistance(myHero.minBBox)
	Orbwalker.AARange = AARange
	Summoners:AutoAll()
	Minions:update()

	ts.range = WSpell.range
	ts:update()
	if ValidTarget(ts.target) then MuramanaOn() else MuramanaOff() end

	if not myHero.dead then
		if iYoConfig.pewpew then PewPew() end
		if iYoConfig.harass then Poke() end
		if iYoConfig.autoFarm then iMinions:LastHit(AARange) end
	end
end

function OnDraw()
	if not myHero.dead then
		if WSpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, WSpell.range, 0x80408000) end
		if ESpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, ESpell.range, 0x80408000) end
		if RSpell:Ready() then DrawCircle(myHero.x, myHero.y, myHero.z, RSpell.range, 0x80408000) end
		if ValidTarget(ts.target) then for i = 1, 10 do DrawCircle(ts.target.x, ts.target.y, ts.target.z, 90+i, 0xFFFF0000) end end
		if iYoConfig.minionMarker then iMinions:marker(50, 0x80408000, 5) end
	end
end

function OnProcessSpell(unit, spell)
	Orbwalker:OnProcessSpell(unit, spell)
end

--[[ Combat ]]--

function PewPew()
	ESpell:Cast(ts.target)
	WSpell:Cast(ts.target)

	-- Melee Part
	ts.range = AARange
	ts:update()
	QSpell:AACast(Orbwalker)
	if iYoConfig.orbWalk then Orbwalker:Orbwalk(mousePos, ts.target) end
end

function Poke()
	ESpell:Cast(ts.target)
	WSpell:Cast(ts.target)
end