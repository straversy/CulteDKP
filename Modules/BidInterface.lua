local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local lootTable = {};

  --[[["132744"] = "|cffa335ee|Hitem:12895::::::::60:::::|h[Breastplate of the Chromatic Flight]|h|r",
  ["132585"] = "|cffa335ee|Hitem:16862::::::::60:::::|h[Sabatons of Might]|h|r",
  ["133066"] = "|cffff8000|Hitem:17182::::::::60:::::|h[Sulfuras, Hand of Ragnaros]|h|r",
  ["133173"] = "|cffa335ee|Hitem:16963::::::::60:::::|h[Helm of Wrath]|h|r",
  ["135065"] = "|cffa335ee|Hitem:16961::::::::60:::::|h[Pauldrons of Wrath]|h|r",--]]

local width, height, numrows = 370, 18, 13
local Bids_Submitted = {};
local CurrItemForBid, CurrItemIcon;

-- Broadcast should set LootTable_Set when loot is opened. Starting an auction will update through CurrItem_Set
-- When bid received it will be broadcasted and handled with Bids_Set(). If bid broadcasting is off, window will be reduced in size and scrollframe removed.

function CulteDKP:LootTable_Set(lootList)
  lootTable = lootList
end

local function SortBidTable()
  mode = core.DB.modes.mode;
  table.sort(Bids_Submitted, function(a, b)
      if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
        return a["bid"] > b["bid"]
      elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
        return a["dkp"] > b["dkp"]
      elseif mode == "Roll Based Bidding" then
        return a["roll"] > b["roll"]
      end
    end)
end

local function RollMinMax_Get()
  local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), UnitName("player"))
  local minRoll;
  local maxRoll;

  if core.DB.modes.rolls.UsePerc then
    if core.DB.modes.rolls.min == 0 or core.DB.modes.rolls.min == 1 then
      minRoll = 1;
    else
      minRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp * (core.DB.modes.rolls.min / 100);
    end
    maxRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp * (core.DB.modes.rolls.max / 100) + core.DB.modes.rolls.AddToMax;
  elseif not core.DB.modes.rolls.UsePerc then
    minRoll = core.DB.modes.rolls.min;

    if core.DB.modes.rolls.max == 0 then
      maxRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp + core.DB.modes.rolls.AddToMax;
    else
      maxRoll = core.DB.modes.rolls.max + core.DB.modes.rolls.AddToMax;
    end
  end
  if tonumber(minRoll) < 1 then minRoll = 1 end
  if tonumber(maxRoll) < 1 then maxRoll = 1 end

  return minRoll, maxRoll;
end

local function UpdateBidderWindow()
	local i = 1;
	local mode = core.DB.modes.mode;
	local _,link,_,_,_,_,_,_,_,icon = GetItemInfo(CurrItemForBid)

	if not core.BidInterface then
		core.BidInterface = core.BidInterface or CulteDKP:BidInterface_Create()
	end

	for j=2, 10 do
		core.BidInterface.LootTableIcons[j]:Hide()
		core.BidInterface.LootTableButtons[j]:Hide();
	end
	core.BidInterface.lootContainer:SetSize(35, 35)

	for k,v in pairs(lootTable) do
		core.BidInterface.LootTableIcons[i]:SetTexture(tonumber(v.icon))
		core.BidInterface.LootTableIcons[i]:Show()
		core.BidInterface.LootTableButtons[i]:Show();
		core.BidInterface.LootTableButtons[i]:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
			GameTooltip:SetHyperlink(v.link)
		end)
		core.BidInterface.LootTableButtons[i]:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		if tonumber(v.icon) == icon and v.link == link then
			ActionButton_ShowOverlayGlow(core.BidInterface.LootTableButtons[i])
		else
			ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
		end
		i = i+1
	end

	if i==1 then
		core.BidInterface.lootContainer:SetSize(35, 35)
	else
		i = i-1
		core.BidInterface.lootContainer:SetSize(43*i, 35)
	end

	if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
		core.BidInterface.MinBidHeader:SetText(L["MINIMUMBID"]..":")
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.Bid, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["SUBMITBID"])
		core.BidInterface.Bid:Show();
		core.BidInterface.CancelBid:Show();
		core.BidInterface.Pass:Show();
	elseif mode == "Roll Based Bidding" then
		core.BidInterface.MinBidHeader:SetText(L["ITEMCOST"]..":")
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.BidHeader, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["ROLL"])
		core.BidInterface.Bid:Hide();
		core.BidInterface.CancelBid:Hide();
		core.BidInterface.Pass:Hide();
	else
		core.BidInterface.MinBidHeader:SetText(L["ITEMCOST"]..":")
		core.BidInterface.SubmitBid:SetPoint("LEFT", core.BidInterface.BidHeader, "RIGHT", 8, 0)
		core.BidInterface.SubmitBid:SetText(L["SUBMITBID"])
		core.BidInterface.Bid:Hide();
		core.BidInterface.CancelBid:Show();
		core.BidInterface.Pass:Show();
	end


	core.BidInterface.item:SetText(CurrItemForBid)
	core.BidInterface.Boss:SetText(core.DB.bossargs.LastKilledBoss)
