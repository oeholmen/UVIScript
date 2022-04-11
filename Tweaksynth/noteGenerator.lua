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
local totalNumSteps = 0
local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}, {5,2,5}, {7,5}, {12}, {3}, {5}, {7}}
local paramsPerPart = {}
local partSelect = {}
local heldNotes = {}
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

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 330

local partsTable = sequencerPanel:Table("Parts", 1, 0, 0, 1, true)
partsTable.enabled = false
partsTable.persistent = false
partsTable.fillStyle = "solid"
partsTable.backgroundColour = "#1f09A3F4"
partsTable.sliderColour = "#5FB5FF"
partsTable.width = 700
partsTable.height = 10
partsTable.x = 0
partsTable.y = 0

local positionTable = sequencerPanel:Table("Position", 1, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = menuTextColour
positionTable.sliderColour = outlineColour
positionTable.width = partsTable.width
positionTable.height = partsTable.height
positionTable.x = partsTable.x
positionTable.y = partsTable.y + partsTable.height

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = menuTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit part"
editPartMenu.showLabel = false
editPartMenu.y = positionTable.y + positionTable.height + 10
editPartMenu.x = 0
editPartMenu.width = 190
editPartMenu.height = 20
editPartMenu.changed = function(self)
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i
    v.polyphony.visible = isVisible
    v.partResolution.visible = isVisible
    v.stepResolution.visible = isVisible
    v.minNoteSteps.visible = isVisible
    v.maxNoteSteps.visible = isVisible
    v.minNote.visible = isVisible
    v.maxNote.visible = isVisible
    v.key.visible = isVisible
    v.scale.visible = isVisible
    v.droneLow.visible = isVisible
    v.droneHigh.visible = isVisible
  end
end

local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
numPartsBox.tooltip = "The Number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.arrowColour = menuArrowColour
numPartsBox.outlineColour = menuOutlineColour
numPartsBox.size = {80,30}
numPartsBox.x = 490
numPartsBox.y = 290
numPartsBox.changed = function(self)
  for i=1, self.value do
    setNumSteps(i)
  end

  local partSelect = {}
  for i=1,self.value do
    -- Add item to part select table
    table.insert(partSelect, "Part " .. i)
    if paramsPerPart[i].init == false then
      -- Copy initial settings from prev part
      local prev = paramsPerPart[i-1]
      paramsPerPart[i].polyphony.value = prev.polyphony.value
      paramsPerPart[i].scale.value = prev.scale.value
      paramsPerPart[i].key.value = prev.key.value
      paramsPerPart[i].droneLow.value = prev.droneLow.value
      paramsPerPart[i].droneHigh.value = prev.droneHigh.value
      paramsPerPart[i].minNote.value = prev.minNote.value
      paramsPerPart[i].maxNote.value = prev.maxNote.value
      paramsPerPart[i].minNoteSteps.value = prev.minNoteSteps.value
      paramsPerPart[i].maxNoteSteps.value = prev.maxNoteSteps.value
      paramsPerPart[i].partResolution.value = prev.partResolution.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].numSteps = prev.numSteps
      paramsPerPart[i].fullScale = prev.fullScale
      paramsPerPart[i].filteredScale = prev.filteredScale
      paramsPerPart[i].init = prev.init
    end
  end
  editPartMenu.items = partSelect

  clearPosition()
end

local evolveButton = sequencerPanel:OnOffButton("EvolveOnOff", false)
evolveButton.backgroundColourOff = "#ff084486"
evolveButton.backgroundColourOn = "#ff02ACFE"
evolveButton.textColourOff = "#ff22FFFF"
evolveButton.textColourOn = "#efFFFFFF"
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "When evolve is active, randomization is written back to the corresponding table, allowing the table to evolve with the changes"
evolveButton.fillColour = "#dd000061"
evolveButton.size = {60,30}
evolveButton.x = numPartsBox.x + numPartsBox.width + 10
evolveButton.y = numPartsBox.y

function clearPosition()
  for i=1, totalNumSteps do
    positionTable:setValue(i, 0)
  end
  for i=1, totalNumSteps do
    partsTable:setValue(i, 0)
  end
