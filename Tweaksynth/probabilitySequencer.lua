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

local voices = 1
local octaves = 9
local notesPlaying = {}
local isPlaying = {}
local noteNumberToNoteName = getNoteMapping()
local noteNames = getNoteNames()
local globalResolution = nil -- Holds the global resolution for all voices
local minResolution = 0.03125 -- The lowest possible resolution

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

local noteInputs = {}
local noteProbabilityInputs = {}
local octaveInputs = {}
local octaveProbabilityInputs = {}

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

columnCount = 0
for i=1,#noteNames do
  local note = notePanel:OnOffButton("Note" .. i, true)
  note.backgroundColourOff = "#ff084486"
  note.backgroundColourOn = "#ff02ACFE"
  note.textColourOff = "#ff22FFFF"
  note.textColourOn = "#efFFFFFF"
  note.displayName = noteNames[i]
  note.tooltip = "Toggle note on/off"
  note.size = {51,30}
  note.x = (columnCount * (note.width + 6.6)) + 5
  note.y = noteLabel.y + noteLabel.height + 5

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.unit = Unit.Percent
  noteProbability.textColour = widgetTextColour
  noteProbability.backgroundColour = widgetBackgroundColour
  noteProbability.showLabel = false
  noteProbability.tooltip = "Set the probability that '" .. noteNames[i] .. "' will be available when generating notes to play"
  noteProbability.width = note.width
  noteProbability.height = 22
  noteProbability.x = note.x
  noteProbability.y = note.y + note.height + 1

  table.insert(noteInputs, note)
  table.insert(noteProbabilityInputs, noteProbability)

  columnCount = columnCount + 1
end

columnCount = 0

local rising = true
local numStepsUpDown = math.floor(octaves / 2)
local changePerStep = 100 / numStepsUpDown
local startValue = 0
for i=1,octaves do
  local octave = notePanel:OnOffButton("Octave" .. i, (startValue > 50))
  octave.backgroundColourOff = "#ff084486"
  octave.backgroundColourOn = "#ff02ACFE"
  octave.textColourOff = "#ff22FFFF"
  octave.textColourOn = "#efFFFFFF"
  octave.displayName = "Oct " .. i - 2
  octave.tooltip = "Toggle octave on/off"
  octave.width = (636 / octaves)
  octave.height = 30
  octave.x = (columnCount * (octave.width + 6.9)) + 5
  octave.y = 90

  local octaveProbabilityInput = notePanel:NumBox("OctaveProbability" .. i, 100, 0, 100, true)
  octaveProbabilityInput.unit = Unit.Percent
  octaveProbabilityInput.textColour = widgetTextColour
  octaveProbabilityInput.backgroundColour = widgetBackgroundColour
  octaveProbabilityInput.showLabel = false
  octaveProbabilityInput.tooltip = "Set the probability that octave " .. i - 2 .. " will be available when generating notes to play"
  octaveProbabilityInput.width = octave.width
  octaveProbabilityInput.height = 22
  octaveProbabilityInput.x = octave.x
  octaveProbabilityInput.y = octave.y + octave.height

  table.insert(octaveInputs, octave)
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
generateKey.tooltip = "Set selected notes from key"
generateKey.showLabel = false
generateKey.backgroundColour = menuBackgroundColour
generateKey.textColour = widgetTextColour
generateKey.arrowColour = menuArrowColour
generateKey.outlineColour = menuOutlineColour
generateKey.size = {102,20}
generateKey.x = noteLabel.x + noteLabel.width + 10
generateKey.y = noteLabel.y
generateKey.changed = function(self)
  setScale()
end

local generateScale = notePanel:Menu("GenerateScale", scaleNames)
generateScale.selected = #scaleNames
generateScale.tooltip = "Set selected notes from scale"
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
-- Resolution Panel
--------------------------------------------------------------------------------

local divOpt = {}
for i=1,128 do
  table.insert(divOpt, "/ " .. i)
end

local resolutions = getResolutions()
local resolutionNames = getResolutionNames()
local resolutionInputs = {}
local toggleResolutionInputs = {}
local resolutionProbabilityInputs = {}
local minRepeats = {}
local divisions = {}

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

