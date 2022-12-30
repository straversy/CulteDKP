local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local awards = 0;  		-- counts the number of hourly DKP awards given
local timer = 0;
local SecondTracker = 0;
local MinuteCount = 0;
local SecondCount = 0;
local StartAwarded = false;
local StartBonus = 0;
local totalAwarded = 0;

local function SecondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds <= 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    
    if tonumber(mins) <= 0 then
    	return secs
    elseif tonumber(hours) <= 0 then
    	return mins..":"..secs
    else
    	return hours..":"..mins..":"..secs
    end
  end
end

function CulteDKP:AwardPlayer(name, amount)
	local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), name, "player")
	local path;

	if search then
		path = CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]]
		path.dkp = path.dkp + amount
		path.lifetime_gained = path.lifetime_gained + amount;
	end
end

local function AwardRaid(amount, reason)
	if UnitAffectingCombat("player") then
		C_Timer.After(5, function() AwardRaid(amount, reason) end)
		return;
	end

	local tempName
	local tempList = "";
	local curTime = time();
	local curOfficer = UnitName("player")

	local OnlineOnly = core.DB.modes.OnlineOnly
	local limitToZone = core.DB.modes.SameZoneOnly

	for i=1, 40 do
		local tempName, _rank, _subgroup, _level, _class, _fileName, zone, online = GetRaidRosterInfo(i)

		local search_DKP = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), tempName)
		local isSameZone = zone == GetRealZoneText()

		if search_DKP and (not OnlineOnly or online) and (not limitToZone or isSameZone) then
			CulteDKP:AwardPlayer(tempName, amount)
			tempList = tempList..tempName..",";
		end
	end

	if #CulteDKP:GetTable(CulteDKP_Standby, true) > 0 and core.DB.DKPBonus.IncStandby then
		local i = 1

		while i <= #CulteDKP:GetTable(CulteDKP_Standby, true) do
			local standbyProfile = CulteDKP:GetTable(CulteDKP_Standby, true)[i].player;
			local isOnline = UnitIsConnected(standbyProfile);
			if strfind(tempList, standbyProfile) then
				table.remove(CulteDKP:GetTable(CulteDKP_Standby, true), i)
			else
				if standbyProfile and (not OnlineOnly or isOnline) then
					CulteDKP:AwardPlayer(standbyProfile, amount)
					tempList = tempList..standbyProfile..",";
				end
				i=i+1
			end
		end
	end

	if tempList ~= "" then
		local newIndex = curOfficer.."-"..curTime
		tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true), 1, {players=tempList, dkp=amount, reason=reason, date=curTime, index=newIndex})

		if CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
			CulteDKP:DKPHistory_Update(true)
		end
		CulteDKP:DKPTable_Update()

		CulteDKP.Sync:SendData("CDKPDKPDist", CulteDKP:GetTable(CulteDKP_DKPHistory, true)[1])

		CulteDKP.Sync:SendData("CDKPBCastMsg", L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
		CulteDKP:Print(L["RAIDDKPADJUSTBY"].." "..amount.." "..L["FORREASON"]..": "..reason)
	end
end

function CulteDKP:StopRaidTimer()
	if CulteDKP.RaidTimer then
		CulteDKP.RaidTimer:SetScript("OnUpdate", nil)
	end
	core.RaidInProgress = false
	core.RaidInPause = false
	CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDENDED"]..":")
	CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["INITRAID"])
	CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..strsub(CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
	CulteDKP.RaidTimerPopout.Output:SetText(CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText());
	CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
	CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["TOTALDKPAWARD"]..":")
	timer = 0;
	awards = 0;
	StartAwarded = false;
	MinuteCount = 0;
	SecondCount = 0;
	SecondTracker = 0;
	StartBonus = 0;

	if IsInRaid() and CulteDKP:CheckRaidLeader() and core.IsOfficer then
		if core.DB.DKPBonus.GiveRaidEnd then -- Award Raid Completion Bonus
			AwardRaid(core.DB.DKPBonus.CompletionBonus, L["RAIDCOMPLETIONBONUS"])
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	elseif IsInRaid() and core.IsOfficer then
		if core.DB.DKPBonus.GiveRaidEnd then
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.CompletionBonus);
			CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
		end
		totalAwarded = 0;
	end
end

