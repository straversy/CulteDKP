--[[
	Core.lua is intended to store all core functions and variables to be used throughout the addon. 
	Don't put anything in here that you don't want to be loaded immediately after the Libs but before initialization.
--]]

local _, core = ...;
local _G = _G;
local L = core.L;

local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0");

core.CulteDKP = {};       -- UI Frames global
core.CulteDKPApi = { __version = 1, pricelist = nil }
local CulteDKP = core.CulteDKP;
local CulteDKPApi = core.CulteDKPApi;

_G.CulteDKPApi = CulteDKPApi;

core.faction = UnitFactionGroup("player")


API_CLASSES = LOCALIZED_CLASS_NAMES_MALE;

core.CColors = {
	["UNKNOWN"] = { r = 0.627, g = 0.627, b = 0.627, hex = "A0A0A0" }
}
core.classes = {}

for class,friendlyClass in pairs(API_CLASSES) do
	local colorTable = {};
	local addColor = false;

	-- There appears to be no WoW API that lists out specific classes to a single faction
	-- Nor is there an API that identifies a specific class to a specific faction.
	-- I'd love to not hard code this though, but I seem to be out of luck.
	
	-- if core.faction == "Horde" then
	-- 	if class ~= "PALADIN" then
	-- 		addColor = true;
	-- 	end
	-- end

	-- if core.faction == "Alliance" then
	-- 	if class ~= "SHAMAN" then
	-- 		addColor = true;
	-- 	end
	-- end
	addColor = true;

	if addColor then
		colorTable.class = friendlyClass;
		colorTable.r, colorTable.g, colorTable.b, colorTable.hex = GetClassColor(class);

		core.CColors[class] = colorTable;
		table.insert(core.classes, class)
	end
end

--------------------------------------
-- Addon Defaults
--------------------------------------
local defaults = {
	theme = { r = 0.6823, g = 0.6823, b = 0.8666, hex = "aeaedd" },
	theme2 = { r = 1, g = 0.37, b = 0.37, hex = "ff6060" }
}

--------------------------------------
-- Encounter ID's Library
--------------------------------------


core.PriceSortButtons = {}
core.WorkingTable = {};       -- table of all entries from CulteDKP:GetTable(CulteDKP_DKPTable, true) that are currently visible in the window. From CulteDKP:GetTable(CulteDKP_DKPTable, true)
core.EncounterList = {      -- Event IDs must be in the exact same order as core.BossList declared in localization files
	MC = {
		663, 664, 665,
		666, 668, 667, 669, 
		670, 671, 672
	},
	BWL = {
		610, 611, 612,
		613, 614, 615, 616, 
		617
	},
	AQ = {
		709, 711, 712,
		714, 715, 717, 
		710, 713, 716
	},
	NAXX = {   --533
		1107, 1110, 1116, 	-- Anub’Rekhan, Grand Widow Faerlina, Maexxna
		1117, 1112, 1115, 	-- Noth the Plaguebringer, Heigan the Unclean, Loatheb
		1113, 1109, 1121, 	-- Instructor Razuvious, Gothik the Harvester, The Four Horsemen
		1118, 1111, 1108, 1120,	-- Patchwerk, Grobbulus, Gluth, Thaddius
		1119, 1114		-- Sapphiron, Kel’Thuzad
	},
	ZG = {
		787, 790, 793, 789, 784, 791,
		785, 792, 786, 788
	},
	AQ20 = {
		722, 721, 719, 718, 720, 723
	},
	ONYXIA = { --249
		1084 -- Onyxia
	},
	WORLD = {     -- No encounter IDs have been identified for these world bosses yet
		"Azuregos", "Lord Kazzak", "Emeriss", "Lethon", "Ysondre", "Taerar"
	},
	KARAZHAN = {
		652, -- "Attumen the Huntsman",
		653, -- "Moroes",
		654, -- "Maiden of Virtue",
		655, -- "Opera Hall",
		656, -- "The Curator",
		657, -- "Terestian Illhoof",
		658, -- "Shade of Aran",
		659, -- "Netherspite",
		660, -- "Chess Event",
		661, -- "Prince Malchezaar",
		662 -- "Nightbane"
	  },
	  GRULLSLAIR = {
		649, -- "High King Maulgar",
		650 -- "Gruul the Dragonkiller"
	  },
	  MAGTHERIDONSLAIR = {
		651 -- "Magtheridon"
	  },
	  SERPENTSHRINECAVERN = {
		623, -- "Hydross the Unstable",
		624, -- "The Lurker Below",
		625, -- "Leotheras the Blind",
		626, -- "Fathom-Lord Karathress",
		627, -- "Morogrim Tidewalker",
		628 -- "Lady Vashj"
	  },
	  TEMPESTKEEP = {
		730, -- "Al'ar",
		731, -- "Void Reaver",
		732, -- "High Astromancer Solarian",
		733 -- "Kael'thas Sunstrider"
	  },
	  ZULAMAN = {
		1189, -- "Akil'zon"
		1190, -- Nalorakk
		1191, -- Jan'alai
		1192, -- Halazzi,
		1193, -- Hex Lord Malacrass
		1194 -- Daakara
	  },
	  BLACKTEMPLE = {
		601, -- High Warlord Naj'entus,
		602, -- Supremus
		603, -- Shade of Akama
		604, -- Teron Gorefiend,
		605, -- Gurtogg Bloodboil
		606, -- Reliquary of Souls
		607, -- Mother Shahraz
		608, -- The Illidari Council
		609 -- Illidan Stormrage
	  },
	  SUNWELLPLATEAU = {
		724, -- "Kalecgos", 
		725, -- "Brutallus",
		726, -- "Felmyst",
		727, -- "Eredar Twins",
		728, -- "M'uru",
		729  -- "Kil'jaeden"
	  },
	  ULDUAR = { --603
		1130, -- Algalon the Observer
		1131, -- Auriaya
		1132, -- Flame Leviathan
		1133, -- Freya
		1134, -- General Vezax
		1135, -- Hodir
		1136, -- Ignis the Furnace Master
		1137, -- Kologarn
		1138, -- Mimiron
		1139, -- Razorscale
		1140, -- The Assembly of Iron
		1141, -- Thorim
		1142, -- XT-002 Deconstructor
		1143, -- Yogg-Saron
		1144  -- Hogger
	  },
	  OBSIDIANSANCTUM = { -- 615
		742 -- Sartharion
	  },
	  EYEOFETERNITY = { --616
		734  -- Malygos
	  },
	  VAULTOFARCHAVON = { --624
		772, -- Archavon the Stone Watcher
		773, -- Emalon the Storm Watcher
		774, -- Koralon the Flame Watcher
		775  -- Toravon the Ice Watcher
	  },
	  ICECROWNCITADEL = { --631
		1095, -- Blood Council
		1096, -- Deathbringer Saurfang
		1097, -- Festergut
		1098, -- Valithria Dreamwalker
		1099, -- Icecrown Gunship Battle
		1100, -- Lady Deathwhisper
		1101, -- Lord Marrowgar
		1102, -- Professor Putricide
		1103, -- Queen Lana'thel
		1104, -- Rotface
		1105, -- Sindragosa
		1106  -- The Lich King
	  },
	  TRIALCRUSADER = { --649
		1085, -- Anub'arak
		1086, -- Faction Champions
		1087, -- Lord Jaraxxus
		1088, -- Northrend Beasts
		1089  -- Val'kyr Twins
	  },
	  RUBYSANCTUM = { --724
		1147, -- Baltharus the Warborn
		1148, -- General Zarithrian
		1149, -- Saviana Ragefire
		1150  -- Halion
	  }
}

