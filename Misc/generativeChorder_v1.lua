--------------------------------------------------------------------------------
-- Generative chorder and sequencer
--------------------------------------------------------------------------------

require "subdivision"

local backgroundColour = "7c7c7c" -- Light or Dark
local widgetBackgroundColour = "111D5E" -- Dark
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
local partToStepMap = {1} -- Holds the starting step for each part
local partRandomizationAmount = 0
local totalNumSteps = 8
local paramsPerPart = {}
local partSelect = {}
local numParts = 1

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
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {1}, -- Chromatic
  {2}, -- Whole tone scale
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
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Chromatic",
  "Whole tone",
}

-- *** NOTE *** The chord definitions use steps in the selected scale, not semitones.
-- 2 means two steps up the scale: C-E for a C major scale. A-C for an A minor scale.
-- Keep in sync with chordDefinitionNames
local chordDefinitions = {
  {2,2,3}, -- Builds triads
  {2,2,2,1}, -- Builds 7th chords
  {3,1,3}, -- Builds supended chords
  {2,2,1,2}, -- Builds 6th chords
  {2}, -- Builds 7/9/11/13 chords depending on polyphony
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
  {4,3}, -- Builds open chords (no3)
  {1,2,1,2,1}, -- Builds supended chords including 7th and 9ths
  {3}, -- Builds chords using only fourths
}

local chordDefinitionNames = {
  "Triads",
  "7th",
  "Sus",
  "6th",
  "7/9/11/13",
  "7th/9th",
  "No 3",
  "Sus + 7/9",
  "4th chords",
}

