local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

 
local function CreateRow(parent, id) -- Create 3 buttons for each row in the list

	local f;

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f = CreateFrame("Button", "$parentLine"..id, parent)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		f = CreateFrame("Button", "$parentLine"..id, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.PriceInfo = {}
	f:SetSize(core.TableWidth, core.TableRowHeight)
	f:SetHighlightTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\ListBox-Highlight");
	f:SetNormalTexture("Interface\\COMMON\\talent-blue-glow")
	f:GetNormalTexture():SetAlpha(0.2)
	--f:SetScript("OnClick", DKPTable_OnClick)
	for i=1, 3 do
		f.PriceInfo[i] = f:CreateFontString(nil, "OVERLAY");
		f.PriceInfo[i]:SetFontObject("CulteDKPSmallOutlineLeft")
		f.PriceInfo[i]:SetTextColor(1, 1, 1, 1);
		if (i==1) then
			f.PriceInfo[i].rowCounter = f:CreateFontString(nil, "OVERLAY");
			f.PriceInfo[i].rowCounter:SetFontObject("CulteDKPSmallOutlineLeft")
			f.PriceInfo[i].rowCounter:SetTextColor(1, 1, 1, 0.3);
			f.PriceInfo[i].rowCounter:SetPoint("LEFT", f, "LEFT", 3, -1);
			f.PriceInfo[i]:SetSize((370)-1, core.TableRowHeight);
			
		end
		if (i==2) then
			f.PriceInfo[i]:SetFontObject("CulteDKPSmallLeft")
			f.PriceInfo[i]:SetSize((60)-1, core.TableRowHeight);
		end
		if (i==3) then
			f.PriceInfo[i]:SetFontObject("CulteDKPSmallLeft")
			f.PriceInfo[i]:SetSize((70)-1, core.TableRowHeight);
		end
	end
	f.PriceInfo[1]:SetPoint("LEFT", 30, 0);
	f.PriceInfo[2]:SetPoint("CENTER", 155, 0)
	f.PriceInfo[3]:SetPoint("RIGHT", 15, 0)

	--f:SetScript("OnMouseDown", function(self, button)
	--	if button == "RightButton" then
	--		RightClickMenu(self)
	--	end
	--end)

	return f
end

function CulteDKP:ProcessDisenchant(loot)
	local itemName,itemLink,_,_,_,_,_,_,_,itemIcon = GetItemInfo(loot)
	local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(loot,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

	if itemName == nil and Name ~= nil then
		itemName = Name;
	end

	local mode = core.DB.modes.mode;

	if core.BiddingWindow and core.BiddingWindow:IsShown() then  -- can only process through bidding process
		if _G["CulteDKPBiddingStartBiddingButton"] then
			_G["CulteDKPBiddingStartBiddingButton"]:SetText(L["STARTBIDDING"])
			_G["CulteDKPBiddingStartBiddingButton"]:SetScript("OnClick", function (self)
				ToggleTimerBtn(self)
			end)
			timerToggle = 0;
		end

		core.BidInProgress = false;
		CulteDKP:BroadcastStopBidTimer()

		
		local search = CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID];
		local cost = CulteDKP_round(core.BiddingWindow.cost:GetNumber(), core.DB.modes.rounding);
		local minBid = cost;
		local newItem = {item=itemName, minbid=minBid, link=itemLink, icon=itemIcon, disenchants=0, lastbid=0, itemID=itemID};
		if search then
			newItem = CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID];
		end
		local numOfDisenchants = newItem["disenchants"] or 0;
		local updatedDisenchants = numOfDisenchants + 1;
		
		--Figure out adjusted cost or minValue
		if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
			local percentSign = "";
			if core.DB.modes.costvalue == "Percent" then
				percentSign = "%";
			end
			SendChatMessage("No bids for ".." "..itemLink.." for "..cost..percentSign.." "..L["DKP"].." and will be disenchanted. This will be disenchant number "..updatedDisenchants, "RAID_WARNING");
			if core.DB.defaults.DecreaseDisenchantValue then
				--If cost is 0, reset disenchants.
				if cost == 0 then
					updatedDisenchants = 0;
				end

				--TODO: Make this less hardcodeded
				--Adjust Price
				if updatedDisenchants >= 3 then
					cost = CulteDKP_round(cost/2, core.DB.modes.rounding);
					if cost < 5 then
						cost = 5
					end
				end
			end

			newItem.lastbid = cost;
			newItem.disenchants = updatedDisenchants;

		else
			minBid = CulteDKP_round(core.BiddingWindow.minBid:GetNumber(), core.DB.modes.rounding);
			newItem.minbid = minBid;
			SendChatMessage("No bids for ".." "..itemLink.." and will be disenchanted. This will be disenchant number "..updatedDisenchants, "RAID_WARNING");
		end

		newItem.disenchants = updatedDisenchants;

		if not search then
			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID] = newItem;
			core.BiddingWindow.CustomMinBid:SetShown(true);
			core.BiddingWindow.CustomMinBid:SetChecked(core.DB.defaults.CustomMinBid);
		else
			if mode == "Static Item Values" or mode == "Roll Based Bidding" or (mode == "Zero Sum" and core.DB.modes.ZeroSumBidType == "Static") then
				CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].minbid = newItem.minbid;
				CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].lastbid = newItem.lastbid;
			end

			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].link = newItem.link;
			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].icon = newItem.icon;
			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].item = newItem.itemName;
			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].itemID = newItem.itemID;
			CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID].disenchants = newItem.disenchants;
			newItem = CulteDKP:GetTable(CulteDKP_MinBids, true)[itemID];
		end
		
		CulteDKP.Sync:SendData("CDKPSetPrice", newItem);
		core.BiddingWindow:Hide()

		CulteDKP:ClearBidWindow()
	end