local offset = 5
local perRow = 3
local columnCount = 0
local rowCount = 1
for i=1,12 do
  local toggleResolution = resolutionPanel:OnOffButton("ToggleResolution" .. i, (i == 1))
  toggleResolution.backgroundColourOff = "#ff084486"
  toggleResolution.backgroundColourOn = "#ff02ACFE"
  toggleResolution.textColourOff = "#ff22FFFF"
  toggleResolution.textColourOn = "#efFFFFFF"
  toggleResolution.displayName = " "
  toggleResolution.tooltip = "Toggle resolution on/off"
  toggleResolution.size = {23,20}
  toggleResolution.x = (columnCount * 232) + 5
  toggleResolution.y = ((toggleResolution.height + 5) * rowCount) + 5

  local resolution = resolutionPanel:Menu("Resolution" .. i, resolutionNames)
  if i == 1 then
    resolution.selected = 20
  elseif i == 2 then
    resolution.selected = 23
  elseif i == 6 then
    resolution.selected = 22
  elseif i == 7 then
    resolution.selected = 18
  elseif i > 9 then
    resolution.selected = i - 3
  else
    resolution.selected = offset
  end
  offset = offset + 3
  resolution.showLabel = false
  resolution.backgroundColour = widgetBackgroundColour
  resolution.textColour = widgetTextColour
  resolution.arrowColour = menuArrowColour
  resolution.outlineColour = menuOutlineColour
  resolution.tooltip = "Select resolution"
  resolution.size = {70,20}
  resolution.x = toggleResolution.x + toggleResolution.width + 1
  resolution.y = toggleResolution.y

  local resolutionProbability = resolutionPanel:NumBox("ResolutionProbability" .. i, 100, 0, 100, true)
  resolutionProbability.unit = Unit.Percent
  resolutionProbability.textColour = widgetTextColour
  resolutionProbability.backgroundColour = widgetBackgroundColour
  resolutionProbability.showLabel = false
  resolutionProbability.tooltip = "Probability of resolution being used"
  resolutionProbability.size = {42,20}
  resolutionProbability.x = resolution.x + resolution.width + 1
  resolutionProbability.y = resolution.y

  local minRepeatValue = 1
  if i == 6 then
    minRepeatValue = 3
  end
  local minRepeat = resolutionPanel:NumBox("MinRepeat" .. i, minRepeatValue, 1, 128, true)
  minRepeat.textColour = widgetTextColour
  minRepeat.backgroundColour = widgetBackgroundColour
  minRepeat.showLabel = false
  minRepeat.tooltip = "Set the minimum number of repeats for this resolution"
  minRepeat.size = {36,20}
  minRepeat.x = resolutionProbability.x + resolutionProbability.width + 1
  minRepeat.y = resolutionProbability.y

  local division = resolutionPanel:Menu("Division" .. i, divOpt)
  division.showLabel = false
  division.backgroundColour = widgetBackgroundColour
  division.textColour = widgetTextColour
  division.arrowColour = menuArrowColour
  division.outlineColour = menuOutlineColour
  division.tooltip = "Set a division for this resolution"
  division.size = {45,20}
  division.x = minRepeat.x + minRepeat.width + 1
  division.y = minRepeat.y

  table.insert(toggleResolutionInputs, toggleResolution)
  table.insert(resolutionInputs, resolution)
  table.insert(resolutionProbabilityInputs, resolutionProbability)
  table.insert(minRepeats, minRepeat)
  table.insert(divisions, division)

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

function setScale()
  local scaleDefinition = scaleDefinitions[generateScale.value]
  local rootNote = generateKey.value - 1 -- Root note
  local scale = createScale(scaleDefinition, rootNote)
  for i,v in ipairs(noteInputs) do
    local noteNumber = i + 11 -- Check note in octave above
    v:setValue(tableIncludes(scale, noteNumber))
  end
end

function adjustForDuration(decay, currentDuration)
  -- TODO Param for adjusting decay
  -- TODO Increase decay for longer durations - less repetition of longer notes
  local middleIndex = 17 -- 1/4 (1 beat) -- TODO Param?
  local middleResolution = resolutions[middleIndex]
  local increase = 0
  if currentDuration > middleResolution and tableIncludes(resolutions, currentDuration) then
    -- Note is longer than 1/4 - increase decay
    local resolutionIndex = getIndexFromValue(currentDuration, resolutions)
    local percentIncrease = (middleIndex * resolutionIndex) / 100
    local factor = decay / percentIncrease
    increase = decay * (factor / 100)
    print("Decay adjusted decay, increase", decay, increase)
  end
  return math.min(100, (decay + increase)) / 100
end

