--[[ iSpy - Knowledge = Power^2 ]]--
--[[ Intelligently tracking your victims ]]--

--[[ Config ]]--

--[[ Constants ]]--

--[[ Script Variables ]]--

local HeroTracker_WPM = WayPointManager()
local HeroTracker_Data = {
	enemyHeroes = {},
	lastSeenTimes = {},
	lastWayPoints = {}
}

function OnLoad()
	HeroTracker_Data.enemyHeroes = GetEnemyHeroes()
end

function OnTick()
	HeroTracker_Update()
end

function OnDraw()
	HeroTracker_Draw()
end







function HeroTracker_Update()
	for i, enemy in ipairs(HeroTracker_Data.enemyHeroes) do
		if enemy.visible and not enemy.dead then
			HeroTracker_Data.lastSeenTimes[i] = GetTickCount()
		end

		HeroTracker_Data.lastWayPoints[i] = HeroTracker_WPM:GetWayPoints(enemy) or HeroTracker_Data.lastWayPoints[i]
	end
end

function HeroTracker_Draw()
	for i, wayPointsList in ipairs(HeroTracker_Data.lastWayPoints) do
		local enemy = HeroTracker_Data.enemyHeroes[i]
		local lastSeen = HeroTracker_Data.lastSeenTimes[i]
		if not enemy.visible and not enemy.dead then
			local WPM_DrawPoints = {}
			for j, wayPoint in ipairs(wayPointsList) do
				local tempWayPoint = WorldToScreen(D3DXVECTOR3(wayPoint.x, enemy.y, wayPoint.y))
				table.insert(WPM_DrawPoints, D3DXVECTOR2(tempWayPoint.x, tempWayPoint.y))
			end
			DrawLines2(WPM_DrawPoints, 3, 0xFFFF0000)
		end
	end
end