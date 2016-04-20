--- Reported v2.0 by Goon Squad
-- Re-written from scratch by Krakyn
--
local addon = select(2, ...)
local  _G = _G
local Reported = _G.ReportedFrame

local rand, pairs, ipairs, type, unpack, floor, max, select, sort, wipe = math.random, pairs, ipairs, type, unpack, floor, max, select, sort, table.wipe
local GetTime, PlaySoundFile, tostring, strupper, strlower, rep = GetTime, PlaySoundFile, tostring, strupper, strlower, string.rep
local CreateFrame, SendChatMessage, UnitIsAFK, UnitName, UnitGUID = CreateFrame, SendChatMessage, UnitIsAFK, UnitName, UnitGUID
local nextCheckTime, modulesAvailable, fauxScrollEntries, fauxScrollOffset = 0, 0, 0, 0
local db, channelToggleButton, playerName, myGUID

-- debug messages; does nothing when the toolkit isn't present and active
local print = function(...) if _G.Devian and _G.Devian.InWorkspace() then print('Reported', ...) end end

-- chat window output
local Msg = function(text)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cFFFFFF00Reported|r: ' ..text) end
end
local versionString = 6024005
local dictionaryVersion = 72
-- default config values
local defaults = {
  channels = {
    SAY = false,
    YELL = true,
    INSTANCE = true,
    BATTLEGROUND = true,
    CHANNEL1 = true,
    CHANNEL2 = true
  },
  modules = {
    ['Default'] = {false, 0, 0},
    ['Riko'] = {true, 0, 0},
  },
  EnableState = true,
  DialogState = true,
  FilterRealmNames = true,
  DelayMin = 2,
  DelayMax = 6,
  Throttle = 24,
  NoAFK = true,
  LineSuffix = '',
  Dictionary =  {
    "%A+f+%s*a+%s*g+%A", -- [1]
    "d+%s*a+%s*m+%s*n+", -- [2]
    "%Af+%s*u+[qck%s]+%A", -- [3]
    "%As+%s*h+%s*i+%s*t+%A", -- [4]
    "[%Ar]f+%s*u+[qck%s]+e+%s*r+", -- [5]
    "%Af+%s*a+%s*g+%s*[oi]+%s*t+", -- [6]
    "%Ad+%s*a+%s*f+%s*u+[qck%s]+", -- [7]
    "%An+%s*i+%s*gg+%s*e+%s*[ra]+", -- [8]
    "%Ac+%s*u+%s*n+%s*t+", -- [9]
    "%Ab+%s*i+%s*t*%s*c+%s*h+", -- [10]
    "%Ab+%s*a+%s*s+%s*t+%s*a+%s*r+%s*d+", -- [11]
    "%Ad+%s*o+%s*u+%s*c+%s*h+%s*e+", -- [12]
    "a+%s*s+%s*h+%s*o+%s*l+%s*e+", -- [13]
    "%Aa%s*s%s*s+%A", -- [14]
    "c+%s*h+%s*i+%s*n+%s*[kqc]+", -- [15]
    "%Aa+%s*s+%s*e+%s*s+%A", -- [16]
    "%As+%s*p+%s*i+%s*[ck%s]+", -- [17]
    "%Ac+%s*o%s*c+%s*[k%s]+%A", -- [18]
    "%Ad+%s*i+%s*[qck%s]+%A", -- [19]
    "%Ad+%s*a+%s*n+%s*g+%A", -- [20]
    "d+%s*a+%s*mm*%s*i+%s*t+", -- [21]
    "%Ad+%s*a+%s*r+%s*n+%A", -- [22]
    "ranga", -- [23]
  }
}
local events = {
  ["CHAT_MSG_SAY"] = 'SAY',
  ["CHAT_MSG_YELL"] = 'YELL',
  ['CHAT_MSG_GUILD'] = 'GUILD',
  ['CHAT_MSG_OFFICER'] = 'OFFICER',
  ['CHAT_MSG_PARTY'] = 'PARTY',
  ['CHAT_MSG_RAID'] = 'RAID',
  ['CHAT_MSG_CHANNEL'] = 'CHANNEL',
  ['CHAT_MSG_INSTANCE_CHAT'] = 'INSTANCE_CHAT',
  ['CHAT_MSG_INSTANCE_CHAT_LEADER'] = 'INSTANCE_CHAT',
  ['CHAT_MSG_BATTLEGROUND'] = 'BATTLEGROUND',
  ['CHAT_MSG_BATTLEGROUND_LEADER'] = 'BATTLEGROUND',
  ['CHAT_MSG_WHISPER'] = 'WHISPER',
  ['CHAT_MSG_RAID_LEADER'] = 'RAID',
  ['CHAT_MSG_PARTY_LEADER'] = 'PARTY',
}
addon.orderedNames = {}
addon.orderedModules = {}
addon.dictionary = {}
addon.enabledModules = {}
local swears = addon.dictionary
local orderedNames = addon.orderedNames
local orderedModules = addon.orderedModules
local enabledModules = addon.enabledModules
local moduleText = addon.moduleText