end

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {50,30}
holdButton.x = evolveButton.x + evolveButton.width + 10
holdButton.y = evolveButton.y
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
    arpId = arpId + 1
  end
end

local seqVelTable = sequencerPanel:Table("Velocity", 1, 100, 1, 127, true)
seqVelTable.tooltip = "Set step velocity. Randomization available in settings."
seqVelTable.showPopupDisplay = true
seqVelTable.showLabel = true
seqVelTable.fillStyle = "solid"
seqVelTable.sliderColour = menuArrowColour
seqVelTable.width = positionTable.width
seqVelTable.height = 70
seqVelTable.x = positionTable.x
seqVelTable.y = 130

local seqGateTable = sequencerPanel:Table("Gate", 1, 100, 0, 120, true)
seqGateTable.tooltip = "Set step gate length. Randomization available in settings."
seqGateTable.showPopupDisplay = true
seqGateTable.showLabel = true
seqGateTable.fillStyle = "solid"
seqGateTable.sliderColour = menuArrowColour
seqGateTable.width = seqVelTable.width
seqGateTable.height = 70
seqGateTable.x = seqVelTable.x
seqGateTable.y = seqVelTable.y + seqVelTable.height + 5

local velRandKnob = sequencerPanel:Knob("VelocityRandomization", 0, 0, 100, true)
velRandKnob.displayName = "Velocity"
velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity"
velRandKnob.unit = Unit.Percent
velRandKnob.width = 100
velRandKnob.x = 0
velRandKnob.y = seqGateTable.y + seqGateTable.height + 5
velRandKnob.changed = function(self)
  velocityRandomizationAmount = self.value
end

local gateRandKnob = sequencerPanel:Knob("GateRandomization", 0, 0, 100, true)
gateRandKnob.displayName = "Gate"
gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate"
gateRandKnob.unit = Unit.Percent
gateRandKnob.width = 100
gateRandKnob.x = velRandKnob.x + velRandKnob.width + 25
gateRandKnob.y = seqGateTable.y + seqGateTable.height + 5
gateRandKnob.changed = function(self)
  gateRandomizationAmount = self.value
end

local partRandKnob = sequencerPanel:Knob("PartRandomization", 0, 0, 100, true)
partRandKnob.displayName = "Part"
partRandKnob.tooltip = "Amount of radomization applied to parts"
partRandKnob.unit = Unit.Percent
partRandKnob.width = 90
partRandKnob.x = gateRandKnob.x + gateRandKnob.width + 25
partRandKnob.y = seqGateTable.y + seqGateTable.height + 5
partRandKnob.changed = function(self)
  partRandomizationAmount = self.value
end

local baseNoteRandKnob = sequencerPanel:Knob("BaseNoteProbability", 0, 0, 100, true)
baseNoteRandKnob.displayName = "Base note"
baseNoteRandKnob.tooltip = "Probability that first note in part will be the base note"
baseNoteRandKnob.unit = Unit.Percent
baseNoteRandKnob.width = 110
baseNoteRandKnob.x = partRandKnob.x + partRandKnob.width + 25
baseNoteRandKnob.y = seqGateTable.y + seqGateTable.height + 5
baseNoteRandKnob.changed = function(self)
  baseNoteProbability = self.value
end

function setNumSteps(index)
  local partDuration = getResolution(paramsPerPart[index].partResolution.value)
  local stepDuration = getResolution(paramsPerPart[index].stepResolution.value)
  local numSteps = partDuration / stepDuration
  paramsPerPart[index].numSteps = numSteps
  --print("part/stepDuration/partDuration/numSteps", index, stepDuration, partDuration, numSteps)
  partToStepMap = {} -- Reset
  totalNumSteps = 0
  for i=1, numPartsBox.value do
    table.insert(partToStepMap, (totalNumSteps + 1))
    --print("Updated partToStepMap part/step/numSteps", i, (totalNumSteps + 1), paramsPerPart[i].numSteps)
    totalNumSteps = totalNumSteps + paramsPerPart[i].numSteps
  end
  seqVelTable.length = totalNumSteps
  seqGateTable.length = totalNumSteps
  positionTable.length = totalNumSteps
  partsTable.length = totalNumSteps
  clearPosition()
