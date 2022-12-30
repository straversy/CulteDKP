--[[
  Usage so far:  CulteDKP.Sync:SendData(prefix, core.WorkingTable)  --sends table through comm channel for updates
--]]  

local _, core = ...;
local _G = _G;
local CulteDKP = core.CulteDKP;
local L = core.L;

CulteDKP.Sync = LibStub("AceAddon-3.0"):NewAddon("CulteDKP", "AceComm-3.0")

local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local LibDeflate = LibStub:GetLibrary("LibDeflate")
--local LibCompress = LibStub:GetLi7brary("LibCompress")
--local LibCompressAddonEncodeTable = LibCompress:GetAddonEncodeTable()

function CulteDKP:ValidateSender(sender)                -- returns true if "sender" has permission to write officer notes. false if not or not found.
  local rankIndex = CulteDKP:GetGuildRankIndex(sender);

  if rankIndex == 1 then             -- automatically gives permissions above all settings if player is guild leader
    return true;
  end
  if #CulteDKP:GetTable(CulteDKP_Whitelist) > 0 then                  -- if a whitelist exists, checks that rather than officer note permissions
    for i=1, #CulteDKP:GetTable(CulteDKP_Whitelist) do
      if CulteDKP:GetTable(CulteDKP_Whitelist)[i] == sender then
        return true;
      end
    end
    return false;
  else
    if rankIndex then
      return C_GuildInfo.GuildControlGetRankFlags(rankIndex)[12]    -- returns true/false if player can write to officer notes
    else
      return false;
    end
  end
end

-------------------------------------------------
-- Register Broadcast Prefixs
-------------------------------------------------

function CulteDKP.Sync:OnEnable()
  CulteDKP.Sync:RegisterComm("CDKPDelUsers", CulteDKP.Sync:OnCommReceived())      -- Broadcasts deleted users (archived users not on the DKP table)
  CulteDKP.Sync:RegisterComm("CDKPAddUsers", CulteDKP.Sync:OnCommReceived())   -- Broadcasts newly added users (or recovers)
  CulteDKP.Sync:RegisterComm("CDKPMerge", CulteDKP.Sync:OnCommReceived())      -- Broadcasts 2 weeks of data from officers (for merging)
  -- Normal broadcast Prefixs
  CulteDKP.Sync:RegisterComm("CDKPDecay", CulteDKP.Sync:OnCommReceived())        -- Broadcasts a weekly decay adjustment
  CulteDKP.Sync:RegisterComm("CDKPBCastMsg", CulteDKP.Sync:OnCommReceived())      -- broadcasts a message that is printed as is
  CulteDKP.Sync:RegisterComm("CDKPCommand", CulteDKP.Sync:OnCommReceived())      -- broadcasts a command (ex. timers, bid timers, stop all timers etc.)
  CulteDKP.Sync:RegisterComm("CDKPLootDist", CulteDKP.Sync:OnCommReceived())      -- broadcasts individual loot award to loot table
  CulteDKP.Sync:RegisterComm("CDKPDelLoot", CulteDKP.Sync:OnCommReceived())      -- broadcasts deleted loot award entries
  CulteDKP.Sync:RegisterComm("CDKPDelSync", CulteDKP.Sync:OnCommReceived())      -- broadcasts deleated DKP history entries
  CulteDKP.Sync:RegisterComm("CDKPDKPDist", CulteDKP.Sync:OnCommReceived())      -- broadcasts individual DKP award to DKP history table
  CulteDKP.Sync:RegisterComm("CDKPMinBid", CulteDKP.Sync:OnCommReceived())      -- broadcasts minimum dkp values (set in Options tab or custom values in bid window)
  CulteDKP.Sync:RegisterComm("CDKPMaxBid", CulteDKP.Sync:OnCommReceived())      -- broadcasts maximum dkp values (set in Options tab or custom values in bid window)
  CulteDKP.Sync:RegisterComm("CDKPWhitelist", CulteDKP.Sync:OnCommReceived())      -- broadcasts whitelist
  CulteDKP.Sync:RegisterComm("CDKPDKPModes", CulteDKP.Sync:OnCommReceived())      -- broadcasts DKP Mode settings
  CulteDKP.Sync:RegisterComm("CDKPStand", CulteDKP.Sync:OnCommReceived())        -- broadcasts standby list
  CulteDKP.Sync:RegisterComm("CDKPRaidTime", CulteDKP.Sync:OnCommReceived())      -- broadcasts Raid Timer Commands
  CulteDKP.Sync:RegisterComm("CDKPZSumBank", CulteDKP.Sync:OnCommReceived())    -- broadcasts ZeroSum Bank
  CulteDKP.Sync:RegisterComm("CDKPQuery", CulteDKP.Sync:OnCommReceived())        -- Querys guild for spec/role data
  CulteDKP.Sync:RegisterComm("CDKPSeed", CulteDKP.Sync:OnCommReceived())
  CulteDKP.Sync:RegisterComm("CDKPBuild", CulteDKP.Sync:OnCommReceived())        -- broadcasts Addon build number to inform others an update is available.
  CulteDKP.Sync:RegisterComm("CDKPTalents", CulteDKP.Sync:OnCommReceived())      -- broadcasts current spec
  CulteDKP.Sync:RegisterComm("CDKPRoles", CulteDKP.Sync:OnCommReceived())        -- broadcasts current role info
  CulteDKP.Sync:RegisterComm("CDKPBossLoot", CulteDKP.Sync:OnCommReceived())      -- broadcast current loot table
  CulteDKP.Sync:RegisterComm("CDKPBidShare", CulteDKP.Sync:OnCommReceived())      -- broadcast accepted bids
  CulteDKP.Sync:RegisterComm("CDKPBidder", CulteDKP.Sync:OnCommReceived())      -- Submit bids
  CulteDKP.Sync:RegisterComm("CDKPAllTabs", CulteDKP.Sync:OnCommReceived())      -- Full table broadcast
  CulteDKP.Sync:RegisterComm("CDKPSetPrice", CulteDKP.Sync:OnCommReceived())      -- Set Single Item Price
  CulteDKP.Sync:RegisterComm("CDKPCurTeam", CulteDKP.Sync:OnCommReceived())      -- Sets Current Raid Team
  CulteDKP.Sync:RegisterComm("CDKPTeams", CulteDKP.Sync:OnCommReceived())
  CulteDKP.Sync:RegisterComm("CDKPPreBroad", CulteDKP.Sync:OnCommReceived()) -- send info that full broadcast is starting
  --CulteDKP.Sync:RegisterComm("CulteDKPEditLoot", CulteDKP.Sync:OnCommReceived())    -- not in use
  --CulteDKP.Sync:RegisterComm("CulteDKPDataSync", CulteDKP.Sync:OnCommReceived())    -- not in use
  --CulteDKP.Sync:RegisterComm("CulteDKPDKPLogSync", CulteDKP.Sync:OnCommReceived())  -- not in use
  --CulteDKP.Sync:RegisterComm("CulteDKPLogSync", CulteDKP.Sync:OnCommReceived())    -- not in use
  CulteDKP.Sync:RegisterComm("CDKProfileSend", CulteDKP.Sync:OnCommReceived()) -- Broadcast Player Profile for Update or Create