end

function CulteDKP_BidInterface_Update()
  local numOptions = #Bids_Submitted;
  local index, row
    local offset = FauxScrollFrame_GetOffset(core.BidInterface.bidTable) or 0
    local rank;
    local showRows = #Bids_Submitted

    if #Bids_Submitted > numrows then
      showRows = numrows
    end

  if not core.BidInterface.bidTable:IsShown() then return end

    SortBidTable()
    for i=1, numrows do
      row = core.BidInterface.bidTable.Rows[i]
      row:Hide()
    end    
  if Bids_Submitted[1] and Bids_Submitted[1].bid and core.BidInterface.bidTable:IsShown() and
    (core.BidInterface.Bid:GetNumber() == nil or tonumber(core.BidInterface.Bid:GetNumber()) == nil or Bids_Submitted[1].bid > tonumber(core.BidInterface.Bid:GetNumber())) then
    core.BidInterface.Bid:SetNumber(Bids_Submitted[1].bid)
  end
    for i=1, showRows do
        row = core.BidInterface.bidTable.Rows[i]
        index = offset + i
        local dkp_total = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), Bids_Submitted[i].player)
        local c
        if dkp_total then
          c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].class)
        else
          local createProfile = CulteDKP_Profile_Create(Bids_Submitted[i].player)

          if createProfile then
            dkp_total = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), Bids_Submitted[i].player)
            c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].class)
          else       -- if unable to create profile, feeds grey color
            c = { r="aa", g="aa", b="aa"}
          end
        end
        rank = CulteDKP:GetGuildRank(Bids_Submitted[i].player)
        if Bids_Submitted[index] then
            row:Show()
            row.index = index
            row.Strings[1].rowCounter:SetText(index)
            row.Strings[1]:SetText(Bids_Submitted[i].player.." |cff666666("..rank..")|r")
            row.Strings[1]:SetTextColor(c.r, c.g, c.b, 1)
            if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
              row.Strings[2]:SetText(Bids_Submitted[i].bid)
              row.Strings[3]:SetText(CulteDKP_round(CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].dkp, core.DB.modes.rounding))
            elseif mode == "Roll Based Bidding" then
              local minRoll;
              local maxRoll;

              if core.DB.modes.rolls.UsePerc then
                if core.DB.modes.rolls.min == 0 or core.DB.modes.rolls.min == 1 then
                  minRoll = 1;
                else
                  minRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].dkp * (core.DB.modes.rolls.min / 100);
                end
                maxRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].dkp * (core.DB.modes.rolls.max / 100) + core.DB.modes.rolls.AddToMax;
              elseif not core.DB.modes.rolls.UsePerc then
                minRoll = core.DB.modes.rolls.min;

                if core.DB.modes.rolls.max == 0 then
                  maxRoll = CulteDKP:GetTable(CulteDKP_DKPTable, true)[dkp_total[1][1]].dkp + core.DB.modes.rolls.AddToMax;
                else
                  maxRoll = core.DB.modes.rolls.max + core.DB.modes.rolls.AddToMax;
                end
              end
              if tonumber(minRoll) < 1 then minRoll = 1 end
              if tonumber(maxRoll) < 1 then maxRoll = 1 end

              row.Strings[2]:SetText(Bids_Submitted[i].roll..Bids_Submitted[i].range)
              row.Strings[3]:SetText(math.floor(minRoll).."-"..math.floor(maxRoll))
            elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
              row.Strings[2]:SetText(Bids_Submitted[i].spec)
              row.Strings[3]:SetText(CulteDKP_round(Bids_Submitted[i].dkp, core.DB.modes.rounding))
            end
        else
            row:Hide()
        end
    end
    FauxScrollFrame_Update(core.BidInterface.bidTable, numOptions, numrows, height, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding
end

function CulteDKP:BidInterface_Toggle()
  core.BidInterface = core.BidInterface or CulteDKP:BidInterface_Create()
  local f = core.BidInterface;
  local mode = core.DB.modes.mode;

  if core.DB.bidintpos then
    core.BidInterface:ClearAllPoints()
    local a = core.DB.bidintpos
    core.BidInterface:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
  end

  if core.BidInterface:IsShown() then core.BidInterface:Hide(); end
  if CulteDKP.BidTimer.OpenBid and CulteDKP.BidTimer.OpenBid:IsShown() then CulteDKP.BidTimer.OpenBid:Hide() end
  if core.DB.modes.BroadcastBids and not core.BiddingWindow then
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.BidInterface:SetHeight(532);
    else
      core.BidInterface:SetHeight(504);
    end
    core.BidInterface.bidTable:Show();
    for k, v in pairs(f.headerButtons) do
      v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
      if k == "player" then
        v:SetSize((width/2)-1, height)
        v:Show()
      else
        v:SetSize((width/4)-1, height)
        if mode == "Minimum Bid Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
		  if k == "spec" then 
            v:Hide()
          else
            v:Show();
          end	
        elseif mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
          if k == "bid" then
            v:Hide()
          else
            v:Show();
          end
        end
      end
    end

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      f.headerButtons.bid.t:SetText(L["BID"]);
      f.headerButtons.bid.t:Show();
      f.headerButtons.spec.t:Hide()
    elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      f.headerButtons.bid.t:Hide(); 
	  f.headerButtons.spec.t:SetText("SPEC");
      f.headerButtons.spec.t:Show()
    elseif mode == "Roll Based Bidding" then
      f.headerButtons.bid.t:SetText(L["PLAYERROLL"])
      f.headerButtons.bid.t:Show()
      f.headerButtons.spec.t:Hide()
    end

    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      f.headerButtons.dkp.t:SetText(L["TOTALDKP"]);
      f.headerButtons.dkp.t:Show();
    elseif mode == "Static Item Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
      f.headerButtons.dkp.t:SetText(L["DKP"]);
      f.headerButtons.dkp.t:Show()
    elseif mode == "Roll Based Bidding" then
      f.headerButtons.dkp.t:SetText(L["EXPECTEDROLL"])
      f.headerButtons.dkp.t:Show();
    end
  end

  if core.DB.modes.BroadcastBids then
    local pass, err = pcall(CulteDKP_BidInterface_Update)

    if not pass then
      print(err)
      core.CulteDKPUI:SetShown(false)
      StaticPopupDialogs["SUGGEST_RELOAD"] = {
        text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
        button1 = L["YES"],
        button2 = L["NO"],
        OnAccept = function()
          ReloadUI();
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
      }
      StaticPopup_Show ("SUGGEST_RELOAD")
    end
  end

  if not core.DB.modes.BroadcastBids or core.BiddingWindow then
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.BidInterface:SetHeight(259);
    else
      core.BidInterface:SetHeight(231);
    end
    core.BidInterface.bidTable:Hide();
  else
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.BidInterface:SetHeight(532);
    else
      core.BidInterface:SetHeight(504);
    end
    core.BidInterface.bidTable:Show();
  end  

  core.BidInterface:SetShown(true)
end

local function BidWindowCreateRow(parent, id) -- Create 3 buttons for each row in the list

  local f;

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f = CreateFrame("Frame", "CulteDKP_BidderWindow", UIParent, "ShadowOverlaySmallTemplate");
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f = CreateFrame("Button", "$parentLine"..id, parent)
  end
      
  f.Strings = {}
  f:SetSize(width, height)
  f:SetHighlightTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\ListBox-Highlight");
  f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
  f:GetNormalTexture():SetAlpha(0.2)
  for i=1, 3 do
      f.Strings[i] = f:CreateFontString(nil, "OVERLAY");
      f.Strings[i]:SetTextColor(1, 1, 1, 1);
      if i==1 then 
        f.Strings[i]:SetFontObject("CulteDKPNormalLeft");
      else
        f.Strings[i]:SetFontObject("CulteDKPNormalCenter");
      end
  end

  f.Strings[1].rowCounter = f:CreateFontString(nil, "OVERLAY");
  f.Strings[1].rowCounter:SetFontObject("CulteDKPSmallOutlineLeft")
  f.Strings[1].rowCounter:SetTextColor(1, 1, 1, 0.3);
  f.Strings[1].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);

    f.Strings[1]:SetWidth((width/2)-10)
    f.Strings[2]:SetWidth(width/4)
    f.Strings[3]:SetWidth(width/4)
