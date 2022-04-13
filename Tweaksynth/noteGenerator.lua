--------------------------------------------------------------------------------
-- GENEREATIVE SEQUENCER
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "00000000"
local arpId = 0
local partToStepMap = {1} -- Holds the starting step for each part
local velocityRandomizationAmount = 0
local gateRandomizationAmount = 0
local partRandomizationAmount = 0
local baseNoteProbability = 0
local totalNumSteps = 8
local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}, {5,2,5}, {7,5}, {12}, {3}, {5}, {7}}
local paramsPerPart = {}
local partSelect = {}
local heldNotes = {}
local isPlaying = false
local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
local noteNumberToNoteName = {} -- Used for mapping - does not include octave, only name of note (C, C#...)
local notenamePos = 1
for i=0,127 do
  local name = notenames[notenamePos] .. (math.floor(i/12)-2) .. " (" .. i .. ")"
  table.insert(noteNumberToNoteName, notenames[notenamePos])
  notenamePos = notenamePos + 1
  if notenamePos > #notenames then
    notenamePos = 1
  end
end

setBackgroundColour("#5f5f5f")

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    --print("Random - value, min, max:", value, min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
    --print("Random - value, min:", value, min)
    return value
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  local value = getRandom(100) <= probability
  return value
end

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value  / 3
end

local resolutions = {
  128, -- "32x" -- 0
  64, -- "16x" -- 1
  32, -- "8x" -- 2
  28, -- "7x" -- 3
  24, -- "6x" -- 4
  20, -- "5x" -- 5
  16, -- "4x" -- 6
  12, -- "3x" -- 7
  8, -- "2x" -- 8
  6, -- "1/1 dot" -- 9
  4, -- "1/1" -- 10
  3, -- "1/2 dot" -- 11
  getTriplet(8), -- "1/1 tri" -- 12
  2, -- "1/2" -- 13
  getDotted(1), -- "1/4 dot", -- 14
  getTriplet(4), -- "1/2 tri", -- 15
  1, -- "1/4", -- 16
  getDotted(0.5), -- "1/8 dot", -- 17
  getTriplet(2), -- "1/4 tri", -- 18
  0.5,  -- "1/8", -- 19
  getDotted(0.25), -- "1/16 dot", -- 20
  getTriplet(1), -- "1/8 tri", -- 21
  0.25, -- "1/16", -- 22
  getDotted(0.125), -- "1/32 dot", -- 23
  getTriplet(0.5), -- "1/16 tri", -- 24
  0.125, -- "1/32" -- 25
  getDotted(0.0625), -- "1/64 dot", -- 26
  getTriplet(0.25), -- "1/32 tri", -- 27
  0.0625, -- "1/64", -- 28
  getTriplet(0.125) -- "1/64 tri" -- 29
}
local resolutionNames = {
  "32x", -- 0
  "16x", -- 1
  "8x", -- 2
  "7x", -- 3
  "6x", -- 4
  "5x", -- 5
  "4x", -- 6
  "3x", -- 7
  "2x", -- 8
  "1/1 dot", -- 9
  "1/1", -- 10
  "1/2 dot", -- 11
  "1/1 tri", -- 12 NY
  "1/2", -- 13
  "1/4 dot", -- 14
  "1/2 tri", -- 15
  "1/4", -- 16
  "1/8 dot", -- 17
  "1/4 tri", -- 18
  "1/8", -- 19
  "1/16 dot", -- 20
  "1/8 tri", -- 21
  "1/16", -- 22
  "1/32 dot", -- 23
  "1/16 tri", -- 24
  "1/32", -- 25
  "1/64 dot", -- 26
  "1/32 tri", -- 27
  "1/64", -- 28
  "1/64 tri" -- 29
}

function getResolution(i)
  return resolutions[i]
end

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
    v.partsTable:setValue(1, 0)
  end
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
sequencerPanel.height = 340

local label = sequencerPanel:Label("label")
label.text = "Generative Sequencer"
--label.align = "centred"
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
editPartMenu.showLabel = true
editPartMenu.y = 65
editPartMenu.x = 0
editPartMenu.width = 132
editPartMenu.changed = function(self)
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i
    v.polyphony.visible = isVisible
    v.numStepsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.minNoteSteps.visible = isVisible
    v.maxNoteSteps.visible = isVisible
    v.minNote.visible = isVisible
    v.maxNote.visible = isVisible
    v.key.visible = isVisible
    v.scale.visible = isVisible
  end
  setTableWidths()
end

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.arrowColour = menuArrowColour
numPartsBox.outlineColour = menuOutlineColour
numPartsBox.width = editPartMenu.width
numPartsBox.height = 20
numPartsBox.x = editPartMenu.x
numPartsBox.y = editPartMenu.y + editPartMenu.height + 5
numPartsBox.changed = function(self)
  print("numPartsBox.changed numParts/self.value", numParts, self.value)
  for i,v in ipairs(paramsPerPart) do
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
      paramsPerPart[i].init = prev.init
    end
  end
  clearPosition()
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)
end

local velRandKnob = sequencerPanel:Knob("VelocityRandomization", 0, 0, 100, true)
velRandKnob.displayName = "Velocity"
velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity"
velRandKnob.unit = Unit.Percent
velRandKnob.width = 100
velRandKnob.x = 0
velRandKnob.y = sequencerPanel.height - 48
velRandKnob.changed = function(self)
  velocityRandomizationAmount = self.value
end

local gateRandKnob = sequencerPanel:Knob("GateRandomization", 0, 0, 100, true)
gateRandKnob.displayName = "Gate"
gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate"
gateRandKnob.unit = Unit.Percent
gateRandKnob.width = velRandKnob.width
gateRandKnob.x = velRandKnob.x + velRandKnob.width + 10
gateRandKnob.y = velRandKnob.y
gateRandKnob.changed = function(self)
  gateRandomizationAmount = self.value
end

local partRandKnob = sequencerPanel:Knob("PartRandomization", 0, 0, 100, true)
partRandKnob.displayName = "Part"
partRandKnob.tooltip = "Amount of radomization applied to parts"
partRandKnob.unit = Unit.Percent
partRandKnob.width = velRandKnob.width
partRandKnob.x = gateRandKnob.x + gateRandKnob.width + 10
partRandKnob.y = velRandKnob.y
partRandKnob.changed = function(self)
  partRandomizationAmount = self.value
end

local baseNoteRandKnob = sequencerPanel:Knob("BaseNoteProbability", 0, 0, 100, true)
baseNoteRandKnob.displayName = "Base note"
baseNoteRandKnob.tooltip = "Probability that first note in part will be the base note"
baseNoteRandKnob.unit = Unit.Percent
baseNoteRandKnob.width = velRandKnob.width
baseNoteRandKnob.x = partRandKnob.x + partRandKnob.width + 10
baseNoteRandKnob.y = velRandKnob.y
baseNoteRandKnob.changed = function(self)
  baseNoteProbability = self.value
end

local outputMenu = sequencerPanel:Menu("OutputMenu", {"Random", "Low->High", "High->Low"})
outputMenu.backgroundColour = menuBackgroundColour
outputMenu.textColour = menuTextColour
outputMenu.arrowColour = menuArrowColour
outputMenu.outlineColour = menuOutlineColour
outputMenu.displayName = "Output Order"
outputMenu.tooltip = "The order for outputted notes (when polyphony > 1)"
outputMenu.x = baseNoteRandKnob.x + baseNoteRandKnob.width + 10
outputMenu.y = baseNoteRandKnob.y
outputMenu.width = 80
outputMenu.height = 45

local evolveButton = sequencerPanel:OnOffButton("EvolveOnOff", false)
evolveButton.backgroundColourOff = "#ff084486"
evolveButton.backgroundColourOn = "#ff02ACFE"
evolveButton.textColourOff = "#ff22FFFF"
evolveButton.textColourOn = "#efFFFFFF"
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "When evolve is active, randomization is written back to the corresponding table, allowing the table to evolve with the changes"
evolveButton.fillColour = "#dd000061"
evolveButton.size = {80,35}
evolveButton.x = outputMenu.x + outputMenu.width + 10
evolveButton.y = outputMenu.y + 10

--[[ local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = evolveButton.size
holdButton.x = evolveButton.x + evolveButton.width + 10
holdButton.y = evolveButton.y
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
    arpId = arpId + 1
  end
end ]]

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.fillColour = "#dd000061"
playButton.displayName = "Play"
playButton.size = evolveButton.size
playButton.x = evolveButton.x + evolveButton.width + 10
playButton.y = evolveButton.y
playButton.changed = function(self)
  if self.value then
    spawn(arpeg, arpId)
  else
    arpId = arpId + 1
    clearPosition()
  end
end

function setNumSteps(index)
  print("setNumSteps", index)
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
  local widthPerStep = tableWidth / totalNumSteps
  local x = 0
  for i=1, numPartsBox.value do
    local isVisible = true
    local partTableWidth = paramsPerPart[i].numStepsBox.value * widthPerStep

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
  seqVelTable.y = numPartsBox.y + numPartsBox.height + 5
  
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
  generatePolyphonyPart.arrowColour = menuArrowColour
  generatePolyphonyPart.outlineColour = menuOutlineColour
  generatePolyphonyPart.visible = false
  generatePolyphonyPart.width = editPartMenu.width
  generatePolyphonyPart.x = editPartMenu.x + editPartMenu.width + 10
  generatePolyphonyPart.y = editPartMenu.y

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, 1, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps can a note last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = menuTextColour
  generateMinNoteStepsPart.arrowColour = menuArrowColour
  generateMinNoteStepsPart.outlineColour = menuOutlineColour
  generateMinNoteStepsPart.enabled = false
  generateMinNoteStepsPart.width = generatePolyphonyPart.width
  generateMinNoteStepsPart.x = generatePolyphonyPart.x
  generateMinNoteStepsPart.y = generatePolyphonyPart.y + generatePolyphonyPart.height + 5

  local generateMaxNoteStepsPart = sequencerPanel:NumBox("GenerateMaxNoteSteps" .. i, 1, 1, 16, true)
  generateMaxNoteStepsPart.displayName = "Max Steps"
  generateMaxNoteStepsPart.tooltip = "The maximium number of steps can a note last"
  generateMaxNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMaxNoteStepsPart.textColour = menuTextColour
  generateMaxNoteStepsPart.arrowColour = menuArrowColour
  generateMaxNoteStepsPart.outlineColour = menuOutlineColour
  generateMaxNoteStepsPart.width = generateMinNoteStepsPart.width
  generateMaxNoteStepsPart.x = generateMinNoteStepsPart.x
  generateMaxNoteStepsPart.y = generateMinNoteStepsPart.y + generateMinNoteStepsPart.height + 5
  generateMaxNoteStepsPart.changed = function(self)
    generateMinNoteStepsPart:setRange(1, self.value)
    generateMinNoteStepsPart.enabled = self.value > 1
  end

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutionNames)
  stepResolution.displayName = "Step Resolution"
  stepResolution.selected = 20
  --stepResolution.showLabel = false
  stepResolution.x = generatePolyphonyPart.x + generatePolyphonyPart.width + 10
  stepResolution.y = generatePolyphonyPart.y
  stepResolution.width = generateMaxNoteStepsPart.width
  --stepResolution.height = numStepsBox.height
  stepResolution.backgroundColour = menuBackgroundColour
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
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.width = stepResolution.width
  numStepsBox.x = stepResolution.x
  numStepsBox.y = stepResolution.y + stepResolution.height + 5
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  local noteRangeLabel = sequencerPanel:Label("NoteRangeLabel")
  noteRangeLabel.text = "Note Range"
  noteRangeLabel.visible = i == 1
  noteRangeLabel.x = stepResolution.x + stepResolution.width + 10
  noteRangeLabel.y = stepResolution.y
  noteRangeLabel.width = stepResolution.width
  noteRangeLabel.height = 20

  local generateMinPart = sequencerPanel:NumBox("GenerateMin" .. i, 24, 0, 127, true)
  generateMinPart.unit = Unit.MidiKey
  generateMinPart.showPopupDisplay = true
  generateMinPart.showLabel = true
  generateMinPart.fillStyle = "solid"
  generateMinPart.sliderColour = menuArrowColour
  generateMinPart.displayName = "Min"
  generateMinPart.tooltip = "Lowest note"
  generateMinPart.x = noteRangeLabel.x
  generateMinPart.y = noteRangeLabel.y + noteRangeLabel.height + 5
  generateMinPart.width = stepResolution.width

  local generateMaxPart = sequencerPanel:NumBox("GenerateMax" .. i, 84, 0, 127, true)
  generateMaxPart.unit = Unit.MidiKey
  generateMaxPart.showPopupDisplay = true
  generateMaxPart.showLabel = true
  generateMaxPart.fillStyle = "solid"
  generateMaxPart.sliderColour = menuArrowColour
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

  table.insert(paramsPerPart, {partsTable=partsTable,positionTable=positionTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,polyphony=generatePolyphonyPart,numStepsBox=numStepsBox,stepResolution=stepResolution,numSteps=0,fullScale={},filteredScale={},scale=generateScalePart,key=generateKeyPart,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})