end

function CulteDKP:PriceTable_Update(scrollOffset)

	local numOptions = #core.PriceTable
	local numOfRows = core.PriceNumRows;
	local index, row
	local offset = CulteDKP_round(scrollOffset / core.TableRowHeight, 0)

	for i=1, numOfRows do     -- hide all rows before displaying them 1 by 1 as they show values
		row = CulteDKP.ConfigTab7.PriceTable.Rows[i];
		row:Hide();
	end
	for i=1, numOfRows do     -- show rows if they have values
		row = CulteDKP.ConfigTab7.PriceTable.Rows[i]
		index = tonumber(offset) + i;
		if core.PriceTable[index] then
			row:Show()
			row.index = index
			local curItemName = core.PriceTable[index].item;
			local curItemPrice = core.PriceTable[index].minbid;

			local curDisenchants = 0;

			if core.PriceTable[index]["disenchants"] ~= nil then
				curDisenchants = core.PriceTable[index].disenchants;
			else
				core.PriceTable[index]["disenchants"] = curDisenchants;
			end

			if core.PriceTable[index]["link"] ~= nil then
				curItemName = core.PriceTable[index].link;
				CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnEnter", function(self)
					GameTooltip:SetOwner(self:GetParent(), "ANCHOR_BOTTOMRIGHT", 0, 500);
					GameTooltip:SetHyperlink(curItemName)
					GameTooltip:Show();
				end)
				CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			else
				CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnEnter", nil)
				CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetScript("OnLeave", nil)
			end
			row.PriceInfo[1]:SetText(curItemName)
			row.PriceInfo[1].rowCounter:SetText(index)
		
			row.PriceInfo[2]:SetText(curItemPrice)
			
			row.PriceInfo[3]:SetText(curDisenchants)
		else
			row:Hide()
		end
	end

	if #core.PriceTable == 0 then  		-- Displays "No Entries Returned" if the result of filter combinations yields an empty table
		--CulteDKP_RestoreFilterOptions()
		CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[1].rowCounter:SetText("")
		CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[1]:SetText("")
		CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[2]:SetText("|cffff6060"..L["NOENTRIESRETURNED"].."|r")
		CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3]:SetText("")

		if CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3].rollrange then CulteDKP.ConfigTab7.PriceTable.Rows[1].PriceInfo[3].rollrange:SetText("") end
		CulteDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnEnter", nil)
		CulteDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnMouseDown", function()
			CulteDKP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		CulteDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnClick", function()
			CulteDKP_RestoreFilterOptions() 		-- restores filter selections to default on click.
		end)
		CulteDKP.ConfigTab7.PriceTable.Rows[1]:Show()
	--else
		--CulteDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnMouseDown", function(self, button)
		--	if button == "RightButton" then
		--		RightClickMenu(self)
		--	end
		--end)
		--CulteDKP.ConfigTab7.PriceTable.Rows[1]:SetScript("OnClick", DKPTable_OnClick)
	end


	FauxScrollFrame_Update(CulteDKP.ConfigTab7.PriceTable, numOptions, numOfRows, core.TableRowHeight, nil, nil, nil, nil, nil, nil, true) -- alwaysShowScrollBar= true to stop frame from hiding