end

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  local generatePolyphonyPart = sequencerPanel:NumBox("GeneratePolyphony" .. i, 1, 0, 16, true)
  generatePolyphonyPart.displayName = "Polyphony"
  generatePolyphonyPart.tooltip = "How many notes are played at once"
  generatePolyphonyPart.backgroundColour = menuBackgroundColour
  generatePolyphonyPart.textColour = menuTextColour
  generatePolyphonyPart.arrowColour = menuArrowColour
  generatePolyphonyPart.outlineColour = menuOutlineColour
  generatePolyphonyPart.visible = false
  generatePolyphonyPart.width = editPartMenu.width
  generatePolyphonyPart.x = editPartMenu.x
  generatePolyphonyPart.y = editPartMenu.y + editPartMenu.height + 5

  local generateMinNoteStepsPart = sequencerPanel:NumBox("GenerateMinNoteSteps" .. i, 1, 1, 1, true)
  generateMinNoteStepsPart.displayName = "Min Steps"
  generateMinNoteStepsPart.tooltip = "The minimum number of steps can a note last"
  generateMinNoteStepsPart.backgroundColour = menuBackgroundColour
  generateMinNoteStepsPart.textColour = menuTextColour
  generateMinNoteStepsPart.arrowColour = menuArrowColour
  generateMinNoteStepsPart.outlineColour = menuOutlineColour
  generateMinNoteStepsPart.visible = false
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
  generateMaxNoteStepsPart.visible = false
  generateMaxNoteStepsPart.width = generateMinNoteStepsPart.width
  generateMaxNoteStepsPart.x = generateMinNoteStepsPart.x
  generateMaxNoteStepsPart.y = generateMinNoteStepsPart.y + generateMinNoteStepsPart.height + 5
  generateMaxNoteStepsPart.changed = function(self)
    generateMinNoteStepsPart:setRange(1, self.value)
    generateMinNoteStepsPart.enabled = self.value > 1
  end

  local generateKeyPart = sequencerPanel:Menu("GenerateKey" .. i, notenames)
  generateKeyPart.displayName = "Key"
  generateKeyPart.visible = false
  generateKeyPart.width = 150
  generateKeyPart.x = 200
  generateKeyPart.y = positionTable.y + positionTable.height + 10
  generateKeyPart.backgroundColour = menuBackgroundColour
  generateKeyPart.textColour = menuTextColour
  generateKeyPart.arrowColour = menuArrowColour
  generateKeyPart.outlineColour = menuOutlineColour
  generateKeyPart.changed = function (self)
    createFullScale(i)
    createFilteredScale(i)
  end

  local droneLowPart = sequencerPanel:Menu("DroneLow" .. i, {"No drone", "Lowest note", "Lowest root", "Lowest held", "Random held"})
  droneLowPart.showLabel = false
  droneLowPart.backgroundColour = menuBackgroundColour
  droneLowPart.textColour = menuTextColour
  droneLowPart.arrowColour = menuArrowColour
  droneLowPart.outlineColour = menuOutlineColour
  droneLowPart.tooltip = "Set a low drone"
  droneLowPart.visible = false
  droneLowPart.x = generateKeyPart.x
  droneLowPart.y = generateKeyPart.y + generateKeyPart.height + 5
  droneLowPart.width = generateKeyPart.width
  droneLowPart.height = 20

  local droneHighPart = sequencerPanel:Menu("DroneHigh" .. i, {"No drone", "Highest note", "Highest root", "Highest held"})
  droneHighPart.showLabel = false
  droneHighPart.backgroundColour = menuBackgroundColour
  droneHighPart.textColour = menuTextColour
  droneHighPart.arrowColour = menuArrowColour
  droneHighPart.outlineColour = menuOutlineColour
  droneHighPart.tooltip = "Set a high drone"
  droneHighPart.visible = false
  droneHighPart.x = droneLowPart.x
  droneHighPart.y = droneLowPart.y + droneLowPart.height + 5
  droneHighPart.width = droneLowPart.width
  droneHighPart.height = droneLowPart.height

  local generateScalePart = sequencerPanel:Menu("GenerateScale" .. i, {"12 tone", "Major", "Minor", "Dorian", "Whole tone", "Major Pentatonic", "Minor Pentatonic", "1-4-5", "1-5", "1", "Dim", "Fours", "Fives"})
  generateScalePart.displayName = "Scale"
  generateScalePart.visible = false
  generateScalePart.width = 185
  generateScalePart.x = 360
  generateScalePart.y = positionTable.y + positionTable.height + 10
  generateScalePart.backgroundColour = menuBackgroundColour
  generateScalePart.textColour = menuTextColour
  generateScalePart.arrowColour = menuArrowColour
  generateScalePart.outlineColour = menuOutlineColour
  generateScalePart.changed = function (self)
    createFullScale(i)
    createFilteredScale(i)
  end

  local partResolution = sequencerPanel:Menu("PartDuration" .. i, resolutionNames)
  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutionNames)

  partResolution.displayName = "Part Duration"
  partResolution.tooltip = "Set the duration of a part."
  partResolution.selected = 9
  partResolution.visible = false
  partResolution.x = generateScalePart.x + generateScalePart.width + 10
  partResolution.y = generateScalePart.y
  partResolution.width = 140
  partResolution.backgroundColour = menuBackgroundColour
  partResolution.textColour = menuTextColour
  partResolution.arrowColour = menuArrowColour
  partResolution.outlineColour = menuOutlineColour
  partResolution.changed = function(self)
    setNumSteps(i)
  end

  stepResolution.displayName = "Step Resolution"
  stepResolution.selected = 20
  stepResolution.visible = false
  stepResolution.x = partResolution.x
  stepResolution.y = partResolution.y + partResolution.height + 5
  stepResolution.width = partResolution.width
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    setNumSteps(i)
  end

  local generateMinPart = sequencerPanel:NumBox("GenerateMin" .. i, 24, 0, 127, true)
  generateMinPart.unit = Unit.MidiKey
  generateMinPart.showPopupDisplay = true
  generateMinPart.showLabel = true
  generateMinPart.fillStyle = "solid"
  generateMinPart.sliderColour = menuArrowColour
  generateMinPart.displayName = "Lowest note"
  generateMinPart.visible = false
  generateMinPart.x = generateScalePart.x
  generateMinPart.y = generateScalePart.y + generateScalePart.height + 5
  generateMinPart.width = generateScalePart.width

  local generateMaxPart = sequencerPanel:NumBox("GenerateMax" .. i, 84, 0, 127, true)
  generateMaxPart.unit = Unit.MidiKey
  generateMaxPart.showPopupDisplay = true
  generateMaxPart.showLabel = true
  generateMaxPart.fillStyle = "solid"
  generateMaxPart.sliderColour = menuArrowColour
  generateMaxPart.displayName = "Highest note"
  generateMaxPart.visible = false
  generateMaxPart.x = generateMinPart.x
  generateMaxPart.y = generateMinPart.y + generateMinPart.height + 5
  generateMaxPart.width = generateMinPart.width

  generateMinPart.changed = function(self)
    createFilteredScale(i)
    generateMaxPart:setRange(self.value+1, 127)
  end

  generateMaxPart.changed = function(self)
    createFilteredScale(i)
    generateMinPart:setRange(0, self.value-1)
  end

  table.insert(paramsPerPart, {polyphony=generatePolyphonyPart,partResolution=partResolution,stepResolution=stepResolution,numSteps=0,fullScale={},filteredScale={},scale=generateScalePart,key=generateKeyPart,droneLow=droneLowPart,droneHigh=droneHighPart,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,init=i==1})

  stepResolution:changed()
