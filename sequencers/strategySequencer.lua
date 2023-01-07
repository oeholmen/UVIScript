--------------------------------------------------------------------------------
-- Strategy Sequencer
--------------------------------------------------------------------------------

local gem = require "includes.common"
local notes = require "includes.notes"
local resolutions = require "includes.resolutions"
local scales = require "includes.scales"
local subdiv = require "includes.subdivision"

local backgroundColour = "4c4c4c" -- Light or Dark
local widgetBackgroundColour = "2E0249" -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local labelBackgoundColour = widgetBackgroundColour
local menuOutlineColour = "5f" .. widgetTextColour
local sliderColour = "5FB5FF"
local selectedPartColour = "cc33cc44"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local isPlaying = false
local heldNotes = {}
local notePosition = 0 -- Holds the current note position
local partToStepMap = {1} -- Holds the starting step for each part
local totalNumSteps = 8
local paramsPerPart = {}
local partSelect = {}
local numParts = 1

local scaleDefinitions = scales.getScaleDefinitions()
local scaleNames = scales.getScaleNames()
local noteNames = notes.getNoteNames()

-- Strategies are ways to play chords and scales
local strategies = {
  {}, -- Randomize next note position +/- 1 oct
  {1}, -- Up
  {-1}, -- Down
  {2,-1}, -- Alternate up
  {-2,1}, -- Alternate down
  {-1,1,-2,-1,3}, -- Generated 1
  {3,1,-1,2}, -- Generated 2
  {-3,2}, -- Generated 3
  {2,2,3}, -- Up v 2
  {-3,-2,-2}, -- Down v 2
  {3,-2,7},
  {-5,4,4},
  {7,7,-5},
  {7,5,6},
  {-7,2,7},
  {7,0,-7},
  {4,0,-4},
  {0},
  {4,-2},
  {3,-2},
}

