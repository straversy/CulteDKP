local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");
local moveTimerToggle = 0;
local validating = false

local function DrawPercFrame(box)
  --Draw % signs if set to percent
  CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetFontObject("CulteDKPNormalLeft");
  CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetPoint("LEFT", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box], "RIGHT", -15, 0);
  CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[box].perc:SetText("%")
  
  if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
    CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box]:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetFontObject("CulteDKPNormalLeft");
    CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetPoint("LEFT", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box], "RIGHT", -15, 0);
    CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[box].perc:SetText("%")
  end
end

local function SaveSettings()
  if CulteDKP.ConfigTab4.default[1] then
    core.DB.DKPBonus.OnTimeBonus = CulteDKP.ConfigTab4.default[1]:GetNumber();
    core.DB.DKPBonus.BossKillBonus = CulteDKP.ConfigTab4.default[2]:GetNumber();
    core.DB.DKPBonus.CompletionBonus = CulteDKP.ConfigTab4.default[3]:GetNumber();
    core.DB.DKPBonus.NewBossKillBonus = CulteDKP.ConfigTab4.default[4]:GetNumber();
    core.DB.DKPBonus.UnexcusedAbsence = CulteDKP.ConfigTab4.default[5]:GetNumber();
    if CulteDKP.ConfigTab4.default[6]:GetNumber() < 0 then
      core.DB.DKPBonus.DecayPercentage = 0 - CulteDKP.ConfigTab4.default[6]:GetNumber();
    else
      core.DB.DKPBonus.DecayPercentage = CulteDKP.ConfigTab4.default[6]:GetNumber();
    end
    CulteDKP.ConfigTab2.decayDKP:SetNumber(core.DB.DKPBonus.DecayPercentage);
    CulteDKP.ConfigTab4.default[6]:SetNumber(core.DB.DKPBonus.DecayPercentage)
    core.DB.DKPBonus.BidTimer = CulteDKP.ConfigTab4.bidTimer:GetNumber();

    core.DB.MinBidBySlot.Head = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:GetNumber()
    core.DB.MinBidBySlot.Neck = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:GetNumber()
    core.DB.MinBidBySlot.Shoulders = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:GetNumber()
    core.DB.MinBidBySlot.Cloak = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:GetNumber()
    core.DB.MinBidBySlot.Chest = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:GetNumber()
    core.DB.MinBidBySlot.Bracers = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:GetNumber()
    core.DB.MinBidBySlot.Hands = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:GetNumber()
    core.DB.MinBidBySlot.Belt = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:GetNumber()
    core.DB.MinBidBySlot.Legs = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:GetNumber()
    core.DB.MinBidBySlot.Boots = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:GetNumber()
    core.DB.MinBidBySlot.Ring = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:GetNumber()
    core.DB.MinBidBySlot.Trinket = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:GetNumber()
    core.DB.MinBidBySlot.OneHanded = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:GetNumber()
    core.DB.MinBidBySlot.TwoHanded = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:GetNumber()
    core.DB.MinBidBySlot.OffHand = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:GetNumber()
    core.DB.MinBidBySlot.Range = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:GetNumber()
    core.DB.MinBidBySlot.Other = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:GetNumber()
    if not CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18]:GetNumber() then
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18]:SetText("10")
    end
    core.DB.MinBidBySlot.OffSpec = CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18]:GetNumber()
    
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      core.DB.MaxBidBySlot.Head = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:GetNumber()
      core.DB.MaxBidBySlot.Neck = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:GetNumber()
      core.DB.MaxBidBySlot.Shoulders = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:GetNumber()
      core.DB.MaxBidBySlot.Cloak = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:GetNumber()
      core.DB.MaxBidBySlot.Chest = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:GetNumber()
      core.DB.MaxBidBySlot.Bracers = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:GetNumber()
      core.DB.MaxBidBySlot.Hands = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:GetNumber()
      core.DB.MaxBidBySlot.Belt = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:GetNumber()
      core.DB.MaxBidBySlot.Legs = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:GetNumber()
      core.DB.MaxBidBySlot.Boots = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:GetNumber()
      core.DB.MaxBidBySlot.Ring = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:GetNumber()
      core.DB.MaxBidBySlot.Trinket = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:GetNumber()
      core.DB.MaxBidBySlot.OneHanded = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:GetNumber()
      core.DB.MaxBidBySlot.TwoHanded = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:GetNumber()
      core.DB.MaxBidBySlot.OffHand = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:GetNumber()
      core.DB.MaxBidBySlot.Range = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:GetNumber()
      core.DB.MaxBidBySlot.Other = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:GetNumber()
      if not CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18]:GetNumber() then
        core.DB.MaxBidBySlot.OffSpec = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18]:SetText("10")
      end
      core.DB.MaxBidBySlot.OffSpec = CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18]:GetNumber()
      end
  end

  core.CulteDKPUI:SetScale(core.DB.defaults.CulteDKPScaleSize);
  core.DB.defaults.HistoryLimit = CulteDKP.ConfigTab4.history:GetNumber();
  core.DB.defaults.DKPHistoryLimit = CulteDKP.ConfigTab4.DKPHistory:GetNumber();
  core.DB.defaults.TooltipHistoryCount = CulteDKP.ConfigTab4.TooltipHistory:GetNumber();
  CulteDKP:DKPTable_Update()
end

