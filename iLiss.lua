--[[ iLiss by Apple ]]--

if myHero.charName ~= "Lissandra" then return end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")
local HK4 = string.byte("X") -- Derp, not used.
local SafeBet = 20 -- % 
local minHitChance = 0.5

--[[ Constants ]]--

local QRange = 725
local WRange = 425
local ERange = 1050
local RRange = 550
local RRadius = 575
local igniteRange = 600
local defaultItemRange = 700

local QSpeed = 2300
local ESpeed = 850
local QDelay = 0.250
local EDelay = 0.250

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST,QRange,DAMAGE_MAGIC,false)
local tpQ = TargetPredictionVIP(QRange, QSpeed, QDelay, 40)
local tpE = TargetPredictionVIP(ERange, ESpeed, EDelay, 80)

local igniteSlot = nil
local EClaw = nil
local EClawRemoved = 0
local enemyMinions = {}
local updateTextTimers = {}

local items = {
	ZHONYAS = {id = 3157, slot = nil, ready = false},
	WOOGLETS = {id = 3090, slot = nil, ready = false},
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

function OnLoad()
	iLissConfig = scriptConfig("iLiss v0.1.1", "iLiss")

	iLissConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iLissConfig:addParam("autoFarm", "Munching Minions", SCRIPT_PARAM_ONKEYDOWN, false, HK2)
	iLissConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK3)

	iLissConfig:addParam("UltInCombo", "PewPew! with Ult?", SCRIPT_PARAM_ONOFF, true)
	iLissConfig:addParam("SmartSave", "Smart Save Items", SCRIPT_PARAM_ONOFF, true)
	iLissConfig:addParam("SmartSaveUlt", "Smart Save Ult", SCRIPT_PARAM_ONOFF, true)
	iLissConfig:addParam("SafeBet", "Smart Save Health %", SCRIPT_PARAM_SLICE, SafeBet or 20, 1, 100, 0)
	iLissConfig:addParam("ETeleManual", "Manual Second E", SCRIPT_PARAM_ONOFF, false)
	iLissConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	iLissConfig:addParam("damageText", "Kill Text", SCRIPT_PARAM_ONOFF, true)

	iLissConfig:permaShow("pewpew")
	iLissConfig:permaShow("harass")
	iLissConfig:permaShow("autoFarm")

	ts.name = "Lissandra"
	iLissConfig:addTS(ts)

	igniteSlot = ((myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") and SUMMONER_1) or (myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") and SUMMONER_2) or nil)
	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)
end

function OnTick()
	ts.range = (myHero:CanUseSpell(_E) == READY and ERange) or QRange
	ts:update()
	enemyMinions:update()
	updateItems()
	if EClaw ~= nil and not EClaw.valid then
		EClaw = nil
	end

	if not myHero.dead then
		AutoIgnite()
		if iLissConfig.autoFarm and not (iLissConfig.pewpew or iLissConfig.harass) then autoFarm() end
		if iLissConfig.pewpew then PewPew() end
		if iLissConfig.harass then Poke() end
		if iLissConfig.damageText then damageText() end
	end
end

