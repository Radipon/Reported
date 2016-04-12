-- Saved variables table
Reported_Global_Vars = {}; -- It will generate from the default table below
local Reported_Global_Vars_Default = { -- Global Var Default table which is compared to the saved variable global table, and removes/adds values if needed
	["namefilter"] = 'On',
	["Counter"] = 0,
	["maxRecent"] = 10,
	["Toggle"] = 'On',
	["rRespond"] = 'On',
	["AFKCancel"] = 'Off',
	["Range"] = {
		["Lower"] = 0,
		["Upper"] = 0,
	},
	["Channels"] = {
	 	["rSay"] = 'On',
	 	["rYell"] = 'On',
	 	["rInstance_CHAT"] = 'On',
	 	["rNumbered"] = 'On',
	 	["rRaid"] = 'Off',
	 	["rParty"] = 'Off',
	 	["rBattleground"] = 'On',
	 	["rGuild"] = 'Off',
	 	["rOfficer"] = 'Off',
 	},
 	["Numbered"] = {
 		[1] = 'On',
 		[2] = 'On',
 		[3] = 'Off',
 		[4] = 'Off',
 		[5] = 'Off',
 		[6] = 'Off',
 		[7] = 'Off',
 		[8] = 'Off',
 		[9] = 'Off',
 		[10] = 'Off',
 	}
};

-- Some global tables
Reported_Recent = {}; -- Holds recent reports
Module_Table = {}; -- Holds module index names that are enabled

tempLineTable, enabledModules, getModuleName, getLine = nil;
 
-- Local variables are cool
local ReportedLineSuffix = ''; -- Appends a static message to the end of any Reported line generated
local timer, lastReported, rangeRand, printModuleName, ReportedLine; -- This simply just declares all the variables that will be used throughout the code; they currently have no value set
local Version = GetAddOnMetadata("Reported", "Version"); -- This is printed in a few messages
local addonLoaded, elapsedUpdate, overDelay, swearFound, afk = 0, 0, 0, 0, 0; -- These are set to 0 instead of nil because I do arithmetic with them
local holdReportedInfo = {}; -- Holds Reported info for the ReportedOnUpdate function

function Msg(msg) -- Now I don't have to type DEFAULT_CHAT_FRAME:AddMessage() everytime I want to print something
    if (DEFAULT_CHAT_FRAME) then
        DEFAULT_CHAT_FRAME:AddMessage(msg); -- Instead of typing 'DEFAULT_CHAT_FRAME:AddMessage();' everytime I want to print something I just have to type Msg(msg);
    end
end

function Reported_FlipState(table, msg)
	if (table == 'On') then
		table = 'Off';
		Msg("|cFFFFFF7F" .. msg .. "|r is now |cFFFFFF7F[|r|cFFFF0000Off|r|cFFFFFF7F]|r");
	else
		table = 'On';
		Msg("|cFFFFFF7F" .. msg .. "|r is now |cFFFFFF7F[|r|cFFFFFF00On|r|cFFFFFF7F]|r");
	end
	return table;
end