end

function GetNameFromLink(link)
  if link == nil then
    return "Item Name Not Found - Bad Link";
  end

  local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(link,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
  return Name;
end

-- main functions that receives all communication via appropriate channels
function CulteDKP.Sync:OnCommReceived(prefix, message, distribution, sender)
  
  if not core.Initialized or core.IsOfficer == nil then 
    return; 
  end

  if prefix then
    local decoded = LibDeflate:DecodeForWoWAddonChannel(message);
    local decompressed = LibDeflate:DecompressDeflate(decoded);

    
    if decompressed == nil then  -- this checks if message was previously encoded and compressed
      -- < 3.2.4-r61 CDKPBuild msg handler
      if prefix == "CDKPBuild" and sender ~= UnitName("player") then
        local LastVerCheck = time() - core.LastVerCheck;

        if LastVerCheck > 900 then             -- limits the Out of Date message from firing more than every 15 minutes 
          if tonumber(message) > core.BuildNumber then
            core.LastVerCheck = time();
            CulteDKP:Print(L["OUTOFDATEANNOUNCE"])
          end
        end

        if tonumber(message) < core.BuildNumber then   -- returns build number if receiving party has a newer version
          CulteDKP.Sync:SendData("CDKPBuild", tostring(core.BuildNumber))
        end
        return;
      elseif prefix == "CDKPBuild" and sender == UnitName("player") then
        return;
      else
        CulteDKP:Print("Unknown comm Received with prefix "..prefix.." from "..sender);
      end      
      return;
    end

    -- decompresed is not null meaning data is coming from 2.3.0 or CulteDKP
    success, _objReceived = LibAceSerializer:Deserialize(decompressed);
    
    --[[ 
      _objReceived = {
        Teams = {},
        CurrentTeam = "0",
        Data = string | {} | nil
      }
    --]]

    if success then
      if prefix == "CDKPQuery" then
        ------------------------------
        -- This has been deprecated --
        ------------------------------
        return;
      elseif prefix == "CDKPSeed" then
        CulteDKP:SeedReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPBidder" then
        CulteDKP:BidderReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPTeams" then
        CulteDKP:TeamsReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKProfileSend" then
        CulteDKP:ProfileReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPCurTeam" then
        CulteDKP:CurTeamReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPTalents" then
        CulteDKP:TalentsReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPRoles" then
        CulteDKP:RolesReceived(_objReceived, sender);
        return;
      elseif prefix == "CDKPBuild" then
        CulteDKP:BuildReceived(_objReceived, sender);
        return;
      end

      ---
      -- OFFICER LEVEL DATA
      ---
      if CulteDKP:ValidateSender(sender) then    -- validates sender as an officer. fail-safe to prevent addon alterations to manipulate DKP table

        if (prefix == "CDKPBCastMsg") and sender ~= UnitName("player") then
          CulteDKP:Print(_objReceived.Data);
          return;
        elseif prefix == "CDKPPreBroad" then
          CulteDKP:PreBroadReceived(_objReceived, sender);
          return;
        elseif prefix == "CDKPCommand" then
          CulteDKP:CommandReceived(_objReceived, sender);
          return;
        elseif prefix == "CDKPRaidTime" then
          CulteDKP:RaidTimeReceived(_objReceived, sender);
          return;
        end

        if (sender ~= UnitName("player")) then
          if prefix == "CDKPAllTabs" then   -- receives full table broadcast
            CulteDKP:AllTabsReceived(_objReceived);
            return;
          elseif prefix == "CDKPMerge" then
            CulteDKP:MergeReceived(_objReceived);
            return;
          elseif prefix == "CDKPLootDist" then
            CulteDKP:LootDistReceived(_objReceived);
            return;
          elseif prefix == "CDKPDKPDist" then
            CulteDKP:DKPDistReceived(_objReceived);
            return;
          elseif prefix == "CDKPDecay" then
            CulteDKP:DKPDecayReceived(_objReceived);
            return;
          elseif prefix == "CDKPAddUsers" then
            CulteDKP:AddUsersReceived(_objReceived);
            return;
          elseif prefix == "CDKPDelUsers" then
            CulteDKP:DelUsersReceived(_objReceived);
            return;
          elseif prefix == "CDKPDelLoot" then
            CulteDKP:DelLootReceived(_objReceived);
            return;
          elseif prefix == "CDKPDelSync" then
            CulteDKP:DelSyncReceived(_objReceived);
            return;
          elseif prefix == "CDKPMinBid" then
            CulteDKP:MinBidReceived(_objReceived);
            return;
          elseif prefix == "CDKPMaxBid" then
            CulteDKP:MaxbidReceived(_objReceived);
            return;
          elseif prefix == "CDKPWhitelist" then 
            CulteDKP:WhiteListReceived(_objReceived);
            return;
          elseif prefix == "CDKPStand" then
            CulteDKP:StandByReceived(_objReceived);
            return;
          elseif prefix == "CDKPSetPrice" then
            CulteDKP:SetPriceReceived(_objReceived);
            return;
          elseif prefix == "CDKPZSumBank" then
            CulteDKP:ZSumBankReceived(_objReceived);
            return;
          elseif prefix == "CDKPDKPModes" then
            CulteDKP:DKPModesReceived(_objReceived);
            return;
          elseif prefix == "CDKPBidShare" then
            CulteDKP:BidShareReceived(_objReceived);
            return;
          elseif prefix == "CDKPBossLoot" then
            CulteDKP:BossLootReceived(_objReceived);
          end 
        end
      end
    else -- success == false
      CulteDKP:Print("OnCommReceived ERROR: "..prefix)  -- error reporting if string doesn't get deserialized correctly
    end
  end
end

function CulteDKP.Sync:SendData(prefix, data, target, targetTeam, prio)

  -- 2.3.0 object being sent with almost everything?
  -- the idea is to envelope the old message into another object and then decode it on receiving end
  -- that way we won't have to do too much diging in the old code
  -- expect to send everything through SendData
  -- the only edge case is CDKPBuild which for now stays the same as it was in 2.1.2

  targetTeam = targetTeam or CulteDKP:GetCurrentTeamIndex();

  local _objToSend = {
    Teams = CulteDKP:GetTable(CulteDKP_DB, false)["teams"],
    CurrentTeam = CulteDKP:GetCurrentTeamIndex(),
    TargetTeam = targetTeam,
    Data = nil,
    Prefix = prefix
  };

  -- everything else but CDKPBuild is getting compressed
  _objToSend.Data = data; -- if we send table everytime we have to serialize / deserialize anyway
  
  local _compressedObj = CulteDKP.Sync:SerializeTableToString(_objToSend);

  if _compressedObj == nil then
    CulteDKP:Print("prefix"..prefix.." ");
    CulteDKP:Print("Compressing is fucked mate");
  end

  if data == nil or data == "" then data = " " end -- just in case, to prevent disconnects due to empty/nil string AddonMessages

  --AceComm Communication doesn't work if the prefix is longer than 15.  And if sucks if you try.
  if #prefix > 15 then
    CulteDKP:Print("CulteDKP Error: Prefix ["..prefix.."] is longer than 15. Please shorten.");
    return;
  end

  -- at this point object is ready to be sent

  if IsInGuild() then
    if prefix == "CDKPQuery" then
      CulteDKP:QuerySend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CDKPTalents" then
      CulteDKP:TalentsSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CDKPRoles" then
      CulteDKP:RolesSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CDKProfileSend" then
      CulteDKP:ProfileSend(prefix, _compressedObj, "GUILD");
      return;
    elseif prefix == "CDKPBidder" then -- bid submissions. Keep to raid.
      CulteDKP:BidderSend(prefix, _compressedObj, "RAID");
      return;
    elseif prefix == "CDKPBuild" then
      CulteDKP:BuildSend(prefix, _compressedObj, "GUILD");
      return;
    end

    if core.IsOfficer then
      if prefix == "CDKPCommand" then
        CulteDKP:CommandSend(prefix, _compressedObj, "RAID");
        return;
      end
  
      if prefix == "CDKPRaidTime" then
        CulteDKP:RaidTimeSend(prefix, _compressedObj, "RAID");
        return;
      end
  
      if prefix == "CDKPBCastMsg" then

        if target == nil then
          CulteDKP:CastMsgSend(prefix, _compressedObj, target, nil, prio);
        else
          CulteDKP:CastMsgSend(prefix, _compressedObj, "WHISPER", target, prio);
        end;
      
        return;
      end  
  
      if prefix == "CDKPZSumBank" then
        CulteDKP:ZSumBankSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CDKPBossLoot" then
        CulteDKP:BossLootSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CDKPBidShare" then
        CulteDKP:BidShareSend(prefix, _compressedObj, "RAID");
        return;
      end  
  
      if prefix == "CDKPPreBroad" then
        CulteDKP:PreBroadSend(prefix, _compressedObj, target);
        return;
      end
  
      if prefix == "CDKPAllTabs" then
        CulteDKP:AllTabsSend(prefix, _compressedObj, target);
        return;
      end
  
      if prefix == "CDKPMerge" then
        CulteDKP:MergeSend(prefix, _compressedObj, target);
        return;
      end
      
      -- what is being sent here?
      if target then
        CulteDKP.Sync:SendCommMessage(prefix, _compressedObj, "WHISPER", target)
      else
        CulteDKP.Sync:SendCommMessage(prefix, _compressedObj, "GUILD")
      end
    end

  end
end


function CulteDKP.Sync:SerializeTableToString(data) 

  local serialized = nil;
  local packet = nil;

  if data then
    serialized = LibAceSerializer:Serialize(data); -- serializes tables to a string
  end
  
  local compressed = LibDeflate:CompressDeflate(serialized, {level = 9})
    if compressed then
      packet = LibDeflate:EncodeForWoWAddonChannel(compressed)
    end
  return packet;
end


function CulteDKP.Sync:DeserializeStringToTable(_string)

  if not _string == nil then

    local decoded = LibDeflate:DecompressDeflate(LibDeflate:DecodeForWoWAddonChannel(_string))
    local success, _obj  = LibAceSerializer:Deserialize(decoded);

    CulteDKP:Print("success: "..success)  -- error reporting if string doesn't get deserialized correctly
    if not success then
      CulteDKP:Print("_string: ".._string)  -- error reporting if string doesn't get deserialized correctly
      CulteDKP:Print("decoded: "..decoded)  -- error reporting if string doesn't get deserialized correctly
    end

    return success, _obj;
  end

end


----------
-- FULL BROADCAST HANDLERS
----------

function CulteDKP:AllTabsSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPAllTabs";

  if channel then -- check if we are targeting specific player
    print("[CulteDKP] COMMS: You started Full Broadcast for team "..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).." to player "..channel);
    CulteDKP.Sync:SendCommMessage(prefix, commObject, "WHISPER", channel, "NORMAL", CulteDKP_BroadcastFull_Callback, channel);
  else
    CulteDKP.Sync:SendData("CDKPPreBroad", prefix, nil);
    CulteDKP.Sync:SendCommMessage(prefix, commObject, _channel, nil, "NORMAL", CulteDKP_BroadcastFull_Callback, _channel);
  end