function PewPew()
	if ValidTarget(ts.target) then
		local _,_,tempQPos = tpQ:GetPrediction(ts.target)
		local QPos = tpQ:GetHitChance(ts.target) > minHitChance and tempQPos or nil
		local _,_,tempEPos = tpE:GetPrediction(ts.target)
		local EPos = tpE:GetHitChance(ts.target) > minHitChance and tempEPos or nil
		if EClaw ~= nil and EClaw.valid and not iLissConfig.ETeleManual then
			if myHero:CanUseSpell(_E) == READY and (myHero:CanUseSpell(_Q) == READY or myHero:CanUseSpell(_W) == READY or myHero:CanUseSpell(_R) == READY) then
				if not UnderTurret(EClaw) then
					for i, enemy in ipairs(GetEnemyHeroes()) do
						if ValidTarget(enemy) and GetDistance(enemy, EClaw) < WRange - 50 and GetDistance(EClaw) < GetDistance(enemy) then
							CastSpell(_E)
							return
						end
					end	
				end
			end
		end
		if GetDistance(ts.target) < QRange then
			local tempDamage = calculateDamage(ts.target, true, true)
			if tempDamage.QWE > ts.target.health then
				if tempDamage.Q > ts.target.health and QPos then
					CastSpell(_Q, QPos.x, QPos.z)
				elseif tempDamage.W > ts.target.health then
					CastSpell(_W)
				elseif tempDamage.E > ts.target.health and EPos and EClaw == nil and GetTickCount() - EClawRemoved > 1000 then
					CastSpell(_E, EPos.x, EPos.z)
				elseif tempDamage.Q > 0 and tempDamage.W > 0 and tempDamage.Q + tempDamage.W > ts.target.health and QPos then
					CastSpell(_Q, QPos.x, QPos.z)
					CastSpell(_W)
				else
					if QPos then CastSpell(_Q, QPos.x, QPos.z) end
					if EPos and EClaw == nil and GetTickCount() - EClawRemoved > 1000 then CastSpell(_E, EPos.x, EPos.z) end
					if GetDistance(ts.target) < WRange then CastSpell(_W) end
				end
			elseif iLissConfig.UltInCombo and tempDamage.QWER > ts.target.health then
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if EPos and EClaw == nil and GetTickCount() - EClawRemoved > 1000 then CastSpell(_E, EPos.x, EPos.z) end
				if GetDistance(ts.target) < WRange then CastSpell(_W) end
				if GetDistance(ts.target) < RRange then CastSpell(_R, ts.target) end
			elseif (iLissConfig.UltInCombo and tempDamage.total or tempDamage.total - tempDamage.R) > ts.target.health then
				for item, itemInfo in pairs(items.itemsList) do
					if itemInfo.ready then
						CastSpell(itemInfo.slot, ts.target)
					end
				end
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if EPos and EClaw == nil and GetTickCount() - EClawRemoved > 1000 then CastSpell(_E, EPos.x, EPos.z) end
				if GetDistance(ts.target) < WRange then CastSpell(_W) end
				if iLissConfig.UltInCombo and GetDistance(ts.target) < RRange then CastSpell(_R, ts.target) end
				if igniteSlot and myHero:CanUseSpell(igniteSlot) then CastSpell(igniteSlot, ts.target) end
			else
				if QPos then CastSpell(_Q, QPos.x, QPos.z) end
				if EPos and EClaw == nil and GetTickCount() - EClawRemoved > 1000 then CastSpell(_E, EPos.x, EPos.z) end
				if GetDistance(ts.target) < WRange then CastSpell(_W) end
			end
		elseif GetDistance(ts.target) < ERange and EClaw == nil and GetTickCount() - EClawRemoved > 1000 and EPos then
			CastSpell(_E, EPos.x, EPos.z)
		end
	end
end

function Poke()
	if ValidTarget(ts.target) then
		local _,_,tempQPos = tpQ:GetPrediction(ts.target)
		local QPos = tpQ:GetHitChance(ts.target) > minHitChance and tempQPos or nil
		if QPos then
			CastSpell(_Q, QPos.x, QPos.z)
		end
	end
end

function AutoFreeze()
	if myHero:CanUseSpell(_W) == READY then
		local count = 0
		for i, enemy in ipairs(GetEnemyHeroes()) do
			if ValidTarget(enemy, WRange) then
				count = count + 1
			end
		end
		if count >= iLissConfig.minAutoFreeze then
			CastSpell(_W)
		end
	end
end

function safeUlt()
	if myHero:CanUseSpell(_R) == READY then
		if myHero.health / myHero.maxHealth < 0.2 then
			local enemyCount = 0
			for i, enemy in ipairs(GetEnemyHeroes()) do
				if ValidTarget(enemy, ERange) then
					enemyCount = enemyCount + 1
				end
			end
			if iLissConfig.minSafeUlt < enemyCount then
				CastSpell(_R, myHero)
			end
		end
	end
end