-- Strategies are ways to play chords and scales
local strategies = {
  {}, -- Randomize next note position +/- 1 oct
  {1}, -- Up 1
  {-1}, -- Down 1
  {2}, -- Up 2
  {-2}, -- Down 2
  {2,-1}, -- Alternate up
  {-2,1}, -- Alternate down
  {-1,1,-2,-1,3}, -- Generated 1
  {3,1,-1,2}, -- Generated 2
  {-3,2}, -- Generated 3
  {2,2,3}, -- Up v triad
  {-3,-2,-2}, -- Down v triad
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

local strategyIndex = {} -- Holds the selected strategy (per voice)
local channelInputs = {}
local noteInputs = {}
local maxVoices = 8
local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
local noteNumberToNoteName = getNoteMapping()

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

function getTopLevelNote(voice, scale)
  local index = 1
  for _,v in ipairs(notes) do
    if v.voice == voice then
      index = gem.getIndexFromValue(v.note, scale)
      print("Resetting to noteInput/notePosition", v.note, index)
      return index
    end
  end
  return index
end

function getNoteFromStrategy(notePosition, strategyIndex, strategyPos, partPos, voice, minNote, maxNote)
  local scale = paramsPerPart[partPos].fullScale
  local strategy = {}
  local input = paramsPerPart[partPos].strategyInputs[voice]
  if input.enabled == true and string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(strategy, w)
      print("Add to strategy", w)
    end
    print("Get strategy from input", #strategy)
  end
  if #strategy == 0 then
    strategy = strategies[strategyIndex[voice]]
  end
  -- Reset strategy position
  if strategyPos[voice] > #strategy then
    strategyPos[voice] = 1
  end
  if notePosition[voice] == 0 or #strategy == 0 then
    -- Start at a random notePosition
    local minPos = gem.getIndexFromValue(minNote, scale)
    local maxPos = gem.getIndexFromValue(maxNote, scale)
    notePosition[voice] = gem.getRandom(minPos, maxPos)
    print("Set random notePosition/voice", notePosition[voice], voice)
  else
    print("Get strategy strategyIndex, strategyPos, increment, notePosition", strategyIndex[voice], strategyPos[voice], strategy[strategyPos[voice]], notePosition[voice])
    -- Get next notePosition from strategy
    notePosition[voice] = notePosition[voice] + strategy[strategyPos[voice]]
    print("Set notePosition", notePosition[voice])
    if type(scale[notePosition[voice]]) == "nil" then
      -- This is just a safeguard if scale is changed while playing
      notePosition[voice] = 1
      return minNote, notePosition[voice], strategyPos[voice]
    end
    if scale[notePosition[voice]] > maxNote then
      print("Reset scale[notePosition] > maxNote", scale[notePosition[voice]], maxNote)
      -- Reset to the base note
      notePosition[voice] = getTopLevelNote(voice, scale)
    elseif scale[notePosition[voice]] < minNote then
      print("Reset scale[notePosition] < minNote", scale[notePosition[voice]], minNote)
      -- Transpose to top octave
      local transposedNote = transpose(scale[notePosition[voice]], (maxNote-12), maxNote)
      notePosition[voice] = gem.getIndexFromValue(transposedNote, scale)
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos[voice] = strategyPos[voice] + 1
        print("Increment strategy pos", strategyPos[voice])
      end
    end
  end
  -- Ensure within range
  local note = transpose(scale[notePosition[voice]], minNote, maxNote)
  notePosition[voice] = gem.getIndexFromValue(note, scale)
  return note, notePosition, strategyPos
end

function canHarmonizeScale(selectedScale)
  -- We can (currently) only harmonize scales with 7 notes
  return #scaleDefinitions[selectedScale.value] == 7
end

function createFullScale(part)
  -- Find scale definition
  local definition = scaleDefinitions[paramsPerPart[part].scale.value]
  -- Find root note
  local root = paramsPerPart[part].key.value - 1
  -- Create scale
  paramsPerPart[part].fullScale = createScale(definition, root)
end

-- Use the selected chord definition to find the index for the next note in the chord
function getNextScaleIndex(note, scale, chordDefinitionIndex, inversionIndex)
  local index = gem.getIndexFromValue(note, scale)
  local increment = chordDefinitions[chordDefinitionIndex][inversionIndex]
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
  local seqVelTable = paramsPerPart[part].seqVelTable
  local velocity = seqVelTable:getValue(step)

  if skipRandomize == true then
    return velocity
  end

  -- Randomize velocity
  return gem.randomizeValue(velocity, seqVelTable.min, seqVelTable.max, paramsPerPart[part].velRandomization.value)
end

function getGate(part, step, skipRandomize)
  local seqGateTable = paramsPerPart[part].seqGateTable
  local gate = seqGateTable:getValue(step)

  if skipRandomize == true then
    return gate
  end

  return gem.randomizeValue(gate, seqGateTable.min, seqGateTable.max, paramsPerPart[part].gateRandomization.value)
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 700
local tableX = 0

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = tableWidth
sequencerPanel.height = 530

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
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.fillColour = "#dd000061"
channelButton.size = {90,22}
channelButton.x = 324
channelButton.y = 0
channelButton.changed = function(self)
  for i,v in ipairs(channelInputs) do
    v.enabled = maxVoices - paramsPerPart[editPartMenu.value].polyphony.value <= maxVoices - i and self.value == true
  end
end

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = "#ff084486"
focusButton.backgroundColourOn = "#ff02ACFE"
focusButton.textColourOff = "#ff22FFFF"
focusButton.textColourOn = "#efFFFFFF"
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
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.fillColour = "#dd000061"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = focusButton.x + focusButton.width + 5
autoplayButton.y = 0

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
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
      for i,w in ipairs(channelInputs) do
        w.enabled = maxVoices - v.polyphony.value <= maxVoices - i and channelButton.value == true
      end
      for i,w in ipairs(noteInputs) do
        w.enabled = maxVoices - v.polyphony.value <= maxVoices - i
      end
      for i,w in ipairs(v.strategyPerVoice) do
        w.enabled = maxVoices - v.polyphony.value <= maxVoices - i
      end
      for i,w in ipairs(v.strategyInputs) do
        w.enabled = maxVoices - v.polyphony.value <= maxVoices - i
      end
      for i,w in ipairs(v.minResPerVoice) do
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
    v.stepResolution.visible = isVisible
    v.minNoteSteps.visible = isVisible
    v.maxNoteSteps.visible = isVisible
    v.minNote.visible = isVisible
    v.maxNote.visible = isVisible
    v.monoLimit.visible = isVisible
    v.key.visible = isVisible
    v.scale.visible = isVisible
    v.harmonizationPropbability.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.stepRepeatProbability.visible = isVisible
    v.baseNoteRandomization.visible = isVisible
    v.subdivisionProbability.visible = isVisible
    v.subdivisionRepeatProbability.visible = isVisible
    --v.subdivisionMinResolution.visible = isVisible
    v.subdivisionTieProbability.visible = isVisible
    v.subdivisionDotProbability.visible = isVisible
    for _,s in ipairs(v.subdivisions) do
      s.visible = isVisible
    end
    for _,m in ipairs(v.minResPerVoice) do
      m.visible = isVisible
    end
    for _,s in ipairs(v.strategyPerVoice) do
      s.visible = isVisible
    end
    for _,s in ipairs(v.strategyInputs) do
      s.visible = isVisible
    end
    for _,c in ipairs(v.chords) do
      c.visible = isVisible
    end
    for _,c in ipairs(v.inversions) do
      c.visible = isVisible
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
      print("Copy initial settings from prev part", i-1)
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].polyphony.value = prev.polyphony.value
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].scale.value = prev.scale.value
      paramsPerPart[i].harmonizationPropbability.value = prev.harmonizationPropbability.value
      paramsPerPart[i].minNote.value = prev.minNote.value
      paramsPerPart[i].maxNote.value = prev.maxNote.value
      paramsPerPart[i].monoLimit.value = prev.monoLimit.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].fullScale = prev.fullScale
      paramsPerPart[i].velRandomization.value = prev.velRandomization.value
      paramsPerPart[i].gateRandomization.value = prev.gateRandomization.value
      paramsPerPart[i].stepRepeatProbability.value = prev.stepRepeatProbability.value
      paramsPerPart[i].baseNoteRandomization.value = prev.baseNoteRandomization.value
      paramsPerPart[i].subdivisionProbability.value = prev.subdivisionProbability.value
      paramsPerPart[i].subdivisionRepeatProbability.value = prev.subdivisionRepeatProbability.value
      --paramsPerPart[i].subdivisionMinResolution.value = prev.subdivisionMinResolution.value
      paramsPerPart[i].subdivisionTieProbability.value = prev.subdivisionTieProbability.value
      paramsPerPart[i].subdivisionDotProbability.value = prev.subdivisionDotProbability.value
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

local chordProbabilityLabel = sequencerPanel:Label("ChordProbabilityProbabilityLabel")
chordProbabilityLabel.text = "Chords"
chordProbabilityLabel.tooltip = "Choose the probability that chords will be included when harmonizing"

