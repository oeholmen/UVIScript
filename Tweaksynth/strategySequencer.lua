--------------------------------------------------------------------------------
-- GENEREATIVE SEQUENCER
--------------------------------------------------------------------------------

require "common"

local backgroundColour = "#5f5f5f"
local labelBackgoundColour = "#111D5E"
local labelTextColour = "#fefefe"
local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#000000"
local isPlaying = false
local heldNotes = {}
local notePosition = 0 -- Holds the current note position
local partToStepMap = {1} -- Holds the starting step for each part
local partRandomizationAmount = 0
local totalNumSteps = 8
local paramsPerPart = {}
local partSelect = {}
local numParts = 1
-- Make sure these are in sync with the scale names!
local scaleDefinitions = {
  {1}, -- 12 tone
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2}, -- Whole tone scale
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {5,2,5},
  {7,5},
  {12},
  {3},
  {5},
  {7}
}
local scaleNames = {
  "12 tone",
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Whole tone",
  "Major Pentatonic",
  "Minor Pentatonic",
  "1-4-5",
  "1-5",
  "1",
  "Dim",
  "Fours",
  "Fives"
}
-- *** NOTE *** The chord definitions use steps in the selected scale, not semitones.
-- 2 means two steps up the scale: C-E for a C major scale. A-C for an A minor scale.
-- Keep in sync with chordDefinitionNames!
local chordDefinitions = {
  {2,2,3}, -- Builds triads
  {2,2,2,1}, -- Builds 7th chords
  {3,1,3}, -- Builds supended chords
  {2,2,1,2}, -- Builds 6th chords
  {2}, -- Builds 7/9/11/13 chords
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
}
local chordDefinitionNames = {
  "Triads",
  "7th",
  "Sus",
  "6th",
  "7/9/11/13",
  "7th/9th",
}
-- Strategies are ways to play chords and scales
local strategies = {
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
}
local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local noteNumberToNoteName = {} -- Used for mapping - does not include octave, only name of note (C, C#...)
local notenamePos = 1
for i=0,127 do
  table.insert(noteNumberToNoteName, notenames[notenamePos])
  notenamePos = notenamePos + 1
  if notenamePos > #notenames then
    notenamePos = 1
  end
end

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

function getNotePositionFromHeldNotes(partPos, scale)
  local minNote = paramsPerPart[partPos].minNote.value
  local maxNote = paramsPerPart[partPos].maxNote.value
  local noteInput = transpose(getNoteAccordingToScale(scale, heldNotes[#heldNotes].note), minNote, maxNote)  
  local index = getIndexFromValue(noteInput, scale)
  print("Resetting to noteInput/notePosition", noteInput, index)
  return index
end

function getNoteFromStrategy(notePosition, strategyIndex, strategyPos, partPos)
  local minNote = paramsPerPart[partPos].minNote.value
  local maxNote = paramsPerPart[partPos].maxNote.value
  local scale = paramsPerPart[partPos].fullScale
  local strategy = {}
  local input = paramsPerPart[partPos].strategyInput
  if input.enabled == true and string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d") do
      table.insert(strategy, w)
      print("Add to strategy", w)
    end
    print("Get strategy from input", #strategy)
  else
    strategy = strategies[strategyIndex]
  end
  -- Reset strategy position
  if strategyPos > #strategy then
    strategyPos = 1
    if paramsPerPart[partPos].strategyRestart.value == 3 or paramsPerPart[partPos].strategyRestart.value == 4 then
      notePosition = 0 -- Reset counter for note position
    end
  end
  print("Get strategy strategyIndex, strategyPos, increment, notePosition", strategyIndex, strategyPos, strategy[strategyPos], notePosition)
  if notePosition == 0 then
    -- Start at the last held note
    notePosition = getNotePositionFromHeldNotes(partPos, scale)
    if paramsPerPart[partPos].strategyRestart.value == 1 then
      strategyPos = 1
    end
  else
    -- Get next notePosition from strategy
    notePosition = notePosition + strategy[strategyPos]
    print("Set notePosition", notePosition)
    if scale[notePosition] > maxNote then
      print("Reset scale[notePosition] > maxNote", scale[notePosition], maxNote)
      -- TODO Param for options
      -- Option 1: Transpose to lowest octave in range
      --local transposedNote = transpose(scale[notePosition], minNote, (minNote+12))
      --notePosition = getIndexFromValue(transposedNote, scale)
      -- Option 2: Reset to the input note from heldnotes
      notePosition = getNotePositionFromHeldNotes(partPos, scale)
      if paramsPerPart[partPos].strategyRestart.value == 2 then
        strategyPos = 1
      end
    elseif scale[notePosition] < minNote then
      print("Reset scale[notePosition] < minNote", scale[notePosition], minNote)
      -- TODO Param for options
      -- Option 1: Transpose to top octave
      local transposedNote = transpose(scale[notePosition], (maxNote-12), maxNote)
      notePosition = getIndexFromValue(transposedNote, scale)
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

function canHarmonizeScale(selectedScale)
  -- We can only harmonize scales with 7 notes
  return #scaleDefinitions[selectedScale.value] == 7
end

function createFullScale(part)
  paramsPerPart[part].fullScale = {}
  -- Find scale definition
  local definition = scaleDefinitions[paramsPerPart[part].scale.value]
  -- Find root note
  local root = paramsPerPart[part].key.value - 1
  -- Find notes for scale
  local pos = 0
  while root < 128 do
    table.insert(paramsPerPart[part].fullScale, root)
    pos = pos + 1
    root = root + definition[pos]
    if pos == #definition then
      pos = 0
    end
  end
  --print("Full scale contains notes:", #paramsPerPart[part].fullScale)
end

function getNoteAccordingToScale(scale, noteToPlay)
  for _,note in ipairs(scale) do
    if note == noteToPlay then
      return noteToPlay
    elseif note > noteToPlay then
      print("Change from noteToPlay to note", noteToPlay, note)
      return note
    end
  end
  return noteToPlay
end

function getVelocity(part, step, skipRandomize)
  local seqVelTable = paramsPerPart[part].seqVelTable
  local velocity = seqVelTable:getValue(step) -- get velocity

  -- Skip randomize
  if skipRandomize == true then
    return velocity
  end

  -- Randomize velocity
  local velRandomization = paramsPerPart[part].velRandomization.value
  if getRandomBoolean(velRandomization) then
    local changeMax = getChangeMax(seqVelTable.max, velRandomization)
    local min = velocity - changeMax
    local max = velocity + changeMax
    if min < seqVelTable.min then
      min = seqVelTable.min
    end
    if max > seqVelTable.max then
      max = seqVelTable.max
    end
    --print("Before randomize vel", vel)
    velocity = getRandom(min, max)
    --print("After randomize vel/changeMax/min/max", vel, changeMax, min, max)
  end

  return velocity
end

function createStrategy(part)
  local numSteps = paramsPerPart[part].numStepsBox.value
  local maxLength = math.min(math.ceil(numSteps * 0.75), 9) -- TODO Param
  local strategy = {} -- Table to hold strategy
  local ln = getRandom(maxLength) -- Length
  for i=1, ln do
    local value = getRandom(-7,7)
    table.insert(strategy, value)
    print("Add value to strategy", value)
  end
  return strategy
end

function getGate(part, step, skipRandomize)
  local seqGateTable = paramsPerPart[part].seqGateTable
  local gate = seqGateTable:getValue(step)

  -- Skip randomize
  if skipRandomize == true then
    return gate
  end

  -- Randomize gate
  local gateRandomization = paramsPerPart[part].gateRandomization.value
  if getRandomBoolean(gateRandomization) then
    local changeMax = getChangeMax(seqGateTable.max, gateRandomization)
    local min = gate - changeMax
    local max = gate + changeMax
    if min < seqGateTable.min then
      min = seqGateTable.min
    end
    if max > seqGateTable.max then
      max = seqGateTable.max
    end
    --print("Before randomize gate", gate)
    gate = getRandom(min, max)
    --print("After randomize gate/changeMax/min/max", gate, changeMax, min, max)
  end

  return gate
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
sequencerPanel.height = 350

local label = sequencerPanel:Label("Label")
label.text = "Strategy Sequencer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {170,25}

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = "#ff084486"
focusButton.backgroundColourOn = "#ff02ACFE"
focusButton.textColourOff = "#ff22FFFF"
focusButton.textColourOn = "#efFFFFFF"
focusButton.displayName = "Focus Part"
focusButton.tooltip = "When focus is active, only the part selected for editing is shown and played"
focusButton.fillColour = "#dd000061"
focusButton.size = {102,22}
focusButton.x = (sequencerPanel.width / 2) + 140
focusButton.y = 0
focusButton.changed = function(self)
  setTableWidths()
end

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {102,22}
holdButton.x = focusButton.x + focusButton.width + 5
holdButton.y = 0
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
  end
end

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = menuTextColour
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
      v.partsTable.backgroundColour = "#cc33cc44"
    elseif i % 2 == 0 then
      v.partsTable.backgroundColour = "#3f09A3F4"
    else
      v.partsTable.backgroundColour = "#1f09A3F4"
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
    v.strategyPropbability.visible = isVisible
    v.strategyRestart.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.subdivisionProbability.visible = isVisible
    v.subdivisionRepeatProbability.visible = isVisible
    v.subdivisionMinResolution.visible = isVisible
    for _,s in ipairs(v.subdivisions) do
      s.visible = isVisible
    end
  end
  setTableWidths()
end

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
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
partRandBox.textColour = menuTextColour
partRandBox.displayName = "Part Order"
partRandBox.tooltip = "Amount of radomization applied to the order of playing parts"
partRandBox.unit = Unit.Percent
partRandBox.width = boxWidth
partRandBox.x = editPartMenu.x
partRandBox.y = editPartMenu.y + editPartMenu.height + 5
partRandBox.changed = function(self)
  partRandomizationAmount = self.value
end

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

local subdivisionProbabilityLabel = sequencerPanel:Label("SubdivisionProbabilityLabel")
subdivisionProbabilityLabel.text = "Subdivision"

local strategyLabel = sequencerPanel:Label("StrategyLabel")
strategyLabel.text = "Strategy"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  local partsTable = sequencerPanel:Table("Parts" .. i, 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  partsTable.backgroundColour = "#1f09A3F4"
  partsTable.sliderColour = "#5FB5FF"
  partsTable.width = tableWidth
  partsTable.height = 10
  partsTable.x = 0
  partsTable.y = label.height + 10
  
  local positionTable = sequencerPanel:Table("Position" .. i, totalNumSteps, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  positionTable.backgroundColour = menuTextColour
  positionTable.sliderColour = outlineColour
  positionTable.width = partsTable.width
  positionTable.height = partsTable.height
  positionTable.x = partsTable.x
  positionTable.y = partsTable.y + partsTable.height
  
  local seqVelTable = sequencerPanel:Table("Velocity" .. i, totalNumSteps, 100, 1, 127, true)
  seqVelTable.tooltip = "Set step velocity. Randomization available in settings."
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = menuArrowColour
  seqVelTable.width = positionTable.width
  seqVelTable.height = 70
  seqVelTable.x = positionTable.x
  seqVelTable.y = partRandBox.y + 102
  
  local seqGateTable = sequencerPanel:Table("Gate" .. i, totalNumSteps, 100, 0, 120, true)
  seqGateTable.tooltip = "Set step gate length. Randomization available in settings."
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = menuArrowColour
  seqGateTable.width = seqVelTable.width
  seqGateTable.height = seqVelTable.height
  seqGateTable.x = seqVelTable.x
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 5

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, totalNumSteps, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps can a note last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = menuTextColour
  generateMinNoteStepsPart.enabled = false
  generateMinNoteStepsPart.width = boxWidth
  generateMinNoteStepsPart.x = editPartMenu.x + boxWidth + 10
  generateMinNoteStepsPart.y = editPartMenu.y

  local generateMaxNoteStepsPart = sequencerPanel:NumBox("GenerateMaxNoteSteps" .. i, 1, 1, totalNumSteps, true)
  generateMaxNoteStepsPart.displayName = "Max Steps"
  generateMaxNoteStepsPart.tooltip = "The maximium number of steps can a note last"
  generateMaxNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMaxNoteStepsPart.textColour = menuTextColour
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
  stepResolution.selected = 20
  stepResolution.showLabel = false
  stepResolution.height = 20
  stepResolution.width = generateMaxNoteStepsPart.width
  stepResolution.x = generateMinNoteStepsPart.x + generateMinNoteStepsPart.width + 10
  stepResolution.y = generateMinNoteStepsPart.y
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    setNumSteps(i)
  end

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, totalNumSteps, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
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
  generateMinPart.textColour = menuTextColour
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
  generateMaxPart.textColour = menuTextColour
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

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, notenames)
  generateKeyPart.tooltip = "Key"
  generateKeyPart.showLabel = false
  generateKeyPart.height = 20
  generateKeyPart.width = generateMaxPart.width
  generateKeyPart.x = generateMinPart.x + generateMinPart.width + 10
  generateKeyPart.y = stepResolution.y
  generateKeyPart.backgroundColour = menuBackgroundColour
  generateKeyPart.textColour = menuTextColour
  generateKeyPart.arrowColour = menuArrowColour
  generateKeyPart.outlineColour = menuOutlineColour
  generateKeyPart.changed = function(self)
    createFullScale(i)
  end

  local generateScalePart = sequencerPanel:Menu("GenerateScale" .. i, scaleNames)
  generateScalePart.tooltip = "Scale"
  generateScalePart.showLabel = false
  generateScalePart.height = 20
  generateScalePart.width = generateKeyPart.width
  generateScalePart.x = generateKeyPart.x
  generateScalePart.y = generateKeyPart.y + generateKeyPart.height + 5
  generateScalePart.backgroundColour = menuBackgroundColour
  generateScalePart.textColour = menuTextColour
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
  velRandomization.textColour = menuTextColour

  local gateRandomization = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRandomization.displayName = "Gate"
  gateRandomization.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandomization.unit = Unit.Percent
  gateRandomization.width = velRandomization.width
  gateRandomization.x = velRandomization.x
  gateRandomization.y = velRandomization.y + velRandomization.height + 5
  gateRandomization.backgroundColour = menuBackgroundColour
  gateRandomization.textColour = menuTextColour

  if i == 1 then
    subdivisionProbabilityLabel.width = boxWidth
    subdivisionProbabilityLabel.x = generateScalePart.x
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
  end

  local subdivisions = {}
  for j=1,4 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, (j<3))
    subdivision.backgroundColourOff = "#ff084486"
    subdivision.backgroundColourOn = "#ff02ACFE"
    subdivision.textColourOff = "#ff22FFFF"
    subdivision.textColourOn = "#efFFFFFF"
    subdivision.displayName = "" .. j
    subdivision.tooltip = "Activate subdivision"
    subdivision.height = 20
    subdivision.width = 25
    subdivision.x = subdivisionProbabilityLabel.x + ((j-1) * (subdivision.width+2.8))
    subdivision.y = subdivisionProbabilityLabel.y + subdivisionProbabilityLabel.height + 5
    table.insert(subdivisions, subdivision)
  end

  local subdivisionProbability = sequencerPanel:NumBox("SubdivisionProbability" .. i, 25, 0, 100, true)
  subdivisionProbability.displayName = "Probability"
  subdivisionProbability.tooltip = "Probability that subdivisions will occur"
  subdivisionProbability.unit = Unit.Percent
  subdivisionProbability.width = generateScalePart.width
  subdivisionProbability.x = subdivisionProbabilityLabel.x
  subdivisionProbability.y = subdivisions[1].y + subdivisions[1].height + 5
  subdivisionProbability.backgroundColour = menuBackgroundColour
  subdivisionProbability.textColour = menuTextColour

  local subdivisionMinResolution = sequencerPanel:Menu("SubdivisionMinResolution" .. i, getResolutionNames())
  subdivisionMinResolution.displayName = "Min Resolution"
  subdivisionMinResolution.tooltip = "This is the lowest resolution when using subdivisions"
  subdivisionMinResolution.selected = 23
  subdivisionMinResolution.x = velRandomization.x
  subdivisionMinResolution.y = subdivisionProbabilityLabel.y
  subdivisionMinResolution.width = velRandomization.width
  subdivisionMinResolution.backgroundColour = menuBackgroundColour
  subdivisionMinResolution.textColour = menuTextColour
  subdivisionMinResolution.arrowColour = menuArrowColour
  subdivisionMinResolution.outlineColour = menuOutlineColour

  local subdivisionRepeatProbability = sequencerPanel:NumBox("SubdivisionRepeatProbability" .. i, 0, 0, 100, true)
  subdivisionRepeatProbability.displayName = "Repeat"
  subdivisionRepeatProbability.tooltip = "What is the probability that the same note will be played in the subdivision, meaning that the same note is repeated?"
  subdivisionRepeatProbability.unit = Unit.Percent
  subdivisionRepeatProbability.width = subdivisionMinResolution.width
  subdivisionRepeatProbability.x = subdivisionMinResolution.x
  subdivisionRepeatProbability.y = subdivisionMinResolution.y + subdivisionMinResolution.height + 5
  subdivisionRepeatProbability.backgroundColour = menuBackgroundColour
  subdivisionRepeatProbability.textColour = menuTextColour

  if i == 1 then
    strategyLabel.x = editPartMenu.x
    strategyLabel.y = subdivisionProbabilityLabel.y
    strategyLabel.width = boxWidth
  end

  -- TODO Add param for strategy probability decay?
  local strategyPropbability = sequencerPanel:NumBox("StrategyPropbability" .. i, 100, 0, 100, true)
  strategyPropbability.displayName = "Probability"
  strategyPropbability.tooltip = "Set the probability that a playing strategy will be used to select the next note. Otherwise notes will be selected by random from the current scale."
  strategyPropbability.unit = Unit.Percent
  strategyPropbability.height = 20
  strategyPropbability.width = boxWidth + 20
  strategyPropbability.x = strategyLabel.x
  strategyPropbability.y = strategyLabel.y + strategyLabel.height + 5
  strategyPropbability.backgroundColour = menuBackgroundColour
  strategyPropbability.textColour = menuTextColour

  local strategyRestart = sequencerPanel:Menu("StrategyRestart" .. i, {"Restart each round", "Out of range", "When finished", "Finished+round"})
  strategyRestart.tooltip = "Choose when a strategy restarts"
  strategyRestart.showLabel = false
  strategyRestart.height = 20
  strategyRestart.width = strategyPropbability.width
  strategyRestart.x = strategyPropbability.x
  strategyRestart.y = strategyPropbability.y + strategyPropbability.height + 5
  strategyRestart.backgroundColour = menuBackgroundColour
  strategyRestart.textColour = menuTextColour
  strategyRestart.arrowColour = menuArrowColour
  strategyRestart.outlineColour = menuOutlineColour

  local autoStrategyButton = sequencerPanel:OnOffButton("AutoStrategyButton" .. i, false)
  autoStrategyButton.displayName = "Auto"
  autoStrategyButton.tooltip = "Strategies are automatically created and randomly changed while playing."
  autoStrategyButton.backgroundColourOff = "#ff084486"
  autoStrategyButton.backgroundColourOn = "#ff02ACFE"
  autoStrategyButton.textColourOff = "#ff22FFFF"
  autoStrategyButton.textColourOn = "#efFFFFFF"
  autoStrategyButton.width = 60
  autoStrategyButton.x = strategyPropbability.x + strategyPropbability.width + 5
  autoStrategyButton.y = strategyPropbability.y

  local createStrategyButton = sequencerPanel:Button("CreateStrategyButton" .. i)
  createStrategyButton.displayName = "Create"
  createStrategyButton.tooltip = "Replace the current strategy with a new one."
  createStrategyButton.persistent = false
  createStrategyButton.width = 60
  createStrategyButton.x = autoStrategyButton.x
  createStrategyButton.y = autoStrategyButton.y + autoStrategyButton.height + 5

  local strategyInput = sequencerPanel:Label("StrategyInput" .. i)
  strategyInput.text = table.concat(strategies[getRandom(#strategies)], ",")
  strategyInput.tooltip = "Strategies are ways to play chords and scales. Numbers represent steps up or down the scale or chord that is currently playing. Feel free to type your own strategies here."
  strategyInput.editable = true
  strategyInput.backgroundColour = menuBackgroundColour
  strategyInput.backgroundColourWhenEditing = "purple"
  strategyInput.textColour = "#00ee00"
  strategyInput.textColourWhenEditing = "white"
  strategyInput.x = autoStrategyButton.x + autoStrategyButton.width + 10
  strategyInput.y = autoStrategyButton.y
  strategyInput.width = 260
  strategyInput.height = 45
  strategyInput.fontSize = 24

  autoStrategyButton.changed = function(self)
    notePosition = 0 -- Reset note position
    strategyInput.enabled = self.value == false
    createStrategyButton.enabled = self.value == false
  end

  createStrategyButton.changed = function()
    local strategy = createStrategy(i)
    strategyInput.text = table.concat(strategy, ",")
  end

  table.insert(paramsPerPart, {strategyRestart=strategyRestart,subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,subdivisionRepeatProbability=subdivisionRepeatProbability,subdivisionMinResolution=subdivisionMinResolution,velRandomization=velRandomization,gateRandomization=gateRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,numStepsBox=numStepsBox,stepResolution=stepResolution,fullScale={},scale=generateScalePart,key=generateKeyPart,createStrategyButton=createStrategyButton,strategyInput=strategyInput,autoStrategyButton=autoStrategyButton,strategyPropbability=strategyPropbability,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})

  createFullScale(i)
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function playSubdivision(note, partPos)
  local scale = paramsPerPart[partPos].fullScale
  local waitDuration = (note.stepDuration * note.steps) / note.subdivision
  for i=1,note.subdivision do
    if #note.notes == 0 then
      local gate = getGate(partPos, note.step)
      if gate > 0 then
        local playDuration = waitDuration * (gate / 100)
        local noteToPlay = note.note
        print("PlaySubdivision partPos/i/noteToPlay/noteName/duration/subdivision", partPos, i, noteToPlay, noteNumberToNoteName[noteToPlay+1], playDuration, note.subdivision)
        playNote(noteToPlay, getVelocity(partPos, note.step), beat2ms(playDuration)-1)
      end
    else
      local subDivisionNote = note.notes[i]
      run(playSubdivision, subDivisionNote, partPos)
    end
    waitBeat(waitDuration)
  end
end

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentRound = 0 -- Counter for rounds
  local currentPartPosition = 1 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local isStarting = true
  local strategyIndex = 1 -- Holds the selected strategy
  local strategyPos = 1 -- Holds the position in the selected strategy
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
      elseif isStarting == false and getRandomBoolean(partRandomizationAmount) then
        -- Randomize parts within the set limit, unless we are in startup mode
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
    end

    local mainBeatDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)

    if startOfPart == true then
      -- Create a random strategy
      local maxStrategies = 32
      -- TODO Add a counter for createStrategyPosition
      local autoStrategy = paramsPerPart[currentPartPosition].autoStrategyButton.value
      if autoStrategy == true and (currentRound % paramsPerPart[currentPartPosition].numStepsBox.value) - 1 == 0 then
        if #strategies > maxStrategies then
          strategies = {}
          print("Clear strategies")
        end
        local strategy = createStrategy(currentPartPosition)
        table.insert(strategies, strategy)
        print("Created #strategy/#strategies", #strategy, #strategies)
      end
      strategyIndex = getRandom(#strategies)
      -- TODO Param for how often strategy is changed
      if autoStrategy == true then
        paramsPerPart[currentPartPosition].strategyInput.text = table.concat(strategies[strategyIndex], ",")
      end
      if paramsPerPart[currentPartPosition].strategyRestart.value == 1 or paramsPerPart[currentPartPosition].strategyRestart.value == 4 then
        notePosition = 0 -- Reset counter for note position
        if paramsPerPart[currentPartPosition].strategyRestart.value == 4 then
          strategyPos = 1 -- Reset strategy position
        end
      end
    end

    -- Get subdivision info
    local subdivisionRepeatProbability = paramsPerPart[currentPartPosition].subdivisionRepeatProbability.value
    local subdivisions = {}
    for i,v in ipairs(paramsPerPart[currentPartPosition].subdivisions) do
      if v.value == true then
        table.insert(subdivisions, i)
        print("Added subdivision", i)
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
      -- Get the subdivision to use
      local function getSubdivision(currentDepth)
        local subdivisionProbability = paramsPerPart[currentPartPosition].subdivisionProbability.value
        -- Calculate depth decay
        -- TODO If decay, there should be a setting for it...
        if currentDepth > 1 then
          subdivisionProbability = math.ceil(subdivisionProbability / (currentDepth / 2)) -- TODO Adjust
          print("subdivisionProbability/currentDepth", subdivisionProbability, currentDepth)
        end
        local subdivision = 1 -- Set default
        if #subdivisions == 1 then
          subdivision = subdivisions[1]
          print("SET SELECTED subdivision", subdivision)
        elseif #subdivisions > 1 and getRandomBoolean(subdivisionProbability) then
          subdivision = subdivisions[getRandom(#subdivisions)]
          print("SET RANDOM subdivision", subdivision)
        end
        return subdivision
      end

      local function getNote(stepDuration, currentDepth)
        if type(stepDuration) == "nil" then
          stepDuration = mainBeatDuration
        end

        if type(currentDepth) == "nil" then
          currentDepth = 0
        end

        local subdivision = getSubdivision(currentDepth)
        print("Got subdivision/currentDepth", subdivision, currentDepth)

        local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
        local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value
        local hasHarmonizeableScale = canHarmonizeScale(paramsPerPart[currentPartPosition].scale)
        local minResolution = getResolution(paramsPerPart[currentPartPosition].subdivisionMinResolution.value)
        local steps = getRandom(minNoteSteps, maxNoteSteps)

        if currentDepth == 0 then
          -- Adjust steps so note does not last beyond the part length
          local maxSteps = (paramsPerPart[currentPartPosition].numStepsBox.value - tablePos) + 1
          if steps > maxSteps then
            print("maxSteps/steps", maxSteps, steps)
            steps = maxSteps
          end
        else
          -- When we are not on the top level, always play just one step.
          -- Variation in length are handled by subdivsions at the lower levels.
          steps = 1
        end

        local note = nil
        --local scale = getFilteredScale(currentPartPosition)
        --local scale = paramsPerPart[currentPartPosition].fullScale
        local strategyPropbability = paramsPerPart[currentPartPosition].strategyPropbability.value
        if getRandomBoolean(strategyPropbability) == true then
          note, notePosition, strategyPos = getNoteFromStrategy(notePosition, strategyIndex, strategyPos, currentPartPosition)
          print("Get note from scale using strategy: note/strategyPos/strategyIndex", note, strategyPos, strategyIndex)
        else
          local scale = getFilteredScale(currentPartPosition)
          note = scale[getRandom(#scale)]
          print("Get random note from scale: note/minNote/maxNote", note, minNote, maxNote)
        end

        -- Check for minimum duration
        local subdivisionNotes = {}
        local subDivDuration = (stepDuration * steps) / subdivision
        if subDivDuration < minResolution then
          subdivision = 1
        end
        if subdivision > 1 then
          currentDepth = currentDepth + 1
          print("Incrementing depth/stepDuration/subDivDuration", currentDepth, stepDuration, subDivDuration)
          for i=1,subdivision do
            local subDivNote = getNote(subDivDuration, currentDepth)
            if i == 1 or getRandomBoolean(subdivisionRepeatProbability) then
              subDivNote.note = note
            end
            table.insert(subdivisionNotes, subDivNote)
            print("generateSubdivision note/subdivisionNum/subDivDuration/currentDepth", subDivNote.note, i, subDivDuration, currentDepth)
          end
        end

        print("Generated note", note)

        return {
          note = note,
          step = tablePos,
          steps = steps,
          stepDuration = stepDuration,
          subdivision = subdivision,
          notes = subdivisionNotes,
          stepCounter = 0
        }
      end
    
      return getNote()
    end

    --------------------------------------------------------------------------------
    -- Play this step - If gate is set to zero, no notes will play on this step
    --------------------------------------------------------------------------------

    if getGate(currentPartPosition, tablePos) > 0 and #notes == 0 then
      table.insert(notes, getNoteToPlay())
      print("Added note for step", tablePos)
    end

    -- PLAY NOTE
    for _,note in ipairs(notes) do
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

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    table.insert(strategyInputData, paramsPerPart[i].strategyInput.text)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
    end
  end

  return {numStepsData, seqVelTableData, seqGateTableData, strategyInputData}
end

function onLoad(data)
  local numStepsData = data[1]
  local seqVelTableData = data[2]
  local seqGateTableData = data[3]
  local strategyInputData = data[4]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].strategyInput.text = strategyInputData[i]
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    for j=1, v do
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
