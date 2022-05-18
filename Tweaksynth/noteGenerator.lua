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
local maxSequences = 2 -- Max stored sequences for each part - sets the default value for the maxSequencesBox parameter
local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}, {5,2,5}, {7,5}, {12}, {3}, {5}, {7}}
local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

setBackgroundColour("#5f5f5f")

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

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
    v.monoLimit.visible = isVisible
    v.key.visible = isVisible
    v.scale.visible = isVisible
    v.velRandomization.visible = isVisible
    v.gateRandomization.visible = isVisible
    v.baseNoteRandomization.visible = isVisible
    v.sequenceRepeatProbability.visible = isVisible
    v.sequenceRepeatProbabilityDecay.visible = isVisible
    v.sequenceRepeatProbabilityThreshold.visible = isVisible
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
      paramsPerPart[i].monoLimit.value = prev.monoLimit.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      --paramsPerPart[i].numSteps = prev.numSteps
      paramsPerPart[i].fullScale = prev.fullScale
      paramsPerPart[i].velRandomization.value = prev.velRandomization.value
      paramsPerPart[i].gateRandomization.value = prev.gateRandomization.value
      paramsPerPart[i].baseNoteRandomization.value = prev.baseNoteRandomization.value
      paramsPerPart[i].sequenceRepeatProbability.value = prev.sequenceRepeatProbability.value
      paramsPerPart[i].sequenceRepeatProbabilityDecay.value = prev.sequenceRepeatProbabilityDecay.value
      paramsPerPart[i].sequenceRepeatProbabilityThreshold.value = prev.sequenceRepeatProbabilityThreshold.value
      paramsPerPart[i].subdivisionProbability.value = prev.subdivisionProbability.value
      paramsPerPart[i].subdivisionRepeatProbability.value = prev.subdivisionRepeatProbability.value
      paramsPerPart[i].subdivisionMinResolution.value = prev.subdivisionMinResolution.value
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

