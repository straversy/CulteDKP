local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local ConsolidatedTable = {}
local DKPTableTemp = {}
local ValInProgress = false

local function ConsolidateTables(keepDKP)
	table.sort(ConsolidatedTable, function(a,b)   	-- inverts tables; oldest to newest
		return a["date"] < b["date"]
	end)

	local i=1
	local timer = 0
	local processing = false
	local DKPStringTemp = ""	-- stores DKP comparisons to create a new entry if they are different
	local PlayerStringTemp = "" -- stores player list to create new DKPHistory entry if any values differ from the DKPTable
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #ConsolidatedTable and not processing then
			processing = true

			if ConsolidatedTable[i].loot then
				local search = CulteDKP:Table_Search(DKPTableTemp, ConsolidatedTable[i].player, "player")

				if search then
					DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(ConsolidatedTable[i].cost)
					DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + tonumber(ConsolidatedTable[i].cost)
				else
					table.insert(DKPTableTemp, { player=ConsolidatedTable[i].player, dkp=tonumber(ConsolidatedTable[i].cost), lifetime_spent=tonumber(ConsolidatedTable[i].cost), lifetime_gained=0 })
				end
			elseif ConsolidatedTable[i].reason then
				local players = {strsplit(",", strsub(ConsolidatedTable[i].players, 1, -2))}

				if strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%") then -- is a decay, calculate new values
					local f = {strfind(ConsolidatedTable[i].dkp, "%-%d*%.?%d+%%")}
					local playerString = ""
					local DKPString = ""
					local value = tonumber(strsub(ConsolidatedTable[i].dkp, f[1]+1, f[2]-1)) / 100

					for j=1, #players do
						local search2 = CulteDKP:Table_Search(DKPTableTemp, players[j], "player")

						if search2 and DKPTableTemp[search2[1][1]].dkp > 0 then
							local deduction = DKPTableTemp[search2[1][1]].dkp * -value;
							deduction = CulteDKP_round(deduction, core.DB.modes.rounding)

							DKPTableTemp[search2[1][1]].dkp = DKPTableTemp[search2[1][1]].dkp + deduction
							playerString = playerString..players[j]..","
							DKPString = DKPString..deduction..","
						else
							playerString = playerString..players[j]..","
							DKPString = DKPString.."0,"

							if not search2 then
								table.insert(DKPTableTemp, { player=players[j], dkp=0, lifetime_gained=0, lifetime_spent=0 })
							end
						end

					end
					local perc = value * 100
					DKPString = DKPString.."-"..perc.."%"

					local EntrySearch = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), ConsolidatedTable[i].date, "date")

					if EntrySearch then
						CulteDKP:GetTable(CulteDKP_DKPHistory, true)[EntrySearch[1][1]].players = playerString
						CulteDKP:GetTable(CulteDKP_DKPHistory, true)[EntrySearch[1][1]].dkp = DKPString
					end
				else
					local dkp = tonumber(ConsolidatedTable[i].dkp)

					for j=1, #players do
						local search = CulteDKP:Table_Search(DKPTableTemp, players[j], "player")

						if search then
							DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + dkp
							DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + dkp
						else
							if dkp > 0 then
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=dkp, lifetime_spent=0 })
							else
								table.insert(DKPTableTemp, { player=players[j], dkp=dkp, lifetime_gained=0, lifetime_spent=0 })
							end
						end
					end
				end
			end
			i=i+1
			processing = false
			timer = 0
		elseif i > #ConsolidatedTable then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			-- Create new DKPHistory entry compensating for difference between history and DKPTable (if some history was lost due to overwriting)
			if keepDKP then
				for i=1, #CulteDKP:GetTable(CulteDKP_DKPTable, true) do 
					local search = CulteDKP:Table_Search(DKPTableTemp, CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player, "player")

					if search then
						if CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].dkp ~= DKPTableTemp[search[1][1]].dkp then
							local val = CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].dkp - DKPTableTemp[search[1][1]].dkp
							val = CulteDKP_round(val, core.DB.modes.rounding)
							PlayerStringTemp = PlayerStringTemp..CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player..","
							DKPStringTemp = DKPStringTemp..val..","
						end
					end
				end

				if DKPStringTemp ~= "" and PlayerStringTemp ~= "" then
					local insert = {
						players = PlayerStringTemp,
						index 	= UnitName("player").."-"..(time()-10),
						dkp 	= DKPStringTemp.."-1%",
						date 	= time(),
						reason	= "Migration Correction",
						hidden	= true,
					}
					table.insert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), insert)
				end
			else
				for i=1, #CulteDKP:GetTable(CulteDKP_DKPTable, true) do 
					local search = CulteDKP:Table_Search(DKPTableTemp, CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].player, "player")

					if search then
						CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].dkp = DKPTableTemp[search[1][1]].dkp
						CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent
						CulteDKP:GetTable(CulteDKP_DKPTable, true)[i].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained
					end
				end
			end

			local curTime = time();
			for i=1, #DKPTableTemp do 	-- finds who had history but was deleted; adds them to archive if so
				local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), DKPTableTemp[i].player)

				if not search then
					CulteDKP:GetTable(CulteDKP_Archive, true)[DKPTableTemp[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=true, edited=curTime } 
				end
			end

			table.sort(CulteDKP:GetTable(CulteDKP_Loot, true), function(a,b)
				return a["date"] > b["date"]
			end)
			table.sort(CulteDKP:GetTable(CulteDKP_DKPHistory, true), function(a,b)
				return a["date"] > b["date"]
			end)
			CulteDKP:GetTable(CulteDKP_DKPHistory, true).seed = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1].index;
			CulteDKP:GetTable(CulteDKP_Loot, true).seed = CulteDKP:GetTable(CulteDKP_Loot, true)[1].index
			CulteDKP:FilterDKPTable(core.currentSort, "reset")
			ValInProgress = false
			CulteDKP:Print(L["REPAIRCOMP"])
		end
	end)
