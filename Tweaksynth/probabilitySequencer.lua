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
setBackgroundColour(backgroundColour)

local voices = 1
local octaves = 9
local notesPlaying = {}
local isPlaying = {}
local noteNumberToNoteName = getNoteMapping()
local noteNames = getNoteNames()
local globalResolution = nil -- Holds the global resolution for all voices

--------------------------------------------------------------------------------
-- Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,2,1}, -- Harmonic minor
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2,2,2,1,2,1,2}, -- Acoustic
  {2,1,2,1,1,3,2}, -- Blues
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {2}, -- Whole tone scale
  {1}, -- Chromatic - Keep last!
}

local scaleNames = {
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Harmonic minor",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Acoustic",
  "Blues",
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Whole tone",
  "Chromatic", -- Keep last!
}

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
settingsPanel.height = 55

local notePanel = Panel("Notes")
notePanel.backgroundColour = "404040"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 120

local resolutionPanel = Panel("Resolutions")
resolutionPanel.backgroundColour = "404040"
resolutionPanel.x = notePanel.x
resolutionPanel.y = notePanel.y + notePanel.height + 5
resolutionPanel.width = 700
resolutionPanel.height = 180

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

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
-- Resolution Panel
--------------------------------------------------------------------------------

local resolutions = getResolutions()
local resolutionNames = getResolutionNames()
local resolutionInputs = {}

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
    if v.enabled then
      v:setValue(100)
    else
      v:setValue(0)
    end
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
    if i < 5 or v.enabled == false or getRandomBoolean() then
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
  if i == 11 then
    value = 15
  elseif i == 14 then
    value = 25
  elseif i == 17 then
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

local resLabel = resolutionPanel:Label("ResolutionsLabel")
resLabel.text = "Base Resolution"
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = 106
resLabel.x = 5
resLabel.y = (25 * rowCount) + 5

local baseResolution = resolutionPanel:Menu("BaseResolution", getResolutionNames())
baseResolution.displayName = resLabel.text
baseResolution.tooltip = "The duration between resets"
baseResolution.selected = 9
baseResolution.showLabel = false
baseResolution.height = 20
baseResolution.width = 106
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width + 10
baseResolution.y = resLabel.y
baseResolution.changed = function(self)
  for i,v in ipairs(resolutionInputs) do
    v.enabled = i >= self.value
  end
end
baseResolution:changed()

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
useGlobalProbabilityInput.unit = Unit.Percent
useGlobalProbabilityInput.textColour = widgetTextColour
useGlobalProbabilityInput.backgroundColour = widgetBackgroundColour
useGlobalProbabilityInput.displayName = "Global"
useGlobalProbabilityInput.tooltip = "Set the probability that same resolution will be selected for all voices"
useGlobalProbabilityInput.size = {106,20}
useGlobalProbabilityInput.x = durationRepeatDecay.x + durationRepeatDecay.width + 10
useGlobalProbabilityInput.y = durationRepeatDecay.y

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 60

local noteInputs = {}
local octaveProbabilityInputs = {}

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
    v:setValue(false)
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
    v:setValue(true)
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
    v:setValue(getRandomBoolean())
  end
end

columnCount = 0
for i=1,#noteNames do
  local note = notePanel:OnOffButton("Note" .. i, true)
  note.backgroundColourOff = "#ff084486"
  note.backgroundColourOn = "#ff02ACFE"
  note.textColourOff = "#ff22FFFF"
  note.textColourOn = "#efFFFFFF"
  note.displayName = noteNames[i]
  note.tooltip = "Probability of note being played"
  note.size = {51,30}
  note.x = (columnCount * (note.width + 6.6)) + 5
  note.y = noteLabel.y + noteLabel.height + 5
  table.insert(noteInputs, note)
  columnCount = columnCount + 1
end

columnCount = 0

