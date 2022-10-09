--------------------------------------------------------------------------------
-- Generative chorder and sequencer
--------------------------------------------------------------------------------

require "../includes/generative"

local backgroundColour = "6c6c6c" -- Light or Dark
local menuBackgroundColour = "01011F"
local widgetBackgroundColour = menuBackgroundColour -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuArrowColour = "66" .. labelTextColour
local labelBackgoundColour = "111D5E"
local menuOutlineColour = "5f" .. widgetTextColour
local sliderColour = "5FB5FF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local colours = {
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
  backgroundColour = backgroundColour
}

local isPlaying = false
local partToStepMap = {1} -- Holds the starting step for each part
local totalNumSteps = 8
local paramsPerPart = {}
local partSelect = {}
local numParts = 1

-- *** NOTE *** The chord definitions use steps in the selected scale, not semitones.
-- 2 means two steps up the scale: C-E for a C major scale. A-C for an A minor scale.
local chordDefinitions = {
  {2,2,3}, -- Builds triads
  {2,2,2,1}, -- Builds 7th chords
  {3,1,3}, -- Builds supended chords
  {2,2,1,2}, -- Builds 6th chords
  {2,2,2,2,6}, -- Builds 7th and 9th chords depending on polyphony
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
  {4,3}, -- Builds open chords (no3)
  {1,2,1,2,1}, -- Builds supended chords including 7th and 9ths
  --{3}, -- Builds chords using only fourths
  --{Randomize},
}

local noteDisplay = {} -- Holds the widgets that displays the notes being played
local maxVoices = 16 -- Max number of oplyphonic voices
local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
local noteNumberToNoteName = getNoteMapping()
local scaleDefinitions = getScaleDefinitions()
local scaleNames = getScaleNames()

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

-- Use the selected chord definition to find the index for the next note in the chord
function getNextScaleIndex(note, scale, chordDefinition, inversionIndex)
  local index = getIndexFromValue(note, scale)
  print("getNextScaleIndex #chordDefinition/inversionIndex", #chordDefinition, inversionIndex)
  local increment = chordDefinition[inversionIndex]
  if type(index) == "nil" then
    index = 0
    print("!!!Note not found in scale!!!")
  end
  return index + increment
end

function notesInclude(notesTable, note)
  for _,v in pairs(notesTable) do
    if v.note == note then
      --print("Note already included", note)
      return true
    end
  end
  return false
end

function hasNoteWithinMonoLimit(notesTable, partPos)
  local monoLimit = paramsPerPart[partPos].monoLimit.value
  for _,v in pairs(notesTable) do
    if v.note <= monoLimit then
      --print("Note already added below limit", note)
      return true
    end
  end
  return false
end

function getVelocity(part, step, skipRandomize)
  local velocityInput = paramsPerPart[part].velocityInput
  local velocity = velocityInput.value

  if skipRandomize == true then
    return velocity
  end

  -- Randomize velocity
  return randomizeValue(velocity, velocityInput.min, velocityInput.max, paramsPerPart[part].velRandomization.value)
end

function getGate(part, step, skipRandomize)
  local gateInput = paramsPerPart[part].gateInput
  local gate = gateInput.value

  if skipRandomize == true then
    return gate
  end

  -- Randomize velocity
  return randomizeValue(gate, gateInput.min, gateInput.max, paramsPerPart[part].velRandomization.value)
end

--------------------------------------------------------------------------------
-- Panels
--------------------------------------------------------------------------------

local tableWidth = 700

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = tableWidth
sequencerPanel.height = 300

local notePanel = Panel("Notes")
notePanel.backgroundColour = backgroundColour
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height + 5
notePanel.width = tableWidth
notePanel.height = 150

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NoteLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50
noteLabel.height = 20
noteLabel.y = 0

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear notes"
clearNotes.tooltip = "Deselect all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 30
clearNotes.y = noteLabel.y
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
addNotes.y = noteLabel.y
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
randomizeNotes.y = noteLabel.y
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(getRandomBoolean())
  end
end

createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Generative Chorder"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {170,25}

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = backgroundColourOff
channelButton.backgroundColourOn = backgroundColourOn
channelButton.textColourOff = textColourOff
channelButton.textColourOn = textColourOn
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.fillColour = "#dd000061"
channelButton.size = {90,22}
channelButton.x = 324
channelButton.y = 0

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = backgroundColourOff
focusButton.backgroundColourOn = backgroundColourOn
focusButton.textColourOff = textColourOff
focusButton.textColourOn = textColourOn
focusButton.displayName = "Focus Part"
focusButton.tooltip = "When focus is active, only the part selected for editing is shown and played"
focusButton.fillColour = "#dd000061"
focusButton.size = channelButton.size
focusButton.x = channelButton.x + channelButton.width + 5
focusButton.y = 0
focusButton.changed = function(self)
  setTableWidths()
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = backgroundColourOff
autoplayButton.backgroundColourOn = backgroundColourOn
autoplayButton.textColourOff = textColourOff
autoplayButton.textColourOn = textColourOn
autoplayButton.fillColour = "#dd000061"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = focusButton.x + focusButton.width + 5
autoplayButton.y = 0

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = backgroundColourOff
playButton.backgroundColourOn = backgroundColourOn
playButton.textColourOff = textColourOff
playButton.textColourOn = textColourOn
playButton.fillColour = "#dd000061"
playButton.displayName = "Play"
playButton.size = channelButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = 0
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = widgetTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit part"
editPartMenu.showLabel = false
editPartMenu.y = 65
editPartMenu.x = 0
editPartMenu.width = 108
editPartMenu.height = 20
editPartMenu.changed = function(self)
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i

    if isVisible then
      for i,w in ipairs(noteDisplay) do
        w.enabled = maxVoices - v.polyphony.value <= maxVoices - i
      end
      v.partsTable.backgroundColour = "#cc33cc44"
    elseif i % 2 == 0 then
      v.partsTable.backgroundColour = "#3f09A3F4"
    else
      v.partsTable.backgroundColour = "#1f09A3F4"
    end

    v.polyphony.visible = isVisible
    v.numStepsBox.visible = isVisible
    v.numRepeatsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.minNoteSteps.visible = isVisible
    v.maxNoteSteps.visible = isVisible
    v.monoLimit.visible = isVisible
    v.key.visible = isVisible
    v.harmonizationPropbability.visible = isVisible
    v.velocityInput.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateInput.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.baseNoteRandomization.visible = isVisible
    v.chordDefinitionInput.visible = isVisible
    v.createChordDefinitionButton.visible = isVisible
    v.autoChordButton.visible = isVisible
    v.randomChordButton.visible = isVisible
    v.slotChordButton.visible = isVisible
    v.loadChordDefinition.visible = isVisible
    v.saveChordDefinition.visible = isVisible
    for _,w in ipairs(v.chordDefinitionSlots) do
      w.visible = isVisible
    end
    for _,w in ipairs(v.chords) do
      w.visible = isVisible
    end
    for _,w in ipairs(v.inversions) do
      w.visible = isVisible
    end
    for _,w in ipairs(v.spreads) do
      w.visible = isVisible
    end
  end
  setTableWidths()
end

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = widgetTextColour
numPartsBox.width = editPartMenu.width
numPartsBox.height = 20
numPartsBox.x = editPartMenu.x
numPartsBox.y = editPartMenu.y + editPartMenu.height + 5
numPartsBox.changed = function(self)
  for _,v in ipairs(paramsPerPart) do
    v.partsTable.visible = false
    v.positionTable.visible = false
  end
  numParts = self.value
  for i=1,numParts do
    setNumSteps(i)
  end

  local partSelect = {}
  for i=1,numParts do
    -- Add item to part select table
    table.insert(partSelect, "Part " .. i)
    if paramsPerPart[i].init == false then
      -- Copy initial settings from prev part
      print("Copy initial settings from prev part", i-1)
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].polyphony.value = prev.polyphony.value
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].harmonizationPropbability.value = prev.harmonizationPropbability.value
      paramsPerPart[i].gateInput.value = prev.gateInput.value
      paramsPerPart[i].velocityInput.value = prev.velocityInput.value
      paramsPerPart[i].monoLimit.value = prev.monoLimit.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].numRepeatsBox.value = prev.numRepeatsBox.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].velRandomization.value = prev.velRandomization.value
      paramsPerPart[i].gateRandomization.value = prev.gateRandomization.value
      paramsPerPart[i].baseNoteRandomization.value = prev.baseNoteRandomization.value
      paramsPerPart[i].init = true
    end
  end
  clearPosition()
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)
end

