--------------------------------------------------------------------------------
-- Probability Sequencer
--------------------------------------------------------------------------------

require "common"

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "white"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

local voices = 1
local notesPlaying = {}
local isPlaying = false
local noteNumberToNoteName = getNoteMapping()
local noteNames = getNoteNames()

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

function startPlaying()
  if isPlaying == true then
    return
  end
  isPlaying = true
  for i=1,voices do
    spawn(arpeg, i)
  end
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  notesPlaying = {}
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 30

local label = sequencerPanel:Label("Label")
label.text = "Probability Sequencer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 180
label.x = 0

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.fillColour = "#dd000061"
channelButton.size = {100,22}
channelButton.x = sequencerPanel.width - (channelButton.width * 3) - 10
channelButton.y = 5

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.fillColour = "#dd000061"
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
playButton.fillColour = "#dd000061"
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
-- Resolution Panel
--------------------------------------------------------------------------------

local resolutions = getResolutions()
local resolutionNames = getResolutionNames()
local resolutionInputs = {}

local resolutionPanel = Panel("Resolutions")
resolutionPanel.backgroundColour = "404040"
resolutionPanel.x = sequencerPanel.x
resolutionPanel.y = sequencerPanel.y + sequencerPanel.height + 5
resolutionPanel.width = 700
resolutionPanel.height = 155

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Resolutions"
resLabel.tooltip = "Set the probability that resolutions will be included when generating resolutions"
resLabel.alpha = 0.75
resLabel.fontSize = 15
resLabel.width = 350

local clearResolutions = resolutionPanel:Button("ClearResolutions")
clearResolutions.displayName = "Clear all"
clearResolutions.tooltip = "Clear all notes"
clearResolutions.persistent = false
clearResolutions.height = resLabel.height
clearResolutions.width = 90
clearResolutions.x = resolutionPanel.width - (clearResolutions.width * 3) - 30
clearResolutions.y = 5
clearResolutions.changed = function()
  for _,v in ipairs(resolutionInputs) do
    v:setValue(0)
  end
end

local addResolutions = resolutionPanel:Button("AddResolutions")
addResolutions.displayName = "Add all"
addResolutions.tooltip = "Add all notes"
addResolutions.persistent = false
addResolutions.height = clearResolutions.height
addResolutions.width = 90
addResolutions.x = clearResolutions.x + clearResolutions.width + 10
addResolutions.y = 5
addResolutions.changed = function()
  for _,v in ipairs(resolutionInputs) do
    v:setValue(100)
  end
end

local randomizeResolutions = resolutionPanel:Button("RandomizeResolutions")
randomizeResolutions.displayName = "Randomize all"
randomizeResolutions.tooltip = "Randomize resolutions"
randomizeResolutions.persistent = false
randomizeResolutions.height = clearResolutions.height
randomizeResolutions.width = 90
randomizeResolutions.x = addResolutions.x + addResolutions.width + 10
randomizeResolutions.y = 5
randomizeResolutions.changed = function()
  for i,v in ipairs(resolutionInputs) do
    if i < 5 or getRandomBoolean() then
      v:setValue(0)
    elseif i < 9 or i > 26 then
      v:setValue(getRandom(0,5))
    elseif i < 17 then
      v:setValue(getRandom(0,25))
    else
      v:setValue(getRandom(0,100))
    end
  end
end

local perRow = 6
local columnCount = 0
local rowCount = 1
for i=1, #resolutions do
  -- Set active defaults
  local value = 0
  if i == 17 then
    value = 50
  elseif i == 20 then
    value = 100
  elseif i == 23 then
    value = 50
  end
  local resolution = resolutionPanel:NumBox("Res" .. i, value, 0, 100, true)
  resolution.unit = Unit.Percent
  resolution.textColour = widgetTextColour
  resolution.backgroundColour = widgetBackgroundColour
  resolution.displayName = resolutionNames[i]
  resolution.tooltip = "Probability of resolution being used"
  resolution.size = {106,20}
  resolution.x = (columnCount * (resolution.width + 10)) + 5
  resolution.y = ((resolution.height + 5) * rowCount) + 5
  table.insert(resolutionInputs, resolution)
  columnCount = columnCount + 1
  if i % perRow == 0 then
    rowCount = rowCount + 1
    columnCount = 0
  end
