--------------------------------------------------------------------------------
-- GENEREATIVE SEQUENCER
--------------------------------------------------------------------------------

require "common"

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
local sequences = {} -- Each part has its own sequences
local maxSequences = 16 -- Max stored sequences for each part TODO Use parameter
local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}, {5,2,5}, {7,5}, {12}, {3}, {5}, {7}}
local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

setBackgroundColour("#5f5f5f")

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getRandomNote(partPos)
  local scale = paramsPerPart[partPos].filteredScale
  if #scale > 0 then
    return scale[getRandom(#scale)]
  end

  return getRandom(paramsPerPart[partPos].minNote.value, paramsPerPart[partPos].maxNote.value)
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
    v.key.visible = isVisible
    v.scale.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.baseNoteRandomization.visible = isVisible
    v.sequenceRepeatProbability.visible = isVisible
    v.sequenceRepeatProbabilityDecay.visible = isVisible
    v.roundsBeforeRepeat.visible = isVisible
    v.subdivisionProbability.visible = isVisible
    v.subdivisionRepeatProbability.visible = isVisible
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
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].polyphony.value = prev.polyphony.value
      paramsPerPart[i].scale.value = prev.scale.value
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].minNote.value = prev.minNote.value
      paramsPerPart[i].maxNote.value = prev.maxNote.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].numSteps = prev.numSteps
      paramsPerPart[i].fullScale = prev.fullScale
      paramsPerPart[i].filteredScale = prev.filteredScale
      paramsPerPart[i].velRandomization.value = prev.velRandomization.value
      paramsPerPart[i].gateRandomization.value = prev.gateRandomization.value
      paramsPerPart[i].baseNoteRandomization.value = prev.baseNoteRandomization.value
      paramsPerPart[i].sequenceRepeatProbability.value = prev.sequenceRepeatProbability.value
      paramsPerPart[i].sequenceRepeatProbabilityDecay.value = prev.sequenceRepeatProbabilityDecay.value
      paramsPerPart[i].roundsBeforeRepeat.value = prev.roundsBeforeRepeat.value
      paramsPerPart[i].subdivisionProbability.value = prev.subdivisionProbability.value
      paramsPerPart[i].subdivisionRepeatProbability.value = prev.subdivisionRepeatProbability.value
      paramsPerPart[i].init = prev.init
      --[[ for _,s in ipairs(paramsPerPart[i].subdivisions) do
        s.value = ???
      end ]]
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
partRandBox.width = numPartsBox.width
partRandBox.x = numPartsBox.x
partRandBox.y = numPartsBox.y + numPartsBox.height + 5
partRandBox.changed = function(self)
  partRandomizationAmount = self.value
end

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