local partRandBox = sequencerPanel:NumBox("PartRandomization", 0, 0, 100, true)
partRandBox.backgroundColour = menuBackgroundColour
partRandBox.textColour = widgetTextColour
partRandBox.displayName = "Part Order"
partRandBox.tooltip = "Amount of radomization applied to the order of playing parts"
partRandBox.unit = Unit.Percent
partRandBox.width = editPartMenu.width
partRandBox.x = numPartsBox.x
partRandBox.y = numPartsBox.y + numPartsBox.height + 5

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function isRootNote(note, partPos)
  -- Find root note index
  local rootIndex = paramsPerPart[partPos].key.value
  local noteIndex = note + 1 -- note index is 1 higher than note number
  return noteNumberToNoteName[rootIndex] == noteNumberToNoteName[noteIndex]
end

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
    v.partsTable:setValue(1, 0)
  end
end

function startPlaying()
  if isPlaying == true then
    return
  end
  spawn(arpeg)
  isPlaying = true
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  clearPosition()
end

function setNumSteps(index)
  local numSteps = paramsPerPart[index].numStepsBox.value
  partToStepMap = {} -- Reset map
  totalNumSteps = 0
  for i=1, numPartsBox.value do
    table.insert(partToStepMap, (totalNumSteps + 1))
    totalNumSteps = totalNumSteps + paramsPerPart[i].numStepsBox.value
  end

  setTableWidths()
end

function setTableWidths()
  local focusSelectedPart = focusButton.value
  local widthPerStep = tableWidth / totalNumSteps
  local x = 0
  for i=1, numPartsBox.value do
    local isVisible = (focusSelectedPart == true and i == editPartMenu.value) or focusSelectedPart == false
    local partTableWidth = paramsPerPart[i].numStepsBox.value * widthPerStep
    if focusSelectedPart then
      partTableWidth = tableWidth
      x = 0
    end

    paramsPerPart[i].partsTable.visible = isVisible
    paramsPerPart[i].partsTable.width = partTableWidth
    paramsPerPart[i].partsTable.x = x

    paramsPerPart[i].positionTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].positionTable.visible = isVisible
    paramsPerPart[i].positionTable.width = partTableWidth
    paramsPerPart[i].positionTable.x = x

    x = x + partTableWidth
  end
end

function createChordDefinition(part)
  local maxValue = 4 -- Max value
  local maxLength = paramsPerPart[part].polyphony.value -- Max length depends on polyphony
  local definition = {} -- Table to hold definition
  local ln = getRandom(maxLength) -- Set a random length for the definition
  for i=1, ln do
    local value = getRandom(maxValue)
    table.insert(definition, value)
    print("Add value to definition", value)
  end
  return definition
end

function getChordInputText(definition)
  if #definition == 0 then
    return "Randomize"
  end
  return table.concat(definition, ",")
end

local chordProbabilityLabel = sequencerPanel:Label("ChordProbabilityProbabilityLabel")
chordProbabilityLabel.text = "Chords"
chordProbabilityLabel.tooltip = "Choose the probability that chords will be included when harmonizing"

local spreadProbabilityLabel = sequencerPanel:Label("SpreadProbabilityLabel")
spreadProbabilityLabel.text = "Note Spread"
spreadProbabilityLabel.tooltip = "Set note spread probability"

