--------------------------------------------------------------------------------
-- GENEREATIVE SEQUENCER
--------------------------------------------------------------------------------

require "../includes/common"

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local isPlaying = false
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
  --{2,1,2,2,2,2,1}, -- Harmonic minor
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
  --"Harmonic minor",
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
  {2}, -- Builds 7/9/11/13 chords depending on polyphony
  {1,1,2,2,1}, -- Builds (close) 7th and 9th chords
  --[[ {3}, -- Builds chords using only fourths
  {4}, -- Builds chords using only fifths
  {1}, -- Builds chords using only seconds
  {1,2,1,2,1}, -- Builds supended chords including 7th and 9ths ]]
}
local chordDefinitionNames = {
  "Triads",
  "7th",
  "Sus",
  "6th",
  "7/9/11/13",
  "7th/9th",
  --[[ "4th chords", -- This can be achieved using tonal/melodic strategies on scales
  "5th chords",
  "2nd chords",
  "Suspended + 7/9", ]]
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
  --[[ {3} -- Fourths
  {3,-1}, 
  {2,1},
  {1,-1},
  {-1,1},
  {-1,-2},
  {2,1,-3},
  {1,2,3,4},
  {1,1,2,-3},
  {-1,-2,1,2},
  {-1,-1,-2,5},
  {-1,1,-1,1,-2},
  {-1,-1,-1,-1,5},
  {2,3,2,4,2,5,1},
  {1,-1,1,-2,-1,3},
  {-1,-1,-1,-1,-3,3,1,1,1,1},
  {-1,-2,1,2,-1,-2,1,2,1,-3,1}, ]]
}
local numStrategies = #strategies
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

setBackgroundColour("#5f5f5f")

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