end


function CulteDKP:AllTabsReceived(commObject)
  --[[ 
      commObject = {
        Teams = {},
        CurrentTeam = "0",
        Data = {
          DKPTable = {},
          DKP = {}, 
          Loot = {}, 
          Archive = {}, 
          MinBids = {},
          Teams= {} 
        }
      }
    --]]

  table.sort(commObject.Data.Loot, function(a, b)
    return a["date"] > b["date"]
  end)

  table.sort(commObject.Data.DKP, function(a, b)
    return a["date"] > b["date"]
  end)

  if commObject.Data.MinBids ~= nil then
    table.sort(commObject.Data.MinBids, function(a, b)
      --Ensure that if there is a data issue, we detect and move on during syncs.
      local aItem = a["item"] or GetNameFromLink(a["link"]);
      local bItem = b["item"] or GetNameFromLink(b["link"]);

      return aItem < bItem
    end)
  end

  if (#CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam) > 0 and #CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam) > 0) and 
    (
      commObject.Data.DKP[1].date < CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam)[1].date or 
      commObject.Data.Loot[1].date < CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam)[1].date
    ) then

    local entry1 = "Loot: "..commObject.Data.Loot[1].loot.." |cff616ccf"..L["WONBY"].." "..commObject.Data.Loot[1].player.." ("..date("%b %d @ %H:%M:%S", commObject.Data.Loot[1].date)..") by "..strsub(commObject.Data.Loot[1].index, 1, strfind(commObject.Data.Loot[1].index, "-")-1).."|r"
    local entry2 = "DKP: |cff616ccf"..commObject.Data.DKP[1].reason.." ("..date("%b %d @ %H:%M:%S", commObject.Data.DKP[1].date)..") - "..strsub(commObject.Data.DKP[1].index, 1, strfind(commObject.Data.DKP[1].index, "-")-1).."|r"

    StaticPopupDialogs["FULL_TABS_ALERT"] = {
      text = "|CFFFF0000"..L["WARNING"].."|r: "..string.format(L["NEWERTABS1"], sender).."\n\n"..entry1.."\n\n"..entry2.."\n\n"..L["NEWERTABS2"],
      button1 = L["YES"],
      button2 = L["NO"],
      OnAccept = function()
        CulteDKP:SetTable(CulteDKP_DKPTable, true, commObject.Data.DKPTable, commObject.CurrentTeam);
        CulteDKP:SetTable(CulteDKP_DKPHistory, true, commObject.Data.DKP, commObject.CurrentTeam);
        CulteDKP:SetTable(CulteDKP_Loot, true, commObject.Data.Loot, commObject.CurrentTeam);
        CulteDKP:SetTable(CulteDKP_Archive, true, commObject.Data.Archive, commObject.CurrentTeam);
        
        local minBidTable = CulteDKP:FormatPriceTable(commObject.Data.MinBids, true);
        local newMinBidTable = {}
        for i=1, #minBidTable do
          local id = minBidTable[i].itemID;
          if id == nil and minBidTable[i].link ~= nil then
            id = minBidTable[i].link:match("|Hitem:(%d+):")
          end
          if id ~= nil then
            newMinBidTable[id] = minBidTable[i];
          end
        end

        CulteDKP:SetTable(CulteDKP_MinBids, true, newMinBidTable, commObject.CurrentTeam);
        core.DB["teams"] = commObject.Teams;

        CulteDKP:SetCurrentTeam(commObject.CurrentTeam)
        
        CulteDKP:FilterDKPTable(core.currentSort, "reset")
        CulteDKP:StatusVerify_Update()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
      preferredIndex = 3,
    }
    StaticPopup_Show ("FULL_TABS_ALERT")
  else
    CulteDKP:SetTable(CulteDKP_DKPTable, true, commObject.Data.DKPTable, commObject.CurrentTeam);
    CulteDKP:SetTable(CulteDKP_DKPHistory, true, commObject.Data.DKP, commObject.CurrentTeam);
    CulteDKP:SetTable(CulteDKP_Loot, true, commObject.Data.Loot, commObject.CurrentTeam);
    CulteDKP:SetTable(CulteDKP_Archive, true, commObject.Data.Archive, commObject.CurrentTeam);

    local minBidTable = CulteDKP:FormatPriceTable(commObject.Data.MinBids, true);
    local newMinBidTable = {}
    for i=1, #minBidTable do
      local id = minBidTable[i].itemID;
      if id == nil and minBidTable[i].link ~= nil then
        id = minBidTable[i].link:match("|Hitem:(%d+):")
      end
      if id ~= nil then
        newMinBidTable[id] = minBidTable[i];
      end
    end

    CulteDKP:SetTable(CulteDKP_MinBids, true, newMinBidTable, commObject.CurrentTeam);

    core.DB["teams"] = commObject.Teams;
    CulteDKP:SetCurrentTeam(commObject.CurrentTeam)
    -- reset seeds since this is a fullbroadcast   
    CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam).seed = 0 
    CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam).seed = 0
    CulteDKP:FilterDKPTable(core.currentSort, "reset");
    CulteDKP:StatusVerify_Update();
  end
  
  print("[CulteDKP] COMMS: Full broadcast receive finished for team "..CulteDKP:GetTeamName(commObject.CurrentTeam));