--[[ local noteRangeLabel = sequencerPanel:Label("NoteRangeLabel")
noteRangeLabel.persistent = false
noteRangeLabel.text = "Note Range" ]]

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
  stepResolution.displayName = "Step Duration"
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

  --[[ if i == 1 then
    noteRangeLabel.x = stepResolution.x + stepResolution.width + 10
    noteRangeLabel.y = stepResolution.y
    noteRangeLabel.width = stepResolution.width
    noteRangeLabel.height = 20
  end ]]

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
    --createFilteredScale(i)
    generateMaxPart:setRange(self.value, 127)
  end

  generateMaxPart.changed = function(self)
    --createFilteredScale(i)
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
    --createFilteredScale(i)
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
    --createFilteredScale(i)
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

  local sequenceRepeatProbabilityThreshold = sequencerPanel:NumBox("SequenceRepeatProbabilityThreshold" .. i, 50, 0, 100, true)
  sequenceRepeatProbabilityThreshold.displayName = "Decay Threshold"
  sequenceRepeatProbabilityThreshold.tooltip = "How low can the repeat probability decay before it is reset?"
  sequenceRepeatProbabilityThreshold.unit = Unit.Percent
  sequenceRepeatProbabilityThreshold.width = sequenceRepeatProbability.width
  sequenceRepeatProbabilityThreshold.x = 0
  sequenceRepeatProbabilityThreshold.y = sequenceRepeatProbabilityDecay.y + sequenceRepeatProbabilityDecay.height + 5
  sequenceRepeatProbabilityThreshold.backgroundColour = menuBackgroundColour
  sequenceRepeatProbabilityThreshold.textColour = menuTextColour

  if i == 1 then
    local subdivisionProbabilityLabel = sequencerPanel:Label("SubdivisionProbabilityLabel")
    subdivisionProbabilityLabel.text = "Subdivision"
    subdivisionProbabilityLabel.x = sequenceRepeatProbabilityThreshold.width + 5
    subdivisionProbabilityLabel.y = partRandBox.y + partRandBox.height + 5
    subdivisionProbabilityLabel.width = 227
  end

  local subdivisions = {}
  for j=1,8 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, (j<3))
    subdivision.enabled = j > 1
    subdivision.backgroundColourOff = "#ff084486"
    subdivision.backgroundColourOn = "#ff02ACFE"
    subdivision.textColourOff = "#ff22FFFF"
    subdivision.textColourOn = "#efFFFFFF"
    subdivision.fillColour = "#dd000061"
    subdivision.displayName = "" .. j
    subdivision.tooltip = "Activate subdivision"
    subdivision.height = 20
    subdivision.width = 28
    subdivision.x = 270 + ((j-2) * (subdivision.width+2.8))
    subdivision.y = partRandBox.y + (partRandBox.height * 2) + 10
    table.insert(subdivisions, subdivision)
  end

  --[[ for j=9,16 do
    local subdivision = sequencerPanel:OnOffButton("SubdivisionSelect" .. i .. j, false)
    subdivision.backgroundColourOff = "#ff084486"
    subdivision.backgroundColourOn = "#ff02ACFE"
    subdivision.textColourOff = "#ff22FFFF"
    subdivision.textColourOn = "#efFFFFFF"
    subdivision.fillColour = "#dd000061"
    subdivision.displayName = "" .. j
    subdivision.tooltip = "Activate subdivision"
    subdivision.height = 20
    subdivision.width = 28
    subdivision.x = 270 + ((j-10) * (subdivision.width+2.8))
    subdivision.y = partRandBox.y + (partRandBox.height * 4) - 4
    table.insert(subdivisions, subdivision)
  end ]]

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
  subdivisionMinResolution.width = subdivisionProbability.width
  subdivisionMinResolution.backgroundColour = menuBackgroundColour
  subdivisionMinResolution.textColour = menuTextColour
  subdivisionMinResolution.arrowColour = menuArrowColour
  subdivisionMinResolution.outlineColour = menuOutlineColour

  table.insert(paramsPerPart, {subdivisionProbability=subdivisionProbability,subdivisions=subdivisions,subdivisionRepeatProbability=subdivisionRepeatProbability,subdivisionMinResolution=subdivisionMinResolution,sequenceRepeatProbability=sequenceRepeatProbability,sequenceRepeatProbabilityDecay=sequenceRepeatProbabilityDecay,sequenceRepeatProbabilityThreshold=sequenceRepeatProbabilityThreshold,velRandomization=velRandomization,gateRandomization=gateRandomization,baseNoteRandomization=baseNoteRandomization,partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,stepResolution=stepResolution,fullScale={},scale=generateScalePart,key=generateKeyPart,minNote=generateMinPart,maxNote=generateMaxPart,monoLimit=monoLimit,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})
end

local sequenceMemoryLabel = sequencerPanel:Label("SequenceMemory")
sequenceMemoryLabel.displayName = "Sequence Memory" -- Used to hold default value
sequenceMemoryLabel.text = sequenceMemoryLabel.displayName
sequenceMemoryLabel.x = 499
sequenceMemoryLabel.y = partRandBox.y + partRandBox.height + 5
sequenceMemoryLabel.width = 200
sequenceMemoryLabel.height = 20

local maxSequencesBox = sequencerPanel:NumBox("MaxSequences", maxSequences, 1, 32, true)
maxSequencesBox.displayName = "Memory"
maxSequencesBox.tooltip = "How many sequences are remebered? Few means less variation, many means more variation."
--maxSequencesBox.displayName = "Rounds Before Repeat"
--maxSequencesBox.tooltip = "How many sequences are generated before we start repeating?"
maxSequencesBox.width = sequenceMemoryLabel.width
maxSequencesBox.height = sequenceMemoryLabel.height
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
--[[ sequencesPerPart.width = (sequenceMemoryLabel.width / 2) - 2
sequencesPerPart.height = 20
sequencesPerPart.x = sequenceMemoryLabel.x
sequencesPerPart.y = sequenceMemoryLabel.y + sequenceMemoryLabel.height + 5 ]]
sequencesPerPart.height = maxSequencesBox.height
sequencesPerPart.width = (maxSequencesBox.width / 2) - 2
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
clearSequences.width = sequenceMemoryLabel.width
clearSequences.height = sequenceMemoryLabel.height

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

