--[[	Items Class for my sweetheart, Klokje
		To be used an extension for the Inventory class in AllClass, which only offers basic functionalities for now.
		
		Got bored and started writing this, out of the blue. Got inspired by Klokje's items class, wanted to see how far I could get.
		Writing classes is so much fun! Might not always be quite as useful, but alas. xD		]]--

class "Items"

local itemsAliasForDmgCalc = { -- Item Aliases for spellDmg lib, including their corresponding itemID's.
	["DFG"] = 3128,
	["HXG"] = 3146,
	["BWC"] = 3144,
	["HYDRA"] = 3074,
	["SHEEN"] = 3057,
	["KITAES"] = 3186,
	["TIAMAT"] = 3077,
	["NTOOTH"] = 3115,
	["SUNFIRE"] = 3068,
	["WITSEND"] = 3091,
	["TRINITY"] = 3078,
	["STATIKK"] = 3087,
	["ICEBORN"] = 3025,
	["MURAMANA"] = 3042,
	["LICHBANE"] = 3100,
	["LIANDRYS"] = 3151,
	["BLACKFIRE"] = 3188,
	["HURRICANE"] = 3085,
	["RUINEDKING"] = 3153,
	["LIGHTBRINGER"] = 3185,
	["SPIRITLIZARD"] = 3209,
	--["ENTROPY"] = 3184,
}

--[[

	Methods:
		Items = Items() -- Returns an Items instance.

	Functions:
		Items:add(name, ID, [range, extraOptions]) 	-- Adds an item to the instance. Name and ID required, range and extraOptions optional.
		Items:update() 								-- Update the instance. Item ready statusses and slots.
		Items:Have(itemID, [unit])					-- Check if the unit has the item. Returns true/false.
		Items:Slot(itemID, [unit])					-- Check if the unit has the item. Returns true/false.
		Items:Dmg(itemID, target, [source])			-- Returns the damage the item will deal on the target. Source optional, uses myHero if omitted.
		Items:InRange(itemID, target, [source])		-- Check if the target is within range. Returns true/false.
		
		Items:Use(itemID, [nil, nil, condition])	-- Use the item(s). Condition is optional, should be a function returning a boolean if used.
		Items:Use(itemID, target, [nil, condition])	-- itemID can be "all" if you wish to use all items.
		Items:Use(itemID, pos.x, pos.z,[condition])	--

	Members:
		Items.items		-- Returns the table with all added items.
	
	Example Usage:
		local items = Items()
		
		function OnLoad()
			items:add("DFG", 3128, 600, {onlyOnKill = true})
		end

		function OnTick()
			if ValidTarget(GetTarget()) then
				items:Use("DFG", GetTarget(), nil, (function(item, target) return (target.health / target.maxHealth > 0.5) end))
			end
		end

]]--

function Items:__init()
	self.items = {}
end

function Items:add(name, ID, range, extraOptions)
	assert(type(name) == "string" and type(ID) == "number" and (not range or range == math.huge or type(range) == "number") and (extraOptions == nil or type(extraOptions) == "table"))
	self.items[name] = {ID = ID, range = range or math.huge, slot = nil, ready = false}
	for key, value in pairs(extraOptions) do
		self.items[name][key] = value
	end
end

function Items:update()
	for itemName, item in pairs(self.items) do
		item.slot = GetInventorySlotItem(item.ID)
		item.ready = (item.slot and myHero:CanUseSpell(item.slot) == READY or false)
	end
end

function Items:Have(itemID, unit)
	return GetInventorySlotItem(type(itemID) == "string" and self.items[itemID].ID or type(itemID) == "number" and itemID, unit) ~= nil
end

function Items:Slot(itemID, unit)
	return GetInventorySlotItem(type(itemID) == "string" and self.items[itemID].ID or type(itemID) == "number" and itemID, unit)
end

function Items:Dmg(itemID, target, source)
	if type(itemID) == "string" then
		if itemsAliasForDmgCalc[itemID] ~= nil then return getDmg(itemID, target, source or myHero) end
		if self.items[itemID] then
			for itemName, aliasID in pairs(itemsAliasForDmgCalc) do
				if self.items[itemID].ID == aliasID then return getDmg(itemName, target, source or myHero) end
			end
		end
	elseif type(itemID) == "number" then
		for itemName, aliasID in pairs(itemsAliasForDmgCalc) do
			if itemID == aliasID then return getDmg(itemName, target, source or myHero) end
		end
	end
	return nil
end

function Items:InRange(itemID, enemy, source)
	if type(itemID) == "string" then return (self.items[itemID] and (not self.items[itemID].range or self.items[itemID].range > GetDistance(enemy, source or myHero))) end
	if type(itemID) == "number" then
		for _, item in pairs(self.items) do
			if itemID == item.ID then
				return (not item.range or item.range > GetDistance(enemy, source or myHero))
			end
		end
	end		
end

function Items:Use(itemID, arg1, arg2, condition) -- Condition could be a function, such as (function(item) return item.slot ~= ITEM_6 end) or perhaps (function(item, target) return (target.health / target.maxHealth > 0.5) end)
	for itemName, item in pairs(self.items) do
		if type(itemID) == "string" and (itemID == "all" or itemID == itemName) or type(itemID) == "number" and itemID == item.ID then
			if item.ready and (condition == nil or condition(item, arg1, arg2)) then
				if arg2 then
					CastSpell(item.slot, arg1, arg2)
				elseif arg1 then
					if self:InRange(itemName, arg1) then
						CastSpell(item.slot, arg1)
					end
				else
					CastSpell(item.slot)
				end
			end
		end
	end
end