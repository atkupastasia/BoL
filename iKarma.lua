--[[ WARNING: This script is still being developed. Shit is messed up, things are incomplete, don't even think about using this in a legit game. ]]--

--[[ Degrec is a fool for trying to use it in a game. GG ]]--

--[[ iKarma by Apple ]]--

if myHero.charName ~= "Karma" then return end
if not VIP_USER then print("iKarma: VIP Script - Loading Aborted") return end

require "iSAC"
require "Collision"
if FileExist(LIB_PATH.."Prodiction.lua") then require "Prodiction" end

--[[ Config ]]--

local HK1 = string.byte("A")
local HK2 = string.byte("T")
local HK3 = string.byte("C")
local HK4 = string.byte("X")

local minHitChance = 0.3

--[[ Constants ]]--

local QRange, QSpeed, QDelay, QWidth, QRadius, QDetRadius, QDetTime = 950, 900, 0.250, 90, 50, 125, 1500
local WRange, WDelay, WLockTime = 675, 0.250, 2000
local ERange, EDelay, ERadius = 800, 0.250, 300

--[[ Script Variables ]]--

local ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, DAMAGE_MAGIC, false)
local tpQ = TargetPredictionVIP(QRange, QSpeed, QDelay, QWidth)
local tpQCollision = Collision(QRange, QSpeed, QDelay, QWidth)
local tpPro = ProdictManager and ProdictManager.GetInstance() or nil
local tpProQ = ProdictManager and tpPro:AddProdictionObject(_Q, QRange, QSpeed, QDelay, QWidth, myHero) or nil
local iOW = iOrbWalker(550, true)

local DamageResults = {}
local UltActive = false
local LinkActive = nil

--[[ Predefined Tables ]]--

local jungleObjects = {
	["TT_Spiderboss7.1.1"] = {object = nil, isCamp = true},
	["Worm12.1.1"] = {object = nil, isCamp = true},
	["Dragon6.1.1"] = {object = nil, isCamp = true},
	["AncientGolem1.1.1"] = {object = nil, isCamp = true},
	["AncientGolem7.1.1"] = {object = nil, isCamp = true},
}

--[[ Core Callbacks ]]--

function OnLoad()
	iKarmaConfig = scriptConfig("iKarma - Being A Bitch", "iKarma")

	iKarmaConfig:addParam("sep", "-=[ Hotkeys ]=-", SCRIPT_PARAM_INFO, "")
	iKarmaConfig:addParam("pewpew","PewPew!", SCRIPT_PARAM_ONKEYDOWN, false, HK1)
	iKarmaConfig:addParam("harass", "Poke!", SCRIPT_PARAM_ONKEYDOWN, false, HK2)

	iKarmaConfig:addParam("sep", "-=[ Combo Settings ]=-", SCRIPT_PARAM_INFO, "")
	if ProdictManager then iKarmaConfig:addParam("tpPro", "Use Prodiction", SCRIPT_PARAM_ONOFF, true) end
	iKarmaConfig:addParam("orbwalk", "Orbwalk", SCRIPT_PARAM_ONOFF, true)
	iKarmaConfig:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, false)
	iKarmaConfig:addParam("IndirectQ", "Indirect Q", SCRIPT_PARAM_ONOFF, true)
	iKarmaConfig:addParam("RangedQ", "Q out of W range", SCRIPT_PARAM_ONOFF, true)

	iKarmaConfig:addParam("sep", "-=[ Auto Settings ]=-", SCRIPT_PARAM_INFO, "")
	iKarmaConfig:addParam("AutoKS", "Auto Killsteal", SCRIPT_PARAM_ONOFF, true)
	iKarmaConfig:addParam("AutoJungle", "Auto Buffsteal", SCRIPT_PARAM_ONOFF, true)

	iKarmaConfig:addParam("sep", "-=[ Other Settings ]=-", SCRIPT_PARAM_INFO, "")
	iKarmaConfig:addParam("drawcircles", "Draw Circles", SCRIPT_PARAM_ONOFF, true)
	iKarmaConfig:addParam("damageText", "Kill Text", SCRIPT_PARAM_ONOFF, true)

	iKarmaConfig:permaShow("pewpew")
	iKarmaConfig:permaShow("harass")

	ts.name = "Karma"
	iKarmaConfig:addTS(ts)

	enemyMinions = minionManager(MINION_ENEMY, ERange, myHero, MINION_SORT_HEALTH_ASC)

	for i = 1, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object and object.valid and jungleObjects[object.name] and jungleObjects[object.name].isCamp then
			jungleObjects[object.name].object = object
		end
	end
