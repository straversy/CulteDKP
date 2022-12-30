local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

local function CMD_Handler(...)
	local _, cmd = string.split(" ", ..., 2)

	if tonumber(cmd) then
		cmd = tonumber(cmd) -- converts it to a number if it's a valid numeric string
	end

	return cmd;
end

function CulteDKP_Standby_Announce(bossName)
	core.StandbyActive = true; -- activates opt in
	table.wipe(CulteDKP:GetTable(CulteDKP_Standby, true));
	if CulteDKP:CheckRaidLeader() then
		SendChatMessage(bossName..L["STANDBYOPTINBEGIN"], "GUILD") -- only raid leader announces
	end
	C_Timer.After(120, function ()
		core.StandbyActive = false;  -- deactivates opt in
		if CulteDKP:CheckRaidLeader() then
			SendChatMessage(L["STANDBYOPTINEND"]..bossName, "GUILD") -- only raid leader announces
			if core.DB.DKPBonus.AutoIncStandby then
				CulteDKP:AutoAward(2, core.DB.DKPBonus.BossKillBonus, core.DB.bossargs.CurrentRaidZone..": "..core.DB.bossargs.LastKilledBoss)
			end
		end
	end)
end

function CulteDKP_Standby_Handler(text, ...)
	local name = ...;
	local cmd;
	local response = L["ERRORPROCESSING"];

	if string.find(name, "-") then					-- finds and removes server name from name if exists
		local dashPos = string.find(name, "-")
		name = strsub(name, 1, dashPos-1)
	end

	if string.find(text, "!standby") == 1 and core.IsOfficer then
		cmd = tostring(CMD_Handler(text))

		if cmd and cmd:gsub("%s+", "") ~= "nil" and cmd:gsub("%s+", "") ~= "" then
			-- if it's !standby *name*
			cmd = cmd:gsub("%s+", "") -- removes unintended spaces from string
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), cmd)
			local verify = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Standby, true), cmd)

			if search and not verify then
				table.insert(CulteDKP:GetTable(CulteDKP_Standby, true), CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]])
				response = "CulteDKP: "..cmd.." "..L["STANDBYWHISPERRESP1"]
			elseif search and verify then
				response = "CulteDKP: "..cmd.." "..L["STANDBYWHISPERRESP2"]
			else
				response = "CulteDKP: "..cmd.." "..L["STANDBYWHISPERRESP3"];
			end
		else
			-- if it's just !standby
			local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), name)
			local verify = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Standby, true), name)

			if search and not verify then
				table.insert(CulteDKP:GetTable(CulteDKP_Standby, true), CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]])
				response = "CulteDKP: "..L["STANDBYWHISPERRESP4"]
			elseif search and verify then
				response = "CulteDKP: "..L["STANDBYWHISPERRESP5"]
			else
				response = "CulteDKP: "..L["STANDBYWHISPERRESP6"];
			end
		end
		if CulteDKP:CheckRaidLeader() then 						 -- only raid leader responds to add.
			SendChatMessage(response, "WHISPER", nil, name)
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg, ...)		-- suppresses outgoing whisper responses to limit spam
		if core.StandbyActive and core.DB.defaults.SuppressTells then
			if strfind(msg, "CulteDKP: ") then
				return true
			end
		end
	end)
end