--	f.Strings[4]:SetWidth(width/4)
    f.Strings[1]:SetPoint("LEFT", f, "LEFT", 20, 0)
    f.Strings[2]:SetPoint("LEFT", f.Strings[1], "RIGHT", -9, 0)
    f.Strings[3]:SetPoint("RIGHT", 0, 0)
--	f.Strings[4]:SetPoint("RIGHT", 0, 0)

    return f
end

-- populate bid window
function CulteDKP:CurrItem_Set(item, value, icon, value2)
  CurrItemForBid = item;
  CurrItemIcon = icon;

  

  ----------------------------------------------------------------------
  -- Check if item is in the item list
  -- If not then we have out of kill bid
  -- Overwrite the list to contain only the item
  -- Thank you to lantisnt of EssentialDKP for the assist on this.
  -- https://github.com/lantisnt/EssentialDKP/pull/26/files#diff-c2e2b9359e4bbfc335111a2a4472c9c6

  local _,tmpLink,_,_,_,_,_,_,_,tmpIcon = GetItemInfo(item)
  local currItemInLoot = false
  
  if tmpLink == nil then
    C_Timer.After(0.5, function () CulteDKP:CurrItem_Set(item, value, icon, value2); end);
    return;
  end

  for _,_i in pairs(lootTable) do
    if _i.link == tmpLink then currItemInLoot = true end
  end

  if not currItemInLoot then
    CulteDKP:LootTable_Set({{icon=tmpIcon, link=tmpLink}})
  end
  ----------------------------------------------------------------------
  
  UpdateBidderWindow()

  if not strfind(value, "%%") and not strfind(value, "DKP") then
    core.BidInterface.MinBid:SetText(value.." DKP");
  else
    core.BidInterface.MinBid:SetText(value);
  end
  
  if core.BidInterface.MaxBid then
    if not strfind(value2, "%%") and not strfind(value2, "DKP") then
      if value2 == "MAX" then
        local dkpValue = 0;

        local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), UnitName("player"), "player")
        if search then
          dkpValue = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp;
        end
        core.BidInterface.MaxBid:SetText(dkpValue.." DKP");
      else
        core.BidInterface.MaxBid:SetText(value2.." DKP");
      end
    else
      core.BidInterface.MaxBid:SetText(value2);
    end
  end
  
  if core.BidInterface.Bid:IsShown() then
    core.BidInterface.Bid:SetNumber(value);
  end

  if core.DB.modes.mode ~= "Roll Based Bidding" then
    core.BidInterface.SubmitBid:SetScript("OnClick", function()
      local message;

      if core.BidInterface.Bid:IsShown() then
        message = "!bid"..CulteDKP_round(core.BidInterface.Bid:GetNumber(), core.DB.modes.rounding)
      else
        message = "!bid";
      end
      CulteDKP.Sync:SendData("CDKPBidder", tostring(message))
      core.BidInterface.Bid:ClearFocus();
    end)
	
    -- TODO YOZO VALIDATE BID OS	
    core.BidInterface.SubmitBidOS:SetScript("OnClick", function()
      local message;

      if core.BidInterface.Bid:IsShown() then
         message = "!bid"..CulteDKP_round(core.BidInterface.Bid:GetNumber(), core.DB.modes.rounding)
      else
        message = "!bid OS";
      end
      CulteDKP.Sync:SendData("CDKPBidder", tostring(message))
      core.BidInterface.Bid:ClearFocus();
    end)

    core.BidInterface.CancelBid:SetScript("OnClick", function()
      CulteDKP.Sync:SendData("CDKPBidder", "!bid cancel")
      core.BidInterface.Bid:ClearFocus();
    end)
  elseif core.DB.modes.mode == "Roll Based Bidding" then
    core.BidInterface.SubmitBid:SetScript("OnClick", function()
      local min, max = RollMinMax_Get()

      RandomRoll(min, max);
    end)
  end

  if not core.DB.modes.BroadcastBids or core.BidInProgress then
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.BidInterface:SetHeight(259);
    else
      core.BidInterface:SetHeight(231);
    end
    core.BidInterface.bidTable:Hide();
  else
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.BidInterface:SetHeight(532);
    else
      core.BidInterface:SetHeight(504);
    end
    core.BidInterface.bidTable:Show();
  end