local noteRangeLabel = sequencerPanel:Label("NoteRangeLabel")
noteRangeLabel.persistent = false
noteRangeLabel.text = "Note Range"

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  print("Set paramsPerPart", i)

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
  seqVelTable.y = partRandBox.y + 130
  
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

  local generatePolyphonyPart = sequencerPanel:NumBox("GeneratePolyphony" .. i, 1, 1, 16, true)
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
  stepResolution.displayName = "Step Resolution"
  stepResolution.selected = 20
  stepResolution.x = generatePolyphonyPart.x + generatePolyphonyPart.width + 10
  stepResolution.y = generatePolyphonyPart.y
  stepResolution.width = generateMaxNoteStepsPart.width
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

  if i == 1 then
    noteRangeLabel.x = stepResolution.x + stepResolution.width + 10
    noteRangeLabel.y = stepResolution.y
    noteRangeLabel.width = stepResolution.width
    noteRangeLabel.height = 20
  end

  local generateMinPart = sequencerPanel:NumBox("GenerateMin" .. i, 24, 0, 127, true)
  generateMinPart.unit = Unit.MidiKey
  generateMinPart.showPopupDisplay = true
  generateMinPart.showLabel = true
  generateMinPart.backgroundColour = menuBackgroundColour
  generateMinPart.textColour = menuTextColour
  generateMinPart.displayName = "Min"
  generateMinPart.tooltip = "Lowest note"
  generateMinPart.x = noteRangeLabel.x
  generateMinPart.y = noteRangeLabel.y + noteRangeLabel.height + 5
  generateMinPart.width = stepResolution.width

  local generateMaxPart = sequencerPanel:NumBox("GenerateMax" .. i, 84, 0, 127, true)
  generateMaxPart.unit = Unit.MidiKey
  generateMaxPart.showPopupDisplay = true
  generateMaxPart.showLabel = true
  generateMaxPart.backgroundColour = menuBackgroundColour
  generateMaxPart.textColour = menuTextColour
  generateMaxPart.displayName = "Max"
  generateMaxPart.tooltip = "Highest note"
  generateMaxPart.x = generateMinPart.x
  generateMaxPart.y = generateMinPart.y + generateMinPart.height + 5
  generateMaxPart.width = generateMinPart.width

  generateMinPart.changed = function(self)
    createFilteredScale(i)
    generateMaxPart:setRange(self.value, 127)
  end

  generateMaxPart.changed = function(self)
    createFilteredScale(i)
    generateMinPart:setRange(0, self.value)
  end

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, notenames)
  generateKeyPart.displayName = "Key / Scale"
  generateKeyPart.width = generateMaxPart.width
  generateKeyPart.x = generateMinPart.x + generateMinPart.width + 10
  generateKeyPart.y = stepResolution.y
  generateKeyPart.backgroundColour = menuBackgroundColour
  generateKeyPart.textColour = menuTextColour
  generateKeyPart.arrowColour = menuArrowColour
  generateKeyPart.outlineColour = menuOutlineColour
  generateKeyPart.changed = function (self)
    createFullScale(i)
    createFilteredScale(i)
  end

  local generateScalePart = sequencerPanel:Menu("GenerateScale" .. i, {"12 tone", "Major", "Minor", "Dorian", "Whole tone", "Major Pentatonic", "Minor Pentatonic", "1-4-5", "1-5", "1", "Dim", "Fours", "Fives"})
  generateScalePart.displayName = "Scale"
  generateScalePart.showLabel = false
  generateScalePart.height = 20
  generateScalePart.width = generateKeyPart.width
  generateScalePart.x = generateKeyPart.x
  generateScalePart.y = generateKeyPart.y + generateKeyPart.height + 5
  generateScalePart.backgroundColour = menuBackgroundColour
  generateScalePart.textColour = menuTextColour
  generateScalePart.arrowColour = menuArrowColour
  generateScalePart.outlineColour = menuOutlineColour
  generateScalePart.changed = function (self)
    createFullScale(i)
    createFilteredScale(i)
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
    local sequenceProbabilityLabel = sequencerPanel:Label("SequenceProbabilityLabel")
    sequenceProbabilityLabel.text = "Repetition"
    sequenceProbabilityLabel.x = 0
    sequenceProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
    sequenceProbabilityLabel.width = 227
  end

  local sequenceRepeatProbability = sequencerPanel:NumBox("SequenceRepeatProbability" .. i, 100, 0, 100, true)
  sequenceRepeatProbability.displayName = "Repeat Probability"
  sequenceRepeatProbability.tooltip = "Probability that sequences will be repeated in part or fully"
  sequenceRepeatProbability.unit = Unit.Percent
  sequenceRepeatProbability.width = 227
  sequenceRepeatProbability.x = 0
  sequenceRepeatProbability.y = partRandBox.y + (partRandBox.height * 2) + 10
  sequenceRepeatProbability.backgroundColour = menuBackgroundColour
  sequenceRepeatProbability.textColour = menuTextColour

  local sequenceRepeatProbabilityDecay = sequencerPanel:NumBox("SequenceRepeatProbabilityDecay" .. i, 25, 0, 100, true)
  sequenceRepeatProbabilityDecay.displayName = "Repeat Probability Decay"
  sequenceRepeatProbabilityDecay.tooltip = "How much will the repeat probability decay for each round?"
  sequenceRepeatProbabilityDecay.unit = Unit.Percent
  sequenceRepeatProbabilityDecay.width = sequenceRepeatProbability.width
  sequenceRepeatProbabilityDecay.x = 0
  sequenceRepeatProbabilityDecay.y = sequenceRepeatProbability.y + sequenceRepeatProbability.height + 5
  sequenceRepeatProbabilityDecay.backgroundColour = menuBackgroundColour
  sequenceRepeatProbabilityDecay.textColour = menuTextColour

  local roundsBeforeRepeat = sequencerPanel:NumBox("RoundsBeforeRepeat" .. i, 1, 1, 16, true)
  roundsBeforeRepeat.displayName = "Rounds Before Repeat"
  roundsBeforeRepeat.tooltip = "How many sequences are generated before we start repeating?"
  roundsBeforeRepeat.width = sequenceRepeatProbability.width
  roundsBeforeRepeat.x = 0
  roundsBeforeRepeat.y = sequenceRepeatProbabilityDecay.y + sequenceRepeatProbabilityDecay.height + 5
  roundsBeforeRepeat.backgroundColour = menuBackgroundColour
  roundsBeforeRepeat.textColour = menuTextColour

  if i == 1 then
    local subdivisionProbabilityLabel = sequencerPanel:Label("SubdivisionProbabilityLabel")
    subdivisionProbabilityLabel.text = "Subdivision"
    subdivisionProbabilityLabel.x = roundsBeforeRepeat.width + 5
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
    subdivisionProbabilityLabel.width = 227
  end

  local subdivisions = {}
  for j=2,9 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, (j<4))
    subdivision.backgroundColourOff = "#ff084486"
    subdivision.backgroundColourOn = "#ff02ACFE"
    subdivision.textColourOff = "#ff22FFFF"
    subdivision.textColourOn = "#efFFFFFF"
    subdivision.fillColour = "#dd000061"
    subdivision.displayName = "" .. j
    subdivision.tooltip = "Activate subdivision"
    subdivision.height = 20
    subdivision.width = 26
    subdivision.x = roundsBeforeRepeat.width + 5 + ((j-2) * (subdivision.width+2.8))
    subdivision.y = partRandBox.y + (partRandBox.height * 2) + 10
    table.insert(subdivisions, subdivision)
  end

  local subdivisionProbability = sequencerPanel:NumBox("SubdivisionProbability" .. i, 25, 0, 100, true)
  subdivisionProbability.displayName = "Subdivision Probability"
  subdivisionProbability.tooltip = "Probability that subdivisions will occur"
  subdivisionProbability.unit = Unit.Percent
  subdivisionProbability.width = 227
  subdivisionProbability.x = roundsBeforeRepeat.width + 5
  subdivisionProbability.y = subdivisions[1].y + subdivisions[1].height + 5 --partRandBox.y + (partRandBox.height * 2) + 10
  subdivisionProbability.backgroundColour = menuBackgroundColour
  subdivisionProbability.textColour = menuTextColour

  local subdivisionRepeatProbability = sequencerPanel:NumBox("SubdivisionRepeatProbability" .. i, 0, 0, 100, true)
  subdivisionRepeatProbability.displayName = "Repeat Probability"
  subdivisionRepeatProbability.tooltip = "What is the probability that the same note will be played in the subdivision, meaning that the same note is repeated?"
  subdivisionRepeatProbability.unit = Unit.Percent
  subdivisionRepeatProbability.width = sequenceRepeatProbability.width
  subdivisionRepeatProbability.x = subdivisionProbability.x
  subdivisionRepeatProbability.y = subdivisionProbability.y + subdivisionProbability.height + 5
  subdivisionRepeatProbability.backgroundColour = menuBackgroundColour
  subdivisionRepeatProbability.textColour = menuTextColour

  table.insert(paramsPerPart, {subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,subdivisionRepeatProbability=subdivisionRepeatProbability,sequenceRepeatProbability=sequenceRepeatProbability,sequenceRepeatProbabilityDecay=sequenceRepeatProbabilityDecay,roundsBeforeRepeat=roundsBeforeRepeat,velRandomization=velRandomization,gateRandomization=gateRandomization,baseNoteRandomization=baseNoteRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,stepResolution=stepResolution,numSteps=0,fullScale={},filteredScale={},scale=generateScalePart,key=generateKeyPart,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})
