-- ################################################################################################# --
-- ##                                                                                             ## --
-- ##                    iGlory Ryze Script                                                       ## --
-- ##                                Version 3.8 final                                            ## --
-- ##                                         based of Ultimate Ryze by bnsfg                     ## --
-- ##                                                                                             ## --
-- ##                            Completely Rewritten by Wursti                                   ## --
-- ##                                                                                             ## --
-- ##                                 Modified by Apple                                           ## --
-- ##                                                                                             ## --
-- ################################################################################################# --
 --
-- ################################################################################################# --
-- ##                                                                                             ## --
-- ##    Sorry, Wursti, but I just HAD to clean up your code. My brain started hurting after      ## --
-- ##    trying to read your stuff. Don't hate me. T_T                                            ## --
-- ##                                                                                             ## --
-- ##    I have removed a shitload of the options, because I personally found many of them        ## --
-- ##    unnecessary. Cleaned up a major part of the code. Oh, did you know that many of these    ## -- 
-- ##    functions can be found in AllClass? Oh, and I added in iSAC functions to test them. :P   ## --
-- ##                                                                                             ## --
-- ##          - Apple                                                                            ## --
-- ##                                                                                             ## --
-- ################################################################################################# --

if GetMyHero().charName ~= "Ryze" then return end

require "iSAC"

--[[ Config ]]--

RyzeConfigConfig = {
	BurstActiveshow = true,
	LongActiveshow = true,
	useUltishow = true,
	cageWshow = true,
	CageHuntershow = true,
	winstashow = true,
	autoQFarmshow = true,
	PowerFarmshow = true,
	autoAAFarmshow = true,
	autoQToggleshow = true,
	autoQHarassshow = true,
	ComboSwitchshow = true,
	drawcircles = true,
}

local floattext = {"Cooldown!","Murder him!"}
local levelSequence = {nil,0,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3} -- Delete this line to disable leveling your shit.

local quotes = {
	'Let\'s go, let\'s go!',
	'Unpleasant? I\'ll show you unpleasant!',
	'Take this scroll and stick it... somewhere safe.',
	'I got these tattoos in rune prison!',
	'Right back at you!'
}

--[[ Constants ]]--

local QRange = 650
local WRange = 625
local ERange = 675
local RRange = 200
local JunglERange = 1000
local turretRange = 950

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LOW_HP, QRange, DAMAGE_MAGIC, false)

local waittxt = {}
local killable = {}

local qcasted = true

local calculationenemy = 1
local lastTick = 0
local waitDelay = 400
local nextTick = 0
local nextQuote = 0

--[[ Tables ]]--

local jungleCamps = {
	["TT_Spiderboss7.1.1"] = {object = nil},
	["Worm12.1.1"] = {object = nil},
	["Dragon6.1.1"] = {object = nil},
	["AncientGolem1.1.1"] = {object = nil},
	["AncientGolem7.1.1"] =  {object = nil},
	["LizardElder4.1.1"] =  {object = nil},
	["LizardElder10.1.1"] = {object = nil},
	["GiantWolf2.1.3"] = {object = nil},
	["GiantWolf8.1.3"] = {object = nil},
	["Wraith3.1.3"] = {object = nil},
	["Wraith9.1.3"] = {object = nil},
	["Golem5.1.2"] = {object = nil},
	["Golem11.1.2"] = {object = nil},
}

--[[ iSAC Variables ]]--

local iSum = iSummoners()
local Items = iTems()
local iOW = iOrbWalker(myHero.range + GetDistance(myHero.minBBox))

--[[ Core Callbacks ]]--