end

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local notePanel = Panel("Notes")
notePanel.backgroundColour = "404040"
notePanel.x = resolutionPanel.x
notePanel.y = resolutionPanel.y + resolutionPanel.height + 5
notePanel.width = 700
notePanel.height = 105

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 350

local noteInputs = {}

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear all"
clearNotes.tooltip = "Clear all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = resolutionPanel.width - (clearNotes.width * 3) - 30
clearNotes.y = 5
clearNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(0)
  end
end

local addNotes = notePanel:Button("AddNotes")
addNotes.displayName = "Add all"
addNotes.tooltip = "Add all notes"
addNotes.persistent = false
addNotes.height = noteLabel.height
addNotes.width = 90
addNotes.x = clearNotes.x + clearNotes.width + 10
addNotes.y = 5
addNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(100)
  end
end

local randomizeNotes = notePanel:Button("RandomizeNotes")
randomizeNotes.displayName = "Randomize all"
randomizeNotes.tooltip = "Randomize all notes"
randomizeNotes.persistent = false
randomizeNotes.height = noteLabel.height
randomizeNotes.width = 90
randomizeNotes.x = addNotes.x + addNotes.width + 10
randomizeNotes.y = 5
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    if getRandomBoolean() then
      v:setValue(0)
    else
      v:setValue(getRandom(0,100))
    end
  end
end

columnCount = 0
rowCount = 1
for i=1, #noteNames do
  local value = 100
  local note = notePanel:NumBox("Note" .. i, value, 0, 100, true)
  note.unit = Unit.Percent
  note.textColour = widgetTextColour
  note.backgroundColour = widgetBackgroundColour
  note.displayName = noteNames[i]
  note.tooltip = "Probability of note being played"
  note.size = {106,20}
  note.x = (columnCount * (note.width + 10)) + 5
  note.y = ((note.height + 5) * rowCount) + 5
  table.insert(noteInputs, note)
  columnCount = columnCount + 1
  if i % perRow == 0 then
    rowCount = rowCount + 1
    columnCount = 0
  end
end

local generateMinPart = notePanel:NumBox("GenerateMin", 21, 0, 127, true)
generateMinPart.unit = Unit.MidiKey
generateMinPart.textColour = widgetTextColour
generateMinPart.backgroundColour = widgetBackgroundColour
generateMinPart.displayName = "Min Note"
generateMinPart.tooltip = "Lowest note"
generateMinPart.size = {106,20}
generateMinPart.x = 5
generateMinPart.y = (25 * rowCount) + 5

local generateMaxPart = notePanel:NumBox("GenerateMax", 88, 0, 127, true)
generateMaxPart.unit = Unit.MidiKey
generateMaxPart.textColour = widgetTextColour
generateMaxPart.backgroundColour = widgetBackgroundColour
generateMaxPart.displayName = "Max Note"
generateMaxPart.tooltip = "Highest note"
generateMaxPart.size = generateMinPart.size
generateMaxPart.x = generateMinPart.x + generateMinPart.width + 10
generateMaxPart.y = generateMinPart.y

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = notePanel.x
settingsPanel.y = notePanel.y + notePanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 55

local settingsLabel = settingsPanel:Label("SettingsLabel")
settingsLabel.text = "Settings"
settingsLabel.alpha = 0.75
settingsLabel.fontSize = 15
settingsLabel.width = 350

local durationRepeatDecay = settingsPanel:NumBox("DurationRepeatDecay", 1, 1, 100, true)
durationRepeatDecay.unit = Unit.Percent
durationRepeatDecay.textColour = widgetTextColour
durationRepeatDecay.backgroundColour = widgetBackgroundColour
durationRepeatDecay.displayName = "Repeat Decay"
durationRepeatDecay.tooltip = "The reduction in repeat probability for each iteration of the playing voice"
durationRepeatDecay.size = {106,20}
durationRepeatDecay.x = 5
durationRepeatDecay.y = settingsLabel.y + settingsLabel.height + 5

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 16, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing (must restart sequencer to take effect)"
voicesInput.size = durationRepeatDecay.size
voicesInput.x = durationRepeatDecay.x + durationRepeatDecay.width + 10
voicesInput.y = durationRepeatDecay.y
voicesInput.changed = function(self)
  voices = self.value
end

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Default gate"
gateInput.size = voicesInput.size
gateInput.x = voicesInput.x + voicesInput.width + 10
gateInput.y = durationRepeatDecay.y

local gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = durationRepeatDecay.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = durationRepeatDecay.y