end

local sequenceMemoryLabel = sequencerPanel:Label("SequenceMemory")
sequenceMemoryLabel.displayName = "Sequence Memory" -- Used to hold default value
sequenceMemoryLabel.text = sequenceMemoryLabel.displayName
sequenceMemoryLabel.x = paramsPerPart[1].subdivisionProbability.x + paramsPerPart[1].subdivisionProbability.width + 10
sequenceMemoryLabel.y = partRandBox.y + partRandBox.height + 5
sequenceMemoryLabel.width = 227

local maxSequencesBox = sequencerPanel:NumBox("MaxSequences", maxSequences, 1, 32, true)
maxSequencesBox.displayName = "Memory"
maxSequencesBox.tooltip = "How many sequences are remebered? Few means less variation, many means more variation"
maxSequencesBox.width = 225
maxSequencesBox.height = 20
maxSequencesBox.x = sequenceMemoryLabel.x
maxSequencesBox.y = sequenceMemoryLabel.y + sequenceMemoryLabel.height + 5
maxSequencesBox.backgroundColour = menuBackgroundColour
maxSequencesBox.textColour = menuTextColour
maxSequencesBox.changed = function(self)
  maxSequences = self.value
end

local sequencesPerPart = sequencerPanel:OnOffButton("SequencesPerPartOnOff", false)
sequencesPerPart.displayName = "Per Part"
sequencesPerPart.tooltip = "When this is selected, each part has it's own sequences. That means more variation between parts."
sequencesPerPart.backgroundColourOff = "#ff084486"
sequencesPerPart.backgroundColourOn = "#ff02ACFE"
sequencesPerPart.textColourOff = "#ff22FFFF"
sequencesPerPart.textColourOn = "#efFFFFFF"
sequencesPerPart.fillColour = "#dd000061"
sequencesPerPart.height = maxSequencesBox.height
sequencesPerPart.width = (maxSequencesBox.width / 2)
sequencesPerPart.x = maxSequencesBox.x
sequencesPerPart.y = maxSequencesBox.y + maxSequencesBox.height + 5

