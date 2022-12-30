local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

local players;
local reason;
local dkp;
local formdate = date;
local date;
local year;
local month;
local day;
local timeofday;
local player_table = {};
local classSearch;
local playerString = "";
local filter;
local c;
local maxDisplayed = 10
local currentLength = 10;
local currentRow = 0;
local btnText = 10;
local curDate;
local history = {};
local menuFrame = CreateFrame("Frame", "CulteDKPDeleteDKPMenuFrame", UIParent, "UIDropDownMenuTemplate")


function CulteDKP:SortDKPHistoryTable()             -- sorts the DKP History Table by date/time
  table.sort(CulteDKP:GetTable(CulteDKP_DKPHistory, true), function(a, b)
    return a["date"] > b["date"]
  end)
end

local function GetSortOptions()
	local PlayerList = {}
	for i=1, #CulteDKP:GetTable(CulteDKP_DKPTable, true) do
		local playerSearch = CulteDKP:Table_Search(PlayerList, CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player)
		if not playerSearch then
			tinsert(PlayerList, CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player)
		end
	end
	table.sort(PlayerList, function(a, b)
		return a < b
	end)
	return PlayerList;
end

function CulteDKP:DKPHistory_Reset()
	if not CulteDKP.ConfigTab6 then return end
	currentRow = 0
	currentLength = maxDisplayed;
	curDate = nil;
	btnText = maxDisplayed;
	if CulteDKP.ConfigTab6.loadMoreBtn then
		CulteDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
	end

	if CulteDKP.ConfigTab6.history then
		for i=1, #CulteDKP.ConfigTab6.history do
			if CulteDKP.ConfigTab6.history[i] then
				CulteDKP.ConfigTab6.history[i].h:SetText("")
				CulteDKP.ConfigTab6.history[i].h:Hide()
				CulteDKP.ConfigTab6.history[i].d:SetText("")
				CulteDKP.ConfigTab6.history[i].d:Hide()
				CulteDKP.ConfigTab6.history[i].s:SetText("")
				CulteDKP.ConfigTab6.history[i].s:Hide()
				CulteDKP.ConfigTab6.history[i]:SetHeight(10)
				CulteDKP.ConfigTab6.history[i]:Hide()
			end
		end
	end
end