end

function CulteDKP:Bids_Set(entry)
  Bids_Submitted = entry;
  
  local pass, err = pcall(CulteDKP_BidInterface_Update)

  if not pass then
    print(err)
    core.CulteDKPUI:SetShown(false)
    StaticPopupDialogs["SUGGEST_RELOAD"] = {
      text = "|CFFFF0000"..L["WARNING"].."|r: "..L["MUSTRELOADUI"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        ReloadUI();
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("SUGGEST_RELOAD")
  end
end

function CulteDKP:BidInterface_Create()
  local f = CreateFrame("Frame", "CulteDKP_BidderWindow", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
  local mode = core.DB.modes.mode;
  f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 700, -200);
  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    f:SetSize(400, 532);
  else
    f:SetSize(400, 504);
  end
  f:SetClampedToScreen(true)
  f:SetBackdrop( {
    bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  });
  f:SetBackdropColor(0,0,0,0.9);
  f:SetBackdropBorderColor(1,1,1,1)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(5)
  f:SetMovable(true);
  f:EnableMouse(true);
  f:RegisterForDrag("LeftButton");
  f:SetScript("OnDragStart", f.StartMoving);
  f:SetScript("OnDragStop", function()
    f:StopMovingOrSizing();
    local point, relativeTo, relativePoint, xOff, yOff = f:GetPoint(1)
    if not core.DB.bidintpos then
      core.DB.bidintpos = {}
    end
    core.DB.bidintpos.point = point;
    core.DB.bidintpos.relativeTo = relativeTo;
    core.DB.bidintpos.relativePoint = relativePoint;
    core.DB.bidintpos.x = xOff;
    core.DB.bidintpos.y = yOff;
  end);
  f:SetScript("OnMouseDown", function(self)
    self:SetFrameLevel(10)
    if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
    if CulteDKP.UIConfig then CulteDKP.UIConfig:SetFrameLevel(2) end
  end)
  tinsert(UISpecialFrames, f:GetName()); -- Sets frame to close on "Escape"

    -- Close Button

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.closeContainer = CreateFrame("Frame", "CulteDKPBidderWindowCloseButtonContainer", f)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f.closeContainer = CreateFrame("Frame", "CulteDKPBidderWindowCloseButtonContainer", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  f.closeContainer:SetPoint("CENTER", f, "TOPRIGHT", -4, 0)
  f.closeContainer:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
  });
  f.closeContainer:SetBackdropColor(0,0,0,0.9)
  f.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
  f.closeContainer:SetSize(28, 28)

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f.closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton", BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  f.closeBtn:SetPoint("CENTER", f.closeContainer, "TOPRIGHT", -14, -14)

  f.LootTableIcons = {}
  f.LootTableButtons = {}

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.lootContainer = CreateFrame("Frame", "CulteDKP_LootContainer", UIParent);
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f.lootContainer = CreateFrame("Frame", "CulteDKP_LootContainer", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
  end

  
  f.lootContainer:SetPoint("TOP", f, "TOP", 0, -40);
  f.lootContainer:SetSize(35, 35)

  f.Boss = f:CreateFontString(nil, "OVERLAY")
  f.Boss:SetFontObject("CulteDKPLargeCenter")
  f.Boss:SetPoint("TOP", f, "TOP", 0, -10)

  for i=1, 10 do
    f.LootTableIcons[i] = f:CreateTexture(nil, "OVERLAY", nil);
    f.LootTableIcons[i]:SetColorTexture(0, 0, 0, 1)
    f.LootTableIcons[i]:SetSize(35, 35);
    f.LootTableIcons[i]:Hide();
    f.LootTableButtons[i] = CreateFrame("Button", "CulteDKPBidderLootTableButton", f)
    f.LootTableButtons[i]:SetPoint("TOPLEFT", f.LootTableIcons[i], "TOPLEFT", 0, 0);
    f.LootTableButtons[i]:SetSize(35, 35);
    f.LootTableButtons[i]:Hide()

    if i==1 then
      f.LootTableIcons[i]:SetPoint("LEFT", f.lootContainer, "LEFT", 0, 0);
    else
      f.LootTableIcons[i]:SetPoint("LEFT", f.LootTableIcons[i-1], "RIGHT", 8, 0);
    end
  end

  f.itemHeader = f:CreateFontString(nil, "OVERLAY")
  f.itemHeader:SetFontObject("CulteDKPLargeRight");
  f.itemHeader:SetScale(0.7)
  f.itemHeader:SetPoint("TOP", f, "TOP", -160, -135);
  f.itemHeader:SetText(L["ITEM"]..":")

  f.item = f:CreateFontString(nil, "OVERLAY")
  f.item:SetFontObject("CulteDKPNormalLeft");
  f.item:SetPoint("LEFT", f.itemHeader, "RIGHT", 5, 2);
  f.item:SetSize(200, 28)

  f.MinBidHeader = f:CreateFontString(nil, "OVERLAY")
  f.MinBidHeader:SetFontObject("CulteDKPLargeRight");
  f.MinBidHeader:SetScale(0.7)
  f.MinBidHeader:SetPoint("TOPRIGHT", f.itemHeader, "BOTTOMRIGHT", 0, -15);
  f.MinBidHeader:SetText(L["MINIMUMBID"]..":")

  f.MinBid = f:CreateFontString(nil, "OVERLAY")
  f.MinBid:SetFontObject("CulteDKPNormalLeft");
  f.MinBid:SetPoint("LEFT", f.MinBidHeader, "RIGHT", 8, 0);
  f.MinBid:SetSize(200, 28)

  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    f.MaxBidHeader = f:CreateFontString(nil, "OVERLAY")
    f.MaxBidHeader:SetFontObject("CulteDKPLargeRight");
    f.MaxBidHeader:SetScale(0.7)
    f.MaxBidHeader:SetPoint("TOPRIGHT", f.MinBidHeader, "BOTTOMRIGHT", 0, -20);
    f.MaxBidHeader:SetText(L["MAXIMUMBID"]..":")

    f.MaxBid = f:CreateFontString(nil, "OVERLAY")
    f.MaxBid:SetFontObject("CulteDKPNormalLeft");
    f.MaxBid:SetPoint("LEFT", f.MaxBidHeader, "RIGHT", 8, 0);
    f.MaxBid:SetSize(200, 28)
  end

  f.BidHeader = f:CreateFontString(nil, "OVERLAY")
  f.BidHeader:SetFontObject("CulteDKPLargeRight");
  f.BidHeader:SetScale(0.7)
  f.BidHeader:SetText(L["BID"]..":")
  if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    f.BidHeader:SetPoint("TOPRIGHT", f.MaxBidHeader, "BOTTOMRIGHT", 0, -20);
  else
    f.BidHeader:SetPoint("TOPRIGHT", f.MinBidHeader, "BOTTOMRIGHT", 0, -20);
  end

  f.Bid = CreateFrame("EditBox", nil, f, BackdropTemplateMixin and "BackdropTemplate" or nil)
  f.Bid:SetPoint("LEFT", f.BidHeader, "RIGHT", 8, 0)   
  f.Bid:SetAutoFocus(false)
  f.Bid:SetMultiLine(false)
  f.Bid:SetSize(70, 28)
  f.Bid:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  f.Bid:SetBackdropColor(0,0,0,0.6)
  f.Bid:SetBackdropBorderColor(1,1,1,0.6)
  f.Bid:SetMaxLetters(8)
  f.Bid:SetTextColor(1, 1, 1, 1)
  f.Bid:SetFontObject("CulteDKPSmallRight")
  f.Bid:SetTextInsets(10, 10, 5, 5)
  f.Bid:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)

  f.BidPlusOne = CreateFrame("Button", nil, f.Bid, "CulteDKPButtonTemplate")
  f.BidPlusOne:SetPoint("TOPLEFT", f.Bid, "BOTTOMLEFT", 0, -2);
  f.BidPlusOne:SetSize(33,20)
  f.BidPlusOne:SetText("+1");
  f.BidPlusOne:GetFontString():SetTextColor(1, 1, 1, 1)
  f.BidPlusOne:SetNormalFontObject("CulteDKPSmallCenter");
  f.BidPlusOne:SetHighlightFontObject("CulteDKPSmallCenter");
  f.BidPlusOne:SetScript("OnClick", function()
    f.Bid:SetNumber(f.Bid:GetNumber() + 1);
  end)

  f.BidPlusFive = CreateFrame("Button", nil, f.Bid, "CulteDKPButtonTemplate")
  f.BidPlusFive:SetPoint("TOPRIGHT", f.Bid, "BOTTOMRIGHT", 0, -2);
  f.BidPlusFive:SetSize(33,20)
  f.BidPlusFive:SetText("+5");
  f.BidPlusFive:GetFontString():SetTextColor(1, 1, 1, 1)
  f.BidPlusFive:SetNormalFontObject("CulteDKPSmallCenter");
  f.BidPlusFive:SetHighlightFontObject("CulteDKPSmallCenter");
  f.BidPlusFive:SetScript("OnClick", function()
    f.Bid:SetNumber(f.Bid:GetNumber() + 5);
  end)

  f.BidMax = CreateFrame("Button", nil, f.BidPlusFive, "CulteDKPButtonTemplate")
  f.BidMax:SetPoint("TOPLEFT", f.BidPlusFive, "BOTTOMLEFT", 0, -2);
  f.BidMax:SetSize(33,20)
  f.BidMax:SetText("MAX");
  f.BidMax:GetFontString():SetTextColor(1, 1, 1, 1)
  f.BidMax:SetNormalFontObject("CulteDKPSmallCenter");
  f.BidMax:SetHighlightFontObject("CulteDKPSmallCenter");
  f.BidMax:SetScript("OnClick", function()
    local behavior = core.DB.modes.MaxBehavior
    local itemValue = 0
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      local value, text = strsplit(" ", f.MaxBid:GetText())
      itemValue = tonumber(value)
    else
      behavior = "Max DKP"
    end

    local dkp = 0
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), UnitName("player"), "player")
    if search then
      dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp;
    end

    if behavior == "Max DKP" or itemValue == 0  then
      f.Bid:SetNumber(dkp);
    elseif behavior == "Max Item Value" then
      f.Bid:SetNumber(itemValue);
    elseif behavior == "Min(Max DKP, Max Item Value)" then
      if dkp < itemValue then
        f.Bid:SetNumber(dkp)
      else
        f.Bid:SetNumber(itemValue);
      end
    else
      f.Bid:SetNumber(dkp);
    end
  end)

  f.BidHalf = CreateFrame("Button", nil, f.BidPlusOne, "CulteDKPButtonTemplate")
  f.BidHalf:SetPoint("TOPLEFT", f.BidPlusOne, "BOTTOMLEFT", 0, -2);
  f.BidHalf:SetSize(33,20)
  f.BidHalf:SetText("HALF");
  f.BidHalf:GetFontString():SetTextColor(1, 1, 1, 1)
  f.BidHalf:SetNormalFontObject("CulteDKPSmallCenter");
  f.BidHalf:SetHighlightFontObject("CulteDKPSmallCenter");
  f.BidHalf:SetScript("OnClick", function()
    local behavior = core.DB.modes.MaxBehavior
    local itemValue = 0
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      local value, text = strsplit(" ", f.MaxBid:GetText())
      itemValue = tonumber(value)
    else
      behavior = "Max DKP"
    end

    local dkp = 0
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), UnitName("player"), "player")
    if search then
      dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp;
    end

    if behavior == "Max DKP" or itemValue == 0  then
      f.Bid:SetNumber(dkp/2);
    elseif behavior == "Max Item Value" then
      f.Bid:SetNumber(itemValue/2);
    elseif behavior == "Min(Max DKP, Max Item Value)" then
      if dkp < itemValue then
        f.Bid:SetNumber(dkp/2)
      else
        f.Bid:SetNumber(itemValue/2);
      end
    else
      f.Bid:SetNumber(dkp/2)
    end
  end)

  f.SubmitBid = CreateFrame("Button", nil, f, "CulteDKPButtonTemplate")
  f.SubmitBid:SetPoint("LEFT", f.Bid, "RIGHT", 8, 0);
  f.SubmitBid:SetSize(115,25)
  f.SubmitBid:SetText(L["SUBMITBID"]);
  f.SubmitBid:GetFontString():SetTextColor(1, 1, 1, 1)
  f.SubmitBid:SetNormalFontObject("CulteDKPSmallCenter");
  f.SubmitBid:SetHighlightFontObject("CulteDKPSmallCenter");