end


----------
-- 2-WEEK MERGE HANDLERS
----------

function CulteDKP:MergeSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPMerge";

  if channel then -- check if we are targeting specific player
    print("[CulteDKP] COMMS: You started 2-week broadcast for team "..CulteDKP:GetTeamName(CulteDKP:GetCurrentTeamIndex()).." to player "..channel);
    CulteDKP.Sync:SendCommMessage(prefix, commObject, "WHISPER", channel, "NORMAL", CulteDKP_BroadcastFull_Callback, channel);
  else
    CulteDKP.Sync:SendData("CDKPPreBroad", prefix, nil);
    CulteDKP.Sync:SendCommMessage(prefix, commObject, _channel, nil, "NORMAL", CulteDKP_BroadcastFull_Callback, _channel);
  end
end


function CulteDKP:MergeReceived(commObject, channel, sender)
  for i=1, #commObject.Data.DKP do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].index, "index")

    if not search and ((CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).DKPMeta and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).DKPMeta < commObject.Data.DKP[i].date) or (not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).DKPMeta)) then   -- prevents adding entry if this entry has already been archived
      local players = {strsplit(",", strsub(commObject.Data.DKP[i].players, 1, -2))}
      local dkp

      if strfind(commObject.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then
        dkp = {strsplit(",", commObject.Data.DKP[i].dkp)}
      end

      if commObject.Data.DKP[i].deletes then      -- adds deletedby field to entry if the received table is a delete entry
        local search_del = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].deletes, "index")

        if search_del then
          CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam)[search_del[1][1]].deletedby = commObject.Data.DKP[i].index
        end
      end
      
      if not commObject.Data.DKP[i].deletedby then
        local search_del = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i].index, "deletes")

        if search_del then
          commObject.Data.DKP[i].deletedby = CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam)[search_del[1][1]].index
        end
      end

      table.insert(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.DKP[i])

      for j=1, #players do
        if players[j] then
          local findEntry = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), players[j], "player")

          if strfind(commObject.Data.DKP[i].dkp, "%-%d*%.?%d+%%") then     -- handles decay entries
            if findEntry then
              CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + tonumber(dkp[j])
            else
              if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]].deleted ~= true) then
                CulteDKP_Profile_Create(players[j], tonumber(dkp[j]), nil, nil, commObject.CurrentTeam)
              end
            end
          else
            if findEntry then
              CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + tonumber(commObject.Data.DKP[i].dkp)
              if (tonumber(commObject.Data.DKP[i].dkp) > 0 and not commObject.Data.DKP[i].deletes) or (tonumber(commObject.Data.DKP[i].dkp) < 0 and commObject.Data.DKP[i].deletes) then -- adjust lifetime if it's a DKP gain or deleting a DKP gain 
                CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_gained = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_gained + commObject.Data.DKP[i].dkp   -- NOT if it's a DKP penalty or deleteing a DKP penalty
              end
            else
              if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[j]].deleted ~= true) then
                local class

                if (tonumber(commObject.Data.DKP[i].dkp) > 0 and not commObject.Data.DKP[i].deletes) or (tonumber(commObject.Data.DKP[i].dkp) < 0 and commObject.Data.DKP[i].deletes) then
                  CulteDKP_Profile_Create(players[j], tonumber(commObject.Data.DKP[i].dkp), tonumber(commObject.Data.DKP[i].dkp), nil, commObject.CurrentTeam)
                else
                  CulteDKP_Profile_Create(players[j], tonumber(commObject.Data.DKP[i].dkp), nil, nil, commObject.CurrentTeam)
                end
              end
            end
          end
        end
      end
    end
  end

  if CulteDKP.ConfigTab6 and CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
    CulteDKP:DKPHistory_Update(true)
  end

  for i=1, #commObject.Data.Loot do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].index, "index")

    if not search and ((CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).LootMeta and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).LootMeta < commObject.Data.Loot[i].date) or (not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam).LootMeta)) then -- prevents adding entry if this entry has already been archived
      if commObject.Data.Loot[i].deletes then
        local search_del = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].deletes, "index")

        if search_del and not CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].deletedby then
          CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].deletedby = commObject.Data.Loot[i].index
        end
      end

      if not commObject.Data.Loot[i].deletedby then
        local search_del = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i].index, "deletes")

        if search_del then
          commObject.Data.Loot[i].deletedby = CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam)[search_del[1][1]].index
        end
      end

      table.insert(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), commObject.Data.Loot[i])

      local findEntry = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.Loot[i].player, "player")

      if findEntry then
        CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].dkp + commObject.Data.Loot[i].cost
        CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_spent = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[findEntry[1][1]].lifetime_spent + commObject.Data.Loot[i].cost
      else
        if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.Loot[i].player].deleted ~= true) then
          CulteDKP_Profile_Create(commObject.Data.Loot[i].player, commObject.Data.Loot[i].cost, 0, commObject.Data.Loot[i].cost, commObject.CurrentTeam)
        end
      end
    end
  end

  for i=1, #commObject.Data.Profiles do

    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.Profiles[i].player, "player")

    if search then
      if CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class == "NONE" then
        CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class = commObject.Data.Profiles[i].class
      end
    else
      tinsert(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam),commObject.Data.Profiles[i])
    end
  end

  CulteDKP:LootHistory_Reset()
  CulteDKP:LootHistory_Update(L["NOFILTER"])
  CulteDKP:FilterDKPTable(core.currentSort, "reset")
  CulteDKP:StatusVerify_Update()
  return
