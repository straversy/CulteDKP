local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

local function Remove_Entries()
	CulteDKP:StatusVerify_Update()
	local numPlayers = 0;
	local removedUsers, c;
	local deleted = {};

	for i=1, #core.SelectedData do
		local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), core.SelectedData[i]["player"]);
		local flag = false -- flag = only create archive entry if they appear anywhere in the history. If there's no history, there's no reason anyone would have it.
		local curTime = time()

		if search then
			local path = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]]

			for i=1, #CulteDKP:GetTable(CulteDKP_DKPHistory, true) do
				if strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].players, ","..path.player..",") or strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].players, path.player..",") == 1 then
					flag = true
				end
			end

			for i=1, #CulteDKP:GetTable(CulteDKP_Loot, true) do
				if CulteDKP:GetTable(CulteDKP_Loot, true)[i].player == path.player then
					flag = true
				end
			end
			
			if flag then 		-- above 2 loops flags character if they have any loot/dkp history. Only inserts to archive and broadcasts if found. Other players will not have the entry if no history exists
				if not CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player] then
					CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player] = { deleted=true, edited=curTime }
				end
				CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player].dkp = path.dkp
				CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player].lifetime_spent = path.lifetime_spent
				CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player].lifetime_gained = path.lifetime_gained
				CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player].deleted = true
				CulteDKP:GetTable(CulteDKP_Archive, true)[core.SelectedData[i].player].edited = curTime
			end

			c = CulteDKP:GetCColors(core.SelectedData[i]["class"])
			if i==1 then
				removedUsers = "|c"..c.hex..core.SelectedData[i]["player"].."|r"
			else
				removedUsers = removedUsers..", |c"..c.hex..core.SelectedData[i]["player"].."|r"
			end
			numPlayers = numPlayers + 1

			tremove(CulteDKP:GetTable(CulteDKP_DKPTable, true), search[1][1])
			tinsert(deleted, { player=path.player, deleted=true })
			CulteDKP:GetTable(CulteDKP_Profiles, true)[path.player] = nil;

			local search2 = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Standby, true), core.SelectedData[i].player, "player");

			if search2 then
				table.remove(CulteDKP:GetTable(CulteDKP_Standby, true), search2[1][1])
			end
		end
	end
	table.wipe(core.SelectedData)
	CulteDKPSelectionCount_Update()
	CulteDKP:FilterDKPTable(core.currentSort, "reset")
	CulteDKP:Print("["..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).."] ".."Removed "..numPlayers.." player(s): "..removedUsers)
	CulteDKP:ClassGraph_Update()

	if #deleted >0 then
		CulteDKP.Sync:SendData("CDKPDelUsers", deleted)
	end
end