local velocityRandomization = settingsPanel:NumBox("VelocityRandomization", 25, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Vel Rand"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x + velocityInput.width + 10
velocityRandomization.y = durationRepeatDecay.y

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Rand"
noteRandomization.tooltip = "Note shift randomization amount - a small amount gives small jumps between notes"
noteRandomization.size = velocityRandomization.size
noteRandomization.x = velocityRandomization.x + velocityRandomization.width + 10
noteRandomization.y = durationRepeatDecay.y

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

function getNoteDuration(currentDuration, durationRepeatProbability)
  if type(currentDuration) == "number" then
    -- Repeat same duration - use probability decay (in percent)
    local durationRepeatProbabilityDecay = durationRepeatProbability * (durationRepeatDecay.value / 100)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    if getRandomBoolean(durationRepeatProbability) then
      return currentDuration, durationRepeatProbability
    end
  end
  local activeResolutions = {} -- All active
  local selectedResolutions = {} -- All selected
  for i,v in ipairs(resolutionInputs) do
    if v.value > 0 then
      table.insert(activeResolutions, i)
      if getRandomBoolean(v.value) == true then
        table.insert(selectedResolutions, i)
      end
    end
  end

  if #selectedResolutions == 0 then
    selectedResolutions = activeResolutions
  end

  if #selectedResolutions == 0 then
    -- Add some defaults if no resolutions where activated
    table.insert(selectedResolutions, 17)
    table.insert(selectedResolutions, 20)
    table.insert(selectedResolutions, 23)
  end

  local resolutionIndex = selectedResolutions[getRandom(#selectedResolutions)]
  print("resolutionIndex, #selectedResolutions", resolutionIndex, #selectedResolutions)
  return getResolution(resolutionIndex), 100
end

function getActiveNotes()
  local allNotes = {} -- All notes
  local activeNotes = {} -- All active notes
  local selectedNotes = {} -- All selected notes
  for i,v in ipairs(noteInputs) do
    table.insert(allNotes, noteNames[i])
    if v.value > 0 then
      table.insert(activeNotes, noteNames[i])
      if getRandomBoolean(v.value) == true then
        table.insert(selectedNotes, noteNames[i])
      end
    end
  end

  if #selectedNotes == 0 then
    selectedNotes = activeNotes
  end

  if #selectedNotes == 0 then
    selectedNotes = allNotes
  end

  return selectedNotes
end

function getNoteToPlay(currentNote)
  local min = math.min(generateMinPart.value, generateMaxPart.value)
  local max = math.max(generateMinPart.value, generateMaxPart.value)
  if min == max then
    min = generateMinPart.min
    max = generateMaxPart.max
  end
  if type(currentNote) == "nil" then
    currentNote = getRandom(min, max)
  end
  local activeNotes = getActiveNotes()
  repeat
    currentNote = randomizeValue(currentNote, min, max, noteRandomization.value)
  until tableIncludes(notesPlaying, currentNote) == false and tableIncludes(activeNotes, noteNumberToNoteName[currentNote+1])
  print("getNoteToPlay noteNumber, noteName", currentNote, noteNumberToNoteName[currentNote+1])
  return currentNote
end

function getGate()
  return randomizeValue(gateInput.value, 0, 100, gateRandomization.value) / 100
end

function getVelocity()
  return randomizeValue(velocityInput.value, 1, 127, velocityRandomization.value)
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(voice)
  local waitDuration = nil
  local durationRepeatProbability = 100
  local noteToPlay = nil
  while isPlaying == true do
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    -- Find a random resolution
    local gate = getGate()
    print("arpeg gate", gate)
    waitDuration, durationRepeatProbability = getNoteDuration(waitDuration, durationRepeatProbability)
    print("arpeg waitDuration", waitDuration)
    if gate > 0 then
      local velocity = getVelocity()
      print("arpeg velocity", velocity)
      local playDuration = beat2ms(waitDuration) * gate
      print("arpeg playDuration", playDuration)
      noteToPlay = getNoteToPlay(noteToPlay)
      playNote(noteToPlay, velocity, playDuration, nil, channel)
      -- Register playing note
      table.insert(notesPlaying, noteToPlay)
    end
    waitBeat(waitDuration)
    if gate > 0 then
      -- Unregister note
      table.remove(notesPlaying, getIndexFromValue(noteToPlay, notesPlaying))
    end
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
