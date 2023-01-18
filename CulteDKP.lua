local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local OptionsLoaded = false;
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");


function CulteDKP_RestoreFilterOptions()  		-- restores default filter selections
	CulteDKP.UIConfig.search:SetText(L["SEARCH"])
	CulteDKP.UIConfig.search:SetTextColor(0.3, 0.3, 0.3, 1)
	CulteDKP.UIConfig.search:ClearFocus()
	core.WorkingTable = CopyTable(CulteDKP:GetTable(CulteDKP_DKPTable, true))
	core.CurView = "all"
	core.CurSubView = "all"
	-- checkBtn 1 to 10 = Classes
	-- checkBtn 11 = ALL
	-- checkBtn 12 = In Party/Raid
	-- checkBtn 13 = Online
	-- checkBtn 14 = Not in Raid
	for i=1, 11 do
		CulteDKP.ConfigTab1.checkBtn[i]:SetChecked(true)
	end
	CulteDKP.ConfigTab1.checkBtn[12]:SetChecked(false)
	CulteDKP.ConfigTab1.checkBtn[13]:SetChecked(false)
	CulteDKP.ConfigTab1.checkBtn[14]:SetChecked(false)
	CulteDKPFilterChecks(CulteDKP.ConfigTab1.checkBtn[11])
end

function CulteDKP:Toggle()        -- toggles IsShown() state of CulteDKP.UIConfig, the entire addon window
	core.CulteDKPUI =  core.CulteDKPUI or CulteDKP:CreateMenu();
	core.CulteDKPUI:SetShown(not core.CulteDKPUI:IsShown())
	CulteDKP.UIConfig:SetFrameLevel(10)
	CulteDKP.UIConfig:SetClampedToScreen(true)
	if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(6) end
	if core.ModesWindow then core.ModesWindow:SetFrameLevel(2) end
		
	if core.IsOfficer == nil then
		CulteDKP:CheckOfficer()
	end
	--core.IsOfficer = C_GuildInfo.CanEditOfficerNote()  -- seemingly removed from classic API
	if core.IsOfficer == false then
		_G["CulteDKPCulteDKP.ConfigTabMenuTab2"]:Hide(); --Adjust DKP
		_G["CulteDKPCulteDKP.ConfigTabMenuTab3"]:Hide(); -- Manage
		--_G["CulteDKPCulteDKP.ConfigTabMenuTab7"]:Hide(); -- Loot Prices
		_G["CulteDKPCulteDKP.ConfigTabMenuTab4"]:SetPoint("TOPLEFT", _G["CulteDKPCulteDKP.ConfigTabMenuTab1"], "TOPRIGHT", -14, 0)
		_G["CulteDKPCulteDKP.ConfigTabMenuTab5"]:SetPoint("TOPLEFT", _G["CulteDKPCulteDKP.ConfigTabMenuTab4"], "TOPRIGHT", -14, 0)
		_G["CulteDKPCulteDKP.ConfigTabMenuTab6"]:SetPoint("TOPLEFT", _G["CulteDKPCulteDKP.ConfigTabMenuTab5"], "TOPRIGHT", -14, 0)
	end

	if not OptionsLoaded then
		core.CulteDKPOptions = core.CulteDKPOptions or CulteDKP:Options()
		OptionsLoaded = true;
	end

	if #CulteDKP:GetTable(CulteDKP_Whitelist) > 0 and core.IsOfficer then 				-- broadcasts whitelist any time the window is opened if one exists (help ensure everyone has the information even if they were offline when it was created)
		CulteDKP.Sync:SendData("CDKPWhitelist", CulteDKP:GetTable(CulteDKP_Whitelist))   -- Only officers propagate the whitelist, and it is only accepted by players that are NOT the GM (prevents overwriting new Whitelist set by GM, if any.)
	end

	if core.CurSubView == "raid" then
		CulteDKP:ViewLimited(true)
	elseif core.CurSubView == "standby" then
		CulteDKP:ViewLimited(false, true)
	elseif core.CurSubView == "raid and standby" then
		CulteDKP:ViewLimited(true, true)
	elseif core.CurSubView == "core" then
		CulteDKP:ViewLimited(false, false, true)
	elseif core.CurSubView == "all" then
		CulteDKP:ViewLimited()
	end

	core.CulteDKPUI:SetScale(core.DB.defaults.CulteDKPScaleSize)
	if CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
		CulteDKP:DKPHistory_Update(true)
	elseif CulteDKP.ConfigTab5 and CulteDKP.ConfigTab5:IsShown() then
		CulteDKP:LootHistory_Update(L["NOFILTER"]);
	end

	CulteDKP:StatusVerify_Update()
	CulteDKP:DKPTable_Update()
end

---------------------------------------
-- Sort Function
---------------------------------------
local SortButtons = {}