function CulteDKP:Options()
  local default = {}
  CulteDKP.ConfigTab4.default = default;
  CulteDKP:CheckOfficer()
  CulteDKP.ConfigTab4.header = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.header:SetFontObject("CulteDKPLargeCenter");
  CulteDKP.ConfigTab4.header:SetPoint("TOPLEFT", CulteDKP.ConfigTab4, "TOPLEFT", 15, -10);
  CulteDKP.ConfigTab4.header:SetText(L["DEFAULTSETTINGS"]);
  CulteDKP.ConfigTab4.header:SetScale(1.2)

  if core.IsOfficer == true then
    CulteDKP.ConfigTab4.description = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.description:SetFontObject("CulteDKPNormalLeft");
    CulteDKP.ConfigTab4.description:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.header, "BOTTOMLEFT", 7, -15);
    CulteDKP.ConfigTab4.description:SetText("|CFFcca600"..L["DEFAULTDKPAWARDVALUES"].."|r");
  
    for i=1, 6 do
      if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        CulteDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
      else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
        CulteDKP.ConfigTab4.default[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
      end
            
      CulteDKP.ConfigTab4.default[i]:SetAutoFocus(false)
      CulteDKP.ConfigTab4.default[i]:SetMultiLine(false)
      CulteDKP.ConfigTab4.default[i]:SetSize(80, 24)
      CulteDKP.ConfigTab4.default[i]:SetBackdrop({
        bgFile   = "Textures\\white.blp", tile = true,
        edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
      });
      CulteDKP.ConfigTab4.default[i]:SetBackdropColor(0,0,0,0.9)
      CulteDKP.ConfigTab4.default[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
      CulteDKP.ConfigTab4.default[i]:SetMaxLetters(6)
      CulteDKP.ConfigTab4.default[i]:SetTextColor(1, 1, 1, 1)
      CulteDKP.ConfigTab4.default[i]:SetFontObject("CulteDKPSmallRight")
      CulteDKP.ConfigTab4.default[i]:SetTextInsets(10, 10, 5, 5)
      CulteDKP.ConfigTab4.default[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      CulteDKP.ConfigTab4.default[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
        self:HighlightText(0,0)
        SaveSettings()
        self:ClearFocus()
      end)
      CulteDKP.ConfigTab4.default[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
        SaveSettings()
        if i == 6 then
          self:HighlightText(0,0)
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetFocus()
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:HighlightText()
        else
          self:HighlightText(0,0)
          CulteDKP.ConfigTab4.default[i+1]:SetFocus()
          CulteDKP.ConfigTab4.default[i+1]:HighlightText()
        end
      end)
      CulteDKP.ConfigTab4.default[i]:SetScript("OnEnter", function(self)
        if (self.tooltipText) then
          GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
          GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
        end
        if (self.tooltipDescription) then
          GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
          GameTooltip:Show();
        end
        if (self.tooltipWarning) then
          GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
          GameTooltip:Show();
        end
      end)
      CulteDKP.ConfigTab4.default[i]:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
      end)

      if i==1 then
        CulteDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4, "TOPLEFT", 144, -84)
      elseif i==4 then
        CulteDKP.ConfigTab4.default[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.default[1], "TOPLEFT", 212, 0)
      else
        CulteDKP.ConfigTab4.default[i]:SetPoint("TOP", CulteDKP.ConfigTab4.default[i-1], "BOTTOM", 0, -22)
      end
    end

    -- Modes Button
    CulteDKP.ConfigTab4.ModesButton = self:CreateButton("TOPRIGHT", CulteDKP.ConfigTab4, "TOPRIGHT", -40, -20, L["DKPMODES"]);
    CulteDKP.ConfigTab4.ModesButton:SetSize(110,25)
    CulteDKP.ConfigTab4.ModesButton:SetScript("OnClick", function()
      CulteDKP:ToggleDKPModesWindow()
    end);
    CulteDKP.ConfigTab4.ModesButton:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["DKPMODES"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["DKPMODESTTDESC2"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["DKPMODESTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    CulteDKP.ConfigTab4.ModesButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    end)
    if not core.IsOfficer then
      CulteDKP.ConfigTab4.ModesButton:Hide()
    end
    CulteDKP.ConfigTab4.default[1]:SetText(core.DB.DKPBonus.OnTimeBonus)
    CulteDKP.ConfigTab4.default[1].tooltipText = L["ONTIMEBONUS"]
    CulteDKP.ConfigTab4.default[1].tooltipDescription = L["ONTIMEBONUSTTDESC"]
      
    CulteDKP.ConfigTab4.default[2]:SetText(core.DB.DKPBonus.BossKillBonus)
    CulteDKP.ConfigTab4.default[2].tooltipText = L["BOSSKILLBONUS"]
    CulteDKP.ConfigTab4.default[2].tooltipDescription = L["BOSSKILLBONUSTTDESC"]
       
    CulteDKP.ConfigTab4.default[3]:SetText(core.DB.DKPBonus.CompletionBonus)
    CulteDKP.ConfigTab4.default[3].tooltipText = L["RAIDCOMPLETIONBONUS"]
    CulteDKP.ConfigTab4.default[3].tooltipDescription = L["RAIDCOMPLETEBONUSTT"]
      
    CulteDKP.ConfigTab4.default[4]:SetText(core.DB.DKPBonus.NewBossKillBonus)
    CulteDKP.ConfigTab4.default[4].tooltipText = L["NEWBOSSKILLBONUS"]
    CulteDKP.ConfigTab4.default[4].tooltipDescription = L["NEWBOSSKILLTTDESC"]

    CulteDKP.ConfigTab4.default[5]:SetText(core.DB.DKPBonus.UnexcusedAbsence)
    CulteDKP.ConfigTab4.default[5]:SetNumeric(false)
    CulteDKP.ConfigTab4.default[5].tooltipText = L["UNEXCUSEDABSENCE"]
    CulteDKP.ConfigTab4.default[5].tooltipDescription = L["UNEXCUSEDTTDESC"]
    CulteDKP.ConfigTab4.default[5].tooltipWarning = L["UNEXCUSEDTTWARN"]

    CulteDKP.ConfigTab4.default[6]:SetText(core.DB.DKPBonus.DecayPercentage)
    CulteDKP.ConfigTab4.default[6]:SetTextInsets(0, 15, 0, 0)
    CulteDKP.ConfigTab4.default[6].tooltipText = L["DECAYPERCENTAGE"]
    CulteDKP.ConfigTab4.default[6].tooltipDescription = L["DECAYPERCENTAGETTDESC"]
    CulteDKP.ConfigTab4.default[6].tooltipWarning = L["DECAYPERCENTAGETTWARN"]

    --OnTimeBonus Header
    CulteDKP.ConfigTab4.OnTimeHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.OnTimeHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.OnTimeHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[1], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.OnTimeHeader:SetText(L["ONTIMEBONUS"]..": ")

    --BossKillBonus Header
    CulteDKP.ConfigTab4.BossKillHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.BossKillHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.BossKillHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[2], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.BossKillHeader:SetText(L["BOSSKILLBONUS"]..": ")

    --CompletionBonus Header
    CulteDKP.ConfigTab4.CompleteHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.CompleteHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.CompleteHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[3], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.CompleteHeader:SetText(L["RAIDCOMPLETIONBONUS"]..": ")

    --NewBossKillBonus Header
    CulteDKP.ConfigTab4.NewBossHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.NewBossHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.NewBossHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[4], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.NewBossHeader:SetText(L["NEWBOSSKILLBONUS"]..": ")

    --UnexcusedAbsence Header
    CulteDKP.ConfigTab4.UnexcusedHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.UnexcusedHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.UnexcusedHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[5], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.UnexcusedHeader:SetText(L["UNEXCUSEDABSENCE"]..": ")

    --DKP Decay Header
    CulteDKP.ConfigTab4.DecayHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.DecayHeader:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.DecayHeader:SetPoint("RIGHT", CulteDKP.ConfigTab4.default[6], "LEFT", 0, 0);
    CulteDKP.ConfigTab4.DecayHeader:SetText(L["DECAYAMOUNT"]..": ")

    CulteDKP.ConfigTab4.DecayFooter = CulteDKP.ConfigTab4.default[6]:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.DecayFooter:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.DecayFooter:SetPoint("LEFT", CulteDKP.ConfigTab4.default[6], "RIGHT", -15, -1);
    CulteDKP.ConfigTab4.DecayFooter:SetText("%")

    -- Default Minimum Bids Container Frame
    CulteDKP.ConfigTab4.DefaultMinBids = CreateFrame("Frame", nil, CulteDKP.ConfigTab4);
    CulteDKP.ConfigTab4.DefaultMinBids:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.default[3], "BOTTOMLEFT", -130, -52)
    CulteDKP.ConfigTab4.DefaultMinBids:SetSize(420, 410);

    CulteDKP.ConfigTab4.DefaultMinBids.description = CulteDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.DefaultMinBids.description:SetFontObject("CulteDKPSmallRight");
    CulteDKP.ConfigTab4.DefaultMinBids.description:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 15, 15);
      -- DEFAULT min bids Create EditBoxes
      local SlotBox = {}
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox = SlotBox;

      for i=1, 18 do

        if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
        else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
        end
        
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetAutoFocus(false)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMultiLine(false)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetSize(60, 24)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetMaxLetters(6)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetFontObject("CulteDKPSmallRight")
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            CulteDKP.ConfigTab4.default[1]:SetFocus()
            CulteDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnEnter", function(self)
          if (self.tooltipText) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
          end
          if (self.tooltipDescription) then
            GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
            GameTooltip:Show();
          end
          if (self.tooltipWarning) then
            GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
            GameTooltip:Show();
          end
        end)
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header = CulteDKP.ConfigTab4.DefaultMinBids:CreateFontString(nil, "OVERLAY")
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetFontObject("CulteDKPNormalLeft");
        CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i].Header:SetPoint("RIGHT", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMinBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8], "BOTTOM", 0, -22)
        elseif i==18 then
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16], "BOTTOM", 0, -22)
        else
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;
      if core.DB.modes.mode == "Minimum Bid Values" then
        prefix = L["MINIMUMBID"];
        CulteDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTMINBIDVALUES"].."|r");
      elseif core.DB.modes.mode == "Static Item Values" then
        CulteDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif core.DB.modes.mode == "Roll Based Bidding" then
        CulteDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      elseif core.DB.modes.mode == "Zero Sum" then
        CulteDKP.ConfigTab4.DefaultMinBids.description:SetText("|CFFcca600"..L["DEFAULTITEMCOSTS"].."|r");
        if core.DB.modes.costvalue == "Integer" then
          prefix = L["DKPPRICE"]
        elseif core.DB.modes.costvalue == "Percent" then
          prefix = L["PERCENTCOST"]
        end
      end
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1]:SetText(core.DB.MinBidBySlot.Head)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipText = L["HEAD"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[2]:SetText(core.DB.MinBidBySlot.Neck)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipText = L["NECK"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[3]:SetText(core.DB.MinBidBySlot.Shoulders)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[4]:SetText(core.DB.MinBidBySlot.Cloak)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipText = L["CLOAK"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[5]:SetText(core.DB.MinBidBySlot.Chest)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipText = L["CHEST"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[6]:SetText(core.DB.MinBidBySlot.Bracers)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipText = L["BRACERS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[7]:SetText(core.DB.MinBidBySlot.Hands)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipText = L["HANDS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8]:SetText(core.DB.MinBidBySlot.Belt)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipText = L["BELT"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9]:SetText(core.DB.MinBidBySlot.Legs)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipText = L["LEGS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[10]:SetText(core.DB.MinBidBySlot.Boots)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipText = L["BOOTS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[11]:SetText(core.DB.MinBidBySlot.Ring)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipText = L["RINGS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[12]:SetText(core.DB.MinBidBySlot.Trinket)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipText = L["TRINKET"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[13]:SetText(core.DB.MinBidBySlot.OneHanded)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14]:SetText(core.DB.MinBidBySlot.TwoHanded)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[15]:SetText(core.DB.MinBidBySlot.OffHand)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16]:SetText(core.DB.MinBidBySlot.Range)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipText = L["RANGE"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"]

      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17]:SetText(core.DB.MinBidBySlot.Other)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipText = L["OTHER"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"]

      --TODO 
      --core.DB.MinBidBySlot.OffSpec = 10;
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18].Header:SetText(L["OFFSPEC"]..": ")
      if not core.DB.MinBidBySlot.OffSpec then
        core.DB.MinBidBySlot.OffSpec = 10
      end
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18]:SetText(core.DB.MinBidBySlot.OffSpec)
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18].tooltipText = L["OFFSPEC"]
      CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18].tooltipDescription = prefix.." "..L["FOROFFSPEC"]

      if core.DB.modes.costvalue == "Percent" then
        for i=1, #CulteDKP.ConfigTab4.DefaultMinBids.SlotBox do
          DrawPercFrame(i)
          CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end
      -- Broadcast Minimum Bids Button
      CulteDKP.ConfigTab4.BroadcastMinBids = self:CreateButton("TOP", CulteDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      CulteDKP.ConfigTab4.BroadcastMinBids:ClearAllPoints();
      CulteDKP.ConfigTab4.BroadcastMinBids:SetPoint("LEFT", CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[18], "RIGHT", 41, 0)
      CulteDKP.ConfigTab4.BroadcastMinBids:SetSize(110,25)
      CulteDKP.ConfigTab4.BroadcastMinBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MINBIDS"] = {
          Text = L["BCASTMINBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, core.DB.MinBidBySlot)
            local teams = CulteDKP:GetGuildTeamList(true);
            local teamTable = {}
          
            for k, v in pairs(teams) do
              local teamIndex = tostring(v.index);
              table.insert(teamTable, {teamIndex, CulteDKP:GetTable(CulteDKP_MinBids, true, teamIndex)});
            end
            table.insert(temptable, teamTable);
            CulteDKP.Sync:SendData("CDKPMinBid", temptable)
            CulteDKP:Print(L["MINBIDVALUESSENT"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MINBIDS")
      end);
      CulteDKP.ConfigTab4.BroadcastMinBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      CulteDKP.ConfigTab4.BroadcastMinBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    -- Default Maximum Bids Container Frame
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      CulteDKP.ConfigTab4.DefaultMaxBids = CreateFrame("Frame", nil, CulteDKP.ConfigTab4);
      CulteDKP.ConfigTab4.DefaultMaxBids:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 0, -52)
      CulteDKP.ConfigTab4.DefaultMaxBids:SetSize(420, 410);

      CulteDKP.ConfigTab4.DefaultMaxBids.description = CulteDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
      CulteDKP.ConfigTab4.DefaultMaxBids.description:SetFontObject("CulteDKPSmallRight");
      CulteDKP.ConfigTab4.DefaultMaxBids.description:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 15, 15);

      -- DEFAULT Max bids Create EditBoxes
      local SlotBox = {}
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox = SlotBox;

      for i=1, 18 do
        if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
        else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i] = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
        end

        
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetAutoFocus(false)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMultiLine(false)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetSize(60, 24)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdrop({
          bgFile   = "Textures\\white.blp", tile = true,
          edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
        });
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropColor(0,0,0,0.9)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetMaxLetters(6)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextColor(1, 1, 1, 1)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetFontObject("CulteDKPSmallRight")
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(10, 10, 5, 5)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
          self:HighlightText(0,0)
          SaveSettings()
          self:ClearFocus()
        end)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnTabPressed", function(self)    -- clears focus on esc
          if i == 8 then
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:HighlightText()
            SaveSettings()
          elseif i == 5 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          elseif i == 13 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(200)
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:HighlightText()
            SaveSettings()
          elseif i == 17 then
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:HighlightText()
            SaveSettings()
          elseif i == 16 then
            self:HighlightText(0,0)
            CulteDKP.UIConfig.TabMenu.ScrollFrame:SetVerticalScroll(1)
            CulteDKP.ConfigTab4.default[1]:SetFocus()
            CulteDKP.ConfigTab4.default[1]:HighlightText()
            SaveSettings()
          else
            self:HighlightText(0,0)
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:SetFocus()
            CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i+1]:HighlightText()
            SaveSettings()
          end
        end)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnEnter", function(self)
          if (self.tooltipText) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText(self.tooltipText, 0.25, 0.75, 0.90, 1, true);
          end
          if (self.tooltipDescription) then
            GameTooltip:AddLine(self.tooltipDescription, 1.0, 1.0, 1.0, true);
            GameTooltip:Show();
          end
          if (self.tooltipWarning) then
            GameTooltip:AddLine(self.tooltipWarning, 1.0, 0, 0, true);
            GameTooltip:Show();
          end
        end)
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)

        -- Slot Headers
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header = CulteDKP.ConfigTab4.DefaultMaxBids:CreateFontString(nil, "OVERLAY")
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetFontObject("CulteDKPNormalLeft");
        CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i].Header:SetPoint("RIGHT", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i], "LEFT", 0, 0);

        if i==1 then
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMaxBids, "TOPLEFT", 100, -10)
        elseif i==9 then
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1], "TOPLEFT", 150, 0)
        elseif i==17 then
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8], "BOTTOM", 0, -22)
        elseif i==18 then
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16], "BOTTOM", 0, -22)
        else
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetPoint("TOP", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i-1], "BOTTOM", 0, -22)
        end
      end

      local prefix;

      prefix = L["MAXIMUMBID"];
      CulteDKP.ConfigTab4.DefaultMaxBids.description:SetText("|CFFcca600"..L["DEFAULTMAXBIDVALUES"].."|r");

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].Header:SetText(L["HEAD"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1]:SetText(core.DB.MaxBidBySlot.Head)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipText = L["HEAD"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[1].tooltipDescription = prefix.." "..L["FORHEADSLOT"].." "..L["MAXIMUMBIDTTDESC"]
       
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].Header:SetText(L["NECK"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[2]:SetText(core.DB.MaxBidBySlot.Neck)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipText = L["NECK"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[2].tooltipDescription = prefix.." "..L["FORNECKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].Header:SetText(L["SHOULDERS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[3]:SetText(core.DB.MaxBidBySlot.Shoulders)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipText = L["SHOULDERS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[3].tooltipDescription = prefix.." "..L["FORSHOULDERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].Header:SetText(L["CLOAK"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[4]:SetText(core.DB.MaxBidBySlot.Cloak)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipText = L["CLOAK"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[4].tooltipDescription = prefix.." "..L["FORBACKSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].Header:SetText(L["CHEST"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[5]:SetText(core.DB.MaxBidBySlot.Chest)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipText = L["CHEST"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[5].tooltipDescription = prefix.." "..L["FORCHESTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].Header:SetText(L["BRACERS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[6]:SetText(core.DB.MaxBidBySlot.Bracers)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipText = L["BRACERS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[6].tooltipDescription = prefix.." "..L["FORWRISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].Header:SetText(L["HANDS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[7]:SetText(core.DB.MaxBidBySlot.Hands)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipText = L["HANDS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[7].tooltipDescription = prefix.." "..L["FORHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].Header:SetText(L["BELT"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8]:SetText(core.DB.MaxBidBySlot.Belt)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipText = L["BELT"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[8].tooltipDescription = prefix.." "..L["FORWAISTSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].Header:SetText(L["LEGS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9]:SetText(core.DB.MaxBidBySlot.Legs)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipText = L["LEGS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[9].tooltipDescription = prefix.." "..L["FORLEGSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].Header:SetText(L["BOOTS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[10]:SetText(core.DB.MaxBidBySlot.Boots)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipText = L["BOOTS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[10].tooltipDescription = prefix.." "..L["FORFEETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].Header:SetText(L["RINGS"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[11]:SetText(core.DB.MaxBidBySlot.Ring)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipText = L["RINGS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[11].tooltipDescription = prefix.." "..L["FORFINGERSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].Header:SetText(L["TRINKET"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[12]:SetText(core.DB.MaxBidBySlot.Trinket)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipText = L["TRINKET"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[12].tooltipDescription = prefix.." "..L["FORTRINKETSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].Header:SetText(L["ONEHANDED"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[13]:SetText(core.DB.MaxBidBySlot.OneHanded)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipText = L["ONEHANDEDWEAPONS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[13].tooltipDescription = prefix.." "..L["FORONEHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].Header:SetText(L["TWOHANDED"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14]:SetText(core.DB.MaxBidBySlot.TwoHanded)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipText = L["TWOHANDEDWEAPONS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[14].tooltipDescription = prefix.." "..L["FORTWOHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].Header:SetText(L["OFFHAND"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[15]:SetText(core.DB.MaxBidBySlot.OffHand)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipText = L["OFFHANDITEMS"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[15].tooltipDescription = prefix.." "..L["FOROFFHANDSLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].Header:SetText(L["RANGE"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16]:SetText(core.DB.MaxBidBySlot.Range)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipText = L["RANGE"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[16].tooltipDescription = prefix.." "..L["FORRANGESLOT"].." "..L["MAXIMUMBIDTTDESC"]

      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].Header:SetText(L["OTHER"]..": ")
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17]:SetText(core.DB.MaxBidBySlot.Other)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipText = L["OTHER"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17].tooltipDescription = prefix.." "..L["FOROTHERSLOT"].." "..L["MAXIMUMBIDTTDESC"]
	  
      --core.DB.MaxBidBySlot.OffSpec = 10;
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18].Header:SetText(L["OFFSPEC"]..": ")
      if not core.DB.MaxBidBySlot.OffSpec then
        core.DB.MaxBidBySlot.OffSpec = 10
      end
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18]:SetText(core.DB.MaxBidBySlot.OffSpec)
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18].tooltipText = L["OFFSPEC"]
      CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[18].tooltipDescription = prefix.." "..L["FOROFFSPEC"]
      
      if core.DB.modes.costvalue == "Percent" then
        for i=1, #CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox do
          DrawPercFrame(i)
          CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[i]:SetTextInsets(0, 15, 0, 0)
        end
      end
      -- Broadcast Maximum Bids Button
      CulteDKP.ConfigTab4.BroadcastMaxBids = self:CreateButton("TOP", CulteDKP.ConfigTab4, "BOTTOM", 30, 30, L["BCASTVALUES"]);
      CulteDKP.ConfigTab4.BroadcastMaxBids:ClearAllPoints();
      CulteDKP.ConfigTab4.BroadcastMaxBids:SetPoint("LEFT", CulteDKP.ConfigTab4.DefaultMaxBids.SlotBox[17], "RIGHT", 41, 0)
      CulteDKP.ConfigTab4.BroadcastMaxBids:SetSize(110,25)
      CulteDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnClick", function()
        StaticPopupDialogs["SEND_MAXBIDS"] = {
          Text = L["BCASTMAXBIDCONFIRM"],
          button1 = L["YES"],
          button2 = L["NO"],
          OnAccept = function()
            local temptable = {}
            table.insert(temptable, core.DB.MaxBidBySlot)
            local teams = CulteDKP:GetGuildTeamList(true);
            local teamTable = {}
          
            for k, v in pairs(teams) do
              local teamIndex = tostring(v.index);
              table.insert(teamTable, {teamIndex, CulteDKP:GetTable(CulteDKP_MaxBids, true, teamIndex)});
            end
            table.insert(temptable, teamTable);
            CulteDKP.Sync:SendData("CDKPMaxBid", temptable)
            CulteDKP:Print(L["MAXBIDVALUESSENT"])
          end,
          timeout = 0,
          whileDead = true,
          hideOnEscape = true,
          preferredIndex = 3,
        }
        StaticPopup_Show ("SEND_MAXBIDS")
      end);
      CulteDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["BCASTVALUES"], 0.25, 0.75, 0.90, 1, true)
        GameTooltip:AddLine(L["BCASTVALUESTTDESC"], 1.0, 1.0, 1.0, true);
        GameTooltip:AddLine(L["BCASTVALUESTTWARN"], 1.0, 0, 0, true);
        GameTooltip:Show()
      end)
      CulteDKP.ConfigTab4.BroadcastMaxBids:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
    end
    -- Bid Timer Slider
    CulteDKP.ConfigTab4.bidTimerSlider = CreateFrame("SLIDER", "$parentBidTimerSlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");

    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	  -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
      Mixin(CulteDKP.ConfigTab4.bidTimerSlider, BackdropTemplateMixin)
    end
    
  CulteDKP.ConfigTab4.bidTimerSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
    if core.DB.modes.mode == "Minimum Bid Values" or (core.DB.modes.mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Minimum Bid") then
      CulteDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMaxBids, "BOTTOMLEFT", 54, -40);
    else
      CulteDKP.ConfigTab4.bidTimerSlider:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DefaultMinBids, "BOTTOMLEFT", 54, -40);
    end
    CulteDKP.ConfigTab4.bidTimerSlider:SetMinMaxValues(10, 90);
    CulteDKP.ConfigTab4.bidTimerSlider:SetValue(core.DB.DKPBonus.BidTimer);
    CulteDKP.ConfigTab4.bidTimerSlider:SetValueStep(1);
    CulteDKP.ConfigTab4.bidTimerSlider.tooltipText = L["BIDTIMER"]
    CulteDKP.ConfigTab4.bidTimerSlider.tooltipRequirement = L["BIDTIMERDEFAULTTTDESC"]
    CulteDKP.ConfigTab4.bidTimerSlider:SetObeyStepOnDrag(true);
    getglobal(CulteDKP.ConfigTab4.bidTimerSlider:GetName().."Low"):SetText("10")
    getglobal(CulteDKP.ConfigTab4.bidTimerSlider:GetName().."High"):SetText("90")
    CulteDKP.ConfigTab4.bidTimerSlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
      CulteDKP.ConfigTab4.bidTimer:SetText(CulteDKP.ConfigTab4.bidTimerSlider:GetValue())
    end)

    CulteDKP.ConfigTab4.bidTimerHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
    CulteDKP.ConfigTab4.bidTimerHeader:SetFontObject("CulteDKPTinyCenter");
    CulteDKP.ConfigTab4.bidTimerHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.bidTimerSlider, "TOP", 0, 3);
    CulteDKP.ConfigTab4.bidTimerHeader:SetText(L["BIDTIMER"])

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
      CulteDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
    else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
      CulteDKP.ConfigTab4.bidTimer = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
    end
    
    CulteDKP.ConfigTab4.bidTimer:SetAutoFocus(false)
    CulteDKP.ConfigTab4.bidTimer:SetMultiLine(false)
    CulteDKP.ConfigTab4.bidTimer:SetSize(50, 18)
    CulteDKP.ConfigTab4.bidTimer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
    });
    CulteDKP.ConfigTab4.bidTimer:SetBackdropColor(0,0,0,0.9)
    CulteDKP.ConfigTab4.bidTimer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
    CulteDKP.ConfigTab4.bidTimer:SetMaxLetters(4)
    CulteDKP.ConfigTab4.bidTimer:SetTextColor(1, 1, 1, 1)
    CulteDKP.ConfigTab4.bidTimer:SetFontObject("CulteDKPTinyCenter")
    CulteDKP.ConfigTab4.bidTimer:SetTextInsets(10, 10, 5, 5)
    CulteDKP.ConfigTab4.bidTimer:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    CulteDKP.ConfigTab4.bidTimer:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
      self:ClearFocus()
    end)
    CulteDKP.ConfigTab4.bidTimer:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
      CulteDKP.ConfigTab4.bidTimerSlider:SetValue(CulteDKP.ConfigTab4.bidTimer:GetNumber());
    end)
    CulteDKP.ConfigTab4.bidTimer:SetPoint("TOP", CulteDKP.ConfigTab4.bidTimerSlider, "BOTTOM", 0, -3)     
    CulteDKP.ConfigTab4.bidTimer:SetText(CulteDKP.ConfigTab4.bidTimerSlider:GetValue())
  end -- the end

  -- Tooltip History Slider

  CulteDKP.ConfigTab4.TooltipHistorySlider = CreateFrame("SLIDER", "$parentTooltipHistorySlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");
  if CulteDKP.ConfigTab4.bidTimer then
    CulteDKP.ConfigTab4.TooltipHistorySlider:SetPoint("LEFT", CulteDKP.ConfigTab4.bidTimerSlider, "RIGHT", 30, 0);
  else
    CulteDKP.ConfigTab4.TooltipHistorySlider:SetPoint("TOP", CulteDKP.ConfigTab4, "TOP", 1, -107);
  end

  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    Mixin(CulteDKP.ConfigTab4.TooltipHistorySlider, BackdropTemplateMixin)
  end
  
  CulteDKP.ConfigTab4.TooltipHistorySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })

  CulteDKP.ConfigTab4.TooltipHistorySlider:SetMinMaxValues(5, 35);
  CulteDKP.ConfigTab4.TooltipHistorySlider:SetValue(core.DB.defaults.TooltipHistoryCount);
  CulteDKP.ConfigTab4.TooltipHistorySlider:SetValueStep(1);
  CulteDKP.ConfigTab4.TooltipHistorySlider.tooltipText = L["TTHISTORYCOUNT"]
  CulteDKP.ConfigTab4.TooltipHistorySlider.tooltipRequirement = L["TTHISTORYCOUNTTTDESC"]
  CulteDKP.ConfigTab4.TooltipHistorySlider:SetObeyStepOnDrag(true);
  getglobal(CulteDKP.ConfigTab4.TooltipHistorySlider:GetName().."Low"):SetText("5")
  getglobal(CulteDKP.ConfigTab4.TooltipHistorySlider:GetName().."High"):SetText("35")
  CulteDKP.ConfigTab4.TooltipHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.TooltipHistory:SetText(CulteDKP.ConfigTab4.TooltipHistorySlider:GetValue())
  end)

  CulteDKP.ConfigTab4.TooltipHistoryHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.TooltipHistoryHeader:SetFontObject("CulteDKPTinyCenter");
  CulteDKP.ConfigTab4.TooltipHistoryHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.TooltipHistorySlider, "TOP", 0, 3);
  CulteDKP.ConfigTab4.TooltipHistoryHeader:SetText(L["TTHISTORYCOUNT"])

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    CulteDKP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    CulteDKP.ConfigTab4.TooltipHistory = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  CulteDKP.ConfigTab4.TooltipHistory:SetAutoFocus(false)
  CulteDKP.ConfigTab4.TooltipHistory:SetMultiLine(false)
  CulteDKP.ConfigTab4.TooltipHistory:SetSize(50, 18)
  CulteDKP.ConfigTab4.TooltipHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CulteDKP.ConfigTab4.TooltipHistory:SetBackdropColor(0,0,0,0.9)
  CulteDKP.ConfigTab4.TooltipHistory:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  CulteDKP.ConfigTab4.TooltipHistory:SetMaxLetters(4)
  CulteDKP.ConfigTab4.TooltipHistory:SetTextColor(1, 1, 1, 1)
  CulteDKP.ConfigTab4.TooltipHistory:SetFontObject("CulteDKPTinyCenter")
  CulteDKP.ConfigTab4.TooltipHistory:SetTextInsets(10, 10, 5, 5)
  CulteDKP.ConfigTab4.TooltipHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.TooltipHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.TooltipHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.TooltipHistorySlider:SetValue(CulteDKP.ConfigTab4.TooltipHistory:GetNumber());
  end)
  CulteDKP.ConfigTab4.TooltipHistory:SetPoint("TOP", CulteDKP.ConfigTab4.TooltipHistorySlider, "BOTTOM", 0, -3)     
  CulteDKP.ConfigTab4.TooltipHistory:SetText(CulteDKP.ConfigTab4.TooltipHistorySlider:GetValue())


  -- Loot History Limit Slider
  CulteDKP.ConfigTab4.historySlider = CreateFrame("SLIDER", "$parentHistorySlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");

  if CulteDKP.ConfigTab4.bidTimer then
    CulteDKP.ConfigTab4.historySlider:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.bidTimerSlider, "BOTTOMLEFT", 0, -50);
  else
    CulteDKP.ConfigTab4.historySlider:SetPoint("TOPRIGHT", CulteDKP.ConfigTab4.TooltipHistorySlider, "BOTTOMLEFT", 56, -49);
  end

  
  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    Mixin(CulteDKP.ConfigTab4.historySlider, BackdropTemplateMixin)
  end

  
  CulteDKP.ConfigTab4.historySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })

  CulteDKP.ConfigTab4.historySlider:SetMinMaxValues(100, 2500);
  CulteDKP.ConfigTab4.historySlider:SetValue(core.DB.defaults.HistoryLimit);
  CulteDKP.ConfigTab4.historySlider:SetValueStep(25);
  CulteDKP.ConfigTab4.historySlider.tooltipText = L["LOOTHISTORYLIMIT"]
  CulteDKP.ConfigTab4.historySlider.tooltipRequirement = L["LOOTHISTLIMITTTDESC"]
  CulteDKP.ConfigTab4.historySlider.tooltipWarning = L["LOOTHISTLIMITTTWARN"]
  CulteDKP.ConfigTab4.historySlider:SetObeyStepOnDrag(true);
  getglobal(CulteDKP.ConfigTab4.historySlider:GetName().."Low"):SetText("100")
  getglobal(CulteDKP.ConfigTab4.historySlider:GetName().."High"):SetText("2500")
  CulteDKP.ConfigTab4.historySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.history:SetText(CulteDKP.ConfigTab4.historySlider:GetValue())
  end)

  CulteDKP.ConfigTab4.HistoryHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.HistoryHeader:SetFontObject("CulteDKPTinyCenter");
  CulteDKP.ConfigTab4.HistoryHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.historySlider, "TOP", 0, 3);
  CulteDKP.ConfigTab4.HistoryHeader:SetText(L["LOOTHISTORYLIMIT"])

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    CulteDKP.ConfigTab4.history = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    CulteDKP.ConfigTab4.history = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
 
  CulteDKP.ConfigTab4.history:SetAutoFocus(false)
  CulteDKP.ConfigTab4.history:SetMultiLine(false)
  CulteDKP.ConfigTab4.history:SetSize(50, 18)
  CulteDKP.ConfigTab4.history:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CulteDKP.ConfigTab4.history:SetBackdropColor(0,0,0,0.9)
  CulteDKP.ConfigTab4.history:SetBackdropBorderColor(0.12,0.12, 0.34, 1)
  CulteDKP.ConfigTab4.history:SetMaxLetters(4)
  CulteDKP.ConfigTab4.history:SetTextColor(1, 1, 1, 1)
  CulteDKP.ConfigTab4.history:SetFontObject("CulteDKPTinyCenter")
  CulteDKP.ConfigTab4.history:SetTextInsets(10, 10, 5, 5)
  CulteDKP.ConfigTab4.history:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.history:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.history:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.historySlider:SetValue(CulteDKP.ConfigTab4.history:GetNumber());
  end)
  CulteDKP.ConfigTab4.history:SetPoint("TOP", CulteDKP.ConfigTab4.historySlider, "BOTTOM", 0, -3)     
  CulteDKP.ConfigTab4.history:SetText(CulteDKP.ConfigTab4.historySlider:GetValue())

  -- DKP History Limit Slider
  CulteDKP.ConfigTab4.DKPHistorySlider = CreateFrame("SLIDER", "$parentDKPHistorySlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");

  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    Mixin(CulteDKP.ConfigTab4.DKPHistorySlider, BackdropTemplateMixin)
  end

  CulteDKP.ConfigTab4.DKPHistorySlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CulteDKP.ConfigTab4.DKPHistorySlider:SetPoint("LEFT", CulteDKP.ConfigTab4.historySlider, "RIGHT", 30, 0);
  CulteDKP.ConfigTab4.DKPHistorySlider:SetMinMaxValues(100, 2500);
  CulteDKP.ConfigTab4.DKPHistorySlider:SetValue(core.DB.defaults.DKPHistoryLimit);
  CulteDKP.ConfigTab4.DKPHistorySlider:SetValueStep(25);
  CulteDKP.ConfigTab4.DKPHistorySlider.tooltipText = L["DKPHISTORYLIMIT"]
  CulteDKP.ConfigTab4.DKPHistorySlider.tooltipRequirement = L["DKPHISTLIMITTTDESC"]
  CulteDKP.ConfigTab4.DKPHistorySlider.tooltipWarning = L["DKPHISTLIMITTTWARN"]
  CulteDKP.ConfigTab4.DKPHistorySlider:SetObeyStepOnDrag(true);
  getglobal(CulteDKP.ConfigTab4.DKPHistorySlider:GetName().."Low"):SetText("100")
  getglobal(CulteDKP.ConfigTab4.DKPHistorySlider:GetName().."High"):SetText("2500")
  CulteDKP.ConfigTab4.DKPHistorySlider:SetScript("OnValueChanged", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.DKPHistory:SetText(CulteDKP.ConfigTab4.DKPHistorySlider:GetValue())
  end)

  CulteDKP.ConfigTab4.DKPHistoryHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CulteDKPTinyCenter");
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.DKPHistorySlider, "TOP", 0, 3);
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetText(L["DKPHISTORYLIMIT"])

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    CulteDKP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    CulteDKP.ConfigTab4.DKPHistory = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  CulteDKP.ConfigTab4.DKPHistory:SetAutoFocus(false)
  CulteDKP.ConfigTab4.DKPHistory:SetMultiLine(false)
  CulteDKP.ConfigTab4.DKPHistory:SetSize(50, 18)
  CulteDKP.ConfigTab4.DKPHistory:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CulteDKP.ConfigTab4.DKPHistory:SetBackdropColor(0,0,0,0.9)
  CulteDKP.ConfigTab4.DKPHistory:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CulteDKP.ConfigTab4.DKPHistory:SetMaxLetters(4)
  CulteDKP.ConfigTab4.DKPHistory:SetTextColor(1, 1, 1, 1)
  CulteDKP.ConfigTab4.DKPHistory:SetFontObject("CulteDKPTinyCenter")
  CulteDKP.ConfigTab4.DKPHistory:SetTextInsets(10, 10, 5, 5)
  CulteDKP.ConfigTab4.DKPHistory:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.DKPHistory:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.DKPHistory:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.DKPHistorySlider:SetValue(CulteDKP.ConfigTab4.history:GetNumber());
  end)
  CulteDKP.ConfigTab4.DKPHistory:SetPoint("TOP", CulteDKP.ConfigTab4.DKPHistorySlider, "BOTTOM", 0, -3)     
  CulteDKP.ConfigTab4.DKPHistory:SetText(CulteDKP.ConfigTab4.DKPHistorySlider:GetValue())

  -- Bid Timer Size Slider
  CulteDKP.ConfigTab4.TimerSizeSlider = CreateFrame("SLIDER", "$parentBidTimerSizeSlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");

  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    Mixin(CulteDKP.ConfigTab4.TimerSizeSlider, BackdropTemplateMixin)
  end
 
  CulteDKP.ConfigTab4.TimerSizeSlider:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CulteDKP.ConfigTab4.TimerSizeSlider:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.historySlider, "BOTTOMLEFT", 0, -50);
  CulteDKP.ConfigTab4.TimerSizeSlider:SetMinMaxValues(0.5, 2.0);
  CulteDKP.ConfigTab4.TimerSizeSlider:SetValue(core.DB.defaults.BidTimerSize);
  CulteDKP.ConfigTab4.TimerSizeSlider:SetValueStep(0.05);
  CulteDKP.ConfigTab4.TimerSizeSlider.tooltipText = L["TIMERSIZE"]
  CulteDKP.ConfigTab4.TimerSizeSlider.tooltipRequirement = L["TIMERSIZETTDESC"]
  CulteDKP.ConfigTab4.TimerSizeSlider.tooltipWarning = L["TIMERSIZETTWARN"]
  CulteDKP.ConfigTab4.TimerSizeSlider:SetObeyStepOnDrag(true);
  getglobal(CulteDKP.ConfigTab4.TimerSizeSlider:GetName().."Low"):SetText("50%")
  getglobal(CulteDKP.ConfigTab4.TimerSizeSlider:GetName().."High"):SetText("200%")
  CulteDKP.ConfigTab4.TimerSizeSlider:SetScript("OnValueChanged", function(self)   
    CulteDKP.ConfigTab4.TimerSize:SetText(CulteDKP.ConfigTab4.TimerSizeSlider:GetValue())
    core.DB.defaults.BidTimerSize = CulteDKP.ConfigTab4.TimerSizeSlider:GetValue();
    CulteDKP.BidTimer:SetScale(core.DB.defaults.BidTimerSize);
  end)

  CulteDKP.ConfigTab4.DKPHistoryHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CulteDKPTinyCenter");
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.TimerSizeSlider, "TOP", 0, 3);
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetText(L["TIMERSIZE"])

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    CulteDKP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    CulteDKP.ConfigTab4.TimerSize = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end

  
  CulteDKP.ConfigTab4.TimerSize:SetAutoFocus(false)
  CulteDKP.ConfigTab4.TimerSize:SetMultiLine(false)
  CulteDKP.ConfigTab4.TimerSize:SetSize(50, 18)
  CulteDKP.ConfigTab4.TimerSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CulteDKP.ConfigTab4.TimerSize:SetBackdropColor(0,0,0,0.9)
  CulteDKP.ConfigTab4.TimerSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CulteDKP.ConfigTab4.TimerSize:SetMaxLetters(4)
  CulteDKP.ConfigTab4.TimerSize:SetTextColor(1, 1, 1, 1)
  CulteDKP.ConfigTab4.TimerSize:SetFontObject("CulteDKPTinyCenter")
  CulteDKP.ConfigTab4.TimerSize:SetTextInsets(10, 10, 5, 5)
  CulteDKP.ConfigTab4.TimerSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.TimerSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.TimerSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.TimerSizeSlider:SetValue(CulteDKP.ConfigTab4.TimerSize:GetNumber());
  end)
  CulteDKP.ConfigTab4.TimerSize:SetPoint("TOP", CulteDKP.ConfigTab4.TimerSizeSlider, "BOTTOM", 0, -3)     
  CulteDKP.ConfigTab4.TimerSize:SetText(CulteDKP.ConfigTab4.TimerSizeSlider:GetValue())

  -- UI Scale Size Slider
  CulteDKP.ConfigTab4.CulteDKPScaleSize = CreateFrame("SLIDER", "$parentCulteDKPScaleSizeSlider", CulteDKP.ConfigTab4, "CulteDKPOptionsSliderTemplate");

  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
	-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    Mixin(CulteDKP.ConfigTab4.CulteDKPScaleSize, BackdropTemplateMixin)
  end
  
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 3, right = 3, top = 6, bottom = 6 }
  })
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.DKPHistorySlider, "BOTTOMLEFT", 0, -50);
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetMinMaxValues(0.5, 2.0);
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetValue(core.DB.defaults.CulteDKPScaleSize);
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetValueStep(0.05);
  CulteDKP.ConfigTab4.CulteDKPScaleSize.tooltipText = L["CulteDKPSCALESIZE"]
  CulteDKP.ConfigTab4.CulteDKPScaleSize.tooltipRequirement = L["CulteDKPSCALESIZETTDESC"]
  CulteDKP.ConfigTab4.CulteDKPScaleSize.tooltipWarning = L["CulteDKPSCALESIZETTWARN"]
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetObeyStepOnDrag(true);
  getglobal(CulteDKP.ConfigTab4.CulteDKPScaleSize:GetName().."Low"):SetText("50%")
  getglobal(CulteDKP.ConfigTab4.CulteDKPScaleSize:GetName().."High"):SetText("200%")
  CulteDKP.ConfigTab4.CulteDKPScaleSize:SetScript("OnValueChanged", function(self)   
    CulteDKP.ConfigTab4.UIScaleSize:SetText(CulteDKP.ConfigTab4.CulteDKPScaleSize:GetValue())
    core.DB.defaults.CulteDKPScaleSize = CulteDKP.ConfigTab4.CulteDKPScaleSize:GetValue();
  end)

  CulteDKP.ConfigTab4.DKPHistoryHeader = CulteDKP.ConfigTab4:CreateFontString(nil, "OVERLAY")
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetFontObject("CulteDKPTinyCenter");
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetPoint("BOTTOM", CulteDKP.ConfigTab4.CulteDKPScaleSize, "TOP", 0, 3);
  CulteDKP.ConfigTab4.DKPHistoryHeader:SetText(L["MAINGUISIZE"])

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    CulteDKP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4)
  else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
    CulteDKP.ConfigTab4.UIScaleSize = CreateFrame("EditBox", nil, CulteDKP.ConfigTab4, BackdropTemplateMixin and "BackdropTemplate" or nil)
  end
  
  CulteDKP.ConfigTab4.UIScaleSize:SetAutoFocus(false)
  CulteDKP.ConfigTab4.UIScaleSize:SetMultiLine(false)
  CulteDKP.ConfigTab4.UIScaleSize:SetSize(50, 18)
  CulteDKP.ConfigTab4.UIScaleSize:SetBackdrop({
    bgFile   = "Textures\\white.blp", tile = true,
    edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
  });
  CulteDKP.ConfigTab4.UIScaleSize:SetBackdropColor(0,0,0,0.9)
  CulteDKP.ConfigTab4.UIScaleSize:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
  CulteDKP.ConfigTab4.UIScaleSize:SetMaxLetters(4)
  CulteDKP.ConfigTab4.UIScaleSize:SetTextColor(1, 1, 1, 1)
  CulteDKP.ConfigTab4.UIScaleSize:SetFontObject("CulteDKPTinyCenter")
  CulteDKP.ConfigTab4.UIScaleSize:SetTextInsets(10, 10, 5, 5)
  CulteDKP.ConfigTab4.UIScaleSize:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.UIScaleSize:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
    self:ClearFocus()
  end)
  CulteDKP.ConfigTab4.UIScaleSize:SetScript("OnEditFocusLost", function(self)    -- clears focus on esc
    CulteDKP.ConfigTab4.CulteDKPScaleSize:SetValue(CulteDKP.ConfigTab4.UIScaleSize:GetNumber());
  end)
  CulteDKP.ConfigTab4.UIScaleSize:SetPoint("TOP", CulteDKP.ConfigTab4.CulteDKPScaleSize, "BOTTOM", 0, -3)     
  CulteDKP.ConfigTab4.UIScaleSize:SetText(CulteDKP.ConfigTab4.CulteDKPScaleSize:GetValue())

  -- Suppress Broadcast Notifications checkbox
  CulteDKP.ConfigTab4.SuppressNotifications = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
  CulteDKP.ConfigTab4.SuppressNotifications:SetPoint("TOP", CulteDKP.ConfigTab4.TimerSizeSlider, "BOTTOMLEFT", 0, -35)
  CulteDKP.ConfigTab4.SuppressNotifications:SetChecked(core.DB.defaults.SuppressNotifications)
  CulteDKP.ConfigTab4.SuppressNotifications:SetScale(0.8)
  CulteDKP.ConfigTab4.SuppressNotifications.Text:SetText("|cff5151de"..L["SUPPRESSNOTIFICATIONS"].."|r");
  CulteDKP.ConfigTab4.SuppressNotifications.Text:SetFontObject("CulteDKPSmall")
  CulteDKP.ConfigTab4.SuppressNotifications:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["SUPPRESSNOTIFICATIONS"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["SUPPRESSNOTIFYTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  CulteDKP.ConfigTab4.SuppressNotifications:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  CulteDKP.ConfigTab4.SuppressNotifications:SetScript("OnClick", function()
    if CulteDKP.ConfigTab4.SuppressNotifications:GetChecked() then
      CulteDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cffff0000"..L["HIDDEN"].."|r.")
      core.DB["defaults"]["SuppressNotifications"] = true;
    else
      core.DB["defaults"]["SuppressNotifications"] = false;
      CulteDKP:Print(L["NOTIFICATIONSLIKETHIS"].." |cff00ff00"..L["VISIBLE"].."|r.")
    end
    PlaySound(808)
  end)

  -- Combat Logging checkbox
  CulteDKP.ConfigTab4.CombatLogging = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
  CulteDKP.ConfigTab4.CombatLogging:SetPoint("TOP", CulteDKP.ConfigTab4.SuppressNotifications, "BOTTOM", 0, 0)
  CulteDKP.ConfigTab4.CombatLogging:SetChecked(core.DB.defaults.AutoLog)
  CulteDKP.ConfigTab4.CombatLogging:SetScale(0.8)
  CulteDKP.ConfigTab4.CombatLogging.Text:SetText("|cff5151de"..L["AUTOCOMBATLOG"].."|r");
  CulteDKP.ConfigTab4.CombatLogging.Text:SetFontObject("CulteDKPSmall")
  CulteDKP.ConfigTab4.CombatLogging:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["AUTOCOMBATLOG"], 0.25, 0.75, 0.90, 1, true)
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:AddLine(L["AUTOCOMBATLOGTTWARN"], 1.0, 0, 0, true);
    GameTooltip:Show()
  end)
  CulteDKP.ConfigTab4.CombatLogging:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  CulteDKP.ConfigTab4.CombatLogging:SetScript("OnClick", function(self)
    core.DB.defaults.AutoLog = self:GetChecked()
    PlaySound(808)
  end)

  if core.DB.defaults.AutoOpenBid == nil then
    core.DB.defaults.AutoOpenBid = true
  end

  CulteDKP.ConfigTab4.AutoOpenCheckbox = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetChecked(core.DB.defaults.AutoOpenBid)
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetScale(0.8);
  CulteDKP.ConfigTab4.AutoOpenCheckbox.Text:SetText("|cff5151de"..L["AUTOOPEN"].."|r");
  CulteDKP.ConfigTab4.AutoOpenCheckbox.Text:SetScale(1);
  CulteDKP.ConfigTab4.AutoOpenCheckbox.Text:SetFontObject("CulteDKPSmallLeft")
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetPoint("TOP", CulteDKP.ConfigTab4.CombatLogging, "BOTTOM", 0, 0);
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnClick", function(self)
    core.DB.defaults.AutoOpenBid = self:GetChecked()
  end)
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    GameTooltip:SetText(L["AUTOOPEN"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["AUTOOPENTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  CulteDKP.ConfigTab4.AutoOpenCheckbox:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)

  if core.IsOfficer == true then
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetChecked(core.DB.defaults.AutoAwardLoot)
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetScale(0.8);
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox.Text:SetText("|cff5151de"..L["AUTOAWARDLOOT"].."|r");
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox.Text:SetScale(1);
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox.Text:SetFontObject("CulteDKPSmallLeft")
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetPoint("TOP", CulteDKP.ConfigTab4.AutoOpenCheckbox, "BOTTOM", 0, 0);
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetScript("OnClick", function(self)
      core.DB.defaults.AutoAwardLoot = self:GetChecked()

      if core.DB.defaults.AutoAwardLoot == false then
        core.DB.pendingLoot = {}
      end

    end)
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT");
      GameTooltip:SetText(L["AUTOAWARDLOOT"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["AUTOAWARDLOOTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:Show();
    end)
    CulteDKP.ConfigTab4.AutoAwardLootCheckbox:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
    
    -- Suppress Broadcast Notifications checkbox
    CulteDKP.ConfigTab4.SuppressTells = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
    CulteDKP.ConfigTab4.SuppressTells:SetPoint("LEFT", CulteDKP.ConfigTab4.SuppressNotifications, "RIGHT", 200, 0)
    CulteDKP.ConfigTab4.SuppressTells:SetChecked(core.DB.defaults.SuppressTells)
    CulteDKP.ConfigTab4.SuppressTells:SetScale(0.8)
    CulteDKP.ConfigTab4.SuppressTells.Text:SetText("|cff5151de"..L["SUPPRESSBIDWHISP"].."|r");
    CulteDKP.ConfigTab4.SuppressTells.Text:SetFontObject("CulteDKPSmall")
    CulteDKP.ConfigTab4.SuppressTells:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(L["SUPPRESSBIDWHISP"], 0.25, 0.75, 0.90, 1, true)
      GameTooltip:AddLine(L["SuppressBIDWHISPTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:AddLine(L["SuppressBIDWHISPTTWARN"], 1.0, 0, 0, true);
      GameTooltip:Show()
    end)
    CulteDKP.ConfigTab4.SuppressTells:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    CulteDKP.ConfigTab4.SuppressTells:SetScript("OnClick", function()
      if CulteDKP.ConfigTab4.SuppressTells:GetChecked() then
        CulteDKP:Print(L["BIDWHISPARENOW"].." |cffff0000"..L["HIDDEN"].."|r.")
        core.DB["defaults"]["SuppressTells"] = true;
      else
        core.DB["defaults"]["SuppressTells"] = false;
        CulteDKP:Print(L["BIDWHISPARENOW"].." |cff00ff00"..L["VISIBLE"].."|r.")
      end
      PlaySound(808)
    end)

    if core.DB.defaults.DecreaseDisenchantValue == nil then
      core.DB.defaults.DecreaseDisenchantValue = false
    end
  
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab4, "UICheckButtonTemplate");
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetPoint("LEFT", CulteDKP.ConfigTab4.CombatLogging, "RIGHT", 200, 0)
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetChecked(core.DB.defaults.DecreaseDisenchantValue)
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScale(0.8);
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox.Text:SetText("|cff5151de"..L["DECREASEDISENCHANT"].."|r");
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox.Text:SetFontObject("CulteDKPSmall")
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnClick", function(self)
      core.DB.defaults.DecreaseDisenchantValue = self:GetChecked()
    end)
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_LEFT");
      GameTooltip:SetText(L["DECREASEDISENCHANT"], 0.25, 0.75, 0.90, 1, true);
      GameTooltip:AddLine(L["DECREASEDISENCHANTTTDESC"], 1.0, 1.0, 1.0, true);
      GameTooltip:Show();
    end)
    CulteDKP.ConfigTab4.DecreaseDisenchantCheckbox:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)
  
  end

  -- Save Settings Button
  CulteDKP.ConfigTab4.submitSettings = self:CreateButton("BOTTOMLEFT", CulteDKP.ConfigTab4, "BOTTOMLEFT", 30, 30, L["SAVESETTINGS"]);
  CulteDKP.ConfigTab4.submitSettings:ClearAllPoints();
  CulteDKP.ConfigTab4.submitSettings:SetPoint("TOP", CulteDKP.ConfigTab4.AutoOpenCheckbox, "BOTTOMLEFT", 20, -40)
  CulteDKP.ConfigTab4.submitSettings:SetSize(90,25)
  CulteDKP.ConfigTab4.submitSettings:SetScript("OnClick", function()
    if core.IsOfficer == true then
      for i=1, 6 do
        if not tonumber(CulteDKP.ConfigTab4.default[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            Text = L["INVALIDOPTIONENTRY"].." "..CulteDKP.ConfigTab4.default[i].tooltipText..". "..L["PLEASEUSENUMS"],
            button1 = L["OK"],
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show ("OPTIONS_VALIDATION")

        return;
        end
      end
      for i=1, 17 do
        if not tonumber(CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i]:GetText()) then
          StaticPopupDialogs["OPTIONS_VALIDATION"] = {
            Text = L["INVALIDMINBIDENTRY"].." "..CulteDKP.ConfigTab4.DefaultMinBids.SlotBox[i].tooltipText..". "..L["PLEASEUSENUMS"],
            button1 = L["OK"],
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
          }
          StaticPopup_Show ("OPTIONS_VALIDATION")

        return;
        end
      end
    end
    
    SaveSettings()
    CulteDKP:Print(L["DEFAULTSETSAVED"])
  end)

  -- Chatframe Selection 
  --CulteDKP.ConfigTab4.ChatFrame = CreateFrame("FRAME", "CulteDKPChatFrameSelectDropDown", CulteDKP.ConfigTab4, "CulteDKPUIDropDownMenuTemplate")
  CulteDKP.ConfigTab4.ChatFrame = LibDD:Create_UIDropDownMenu("CulteDKPChatFrameSelectDropDown", CulteDKP.ConfigTab4);
  if not core.DB.defaults.ChatFrames then core.DB.defaults.ChatFrames = {} end

  LibDD:UIDropDownMenu_Initialize(CulteDKP.ConfigTab4.ChatFrame, function(self, level, menuList)
    
  local SelectedFrame = LibDD:UIDropDownMenu_CreateInfo()
    SelectedFrame.func = self.SetValue
    SelectedFrame.fontObject = "CulteDKPSmallCenter"
    SelectedFrame.keepShownOnClick = true;
    SelectedFrame.isNotRadio = true;

    for i = 1, NUM_CHAT_WINDOWS do
      local name = GetChatWindowInfo(i)
      if name ~= "" then
        SelectedFrame.Text, SelectedFrame.arg1, SelectedFrame.checked = name, name, core.DB.defaults.ChatFrames[name]
        LibDD:UIDropDownMenu_AddButton(SelectedFrame)
      end
    end
  end)

  CulteDKP.ConfigTab4.ChatFrame:SetPoint("LEFT", CulteDKP.ConfigTab4.AutoOpenCheckbox, "RIGHT", 130, 0)
  LibDD:UIDropDownMenu_SetWidth(CulteDKP.ConfigTab4.ChatFrame, 150)
  LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab4.ChatFrame, "Addon Notifications")

  function CulteDKP.ConfigTab4.ChatFrame:SetValue(arg1)
    core.DB.defaults.ChatFrames[arg1] = not core.DB.defaults.ChatFrames[arg1]
    LibDD:CloseDropDownMenus()
  end



  -- Position Bid Timer Button
  CulteDKP.ConfigTab4.moveTimer = self:CreateButton("BOTTOMRIGHT", CulteDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["MOVEBIDTIMER"]);
  CulteDKP.ConfigTab4.moveTimer:ClearAllPoints();
  CulteDKP.ConfigTab4.moveTimer:SetPoint("LEFT", CulteDKP.ConfigTab4.submitSettings, "RIGHT", 200, 0)
  CulteDKP.ConfigTab4.moveTimer:SetSize(110,25)
  CulteDKP.ConfigTab4.moveTimer:SetScript("OnClick", function()
    if moveTimerToggle == 0 then
      CulteDKP:StartTimer(120, L["MOVEME"])
      CulteDKP.ConfigTab4.moveTimer:SetText(L["HIDEBIDTIMER"])
      moveTimerToggle = 1;
    else
      CulteDKP.BidTimer:SetScript("OnUpdate", nil)
      CulteDKP.BidTimer:Hide()
      CulteDKP.ConfigTab4.moveTimer:SetText(L["MOVEBIDTIMER"])
      moveTimerToggle = 0;
    end
  end)

  -- wipe tables button
  CulteDKP.ConfigTab4.WipeTables = self:CreateButton("BOTTOMRIGHT", CulteDKP.ConfigTab4, "BOTTOMRIGHT", -50, 30, L["WIPETABLES"]);
  CulteDKP.ConfigTab4.WipeTables:ClearAllPoints();
  CulteDKP.ConfigTab4.WipeTables:SetPoint("RIGHT", CulteDKP.ConfigTab4.moveTimer, "LEFT", -40, 0)
  CulteDKP.ConfigTab4.WipeTables:SetSize(110,25)
  CulteDKP.ConfigTab4.WipeTables:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText(L["WIPETABLES"], 0.25, 0.75, 0.90, 1, true);
    GameTooltip:AddLine(L["WIPETABLESTTDESC"], 1.0, 1.0, 1.0, true);
    GameTooltip:Show();
  end)
  CulteDKP.ConfigTab4.WipeTables:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  CulteDKP.ConfigTab4.WipeTables:SetScript("OnClick", function()

    StaticPopupDialogs["WIPE_TABLES"] = {
      Text = L["WIPETABLESCONF"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        CulteDKP:SetTable(CulteDKP_Whitelist, false, nil);
        CulteDKP:SetTable(CulteDKP_DKPTable, true, nil);
        CulteDKP:SetTable(CulteDKP_Loot, true, nil);
        CulteDKP:SetTable(CulteDKP_DKPHistory, true, nil);
        CulteDKP:SetTable(CulteDKP_Archive, true, nil);
        CulteDKP:SetTable(CulteDKP_Standby, true, nil);
        CulteDKP:SetTable(CulteDKP_MinBids, true, nil);
        CulteDKP:SetTable(CulteDKP_MaxBids, true, nil);

        CulteDKP:SetTable(CulteDKP_DKPTable, true, {});
        CulteDKP:SetTable(CulteDKP_Loot, true, {});
        CulteDKP:SetTable(CulteDKP_DKPHistory, true, {});
        CulteDKP:SetTable(CulteDKP_Archive, true, {});
        CulteDKP:SetTable(CulteDKP_Whitelist, false, {});
        CulteDKP:SetTable(CulteDKP_Standby, true, {});
        CulteDKP:SetTable(CulteDKP_MinBids, true, {});
        CulteDKP:SetTable(CulteDKP_MaxBids, true, {});
        CulteDKP:LootHistory_Reset()
        CulteDKP:FilterDKPTable(core.currentSort, "reset")
        CulteDKP:StatusVerify_Update()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("WIPE_TABLES")
  end)

  -- Options Footer (empty frame to push bottom of scrollframe down)
  CulteDKP.ConfigTab4.OptionsFooterFrame = CreateFrame("Frame", nil, CulteDKP.ConfigTab4);
  CulteDKP.ConfigTab4.OptionsFooterFrame:SetPoint("TOPLEFT", CulteDKP.ConfigTab4.moveTimer, "BOTTOMLEFT")
  CulteDKP.ConfigTab4.OptionsFooterFrame:SetSize(420, 50);
  
end