end

editPartMenu:changed()
numPartsBox:changed()

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
  print("Filtered scale contains notes:", #paramsPerPart[part].filteredScale)
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
  print("Full scale contains notes:", #paramsPerPart[part].fullScale)
end

function isRootNote(note, currentPartPosition)
  -- Find root note index
  local rootIndex = paramsPerPart[currentPartPosition].key.value
  local noteIndex = note + 1 -- note index is 1 higher than note number
  print("Check isRootNote", rootIndex-1, note, noteNumberToNoteName[rootIndex], noteNumberToNoteName[noteIndex])
  return noteNumberToNoteName[rootIndex] == noteNumberToNoteName[noteIndex]
end

function notesInclude(notesTable, note)
  for _,v in pairs(notesTable) do
    if v.note == note then
      print("Note already included", note)
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(arpId_)
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentPartPosition = 0 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local heldNoteIndex = 0
  -- START ARP LOOP
  while arpId_ == arpId do
    -- SET VALUES
    local numParts = numPartsBox.value
    local currentPosition = (index % totalNumSteps) + 1 -- 11 % 4 = 3
    --print("currentPosition", currentPosition)
    -- Set part position
    local startOfPart = false
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        currentPartPosition = pp
        --print("Set currentPartPosition", currentPartPosition)
        startOfPart = true
        break
      end
    end

    -- Increment step counter
    currentStep = currentStep + 1
    if currentStep > totalNumSteps then
      currentStep = 1
    end

    -- Check if we are at the start of a part
    if startOfPart and partRandomizationAmount > 0 then
      -- Randomize parts within the set limit
      print("currentPartPosition before", currentPartPosition)
      print("currentPosition before", currentPosition)
      print("index before", index)
      currentPartPosition = getRandom(numParts)
      -- Find the current pos and index
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
      print("currentPartPosition after", currentPartPosition)
      print("currentPosition after", currentPosition)
      print("index after", index)
    end

    local stepDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local numStepsInPart = paramsPerPart[currentPartPosition].numSteps
    local startStep = partToStepMap[currentPartPosition]

    -- If evolve is true, the randomization is written back to the table
    local evolve = evolveButton.value

    -- Tables for current step position
    local seqVelTable = paramsPerPart[currentPartPosition].seqVelTable
    local seqGateTable = paramsPerPart[currentPartPosition].seqGateTable

    -- Params for current step position
    local tablePos = currentPosition - startStep + 1
    local vel = seqVelTable:getValue(tablePos) -- get velocity
    local gate = seqGateTable:getValue(tablePos) -- get gate

    -- Randomize gate
    if gateRandomizationAmount > 0 then
      if getRandomBoolean(gateRandomizationAmount) then
        local changeMax = math.ceil(seqGateTable.max * (gateRandomizationAmount/100)) -- 110 * 0,15 = 16,5 = 17
        local min = gate - changeMax -- 100 - 17 = 83
        local max = gate + changeMax -- 100 + 17 = 117 = 110
        if min < seqGateTable.min then
          min = seqGateTable.min
        end
        if max > seqGateTable.max then
          max = seqGateTable.max
        end
        --print("Before randomize gate", gate)
        gate = getRandom(min, max)
        --print("After randomize gate/changeMax/min/max", gate, changeMax, min, max)
        if evolve == true then
          seqGateTable:setValue(tablePos, gate)
        end
      end
    end

    -- Randomize vel
    if velocityRandomizationAmount > 0 then
      if getRandomBoolean(velocityRandomizationAmount) then
        local changeMax = math.ceil(seqVelTable.max * (velocityRandomizationAmount/100))
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
        if evolve == true then
          seqVelTable:setValue(tablePos, vel)
        end
      end
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
      if currentStep == 1 and notesInclude(notes, minNote) == false and getRandomBoolean(baseNoteProbability) then
        local noteSteps = getRandom(minNoteSteps,maxNoteSteps)
        table.insert(notes, {note=minNote,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
        print("Insert base note note/steps/vel/gate", minNote, noteSteps, vel, gate)
      end

      -- Check how many notes are already playing, and remove number from numberOfNotes if more than max polyphony
      if numberOfNotes + #notes > polyphony then
        numberOfNotes = numberOfNotes - #notes
      end

      -- Note generate function
      function generateNoteToPlay(currentPartPosition)
        if #paramsPerPart[currentPartPosition].filteredScale > 0 then
          local pos = getRandom(#paramsPerPart[currentPartPosition].filteredScale)
          return paramsPerPart[currentPartPosition].filteredScale[pos]
        end
        return getRandom(minNote, maxNote)
      end      

      -- Add notes to play
      local noteCounter = 0
      local roundCounter = 0
      local maxRounds = numberOfNotes * 2
      while noteCounter < numberOfNotes and roundCounter < maxRounds do
        local noteToPlay = generateNoteToPlay(currentPartPosition)
        if notesInclude(notes, noteToPlay) == false then
          local noteSteps = getRandom(minNoteSteps, maxNoteSteps)
          table.insert(notes, {note=noteToPlay,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
          print("Insert to notes note/steps/vel/gate", noteToPlay, noteSteps, vel, gate)
          noteCounter = noteCounter + 1
        end
        roundCounter = roundCounter + 1
      end
      -- Check if notes should be sorted before playing
      if outputMenu.value == 2 then
        -- Low -> High
        table.sort(notes, function(a,b) return a.note < b.note end)
      elseif outputMenu.value == 3 then
        -- High -> Low
        table.sort(notes, function(a,b) return a.note > b.note end)
      end
      print("Notes ready to play", #notes)
    end

    -- PLAY NOTE(S)
    --print("Ready to play notes", #notes)
    for _,note in ipairs(notes) do
      --print("Check note/stepCounter", note.note, note.stepCounter)
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 and note.gate > 0 then
        -- Play the note for the number of steps that are set
        local beats = stepDuration * (note.gate/100) * note.steps
        playNote(note.note, note.vel, beat2ms(beats))
        print("Playing note/stepDuration/note.gate/steps/beats", note.note, stepDuration, note.gate, note.steps, beats)
      end
      -- Increment step counter
      note.stepCounter = note.stepCounter + 1
      --print("Increment note step counter", note.stepCounter)
    end

    --[[ -- UPDATE STEP POSITION TABLE
    for i=1, totalNumSteps do
      local val = 0
      if i == currentPosition then
        val = 1
      end
      positionTable:setValue(i, val)
    end
    -- UPDATE PART POSITION TABLE
    if startOfPart then
      local startStep = partToStepMap[currentPartPosition]
      local endStep = startStep + numStepsInPart
      for i=1, totalNumSteps do
        local val = 0
        if i >= startStep and i < endStep then
          val = 1
        end
        partsTable:setValue(i, val)
      end
    end ]]

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

function onTransport(start)
  playButton:setValue(start)
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