end

local function RepairDKPHistory(keepDKP)
	local deleted_entries = 0
	local i=1
	local timer = 0
	local processing = false
	local officer = UnitName("player")
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #CulteDKP:GetTable(CulteDKP_DKPHistory, true) and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].date, "date")
			
			if CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes or CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletedby or CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].reason == "Migration Correction" then  -- removes deleted entries/Migration Correction
				table.remove(CulteDKP:GetTable(CulteDKP_DKPHistory, true), i)
			elseif #search > 1 then 		-- removes duplicate entries
				for j=2, #search do
					table.remove(CulteDKP:GetTable(CulteDKP_DKPHistory, true), search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				local curTime = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].date
				CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].index = officer.."-"..curTime
				if not strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp, "%-%d*%.?%d+%%") then
					CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp = tonumber(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp)
				end
				table.insert(ConsolidatedTable, CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #CulteDKP:GetTable(CulteDKP_DKPHistory, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			ConsolidateTables(keepDKP)
		end
	end)
end

function CulteDKP:RepairTables(keepDKP)  -- Repair starts
	if ValInProgress then
		CulteDKP:Print(L["VALIDATEINPROG"])
		return
	end

	local officer = UnitName("player")
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	CulteDKP:Print(L["REPAIRSTART"])

	if keepDKP then
		CulteDKP:Print("Keep DKP: true")
	else
		CulteDKP:Print("Keep DKP: false")
	end

	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #CulteDKP:GetTable(CulteDKP_Loot, true) and not processing then
			processing = true
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true), CulteDKP:GetTable(CulteDKP_Loot, true)[i].date, "date")
			
			if CulteDKP:GetTable(CulteDKP_Loot, true)[i].deletedby or CulteDKP:GetTable(CulteDKP_Loot, true)[i].deletes then
				table.remove(CulteDKP:GetTable(CulteDKP_Loot, true), i)
			elseif search and #search > 1 then
				for j=2, #search do
					if CulteDKP:GetTable(CulteDKP_Loot, true)[search[j][1]].loot == CulteDKP:GetTable(CulteDKP_Loot, true)[i].loot then
						table.remove(CulteDKP:GetTable(CulteDKP_Loot, true), search[j][1])
					end
				end
			else
				local curTime = CulteDKP:GetTable(CulteDKP_Loot, true)[i].date
				CulteDKP:GetTable(CulteDKP_Loot, true)[i].index = officer.."-"..curTime
				if tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost) > 0 then
					CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost = tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost) * -1
				end
				table.insert(ConsolidatedTable, CulteDKP:GetTable(CulteDKP_Loot, true)[i])
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #CulteDKP:GetTable(CulteDKP_Loot, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			RepairDKPHistory(keepDKP)
		end
	end)
end
