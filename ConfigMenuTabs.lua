local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

--
--  When clicking a box off, unchecks "All" as well and flags checkAll to false
--

local next = next
local checkAll = true;                    -- changes to false when less than all of the boxes are checked
local curReason;                          -- stores user input in dropdown 

local function ScrollFrame_OnMouseWheel(self, delta)          -- scroll function for all but the DKPTable frame
	local newValue = self:GetVerticalScroll() - (delta * 20);   -- DKPTable frame uses FauxScrollFrame_OnVerticalScroll()
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end

function CulteDKPFilterChecks(self)         -- sets/unsets check boxes in conjunction with "All" button, then runs CulteDKP:FilterDKPTable() above
	local verifyCheck = true; -- switches to false if the below loop finds anything unchecked
	if (self:GetChecked() == false and not CulteDKP.ConfigTab1.checkBtn[11]) then
		core.CurView = "limited"
		core.CurSubView = "raid"
		CulteDKP.ConfigTab1.checkBtn[11]:SetChecked(false);
		checkAll = false;
		verifyCheck = false
	end
	for i=1, 10 do             -- checks all boxes to see if all are checked, if so, checks "All" as well
		if CulteDKP.ConfigTab1.checkBtn[i]:GetChecked() == false then
			verifyCheck = false;
		end
	end
	if (verifyCheck == true) then
		CulteDKP.ConfigTab1.checkBtn[11]:SetChecked(true);
	else
		CulteDKP.ConfigTab1.checkBtn[11]:SetChecked(false);
	end
	for k,v in pairs(core.classes) do
		if (CulteDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
			core.classFiltered[v] = true;
		else
			core.classFiltered[v] = false;
		end
	end
	PlaySound(808)
	CulteDKP:FilterDKPTable(core.currentSort, "reset");
end

local function Tab_OnClick(self)
	PanelTemplates_SetTab(self:GetParent(), self:GetID());
	
	if self:GetID() > 4 then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	elseif self:GetID() == 4 and core.IsOfficer == true then
		self:GetParent().ScrollFrame.ScrollBar:Show()
	else
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	if self:GetID() == 5 then
		CulteDKP:LootHistory_Update(L["NOFILTER"]);
	elseif self:GetID() == 6 then
		CulteDKP:DKPHistory_Update(true)
	end

	if self:GetID() == 7 then
		self:GetParent().ScrollFrame.ScrollBar:Hide()
	end

	local scrollChild = self:GetParent().ScrollFrame:GetScrollChild();
	if (scrollChild) then
		scrollChild:Hide();
	end
	
	PlaySound(808)
	self:GetParent().ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
	self:GetParent().ScrollFrame:SetVerticalScroll(0)
end

function CulteDKP:SetTabs(frame, numTabs, width, height, ...)
	frame.numTabs = numTabs;
	
	local contents = {};
	local frameName = frame:GetName();
	
	for i = 1, numTabs do 
		local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CulteDKPTabButtonTemplate");
		tab:SetID(i);
		tab:SetText(select(i, ...));
		tab:GetFontString():SetFontObject("CulteDKPSmallOutlineCenter")
		tab:GetFontString():SetTextColor(0.7, 0.7, 0.86, 1)
		tab:SetScript("OnClick", Tab_OnClick);
		
		tab.content = CreateFrame("Frame", nil, frame.ScrollFrame);
		tab.content:SetSize(width, height);
		tab.content:Hide();
				
		table.insert(contents, tab.content);
		
		if (i == 1) then
			tab:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", -5, 1);
		else
			tab:SetPoint("TOPLEFT", _G[frameName.."Tab"..(i - 1)], "TOPRIGHT", -17, 0);
		end 
	end
	
	Tab_OnClick(_G[frameName.."Tab1"]);
	
	return unpack(contents);
end

---------------------------------------
-- Populate Tabs 
---------------------------------------
function CulteDKP:ConfigMenuTabs()	
	---------------------------------------
	-- TabMenu
	---------------------------------------

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.UIConfig.TabMenu = CreateFrame("Frame", "CulteDKPCulteDKP.ConfigTabMenu", CulteDKP.UIConfig);
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.UIConfig.TabMenu = CreateFrame("Frame", "CulteDKPCulteDKP.ConfigTabMenu", CulteDKP.UIConfig, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end
	
	CulteDKP.UIConfig.TabMenu:SetPoint("TOPRIGHT", CulteDKP.UIConfig, "TOPRIGHT", -25, -25); --Moves the entire tabframe (defaults -25, -25)
	CulteDKP.UIConfig.TabMenu:SetSize(535, 510);  --default: 477,510
	CulteDKP.UIConfig.TabMenu:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	CulteDKP.UIConfig.TabMenu:SetBackdropColor(0,0,0,0.9);
	CulteDKP.UIConfig.TabMenu:SetBackdropBorderColor(1,1,1,0.5)

	CulteDKP.UIConfig.TabMenuBG = CulteDKP.UIConfig.TabMenu:CreateTexture(nil, "OVERLAY", nil);
	CulteDKP.UIConfig.TabMenuBG:SetColorTexture(0, 0, 0, 1)
	CulteDKP.UIConfig.TabMenuBG:SetPoint("TOPLEFT", CulteDKP.UIConfig.TabMenu, "TOPLEFT", 2, -2);
	CulteDKP.UIConfig.TabMenuBG:SetSize(536, 511);
	CulteDKP.UIConfig.TabMenuBG:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\menu-bg");
	-- CulteDKP.UIConfig.TabMenuBG:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\Culte-dkp_large");

	-- TabMenu ScrollFrame and ScrollBar
	CulteDKP.UIConfig.TabMenu.ScrollFrame = CreateFrame("ScrollFrame", nil, CulteDKP.UIConfig.TabMenu, "UIPanelScrollFrameTemplate");
	CulteDKP.UIConfig.TabMenu.ScrollFrame:ClearAllPoints();
	CulteDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("TOPLEFT",  CulteDKP.UIConfig.TabMenu, "TOPLEFT", 4, -8);
	CulteDKP.UIConfig.TabMenu.ScrollFrame:SetPoint("BOTTOMRIGHT", CulteDKP.UIConfig.TabMenu, "BOTTOMRIGHT", -3, 4);
	CulteDKP.UIConfig.TabMenu.ScrollFrame:SetClipsChildren(false);
	CulteDKP.UIConfig.TabMenu.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	
	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		-- CulteDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar = CreateFrame("Slider", nil, CulteDKP.UIConfig.TabMenu.ScrollFrame, "UIPanelScrollFrameTemplate")
		-- CulteDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:Hide();
		-- CulteDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:ClearAllPoints();
		-- CulteDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", CulteDKP.UIConfig.TabMenu.ScrollFrame, "TOPRIGHT", -20, -12);
		-- CulteDKP.UIConfig.TabMenu.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", CulteDKP.UIConfig.TabMenu.ScrollFrame, "BOTTOMRIGHT", -2, 15);
	end
	
	CulteDKP.ConfigTab1, CulteDKP.ConfigTab2,CulteDKP.ConfigTab3, CulteDKP.ConfigTab4, CulteDKP.ConfigTab5, CulteDKP.ConfigTab6, CulteDKP.ConfigTab7 = CulteDKP:SetTabs(CulteDKP.UIConfig.TabMenu, 7, 533, 490, L["FILTERS"], L["ADJUSTDKP"], L["MANAGE"], L["OPTIONS"], L["LOOTHISTORY"], L["DKPHISTORY"], L["PRICETAB"]); 

	---------------------------------------
	-- MENU TAB 1
	---------------------------------------
	CulteDKP.ConfigTab1.Text = CulteDKP.ConfigTab1:CreateFontString(nil, "OVERLAY")   -- Filters header
	CulteDKP.ConfigTab1.Text:ClearAllPoints();
	CulteDKP.ConfigTab1.Text:SetFontObject("CulteDKPLargeCenter");
	CulteDKP.ConfigTab1.Text:SetPoint("TOPLEFT", CulteDKP.ConfigTab1, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab1.Text:SetText(L["FILTERS"]);
	CulteDKP.ConfigTab1.Text:SetScale(1.2)

	local checkBtn = {}
	CulteDKP.ConfigTab1.checkBtn = checkBtn;
	-- Create CheckBoxes 
	for i=1, 14 do
		-- 1 to 10 classes, 11: ALL Classes, 12 In Party/Raid, 13 Online, 14 Not In Raid
		CulteDKP.ConfigTab1.checkBtn[i] = CreateFrame("CheckButton", nil, CulteDKP.ConfigTab1, "UICheckButtonTemplate");
		CulteDKP.ConfigTab1.checkBtn[i]:SetID(i)
	    CulteDKP.ConfigTab1.checkBtn[i].Text:SetFontObject("CulteDKPSmall")
		if i <= 11 then 
			if i <= 10 then -- Classes only
				CulteDKP.ConfigTab1.checkBtn[i].Text:SetText("|cff5151de"..API_CLASSES[core.classes[i]].."|r");
			end
			CulteDKP.ConfigTab1.checkBtn[i]:SetChecked(true) 
		else 
			CulteDKP.ConfigTab1.checkBtn[i]:SetChecked(false) 
		end;
		if i==11 then -- All Classes
			CulteDKP.ConfigTab1.checkBtn[i].Text:SetText("|cff5151de"..L["ALLCLASSES"].."|r");
			CulteDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick",
				function()
					for j=1, 10 do
						if (checkAll) then
							CulteDKP.ConfigTab1.checkBtn[j]:SetChecked(false)
						else
							CulteDKP.ConfigTab1.checkBtn[j]:SetChecked(true)
						end
					end
					checkAll = not checkAll;
					CulteDKPFilterChecks(CulteDKP.ConfigTab1.checkBtn[11]);
				end)

			for k,v in pairs(core.classes) do               -- sets core.classFiltered table with all values
				if (CulteDKP.ConfigTab1.checkBtn[k]:GetChecked() == true) then
					core.classFiltered[v] = true;
				else
					core.classFiltered[v] = false;
				end
			end
		elseif i==12 or i==14 then -- In Party/Raid or Not In Raid
			local tagName = L["INPARTYRAID"];
			local otherButton = 14;
			if i==14 then
				tagName = L["NOTINRAIDFILTER"];
				otherButton = 12;
			end
			CulteDKP.ConfigTab1.checkBtn[i].Text:SetText("|cff5151de"..tagName.."|r");
			CulteDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", function(self)
					CulteDKP.ConfigTab1.checkBtn[otherButton]:SetChecked(false);
					CulteDKPFilterChecks(self)
				end)
		elseif i==13 then -- Online
			CulteDKP.ConfigTab1.checkBtn[13].Text:SetText("|cff5151de"..L["ONLINE"].."|r");
			CulteDKP.ConfigTab1.checkBtn[13]:SetScript("OnClick", CulteDKPFilterChecks)
		else -- classes
			CulteDKP.ConfigTab1.checkBtn[i]:SetScript("OnClick", CulteDKPFilterChecks)
		end		
	end

	-- Filters Check Buttons position:
	CulteDKP.ConfigTab1.checkBtn[1]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1, "TOPLEFT", 60, -70);
	CulteDKP.ConfigTab1.checkBtn[2]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[1], "TOPRIGHT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[3]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[2], "TOPRIGHT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[4]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[3], "TOPRIGHT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[5]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[4], "TOPRIGHT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[6]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[1], "BOTTOMLEFT", 0, -10);
	CulteDKP.ConfigTab1.checkBtn[7]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[2], "BOTTOMLEFT", 0, -10);
	CulteDKP.ConfigTab1.checkBtn[8]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[3], "BOTTOMLEFT", 0, -10);
	CulteDKP.ConfigTab1.checkBtn[9]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[4], "BOTTOMLEFT", 0, -10);
	CulteDKP.ConfigTab1.checkBtn[10]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[5], "BOTTOMLEFT", 0, -10);
	CulteDKP.ConfigTab1.checkBtn[11]:SetPoint("BOTTOMRIGHT", CulteDKP.ConfigTab1.checkBtn[3], "TOPLEFT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[12]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[6], "BOTTOMLEFT", 50, 0);
	CulteDKP.ConfigTab1.checkBtn[13]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[12], "TOPRIGHT", 100, 0);
	CulteDKP.ConfigTab1.checkBtn[14]:SetPoint("TOPLEFT", CulteDKP.ConfigTab1.checkBtn[13], "TOPRIGHT", 65, 0);
	
	core.ClassGraph = CulteDKP:ClassGraph()  -- draws class graph on tab1

	---------------------------------------
	-- Adjust DKP TAB
	---------------------------------------
	CulteDKP:AdjustDKPTab_Create()

	---------------------------------------
	-- Price  TAB
	---------------------------------------
	CulteDKP:PriceTab_Create()

	---------------------------------------
	-- Manage DKP TAB
	---------------------------------------
	CulteDKP.ConfigTab3.header = CulteDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab3.header:ClearAllPoints();
	CulteDKP.ConfigTab3.header:SetFontObject("CulteDKPLargeCenter");
	CulteDKP.ConfigTab3.header:SetPoint("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab3.header:SetText(L["MANAGEDKP"]);
	CulteDKP.ConfigTab3.header:SetScale(1.2)

	-- Populate Manage Tab
	CulteDKP:ManageEntries()

    
	---------------------------------------
	-- Loot History TAB
	---------------------------------------
	CulteDKP.ConfigTab5.Text = CulteDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab5.Text:ClearAllPoints();
	CulteDKP.ConfigTab5.Text:SetFontObject("CulteDKPLargeLeft");
	CulteDKP.ConfigTab5.Text:SetPoint("TOPLEFT", CulteDKP.ConfigTab5, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab5.Text:SetText(L["LOOTHISTORY"]);
	CulteDKP.ConfigTab5.Text:SetScale(1.2)
	CulteDKP.ConfigTab5.inst = CulteDKP.ConfigTab5:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab5.inst:ClearAllPoints();
	CulteDKP.ConfigTab5.inst:SetFontObject("CulteDKPSmallRight");
	CulteDKP.ConfigTab5.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	CulteDKP.ConfigTab5.inst:SetPoint("TOPRIGHT", CulteDKP.ConfigTab5, "TOPRIGHT", -40, -43);
	CulteDKP.ConfigTab5.inst:SetText(L["LOOTHISTINST1"]);
	-- Populate Loot History (LootHistory.lua)
	local looter = {}
	CulteDKP.ConfigTab5.looter = looter
	local lootFrame = {}
	CulteDKP.ConfigTab5.lootFrame = lootFrame
	for i=1, #CulteDKP:GetTable(CulteDKP_Loot, true) do
		CulteDKP.ConfigTab5.lootFrame[i] = CreateFrame("Frame", "CulteDKPLootHistoryFrame"..i, CulteDKP.ConfigTab5);
	end
	if #CulteDKP:GetTable(CulteDKP_Loot, true) > 0 then
		CulteDKP:LootHistory_Update(L["NOFILTER"])
		CulteDKP:CreateSortBox();
	end
	---------------------------------------
	-- DKP History Tab
	---------------------------------------
	CulteDKP.ConfigTab6.Text = CulteDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab6.Text:ClearAllPoints();
	CulteDKP.ConfigTab6.Text:SetFontObject("CulteDKPLargeLeft");
	CulteDKP.ConfigTab6.Text:SetPoint("TOPLEFT", CulteDKP.ConfigTab6, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab6.Text:SetText(L["DKPHISTORY"]);
	CulteDKP.ConfigTab6.Text:SetScale(1.2)

	CulteDKP.ConfigTab6.inst = CulteDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")
	CulteDKP.ConfigTab6.inst:ClearAllPoints();
	CulteDKP.ConfigTab6.inst:SetFontObject("CulteDKPSmallRight");
	CulteDKP.ConfigTab6.inst:SetTextColor(0.3, 0.3, 0.3, 0.7)
	CulteDKP.ConfigTab6.inst:SetPoint("TOPRIGHT", CulteDKP.ConfigTab6, "TOPRIGHT", -40, -43);
	if #CulteDKP:GetTable(CulteDKP_DKPHistory, true) > 0 then
		CulteDKP:DKPHistory_Update()
	end
	CulteDKP:DKPHistoryFilterBox_Create()
end