core.CulteDKPUI = {}        -- global storing entire Configuration UI to hide/show UI
core.MonVersion = "v1.0.3";
core.BuildNumber = 30209;
core.ReleaseNumber = 1
core.defaultTable = "__default";
core.SemVer = core.MonVersion.."-r"..tostring(core.ReleaseNumber);
core.UpgradeSchema = false;
core.TableWidth, core.TableRowHeight, core.TableNumRows, core.PriceNumRows = 500, 18, 27, 22; -- width, row height, number of rows
core.SelectedData = { player="none"};         -- stores data of clicked row for manipulation.
core.classFiltered = {};   -- tracks classes filtered out with checkboxes
core.IsOfficer = nil;
core.ShowState = false;
core.StandbyActive = false;
core.currentSort = "dkp"		-- stores current sort selection
core.BidInProgress = false;   -- flagged true if bidding in progress. else; false.
core.BidAuctioneer = false;
core.RaidInProgress = false;
core.RaidInPause = false;
core.NumLootItems = 0;        -- updates on LOOT_OPENED event
core.Initialized = false
core.InitStart = false
core.CurrentRaidZone = ""
core.LastKilledBoss = ""
core.ArchiveActive = false
core.CurView = "all"
core.CurSubView = "all"
core.LastVerCheck = 0
core.CenterSort = "class";
core.OOD = false
core.RealmName = nil;
core.FactionName = nil;
core.RepairWorking = false;

function CulteDKP:GetCColors(class)
	if core.CColors then 
	local c
		if class then
		c = core.CColors[class] or core.CColors["UNKNOWN"];
	else
		c = core.CColors
	end
		return c;
	else
		return false;
	end
end

function CulteDKP_round(number, decimals)
		number = number or 0;
		decimals = decimals or 0;
		return tonumber((("%%.%df"):format(decimals)):format(number))
end

function CulteDKP:ResetPosition()
	core.DB.bidpos = nil;
	core.DB.timerpos = nil;
	CulteDKP.UIConfig:ClearAllPoints();
	CulteDKP.UIConfig:SetPoint("CENTER", UIParent, "CENTER", -250, 100);
	CulteDKP.UIConfig:SetSize(550, 590);
	CulteDKP.UIConfig.TabMenu:Hide()
	CulteDKP.UIConfig.expandtab:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\expand-arrow");
	core.ShowState = false;
	CulteDKP.BidTimer:ClearAllPoints()
	CulteDKP.BidTimer:SetPoint("CENTER", UIParent)
	CulteDKP:Print(L["POSITIONRESET"])