function getFilteredScale(part, minNote, maxNote)
  --paramsPerPart[part].filteredScale = {}
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

function hasNoteBelowMonoLimit(notesTable, partPos)
  local monoLimit = paramsPerPart[partPos].monoLimit.value
  for _,v in pairs(notesTable) do
    if v.note < monoLimit then
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
        if #scale > 0 then
          noteToPlay = getNoteAccordingToScale(scale, noteToPlay)
        end
        noteToPlay = transpose(noteToPlay, paramsPerPart[partPos].minNote.value, paramsPerPart[partPos].maxNote.value)
        print("PlaySubdivision partPos/i/noteToPlay/duration/subdivision", partPos, i, noteToPlay, playDuration, note.subdivision)
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

function arpeg()
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentPartPosition = 1 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local sequenceRepeatProbability = nil
  local recordedNotes = {}
  local heldNoteIndex = 0
  local sequencePartIndex = 0 -- The part to play sequences from
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
    else
      sequencePartIndex = 1
    end
    print("currentPosition", currentPosition)
    -- Set part position
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        -- Set start of part
        startOfPart = true
        -- Store the recorded notes before changing parts
        if #recordedNotes > 0 then

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

          -- Increment sequence counter
          if #storedSequences >= maxSequences then
            sequenceCounter = sequenceCounter + 1
            print("Increment sequenceCounter", sequenceCounter)
            if sequenceCounter > maxSequences then
              sequenceCounter = 1
              print("Reset sequenceCounter", sequenceCounter)
            end
          end

          table.remove(sequences, currentPartPosition)
          table.insert(sequences, currentPartPosition, storedSequences)

          if sequenceCounter > 0 then
            sequenceMemoryLabel.text = sequenceMemoryLabel.displayName .. " (Recalling memory " .. sequenceCounter .. ")"
          end

          --print("SAVE SEQUENCE notes/sequences/currentPartPosition", #recordedNotes, #sequences[sequencePartIndex], currentPartPosition)
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
    local numberOfNotes = polyphony -- Default is "mono"
    local mainBeatDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local maxDepth = getMaxDepthFromBeatDuration(mainBeatDuration, currentPartPosition)

    if partWasChanged then
      print("currentPartPosition after/partWasChanged", currentPartPosition, partWasChanged)
      print("currentPosition after", currentPosition)
      sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
      if sequencesPerPart.value == true then
        sequencePartIndex = currentPartPosition
      end
      if type(sequences[sequencePartIndex]) == "table" then
        if sequencesPerPart.value == true then
          sequenceCounter = 1
          print("Sequence counter reset due to part change", sequenceCounter)
        else
          print("No change needed for sequenceCounter", sequenceCounter)
        end
      else
        sequenceCounter = 0
        print("Sequence counter reset due to part change", sequenceCounter)
      end
    end

    if type(sequences[sequencePartIndex]) ~= "table" or #sequences[sequencePartIndex] < maxSequences then
      local seqNum = 1
      if type(sequences[sequencePartIndex]) == "table" then
        seqNum = #sequences[sequencePartIndex] + 1
      end
      sequenceMemoryLabel.text = sequenceMemoryLabel.displayName .. " (Generating sequence " .. (seqNum) .. ")"
    end

    local sequenceRepeatProbabilityDecay = paramsPerPart[currentPartPosition].sequenceRepeatProbabilityDecay.value
    if type(sequenceRepeatProbability) ~= "number" then
      sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
    end

    if startOfPart and isStarting == false and sequenceRepeatProbability > 0 then
      -- Calculate decay
      local sequenceRepeatProbabilityThreshold = paramsPerPart[currentPartPosition].sequenceRepeatProbabilityThreshold.value
      local changeMax = getChangeMax(sequenceRepeatProbability, sequenceRepeatProbabilityDecay)
      local decay = math.ceil(changeMax / maxSequences)
      print("Before decay/changeMax/sequenceRepeatProbability/sequenceRepeatProbabilityDecay", decay, changeMax, sequenceRepeatProbability, sequenceRepeatProbabilityDecay)
      sequenceRepeatProbability = sequenceRepeatProbability - decay -- Decay
      print("After decay sequenceRepeatProbability", sequenceRepeatProbability)
      if sequenceRepeatProbability < sequenceRepeatProbabilityThreshold or sequenceRepeatProbabilityDecay == 0 then
        sequenceRepeatProbability = paramsPerPart[currentPartPosition].sequenceRepeatProbability.value
        print("Reset sequenceRepeatProbability", sequenceRepeatProbability)
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

    -- Tables for current step position
    --local seqVelTable = paramsPerPart[currentPartPosition].seqVelTable
    --local seqGateTable = paramsPerPart[currentPartPosition].seqGateTable

    -- Params for current step position
    local startStep = partToStepMap[currentPartPosition]
    local tablePos = currentPosition - startStep + 1
    --local vel = getVelocity(currentPartPosition, tablePos)--seqVelTable:getValue(tablePos) -- get velocity
    --local gate = getGate(currentPartPosition, tablePos)--seqGateTable:getValue(tablePos) -- get gate

    --------------------------------------------------------------------------------
    -- Note functions
    --------------------------------------------------------------------------------

    -- Note generator function
    local function getNoteToPlay()
      --print("getNoteToPlay sequenceRepeatProbability", sequenceRepeatProbability)
      local minNote = paramsPerPart[currentPartPosition].minNote.value
      local maxNote = paramsPerPart[currentPartPosition].maxNote.value
      local partSequences = sequences[sequencePartIndex]
      if type(partSequences) == "table" and #partSequences >= maxSequences and getRandomBoolean(sequenceRepeatProbability) then
        local sequence = {}
        if #partSequences > 0 and getRandomBoolean(sequenceRepeatProbability) then
          -- Select sequence by counter - check counter is valid!
          if sequenceCounter > #partSequences then
            sequenceCounter = #partSequences
          elseif sequenceCounter == 0 then
            sequenceCounter = 1
          end
          sequence = partSequences[sequenceCounter]
          print("Getting sequence from sequenceCounter/#partSequences", sequenceCounter, #partSequences)
        else
          local sequenceIndex = getRandom(#partSequences)
          sequence = partSequences[sequenceIndex]
          print("Getting sequence from random sequenceIndex/#sequences@currentPartPosition", sequenceIndex, #partSequences)
        end
        local notesAtCurrentStep = {}
        print("Finding note at tablePos", tablePos)
        for _,v in ipairs(sequence) do
          if v.step == tablePos and notesInclude(notes, v.note) == false and v.note >= minNote and v.note <= maxNote then
            table.insert(notesAtCurrentStep, v)
          end
        end
        print("Found notes at current step", #notesAtCurrentStep)
        if #notesAtCurrentStep > 0 then
          --local note = notesAtCurrentStep[getRandom(#notesAtCurrentStep)]
          local note = notesAtCurrentStep[1]
          print("SEQUENCE note/noteSteps/sequenceCounter/sequenceRepeatProbability", note.note, note.steps, sequenceCounter, sequenceRepeatProbability)
          --note.vel = vel -- Adjust to current vel
          --note.gate = gate -- Adjust to current gate
          --note.stepDuration = stepDuration -- Adjust to current step duration
          --return note
          --local stepDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
          local subDivNotes = {}
          for _,v in ipairs(note.notes) do
            table.insert(subDivNotes, v)
          end
          return {note=note.note,step=tablePos,steps=note.steps,stepDuration=mainBeatDuration,notes=subDivNotes,subdivision=note.subdivision,stepCounter=0}
        end
      end

      local function getSubdivision(currentDepth)
        local subdivisionProbability = paramsPerPart[currentPartPosition].subdivisionProbability.value
        -- Calculate depth decay
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

      -- Generate note
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
        local hasScale = #paramsPerPart[currentPartPosition].fullScale > 0
        local minResolution = getResolution(paramsPerPart[currentPartPosition].subdivisionMinResolution.value)
        local steps = getRandom(minNoteSteps, maxNoteSteps)
        local note = 0

        if currentDepth == 0 then
          if hasNoteBelowMonoLimit(notes, currentPartPosition) == true then
            -- Ensure we only have one note below the mono limit
            minNote = monoLimit
          else
            -- Ensure we have a note within the mono limit if polyphony > 1 (TODO Param?)
            if polyphony > 1 and monoLimit > minNote then
              maxNote = monoLimit
            end
          end

          -- Adjust steps so note does not last beyond the part length
          local maxSteps = (paramsPerPart[currentPartPosition].numStepsBox.value - tablePos) + 1
          if steps > maxSteps then
            print("maxSteps/steps", maxSteps, steps)
            steps = maxSteps
          end
        end

        -- When we are not on the top level, always play just one step.
        -- Variation in length are handled by subdivsions at the lower levels.
        if currentDepth > 0 then
          steps = 1
        end

        if currentStep == 1 and currentDepth == 0 and notesInclude(notes, minNote) == false and getRandomBoolean(baseNoteRandomization) then
          note = minNote -- Use the base note
        elseif hasScale == true then
          local scale = getFilteredScale(currentPartPosition, minNote, maxNote)
          note = scale[getRandom(#scale)] -- Use a note from the current scale
        else
          note = getRandom(minNote, maxNote) -- Get random note
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

        print("Generated note: note, gate, vel steps, stepDuration, subdivision, currentDepth", note, gate, vel, steps, stepDuration, subdivision, currentDepth)

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
    
      return generateNote()
    end

    --------------------------------------------------------------------------------
    -- Play this step - If gate is set to zero, no notes will play on this step
    --------------------------------------------------------------------------------
    if getGate(currentPartPosition, tablePos, true) > 0 then
      -- Check how many notes are already playing, and remove number from numberOfNotes if more than max polyphony
      if numberOfNotes + #notes > polyphony then
        numberOfNotes = numberOfNotes - #notes
      end

      -- Add notes to play
      local noteCounter = 0
      local roundCounter = 0
      local maxRounds = numberOfNotes * 2
      local monoLimit = paramsPerPart[currentPartPosition].monoLimit.value
      while noteCounter < numberOfNotes and roundCounter < maxRounds do
        local noteToPlay = getNoteToPlay()
        if notesInclude(notes, noteToPlay.note) == false and (hasNoteBelowMonoLimit(notes, currentPartPosition) and noteToPlay.note < monoLimit) == false then
          table.insert(notes, noteToPlay)
          print("Insert note", noteToPlay.note)
          noteCounter = noteCounter + 1
        end
        roundCounter = roundCounter + 1
        print("Increment roundCounter while searching for notes", roundCounter)
      end
      print("Notes ready to play", #notes)
    end

    -- PLAY NOTE(S)
    for _,note in ipairs(notes) do
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 then
        run(playSubdivision, note, currentPartPosition)
        table.insert(recordedNotes, note)
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

  return {numStepsData, seqVelTableData, seqGateTableData, sequences}
end

function onLoad(data)
  local numStepsData = data[1]
  local seqVelTableData = data[2]
  local seqGateTableData = data[3]
  sequences = data[4]

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
