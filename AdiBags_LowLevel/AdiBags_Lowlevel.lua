local _, ns = ...
local string_find = string.find
local addon = LibStub("AceAddon-3.0"):GetAddon("AdiBags")
local L = setmetatable({}, {__index = addon.L})
local C_TooltipInfo_GetBagItem = C_TooltipInfo and C_TooltipInfo.GetBagItem
local TooltipUtil_SurfaceArgs = TooltipUtil and TooltipUtil.SurfaceArgs

local function create()
  local tip, leftTip, rightTip = CreateFrame("GameTooltip"), {}, {}
  for x = 1,6 do
    local L,R = tip:CreateFontString(), tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L,R)
    leftTip[x] = L
    rightTip[x] = R
  end
  tip.leftTip = leftTip
  tip.rightTip = rightTip
  return tip
end

local tooltip = tooltip or create()

-- The filter itself

local setFilter = addon:RegisterFilter("Lowlevel", 62, 'ABEvent-1.0')
setFilter.uiName = L['Lowlevel']
setFilter.uiDesc = L['Put Low level items in their own sections.']

function setFilter:OnInitialize()
  self.db = addon.db:RegisterNamespace('Lowlevel', {
    profile = { enable = true, level = 800 },
    char = {  },
  })
end

function setFilter:Update()
  self:SendMessage('AdiBags_FiltersChanged')
end

function setFilter:OnEnable()
  addon:UpdateFilters()
end

function setFilter:OnDisable()
  addon:UpdateFilters()
end

-- Tooltip used for scanning.
-- Let's keep this name for all scanner addons.
local _SCANNER = "AVY_ScannerTooltip"
local Scanner
if not addon.WoW10 then
	-- This is not needed on WoW10, since we can use C_TooltipInfo
	Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, UIParent, "GameTooltipTemplate")
end

-- Cache of information objects,
-- globally available so addons can share it.
local Cache = AVY_ItemBindInfoCache or {}
AVY_ItemBindInfoCache = Cache

function setFilter:Filter(slotData)

	local bag, slot, quality, itemId = slotData.bag, slotData.slot, slotData.quality, slotData.itemId

	local _, _, _, _, _, _, _, _, _, _, _, _, _, bindType, _, _, _ = GetItemInfo(itemId)

  local level = self:GetItemCategory(bag, slot)
  return level
end


function setFilter:GetItemCategory(bag, slot)
	local category = nil

  -- New API in WoW10 means we don't need an actual frame for the tooltip
  -- https://wowpedia.fandom.com/wiki/Patch_10.0.2/API_changes#Tooltip_Changes
  Scanner = C_TooltipInfo_GetBagItem(bag, slot)
  -- The SurfaceArgs calls are required to assign values to the 'leftText' fields seen below.
  TooltipUtil_SurfaceArgs(Scanner)
  for _, line in ipairs(Scanner.lines) do
    TooltipUtil_SurfaceArgs(line)
  end
  for i = 2, 6 do
    local line = Scanner.lines[i]
    if (not line) then
      break
    end

    local m = line.leftText:match("^Item Level (%d+)$")
    if self.db.profile.enable and m ~= nil and tonumber(m) < self.db.profile.level then
      return "Low level"
    end
  end

	return category
end

function setFilter:GetOptions()
  return {
    enable = {
      name = L['Enable Lowlevel'],
      desc = L['Check this if you want a section for lowlevel items.'],
      type = 'toggle',
      order = 10,
    },
    level = {
      name = L['Item level'],
      desc = L['Minimum item level matched'],
      type = 'range',
      min = 0,
      max = 1000,
      step = 1,
      order = 20,
    },
  }, addon:GetOptionHandler(self, false, function() return self:Update() end)
end