end

function CulteDKP:GetGuildRank(player)
	local name, rank, rankIndex;
	local guildSize;

	if IsInGuild() then
		guildSize = GetNumGuildMembers();
		for i=1, guildSize do
			name, rank, rankIndex = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank, rankIndex;
			end
		end
		return L["NOTINGUILD"];
	end
	return L["NOGUILD"]
end

function CulteDKP:GetDefaultEntity()
	local entityProfile = {}
	entityProfile = {
		player = "",
		class = "None",
		dkp = 0,
		previous_dkp = 0,
		lifetime_gained = 0,
		lifetime_spent = 0,
		rank = 20,
		rankName = "None",
		spec = "No Spec Reported",
		role = "No Role Reported",
		version = "Unknown"
  };
  return entityProfile;
end

function CulteDKP:GetRealmName()

	if core.FactionName == nil or core.RealmName == nil then
		core.RealmName = GetRealmName();
		core.FactionName = UnitFactionGroup(UnitName("player"));
	end

	return core.RealmName.."-"..core.FactionName
end

function CulteDKP:GetGuildName()
	local name;

	if IsInGuild() then
		name,_,_ = GetGuildInfo(UnitName("player"))
		if name then
			return name;
		else
			return L["NOGUILD"]
		end
	end
	return L["NOTINGUILD"];	
end

function CulteDKP:GetGuildRankIndex(player)
	local name, rank;
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if name == player then
				return rank+1;
			end
		end
		return false;
	end
end

function CulteDKP:CheckOfficer()      -- checks if user is an officer IF core.IsOfficer is empty. Use before checks against core.IsOfficer
	if not core.InitStart then 
		return
	end

	if core.IsOfficer == nil then      -- used as a redundency as it should be set on load in init.lua GUILD_ROSTER_UPDATE event
		if CulteDKP:GetGuildRankIndex(UnitName("player")) == 1 then       -- automatically gives permissions above all settings if player is guild leader
			core.IsOfficer = true
			return;
		end
		if IsInGuild() then
			if #CulteDKP:GetTable(CulteDKP_Whitelist) > 0 then
				core.IsOfficer = false;
				for i=1, #CulteDKP:GetTable(CulteDKP_Whitelist) do
					if CulteDKP:GetTable(CulteDKP_Whitelist)[i] == UnitName("player") then
						core.IsOfficer = true;
					end
				end
			else
				local curPlayerRank = CulteDKP:GetGuildRankIndex(UnitName("player"))
				if curPlayerRank then
					core.IsOfficer = C_GuildInfo.GuildControlGetRankFlags(curPlayerRank)[12]
				end
			end
		else
			core.IsOfficer = false;
		end
	end
	
end

function CulteDKP:GetGuildRankGroup(index)                -- returns all members within a specific rank index as well as their index in the guild list (for use with GuildRosterSetPublicNote(index, "msg") and GuildRosterSetOfficerNote)
	local name, rank --, seed;                               -- local temp = CulteDKP:GetGuildRankGroup(1)
	local group = {}                                      -- print(temp[1]["name"])
	local guildSize,_,_ = GetNumGuildMembers();

	if IsInGuild() then
		for i=1, tonumber(guildSize) do
			name,_,rank = GetGuildRosterInfo(i)
			--seed = CulteDKP:RosterSeedExtract(i)
			rank = rank+1;
			name = strsub(name, 1, string.find(name, "-")-1)  -- required to remove server name from player (can remove in classic if this is not an issue)
			if rank == index then
				--tinsert(group, { name = name, index = i, seed = seed })
				tinsert(group, { name = name, index = i })
			end
		end
		return group;
	end
end

function CulteDKP:CheckRaidLeader()
	local tempName,tempRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole;

	for i=1, 40 do
		 
		 tempName, tempRank, subgroup, level, class, fileName, zone, online, isDead, role, isML, combatRole = GetRaidRosterInfo(i);

		if tempName == UnitName("player") and tempRank == 2 then
			return true
		elseif tempName == UnitName("player") and tempRank < 2 then
			return false
		end
	end
	return false;
end

function CulteDKP:GetThemeColor()
	local c = {defaults.theme, defaults.theme2};
	return c;
end

function CulteDKP:GetPlayerDKP(player)
	local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), player)

	if search then
		return CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp
	else
		return false;
	end
end