local monitors_order = {
  'CHANNEL', 'SAY', 'YELL', 'PARTY', 'RAID', 'INSTANCE_CHAT', 'BATTLEGROUND', 'GUILD', 'OFFICER'
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
  INSTANCE_CHAT = {
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

local GetReportedLine = function(filteredname)
  local module = addon.enabledModules[rand(1,#addon.enabledModules)]
  local line = rand(1, #moduleText[module])
  local text = moduleText[module][line]
  text = text:gsub("%%Pl", filteredname);
  text = text:gsub("%%PL", strupper(filteredname));
  text = text:gsub("%%pl", strlower(filteredname));
  db.modules[module] = db.modules[module] or {true, 0, 0 }

  if #db.LineSuffix >= 1 then
    text = text .. ' ' .. db.LineSuffix
  end

  return text, module, line, unpack(db.modules[module])
end

local Reported_OnUpdate = function(self, elapsed)
  self.current = self.current + elapsed
  if self.duration > 0 then
    local remaining = self.expire - self.current
    if remaining <= 0 then
      self:SetScript('OnUpdate', nil)
      self.time:Hide()
      self.progress:Hide()
    else
      self.time:SetFormattedText('%0.2f / %d', remaining, self.duration)
      self.progress:SetWidth(ChatFrame1:GetWidth() * max(0,(remaining/self.duration)))
    end
  end
end

-- deals with timing delayed reponses and output throttle
-- priority value is used to safeguard against timer spam
local Reported_Timer = function(self, duration, priority, payload)
  if self.duration == 0 or priority > self.priority then
    C_Timer.After(duration, function()
      self.duration = 0
      self.expire = 0
      self.priority = 0
        if payload then
          payload()
        end
      end)
    self.current = GetTime()
    self.duration = duration
    self.expire = self.current+ self.duration
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

-- parses the actual chat event for dirty words
local Reported_OnChatMsg = function(self, event, message, sender, channelName, _, target, _, _, channelNumber)

  print(self, event, message, sender, channelName, _, target, _, _, channelNumber)
  if GetTime() <= nextCheckTime then
    return
  end

  local filteredname = sender:gsub("%-.+", "")
  local chatType = events[event]
  local chatID = chatType

  if chatType == 'CHANNEL' then
    if not db.channels[chatType .. channelNumber] then
      return
    end
    chatID = chatID .. channelNumber
  end
  print(chatType, chatID, sender)

  message = ' ' .. strlower(message) .. ' ' -- pad with spaces for matching full words
  local hasSwear = false
  local detectedWord
  local lastWord
  for i, cussString in ipairs(db.Dictionary) do

    detectedWord = message:match(cussString)
    lastWord = cussString
    if detectedWord then
      detectedWord = detectedWord:gsub("^%s+", ""):gsub("%s+$", "")
      PlaySoundFile([[Interface\Addons\SharedMedia_MyMedia\sound\Quack.ogg]])
      hasSwear = true
      break
    end
  end
  print('pattern check ended at "'..tostring(lastWord)..'"')

  if hasSwear then
    sender=  sender:gsub("%-.+$", "")
    nextCheckTime = GetTime() +  db.Throttle
    local delay = rand(db.DelayMin, db.DelayMax)
    local message, module, line, total, session = GetReportedLine(filteredname)
    Reported_Timer(self, delay, 1, function()
      PlaySoundFile([[Interface\Addons\SharedMedia_MyMedia\sound\IM.ogg]])
      SendChatMessage(message, chatType, nil, channelNumber)
      Reported_Timer(self, db.Throttle, 2)
    end)
    local numReports = 1

    db.modules[module] = db.modules[module] or {true, 0, 0 }
    db.modules[module][2] = db.modules[module][2] + 1

    Msg('Reporting |cFFFFFF88'.. filteredname .. '|r for "|cFFFF0000'..detectedWord..'|r" (#'..(db.modules[module][2])..') in |cFF00FFFF' .. chatID .. '|r (|cFF00FF00'..module..'|r, |cFFFFFF00'..line..'|r).')
  end
end

local colors = {
  ['disabled']  = {.15, .15, .15, 1,
    1, 1, 1, .05},
  ['checkdisabled'] = {.25, .25, .25, 1,
    1, 1, 1, .35
  },
  ['checked']   = {.4, .8, 1, 1,
    0.3, .7, 1, 1},
  ['unchecked'] = {0.1, 0.1, 0.1, 1,
    1, 1, 1, .5},
}

local JournalButton_OnClick = function(self)
  if db.modules[self.moduleName] then
    if db.modules[self.moduleName][1] == true then
      db.modules[self.moduleName][1] = false
    else
      db.modules[self.moduleName][1] = true
    end
  else
    db.modules[self.moduleName] = { true, 0, 0 }
  end
  addon.UpdateEntries()
  addon.UpdateModules()
end

local SetPalette = function(self, checked, enabled)
end


local ChannelButton_OnShow = function(self)
  local checked, enabled = self:GetChecked(), self:IsEnabled()
  local swatch = colors.unchecked
  if not enabled then
    swatch = colors.disabled
    if checked then swatch = colors.checkdisabled end
  else
    if checked then swatch = colors.checked end
  end
  local r1, b1, g1, a1, r2, b2, g2, a2 = unpack(swatch)
  self.bg:SetTexture(r1, b1, g1, a1)
  self.label:SetTextColor(r2, b2, g2, a2)
end
local ChatChannelButton_OnClick = function(self)
  db.channels[self.chatID] = self:GetChecked()
  ChannelButton_OnShow(self)
end

local ChatButton_OnClick = function(self, value)
  local value = self:GetChecked()
  if self.chatType == 'CHANNEL' then
    -- chat channel buttons
    for i = 1, 10 do
      if value == true then
        self.numbers[i]:Enable()
      else
        self.numbers[i]:Disable()
      end
      ChannelButton_OnShow(self.numbers[i])
    end
  end
  db.channels[self.chatType] = value
  ChannelButton_OnShow(self)
end

-- organized into tables of ['FrameScript type']['widget key']
local OnClick = {}
local OnValueChanged = {}
local OnEnterPressed = {}
local OnEscapePressed = {}
OnEnterPressed.Dictionary = function(self)
  local wordlist = {}
  local words = self:GetText()
  local position = 0
  local n = 1
  local offset = word:find('\n')
  repeat
    local cussword = words:sub(position, offset)
    cussword = cussword:gsub('*', '[%s*]'):gsub('|end', '%A'):gsub('start|', '%A')
    cussword = cussword:gsub('^%s+', ''):gsub('%s+$', '')
    print('  saving cussword pattern:', cussword)
    tinsert(wordlist, cusswords)

    position = offset+1
    offset = word:find('\n', position)
  until offset >= #words


end
OnEscapePressed.LineSuffix = function(self)

end

OnValueChanged.DelayMin = function(self)
  if self:GetValue() > Reported.DelayMax:GetValue() then
    Reported.DelayMax:SetValue(self:GetValue())
  end
  db.DelayMin = self:GetValue()
  self.label:SetFormattedText("%0.1f", self:GetValue())
end
OnValueChanged.DelayMax = function(self)
  if self:GetValue() < Reported.DelayMin:GetValue() then
    Reported.DelayMin:SetValue(self:GetValue())
  end
  db.DelayMax = self:GetValue()
  print('DelayMax', db.DelayMax)
  self.label:SetFormattedText("%0.1f", self:GetValue())
end
OnValueChanged.Throttle = function(self)
  db.Throttle = floor(self:GetValue()+.5)
  self.label:SetFormattedText("%d", db.Throttle)
end

OnClick.EnableState = function(self)
  db.EnableState = self:GetChecked()
  Reported.enabled = db.EnableState
  addon.UpdateEnableState()
end
OnClick.NoAFK = function(self)
  db.NoAFK = self:GetChecked()
  addon:PlayerFlagsChanged()
end
OnClick.TestButton = function(self)
  local text, module, line,  enabled, total, session = GetReportedLine(playerName)
  Msg('Test:\n'.. text .. '\n(|cFF00FF00'.. module..'|r. |cFFFFFF00' .. line .. '|r).')
end
OnClick.CloseButton = function()
  Reported.fadeOut:Play()
end

---- These are all prompted by user action and therefore have to be accessible to one another
-- chat command
addon.Command = function(input)
  if input:match("%a+") then
    Msg("|cFFFFFF00Reported|r usage: /reported")
    return
  end

  if Reported:IsVisible() then
    Reported.fadeOut:Play()
    db.DialogState = false
  else
    Reported.fadeIn:Play()
    db.DialogState = true
  end
end

-- module selection
local entryHeight, entryWidth
addon.UpdateEntries = function()

  -- reset the module journal
  wipe(addon.orderedModules)
  sort(addon.orderedNames, addon.ModuleSort)
  for i, v in ipairs(addon.orderedNames) do
    addon.orderedModules[i] = addon.moduleText[v]
  end

  Reported.entries = Reported.entries or {}
  local last= Reported.entryListHeader

  if not Reported.entries[1] then
    -- create a dummy entry so we can get measurements
    Reported.entries[1] = CreateFrame('Button', 'ReportedModuleEntry1', Reported, 'ReportedModuleentry')
    Reported.entries[1].text:SetText('bar')
    entryHeight = Reported.entries[1].text:GetStringHeight() + 6
    entryWidth = Reported.entryList:GetWidth()
    fauxScrollEntries = floor((Reported.entryList:GetHeight() - Reported.entryListHeader:GetHeight()) / entryHeight)
  end

  for i = 1, fauxScrollEntries do
    Reported.entries[i] = Reported.entries[i] or CreateFrame('Button', 'ReportedModuleEntry'..i, Reported, 'ReportedModuleentry')
    local entry = Reported.entries[i]
    local index = i + fauxScrollOffset

    entry.moduleName = orderedNames[index]
    entry.text:SetText('|cFF66DDFF' .. orderedNames[index].. '|r - ' .. (orderedModules[index].Description or "") .. (orderedModules[index].Credit and (' |cFFFFFF00by '.. orderedModules[index].Credit) or ""))
    entry:SetSize(entryWidth, entryHeight)
    entry:SetPoint('TOPLEFT', last, 'BOTTOMLEFT', 0, 0)
    entry:SetScript('OnClick', JournalButton_OnClick)

    local numModules, numLines = 0, 0
    if db.modules[orderedNames[index]] and db.modules[orderedNames[index]][1] then
      entry.bg:SetTexture(.2,0.4,.2, 1)
      numModules= numModules + 1
      numLines = numLines + #moduleText[orderedNames[index]]
    else
      entry.bg:SetTexture(.2, .2, .2, 1)
    end
    last = entry
  end
end

-- used to sort module list with selected modules placed at the top
addon.ModuleSort = function(a,b)
  if db.modules[a] and (db.modules[a][1] == true) then
    if db.modules[b] and (db.modules[b][1] == true) then
      --print('and(', a, ',', b') = true, but a < b =', (a < b))
      return a < b
    else
      --print('and(', a, ' true,', b,' false) = true')
      return true
    end
  elseif db.modules[b] and (db.modules[b][1] == true) then
    --print(a, 'false', b, 'true, so false')
    return false
  else
    return a < b
  end
end

-- player login/zoning
addon.Initialize = function()
  -- shortcuts
  enabledModules = addon.enabledModules
  swears = addon.dictionary


  -- player info
  myGUID = UnitGUID('player')
  playerName = UnitName('player')

  -- fetch savedvars
  _G.ReportedDB = _G.ReportedDB or {}
  db = _G.ReportedDB
  for k,v in pairs(defaults) do
    if db[k] == nil then
      db[k] = v
    end

    if type(v) == 'table' then
      for kk, vv in pairs(defaults[k]) do
        if db[k][kk] == nil then
          db[k][kk] = vv
        end
      end
    end
  end

  if versionString > (db.versionString or 0) then
    db.versionString = versionString
    db = defaults
    Msg('Saved options were reset for a recent update. This message will self-destruct.')
  elseif dictionaryVersion > (db.dictionaryVersion or 0) then
    _G.ReportedDB.Dictionary = defaults.Dictionary
    db.dictionaryVersion = dictionaryVersion
    Msg('Dictionary was reset for a recent update. This message will self-destruct.')
  end



  -- resolve watched channels
  for chatID, monitor in pairs(monitors) do
    --print('watching', monitor.label)
    monitor.enable = db.channels[chatID] and db.channels[chatID] or false
  end

  addon.UpdateModules()
  Reported:UnregisterEvent('ADDON_LOADED')
  Reported:RegisterUnitEvent('PLAYER_FLAGS_CHANGED', 'player')
  addon.UpdateEnableState(true)

  if db.dialog == true and not Reported:IsVisible() then
    Reported.fadeIn:Play()
  end

end

addon.UpdateModules = function()
  -- compile stats
  local moduleLines = 0
  wipe(addon.orderedNames)
  wipe(addon.enabledModules)
  for name, module in pairs(addon.moduleText) do
    local i = #addon.orderedNames+1
    addon.orderedNames[i] = name

    if db.modules[name] then
      local enabled, totalReports = unpack(db.modules[name])
      db.modules[name][3] = 0
      if enabled then
        local newindex = #addon.enabledModules + 1
        --print('|cFFFF0088'..newindex..'|r', name)
        addon.enabledModules[newindex] = name
        moduleText[name].index = newindex
        moduleLines = moduleLines + #moduleText[name]
      end
    end
  end
  local numModules = #addon.enabledModules
  local modulesString = tostring(numModules) .. ' module'..((numModules ~= 1) and 's' or '')..', '.. tostring(moduleLines).. ' lines'
  Reported.stats:SetText(modulesString)
end

-- addon function is toggled
addon.UpdateEnableState = function(quiet)
  if Reported.enabled == false then
    Reported:UnregisterAllEvents()
    if not quiet then
      if db.EnableState == false then
        Msg("|cFFFFFF00Reported|r toggled |cFFFF0000Off|r.")
      else
        Msg("|cFFFFFF00Reported|r standing by.")
      end
    end
  else
    for event, chatID in pairs(events) do
      Reported:RegisterEvent(event)
    end
    if not quiet then Msg("|cFFFFFF00Reported|r toggled |cFF00FF00On|r.") end
  end
end

-- player's AFK state changed
addon.PlayerFlagsChanged = function()
  local enabled = Reported.enabled
  if UnitIsAFK('player') and db.NoAFK then
    if Reported:IsVisible() then
      Reported.playerFlag:Show()
      Reported.playerFlag:SetText('AFK')
    end
    Reported.enabled = false
  else
    if Reported:IsVisible() then
      Reported.playerFlag:Hide()
    end
    Reported.enabled = db.EnableState
  end
  if enabled ~= Reported.enabled then
    addon.UpdateEnableState()
  end
end

---- Defined in global space for simplicity; they are only looked up once so it's probably okay

-- journal scrollwheel activity
ReportedGSH_OnScroll = function(self, delta)
  if delta < 0 then
    fauxScrollOffset = fauxScrollOffset + 5
    if (fauxScrollOffset + fauxScrollEntries) >= #addon.orderedModules then
      fauxScrollOffset = #addon.orderedModules - fauxScrollEntries
    end
  else
    fauxScrollOffset = fauxScrollOffset - 5
    if fauxScrollOffset <= 0 then
      fauxScrollOffset = 0
    end
  end
  addon.UpdateEntries(self)
end

-- any time the /reported UI is opened
ReportedGSH_OnShow = function(self)
  local last = self
  local anchor, point, x, y = 'TOPRIGHT', 'TOPLEFT', 0, 0
  self:EnableMouse(true)
  self:EnableMouseWheel(true)
  self.channels = self.channels or {}
  for index, chatType in ipairs(monitors_order) do
    local monitor = monitors[chatType]
    self.channels[index] = self.channels[index] or CreateFrame('CheckButton', 'Reported'.. chatType..'Button', self, 'ReportedCheckButton')
    local button = self.channels[index]

    button.label:SetText(monitor.label)
    button:SetPoint(anchor, last, point, x, y)
    button:SetChecked(db.channels[chatType])
    button:SetID(index)
    button.chatType = chatType
    last = button
    anchor, point, x, y = 'TOPLEFT', 'BOTTOMLEFT', 0, -1

    if chatType == 'CHANNEL' then
      channelToggleButton = button

      button.numbers = button.numbers or {}
      local lastChannel = last
      for channel = 1, 10 do
        local from, target, to, x, y
        if channel == 1 then
          from, target, to, x, y= 'TOPLEFT', lastChannel, 'TOPRIGHT', 6 , 0
        else

          from, target, to, x, y= 'TOPLEFT', lastChannel, 'TOPRIGHT', 1, 0
        end

        local chatID = 'CHANNEL' .. channel
        button.numbers[channel] = button.numbers[channel] or CreateFrame('CheckButton', 'Reported'.. chatID..'Button', self, 'ReportedChannelCheckButton')
        local channelButton = button.numbers[channel]

        channelButton:SetID(channel)
        channelButton.chatType = chatType
        channelButton.chatID = chatID
        channelButton:SetChecked(db.channels[chatID])
        channelButton.label:SetText(channel)
        channelButton.label:ClearAllPoints()
        channelButton.label:SetPoint('CENTER')
        channelButton:SetPoint(from, target, to, x, y)
        channelButton:SetChecked(db.channels[chatID])
        lastChannel = channelButton
        channelButton:SetScript('OnClick', ChatChannelButton_OnClick)
        ChannelButton_OnShow(channelButton)
      end
    end
    button:SetScript('OnClick', ChatButton_OnClick)
    ChannelButton_OnShow(button)
  end

  addon.UpdateEntries(self)

  for name, func in pairs(OnClick) do
    if self[name] then
      print('identified region |cFFFF0088', name)
      local region = self[name]
      if region.SetChecked and db[name] then
        region:SetChecked(db[name])
      end
      --func(region)
      region:SetScript('OnClick', func)
    end
  end
  for name, func in pairs(OnValueChanged) do
    if self[name] then
      local region = self[name]
      if region.SetValue and db[name] then
        region:SetValue(db[name])
      end

      func(region)
      region:SetScript('OnValueChanged', func)
    end
  end

  for name, func in pairs(OnEnterPressed) do
    if self[name] and self[name].SetText then
      local text = table.concat(db[name] or {},'\n') or ""
      text = text:gsub('%%s%*', '%*')
      text = text:gsub('%%A', '%"')
      self[name]:SetText(text)
    end
    self[name]:SetScript('OnEnterPressed', func)
  end

  db.dialog = true
end

-- any time the /reported UI is closed
ReportedGSH_OnHide = function(self)
  self:EnableMouse(false)
  self:EnableMouseWheel(false)
  db.dialog = false
end

-- sets the slash command and ensures that shortcut variables point to their things
ReportedGSH_OnLoad = function(self)
  Reported = self
  self.duration, self.expire, self.priority = 0, 0, 0 -- prime the throttle timer
  self:RegisterEvent('ADDON_LOADED')
  self:RegisterForDrag('LeftButton')
  self.Dictionary = self.DictionaryScroll.Dictionary
  _G.SLASH_REPORTED1 = "/reported"
  _G.SlashCmdList['REPORTED'] = addon.Command
end

ReportedGSH_OnEvent = function(self, event, ...)
  if event == 'ADDON_LOADED' then
    if select(1,...)  == 'Reported' then
      addon.Initialize()
      addon.PlayerFlagsChanged()
    end
  elseif event == 'PLAYER_FLAGS_CHANGED'  then
    addon.PlayerFlagsChanged()
  elseif events[event] then
    local guid = select(12,...)
    print('|cFF00FF00', event, guid)
    if guid and guid ~= myGUID then
      if events[event] and db.channels[events[event]] then
        Reported_OnChatMsg(self, event, ...)
      end
    end
  end
end