end

numPartsBox:changed()
editPartMenu:changed()

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

    -- If evolve is true, the randomization is written back to the table
    local evolve = evolveButton.value

    -- Params for current step position
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local gate = seqGateTable:getValue(currentPosition) -- get gate

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
          seqGateTable:setValue(currentPosition, gate)
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
          seqVelTable:setValue(currentPosition, vel)
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
      local isLowDroneActive = paramsPerPart[currentPartPosition].droneLow.visible and paramsPerPart[currentPartPosition].droneLow.value > 1
      if currentStep == 1 and isLowDroneActive == false and notesInclude(notes, minNote) == false and getRandomBoolean(baseNoteProbability) then
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
      table.sort(notes, function(a,b) return a.note < b.note end) -- TODO Parameter for this?
      print("Notes ready to play", #notes)
    end

    -- PLAY DRONE(S) ON START OF PART HOLDING ALL PART
    local isLowDroneActive = paramsPerPart[currentPartPosition].droneLow.visible and paramsPerPart[currentPartPosition].droneLow.value > 1
    local isHighDroneActive = paramsPerPart[currentPartPosition].droneHigh.visible and paramsPerPart[currentPartPosition].droneHigh.value > 1
    if startOfPart and (isLowDroneActive or isHighDroneActive) then
      -- 2 = lowest, 3 = lowest in scale, 4 = lowest held
      local droneDuration = beat2ms(getResolution(paramsPerPart[currentPartPosition].partResolution.value))
      local minNote = paramsPerPart[currentPartPosition].minNote.value
      local maxNote = paramsPerPart[currentPartPosition].maxNote.value
    
      -- PLAY LOW DRONE ---
      -- Options: {"Off", "Lowest note", "Lowest root", "Lowest held", "Random held"}
      local droneNoteLow = minNote -- default lowest
      if isLowDroneActive then
        if paramsPerPart[currentPartPosition].droneLow.value == 3 then
          -- Get lowest root note in scale
          while(isRootNote(droneNoteLow, currentPartPosition) == false and droneNoteLow <= maxNote)
          do
            droneNoteLow = droneNoteLow + 1 -- increment note
          end
        elseif paramsPerPart[currentPartPosition].droneLow.value == 4 then
          -- Get the lowest held note
          if #heldNotes > 0 then
            droneNoteLow = heldNotes[1].note
          end
        elseif paramsPerPart[currentPartPosition].droneLow.value == 5 then
          -- Random - get a random note from held notes
          if #heldNotes > 0 then
            droneNoteLow = heldNotes[getRandom(#heldNotes)].note
          end
        end
        print("Playing low drone", droneNoteLow, droneDuration)
        playNote(droneNoteLow, vel, droneDuration)
      end

      -- PLAY HIGH DRONE ---
      local droneNoteHigh = maxNote -- default highest
      if isHighDroneActive then
        if paramsPerPart[currentPartPosition].droneHigh.value == 3 then
          -- Get highest root note in scale
          while(isRootNote(droneNoteHigh, currentPartPosition) == false and droneNoteHigh >= minNote)
          do
            droneNoteHigh = droneNoteHigh - 1 -- decrement note
          end
        elseif paramsPerPart[currentPartPosition].droneHigh.value == 4 then
          -- Get the highest held note
          droneNoteHigh = heldNotes[#heldNotes].note
        end
        if droneNoteHigh ~= droneNoteLow then
          print("Playing high drone", droneNoteHigh, droneDuration)
          playNote(droneNoteHigh, vel, droneDuration)
        end
      end
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

    -- UPDATE STEP POSITION TABLE
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
    end

    -- WAIT FOR NEXT BEAT
    waitBeat(stepDuration)

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
        return
      end
    end
  end
  table.insert(heldNotes, e)
  if #heldNotes == 1 then
    arpeg(arpId)
  end
end

function onRelease(e)
  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
        if #heldNotes == 0 then
          clearPosition()
          arpId = arpId + 1
        end
      end
    end
  end
  postEvent(e)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local data = {}
  local seqVelTableData = {}
  local seqGateTableData = {}

  for i=1,totalNumSteps do
    table.insert(seqVelTableData, seqVelTable:getValue(i))
    table.insert(seqGateTableData, seqGateTable:getValue(i))
  end

  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)

  return data
end

function onLoad(data)
  local seqVelTableData = data[1]
  local seqGateTableData = data[2]

  totalNumSteps = #seqVelTableData

  seqVelTable.length = totalNumSteps
  seqGateTable.length = totalNumSteps

  for i=1,totalNumSteps do
    seqVelTable:setValue(i, seqVelTableData[i])
    seqGateTable:setValue(i, seqGateTableData[i])
  end
end