function CulteDKP:DKPHistoryFilterBox_Create()
	local PlayerList = GetSortOptions();
	local curSelected = 0;

	-- Create the dropdown, and configure its appearance
	if not filterDropdown then
		--filterDropdown = CreateFrame("FRAME", "CulteDKPDKPHistoryFilterNameDropDown", CulteDKP.ConfigTab6, "CulteDKPUIDropDownMenuTemplate")
		filterDropdown = LibDD:Create_UIDropDownMenu("CulteDKPDKPHistoryFilterNameDropDown", CulteDKP.ConfigTab6);
	end

	-- Create and bind the initialization function to the dropdown menu
		LibDD:UIDropDownMenu_Initialize(filterDropdown, function(self, level, menuList)
		
		local filterName = LibDD:UIDropDownMenu_CreateInfo()
		local ranges = {1}
		while ranges[#ranges] < #PlayerList do
			table.insert(ranges, ranges[#ranges]+20)
		end

		if (level or 1) == 1 then
			local numSubs = ceil(#PlayerList/20)
			filterName.func = self.FilterSetValue
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["NOFILTER"], L["NOFILTER"], L["NOFILTER"], L["NOFILTER"] == curfilterName, true
			LibDD:UIDropDownMenu_AddButton(filterName)
			filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"], L["DELETEDENTRY"] == curfilterName, true
			LibDD:UIDropDownMenu_AddButton(filterName)
		
			for i=1, numSubs do
				local max = i*20;
				if max > #PlayerList then max = #PlayerList end
				filterName.text, filterName.checked, filterName.menuList, filterName.hasArrow = strsub(PlayerList[((i*20)-19)], 1, 1).."-"..strsub(PlayerList[max], 1, 1), curSelected >= (i*20)-19 and curSelected <= i*20, i, true
				LibDD:UIDropDownMenu_AddButton(filterName)
			end
			
		else
			filterName.func = self.FilterSetValue
			for i=ranges[menuList], ranges[menuList]+19 do
				if PlayerList[i] then
					local classSearch = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), PlayerList[i])
				    local c;

				    if classSearch then
				     	c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[classSearch[1][1]].class)
				    else
				     	c = { hex="ff444444" }
				    end
					filterName.text, filterName.arg1, filterName.arg2, filterName.checked, filterName.isNotRadio = "|c"..c.hex..PlayerList[i].."|r", PlayerList[i], "|c"..c.hex..PlayerList[i].."|r", PlayerList[i] == curfilterName, true
					LibDD:UIDropDownMenu_AddButton(filterName, level)
				end
			end
		end
	end)

	filterDropdown:SetPoint("TOPRIGHT", CulteDKP.ConfigTab6, "TOPRIGHT", -13, -11)

	LibDD:UIDropDownMenu_SetWidth(filterDropdown, 150)
	LibDD:UIDropDownMenu_SetText(filterDropdown, curfilterName or L["NOFILTER"])
	
  -- Dropdown Menu Function
  function filterDropdown:FilterSetValue(newValue, arg2)
    if curfilterName ~= newValue then curfilterName = newValue else curfilterName = nil end
    LibDD:UIDropDownMenu_SetText(filterDropdown, arg2)
    
    if newValue == L["NOFILTER"] then
    	filter = nil;
    	maxDisplayed = 10; 				
    	curSelected = 0
    elseif newValue == L["DELETEDENTRY"] then
    	filter = newValue;
    	maxDisplayed = 10; 				
    	curSelected = 0
    else
	    filter = newValue;
	    maxDisplayed = 30;
	    local search = CulteDKP:Table_Search(PlayerList, newValue)
	    curSelected = search[1]
    end

    CulteDKP:DKPHistory_Update(true)
    LibDD:CloseDropDownMenus()
  end
end

local function CulteDKPDeleteDKPEntry(index, timestamp, item)  -- index = entry index (Vapok-1), item = # of the entry on DKP History tab; may be different than the key of DKPHistory if hidden fields exist
	-- pop confirmation. If yes, cycles through CulteDKP:GetTable(CulteDKP_DKPHistory, true).players and every name it finds, it refunds them (or strips them of) dkp.
	-- if deleted is the weekly decay,     curdkp * (100 / (100 - decayvalue))
	local reason_header = CulteDKP.ConfigTab6.history[item].d:GetText();
	if strfind(reason_header, L["OTHER"].."- ") then reason_header = reason_header:gsub(L["OTHER"].." -- ", "") end
	if strfind(reason_header, "%%") then
		reason_header = gsub(reason_header, "%%", "%%%%")
	end
	local confirm_string = L["CONFIRMDELETEENTRY1"]..":\n\n"..reason_header.."\n\n|CFFFF0000"..L["WARNING"].."|r: "..L["DELETEENTRYREFUNDCONF"];

	StaticPopupDialogs["CONFIRM_DELETE"] = {

		text = confirm_string,
		button1 = L["YES"],
		button2 = L["NO"],
		OnAccept = function()

		-- add new entry and add "delted_by" field to entry being "deleted". make new entry exact opposite of "deleted" entry
		-- new entry gets "deletes", old entry gets "deleted_by", deletes = deleted_by index. and vice versa
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), index, "index")

			if search then
				local players = {strsplit(",", strsub(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].players, 1, -2))} 	-- cuts off last "," from string to avoid creating an empty value
				local dkp, mod;
				local dkpString = "";
				local curOfficer = UnitName("player")
				local curTime = time()
				local newIndex = curOfficer.."-"..curTime

				if strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].dkp, "%-%d*%.?%d+%%") then 		-- determines if it's a mass decay
					dkp = {strsplit(",", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].dkp)}
					mod = "perc";
				else
					dkp = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].dkp
					mod = "whole"
				end

				for i=1, #players do
					if mod == "perc" then
						local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), players[i])

						if search then
							local inverted = tonumber(dkp[i]) * -1
							CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp + inverted
							dkpString = dkpString..inverted..",";

							if i == #players then
								dkpString = dkpString..dkp[#dkp]
							end
						end
					else
						local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), players[i])

						if search then
							local inverted = tonumber(dkp) * -1

							CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp + inverted

							if tonumber(dkp) > 0 then
								CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_gained = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_gained + inverted
							end
							
							dkpString = inverted;
						end
					end
				end
				
				CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].deletedby = newIndex
				table.insert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, { players=CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].players, dkp=dkpString, date=curTime, reason="Delete Entry", index=newIndex, deletes=index })
				CulteDKP.Sync:SendData("CDKPDelSync", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])

				if CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
					CulteDKP:DKPHistory_Update(true)
				end

				CulteDKP:StatusVerify_Update()
				CulteDKP:DKPTable_Update()
			end
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show ("CONFIRM_DELETE")
end

