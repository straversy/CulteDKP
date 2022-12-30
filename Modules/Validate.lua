local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local DKPTableTemp = {}
local ValInProgress = false

function CulteDKP_TableCompare(t1,t2) 		-- compares two tables. returns true if all keys and values match
	local ty1 = type(t1)
	local ty2 = type(t2)
	
	if ty1 ~= ty2 then
		return false
	end
	
	if ty1 ~= 'table' and ty2 ~= 'table' then
		return t1 == t2
	end
	
	for k1,v1 in pairs(t1) do
		local v2 = t2[k1]
		if v2 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	for k2,v2 in pairs(t2) do
		local v1 = t1[k2]
		if v1 == nil or not TableCompare(v1,v2) then
			return false
		end
	end
	return true
end

function CulteDKP:ValidateDKPTable_Loot()
	DKPTableTemp = {}
	local i=1
	local timer = 0
	local processing = false
	local total = #CulteDKP:GetTable(CulteDKP_Loot, true);
	CulteDKP:Print("Building Validation Temp Table...");
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= total and not processing then
			processing = true
			local search = CulteDKP:Table_Search(DKPTableTemp, CulteDKP:GetTable(CulteDKP_Loot, true)[i].player, "player")

			if search then
				DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost)
				DKPTableTemp[search[1][1]].lifetime_spent = DKPTableTemp[search[1][1]].lifetime_spent + tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost)
			else
				table.insert(DKPTableTemp, { player=CulteDKP:GetTable(CulteDKP_Loot, true)[i].player, dkp=tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost), lifetime_gained=0, lifetime_spent=tonumber(CulteDKP:GetTable(CulteDKP_Loot, true)[i].cost) })
			end
			processing = false
			i=i+1
			timer = 0
		elseif i > #CulteDKP:GetTable(CulteDKP_Loot, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			CulteDKP:ValidateDKPTable_DKP()
		end
	end)
end

function CulteDKP:ValidateDKPTable_DKP()
	local i=1
	local j=1
	local timer = 0
	local timer2 = 0
	local processing = false
	local pause = false
	local proc2 = false
	local total = #CulteDKP:GetTable(CulteDKP_DKPHistory, true)
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.0001 and i <= total and not processing and not pause then
			processing = true
			pause = true

			local players = {strsplit(",", strsub(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].players, 1, -2))}
			local dkp = {strsplit(",", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp)}

			if #dkp == 1 then
				for i=1, #players do
					dkp[i] = tonumber(dkp[1])
				end
			else
				for i=1, #dkp do
					dkp[i] = tonumber(dkp[i])
				end
			end
			
			local ValidateTimer2 = ValidateTimer2 or CreateFrame("StatusBar", nil, UIParent)
			ValidateTimer2:SetScript("OnUpdate", function(self, elapsed)
				timer2 = timer2 + elapsed
				if timer2 > 0.0001 and j <= #players and not proc2 then
					proc2 = true

					local search = CulteDKP:Table_Search(DKPTableTemp, players[j], "player")

					if search then
						DKPTableTemp[search[1][1]].dkp = DKPTableTemp[search[1][1]].dkp + tonumber(dkp[j])
						if ((tonumber(dkp[j]) > 0 and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes) or (tonumber(dkp[j]) < 0 and CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes)) and not strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp, "%-%d*%.?%d+%%") then
							DKPTableTemp[search[1][1]].lifetime_gained = DKPTableTemp[search[1][1]].lifetime_gained + tonumber(dkp[j])
						end
					else
						if ((tonumber(dkp[j]) > 0 and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes) or (tonumber(dkp[j]) < 0 and CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes)) and not strfind(CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].dkp, "%-%d*%.?%d+%%") then
							table.insert(DKPTableTemp, { player=players[j], dkp=tonumber(dkp[j]), lifetime_gained=tonumber(dkp[j]), lifetime_spent=0 })
						else
							table.insert(DKPTableTemp, { player=players[j], dkp=tonumber(dkp[j]), lifetime_gained=0, lifetime_spent=0 })
						end
					end
					j=j+1
					proc2 = false
				elseif j > #players then
					ValidateTimer2:SetScript("OnUpdate", nil)
					j=1
					timer2 = 0
					pause = false					
					i=i+1
					processing = false
					timer = 0
				end
			end)
		elseif i > #CulteDKP:GetTable(CulteDKP_DKPHistory, true) and not processing and not proc2 and not pause then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			CulteDKP:Print("Validation Temp Table built.");
			CulteDKP:ValidateDKPTable_Final()
		end
	end)
end