end


----------
-- CDKPQuery message HANDLERS
----------

function CulteDKP:QuerySend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPQuery";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end

----------
-- CDKPBuild message HANDLERS
----------

function CulteDKP:BuildSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPQuery";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
  return;
end

function CulteDKP:BuildReceived(commObject, sender)
  if sender ~= UnitName("player") then
    local LastVerCheck = time() - core.LastVerCheck;

        if LastVerCheck > 900 then             -- limits the Out of Date message from firing more than every 15 minutes 
          if tonumber(_objReceived.Data) > core.BuildNumber then
            core.LastVerCheck = time();
            CulteDKP:Print(L["OUTOFDATEANNOUNCE"])
          end
        end

        if tonumber(_objReceived.Data) < core.BuildNumber then   -- returns build number if receiving party has a newer version
          CulteDKP.Sync:SendData("CDKPBuild", tostring(core.BuildNumber))
        end
        return;
  end
end

----------
-- CDKPTalents message HANDLERS
----------

function CulteDKP:TalentsSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPTalents";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:TalentsReceived(commObject, sender)
  for teamIndex,team in pairs(commObject.Teams) do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex), sender, "player")

    if search then
      local curSelection = CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex)[search[1][1]]
      curSelection.spec = commObject.Data;
      
      if CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender] == nil then
        CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender] = CulteDKP:GetDefaultEntity();
      end

      CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender].spec = commObject.Data;
    end
    
  end

  return
end

----------
-- CDKPRoles message HANDLERS
----------

function CulteDKP:RolesSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPRoles";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:RolesReceived(commObject, sender)
  for teamIndex,team in pairs(commObject.Teams) do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex), sender, "player")
    local curClass = "None";

    if search then
      local curSelection = CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex)[search[1][1]]
      curClass = CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex)[search[1][1]].class
    
      if curClass == "WARRIOR" then
        local a,b,c = strsplit("/", commObject.Data)
        if strfind(commObject.Data, "Protection") or (tonumber(c) and tonumber(strsub(c, 1, -2)) > 15) then
          curSelection.role = L["TANK"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "PALADIN" then
        if strfind(commObject.Data, "Protection") then
          curSelection.role = L["TANK"]
        elseif strfind(commObject.Data, "Holy") then
          curSelection.role = L["HEALER"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "HUNTER" then
        curSelection.role = L["RANGEDPS"]
      elseif curClass == "ROGUE" then
        curSelection.role = L["MELEEDPS"]
      elseif curClass == "PRIEST" then
        if strfind(commObject.Data, "Shadow") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["HEALER"]
        end
      elseif curClass == "SHAMAN" then
        if strfind(commObject.Data, "Restoration") then
          curSelection.role = L["HEALER"]
        elseif strfind(commObject.Data, "Elemental") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["MELEEDPS"]
        end
      elseif curClass == "MAGE" then
        curSelection.role = L["CASTERDPS"]
      elseif curClass == "WARLOCK" then
        curSelection.role = L["CASTERDPS"]
      elseif curClass == "DRUID" then
        if strfind(commObject.Data, "Feral") then
          curSelection.role = L["TANK"]
        elseif strfind(commObject.Data, "Balance") then
          curSelection.role = L["CASTERDPS"]
        else
          curSelection.role = L["HEALER"]
        end
      else
        curSelection.role = L["NOROLEDETECTED"]
      end

      if CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender] == nil then
        CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender] = CulteDKP:GetDefaultEntity();
      end

      CulteDKP:GetTable(CulteDKP_Profiles, true, teamIndex)[sender].role = curSelection.role;
      CulteDKP:GetTable(CulteDKP_DKPTable, true, teamIndex)[search[1][1]].role = curSelection.role;
    end
  end
  return;
end

----------
-- CDKProfileSend message HANDLERS
----------

function CulteDKP:ProfileSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKProfileSend";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:ProfileReceived(commObject, sender)
  local profile = commObject.Data;
  CulteDKP:GetTable(CulteDKP_Profiles, true, commObject.CurrentTeam)[profile.player] = profile;
  
  --Legacy Version Tracking
  local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true), profile.player, "player")
  if search then
    CulteDKP:GetTable(CulteDKP_DKPTable, true)[search[1][1]].version = profile.version;
  end
end

----------
-- CDKPBidder message HANDLERS
----------

function CulteDKP:BidderSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPBidder";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:BidderReceived(commObject, sender)
  if core.BidInProgress and core.IsOfficer then
    if commObject.Data == "pass" then
        -- CulteDKP:Print(sender.." has passed.")  --TODO: Let's do something different here at some point.
      return;
    else
      CulteDKP_CHAT_MSG_WHISPER(commObject.Data, sender);
      return;
    end
  else
    return;
  end
end

----------
-- CDKPCommand message HANDLERS
----------

function CulteDKP:CommandSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPCommand";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:CommandReceived(commObject, sender)
  local command, arg1, arg2, arg3, arg4 = strsplit("#", commObject.Data);
  if sender ~= UnitName("player") then
    if command == "StartTimer" then
      CulteDKP:StartTimer(arg1, arg2)
    elseif command == "StartBidTimer" then
      CulteDKP:StartBidTimer(arg1, arg2, arg3)
      core.BiddingInProgress = true;
      if strfind(arg1, "{") then
        CulteDKP:Print("Bid timer extended by "..tonumber(strsub(arg1, strfind(arg1, "{")+1)).." seconds.")
      end
    elseif command == "StopBidTimer" then
      if CulteDKP.BidTimer then
        CulteDKP.BidTimer:SetScript("OnUpdate", nil)
        CulteDKP.BidTimer:Hide()
        core.BiddingInProgress = false;
      end
      if core.BidInterface and #core.BidInterface.LootTableButtons > 0 then
        for i=1, #core.BidInterface.LootTableButtons do
          ActionButton_HideOverlayGlow(core.BidInterface.LootTableButtons[i])
        end
      end
      C_Timer.After(2, function()
        if core.BidInterface and core.BidInterface:IsShown() and not core.BiddingInProgress then
          core.BidInterface:Hide()
        end
      end)
    elseif command == "BidInfo" then
      if not core.BidInterface then
        core.BidInterface = core.BidInterface or CulteDKP:BidInterface_Create()  -- initiates bid window if it hasn't been created
      end
      if core.DB.defaults.AutoOpenBid and not core.BidInterface:IsShown() then  -- toggles bid window if option is set to
        CulteDKP:BidInterface_Toggle()
      end

      CulteDKP:CurrItem_Set(arg1, arg2, arg3, arg4)  -- populates bid window
    end
  end