local inversionProbabilityLabel = sequencerPanel:Label("ChordProbabilityProbabilityLabel")
inversionProbabilityLabel.text = "Chord inversions"
inversionProbabilityLabel.tooltip = "Choose the probability that inversions will be used when harmonizing"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  local chords = {}
  local inversions = {}
  local strategyInputs = {}
  local strategyPerVoice = {}
  local minResPerVoice = {}

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
  seqVelTable.y = partRandBox.y + 260
  
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
    for i,v in ipairs(strategyPerVoice) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
    for i,v in ipairs(strategyInputs) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
    for i,v in ipairs(minResPerVoice) do
      v.enabled = maxVoices - self.value <= maxVoices - i
    end
    for i,v in ipairs(channelInputs) do
      v.enabled = maxVoices - self.value <= maxVoices - i and channelButton.value == true
    end
    for i,v in ipairs(noteInputs) do
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
  --stepResolution.showLabel = false
  --stepResolution.height = 20
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
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = widgetTextColour
  numStepsBox.width = stepResolution.width
  numStepsBox.x = stepResolution.x
  numStepsBox.y = stepResolution.y + stepResolution.height + 5
  numStepsBox.changed = function(self)
    setNumSteps(i)
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

  local monoLimit = sequencerPanel:NumBox("MonoLimit" .. i, 48, 0, 64, true)
  monoLimit.unit = Unit.MidiKey
  monoLimit.showPopupDisplay = true
  monoLimit.showLabel = true
  monoLimit.backgroundColour = menuBackgroundColour
  monoLimit.textColour = widgetTextColour
  monoLimit.displayName = "Mono Limit"
  monoLimit.tooltip = "Below this note there will only be played one note (polyphony=1)"
  monoLimit.x = generateMaxPart.x
  monoLimit.y = generateMaxPart.y + generateMaxPart.height + 5
  monoLimit.width = generateMaxPart.width

  generateMinPart.changed = function(self)
    generateMaxPart:setRange(self.value, 127)
  end

  generateMaxPart.changed = function(self)
    generateMinPart:setRange(0, self.value)
  end

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, getNoteNames())
  generateKeyPart.tooltip = "Key"
  generateKeyPart.showLabel = false
  generateKeyPart.height = 20
  generateKeyPart.width = generateMaxPart.width
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
  generateScalePart.width = generateKeyPart.width
  generateScalePart.x = generateKeyPart.x
  generateScalePart.y = generateKeyPart.y + generateKeyPart.height + 5
  generateScalePart.backgroundColour = menuBackgroundColour
  generateScalePart.textColour = widgetTextColour
  generateScalePart.arrowColour = menuArrowColour
  generateScalePart.outlineColour = menuOutlineColour
  
  local harmonizationPropbability = sequencerPanel:NumBox("HarmonizationPropbability" .. i, 100, 0, 100, true)
  harmonizationPropbability.displayName = "Harmonize"
  harmonizationPropbability.tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale."
  harmonizationPropbability.unit = Unit.Percent
  harmonizationPropbability.height = 20
  harmonizationPropbability.width = generateScalePart.width
  harmonizationPropbability.x = generateScalePart.x
  harmonizationPropbability.y = generateScalePart.y + generateScalePart.height + 5
  harmonizationPropbability.backgroundColour = menuBackgroundColour
  harmonizationPropbability.textColour = widgetTextColour

  generateScalePart.changed = function(self)
    createFullScale(i)
    local isEnabled = canHarmonizeScale(self)
    harmonizationPropbability.enabled = isEnabled
    for _,v in ipairs(chords) do
      v.enabled = isEnabled
    end
    for _,v in ipairs(inversions) do
      v.enabled = isEnabled
    end
  end

  local velRandomization = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRandomization.displayName = "Velocity"
  velRandomization.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandomization.unit = Unit.Percent
  velRandomization.width = editPartMenu.width
  velRandomization.x = generateKeyPart.x + generateKeyPart.width + 10
  velRandomization.y = editPartMenu.y
  velRandomization.backgroundColour = menuBackgroundColour
  velRandomization.textColour = widgetTextColour

  local gateRandomization = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRandomization.displayName = "Gate"
  gateRandomization.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandomization.unit = Unit.Percent
  gateRandomization.width = velRandomization.width
  gateRandomization.x = velRandomization.x
  gateRandomization.y = velRandomization.y + velRandomization.height + 5
  gateRandomization.backgroundColour = menuBackgroundColour
  gateRandomization.textColour = widgetTextColour

  local baseNoteRandomization = sequencerPanel:NumBox("BaseNoteProbability" .. i, 75, 0, 100, true)
  baseNoteRandomization.displayName = "Base Chord"
  baseNoteRandomization.tooltip = "Probability that first chord in the part will be the root chord"
  baseNoteRandomization.unit = Unit.Percent
  baseNoteRandomization.width = gateRandomization.width
  baseNoteRandomization.x = gateRandomization.x
  baseNoteRandomization.y = gateRandomization.y + gateRandomization.height + 5
  baseNoteRandomization.backgroundColour = menuBackgroundColour
  baseNoteRandomization.textColour = widgetTextColour

  if i == 1 then
    subdivisionProbabilityLabel.width = editPartMenu.width
    subdivisionProbabilityLabel.x = 0
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
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
    subdivision.width = (subdivisionProbabilityLabel.width / 3) - 2
    subdivision.x = subdivisionProbabilityLabel.x + ((j-1) * (subdivision.width+3))
    subdivision.y = subdivisionProbabilityLabel.y + subdivisionProbabilityLabel.height + 5
    table.insert(subdivisions, subdivision)
  end

  local subdivisionProbability = sequencerPanel:NumBox("SubdivisionProbability" .. i, 25, 0, 100, true)
  subdivisionProbability.displayName = "Probability"
  subdivisionProbability.tooltip = "Probability that active subdivisions will be selected by random - if set to 0, the first selected subdivision will be used"
  subdivisionProbability.unit = Unit.Percent
  subdivisionProbability.width = subdivisionProbabilityLabel.width
  subdivisionProbability.x = subdivisionProbabilityLabel.x
  subdivisionProbability.y = subdivisions[1].y + subdivisions[1].height + 5
  subdivisionProbability.backgroundColour = menuBackgroundColour
  subdivisionProbability.textColour = widgetTextColour

  local subdivisionRepeatProbability = sequencerPanel:NumBox("SubdivisionRepeatProbability" .. i, 0, 0, 100, true)
  subdivisionRepeatProbability.displayName = "Note Repeat"
  subdivisionRepeatProbability.tooltip = "What is the probability that the same note will be played in the subdivision, meaning that the same note is repeated?"
  subdivisionRepeatProbability.unit = Unit.Percent
  subdivisionRepeatProbability.width = subdivisionProbability.width
  subdivisionRepeatProbability.x = subdivisionProbability.x
  subdivisionRepeatProbability.y = subdivisionProbability.y + subdivisionProbability.height + 5
  subdivisionRepeatProbability.backgroundColour = menuBackgroundColour
  subdivisionRepeatProbability.textColour = widgetTextColour

  local stepRepeatProbability = sequencerPanel:NumBox("StepRepeatProbability" .. i, 50, 0, 100, true)
  stepRepeatProbability.displayName = "Step Repeat"
  stepRepeatProbability.tooltip = "Probability that the rythmic structure of a previous step will be repeated."
  stepRepeatProbability.unit = Unit.Percent
  stepRepeatProbability.width = subdivisionProbability.width
  stepRepeatProbability.x = subdivisionProbability.x + subdivisionProbability.width + 10
  stepRepeatProbability.y = subdivisionProbabilityLabel.y + subdivisionProbabilityLabel.height + 5
  stepRepeatProbability.backgroundColour = menuBackgroundColour
  stepRepeatProbability.textColour = widgetTextColour

  local subdivisionDotProbability = sequencerPanel:NumBox("SubdivisionDotProbability" .. i, 25, 0, 100, true)
  subdivisionDotProbability.displayName = "Dotted"
  subdivisionDotProbability.tooltip = "What is the probability that there will be dotted subdivisions?"
  subdivisionDotProbability.unit = Unit.Percent
  subdivisionDotProbability.width = subdivisionProbability.width
  subdivisionDotProbability.x = stepRepeatProbability.x
  subdivisionDotProbability.y = stepRepeatProbability.y + stepRepeatProbability.height + 5
  subdivisionDotProbability.backgroundColour = menuBackgroundColour
  subdivisionDotProbability.textColour = widgetTextColour

  local subdivisionTieProbability = sequencerPanel:NumBox("SubdivisionMultistepProbability" .. i, 25, 0, 100, true)
  subdivisionTieProbability.displayName = "Ties"
  subdivisionTieProbability.tooltip = "What is the probability that there will be ties in subdivisions?"
  subdivisionTieProbability.unit = Unit.Percent
  subdivisionTieProbability.width = subdivisionDotProbability.width
  subdivisionTieProbability.x = subdivisionDotProbability.x
  subdivisionTieProbability.y = subdivisionDotProbability.y + subdivisionDotProbability.height + 5
  subdivisionTieProbability.backgroundColour = menuBackgroundColour
  subdivisionTieProbability.textColour = widgetTextColour

  local voiceLabelBgColour = "9F9F9F"
  local voiceLabelTextColour = "202020"
  local voiceRowCount = 2

  if i == 1 then
    for j=1,maxVoices do
      local voiceLabel = sequencerPanel:Label("VoiceLabel" .. i .. j)
      voiceLabel.persistent = false
      voiceLabel.text = "Voice " .. j
      voiceLabel.tooltip = "Settings for voice " .. j
      voiceLabel.backgroundColour = voiceLabelBgColour
      voiceLabel.textColour = voiceLabelTextColour
      voiceLabel.width = tableWidth / (maxVoices + 1)
      voiceLabel.height = 20
      voiceLabel.x = (j * (voiceLabel.width + 1)) - 2
      voiceLabel.y = subdivisionRepeatProbability.y + subdivisionRepeatProbability.height + 9
    end
  end

  if i == 1 then
    local strategyLabel = sequencerPanel:Label("StrategyLabel" .. i)
    strategyLabel.persistent = false
    strategyLabel.text = "Strategy"
    strategyLabel.tooltip = "Strategy for voice"
    strategyLabel.backgroundColour = voiceLabelBgColour
    strategyLabel.textColour = voiceLabelTextColour
    strategyLabel.width = (tableWidth / (maxVoices + 1)) - 2
    strategyLabel.height = 40
    strategyLabel.x = 0
    strategyLabel.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 10
  end

  for j=1,maxVoices do
    local strategyInput = sequencerPanel:Label("StrategyInput" .. i .. j)
    strategyInput.enabled = maxVoices - generatePolyphonyPart.value <= maxVoices - j
    strategyInput.tooltip = "Strategy input for voice " .. j
    strategyInput.editable = true
    strategyInput.text = ""
    strategyInput.backgroundColour = menuBackgroundColour
    strategyInput.textColour = labelTextColour
    strategyInput.backgroundColourWhenEditing = "black"
    strategyInput.textColourWhenEditing = "white"
    strategyInput.width = tableWidth / (maxVoices + 1)
    strategyInput.height = 20
    strategyInput.x = (j * (strategyInput.width + 1)) - 2
    strategyInput.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 10
    table.insert(strategyInputs, strategyInput)
  end

  voiceRowCount = voiceRowCount + 1

  local strategyItems = {"Random"}
  for j=1,#strategies do
    if #strategies[j] == 0 then
      table.insert(strategyItems, "Off")
    else
      table.insert(strategyItems, table.concat(strategies[j], ","))
    end
  end
  for j=1,maxVoices do
    local strategySelect = sequencerPanel:Menu("StrategySelect" .. i .. j, strategyItems)
    strategySelect.enabled = maxVoices - generatePolyphonyPart.value <= maxVoices - j
    strategySelect.showLabel = false
    if j == 1 then
      strategySelect.selected = 2 -- Set strategy off for the first voice
    end
    strategySelect.tooltip = "Choose a playing strategy for voice " .. j
    strategySelect.arrowColour = menuArrowColour
    strategySelect.backgroundColour = menuBackgroundColour
    strategySelect.textColour = widgetTextColour
    strategySelect.width = tableWidth / (maxVoices + 1)
    strategySelect.height = 20
    strategySelect.x = (j * (strategySelect.width + 1)) - 2
    strategySelect.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 10
    strategySelect.changed = function(self)
      if self.value == 1 then
        strategyIndex[j] = nil
        strategyInputs[j].text = ""
        print("Selected strategyIndex by random for voice", j)
      else
        strategyIndex[j] = self.value - 1
        if self.value == 2 then
          strategyInputs[j].text = ""
        else
          strategyInputs[j].text = self.selectedText
        end
        print("Selected strategyIndex for voice", strategyIndex[j], j)
      end
    end
    table.insert(strategyPerVoice, strategySelect)
  end

  voiceRowCount = voiceRowCount + 1

  if i == 1 then
    local minResolutionLabel = sequencerPanel:Label("MinResolutionLabel" .. i)
    minResolutionLabel.persistent = false
    minResolutionLabel.text = "Min Resolution"
    minResolutionLabel.tooltip = "Minimum resolution for voice"
    minResolutionLabel.backgroundColour = voiceLabelBgColour
    minResolutionLabel.textColour = voiceLabelTextColour
    minResolutionLabel.width = (tableWidth / (maxVoices + 1)) - 2
    minResolutionLabel.height = 20
    minResolutionLabel.x = 0
    minResolutionLabel.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 12
  end

  for j=1,maxVoices do
    local subdivisionMinResolution = sequencerPanel:Menu("SubdivisionMinResolution" .. i .. j, getResolutionNames())
    if j == 1 then
      subdivisionMinResolution.selected = 11
    elseif j == 2 then
      subdivisionMinResolution.selected = 17
    else
      subdivisionMinResolution.selected = 20
    end
    subdivisionMinResolution.enabled = maxVoices - generatePolyphonyPart.value <= maxVoices - j
    subdivisionMinResolution.showLabel = false
    subdivisionMinResolution.tooltip = "Choose a playing strategy for voice " .. j
    subdivisionMinResolution.arrowColour = menuArrowColour
    subdivisionMinResolution.backgroundColour = menuBackgroundColour
    subdivisionMinResolution.textColour = widgetTextColour
    subdivisionMinResolution.width = tableWidth / (maxVoices + 1)
    subdivisionMinResolution.height = 20
    subdivisionMinResolution.x = (j * (subdivisionMinResolution.width + 1)) - 2
    subdivisionMinResolution.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 12
    table.insert(minResPerVoice, subdivisionMinResolution)
  end

  voiceRowCount = voiceRowCount + 1

  if i == 1 then
    local channelLabel = sequencerPanel:Label("ChannelLabel" .. i)
    channelLabel.persistent = false
    channelLabel.text = "Channel"
    channelLabel.tooltip = "Channels can be set per voice, but is the same for every part"
    channelLabel.backgroundColour = voiceLabelBgColour
    channelLabel.textColour = voiceLabelTextColour
    channelLabel.width = (tableWidth / (maxVoices + 1)) - 2
    channelLabel.height = 20
    channelLabel.x = 0
    channelLabel.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 14

    local channels = {}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    for j=1,maxVoices do
      local channelInput = sequencerPanel:Menu("ChannelInput" .. j, channels)
      channelInput.enabled = false
      channelInput.tooltip = "Channel for voice " .. j .. " in multichannel mode"
      channelInput.arrowColour = menuArrowColour
      channelInput.showLabel = false
      channelInput.selected = j
      channelInput.backgroundColour = menuBackgroundColour
      channelInput.textColour = widgetTextColour
      channelInput.width = tableWidth / (maxVoices + 1)
      channelInput.height = 20
      channelInput.x = (j * (channelInput.width + 1)) - 2
      channelInput.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 14
      table.insert(channelInputs, channelInput)
    end

    voiceRowCount = voiceRowCount + 1

    local notesLabel = sequencerPanel:Label("NotesLabel" .. i)
    notesLabel.persistent = false
    notesLabel.text = "Notes"
    notesLabel.tooltip = "Shows the base note playing for the corresponding voice"
    notesLabel.backgroundColour = voiceLabelBgColour
    notesLabel.textColour = voiceLabelTextColour
    notesLabel.width = (tableWidth / (maxVoices + 1)) - 2
    notesLabel.height = 20
    notesLabel.x = 0
    notesLabel.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 16

    for j=1,maxVoices do
      local noteInput = sequencerPanel:Label("NoteInput" .. j)
      noteInput.enabled = false--maxVoices - generatePolyphonyPart.value <= maxVoices - j
      noteInput.persistent = false
      noteInput.tooltip = "Displays the base note for voice " .. j .. " when playing"
      noteInput.text = "-"
      noteInput.backgroundColour = menuBackgroundColour
      noteInput.textColour = labelTextColour
      --noteInput.backgroundColourWhenEditing = "black"
      --noteInput.textColourWhenEditing = "white"
      noteInput.width = tableWidth / (maxVoices + 1)
      noteInput.height = 20
      noteInput.x = (j * (noteInput.width + 1)) - 2
      noteInput.y = subdivisionRepeatProbability.y + (subdivisionRepeatProbability.height*voiceRowCount) + 16
      table.insert(noteInputs, noteInput)
    end
  end

  if i == 1 then
    chordProbabilityLabel.width = editPartMenu.width
    chordProbabilityLabel.x = stepResolution.x
    chordProbabilityLabel.y = subdivisionProbabilityLabel.y
  end

  -- Chords
  local perRow = 3
  local columnCount = 0
  local rowCount = 1
  local defaultValue = 100
  for j,v in ipairs(chordDefinitionNames) do
    local chordProbability = sequencerPanel:NumBox("ChordProbability" .. i .. j, defaultValue, 0, 100, true)
    chordProbability.displayName = v
    chordProbability.tooltip = "Probability that " .. v .. " will be included"
    chordProbability.unit = Unit.Percent
    chordProbability.height = 20
    chordProbability.width = editPartMenu.width
    chordProbability.x = chordProbabilityLabel.x + (columnCount * (chordProbability.width + 10))
    chordProbability.y = chordProbabilityLabel.y + ((chordProbability.height + 5) * rowCount)
    chordProbability.backgroundColour = menuBackgroundColour
    chordProbability.textColour = widgetTextColour
    table.insert(chords, chordProbability)
    if defaultValue > 0 then
      defaultValue = defaultValue - 20
    end
    columnCount = columnCount + 1
    if j % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end

  if i == 1 then
    inversionProbabilityLabel.x = velRandomization.x
    inversionProbabilityLabel.y = chordProbabilityLabel.y
    inversionProbabilityLabel.width = editPartMenu.width
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

  table.insert(paramsPerPart, {minResPerVoice=minResPerVoice,strategyInputs=strategyInputs,strategyPerVoice=strategyPerVoice,inversions=inversions,chords=chords,subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,subdivisionRepeatProbability=subdivisionRepeatProbability,subdivisionDotProbability=subdivisionDotProbability,subdivisionTieProbability=subdivisionTieProbability,subdivisionMinResolution=subdivisionMinResolution,velRandomization=velRandomization,stepRepeatProbability=stepRepeatProbability,gateRandomization=gateRandomization,baseNoteRandomization=baseNoteRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,stepResolution=stepResolution,fullScale={},scale=generateScalePart,key=generateKeyPart,harmonizationPropbability=harmonizationPropbability,minNote=generateMinPart,maxNote=generateMaxPart,monoLimit=monoLimit,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})

  generateScalePart:changed()
