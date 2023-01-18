local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local curReason;
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

function CulteDKP:AdjustDKP(value)
	local adjustReason = curReason;
	local curTime = time()
	local c;
	local curOfficer = UnitName("player")
	value = CulteDKP_round(value, core.DB.modes.rounding);

	if not IsInRaid() then
		c = CulteDKP:GetCColors();
	end

	if (curReason == L["OTHER"]) then adjustReason = L["OTHER"].." - "..CulteDKP.ConfigTab2.otherReason:GetText(); end
	if curReason == L["BOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss; end
	if curReason == L["NEWBOSSKILLBONUS"] then adjustReason = core.CurrentRaidZone..": "..core.LastKilledBoss.." ("..L["FIRSTKILL"]..")" end
	if (#core.SelectedData > 0 and adjustReason and adjustReason ~= L["OTHER"].." - "..L["ENTEROTHERREASONHERE"]) then
		if core.IsOfficer then
			local tempString = "";       -- stores list of changes
			local dkpHistoryString = ""   -- stores list for CulteDKP:GetTable(CulteDKP_DKPHistory, true)
			for i=1, #core.SelectedData do
				local current;
				local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), core.SelectedData[i]["player"])
				if search then
					if not IsInRaid() then
						if i < #core.SelectedData then
							tempString = tempString.."|c"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r, ";
						else
							tempString = tempString.."|c"..c[core.SelectedData[i]["class"]].hex..core.SelectedData[i]["player"].."|r";
						end
					end
					dkpHistoryString = dkpHistoryString..core.SelectedData[i]["player"]..","
					current = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp
					CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp = CulteDKP_round(tonumber(current + value), core.DB.modes.rounding)
					if value > 0 then
						CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]]["lifetime_gained"] = CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]]["lifetime_gained"] + value), core.DB.modes.rounding)
					end
				end
			end
			local newIndex = curOfficer.."-"..curTime
			tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, {players=dkpHistoryString, dkp=value, reason=adjustReason, date=curTime, index=newIndex})
			CulteDKP.Sync:SendData("CDKPDKPDist", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])

			if CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
				CulteDKP:DKPHistory_Update(true)
			end
			CulteDKP:DKPTable_Update()
			if IsInRaid() then
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..value.." "..L["FORREASON"]..": "..adjustReason)
			else
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["DKPADJUSTBY"].." "..value.." "..L["FORPLAYERS"]..": ")
				CulteDKP.Sync:SendData("CDKPBCastMsg", tempString)
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["REASON"]..": "..adjustReason)
			end
		end
	else
		local validation;
		if (#core.SelectedData == 0 and not adjustReason) then
			validation = L["PLAYERREASONVALIDATE"]
		elseif #core.SelectedData == 0 then
			validation = L["PLAYERVALIDATE"]
		elseif not adjustReason or CulteDKP.ConfigTab2.otherReason:GetText() == "" or CulteDKP.ConfigTab2.otherReason:GetText() == L["ENTEROTHERREASONHERE"] then
			validation = L["OTHERREASONVALIDATE"]
		end

		StaticPopupDialogs["VALIDATION_PROMPT"] = {
		    Text = validation,
			button1 = L["OK"],
			timeout = 5,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show ("VALIDATION_PROMPT")
	end
end

local function DecayDKP(amount, deductionType, GetSelections)
	local playerString = "";
	local dkpString = "";
	local curTime = time()
	local curOfficer = UnitName("player")

	for key, value in ipairs(CulteDKP:GetTable(CulteDKP_DKPTable, true)) do
		local dkp = tonumber(value["dkp"])
		local player = value["player"]
		local amount = amount;
		amount = tonumber(amount) / 100		-- converts percentage to a decimal
		if amount < 0 then
			amount = amount * -1			-- flips value to positive if officer accidently used negative number in editbox
		end
		local deducted;

		if (GetSelections and CulteDKP:Table_Search(core.SelectedData, player)) or GetSelections == false then
			if dkp > 0 then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = dkp - deducted
					value["dkp"] = CulteDKP_round(tonumber(dkp), core.DB.modes.rounding);
					dkpString = dkpString.."-"..CulteDKP_round(deducted, core.DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end
			elseif dkp < 0 and CulteDKP.ConfigTab2.AddNegative:GetChecked() then
				if deductionType == "percent" then
					deducted = dkp * amount
					dkp = (deducted - dkp) * -1
					value["dkp"] = CulteDKP_round(tonumber(dkp), core.DB.modes.rounding)
					dkpString = dkpString..CulteDKP_round(-deducted, core.DB.modes.rounding)..",";
					playerString = playerString..player..",";
				elseif deductionType == "points" then
					-- do stuff for flat point deductions
				end	
			end
		end
	end
	dkpString = dkpString.."-"..amount.."%";

	if tonumber(amount) < 0 then amount = amount * -1 end		-- flips value to positive if officer accidently used a negative number

	local newIndex = curOfficer.."-"..curTime
	tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, {players=playerString, dkp=dkpString, reason=L["WEEKLYDECAY"], date=curTime, index=newIndex})
	CulteDKP.Sync:SendData("CDKPDecay", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])
	if CulteDKP.ConfigTab6.history then
		CulteDKP:DKPHistory_Update(true)
	end
	CulteDKP:DKPTable_Update()
end

local function RaidTimerPopout_Create()
	if not CulteDKP.RaidTimerPopout then

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.RaidTimerPopout = CreateFrame("Frame", "CulteDKP_RaidTimerPopout", UIParent, "ShadowOverlaySmallTemplate");
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.RaidTimerPopout = CreateFrame("Frame", "CulteDKP_RaidTimerPopout", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
		end
	
	    CulteDKP.RaidTimerPopout:SetPoint("RIGHT", UIParent, "RIGHT", -300, 100);
	    CulteDKP.RaidTimerPopout:SetSize(100, 50);
	    CulteDKP.RaidTimerPopout:SetBackdrop( {
	      bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
	      edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
	      insets = { left = 0, right = 0, top = 0, bottom = 0 }
	    });
	    CulteDKP.RaidTimerPopout:SetBackdropColor(0,0,0,0.9);
	    CulteDKP.RaidTimerPopout:SetBackdropBorderColor(1,1,1,1)
	    CulteDKP.RaidTimerPopout:SetFrameStrata("DIALOG")
	    CulteDKP.RaidTimerPopout:SetFrameLevel(15)
	    CulteDKP.RaidTimerPopout:SetMovable(true);
	    CulteDKP.RaidTimerPopout:EnableMouse(true);
	    CulteDKP.RaidTimerPopout:RegisterForDrag("LeftButton");
	    CulteDKP.RaidTimerPopout:SetScript("OnDragStart", CulteDKP.RaidTimerPopout.StartMoving);
	    CulteDKP.RaidTimerPopout:SetScript("OnDragStop", CulteDKP.RaidTimerPopout.StopMovingOrSizing);

	    -- Popout Close Button
		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.RaidTimerPopout.closeContainer = CreateFrame("Frame", "CulteDKPChangeLogClose", CulteDKP.RaidTimerPopout)
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.RaidTimerPopout.closeContainer = CreateFrame("Frame", "CulteDKPChangeLogClose", CulteDKP.RaidTimerPopout, BackdropTemplateMixin and "BackdropTemplate" or nil)
		end
    
	    CulteDKP.RaidTimerPopout.closeContainer:SetPoint("CENTER", CulteDKP.RaidTimerPopout, "TOPRIGHT", -8, -4)
	    CulteDKP.RaidTimerPopout.closeContainer:SetBackdrop({
	      bgFile   = "Textures\\white.blp", tile = true,
	      edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	    });
	    CulteDKP.RaidTimerPopout.closeContainer:SetBackdropColor(0,0,0,0.9)
	    CulteDKP.RaidTimerPopout.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	    CulteDKP.RaidTimerPopout.closeContainer:SetScale(0.7)
	    CulteDKP.RaidTimerPopout.closeContainer:SetSize(28, 28)

	    CulteDKP.RaidTimerPopout.closeBtn = CreateFrame("Button", nil, CulteDKP.RaidTimerPopout, "UIPanelCloseButton")
	    CulteDKP.RaidTimerPopout.closeBtn:SetPoint("CENTER", CulteDKP.RaidTimerPopout.closeContainer, "TOPRIGHT", -14, -14)
	    CulteDKP.RaidTimerPopout.closeBtn:SetScale(0.7)
	    CulteDKP.RaidTimerPopout.closeBtn:HookScript("OnClick", function()
	    	CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">");
	    end)

	    -- Raid Timer Output
	    CulteDKP.RaidTimerPopout.Output = CulteDKP.RaidTimerPopout:CreateFontString(nil, "OVERLAY")
	    CulteDKP.RaidTimerPopout.Output:SetFontObject("CulteDKPLargeLeft");
	    CulteDKP.RaidTimerPopout.Output:SetScale(0.8)
	    CulteDKP.RaidTimerPopout.Output:SetPoint("CENTER", CulteDKP.RaidTimerPopout, "CENTER", 0, 0);
	    CulteDKP.RaidTimerPopout.Output:SetText("|cff00ff0000:00:00|r")
	    CulteDKP.RaidTimerPopout:Hide();
	else
		CulteDKP.RaidTimerPopout:Show()
	end
end

function CulteDKP:AdjustDKPTab_Create()
	CulteDKP.ConfigTab2.header = CulteDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab2.header:SetPoint("TOPLEFT", CulteDKP.ConfigTab2, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab2.header:SetFontObject("CulteDKPLargeCenter")
	CulteDKP.ConfigTab2.header:SetText(L["ADJUSTDKP"]);
	CulteDKP.ConfigTab2.header:SetScale(1.2)

	CulteDKP.ConfigTab2.description = CulteDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab2.description:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.header, "BOTTOMLEFT", 7, -10);
	CulteDKP.ConfigTab2.description:SetWidth(400)
	CulteDKP.ConfigTab2.description:SetFontObject("CulteDKPNormalLeft")
	CulteDKP.ConfigTab2.description:SetText(L["ADJUSTDESC"]); 

	-- Reason DROPDOWN box 
	-- Create the dropdown, and configure its appearance
	CulteDKP.ConfigTab2.reasonDropDown = LibDD:Create_UIDropDownMenu("CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab2);
	--CulteDKP.ConfigTab2.reasonDropDown = CreateFrame("FRAME", "CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab2, "CulteDKPUIDropDownMenuTemplate")
	CulteDKP.ConfigTab2.reasonDropDown:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.description, "BOTTOMLEFT", -23, -60)
	LibDD:UIDropDownMenu_SetWidth(CulteDKP.ConfigTab2.reasonDropDown, 150)
	LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.reasonDropDown, L["SELECTREASON"])

	-- Create and bind the initialization function to the dropdown menu
		LibDD:UIDropDownMenu_Initialize(CulteDKP.ConfigTab2.reasonDropDown, function(self, level, menuList)
		
		local reason = LibDD:UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "CulteDKPSmallCenter"
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["ONTIMEBONUS"], L["ONTIMEBONUS"], L["ONTIMEBONUS"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["BOSSKILLBONUS"], L["BOSSKILLBONUS"], L["BOSSKILLBONUS"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"], L["RAIDCOMPLETIONBONUS"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"], L["NEWBOSSKILLBONUS"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["CORRECTINGERROR"], L["CORRECTINGERROR"], L["CORRECTINGERROR"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["DKPADJUST"], L["DKPADJUST"], L["DKPADJUST"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"], L["UNEXCUSEDABSENCE"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.checked, reason.isNotRadio = L["OTHER"], L["OTHER"], L["OTHER"] == curReason, true
		LibDD:UIDropDownMenu_AddButton(reason)
	end)

	-- Dropdown Menu Function
	function CulteDKP.ConfigTab2.reasonDropDown:SetValue(newValue)
		if curReason ~= newValue then curReason = newValue else curReason = nil end

		LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.reasonDropDown, curReason)

		if (curReason == L["ONTIMEBONUS"]) then CulteDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.OnTimeBonus); CulteDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["BOSSKILLBONUS"]) then
			CulteDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.BossKillBonus);
			CulteDKP.ConfigTab2.BossKilledDropdown:Show()
			LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["RAIDCOMPLETIONBONUS"]) then CulteDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.CompletionBonus); CulteDKP.ConfigTab2.BossKilledDropdown:Hide()
		elseif (curReason == L["NEWBOSSKILLBONUS"]) then
			CulteDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.NewBossKillBonus);
			CulteDKP.ConfigTab2.BossKilledDropdown:Show()
			LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		elseif (curReason == L["UNEXCUSEDABSENCE"]) then CulteDKP.ConfigTab2.addDKP:SetNumber(core.DB.DKPBonus.UnexcusedAbsence); CulteDKP.ConfigTab2.BossKilledDropdown:Hide()
		else CulteDKP.ConfigTab2.addDKP:SetText(""); CulteDKP.ConfigTab2.BossKilledDropdown:Hide() end

		if (curReason == L["OTHER"]) then
			CulteDKP.ConfigTab2.otherReason:Show();
			CulteDKP.ConfigTab2.BossKilledDropdown:Hide()
		else
			CulteDKP.ConfigTab2.otherReason:Hide();
		end

		LibDD:CloseDropDownMenus()
	end

	CulteDKP.ConfigTab2.reasonDropDown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["REASON"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["REASONTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["REASONTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.reasonDropDown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CulteDKP.ConfigTab2.reasonHeader = CulteDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab2.reasonHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.reasonDropDown, "TOPLEFT", 25, 0);
	CulteDKP.ConfigTab2.reasonHeader:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.reasonHeader:SetText(L["REASONFORADJUSTMENT"]..":")

	-- Other Reason Editbox. Hidden unless "Other" is selected in dropdown

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.ConfigTab2.otherReason = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.ConfigTab2.otherReason:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 19, 2)     
	CulteDKP.ConfigTab2.otherReason:SetAutoFocus(false)
	CulteDKP.ConfigTab2.otherReason:SetMultiLine(false)
	CulteDKP.ConfigTab2.otherReason:SetSize(225, 24)
	CulteDKP.ConfigTab2.otherReason:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CulteDKP.ConfigTab2.otherReason:SetBackdropColor(0,0,0,0.9)
	CulteDKP.ConfigTab2.otherReason:SetBackdropBorderColor(1,1,1,0.6)
	CulteDKP.ConfigTab2.otherReason:SetMaxLetters(50)
	CulteDKP.ConfigTab2.otherReason:SetTextColor(0.4, 0.4, 0.4, 1)
	CulteDKP.ConfigTab2.otherReason:SetFontObject("CulteDKPNormalLeft")
	CulteDKP.ConfigTab2.otherReason:SetTextInsets(10, 10, 5, 5)
	CulteDKP.ConfigTab2.otherReason:SetText(L["ENTEROTHERREASONHERE"])
	CulteDKP.ConfigTab2.otherReason:SetScript("OnEscapePressed", function(self)    -- clears.Text and focus on esc
		self:ClearFocus()
	end)
	CulteDKP.ConfigTab2.otherReason:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() == L["ENTEROTHERREASONHERE"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		end
	end)
	CulteDKP.ConfigTab2.otherReason:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["ENTEROTHERREASONHERE"])
			self:SetTextColor(0.4, 0.4, 0.4, 1)
		end
	end)
	CulteDKP.ConfigTab2.otherReason:Hide();

	-- Boss Killed Dropdown - Hidden unless "Boss Kill Bonus" or "New Boss Kill Bonus" is selected
	-- Killing a boss on the list will auto select that boss
	--CulteDKP.ConfigTab2.BossKilledDropdown = CreateFrame("FRAME", "CulteDKPBossKilledDropdown", CulteDKP.ConfigTab2, "CulteDKPUIDropDownMenuTemplate")
	CulteDKP.ConfigTab2.BossKilledDropdown = LibDD:Create_UIDropDownMenu("CulteDKPBossKilledDropdown", CulteDKP.ConfigTab2);
	CulteDKP.ConfigTab2.BossKilledDropdown:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 0, 2)
	CulteDKP.ConfigTab2.BossKilledDropdown:Hide()
	LibDD:UIDropDownMenu_SetWidth(CulteDKP.ConfigTab2.BossKilledDropdown, 210)
	LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.BossKilledDropdown, L["SELECTBOSS"])

	LibDD:UIDropDownMenu_Initialize(CulteDKP.ConfigTab2.BossKilledDropdown, function(self, level, menuList)
		local boss = LibDD:UIDropDownMenu_CreateInfo()
		boss.fontObject = "CulteDKPSmallCenter"
		if (level or 1) == 1 then
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[4], core.CurrentRaidZone == core.ZoneList[4], "NAXX", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[17], core.CurrentRaidZone == core.ZoneList[17], "ULDUAR", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[18], core.CurrentRaidZone == core.ZoneList[18], "OBSIDIANSANCTUM", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[19], core.CurrentRaidZone == core.ZoneList[19], "EYEOfETERNITY", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[20], core.CurrentRaidZone == core.ZoneList[20], "VAULTOFARCHAVON", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[21], core.CurrentRaidZone == core.ZoneList[21], "ICECROWNCITADEL", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[22], core.CurrentRaidZone == core.ZoneList[22], "TRIALCRUSADER", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[23], core.CurrentRaidZone == core.ZoneList[23], "RUBYSANCTUM", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[7], core.CurrentRaidZone == core.ZoneList[7], "ONYXIA", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[9], core.CurrentRaidZone == core.ZoneList[9], "KARAZHAN", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[10], core.CurrentRaidZone == core.ZoneList[10], "GRULLSLAIR", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[11], core.CurrentRaidZone == core.ZoneList[11], "MAGTHERIDONSLAIR", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[12], core.CurrentRaidZone == core.ZoneList[12], "SERPENTSHRINECAVERN", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[13], core.CurrentRaidZone == core.ZoneList[13], "TEMPESTKEEP", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[14], core.CurrentRaidZone == core.ZoneList[14], "ZULAMAN", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[15], core.CurrentRaidZone == core.ZoneList[15], "BLACKTEMPLE", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[16], core.CurrentRaidZone == core.ZoneList[16], "SUNWELLPLATEAU", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[1], core.CurrentRaidZone == core.ZoneList[1], "MC", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[2], core.CurrentRaidZone == core.ZoneList[2], "BWL", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[3], core.CurrentRaidZone == core.ZoneList[3], "AQ", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[5], core.CurrentRaidZone == core.ZoneList[5], "ZG", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[6], core.CurrentRaidZone == core.ZoneList[6], "AQ20", true
			LibDD:UIDropDownMenu_AddButton(boss)
			boss.Text, boss.checked, boss.menuList, boss.hasArrow = core.ZoneList[8], core.CurrentRaidZone == core.ZoneList[8], "WORLD", true
			LibDD:UIDropDownMenu_AddButton(boss)
			
		else
			boss.func = self.SetValue
			for i=1, #core.BossList[menuList] do
				boss.Text, boss.arg1, boss.checked = core.BossList[menuList][i], core.EncounterList[menuList][i], core.BossList[menuList][i] == core.LastKilledBoss
				LibDD:UIDropDownMenu_AddButton(boss, level)
			end
		end
	end)
	
	function CulteDKP.ConfigTab2.BossKilledDropdown:SetValue(newValue)
		local search = CulteDKP:Table_Search(core.EncounterList, newValue);
		if CulteDKP:Table_Search(core.EncounterList.MC, newValue) then
			core.CurrentRaidZone = core.ZoneList[1]
		elseif CulteDKP:Table_Search(core.EncounterList.BWL, newValue) then
			core.CurrentRaidZone = core.ZoneList[2]
		elseif CulteDKP:Table_Search(core.EncounterList.AQ, newValue) then
			core.CurrentRaidZone = core.ZoneList[3]
		elseif CulteDKP:Table_Search(core.EncounterList.NAXX, newValue) then
			core.CurrentRaidZone = core.ZoneList[4]
		elseif CulteDKP:Table_Search(core.EncounterList.ZG, newValue) then
			core.CurrentRaidZone = core.ZoneList[5]
		elseif CulteDKP:Table_Search(core.EncounterList.AQ20, newValue) then
			core.CurrentRaidZone = core.ZoneList[6]
		elseif CulteDKP:Table_Search(core.EncounterList.ONYXIA, newValue) then
			core.CurrentRaidZone = core.ZoneList[7]
		elseif CulteDKP:Table_Search(core.EncounterList.KARAZHAN, newValue) then
			core.CurrentRaidZone = core.ZoneList[9]
		elseif CulteDKP:Table_Search(core.EncounterList.GRULLSLAIR, newValue) then
			core.CurrentRaidZone = core.ZoneList[10]
		elseif CulteDKP:Table_Search(core.EncounterList.MAGTHERIDONSLAIR, newValue) then
			core.CurrentRaidZone = core.ZoneList[11]
		elseif CulteDKP:Table_Search(core.EncounterList.SERPENTSHRINECAVERN, newValue) then
			core.CurrentRaidZone = core.ZoneList[12]
		elseif CulteDKP:Table_Search(core.EncounterList.TEMPESTKEEP, newValue) then
			core.CurrentRaidZone = core.ZoneList[13]
		elseif CulteDKP:Table_Search(core.EncounterList.ZULAMAN, newValue) then
			core.CurrentRaidZone = core.ZoneList[14]
		elseif CulteDKP:Table_Search(core.EncounterList.BLACKTEMPLE, newValue) then
			core.CurrentRaidZone = core.ZoneList[15]
		elseif CulteDKP:Table_Search(core.EncounterList.SUNWELLPLATEAU, newValue) then
			core.CurrentRaidZone = core.ZoneList[16]
		elseif CulteDKP:Table_Search(core.EncounterList.ULDUAR, newValue) then
			core.CurrentRaidZone = core.ZoneList[17]
		elseif CulteDKP:Table_Search(core.EncounterList.OBSIDIANSANCTUM, newValue) then
			core.CurrentRaidZone = core.ZoneList[18]
		elseif CulteDKP:Table_Search(core.EncounterList.EYEOFETERNITY, newValue) then
			core.CurrentRaidZone = core.ZoneList[19]
		elseif CulteDKP:Table_Search(core.EncounterList.VAULTOFARCHAVON, newValue) then
			core.CurrentRaidZone = core.ZoneList[20]
		elseif CulteDKP:Table_Search(core.EncounterList.ICECROWNCITADEL, newValue) then
			core.CurrentRaidZone = core.ZoneList[21]
		elseif CulteDKP:Table_Search(core.EncounterList.TRIALCRUSADER, newValue) then
			core.CurrentRaidZone = core.ZoneList[22]
		elseif CulteDKP:Table_Search(core.EncounterList.RUBYSANCTUM, newValue) then
			core.CurrentRaidZone = core.ZoneList[23]
		else  --if CulteDKP:Table_Search(core.EncounterList.WORLD, newValue) then -- encounter IDs not known yet
			core.CurrentRaidZone = core.ZoneList[8]
		end

		if search then
			core.LastKilledBoss = core.BossList[search[1][1]][search[1][2]]
		else
			return;
		end

		core.DB.bossargs["LastKilledBoss"] = core.LastKilledBoss;
		core.DB.bossargs["CurrentRaidZone"] = core.CurrentRaidZone;

		if curReason ~= L["BOSSKILLBONUS"] and curReason ~= L["NEWBOSSKILLBONUS"] then
			CulteDKP.ConfigTab2.reasonDropDown:SetValue(L["BOSSKILLBONUS"])
		end
		LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab2.BossKilledDropdown, core.CurrentRaidZone..": "..core.LastKilledBoss)
		LibDD:CloseDropDownMenus()
	end

	-- Add DKP Edit Box
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.ConfigTab2.addDKP = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.ConfigTab2.addDKP:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.reasonDropDown, "BOTTOMLEFT", 20, -44)     
	CulteDKP.ConfigTab2.addDKP:SetAutoFocus(false)
	CulteDKP.ConfigTab2.addDKP:SetMultiLine(false)
	CulteDKP.ConfigTab2.addDKP:SetSize(100, 24)
	CulteDKP.ConfigTab2.addDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	CulteDKP.ConfigTab2.addDKP:SetBackdropColor(0,0,0,0.9)
	CulteDKP.ConfigTab2.addDKP:SetBackdropBorderColor(1,1,1,0.6)
	CulteDKP.ConfigTab2.addDKP:SetMaxLetters(10)
	CulteDKP.ConfigTab2.addDKP:SetTextColor(1, 1, 1, 1)
	CulteDKP.ConfigTab2.addDKP:SetFontObject("CulteDKPNormalRight")
	CulteDKP.ConfigTab2.addDKP:SetTextInsets(10, 10, 5, 5)
	CulteDKP.ConfigTab2.addDKP:SetScript("OnEscapePressed", function(self)    -- clears.Text and focus on esc
		self:SetText("")
		self:ClearFocus()
	end)
	CulteDKP.ConfigTab2.addDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["POINTS"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["POINTSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["POINTSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.addDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CulteDKP.ConfigTab2.pointsHeader = CulteDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")	
	CulteDKP.ConfigTab2.pointsHeader:SetFontObject("GameFontHighlightLeft");
	CulteDKP.ConfigTab2.pointsHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.addDKP, "TOPLEFT", 3, 3);
	CulteDKP.ConfigTab2.pointsHeader:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.pointsHeader:SetText(L["POINTS"]..":")

	-- Raid Only Checkbox
	CulteDKP.ConfigTab2.RaidOnlyCheck = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2, "UICheckButtonTemplate");
	CulteDKP.ConfigTab2.RaidOnlyCheck:SetChecked(false)
	CulteDKP.ConfigTab2.RaidOnlyCheck:SetScale(0.6);
	CulteDKP.ConfigTab2.RaidOnlyCheck.Text:SetText("  |cff5151deShow Raid Only|r");
	CulteDKP.ConfigTab2.RaidOnlyCheck.Text:SetScale(1.5);
	CulteDKP.ConfigTab2.RaidOnlyCheck.Text:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.RaidOnlyCheck:SetPoint("LEFT", CulteDKP.ConfigTab2.addDKP, "RIGHT", 15, 13);
	CulteDKP.ConfigTab2.RaidOnlyCheck:Hide()
	

	-- Select All Checkbox
	CulteDKP.ConfigTab2.selectAll = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2, "UICheckButtonTemplate");
	CulteDKP.ConfigTab2.selectAll:SetChecked(false)
	CulteDKP.ConfigTab2.selectAll:SetScale(0.6);
	CulteDKP.ConfigTab2.selectAll.Text:SetText("  |cff5151de"..L["SELECTALLVISIBLE"].."|r");
	CulteDKP.ConfigTab2.selectAll.Text:SetScale(1.5);
	CulteDKP.ConfigTab2.selectAll.Text:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.selectAll:SetPoint("LEFT", CulteDKP.ConfigTab2.addDKP, "RIGHT", 15, -13);
	CulteDKP.ConfigTab2.selectAll:Hide();
	

	-- Adjust DKP Button
	CulteDKP.ConfigTab2.adjustButton = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab2.addDKP, "BOTTOMLEFT", -1, -15, L["ADJUSTDKP"]);
	CulteDKP.ConfigTab2.adjustButton:SetSize(90,25)
	CulteDKP.ConfigTab2.adjustButton:SetScript("OnClick", function()
		if #core.SelectedData > 0 and curReason and CulteDKP.ConfigTab2.otherReason:GetText() then
			local selected = L["AREYOUSURE"].." "..CulteDKP_round(CulteDKP.ConfigTab2.addDKP:GetNumber(), core.DB.modes.rounding).." "..L["DKPTOFOLLOWING"]..": \n\n";
			for i=1, #core.SelectedData do
				-- CulteDKP:Print("Adjust DKP Button classSearch");
				local classSearch = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), core.SelectedData[i].player)
				if classSearch then
					c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[classSearch[1][1]].class)
				else
					c = { hex="ffffffff" }
				end
				if i == 1 then
					selected = selected.."|c"..c.hex..core.SelectedData[i].player.."|r"
				else
					selected = selected..", |c"..c.hex..core.SelectedData[i].player.."|r"
				end
			end
			StaticPopupDialogs["ADJUST_DKP"] = {
			    Text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					CulteDKP:AdjustDKP(CulteDKP.ConfigTab2.addDKP:GetNumber())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
		else
			CulteDKP:AdjustDKP(CulteDKP.ConfigTab2.addDKP:GetNumber());
		end
	end)
	CulteDKP.ConfigTab2.adjustButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADJUSTDKP"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADJUSTDKPTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.adjustButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- weekly decay Editbox

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.ConfigTab2.decayDKP = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.ConfigTab2.decayDKP:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2, "BOTTOMLEFT", 21, 70)     
	CulteDKP.ConfigTab2.decayDKP:SetAutoFocus(false)
	CulteDKP.ConfigTab2.decayDKP:SetMultiLine(false)
	CulteDKP.ConfigTab2.decayDKP:SetSize(100, 24)
	CulteDKP.ConfigTab2.decayDKP:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
	});
	CulteDKP.ConfigTab2.decayDKP:SetBackdropColor(0,0,0,0.9)
	CulteDKP.ConfigTab2.decayDKP:SetBackdropBorderColor(1,1,1,0.6)
	CulteDKP.ConfigTab2.decayDKP:SetMaxLetters(4)
	CulteDKP.ConfigTab2.decayDKP:SetTextColor(1, 1, 1, 1)
	CulteDKP.ConfigTab2.decayDKP:SetFontObject("CulteDKPNormalRight")
	CulteDKP.ConfigTab2.decayDKP:SetTextInsets(10, 15, 5, 5)
	CulteDKP.ConfigTab2.decayDKP:SetNumber(tonumber(core.DB.DKPBonus.DecayPercentage))
	CulteDKP.ConfigTab2.decayDKP:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
		self:ClearFocus()
	end)

	CulteDKP.ConfigTab2.decayDKP:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["WEEKLYDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.decayDKP:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CulteDKP.ConfigTab2.decayDKPHeader = CulteDKP.ConfigTab2:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab2.decayDKPHeader:SetFontObject("GameFontHighlightLeft");
	CulteDKP.ConfigTab2.decayDKPHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.decayDKP, "TOPLEFT", 3, 3);
	CulteDKP.ConfigTab2.decayDKPHeader:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.decayDKPHeader:SetText(L["WEEKLYDKPDECAY"]..":")

	CulteDKP.ConfigTab2.decayDKPFooter = CulteDKP.ConfigTab2.decayDKP:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab2.decayDKPFooter:SetFontObject("CulteDKPNormalLeft");
	CulteDKP.ConfigTab2.decayDKPFooter:SetPoint("LEFT", CulteDKP.ConfigTab2.decayDKP, "RIGHT", -15, 0);
	CulteDKP.ConfigTab2.decayDKPFooter:SetText("%")

	-- selected players only checkbox
	CulteDKP.ConfigTab2.SelectedOnlyCheck = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2, "UICheckButtonTemplate");
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetChecked(false)
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetScale(0.6);
	CulteDKP.ConfigTab2.SelectedOnlyCheck.Text:SetText("  |cff5151de"..L["SELPLAYERSONLY"].."|r");
	CulteDKP.ConfigTab2.SelectedOnlyCheck.Text:SetScale(1.5);
	CulteDKP.ConfigTab2.SelectedOnlyCheck.Text:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetPoint("TOP", CulteDKP.ConfigTab2.decayDKP, "BOTTOMLEFT", 15, -13);
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnClick", function(self)
		PlaySound(808)
	end)
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SELPLAYERSONLY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SELPLAYERSTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["SELPLAYERSTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.SelectedOnlyCheck:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- add to negative dkp checkbox
	CulteDKP.ConfigTab2.AddNegative = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2, "UICheckButtonTemplate");
	CulteDKP.ConfigTab2.AddNegative:SetChecked(core.DB.modes.AddToNegative)
	CulteDKP.ConfigTab2.AddNegative:SetScale(0.6);
	CulteDKP.ConfigTab2.AddNegative.Text:SetText("  |cff5151de"..L["ADDNEGVALUES"].."|r");
	CulteDKP.ConfigTab2.AddNegative.Text:SetScale(1.5);
	CulteDKP.ConfigTab2.AddNegative.Text:SetFontObject("CulteDKPSmallLeft")
	CulteDKP.ConfigTab2.AddNegative:SetPoint("TOP", CulteDKP.ConfigTab2.SelectedOnlyCheck, "BOTTOM", 0, 0);
	CulteDKP.ConfigTab2.AddNegative:SetScript("OnClick", function(self)
		core.DB.modes.AddToNegative = self:GetChecked();
		PlaySound(808)
	end)
	CulteDKP.ConfigTab2.AddNegative:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["ADDNEGVALUES"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["ADDNEGTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["ADDNEGTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.AddNegative:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	CulteDKP.ConfigTab2.decayButton = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab2.decayDKP, "TOPRIGHT", 20, 0, L["APPLYDECAY"]);
	CulteDKP.ConfigTab2.decayButton:SetSize(90,25)
	CulteDKP.ConfigTab2.decayButton:SetScript("OnClick", function()
		local SelectedToggle;
		local selected;

		if CulteDKP.ConfigTab2.SelectedOnlyCheck:GetChecked() then SelectedToggle = "|cffff0000"..L["SELECTED"].."|r" else SelectedToggle = "|cffff0000"..L["ALL"].."|r" end
		selected = L["CONFIRMDECAY"].." "..SelectedToggle.." "..L["DKPENTRIESBY"].." "..CulteDKP.ConfigTab2.decayDKP:GetNumber().."%%";

			StaticPopupDialogs["ADJUST_DKP"] = {
			    Text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					DecayDKP(CulteDKP.ConfigTab2.decayDKP:GetNumber(), "percent", CulteDKP.ConfigTab2.SelectedOnlyCheck:GetChecked())
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show ("ADJUST_DKP")
	end)
	CulteDKP.ConfigTab2.decayButton:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["WEEKLYDKPDECAY"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["APPDECAYTTDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:AddLine(L["APPDECAYTTWARN"], 1.0, 0, 0, true);
		GameTooltip:Show();
	end)
	CulteDKP.ConfigTab2.decayButton:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	-- Raid Timer Container
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab2.RaidTimerContainer = CreateFrame("Frame", nil, CulteDKP.ConfigTab2);
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.ConfigTab2.RaidTimerContainer = CreateFrame("Frame", nil, CulteDKP.ConfigTab2, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end
	
	CulteDKP.ConfigTab2.RaidTimerContainer:SetSize(200, 360);
	CulteDKP.ConfigTab2.RaidTimerContainer:SetPoint("RIGHT", CulteDKP.ConfigTab2, "RIGHT", -25, -60)
	CulteDKP.ConfigTab2.RaidTimerContainer:SetBackdrop({
      bgFile   = "Textures\\white.blp", tile = true,
      edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2, 
    });
	CulteDKP.ConfigTab2.RaidTimerContainer:SetBackdropColor(0,0,0,0.9)
	CulteDKP.ConfigTab2.RaidTimerContainer:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)

		-- Pop out button
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut = CreateFrame("Button", nil, CulteDKP.ConfigTab2, "UIMenuButtonStretchTemplate")
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetPoint("TOPRIGHT", CulteDKP.ConfigTab2.RaidTimerContainer, "TOPRIGHT", -5, -5)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHeight(22)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetWidth(18)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetNormalFontObject("CulteDKPLargeCenter")
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetHighlightFontObject("CulteDKPLargeCenter")
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:GetFontString():SetTextColor(0, 0.3, 0.7, 1)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScale(1.2)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameStrata("DIALOG")
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetFrameLevel(15)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetText(">")
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["POPOUTTIMER"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["POPOUTTIMERDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.PopOut:SetScript("OnClick", function(self)
			if self:GetText() == ">" then
				self:SetText("<");
				RaidTimerPopout_Create()
			else
				self:SetText(">");
				CulteDKP.RaidTimerPopout:Hide();
			end
		end)

		-- Raid Timer Header
	    CulteDKP.ConfigTab2.RaidTimerContainer.Header = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.Header:SetFontObject("CulteDKPLargeLeft");
	    CulteDKP.ConfigTab2.RaidTimerContainer.Header:SetScale(0.6)
	    CulteDKP.ConfigTab2.RaidTimerContainer.Header:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.RaidTimerContainer, "TOPLEFT", 15, -15);
	    CulteDKP.ConfigTab2.RaidTimerContainer.Header:SetText(L["RAIDTIMER"])

	    -- Raid Timer Output Header
	    CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetFontObject("CulteDKPNormalRight");
	    CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetPoint("TOP", CulteDKP.ConfigTab2.RaidTimerContainer, "TOP", -20, -40);
	    CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
	    CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Hide();

	    -- Raid Timer Output
	    CulteDKP.ConfigTab2.RaidTimerContainer.Output = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetFontObject("CulteDKPLargeLeft");
	    CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetScale(0.8)
	    CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetPoint("LEFT", CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader, "RIGHT", 5, 0);

	    -- Bonus Awarded Header
	    CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetFontObject("CulteDKPNormalRight");
	    CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetPoint("TOP", CulteDKP.ConfigTab2.RaidTimerContainer, "TOP", -15, -60);
	    CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
	    CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Hide();

	    -- Bonus Awarded Output
	    CulteDKP.ConfigTab2.RaidTimerContainer.Bonus = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetFontObject("CulteDKPLargeLeft");
	    CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetScale(0.8)
	    CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetPoint("LEFT", CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader, "RIGHT", 5, 0);

	    -- Start Raid Timer Button
	    CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer = self:CreateButton("BOTTOMLEFT", CulteDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 135, L["INITRAID"]);
		CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetSize(90,25)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnClick", function(self)
			if not IsInRaid() then
				StaticPopupDialogs["NO_RAID_TIMER"] = {
				    Text = L["NOTINRAID"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("NO_RAID_TIMER")
				return;
			end
			if not core.RaidInProgress then				
				if core.DB.DKPBonus.GiveRaidStart and self:GetText() ~= L["CONTINUERAID"] then
					StaticPopupDialogs["START_RAID_BONUS"] = {
					    Text = L["RAIDTIMERBONUSCONFIRM"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()						
							local setInterval = CulteDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
							local setBonus = CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
							local setOnTime = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
							local setGiveEnd = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
							local setStandby = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
							CulteDKP.Sync:SendData("CDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
							if CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
								CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDRESUME"])
							else
								CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDSTART"])
								CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
							end
							CulteDKP:StartRaidTimer(false)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("START_RAID_BONUS")
				else
					local setInterval = CulteDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
					local setBonus = CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
					local setOnTime = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
					local setGiveEnd = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
					local setStandby = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());
					CulteDKP.Sync:SendData("CDKPRaidTime", "start,false "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
					if CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:GetText() == L["CONTINUERAID"] then
						CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDRESUME"])
					else
						CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDSTART"])
						CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff0000|r")
					end
					CulteDKP:StartRaidTimer(false)
				end
			else
				StaticPopupDialogs["END_RAID"] = {
				    Text = L["ENDCURRAIDCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDTIMERCONCLUDE"].." "..CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
						CulteDKP.Sync:SendData("CDKPRaidTime", "stop")
						CulteDKP:StopRaidTimer()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("END_RAID")
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INITRAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INITRAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INITRAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Pause Raid Timer Button
	    CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer = self:CreateButton("BOTTOMRIGHT", CulteDKP.ConfigTab2.RaidTimerContainer, "BOTTOMRIGHT", -10, 135, L["PAUSERAID"]);
		CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetSize(90,25)
		CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
		CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnClick", function(self)
			if core.RaidInProgress then
				local setInterval = CulteDKP.ConfigTab2.RaidTimerContainer.interval:GetNumber();
				local setBonus = CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:GetNumber();
				local setOnTime = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:GetChecked());
				local setGiveEnd = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:GetChecked());
				local setStandby = tostring(CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:GetChecked());

				CulteDKP.Sync:SendData("CDKPRaidTime", "start,true "..setInterval.. " "..setBonus.." "..setOnTime.." "..setGiveEnd.." "..setStandby)
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDPAUSE"].." "..CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText().."!")
				CulteDKP:StartRaidTimer(true)
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["PAUSERAID"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["PAUSERAIDTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["PAUSERAIDTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Award Interval Editbox
		if not core.DB.modes.increment then core.DB.modes.increment = 60 end

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.ConfigTab2.RaidTimerContainer.interval = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2.RaidTimerContainer)
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.ConfigTab2.RaidTimerContainer.interval = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2.RaidTimerContainer, BackdropTemplateMixin and "BackdropTemplate" or nil)
		end
		
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 35, 225)     
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetAutoFocus(false)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetMultiLine(false)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetSize(60, 24)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropColor(0,0,0,0.9)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetBackdropBorderColor(1,1,1,0.6)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetMaxLetters(5)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetTextColor(1, 1, 1, 1)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetFontObject("CulteDKPSmallRight")
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetTextInsets(10, 15, 5, 5)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(core.DB.modes.increment))
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				core.DB.modes.increment = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
				    Text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFocus()
			CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:HighlightText()
		end)

		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDINTERVAL"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["AWARDINTERVALTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CulteDKP.ConfigTab2.RaidTimerContainer.intervalHeader = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetFontObject("CulteDKPTinyRight");
	    CulteDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.RaidTimerContainer.interval, "TOPLEFT", 0, 2);
	    CulteDKP.ConfigTab2.RaidTimerContainer.intervalHeader:SetText(L["INTERVAL"]..":")

	    -- Award Value Editbox
	    if not core.DB.DKPBonus.IntervalBonus then core.DB.DKPBonus.IntervalBonus = 15 end

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2.RaidTimerContainer)
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue = CreateFrame("EditBox", nil, CulteDKP.ConfigTab2.RaidTimerContainer, BackdropTemplateMixin and "BackdropTemplate" or nil)
		end
	
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetPoint("LEFT", CulteDKP.ConfigTab2.RaidTimerContainer.interval, "RIGHT", 10, 0)     
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetAutoFocus(false)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMultiLine(false)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetSize(60, 24)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile", tile = true, tileSize = 32, edgeSize = 2,
		});
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropColor(0,0,0,0.9)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetBackdropBorderColor(1,1,1,0.6)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetMaxLetters(5)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextColor(1, 1, 1, 1)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetFontObject("CulteDKPSmallRight")
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetTextInsets(10, 15, 5, 5)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(core.DB.DKPBonus.IntervalBonus))
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTextChanged", function(self)    -- clears focus on esc
			if tonumber(self:GetNumber()) then
				core.DB.DKPBonus.IntervalBonus = self:GetNumber();
			else
				StaticPopupDialogs["ALERT_NUMBER"] = {
				    Text = L["INCREMENTINVALIDWARN"],
					button1 = L["OK"],
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("ALERT_NUMBER")
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEscapePressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnterPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			self:ClearFocus()
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnTabPressed", function(self)    -- clears focus on esc
			self:HighlightText(0,0)
			CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetFocus()
			CulteDKP.ConfigTab2.RaidTimerContainer.interval:HighlightText()
		end)

		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["AWARDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["AWARDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetFontObject("CulteDKPTinyRight");
	    CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue, "TOPLEFT", 0, 2);
	    CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalueHeader:SetText(L["BONUS"]..":")
    	
    	-- Give On Time Bonus Checkbox
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(core.DB.DKPBonus.GiveRaidStart)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScale(0.6);
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus.Text:SetText("  |cff5151de"..L["GIVEONTIMEBONUS"].."|r");
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus.Text:SetScale(1.5);
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus.Text:SetFontObject("CulteDKPSmallLeft")
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetPoint("TOPLEFT", CulteDKP.ConfigTab2.RaidTimerContainer.interval, "BOTTOMLEFT", 0, -10);
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.GiveRaidStart = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.GiveRaidStart = false;
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEONTIMEBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEONTIMETTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Give Raid End Bonus Checkbox
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(core.DB.DKPBonus.GiveRaidEnd)
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScale(0.6);
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.Text:SetText("  |cff5151de"..L["GIVEENDBONUS"].."|r");
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.Text:SetScale(1.5);
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus.Text:SetFontObject("CulteDKPSmallLeft")
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetPoint("TOP", CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus, "BOTTOM", 0, 2);
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.GiveRaidEnd = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.GiveRaidEnd = false;
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["GIVEENDBONUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["GIVEENDBONUSTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Include Standby Checkbox
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab2.RaidTimerContainer, "UICheckButtonTemplate");
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(core.DB.DKPBonus.IncStandby)
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScale(0.6);
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.Text:SetText("  |cff5151de"..L["INCLUDESTANDBY"].."|r");
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.Text:SetScale(1.5);
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude.Text:SetFontObject("CulteDKPSmallLeft")
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetPoint("TOP", CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus, "BOTTOM", 0, 2);
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.DKPBonus.IncStandby = true;
				PlaySound(808)
			else
				core.DB.DKPBonus.IncStandby = false;
			end
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetText(L["INCLUDESTANDBY"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTDESC"], 1.0, 1.0, 1.0, true);
			GameTooltip:AddLine(L["INCLUDESTANDBYTTWARN"], 1.0, 0, 0, true);
			GameTooltip:Show();
		end)
		CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		CulteDKP.ConfigTab2.RaidTimerContainer.TimerWarning = CulteDKP.ConfigTab2.RaidTimerContainer:CreateFontString(nil, "OVERLAY")
	    CulteDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetFontObject("CulteDKPTinyLeft");
	    CulteDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetWidth(180)
	    CulteDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab2.RaidTimerContainer, "BOTTOMLEFT", 10, 10);
	    CulteDKP.ConfigTab2.RaidTimerContainer.TimerWarning:SetText("|CFFFF0000"..L["TIMERWARNING"].."|r")
	    RaidTimerPopout_Create()
end