local function AddRaidToDKPTable()
	local GroupType = "none";

	if IsInRaid() then
		GroupType = "raid"
	elseif IsInGroup() then
		GroupType = "party"
	end

	if GroupType ~= "none" then
		local tempName,tempClass;
		local addedUsers, c
		local numPlayers = 0;
		local guildSize = GetNumGuildMembers();
		local name, rank, rankIndex;
		local InGuild = false; -- Only adds player to list if the player is found in the guild roster.
		local GroupSize;
		local FlagRecovery = false
		local curTime = time()
		local entities = {}

		if GroupType == "raid" then
			GroupSize = 40
		elseif GroupType == "party" then
			GroupSize = 5
		end

		for i=1, GroupSize do
			tempName,_,_,_,_,tempClass = GetRaidRosterInfo(i)
			for j=1, guildSize do
				name, rank, rankIndex = GetGuildRosterInfo(j)
				name = strsub(name, 1, string.find(name, "-")-1)						-- required to remove server name from player (can remove in classic if this is not an issue)
				if name == tempName then
					InGuild = true;
				end
			end
			if tempName then
				local profile = CulteDKP:GetDefaultEntity();
				if not CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), tempName) then
					if InGuild then
						profile.player=tempName;
						profile.class=tempClass;
						profile.rank = rankIndex;
						profile.rankName = rank;
					else
						profile.player=tempName;
						profile.class=tempClass;
					end
					tinsert(CulteDKP:GetTable(CulteDKP_DKPTable, true), profile);
					tinsert(entities, profile);
					CulteDKP:GetTable(CulteDKP_Profiles, true)[name] = profile;
					numPlayers = numPlayers + 1;
					c = CulteDKP:GetCColors(tempClass)
					if addedUsers == nil then
						addedUsers = "|c"..c.hex..tempName.."|r"; 
					else
						addedUsers = addedUsers..", |c"..c.hex..tempName.."|r"
					end
					if CulteDKP:GetTable(CulteDKP_Archive, true)[tempName] and CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].deleted then
						profile.dkp = CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].dkp
						profile.lifetime_gained = CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].lifetime_gained
						profile.lifetime_spent = CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].lifetime_spent
						CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].deleted = "Recovered"
						CulteDKP:GetTable(CulteDKP_Archive, true)[tempName].edited = curTime
						FlagRecovery = true
					end
				end
			end
		end
		if addedUsers then
			CulteDKP:Print("["..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if core.ClassGraph then
			CulteDKP:ClassGraph_Update()
		else
			CulteDKP:ClassGraph()
		end
		if FlagRecovery then 
			CulteDKP:Print(L["YOUHAVERECOVERED"])
		end
		CulteDKP:FilterDKPTable(core.currentSort, "reset")
		if numPlayers > 0 then
			CulteDKP.Sync:SendData("CDKPAddUsers", CopyTable(entities))
		end
	else
		CulteDKP:Print(L["NOPARTYORRAID"])
	end
end

local function AddGuildToDKPTable(rank, level)
	local guildSize = GetNumGuildMembers();
	local class, addedUsers, c, name, rankName, rankIndex, charLevel;
	local numPlayers = 0;
	local FlagRecovery = false
	local curTime = time()
	local entities = {}

	for i=1, guildSize do
		name,rankName,rankIndex,charLevel,_,_,_,_,_,_,class = GetGuildRosterInfo(i)
		name = strsub(name, 1, string.find(name, "-")-1)			-- required to remove server name from player (can remove in classic if this is not an issue)
		local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), name)

		if not search and (level == nil or charLevel >= level) and (rank == nil or rankIndex == rank) then
			local profile = CulteDKP:GetDefaultEntity();

			profile.player=name;
			profile.class=class;
			profile.rank = rankIndex;
			profile.rankName = rank;

			tinsert(CulteDKP:GetTable(CulteDKP_DKPTable, true), profile);
			tinsert(entities, profile);
			CulteDKP:GetTable(CulteDKP_Profiles, true)[name] = profile;

			numPlayers = numPlayers + 1;
			c = CulteDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|c"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |c"..c.hex..name.."|r"
			end
			if CulteDKP:GetTable(CulteDKP_Archive, true)[name] and CulteDKP:GetTable(CulteDKP_Archive, true)[name].deleted then
				profile.dkp = CulteDKP:GetTable(CulteDKP_Archive, true)[name].dkp
				profile.lifetime_gained = CulteDKP:GetTable(CulteDKP_Archive, true)[name].lifetime_gained
				profile.lifetime_spent = CulteDKP:GetTable(CulteDKP_Archive, true)[name].lifetime_spent
				CulteDKP:GetTable(CulteDKP_Archive, true)[name].deleted = "Recovered"
				CulteDKP:GetTable(CulteDKP_Archive, true)[name].edited = curTime
				FlagRecovery = true
			end
		end
	end
	CulteDKP:FilterDKPTable(core.currentSort, "reset")
	if addedUsers then
		CulteDKP:Print("["..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
	end
	if FlagRecovery then 
		CulteDKP:Print(L["YOUHAVERECOVERED"])
	end
	if core.ClassGraph then
		CulteDKP:ClassGraph_Update()
	else
		CulteDKP:ClassGraph()
	end
	if numPlayers > 0 then
		CulteDKP.Sync:SendData("CDKPAddUsers", CopyTable(entities))
	end
end

local function AddTargetToDKPTable()
	local name = UnitName("target");
	local _,class = UnitClass("target");
	local c;
	local curTime = time()
	local entities = {}

	local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), name)
	local profile = CulteDKP:GetDefaultEntity();
	
	profile.player=name;
	profile.class=class;

	if not search then
		tinsert(CulteDKP:GetTable(CulteDKP_DKPTable, true), profile);
		tinsert(entities, profile);
		CulteDKP:GetTable(CulteDKP_Profiles, true)[name] = profile;

		CulteDKP:FilterDKPTable(core.currentSort, "reset")
		c = CulteDKP:GetCColors(class)
		CulteDKP:Print("["..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).."] "..L["ADDED"].." |c"..c.hex..name.."|r")

		if addedUsers == nil then
			addedUsers = "|c"..c.hex..name.."|r"; 
		else
			addedUsers = addedUsers..", |c"..c.hex..name.."|r"
		end


		if core.ClassGraph then
			CulteDKP:ClassGraph_Update()
		else
			CulteDKP:ClassGraph()
		end
		if CulteDKP:GetTable(CulteDKP_Archive, true)[name] and CulteDKP:GetTable(CulteDKP_Archive, true)[name].deleted then
			profile.dkp = CulteDKP:GetTable(CulteDKP_Archive, true)[name].dkp
			profile.lifetime_gained = CulteDKP:GetTable(CulteDKP_Archive, true)[name].lifetime_gained
			profile.lifetime_spent = CulteDKP:GetTable(CulteDKP_Archive, true)[name].lifetime_spent
			CulteDKP:GetTable(CulteDKP_Archive, true)[name].deleted = "Recovered"
			CulteDKP:GetTable(CulteDKP_Archive, true)[name].edited = curTime
			CulteDKP:Print(L["YOUHAVERECOVERED"])
		end
		CulteDKP.Sync:SendData("CDKPAddUsers", CopyTable(entities))
	end
end

function CulteDKP:CopyProfileToTeam(row, team)
	local entities = {};
	local copy = {};
	if #core.SelectedData > 1 then
		--Multiple Selections
		copy = CopyTable(core.SelectedData)
	else
		--Only Profile Selected
		tinsert(copy,core.WorkingTable[row])
	end

	for i=1, #copy do
		local profile = copy[i];
		local name = profile.player;

		local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, team), name);

		if not search then
			profile.norecover = true;
			tinsert(entities, profile);
		end
	end

	if #entities > 0 then
		CulteDKP:AddEntitiesToDKPTable(CopyTable(entities), team);
		CulteDKP.Sync:SendData("CDKPAddUsers", CopyTable(entities), nil, team);
	end
end