function CulteDKP:FilterDKPTable(sort, reset)          -- filters core.WorkingTable based on classes in classFiltered table. core.currentSort should be used in most cases
	local parentTable;

	if not CulteDKP.UIConfig then 
		return
	end

	if core.CurSubView ~= "all" then
		if core.CurSubView == "raid" then
			CulteDKP:ViewLimited(true)
		elseif core.CurSubView == "standby" then
			CulteDKP:ViewLimited(false, true)
		elseif core.CurSubView == "raid and standby" then
			CulteDKP:ViewLimited(true, true)
		elseif core.CurSubView == "core" then
			CulteDKP:ViewLimited(false, false, true)
		end
		parentTable = core.WorkingTable;
	else
		parentTable = CulteDKP:GetTable(CulteDKP_DKPTable, true);
	end

	core.WorkingTable = {}
	for k,v in ipairs(parentTable) do
		local IsOnline = false;
		local name;
		local InRaid = false;
		local searchFilter = true

		if CulteDKP.UIConfig.search:GetText() ~= L["SEARCH"] and CulteDKP.UIConfig.search:GetText() ~= "" then
			if not strfind(string.upper(v.player), string.upper(CulteDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.class), string.upper(CulteDKP.UIConfig.search:GetText()))
			and not strfind(string.upper(v.role), string.upper(CulteDKP.UIConfig.search:GetText())) and not strfind(string.upper(v.rankName), string.upper(CulteDKP.UIConfig.search:GetText())) 
			and not strfind(string.upper(v.spec), string.upper(CulteDKP.UIConfig.search:GetText())) then
				searchFilter = false;
			end
		end
		
		if CulteDKP.ConfigTab1.checkBtn[13]:GetChecked() then
			local guildSize,_,_ = GetNumGuildMembers();
			for i=1, guildSize do
				local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
				name = strsub(name, 1, string.find(name, "-")-1)
				
				if name == v.player then
					IsOnline = online;
					break;
				end
			end
		end
		if(core.classFiltered[parentTable[k]["class"]] == true) and searchFilter == true then
			if CulteDKP.ConfigTab1.checkBtn[12]:GetChecked() or CulteDKP.ConfigTab1.checkBtn[14]:GetChecked() then
				for i=1, 40 do
					tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
					if tempName and tempName == v.player and CulteDKP.ConfigTab1.checkBtn[12]:GetChecked() then
						tinsert(core.WorkingTable, v)
					elseif tempName and tempName == v.player and CulteDKP.ConfigTab1.checkBtn[14]:GetChecked() then
						InRaid = true;
					end
				end
			else
				if ((CulteDKP.ConfigTab1.checkBtn[13]:GetChecked() and IsOnline) or not CulteDKP.ConfigTab1.checkBtn[13]:GetChecked()) then
					tinsert(core.WorkingTable, v)
				end
			end
			if CulteDKP.ConfigTab1.checkBtn[14]:GetChecked() and InRaid == false then
				if CulteDKP.ConfigTab1.checkBtn[13]:GetChecked() then
					if IsOnline then
						tinsert(core.WorkingTable, v)
					end
				else
					tinsert(core.WorkingTable, v)
				end
			end
		end
		InRaid = false;
	end

	if #core.WorkingTable == 0 then  		-- removes all filter settings if the filter combination results in an empty table
		--CulteDKP_RestoreFilterOptions()
		CulteDKP.DKPTable.Rows[1].DKPInfo[1]:SetText("|cffff0000No Entries Returned.|r")
		CulteDKP.DKPTable.Rows[1]:Show()
	end
	CulteDKP:SortDKPTable(sort, reset);
end

function CulteDKP:SortDKPTable(id, reset)        -- reorganizes core.WorkingTable based on id passed. Avail IDs are "class", "player" and "dkp"
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)

	if id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
		button = SortButtons.class
	elseif id == "spec" then                -- doesn't allow "spec" to be sorted.
		CulteDKP:DKPTable_Update()
		return;
	else
		button = SortButtons[id]
	end

	if button == nil then
		return;
	end

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(SortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.WorkingTable, function(a, b)
		-- Validate Data and Fix Discrepencies
		if a[button.Id] == nil then
			print("[CulteDKP] Bad DKP Player Record Found: "..a.player)
			core.RepairWorking = true;
			return false;
		end
		if b[button.Id] == nil then
			print("[CulteDKP] Bad DKP Player Record Found: "..b.player)
			core.RepairWorking = true;
			return false;
		end

		if button.Ascend then
			if id == "dkp" then
				return a[button.Id] > b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
				if a[button.Id] < b[button.Id] then
					return true
				elseif a[button.Id] > b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] < b[button.Id]
			end
		else
			if id == "dkp" then
				return a[button.Id] < b[button.Id]
			elseif id == "class" or id == "rank" or id == "role" or id == "spec" or id == "version" then
				if a[button.Id] > b[button.Id] then
					return true
				elseif a[button.Id] < b[button.Id] then
					return false
				else
					return a.dkp > b.dkp
				end
			else
				return a[button.Id] > b[button.Id]
			end
		end
	end)
	core.currentSort = id;
	CulteDKP:DKPTable_Update()
end