end

editPartMenu:changed()
numPartsBox:changed()
paramsPerPart[editPartMenu.value].strategyPerVoice[1]:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function playSubdivision(structure, partPos)
  for i,node in ipairs(structure.notes) do
    local gate = getGate(partPos, structure.step)
    local waitDuration = (node.stepDuration / node.subdivision) * node.steps
    local playDuration = getPlayDuration(waitDuration, gate)
    local noteToPlay = node.note
    print("PlaySubdivision partPos/i/noteToPlay/noteName/duration/voice", partPos, i, noteToPlay, noteNumberToNoteName[noteToPlay+1], playDuration, structure.voice)
    -- If the key is already playing, send a note off event before playing the note
    if isKeyDown(noteToPlay) then
      postEvent({type=Event.NoteOff, note=noteToPlay, velocity=0})
      print("isKeyDown/noteToPlay", isKeyDown(noteToPlay), noteToPlay)
    end
    local channel = nil
    if channelButton.value == true then
      channel = channelInputs[structure.voice].value
    end
    playNote(noteToPlay, getVelocity(partPos, structure.step), beat2ms(playDuration)-1, nil, channel)
    waitBeat(waitDuration)
  end
end

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentRound = 0 -- Counter for rounds
  local currentPartPosition = 1 -- Holds the currently playing part
  local heldNoteIndex = 0
  local isStarting = true
  local scale = {} -- The scale the generator can choose from.
  local inversionIndex = 0
  local chordDefinitionIndex = 1
  local notePosition = {0} -- Holds the current note position in chord/scale (per voice)
  local strategyPos = {1} -- Holds the position in the selected strategy (per voice)
  local structureMemory = {}
  notes = {} -- Ensure notes are reset when seqencer starts

  -- START ARP LOOP
  while isPlaying do
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
      elseif isStarting == false and gem.getRandomBoolean(partRandomizationAmount) then
        -- Randomize parts within the set limit, unless we are in startup mode
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

    -- Number of simultainious notes are set by polyphony
    local polyphony = paramsPerPart[currentPartPosition].polyphony.value
    local subdivisionTieProbability = paramsPerPart[currentPartPosition].subdivisionTieProbability.value
    local subdivisionDotProbability = paramsPerPart[currentPartPosition].subdivisionDotProbability.value
    local subdivisionRepeatProbability = paramsPerPart[currentPartPosition].subdivisionRepeatProbability.value
    local stepRepeatProbability = paramsPerPart[currentPartPosition].stepRepeatProbability.value
    local minNote = paramsPerPart[currentPartPosition].minNote.value
    local maxNote = paramsPerPart[currentPartPosition].maxNote.value
    local mainBeatDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
    local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value
    local subdivisionProbability = paramsPerPart[currentPartPosition].subdivisionProbability.value
    local subdivisions = paramsPerPart[currentPartPosition].subdivisions
    local strategyPerVoice = paramsPerPart[currentPartPosition].strategyPerVoice
    local strategyInputs = paramsPerPart[currentPartPosition].strategyInputs
    local minResPerVoice = paramsPerPart[currentPartPosition].minResPerVoice

    if startOfPart == true then
      for voice=1,#strategyIndex do
        -- Randomize strategies
        if strategyPerVoice[voice].value == 1 and gem.getRandomBoolean() then
          strategyIndex[voice] = gem.getRandom(#strategies)
          print("Set random strategy index for voice", strategyIndex[voice], voice)
        end
      end
      for voice=1,#notePosition do
        notePosition[voice] = 0 -- Reset note positions at the start of each part
      end
      structureMemory = {}
    end

    inversionIndex = 0 -- Reset counter for inversion progress
    chordDefinitionIndex = 1 -- Set default
    -- Find chord types to include
    local chords = paramsPerPart[currentPartPosition].chords
    local activeChordDefinitions = {}
    for i,v in ipairs(chords) do
      if gem.getRandomBoolean(v.value) == true then
        table.insert(activeChordDefinitions, i)
      end
    end

    if #activeChordDefinitions > 0 then
      -- Get a chord def index from the active definitions
      chordDefinitionIndex = activeChordDefinitions[gem.getRandom(#activeChordDefinitions)]
      print("Chord definition selected by random/#activeChordDefinitions", chordDefinitionIndex, #activeChordDefinitions)
    end

    -- Always use the first inversion at the start of a part
    if startOfPart == false then
      -- Find inversions to include
      local inversions = paramsPerPart[currentPartPosition].inversions
      local activeInversions = {}
      for i,v in ipairs(inversions) do
        if gem.getRandomBoolean(v.value) == true then
          table.insert(activeInversions, i)
        end
      end

      if #activeInversions > 0 then
        -- Get a chord def index from the active definitions
        inversionIndex = activeInversions[gem.getRandom(#activeInversions)] - 1
        print("Chord inversion selected by random/#activeInversions", inversionIndex, #activeInversions)
      end
    end

    -- Get current position in the table
    local startStep = partToStepMap[currentPartPosition]
    local tablePos = currentPosition - startStep + 1

    --------------------------------------------------------------------------------
    -- Note functions
    --------------------------------------------------------------------------------

    -- Main function for getting notes to play
    local function getNotesToPlay(voice)
      -- Ensure voice has a strategy!
      if type(strategyIndex[voice]) == "nil" then
        strategyIndex[voice] = gem.getRandom(#strategies)
        print("Set random strategy index for voice in getNotesToPlay", strategyIndex[voice], voice)
      end

      -- Ensure voice has a strategy position!
      if type(strategyPos[voice]) == "nil" then
        strategyPos[voice] = 1
        print("Set strategy position for voice", voice)
      end

      -- Note generator function
      local function generateNote(nodePos)
        local note = nil
        local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
        local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
        local hasHarmonizeableScale = canHarmonizeScale(paramsPerPart[currentPartPosition].scale)
        local baseMin = minNote
        local baseMax = maxNote

        if hasNoteWithinMonoLimit(notes, currentPartPosition) == true then
          -- Ensure we only have one note below the mono limit
          baseMin = monoLimit
          print("Adjust baseMin to mono limit", baseMin)
        elseif monoLimit > baseMin then
          -- Ensure we have a note within the mono limit
          baseMax = monoLimit
          print("Adjust baseMax to mono limit", baseMax)
        end

        scale = paramsPerPart[currentPartPosition].fullScale

        local function getChord(currentNote, basic)
          local fullScale = paramsPerPart[currentPartPosition].fullScale
          local noteName = noteNumberToNoteName[currentNote+1]
          local maxBase = fullScale[#fullScale]
          local i = #fullScale
          while maxBase >= maxNote and i >= 0 do
            local scaleNoteIndex = fullScale[i] + 1 -- note index is 1 higher than note number
            local noteIndex = currentNote + 1 -- note index is 1 higher than note number
            if noteNumberToNoteName[scaleNoteIndex] == noteNumberToNoteName[noteIndex] then
              maxBase = fullScale[i]
            end
            i = i - 1 -- Decrement counter
          end
          -- Register the first note in the note selection
          local chordTable = {currentNote}
          print("Add note to chord - baseNote/noteName/chordDefinitionIndex/inversionIndex", currentNote, noteName, chordDefinitionIndex, inversionIndex)
          -- Get the remaining notes for the note selection
          local inversionPos = inversionIndex
          while hasHarmonizeableScale == true do
            -- Increment inversion pos
            inversionPos = inversionPos + 1
            if inversionPos > #chordDefinitions[chordDefinitionIndex] then
              inversionPos = 1
            end
            -- Find the scale index for the current note
            local scaleIndex = getNextScaleIndex(currentNote, fullScale, chordDefinitionIndex, inversionPos)
            -- Set the current note and note name
            currentNote = fullScale[scaleIndex]
            noteName = noteNumberToNoteName[currentNote+1]
            -- In full mode we stop building the chord when the current note is higher that max note
            if currentNote >= maxBase then
              print("Found notes for chord", #chordTable)
              break
            end
            -- In basic mode we stop building the chord when it contains the notes from the current chord definition
            if basic == true and #chordDefinitions[chordDefinitionIndex] == #chordTable then
              print("Found notes for chord in basic mode", #chordTable)
              break
            end
            table.insert(chordTable, currentNote)
            print("Add note to chord note, noteName, scaleIndex, inversionPos", currentNote, noteName, scaleIndex, inversionPos)
          end
          return chordTable
        end

        local function getBaseNote()
          local baseNote = minNote -- Start from the lowest note
          local useBaseNote = currentStep == 1
          if useBaseNote and gem.getRandomBoolean(baseNoteRandomization) then
            while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
              baseNote = baseNote + 1 -- increment note until we hit the base note
            end
            notePosition[voice] = gem.getIndexFromValue(baseNote, scale)
            print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
          else
            local noteRange = baseMax - baseMin
            if monoLimit <= baseMin then
              -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
              noteRange = math.max(12, math.ceil(noteRange / polyphony))
              print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
            end
            if notePosition[voice] == 0 then
              baseNote = getNoteAccordingToScale(scale, (baseNote + gem.getRandom(noteRange) - 1))
              notePosition[voice] = gem.getIndexFromValue(baseNote, scale)
            end
            baseNote, notePosition, strategyPos = getNoteFromStrategy(notePosition, strategyIndex, strategyPos, currentPartPosition, voice, baseMin, baseMax)
            print("Get base note from scale using strategy: note/minNote/maxNote/strategyIndex", baseNote, baseMin, baseMax, strategyIndex[voice])
          end

          return baseNote
        end

        -- The first node on the first voice gets the base note
        if voice == 1 and nodePos == 1 then
          local function validateBaseNote(baseNote)
            local valid = true
            if hasHarmonizeableScale == false then
              -- Always valid if scale does not support harmonization
              return valid
            end
            local baseChord = getChord(baseNote, true)
            -- chordDefinitionIndex 3 == suspended - not valid if tritone
            if chordDefinitionIndex == 3 then
              for i,v in ipairs(baseChord) do 
                if i == 1 then
                  if getSemitonesBetweenNotes(v, baseChord[#baseChord]) == 6 then
                    valid = false
                    break
                  end
                end
                if i < #baseChord then
                  if getSemitonesBetweenNotes(v, baseChord[i+1]) == 6 then
                    valid = false
                    break
                  end
                end
              end
            end
            print("valid", valid)
            return valid
          end
          local maxAttempts = 3
          local counter = 0
          -- TODO Check for repeated basenote+inversionDefinition+inversion
          while counter < maxAttempts do
            local baseNote = getBaseNote()
            if validateBaseNote(baseNote) == true then
              note = baseNote
              print("Set note from baseNote", note)
              break
            end
            counter = counter + 1
            print("Retry getting basenote/tries/valid", note, counter, valid)
          end
        end

        local harmonizationPropbability = paramsPerPart[currentPartPosition].harmonizationPropbability.value
        if type(note) == "nil" and gem.getRandomBoolean(harmonizationPropbability) == true and nodePos == 1 and hasHarmonizeableScale == true then
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
            if prevNote < baseMin then
              prevNote = transpose(prevNote, baseMin, baseMax)
              print("Transposing prevNote to within range", prevNote)
            end
            -- Increment inversion index
            inversionIndex = inversionIndex + 1
            if inversionIndex > #chordDefinitions[chordDefinitionIndex] then
              inversionIndex = 1
            end
            local fullScale = paramsPerPart[currentPartPosition].fullScale
            local scaleIndex = getNextScaleIndex(prevNote, fullScale, chordDefinitionIndex, inversionIndex)
            -- Ensure note is within range
            note = transpose(fullScale[scaleIndex], baseMin, baseMax)
            local noteRange = baseMax - prevNote
            local octaveRange = math.floor(noteRange / 12)
            local notesLeft = polyphony - #notes
            local octave = math.floor(octaveRange / notesLeft)
            if octave > 0 and note > baseMax / 2 and gem.getRandomBoolean() then
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

        -- Ensure voice has a note position!
        if type(notePosition[voice]) == "nil" then
          -- Set note position for the voice
          if type(note) == "nil" then
            notePosition[voice] = 0
          else
            notePosition[voice] = gem.getIndexFromValue(note, scale)
          end
          print("Set note position for voice", notePosition[voice], voice)
        end

        -- Get note from scale using strategy
        if type(note) == "nil" then
          note, notePosition, strategyPos = getNoteFromStrategy(notePosition, strategyIndex, strategyPos, currentPartPosition, voice, baseMin, baseMax)
          print("Get note from scale using strategy: note/minNote/maxNote/strategyIndex", note, minNote, maxNote, strategyIndex[voice])
        end

        return note
      end

      -- Recursive method for generating the rythmic structure
      local function generateStructure(stepDuration, steps, currentDepth, stop)
        if type(currentDepth) == "nil" then
          currentDepth = 0
        end

        local subdivision, subDivDuration, remainderDuration, stop = getSubdivision(stepDuration, steps, getResolution(minResPerVoice[voice].value), subdivisionProbability, subdivisions, stop, subdivisionDotProbability)
        print("Got subdivision/subDivDuration/currentDepth/voice", subdivision, subDivDuration, currentDepth, voice)

        -- Check for minimum duration
        local subdivisionStructures = {}
        if subdivision > 1 then
          currentDepth = currentDepth + 1
          print("Incrementing depth/stepDuration/subDivDuration", currentDepth, stepDuration, subDivDuration)
          local dotted = subDivDuration ~= remainderDuration
          local subDivPos = 1
          while subDivPos <= subdivision do
            local subdivisionSteps = 1 -- Set default
            if dotted == false then
              subdivisionSteps, stop = getSubdivisionSteps(subdivision, subDivPos, subdivisionTieProbability)
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

      if gem.getRandomBoolean(stepRepeatProbability) and type(structureMemory[voice]) == "table" then --  and tablePos > 1
        nodes = structureMemory[voice] -- Load structure from memory
        print("Load structure from memory for voice", voice)
      else
        local function parseTree(structureTree)
          -- Traverse the tree until we find the levels with no child nodes
          for i=1,structureTree.subdivision do
            if #structureTree.children == 0 then
              print("Add final node from structure steps/stepDuration", structureTree.steps, structureTree.stepDuration)
              table.insert(nodes, structureTree)
            else
              print("Parsing further down the tree #children/subdvision", #structureTree.children, structureTree.subdivision)
              if type(structureTree.children[i]) == "table" then
                parseTree(structureTree.children[i]) -- Parse next level
              end
            end
          end
        end
  
        local structureTree = generateStructure(mainBeatDuration, steps) -- Gets the structrure / rythmic pattern to use
        parseTree(structureTree) -- Parses the tree and finds the nodes on the lowest level
        print("Generated #nodes/step/voice", #nodes, tablePos, voice)
        table.insert(structureMemory, voice, nodes)
      end

      -- Get notes for each node in the tree
      nodes = setNotesOnNodes(nodes, subdivisionRepeatProbability, generateNote)
      local notesToPlay = {
        notes = nodes,
        note = nodes[1].note, -- The base note
        step = tablePos,
        steps = steps,
        voice = voice,
        stepCounter = 0
      }

      return notesToPlay
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
          local notesToPlay = getNotesToPlay(voice)
          if notesInclude(notes, notesToPlay.note) == false then
            table.insert(notes, notesToPlay)
            print("Insert notes/note", #notesToPlay.notes, notesToPlay.note)
            noteInputs[voice].text = noteNumberToNoteName[notesToPlay.note + 1] .. " (" .. notesToPlay.note .. ")"
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
        run(playSubdivision, note, currentPartPosition)
        --print("Playing note/stepDuration/note.gate/note.steps/note.stepDuration", note.note, stepDuration, note.gate, note.steps, note.stepDuration)
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
  local seqVelTableData = {}
  local seqGateTableData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
    end
  end

  return {numStepsData, seqVelTableData, seqGateTableData}
end

function onLoad(data)
  local numStepsData = data[1]
  local seqVelTableData = data[2]
  local seqGateTableData = data[3]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    for j=1, v do
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