end


----------
-- CDKPRaidTime message HANDLERS
----------

function CulteDKP:RaidTimeSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPRaidTime";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:RaidTimeReceived(commObject, sender)
  local command, args = strsplit(",", commObject.Data);

  if sender ~= UnitName("player") and core.IsOfficer and CulteDKP.ConfigTab2 then
    if command == "start" then
      CulteDKP:SetCurrentTeam(commObject.CurrentTeam); -- on start change the currentTeam
      local arg1, arg2, arg3, arg4, arg5, arg6 = strsplit(" ", args, 6)

      if arg1 == "true" then arg1 = true else arg1 = false end
      if arg4 == "true" then arg4 = true else arg4 = false end
      if arg5 == "true" then arg5 = true else arg5 = false end
      if arg6 == "true" then arg6 = true else arg6 = false end

      if arg2 ~= nil then
        CulteDKP.ConfigTab2.RaidTimerContainer.interval:SetNumber(tonumber(arg2));
        core.DB.modes.increment = tonumber(arg2);
      end
      if arg3 ~= nil then
        CulteDKP.ConfigTab2.RaidTimerContainer.bonusvalue:SetNumber(tonumber(arg3));
        core.DB.DKPBonus.IntervalBonus = tonumber(arg3);
      end
      if arg4 ~= nil then
        CulteDKP.ConfigTab2.RaidTimerContainer.StartBonus:SetChecked(arg4);
        core.DB.DKPBonus.GiveRaidStart = arg4;
      end
      if arg5 ~= nil then
        CulteDKP.ConfigTab2.RaidTimerContainer.EndRaidBonus:SetChecked(arg5);
        core.DB.DKPBonus.GiveRaidEnd = arg5;
      end
      if arg6 ~= nil then
        CulteDKP.ConfigTab2.RaidTimerContainer.StandbyInclude:SetChecked(arg6);
        core.DB.DKPBonus.IncStandby = arg6;
      end

      CulteDKP:StartRaidTimer(arg1)
    elseif command == "stop" then
      CulteDKP:StopRaidTimer()
    elseif strfind(command, "sync", 1) then
      local _, syncTimer, syncSecondCount, syncMinuteCount, syncAward = strsplit(" ", command, 5)
      CulteDKP:StartRaidTimer(nil, syncTimer, syncSecondCount, syncMinuteCount, syncAward)
      CulteDKP:SetCurrentTeam(_objReceived.CurrentTeam);
      core.RaidInProgress = true
    end
  elseif sender ~= UnitName("player") and not core.IsOfficer and not CulteDKP.ConfigTab2 then
    CulteDKP:SetCurrentTeam(_objReceived.CurrentTeam);
  end

end

----------
-- CDKPBCastMsg message HANDLERS
----------

function CulteDKP:CastMsgSend(prefix, commObject, channel, player, prio)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPBCastMsg";
  local _prio = prio or "NORMAL";

  if player == nil then
    CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel, nil, _prio, nil, nil);
  else
    CulteDKP.Sync:SendCommMessage(_prefix, commObject, "WHISPER", player, _prio, nil, nil);
  end;
end


----------
-- CDKPZSumBank message HANDLERS
----------

function CulteDKP:ZSumBankSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPZSumBank";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:ZSumBankReceived(commObject)
  if core.IsOfficer then
    core.DB.modes.ZeroSumBank = commObject.Data;
    if core.ZeroSumBank then
      if commObject.Data.balance == 0 then
        core.ZeroSumBank.LootFrame.LootList:SetText("")
      end
      CulteDKP:ZeroSumBank_Update()
    end
  end
end

----------
-- CDKPBossLoot message HANDLERS
----------

function CulteDKP:BossLootSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPBossLoot";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:BossLootReceived(commObject)

  local lootList = {};
  core.DB.bossargs.LastKilledBoss = commObject.Data.boss;

  for i=1, #commObject.Data do
    local item = Item:CreateFromItemLink(commObject.Data[i]);
    item:ContinueOnItemLoad(function()
      local icon = item:GetItemIcon()
      table.insert(lootList, {icon=icon, link=item:GetItemLink()})
    end);
  end
  CulteDKP:LootTable_Set(lootList)
end

----------
-- CDKPBidShare message HANDLERS
----------

function CulteDKP:BidShareSend(prefix, commObject, channel)
  local _channel = channel or "RAID";
  local _prefix = prefix or "CDKPBidShare";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end

function CulteDKP:BidShareReceived(commObject)
  if core.BidInterface then
    CulteDKP:Bids_Set(commObject.Data)
  end
  return
end

----------
-- CDKPPreBroad message HANDLERS
----------

function CulteDKP:PreBroadSend(prefix, commObject, channel)
  local _channel = channel or "GUILD";
  local _prefix = prefix or "CDKPPreBroad";
  CulteDKP.Sync:SendCommMessage(_prefix, commObject, _channel);
end


function CulteDKP:PreBroadReceived(commObject, sender)
  
  if sender ~= UnitName("player") then
    if commObject.Data == "CDKPAllTabs" then
      print("[CulteDKP] COMMS: You started Full Broadcast for team "..CulteDKP:GetTeamName(commObject.CurrentTeam));
    elseif commObject.Data == "CDKPMerge" then
      print("[CulteDKP] COMMS: You started 2-week broadcast for team "..CulteDKP:GetTeamName(commObject.CurrentTeam));
    end
  else
    if commObject.Data == "CDKPAllTabs" then
      print("[CulteDKP] COMMS: Full broadcast started by "..sender.." for team "..CulteDKP:GetTeamName(commObject.CurrentTeam));
    elseif commObject.Data == "CDKPMerge" then
      print("[CulteDKP] COMMS: 2-week merge broadcast started by "..sender.." for team "..CulteDKP:GetTeamName(commObject.CurrentTeam));
    end
  end
end

----------
-- CDKPLootDist message HANDLERS
----------

