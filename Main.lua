--- Reported v2.0 by Krakyn Mal'Ganis
local addon = select(2, ...)
local  _G = _G
local db, Reported
local print = function(...) print('Reported', ...) end
local rand, pairs, ipairs, type, tinsert, tremove = math.random, pairs, ipairs, type, tinsert, tremove
local GetTime, PlaySoundFile, tostring, strupper, strlower = GetTime, PlaySoundFile, tostring, strupper, strlower
local CreateFrame, SendChatMessage = CreateFrame, SendChatMessage
local nextCheckTime = 0
local defaults = {
  dialog = true,
  channels = {
    SAY = false,
    YELL = true,
    INSTANCE = true,
    BATTLEGROUND = true,
    CHANNEL1 = true,
    CHANNEL2 = true
  },
  modules = {
    ['Default'] = {true, 0, 0},
  },
  enable = true,
  filterRealmName = true,
  delayMin = 3,
  delayMax = 9,
  throttle = 17,
  noAFK = true
}
local monitors_order = {
  'CHANNEL', 'SAY', 'YELL', 'PARTY', 'RAID', 'INSTANCE', 'BATTLEGROUND', 'GUILD', 'OFFICER'
}
local monitors = {
  SAY = {
    enable = true,
    label = _G.SAY
  },
  YELL = {
    enable = true,
    label = _G.YELL
  },
  INSTANCE = {
    enable = true,
    label = _G.INSTANCE
  },
  CHANNEL = {
    enable = true,
    label = _G.CHAT,
  },
  RAID = {
    enable = false,
    label = _G.RAID
  },
  PARTY = {
    enable = false,
    label = _G.PARTY
  },
  BATTLEGROUND = {
    enable = true,
    label = _G.BATTLEGROUND
  },
  GUILD = {
    enable = false,
    label = _G.GUILD,
  },
  OFFICER = {
    enable = false,
    label = _G.OFFICER
  },
}
local swears = {
  "f+%s*a+%s*g+%s*[oi]+%s*t+",
  "f+%s*u+[qck%s]+",           -- 'fuck' variations
  "f+%s*u+[qck%s]+e+%s*r+",    -- 'fucker' variations
  "d+%s*a+%s*f+%s*u+[qck%s]+", -- 'dafuck'
  "n+%s*i+%s*g+%s*e+%s*[ra]+",
  "c+%s*u+%s*n+%s*t+",
  "b+%s*i+%s*t*%s*c+%s*h+",
  "b+%s*a+%s*s+%s*t+%s*a+%s*r+%s*d+",
  "d+%s*o+%s*u+%s*c+%s*h+%s*e+",
  "a+%s*s+%s*h+%s*o+%s*l+%s*e+",
  "g+%s*o+%s*[ckq]+",
  "c+%s*h+%s*i+%s*n+%s*[kqc]+",
  "a+%s*s+%s*e+%s*s+",
  "b+%s*u+%s*tt+%s*",	-- match butt with two T's
  "s+%s*p+%s*i+%s*[ck%s]+",			-- This matches the word spic only
  "c+%s*o+%s*[qck%s]+", 		-- This matches the word cock only
  "%Ad+%s*i+%s*[qck%s]+%A",			-- This matches the word dick only
  "d+%s*a+%s*n+%s*g+",			-- This matches the word dang only
  "d+%s*a+%s*r+%s*n+",			-- This matches the word darn only
  "f+%s*a+%s*g+",
  "s+%s*h+%s*i+%s*t+",
  "ranga", 		-- This matches the word ranga only
}