local rising = true
local numStepsUpDown = math.floor(octaves / 2)
local changePerStep = 100 / numStepsUpDown
local startValue = 0
for i=1,octaves do
  local octaveLabel = notePanel:Label("OctaveLabel")
  octaveLabel.text = "Oct " .. i - 2
  octaveLabel.alpha = 0.75
  octaveLabel.fontSize = 15
  octaveLabel.width = 670 / octaves
  octaveLabel.height = 22
  octaveLabel.x = ((octaveLabel.width+(22/octaves)) * columnCount) + 5
  octaveLabel.y = 70

  local octaveProbabilityInput = notePanel:NumBox("OctaveProbability" .. i, startValue, 0, 100, true)
  octaveProbabilityInput.unit = Unit.Percent
  octaveProbabilityInput.textColour = widgetTextColour
  octaveProbabilityInput.backgroundColour = widgetBackgroundColour
  octaveProbabilityInput.showLabel = false
  octaveProbabilityInput.tooltip = "Set the probability that octave " .. i - 2 .. " will be available when generating notes to play"
  octaveProbabilityInput.width = octaveLabel.width
  octaveProbabilityInput.height = octaveLabel.height
  octaveProbabilityInput.x = octaveLabel.x
  octaveProbabilityInput.y = octaveLabel.y + octaveLabel.height

  table.insert(octaveProbabilityInputs, octaveProbabilityInput)

  if rising then
    startValue = startValue + changePerStep
    if startValue >= 100 then
      rising = false
    end
  else
    startValue = startValue - changePerStep
  end

  columnCount = columnCount + 1
end

local generateKey = notePanel:Menu("GenerateKey", noteNames)
generateKey.tooltip = "Key"
generateKey.showLabel = false
generateKey.backgroundColour = menuBackgroundColour
generateKey.textColour = widgetTextColour
generateKey.arrowColour = menuArrowColour
generateKey.outlineColour = menuOutlineColour
generateKey.size = {106,20}
generateKey.x = noteLabel.x + noteLabel.width + 10
generateKey.y = noteLabel.y
generateKey.changed = function(self)
  setScale()
end

local generateScale = notePanel:Menu("GenerateScale", scaleNames)
generateScale.selected = #scaleNames
generateScale.tooltip = "Scale"
generateScale.showLabel = false
generateScale.backgroundColour = menuBackgroundColour
generateScale.textColour = widgetTextColour
generateScale.arrowColour = menuArrowColour
generateScale.outlineColour = menuOutlineColour
generateScale.size = generateKey.size
generateScale.x = generateKey.x + generateKey.width + 10
generateScale.y = generateKey.y
generateScale.changed = function(self)
  setScale()
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsLabel = settingsPanel:Label("SettingsLabel")
settingsLabel.text = "Settings"
settingsLabel.alpha = 0.75
settingsLabel.fontSize = 15
settingsLabel.width = 350

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 16, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.size = {106,20}
voicesInput.x = 5
voicesInput.y = settingsLabel.y + settingsLabel.height + 5
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
gateInput.y = voicesInput.y

local gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = voicesInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = voicesInput.y