function CulteDKP:PurgeLootHistory()     -- cleans old loot history beyond history limit to reduce native system load
	local limit = core.DB.defaults.HistoryLimit

	if #CulteDKP:GetTable(CulteDKP_Loot, true) > limit then
		while #CulteDKP:GetTable(CulteDKP_Loot, true) > limit do
			CulteDKP:SortLootTable()
			local path = CulteDKP:GetTable(CulteDKP_Loot, true)[#CulteDKP:GetTable(CulteDKP_Loot, true)]

			if not CulteDKP:GetTable(CulteDKP_Archive, true)[path.player] then
				CulteDKP:GetTable(CulteDKP_Archive, true)[path.player] = { dkp=path.cost, lifetime_spent=path.cost, lifetime_gained=0 }
			else
				CulteDKP:GetTable(CulteDKP_Archive, true)[path.player].dkp = CulteDKP:GetTable(CulteDKP_Archive, true)[path.player].dkp + path.cost
				CulteDKP:GetTable(CulteDKP_Archive, true)[path.player].lifetime_spent = CulteDKP:GetTable(CulteDKP_Archive, true)[path.player].lifetime_spent + path.cost
			end
			if not CulteDKP:GetTable(CulteDKP_Archive, true).LootMeta or CulteDKP:GetTable(CulteDKP_Archive, true).LootMeta < path.date then
				CulteDKP:GetTable(CulteDKP_Archive, true).LootMeta = path.date
			end

			tremove(CulteDKP:GetTable(CulteDKP_Loot, true), #CulteDKP:GetTable(CulteDKP_Loot, true))
		end
	end
end

function CulteDKP:PurgeDKPHistory()     -- purges old entries and stores relevant data in each users CulteDKP:GetTable(CulteDKP_Archive, true) entry (dkp, lifetime spent, and lifetime gained) 
	local limit = core.DB.defaults.DKPHistoryLimit

	if #CulteDKP:GetTable(CulteDKP_DKPHistory, true) > limit then
		while #CulteDKP:GetTable(CulteDKP_DKPHistory, true) > limit do
			CulteDKP:SortDKPHistoryTable()
			local path = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[#CulteDKP:GetTable(CulteDKP_DKPHistory, true)]

			local players = {strsplit(",", strsub(path.players, 1, -2))}
			local dkp = {strsplit(",", path.dkp)}

			if #dkp == 1 then
				for i=1, #players do
					dkp[i] = tonumber(dkp[1])
				end
			else
				for i=1, #dkp do
					dkp[i] = tonumber(dkp[i])
				end
			end

			for i=1, #players do
				if not CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]] then
					if ((dkp[i] > 0 and not path.deletes) or (dkp[i] < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then
						CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=dkp[i] }
					else
						CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]] = { dkp=dkp[i], lifetime_spent=0, lifetime_gained=0 }
					end
				else
					local dkpAmount = dkp[i] or 0
					CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]].dkp = CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]].dkp + dkpAmount
					if ((dkpAmount > 0 and not path.deletes) or (dkpAmount < 0 and path.deletes)) and not strfind(path.dkp, "%-%d*%.?%d+%%") then 	--lifetime gained if dkp addition and not a delete entry, dkp decrease and IS a delete entry
						CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]].lifetime_gained = CulteDKP:GetTable(CulteDKP_Archive, true)[players[i]].lifetime_gained + path.dkp 				--or is NOT a decay
					end
				end
			end
			if not CulteDKP:GetTable(CulteDKP_Archive, true).DKPMeta or CulteDKP:GetTable(CulteDKP_Archive, true).DKPMeta < path.date then
				CulteDKP:GetTable(CulteDKP_Archive, true).DKPMeta = path.date
			end

			tremove(CulteDKP:GetTable(CulteDKP_DKPHistory, true), #CulteDKP:GetTable(CulteDKP_DKPHistory, true))
		end
	end
end

function CulteDKP:FormatTime(time)
	local str = date("%y/%m/%d %H:%M:%S", time)

	return str;
end

function CulteDKP:Print(...)        --print function to add "CulteDKP:" to the beginning of print() outputs.
	if core.DB == nil or not core.DB.defaults.SuppressNotifications then
		local defaults = CulteDKP:GetThemeColor();
		local prefix = string.format("|cff%s%s|r|cff%s", defaults[1].hex:upper(), "CulteDKP:", defaults[2].hex:upper());
		local suffix = "|r";

		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i)

			if core.DB == nil or core.DB.defaults.ChatFrames[name] then
				_G["ChatFrame"..i]:AddMessage(string.join(" ", prefix, ..., suffix));
			end
		end
	end
end

function CulteDKP:CreateButton(point, relativeFrame, relativePoint, xOffset, yOffset, text)
	local btn = CreateFrame("Button", nil, relativeFrame, "CulteDKPButtonTemplate")
	btn:SetPoint(point, relativeFrame, relativePoint, xOffset, yOffset);
	btn:SetSize(100, 30);
	btn:SetText(text);
	btn:GetFontString():SetTextColor(1, 1, 1, 1)
	btn:SetNormalFontObject("CulteDKPSmallCenter");
	btn:SetHighlightFontObject("CulteDKPSmallCenter");
	return btn; 
end