end

function OnTick()
	ts:update()
	DamageCalculations()
	iOW.AARange = GetDistance(myHero.minBBox) + myHero.range
	UltActive = myHero:GetSpellData(_Q).name == ""

	if LinkActive and myHero:CanUseSpell(_W) == READY and GetTickCount() - LinkActive > GetLatency()*3 then LinkActive = false end

	if myHero.dead then return end
	if iKarmaConfig.damageText then damageText() end
	if iKarmaConfig.AutoKS then AutoKS() end
	if iKarmaConfig.AutoJungle then AutoJungle() end
	if iKarmaConfig.pewpew then PewPew() end
	if iKarmaConfig.harass then Poke() end

	if (iKarmaConfig.pewpew or iKarmaConfig.harass) and not (_G.AutoCarry and _G.AutoCarry.MainMenu.AutoCarry) then
		if iKarmaConfig.orbwalk then
			iOW:Orbwalk(mousePos, ts.target)
		elseif iKarmaConfig.moveToMouse then
			iOW:Move(mousePos)
		end
	end
end

function OnCreateObj(object)
	if object.name == "tempkarma_spiritbindtether_beam.troy" then LinkActive = GetTickCount() end
	if jungleObjects[object.name] and jungleObjects[object.name].isCamp then
		jungleObjects[object.name].object = object
	end
end

function OnDeleteObj(object)
	if object.name == "tempkarma_spiritbindtether_beam" then LinkActive = nil end
	if jungleObjects[object.name] and jungleObjects[object.name].isCamp then
		jungleObjects[object.name].object = nil
	end
end

function OnSendPacket(packet)
	if packet and packet.header == 0x9A then
		packet.pos = 1
		local networkID = packet:DecodeF()
		local spell = packet:Decode1()
		if networkID == myHero.networkID and spell == 1 and myHero:CanUseSpell(_W) == READY then
			LinkActive = GetTickCount()
		end
	end
end

function OnDraw()
	if myHero.dead then return end
	if iKarmaConfig.drawcircles then
		if myHero:CanUseSpell(_Q) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, QRange, 0xFF80FF00) end
		if myHero:CanUseSpell(_W) == READY then DrawCircle(myHero.x, myHero.y, myHero.z, WRange, 0xFF80FF00) end
		if ValidTarget(ts.target) then DrawCircle(ts.target.x, ts.target.y, ts.target.z, 100, 0xFFFF0000) end
		--if CollisionPos then DrawCircle(CollisionPos.x, myHero.y, CollisionPos.z, 100, 0xFFFF0000) end
	end
end

--[[ Combat Functions ]]--

