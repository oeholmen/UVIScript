--------------------------------------------------------------------------------
-- Probability Sequencer
--------------------------------------------------------------------------------

require "../includes/noteSelector"
require "../includes/resolutionSelector"

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "white"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour
}

local voices = 1
local notesPlaying = {}
local isPlaying = {}
local noteNames = getNoteNames()
local minResolution = resolutions[#resolutions] -- The lowest allowed resolution

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

function startPlaying()
  if #isPlaying > 1 then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if #isPlaying == 0 then
    return
  end
  isPlaying = {}
  notesPlaying = {}
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 30

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 85

local notePanel = Panel("Notes")
notePanel.backgroundColour = "404040"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local resolutionPanel = Panel("Resolutions")
resolutionPanel.backgroundColour = "404040"
resolutionPanel.x = notePanel.x
resolutionPanel.y = notePanel.y + notePanel.height + 5
resolutionPanel.width = 700
resolutionPanel.height = 162

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Drunken Sequencer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 170
label.x = 0

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = channelButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsLabel = settingsPanel:Label("SettingsLabel")
settingsLabel.text = "Settings"
settingsLabel.alpha = 0.75
settingsLabel.fontSize = 15
settingsLabel.width = 350

--- First row ---

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
--noteRandomization.displayName = "Drunk Level"
noteRandomization.displayName = "Note Movement"
noteRandomization.tooltip = "Random note movement amount - a small amount gives small steps between notes"
noteRandomization.size = {163,20}
noteRandomization.x = 5
noteRandomization.y = settingsLabel.y + settingsLabel.height + 5

local noteDirection = settingsPanel:NumBox("NoteDirection", 50, 0, 100, true)
noteDirection.unit = Unit.Percent
noteDirection.textColour = widgetTextColour
noteDirection.backgroundColour = widgetBackgroundColour
noteDirection.displayName = "Direction"
noteDirection.tooltip = "Affect the random note movement by specifying the probability of direction. <50% = more down, >50% = more up, 50% = equal chance"
noteDirection.size = noteRandomization.size
noteDirection.x = noteRandomization.x + noteRandomization.width + 10
noteDirection.y = noteRandomization.y

local randomReset = settingsPanel:OnOffButton("RandomReset", true)
randomReset.enabled = false
randomReset.backgroundColourOff = "#ff084486"
randomReset.backgroundColourOn = "#ff02ACFE"
randomReset.textColourOff = "#ff22FFFF"
randomReset.textColourOn = "#efFFFFFF"
randomReset.displayName = "Random Reset"
randomReset.tooltip = "When direction is biased (above or below 50%), use random reset to start from a random note when highest or lowest note is reached"
randomReset.size = noteDirection.size
randomReset.x = noteDirection.x + noteDirection.width + 10
randomReset.y = noteDirection.y

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 16, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.size = noteDirection.size
voicesInput.x = randomReset.x + randomReset.width + 10
voicesInput.y = randomReset.y

noteDirection.changed = function(self)
  randomReset.enabled = self.value ~= 50
end

--- Second row ---

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Default gate"
gateInput.size = noteDirection.size
gateInput.x = noteRandomization.x
gateInput.y = noteDirection.y + noteDirection.height + 5

local gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateInput.y

local velocityRandomization = settingsPanel:NumBox("VelocityRandomization", 25, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Velocity Rand"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x + velocityInput.width + 10
velocityRandomization.y = gateInput.y

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear notes"
clearNotes.tooltip = "Deselect all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 30
clearNotes.y = 5
clearNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(false)
  end
end

local addNotes = notePanel:Button("AddNotes")
addNotes.displayName = "All notes"
addNotes.tooltip = "Select all notes"
addNotes.persistent = false
addNotes.height = noteLabel.height
addNotes.width = 90
addNotes.x = clearNotes.x + clearNotes.width + 10
addNotes.y = 5
addNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(true)
  end
end

local randomizeNotes = notePanel:Button("RandomizeNotes")
randomizeNotes.displayName = "Randomize notes"
randomizeNotes.tooltip = "Randomize all notes"
randomizeNotes.persistent = false
randomizeNotes.height = noteLabel.height
randomizeNotes.width = 90
randomizeNotes.x = addNotes.x + addNotes.width + 10
randomizeNotes.y = 5
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(getRandomBoolean())
  end
end

createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Resolution Panel
--------------------------------------------------------------------------------

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Resolutions"
resLabel.tooltip = "Set probability for each resolution to be selected"
resLabel.alpha = 0.75
resLabel.fontSize = 15
resLabel.width = 350

local clearResolutions = resolutionPanel:Button("ClearResolutions")
clearResolutions.displayName = "All off"
clearResolutions.tooltip = "Deactivate all resolutions"
clearResolutions.persistent = false
clearResolutions.height = resLabel.height
clearResolutions.width = 90
clearResolutions.x = resolutionPanel.width - (clearResolutions.width * 3) - 30
clearResolutions.y = 5
clearResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(false)
  end
end

local addResolutions = resolutionPanel:Button("AddResolutions")
addResolutions.displayName = "All on"
addResolutions.tooltip = "Activate all resolutions"
addResolutions.persistent = false
addResolutions.height = clearResolutions.height
addResolutions.width = 90
addResolutions.x = clearResolutions.x + clearResolutions.width + 10
addResolutions.y = 5
addResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(true)
  end
end

local randomizeResolutions = resolutionPanel:Button("RandomizeResolutions")
randomizeResolutions.displayName = "Randomize"
randomizeResolutions.tooltip = "Randomize selected resolutions"
randomizeResolutions.persistent = false
randomizeResolutions.height = clearResolutions.height
randomizeResolutions.width = 90
randomizeResolutions.x = addResolutions.x + addResolutions.width + 10
randomizeResolutions.y = 5
randomizeResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    toggleResolutionInputs[i]:setValue(getRandomBoolean())
  end
end

rowCount = createResolutionSelector(resolutionPanel, colours)

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Base Resolution"
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = 106
resLabel.x = 5
resLabel.y = (25 * rowCount) + 10

local baseResolution = resolutionPanel:Menu("BaseResolution", resolutionNames)
baseResolution.displayName = resLabel.text
baseResolution.tooltip = "The duration between resets"
baseResolution.selected = 7
baseResolution.showLabel = false
baseResolution.height = 20
baseResolution.width = 106
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width + 10
baseResolution.y = resLabel.y

local durationRepeatProbabilityInput = resolutionPanel:NumBox("DurationRepeatProbability", 100, 0, 100, true)
durationRepeatProbabilityInput.unit = Unit.Percent
durationRepeatProbabilityInput.textColour = widgetTextColour
durationRepeatProbabilityInput.backgroundColour = widgetBackgroundColour
durationRepeatProbabilityInput.displayName = "Repeat Probability"
durationRepeatProbabilityInput.tooltip = "The probability that a resolution will be repeated"
durationRepeatProbabilityInput.size = {106*1.5+5,20}
durationRepeatProbabilityInput.x = baseResolution.x + baseResolution.width + 10
durationRepeatProbabilityInput.y = baseResolution.y

local durationRepeatDecay = resolutionPanel:NumBox("DurationRepeatDecay", 1, 0.01, 100)
durationRepeatDecay.unit = Unit.Percent
durationRepeatDecay.textColour = widgetTextColour
durationRepeatDecay.backgroundColour = widgetBackgroundColour
durationRepeatDecay.displayName = "Probability Decay"
durationRepeatDecay.tooltip = "The reduction in repeat probability for each iteration of the playing voice"
durationRepeatDecay.size = durationRepeatProbabilityInput.size
durationRepeatDecay.x = durationRepeatProbabilityInput.x + durationRepeatProbabilityInput.width + 10
durationRepeatDecay.y = durationRepeatProbabilityInput.y

local useGlobalProbabilityInput = resolutionPanel:NumBox("UseGlobalProbabilityInput", 50, 0, 100, true)
useGlobalProbabilityInput.enabled = false
useGlobalProbabilityInput.unit = Unit.Percent
useGlobalProbabilityInput.textColour = widgetTextColour
useGlobalProbabilityInput.backgroundColour = widgetBackgroundColour
useGlobalProbabilityInput.displayName = "Link Voices"
useGlobalProbabilityInput.tooltip = "Set the probability that same resolution will be selected for all voices"
useGlobalProbabilityInput.size = {106,20}
useGlobalProbabilityInput.x = durationRepeatDecay.x + durationRepeatDecay.width + 10
useGlobalProbabilityInput.y = durationRepeatDecay.y

voicesInput.changed = function(self)
  voices = self.value
  useGlobalProbabilityInput.enabled = voices > 1
end

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

function generateNote(currentNote)
  local selectedNotes = getSelectedNotes() -- Holds note numbers that are available

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  local noteIndex = 1
  local currentIndex = getIndexFromValue(currentNote, selectedNotes)

  if type(currentNote) == "nil" or type(currentIndex) == "nil" then
    noteIndex = getRandom(#selectedNotes)
    --print("Get random note index", noteIndex)
  else
    local noteDirectionProbability = noteDirection.value
    local goUp = getRandomBoolean(noteDirectionProbability)
    local resetFull = randomReset.value == false
    if noteDirectionProbability == 50 then
      -- Equal up/down
      noteIndex = randomizeValue(currentIndex, 1, #selectedNotes, noteRandomization.value)
      --print("Equal up/down noteIndex/currentIndex", noteIndex, currentIndex)
    elseif goUp and (currentIndex < #selectedNotes or resetFull) then
      if currentIndex == #selectedNotes then
        noteIndex = 1 -- Reset to lowest index
      else
        noteIndex = randomizeValue(currentIndex, currentIndex, #selectedNotes, noteRandomization.value)
      end
      print("Up noteIndex/currentIndex", noteIndex, currentIndex)
    elseif currentIndex > 1 or resetFull then
      if currentIndex == 1 then
        noteIndex = #selectedNotes -- Reset to max index
      else
        noteIndex = randomizeValue(currentIndex, 1, currentIndex, noteRandomization.value)
      end
      print("Down noteIndex/currentIndex", noteIndex, currentIndex)
    else
      noteIndex = getRandom(#selectedNotes)
      print("Random note index", noteIndex)
    end
  end

  return selectedNotes[noteIndex]
end

function getGate()
  return randomizeValue(gateInput.value, 0, 101, gateRandomization.value) / 100
end

function getVelocity()
  return randomizeValue(velocityInput.value, 1, 127, velocityRandomization.value)
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  local currentVoices = 0
  repeat
    --print("sequenceRunner new round")
    if currentVoices ~= voices then
      --print("currentVoices ~= voices", currentVoices, voices)
      isPlaying = {}
      for i=1,voices do
        table.insert(isPlaying, i)
        if i > currentVoices then
          spawn(arpeg, i)
        end
      end
      currentVoices = #isPlaying
    end
    local baseDuration = getResolution(baseResolution.value)
    waitBeat(baseDuration)
  until #isPlaying == 0
end

function arpeg(voice)
  local waitDuration = nil
  local noteToPlay = nil
  local remainingDuration = 0
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  local repeatCounter = 1
  --print("Start playing voice", voice)
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    --print("arpeg gate", gate)
    if remainingDuration == 0 then
      remainingDuration = getResolution(baseResolution.value) -- Reset remaining duration to base duration
      repeatCounter = 1 -- Reset repeat counter - should counter be reset here?
      --print("New round for voice, remainingDuration", voice, remainingDuration)
    end
    local useGlobalProbability = useGlobalProbabilityInput.value
    if useGlobalProbabilityInput.enabled == false then
      useGlobalProbability = 0
    end
    waitDuration, repeatCounter, durationRepeatProbability = getNoteDuration(waitDuration, repeatCounter, durationRepeatProbability, durationRepeatDecay.value, useGlobalProbability)
    if durationRepeatProbability == nil then
      durationRepeatProbability = durationRepeatProbabilityInput.value
    end
    --print("remainingDuration, waitDuration, repeatCounter, durationRepeatProbability", remainingDuration, waitDuration, repeatCounter, durationRepeatProbability)
    if remainingDuration < waitDuration then
      waitDuration = remainingDuration
      --print("waitDuration changed to remaining", waitDuration)
    end
    local gate = getGate()
    if gate > 0 and waitDuration >= minResolution then
      noteToPlay = generateNote(noteToPlay)
    else
      noteToPlay = nil
    end
    if type(noteToPlay) == "number" then
      local velocity = getVelocity()
      local playDuration = beat2ms(waitDuration) * gate
        playNote(noteToPlay, velocity, playDuration, nil, channel)
      --print("playNote noteToPlay, velocity, playDuration, voice", noteToPlay, velocity, playDuration, voice)
      -- Register playing note
      table.insert(notesPlaying, noteToPlay)
    end
    --print("waitBeat(waitDuration)", waitDuration)
    waitBeat(waitDuration)
    if type(noteToPlay) == "number" then
      -- Unregister note
      table.remove(notesPlaying, getIndexFromValue(noteToPlay, notesPlaying))
    end
    remainingDuration = remainingDuration - waitDuration
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end