end

function CulteDKP:PriceListSort(id, reset)
	local button;                                 -- passing "reset" forces it to do initial sort (A to Z repeatedly instead of A to Z then Z to A toggled)
	local PriceSortButtons = core.PriceSortButtons

	button = PriceSortButtons[id]

	if reset and reset ~= "Clear" then                         -- reset is useful for check boxes when you don't want it repeatedly reversing the sort
		button.Ascend = button.Ascend
	else
		button.Ascend = not button.Ascend
	end
	for k, v in pairs(PriceSortButtons) do
		if v ~= button then
			v.Ascend = nil
		end
	end
	table.sort(core.PriceTable, function(a, b)

		if id == "disenchants" then
			if a[button.Id] == nil then
				a[button.Id] = 0;
			end
			if b[button.Id] == nil then
				b[button.Id] = 0;
			end
		end

		if button.Ascend then
			if id == "item" then
				return a[button.Id] < b[button.Id]
			else
				return a[button.Id] > b[button.Id]
			end
		else
			if id == "item" then
				return a[button.Id] > b[button.Id]
			else
				return a[button.Id] < b[button.Id]
			end
		end
	end)
	core.currentSort = id;
	CulteDKP:PriceTable_Update(0)

end

function CulteDKP:PriceTab_Create()

	local numOfRows = core.PriceNumRows;
	local PriceSortButtons = core.PriceSortButtons

	CulteDKP.ConfigTab7.header = CulteDKP.ConfigTab7:CreateFontString(nil, "OVERLAY");
	CulteDKP.ConfigTab7.header:ClearAllPoints();
	CulteDKP.ConfigTab7.header:SetPoint("TOPLEFT", CulteDKP.ConfigTab7, "TOPLEFT", 15, -10);
	CulteDKP.ConfigTab7.header:SetFontObject("CulteDKPLargeCenter");
	CulteDKP.ConfigTab7.header:SetText(L["PRICETITLE"]);
	CulteDKP.ConfigTab7.header:SetScale(1.2);

	CulteDKP.ConfigTab7.description = CulteDKP.ConfigTab7:CreateFontString(nil, "OVERLAY");
	CulteDKP.ConfigTab7.description:ClearAllPoints();
	CulteDKP.ConfigTab7.description:SetPoint("TOPLEFT", CulteDKP.ConfigTab7.header, "BOTTOMLEFT", 7, -10);
	CulteDKP.ConfigTab7.description:SetWidth(400);
	CulteDKP.ConfigTab7.description:SetFontObject("CulteDKPNormalLeft");
	CulteDKP.ConfigTab7.description:SetText(L["PRICEDESC"]);

	CulteDKP.ConfigTab7.PriceTable = CreateFrame("ScrollFrame", "CulteDKPPriceScrollFrame", CulteDKP.ConfigTab7, "FauxScrollFrameTemplate")
		CulteDKP.ConfigTab7.PriceTable:SetSize(core.TableWidth, core.TableRowHeight*numOfRows)
	CulteDKP.ConfigTab7.PriceTable:SetPoint("TOPLEFT", 0, -95)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab7.PriceTable:SetBackdrop( {
			bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
			edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,
			insets = { left = 0, right = 0, top = 0, bottom = 0 }
		});

		CulteDKP.ConfigTab7.PriceTable:SetBackdropColor(0,0,0,0.4);
		CulteDKP.ConfigTab7.PriceTable:SetBackdropBorderColor(1,1,1,0.5)
	end
	
	CulteDKP.ConfigTab7.PriceTable:SetClipsChildren(false);

	CulteDKP.ConfigTab7.PriceTable.ScrollBar = FauxScrollFrame_GetChildFrames(CulteDKP.ConfigTab7.PriceTable)
	CulteDKP.ConfigTab7.PriceTable.Rows = {}

	for i=1, numOfRows do
		CulteDKP.ConfigTab7.PriceTable.Rows[i] = CreateRow(CulteDKP.ConfigTab7.PriceTable, i)
		if i==1 then
			CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab7.PriceTable, "TOPLEFT", 0, -2)
		else  
			CulteDKP.ConfigTab7.PriceTable.Rows[i]:SetPoint("TOPLEFT", CulteDKP.ConfigTab7.PriceTable.Rows[i-1], "BOTTOMLEFT")
		end
	end

	CulteDKP.ConfigTab7.PriceTable:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, core.TableRowHeight, CulteDKP:PriceTable_Update(offset))
	end)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CulteDKP.ConfigTab7.PriceTable.Headers = CreateFrame("Frame", "CulteDKPPriceTableHeaders", CulteDKP.ConfigTab7)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		CulteDKP.ConfigTab7.PriceTable.Headers = CreateFrame("Frame", "CulteDKPPriceTableHeaders", CulteDKP.ConfigTab7, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	CulteDKP.ConfigTab7.PriceTable.Headers:SetSize(500, 22)
	CulteDKP.ConfigTab7.PriceTable.Headers:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab7.PriceTable, "TOPLEFT", 0, 1)
	CulteDKP.ConfigTab7.PriceTable.Headers:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true,
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2, 
	});
	CulteDKP.ConfigTab7.PriceTable.Headers:SetBackdropColor(0,0,0,0.8);
	CulteDKP.ConfigTab7.PriceTable.Headers:SetBackdropBorderColor(1,1,1,0.5)
	CulteDKP.ConfigTab7.PriceTable.Headers:Show()

	PriceSortButtons.item = CreateFrame("Button", "$ParentPriceSortButtonItem", CulteDKP.ConfigTab7.PriceTable.Headers)
	PriceSortButtons.disenchants = CreateFrame("Button", "$ParentPriceSortButtonDisenchants", CulteDKP.ConfigTab7.PriceTable.Headers)
	PriceSortButtons.minbid = CreateFrame("Button", "$ParentPriceSortButtonDkp", CulteDKP.ConfigTab7.PriceTable.Headers)

	PriceSortButtons.minbid:SetPoint("BOTTOM", CulteDKP.ConfigTab7.PriceTable.Headers, "BOTTOM", 130, 2)
	PriceSortButtons.item:SetPoint("RIGHT", PriceSortButtons.minbid, "LEFT", 0, 0)
	PriceSortButtons.disenchants:SetPoint("LEFT", PriceSortButtons.minbid, "RIGHT")

	for k, v in pairs(PriceSortButtons) do
		v.Id = k
		v:SetHighlightTexture("Interface\\BUTTONS\\BlueGrad64_faded.blp");
		if k == "minbid" then
			v:SetSize((60), core.TableRowHeight)
		elseif k == "item" then
			v:SetSize((370), core.TableRowHeight)
		else
			v:SetSize((70), core.TableRowHeight)
		end
		
		v:SetScript("OnClick", function(self) CulteDKP:PriceListSort(self.Id, "Clear") end)
	end

	PriceSortButtons.item.t = PriceSortButtons.item:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.item.t:SetFontObject("CulteDKPNormal")
	PriceSortButtons.item.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.item.t:SetPoint("LEFT", PriceSortButtons.item, "LEFT", 50, 0);
	PriceSortButtons.item.t:SetText("Item Name");

 	PriceSortButtons.disenchants.t = PriceSortButtons.disenchants:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.disenchants.t:SetFontObject("CulteDKPNormal");
	PriceSortButtons.disenchants.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.disenchants.t:SetPoint("CENTER", PriceSortButtons.disenchants, "CENTER", 0, 0);
	PriceSortButtons.disenchants.t:SetText("Disenchants");
	
	PriceSortButtons.minbid.t = PriceSortButtons.minbid:CreateFontString(nil, "OVERLAY")
	PriceSortButtons.minbid.t:SetFontObject("CulteDKPNormal")
	PriceSortButtons.minbid.t:SetTextColor(1, 1, 1, 1);
	PriceSortButtons.minbid.t:SetPoint("CENTER", PriceSortButtons.minbid, "CENTER", 0, 0);
	PriceSortButtons.minbid.t:SetText("DKP");
	core.PriceSortButtons = PriceSortButtons;

	CulteDKP:PriceTable_Update(0)
end