function CulteDKP:AddEntitiesToDKPTable(entities, team)
	team = team or CulteDKP:GetCurrentTeamIndex();
	local addedUsers;
	local numPlayers = 0;
	local curTime = time()

	for i=1, #entities do
		local name = entities[i].player;
		local class = entities[i].class;
		local profile = entities[i];
		local c;
	
		local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, team), name)
	
		CulteDKP:GetTable(CulteDKP_Profiles, true, team)[name] = profile;

		if not search then
	
			numPlayers = numPlayers + 1;
			c = CulteDKP:GetCColors(class)
			if addedUsers == nil then
				addedUsers = "|c"..c.hex..name.."|r"; 
			else
				addedUsers = addedUsers..", |c"..c.hex..name.."|r"
			end
			if profile.norecover then
				profile.norecover = nil;
			else
				if CulteDKP:GetTable(CulteDKP_Archive, true, team)[name] and CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].deleted then
					profile.dkp = CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].dkp
					profile.lifetime_gained = CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].lifetime_gained
					profile.lifetime_spent = CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].lifetime_spent
					CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].deleted = "Recovered"
					CulteDKP:GetTable(CulteDKP_Archive, true, team)[name].edited = curTime
					FlagRecovery = true
				end
			end
			tinsert(CulteDKP:GetTable(CulteDKP_DKPTable, true, team), CopyTable(profile));
		end
	end

	if numPlayers > 0  then
		CulteDKP:FilterDKPTable(core.currentSort, "reset")
		if addedUsers then
			CulteDKP:Print("["..CulteDKP:GetTeamName(team).."] "..L["ADDED"].." "..numPlayers.." "..L["PLAYERS"]..": "..addedUsers)
		end
		if FlagRecovery then 
			CulteDKP:Print(L["YOUHAVERECOVERED"])
		end
		if core.ClassGraph then
			CulteDKP:ClassGraph_Update()
		else
			CulteDKP:ClassGraph()
		end
	end
end


function CulteDKP:GetGuildRankList()
	local numRanks = GuildControlGetNumRanks()
	local tempTable = {}
	for i=1, numRanks do
		table.insert(tempTable, {index = i-1, name = GuildControlGetRankName(i)})
		tempTable[GuildControlGetRankName(i)] = i-1
	end
	
	return tempTable;
end

-------
-- TEAM FUNCTIONS
-------

function CulteDKP:ChangeTeamName(index, _name) 
	CulteDKP:GetTable(CulteDKP_DB, false)["teams"][tostring(index)].name = _name;
	CulteDKP.Sync:SendData("CDKPTeams", {Teams =  CulteDKP:GetTable(CulteDKP_DB, false)["teams"]} , nil)
end

function CulteDKP:AddNewTeamToGuild() 
	local _index = 0
	local _tmp = CulteDKP:GetTable(CulteDKP_DB, false)["teams"]
	local realmName = CulteDKP:GetRealmName();
	local guildName = CulteDKP:GetGuildName();

	-- get the index of last team from CulteDKP_DB
	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			_index = _index + 1
		end
	end

	-- add new team definition to CulteDKP_DB with generic GuildName-index
	CulteDKP:GetTable(CulteDKP_DB, false)["teams"][tostring(_index)] = { ["name"] = guildName.."-"..tostring(_index)}

	------
	-- add new team with new "index" to all "team" tables in saved variables
	-- CulteDKP_Loot, CulteDKP_DKPTable, CulteDKP_DKPHistory, CulteDKP_MinBids, CulteDKP_MaxBids, CulteDKP_Standby, CulteDKP_Archive
	------
		CulteDKP:GetTable(CulteDKP_Loot, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_DKPTable, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_DKPHistory, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_MinBids, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_MaxBids, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_Standby, false)[tostring(_index)] = {}
		CulteDKP:GetTable(CulteDKP_Archive, false)[tostring(_index)] = {}

		CulteDKP.Sync:SendData("CDKPTeams", {Teams =  CulteDKP:GetTable(CulteDKP_DB, false)["teams"]} , nil)

	return tostring(_index)
end

-------
-- TEAM FUNCTIONS END
-------

function CulteDKP:reset_prev_dkp(player)
	if player then
		local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), player, "player")

		if search then
			CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].previous_dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp
		end
	else
		for i=1, #CulteDKP:GetTable(CulteDKP_DKPTable, true) do
			CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].previous_dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].dkp
		end
	end
end

local function UpdateWhitelist()
	if #core.SelectedData > 0 then
		table.wipe(CulteDKP:GetTable(CulteDKP_Whitelist))
		for i=1, #core.SelectedData do
			local validate = CulteDKP:ValidateSender(core.SelectedData[i].player)

			if not validate then
				StaticPopupDialogs["VALIDATE_OFFICER"] = {
				    text = core.SelectedData[i].player.." "..L["NOTANOFFICER"],
					button1 = "Ok",
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("VALIDATE_OFFICER")
				return;
			end
		end
		for i=1, #core.SelectedData do
			table.insert(CulteDKP:GetTable(CulteDKP_Whitelist), core.SelectedData[i].player)
		end

		local verifyLeadAdded = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Whitelist), UnitName("player"))

		if not verifyLeadAdded then
			local pname = UnitName("player");
			table.insert(CulteDKP:GetTable(CulteDKP_Whitelist), pname)		-- verifies leader is included in white list. Adds if they aren't
		end
	else
		table.wipe(CulteDKP:GetTable(CulteDKP_Whitelist))
	end
	CulteDKP.Sync:SendData("CDKPWhitelist", CulteDKP:GetTable(CulteDKP_Whitelist))
	CulteDKP:Print(L["WHITELISTBROADCASTED"])
end

local function ViewWhitelist()
	if #CulteDKP:GetTable(CulteDKP_Whitelist) > 0 then
		core.SelectedData = {}
		for i=1, #CulteDKP:GetTable(CulteDKP_Whitelist) do
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), CulteDKP:GetTable(CulteDKP_Whitelist)[i])

			if search then
				table.insert(core.SelectedData, CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]])
			end
		end
		CulteDKP:FilterDKPTable(core.currentSort, "reset")
	end