function PewPew()
	if not ValidTarget(ts.target) then return end

	if myHero:CanUseSpell(_W) == READY and GetDistance(ts.target) < WRange then
		CastSpell(_W, ts.target)
	end

	local QPos = myHero:CanUseSpell(_Q) == READY and GetQPrediction(ts.target) or nil
	if QPos then
		local TarDist, QDist = GetDistance(ts.target), GetDistance(QPos)
		if QDist < QRange then
			local Damage = DamageResults[ts.target.networkID]
			local myMS, tarMS = myHero.ms, ts.target.ms
			local LinkTimeLeft = 2000 - (LinkActive and GetTickCount() - LinkActive or 0)
			local LinkDamages = LinkActive and math.ceil(LinkTimeLeft / 2000 * 3) or 0
			local LinkDuration = myHero:GetSpellData(_W).level * 250 + 750
			local DetonationTime = 1500 - 125 / (tarMS * 0.75) + QDelay
			local DetTimeFrame = LinkTimeLeft + LinkDuration - DetonationTime
			local QCD, CurRCD = (myHero:GetSpellData(_Q).cd * (1 + myHero.cdr)) * 1000, (myHero:GetSpellData(_R).currentCd - LinkDamages) * 1000
	
			if Damage.Q > ts.target.health then
				CastSpell(_Q, QPos.x, QPos.z)
				return
			elseif myHero:CanUseSpell(_R) == READY then
				if Damage.QUlt > ts.target.health or myHero:GetSpellData(_W).level == 0 or (myHero:CanUseSpell(_W) ~= READY and not LinkActive) then
					CastSpell(_R)
					CastSpell(_Q, QPos.x, QPos.z)
					return
				elseif not ts.target.canMove then
					CastSpell(_R)
					CastSpell(_Q, ts.target.x, ts.target.z)
				else
					if DetTimeFrame > QCD then
						CastSpell(_Q, QPos.x, QPos.z)
					end
				end
			end
	
			if LinkActive and tarMS > myMS and QDist > TarDist then
				local CurLinkLeft = (WRange - TarDist) / (myMS - tarMS)
				if LinkTimeLeft > CurLinkLeft and CurLinkLeft < QDelay or LinkTimeLeft % 666  > CurLinkLeft then
					CastSpell(_Q, QPos.x, QPos.z)
				end
			elseif myHero:CanUseSpell(_R) ~= READY then
				if CurRCD > QCD then
					CastSpell(_Q, QPos.x, QPos.z)
				elseif Damage.Q * CurRCD / QCD > Damage.QUlt - Damage.Q then
					CastSpell(_Q, QPos.x, QPos.z)
				elseif iKarmaConfig.RangedQ and TarDist > WRange and QDist > TarDist then
					if tarMS > myMS then
						CastSpell(_Q, QPos.x, QPos.z)
					else
						local SlowedCatchTime = (TarDist - WRange) / (myMS - tarMS * 0.75) + (QDelay + GetDistance(ts.target, QPos)) / tarMS
						if DetTimeFrame + SlowedCatchTime > QCD then
							CastSpell(_Q, QPos.x, QPos.z)
						end
					end
				end
			end
		end
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

function AutoKS()
	if myHero:CanUseSpell(_Q) ~= READY then return end
	for i, enemy in ipairs(GetEnemyHeroes()) do
		local Damage = DamageResults[enemy.networkID]
		if Damage and GetDistance(enemy) < QRange then
			if Damage.Q > enemy.health then
				local QPos = GetQPrediction(enemy)
				if QPos then
					CastSpell(_Q, QPos.x, QPos.z)
				return
				end
			elseif myHero:CanUseSpell(_R) == READY and Damage.QUlt > enemy.health then
				local QPos = GetQPrediction(enemy)
				if QPos then
					CastSpell(_R)
					CastSpell(_Q, QPos.x, QPos.z)
				return
				end
			end
		end
	end
end

function AutoJungle()
	if myHero:CanUseSpell(_Q) ~= READY then return end
	for _, jungleMob in pairs(jungleObjects) do
		if jungleMob and jungleMob.isCamp then
			local tempMob = jungleMob.object
			if ValidTarget(tempMob, QRange) and myHero:CalcMagicDamage(tempMob, 40 + 45 * QLevel + 0.6 * MyAP) >  tempMob.health then
				CastSpell(_Q, tempMob.x, tempMob.z)
			end
		end
	end
end

--[[ Predictions and Calculations ]]--