function CulteDKP:BroadcastTimer(seconds, ...)       -- broadcasts timer and starts it natively
	if IsInRaid() and core.IsOfficer == true then
		local title = ...;
		if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
			CulteDKP:Print(L["INVALIDTIMER"]);
			return;
		end
		CulteDKP:StartTimer(seconds, ...)
		CulteDKP.Sync:SendData("CDKPCommand", "StartTimer#"..seconds.."#"..title)
	end
end

function CulteDKP:CreateContainer(parent, name, header)

	local f;

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f = CreateFrame("Frame", "CulteDKP"..name, parent);
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		f = CreateFrame("Frame", "CulteDKP"..name, parent, BackdropTemplateMixin and "BackdropTemplate" or nil);
	end

	
	f:SetBackdrop( {
		edgeFile = "Interface\\AddOns\\CulteDKP\\Media\\Textures\\edgefile.tga", tile = true, tileSize = 1, edgeSize = 2,  
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f:SetBackdropColor(0,0,0,0.9);
	f:SetBackdropBorderColor(1,1,1,0.5)

	if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		f.header = CreateFrame("Frame", "CulteDKP"..name.."Header", f)
	else -- WOW_PROJECT_BURNING_CRUSADE_CLASSIC OR WOW_PROJECT_WRATH_CLASSIC
		f.header = CreateFrame("Frame", "CulteDKP"..name.."Header", f, BackdropTemplateMixin and "BackdropTemplate" or nil)
	end
	
	f.header:SetBackdrop( {
		bgFile = "Textures\\white.blp", tile = true,                -- White backdrop allows for black background with 1.0 alpha on low alpha containers
		insets = { left = 0, right = 0, top = 0, bottom = 0 }
	});
	f.header:SetBackdropColor(0,0,0,1)
	f.header:SetBackdropBorderColor(0,0,0,1)
	f.header:SetPoint("LEFT", f, "TOPLEFT", 20, 0)
	f.header.text = f.header:CreateFontString(nil, "OVERLAY")
	f.header.text:SetFontObject("CulteDKPSmallCenter");
	f.header.text:SetPoint("CENTER", f.header, "CENTER", 0, 0);
	f.header.text:SetText(header);
	f.header:SetWidth(f.header.text:GetWidth() + 30)
	f.header:SetHeight(f.header.text:GetHeight() + 4)

	return f;
end

function CulteDKP:StartTimer(seconds, ...)
	local duration = tonumber(seconds)
	local alpha = 1;

	if not tonumber(seconds) then       -- cancels the function if the command was entered improperly (eg. no number for time)
		CulteDKP:Print(L["INVALIDTIMER"]);
		return;
	end

	CulteDKP.BidTimer = CulteDKP.BidTimer or CulteDKP:CreateTimer();    -- recycles timer frame so multiple instances aren't created
	CulteDKP.BidTimer:SetShown(not CulteDKP.BidTimer:IsShown())         -- shows if not shown
	if CulteDKP.BidTimer:IsShown() == false then                    -- terminates function if hiding timer
		return;
	end

	CulteDKP.BidTimer:SetMinMaxValues(0, duration)
	CulteDKP.BidTimer.timerTitle:SetText(...)
	PlaySound(8959)

	if core.DB.timerpos then
		local a = core.DB.timerpos                   -- retrieves timer's saved position from SavedVariables
		CulteDKP.BidTimer:SetPoint(a.point, a.relativeTo, a.relativePoint, a.x, a.y)
	else
		CulteDKP.BidTimer:SetPoint("CENTER")                      -- sets to center if no position has been saved
	end

	local timer = 0             -- timer starts at 0
	local timerText;            -- count down when below 1 minute
	local modulo                -- remainder after divided by 60
	local timerMinute           -- timerText / 60 to get minutes.
	local audioPlayed = false;  -- so audio only plays once
	local expiring;             -- determines when red blinking bar starts. @ 30 sec if timer > 120 seconds, @ 10 sec if below 120 seconds

	CulteDKP.BidTimer:SetScript("OnUpdate", function(self, elapsed)   -- timer loop
		timer = timer + elapsed
		timerText = CulteDKP_round(duration - timer, 1)
		if tonumber(timerText) > 60 then
			timerMinute = math.floor(tonumber(timerText) / 60, 0);
			modulo = bit.mod(tonumber(timerText), 60);
			if tonumber(modulo) < 10 then modulo = "0"..modulo end
			CulteDKP.BidTimer.timertext:SetText(timerMinute..":"..modulo)
		else
			CulteDKP.BidTimer.timertext:SetText(timerText)
		end
		if duration >= 120 then
			expiring = 30;
		else
			expiring = 10;
		end
		if tonumber(timerText) < expiring then
			if audioPlayed == false then
				PlaySound(23639);
			end
			if tonumber(timerText) < 10 then
				audioPlayed = true
				StopSound(23639)
			end
			CulteDKP.BidTimer:SetStatusBarColor(0.8, 0.1, 0, alpha)
			if alpha > 0 then
				alpha = alpha - 0.005
			elseif alpha <= 0 then
				alpha = 1
			end
		else
			CulteDKP.BidTimer:SetStatusBarColor(0, 0.8, 0)
		end
		self:SetValue(timer)
		if timer >= duration then
			CulteDKP.BidTimer:SetScript("OnUpdate", nil)
			CulteDKP.BidTimer:Hide();
		end
	end)
end

function CulteDKP:StatusVerify_Update()
	if (CulteDKP.UIConfig and not CulteDKP.UIConfig:IsShown()) or 
	   (#CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()) == 0 and #CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()) == 0) then
		-- blocks update if dkp window is closed. Updated when window is opened anyway
		return;
	end

	if IsInGuild() and core.Initialized then
		core.OOD = false

		local missing = {}

		if (CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()).seed and strfind(CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()).seed, "-")) or
		   (CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()).seed and strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()).seed, "-"))
		then

			local search_dkp = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()), CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()).seed, "index")
			local search_loot = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()), CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()).seed, "index")
	
			if not search_dkp then
				core.OOD = true
				local officer1, date1 = strsplit("-", CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()).seed)
				if (date1 and tonumber(date1) < (time() - 1209600)) or not CulteDKP:ValidateSender(officer1) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date1 = date("%m/%d/%y %H:%M:%S", tonumber(date1))
					missing[officer1] = date1 			-- if both missing seeds identify the same officer, it'll only list once
				end
			end
			
			if not search_loot and not core.OOD then
				core.OOD = true
				local officer2, date2 = strsplit("-", CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()).seed)
				if (date2 and tonumber(date2) < (time() - 1209600)) or not CulteDKP:ValidateSender(officer2) then   -- does not consider if claimed entry was made more than two weeks ago or name is not an officer
					core.OOD = false
				else
					date2 = date("%m/%d/%y %H:%M:%S", tonumber(date2))
					missing[officer2] = date2
				end
			end
		end

		if not core.OOD then
			CulteDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\up-to-date")
			CulteDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(L["ALLTABLES"].." |cff00ff00"..L["UPTODATE"].."|r.", 1.0, 1.0, 1.0, false);
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			CulteDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return true;
		else
			CulteDKP.DKPTable.SeedVerifyIcon:SetTexture("Interface\\AddOns\\CulteDKP\\Media\\Textures\\out-of-date")
			CulteDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
				GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
				if #CulteDKP:GetTable(CulteDKP_Loot, true, CulteDKP:GetCurrentTeamIndex()) == 0 and #CulteDKP:GetTable(CulteDKP_DKPHistory, true, CulteDKP:GetCurrentTeamIndex()) == 0 then
					GameTooltip:AddLine(L["TABLESAREEMPTY"], 1.0, 1.0, 1.0, false);
				else
					GameTooltip:AddLine(L["ONETABLEOOD"].." |cffff0000"..L["OUTOFDATE"].."|r.", 1.0, 1.0, 1.0, false);
				end
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(L["MISSINGENT"]..":", 0.25, 0.75, 0.90, 1, true);
				GameTooltip:AddLine(" ")
				GameTooltip:AddDoubleLine(L["PLAYER"], L["CREATED"],1,1,1,1,1,1)
				for k,v in pairs(missing) do
					local classSearch = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, CulteDKP:GetCurrentTeamIndex()), k)

					if classSearch then
						c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true, CulteDKP:GetCurrentTeamIndex())[classSearch[1][1]].class)
					else
						c = { hex="ffffffff" }
					end
					GameTooltip:AddDoubleLine("|c"..c.hex..k.."|r",v,1,1,1,1,1,1);
				end
				if core.IsOfficer then
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("|cffff0000"..L["CLICKQUERYGUILD"].."|r", 1.0, 1.0, 1.0, true);
				end
				GameTooltip:Show()
			end)
			CulteDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
				GameTooltip:Hide()
			end)

			return false;
		end
	elseif core.Initialized then
		CulteDKP.DKPTable.SeedVerify:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0);
			GameTooltip:SetText(L["DKPSTATUS"], 0.25, 0.75, 0.90, 1, true);
			GameTooltip:AddLine(L["CURRNOTINGUILD"], 1.0, 1.0, 1.0, true);
			GameTooltip:Show()
		end)
		CulteDKP.DKPTable.SeedVerify:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		return false;
	end