function CulteDKP:StartRaidTimer(pause, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
	local increment;
	
	CulteDKP.RaidTimer = CulteDKP.RaidTimer or CreateFrame("StatusBar", nil, UIParent)
	if not syncTimer then
		if not pause then -- pause == false
			CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
				CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				if totalAwarded == 0 then
					CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
				else
					CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
				end
			end
			CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = core.DB.modes.increment;
			core.RaidInProgress = true
			core.RaidInPause = false
		else -- pause == true
			CulteDKP.RaidTimer:SetScript("OnUpdate", nil)
			CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["CONTINUERAID"])
			CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["RAIDPAUSED"]..":")
			CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Hide();
			CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cffff0000"..strsub(CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText(), 11, -3).."|r")
			CulteDKP.RaidTimerPopout.Output:SetText(CulteDKP.ConfigTab2.RaidTimerContainer.Output:GetText())
			core.RaidInProgress = false
			core.RaidInPause = true
			return;
		end
		if IsInRaid() and CulteDKP:CheckRaidLeader() and not pause and core.IsOfficer then
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then -- Award On Time Bonus
				AwardRaid(core.DB.DKPBonus.OnTimeBonus, L["ONTIMEBONUS"])
				StartBonus = core.DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		else
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then
				StartBonus = core.DB.DKPBonus.OnTimeBonus;
				StartAwarded = true;
			end
		end
	else
		if core.RaidInProgress == false and timer == 0 and SecondCount == 0 and MinuteCount == 0 then
			timer = tonumber(syncTimer);
			SecondCount = tonumber(syncSecondCount);
			MinuteCount = tonumber(syncMinuteCount);
			totalAwarded = tonumber(syncAward) - tonumber(core.DB.DKPBonus.OnTimeBonus);

			CulteDKP.ConfigTab2.RaidTimerContainer.StartTimer:SetText(L["ENDRAID"])
			CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:SetText(L["TIMEELAPSED"]..":")
			CulteDKP.ConfigTab2.RaidTimerContainer.OutputHeader:Show();
			if core.DB.DKPBonus.GiveRaidStart and not StartAwarded then
				totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.OnTimeBonus)
				CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r")
			else
				CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cffff0000"..totalAwarded.."|r")
			end
			CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:SetText(L["BONUSAWARDED"]..":")
			CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show()
			CulteDKP.ConfigTab2.RaidTimerContainer.PauseTimer:Show();
			increment = core.DB.modes.increment;
			StartBonus = core.DB.DKPBonus.OnTimeBonus;
			if not StartAwarded and core.DB.DKPBonus.GiveRaidStart then
				StartAwarded = true;
				core.RaidInProgress = true
			end
		else
			return;
		end
	end
	
	CulteDKP.RaidTimer:SetScript("OnUpdate", function(self, elapsed)
		timer = timer + elapsed
		SecondTracker = SecondTracker + elapsed

		if SecondTracker >= 1 then
			local curTicker = SecondsToClock(timer);
			CulteDKP.ConfigTab2.RaidTimerContainer.Output:SetText("|cff00ff00"..curTicker.."|r")
			CulteDKP.RaidTimerPopout.Output:SetText("|cff00ff00"..curTicker.."|r")
			SecondTracker = 0;
			SecondCount = SecondCount + 1;
		end

		if SecondCount >= 60 then						-- counds minutes past toward interval
			SecondCount = 0;
			MinuteCount = MinuteCount + 1;
			CulteDKP.Sync:SendData("CDKPRaidTime", "sync "..timer.." "..SecondCount.." "..MinuteCount.." "..totalAwarded)
			--print("Minute has passed!!!!")
		end

		if MinuteCount >= increment and increment > 0 then				-- apply bonus once increment value has been met
			MinuteCount = 0;
			totalAwarded = totalAwarded + tonumber(core.DB.DKPBonus.IntervalBonus)
			CulteDKP.ConfigTab2.RaidTimerContainer.BonusHeader:Show();
			CulteDKP.ConfigTab2.RaidTimerContainer.Bonus:SetText("|cff00ff00"..totalAwarded.."|r");

			if IsInRaid() and CulteDKP:CheckRaidLeader() and core.RaidInProgress then
				AwardRaid(core.DB.DKPBonus.IntervalBonus, L["TIMEINTERVALBONUS"])
			end
		end
	end)
end