function updateItems()
	for item, itemInfo in pairs(items.itemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)		
		itemInfo.ready = (itemInfo.slot and myHero:CanUseSpell(itemInfo.slot) == READY or false)
	end
	for item, itemInfo in pairs(items.passiveItemsList) do
		itemInfo.slot = GetInventorySlotItem(itemInfo.id)
	end
	items["ZHONYAS"].slot = GetInventorySlotItem(items["ZHONYAS"].id)		
	items["ZHONYAS"].ready = (items["ZHONYAS"].slot and myHero:CanUseSpell(items["ZHONYAS"].slot) == READY or false)
	items["WOOGLETS"].slot = GetInventorySlotItem(items["WOOGLETS"].id)		
	items["WOOGLETS"].ready = (items["WOOGLETS"].slot and myHero:CanUseSpell(items["WOOGLETS"].slot) == READY or false)
end

function calculateDamage(enemy, checkRange, readyCheck)		
	local _,_,tempQPos = tpQ:GetPrediction(enemy)
	local QPos = tpQ:GetHitChance(enemy) > minHitChance and tempQPos or nil
	local _,_,tempEPos = tpE:GetPrediction(enemy)
	local EPos = tpE:GetHitChance(enemy) > minHitChance and tempEPos or nil

	local returnDamage = {}
	returnDamage.Qbase = (( (myHero:CanUseSpell(_Q) == READY or not readyCheck) and (QPos and GetDistance({x = QPos.x, z = QPos.z}) < QRange or not checkRange) and getDmg("Q", enemy, myHero)) or 0 )
	returnDamage.Wbase = (( (myHero:CanUseSpell(_W) == READY or not readyCheck) and (GetDistance(enemy) < WRange or not checkRange) and getDmg("W", enemy, myHero)) or 0 )
	returnDamage.Ebase = (( (myHero:CanUseSpell(_E) == READY or not readyCheck) and (EPos and GetDistance({x = EPos.x, z = EPos.z}) < ERange or not checkRange) and getDmg("E", enemy, myHero)) or 0 )
	returnDamage.Rbase = (( (myHero:CanUseSpell(_R) == READY or not readyCheck) and (GetDistance(enemy) < RRange or not checkRange) and getDmg("R", enemy, myHero)) or 0 )
	returnDamage.DFG = (( (items.itemsList["DFG"].ready or (items.itemsList["DFG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("DFG", enemy, myHero)) or 0 )
	returnDamage.HXG = (( (items.itemsList["HXG"].ready or (items.itemsList["HXG"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("HXG", enemy, myHero)) or 0 )
	returnDamage.BWC = (( (items.itemsList["BWC"].ready or (items.itemsList["BWC"].slot and not readyCheck)) and (GetDistance(enemy) < defaultItemRange or not checkRange) and getDmg("BWC", enemy, myHero)) or 0 )
	returnDamage.LIANDRYS = (( items.passiveItemsList["LIANDRYS"].slot and getDmg("LIANDRYS", enemy, myHero)) or 0)
	returnDamage.BLACKFIRE = (( items.passiveItemsList["BLACKFIRE"].slot and getDmg("BLACKFIRE", enemy, myHero)) or 0)
	returnDamage.ignite = (( igniteSlot and (myHero:CanUseSpell(igniteSlot) == READY or not readyCheck) and (GetDistance(enemy) < igniteRange or not checkRange) and getDmg("IGNITE", enemy, myHero)) or 0)

	returnDamage.onSpell = returnDamage.LIANDRYS + returnDamage.BLACKFIRE
	returnDamage.Q = returnDamage.Qbase + returnDamage.onSpell
	returnDamage.W = returnDamage.Wbase + returnDamage.onSpell
	returnDamage.E = returnDamage.Ebase + returnDamage.onSpell
	returnDamage.R = returnDamage.Rbase + returnDamage.onSpell
	returnDamage.QWE = returnDamage.Q + returnDamage.W + returnDamage.E
	returnDamage.QWER = returnDamage.QWE + returnDamage.R
	returnDamage.items = returnDamage.DFG + returnDamage.HXG + returnDamage.BWC

	returnDamage.total = (returnDamage.DFG > 0 and 1.2 * returnDamage.QWER or returnDamage.QWER) + returnDamage.items + returnDamage.ignite

	return returnDamage
end

function OnCreateObj(object)
	if object.name:find("Lissandra_E_Missile.troy") then
		EClaw = object
	end
end

function OnDeleteObj(object)
	if object.name:find("Lissandra_E_Missile.troy") then
		EClaw = nil
		EClawRemoved = GetTickCount()
	end
end

function damageText()
	local damageTextList = {"Poor Enemy", "Ultimate!", "Nuke!", "Risky"}
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			local calcDmg = calculateDamage(enemy, false, true)
			local killMode = (calcDmg.QWE > enemy.health and 1) or (calcDmg.R > enemy.health and 2) or (calcDmg.QWER > enemy.health and 3) or (calcDmg.total > enemy.health and 4) or 0
			if updateTextTimers[enemy.charName] == nil then
				updateTextTimers[enemy.charName] = 30
			elseif updateTextTimers[enemy.charName] > 1 then
				updateTextTimers[enemy.charName] = updateTextTimers[enemy.charName] - 1
			elseif killMode > 0 and updateTextTimers[enemy.charName] == 1 then
				PrintFloatText(enemy, 0, damageTextList[killMode])
				updateTextTimers[enemy.charName] = 30
			end
		end
	end
end

function OnDraw()
	if not myHero.dead and iLissConfig.drawcircles then
		if myHero:CanUseSpell(_Q) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFF80FF00)
		end
		if myHero:CanUseSpell(_W) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFF80FF00)
		end
		if myHero:CanUseSpell(_E) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, ERange, 0xFF80FF00)
		end
		if myHero:CanUseSpell(_R) == READY then
			DrawCircle(myHero.x, myHero.y, myHero.z, RRange, 0xFF80FF00)
		end

		if ValidTarget(ts.target) then
			for i = 1, 10 do
				DrawCircle(ts.target.x, ts.target.y, ts.target.z, 90+i, 0xFFFF0000)
			end
		end

		for i, minion in ipairs(enemyMinions.objects) do
			if minion and ValidTarget(minion, QRange) then
				if minion.health < getDmg("AD", minion, myHero) then
					for j = 1, 10 do
						DrawCircle(minion.x, minion.y, minion.z, 50+j, 0xFF80FF00)
					end
				elseif minion.health < getDmg("Q", minion, myHero) then
					for j = 1, 10 do
						DrawCircle(minion.x, minion.y, minion.z, 50+j, 0xFFFF0000)
					end
				end
			end
		end
	end
end

function AutoIgnite()
	if igniteSlot and myHero:CanUseSpell(igniteSlot) then
		for i, enemy in ipairs(GetEnemyHeroes()) do
			local igniteDmg = getDmg("IGNITE", enemy, myHero)
			if ValidTarget(enemy, igniteRange) and enemy.health < igniteDmg then
				CastSpell(igniteSlot, enemy)
			end
		end
	end
end

function autoFarm()
	local enemyNear = false
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if  ValidTarget(enemy, QRange) then
			enemyNear = true
		end
	end
	for i, minion in ipairs(enemyMinions.objects) do
		if minion and ValidTarget(minion, QRange) then
			if minion.health < getDmg("AD", minion, myHero) * 1.1 then
				myHero:Attack(minion)
				return
			elseif myHero:CanUseSpell(_Q) == READY and not enemyNear and minion.health < getDmg("Q", minion, myHero) then
				CastSpell(_Q, minion.x, minion.z)
			end
		end
	end
end

function OnProcessSpell(object, spell)

	if object == nil or spell == nil or not object.valid then return end

	if ((items["WOOGLETS"].ready or items["ZHONYAS"].ready) and iLissConfig.SmartSave) or (myHero:CanUseSpell(_R) == READY and iLissConfig.SmartSaveUlt) then
		if ValidTarget(object) and not myHero.dead and not (object.name:find("Minion_") or object.name:find("Odin")) then
			if object.type == "obj_AI_Hero" then
				local spellType = getSpellType(object, spell.name)
				if spellType ~= nil then

					-- Basic Attacks
					if spellType == "BAttack" or spellType == "CAttack" then
						local baseADmg = getDmg("AD", myHero, object)
						local onHitDmg = 0
							+ ((GetInventoryHaveItem(3078, object) and getDmg("TRINITY", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3186, object) and getDmg("KITAES", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3087, object) and getDmg("STATIKK", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3100, object) and getDmg("LICHBANE", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3114, object) and getDmg("MALADY", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3153, object) and getDmg("RUINEDKING", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3042, object) and getDmg("MURAMANA", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3091, object) and getDmg("WITSEND", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3057, object) and getDmg("SHEEN", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3025, object) and getDmg("ICEBORN", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3184, object) and 80) or 0)
						local PhysDamage = (spellType == "BAttack" and (baseADmg + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0)) or (spellType == "CAttack" and (GetInventoryHaveItem(3031, object) and (baseADmg * 2.5 + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0)) or (baseADmg * 1.5 + onHitDmg) * 1.07 + ((GetInventoryHaveItem(3209, object) and getDmg("SPIRITLIZARD", myHero, object)) or 0))
	
						if spell.endPos ~= nil and GetDistance(spell.endPos) < 50 then
							if myHero.health - PhysDamage < myHero.maxHealth * (iLissConfig.SafeBet / 100) then
								if items["WOOGLETS"].ready and iLissConfig.SmartSave then
									CastSpell(items["WOOGLETS"].slot)
								elseif items["ZHONYAS"].ready and iLissConfig.SmartSave then
									CastSpell(items["ZHONYAS"].slot)
								elseif myHero:CanUseSpell(_R) == READY and iLissConfig.SmartSaveUlt then
									CastSpell(_R, myHero)
								end
							end
						end

					-- QWER Attacks
					elseif string.find("QWER", spellType) then
						local onHitSpellDmg = 0
							+ ((GetInventoryHaveItem(3151, object) and getDmg("LIANDRYS", myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3042, object) and getDmg("MURAMANA",myHero, object)) or 0)
							+ ((GetInventoryHaveItem(3188, object) and getDmg("BLACKFIRE", myHero, object)) or 0)
						local spellDamage = (getDmg(spellType, myHero, object) + onHitSpellDmg) * 1.07 + (GetInventoryHaveItem(3209) and getDmg("SPIRITLIZARD", myHero, object) or 0)
						local skillType, skillRadius, skillMaxDistance = skillData[object.charName][spellType]["type"], skillData[object.charName][spellType]["radius"], skillData[object.charName][spellType]["maxdistance"]
						if (skillType == 0 and checkhitaoe(object, spell.endPos, 80, myHero, 0)) or (skillType == 1 and checkhitlinepass(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 2 and checkhitlinepoint(object, spell.endPos, skillRadius, myHero, 50)) or (skillType == 3 and checkhitaoe(object, spell.endPos, skillRadius, myHero, 50)) or (skillType == 4 and checkhitcone(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 5 and checkhitwall(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50)) or (skillType == 6 and (checkhitlinepass(object, spell.endPos, skillRadius, skillMaxDistance, myHero, 50) or checkhitlinepass(object, Vector(object)*2-spell.endPos, skillRadius, skillMaxDistance, myHero, 50))) then
							if myHero.health - spellDamage < myHero.maxHealth * (iLissConfig.SafeBet / 100) then
								if items["WOOGLETS"].ready and iLissConfig.SmartSave then
									CastSpell(items["WOOGLETS"].slot)
								elseif items["ZHONYAS"].ready and iLissConfig.SmartSave then
									CastSpell(items["ZHONYAS"].slot)
								elseif myHero:CanUseSpell(_R) == READY and iLissConfig.SmartSaveUlt then
									CastSpell(_R, myHero)
								end
							end
						end
					end
				end
			end
		end
	end
end