end

-------
-- TEAM FUNCTIONS
-------
function CulteDKP:tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1 
	end
	return count
end

function CulteDKP:GetCurrentTeamIndex() 
	local _tmpString = CulteDKP:GetTable(CulteDKP_DB, false)["defaults"]["CurrentTeam"] or "0"
	return _tmpString
end

function CulteDKP:GetCurrentTeamName()
	local _string = "Unguilded";
	local teams = CulteDKP:GetTable(CulteDKP_DB, false)["teams"];

	if CulteDKP:tablelength(teams) > 0 then
		_string = CulteDKP:GetTable(CulteDKP_DB, false)["teams"][CulteDKP:GetCurrentTeamIndex()].name
	end

	return _string
end

function CulteDKP:GetTeamName(index)
	local _string = "Unguilded";
	if index == nil then return _string end
	local teamName = CulteDKP:GetTable(CulteDKP_DB, false)["teams"][index]["name"];

	if teamName == nil then return "no team" end;

	return teamName;
end

function CulteDKP:GetGuildTeamList(asObject) 
	local asObject = asObject or false
	local _list = {};
	local _tmp = CulteDKP:GetTable(CulteDKP_DB, false)["teams"]

	for k,v in pairs(_tmp) do
		if(type(v) == "table") then
			if asObject then
				local team = v;
				team["index"] = tonumber(k);
				table.insert(_list, team);
			else
				table.insert(_list, {tonumber(k), v.name})
			end
		end
	end
	-- so, because team "index" is a string Lua doesn't give a flying fuck
	-- about order of adding elements to "string" indexed table so we have to unfuck it
	table.sort(_list,  
		function(a, b)
			if asObject then
				return a.index < b.index
			else
				return a[1] < b[1]
			end
		end
	)

	return _list