function CulteDKP:CreateMenu()
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig = CreateFrame("Frame", "CulteDKPConfig", UIParent, "ShadowOverlaySmallTemplate")
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig = CreateFrame("Frame", "CulteDKPConfig", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)  --UIPanelDialogueTemplate, ShadowOverlaySmallTemplate
	end
	
	CulteDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	CulteDKP.UIConfig:SetSize(550, 590);
	CulteDKP.UIConfig:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CulteDKP.UIConfig:SetBackdropColor(0,0,0,0.8);
	CulteDKP.UIConfig:SetMovable(true);
	CulteDKP.UIConfig:EnableMouse(true);
	CulteDKP.UIConfig:RegisterForDrag("LeftButton");
	CulteDKP.UIConfig:SetScript("OnDragStart", CulteDKP.UIConfig.StartMoving);
	CulteDKP.UIConfig:SetScript("OnDragStop", CulteDKP.UIConfig.StopMovingOrSizing);
	CulteDKP.UIConfig:SetFrameStrata("DIALOG")
	CulteDKP.UIConfig:SetFrameLevel(10)
	CulteDKP.UIConfig:SetScript("OnMouseDown", function(self)
		self:SetFrameLevel(10)
		if core.ModesWindow then core.ModesWindow:SetFrameLevel(6) end
		if core.BiddingWindow then core.BiddingWindow:SetFrameLevel(2) end
	end)
	
	-- Close Button
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.closeContainer = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.closeContainer = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end

	CulteDKP.UIConfig.closeContainer:SetPoint("CENTER", CulteDKP.UIConfig, "TOPRIGHT", -4, 0)

	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
		-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		Mixin(CulteDKP.UIConfig.closeContainer, BackdropTemplateMixin)
	end

	CulteDKP.UIConfig.closeContainer:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});

	CulteDKP.UIConfig.closeContainer:SetBackdropColor(0,0,0,0.9)
	CulteDKP.UIConfig.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
	CulteDKP.UIConfig.closeContainer:SetSize(28, 28)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.closeBtn = CreateFrame("Button", nil, CulteDKP.UIConfig, "UIPanelCloseButton")
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.closeBtn = CreateFrame("Button", nil, CulteDKP.UIConfig, "UIPanelCloseButton", BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	CulteDKP.UIConfig.closeBtn:SetPoint("CENTER", CulteDKP.UIConfig.closeContainer, "TOPRIGHT", -14, -14)
	tinsert(UISpecialFrames, CulteDKP.UIConfig:GetName()); -- Sets frame to close on "Escape"
	---------------------------------------
	-- Create and Populate Tab Menu and DKP Table
	---------------------------------------
	CulteDKP.TabMenu = CulteDKP:ConfigMenuTabs();           -- Create and populate Config Menu Tabs
	CulteDKP:DKPTable_Create();                             -- Create DKPTable and populate rows
	CulteDKP.UIConfig.TabMenu:Hide()                     -- Hide menu until expanded
	---------------------------------------
	-- DKP Table Header and Sort Buttons
	---------------------------------------
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.DKPTable_Headers = CreateFrame("Frame", "CulteDKPDKPTableHeaders", CulteDKP.UIConfig)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.DKPTable_Headers = CreateFrame("Frame", "CulteDKPDKPTableHeaders", CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.DKPTable_Headers:SetSize(500, 22)
	CulteDKP.DKPTable_Headers:SetPoint("BOTTOMLEFT", CulteDKP.DKPTable, "TOPLEFT", 0, 1)

	if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
		-- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		Mixin(CulteDKP.DKPTable_Headers, BackdropTemplateMixin)
	end
	
	CulteDKP.DKPTable_Headers:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	CulteDKP.DKPTable_Headers:SetBackdropColor(0,0,0,0.8);
	CulteDKP.DKPTable_Headers:SetBackdropBorderColor(1,1,1,0.5)
	CulteDKP.DKPTable_Headers:Show()
	---------------------------------------
	-- Sort Buttons
	--------------------------------------- 
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", CulteDKP.DKPTable_Headers)
		SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", CulteDKP.DKPTable_Headers)
		SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", CulteDKP.DKPTable_Headers)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		SortButtons.player = CreateFrame("Button", "$ParentSortButtonPlayer", CulteDKP.DKPTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
		SortButtons.class = CreateFrame("Button", "$ParentSortButtonClass", CulteDKP.DKPTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
		SortButtons.dkp = CreateFrame("Button", "$ParentSortButtonDkp", CulteDKP.DKPTable_Headers, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	SortButtons.class:SetPoint("BOTTOM", CulteDKP.DKPTable_Headers, "BOTTOM", 0, 2)
	SortButtons.player:SetPoint("RIGHT", SortButtons.class, "LEFT")
	SortButtons.dkp:SetPoint("LEFT", SortButtons.class, "RIGHT")
	 
	for k, v in pairs(SortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		v:SetSize((core.TableWidth/3)-1, core.TableRowHeight)
		if v.Id == "class" then
			v:SetScript("OnClick", function(self) CulteDKP:SortDKPTable(core.CenterSort, "Clear") end)
		else
			v:SetScript("OnClick", function(self) CulteDKP:SortDKPTable(self.Id, "Clear") end)
		end
	end
	SortButtons.player:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)
	SortButtons.class:SetSize((core.TableWidth*0.2)-1, core.TableRowHeight)
	SortButtons.dkp:SetSize((core.TableWidth*0.4)-1, core.TableRowHeight)

	SortButtons.player.t = SortButtons.player:CreateFontString(nil, "OVERLAY")
	SortButtons.player.t:SetFontObject("CulteDKPNormal")
	SortButtons.player.t:SetTextColor(1, 1, 1, 1);
	SortButtons.player.t:SetPoint("LEFT", SortButtons.player, "LEFT", 50, 0);
	SortButtons.player.t:SetText(L["PLAYER"]); 

	--[[SortButtons.class.t = SortButtons.class:CreateFontString(nil, "OVERLAY")
	SortButtons.class.t:SetFontObject("CulteDKPNormal");
	SortButtons.class.t:SetTextColor(1, 1, 1, 1);
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 0, 0);
	SortButtons.class.t:SetText(L["CLASS"]); --]]

	-- center column dropdown (class, rank, spec etc..)
	--SortButtons.class.t = CreateFrame("FRAME", "CulteDKPSortColDropdown", SortButtons.class, "CulteDKPTableHeaderDropDownMenuTemplate")
	SortButtons.class.t = LibDD:Create_UIDropDownMenu("CulteDKPSortColDropdown", SortButtons.class)
	SortButtons.class.t:SetPoint("CENTER", SortButtons.class, "CENTER", 4, -3)
	LibDD:UIDropDownMenu_JustifyText(SortButtons.class.t, "CENTER")
	LibDD:UIDropDownMenu_SetWidth(SortButtons.class.t, 80)
	LibDD:UIDropDownMenu_SetText(SortButtons.class.t, L["CLASS"])
	LibDD:UIDropDownMenu_Initialize(SortButtons.class.t, function(self, level, menuList)
		
	local reason = LibDD:UIDropDownMenu_CreateInfo()
		reason.func = self.SetValue
		reason.fontObject = "CulteDKPSmallCenter"
		reason.Text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["CLASS"], "class", L["CLASS"], "class" == core.CenterSort, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["SPEC"], "spec", L["SPEC"], "spec" == core.CenterSort, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["RANK"], "rank", L["RANK"], "rank" == core.CenterSort, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["ROLE"], "role", L["ROLE"], "role" == core.CenterSort, true
		LibDD:UIDropDownMenu_AddButton(reason)
		reason.Text, reason.arg1, reason.arg2, reason.checked, reason.isNotRadio = L["VERSION"], "version", L["VERSION"], "version" == core.CenterSort, true
		LibDD:UIDropDownMenu_AddButton(reason)
	end)
	-- Dropdown Menu Function
	function SortButtons.class.t:SetValue(newValue, arg2)
		core.CenterSort = newValue
		SortButtons.class.Id = newValue;
		LibDD:UIDropDownMenu_SetText(SortButtons.class.t, arg2)
		CulteDKP:SortDKPTable(newValue, "reset")
		core.currentSort = newValue;
		LibDD:CloseDropDownMenus()
	end
	SortButtons.dkp.t = SortButtons.dkp:CreateFontString(nil, "OVERLAY")
	SortButtons.dkp.t:SetFontObject("CulteDKPNormal")
	SortButtons.dkp.t:SetTextColor(1, 1, 1, 1);
	if core.DB.modes.mode == "Roll Based Bidding" then
		SortButtons.dkp.t:SetPoint("RIGHT", SortButtons.dkp, "RIGHT", -50, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);

		SortButtons.dkp.roll = SortButtons.dkp:CreateFontString(nil, "OVERLAY");
		SortButtons.dkp.roll:SetFontObject("CulteDKPNormal")
		SortButtons.dkp.roll:SetScale("0.8")
		SortButtons.dkp.roll:SetTextColor(1, 1, 1, 1);
		SortButtons.dkp.roll:SetPoint("LEFT", SortButtons.dkp, "LEFT", 20, -1);
		SortButtons.dkp.roll:SetText(L["ROLLRANGE"])
	else
		SortButtons.dkp.t:SetPoint("CENTER", SortButtons.dkp, "CENTER", 20, 0);
		SortButtons.dkp.t:SetText(L["TOTALDKP"]);
	end
	----- Counter below DKP Table
	CulteDKP.DKPTable.counter = CreateFrame("Frame", "CulteDKPDisplayFrameCounter", CulteDKP.UIConfig);
	CulteDKP.DKPTable.counter:SetPoint("TOP", CulteDKP.DKPTable, "BOTTOM", 0, 0)
	CulteDKP.DKPTable.counter:SetSize(400, 30)

	CulteDKP.DKPTable.counter.t = CulteDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	CulteDKP.DKPTable.counter.t:SetFontObject("CulteDKPNormal");
	CulteDKP.DKPTable.counter.t:SetTextColor(1, 1, 1, 0.7);
	CulteDKP.DKPTable.counter.t:SetPoint("CENTER", CulteDKP.DKPTable.counter, "CENTER");

	CulteDKP.DKPTable.counter.s = CulteDKP.DKPTable.counter:CreateFontString(nil, "OVERLAY")
	CulteDKP.DKPTable.counter.s:SetFontObject("CulteDKPTiny");
	CulteDKP.DKPTable.counter.s:SetTextColor(1, 1, 1, 0.7);
	CulteDKP.DKPTable.counter.s:SetPoint("CENTER", CulteDKP.DKPTable.counter, "CENTER", 0, -15);
	------------------------------
	-- Search Box
	------------------------------
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.search = CreateFrame("EditBox", nil, CulteDKP.UIConfig)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.search = CreateFrame("EditBox", nil, CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.UIConfig.search:SetPoint("BOTTOMLEFT", CulteDKP.UIConfig, "BOTTOMLEFT", 50, 18)
	CulteDKP.UIConfig.search:SetAutoFocus(false)
	CulteDKP.UIConfig.search:SetMultiLine(false)
	CulteDKP.UIConfig.search:SetSize(140, 24)
	CulteDKP.UIConfig.search:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
	});
	CulteDKP.UIConfig.search:SetBackdropColor(0,0,0,0.9)
	CulteDKP.UIConfig.search:SetBackdropBorderColor(1,1,1,0.6)
	CulteDKP.UIConfig.search:SetMaxLetters(50)
	CulteDKP.UIConfig.search:SetTextColor(0.4, 0.4, 0.4, 1)
	CulteDKP.UIConfig.search:SetFontObject("CulteDKPNormalLeft");
	CulteDKP.UIConfig.search:SetTextInsets(10, 10, 5, 5)
	CulteDKP.UIConfig.search:SetText(L["SEARCH"])
	CulteDKP.UIConfig.search:SetScript("OnKeyUp", function(self)    -- clears.Text and focus on esc
		if (CulteDKP.UIConfig.search:GetText():match("[%^%$%(%)%%%.%[%]%*%+%-%?]")) then
			CulteDKP.UIConfig.search:SetText(string.gsub(CulteDKP.UIConfig.search:GetText(), "[%^%$%(%)%%%.%[%]%*%+%-%?]", ""))
			--CulteDKP.UIConfig.search:SetText(strsub(CulteDKP.UIConfig.search:GetText(), 1, -2))
		else
			CulteDKP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
	CulteDKP.UIConfig.search:SetScript("OnEscapePressed", function(self)    -- clears.Text and focus on esc
		self:SetText(L["SEARCH"])
		self:SetTextColor(0.3, 0.3, 0.3, 1)
		self:ClearFocus()
		CulteDKP:FilterDKPTable(core.currentSort, "reset")
	end)
	CulteDKP.UIConfig.search:SetScript("OnEnterPressed", function(self)    -- clears.Text and focus on enter
		self:ClearFocus()
	end)
	CulteDKP.UIConfig.search:SetScript("OnTabPressed", function(self)    -- clears.Text and focus on tab
		self:ClearFocus()
	end)
	CulteDKP.UIConfig.search:SetScript("OnEditFocusGained", function(self)
		if (self:GetText() ==  L["SEARCH"]) then
			self:SetText("");
			self:SetTextColor(1, 1, 1, 1)
		else
			self:HighlightText();
		end
	end)
	CulteDKP.UIConfig.search:SetScript("OnEditFocusLost", function(self)
		if (self:GetText() == "") then
			self:SetText(L["SEARCH"])
			self:SetTextColor(0.3, 0.3, 0.3, 1)
		end
	end)
	CulteDKP.UIConfig.search:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(L["SEARCH"], 0.25, 0.75, 0.90, 1, true);
		GameTooltip:AddLine(L["SEARCHDESC"], 1.0, 1.0, 1.0, true);
		GameTooltip:Show();
	end)
	CulteDKP.UIConfig.search:SetScript("OnLeave", function(self)
		GameTooltip:Hide();
	end)

	------------------------------
	-- Team view changer Drop Down
	------------------------------
		--CulteDKP.UIConfig.TeamViewChangerDropDown = CreateFrame("FRAME", "CulteDKPConfigReasonDropDown", CulteDKP.UIConfig, "CulteDKPUIDropDownMenuTemplate")
		CulteDKP.UIConfig.TeamViewChangerDropDown = LibDD:Create_UIDropDownMenu("CulteDKPConfigReasonDropDown", CulteDKP.UIConfig);
		--CulteDKP.ConfigTab3.TeamManagementContainer.TeamListDropDown:ClearAllPoints()
		CulteDKP.UIConfig.TeamViewChangerDropDown:SetPoint("BOTTOMLEFT", CulteDKP.UIConfig, "BOTTOMLEFT", 340, 4)
		-- tooltip on mouseOver
		CulteDKP.UIConfig.TeamViewChangerDropDown:SetScript("OnEnter", 
			function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["TEAMCURRENTLIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["TEAMCURRENTLISTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["WARNING"], 1.0, 0, 0, true);
				GameTooltip:AddLine(L["TEAMCURRENTLISTDESC2"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.UIConfig.TeamViewChangerDropDown:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		LibDD:UIDropDownMenu_SetWidth(CulteDKP.UIConfig.TeamViewChangerDropDown, 150)
		LibDD:UIDropDownMenu_SetText(CulteDKP.UIConfig.TeamViewChangerDropDown, CulteDKP:GetCurrentTeamName())

		-- Create and bind the initialization function to the dropdown menu
		LibDD:UIDropDownMenu_Initialize(CulteDKP.UIConfig.TeamViewChangerDropDown, 
			function(self, level, menuList)
				
				local dropDownMenuItem = LibDD:UIDropDownMenu_CreateInfo()
				dropDownMenuItem.func = self.SetValue
				dropDownMenuItem.fontObject = "CulteDKPSmallCenter"
			
				teamList = CulteDKP:GetGuildTeamList()

				for i=1, #teamList do
					dropDownMenuItem.Text = teamList[i][2]
					dropDownMenuItem.arg1 = teamList[i][2] -- name
					dropDownMenuItem.arg2 = teamList[i][1] -- index
					dropDownMenuItem.checked = teamList[i][1] == tonumber(CulteDKP:GetCurrentTeamIndex())
					dropDownMenuItem.isNotRadio = true
					LibDD:UIDropDownMenu_AddButton(dropDownMenuItem)
				end
			end
		)
	
		-- Dropdown Menu on SetValue()
		function CulteDKP.UIConfig.TeamViewChangerDropDown:SetValue(arg1, arg2)

			if tonumber(CulteDKP:GetCurrentTeamIndex()) ~= arg2 then
				if core.RaidInProgress == false and core.RaidInPause == false then
					CulteDKP:SetCurrentTeam(arg2)
					CulteDKP:SortDKPTable(core.currentSort, "reset")
					LibDD:UIDropDownMenu_SetText(CulteDKP.UIConfig.TeamViewChangerDropDown, arg1)
				else
					StaticPopupDialogs["RAID_IN_PROGRESS"] = {
					    Text = L["TEAMCHANGERAIDINPROGRESS"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("RAID_IN_PROGRESS")
				end
			else
				LibDD:CloseDropDownMenus()
			end
		end

		CulteDKP.UIConfig.TeamViewChangerLabel = CulteDKP.UIConfig.TeamViewChangerDropDown:CreateFontString(nil, "OVERLAY")
		CulteDKP.UIConfig.TeamViewChangerLabel:SetPoint("TOPLEFT", CulteDKP.UIConfig.TeamViewChangerDropDown, "TOPLEFT", 17, 13);
		CulteDKP.UIConfig.TeamViewChangerLabel:SetFontObject("CulteDKPTiny");
		CulteDKP.UIConfig.TeamViewChangerLabel:SetTextColor(1, 1, 1, 0.7);
		CulteDKP.UIConfig.TeamViewChangerLabel:SetText(L["TEAMCURRENTLISTLABEL"]);

	---------------------------------------
	-- Expand / Collapse Arrow
	---------------------------------------

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.expand = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.expand = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.UIConfig.expand:SetPoint("LEFT", CulteDKP.UIConfig, "RIGHT", 0, 0)
	CulteDKP.UIConfig.expand:SetBackdrop({
		bgFile   = "Textures\\white.blp", tile = true,
	});
	CulteDKP.UIConfig.expand:SetBackdropColor(0,0,0,0.7)
	CulteDKP.UIConfig.expand:SetSize(15, 60)
	
	CulteDKP.UIConfig.expandtab = CulteDKP.UIConfig.expand:CreateTexture(nil, "OVERLAY", nil);
	CulteDKP.UIConfig.expandtab:SetColorTexture(0, 0, 0, 1)
	CulteDKP.UIConfig.expandtab:SetPoint("CENTER", CulteDKP.UIConfig.expand, "CENTER");
	CulteDKP.UIConfig.expandtab:SetSize(15, 60);
	CulteDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\expand-arrow.tga");

	CulteDKP.UIConfig.expand.trigger = CreateFrame("Button", "$ParentCollapseExpandButton", CulteDKP.UIConfig.expand)
	CulteDKP.UIConfig.expand.trigger:SetSize(15, 60)
	CulteDKP.UIConfig.expand.trigger:SetPoint("CENTER", CulteDKP.UIConfig.expand, "CENTER", 0, 0)
	CulteDKP.UIConfig.expand.trigger:SetScript("OnClick", function(self) 
		if core.ShowState == false then
			CulteDKP.UIConfig:SetWidth(1106)
			CulteDKP.UIConfig.TabMenu:Show()
			CulteDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\collapse-arrow");
		else
			CulteDKP.UIConfig:SetWidth(550)
			CulteDKP.UIConfig.TabMenu:Hide()
			CulteDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\expand-arrow");
		end
		PlaySound(62540)
		core.ShowState = not core.ShowState
	end)

	-- Title Frame (top/center)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.TitleBar = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig, "ShadowOverlaySmallTemplate")
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.TitleBar = CreateFrame("Frame", "CulteDKPTitle", CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.UIConfig.TitleBar:SetPoint("BOTTOM", SortButtons.class, "TOP", 0, 10)
-- TODO YOZO Add culte logo ?
--	CulteDKP.UIConfig.TitleBar:SetBackdrop({
--		bgFile   = "Textures\\white.blp", tile = true,
--		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
--	});
--	CulteDKP.UIConfig.TitleBar:SetBackdropColor(0,0,0,0.9)
--	CulteDKP.UIConfig.TitleBar:SetSize(166, 54)
--	CulteDKP.UIConfig.TitleBar:SetSize(144, 70)

	-- Addon Title
--	CulteDKP.UIConfig.Title = CulteDKP.UIConfig.TitleBar:CreateTexture(nil, "OVERLAY", nil);   -- Title Bar Texture
--	CulteDKP.UIConfig.Title:SetColorTexture(0, 0, 0, 1)
--	CulteDKP.UIConfig.Title:SetPoint("CENTER", CulteDKP.UIConfig.TitleBar, "CENTER");
--	CulteDKP.UIConfig.Title:SetSize(160, 48);
--	CulteDKP.UIConfig.Title:SetSize(138, 64);
--	CulteDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\Culte-dkp.tga");
--	CulteDKP.UIConfig.Title:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\Culte-dkp_small.tga");
	---------------------------------------
	-- CHANGE LOG WINDOW
	---------------------------------------
	if core.DB.defaults.HideChangeLogs < core.BuildNumber then

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.ChangeLogDisplay = CreateFrame("Frame", "CulteDKP_ChangeLogDisplay", UIParent, "ShadowOverlaySmallTemplate");
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.ChangeLogDisplay = CreateFrame("Frame", "CulteDKP_ChangeLogDisplay", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil);
		end

		CulteDKP.ChangeLogDisplay:SetPoint("TOP", UIParent, "TOP", 0, -200);
		CulteDKP.ChangeLogDisplay:SetSize(600, 100);
		CulteDKP.ChangeLogDisplay:SetBackdrop( {
			bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
			edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3,  
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		});
		CulteDKP.ChangeLogDisplay:SetBackdropColor(0,0,0,0.9);
		CulteDKP.ChangeLogDisplay:SetBackdropBorderColor(1,1,1,1)
		CulteDKP.ChangeLogDisplay:SetFrameStrata("DIALOG")
		CulteDKP.ChangeLogDisplay:SetFrameLevel(1)
		CulteDKP.ChangeLogDisplay:SetMovable(true);
		CulteDKP.ChangeLogDisplay:EnableMouse(true);
		CulteDKP.ChangeLogDisplay:RegisterForDrag("LeftButton");
		CulteDKP.ChangeLogDisplay:SetScript("OnDragStart", CulteDKP.ChangeLogDisplay.StartMoving);
		CulteDKP.ChangeLogDisplay:SetScript("OnDragStop", CulteDKP.ChangeLogDisplay.StopMovingOrSizing);

		CulteDKP.ChangeLogDisplay.ChangeLogHeader = CulteDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CulteDKP.ChangeLogDisplay.ChangeLogHeader:ClearAllPoints();
		CulteDKP.ChangeLogDisplay.ChangeLogHeader:SetFontObject("CulteDKPLargeLeft");
		CulteDKP.ChangeLogDisplay.ChangeLogHeader:SetPoint("TOPLEFT", CulteDKP.ChangeLogDisplay, "TOPLEFT", 10, -10);
		CulteDKP.ChangeLogDisplay.ChangeLogHeader:SetText("CulteDKP Change Log");

		CulteDKP.ChangeLogDisplay.Notes = CulteDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CulteDKP.ChangeLogDisplay.Notes:ClearAllPoints();
		CulteDKP.ChangeLogDisplay.Notes:SetWidth(580)
		CulteDKP.ChangeLogDisplay.Notes:SetFontObject("CulteDKPNormalLeft");
		CulteDKP.ChangeLogDisplay.Notes:SetPoint("TOPLEFT", CulteDKP.ChangeLogDisplay.ChangeLogHeader, "BOTTOMLEFT", 0, -10);

		CulteDKP.ChangeLogDisplay.VerNumber = CulteDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CulteDKP.ChangeLogDisplay.VerNumber:ClearAllPoints();
		CulteDKP.ChangeLogDisplay.VerNumber:SetWidth(580)
		CulteDKP.ChangeLogDisplay.VerNumber:SetScale(0.8)
		CulteDKP.ChangeLogDisplay.VerNumber:SetFontObject("CulteDKPLargeLeft");
		CulteDKP.ChangeLogDisplay.VerNumber:SetPoint("TOPLEFT", CulteDKP.ChangeLogDisplay.Notes, "BOTTOMLEFT", 0, -10);

		CulteDKP.ChangeLogDisplay.ChangeLogText = CulteDKP.ChangeLogDisplay:CreateFontString(nil, "OVERLAY")   -- Filters header
		CulteDKP.ChangeLogDisplay.ChangeLogText:ClearAllPoints();
		CulteDKP.ChangeLogDisplay.ChangeLogText:SetWidth(540)
		CulteDKP.ChangeLogDisplay.ChangeLogText:SetFontObject("CulteDKPNormalLeft");
		CulteDKP.ChangeLogDisplay.ChangeLogText:SetPoint("TOPLEFT", CulteDKP.ChangeLogDisplay.VerNumber, "BOTTOMLEFT", 5, -0);

		-- Change Log Close Button

		if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
			CulteDKP.ChangeLogDisplay.closeContainer = CreateFrame("Frame", "CulteDKPChangeLogClose", CulteDKP.ChangeLogDisplay)
		else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
			CulteDKP.ChangeLogDisplay.closeContainer = CreateFrame("Frame", "CulteDKPChangeLogClose", CulteDKP.ChangeLogDisplay, BackdropTemplateMixin and "BackdropTemplate" or nil)
		end
		
		CulteDKP.ChangeLogDisplay.closeContainer:SetPoint("CENTER", CulteDKP.ChangeLogDisplay, "TOPRIGHT", -4, 0)
		CulteDKP.ChangeLogDisplay.closeContainer:SetBackdrop({
			bgFile   = "Textures\\white.blp", tile = true,
			edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 3, 
		});
		CulteDKP.ChangeLogDisplay.closeContainer:SetBackdropColor(0,0,0,0.9)
		CulteDKP.ChangeLogDisplay.closeContainer:SetBackdropBorderColor(1,1,1,0.2)
		CulteDKP.ChangeLogDisplay.closeContainer:SetSize(28, 28)

		CulteDKP.ChangeLogDisplay.closeBtn = CreateFrame("Button", nil, CulteDKP.ChangeLogDisplay, "UIPanelCloseButton")
		CulteDKP.ChangeLogDisplay.closeBtn:SetPoint("CENTER", CulteDKP.ChangeLogDisplay.closeContainer, "TOPRIGHT", -14, -14)

		CulteDKP.ChangeLogDisplay.DontShowCheck = CreateFrame("CheckButton", nil, CulteDKP.ChangeLogDisplay, "UICheckButtonTemplate");
		CulteDKP.ChangeLogDisplay.DontShowCheck:SetChecked(false)
		CulteDKP.ChangeLogDisplay.DontShowCheck:SetScale(0.6);
		CulteDKP.ChangeLogDisplay.DontShowCheck.Text:SetText("  |cff5151de"..L["DONTSHOW"].."|r");
		CulteDKP.ChangeLogDisplay.DontShowCheck.Text:SetScale(1.5);
		CulteDKP.ChangeLogDisplay.DontShowCheck.Text:SetFontObject("CulteDKPSmallLeft");
		CulteDKP.ChangeLogDisplay.DontShowCheck:SetPoint("LEFT", CulteDKP.ChangeLogDisplay.ChangeLogHeader, "RIGHT", 10, 0);
		CulteDKP.ChangeLogDisplay.DontShowCheck:SetScript("OnClick", function(self)
			if self:GetChecked() then
				core.DB.defaults.HideChangeLogs = core.BuildNumber
			else
				core.DB.defaults.HideChangeLogs = 0
			end
		end)
		
		if L["BESTPRACTICES"] ~= "" then
			CulteDKP.ChangeLogDisplay.Notes:SetText("|CFFAEAEDD"..L["BESTPRACTICES"].."|r")
		end
		CulteDKP.ChangeLogDisplay.VerNumber:SetText("Version: "..core.MonVersion)

		--------------------------------------
		-- ChangeLog variable calls (bottom of localization files)
		--------------------------------------
		CulteDKP.ChangeLogDisplay.ChangeLogText:SetText(L["CHANGELOG1"].."\n\n"..L["CHANGELOG2"].."\n\n"..L["CHANGELOG3"].."\n\n"..L["CHANGELOG4"].."\n\n"..L["CHANGELOG5"].."\n\n"..L["CHANGELOG6"].."\n\n"..L["CHANGELOG7"].."\n\n"..L["CHANGELOG8"].."\n\n"..L["CHANGELOG9"].."\n\n"..L["CHANGELOG10"]);

		local logHeight = CulteDKP.ChangeLogDisplay.ChangeLogHeader:GetHeight() + CulteDKP.ChangeLogDisplay.Notes:GetHeight() + CulteDKP.ChangeLogDisplay.VerNumber:GetHeight() + CulteDKP.ChangeLogDisplay.ChangeLogText:GetHeight();
		CulteDKP.ChangeLogDisplay:SetSize(800, logHeight);  -- resize container

	end
	---------------------------------------
	-- VERSION IDENTIFIER
	---------------------------------------
	local c = CulteDKP:GetThemeColor();
	CulteDKP.UIConfig.Version = CulteDKP.UIConfig.TitleBar:CreateFontString(nil, "OVERLAY")   -- not in a function so requires CreateFontString
	CulteDKP.UIConfig.Version:ClearAllPoints();
	CulteDKP.UIConfig.Version:SetFontObject("CulteDKPSmallCenter");
	CulteDKP.UIConfig.Version:SetScale("0.9")
	CulteDKP.UIConfig.Version:SetTextColor(c[1].r, c[1].g, c[1].b, 0.5);
	CulteDKP.UIConfig.Version:SetPoint("BOTTOMRIGHT", CulteDKP.UIConfig.TitleBar, "BOTTOMRIGHT", -8, 4);
	CulteDKP.UIConfig.Version:SetText(core.SemVer); 

	CulteDKP.UIConfig:Hide(); -- hide menu after creation until called.
	CulteDKP:FilterDKPTable(core.currentSort)   -- initial sort and populates data values in DKPTable.Rows{} CulteDKP:FilterDKPTable() -> CulteDKP:SortDKPTable() -> CulteDKP:DKPTable_Update()
	core.Initialized = true
	
	CulteDKP:Print("Initialization completed.");
	return CulteDKP.UIConfig;
end