local function RightClickDKPMenu(self, index, timestamp, item)
	local header
	local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), index, "index")

	if search then
		menu = {
		{ text = CulteDKP.ConfigTab6.history[item].d:GetText():gsub(L["OTHER"].." -- ", ""), isTitle = true},
		{ text = L["DELETEDKPENTRY"], func = function()
			CulteDKPDeleteDKPEntry(index, timestamp, item)
		end },
		}
		EasyMenu(menu, menuFrame, "cursor", 0 , 0, "MENU", 2);
	end
end

function CulteDKP:DKPHistory_Update(reset)
	local DKPHistory = {}
	CulteDKP:SortDKPHistoryTable()

	if not CulteDKP.UIConfig:IsShown() then 			-- prevents history update from firing if the DKP window is not opened (eliminate lag). Update run when opened
		return;
	end

	if reset then
		CulteDKP:DKPHistory_Reset()
	end

	if filter and filter ~= L["DELETEDENTRY"] then
		for i=1, #CulteDKP:GetTable(CulteDKP_DKPHistory, true) do
			if not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletedby and CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].reason ~= "Migration Correction" and (strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].players, ","..filter..",") or strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].players, filter..",") == 1) then
				table.insert(DKPHistory, CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i])
			end
		end
	elseif filter and filter == L["DELETEDENTRY"] then
		for i=1, #CulteDKP:GetTable(CulteDKP_DKPHistory, true) do
			if CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes then
				table.insert(DKPHistory, CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i])
			end
		end
	elseif not filter then
		for i=1, #CulteDKP:GetTable(CulteDKP_DKPHistory, true) do
			if not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].hidden and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletedby then
				table.insert(DKPHistory, CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i])
			end
		end
	end
	
	CulteDKP.ConfigTab6.history = history;

	if currentLength > #DKPHistory then currentLength = #DKPHistory end

	local j=currentRow+1
	local HistTimer = 0
	local processing = false
	local DKPHistTimer = DKPHistTimer or CreateFrame("StatusBar", nil, UIParent)
	DKPHistTimer:SetScript("OnUpdate", function(self, elapsed)
		HistTimer = HistTimer + elapsed
		if HistTimer > 0.001 and j <= currentLength and not processing then
			local i = j
			processing = true

			if CulteDKP.ConfigTab6.loadMoreBtn then
				CulteDKP.ConfigTab6.loadMoreBtn:Hide()
			end

			local curOfficer, curIndex

			if DKPHistory[i].index then
				curOfficer, curIndex = strsplit("-", DKPHistory[i].index)
			else
				curOfficer = "Unknown"
			end

			if not CulteDKP.ConfigTab6.history[i] then
				if i==1 then
					CulteDKP.ConfigTab6.history[i] = CreateFrame("Frame", "CulteDKP:GetTable(CulteDKP_DKPHistory, true)Tab", CulteDKP.ConfigTab6);
					CulteDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab6, "TOPLEFT", 0, -45)
					CulteDKP.ConfigTab6.history[i]:SetWidth(400)
				else
					CulteDKP.ConfigTab6.history[i] = CreateFrame("Frame", "CulteDKP:GetTable(CulteDKP_DKPHistory, true)Tab", CulteDKP.ConfigTab6);
					CulteDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, 0)
					CulteDKP.ConfigTab6.history[i]:SetWidth(400)
				end

				CulteDKP.ConfigTab6.history[i].h = CulteDKP.ConfigTab6:CreateFontString(nil, "OVERLAY") 		-- entry header
				CulteDKP.ConfigTab6.history[i].h:SetFontObject("CulteDKPNormalLeft");
				CulteDKP.ConfigTab6.history[i].h:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i], "TOPLEFT", 15, 0);
				CulteDKP.ConfigTab6.history[i].h:SetWidth(400)

				CulteDKP.ConfigTab6.history[i].d = CulteDKP.ConfigTab6:CreateFontString(nil, "OVERLAY") 		-- entry description
				CulteDKP.ConfigTab6.history[i].d:SetFontObject("CulteDKPSmallLeft");
				CulteDKP.ConfigTab6.history[i].d:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i].h, "BOTTOMLEFT", 5, -2);
				CulteDKP.ConfigTab6.history[i].d:SetWidth(400)

				CulteDKP.ConfigTab6.history[i].s = CulteDKP.ConfigTab6:CreateFontString(nil, "OVERLAY")			-- entry player string
				CulteDKP.ConfigTab6.history[i].s:SetFontObject("CulteDKPTinyLeft");
				CulteDKP.ConfigTab6.history[i].s:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i].d, "BOTTOMLEFT", 15, -4);
				CulteDKP.ConfigTab6.history[i].s:SetWidth(400)

				CulteDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
			    	if button == "RightButton" then
		   				if core.IsOfficer == true then
		   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
		   				end
		   			end
			    end)
			end

			local delete_on_date, delete_day, delete_timeofday, delete_year, delete_month, delete_day, delOfficer;

			if filter == L["DELETEDENTRY"] then
				local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), DKPHistory[i].deletes, "index")

				if search then
					delOfficer,_ = strsplit("-", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].deletedby)
					players = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].players;
					if strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].reason, L["OTHER"].." - ") == 1 then
						reason = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].reason:gsub(L["OTHER"].." -- ", "");
					else
						reason = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].reason
					end
					dkp = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].dkp;
					date = CulteDKP:FormatTime(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].date);
					delete_on_date = CulteDKP:FormatTime(DKPHistory[i].date)
					delete_day = strsub(delete_on_date, 1, 8)
					delete_timeofday = strsub(delete_on_date, 10)
					delete_year, delete_month, delete_day = strsplit("/", delete_day)
				end
			else
				players = DKPHistory[i].players;
				if strfind(DKPHistory[i].reason, L["OTHER"].." - ") == 1 then
					reason = DKPHistory[i].reason:gsub(L["OTHER"].." -- ", "");
				else
					reason = DKPHistory[i].reason
				end
				dkp = DKPHistory[i].dkp;
				date = CulteDKP:FormatTime(DKPHistory[i].date);

				if CulteDKP.ConfigTab6.history[i].b then
					CulteDKP.ConfigTab6.history[i].b:Hide()
				end
			end
			
			
			player_table = { strsplit(",", players) } or players
			if player_table[1] ~= nil and #player_table > 1 then	-- removes last entry in table which ends up being nil, which creates an additional comma at the end of the string
				tremove(player_table, #player_table)
			end

			for k=1, #player_table do
				classSearch = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), player_table[k])

				if classSearch then
					c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[classSearch[1][1]].class)
					if k < #player_table then
						playerString = playerString.."|c"..c.hex..player_table[k].."|r, "
					elseif k == #player_table then
						playerString = playerString.."|c"..c.hex..player_table[k].."|r"
					end
				end
			end

			CulteDKP.ConfigTab6.history[i]:SetScript("OnMouseDown", function(self, button)
		    	if button == "RightButton" and filter ~= L["DELETEDENTRY"] then
	   				if core.IsOfficer == true then
	   					RightClickDKPMenu(self, DKPHistory[i].index, DKPHistory[i].date, i)
	   				end
	   			end
		    end)
		    CulteDKP.ConfigTab6.inst:Show();

			day = strsub(date, 1, 8)
			timeofday = strsub(date, 10)
			year, month, day = strsplit("/", day)

			if day ~= curDate then
				if i~=1 then
					CulteDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, -20)
				end
				CulteDKP.ConfigTab6.history[i].h:SetText(month.."/"..day.."/"..year);
				CulteDKP.ConfigTab6.history[i].h:Show()
				curDate = day;
			else
				if i~=1 then
					CulteDKP.ConfigTab6.history[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i-1], "BOTTOMLEFT", 0, 0)
				end
				CulteDKP.ConfigTab6.history[i].h:Hide()
			end

			local officer_search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), curOfficer, "player")
	    	if officer_search then
		     	c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[officer_search[1][1]].class)
		    else
		     	c = { hex="ff444444" }
		    end
			
			if not strfind(dkp, "-") then
				CulteDKP.ConfigTab6.history[i].d:SetText("|cff00ff00"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |c"..c.hex..curOfficer.."|r");
			else
				if filter and filter ~= L["DELETEDENTRY"] and strfind(reason, L["WEEKLYDECAY"]) then
					local decay = {strsplit(",", dkp)}
					-- get substring till player name and split to get correct player index for decay list
					local playerIndex = {strsplit(",", string.sub(players, 1, strfind(players, filter..",")))};
					-- Print decay value using playerIndex instead of percentage
					CulteDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..decay[#playerIndex].." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |c"..c.hex..curOfficer.."|r");
				elseif strfind(reason, L["WEEKLYDECAY"]) or strfind(reason, "Migration Correction") then
					local decay = {strsplit(",", dkp)}
					CulteDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..decay[#decay].." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |c"..c.hex..curOfficer.."|r"..decay[#decay].." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |c"..c.hex..curOfficer.."|r");
				else
					CulteDKP.ConfigTab6.history[i].d:SetText("|cffff0000"..dkp.." "..L["DKP"].."|r - |cff616ccf"..reason.."|r |cff555555("..timeofday..")|r by |c"..c.hex..curOfficer.."|r");
				end
			end

			CulteDKP.ConfigTab6.history[i].d:Show()

			if not filter or (filter and filter == L["DELETEDENTRY"]) then
				CulteDKP.ConfigTab6.history[i].s:SetText(playerString);
				CulteDKP.ConfigTab6.history[i].s:Show()
			else
				CulteDKP.ConfigTab6.history[i].s:Hide()
			end

			if filter and filter ~= L["DELETEDENTRY"] then
				CulteDKP.ConfigTab6.history[i]:SetHeight(CulteDKP.ConfigTab6.history[i].s:GetHeight() + CulteDKP.ConfigTab6.history[i].h:GetHeight() + CulteDKP.ConfigTab6.history[i].d:GetHeight())
			else
				CulteDKP.ConfigTab6.history[i]:SetHeight(CulteDKP.ConfigTab6.history[i].s:GetHeight() + CulteDKP.ConfigTab6.history[i].h:GetHeight() + CulteDKP.ConfigTab6.history[i].d:GetHeight() + 10)
				if filter == L["DELETEDENTRY"] then
					if not CulteDKP.ConfigTab6.history[i].b then
						CulteDKP.ConfigTab6.history[i].b = CreateFrame("Button", "RightClickButtonDKPHistory"..i, CulteDKP.ConfigTab6.history[i]);
					end
					CulteDKP.ConfigTab6.history[i].b:Show()
					CulteDKP.ConfigTab6.history[i].b:SetPoint("TOPLEFT", CulteDKP.ConfigTab6.history[i], "TOPLEFT", 0, 0)
					CulteDKP.ConfigTab6.history[i].b:SetPoint("BOTTOMRIGHT", CulteDKP.ConfigTab6.history[i], "BOTTOMRIGHT", 0, 0)
					CulteDKP.ConfigTab6.history[i].b:SetScript("OnEnter", function(self)
				    	local col
				    	local s = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), delOfficer, "player")
				    	if s then
				    		col = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[s[1][1]].class)
				    	else
				    		col = { hex="ff444444"}
				    	end
						GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0);
						GameTooltip:SetText(L["DELETEDBY"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddDoubleLine("|c"..col.hex..delOfficer.."|r", delete_month.."/"..delete_day.."/"..delete_year.." @ "..delete_timeofday, 1,0,0,1,1,1)
						GameTooltip:Show()
					end);
					CulteDKP.ConfigTab6.history[i].b:SetScript("OnLeave", function(self)
						GameTooltip:Hide();
					end)
				end
			end

			playerString = ""
			table.wipe(player_table)

			CulteDKP.ConfigTab6.history[i]:Show()

			currentRow = currentRow + 1;
			processing = false
		    j=i+1
		    HistTimer = 0
		elseif j > currentLength then
			DKPHistTimer:SetScript("OnUpdate", nil)
			HistTimer = 0

			if not CulteDKP.ConfigTab6.loadMoreBtn then
				CulteDKP.ConfigTab6.loadMoreBtn = CreateFrame("Button", nil, CulteDKP.ConfigTab6, "CulteDKPButtonTemplate")
				CulteDKP.ConfigTab6.loadMoreBtn:SetSize(100, 30);
				CulteDKP.ConfigTab6.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...");
				CulteDKP.ConfigTab6.loadMoreBtn:GetFontString():SetTextColor(1, 1, 1, 1)
				CulteDKP.ConfigTab6.loadMoreBtn:SetNormalFontObject("CulteDKPSmallCenter");
				CulteDKP.ConfigTab6.loadMoreBtn:SetHighlightFontObject("CulteDKPSmallCenter");
				CulteDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", CulteDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
				CulteDKP.ConfigTab6.loadMoreBtn:SetScript("OnClick", function(self)
					currentLength = currentLength + maxDisplayed;
					CulteDKP:DKPHistory_Update()
					CulteDKP.ConfigTab6.loadMoreBtn:SetText(L["LOAD"].." "..btnText.." "..L["MORE"].."...")
					CulteDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", CulteDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10)
				end)
			end

			if CulteDKP.ConfigTab6.loadMoreBtn and currentRow == #DKPHistory then 
				CulteDKP.ConfigTab6.loadMoreBtn:Hide();
			elseif CulteDKP.ConfigTab6.loadMoreBtn and currentRow < #DKPHistory then
				if (#DKPHistory - currentRow) < btnText then btnText = (#DKPHistory - currentRow) end
				CulteDKP.ConfigTab6.loadMoreBtn:SetText(string.format(L["LOAD50MORE"], btnText).."...")
				CulteDKP.ConfigTab6.loadMoreBtn:SetPoint("TOP", CulteDKP.ConfigTab6.history[currentRow], "BOTTOM", 0, -10);
				CulteDKP.ConfigTab6.loadMoreBtn:Show()
			end
		end
	end)
end