end

function CulteDKP:FormatPriceTable(minBids, convertToTable)
	minBids = minBids or CulteDKP:GetTable(CulteDKP_MinBids, true);
	convertToTable = convertToTable or false; --false means it will convert to an array
	local priceTable = {}

	if withIds then
		for i=1, #minBids do
			priceTable[minBids[i].itemID] = minBids[i];
		end
	else
		for key, value in pairs(minBids) do
			tinsert(priceTable, value);
		end
	end
	return priceTable;
end

-- moved to core from ManageEntries as this is called from comm.lua aswell
function CulteDKP:SetCurrentTeam(index)
	CulteDKP:GetTable(CulteDKP_DB, false)["defaults"]["CurrentTeam"] = tostring(index);
	CulteDKP:StatusVerify_Update();
	LibDD:UIDropDownMenu_SetText(CulteDKP.UIConfig.TeamViewChangerDropDown, CulteDKP:GetCurrentTeamName());

	-- reset dkp table and update it
	core.WorkingTable = CulteDKP:GetTable(CulteDKP_DKPTable, true);
	core.PriceTable	= CulteDKP:FormatPriceTable();

	CulteDKP:DKPTable_Update();

	-- reset dkp history table and update it
	CulteDKP:DKPHistory_Update(true);
	-- reset loot history
	CulteDKP:LootHistory_Update(L["NOFILTER"]);
	-- update class graph
	CulteDKP:ClassGraph_Update();
	-- update price table
	CulteDKP:PriceTable_Update(0);
	-- broadcast Talents and Roles
	CulteDKP:SendTalentsAndRole();
end

function CulteDKP:SendTalentsAndRole()

	--Does a Profile Exist? If no, exit, nothing to do here.
	local oldProfile = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), UnitName("player"), "player")
	local newProfile = CulteDKP:GetTable(CulteDKP_Profiles, true)[UnitName("player")]
	if newProfile == nil and not oldProfile then
		return;
	end

	-- talents check
	local TalTrees={}; table.insert(TalTrees, {GetTalentTabInfo(1)}); table.insert(TalTrees, {GetTalentTabInfo(2)}); table.insert(TalTrees, {GetTalentTabInfo(3)});
	local talBuild = "("..TalTrees[1][3].."/"..TalTrees[2][3].."/"..TalTrees[3][3]..")"
	local talRole;
	table.sort(TalTrees, function(a, b)
		return a[3] > b[3]
	end) 

	talBuild = TalTrees[1][1].." "..talBuild;
	talRole = TalTrees[1][4];

	local profile = newProfile or CulteDKP:GetDefaultEntity();
	profile.player=UnitName("player");
	profile.version=core.SemVer;

	CulteDKP:GetTable(CulteDKP_Profiles, true)[UnitName("player")] = profile;

	if oldProfile then
		CulteDKP:GetTable(CulteDKP_DKPTable, true)[oldProfile[1][1]].version = core.SemVer;
	end

	CulteDKP.Sync:SendData("CDKProfileSend", profile)
	CulteDKP.Sync:SendData("CDKPTalents", talBuild)
	CulteDKP.Sync:SendData("CDKPRoles", talRole)

	table.wipe(TalTrees);
end

-------
-- TEAM FUNCTIONS END
-------