function CulteDKP:LootDistReceived(commObject)

  local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.player, "player")
  if search then
    local DKPTable = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]]
    DKPTable.dkp = DKPTable.dkp + commObject.Data.cost
    DKPTable.lifetime_spent = DKPTable.lifetime_spent + commObject.Data.cost
  else
    if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] or 
    (
      CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] and 
      CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player].deleted ~= true
    ) then
      CulteDKP_Profile_Create(commObject.Data.player, commObject.Data.cost, 0, commObject.Data.cost, commObject.CurrentTeam);
    end
  end
  tinsert(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), 1, commObject.Data)

  CulteDKP:LootHistory_Reset()
  CulteDKP:LootHistory_Update(L["NOFILTER"])
  CulteDKP:FilterDKPTable(core.currentSort, "reset")
  
end


----------
-- CDKPDKPDist message HANDLERS
----------

function CulteDKP:DKPDistReceived(commObject)

  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}
  local dkp = commObject.Data.dkp

  tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)

  for i=1, #players do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

    if search then
      CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp + tonumber(dkp)
      if tonumber(dkp) > 0 then
        CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].lifetime_gained = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].lifetime_gained + tonumber(dkp)
      end
    else
      if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] or
       (
         CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] and 
         CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true
      ) then
        CulteDKP_Profile_Create(players[i], tonumber(dkp), tonumber(dkp), nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
      end
    end
  end

  if CulteDKP.ConfigTab6 and CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
    CulteDKP:DKPHistory_Update(true)
  end
  CulteDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CDKPDecay message HANDLERS
----------

function CulteDKP:DKPDecayReceived(commObject)

  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}
  local dkp = {strsplit(",", commObject.Data.dkp)}

  tinsert(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)
  
  for i=1, #players do
    local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

    if search then
      CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].dkp + tonumber(dkp[i])
    else
      if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
        CulteDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
      end
    end
  end

  if CulteDKP.ConfigTab6 and CulteDKP.ConfigTab6.history and CulteDKP.ConfigTab6:IsShown() then
    CulteDKP:DKPHistory_Update(true)
  end
  CulteDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CDKPAddUsers message HANDLERS
----------

function CulteDKP:AddUsersReceived(commObject)
  if UnitName("player") ~= sender then
    CulteDKP:AddEntitiesToDKPTable(commObject.Data, commObject.TargetTeam);
  end
  return;
end

----------
-- CDKPDelUsers message HANDLERS
----------

function CulteDKP:DelUsersReceived(commObject)
  local numPlayers = 0
  local removedUsers = ""

  if UnitName("player") ~= sender then
    for i=1, #commObject.Data do
      local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data[i].player, "player")

      if search and commObject.Data[i].deleted and commObject.Data[i].deleted ~= "Recovered" then
        if commObject.Data[i].edited == nil then
          commObject.Data[i].edited = time();
        end

        if (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and commObject.Data[i].deleted) or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited < commObject.Data[i].edited) or (not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player]) then
          --delete user, archive data
          if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] then    -- creates/adds to archive entry for user
            CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] = { dkp=0, lifetime_spent=0, lifetime_gained=0, deleted=commObject.Data[i].deleted, edited=commObject.Data[i].edited }
          else
            CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].deleted = commObject.Data[i].deleted
            CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited = commObject.Data[i].edited
          end
          
          c = CulteDKP:GetCColors(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].class)
          if i==1 then
            removedUsers = "|c"..c.hex..CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].player.."|r"
          else
            removedUsers = removedUsers..", |c"..c.hex..CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search[1][1]].player.."|r"
          end
          numPlayers = numPlayers + 1

          tremove(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), search[1][1])
          CulteDKP:GetTable(CulteDKP_Profiles, true, commObject.CurrentTeam)[commObject.Data[i].player] = nil;

          local search2 = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Standby, true, commObject.CurrentTeam), commObject.Data[i].player, "player");

          if search2 then
            table.remove(CulteDKP:GetTable(CulteDKP_Standby,true, commObject.CurrentTeam), search2[1][1])
          end
        end
      elseif not search and commObject.Data[i].deleted == "Recovered" then
        if CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player] and (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited == nil or CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited < commObject.Data[i].edited) then
          CulteDKP_Profile_Create(commObject.Data[i].player, nil, nil, nil, commObject.CurrentTeam);  -- User was recovered, create/request profile as needed
          CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].deleted = "Recovered"
          CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data[i].player].edited = commObject.Data[i].edited
        end
      end
    end
    if numPlayers > 0 then
      CulteDKP:FilterDKPTable(core.currentSort, "reset")
      CulteDKP:Print("["..CulteDKP:GetTeamName(commObject.CurrentTeam).."] ".."Removed "..numPlayers.." player(s): "..removedUsers)
    end
  end
  return
end

----------
-- CDKPDelLoot message HANDLERS
----------

function CulteDKP:DelLootReceived(commObject)
  local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), commObject.Data.deletes, "index")

  if search then
    CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam)[search[1][1]].deletedby = commObject.Data.index
  end

  local search_player = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), commObject.Data.player, "player")

  if search_player then
    CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].dkp + commObject.Data.cost                  -- refund previous looter
    CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].lifetime_spent = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search_player[1][1]].lifetime_spent + commObject.Data.cost       -- remove from lifetime_spent
  else
    if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[commObject.Data.player].deleted ~= true) then
      CulteDKP_Profile_Create(commObject.Data.player, commObject.Data.cost, 0, commObject.Data.cost, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
    end
  end

  table.insert(CulteDKP:GetTable(CulteDKP_Loot, true, commObject.CurrentTeam), 1, commObject.Data)
  CulteDKP:SortLootTable()
  CulteDKP:LootHistory_Reset()
  CulteDKP:LootHistory_Update(L["NOFILTER"]);
  CulteDKP:FilterDKPTable(core.currentSort, "reset")
end

----------
-- CDKPDelSync message HANDLERS
----------

function CulteDKP:DelSyncReceived(commObject)
  local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), commObject.Data.deletes, "index")
  local players = {strsplit(",", strsub(commObject.Data.players, 1, -2))}   -- cuts off last "," from string to avoid creating an empty value
  local dkp, mod;

  if strfind(commObject.Data.dkp, "%-%d*%.?%d+%%") then     -- determines if it's a mass decay
    dkp = {strsplit(",", commObject.Data.dkp)}
    mod = "perc";
  else
    dkp = commObject.Data.dkp
    mod = "whole"
  end

  for i=1, #players do
    if mod == "perc" then
      local search2 = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

      if search2 then
        CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp[i])
      else
        if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
          CulteDKP_Profile_Create(players[i], tonumber(dkp[i]), nil, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
        end
      end
    else
      local search2 = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam), players[i], "player")

      if search2 then
        CulteDKP:GetTable(CulteDKP_DKPTable, true)[search2[1][1]].dkp = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].dkp + tonumber(dkp)

        if tonumber(dkp) < 0 then
          CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].lifetime_gained = CulteDKP:GetTable(CulteDKP_DKPTable, true, commObject.CurrentTeam)[search2[1][1]].lifetime_gained + tonumber(dkp)
        end
      else
        if not CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] or (CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]] and CulteDKP:GetTable(CulteDKP_Archive, true, commObject.CurrentTeam)[players[i]].deleted ~= true) then
          local gained;
          if tonumber(dkp) < 0 then gained = tonumber(dkp) else gained = 0 end

          CulteDKP_Profile_Create(players[i], tonumber(dkp), gained, nil, commObject.CurrentTeam);  -- creates temp profile for data and requests additional data from online officers (hidden until data received)
        end
      end
    end
  end

  if search then
    CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam)[search[1][1]].deletedby = commObject.Data.index;    -- adds deletedby field if the entry exists
  end

  table.insert(CulteDKP:GetTable(CulteDKP_DKPHistory, true, commObject.CurrentTeam), 1, commObject.Data)

  if CulteDKP.ConfigTab6 and CulteDKP.ConfigTab6.history then
    CulteDKP:DKPHistory_Update(true)
  end
  CulteDKP:DKPTable_Update()