function getNoteDuration(currentDuration, repeatCounter, durationRepeatProbability)
  --print("repeatCounter", repeatCounter)
  repeatCounter = repeatCounter - 1
  -- Repeat the current duration until repeat counter reaches zero
  if repeatCounter > 0 then
    --print("Repeating duration", repeatCounter, currentDuration)
    return currentDuration, repeatCounter, durationRepeatProbability
  end

  -- Find available resolutions
  local availableResolutions = {}
  local selectedDivisionsAndRepeats = {}
  for i,v in ipairs(resolutionInputs) do
    local resolutionActive = toggleResolutionInputs[i].value
    if resolutionActive and getRandomBoolean(resolutionProbabilityInputs[i].value) then
      table.insert(availableResolutions, v.value)
      table.insert(selectedDivisionsAndRepeats, {division=divisions[i].value,repeats=minRepeats[i].value})
    end
  end

  --print("#availableResolutions", #availableResolutions)

  -- Check if we should use the global resolution
  local useGlobalProbability = useGlobalProbabilityInput.value
  if type(globalResolution) == "number" and useGlobalProbabilityInput.enabled and getRandomBoolean(useGlobalProbability) then
    currentDuration = globalResolution
    --print("Set currentDuration from globalResolution", currentDuration)
    useGlobalProbability = true
  else
    useGlobalProbability = false
  end

  -- Failsafe in case no resolutions are selected
  if #availableResolutions == 0 then
    if type(globalResolution) == "number" then
      return globalResolution, 1, durationRepeatProbabilityInput.value
    else
      return getResolution(17), 1, durationRepeatProbabilityInput.value
    end
  end

  local resolutionIndex = nil
  if tableIncludes(resolutions, currentDuration) then
    resolutionIndex = getIndexFromValue(currentDuration, resolutions)
  end

  -- Check resolution repeat by probability
  if type(currentDuration) == "number" then
    local durationRepeatProbabilityDecay = durationRepeatProbability * adjustForDuration(durationRepeatDecay.value, currentDuration)
    durationRepeatProbability = durationRepeatProbability - durationRepeatProbabilityDecay
    -- Repeat only if current resolution is still available
    if tableIncludes(availableResolutions, resolutionIndex) and getRandomBoolean(durationRepeatProbability) then
      --print("Repeating current duration", currentDuration)
      return currentDuration, 1, durationRepeatProbability
    end
  end

  -- Remove last known resolution if repeat was not selected
  if type(resolutionIndex) == "number" and type(currentDuration) == "number" and #availableResolutions > 1 then
    local removeIndex = getIndexFromValue(resolutionIndex, availableResolutions)
    table.remove(availableResolutions, removeIndex)
    table.remove(selectedDivisionsAndRepeats, removeIndex)
    --print("Remove current duration to avoid repeat", removeIndex)
  end

  -- Remove global resolution if it was not used?
  --[[ if useGlobalProbabilityInput.enabled and useGlobalProbability == false and type(globalResolution) == "number" and #availableResolutions > 1 then
    local removeIndex = getIndexFromValue(getIndexFromValue(globalResolution, resolutions), availableResolutions)
    table.remove(availableResolutions, removeIndex)
    table.remove(selectedDivisionsAndRepeats, removeIndex)
    print("Remove global duration if not selected", removeIndex)
  end ]]

  local index = 1
  if #availableResolutions > 1 then
    index = getRandom(#availableResolutions)
    --print("Index selected by random", index)
  end

  -- Get resolution and divide by the selected division - not lower than system min res (1/128)
  globalResolution = math.max(minResolution, (getResolution(availableResolutions[index]) / selectedDivisionsAndRepeats[index].division))

  return globalResolution, selectedDivisionsAndRepeats[index].repeats, durationRepeatProbabilityInput.value
end

function getNoteToPlay(currentNote)
  local selectedNotes = {} -- Holds note numbers that are available
  for octaveIndex,octave in ipairs(octaveInputs) do
    local octaveProbability = octaveProbabilityInputs[octaveIndex].value
    if octave.value and octaveProbability > 0 then
      for i,v in ipairs(noteInputs) do
        -- Check if note should be added for this octave
        local noteProbability = noteProbabilityInputs[i].value
        if v.value and getRandomBoolean(noteProbability) and getRandomBoolean(octaveProbability) then
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
    waitDuration, repeatCounter, durationRepeatProbability = getNoteDuration(waitDuration, repeatCounter, durationRepeatProbability)
    --print("remainingDuration, waitDuration, repeatCounter, durationRepeatProbability", remainingDuration, waitDuration, repeatCounter, durationRepeatProbability)
    if remainingDuration < waitDuration then
      waitDuration = remainingDuration
      --print("waitDuration changed to remaining", waitDuration)
    end
    local gate = getGate()
    if gate > 0 and waitDuration >= minResolution then
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