local inversionProbabilityLabel = sequencerPanel:Label("InversionProbabilityLabel")
inversionProbabilityLabel.text = "Chord Inversions"
inversionProbabilityLabel.tooltip = "Choose the probability that inversions will be used when harmonizing"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  local chords = {}
  local spreads = {}
  local inversions = {}

  local partsTable = sequencerPanel:Table("Parts" .. i, 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  partsTable.backgroundColour = "#1f09A3F4"
  partsTable.sliderColour = sliderColour
  partsTable.width = tableWidth
  partsTable.height = 10
  partsTable.x = 0
  partsTable.y = label.height + 10
  
  local positionTable = sequencerPanel:Table("Position" .. i, totalNumSteps, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  positionTable.backgroundColour = widgetTextColour
  positionTable.sliderColour = sliderColour
  positionTable.width = partsTable.width
  positionTable.height = partsTable.height
  positionTable.x = partsTable.x
  positionTable.y = partsTable.y + partsTable.height
  
  local generatePolyphonyPart = sequencerPanel:NumBox("GeneratePolyphony" .. i, 4, 1, maxVoices, true)
  generatePolyphonyPart.displayName = "Polyphony"
  generatePolyphonyPart.tooltip = "How many notes are played at once"
  generatePolyphonyPart.backgroundColour = menuBackgroundColour
  generatePolyphonyPart.textColour = widgetTextColour
  generatePolyphonyPart.visible = false
  generatePolyphonyPart.width = editPartMenu.width
  generatePolyphonyPart.x = editPartMenu.x + editPartMenu.width + 10
  generatePolyphonyPart.y = editPartMenu.y
  generatePolyphonyPart.changed = function(self)
    for i,v in ipairs(noteDisplay) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
  end

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, 16, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps a note can last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = widgetTextColour
  generateMinNoteStepsPart.enabled = false
  generateMinNoteStepsPart.width = generatePolyphonyPart.width
  generateMinNoteStepsPart.x = generatePolyphonyPart.x
  generateMinNoteStepsPart.y = generatePolyphonyPart.y + generatePolyphonyPart.height + 5

  local generateMaxNoteStepsPart = sequencerPanel:NumBox("GenerateMaxNoteSteps" .. i, 1, 1, 16, true)
  generateMaxNoteStepsPart.displayName = "Max Steps"
  generateMaxNoteStepsPart.tooltip = "The maximium number of steps a note can last"
  generateMaxNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMaxNoteStepsPart.textColour = widgetTextColour
  generateMaxNoteStepsPart.width = generateMinNoteStepsPart.width
  generateMaxNoteStepsPart.x = generateMinNoteStepsPart.x
  generateMaxNoteStepsPart.y = generateMinNoteStepsPart.y + generateMinNoteStepsPart.height + 5
  generateMaxNoteStepsPart.changed = function(self)
    generateMinNoteStepsPart:setRange(1, self.value)
    generateMinNoteStepsPart.enabled = self.value > 1
  end

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
  stepResolution.displayName = "Step Duration"
  stepResolution.tooltip = "The duration of each step in the part"
  stepResolution.selected = 11
  stepResolution.showLabel = false
  stepResolution.height = 20
  stepResolution.width = generateMaxNoteStepsPart.width
  stepResolution.x = generatePolyphonyPart.x + generatePolyphonyPart.width + 10
  stepResolution.y = generatePolyphonyPart.y
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = widgetTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    setNumSteps(i)
  end

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, totalNumSteps, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The number of steps in the part"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = widgetTextColour
  numStepsBox.width = stepResolution.width
  numStepsBox.x = stepResolution.x
  numStepsBox.y = stepResolution.y + stepResolution.height + 5
  numStepsBox.changed = function(self)
    setNumSteps(i)
  end

  local numRepeatsBox = sequencerPanel:NumBox("Repeats" .. i, 1, 1, 256, true)
  numRepeatsBox.displayName = "Repeats"
  numRepeatsBox.tooltip = "The number of times this part will repeat before proceeding to the next"
  numRepeatsBox.backgroundColour = menuBackgroundColour
  numRepeatsBox.textColour = widgetTextColour
  numRepeatsBox.width = numStepsBox.width
  numRepeatsBox.x = numStepsBox.x
  numRepeatsBox.y = numStepsBox.y + numStepsBox.height + 5

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, getNoteNames())
  generateKeyPart.displayName = "Root Note"
  generateKeyPart.tooltip = "Root Note"
  generateKeyPart.showLabel = true
  --generateKeyPart.height = 20
  generateKeyPart.width = stepResolution.width
  generateKeyPart.x = stepResolution.x + stepResolution.width + 10
  generateKeyPart.y = stepResolution.y
  generateKeyPart.backgroundColour = menuBackgroundColour
  generateKeyPart.textColour = widgetTextColour
  generateKeyPart.arrowColour = menuArrowColour
  generateKeyPart.outlineColour = menuOutlineColour
  
  local baseNoteRandomization = sequencerPanel:NumBox("BaseNoteProbability" .. i, 75, 0, 100, true)
  baseNoteRandomization.displayName = "Base Chord"
  baseNoteRandomization.tooltip = "Probability that first chord in the part will be the root chord"
  baseNoteRandomization.unit = Unit.Percent
  baseNoteRandomization.width = generateKeyPart.width
  baseNoteRandomization.x = generateKeyPart.x
  baseNoteRandomization.y = generateKeyPart.y + generateKeyPart.height + 5
  baseNoteRandomization.backgroundColour = menuBackgroundColour
  baseNoteRandomization.textColour = widgetTextColour

  local monoLimit = sequencerPanel:NumBox("MonoLimit" .. i, 48, 0, 64, true)
  monoLimit.unit = Unit.MidiKey
  monoLimit.showPopupDisplay = true
  monoLimit.showLabel = true
  monoLimit.backgroundColour = menuBackgroundColour
  monoLimit.textColour = widgetTextColour
  monoLimit.displayName = "Mono Limit"
  monoLimit.tooltip = "Below this note there will only be played one note (polyphony=1)"
  monoLimit.x = generateKeyPart.x + generateKeyPart.width + 10
  monoLimit.y = generateKeyPart.y
  monoLimit.width = stepResolution.width

  local gateInput = sequencerPanel:NumBox("GateInput" .. i, 100, 0, 100, true)
  gateInput.unit = Unit.Percent
  gateInput.textColour = widgetTextColour
  gateInput.backgroundColour = widgetBackgroundColour
  gateInput.displayName = "Gate"
  gateInput.tooltip = "Gate Level"
  gateInput.width = stepResolution.width
  gateInput.x = monoLimit.x
  gateInput.y = monoLimit.y + monoLimit.height + 5

  local velocityInput = sequencerPanel:NumBox("VelocityInput" .. i, 64, 1, 127, true)
  velocityInput.textColour = widgetTextColour
  velocityInput.backgroundColour = widgetBackgroundColour
  velocityInput.displayName = "Velocity"
  velocityInput.tooltip = "Default velocity"
  velocityInput.width = stepResolution.width
  velocityInput.x = gateInput.x
  velocityInput.y = gateInput.y + gateInput.height + 5

  local harmonizationPropbability = sequencerPanel:NumBox("HarmonizationPropbability" .. i, 100, 0, 100, true)
  harmonizationPropbability.displayName = "Harmonize"
  harmonizationPropbability.tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale."
  harmonizationPropbability.unit = Unit.Percent
  harmonizationPropbability.height = 20
  harmonizationPropbability.width = generateKeyPart.width
  harmonizationPropbability.x = monoLimit.x + monoLimit.width + 10
  harmonizationPropbability.y = monoLimit.y
  harmonizationPropbability.backgroundColour = menuBackgroundColour
  harmonizationPropbability.textColour = widgetTextColour

  local gateRandomization = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRandomization.displayName = "Gate Rand"
  gateRandomization.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandomization.unit = Unit.Percent
  gateRandomization.width = harmonizationPropbability.width
  gateRandomization.x = harmonizationPropbability.x
  gateRandomization.y = harmonizationPropbability.y + harmonizationPropbability.height + 5
  gateRandomization.backgroundColour = menuBackgroundColour
  gateRandomization.textColour = widgetTextColour

  local velRandomization = sequencerPanel:NumBox("VelocityRandomization" .. i, 15, 0, 100, true)
  velRandomization.displayName = "Velocity Rand"
  velRandomization.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandomization.unit = Unit.Percent
  velRandomization.width = editPartMenu.width
  velRandomization.x = gateRandomization.x
  velRandomization.y = gateRandomization.y + gateRandomization.height + 5
  velRandomization.backgroundColour = menuBackgroundColour
  velRandomization.textColour = widgetTextColour

  local voiceLabelBgColour = "9F9F9F"
  local voiceLabelTextColour = "202020"
  local voiceRowCount = 2
  local voiceLabelY = 250

  if i == 1 then
    for j=1,maxVoices do
      local voiceLabel = sequencerPanel:Label("VoiceLabel" .. i .. j)
      voiceLabel.persistent = false
      voiceLabel.text = "Voice " .. j
      voiceLabel.tooltip = "Settings for voice " .. j
      voiceLabel.backgroundColour = voiceLabelBgColour
      voiceLabel.textColour = voiceLabelTextColour
      voiceLabel.width = tableWidth / maxVoices
      voiceLabel.height = 20
      --voiceLabel.x = (j * (voiceLabel.width + 1)) - 2
      voiceLabel.x = ((j - 1) * (voiceLabel.width + 1)) - 2
      voiceLabel.y = voiceLabelY
    end
  end

  if i == 1 then
    for j=1,maxVoices do
      local noteInput = sequencerPanel:Label("NoteInput" .. j)
      noteInput.enabled = false
      noteInput.persistent = false
      noteInput.tooltip = "Displays the note played by voice " .. j
      noteInput.text = "-"
      noteInput.backgroundColour = menuBackgroundColour
      noteInput.textColour = labelTextColour
      noteInput.width = tableWidth / maxVoices
      noteInput.height = 20
      noteInput.x = ((j - 1) * (noteInput.width + 1)) - 2
      noteInput.y = voiceLabelY + 22
      table.insert(noteDisplay, noteInput)
    end
  end

  if i == 1 then
    chordProbabilityLabel.width = editPartMenu.width
    chordProbabilityLabel.x = 0
    chordProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
  end

  local chordDefinitionInput = sequencerPanel:Label("ChordInput" .. i)
  chordDefinitionInput.text = getChordInputText(chordDefinitions[1])
  chordDefinitionInput.tooltip = "Chord definitions build chords. Numbers represent steps up or down the scale that is currently selected. Feel free to type your own chord definitions here, or select from the menu."
  chordDefinitionInput.editable = true
  chordDefinitionInput.backgroundColour = menuBackgroundColour
  chordDefinitionInput.backgroundColourWhenEditing = "black"
  chordDefinitionInput.textColour = labelTextColour
  chordDefinitionInput.textColourWhenEditing = "white"
  chordDefinitionInput.width = editPartMenu.width * 2.13
  chordDefinitionInput.height = 45
  chordDefinitionInput.fontSize = 30
  chordDefinitionInput.x = generatePolyphonyPart.x
  chordDefinitionInput.y = chordProbabilityLabel.y + chordProbabilityLabel.height + 5

  local autoChordButton = sequencerPanel:OnOffButton("AutoChordButton" .. i, false)
  autoChordButton.displayName = "Auto"
  autoChordButton.tooltip = "Default chord definitions are alternated by random while playing."
  autoChordButton.backgroundColourOff = backgroundColourOff
  autoChordButton.backgroundColourOn = backgroundColourOn
  autoChordButton.textColourOff = textColourOff
  autoChordButton.textColourOn = textColourOn
  autoChordButton.width = editPartMenu.width
  autoChordButton.x = baseNoteRandomization.x
  autoChordButton.y = chordDefinitionInput.y

  local randomChordButton = sequencerPanel:OnOffButton("RandomChordButton" .. i, false)
  randomChordButton.displayName = "Random"
  randomChordButton.tooltip = "Chord definitions are created by random while playing."
  randomChordButton.backgroundColourOff = backgroundColourOff
  randomChordButton.backgroundColourOn = backgroundColourOn
  randomChordButton.textColourOff = textColourOff
  randomChordButton.textColourOn = textColourOn
  randomChordButton.width = autoChordButton.width
  randomChordButton.x = autoChordButton.x
  randomChordButton.y = autoChordButton.y + autoChordButton.height + 5

  local slotChordButton = sequencerPanel:OnOffButton("SlotChordButton" .. i, false)
  slotChordButton.displayName = "Slots"
  slotChordButton.tooltip = "Chord definitions are selected by random from the slots."
  slotChordButton.backgroundColourOff = backgroundColourOff
  slotChordButton.backgroundColourOn = backgroundColourOn
  slotChordButton.textColourOff = textColourOff
  slotChordButton.textColourOn = textColourOn
  slotChordButton.width = randomChordButton.width
  slotChordButton.x = randomChordButton.x
  slotChordButton.y = randomChordButton.y + randomChordButton.height + 5

  local createChordDefinitionButton = sequencerPanel:Button("CreateDefButton" .. i)
  createChordDefinitionButton.displayName = "Create"
  createChordDefinitionButton.tooltip = "Create a random chord definition."
  createChordDefinitionButton.persistent = false
  createChordDefinitionButton.width = editPartMenu.width
  createChordDefinitionButton.x = chordProbabilityLabel.x
  createChordDefinitionButton.y = chordProbabilityLabel.y + chordProbabilityLabel.height + 5

  local saveActions = {"Save to..."}
  local chordDefinitionSlots = {}
  for j=1,8 do
    local definitionSlot = sequencerPanel:OnOffButton("ChordSlot" .. i .. j)
    definitionSlot.backgroundColourOff = backgroundColourOff
    definitionSlot.backgroundColourOn = backgroundColourOn
    definitionSlot.textColourOff = textColourOff
    definitionSlot.textColourOn = textColourOn
    definitionSlot.displayName = "" .. j
    definitionSlot.enabled = false
    definitionSlot.tooltip = "Unused"
    definitionSlot.height = 20
    definitionSlot.width = 27
    definitionSlot.x = chordDefinitionInput.x + ((j-1) * (definitionSlot.width+2))
    definitionSlot.y = chordDefinitionInput.y + chordDefinitionInput.height + 5
    definitionSlot.changed = function(self)
      chordDefinitionInput.text = definitionSlot.tooltip
      self.value = false
    end
    table.insert(chordDefinitionSlots, definitionSlot)
    table.insert(saveActions, "Slot " .. j)
  end

  local loadActions = {"Load..."}
  for _,v in ipairs(chordDefinitions) do
    table.insert(loadActions, getChordInputText(v))
  end

  local loadChordDefinition = sequencerPanel:Menu("LoadChordDefinition" .. i, loadActions)
  loadChordDefinition.tooltip = "Load a chord definition"
  loadChordDefinition.showLabel = false
  loadChordDefinition.height = 20
  loadChordDefinition.width = editPartMenu.width
  loadChordDefinition.x = createChordDefinitionButton.x
  loadChordDefinition.y = createChordDefinitionButton.y + createChordDefinitionButton.height + 5
  loadChordDefinition.backgroundColour = menuBackgroundColour
  loadChordDefinition.textColour = widgetTextColour
  loadChordDefinition.arrowColour = menuArrowColour
  loadChordDefinition.outlineColour = menuOutlineColour
  loadChordDefinition.changed = function(self)
    -- 1 is the menu label...
    if self.value == 1 then
      return
    end

    local actionIndex = self.value - 1
    chordDefinitionInput.text = self.selectedText

    -- Must be last
    self.selected = 1
  end

  local saveChordDefinition = sequencerPanel:Menu("SaveChordDefinition" .. i, saveActions)
  saveChordDefinition.tooltip = "Save the current chord definition to the selected slot"
  saveChordDefinition.showLabel = false
  saveChordDefinition.height = 20
  saveChordDefinition.width = editPartMenu.width
  saveChordDefinition.x = loadChordDefinition.x
  saveChordDefinition.y = loadChordDefinition.y + loadChordDefinition.height + 5
  saveChordDefinition.backgroundColour = menuBackgroundColour
  saveChordDefinition.textColour = widgetTextColour
  saveChordDefinition.arrowColour = menuArrowColour
  saveChordDefinition.outlineColour = menuOutlineColour
  saveChordDefinition.changed = function(self)
    -- 1 is the menu label...
    if self.value == 1 then
      return
    end

    local actionIndex = self.value - 1

    -- Save chord definition
    if string.len(chordDefinitionInput.text) > 0 then
      chordDefinitionSlots[actionIndex].tooltip = chordDefinitionInput.text
      chordDefinitionSlots[actionIndex].enabled = true
    else
      chordDefinitionSlots[actionIndex].tooltip = "Unused"
      chordDefinitionSlots[actionIndex].enabled = false
    end
    print("Chord definition saved to slot", chordDefinitionInput.text, actionIndex)

    -- Must be last
    self.selected = 1
  end

  autoChordButton.changed = function(self)
    slotChordButton:setValue(false, false)
    randomChordButton:setValue(false, false)
    chordDefinitionInput.enabled = self.value == false
    createChordDefinitionButton.enabled = self.value == false
  end

  randomChordButton.changed = function(self)
    autoChordButton:setValue(false, false)
    slotChordButton:setValue(false, false)
    chordDefinitionInput.enabled = self.value == false
    createChordDefinitionButton.enabled = self.value == false
  end

  slotChordButton.changed = function(self)
    autoChordButton:setValue(false, false)
    randomChordButton:setValue(false, false)
    chordDefinitionInput.enabled = true
    createChordDefinitionButton.enabled = true
  end

  createChordDefinitionButton.changed = function()
    chordDefinitionInput.text = getChordInputText(createChordDefinition(i))
  end

  if i == 1 then
    spreadProbabilityLabel.x = monoLimit.x
    spreadProbabilityLabel.y = chordProbabilityLabel.y
    spreadProbabilityLabel.width = editPartMenu.width

    inversionProbabilityLabel.x = velRandomization.x
    inversionProbabilityLabel.y = chordProbabilityLabel.y
    inversionProbabilityLabel.width = editPartMenu.width
  end

  -- Note Spread
  local perRow = 1
  local columnCount = 0
  local rowCount = 1
  for spread=1,3 do
    local spreadProbability = sequencerPanel:NumBox("SpreadProbability" .. i .. spread, 100, 0, 100, true)
    if spread == 1 then
      spreadProbability.displayName = "Close"
      spreadProbability.tooltip = "Set the probability that close chords will be included"
    elseif spread == 2 then
      spreadProbability.displayName = "Medium"
      spreadProbability.tooltip = "Set the probability that medium wide chords will be included"
    else
      spreadProbability.displayName = "Wide"
      spreadProbability.tooltip = "Set the probability that wide chords will be included"
    end
    spreadProbability.unit = Unit.Percent
    spreadProbability.height = 20
    spreadProbability.width = editPartMenu.width
    spreadProbability.x = spreadProbabilityLabel.x + (columnCount * (spreadProbability.width + 10))
    spreadProbability.y = spreadProbabilityLabel.y + ((spreadProbability.height + 5) * rowCount)
    spreadProbability.backgroundColour = menuBackgroundColour
    spreadProbability.textColour = widgetTextColour
    table.insert(spreads, spreadProbability)
    columnCount = columnCount + 1
    if spread % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end

  -- Inversions
  local perRow = 1
  local columnCount = 0
  local rowCount = 1
  for inversion=1,3 do
    local inversionProbability = sequencerPanel:NumBox("InversionsProbability" .. i .. inversion, 100, 0, 100, true)
    inversionProbability.displayName = "Inv " .. inversion
    inversionProbability.tooltip = "Probability that inversion " .. inversion .. " will be included"
    inversionProbability.unit = Unit.Percent
    inversionProbability.height = 20
    inversionProbability.width = editPartMenu.width
    inversionProbability.x = inversionProbabilityLabel.x + (columnCount * (inversionProbability.width + 10))
    inversionProbability.y = inversionProbabilityLabel.y + ((inversionProbability.height + 5) * rowCount)
    inversionProbability.backgroundColour = menuBackgroundColour
    inversionProbability.textColour = widgetTextColour
    table.insert(inversions, inversionProbability)
    columnCount = columnCount + 1
    if inversion % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end

  table.insert(paramsPerPart, {chordDefinitionSlots=chordDefinitionSlots,createChordDefinitionButton=createChordDefinitionButton,loadChordDefinition=loadChordDefinition,saveChordDefinition=saveChordDefinition,chordDefinitionInput=chordDefinitionInput,autoChordButton=autoChordButton,randomChordButton=randomChordButton,slotChordButton=slotChordButton,inversions=inversions,spreads=spreads,chords=chords,velRandomization=velRandomization,gateRandomization=gateRandomization,baseNoteRandomization=baseNoteRandomization,partsTable=partsTable,positionTable=positionTable,velocityInput=velocityInput,gateInput=gateInput,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,numRepeatsBox=numRepeatsBox,stepResolution=stepResolution,key=generateKeyPart,harmonizationPropbability=harmonizationPropbability,monoLimit=monoLimit,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function play(node, partPos)
  local gate = getGate(partPos, node.step)
  local noteDuration = node.stepDuration * node.steps
  local playDuration = getPlayDuration(noteDuration, gate)
  local noteToPlay = node.note
  print("play note partPos/noteToPlay/noteName/duration/voice", partPos, noteToPlay, noteNumberToNoteName[noteToPlay+1], playDuration, node.voice)
  -- If the key is already playing, send a note off event before playing the note
  if isKeyDown(noteToPlay) then
    postEvent({type=Event.NoteOff, note=noteToPlay, velocity=0})
    print("isKeyDown/noteToPlay", isKeyDown(noteToPlay), noteToPlay)
  end
  local channel = nil
  if channelButton.value == true then
    channel = node.voice
  end
  playNote(noteToPlay, getVelocity(partPos, node.step), beat2ms(playDuration)-1, nil, channel)
end

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentPartPosition = 1 -- Holds the currently playing part
  local heldNoteIndex = 0
  local isStarting = true
  local scale = {} -- The scale the generator can choose from.
  local inversionIndex = 0
  local repeatCounter = 0 -- Count part repeats
  notes = {} -- Ensure notes are reset when seqencer starts

  -- START ARP LOOP
  while isPlaying do
    local numRepeats = paramsPerPart[currentPartPosition].numRepeatsBox.value
    local currentPosition = (index % totalNumSteps) + 1
    local startOfPart = false
    local partWasChanged = false
    print("currentPosition/currentPartPosition", currentPosition, currentPartPosition)

    -- Set part position
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        -- Set start of part
        startOfPart = true
        -- Update part position
        partWasChanged = currentPartPosition ~= pp
        if partWasChanged then
          -- Increment repeat
          repeatCounter = repeatCounter + 1
          -- Check for repeat
          if repeatCounter < numRepeats then
            -- Repeat part - no change
            partWasChanged = false
          end
        end
        if partWasChanged then
          currentPartPosition = pp
        end
        break
      end
    end

    -- Increment step counter
    currentStep = currentStep + 1
    if currentStep > totalNumSteps then
      currentStep = 1
    end

    -- Check if we are at the start of a part
    if startOfPart and numParts > 1 then
      if focusButton.value == true then
        partWasChanged = currentPartPosition ~= editPartMenu.value
        currentPartPosition = editPartMenu.value
      elseif (isStarting == false or partRandBox.value > 50) and getRandomBoolean(partRandBox.value) then
        -- Randomize parts within the set limit
        print("currentPartPosition before", currentPartPosition)
        print("currentPosition before", currentPosition)
        --print("index before", index)
        local randomPartPosition = getRandom(numParts)
        partWasChanged = currentPartPosition ~= randomPartPosition
        currentPartPosition = randomPartPosition
      end
      -- Find the current pos and index
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
      if partWasChanged then
        repeatCounter = 0 -- Reset repeat counter
      end
    end

    -- Number of simultainious notes are set by polyphony
    scale = getSelectedNotes()
    fullScale = getActiveNotes()
    local polyphony = paramsPerPart[currentPartPosition].polyphony.value
    local minNote = scale[1]
    local maxNote = scale[#scale]
    local mainBeatDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
    local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value

    inversionIndex = 0 -- Reset counter for inversion progress
    local autoChord = paramsPerPart[currentPartPosition].autoChordButton.value
    local randomChord = paramsPerPart[currentPartPosition].randomChordButton.value
    local slotChord = paramsPerPart[currentPartPosition].slotChordButton.value
    if autoChord == true then
      local index = getRandom(#chordDefinitions)
      paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(chordDefinitions[index])
    end
    if randomChord == true then
      paramsPerPart[currentPartPosition].chordDefinitionInput.text = getChordInputText(createChordDefinition(currentPartPosition))
    end
    if slotChord == true then
      local chordDefinitionSlots = {}
      for _,v in ipairs(paramsPerPart[currentPartPosition].chordDefinitionSlots) do
        if v.enabled == true then
          table.insert(chordDefinitionSlots, v)
        end
      end
      if #chordDefinitionSlots > 0 then
        chordDefinitionSlots[math.ceil(getRandom(#chordDefinitionSlots))]:setValue(true)
      end
    end

    -- Always use the first inversion at the start of a part
    if startOfPart == false then
      -- Find inversions to include
      local inversions = paramsPerPart[currentPartPosition].inversions
      local activeInversions = {}
      for i,v in ipairs(inversions) do
        if getRandomBoolean(v.value) == true then
          table.insert(activeInversions, i)
        end
      end

      if #activeInversions > 0 then
        -- Get a chord def index from the active definitions
        inversionIndex = activeInversions[getRandom(#activeInversions)] - 1
        print("Chord inversion selected by random/#activeInversions", inversionIndex, #activeInversions)
      end
    end

    -- Find spreads to include
    local selectedSpread = 2 -- Reset to default
    local spreads = paramsPerPart[currentPartPosition].spreads
    local activeSpreads = {}
    for i,v in ipairs(spreads) do
      if getRandomBoolean(v.value) == true then
        table.insert(activeSpreads, i)
      end
    end

    if #activeSpreads > 0 then
      -- Get a chord def index from the active definitions
      if #activeSpreads > 1 then
        selectedSpread = activeSpreads[getRandom(#activeSpreads)]
      else
        selectedSpread = activeSpreads[1]
      end
      print("Chord spread selected by random: selectedSpread/#activeSpreads", selectedSpread, #activeSpreads)
    end

    -- Get current position in the table
    local startStep = partToStepMap[currentPartPosition]
    local tablePos = currentPosition - startStep + 1

    --------------------------------------------------------------------------------
    -- Note functions
    --------------------------------------------------------------------------------

    -- Main function for getting note to play
    local function getNoteToPlay(voice, chordDefinition)
      -- Note generator function
      local function generateNote()
        local note = nil
        local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
        local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
        local baseMin = minNote
        local baseMax = maxNote

        if #scale == 0 then
          return note
        end

        if #scale == 1 then
          return scale[1]
        end

        if hasNoteWithinMonoLimit(notes, currentPartPosition) == true then
          -- Ensure we only have one note below the mono limit
          baseMin = monoLimit
          print("Adjust baseMin to mono limit", baseMin)
        elseif monoLimit > baseMin then
          -- Ensure we have a note within the mono limit
          baseMax = monoLimit
          print("Adjust baseMax to mono limit", baseMax)
        end

        local function getBaseNote()
          local baseNote = minNote -- Start from the lowest note
          local useBaseNote = currentStep == 1
          if useBaseNote and getRandomBoolean(baseNoteRandomization) then
            while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
              baseNote = baseNote + 1 -- increment note until we hit the base note
            end
            print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
          else
            local noteRange = baseMax - baseMin
            if monoLimit <= baseMin then
              -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
              noteRange = math.max(12, math.ceil(noteRange / polyphony))
              print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
            end
            baseNote = baseNote + getRandom(noteRange) - 1
          end

          return getNoteAccordingToScale(scale, baseNote)
        end

        -- The note on the first voice is the base note
        if voice == 1 then
          note = getBaseNote()
        end

        local harmonizationPropbability = paramsPerPart[currentPartPosition].harmonizationPropbability.value
        if type(note) == "nil" and getRandomBoolean(harmonizationPropbability) == true then
          local startingNotes = {}
          for _,v in ipairs(notes) do
            if v.stepCounter == 0 then
              table.insert(startingNotes, v.note)
              print("Insert into startingNotes", v.note)
            end
          end
          if #startingNotes > 0 then
            -- If we have notes added, use them as the basis for the next note
            print("startingNotes", #startingNotes)
            local prevNote = startingNotes[#startingNotes]
            print("Found prevNote", prevNote)
            -- Increment inversion index
            inversionIndex = inversionIndex + 1
            if inversionIndex > #chordDefinition then
              inversionIndex = 1
            end
            local scaleIndex = getNextScaleIndex(prevNote, fullScale, chordDefinition, inversionIndex)
            note = fullScale[scaleIndex]
            if type(note) == "number" then
              note = transpose(note, baseMin, baseMax) -- Ensure note is 
              local noteRange = baseMax - prevNote
              local octaveFactor = 12-- / (selectedSpread / 2)
              local octaveRange = math.floor(noteRange / octaveFactor)
              local notesLeft = polyphony - #notes
              local octave = 0
              local octaveProbability = 50
              local negOctProbability = 50
              if selectedSpread == 1 then
                octaveProbability = 15
                negOctProbability = 75
              elseif selectedSpread == 3 then
                octaveProbability = 75
                negOctProbability = 15
              end
              if getRandomBoolean(octaveProbability) then
                octave = math.floor(octaveRange / notesLeft)
              end
              print("Check octave/note/baseMax/negOctProbability", octave, note, baseMax, negOctProbability)
              if octave > 0 and octave < 3 and note > baseMax / 2 and getRandomBoolean(negOctProbability) then
                octave = -octave
                print("Negative octave", octave)
              end
              local octaveOffset = octave * 12
              print("Calculate octave adjustment - noteRange/octaveRange/notesLeft/octave", noteRange, octaveRange, notesLeft, octave)
              if octaveOffset > 0 and note + octaveOffset <= baseMax then
                note = note + octaveOffset
                print("Octave adjusted octave/octaveOffset/note", octave, octaveOffset, note)
              end
              print("Found note from prev note - note, prevNote", note, prevNote)
            end
          end
        end

        -- Get random note from scale
        if type(note) == "nil" then
          note = getNoteAccordingToScale(scale, getRandom(baseMin, baseMax))
        end

        return note
      end

      -- Get the number of steps this structure will last
      local steps = getRandom(minNoteSteps, maxNoteSteps)
      
      -- Adjust steps so note does not last beyond the part length
      local maxSteps = (paramsPerPart[currentPartPosition].numStepsBox.value - tablePos) + 1
      if steps > maxSteps then
        print("maxSteps/steps", maxSteps, steps)
        steps = maxSteps
      end

      -- Get notes for each node in the tree
      local note = generateNote()
      local noteToPlay = {
        note = note,
        step = tablePos,
        steps = steps,
        stepDuration = mainBeatDuration,
        voice = voice,
        stepCounter = 0
      }

      return noteToPlay
    end

    --------------------------------------------------------------------------------
    -- Play this step - If gate is set to zero, no notes will play on this step
    --------------------------------------------------------------------------------
    if getGate(currentPartPosition, tablePos, true) > 0 then
      -- Check how many voices are already playing
      local voicesPlaying = {}
      for _,v in ipairs(notes) do
        table.insert(voicesPlaying, v.voice)
        print("Voice is playing", v.voice)
      end

      -- Get chord definition from input
      local chordDefinition = {}
      local input = paramsPerPart[currentPartPosition].chordDefinitionInput
      if string.len(input.text) > 0 then
        for w in string.gmatch(input.text, "-?%d+") do
          table.insert(chordDefinition, w)
          print("Add to chordDefinition", w)
        end
        print("Get chordDefinition from input", #chordDefinition)
      end

      -- Create a random chord definition if empty
      if #chordDefinition == 0 then
        chordDefinition = createChordDefinition(currentPartPosition)
      end
      
      -- Add notes to play
      local voice = 1
      local roundCounter = 0
      local maxRounds = (polyphony - #voicesPlaying) * 2
      local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
      while voice <= polyphony and roundCounter < maxRounds do
        local isVoicePlaying = false
        for _,v in ipairs(voicesPlaying) do
          if v == voice then
            isVoicePlaying = true
          end
        end
        if isVoicePlaying == true then
          -- If the voice is playing, just increment without adding a note for this voice
          print("Voice is playing", voice)
          voice = voice + 1
        else
          print("Voice is not playing", voice)
          local noteToPlay = getNoteToPlay(voice, chordDefinition)
          if type(noteToPlay.note) == "number" and notesInclude(notes, noteToPlay.note) == false then
            table.insert(notes, noteToPlay)
            print("Insert note", noteToPlay.note)
            noteDisplay[voice].text = noteNumberToNoteName[noteToPlay.note + 1] .. " (" .. noteToPlay.note .. ")"
            voice = voice + 1
          end
        end
        roundCounter = roundCounter + 1
        print("Searching for notes roundCounter", roundCounter)
      end
      print("Notes ready to play at this step/#notes-#voicesPlaying", tablePos, (#notes - #voicesPlaying))
    end

    -- PLAY NOTE(S)
    for _,note in ipairs(notes) do
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 then
        play(note, currentPartPosition)
      end
      -- Increment step counter
      note.stepCounter = note.stepCounter + 1
    end

    -- UPDATE STEP POSITION TABLE
    for i=1, numParts do
      for j=1, paramsPerPart[i].numStepsBox.value do
        if i == currentPartPosition and j == currentPosition - startStep + 1 then
          paramsPerPart[i].positionTable:setValue(j, 1)
        else
          paramsPerPart[i].positionTable:setValue(j, 0)
        end
      end
    end

    -- UPDATE PART POSITION TABLE
    if startOfPart then
      for i=1, numParts do
        if i == currentPartPosition then
          paramsPerPart[i].partsTable:setValue(1, 1)
        else
          paramsPerPart[i].partsTable:setValue(1, 0)
        end
      end
    end

    -- INCREMENT POSITION
    index = (index + 1) % totalNumSteps -- increment position

    isStarting = false

    -- REMOVE COMPLETED NOTES
    local keep = {}
    for _,note in ipairs(notes) do
      if note.steps > note.stepCounter then
        -- Keep note if more steps than counter is currently on
        table.insert(keep, note)
      end
    end
    notes = keep -- Refresh notes table

    -- WAIT FOR NEXT BEAT
    waitBeat(mainBeatDuration)
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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local chordDefinitionInputData = {}
  local chordDefinitionSlotsData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    table.insert(chordDefinitionInputData, paramsPerPart[i].chordDefinitionInput.text)
    for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
      table.insert(chordDefinitionSlotsData, v.tooltip)
    end
  end

  return {numStepsData, chordDefinitionInputData, chordDefinitionSlotsData}
end

function onLoad(data)
  local numStepsData = data[1]
  local chordDefinitionInputData = data[2]
  local chordDefinitionSlotsData = data[3]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].chordDefinitionInput.text = chordDefinitionInputData[i]
    for _,v in ipairs(paramsPerPart[i].chordDefinitionSlots) do
      v.tooltip = chordDefinitionSlotsData[dataCounter]
      v.enabled = v.tooltip ~= "Unused"
      dataCounter = dataCounter + 1
    end
  end
end