local replaceSequence = sequencerPanel:OnOffButton("ReplaceSequenceOnOff", false)
replaceSequence.displayName = "Replace"
replaceSequence.tooltip = "When this is selected, the sequence is replaced for each round when the buffer is full. That means more variation between rounds."
replaceSequence.backgroundColourOff = "#ff084486"
replaceSequence.backgroundColourOn = "#ff02ACFE"
replaceSequence.textColourOff = "#ff22FFFF"
replaceSequence.textColourOn = "#efFFFFFF"
replaceSequence.fillColour = "#dd000061"
replaceSequence.height = sequencesPerPart.height
replaceSequence.width = sequencesPerPart.width
replaceSequence.x = sequencesPerPart.x + sequencesPerPart.width + 5
replaceSequence.y = sequencesPerPart.y

local clearSequences = sequencerPanel:Button("ClearSequences")
clearSequences.displayName = "Clear Sequence Memory"
clearSequences.tooltip = "This will purge all sequences currently remembered"
clearSequences.persistent = false
clearSequences.x = sequenceMemoryLabel.x
clearSequences.y = replaceSequence.y + replaceSequence.height + 5
clearSequences.width = maxSequencesBox.width
clearSequences.height = maxSequencesBox.height

clearSequences.changed = function()
  sequences = {}
  sequenceMemoryLabel.text = sequenceMemoryLabel.displayName
  print("Sequences cleared!", #sequences)
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Scale and note functions
--------------------------------------------------------------------------------

function createFilteredScale(part)
  paramsPerPart[part].filteredScale = {}
  if #paramsPerPart[part].fullScale > 0 then
    -- Filter out notes outside min/max
    local minNote = paramsPerPart[part].minNote.value
    local maxNote = paramsPerPart[part].maxNote.value  
    for i=1,#paramsPerPart[part].fullScale do
      if paramsPerPart[part].fullScale[i] >= minNote and paramsPerPart[part].fullScale[i] <= maxNote then
        table.insert(paramsPerPart[part].filteredScale, paramsPerPart[part].fullScale[i])
      end
    end
  end
  --print("Filtered scale contains notes:", #paramsPerPart[part].filteredScale)
end

function createFullScale(part)
  paramsPerPart[part].fullScale = {}
  if paramsPerPart[part].scale.value == 1 then
    return
  end
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

function notesInclude(notesTable, note)
  for _,v in pairs(notesTable) do
    if v.note == note then
      --print("Note already included", note)
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function playSubdivision(note)
  local waitDuration = (note.stepDuration * note.steps) / note.subdivision
  local playDuration = beat2ms(waitDuration) * (note.gate / 100)
  for i=1,note.subdivision do
    print("PlaySubdivision i/type(note)/note/dur/subdiv", i, type(note.notes[i]), note.notes[i], playDuration, note.subdivision)
    playNote(note.notes[i], note.vel, (playDuration-1))
    waitBeat(waitDuration)
  end
end

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentPartPosition = 0 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local sequenceRepeatProbability = nil
  local recordedNotes = {}
  local heldNoteIndex = 0
  local sequencePartIndex = 1
  local sequenceCounter = 0 -- Holds the pointer for what sequence to select notes from
  local isStarting = true
  -- START ARP LOOP
  while isPlaying do
    -- SET VALUES
    local numParts = numPartsBox.value
    local currentPosition = (index % totalNumSteps) + 1
    local startOfPart = false
    local partWasChanged = false
    if sequencesPerPart.value == true then
      sequencePartIndex = currentPartPosition
    end
    print("currentPosition", currentPosition)
    -- Set part position
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        -- Set start of part
        startOfPart = true
        -- Store the recorded notes before changing parts
        if #recordedNotes > 0 then

          -- Increment sequence counter
          sequenceCounter = sequenceCounter + 1
          print("Increment sequenceCounter", sequenceCounter)
          if sequenceCounter > maxSequences then
            sequenceCounter = 1
            print("Reset sequenceCounter", sequenceCounter)
          end

          local storedSequences = {}
          -- Include the already stored notes
          if type(sequences[sequencePartIndex]) == "table" then
            storedSequences = sequences[sequencePartIndex]
          end
          if type(sequences[sequencePartIndex]) ~= "table" or #sequences[sequencePartIndex] < maxSequences then
            -- Add the recorded notes
            table.insert(storedSequences, recordedNotes)
            print("Added the recorded notes to #storedSequences", #storedSequences)
          elseif replaceSequence.value == true then
            -- When buffer is full, we insert the recorded notes at the current position (if replaceSequence option is true)
            table.remove(storedSequences, sequenceCounter)
            table.insert(storedSequences, sequenceCounter, recordedNotes)
            print("Updated storedSequences index", sequenceCounter)
          end

          table.remove(sequences, currentPartPosition)
          table.insert(sequences, currentPartPosition, storedSequences)

          sequenceMemoryLabel.text = sequenceMemoryLabel.displayName .. " (Playing seq " .. sequenceCounter .. ")"

          print("SAVE SEQUENCE notes/sequences/currentPartPosition/type(storedSequences)", #recordedNotes, #sequences[sequencePartIndex], currentPartPosition, type(storedSequences))
          recordedNotes = {} -- Clear the recored notes
        end
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
        print("index before", index)
        local randomPartPosition = getRandom(numParts)
        partWasChanged = currentPartPosition ~= randomPartPosition
        currentPartPosition = randomPartPosition
      end
      -- Find the current pos and index
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
      print("currentPartPosition after/partWasChanged", currentPartPosition, partWasChanged)
      print("currentPosition after", currentPosition)
      print("index after", index)
    end

    if partWasChanged then
      sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
      if type(sequences[sequencePartIndex]) == "table" then
        sequenceCounter = #sequences[sequencePartIndex]
      else
        sequenceCounter = 0
      end
    end

    local sequenceRepeatProbabilityDecay = paramsPerPart[currentPartPosition].sequenceRepeatProbabilityDecay.value
    if type(sequenceRepeatProbability) ~= "number" then
      sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
    end

    if startOfPart and isStarting == false and sequenceRepeatProbability > 0 then
      -- Calculate decay
      --local originalSequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
      --local minProbability = originalSequenceRepeatProbability - getChangeMax(originalSequenceRepeatProbability, sequenceRepeatProbabilityDecay)
      local minProbability = math.ceil(sequenceRepeatProbability / 2) -- TODO Param
      local changeMax = getChangeMax(sequenceRepeatProbability, sequenceRepeatProbabilityDecay)
      local decay = math.ceil(changeMax / maxSequences)
      print("Before decay/changeMax/sequenceRepeatProbability/sequenceRepeatProbabilityDecay", decay, changeMax, sequenceRepeatProbability, sequenceRepeatProbabilityDecay)
      sequenceRepeatProbability = sequenceRepeatProbability - decay -- Decay
      print("After decay sequenceRepeatProbability", sequenceRepeatProbability)
      if sequenceRepeatProbability < minProbability or sequenceRepeatProbabilityDecay == 0 then
        sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
        print("Reset sequenceRepeatProbability", sequenceRepeatProbability)
      end
    end

    -- Get subdivision info
    local subdivisionProbability = paramsPerPart[currentPartPosition].subdivisionProbability.value
    local subdivisionRepeatProbability = paramsPerPart[currentPartPosition].subdivisionRepeatProbability.value
    local subdivisions = {1}
    for i,v in ipairs(paramsPerPart[currentPartPosition].subdivisions) do
      if v.value then
        table.insert(subdivisions, (i+1))
        print("Added subdivision", (i+1), #subdivisions)
      end
    end

    local stepDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local startStep = partToStepMap[currentPartPosition]

    -- Tables for current step position
    local seqVelTable = paramsPerPart[currentPartPosition].seqVelTable
    local seqGateTable = paramsPerPart[currentPartPosition].seqGateTable

    -- Params for current step position
    local tablePos = currentPosition - startStep + 1
    local vel = seqVelTable:getValue(tablePos) -- get velocity
    local gate = seqGateTable:getValue(tablePos) -- get gate

    -- Randomize gate
    local gateRandomization = paramsPerPart[currentPartPosition].gateRandomization.value
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

    -- Randomize vel
    local velRandomization = paramsPerPart[currentPartPosition].velRandomization.value
    if getRandomBoolean(velRandomization) then
      local changeMax = getChangeMax(seqVelTable.max, velRandomization)
      local min = vel - changeMax
      local max = vel + changeMax
      if min < seqVelTable.min then
        min = seqVelTable.min
      end
      if max > seqVelTable.max then
        max = seqVelTable.max
      end
      --print("Before randomize vel", vel)
      vel = getRandom(min, max)
      --print("After randomize vel/changeMax/min/max", vel, changeMax, min, max)
    end

    -- If gate is zero no notes will play on this step
    if gate > 0 then

      -- note: the note to play
      -- gate: gate length
      -- vel: note velocity
      -- steps: the duration of the note in steps
      -- stepCounter: the counter for how many steps the note has lasted so far

      -- Number of simultainious notes are set by polyphony
      local polyphony = paramsPerPart[currentPartPosition].polyphony.value
      local minNote = paramsPerPart[currentPartPosition].minNote.value
      local maxNote = paramsPerPart[currentPartPosition].maxNote.value
      local minNoteSteps = paramsPerPart[currentPartPosition].minNoteSteps.value
      local maxNoteSteps = paramsPerPart[currentPartPosition].maxNoteSteps.value
      local numberOfNotes = polyphony -- Default is "mono"
      if numberOfNotes > 1 and maxNoteSteps > 1 then
        numberOfNotes = getRandom(polyphony)
      end

      -- On step one, always add the base note if probability hits (unless low drone is active)
      local baseNoteRandomization = paramsPerPart[currentPartPosition].baseNoteRandomization.value
      if currentStep == 1 and notesInclude(notes, minNote) == false and getRandomBoolean(baseNoteRandomization) then
        local noteSteps = getRandom(minNoteSteps,maxNoteSteps)
        table.insert(notes, {note=minNote,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
        print("Insert base note note/steps/vel/gate", minNote, noteSteps, vel, gate)
      end

      -- Check how many notes are already playing, and remove number from numberOfNotes if more than max polyphony
      if numberOfNotes + #notes > polyphony then
        numberOfNotes = numberOfNotes - #notes
      end

      -- Note function
      local function getNoteToPlay()
        --print("getNoteToPlay sequenceRepeatProbability", sequenceRepeatProbability)
        local roundsBeforeRepeat = paramsPerPart[currentPartPosition].roundsBeforeRepeat.value -- How many sequences are generated before we start repeating
        local partSequences = sequences[sequencePartIndex]
        if type(partSequences) == "table" and #partSequences >= roundsBeforeRepeat and getRandomBoolean(sequenceRepeatProbability) then
          local sequence = {}
          if #partSequences > 0 and getRandomBoolean(sequenceRepeatProbability) then
            -- Select sequence by counter
            if sequenceCounter > #partSequences then
              sequenceCounter = #partSequences
            end
            sequence = partSequences[sequenceCounter]
            print("Getting sequence from sequenceCounter pos", sequenceCounter, #partSequences)
          else
            local sequenceIndex = getRandom(#partSequences)
            sequence = partSequences[sequenceIndex]
            print("Getting sequence from random sequenceIndex/#sequences@currentPartPosition", sequenceIndex, #partSequences)
          end
          local notesAtCurrentStep = {}
          print("Finding note at currentPosition/tablePos", currentPosition, tablePos)
          for _,v in ipairs(sequence) do
            if v.step == tablePos and notesInclude(notes, v.note.note) == false then
              table.insert(notesAtCurrentStep, v.note)
            end
          end
          print("Found notes at current step", #notesAtCurrentStep)
          if #notesAtCurrentStep > 0 then
            local note = notesAtCurrentStep[getRandom(#notesAtCurrentStep)]
            print("SEQUENCE note/noteSteps/sequenceCounter/sequenceRepeatProbability", note.note, note.steps, sequenceCounter, sequenceRepeatProbability)
            note.vel = vel -- Adjust to current vel
            note.gate = gate -- Adjust to current gate
            note.stepDuration = stepDuration -- Adjust to current step duration
            return note
          end
        end
        local note = getRandomNote(currentPartPosition)
        local noteSteps = getRandom(minNoteSteps, maxNoteSteps)
        print("RANDOM note/noteSteps/sequenceRepeatProbability", note, noteSteps)
        return {note=note,gate=gate,vel=vel,steps=noteSteps}
      end

      -- Add notes to play
      local noteCounter = 0
      local roundCounter = 0
      local maxRounds = numberOfNotes * 2
      while noteCounter < numberOfNotes and roundCounter < maxRounds do
        local noteToPlay = getNoteToPlay()
        if notesInclude(notes, noteToPlay.note) == false then
          noteToPlay.stepCounter = 0
          table.insert(notes, noteToPlay)
          print("Insert note", noteToPlay.note)
          noteCounter = noteCounter + 1
        end
        roundCounter = roundCounter + 1
        print("Increment roundCounter", roundCounter)
      end
      print("Notes ready to play", #notes)
    end

    -- PLAY NOTE(S)
    for _,note in ipairs(notes) do
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 and note.gate > 0 then
        -- Play the note for the number of steps that are set
        if type(note.stepDuration) ~= "number" then
          --note.duration = beat2ms(stepDuration * (note.gate/100) * note.steps)
          note.stepDuration = stepDuration
        end
        if type(note.subdivision) ~= "number" or getRandomBoolean(sequenceRepeatProbability) == false then
          if getRandomBoolean(subdivisionProbability) then
            note.subdivision = subdivisions[getRandom(#subdivisions)]
            print("SET RANDOM subdivision", note.subdivision)
          else
            note.subdivision = 1 -- Set default
          end
        end
        --print("NOTE HAS subdivision", note.subdivision)
        -- Subdiv different notes, not just repeat
        --print("type(note.notes)", type(note.notes))
        if type(note.notes) ~= "table" or #note.notes < note.subdivision then
          --[[ if type(note.notes) == "table" then
            print("#notes~=subdivision", type(note.notes), #note.notes, note.subdivision)
          else
            print("note.notes is not table", type(note.notes), note.subdivision)
          end ]]
          local subDivNotes = {}
          for i=1,note.subdivision do
            if i == 1 or getRandomBoolean(subdivisionRepeatProbability) then
              table.insert(subDivNotes, note.note)
              print("Using the main note@subdiv", note.note, i)
            else
              local subDivNote = getRandomNote(currentPartPosition)
              table.insert(subDivNotes, subDivNote)
              print("Using random note@subdiv", subDivNote, i)
            end
          end
          --[[ if #subDivNotes ~= note.subdivision then
            print("ERROR #subDivNotes/note.subdivision", #subDivNotes, note.subdivision)
          end ]]
          note.notes = subDivNotes
        end
        run(playSubdivision, note, currentPartPosition)
        table.insert(recordedNotes, {note=note,step=currentPosition})
        print("Playing note/stepDuration/note.gate/note.steps/note.stepDuration", note.note, stepDuration, note.gate, note.steps, note.stepDuration)
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
    waitBeat(stepDuration)
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
