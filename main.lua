--[[
	Lobotomizer Script Custom Version
]]
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua'))()
local Window = Rayfield:CreateWindow({Name = 'the "debug" button they call it', LoadingTitle = 'ready for the chaos?'})
local Players = game:GetService('Players')
local RepStorage = game:GetService('ReplicatedStorage')
local LocalPlayer = Players.LocalPlayer

local autoParryEnabled = false
local parryDistance = 18

local function listChildren(folder)
	local t = {}
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			table.insert(t, v.Name)
		end
	end
	table.sort(t)
	return t
end

local function getFolder(root, ...)
	local cur = root
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		if not cur then return nil end
		cur = cur:FindFirstChild(n)
	end
	return cur
end

local function normalizeSelected(v)
	if type(v) == 'string' then return v end
	if typeof(v) == 'Instance' then return v.Name end
	if type(v) == 'table' then
		if v[1] then return v[1] end
		if v.Name then return v.Name end
	end
	return tostring(v)
end

local function titleCase(s)
	if not s or #s == 0 then return '' end
	return string.upper(string.sub(s, 1, 1)) .. string.lower(string.sub(s, 2))
end

local abnoList = listChildren(getFolder(workspace, 'Abnormalities'))
local talentList = listChildren(getFolder(RepStorage, 'Assets', 'Talents'))
local selectedWork = 'Instinct'
local selectedTalentRaw = talentList[1] or ''
local selectedAbnos = {}

local Tab = Window:CreateTab('abno working')
Tab:CreateSection('Controls')
Tab:CreateSection('Select Abnormalities')

for _, abno in ipairs(abnoList) do
	Tab:CreateToggle({
		Name = abno,
		CurrentValue = false,
		Callback = function(Value)
			if Value then
				if not table.find(selectedAbnos, abno) then table.insert(selectedAbnos, abno) end
			else
				for i, v in ipairs(selectedAbnos) do
					if v == abno then table.remove(selectedAbnos, i) break end
				end
			end
		end,
	})
end

Tab:CreateButton({
	Name = 'Clear Selection',
	Callback = function() selectedAbnos = {} end,
})

Tab:CreateDropdown({
	Name = 'Work Type',
	Options = { 'Instinct', 'Insight', 'Attachment', 'Repression' },
	CurrentOption = selectedWork,
	Callback = function(opt) selectedWork = opt end,
})

Tab:CreateButton({
	Name = 'Work',
	Callback = function()
		pcall(function()
			if #selectedAbnos == 0 then return end
			local abnoRoot = getFolder(workspace, 'Abnormalities')
			local remote = getFolder(RepStorage, 'Assets', 'RemoteEvents', 'WorkEvent')
			if not abnoRoot or not remote then return end
			local flavor = titleCase(normalizeSelected(selectedWork))
			for _, abnoName in ipairs(selectedAbnos) do
				local sel = normalizeSelected(abnoName)
				local abno = abnoRoot:FindFirstChild(sel)
				if abno and abno:FindFirstChild('WorkTablet') then 
					remote:FireServer(abno.WorkTablet, flavor) 
				end
			end
		end)
	end,
})

local CardTab = Window:CreateTab('card selector')
CardTab:CreateDropdown({
	Name = 'Talent',
	Options = talentList,
	CurrentOption = selectedTalentRaw,
	Callback = function(opt) selectedTalentRaw = opt end,
})

CardTab:CreateButton({
	Name = 'Select card',
	Callback = function()
		pcall(function()
			local sel = normalizeSelected(selectedTalentRaw)
			if sel == '' then return end
			local remote = getFolder(RepStorage, 'Assets', 'RemoteEvents', 'SelectCardEvent')
			if remote then remote:FireServer(sel) end
		end)
	end,
})

local WeaponTab = Window:CreateTab('weapon mod')
WeaponTab:CreateSection('Defensive Mods (Auto Parry)')

WeaponTab:CreateToggle({
	Name = 'Enable Auto Parry',
	CurrentValue = false,
	Callback = function(Value) autoParryEnabled = Value end,
})

WeaponTab:CreateInput({
	Name = 'Parry Distance (Studs)',
	PlaceholderText = '18',
	Callback = function(text)
		local v = tonumber(text)
		if v and v > 0 then parryDistance = v end
	end,
})

WeaponTab:CreateSection('Hitbox Settings')
local hitboxSize = 10

WeaponTab:CreateInput({
	Name = 'Hitbox Size',
	PlaceholderText = '10',
	Callback = function(text)
		local v = tonumber(text)
		if v and v > 0 then hitboxSize = v end
	end,
})

local function applyHitboxToWeapon(tool)
    if tool and tool:IsA("Tool") and tool:FindFirstChild("Animations") then
        local attackAnims = tool.Animations:FindFirstChild("AttackAnimations")
        if attackAnims then
            for _, animFolder in ipairs(attackAnims:GetChildren()) do
                local hitboxValue = animFolder:FindFirstChild("HitboxSize")
                if hitboxValue and hitboxValue:IsA("Vector3Value") then
                    hitboxValue.Value = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                end
            end
        end
    end
end

local function applyHitboxToAllWeapons()
	if LocalPlayer.Character then
		for _, child in ipairs(LocalPlayer.Character:GetChildren()) do
			if child:IsA("Tool") then applyHitboxToWeapon(child) end
		end
	end
	if LocalPlayer:FindFirstChild("Backpack") then
		for _, child in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if child:IsA("Tool") then applyHitboxToWeapon(child) end
		end
	end
end

WeaponTab:CreateButton({
	Name = 'Apply Hitbox Size',
	Callback = function() applyHitboxToAllWeapons() end,
})

WeaponTab:CreateSection('Damage Settings')
local dmgMax, dmgMin = 1500, 1500

WeaponTab:CreateInput({
	Name = 'Max Damage',
	PlaceholderText = '1500',
	Callback = function(text) local v = tonumber(text) if v then dmgMax = v end end,
})

WeaponTab:CreateInput({
	Name = 'Min Damage',
	PlaceholderText = '1500',
	Callback = function(text) local v = tonumber(text) if v then dmgMin = v end end,
})

local function applyDamageToTool(tool)
	if tool:IsA('Tool') and tool:FindFirstChild('SettingValues') then
		local maxVal = tool.SettingValues:FindFirstChild('MaxDamageValue')
		local minVal = tool.SettingValues:FindFirstChild('MinDamageValue')
		if maxVal then pcall(function() maxVal.Value = dmgMax end) end
		if minVal then pcall(function() minVal.Value = dmgMin end) end
	end
end

local function applyAllDamageToWeapons()
	if LocalPlayer:FindFirstChild('Backpack') then
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do applyDamageToTool(tool) end
	end
	if LocalPlayer.Character then
		for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do applyDamageToTool(tool) end
	end
end

WeaponTab:CreateButton({
	Name = 'Apply Damage Changes',
	Callback = function() applyAllDamageToWeapons() end
})

WeaponTab:CreateSection('Attack Speed')
local attackSpeedValue = 5
local infiniteAttackSpeed = false

WeaponTab:CreateInput({
	Name = 'Attack Speed',
	PlaceholderText = '5',
	Callback = function(text) local v = tonumber(text) if v then attackSpeedValue = v end end,
})

local function setAttackSpeedValue(val)
	pcall(function()
		local units = workspace:WaitForChild('Units', 2)
		local playerUnit = units and units:FindFirstChild(LocalPlayer.Name)
		local charStats = playerUnit and playerUnit:FindFirstChild('CharStats')
		local attackSpeed = charStats and charStats:FindFirstChild