-- Slash commands table
local Reported_Commands = {
	["a"] = function() -- The same as toggle
		Reported_Global_Vars.Toggle = Reported_FlipState(Reported_Global_Vars.Toggle, "Reported");
	end,
	["toggle"] = function() -- This creates a mini function within the table its self. You can even give it args as seen below.  To refer to this particular one you would type Reported_Commands.toggle(); or Reported_Commands[toggle](); or Reported_Commands["toggle"]();
  		Reported_Global_Vars.Toggle = Reported_FlipState(Reported_Global_Vars.Toggle, "Reported");
	end,
	["counter"] = function()
  		Msg("|cFFFFFF7FReported|r has been triggered |cFFFFFF7F[|r" .. Reported_Global_Vars.Counter .. "|cFFFFFF7F]|r times.");
	end,
	["channels"] = function()
		local Reported_Channels_Temp = {}; -- Creates an empty table
		for i in pairs(Reported_Global_Vars.Channels) do -- Gets the name of the channel
			tinsert(Reported_Channels_Temp, i); -- Inserts it into the table we just made
		end
		sort(Reported_Channels_Temp, function(a,b) return a<b end); -- Sorts the table we just made with all the channel names alphabetically
		for _,v in pairs(Reported_Channels_Temp) do -- For every variable in the channel global var table it makes a message
			if (gsub(strlower(v), "r", "", 1) == "numbered") then -- Turns rNumbered to rnumbered, then removes the first r 
				local channels = ""; -- Creates a string so it can be added to later on
				for i,v in ipairs(Reported_Global_Vars.Numbered) do
					if (v == 'On') then
						channels = channels .. "," .. i; -- Adds channel number to channels string if it's enabled
					end
				end
				channels = gsub(channels, ",", "", 1); -- Remove the leading comma
				if (Reported_Global_Vars.Channels[v] == 'On') then
					Msg(" - |cFFFFFF7F" .. gsub(strlower(v), "r", "", 1) .. " [|r" .. channels .. "|cFFFFFF7F][|r|cFFFFFF00On|r|cFFFFFF7F]|r: Toggles monitoring the " .. gsub(strlower(v), "r", "", 1) .. " channel(s), add a valid channel number to make reported monitor it");
				else
					Msg(" - |cFFFFFF7F" .. gsub(strlower(v), "r", "", 1) .. " [|r" .. channels .. "|cFFFFFF7F][|r|cFFFFFF00Off|r|cFFFFFF7F]|r: Toggles monitoring the " .. gsub(strlower(v), "r", "", 1) .. " channel(s), add a valid channel number to make reported monitor it");
				end
			elseif (Reported_Global_Vars.Channels[v] == 'On') then
				Msg(" - |cFFFFFF7F" .. gsub(strlower(v), "r", "", 1) .. " [|r|cFFFFFF00On|r|cFFFFFF7F]|r: Toggles monitoring the " .. gsub(strlower(v), "r", "", 1) .. " channel");
			else
				Msg(" - |cFFFFFF7F" .. gsub(strlower(v), "r", "", 1) .. " [|r|cFFFF0000Off|r|cFFFFFF7F]|r: Toggles monitoring the " .. gsub(strlower(v), "r", "", 1) .. " channel");
			end
		end
	end,
	["channels_say"] = function()
		Reported_Global_Vars.Channels.rSay = Reported_FlipState(Reported_Global_Vars.Channels.rSay, "Say channel monitoring");
	end,
	["channels_instance_CHAT"] = function()
		Reported_Global_Vars.Channels.rInstance_CHAT = Reported_FlipState(Reported_Global_Vars.Channels.rInstance_CHAT, "Instance_CHAT channel monitoring");
	end,
	["channels_yell"] = function()
  		Reported_Global_Vars.Channels.rYell = Reported_FlipState(Reported_Global_Vars.Channels.rYell, "Yell channel monitoring");
	end,
	["channels_guild"] = function()
  		Reported_Global_Vars.Channels.rGuild = Reported_FlipState(Reported_Global_Vars.Channels.rGuild, "Guild channel monitoring");
	end,
	["channels_officer"] = function()
  		Reported_Global_Vars.Channels.rOfficer = Reported_FlipState(Reported_Global_Vars.Channels.rOfficer, "Officer channel monitoring");
	end,
	["channels_bg"] = function()
	   Reported_Global_Vars.Channels.rBattleground = Reported_FlipState(Reported_Global_Vars.Channels.rBattleground, "Battleground channel monitoring");
	end,
	["channels_battleground"] = function() -- The same as bg
  		Reported_Global_Vars.Channels.rBattleground = Reported_FlipState(Reported_Global_Vars.Channels.rBattleground, "Battleground channel monitoring");
	end,
	["channels_party"] = function()
  		Reported_Global_Vars.Channels.rParty = Reported_FlipState(Reported_Global_Vars.Channels.rParty, "Party channel monitoring");
	end,
	["channels_raid"] = function()
  		Reported_Global_Vars.Channels.rRaid = Reported_FlipState(Reported_Global_Vars.Channels.rRaid, "Raid channel monitoring");
	end,
	["channels_numbered"] = function()
  		Reported_Global_Vars.Channels.rNumbered = Reported_FlipState(Reported_Global_Vars.Channels.rNumbered, "Numbered channel monitoring");
	end,
	["channels_numbered_channels"] = function(chan) -- A function argument!
		if (Reported_Global_Vars.Numbered[chan] == 'On') then
			Msg("Channel |cFFFFFF7F" .. chan .. "|r has been |cFFFFFF7Fremoved|r from the |cFFFFFF7Fnumbered channel|r list.");
			Reported_Global_Vars.Numbered[chan] = 'Off';
		else
			Msg("Channel |cFFFFFF7F" .. chan .. "|r has been |cFFFFFF7Fadded|r to the |cFFFFFF7Fnumbered channel|r list.");
			Reported_Global_Vars.Numbered[chan] = 'On';
		end
	end,
	["modules"] = function()
		local Reported_Modules_Temp = {}; -- Creates and empty table
		for i in pairs(Reported_Modules) do -- Gets the name of each module
			tinsert(Reported_Modules_Temp, i); -- Adds it to the empty table we just made
		end
		sort(Reported_Modules_Temp, function(a,b) return a<b end); -- Sorts the table we just made with all the module names alphabetically
		Msg("|cFFFFFF7FReported Modules|r: To toggle a module type /reported |cFFFFFF7F[|rmodule_name|cFFFFFF7F]|r i.e. |cFFFFFF7F/reported gandalf|r");
		for _,v in pairs(Reported_Modules_Temp) do -- Gets all the module names
      		local pi = gsub(v, "_", " "); -- Removes underscore from module name, replaces with space.
			if (Reported_Modules[v].Toggle == 'On') then -- Checks the modules toggled status, prints thusly
				Msg(" - |cFFFFFF7F" .. pi .. " [|r|cFFFFFF00" .. Reported_Modules[v].Toggle .. "|r|cFFFFFF7F]|r: " .. Reported_Modules[v].Description);
			else
				Msg(" - |cFFFFFF7F" .. pi .. " [|r|cFFFF0000" .. Reported_Modules[v].Toggle .. "|r|cFFFFFF7F]|r: " .. Reported_Modules[v].Description);
			end
		end
	end,
	["modules_on"] = function()
		Msg("All |cFFFFFF7FReported Modules|r have been turned |cFFFFFF7F[|r|cFFFFFF00on|r|cFFFFFF7F]|r.");
		for i in pairs(Reported_Modules) do -- Goes through every module and sets their toggle setting to on.
		    Reported_Modules[i].Toggle = 'On';
		end
	end,
	["modules_off"] = function()
  		Msg("All |cFFFFFF7FReported Modules|r have been turned |cFFFFFF7F[|r|cFFFF0000off|r|cFFFFFF7F]|r. Don't forget to enable atleast 1 module!");
  		for i in pairs(Reported_Modules) do -- Goes through every module and sets their toggle setting to off.
		    Reported_Modules[i].Toggle = 'Off';
		end
	end,
	["modules_counters"] = function()
		local Reported_Modules_Counters_Temp = {}; -- Creates and empty table
		for i in pairs(Reported_Modules) do -- Gets the name of each module
			tinsert(Reported_Modules_Counters_Temp, i); -- Adds it to the empty table we just made
		end
		sort(Reported_Modules_Counters_Temp, function(a,b) return a<b end);
  		for _,v in pairs(Reported_Modules_Counters_Temp) do -- Goes through every module, prints their counter.
        	local pi = gsub(v, "_", " "); -- Removes underscore from module name, replaces with space.
		    Msg("|cFFFFFF7F".. pi .. "|r: " .. Reported_Modules[v].Counter);
		end
	end,
	["recent"] = function()
		local num = 0;
		Msg("Last |cFFFFFF7F10|r reports:");
  		for _,v in pairs(Reported_Recent) do -- Goes through every module, prints their counter.
  			num = num + 1;
        	Msg("#|cFFFFFF7F" .. num .. "|r " .. v);
		end
	end,
	["recent_max"] = function(max)
	    Msg("|cFFFFFF7FMax|r number of |cFFFFFF7Frecent reports|r set to |cFFFFFF7F" .. max .. "|r.");
	    Reported_Global_Vars.maxRecent = max; -- Puts the max value into the global variable table
	    if (#(Reported_Recent) > Reported_Global_Vars.maxRecent) then -- If there are more lines in the table than the max allows...
			repeat -- Keep doing this line until...
				tremove(Reported_Recent, Reported_Global_Vars.maxRecent + 1); -- Removes the line just after the max line (i.e. if the max were 10 it would deleted line 11)
			until (#(Reported_Recent) == Reported_Global_Vars.maxRecent); -- Repeat this until the max allowed and total number of lines are equal
		end
	end,
	["fakeReport"] = function(fakeChannel, fakeName, fakeNum)
	    local ReportedLine = GetModuleLine(fakeName); -- Gets a random module line
		SendChatMessage(ReportedLine, strupper(fakeChannel), nil, fakeNum); -- Sends message with the line that was randomly chosen
		timer = floor(GetTime()) + 35; -- Makes it so if you fake report a real report won't go off, thus making you spam
	end,
	["delay"] = function(lower, upper)
		if (lower) and (upper) then
		    if (lower < upper) and (lower >= 0) then -- If lower is actually lower than upper and is a positive number
		        Reported_Global_Vars.Range.Toggle = "On";
		        Reported_Global_Vars.Range.Lower = lower;
				Reported_Global_Vars.Range.Upper = upper;
				rangeRand = nil;
				Msg("Delay range is |cFFFFFF7F35|r seconds + |cFFFFFF7F" .. Reported_Global_Vars.Range.Lower .. "|r to |cFFFFFF7F" .. Reported_Global_Vars.Range.Upper .. "|r seconds.");
            elseif (lower == upper) then -- Else if lower is the same as upper (no range)
                rangeRand = nil;
		    	Reported_Global_Vars.Range.Lower = lower;
				Reported_Global_Vars.Range.Upper = lower;
				Msg("Delay is now |cFFFFFF7F35|r seconds + |cFFFFFF7F" .. Reported_Global_Vars.Range.Lower .. "|r seconds.");
			elseif (lower == 0 and upper == 0) then -- Else if they are both 0, then add nothing to the base delay.
                rangeRand = nil;
		    	Reported_Global_Vars.Range.Lower = 0;
				Reported_Global_Vars.Range.Upper = 0;
				Msg("Delay is now just |cFFFFFF7F35|r seconds.");
			else
		        Msg("You need to enter |cFFFFFF7Fvalid|r numbers! Lower must be smaller than upper, and they both must not be negative.");
			end
		else
            Msg("Delay range is |cFFFFFF7F35|r seconds + |cFFFFFF7F" .. Reported_Global_Vars.Range.Lower .. "|r to |cFFFFFF7F" .. Reported_Global_Vars.Range.Upper .. "|r seconds.");
		end
	end,
	["afk"] = function()
		Reported_Global_Vars.AFKCancel = Reported_FlipState(Reported_Global_Vars.AFKCancel, "Reporting while AFK");
	end,
	["namefilter"] = function()
		Reported_Global_Vars.namefilter = Reported_FlipState(Reported_Global_Vars.namefilter, "Name filtering");
	end,
	["test"] = function()
	    local string = "modules on off fart banana"
	    local captureTable = {}
	    gsub(string, "(%a+)", function(x) print(x); table.insert(captureTable, x) end)
	    for i,v in pairs(captureTable) do
	        Msg(i .. " : " .. v);
	    end
	end
};

function TableCompare(table1, table2)	
	for i,v in pairs(table1) do -- Adds tables from table1 to table2 if it does not already have it
		if (type(v) == "table") then
			if (table2[i]) then	
				local tempTable = v;
				TableCompare(tempTable, table2[i]);
			else
				table2[i] = v;
			end
		else
			if not (table2[i]) then
				table2[i] = v;
			end
		end
	end
	for i,v in pairs(table2) do -- Removes tables from table2 that no longer exist in table1
		if (type(v) == "table") and not (table1[i]) then
			table2[i] = nil;
		elseif not (table1[i]) then
			table2[i] = nil;
		end
	end
	return table1, table2;	
end

function PrintTable(table)	
	for i,v in pairs(table) do
		if (type(v) == "table") then
			local tempTable = v;
			PrintTable(tempTable);
		else
			Msg(i .. " = " .. v);
		end
	end	
end

function Reported_Slash_Commands(string)
    string = strlower(string);
    if (string ~= "") then
	    local slashArgs = {};
	    gsub(string, "(%w+)", function(x) tinsert(slashArgs, x) end) 
        if (#slashArgs == 1) and (Reported_Commands[string]) then
            Reported_Commands[string]();
        elseif (#slashArgs >= 2) then
            if (slashArgs[1] == "modules") and (slashArgs[2] ~= "on") and (slashArgs[2] ~= "off") and (slashArgs[2] ~= "counters") then
                local moduleName = slashArgs[2];         
                for i=3, #slashArgs do
                    moduleName = moduleName .. "_" .. slashArgs[i]; 
                end
                for i in pairs(Reported_Modules) do
                    if (strlower(i) == moduleName) then
                        if (Reported_Modules[i].Toggle == 'On') then
                            Reported_Modules[i].Toggle = 'Off';
                            Msg("|cFFFFFF7F" .. i .. " module|r is now |cFFFFFF7F[|r|cFFFF0000Off|r|cFFFFFF7F]|r");
                        else
                            Reported_Modules[i].Toggle = 'On';
                            Msg("|cFFFFFF7F" .. i .. " module|r is now |cFFFFFF7F[|r|cFFFFFF00On|r|cFFFFFF7F]|r");
                        end
                    Build_Module_Table(); -- The amount of enabled modules has changed, gotta rebuild the enabled module table!
                    break end
                end
            elseif (slashArgs[1] == "modules") and (slashArgs[2] == "on" or slashArgs[2] == "off" or slashArgs[2] == "counters") then
                Reported_Commands[slashArgs[1] .. "_" .. slashArgs[2]]();
            elseif (slashArgs[1] .. "_" .. slashArgs[2] == "channels_numbered") then
				slashArgs[3] = tonumber(slashArgs[3]); -- Turns the string into a number
				if (slashArgs[3] <= 10) then -- If the digit is less than 10 (max number of channels) it returns true
					Reported_Commands.channels_numbered_channels(slashArgs[3]); -- Send the channel number to the command
				end
            elseif (slashArgs[1] == "channels") and (Reported_Commands[slashArgs[1] .. "_" .. slashArgs[2]]) then
                Reported_Commands[slashArgs[1] .. "_" .. slashArgs[2]]();
            elseif (slashArgs[1] == "recent") then
				slashArgs[2] = tonumber(slashArgs[2]); -- Turns the string into a number
				Reported_Commands.recent_max(slashArgs[2]); -- Send the channel number to the command
            elseif (slashArgs[1] == "report") then
                if (#slashArgs == 3) then
					local fakeChannel = slashArgs[2];
	                if (fakeChannel == "guild") or (fakeChannel == "officer") or (fakeChannel == "party") or (fakeChannel == "raid") or (fakeChannel == "say") or (fakeChannel == "yell") or (fakeChannel == "battleground") or (fakeChannel == "instance_CHAT") then -- checks if the channel arg is any of these
						Reported_Commands.fakeReport(fakeChannel, slashArgs[3]);
					elseif (strlen(fakeChannel) <= 2) and (fakeChannel + 0 >= 1) and (fakeChannel + 0 <= 10) then -- If it doesn't match any named channel it converts it into a number and checks to see if it's 10 or less
						Reported_Commands.fakeReport("CHANNEL", slashArgs[3], fakeChannel);
					end
				else
				    Msg("Hey, enter the right number of arguments jerk. |cFFFFFF7F/reported report [|rchannel|cFFFFFF7F] [|rname|cFFFFFF7F]|r");
				end
            elseif (slashArgs[1] == "delay") then
                slashArgs[2] = tonumber(slashArgs[2]);
                slashArgs[3] = tonumber(slashArgs[3]);
				if (#slashArgs == 3) then
					Reported_Commands["delay"](slashArgs[2], slashArgs[3]);
				elseif (#slashArgs == 2) then
       				Reported_Commands["delay"](slashArgs[2], slashArgs[2]);
				else
					Msg("You must enter |cFFFFFF7Fvalid|r numbers.");
				end
            end
        elseif not (Reported_Commands[string]) then
            Reported_Usage();        
        end 
    else
        Reported_Usage();
    end
end

function Reported_Usage()
	Msg("|cFFFFFF7FReported|r v|cFFFFFF7F" .. Version .. "|r Addon Usage:|r");
	if (Reported_Global_Vars.Toggle == 'On') then
    	Msg(" - |cFFFFFF7Ftoggle [|r|cFFFFFF00On|r|cFFFFFF7F]|r: Toggles the addon on and off");
	else
	    Msg(" - |cFFFFFF7Ftoggle [|r|cFFFF0000Off|r|cFFFFFF7F]|r: Toggles the addon on and off");
	end
	if (Reported_Global_Vars.AFKCancel == 'On') then
    	Msg(" - |cFFFFFF7Fafk [|r|cFFFFFF00On|r|cFFFFFF7F]|r: Toggles blocking the ability to report while AFK");
	else
	    Msg(" - |cFFFFFF7Fafk [|r|cFFFF0000Off|r|cFFFFFF7F]|r: Toggles blocking the ability to report while AFK");
	end
	if (Reported_Global_Vars.namefilter == 'On') then
    	Msg(" - |cFFFFFF7Fnamefilter [|r|cFFFFFF00On|r|cFFFFFF7F]|r: Toggles filtering of server name out of player names");
	else
	    Msg(" - |cFFFFFF7Fnamefilter [|r|cFFFF0000Off|r|cFFFFFF7F]|r: Toggles filtering of server name out of player names");
	end
	Msg(" - |cFFFFFF7Fcounter [|r" .. Reported_Global_Vars.Counter .. "|cFFFFFF7F]|r: Tells you how many times this addon has been triggered (oh it's right there, heh)");
	Msg(" - |cFFFFFF7Frange [|r" ..Reported_Global_Vars.Range.Lower .. " |cFFFFFF7Fto|r " .. Reported_Global_Vars.Range.Upper .. "|cFFFFFF7F]|r: Range of the time (in seconds) of the delay before a |cFFFFFF7FReported|r message is sent. Use |cFFFFFF7F/reported delay n1 n2|r  where |cFFFFFF7Fn1|r is the lower end of the range and |cFFFFFF7Fn2|r is the upper end of the range. Keep |cFFFFFF7Fn2|r blank for no deviation.");
	Msg(" - |cFFFFFF7Frecent[|r" .. #(Reported_Recent) .. "/" .. Reported_Global_Vars.maxRecent.. "|cFFFFFF7F]|r: Prints last " .. Reported_Global_Vars.maxRecent .. " messages you reported, add a number after |cFFFFFF7F/reported recent|r to set max number to record");
	Msg(" - |cFFFFFF7Freport [|rchannel|cFFFFFF7F] [|rname|cFFFFFF7F]|r: Does a fake report, ignores timer but does trigger the timer for regular reporting. Does not add to counter. Example: /reported report 2 Lordbeef, /reported report guild Poopsocks");
 	Msg(" - |cFFFFFF7Fchannels|r: List of all channels you can make reported monitor");
	Msg(" - |cFFFFFF7Fmodules|r: List of all modules and their toggled status");
	Msg(" - |cFFFFFF7Fmodules on|r: Enables all modules");
	Msg(" - |cFFFFFF7Fmodules off|r: Disables all modules");
	Msg(" - |cFFFFFF7Fmodules counters|r: Prints counters of every module");
end

-- Prints the OnLoad message and sets up slash commands
function Reported_OnLoad(self)
 	local totalModules = 0;
	for i in pairs(Reported_Modules_Default) do
	    totalModules = totalModules + 1; -- Adds 1 for every module in the module table
	end
	Msg("|cFFFFFF7FReported|r v|cFFFFFF7F" .. Version .. "|r: Type |cFFFFFF7F/reported|r for info. |cFFFFFF7F" .. totalModules .. "|r modules loaded. Addon by |cFFFFFF7FGoon Squad Mal'Ganis|r."); -- Prints when addon is initialized
 	self:RegisterEvent("ADDON_LOADED");
 	self:RegisterEvent("PLAYER_FLAGS_CHANGED");
 	SLASH_REPORTED1 = "/reported";
 	SlashCmdList["REPORTED"] = Reported_Slash_Commands; -- Directs all slash commands to this function
end

function Reported_OnEvent(self, event)
	if (event == "ADDON_LOADED") and (addonLoaded == 0) then
		Reported_Global_Vars_Default, Reported_Global_Vars = TableCompare(Reported_Global_Vars_Default, Reported_Global_Vars);
		Reported_Modules_Default, Reported_Modules = TableCompare(Reported_Modules_Default, Reported_Modules);
		Build_Module_Table();  -- This is not in the OnLoad function as it would just be ignored.
		addonLoaded = 1;
	end
	if (event == "PLAYER_FLAGS_CHANGED") then
		afk = UnitIsAFK("Player");
	end
end

function Build_Module_Table()
	wipe(Module_Table); -- Clear the table
	for i,v in pairs(Reported_Modules) do -- Walks through the table, getting the index and the value of said index
  		if (Reported_Modules[i].Toggle == 'On') then
		    tinsert(Module_Table, i); -- Turns every index name in Reported_Modules into a value in the Module_Table
		end
	end
end

function CheckMsg(msg, player, chatType, channel, channame) -- The most important function of this AddOn, checks messages for swear words and responds
    -- Table of swears it will check against the message please cover your eyes
	local swears = {
		"faggot",
		"faggit",
		"fuck",
		"nigger",
		"nigga",
		"cunt",
		"bitch",
		"bastard",
		"douche",
		"asshole",
		"gook",
		"chink",
    "%Aasses%A",
		"%Abutt%A",			-- This matches the word butt only
		"%Aspic%A",			-- This matches the word spic only
		"%Acock%A", 		-- This matches the word cock only
		"%Adick%A",			-- This matches the word dick only
		"%Aranga%A", 		-- This matches the word ranga only
		"%Adang%A",			-- This matches the word dang only
		"%Adarn%A",			-- This matches the word darn only
		"%Afuk%A", 			-- This matches the word fuk only
    "%Afuc%A",
    "%Afuker%A",
    "%Afukker%A",
    "%Adafuq%A",
		"%Afukk%A",			-- This matches the word fukk only
		"%Afukc%A",			-- This matches the word fukc only
		"%Aass%A", 			-- This matches the word ass only
		"%Afag%A", 			-- This matches the word fag only
		"%Ashit%A" 			-- This matches the word shit only
	};
	local filteredname;
	
	msg = msg .. " "; -- Makes matching 'shit' easier
	for i,v in ipairs(swears) do -- For every line in the swear table do this
		filteredname = strmatch(player, "([^%-]+)%-?.*"); -- Remove server name from player names. Thanks Lemonking;
		if (strmatch(strlower(msg), v)) and (Reported_Global_Vars.Toggle == 'On') and (filteredname ~= UnitName("Player")) and (#(Module_Table) > 0) and not (afk and Reported_Global_Vars.AFKCancel == 'On') then -- Damn that's a lot of ands. Checks to see if 1. Reported is enabled, 2. You have atleast 1 module enabled, 3. It's not reporting yourself, 4. It's not matching with a tradeskill link.
			if not (timer) or (GetTime() > timer) then -- Has it been 35 seconds since the last report?
			
				if (Reported_Global_Vars.namefilter == "On") then -- use the filter name if the toggle is on
					player = filteredname;
				end
				
				ReportedLine = GetModuleLine(player); -- Passes on the player name to put into the response line if needed
				ReportedLine = ReportedLine .. ReportedLineSuffix; -- Appends suffix to response line

				Reported_Modules[getModuleName].Counter = Reported_Modules[getModuleName].Counter + 1; -- Adds 1 to the module counter				
				Reported_Global_Vars.Counter = Reported_Global_Vars.Counter + 1; -- Adds 1 to the total counter
				printModuleName = gsub(getModuleName, "_", " "); -- Replace underscore with space in the module name for printing purposes
				timer = floor(GetTime()) + 35; -- Can't 'report' someone for 35 seconds.  DO NOT CHANGE THIS
				rResponded = 0;
				local timestampH, timestampM = GetGameTime(); -- Timestamps for Reported_Recent
				lastReported = player; -- These two lines are for the rRespond option
				if (Reported_Global_Vars.Range.Upper == 0) then
					Msg("|cFFFFFF7FReported|r #|cFFFFFF7F" .. Reported_Global_Vars.Counter .. "|r(|cFFFFFF7F" .. Reported_Modules[getModuleName].Counter .. "|r) using |cFFFFFF7F" .. printModuleName .. "|r module.");
					SendChatMessage(ReportedLine, chatType, nil, channel); -- Sends message with the line that was randomly chosen
				else -- If the delay is not 0 then it does other stuff than normal
					elapsedUpdate, swearFound = 0, 1; -- Reset timer to 0
					holdReportedInfo.ChatType = chatType; -- Preserve chatType for delay
					holdReportedInfo.Channel = channel; -- Preserve channel for delay
				end
				if (channel) then -- If channel is something other than nil
					tinsert(Reported_Recent, 1, "[" .. timestampH .. ":" .. timestampM .. "] [" .. channel .. ". " .. channame .. "] [" .. player .. "]: " .. msg); -- Insert information to the beginning of the table
				else
				    local tempPrefix = strmatch(chatType, "%a"); -- Takes the first letter of the variable chatType
					local tempSuffix = strmatch(chatType, "%a*", 2); -- Takes the rest of variable chatType, but skips the first letter
    				chatType = tempPrefix .. strlower(tempSuffix); -- Adds these two together, formatting it so the first letter is capitalized and the rest aren't
                    tinsert(Reported_Recent, 1,"[" .. timestampH .. ":" .. timestampM .. "] [" .. chatType .. "] [" .. player .. "]: " .. msg); -- Inserts it at the top of the table
				end
				if (#(Reported_Recent) > Reported_Global_Vars.maxRecent) then -- If the recent table is larger than it should be
					repeat
						tremove(Reported_Recent, Reported_Global_Vars.maxRecent + 1); -- Removes the line in the table after what should be the last one
					until (#(Reported_Recent) == Reported_Global_Vars.maxRecent); -- Keep doing this until the length of the table is aslong as is allowed
				end
			end
		end
	end
end

function Reported_OnUpdate(self, elapsed)
	if (Reported_Global_Vars.Toggle == "On") and (swearFound == 1) then
        if (rangeRand == nil) then
		    rangeRand = math.random(Reported_Global_Vars.Range.Lower, Reported_Global_Vars.Range.Upper);
		    Msg("|cFFFFFF7FReported|r #|cFFFFFF7F" .. Reported_Global_Vars.Counter .. "|r(|cFFFFFF7F" .. Reported_Modules[getModuleName].Counter .. "|r) using |cFFFFFF7F" .. printModuleName .. "|r module. Delaying by |cFFFFFF7F" .. rangeRand .. "|r seconds.");
		elseif (Reported_Global_Vars.Range.Lower ~= Reported_Global_Vars.Range.Upper) then
			if (elapsedUpdate < rangeRand) then
			    elapsedUpdate = elapsedUpdate + elapsed;
			else
			    swearFound = 0; 
				SendChatMessage(ReportedLine, holdReportedInfo.ChatType, nil, holdReportedInfo.Channel); -- Sends message with the line that was randomly chosen
				wipe(holdReportedInfo); -- Clean up the table
			end
		else
			if (elapsedUpdate < Reported_Global_Vars.Range.Lower) then
		    	elapsedUpdate = elapsedUpdate + elapsed;
			else
				swearFound = 0;
				SendChatMessage(ReportedLine, holdReportedInfo.ChatType, nil, holdReportedInfo.Channel); -- Sends message with the line that was randomly chosen
				wipe(holdReportedInfo); -- Clean up the table
			end
		end
	end
end

local Reported_frame = CreateFrame("Frame"); -- Create frame to get all the events registered below
	Reported_frame:RegisterEvent("CHAT_MSG_SAY"); -- Without registering these chat events, these channels would not be monitored at all for swear words
	Reported_frame:RegisterEvent("CHAT_MSG_YELL");
	Reported_frame:RegisterEvent("CHAT_MSG_GUILD");
	Reported_frame:RegisterEvent("CHAT_MSG_OFFICER");
	Reported_frame:RegisterEvent("CHAT_MSG_PARTY");
	Reported_frame:RegisterEvent("CHAT_MSG_RAID");
	Reported_frame:RegisterEvent("CHAT_MSG_CHANNEL");
	Reported_frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT");
	Reported_frame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER");
	Reported_frame:RegisterEvent("CHAT_MSG_BATTLEGROUND");
	Reported_frame:RegisterEvent("CHAT_MSG_WHISPER");
	Reported_frame:RegisterEvent("CHAT_MSG_BATTLEGROUND_LEADER");
	Reported_frame:RegisterEvent("CHAT_MSG_RAID_LEADER");
	Reported_frame:RegisterEvent("CHAT_MSG_PARTY_LEADER");
	Reported_frame:SetScript("OnEvent", function (self, event, msg, player, _, _, _, _, _, channel, channame)
	event = gsub(event, "_LEADER", ""); -- Removes the _LEADER from PARTY_LEADER so you can report them
	if (event == "CHAT_MSG_SAY" and Reported_Global_Vars.Channels.rSay == 'On') or (event == "CHAT_MSG_YELL" and Reported_Global_Vars.Channels.rYell == 'On') or (event == "CHAT_MSG_GUILD" and Reported_Global_Vars.Channels.rGuild == 'On') or (event == "CHAT_MSG_OFFICER" and Reported_Global_Vars.Channels.rOfficer == 'On') or (event == "CHAT_MSG_PARTY" and Reported_Global_Vars.Channels.rParty == 'On') or (event == "CHAT_MSG_RAID" and Reported_Global_Vars.Channels.rRaid == 'On') or (event == "CHAT_MSG_INSTANCE_CHAT" and  Reported_Global_Vars.Channels.rInstance_CHAT == 'On') or (event == "CHAT_MSG_BATTLEGROUND" and Reported_Global_Vars.Channels.rBattleground == 'On') then
  		event = gsub(event, "CHAT_MSG_", ""); -- Removes the first two parts of the event, leaving the channel it was said in
		msg = gsub(msg, "%[.+%](%|h)", ""); -- This funky thing removes any thing that you would see in brackets such as item, achievement, spell, and tradeskill links
		CheckMsg(msg, player, event); -- Send info to function
	elseif (event == "CHAT_MSG_CHANNEL") and (Reported_Global_Vars.Channels.rNumbered == 'On') then
		for i,v in pairs(Reported_Global_Vars.Numbered) do
			if (i == channel) and (v == 'On') then
				msg = gsub(msg, "%[.+%](%|h)", ""); -- This funky thing removes any thing that you would see in brackets such as item, achievement, spell, and tradeskill links
				CheckMsg(msg, player, "CHANNEL", channel, channame); -- Send info to function
			end
		end
	elseif (event == "CHAT_MSG_WHISPER") and (Reported_Global_Vars.Channels.rRespond == 'On') and (rResponded == 0) and (player == lastReported) then -- If the message is in a whisper, rRespond is enabled, it has not responded to the person before, and the person is the last person to be reported then
		rResponded = 1; -- Makes it so this is only set once to the person
		SendChatMessage("hey man...just stop cussing, and vot republican. peace", "WHISPER", nil, player); -- palin/bachmann 2012
	end
end);	