function OnLoad()
	RyzeConfig = scriptConfig("Ryze Combo", "Ryze_Config")
	RyzeSettings = scriptConfig("Ryze Combo Settings", "Ryze_Settings")

	RyzeConfig:addParam("BurstActive", "Burst Combo", SCRIPT_PARAM_ONKEYDOWN, false, 65)
	RyzeConfig:addParam("LongActive", "Long Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	RyzeConfig:addParam("JungleActive", "Jungle Creeps Combo", SCRIPT_PARAM_ONKEYDOWN, false, 66)
	RyzeConfig:addParam("useUlti", "Use ultimate in combos", SCRIPT_PARAM_ONOFF, true)
	RyzeConfig:addParam("useMura", "Auto Muramana", SCRIPT_PARAM_ONOFF, true)
	RyzeConfig:addParam("PowerFarm", "Power Farm", SCRIPT_PARAM_ONKEYTOGGLE, false, 73)
	RyzeConfig:addParam("Orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	RyzeConfig:addParam("Quotes", "Show Cheesy Ryze Quotes", SCRIPT_PARAM_ONOFF, true)

	RyzeSettings:addParam("minMuraMana", "Min Mana Muramana", SCRIPT_PARAM_SLICE, 25, 0, 100, 2)
	RyzeSettings:addParam("PowerMinMana", "Power Farm min mana %", SCRIPT_PARAM_SLICE, 50, 0, 100, 2)
	RyzeSettings:addParam("whunt", "First cage with W range", SCRIPT_PARAM_SLICE, 550, 0, 625, 0)
	RyzeSettings:addParam("wflee", "First cage in Long Combo if fleeing", SCRIPT_PARAM_SLICE, 550, 0, 625, 0)
	RyzeSettings:addParam("winsta", "Cage without waiting on Q if fleeing", SCRIPT_PARAM_ONOFF, true)
	RyzeSettings:addParam("ComboSwitch", "Switch Combo", SCRIPT_PARAM_ONOFF, true)
	RyzeSettings:addParam("minCDRnew", "CDR % to switch Combo", SCRIPT_PARAM_SLICE, 35, 0, 40, 0)

	if RyzeConfigConfig.BurstActiveshow then RyzeConfig:permaShow("BurstActive") end
	if RyzeConfigConfig.LongActiveshow then RyzeConfig:permaShow("LongActive") end
	if RyzeConfigConfig.useUltishow then RyzeConfig:permaShow("useUlti") end
	if RyzeConfigConfig.winstashow then RyzeSettings:permaShow("winsta") end
	if RyzeConfigConfig.PowerFarmshow then RyzeConfig:permaShow("PowerFarm") end
	if RyzeConfigConfig.ComboSwitchshow then RyzeSettings:permaShow("ComboSwitch") end

	ts.name = "Ryze"
	RyzeConfig:addTS(ts)

	ASLoadMinions()
	enemyMinions = minionManager(MINION_ENEMY, QRange, player, MINION_SORT_HEALTH_ASC)

	for i=1, heroManager.iCount do waittxt[i] = i*3 end
	if levelSequence then
		autoLevelSetSequence(levelSequence)
		autoLevelSetFunction(onChoiceFunction)
	end

	Items:add("DFG", 3128)
	Items:add("HXG", 3146)
	Items:add("BWC", 3144)
	Items:add("HYDRA", 3074)
	Items:add("SHEEN", 3057)
	Items:add("KITAES", 3186)
	Items:add("TIAMAT", 3077)
	Items:add("NTOOTH", 3115)
	Items:add("SUNFIRE", 3068)
	Items:add("WITSEND", 3091)
	Items:add("TRINITY", 3078)
	Items:add("STATIKK", 3087)
	Items:add("ICEBORN", 3025)
	Items:add("MURAMANA", 3042)
	Items:add("LICHBANE", 3100)
	Items:add("LIANDRYS", 3151)
	Items:add("BLACKFIRE", 3188)
	Items:add("HURRICANE", 3085)
	Items:add("RUINEDKING", 3153)
	Items:add("LIGHTBRINGER", 3185)
	Items:add("SPIRITLIZARD", 3209)
end

function OnDraw()
	if myHero.dead then return end  
	if RyzeConfigConfig.drawcircles then
		DrawCircle(myHero.x, myHero.y, myHero.z, QRange, myHero:CanUseSpell(_Q) == READY and 0x19A712 or 0x992D3D)
		DrawCircle(myHero.x, myHero.y, myHero.z, WRange, myHero:CanUseSpell(_W) == READY and 0x19A712 or 0x992D3D)
		DrawCircle(myHero.x, myHero.y, myHero.z, ERange, myHero:CanUseSpell(_E) == READY and 0x19A712 or 0x992D3D)
		if ValidTarget(ts.target) then DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0xFF80FF00) end
		if RyzeConfig.LongActive then DrawCircle(myHero.x, myHero.y, myHero.z, RyzeSettings.wflee, 0xFFFF0000) end

		for _, enemydraw in ipairs(GetEnemyHeroes()) do
			if killable[i] == 1 then
					DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80, 0x0000FF)
			elseif killable[i] == 2 then
					DrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80, 0xFF0000)
			end
			if waittxt[i] == 1 and killable[i] ~= 0 then
				PrintFloatText(enemydraw,0,floattext[killable[i]])
			end
			if waittxt[i] == 1 then 
				waittxt[i] = 30
			else
				waittxt[i] = waittxt[i]-1
			end
		end
	end
	if RyzeConfig.Quotes then
		if GetTickCount() > nextQuote then
			PrintFloatText(myHero, 10, quotes[math.random(5)])
			nextQuote = GetTickCount() + 60000
		end
	end
end

