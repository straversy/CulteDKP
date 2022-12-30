local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

function CulteDKP:AutoAward(phase, amount, reason) -- phase identifies who to award (1=just raid, 2=just standby, 3=both)
	local tempList = "";
	local tempList2 = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	if CulteDKP:CheckRaidLeader() then -- only allows raid leader to disseminate DKP
		if phase == 1 or phase == 3 then
			for i=1, 40 do
				local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)
				local search_DKP = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), tempName)
				local OnlineOnly = core.DB.modes.OnlineOnly
				local limitToZone = core.DB.modes.SameZoneOnly
				local isSameZone = zone == GetRealZoneText()

				if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
					CulteDKP:AwardPlayer(tempName, amount)
					tempList = tempList..tempName..",";
				end
			end
		end

		if #CulteDKP:GetTable(CulteDKP_Standby, true) > 0 and core.DB.DKPBonus.AutoIncStandby and (phase == 2 or phase == 3) then
			local raidParty = "";
			for i=1, 40 do
				local tempName = GetRaidRosterInfo(i)
				if tempName then	
					raidParty = raidParty..tempName..","
				end
			end
			for i=1, #CulteDKP:GetTable(CulteDKP_Standby, true) do
				if strfind(raidParty, CulteDKP:GetTable(CulteDKP_Standby, true)[i].player..",") ~= 1 and not strfind(raidParty, ","..CulteDKP:GetTable(CulteDKP_Standby, true)[i].player..",") then
					CulteDKP:AwardPlayer(CulteDKP:GetTable(CulteDKP_Standby, true)[i].player, amount)
					tempList2 = tempList2..CulteDKP:GetTable(CulteDKP_Standby, true)[i].player..",";
				end
			end
			local i = 1
			while i <= #CulteDKP:GetTable(CulteDKP_Standby, true) do
				if CulteDKP:GetTable(CulteDKP_Standby, true)[i] and (strfind(raidParty, CulteDKP:GetTable(CulteDKP_Standby, true)[i].player..",") == 1 or strfind(raidParty, ","..CulteDKP:GetTable(CulteDKP_Standby, true)[i].player..",")) then
					table.remove(CulteDKP:GetTable(CulteDKP_Standby, true), i)
				else
					i=i+1
				end
			end
		end

		if tempList ~= "" or tempList2 ~= "" then
			if (phase == 1 or phase == 3) and tempList ~= "" then
				local newIndex = curOfficer.."-"..curTime
				tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				CulteDKP.Sync:SendData("CDKPDKPDist", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])
			end
			if (phase == 2 or phase == 3) and tempList2 ~= "" then
				local newIndex = curOfficer.."-"..curTime+1
				tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, {players=tempList2, dkp=amount, reason=reason.." (Standby)", date=curTime+1, index=newIndex})
				CulteDKP.Sync:SendData("CDKPBCastMsg", L["STANDBYADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
				CulteDKP.Sync:SendData("CDKPDKPDist", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])
			end

			if CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
				CulteDKP:DKPHistory_Update(true)
			end
			CulteDKP:DKPTable_Update()
		end
	end
end