local strategyIndex = gem.getRandom(#strategies) -- Holds the selected strategy - start with a random strategy
local structureMemory = {} -- Holds the most recent structure memory
local maxStoredStructures = 100 -- Max stored structures
local noteNumberToNoteName = notes.getNoteMapping()

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

function getNotePositionFromHeldNotes(partPos, scale)
  local minNote = paramsPerPart[partPos].minNote.value
  local maxNote = paramsPerPart[partPos].maxNote.value
  local noteInput = notes.transpose(notes.getNoteAccordingToScale(scale, heldNotes[#heldNotes].note), minNote, maxNote)
  local index = gem.getIndexFromValue(noteInput, scale)
  print("Resetting to noteInput/notePosition", noteInput, index)
  return index
end

function getNoteFromStrategy(notePosition, strategyIndex, strategyPos, partPos)
  local scale = paramsPerPart[partPos].fullScale
  local minNote = notes.getNoteAccordingToScale(scale, paramsPerPart[partPos].minNote.value)
  local maxNote = notes.getNoteAccordingToScale(scale, paramsPerPart[partPos].maxNote.value)
  local strategy = {}
  local input = paramsPerPart[partPos].strategyInput
  if input.enabled == true and string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(strategy, w)
      print("Add to strategy", w)
    end
    print("Get strategy from input", #strategy)
  end
  if #strategy == 0 then
    strategy = strategies[strategyIndex]
  end
  -- Reset strategy position
  if strategyPos > #strategy then
    strategyPos = 1
    if paramsPerPart[partPos].strategyRestart.value == 3 or paramsPerPart[partPos].strategyRestart.value == 4 then
      notePosition = 0 -- Reset counter for note position
      print("Reset counter for note position")
    end
  end
  print("Get strategy strategyIndex/strategyPos", strategyIndex, strategyPos)
  if notePosition == 0 then
    -- Start at the last held note
    notePosition = getNotePositionFromHeldNotes(partPos, scale)
    if paramsPerPart[partPos].strategyRestart.value == 1 then
      strategyPos = 1
    end
  else
    -- Get next notePosition from strategy
    if #strategy == 0 then -- Strategy random
      local offset = gem.getRandom(-12,12) -- 1 oct +/-
      local note = scale[notePosition] -- Get the current note from scale
      note = note + offset -- Change within the offset
      note = notes.transpose(notes.getNoteAccordingToScale(scale, note), minNote, maxNote) -- Endure within scale and limits
      notePosition = gem.getIndexFromValue(note, scale)
      print("Set increment by random notePosition/note/offset(in semitones)/#scale", notePosition, note, offset, #scale)
    else
      notePosition = notePosition + strategy[strategyPos]
      print("Set notePosition/strategyPos", notePosition, strategy[strategyPos])
    end
    if type(scale[notePosition]) == "nil" then
      -- This is just a safeguard if scale is changed while playing
      notePosition = 1
      return minNote, notePosition, strategyPos
    end
    if scale[notePosition] > maxNote then
      print("Reset scale[notePosition] > maxNote", scale[notePosition], maxNote)
      -- TODO Param for options
      -- Option 1: Transpose to lowest octave in range
      --local transposedNote = transpose(scale[notePosition], minNote, (minNote+12))
      --notePosition = gem.getIndexFromValue(transposedNote, scale)
      -- Option 2: Reset to the input note from heldnotes
      notePosition = getNotePositionFromHeldNotes(partPos, scale)
      if paramsPerPart[partPos].strategyRestart.value == 2 then
        strategyPos = 1
      end
    elseif scale[notePosition] < minNote then
      print("Reset scale[notePosition] < minNote", scale[notePosition], minNote)
      -- TODO Param for options
      -- Option 1: Transpose to top octave
      local transposedNote = notes.transpose(scale[notePosition], (maxNote-12), maxNote)
      notePosition = gem.getIndexFromValue(transposedNote, scale)
      -- Option 2: Reset to the input note from heldnotes
      --notePosition = getNotePositionFromHeldNotes(partPos, scale)
      if paramsPerPart[partPos].strategyRestart.value == 2 then
        strategyPos = 1
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos = strategyPos + 1
        print("Increment strategy pos", strategyPos)
      end
    end
  end
  local note = scale[notePosition]
  return note, notePosition, strategyPos
end

function getFilteredScale(part, minNote, maxNote)
  local filteredScale = {}
  if type(minNote) ~= "number" then
    minNote = paramsPerPart[part].minNote.value
  end
  if type(maxNote) ~= "number" then
    maxNote = paramsPerPart[part].maxNote.value
  end
  if #paramsPerPart[part].fullScale > 0 then
    -- Filter out notes outside min/max
    for i=1,#paramsPerPart[part].fullScale do
      if paramsPerPart[part].fullScale[i] >= minNote and paramsPerPart[part].fullScale[i] <= maxNote then
        table.insert(filteredScale, paramsPerPart[part].fullScale[i])
      end
    end
  end
  --print("Filtered scale contains notes:", #paramsPerPart[part].filteredScale)
  return filteredScale
end

function createFullScale(part)
  -- Find scale definition
  local definition = scaleDefinitions[paramsPerPart[part].scale.value]
  -- Find root note
  local root = paramsPerPart[part].key.value - 1
  -- Create scale
  paramsPerPart[part].fullScale = scales.createScale(definition, root)
end

function getVelocity(part, step, skipRandomize)
  local seqVelTable = paramsPerPart[part].seqVelTable
  local velocity = seqVelTable:getValue(step) -- get velocity

  -- Skip randomize
  if skipRandomize == true then
    return velocity
  end

  -- Randomize velocity
  return gem.randomizeValue(velocity, seqVelTable.min, seqVelTable.max, paramsPerPart[part].velRandomization.value)
end

function getGate(part, step, skipRandomize)
  local seqGateTable = paramsPerPart[part].seqGateTable
  local gate = seqGateTable:getValue(step)

  -- Skip randomize
  if skipRandomize == true then
    return gate
  end

  -- Randomize gate
  return gem.randomizeValue(gate, seqGateTable.min, seqGateTable.max, paramsPerPart[part].gateRandomization.value)
end

function createStrategy(part)
  local numSteps = paramsPerPart[part].numStepsBox.value
  local maxLength = math.min(math.ceil(numSteps * 0.75), 9) -- TODO Param
  local strategy = {} -- Table to hold strategy
  local ln = gem.getRandom(maxLength) -- Length
  for i=1, ln do
    local value = gem.getRandom(-7,7)
    table.insert(strategy, value)
    print("Add value to strategy", value)
  end
  return strategy
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 700
local tableX = 0
local boxWidth = 108

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = tableWidth
sequencerPanel.height = 380

local label = sequencerPanel:Label("Label")
label.text = "Strategy Sequencer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {170,25}

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = sequencerPanel:Menu("ChannelInput", channels)
channelInput.tooltip = "Only listen to notes on this channel"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = (sequencerPanel.width / 2) - 25
channelInput.y = 0

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = backgroundColourOff
focusButton.backgroundColourOn = backgroundColourOn
focusButton.textColourOff = textColourOff
focusButton.textColourOn = textColourOn
focusButton.displayName = "Focus Part"
focusButton.tooltip = "When focus is active, only the part selected for editing is shown and played"
focusButton.size = channelInput.size
focusButton.x = channelInput.x + channelInput.width + 5
focusButton.y = 0
focusButton.changed = function(self)
  setTableWidths()
end

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = backgroundColourOff
holdButton.backgroundColourOn = backgroundColourOn
holdButton.textColourOff = textColourOff
holdButton.textColourOn = textColourOn
holdButton.displayName = "Hold"
holdButton.size = channelInput.size
holdButton.x = focusButton.x + focusButton.width + 5
holdButton.y = 0
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
  end
end

local muteButton = sequencerPanel:OnOffButton("MuteOnOff", false)
muteButton.backgroundColourOff = backgroundColourOff
muteButton.backgroundColourOn = backgroundColourOn
muteButton.textColourOff = textColourOff
muteButton.textColourOn = textColourOn
muteButton.displayName = "Mute"
muteButton.tooltip = "Mute all incoming notes"
muteButton.size = channelInput.size
muteButton.x = holdButton.x + holdButton.width + 5
muteButton.y = 0
muteButton.changed = function(self)
  heldNotes = {}
end

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = widgetTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit part"
editPartMenu.showLabel = false
editPartMenu.y = 65
editPartMenu.x = 0
editPartMenu.width = boxWidth / 2
editPartMenu.height = 20
editPartMenu.changed = function(self)
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i

    if isVisible then
      v.partsTable.backgroundColour = selectedPartColour
    elseif i % 2 == 0 then
      v.partsTable.backgroundColour = "3c" .. sliderColour
    else
      v.partsTable.backgroundColour = "1a" .. sliderColour
    end

    v.numStepsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.minNoteSteps.visible = isVisible
    v.maxNoteSteps.visible = isVisible
    v.minNote.visible = isVisible
    v.maxNote.visible = isVisible
    v.key.visible = isVisible
    v.scale.visible = isVisible
    v.strategyInput.visible = isVisible
    v.createStrategyButton.visible = isVisible
    v.autoStrategyButton.visible = isVisible
    v.slotStrategyButton.visible = isVisible
    v.strategyPropbability.visible = isVisible
    v.strategyRestart.visible = isVisible
    v.strategyActions.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.subdivisionProbability.visible = isVisible
    v.subdivisionRepeatProbability.visible = isVisible
    v.subdivisionDotProbability.visible = isVisible
    v.subdivisionTieProbability.visible = isVisible
    v.stepRepeatProbability.visible = isVisible
    v.structureMemoryMenu.visible = isVisible
    v.subdivisionMinResolution.visible = isVisible
    for _,s in ipairs(v.subdivisions) do
      s.visible = isVisible
    end
    for _,s in ipairs(v.strategySlots) do
      s.visible = isVisible
    end
  end
  setTableWidths()
end

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = widgetTextColour
numPartsBox.width = (boxWidth / 2) - 2
numPartsBox.height = 20
numPartsBox.x = editPartMenu.x + editPartMenu.width + 2
numPartsBox.y = editPartMenu.y
numPartsBox.changed = function(self)
  for _,v in ipairs(paramsPerPart) do
    v.partsTable.visible = false
    v.positionTable.visible = false
    v.seqVelTable.visible = false
    v.seqGateTable.visible = false
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
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].scale.value = prev.scale.value
      paramsPerPart[i].strategyInput.value = prev.strategyInput.value
      paramsPerPart[i].strategyPropbability.value = prev.strategyPropbability.value
      paramsPerPart[i].strategyRestart.value = prev.strategyRestart.value
      paramsPerPart[i].autoStrategyButton.value = prev.autoStrategyButton.value
      paramsPerPart[i].slotStrategyButton.value = prev.slotStrategyButton.value
      paramsPerPart[i].minNote.value = prev.minNote.value
      paramsPerPart[i].maxNote.value = prev.maxNote.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].fullScale = prev.fullScale
      paramsPerPart[i].velRandomization.value = prev.velRandomization.value
      paramsPerPart[i].gateRandomization.value = prev.gateRandomization.value
      paramsPerPart[i].subdivisionProbability.value = prev.subdivisionProbability.value
      paramsPerPart[i].subdivisionRepeatProbability.value = prev.subdivisionRepeatProbability.value
      paramsPerPart[i].subdivisionDotProbability.value = prev.subdivisionDotProbability.value
      paramsPerPart[i].subdivisionTieProbability.value = prev.subdivisionTieProbability.value
      paramsPerPart[i].stepRepeatProbability.value = prev.stepRepeatProbability.value
      paramsPerPart[i].structureMemoryMenu.value = prev.structureMemoryMenu.value
      paramsPerPart[i].subdivisionMinResolution.value = prev.subdivisionMinResolution.value
      paramsPerPart[i].init = prev.init
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
partRandBox.width = boxWidth
partRandBox.x = editPartMenu.x
partRandBox.y = editPartMenu.y + editPartMenu.height + 5

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
  isPlaying = true
  spawn(arpeg)
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
    --local isVisible = true
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

    paramsPerPart[i].seqVelTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqVelTable.visible = isVisible
    paramsPerPart[i].seqVelTable.width = partTableWidth
    paramsPerPart[i].seqVelTable.x = x

    paramsPerPart[i].seqGateTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqGateTable.visible = isVisible
    paramsPerPart[i].seqGateTable.width = partTableWidth
    paramsPerPart[i].seqGateTable.x = x

    x = x + partTableWidth
  end
end

function getStrategyInputText(strategy)
  if #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

local subdivisionProbabilityLabel = sequencerPanel:Label("SubdivisionProbabilityLabel")
subdivisionProbabilityLabel.text = "Subdivision"

local strategyLabel = sequencerPanel:Label("StrategyLabel")
strategyLabel.text = "Strategy"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  local storedStructures = {} -- Used to store rythmic structures
  local storedStructuresPos = 1 -- Menu position for storing structure

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
  
  local seqVelTable = sequencerPanel:Table("Velocity" .. i, totalNumSteps, 100, 1, 127, true)
  seqVelTable.tooltip = "Set step velocity. Randomization available in settings."
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = sliderColour
  seqVelTable.width = positionTable.width
  seqVelTable.height = 70
  seqVelTable.x = positionTable.x
  seqVelTable.y = partRandBox.y + 136
  
  local seqGateTable = sequencerPanel:Table("Gate" .. i, totalNumSteps, 100, 0, 120, true)
  seqGateTable.tooltip = "Set step gate length. Randomization available in settings."
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = sliderColour
  seqGateTable.width = seqVelTable.width
  seqGateTable.height = seqVelTable.height
  seqGateTable.x = seqVelTable.x
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 5

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, totalNumSteps, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps can a note last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = widgetTextColour
  generateMinNoteStepsPart.enabled = false
  generateMinNoteStepsPart.width = boxWidth
  generateMinNoteStepsPart.x = editPartMenu.x + boxWidth + 10
  generateMinNoteStepsPart.y = editPartMenu.y

  local generateMaxNoteStepsPart = sequencerPanel:NumBox("GenerateMaxNoteSteps" .. i, 1, 1, totalNumSteps, true)
  generateMaxNoteStepsPart.displayName = "Max Steps"
  generateMaxNoteStepsPart.tooltip = "The maximium number of steps can a note last"
  generateMaxNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMaxNoteStepsPart.textColour = widgetTextColour
  generateMaxNoteStepsPart.width = generateMinNoteStepsPart.width
  generateMaxNoteStepsPart.x = generateMinNoteStepsPart.x
  generateMaxNoteStepsPart.y = generateMinNoteStepsPart.y + generateMinNoteStepsPart.height + 5
  generateMaxNoteStepsPart.changed = function(self)
    generateMinNoteStepsPart:setRange(1, self.value)
    generateMinNoteStepsPart.enabled = self.value > 1
  end

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
  stepResolution.displayName = "Step Duration"
  stepResolution.tooltip = "The duration of each step in the part"
  stepResolution.selected = 20
  stepResolution.showLabel = false
  stepResolution.height = 20
  stepResolution.width = generateMaxNoteStepsPart.width
  stepResolution.x = generateMinNoteStepsPart.x + generateMinNoteStepsPart.width + 10
  stepResolution.y = generateMinNoteStepsPart.y
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = widgetTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    setNumSteps(i)
  end

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, totalNumSteps, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = widgetTextColour
  numStepsBox.width = stepResolution.width
  numStepsBox.x = stepResolution.x
  numStepsBox.y = stepResolution.y + stepResolution.height + 5
  numStepsBox.changed = function(self)
    setNumSteps(i)
    generateMinNoteStepsPart:setRange(1, self.value)
    generateMaxNoteStepsPart:setRange(1, self.value)
  end

  local generateMinPart = sequencerPanel:NumBox("GenerateMin" .. i, 24, 0, 127, true)
  generateMinPart.unit = Unit.MidiKey
  generateMinPart.showPopupDisplay = true
  generateMinPart.showLabel = true
  generateMinPart.backgroundColour = menuBackgroundColour
  generateMinPart.textColour = widgetTextColour
  generateMinPart.displayName = "Min Note"
  generateMinPart.tooltip = "Lowest note"
  generateMinPart.x = stepResolution.x + stepResolution.width + 10
  generateMinPart.y = stepResolution.y
  generateMinPart.width = stepResolution.width

  local generateMaxPart = sequencerPanel:NumBox("GenerateMax" .. i, 84, 0, 127, true)
  generateMaxPart.unit = Unit.MidiKey
  generateMaxPart.showPopupDisplay = true
  generateMaxPart.showLabel = true
  generateMaxPart.backgroundColour = menuBackgroundColour
  generateMaxPart.textColour = widgetTextColour
  generateMaxPart.displayName = "Max Note"
  generateMaxPart.tooltip = "Highest note"
  generateMaxPart.x = generateMinPart.x
  generateMaxPart.y = generateMinPart.y + generateMinPart.height + 5
  generateMaxPart.width = generateMinPart.width

  generateMinPart.changed = function(self)
    generateMaxPart:setRange(self.value, 127)
  end

  generateMaxPart.changed = function(self)
    generateMinPart:setRange(0, self.value)
  end

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, noteNames)
  generateKeyPart.tooltip = "Key"
  generateKeyPart.showLabel = false
  generateKeyPart.height = 20
  generateKeyPart.width = boxWidth
  generateKeyPart.x = generateMinPart.x + generateMinPart.width + 10
  generateKeyPart.y = stepResolution.y
  generateKeyPart.backgroundColour = menuBackgroundColour
  generateKeyPart.textColour = widgetTextColour
  generateKeyPart.arrowColour = menuArrowColour
  generateKeyPart.outlineColour = menuOutlineColour
  generateKeyPart.changed = function(self)
    createFullScale(i)
  end

  local generateScalePart = sequencerPanel:Menu("GenerateScale" .. i, scaleNames)
  generateScalePart.tooltip = "Scale"
  generateScalePart.showLabel = false
  generateScalePart.height = 20
  generateScalePart.width = boxWidth
  generateScalePart.x = generateKeyPart.x
  generateScalePart.y = generateKeyPart.y + generateKeyPart.height + 5
  generateScalePart.backgroundColour = menuBackgroundColour
  generateScalePart.textColour = widgetTextColour
  generateScalePart.arrowColour = menuArrowColour
  generateScalePart.outlineColour = menuOutlineColour
  generateScalePart.changed = function(self)
    createFullScale(i)
  end

  local velRandomization = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRandomization.displayName = "Velocity"
  velRandomization.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandomization.unit = Unit.Percent
  velRandomization.width = boxWidth
  velRandomization.x = generateKeyPart.x + generateKeyPart.width + 10
  velRandomization.y = editPartMenu.y
  velRandomization.backgroundColour = menuBackgroundColour
  velRandomization.textColour = widgetTextColour

  local gateRandomization = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRandomization.displayName = "Gate"
  gateRandomization.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandomization.unit = Unit.Percent
  gateRandomization.width = boxWidth
  gateRandomization.x = velRandomization.x
  gateRandomization.y = velRandomization.y + velRandomization.height + 5
  gateRandomization.backgroundColour = menuBackgroundColour
  gateRandomization.textColour = widgetTextColour

  if i == 1 then
    subdivisionProbabilityLabel.width = boxWidth
    subdivisionProbabilityLabel.x = generateMinPart.x
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 10
  end

  local subdivisions = {}
  for j=1,3 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, (j<3))
    subdivision.backgroundColourOff = backgroundColourOff
    subdivision.backgroundColourOn = backgroundColourOn
    subdivision.textColourOff = textColourOff
    subdivision.textColourOn = textColourOn
    subdivision.displayName = "" .. j
    if j == 1 then
      subdivision.tooltip = "Activate base - subdivision bases will divide until the minimum resolution is reached"
    else
      subdivision.tooltip = "When base 1 is active, subdivisions will stop when 1 is selected, either by random, or if probability is 0"
    end
    subdivision.height = 20
    subdivision.width = 33
    subdivision.x = subdivisionProbabilityLabel.x + ((j-1) * (subdivision.width+4))
    subdivision.y = subdivisionProbabilityLabel.y + subdivisionProbabilityLabel.height + 5
    table.insert(subdivisions, subdivision)
  end

  local subdivisionProbability = sequencerPanel:NumBox("SubdivisionProbability" .. i, 25, 0, 100, true)
  subdivisionProbability.displayName = "Probability"
  subdivisionProbability.tooltip = "Probability that active subdivisions will be selected by random - if set to 0, the first selected subdivision will be used"
  subdivisionProbability.unit = Unit.Percent
  subdivisionProbability.width = boxWidth
  subdivisionProbability.x = subdivisionProbabilityLabel.x
  subdivisionProbability.y = subdivisions[1].y + subdivisions[1].height + 5
  subdivisionProbability.backgroundColour = menuBackgroundColour
  subdivisionProbability.textColour = widgetTextColour

  local subdivisionRepeatProbability = sequencerPanel:NumBox("SubdivisionRepeatProbability" .. i, 0, 0, 100, true)
  subdivisionRepeatProbability.displayName = "Note Repeat"
  subdivisionRepeatProbability.tooltip = "What is the probability that the same note will be played in the subdivision, meaning that the same note is repeated?"
  subdivisionRepeatProbability.unit = Unit.Percent
  subdivisionRepeatProbability.width = boxWidth
  subdivisionRepeatProbability.x = subdivisionProbability.x
  subdivisionRepeatProbability.y = subdivisionProbability.y + subdivisionProbability.height + 5
  subdivisionRepeatProbability.backgroundColour = menuBackgroundColour
  subdivisionRepeatProbability.textColour = widgetTextColour

  local subdivisionMinResolution = sequencerPanel:Menu("SubdivisionMinResolution" .. i, resolutions.getResolutionNames())
  subdivisionMinResolution.displayName = "Min Resolution"
  subdivisionMinResolution.showLabel = false
  subdivisionMinResolution.height = 20
  subdivisionMinResolution.tooltip = "This is the lowest resolution when using subdivisions"
  subdivisionMinResolution.selected = 23
  subdivisionMinResolution.x = subdivisionProbabilityLabel.x + subdivisionProbabilityLabel.width + 10
  subdivisionMinResolution.y = subdivisions[1].y --subdivisionProbabilityLabel.y
  subdivisionMinResolution.width = boxWidth
  subdivisionMinResolution.backgroundColour = menuBackgroundColour
  subdivisionMinResolution.textColour = widgetTextColour
  subdivisionMinResolution.arrowColour = menuArrowColour
  subdivisionMinResolution.outlineColour = menuOutlineColour

  local subdivisionDotProbability = sequencerPanel:NumBox("SubdivisionDotProbability" .. i, 25, 0, 100, true)
  subdivisionDotProbability.displayName = "Dotted"
  subdivisionDotProbability.tooltip = "What is the probability that there will be dotted subdivisions?"
  subdivisionDotProbability.unit = Unit.Percent
  subdivisionDotProbability.width = boxWidth
  subdivisionDotProbability.x = subdivisionMinResolution.x
  subdivisionDotProbability.y = subdivisionMinResolution.y + subdivisionMinResolution.height + 5
  subdivisionDotProbability.backgroundColour = menuBackgroundColour
  subdivisionDotProbability.textColour = widgetTextColour

  local subdivisionTieProbability = sequencerPanel:NumBox("SubdivisionMultistepProbability" .. i, 25, 0, 100, true)
  subdivisionTieProbability.displayName = "Ties"
  subdivisionTieProbability.tooltip = "What is the probability that there will be ties in subdivisions?"
  subdivisionTieProbability.unit = Unit.Percent
  subdivisionTieProbability.width = boxWidth
  subdivisionTieProbability.x = subdivisionDotProbability.x
  subdivisionTieProbability.y = subdivisionDotProbability.y + subdivisionDotProbability.height + 5
  subdivisionTieProbability.backgroundColour = menuBackgroundColour
  subdivisionTieProbability.textColour = widgetTextColour

  local stepRepeatProbability = sequencerPanel:NumBox("StepRepeatProbability" .. i, 90, 0, 100, true)
  stepRepeatProbability.displayName = "Memory"
  stepRepeatProbability.tooltip = "Probability that the rythmic structure of a previous step will be repeated."
  stepRepeatProbability.unit = Unit.Percent
  stepRepeatProbability.width = boxWidth
  stepRepeatProbability.x = subdivisionMinResolution.x + subdivisionMinResolution.width + 10
  stepRepeatProbability.y = subdivisionMinResolution.y
  stepRepeatProbability.backgroundColour = menuBackgroundColour
  stepRepeatProbability.textColour = widgetTextColour

  local structureMemoryMenu = sequencerPanel:Menu("StructureMemoryMenu" .. i, {"Load memory..."})
  structureMemoryMenu.displayName = "Structure"
  structureMemoryMenu.enabled = false
  structureMemoryMenu.showLabel = false
  structureMemoryMenu.height = 20
  structureMemoryMenu.tooltip = "Load a stored structure to memory"
  structureMemoryMenu.x = stepRepeatProbability.x
  structureMemoryMenu.y = stepRepeatProbability.y + stepRepeatProbability.height + 5
  structureMemoryMenu.width = boxWidth
  structureMemoryMenu.backgroundColour = menuBackgroundColour
  structureMemoryMenu.textColour = widgetTextColour
  structureMemoryMenu.arrowColour = menuArrowColour
  structureMemoryMenu.outlineColour = menuOutlineColour
  structureMemoryMenu.changed = function(self)
    local memoryIndex = self.value - 1
    if memoryIndex > 0 then
      structureMemory = paramsPerPart[i].storedStructures[memoryIndex]
      stepRepeatProbability:setValue(100)
      print("Loaded structure " .. memoryIndex, #paramsPerPart[i].storedStructures)
    end
  end

  if i == 1 then
    strategyLabel.x = editPartMenu.x
    strategyLabel.y = subdivisionProbabilityLabel.y
    strategyLabel.width = boxWidth
    --strategyLabel.backgroundColour = "red"
  end

  -- TODO Add param for strategy probability decay?
  local strategyPropbability = sequencerPanel:NumBox("StrategyPropbability" .. i, 100, 0, 100, true)
  strategyPropbability.displayName = "Probability"
  strategyPropbability.tooltip = "Set the probability that a playing strategy will be used to select the next note. Otherwise notes will be selected by random from the current scale."
  strategyPropbability.unit = Unit.Percent
  strategyPropbability.height = 20
  strategyPropbability.width = boxWidth
  strategyPropbability.x = strategyLabel.x
  strategyPropbability.y = strategyLabel.y + strategyLabel.height + 5
  strategyPropbability.backgroundColour = menuBackgroundColour
  strategyPropbability.textColour = widgetTextColour

  local strategyRestart = sequencerPanel:Menu("StrategyRestart" .. i, {"Restart each round", "Out of range", "When finished", "Finished+round"})
  strategyRestart.tooltip = "Choose when a strategy restarts"
  strategyRestart.showLabel = false
  strategyRestart.height = 20
  strategyRestart.width = strategyPropbability.width
  strategyRestart.x = strategyPropbability.x
  strategyRestart.y = strategyPropbability.y + strategyPropbability.height + 5
  strategyRestart.backgroundColour = menuBackgroundColour
  strategyRestart.textColour = widgetTextColour
  strategyRestart.arrowColour = menuArrowColour
  strategyRestart.outlineColour = menuOutlineColour

  local strategyInput = sequencerPanel:Label("StrategyInput" .. i)
  strategyInput.text = getStrategyInputText(strategies[strategyIndex])
  strategyInput.tooltip = "Strategies are ways to play chords and scales. Numbers represent steps up or down the scale or chord that is currently playing. Feel free to type your own strategies here."
  strategyInput.editable = true
  strategyInput.backgroundColour = menuBackgroundColour
  strategyInput.backgroundColourWhenEditing = "black"
  strategyInput.textColour = labelTextColour
  strategyInput.textColourWhenEditing = "white"
  strategyInput.x = generateMaxNoteStepsPart.x
  strategyInput.y = strategyPropbability.y
  strategyInput.width = boxWidth * 2.1
  strategyInput.height = 45
  strategyInput.fontSize = 30

  local actions = {"Actions..."}
  local strategySlots = {}
  for j=1,9 do
    local strategySlot = sequencerPanel:OnOffButton("StrategySlot" .. i .. j)
    strategySlot.backgroundColourOff = backgroundColourOff
    strategySlot.backgroundColourOn = backgroundColourOn
    strategySlot.textColourOff = textColourOff
    strategySlot.textColourOn = textColourOn
    strategySlot.displayName = "" .. j
    strategySlot.enabled = false
    strategySlot.tooltip = "Unused"
    strategySlot.height = 20
    strategySlot.width = 24
    strategySlot.x = strategyInput.x + ((j-1) * (strategySlot.width+1.2))
    strategySlot.y = strategyInput.y + strategyInput.height + 5
    strategySlot.changed = function(self)
      strategyInput.text = strategySlot.tooltip
      self.value = false
    end
    table.insert(strategySlots, strategySlot)
    table.insert(actions, "Save to " .. j)
  end

  table.insert(actions, "--- Load ---")
  for _,v in ipairs(strategies) do
    table.insert(actions, getStrategyInputText(v))
  end

  local strategyActions = sequencerPanel:Menu("StrategyActions" .. i, actions)
  strategyActions.tooltip = "Choose when a strategy restarts"
  strategyActions.showLabel = false
  strategyActions.height = 20
  strategyActions.width = strategyRestart.width
  strategyActions.x = strategyRestart.x
  strategyActions.y = strategyRestart.y + strategyRestart.height + 5
  strategyActions.backgroundColour = menuBackgroundColour
  strategyActions.textColour = widgetTextColour
  strategyActions.arrowColour = menuArrowColour
  strategyActions.outlineColour = menuOutlineColour
  strategyActions.changed = function(self)
    -- 1 is the menu label...
    if self.value == 1 then
      return
    end

    local actionIndex = self.value - 1

    -- Save strategy
    if actionIndex <= #strategySlots then
      if string.len(strategyInput.text) > 0 then
        strategySlots[actionIndex].tooltip = strategyInput.text
        strategySlots[actionIndex].enabled = true
      else
        strategySlots[actionIndex].tooltip = "Unused"
        strategySlots[actionIndex].enabled = false
      end
      print("Strategy saved to slot", strategyInput.text, actionIndex)
    elseif actionIndex > #strategySlots + 1 then
      strategyInput.text = self.selectedText
      strategyIndex = actionIndex - #strategySlots - 1
      print("Strategy index selected", strategyIndex)
    end

    -- Must be last
    self.selected = 1
  end

  local autoStrategyButton = sequencerPanel:OnOffButton("AutoStrategyButton" .. i, false)
  autoStrategyButton.displayName = "Auto"
  autoStrategyButton.tooltip = "Strategies are automatically created and randomly changed while playing."
  autoStrategyButton.backgroundColourOff = backgroundColourOff
  autoStrategyButton.backgroundColourOn = backgroundColourOn
  autoStrategyButton.textColourOff = textColourOff
  autoStrategyButton.textColourOn = textColourOn
  autoStrategyButton.width = boxWidth / 2 - 2
  autoStrategyButton.x = generateMaxNoteStepsPart.x
  autoStrategyButton.y = strategyLabel.y

  local slotStrategyButton = sequencerPanel:OnOffButton("SlotStrategyButton" .. i, false)
  slotStrategyButton.displayName = "Slots"
  slotStrategyButton.tooltip = "Strategies are selected from the slots."
  slotStrategyButton.backgroundColourOff = backgroundColourOff
  slotStrategyButton.backgroundColourOn = backgroundColourOn
  slotStrategyButton.textColourOff = textColourOff
  slotStrategyButton.textColourOn = textColourOn
  slotStrategyButton.width = boxWidth / 2 - 2
  slotStrategyButton.x = autoStrategyButton.x + autoStrategyButton.width + 5
  slotStrategyButton.y = autoStrategyButton.y

  local createStrategyButton = sequencerPanel:Button("CreateStrategyButton" .. i)
  createStrategyButton.displayName = "Create"
  createStrategyButton.tooltip = "Replace the current strategy with a new one."
  createStrategyButton.persistent = false
  createStrategyButton.width = slotStrategyButton.width
  createStrategyButton.x = slotStrategyButton.x + slotStrategyButton.width + 5
  createStrategyButton.y = slotStrategyButton.y

  autoStrategyButton.changed = function(self)
    slotStrategyButton:setValue(false, false)
    notePosition = 0 -- Reset note position
    strategyInput.enabled = self.value == false
    createStrategyButton.enabled = self.value == false
  end

  slotStrategyButton.changed = function(self)
    autoStrategyButton:setValue(false, false)
    notePosition = 0 -- Reset note position
    strategyInput.enabled = true
    createStrategyButton.enabled = true
  end

  createStrategyButton.changed = function()
    local strategy = createStrategy(i)
    strategyInput.text = table.concat(strategy, ",")
  end

  table.insert(paramsPerPart, {storedStructures=storedStructures,storedStructuresPos=storedStructuresPos,strategySlots=strategySlots,strategyActions=strategyActions,strategyRestart=strategyRestart,subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,structureMemoryMenu=structureMemoryMenu,stepRepeatProbability=stepRepeatProbability,subdivisionTieProbability=subdivisionTieProbability,subdivisionDotProbability=subdivisionDotProbability,subdivisionRepeatProbability=subdivisionRepeatProbability,subdivisionMinResolution=subdivisionMinResolution,velRandomization=velRandomization,gateRandomization=gateRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,numStepsBox=numStepsBox,stepResolution=stepResolution,fullScale={},scale=generateScalePart,key=generateKeyPart,createStrategyButton=createStrategyButton,strategyInput=strategyInput,autoStrategyButton=autoStrategyButton,slotStrategyButton=slotStrategyButton,strategyPropbability=strategyPropbability,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})

  createFullScale(i)
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function playSubdivision(structure, partPos)
  for i,node in ipairs(structure.notes) do
    local gate = getGate(partPos, structure.step)
    local waitDuration = node.duration
    local playDuration = resolutions.getPlayDuration(node.duration, gate)
    local noteToPlay = node.note
    print("PlaySubdivision partPos/i/noteToPlay/noteName/waitDuration/playDuration/gate", partPos, i, noteToPlay, noteNumberToNoteName[noteToPlay+1], waitDuration, playDuration, gate)
    playNote(noteToPlay, getVelocity(partPos, structure.step), beat2ms(playDuration)-1)
    waitBeat(waitDuration)
  end
end

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentRound = 0 -- Counter for rounds
  local currentPartPosition = 1 -- Holds the currently playing part
  local playingNotes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local isStarting = true
  local strategyPos = 1 -- Holds the position in the selected strategy
  --local slotIndex = 1 -- Holds the slot index when slot strategy is active
  print("Start playing!")

  -- START ARP LOOP
  while isPlaying do

    local offset = 0
    if #heldNotes == 0 then
      local buffer = 1 -- How long to wait for notes before stopping the sequencer
      wait(buffer)
      print("waiting for heldNotes", buffer)
      offset = offset + buffer
    end
    if #heldNotes == 0 then
      print("#heldNotes == 0 - stopping sequencer")
      stopPlaying()
      break
    end

    local currentPosition = (index % totalNumSteps) + 1
    local startOfPart = false
    local partWasChanged = false
    print("currentPosition/currentPartPosition", currentPosition, currentPartPosition)

    -- Set part position
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        -- Set start of part
        startOfPart = true
        currentRound = currentRound + 1 -- Increment round counter
        -- Update part position
        partWasChanged = currentPartPosition ~= pp
        currentPartPosition = pp
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
      elseif (isStarting == false or partRandBox.value > 50) and gem.getRandomBoolean(partRandBox.value) then
        -- Randomize parts within the set limit
        print("currentPartPosition before", currentPartPosition)
        print("currentPosition before", currentPosition)
        --print("index before", index)
        local randomPartPosition = gem.getRandom(numParts)
        partWasChanged = currentPartPosition ~= randomPartPosition
        currentPartPosition = randomPartPosition
      end
      -- Find the current pos and index
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
    end

    local mainBeatDuration = resolutions.getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local minResolution = resolutions.getResolution(paramsPerPart[currentPartPosition].subdivisionMinResolution.value)
    local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
    local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value
    local stepRepeatProbability = paramsPerPart[currentPartPosition].stepRepeatProbability.value
    local subdivisionProbability = paramsPerPart[currentPartPosition].subdivisionProbability.value
    local subdivisionRepeatProbability = paramsPerPart[currentPartPosition].subdivisionRepeatProbability.value
    local subdivisionDotProbability = paramsPerPart[currentPartPosition].subdivisionDotProbability.value
    local subdivisionTieProbability = paramsPerPart[currentPartPosition].subdivisionTieProbability.value
    local subdivisions = paramsPerPart[currentPartPosition].subdivisions

    if startOfPart == true then
      -- Create a random strategy
      local maxStrategies = 32
      -- TODO Add a counter for createStrategyPosition
      local autoStrategy = paramsPerPart[currentPartPosition].autoStrategyButton.value
      local slotStrategy = paramsPerPart[currentPartPosition].slotStrategyButton.value
      if autoStrategy == true and (currentRound % paramsPerPart[currentPartPosition].numStepsBox.value) - 1 == 0 then
        if #strategies > maxStrategies then
          strategies = {}
          print("Clear strategies")
        end
        local strategy = createStrategy(currentPartPosition)
        table.insert(strategies, strategy)
        -- TODO Set limit? Follow maxStrategies?
        -- Check for duplicates
        local strategyText = table.concat(strategy, ",")
        local wasFound = false
        for _,v in ipairs(paramsPerPart[currentPartPosition].strategyActions.items) do
          if v == strategyText then
            wasFound = true
            break
          end
        end
        if wasFound == false then
          paramsPerPart[currentPartPosition].strategyActions:addItem(table.concat(strategy, ","))
        end
        print("Created #strategy/#strategies", #strategy, #strategies)
      end
      if autoStrategy == true then
        strategyIndex = gem.getRandom(#strategies)
        paramsPerPart[currentPartPosition].strategyInput.text = getStrategyInputText(strategies[strategyIndex])
      end
      if slotStrategy == true then
        local strategySlots = {}
        for _,v in ipairs(paramsPerPart[currentPartPosition].strategySlots) do
          if v.enabled == true then
            table.insert(strategySlots, v)
          end
        end
        --[[ if type(slotIndex) == "number" then
          strategySlots[slotIndex]:setValue(true)
        else ]]
          if #strategySlots > 0 then
            strategySlots[gem.getRandom(#strategySlots)]:setValue(true)
          end
        --end
        --[[ slotIndex = slotIndex + 1
        if slotIndex > #strategySlots then
          slotIndex = nil
        end ]]
      end
      if paramsPerPart[currentPartPosition].strategyRestart.value == 1 or paramsPerPart[currentPartPosition].strategyRestart.value == 4 then
        notePosition = 0 -- Reset counter for note position
        if paramsPerPart[currentPartPosition].strategyRestart.value == 4 then
          strategyPos = 1 -- Reset strategy position
        end
      end
    end

    -- Get current position in the table
    local startStep = partToStepMap[currentPartPosition]
    local tablePos = currentPosition - startStep + 1

    --------------------------------------------------------------------------------
    -- Note functions
    --------------------------------------------------------------------------------

    -- Note generator function
    local function getNoteToPlay()
      local function generateNote(nodePos)
        local note = nil
        local strategyPropbability = paramsPerPart[currentPartPosition].strategyPropbability.value
        if gem.getRandomBoolean(strategyPropbability) == true then
          note, notePosition, strategyPos = getNoteFromStrategy(notePosition, strategyIndex, strategyPos, currentPartPosition)
          print("Get note from scale using strategy: note/strategyPos/strategyIndex", note, strategyPos, strategyIndex)
        else
          local scale = getFilteredScale(currentPartPosition)
          note = scale[gem.getRandom(#scale)]
          print("Get random note from scale: note/minNote/maxNote", note, minNote, maxNote)
        end
        return note
      end

      local function generateStructure(steps, stepDuration, currentDepth, stop)
        if type(stepDuration) == "nil" then
          stepDuration = mainBeatDuration
        end

        if type(currentDepth) == "nil" then
          currentDepth = 0
        end

        local subdivision, subDivDuration, remainderDuration, stop = subdiv.getSubdivision(stepDuration, steps, minResolution, subdivisionProbability, subdivisions, stop, subdivisionDotProbability)
        print("Got subdivision/currentDepth", subdivision, currentDepth)

        -- Check for minimum duration
        local subdivisionStructures = {}
        if subdivision > 1 then
          currentDepth = currentDepth + 1
          print("Incrementing depth/stepDuration/subDivDuration", currentDepth, stepDuration, subDivDuration)
          local dotted = subDivDuration > remainderDuration
          local subDivPos = 1
          while subDivPos <= subdivision do
            local subdivisionSteps = 1 -- Set default
            if dotted == false then
              subdivisionSteps, stop = subdiv.getSubdivisionSteps(subdivision, subDivPos, subdivisionTieProbability)
            elseif subDivPos == subdivision then
              -- Use the remainder on the last step when dotted subdivision
              subDivDuration = remainderDuration
            end
            -- Create the recursive structure tree
            print("Generating structure for subdivisionNum/subdivisionSteps/subDivDuration/currentDepth", subDivPos, subdivisionSteps, subDivDuration, currentDepth)
            local subdivisionStructure = generateStructure(subdivisionSteps, subDivDuration, currentDepth, stop)
            table.insert(subdivisionStructures, subdivisionStructure)
            subDivPos = subDivPos + subdivisionSteps -- Increment pos
          end
        end

        return {
          steps = steps,
          stepDuration = stepDuration,
          subdivision = subdivision,
          children = subdivisionStructures,
        }
      end

      -- Get the number of steps this structure will last
      local steps = gem.getRandom(minNoteSteps, maxNoteSteps)

      -- Adjust steps so note does not last beyond the part length
      local maxSteps = (paramsPerPart[currentPartPosition].numStepsBox.value - tablePos) + 1
      if steps > maxSteps then
        print("maxSteps/steps", maxSteps, steps)
        steps = maxSteps
      end

      local nodes = {}

      if gem.getRandomBoolean(stepRepeatProbability) and #structureMemory > 0 then
        nodes = structureMemory -- Load structure from memory
        print("Load structure from memory")
      else
        local function parseTree(structureTree)
          -- Traverse the tree until we find the levels with no child nodes
          for i=1,structureTree.subdivision do
            if #structureTree.children == 0 then
              local nodeDuration = structureTree.stepDuration*structureTree.steps
              table.insert(nodes, {duration=nodeDuration})
              print("Added node duration", nodeDuration)
            else
              print("Parsing further down the tree #children/subdvision", #structureTree.children, structureTree.subdivision)
              if type(structureTree.children[i]) == "table" then
                parseTree(structureTree.children[i]) -- Parse next level
              end
            end
          end
        end
  
        local structureTree = generateStructure(steps, mainBeatDuration) -- Gets the structrure / rythmic pattern to use
        parseTree(structureTree) -- Parses the tree and finds the nodes on the lowest level
        print("Generated #nodes/step", #nodes, tablePos)
        structureMemory = nodes
        -- Do not store if repeat probability is off
        if stepRepeatProbability > 0 then
          table.insert(paramsPerPart[currentPartPosition].storedStructures, structureMemory)
          local storedStructuresPos = paramsPerPart[currentPartPosition].storedStructuresPos
          local structureMemoryMenu = paramsPerPart[currentPartPosition].structureMemoryMenu
          if #structureMemoryMenu.items > storedStructuresPos then
            structureMemoryMenu:setItem((storedStructuresPos+1), "Structure " .. storedStructuresPos)
          else
            structureMemoryMenu:addItem("Structure " .. storedStructuresPos)
            structureMemoryMenu.enabled = true
          end
          structureMemoryMenu:setValue((storedStructuresPos + 1), false)
          paramsPerPart[currentPartPosition].storedStructuresPos = storedStructuresPos + 1
          if paramsPerPart[currentPartPosition].storedStructuresPos > maxStoredStructures then
            paramsPerPart[currentPartPosition].storedStructuresPos = 1
          end
        end
      end

      -- Get notes for each node in the tree
      nodes = subdiv.setNotesOnNodes(nodes, subdivisionRepeatProbability, generateNote)
      local notesToPlay = {
        notes = nodes,
        step = tablePos,
        steps = steps,
        stepCounter = 0
      }

      return notesToPlay
    end

    --------------------------------------------------------------------------------
    -- Play this step - If gate is set to zero, no notes will play on this step
    --------------------------------------------------------------------------------

    if getGate(currentPartPosition, tablePos) > 0 and #playingNotes == 0 then
      table.insert(playingNotes, getNoteToPlay())
      print("Added note for step", tablePos)
    end

    -- PLAY NOTE
    for _,note in ipairs(playingNotes) do
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 then
        run(playSubdivision, note, currentPartPosition)
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
    for _,note in ipairs(playingNotes) do
      if note.steps > note.stepCounter then
        -- Keep note if more steps than counter is currently on
        table.insert(keep, note)
      end
    end
    playingNotes = keep -- Refresh notes table

    -- WAIT FOR NEXT BEAT
    waitBeat(mainBeatDuration)
  end
end

--------------------------------------------------------------------------------
-- Handle note events
--------------------------------------------------------------------------------

function onController(e)
  if e.controller == 3 then
    muteButton:setValue(e.value == 0)
  end
  postEvent(e)
end

function onNote(e)
  if muteButton.value == true then
    return
  end
  local channel = channelInput.value - 1
  local playNote = channel == 0 or e.channel == channel
  print("channel/e.channel/note/playNote", channel, e.channel, e.note, playNote)
  if playNote == false then
    postEvent(e)
    return
  end

  if holdButton.value == true then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        -- When hold button is active
        -- we remove the note from held notes
        -- if table has more than one note
        if #heldNotes > 1 then
          table.remove(heldNotes, i)
        end
        break
      end
    end
  end
  notePosition = 0
  table.insert(heldNotes, e)
  if #heldNotes == 1 and isPlaying == false then
    startPlaying()
  end
end

function onRelease(e)
  local channel = channelInput.value - 1
  local playNote = channel == 0 or e.channel == channel
  if playNote == false then
    postEvent(e)
    return
  end

  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqVelTableData = {}
  local seqGateTableData = {}
  local strategyInputData = {}
  local strategySlotsData = {}
  local strategyActionsData = {}
  local storedStructuresData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    table.insert(strategyInputData, paramsPerPart[i].strategyInput.text)
    table.insert(strategyActionsData, paramsPerPart[i].strategyActions.items)
    table.insert(storedStructuresData, paramsPerPart[i].storedStructures)
    for _,v in ipairs(paramsPerPart[i].strategySlots) do
      table.insert(strategySlotsData, v.tooltip)
    end
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
    end
  end

  return {numStepsData, seqVelTableData, seqGateTableData, strategyInputData, strategySlotsData, strategyActionsData, storedStructuresData}
end

function onLoad(data)
  local numStepsData = data[1]
  local seqVelTableData = data[2]
  local seqGateTableData = data[3]
  local strategyInputData = data[4]
  local strategySlotsData = data[5]
  local strategyActionsData = data[6]
  local storedStructuresData = data[7]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  local strategySlotsDataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].storedStructures = storedStructuresData[i]
    for j=1,#paramsPerPart[i].storedStructures do
      paramsPerPart[i].structureMemoryMenu:addItem("Structure " .. j)
    end
    paramsPerPart[i].storedStructuresPos = #paramsPerPart[i].storedStructures + 1
    if paramsPerPart[i].storedStructuresPos > maxStoredStructures then
      paramsPerPart[i].storedStructuresPos = 1
    end
    paramsPerPart[i].structureMemoryMenu.enabled = #paramsPerPart[i].storedStructures > 0
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].strategyActions.items = strategyActionsData[i]
    paramsPerPart[i].strategyInput.text = strategyInputData[i]
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    for _,v in ipairs(paramsPerPart[i].strategySlots) do
      v.tooltip = strategySlotsData[strategySlotsDataCounter]
      v.enabled = v.tooltip ~= "Unused"
      strategySlotsDataCounter = strategySlotsDataCounter + 1
    end
    for j=1, v do
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