end

----------
-- CDKPMinBid message HANDLERS
----------

function CulteDKP:MinBidReceived(commObject)
  if core.IsOfficer then
    core.DB.MinBidBySlot = commObject.Data[1]

    for i=1, #commObject.Data[2] do
      local bidInfo = commObject.Data[2][i]
      local bidTeam = bidInfo[1]
      local bidItems = bidInfo[2]
      if bidItems ~= nil then
        for j=1, #bidItems do
          local search = CulteDKP:GetTable(CulteDKP_MinBids, true, bidTeam)[bidItems[j].itemID];
          if search then
            CulteDKP:GetTable(CulteDKP_MinBids, true, bidTeam)[bidItems[j].itemID].minbid = bidItems[j].minbid
            if bidItems[j]["link"] ~= nil then
              CulteDKP:GetTable(CulteDKP_MinBids, true, bidTeam)[bidItems[j].itemID].link = bidItems[j].link
            end
            if bidItems[j]["icon"] ~= nil then
              CulteDKP:GetTable(CulteDKP_MinBids, true, bidTeam)[bidItems[j].itemID].icon = bidItems[j].icon
            end
          else
            CulteDKP:GetTable(CulteDKP_MinBids, true, bidTeam)[bidItems[j].itemID] = bidItems[j];
          end
        end 
      end
    end
  end
end

----------
-- CDKPMaxBid message HANDLERS
----------

function CulteDKP:MaxbidReceived(commObject)
  if core.IsOfficer then

    core.DB.MaxBidBySlot = commObject.Data[1];
    _objMaxBidValues = commObject.Data[1];

    for i=1, #commObject.Data[2] do
      local bidInfo = commObject.Data[2][i]
      local bidTeam = bidInfo[1]
      local bidItems = bidInfo[2] or {}

      for j=1, #bidItems do
        local search = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_MaxBids, true, bidTeam), bidItems[j].item)
        if search then
          CulteDKP:GetTable(CulteDKP_MaxBids, true, bidTeam)[search[1][1]].maxbid = bidItems[j].maxbid
        else
          table.insert(CulteDKP:GetTable(CulteDKP_MaxBids, true, bidTeam), bidItems[j])
        end
      end 
    end
  end
end

----------
-- CDKPWhitelist message HANDLERS
----------

function CulteDKP:WhiteListReceived(commObject)
  if CulteDKP:GetGuildRankIndex(UnitName("player")) > 1 then -- only applies if not GM
    CulteDKP:SetTable(CulteDKP_Whitelist, false, commObject.Data, commObject.CurrentTeam);
  end
end

----------
-- CDKPStand message HANDLERS
----------

function CulteDKP:StandByReceived(commObject)
  CulteDKP:SetTable(CulteDKP_Standby, true, commObject.Data, commObject.CurrentTeam); -- issues/153
end

----------
-- CDKPSetPrice message HANDLERS
----------

function CulteDKP:SetPriceReceived(commObject)

  local _objSetPrice = _objReceived.Data;
  local _, _, Color, Ltype, itemID, Enchant, Gem1, Gem2, Gem3, Gem4, Suffix, Unique, LinkLvl, Name = string.find(_objSetPrice.link,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*):?(%-?%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")

  local search = CulteDKP:GetTable(CulteDKP_MinBids, true, _objReceived.CurrentTeam)[itemID];

  if not search then
    CulteDKP:GetTable(CulteDKP_MinBids, true, _objReceived.CurrentTeam)[itemID] = _objSetPrice;
  elseif search then
    CulteDKP:GetTable(CulteDKP_MinBids, true, _objReceived.CurrentTeam)[itemID] = _objSetPrice;
  end
  
  core.PriceTable = CulteDKP:FormatPriceTable();
  CulteDKP:PriceTable_Update(0);

end

----------
-- CDKPDKPModes message HANDLERS
----------

function CulteDKP:DKPModesReceived(commObject)
  if (core.DB.modes.mode ~= commObject.Data[1].mode) or (core.DB.modes.MaxBehavior ~= commObject.Data[1].MaxBehavior) then
    CulteDKP:Print(L["RECOMMENDRELOAD"])
  end
  core.DB.modes = commObject.Data[1]
  core.DB.DKPBonus = commObject.Data[2]
  core.DB.raiders = commObject.Data[3]
end

----------
-- CDKPSeed message HANDLERS
----------

function CulteDKP:SeedReceived(commObject, sender)

  --[[ 
      Data = {
        ["0"] = {
          ["Loot"] = "name-date",
          ["DKPHistory"] = "name-date"
        },
        ["1"] = {
          ["Loot"] = "start",
          ["DKPHistory"] = "start"
        }
      }
    --]]

  if sender ~= UnitName("player") then
    for tableIndex,v in pairs(commObject.Data) do
      if(type(v) == "table") then
        for property,value in pairs(v) do
          if value ~= "start" then

            local off1,date1 = strsplit("-", value);

            if CulteDKP:ValidateSender(off1) then
              if property == "Loot" then

                local searchLoot = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_Loot, true, tostring(tableIndex)), value, "index")

                if not searchLoot then
                  CulteDKP:GetTable(CulteDKP_Loot, true, tostring(tableIndex)).seed = value
                end

              elseif property == "DKPHistory" then
                local searchDKPHistory = CulteDKP:Table_Search(CulteDKP:GetTable(CulteDKP_DKPHistory, true, tostring(tableIndex)), value, "index")
                
                if not searchDKPHistory then
                  CulteDKP:GetTable(CulteDKP_DKPHistory, true, tostring(tableIndex)).seed = value
                end
              end
            end
          end
        end
      end
    end
  end
end

----------
-- CDKPTeams message HANDLERS
----------

function CulteDKP:TeamsReceived(commObject, sender)
  CulteDKP:GetTable(CulteDKP_DB, false)["teams"] = commObject.Teams
end

----------
-- CDKPCurTeam message HANDLERS
----------

function CulteDKP:CurTeamReceived(commObject, sender)
  CulteDKP:SetCurrentTeam(commObject.CurrentTeam) -- this also refreshes all the tables/views/graphs
end

----------
-- TODO message HANDLERS
----------