end


---------------------------------------
-- Manage DKP TAB.Create()
---------------------------------------
function CulteDKP:ManageEntries()
	local CheckLeader = CulteDKP:GetGuildRankIndex(UnitName("player"))
	-- add raid to dkp table if they don't exist

	----------------------------------
	-- Header.Text above the buttons
	----------------------------------
		CulteDKP.ConfigTab3.AddEntriesHeader = CulteDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		CulteDKP.ConfigTab3.AddEntriesHeader:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab3.add_raid_to_table, "TOPLEFT", -10, 10);
		CulteDKP.ConfigTab3.AddEntriesHeader:SetWidth(400)
		CulteDKP.ConfigTab3.AddEntriesHeader:SetFontObject("CulteDKPNormalLeft")
		CulteDKP.ConfigTab3.AddEntriesHeader:SetText(L["ADDREMDKPTABLEENTRIES"]); 

	----------------------------------
	-- add raid members button
	----------------------------------
		CulteDKP.ConfigTab3.add_raid_to_table = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 30, -90, L["ADDRAIDMEMBERS"]);
		CulteDKP.ConfigTab3.add_raid_to_table:SetSize(120,25);

		-- tooltip for add raid members button
		CulteDKP.ConfigTab3.add_raid_to_table:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDRAIDMEMBERS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDRAIDMEMBERSTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.add_raid_to_table:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)

		-- confirmation dialog to remove user(s)
		CulteDKP.ConfigTab3.add_raid_to_table:SetScript("OnClick", 
			function ()
				local selected = L["ADDRAIDMEMBERSCONFIRM"];

				StaticPopupDialogs["ADD_RAID_ENTRIES"] = {
			    text = selected,
				button1 = L["YES"],
				button2 = L["NO"],
				OnAccept = function()
					AddRaidToDKPTable()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
				}
				StaticPopup_Show ("ADD_RAID_ENTRIES")
			end
		);


	
	----------------------------------
	-- remove selected entries button
	----------------------------------
		CulteDKP.ConfigTab3.remove_entries = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 170, -60, L["REMOVEENTRIES"]);
		CulteDKP.ConfigTab3.remove_entries:SetSize(120,25);
		CulteDKP.ConfigTab3.remove_entries:ClearAllPoints()
		CulteDKP.ConfigTab3.remove_entries:SetPoint("LEFT", CulteDKP.ConfigTab3.add_raid_to_table, "RIGHT", 20, 0)
		CulteDKP.ConfigTab3.remove_entries:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["REMOVESELECTEDENTRIES"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["REMSELENTRIESTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.remove_entries:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		CulteDKP.ConfigTab3.remove_entries:SetScript("OnClick", 
			function ()	
				if #core.SelectedData > 0 then
					local selected = L["CONFIRMREMOVESELECT"]..": \n\n";

					for i=1, #core.SelectedData do
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
					selected = selected.."?"

					StaticPopupDialogs["REMOVE_ENTRIES"] = {
				    text = selected,
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						Remove_Entries()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
					}
					StaticPopup_Show ("REMOVE_ENTRIES")
				else
					CulteDKP:Print(L["NOENTRIESSELECTED"])
				end
			end
		);
	----------------------------------
	-- Reset previous DKP button -- number showing how much a player has gained or lost since last clear
	----------------------------------
		CulteDKP.ConfigTab3.reset_previous_dkp = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 310, -60, L["RESETPREVIOUS"]);
		CulteDKP.ConfigTab3.reset_previous_dkp:SetSize(120,25);
		CulteDKP.ConfigTab3.reset_previous_dkp:ClearAllPoints()
		CulteDKP.ConfigTab3.reset_previous_dkp:SetPoint("LEFT", CulteDKP.ConfigTab3.remove_entries, "RIGHT", 20, 0)
		CulteDKP.ConfigTab3.reset_previous_dkp:SetScript("OnEnter",
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RESETPREVDKP"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["RESETPREVDKPTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.reset_previous_dkp:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to remove user(s)
		CulteDKP.ConfigTab3.reset_previous_dkp:SetScript("OnClick",
			function ()	
				StaticPopupDialogs["RESET_PREVIOUS_DKP"] = {
				    text = L["RESETPREVCONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						CulteDKP:reset_prev_dkp()
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("RESET_PREVIOUS_DKP")
			end
		);

	local curIndex;
	local curRank;

	----------------------------------
	-- rank select dropDownMenu
	----------------------------------
		--CulteDKP.ConfigTab3.GuildRankDropDown = CreateFrame("FRAME", "CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab3, "CulteDKPUIDropDownMenuTemplate")
		CulteDKP.ConfigTab3.GuildRankDropDown = LibDD:Create_UIDropDownMenu("CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab3);
		CulteDKP.ConfigTab3.GuildRankDropDown:SetPoint("TOPLEFT", CulteDKP.ConfigTab3.add_raid_to_table, "BOTTOMLEFT", -17, -15)
		CulteDKP.ConfigTab3.GuildRankDropDown:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["RANKLIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["RANKLISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.GuildRankDropDown:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		LibDD:UIDropDownMenu_SetWidth(CulteDKP.ConfigTab3.GuildRankDropDown, 105)
		LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.GuildRankDropDown, "Select Rank")

		-- Create and bind the initialization function to the dropdown menu
			LibDD:UIDropDownMenu_Initialize(CulteDKP.ConfigTab3.GuildRankDropDown, 
			function(self, level, menuList)
				
				local rank = LibDD:UIDropDownMenu_CreateInfo()
					rank.func = self.SetValue
					rank.fontObject = "CulteDKPSmallCenter"

					local rankList = CulteDKP:GetGuildRankList()

					for i=1, #rankList do
						rank.text, rank.arg1, rank.arg2, rank.checked, rank.isNotRadio = rankList[i].name, rankList[i].name, rankList[i].index, rankList[i].name == curRank, true
						LibDD:UIDropDownMenu_AddButton(rank)
					end
			end
		)

		-- Dropdown Menu Function
		function CulteDKP.ConfigTab3.GuildRankDropDown:SetValue(arg1, arg2)
			if curRank ~= arg1 then
				curRank = arg1
				curIndex = arg2
				LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.GuildRankDropDown, arg1)
			else
				curRank = nil
				curIndex = nil
				LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.GuildRankDropDown, L["SELECTRANK"])
			end

			LibDD:CloseDropDownMenus()
		end

	----------------------------------
	-- Add Guild to DKP Table Button
	----------------------------------
		CulteDKP.ConfigTab3.AddGuildToDKP = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDGUILDMEMBERS"]);
		CulteDKP.ConfigTab3.AddGuildToDKP:SetSize(120,25);
		CulteDKP.ConfigTab3.AddGuildToDKP:ClearAllPoints()
		CulteDKP.ConfigTab3.AddGuildToDKP:SetPoint("LEFT", CulteDKP.ConfigTab3.GuildRankDropDown, "RIGHT", 2, 2)
		CulteDKP.ConfigTab3.AddGuildToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDGUILDDKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDGUILDDKPTABLETT"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.AddGuildToDKP:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		CulteDKP.ConfigTab3.AddGuildToDKP:SetScript("OnClick",
			function ()	
				if curIndex ~= nil then
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					    text = L["ADDGUILDCONFIRM"].." \""..curRank.."\"?",
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							AddGuildToDKPTable(curIndex)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				else
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					    text = L["NORANKSELECTED"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				end
			end
		);

	----------------------------------
	-- Add target to DKP list button
	----------------------------------	
		CulteDKP.ConfigTab3.AddTargetToDKP = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 0, 0, L["ADDTARGET"]);
		CulteDKP.ConfigTab3.AddTargetToDKP:SetSize(120,25);
		CulteDKP.ConfigTab3.AddTargetToDKP:ClearAllPoints()
		CulteDKP.ConfigTab3.AddTargetToDKP:SetPoint("LEFT", CulteDKP.ConfigTab3.AddGuildToDKP, "RIGHT", 20, 0)
		CulteDKP.ConfigTab3.AddTargetToDKP:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["ADDTARGETTODKPTABLE"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ADDTARGETTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.AddTargetToDKP:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		CulteDKP.ConfigTab3.AddTargetToDKP:SetScript("OnClick", 
			function ()	-- confirmation dialog to add user(s)
				if UnitIsPlayer("target") == true then
					StaticPopupDialogs["ADD_TARGET_DKP"] = {
					    text = L["CONFIRMADDTARGET"].." "..UnitName("target").." "..L["TODKPLIST"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							AddTargetToDKPTable()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_TARGET_DKP")
				else
					StaticPopupDialogs["ADD_TARGET_DKP"] = {
					    text = L["NOPLAYERTARGETED"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_TARGET_DKP")
				end
			end
		);

	----------------------------------
	-- Purge DKP list button
	----------------------------------
		CulteDKP.ConfigTab3.CleanList = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 0, 0, L["PURGELIST"]);
		CulteDKP.ConfigTab3.CleanList:SetSize(120,25);
		CulteDKP.ConfigTab3.CleanList:ClearAllPoints()
		CulteDKP.ConfigTab3.CleanList:SetPoint("TOP", CulteDKP.ConfigTab3.AddTargetToDKP, "BOTTOM", 0, -16)
		CulteDKP.ConfigTab3.CleanList:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["PURGELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["PURGELISTTTDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.CleanList:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		CulteDKP.ConfigTab3.CleanList:SetScript("OnClick", 
			function()
				StaticPopupDialogs["PURGE_CONFIRM"] = {
				    text = L["PURGECONFIRM"],
					button1 = L["YES"],
					button2 = L["NO"],
					OnAccept = function()
						local purgeString, c, name;
						local count = 0;
						local i = 1;

						while i <= #CulteDKP:GetTable(CulteDKP_DKPTable, true) do
							local search = CulteDKP:TableStrFind(CulteDKP:GetTable(CulteDKP_DKPHistory, true), CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player, "players")

							if CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].dkp == 0 and not search then
								c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].class)
								name = CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player;

								if purgeString == nil then
									purgeString = "|c"..c.hex..name.."|r"; 
								else
									purgeString = purgeString..", |c"..c.hex..name.."|r"
								end

								count = count + 1;
								table.remove(CulteDKP:GetTable(CulteDKP_DKPTable, true), i)
							else
								i=i+1;
							end
						end
						if count > 0 then
							CulteDKP:Print(L["PURGELIST"].." ("..count.."):")
							CulteDKP:Print(purgeString)
							CulteDKP:FilterDKPTable(core.currentSort, "reset")
						end
					end,
					timeout = 0,
					whileDead = true,
					hideOnEscape = true,
					preferredIndex = 3,
				}
				StaticPopup_Show ("PURGE_CONFIRM")
			end
		)

	----------------------------------
	-- White list container
	----------------------------------
		CulteDKP.ConfigTab3.WhitelistContainer = CreateFrame("Frame", nil, CulteDKP.ConfigTab3);
		CulteDKP.ConfigTab3.WhitelistContainer:SetSize(475, 200);
		CulteDKP.ConfigTab3.WhitelistContainer:SetPoint("TOPLEFT", CulteDKP.ConfigTab3.GuildRankDropDown, "BOTTOMLEFT", 20, -30)

		-- Whitelist Header
		CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader = CulteDKP.ConfigTab3.WhitelistContainer:CreateFontString(nil, "OVERLAY")
		CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetPoint("TOPLEFT", CulteDKP.ConfigTab3.WhitelistContainer, "TOPLEFT", -10, 0);
		CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetWidth(400)
		CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetFontObject("CulteDKPNormalLeft")
		CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader:SetText(L["WHITELISTHEADER"]); 

		-- Whitelist button
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton = self:CreateButton("BOTTOMLEFT", CulteDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SETWHITELIST"]);
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:ClearAllPoints()
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetPoint("TOPLEFT", CulteDKP.ConfigTab3.WhitelistContainer.WhitelistHeader, "BOTTOMLEFT", 10, -10)
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["SETWHITELIST"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC1"], 1.0, 1.0, 1.0, true);
				GameTooltip:AddLine(L["SETWHITELISTTTDESC2"], 0.2, 1.0, 0.2, true);
				GameTooltip:AddLine(L["SETWHITELISTTTWARN"], 1.0, 0, 0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnLeave", 
			function(self)
				GameTooltip:Hide()
			end
		)
		-- confirmation dialog to add user(s)
		CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton:SetScript("OnClick", 
			function ()	
				if #core.SelectedData > 0 then
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					    text = L["CONFIRMWHITELIST"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							UpdateWhitelist()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				else
					StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
					    text = L["CONFIRMWHITELISTCLEAR"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							UpdateWhitelist()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show ("ADD_GUILD_MEMBERS")
				end
			end
		);

			----------------------------------
			-- View Whitelist Button
			----------------------------------
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton = self:CreateButton("BOTTOMLEFT", CulteDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["VIEWWHITELISTBTN"]);
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:ClearAllPoints()
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetPoint("LEFT", CulteDKP.ConfigTab3.WhitelistContainer.AddWhitelistButton, "RIGHT", 10, 0)
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnEnter",
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["VIEWWHITELISTBTN"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["VIEWWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:Show();
					end
				)
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnLeave", 
					function(self)
						GameTooltip:Hide()
					end
				)
				CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton:SetScript("OnClick", 
					function ()	-- confirmation dialog to add user(s)
						if #CulteDKP:GetTable(CulteDKP_Whitelist) > 0 then
							ViewWhitelist()
						else
							StaticPopupDialogs["ADD_GUILD_MEMBERS"] = {
							    text = L["WHITELISTEMPTY"],
								button1 = L["OK"],
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
								preferredIndex = 3
							}
							StaticPopup_Show ("ADD_GUILD_MEMBERS")
						end
					end
				);

			----------------------------------
			-- Broadcast Whitelist Button
			----------------------------------
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton = self:CreateButton("BOTTOMLEFT", CulteDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", 15, 15, L["SENDWHITELIST"]);
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:ClearAllPoints()
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetPoint("LEFT", CulteDKP.ConfigTab3.WhitelistContainer.ViewWhitelistButton, "RIGHT", 30, 0)
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnEnter", 
					function(self)
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
						GameTooltip:SetText(L["SENDWHITELIST"], 0.25, 0.75, 0.90, 1, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTDESC"], 1.0, 1.0, 1.0, true);
						GameTooltip:AddLine(L["SENDWHITELISTTTWARN"], 1.0, 0, 0, true);
						GameTooltip:Show();
					end
				)
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnLeave",
					function(self)
						GameTooltip:Hide()
					end
				)
				-- confirmation dialog to add user(s)
				CulteDKP.ConfigTab3.WhitelistContainer.SendWhitelistButton:SetScript("OnClick",
					function ()	
						CulteDKP.Sync:SendData("CDKPWhitelist", CulteDKP:GetTable(CulteDKP_Whitelist))
						CulteDKP:Print(L["WHITELISTBROADCASTED"])
					end
				);

		

	----------------------------------
	-- Guild team management section
	----------------------------------
	local selectedTeam;
	local selectedTeamIndex;

		----------------------------------
		-- Teams Header
		----------------------------------
		CulteDKP.ConfigTab3.TeamHeader = CulteDKP.ConfigTab3:CreateFontString(nil, "OVERLAY")
		CulteDKP.ConfigTab3.TeamHeader:SetPoint("TOPLEFT", CulteDKP.ConfigTab3.WhitelistContainer, "BOTTOMLEFT", -10, -5);
		CulteDKP.ConfigTab3.TeamHeader:SetWidth(400)
		CulteDKP.ConfigTab3.TeamHeader:SetFontObject("CulteDKPNormalLeft")
		CulteDKP.ConfigTab3.TeamHeader:SetText(L["TEAMMANAGEMENTHEADER"].." of "..CulteDKP:GetGuildName()..""); 

		----------------------------------
		-- Drop down with lists of teams 
		----------------------------------
			--CulteDKP.ConfigTab3.TeamListDropDown = CreateFrame("FRAME", "CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab3, "CulteDKPUIDropDownMenuTemplate")
			CulteDKP.ConfigTab3.TeamListDropDown = LibDD:Create_UIDropDownMenu("CulteDKPConfigReasonDropDown", CulteDKP.ConfigTab3);
			--CulteDKP.ConfigTab3.TeamManagementContainer.TeamListDropDown:ClearAllPoints()
			CulteDKP.ConfigTab3.TeamListDropDown:SetPoint("BOTTOMLEFT", CulteDKP.ConfigTab3.TeamHeader, "BOTTOMLEFT", 0, -50)
			-- tooltip on mouseOver
			CulteDKP.ConfigTab3.TeamListDropDown:SetScript("OnEnter", 
				function(self) 
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMLIST"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMLISTDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			CulteDKP.ConfigTab3.TeamListDropDown:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			LibDD:UIDropDownMenu_SetWidth(CulteDKP.ConfigTab3.TeamListDropDown, 105)
			LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])

			-- Create and bind the initialization function to the dropdown menu
				LibDD:UIDropDownMenu_Initialize(CulteDKP.ConfigTab3.TeamListDropDown, 
				function(self, level, menuList)
					
					local dropDownMenuItem = LibDD:UIDropDownMenu_CreateInfo()
					dropDownMenuItem.func = self.SetValue
					dropDownMenuItem.fontObject = "CulteDKPSmallCenter"
					
					teamList = CulteDKP:GetGuildTeamList()
					
					for i=1, #teamList do
						dropDownMenuItem.text = teamList[i][2]
						dropDownMenuItem.arg1 = teamList[i][2]
						dropDownMenuItem.arg2 = teamList[i][1]
						dropDownMenuItem.checked = teamList[i][1] == selectedTeamIndex
						dropDownMenuItem.isNotRadio = true
						LibDD:UIDropDownMenu_AddButton(dropDownMenuItem)
					end
				end
			)

			-- Dropdown Menu on SetValue()
			function CulteDKP.ConfigTab3.TeamListDropDown:SetValue(arg1, arg2)
				if selectedTeamIndex ~= arg2 then
					selectedTeam = arg1
					selectedTeamIndex = arg2
					LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, arg1)
					CulteDKP.ConfigTab3.TeamNameInput:SetText(arg1)
				else
					selectedTeam = nil
					selectedTeamIndex = nil
					CulteDKP.ConfigTab3.TeamNameInput:SetText("")
					LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
				end

				LibDD:CloseDropDownMenus()
			end

		----------------------------------
		-- Team name input box
		----------------------------------
			if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
				CulteDKP.ConfigTab3.TeamNameInput = CreateFrame("EditBox", nil, CulteDKP.ConfigTab3)
			else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
				CulteDKP.ConfigTab3.TeamNameInput = CreateFrame("EditBox", nil, CulteDKP.ConfigTab3, BackdropTemplateMixin and "BackdropTemplate" or nil)
			end
			
			CulteDKP.ConfigTab3.TeamNameInput:SetAutoFocus(false)
			CulteDKP.ConfigTab3.TeamNameInput:SetMultiLine(false)
			CulteDKP.ConfigTab3.TeamNameInput:SetSize(160, 24)
			CulteDKP.ConfigTab3.TeamNameInput:SetPoint("TOPRIGHT", CulteDKP.ConfigTab3.TeamListDropDown, "TOPRIGHT", 160, 0)
			CulteDKP.ConfigTab3.TeamNameInput:SetBackdrop({
				bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true,
				edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile",
				tile = true, 
				tileSize = 32, 
				edgeSize = 2
			});
			CulteDKP.ConfigTab3.TeamNameInput:SetBackdropColor(0,0,0,0.9)
			CulteDKP.ConfigTab3.TeamNameInput:SetBackdropBorderColor(0.12, 0.12, 0.34, 1)
			--CulteDKP.ConfigTab3.TeamNameInput:SetMaxLetters(6)
			CulteDKP.ConfigTab3.TeamNameInput:SetTextColor(1, 1, 1, 1)
			CulteDKP.ConfigTab3.TeamNameInput:SetFontObject("CulteDKPSmallRight")
			CulteDKP.ConfigTab3.TeamNameInput:SetTextInsets(10, 10, 5, 5)
			CulteDKP.ConfigTab3.TeamNameInput.tooltipText = L["TEAMNAMEINPUTTOOLTIP"]
			CulteDKP.ConfigTab3.TeamNameInput.tooltipDescription = L["TEAMNAMEINPUTTOOLTIPDESC"]
			CulteDKP.ConfigTab3.TeamNameInput:SetScript("OnEscapePressed", 
				function(self)    -- clears focus on esc
					self:HighlightText(0,0)
					self:ClearFocus()
				end
			)
			CulteDKP.ConfigTab3.TeamNameInput:SetScript("OnEnterPressed", 
				function(self)
					self:HighlightText(0,0)
					if (selectedTeamIndex == nil ) then
						StaticPopupDialogs["RENAME_TEAM"] = {
						    text = L["NOTEAMCHOSEN"],
							button1 = L["OK"],
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3
						}
						StaticPopup_Show ("RENAME_TEAM")
					else
						CulteDKP:ChangeTeamName(selectedTeamIndex, self:GetText())
						-- if we are performing name change on currently selected team, change main team view dropdown Text
						if tonumber(CulteDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
							LibDD:UIDropDownMenu_SetText(CulteDKP.UIConfig.TeamViewChangerDropDown, self:SetText(""))
						end
						LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
						selectedTeam = nil
						selectedTeamIndex = nil
						LibDD:CloseDropDownMenus()
						self:ClearFocus()
						self:SetText("")
					end
				end
			)
			CulteDKP.ConfigTab3.TeamNameInput:SetScript("OnEnter", 
				function(self)
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
				end
			)
			CulteDKP.ConfigTab3.TeamNameInput:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)

			

		----------------------------------
		-- Rename selected team button
		----------------------------------	
			CulteDKP.ConfigTab3.TeamRename = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMRENAME"]);
			CulteDKP.ConfigTab3.TeamRename:SetSize(120,25);
			CulteDKP.ConfigTab3.TeamRename:ClearAllPoints()
			CulteDKP.ConfigTab3.TeamRename:SetPoint("TOPRIGHT", CulteDKP.ConfigTab3.TeamNameInput, "TOPRIGHT", 125, 0)
			CulteDKP.ConfigTab3.TeamRename:SetScript("OnEnter", 
				function(self)
					GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
					GameTooltip:SetText(L["TEAMRENAMESELECTED"], 0.25, 0.75, 0.90, 1, true);
					GameTooltip:AddLine(L["TEAMRENAMESELECTEDESC"], 1.0, 1.0, 1.0, true);
					GameTooltip:Show();
				end
			)
			CulteDKP.ConfigTab3.TeamRename:SetScript("OnLeave",
				function(self)
					GameTooltip:Hide()
				end
			)
			-- rename team function
			CulteDKP.ConfigTab3.TeamRename:SetScript("OnClick", 
				function ()	
					if selectedTeamIndex == nil then
						StaticPopupDialogs["RENAME_TEAM"] = {
						    text = L["NOTEAMCHOSEN"],
							button1 = L["OK"],
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3
						}
						StaticPopup_Show ("RENAME_TEAM")
					else
						if CheckLeader and CheckLeader <= 2 then
							CulteDKP:ChangeTeamName(selectedTeamIndex, CulteDKP.ConfigTab3.TeamNameInput:GetText())
							-- if we are performing name change on currently selected team, change main team view dropdown Text
							if tonumber(CulteDKP:GetCurrentTeamIndex()) == selectedTeamIndex then
								LibDD:UIDropDownMenu_SetText(CulteDKP.UIConfig.TeamViewChangerDropDown, CulteDKP.ConfigTab3.TeamNameInput:GetText())
							end
							CulteDKP.ConfigTab3.TeamNameInput:SetText("")
							LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
							selectedTeam = nil
							selectedTeamIndex = nil
							LibDD:CloseDropDownMenus()
						else
							StaticPopupDialogs["NOT_GUILD_MASTER"] = {
							    text = L["NOTGUILDMASTER"],
								button1 = L["OK"],
								timeout = 0,
								whileDead = true,
								hideOnEscape = true,
								preferredIndex = 3
							}
							StaticPopup_Show ("NOT_GUILD_MASTER")	
						end
					end
				end
			);

		----------------------------------
		-- Add new team button
		----------------------------------	
		CulteDKP.ConfigTab3.TeamAdd = self:CreateButton("TOPLEFT", CulteDKP.ConfigTab3, "TOPLEFT", 0, 0, L["TEAMADD"]);
		CulteDKP.ConfigTab3.TeamAdd:SetSize(120,25);
		CulteDKP.ConfigTab3.TeamAdd:ClearAllPoints()
		CulteDKP.ConfigTab3.TeamAdd:SetPoint("BOTTOM", CulteDKP.ConfigTab3.TeamRename, "BOTTOM", 0, -40)
		CulteDKP.ConfigTab3.TeamAdd:SetScript("OnEnter", 
			function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
				GameTooltip:SetText(L["TEAMADD"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["TEAMADDDESC"], 1.0, 1.0, 1.0, true);
				GameTooltip:Show();
			end
		)
		CulteDKP.ConfigTab3.TeamAdd:SetScript("OnLeave",
			function(self)
				GameTooltip:Hide()
			end
		)
		-- rename team function
		CulteDKP.ConfigTab3.TeamAdd:SetScript("OnClick", 
			function ()	
				if CheckLeader and CheckLeader <= 2 then
					StaticPopupDialogs["ADD_TEAM"] = {
					    text = L["TEAMADDDIALOG"],
						button1 = L["YES"],
						button2 = L["NO"],
						OnAccept = function()
							CulteDKP:AddNewTeamToGuild()
							CulteDKP.ConfigTab3.TeamNameInput:SetText("")
							LibDD:UIDropDownMenu_SetText(CulteDKP.ConfigTab3.TeamListDropDown, L["TEAMSELECT"])
							LibDD:CloseDropDownMenus()
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3
					}
					StaticPopup_Show ("ADD_TEAM")	
				else
					StaticPopupDialogs["NOT_GUILD_MASTER"] = {
					    text = L["NOTGUILDMASTER"],
						button1 = L["OK"],
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3
					}
					StaticPopup_Show ("NOT_GUILD_MASTER")	
				end			
			end
		);

	-- only show whitelist and/or team management if player is a guild master
	if CheckLeader and CheckLeader <= 2 then
		CulteDKP.ConfigTab3.WhitelistContainer:Show()
		CulteDKP.ConfigTab3.TeamHeader:Show()
		CulteDKP.ConfigTab3.TeamListDropDown:Show()
		CulteDKP.ConfigTab3.TeamNameInput:Show()
		CulteDKP.ConfigTab3.TeamRename:Show()
		CulteDKP.ConfigTab3.TeamAdd:Show()
	else
		CulteDKP.ConfigTab3.WhitelistContainer:Hide()
		CulteDKP.ConfigTab3.TeamHeader:Hide()
		CulteDKP.ConfigTab3.TeamListDropDown:Hide()
		CulteDKP.ConfigTab3.TeamNameInput:Hide()
		CulteDKP.ConfigTab3.TeamRename:Hide()
		CulteDKP.ConfigTab3.TeamAdd:Hide()
	end
end