local velocityRandomization = settingsPanel:NumBox("VelocityRandomization", 25, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Vel Rand"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x + velocityInput.width + 10
velocityRandomization.y = voicesInput.y

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Move"
noteRandomization.tooltip = "Note movement randomization amount - a small amount gives small steps between notes"
noteRandomization.size = velocityRandomization.size
noteRandomization.x = velocityRandomization.x + velocityRandomization.width + 10
noteRandomization.y = voicesInput.y

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

function setScale()
  local scaleDefinition = scaleDefinitions[generateScale.value]
  local rootNote = generateKey.value - 1 -- Root note
  local scale = createScale(scaleDefinition, rootNote)
  for i,v in ipairs(noteInputs) do
    local noteNumber = i + 11 -- Check note in octave above
    v:setValue(tableIncludes(scale, noteNumber))
  end
end

function getNoteDuration(currentDuration, durationRepeatProbability)
  local activeResolutions = {} -- All active
  local selectedResolutions = {} -- All selected
  for i,v in ipairs(resolutionInputs) do
    if v.enabled and v.value > 0 then
      table.insert(activeResolutions, i)
      if getRandomBoolean(v.value) == true then
        table.insert(selectedResolutions, i)
      end
    end
  end

  if #selectedResolutions == 0 then
    selectedResolutions = activeResolutions
  end

  -- Failsafe in case no resolutions are activated
  if #selectedResolutions == 0 then
    if type(globalResolution) == "number" then
      return globalResolution, durationRepeatProbabilityInput.value
    else
      return getResolution(17), durationRepeatProbabilityInput.value
    end
  end

  -- Check resolution repeat
  local useGlobalProbability = useGlobalProbabilityInput.value
  if type(globalResolution) == "number" and getRandomBoolean(useGlobalProbability) then
    currentDuration = globalResolution
  end
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * (durationRepeatDecay.value / 100)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    local resolutionIndex = getIndexFromValue(currentDuration, resolutions)
    if tableIncludes(selectedResolutions, resolutionIndex) and getRandomBoolean(durationRepeatProbability) then
      return currentDuration, durationRepeatProbability
    end
  end

  -- Remove last known resolution
  if type(currentDuration) == "number" and #selectedResolutions > 1 then
    table.remove(selectedResolutions, getIndexFromValue(currentDuration, selectedResolutions))
  end

  if #selectedResolutions == 1 then
    globalResolution = getResolution(selectedResolutions[1])
  else
    globalResolution = getResolution(selectedResolutions[getRandom(#selectedResolutions)])
  end

  return globalResolution, durationRepeatProbabilityInput.value
end

function getNoteToPlay(currentNote)
  local selectedNotes = {} -- Holds note numbers that are available
  for octaveIndex=1,octaves do
    local octaveProbability = octaveProbabilityInputs[octaveIndex].value
    if octaveProbability > 0 then
      for i,v in ipairs(noteInputs) do
        -- Check if note should be added for this octave
        if v.value and getRandomBoolean(octaveProbability) then
          local noteNumber = i - 1 -- Base note
          noteNumber = noteNumber + (12 * octaveIndex) -- Set octave
          if tableIncludes(notesPlaying, noteNumber) == false then
            table.insert(selectedNotes, noteNumber)
            --print("Note added: noteNumber/name", noteNumber, noteNumberToNoteName[noteNumber+1])
          end
        end
      end
    end
  end

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  local noteIndex = 1

  if type(currentNote) == "nil" or tableIncludes(selectedNotes, currentNote) == false then
    noteIndex = getRandom(#selectedNotes)
    --print("Get random note index", noteIndex)
  else
    local currentIndex = getIndexFromValue(currentNote, selectedNotes)
    noteIndex = randomizeValue(currentIndex, 1, #selectedNotes, noteRandomization.value)
    --print("Get from noteIndex/currentIndex", noteIndex, currentIndex)
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
  local baseDuration = 0
  local remainingDuration = 0
  local durationRepeatProbability = durationRepeatProbabilityInput.value
  --print("Start playing voice", voice)
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice
    end
    --print("arpeg gate", gate)
    if remainingDuration == 0 then
      --waitDuration = nil -- Reset duration?
      baseDuration = getResolution(baseResolution.value)
      remainingDuration = baseDuration -- RESET to base
      print("New round voice/baseDuration", voice, baseDuration)
      --randomizeResolutions:changed() -- Param
      --randomizeNotes:changed() -- Param
    end
    waitDuration, durationRepeatProbability = getNoteDuration(waitDuration, durationRepeatProbability)
    --print("remainingDuration, waitDuration", remainingDuration, waitDuration)
    if remainingDuration < waitDuration then
      waitDuration = remainingDuration
      --print("waitDuration changed to remaining", waitDuration)
    end
    local gate = getGate()
    if gate > 0 then
      noteToPlay = getNoteToPlay(noteToPlay)
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