local playerName
local enabledModules = {}
local GetReportedLine = function(filteredname)
  local module = rand(1,#enabledModules)
  local line = rand(1, #enabledModules[module])
  local text = addon.moduleText[module][line]
  print('pulling line|cFFFFFF00', line, '|rfrom module|cFF00FF00', module..'|r')
  text = text:gsub("%%Pl", filteredname);
  text = text:gsub("%%PL", strupper(filteredname));
  text = text:gsub("%%pl", strlower(filteredname));
  return text
end



local Reported_Command = function()
  print('hello')
  if Reported:IsVisible() then
    Reported.fadeOut:Play()
    db.dialog = false
  else
    Reported.fadeIn:Play()
    db.dialog = true
  end
end


local Reported_OnUpdate = function(self, elapsed)
  self.current = self.current + elapsed
  if self.duration > 0 then
    local remaining = self.expire - self.current
    --print(remaining)
    if remaining <= 0 then
      self:SetScript('OnUpdate', nil)
      self.duration, self.expire = 0
      self.priority = 0
      self.duration = 0
      self.expire = 0
      self.time:Hide()
      self.progress:Hide()

      if self.payload then
        print('executing payload')
        self:payload(self)
      end

    else
      self.time:SetFormattedText('%0.2f / %d', remaining, self.duration)

      self.progress:SetWidth(self:GetWidth() * max(0,(remaining/self.duration)))
    end
  end
end

local Reported_Timer = function(self, duration, priority, payload)
  if self.duration == 0 or priority > self.priority then
    self.current = GetTime()
    self.duration = duration
    self.expire = self.current+ self.duration
    print('beginning timer', self.duration, (tostring(priority) .. '('..self.priority..')'), payload)
    self.priority = priority
    self:SetScript('OnUpdate', Reported_OnUpdate)
    self.progress:SetTexture(priority-1, 2-priority, 0, 1)
    self.payload = payload
    self.progress:Show()
    self.time:Show()
    return true
  end
  return false
end

local Reported_Send = function(filteredname, chatType, channelNumber)
end

local Reported_OnChatMsg = function(self, event, message, sender, language, channelString, target, flags, unknown, channelNumber, channelName, unknown, counter, guid)
  if GetTime() <= nextCheckTime then
    return
  end

  local filteredname = sender:gsub("-%a+", "")
  message = ' ' .. message .. ' ' -- pad with spaces for matching full words
  local hasSwear = false
  local detectedWord
  for _, cussString in ipairs(swears) do

    detectedWord = message:match(cussString)
    if detectedWord then
      PlaySoundFile([[Interface\Addons\SharedMedia_MyMedia\sound\Quack.ogg]])
      print(detectedWord)
      hasSwear = true
      break
    end
  end

  if hasSwear then
    print('|cFF00FF00', '|cFFFFFF00'..filteredname..'|r', message:gsub(detectedWord, '|cFFFF0000'..string.rep('*', #detectedWord)..'|r'))
    sender=  sender:gsub("%-.+$", "")
    print(sender)
    nextCheckTime = GetTime() +  db.throttle
    local delay = rand(db.delayMin, db.delayMax)
    Reported_Timer(self, delay, 1, function()
      PlaySoundFile([[Interface\Addons\SharedMedia_MyMedia\sound\IM.ogg]])

      local message = GetReportedLine(filteredname)
      SendChatMessage(message, chatType, nil, channelNumber)
      Reported_Timer(self, db.throttle, 2)
    end)
    local numReports = 1
    print('Reporting #'..numReports..' in '..delay..'s.')
  end
end


local events = {
  ["CHAT_MSG_SAY"] = 'SAY',
  ["CHAT_MSG_YELL"] = 'YELL',
  ['CHAT_MSG_GUILD'] = 'GUILD',
  ['CHAT_MSG_OFFICER'] = 'OFFICER',
  ['CHAT_MSG_PARTY'] = 'PARTY',
  ['CHAT_MSG_RAID'] = 'RAID',
  ['CHAT_MSG_CHANNEL'] = function(...) return "CHANNEL" .. tostring(select(10,...)) end,
  ['CHAT_MSG_INSTANCE_CHAT'] = 'INSTANCE',
  ['CHAT_MSG_INSTANCE_CHAT_LEADER'] = 'INSTANCE',
  ['CHAT_MSG_BATTLEGROUND'] = 'BATTLEGROUND',
  ['CHAT_MSG_BATTLEGROUND_LEADER'] = 'BATTLEGROUND',
  ['CHAT_MSG_WHISPER'] = 'WHISPER',
  ['CHAT_MSG_RAID_LEADER'] = 'RAID',
  ['CHAT_MSG_PARTY_LEADER'] = 'PARTY',
}
local ReportedButton_Update = function(self, value)
  print('new value', value)
  if self:GetChecked() then
    --self.label:SetTextColor(0,1,0,1)
  else
    --self.label:SetTextColor(1, 0,0,1)
  end
end

Reported_OnLoad = function(self)
  Reported = self
  self.duration, self.expire, self.priority = 0, 0, 0
  self:RegisterEvent('ADDON_LOADED')
  self:RegisterUnitEvent('PLAYER_FLAGS_CHANGED', 'player')

  for event, chatID in pairs(events) do
    self:RegisterEvent(event)
  end
  SLASH_REPORTED1 = "/reported"
  SlashCmdList['REPORTED'] = Reported_Command

end
Reported_OnEvent = function(self, event, ...)
  if event == 'ADDON_LOADED' then
    print('addon loaded')
    if not _G.ReportedDB then _G.ReportedDB = {} end
    db = _G.ReportedDB
    for k,v in pairs(defaults) do
      --if not db[k] then
        db[k] = v
      --end

      if type(v) == 'table' then
        for kk, vv in pairs(defaults[k]) do
          --if not db[k][kk] then
            db[k][kk] = vv
          --end
        end
      end
    end

    for chatID, monitor in pairs(monitors) do
      print('watching', monitor.label)
      monitor.enable = db.channels[chatID] and db.channels[chatID] or false
    end



    playerName = UnitName('player')
    local moduleLines = 0
    local moduleText = addon.moduleText
    local moduleInfo = addon.moduleInfo
    enabledModules = {}
    for moduleName, enabled in pairs(db.modules) do
      if enabled and moduleInfo[moduleName] then
        local newindex = #enabledModules + 1
        print(addon, newindex, moduleName)

        enabledModules[newindex] = moduleText[moduleName]
        moduleInfo[moduleName].index = newindex

        moduleLines = moduleLines + #moduleText[moduleName]
      end
    end

    print(#moduleInfo, 'modules', moduleLines, 'lines')

    local last = self.label
    for index, chatID in ipairs(monitors_order) do
      local monitor = monitors[chatID]
      local button = CreateFrame('CheckButton', 'Reported'.. chatID..'Button', self, 'ReportedCheckButton')

      button.label:SetText(monitor.label)
      button:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, -1)
      button:SetChecked(db.channels[chatID])

      print(chatID, button, button:GetPoint(1))
      last = button

      if chatID == 'CHANNEL' then
        local lastChannel = last
        for channelNumber = 1, 10 do
          local from, target, to, x, y
          if channelNumber == 1 then
            from, target, to, x, y= 'TOPLEFT', lastChannel, 'TOPRIGHT', 26 , 0
          else

            from, target, to, x, y= 'TOPLEFT', lastChannel, 'TOPRIGHT', 1, 0
          end

          chatID = 'CHANNEL' .. channelNumber
          local channelButton = CreateFrame('CheckButton', 'Reported'.. chatID..'Button', self, 'ReportedChannelCheckButton')
          channelButton:SetChecked(db.channels[chatID])
          channelButton.Update = ReportedButton_Update
          channelButton.label:SetText(channelNumber)
          channelButton:SetPoint(from, target, to, x, y)
          channelButton:SetChecked(db.channels[chatID])

          channelButton:Update()
          print(chatID, channelButton, channelButton:GetPoint(1))
          lastChannel = channelButton
        end
        button.Update = function(self)
          ReportedButton_Update(self)
          local enabled = self:GetChecked()

          for i = 1, 10 do
            print('ReportedCHANNEL'..i..'Button')
            _G['ReportedCHANNEL'..i..'Button']:SetEnabled(enabled)
          end
        end
      else
        button.Update = ReportedButton_Update
      end
      button:Update()

    end
    self:UnregisterEvent('ADDON_LOADED')
  elseif event == 'PLAYER_FLAGS_CHANGED'  then

  elseif events[event] then
    local chatID = (type(events[event]) == 'function') and events[event](self, event, ...) or events[event]
    print('resolved chatID:', chatID)
    if db.channels[chatID] then
      Reported_OnChatMsg(self, event, ...)
    end
  end
end