function GetQPrediction(enemy)
	if iKarmaConfig.tpPro then
		local QPos, _, QHitChance = tpProQ:GetPrediction(enemy)
		if not QPos or minHitChance ~= 0 and QHitChance and QHitChance < minHitChance or GetDistance(QPos) > QRange + GetDistance(enemy, enemy.minBBox)/2 then return nil end
		local willCollide, collideArray = tpQCollision:GetMinionCollision(myHero, QPos)
		if not willCollide then
			return QPos
		elseif iKarmaConfig.IndirectQ then
			local ClosestMinion, ClosestDistance = nil, 0
			for i, minion in pairs(collideArray) do
				local CurDistance = GetDistance(minion)
				if not ClosestMinion or CurDistance < ClosestDistance then
					ClosestMinion = minion
					ClosestDistance = CurDistance
				end
			end
			CollisionPos = CircleLineIntersection(myHero, QPos, ClosestMinion, GetDistance(ClosestMinion, ClosestMinion.minBBox) / 2)
			if CollisionPos then
				if GetDistance(CollisionPos, QPos) < QRadius + GetDistance(enemy, enemy.minBBox) / 2 then
					return QPos
				end
			end
		end
	end
end

function DamageCalculations()
	local MyAP, QLevel, WLevel, RLevel = myHero.ap, myHero:GetSpellData(_Q).level, myHero:GetSpellData(_W).level, myHero:GetSpellData(_R).level
	for i, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			local ReturnDamage = {}
			ReturnDamage.Q = myHero:CalcMagicDamage(enemy, 40 + 45 * QLevel + 0.6 * MyAP)
			ReturnDamage.QUlt = ReturnDamage.Q + myHero:CalcMagicDamage(enemy, 25 + 50 * RLevel + 0.3 * MyAP)
			ReturnDamage.QDet = myHero:CalcMagicDamage(enemy, -50 + 100 * RLevel + 0.6 * MyAP)
			ReturnDamage.W = myHero:CalcMagicDamage(enemy, 10 + 50 * WLevel + 0.6 * MyAP)
			ReturnDamage.WUlt = ReturnDamage.W + myHero:CalcMagicDamage(enemy, 75 * WLevel + 0.6 * MyAP)
			ReturnDamage.WTick = math.ceil(ReturnDamage.W/3)
			ReturnDamage.WUltTick = math.ceil(ReturnDamage.WUlt/3)
			ReturnDamage.EUlt = myHero:CalcMagicDamage(enemy, -20 + 80 * RLevel + 0.6 * MyAP)
			DamageResults[enemy.networkID] = ReturnDamage
		else
			DamageResults[enemy.networkID] = nil
		end
	end
	DamageResults.E = 40 + 40 * myHero:GetSpellData(_E).level + 0.5 * MyAP
end

function CircleLineIntersection(PointA, PointB, Center, Radius, Width)
	local baX = PointB.x - PointA.x
	local baY = PointB.z - PointA.z
	local caX = Center.x - PointA.x
	local caY = Center.z - PointA.z
	
	local a = baX * baX + baY * baY
	local b = (baX * caX + baY * caY) / a
	
	local disc = b * b - (caX * caX + caY * caY - Radius * Radius) / a;
	local Sqrt = math.sqrt(disc);
	local abScF1 = -b + Sqrt;
	local abScF2 = -b - Sqrt;
	
	if disc < 0 then return nil end
	local IntersectA = {x = PointA.x - baX * abScF1, z = PointA.z - baY * abScF1}
	if disc == 0 then return IntersectA end
	local IntersectB = {x = PointA.x - baX * abScF2, z = PointA.z - baY * abScF2}
	return GetDistance(IntersectA) < GetDistance(IntersectB) and IntersectA or IntersectB
end

function damageText()
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if ValidTarget(enemy) then
			if updateTextTimers[enemy.networkID] == nil then
				updateTextTimers[enemy.networkID] = 30
			elseif updateTextTimers[enemy.networkID] > 1 then
				updateTextTimers[enemy.networkID] = updateTextTimers[enemy.networkID] - 1
			elseif updateTextTimers[enemy.networkID] == 1 then			
				local Damage = DamageResults[enemy.networkID]
				if Damage.Q > enemy.health then
					PrintFloatText(enemy, 0, "Q!")
				elseif Damage.QUlt > enemy.health then
					PrintFloatText(enemy, 0, "Ult-Q!")
				elseif (myHero:CanUseSpell(_R) == READY and Damage.QUlt or Damage.Q) + Damage.W > enemy.health then
					PrintFloatText(enemy, 0, "Nuke!")
				end
				updateTextTimers[enemy.networkID] = 30
			end
		end
	end
end