-- TODO YOZO SubmitBidOS
  f.SubmitBidOS = CreateFrame("Button", nil, f, "CulteDKPButtonTemplate")
  f.SubmitBidOS:SetPoint("LEFT", f.SubmitBid, "RIGHT", 32, 0);
  f.SubmitBidOS:SetSize(115,25)
  f.SubmitBidOS:SetText(L["SUBMITBIDOS"]);
  f.SubmitBidOS:GetFontString():SetTextColor(1, 1, 1, 1)
  f.SubmitBidOS:SetNormalFontObject("CulteDKPSmallCenter");
  f.SubmitBidOS:SetHighlightFontObject("CulteDKPSmallCenter");
  --f.SubmitBidOS:Disable();

  f.CancelBid = CreateFrame("Button", nil, f, "CulteDKPButtonTemplate")
  f.CancelBid:SetPoint("LEFT", f.SubmitBid, "BOTTOMLEFT", 0, -14);
  f.CancelBid:SetSize(115,25)
  f.CancelBid:SetText(L["CANCELBID"]);
  f.CancelBid:GetFontString():SetTextColor(1, 1, 1, 1)
  f.CancelBid:SetNormalFontObject("CulteDKPSmallCenter");
  f.CancelBid:SetHighlightFontObject("CulteDKPSmallCenter");
  f.CancelBid:SetScript("OnClick", function()
    --CancelBid()
    f.Bid:ClearFocus();
  end)

  f.Pass = CreateFrame("Button", nil, f, "CulteDKPButtonTemplate")
  f.Pass:SetPoint("LEFT", f.SubmitBidOS, "BOTTOMLEFT", 0, -14);
  f.Pass:SetSize(115,25)
  f.Pass:SetText(L["PASS"]);
  f.Pass:GetFontString():SetTextColor(1, 1, 1, 1)
  f.Pass:SetNormalFontObject("CulteDKPSmallCenter");
  f.Pass:SetHighlightFontObject("CulteDKPSmallCenter");
  f.Pass:SetScript("OnClick", function()
    f.Bid:ClearFocus();
    CulteDKP.Sync:SendData("CDKPBidder", "pass")
    core.BidInterface:Hide()
  end)

  if core.DB.defaults.AutoOpenBid == nil then
    core.DB.defaults.AutoOpenBid = true
  end

  f.AutoOpenCheckbox = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
  f.AutoOpenCheckbox:SetChecked(core.DB.defaults.AutoOpenBid)
  f.AutoOpenCheckbox:SetScale(0.6);
  f.AutoOpenCheckbox.text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
  f.AutoOpenCheckbox.text:SetScale(1.4);
  f.AutoOpenCheckbox.text:ClearAllPoints()
  f.AutoOpenCheckbox.text:SetPoint("RIGHT", f.AutoOpenCheckbox, "LEFT", -2, 0)
  f.AutoOpenCheckbox.text:SetFontObject("CulteDKPSmallLeft")
  f.AutoOpenCheckbox:SetPoint("TOP", f.CancelBid, "BOTTOMRIGHT", 5, -53)
  f.AutoOpenCheckbox:SetScript("OnClick", function(self)
    core.DB.defaults.AutoOpenBid = self:GetChecked()
  end)
  f.AutoOpenCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  f.AutoOpenCheckbox:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)


  --------------------------------------------------
  -- Bid Table
  --------------------------------------------------
  f.bidTable = CreateFrame("ScrollFrame", "CulteDKP_BiderWindowTable", f, "FauxScrollFrameTemplate")
  f.bidTable:SetSize(width, height*numrows+3)

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.bidTable:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
    });
    f.bidTable:SetBackdropColor(0,0,0,0.2)
    f.bidTable:SetBackdropBorderColor(1,1,1,0.4)
  end
  
  f.bidTable.ScrollBar = FauxScrollFrame_GetChildFrames(f.bidTable)
  f.bidTable.ScrollBar:Hide()
  f.bidTable.Rows = {}
  for i=1, numrows do
      f.bidTable.Rows[i] = BidWindowCreateRow(f.bidTable, i)
      if i==1 then
        f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable, "TOPLEFT", 0, -3)
      else  
        f.bidTable.Rows[i]:SetPoint("TOPLEFT", f.bidTable.Rows[i-1], "BOTTOMLEFT")
      end
  end
  f.bidTable:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, height, BidderScrollFrame_Update)
  end)

  ---------------------------------------
  -- Header Buttons
  --------------------------------------- 
  f.headerButtons = {}
  mode = core.DB.modes.mode;

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.BidTable_Headers = CreateFrame("Frame", "CulteDKPBidderTableHeaders", f.bidTable)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f.BidTable_Headers = CreateFrame("Frame", "CulteDKPBidderTableHeaders", f.bidTable, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  f.BidTable_Headers:SetSize(370, 22)
  f.BidTable_Headers:SetPoint("BOTTOMLEFT", f.bidTable, "TOPLEFT", 0, 1)
  f.BidTable_Headers:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
  });
  f.BidTable_Headers:SetBackdropColor(0,0,0,0.8);
  f.BidTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
  f.bidTable:SetPoint("BOTTOM", f, "BOTTOM", 0, 15)
  f.BidTable_Headers:Show()

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    f.headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers)
    f.headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers)
    f.headerButtons.spec = CreateFrame("Button", "$ParentButtonSpec", f.BidTable_Headers)
    f.headerButtons.dkp = CreateFrame("Button", "$ParentButtonDkp", f.BidTable_Headers)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    f.headerButtons.player = CreateFrame("Button", "$ParentButtonPlayer", f.BidTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f.headerButtons.bid = CreateFrame("Button", "$ParentButtonBid", f.BidTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f.headerButtons.spec = CreateFrame("Button", "$ParentButtonSpec", f.BidTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
    f.headerButtons.dkp = CreateFrame("Button", "$ParentButtonDkp", f.BidTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end

  f.headerButtons.player:SetPoint("LEFT", f.BidTable_Headers, "LEFT", 2, 0)
  f.headerButtons.bid:SetPoint("LEFT", f.headerButtons.player, "RIGHT", 0, 0)
  f.headerButtons.spec:SetPoint("LEFT", f.headerButtons.player, "RIGHT", 0, 0)
  f.headerButtons.dkp:SetPoint("RIGHT", f.BidTable_Headers, "RIGHT", -1, 0)

  f.headerButtons.player.t = f.headerButtons.player:CreateFontString(nil, "OVERLAY")
  f.headerButtons.player.t:SetFontObject("CulteDKPNormalLeft")
  f.headerButtons.player.t:SetTextColor(1, 1, 1, 1);
  f.headerButtons.player.t:SetPoint("LEFT", f.headerButtons.player, "LEFT", 20, 0);
  f.headerButtons.player.t:SetText(L["PLAYER"]); 

  f.headerButtons.bid.t = f.headerButtons.bid:CreateFontString(nil, "OVERLAY")
  f.headerButtons.bid.t:SetFontObject("CulteDKPNormal");
  f.headerButtons.bid.t:SetTextColor(1, 1, 1, 1);
  f.headerButtons.bid.t:SetPoint("CENTER", f.headerButtons.bid, "CENTER", 0, 0);

  f.headerButtons.spec.t = f.headerButtons.dkp:CreateFontString(nil, "OVERLAY")
  f.headerButtons.spec.t:SetFontObject("CulteDKPNormal")
  f.headerButtons.spec.t:SetTextColor(1, 1, 1, 1);
  f.headerButtons.spec.t:SetPoint("CENTER", f.headerButtons.dkp, "CENTER", 0, 0);

  f.headerButtons.dkp.t = f.headerButtons.dkp:CreateFontString(nil, "OVERLAY")
  f.headerButtons.dkp.t:SetFontObject("CulteDKPNormal")
  f.headerButtons.dkp.t:SetTextColor(1, 1, 1, 1);
  f.headerButtons.dkp.t:SetPoint("CENTER", f.headerButtons.dkp, "CENTER", 0, 0);

  if not core.DB.modes.BroadcastBids then
    f.bidTable:Hide();
    if mode == "Minimum Bid Values" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      f:SetHeight(259);
    else
      f:SetHeight(231);
    end
  end;     --hides table if broadcasting is set to false.

  f:Hide();

  f:SetScript("OnHide", function ()
    if core.BiddingInProgress then
      CulteDKP:Print(L["CLOSEDBIDINPROGRESS"])
    end
    if CulteDKP.BidTimer:IsShown() then
      CulteDKP.BidTimer.OpenBid:Show()
    end
  end)

  return f;
end