function OnTick()
	ts:update()
	enemyMinions:update()
	iSum:AutoIgnite()
	Items:update()
	RyzeDmg()
	iOW.AARange = myHero.range + GetDistance(myHero.minBBox)

	if not myHero.dead then
		if RyzeConfig.useMura then MuramanaToggle(1000, ((player.mana / player.maxMana) > (RyzeSettings.minMuraMana / 100))) end
		if RyzeConfig.BurstActive then
			if RyzeConfig.Orbwalk then iOW:Orbwalk(mousePos, ts.target) end
			if math.abs(myHero.cdr*100) >= RyzeSettings.minCDRnew and RyzeSettings.ComboSwitch then
				LongCombo()
			else
				BurstCombo()
			end
		elseif RyzeConfig.LongActive then
			if RyzeConfig.Orbwalk then iOW:Orbwalk(mousePos, ts.target) end
			LongCombo()
		elseif RyzeConfig.JungleActive then
			JungleClear()
		elseif RyzeConfig.PowerFarm and RyzeSettings.PowerMinMana<=((myHero.mana/myHero.maxMana)*100) then
			PowerFarm()
		end
	end
end

function OnProcessSpell(unit, spell)
	iOW:OnProcessSpell(unit, spell)
	if ValidTarget(unit, WRange) and UnderTurret(unit, false) and GetDistance(spell.endPos, myHero) < 10 and myHero:CanUseSpell(_W) == READY then
		CastSpellP(_W, unit)
	end
end

function OnCreateObj(object)
	if object and object.type == "obj_AI_Minion" and obj.name and jungleCamps[object.name] then
		jungleCamps[object.name].object = object
	end
end

--[[ Combat Functions ]]--

function doSpell(spell, range)
	if ts.target ~= nil and myHero:CanUseSpell(spell) == READY and GetDistance(ts.target) <= range then
		CastSpellP(spell, ts.target)
	end
end

function BurstCombo()
	if not ValidTarget(ts.target) then return end
	if DFGREADY then CastSpellP(DFGSlot, ts.target) end
	if HXGREADY then CastSpellP(HXGSlot, ts.target) end
	if BWCREADY then CastSpellP(BWCSlot, ts.target) end

	if myHero:CanUseSpell(SPELL_2) == READY and myHero:GetDistance(ts.target) > RyzeSettings.whunt then
		doSpell(ts, SPELL_2, WRange)
	elseif myHero:CanUseSpell(SPELL_1) == READY and myHero:GetDistance(ts.target) <= RyzeSettings.whunt then
		doSpell(ts, SPELL_1, QRange)
	elseif myHero:CanUseSpell(SPELL_1) == READY then
		doSpell(ts, SPELL_1, QRange)
	elseif RyzeConfig.useUlti and myHero:CanUseSpell(SPELL_4) == READY then
		CastSpellP(SPELL_4)
	elseif myHero:CanUseSpell(SPELL_3) == READY then
		doSpell(ts, SPELL_3, ERange)
	elseif myHero:CanUseSpell(SPELL_2) == READY then
		doSpell(ts, SPELL_2, WRange)
	end
end

function LongCombo()
	if not ValidTarget(ts.target) then return end
	if DFGREADY then CastSpellP(DFGSlot, ts.target) end
	if HXGREADY then CastSpellP(HXGSlot, ts.target) end
	if BWCREADY then CastSpellP(BWCSlot, ts.target) end
	if myHero:CanUseSpell(SPELL_1) == READY and myHero:GetDistance(ts.target) <= RyzeSettings.whunt then
		doSpell(ts, SPELL_1, QRange)
		qcasted = true
		if RyzeConfig.useUlti and myHero:CanUseSpell(SPELL_4) == READY and qcasted == true and myHero:CanUseSpell(SPELL_1) == COOLDOWN then
			CastSpellP(SPELL_4)
			qcasted = false
		end
	elseif myHero:CanUseSpell(SPELL_2) == READY and myHero:GetDistance(ts.target) > RyzeSettings.whunt then
		doSpell(ts, SPELL_2, WRange)
		qcasted = false
		if myHero:CanUseSpell(SPELL_1) == READY then
			doSpell(ts, SPELL_1, QRange)
			qcasted = true
		end
	elseif myHero:CanUseSpell(SPELL_1) == READY then
		doSpell(ts, SPELL_1, QRange)
		qcasted = true
	elseif RyzeConfig.useUlti and myHero:CanUseSpell(SPELL_4) == READY and qcasted == true and myHero:CanUseSpell(SPELL_1) == COOLDOWN then
		CastSpellP(SPELL_4)
		qcasted = false
	elseif myHero:CanUseSpell(SPELL_2) == READY and ((qcasted == true and myHero:CanUseSpell(SPELL_1) == COOLDOWN and myHero:GetDistance(ts.target) >= RyzeSettings.wflee) or (RyzeSettings.winsta == true and myHero:GetDistance(ts.target) >= RyzeSettings.wflee)) then
		doSpell(ts, SPELL_2, WRange)
		qcasted = false
	elseif myHero:CanUseSpell(SPELL_3) == READY and qcasted == true and myHero:CanUseSpell(SPELL_1) == COOLDOWN then
		doSpell(ts, SPELL_3, WRange)
		qcasted = false
	elseif myHero:CanUseSpell(SPELL_2) == READY and qcasted == true and myHero:CanUseSpell(SPELL_1) == COOLDOWN then
		doSpell(ts, SPELL_2, WRange)
		qcasted = false
	end