function getNotePositionFromStragegy(notesTable, notePosition, strategyIndex, strategyPos, partPos, voice)
  local index = strategyIndex[voice]
  local strategy = {}
  local input = paramsPerPart[partPos].strategyInput
  if input.enabled == true and string.len(input.text) > 0 then
    for w in string.gmatch(input.text, "-?%d+") do
      table.insert(strategy, w)
      print("Add to strategy", w)
    end
    print("Get strategy from input", #strategy)
  else
    strategy = strategies[index]
  end
  -- Reset strategy pos if needed
  if strategyPos > #strategy then
    strategyPos = 1
  end
  print("Get strategy strategyIndex, voice, strategyPos, increment, notePosition", index, voice, strategyPos, strategy[strategyPos], notePosition)
  if notePosition == 0 then
    -- Start at a random notePosition
    notePosition = getRandom(#notesTable)
    print("Set random notePosition from notesTable", notePosition, #notesTable)
  else
    -- Get next notePosition from strategy
    notePosition = notePosition + strategy[strategyPos]
    print("Set notePosition", notePosition)
  end
  if notePosition > #notesTable then
    print("Reset notePosition > #notesTable", notePosition, #notesTable)
    notePosition = 1
    strategyPos = 1
  elseif notePosition < 1 then
    print("Reset notePosition < 1", notePosition)
    notePosition = #notesTable
    strategyPos = 1
  else
    -- Increment strategy pos
    if #strategy > 1 then
      strategyPos = strategyPos + 1
      print("Increment strategy pos", strategyPos)
    end
  end
  return notePosition, strategyPos
end

function getSemitonesBetweenNotes(note1, note2)
  return math.max(note1, note2) - math.min(note1, note1)
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
  --notePosition = 0 -- Reset note position
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

function getScaleIndexFromNote(note, scale)
  for i,v in ipairs(scale) do
    if v == note then
      print("Found index", i)
      return i
    end
  end
  return 1
end

-- Use the selected chord definition to find the index for the next note in the chord
function getNextScaleIndex(note, scale, chordDefinitionIndex, inversionIndex)
  local index = getScaleIndexFromNote(note, scale)
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

function getMaxDepthFromBeatDuration(resolution, partPosition)
  local depth = 1
  local subdivision = 1
  local subdivisions = {}
  local minResolution = getResolution(paramsPerPart[partPosition].subdivisionMinResolution.value)

  -- Find active subdivisions
  for i,v in ipairs(paramsPerPart[partPosition].subdivisions) do
    if v.value == true then
      table.insert(subdivisions, i)
    end
  end

  if #subdivisions > 0 then
    subdivision = subdivisions[#subdivisions]
  end

  if subdivision > 1 then
    depth = math.ceil(math.abs((math.log((minResolution/resolution))/math.log(subdivision))))
  end

  print("Found depth/resolution/subdivision/minResolution", depth, resolution, subdivision, minResolution)

  return depth
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
  --notePosition = 0 -- Reset note position
  local numSteps = paramsPerPart[part].numStepsBox.value
  local maxLength = math.min(math.ceil(numSteps * 0.75), 9) -- 8 * 0.75 = 6
  local strategy = {} -- Table to hold strategy
  local ln = getRandom(maxLength) -- Length
  for i=1, ln do
    local value = 1
    if getRandomBoolean(25) then -- TODO Param?
      value = 2
    elseif getRandomBoolean(15) then -- TODO Param?
      value = 3
    elseif getRandomBoolean(3) then -- TODO Param?
      value = 4
    elseif getRandomBoolean(10) then -- TODO Param?
      value = 0
    end
    if getRandomBoolean(33) and value > 0 then -- TODO Param?
      value = -value
    end
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

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = tableWidth
sequencerPanel.height = 400

local label = sequencerPanel:Label("Label")
label.text = "Generative Sequencer"
label.alpha = 0.5
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {190,25}

local focusButton = sequencerPanel:OnOffButton("FocusPartOnOff", false)
focusButton.backgroundColourOff = "#ff084486"
focusButton.backgroundColourOn = "#ff02ACFE"
focusButton.textColourOff = "#ff22FFFF"
focusButton.textColourOn = "#efFFFFFF"
focusButton.displayName = "Focus Part"
focusButton.tooltip = "When focus is active, only the part selected for editing is shown and played"
focusButton.fillColour = "#dd000061"
focusButton.size = {102,22}
focusButton.x = (sequencerPanel.width / 2) + 33
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
autoplayButton.size = {102,22}
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
playButton.size = {102,22}
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = 0
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
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
editPartMenu.width = 108
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
    v.strategyInput.visible = isVisible
    v.createStrategyButton.visible = isVisible
    v.autoStrategyButton.visible = isVisible
    v.strategyPropbability.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.baseNoteRandomization.visible = isVisible
    v.subdivisionProbability.visible = isVisible
    v.subdivisionRepeatProbability.visible = isVisible
    v.subdivisionMinResolution.visible = isVisible
    for _,s in ipairs(v.subdivisions) do
      s.visible = isVisible
    end
    for _,c in ipairs(v.chords) do
      c.visible = isVisible
    end
  end
  setTableWidths()
end

local polyButton = sequencerPanel:OnOffButton("PolyButton", false)

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.width = editPartMenu.width / 2
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
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].polyphony.value = prev.polyphony.value
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].scale.value = prev.scale.value
      paramsPerPart[i].harmonizationPropbability.value = prev.harmonizationPropbability.value
      paramsPerPart[i].strategyInput.value = prev.strategyInput.value
      paramsPerPart[i].strategyPropbability.value = prev.strategyPropbability.value
      paramsPerPart[i].autoStrategyButton.value = prev.autoStrategyButton.value
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
      paramsPerPart[i].baseNoteRandomization.value = prev.baseNoteRandomization.value
      paramsPerPart[i].subdivisionProbability.value = prev.subdivisionProbability.value
      paramsPerPart[i].subdivisionRepeatProbability.value = prev.subdivisionRepeatProbability.value
      paramsPerPart[i].subdivisionMinResolution.value = prev.subdivisionMinResolution.value
      paramsPerPart[i].init = prev.init
    end
  end
  clearPosition()
  if polyButton.value == true then
    playButton:setValue(false)
  end
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)
end

local partRandBox = sequencerPanel:NumBox("PartRandomization", 0, 0, 100, true)
partRandBox.backgroundColour = menuBackgroundColour
partRandBox.textColour = menuTextColour
partRandBox.displayName = "Part Order"
partRandBox.tooltip = "Amount of radomization applied to the order of playing parts"
partRandBox.unit = Unit.Percent
partRandBox.width = editPartMenu.width
partRandBox.x = numPartsBox.x
partRandBox.y = numPartsBox.y + numPartsBox.height + 5
partRandBox.changed = function(self)
  partRandomizationAmount = self.value
end

polyButton.displayName = "Poly"
polyButton.tooltip = "In poly mode, parts are played in parallell, instead of sequential."
polyButton.width = numPartsBox.width - 5
polyButton.x = numPartsBox.x + numPartsBox.width + 5
polyButton.y = numPartsBox.y
polyButton.backgroundColourOff = "#ff084486"
polyButton.backgroundColourOn = "#ff02ACFE"
polyButton.textColourOff = "#ff22FFFF"
polyButton.textColourOn = "#efFFFFFF"
polyButton.changed = function(self)
  partRandBox.enabled = self.value == false
  playButton:setValue(false)
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
  if polyButton.value == true then
    for i=1,numPartsBox.value do
      spawn(arpeg, i)
    end
  else
    spawn(arpeg)
  end
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

local strategyLabel = sequencerPanel:Label("StrategyLabel")
strategyLabel.text = "Strategy"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  --print("Set paramsPerPart", i)

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
  seqVelTable.y = partRandBox.y + 125
  
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

  local generatePolyphonyPart = sequencerPanel:NumBox("GeneratePolyphony" .. i, 1, 1, 8, true)
  generatePolyphonyPart.displayName = "Polyphony"
  generatePolyphonyPart.tooltip = "How many notes are played at once"
  generatePolyphonyPart.backgroundColour = menuBackgroundColour
  generatePolyphonyPart.textColour = menuTextColour
  generatePolyphonyPart.visible = false
  generatePolyphonyPart.width = editPartMenu.width
  generatePolyphonyPart.x = editPartMenu.x + editPartMenu.width + 10
  generatePolyphonyPart.y = editPartMenu.y

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, 16, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps can a note last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = menuTextColour
  generateMinNoteStepsPart.enabled = false
  generateMinNoteStepsPart.width = generatePolyphonyPart.width
  generateMinNoteStepsPart.x = generatePolyphonyPart.x
  generateMinNoteStepsPart.y = generatePolyphonyPart.y + generatePolyphonyPart.height + 5

  local generateMaxNoteStepsPart = sequencerPanel:NumBox("GenerateMaxNoteSteps" .. i, 1, 1, 16, true)
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
  --stepResolution.showLabel = false
  --stepResolution.height = 20
  stepResolution.width = generateMaxNoteStepsPart.width
  stepResolution.x = generatePolyphonyPart.x + generatePolyphonyPart.width + 10
  stepResolution.y = generatePolyphonyPart.y
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

  local monoLimit = sequencerPanel:NumBox("MonoLimit" .. i, 48, 0, 64, true)
  monoLimit.unit = Unit.MidiKey
  monoLimit.showPopupDisplay = true
  monoLimit.showLabel = true
  monoLimit.backgroundColour = menuBackgroundColour
  monoLimit.textColour = menuTextColour
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
  
  local harmonizationPropbability = sequencerPanel:NumBox("HarmonizationPropbability" .. i, 100, 0, 100, true)
  harmonizationPropbability.enabled = false
  harmonizationPropbability.displayName = "Harmonize"
  harmonizationPropbability.tooltip = "When harmonizing, we get notes from the currently playing chord. Otherwise notes are selected from the current scale."
  harmonizationPropbability.unit = Unit.Percent
  harmonizationPropbability.height = 20
  harmonizationPropbability.width = generateScalePart.width
  harmonizationPropbability.x = generateScalePart.x
  harmonizationPropbability.y = generateScalePart.y + generateScalePart.height + 5
  harmonizationPropbability.backgroundColour = menuBackgroundColour
  harmonizationPropbability.textColour = menuTextColour

  generateScalePart.changed = function(self)
    createFullScale(i)
    harmonizationPropbability.enabled = canHarmonizeScale(self)
  end

  local velRandomization = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRandomization.displayName = "Velocity"
  velRandomization.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandomization.unit = Unit.Percent
  velRandomization.width = editPartMenu.width
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

  local baseNoteRandomization = sequencerPanel:NumBox("BaseNoteProbability" .. i, 0, 0, 100, true)
  baseNoteRandomization.displayName = "Base note"
  baseNoteRandomization.tooltip = "Probability that first note in part will be the base note"
  baseNoteRandomization.unit = Unit.Percent
  baseNoteRandomization.width = gateRandomization.width
  baseNoteRandomization.x = gateRandomization.x
  baseNoteRandomization.y = gateRandomization.y + gateRandomization.height + 5
  baseNoteRandomization.backgroundColour = menuBackgroundColour
  baseNoteRandomization.textColour = menuTextColour

  if i == 1 then
    subdivisionProbabilityLabel.width = editPartMenu.width
    subdivisionProbabilityLabel.x = 0
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
  end

  local subdivisions = {}
  for j=1,8 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, (j<3))
    subdivision.backgroundColourOff = "#ff084486"
    subdivision.backgroundColourOn = "#ff02ACFE"
    subdivision.textColourOff = "#ff22FFFF"
    subdivision.textColourOn = "#efFFFFFF"
    subdivision.fillColour = "#dd000061"
    subdivision.displayName = "" .. j
    subdivision.tooltip = "Activate subdivision"
    subdivision.height = 20
    subdivision.width = 25
    subdivision.x = 30 + ((j-2) * (subdivision.width+3.3))
    subdivision.y = subdivisionProbabilityLabel.y + subdivisionProbabilityLabel.height + 5
    table.insert(subdivisions, subdivision)
  end

  local subdivisionProbability = sequencerPanel:NumBox("SubdivisionProbability" .. i, 25, 0, 100, true)
  subdivisionProbability.displayName = "Probability"
  subdivisionProbability.tooltip = "Probability that subdivisions will occur"
  subdivisionProbability.unit = Unit.Percent
  subdivisionProbability.width = 120
  subdivisionProbability.x = subdivisions[1].x
  subdivisionProbability.y = subdivisions[1].y + subdivisions[1].height + 5
  subdivisionProbability.backgroundColour = menuBackgroundColour
  subdivisionProbability.textColour = menuTextColour

  local subdivisionRepeatProbability = sequencerPanel:NumBox("SubdivisionRepeatProbability" .. i, 0, 0, 100, true)
  subdivisionRepeatProbability.displayName = "Repeat"
  subdivisionRepeatProbability.tooltip = "What is the probability that the same note will be played in the subdivision, meaning that the same note is repeated?"
  subdivisionRepeatProbability.unit = Unit.Percent
  subdivisionRepeatProbability.width = subdivisionProbability.width
  subdivisionRepeatProbability.x = subdivisionProbability.x
  subdivisionRepeatProbability.y = subdivisionProbability.y + subdivisionProbability.height + 5
  subdivisionRepeatProbability.backgroundColour = menuBackgroundColour
  subdivisionRepeatProbability.textColour = menuTextColour

  local subdivisionMinResolution = sequencerPanel:Menu("SubdivisionMinResolution" .. i, getResolutionNames())
  subdivisionMinResolution.displayName = "Min Resolution"
  subdivisionMinResolution.tooltip = "This is the lowest resolution when using subdivisions"
  subdivisionMinResolution.selected = 23
  subdivisionMinResolution.x = subdivisionProbability.x + subdivisionProbability.width + 10
  subdivisionMinResolution.y = subdivisionProbability.y
  subdivisionMinResolution.width = subdivisionProbability.width - 25
  subdivisionMinResolution.backgroundColour = menuBackgroundColour
  subdivisionMinResolution.textColour = menuTextColour
  subdivisionMinResolution.arrowColour = menuArrowColour
  subdivisionMinResolution.outlineColour = menuOutlineColour

  if i == 1 then
    chordProbabilityLabel.width = editPartMenu.width
    chordProbabilityLabel.x = stepResolution.x
    chordProbabilityLabel.y = subdivisionProbabilityLabel.y
  end

  -- Chords
  local chords = {}
  local perRow = 2
  local columnCount = 0
  local rowCount = 1
  for j,v in ipairs(chordDefinitionNames) do
    local defaultValue = 0
    if j < 6 then
      defaultValue = 120 - (j * 20)
    end
    local chordProbability = sequencerPanel:NumBox("ChordProbability" .. i .. j, defaultValue, 0, 100, true)
    chordProbability.displayName = v
    chordProbability.tooltip = "Probability that " .. v .. " will be included"
    chordProbability.unit = Unit.Percent
    chordProbability.height = 20
    chordProbability.width = editPartMenu.width
    chordProbability.x = chordProbabilityLabel.x + (columnCount * (chordProbability.width + 10))
    chordProbability.y = chordProbabilityLabel.y + ((chordProbability.height + 5) * rowCount)
    chordProbability.backgroundColour = menuBackgroundColour
    chordProbability.textColour = menuTextColour
    table.insert(chords, chordProbability)
    columnCount = columnCount + 1
    if j % perRow == 0 then
      rowCount = rowCount + 1
      columnCount = 0
    end
  end

  if i == 1 then
    strategyLabel.x = generateScalePart.x
    strategyLabel.y = chordProbabilityLabel.y
    strategyLabel.width = editPartMenu.width
  end

  local strategyPropbability = sequencerPanel:NumBox("StrategyPropbability" .. i, 100, 0, 100, true)
  strategyPropbability.displayName = "Probability"
  strategyPropbability.tooltip = "Set the probability that a playing strategy will be used to select the next note. Otherwise notes will be selected by random."
  strategyPropbability.unit = Unit.Percent
  strategyPropbability.height = 20
  strategyPropbability.width = strategyLabel.width * 1.5
  strategyPropbability.x = strategyLabel.x
  strategyPropbability.y = strategyLabel.y + strategyLabel.height + 5
  strategyPropbability.backgroundColour = menuBackgroundColour
  strategyPropbability.textColour = menuTextColour

  local strategyInput = sequencerPanel:Label("StrategyInput" .. i)
  strategyInput.text = table.concat(strategies[getRandom(#strategies)], ",")
  strategyInput.tooltip = "Strategies are ways to play chords and scales. Numbers represent steps up or down the scale or chord that is currently playing."
  strategyInput.editable = true
  strategyInput.backgroundColour = menuBackgroundColour
  strategyInput.backgroundColourWhenEditing = "#aaffffff"
  strategyInput.textColour = "#00ee00"
  strategyInput.textColourWhenEditing = "black"
  strategyInput.x = strategyLabel.x
  strategyInput.y = strategyPropbability.y + strategyPropbability.height + 5
  strategyInput.width = strategyPropbability.width

  local createStrategyButton = sequencerPanel:Button("CreateStrategyButton" .. i)
  createStrategyButton.displayName = "Create"
  createStrategyButton.tooltip = "Replace the current strategy with a new one."
  createStrategyButton.persistent = false
  createStrategyButton.width = 60
  createStrategyButton.x = strategyInput.x + strategyInput.width + 5
  createStrategyButton.y = strategyInput.y
  createStrategyButton.changed = function()
    local strategy = createStrategy(i)
    strategyInput.text = table.concat(strategy, ",") -- TODO Handle voice
    --[[ for voice=1, #strategyIndex do
      local strategy = createStrategy(i)
      table.insert(strategies, strategy)
      strategyIndex[voice] = #strategies
      strategyInput.text = table.concat(strategy, ",") -- TODO Handle voice
    end ]]
  end

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
  autoStrategyButton.changed = function(self)
    --notePosition = 0 -- Reset note position
    strategyInput.enabled = self.value == false
    createStrategyButton.enabled = self.value == false
  end

  table.insert(paramsPerPart, {chords=chords,subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,subdivisionRepeatProbability=subdivisionRepeatProbability,subdivisionMinResolution=subdivisionMinResolution,velRandomization=velRandomization,gateRandomization=gateRandomization,baseNoteRandomization=baseNoteRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,stepResolution=stepResolution,fullScale={},scale=generateScalePart,key=generateKeyPart,createStrategyButton=createStrategyButton,strategyInput=strategyInput,autoStrategyButton=autoStrategyButton,strategyPropbability=strategyPropbability,harmonizationPropbability=harmonizationPropbability,minNote=generateMinPart,maxNote=generateMaxPart,monoLimit=monoLimit,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})

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
        local noteToPlay = getNoteAccordingToScale(scale, note.note)
        noteToPlay = transpose(noteToPlay, paramsPerPart[partPos].minNote.value, paramsPerPart[partPos].maxNote.value)
        print("PlaySubdivision partPos/i/noteToPlay/noteName/duration/subdivision/voice", partPos, i, noteToPlay, noteNumberToNoteName[noteToPlay+1], playDuration, note.subdivision, note.voice)
        -- If the key is already playing, send a note off event before playing the note
        if isKeyDown(noteToPlay) then
          postEvent({type=Event.NoteOff, note=noteToPlay, velocity=0})
          print("isKeyDown/noteToPlay", isKeyDown(noteToPlay), noteToPlay)
        end
        playNote(noteToPlay, getVelocity(partPos, note.step), beat2ms(playDuration)-1)
      end
    else
      local subDivisionNote = note.notes[i]
      run(playSubdivision, subDivisionNote, partPos)
    end
    waitBeat(waitDuration)
  end
end

function arpeg(selectedPart)
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentRound = 0 -- Counter for rounds
  local currentPartPosition = 1 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local heldNoteIndex = 0
  local isStarting = true
  local noteSelection = {} -- The note selection the generator can choose from. Can be chord or scale.
  local inversionIndex = 1
  local chordDefinitionIndex = 1
  local notePosition = 0 -- Holds the current note position in chord/scale
  local strategyIndex = {1} -- Holds the selected strategy (per voice)
  local strategyPos = 1 -- Holds the position in the selected strategy
  local polyMode = type(selectedPart) == "number"

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
        if polyMode == false then
          -- Update part position
          partWasChanged = currentPartPosition ~= pp
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
      if polyMode == true then
        partWasChanged = false
        currentPartPosition = selectedPart
      elseif focusButton.value == true then
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

    -- Number of simultainious notes are set by polyphony
    local polyphony = paramsPerPart[currentPartPosition].polyphony.value
    local mainBeatDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local maxDepth = getMaxDepthFromBeatDuration(mainBeatDuration, currentPartPosition)

    if startOfPart == true or polyphony > 1 then
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
      for voice=1, #strategyIndex do
        local strategy = createStrategy(currentPartPosition)
        table.insert(strategies, strategy)
        strategyIndex[voice] = getRandom(#strategies)
        if autoStrategy == true then
          paramsPerPart[currentPartPosition].strategyInput.text = table.concat(strategies[strategyIndex[voice]], ",") -- TODO Handle voice
        end
      end
      --strategyIndex[1] = #strategies
      --strategyIndex[1] = 1
      noteSelection = {} -- Reset note selection
      inversionIndex = 1 -- Reset counter for inversion progress
      notePosition = 0 -- Reset counter for chord progress TODO Param for this?
      chordDefinitionIndex = 1 -- Set default
      -- Find chord types to include
      local chords = paramsPerPart[currentPartPosition].chords
      local activeChordDefinitions = {}
      for i,v in ipairs(chords) do
        if getRandomBoolean(v.value) == true then
          table.insert(activeChordDefinitions, i)
        end
      end

      if #activeChordDefinitions > 0 then
        -- Get a chord def index from the active definitions
        chordDefinitionIndex = activeChordDefinitions[getRandom(#activeChordDefinitions)]
        print("Chord inversions selected by random/#activeChordDefinitions", chordDefinitionIndex, #activeChordDefinitions)
      end

      -- Always use the first inversion at the start of a part
      -- Otherwise we select an inversion by random
      if startOfPart == false and polyphony > 1 then
        -- TODO Param for inversions
        inversionIndex = getRandom(#chordDefinitions[chordDefinitionIndex])
        print("Set random inversionIndex", inversionIndex)
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
    local function getNoteToPlay(voice)
      local minNote = paramsPerPart[currentPartPosition].minNote.value
      local maxNote = paramsPerPart[currentPartPosition].maxNote.value

      -- Ensure voice has a strategy!
      if type(strategyIndex[voice]) == "nil" then
        strategyIndex[voice] = getRandom(#strategies)
      end

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
        if currentDepth == maxDepth then
          -- Ensure we do not subdivide deeper
          print("Max depth reached", currentDepth)
        else
          if #subdivisions == 1 then
            subdivision = subdivisions[1]
            print("SET SELECTED subdivision", subdivision)
          elseif #subdivisions > 1 and getRandomBoolean(subdivisionProbability) then
            subdivision = subdivisions[getRandom(#subdivisions)]
            print("SET RANDOM subdivision", subdivision)
          end
        end
        return subdivision
      end

      -- Generate note method
        -- note: the note to play
        -- notes: the notes to play for subdivision
        -- subdivision: the subdivision of the note
        -- step: the step (tablePos) the note was triggered at
        -- steps: the duration of the note in steps
        -- stepCounter: the counter for how many steps the note has lasted so far
      local function generateNote(stepDuration, currentDepth)
        if type(stepDuration) == "nil" then
          stepDuration = mainBeatDuration
        end

        if type(currentDepth) == "nil" then
          currentDepth = 0
        end

        local subdivision = getSubdivision(currentDepth)
        print("Got subdivision/currentDepth", subdivision, currentDepth)

        local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
        local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
        local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value
        local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
        local hasHarmonizeableScale = canHarmonizeScale(paramsPerPart[currentPartPosition].scale)
        local minResolution = getResolution(paramsPerPart[currentPartPosition].subdivisionMinResolution.value)
        local steps = getRandom(minNoteSteps, maxNoteSteps)
        local note = nil
        local baseMin = minNote
        local baseMax = maxNote

        if currentDepth == 0 and polyphony > 1 then
          if hasNoteWithinMonoLimit(notes, currentPartPosition) == true then
            -- Ensure we only have one note below the mono limit
            baseMin = monoLimit
            print("Adjust baseMin to mono limit", baseMin)
          elseif monoLimit > baseMin then
            -- Ensure we have a note within the mono limit
            baseMax = monoLimit
            print("Adjust baseMax to mono limit", baseMax)
          end
        end

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
            -- Increment inversion pos
            inversionPos = inversionPos + 1
            if inversionPos > #chordDefinitions[chordDefinitionIndex] then
              inversionPos = 1
            end
          end
          return chordTable
        end

        local function getBaseNote()
          local baseNote = minNote -- Start from the lowest note
          local useBaseNote = currentStep == 1
          if polyphony == 1 then
            useBaseNote = (currentRound % paramsPerPart[currentPartPosition].numStepsBox.value) - 1 == 0
            print("useBaseNote/currentRound/modulo", useBaseNote, currentRound, (currentRound % paramsPerPart[currentPartPosition].numStepsBox.value) - 1)
          end
          if useBaseNote and getRandomBoolean(baseNoteRandomization) then
            while isRootNote(baseNote, currentPartPosition) == false and baseNote <= baseMax do
              baseNote = baseNote + 1 -- increment note to find the base note
            end
            print("Get root note: note/baseMin/baseMax", baseNote, baseMin, baseMax)
          else
            local noteRange = baseMax - baseMin
            if polyphony == 1 or currentDepth > 0 then
              noteRange = math.min(noteRange, 12) -- Get a note from the lowest octave
              print("Get note range for poly1 or depth > 0", noteRange)
            elseif monoLimit < baseMin then
              -- If there is no mono limit, we ajust the note range by polyphony to get a base note range
              noteRange = math.ceil(noteRange / polyphony)
              print("Calculate range for base note baseMin/baseMax/noteRange", baseMin, baseMax, noteRange)
            end
            baseNote = baseNote + getRandom(noteRange) - 1
            local scale = getFilteredScale(currentPartPosition, baseMin, baseMax)
            baseNote = getNoteAccordingToScale(scale, baseNote)
            print("Get random note from the low range: note/baseMin/monoLimit/baseMax/noteRange", baseNote, baseMin, monoLimit, baseMax, noteRange)
          end

          return baseNote
        end

        local harmonizationPropbability = paramsPerPart[currentPartPosition].harmonizationPropbability.value
        local strategyPropbability = paramsPerPart[currentPartPosition].strategyPropbability.value
        if getRandomBoolean(strategyPropbability) == true and (polyphony == 1 or currentDepth > 0) then
          if #noteSelection == 0 then
            local baseNote
            if polyphony == 1 and polyMode == true and currentPartPosition > 1 and type(paramsPerPart[1].baseNote) == "number" then
              baseNote = transpose(paramsPerPart[1].baseNote, baseMin, baseMax)
              inversionIndex = paramsPerPart[1].inversionIndex
              print("Got baseNote/inversionIndex from main part", baseNote, inversionIndex)
            else
              baseNote = getBaseNote()
            end
            if getRandomBoolean(harmonizationPropbability) == true and hasHarmonizeableScale == true and polyphony == 1 then
              noteSelection = getChord(baseNote)
              print("Get note selection from chord #noteSelection", #noteSelection)
            else
              local scaleMax = baseMax
              if (baseMax - baseNote) >= 24 then
                scaleMax = getRandom(baseMax-11,baseMax) -- Do this for variation on decrementing strategies
              end
              noteSelection = getFilteredScale(currentPartPosition, baseNote, scaleMax)
              print("Get note selection from scale #noteSelection", #noteSelection)
            end
            if polyphony == 1 and polyMode == true and currentPartPosition == 1 then
              paramsPerPart[1].baseNote = baseNote
              paramsPerPart[1].inversionIndex = inversionIndex
            end
          end
          notePosition, strategyPos = getNotePositionFromStragegy(noteSelection, notePosition, strategyIndex, strategyPos, currentPartPosition, voice)
          note = noteSelection[notePosition]
          print("Found note, notePosition, strategyIndex, voice", note, notePosition, strategyIndex[voice], voice)
        elseif getRandomBoolean(harmonizationPropbability) == true and currentDepth == 0 and polyphony > 1 and hasHarmonizeableScale == true then
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

            local fullScale = paramsPerPart[currentPartPosition].fullScale
            local scaleIndex = getNextScaleIndex(prevNote, fullScale, chordDefinitionIndex, inversionIndex)
            -- Ensure note is within range
            note = transpose(fullScale[scaleIndex], baseMin, baseMax)
            local noteRange = baseMax - prevNote
            local octaveRange = math.floor(noteRange / 12)
            local notesLeft = polyphony - #notes
            local octave = math.floor(octaveRange / notesLeft)
            if octave > 0 and note > baseMax / 2 and getRandomBoolean() then
              octave = -octave
              print("Negative octave", octave)
            end
            local octaveOffset = octave * 12
            print("Calculate octave adjustment - noteRange/octaveRange/notesLeft/octave", noteRange, octaveRange, notesLeft, octave)
            if octaveOffset > 0 and note + octaveOffset <= baseMax then
              note = note + octaveOffset
              print("Octave adjusted octave/octaveOffset/note", octave, octaveOffset, note)
            end
            inversionIndex = inversionIndex + 1
            if inversionIndex > #chordDefinitions[chordDefinitionIndex] then
              inversionIndex = 1
            end
            print("Found note from prev note - note, prevNote", note, prevNote)
          end
        end

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

        -- Get base note
        if type(note) == "nil" and polyphony > 1 and currentDepth == 0 and #notes == 0 then
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
          if polyMode == true and currentPartPosition > 1 and type(paramsPerPart[1].baseNote) == "number" then
            baseNote = transpose(paramsPerPart[1].baseNote, baseMin, baseMax)
            inversionIndex = paramsPerPart[1].inversionIndex
            print("Got baseNote/inversionIndex from main part", baseNote, inversionIndex)
          else
            local maxAttempts = 3
            local counter = 0
            -- TODO Check for repeated basenote+inversionDefinition+inversion
            while counter < maxAttempts do
              local baseNote = getBaseNote()
              if validateBaseNote(baseNote) == true then
                note = baseNote
                if polyMode == true and currentPartPosition == 1 then
                  paramsPerPart[1].baseNote = baseNote
                  paramsPerPart[1].inversionIndex = inversionIndex
                end
                break
              end
              counter = counter + 1
              print("Retry getting basenote/tries/valid", note, counter, valid)
            end
          end
        end

        -- Get a random or strategic note from the current scale / chord
        if type(note) == "nil" then
          if #noteSelection > 0 and getRandomBoolean() then
            if getRandomBoolean(strategyPropbability) == true then
              notePosition, strategyPos = getNotePositionFromStragegy(noteSelection, notePosition, strategyIndex, strategyPos, currentPartPosition, voice)
              note = noteSelection[notePosition]
              print("Get note from selection using strategy: note/baseMin/baseMax/strategyIndex, voice", note, baseMin, baseMax, strategyIndex[voice], voice)
            else
              note = noteSelection[getRandom(#noteSelection)]
              print("Get random note from selection: note/baseMin/baseMax", note, baseMin, baseMax)
            end
          else
            local scale = getFilteredScale(currentPartPosition, baseMin, baseMax)
            if getRandomBoolean(strategyPropbability) == true then
              notePosition, strategyPos = getNotePositionFromStragegy(scale, notePosition, strategyIndex, strategyPos, currentPartPosition, voice)
              note = scale[notePosition]
              print("Get note from scale using strategy: note/baseMin/baseMax/strategyIndex, voice", note, baseMin, baseMax, strategyIndex[voice], voice)
            else
              note = scale[getRandom(#scale)]
              print("Get random note from scale: note/baseMin/baseMax", note, baseMin, baseMax)
            end
          end
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
            local subDivNote = generateNote(subDivDuration, currentDepth)
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
          voice = voice,
          step = tablePos,
          steps = steps,
          stepDuration = stepDuration,
          subdivision = subdivision,
          notes = subdivisionNotes,
          stepCounter = 0
        }
      end
    
      return generateNote()
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
          local noteToPlay = getNoteToPlay(voice)
          if notesInclude(notes, noteToPlay.note) == false then
            table.insert(notes, noteToPlay)
            print("Insert note", noteToPlay.note)
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

    if polyButton.value == true then
      -- UPDATE STEP POSITION TABLE
      for i=1, paramsPerPart[currentPartPosition].numStepsBox.value do
        if i == currentPosition - startStep + 1 then
          paramsPerPart[currentPartPosition].positionTable:setValue(i, 1)
        else
          paramsPerPart[currentPartPosition].positionTable:setValue(i, 0)
        end
      end
    else
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