function CulteDKP:ValidateDKPTable_Final()
	-- validates all profile DKP values against saved values created above
	local i=1
	local timer = 0
	local processing = false
	local rectified = 0
	
	CulteDKP:Print("Validating Profiles...");

	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.1 and i <= #DKPTableTemp and not processing then
			processing = true
			local flag = false
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), DKPTableTemp[i].player, "player")

			if search then
				if CulteDKP:GetTable(CulteDKP_Archive, true)[DKPTableTemp[i].player] then
					DKPTableTemp[i].dkp = DKPTableTemp[i].dkp + tonumber(CulteDKP:GetTable(CulteDKP_Archive, true)[DKPTableTemp[i].player].dkp)
					DKPTableTemp[i].lifetime_gained = DKPTableTemp[i].lifetime_gained + tonumber(CulteDKP:GetTable(CulteDKP_Archive, true)[DKPTableTemp[i].player].lifetime_gained)
					DKPTableTemp[i].lifetime_spent = DKPTableTemp[i].lifetime_spent + tonumber(CulteDKP:GetTable(CulteDKP_Archive, true)[DKPTableTemp[i].player].lifetime_spent)
				end
				if CulteDKP_round(tonumber(DKPTableTemp[i].dkp), core.DB.modes.rounding) ~= CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp), core.DB.modes.rounding) then
					CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].dkp = tonumber(DKPTableTemp[i].dkp)
					flag = true
				end
				if CulteDKP_round(tonumber(DKPTableTemp[i].lifetime_gained), core.DB.modes.rounding) ~= CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_gained), core.DB.modes.rounding) then
					CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_gained = tonumber(DKPTableTemp[i].lifetime_gained)
					flag = true
				end
				if CulteDKP_round(tonumber(DKPTableTemp[i].lifetime_spent), core.DB.modes.rounding) ~= CulteDKP_round(tonumber(CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_spent), core.DB.modes.rounding) then
					CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].lifetime_spent = tonumber(DKPTableTemp[i].lifetime_spent)
					flag = true
				end
			end
			if flag then 
				rectified = rectified + 1 
				CulteDKP:Print("DKP Profile for "..DKPTableTemp[i].player.." adjusted.");
			end
			i=i+1
			processing = false
			timer = 0
		elseif i > #DKPTableTemp then
			ValidateTimer:SetScript("OnUpdate", nil)
			timer = 0
			if rectified == 0 then
				CulteDKP:Print(L["VALIDATIONCOMPLETE1"])
			else
				CulteDKP:Print(string.format(L["VALIDATIONCOMPLETE2"], rectified))
			end
			ValInProgress = false
			table.wipe(DKPTableTemp)
			CulteDKP:FilterDKPTable(core.currentSort, "reset")
		end
	end)
end

function CulteDKP:ValidateDKPHistory()
	local deleted_entries = 0
	local i=1
	local timer = 0
	local processing = false
	
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #CulteDKP:GetTable(CulteDKP_DKPHistory, true) and not processing then
			processing = true
			-- delete duplicate entries and correct DKP (DKPHistory table)
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].index, "index")
			
			if CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes then  -- adds deltedby index to field if it was received after a delete entry was received but was sent by someone that did not have the delete entry
				local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true), CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].deletes, "index")

				if search and not CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].deletedby then
					CulteDKP:GetTable(CulteDKP_DKPHistory, true)[search[1][1]].deletedby = CulteDKP:GetTable(CulteDKP_DKPHistory, true)[i].index
				end
			end

			if #search > 1 then
				for j=2, #search do
					table.remove(CulteDKP:GetTable(CulteDKP_DKPHistory, true), search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				i=i+1
			end

			processing = false
			timer = 0
		elseif i > #CulteDKP:GetTable(CulteDKP_DKPHistory, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			CulteDKP:Print("History Table Validated. "..deleted_entries.." entries deleted.");
			timer = 0
			CulteDKP:ValidateDKPTable_Loot()
		end
	end)
end

function CulteDKP:ValidateLootTable()  -- validation starts here
	if ValInProgress then
		CulteDKP:Print(L["VALIDATEINPROG"])
		return
	end
	local deleted_entries = 0
	-- delete duplicate entries and correct DKP (loot table)
	local i=1
	local timer = 0
	local processing = false
	ValInProgress = true
	
	CulteDKP:Print(L["VALIDATINGTABLES"])
	local ValidateTimer = ValidateTimer or CreateFrame("StatusBar", nil, UIParent)
	ValidateTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		if timer > 0.01 and i <= #CulteDKP:GetTable(CulteDKP_Loot, true) and not processing then
			processing = true
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true), CulteDKP:GetTable(CulteDKP_Loot, true)[i].index, "index")
			
			if search and #search > 1 then
				for j=2, #search do
					table.remove(CulteDKP:GetTable(CulteDKP_Loot, true), search[j][1])
					deleted_entries = deleted_entries + 1
				end
			else
				i=i+1
			end
			processing = false
			timer = 0
		elseif i > #CulteDKP:GetTable(CulteDKP_Loot, true) then
			ValidateTimer:SetScript("OnUpdate", nil)
			CulteDKP:Print("Loot Table Validated. "..deleted_entries.." entries deleted.");
			timer = 0
			CulteDKP:ValidateDKPHistory()
		end
	end)
end