end

function PowerFarm()
	if RyzeConfig.Orbwalk then iOW:Orbwalk(mousePos, enemyMinions.objects[1]) end
	for _, minion in ipairs(enemyMinions.objects) do
		if ValidTarget(minion) then
			if myHero:CanUseSpell(SPELL_1) == READY and minion.health < getDmg("Q", minion, myHero) then
				CastSpellP(SPELL_1, minion)
			elseif myHero:CanUseSpell(SPELL_2) == READY and minion.health < getDmg("W", minion, myHero) then
				CastSpellP(SPELL_2, minion)
			elseif myHero:CanUseSpell(SPELL_3) == READY and minion.health < getDmg("E", minion, myHero) then
				CastSpellP(SPELL_3, minion)
			end
		end
	end
end

function JungleClear()
	local MonsterTarget = GetMonsterTarget()
	if RyzeConfig.Orbwalk then iOW:Orbwalk(mousePos, MonsterTarget) end
	if ValidTarget(MonsterTarget) then
		if myHero:CanUseSpell(SPELL_1) == READY then CastSpellP(SPELL_1, MonsterTarget) end
		if myHero:CanUseSpell(SPELL_2) == READY then CastSpellP(SPELL_2, MonsterTarget) end
		if myHero:CanUseSpell(SPELL_3) == READY then CastSpellP(SPELL_3, MonsterTarget) end
	end
end

--[[ Other Functions ]]--

function findClosestEnemy()
	local closestEnemy = nil
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) and closestEnemy == nil or GetDistanceSqr(enemy) < GetDistanceSqr(closestEnemy) then
			closestEnemy = enemy
		end
	end
	return closestEnemy
end

function RyzeDmg()
	if GetTickCount() - lastTick >= 100 then
		lastTick = GetTickCount()
		local enemy = heroManager:GetHero(calculationenemy)
		if ValidTarget(enemy) then
			local qdamage = getDmg("Q",enemy,myHero) --Normal
			local wdamage = getDmg("W",enemy,myHero)
			local edamage = getDmg("E",enemy,myHero)
			local itemDamage = 0
			for itemName, item in pairs(Items.items) do
				if item.ready then
					itemDamage = itemDamage + Items:Dmg(itemName, enemy)
				end
			end
			local combo1 = qdamage + qdamage + wdamage + edamage + itemDamage
			local combo2 = itemDamage
			if myHero:CanUseSpell(SPELL_1) == READY then combo2 = qdamage + combo2 end
			if myHero:CanUseSpell(SPELL_3) == READY then combo2 = edamage + combo2 end
			if myHero:CanUseSpell(SPELL_2) then combo2 = wdamage + combo2 end
			if myHero:CanUseSpell(SPELL_1) and myHero:CanUseSpell(SPELL_3) and myHero:CanUseSpell(SPELL_2) == READY then combo2 = qdamage + combo2 end
			if Items:Ready("DFG") then
				combo1 = combo1 * 1.2
				combo2 = combo2 * 1.2
			end
			if combo2 >= enemy.health then
				killable[calculationenemy] = 2
			elseif combo1 >= enemy.health then
				killable[calculationenemy] = 1
			else
				killable[calculationenemy] = 0
			end
		end
		if calculationenemy == 1 then
			calculationenemy = heroManager.iCount
		else
			calculationenemy = calculationenemy-1
		end
	end
end

function ASLoadMinions()
	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.type == "obj_AI_Minion" and obj.name and jungleCamps[object.name] then
			jungleCamps[object.name].object = object
		end
	end
end

function GetMonsterTarget()
	for _, monster in pairs(jungleCamps) do
		if ValidTarget(monster, QRange) then
			return monster
		end
	end
	return nil
end

function onChoiceFunction()
	if player:GetSpellData(SPELL_1).level < player:GetSpellData(SPELL_2).level then
		return 1
	else
		return 2
	end
end

function CastSpellP(spell, target)
	if target then
		Packet("S_CAST", {spellId = spell, targetNetworkId = target.networkID}):send()
	else
		Packet("S_CAST", {spellId = spell}):send()
	end
end