-------------------------------------
-- Recursively searches tar (table) for val (string) as far as 4 nests deep (use field only if you wish to search a specific key IE: CulteDKP:GetTable(CulteDKP_DKPTable, true), "Vapok", "player" would only search for Vapok in the player key)
-- returns an indexed array of the keys to get to searched value
-- First key is the result (ie if it's found 8 times, it will return 8 tables containing results).
-- Second key holds the path to the value searched. So to get to a player searched on DKPTable that returned 1 result, CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]][search[1][2]] would point at the "player" field
-- if the result is 1 level deeper, it would be CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]][search[1][2]][search[1][3]].  CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[2][1]][search[2][2]][search[2][3]] would locate the second return, if there is one.
-- use to search for players in SavedVariables. Only two possible returns is the table or false.
-------------------------------------
function CulteDKP:Table_Search(tar, val, field, limit)
	local value = string.upper(tostring(val));
	local location = {}
	local tableLimit = limit or -1;
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if string.upper(tostring(v)) == value then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
											if tableLimit ~= -1 and #location >= tableLimit then
												return location;
											end;
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
										if tableLimit ~= -1 and #location >= tableLimit then
											return location;
										end;
									end
								end;
							end
						end
						if string.upper(tostring(v)) == value then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
									if tableLimit ~= -1 and #location >= tableLimit then
										return location;
									end;
								end
							else
								tinsert(location, {temp1, temp2, k} )
								if tableLimit ~= -1 and #location >= tableLimit then
									return location;
								end;
							end
						end;
					end
				end
				if string.upper(tostring(v)) == value then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
							if tableLimit ~= -1 and #location >= tableLimit then
								return location;
							end;
						end
					else
						tinsert(location, {temp1, k} )
						if tableLimit ~= -1 and #location >= tableLimit then
							return location;
						end;
					end
				end;
			end
		end
		if string.upper(tostring(v)) == value then
			if field then
				if k == field then
					tinsert(location, k)
					if tableLimit ~= -1 and #location >= tableLimit then
						return location;
					end;
				end
			else
				tinsert(location, k)
				if tableLimit ~= -1 and #location >= tableLimit then
					return location;
				end;
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function CulteDKP:TableStrFind(tar, val, field, limit)              -- same function as above, but searches values that contain the searched string rather than exact string matches
	local value = string.upper(tostring(val));        -- ex. CulteDKP:TableStrFind(CulteDKP:GetTable(CulteDKP_DKPHistory, true), "Vapok") will return the path to any table element that contains "Vapok"
	local location = {}
	local tableLimit = limit or -1 -- so some functions dont operate on huge tables when they need like last 20 records...
	for k,v in pairs(tar) do
		if(type(v) == "table") then
			local temp1 = k
			for k,v in pairs(v) do
				if(type(v) == "table") then
					local temp2 = k;
					for k,v in pairs(v) do
						if(type(v) == "table") then
							local temp3 = k
							for k,v in pairs(v) do
								if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
									if field then
										if k == field then
											tinsert(location, {temp1, temp2, temp3, k} )
											if tableLimit ~= -1 and #location >= tableLimit then
												return location;
											end;
										end
									else
										tinsert(location, {temp1, temp2, temp3, k} )
										if tableLimit ~= -1 and #location >= tableLimit then
											return location;
										end;
									end
								end;
							end
						end
						if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
							if field then
								if k == field then
									tinsert(location, {temp1, temp2, k} )
									if tableLimit ~= -1 and #location >= tableLimit then
										return location;
									end;
								end
							else
								tinsert(location, {temp1, temp2, k} )
								if tableLimit ~= -1 and #location >= tableLimit then
									return location;
								end;
							end
						end;
					end
				end
				if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
					if field then
						if k == field then
							tinsert(location, {temp1, k} )
							if tableLimit ~= -1 and #location >= tableLimit then
								return location;
							end;
						end
					else
						tinsert(location, {temp1, k} )
						if tableLimit ~= -1 and #location >= tableLimit then
							return location;
						end;
					end
				end;
			end
		end
		if (field ~= "players" and field ~= "player" and strfind(string.upper(tostring(v)), value)) or ((field == "players" or field == "player") and (strfind(string.upper(tostring(v)), ","..value..",") or strfind(string.upper(tostring(v)), value..",") == 1)) then
			if field then
				if k == field then
					tinsert(location, k)
					if tableLimit ~= -1 and #location >= tableLimit then
						return location;
					end;
				end
			else
				tinsert(location, k)
				if tableLimit ~= -1 and #location >= tableLimit then
					return location;
				end;
			end
		end;
	end
	if (#location > 0) then
		return location;
	else
		return false;
	end
end

function CulteDKP:DKPTable_Set(tar, field, value, loot)                -- updates field with value where tar is found (IE: CulteDKP:DKPTable_Set("Vapok", "dkp", 10) adds 10 dkp to user Vapok). loot = true/false if it's to alter lifetime_spent
	local result = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), tar);
	for i=1, #result do
		local current = CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]][field];
		if(field == "dkp") then
			CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]][field] = CulteDKP_round(tonumber(current + value), core.DB.modes.rounding)
			if value > 0 and loot == false then
				CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]]["lifetime_gained"] = CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]]["lifetime_gained"] + value), core.DB.modes.rounding)
			elseif value < 0 and loot == true then
				CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]]["lifetime_spent"] = CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]]["lifetime_spent"] + value), core.DB.modes.rounding)
			end
		else
			CulteDKP:GetTable(CulteDKP_DKPTable, true)[result[i][1]][field] = value
		end
	end
	CulteDKP:DKPTable_Update()
end
