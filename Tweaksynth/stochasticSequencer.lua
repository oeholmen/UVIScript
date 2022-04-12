--------------------------------------------------------------------------------
-- Stochastic Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "00000000"
local arpId = 0
local partToStepMap = {1} -- Holds the starting step for each part
local totalNumSteps = 8
local numParts = 1
local heldNotes = {}
local paramsPerPart = {}
local partSelect = {}

setBackgroundColour("#3f3f3f")

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
  return getRandom(100) <= probability
end

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value / 3
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

function getResolutionNames(options)
  local res = {}

  for _,r in ipairs(resolutionNames) do
    table.insert(res, r)
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(res, o)
    end
  end

  return res
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local tableWidth = 630
local tableX = 0

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 480

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
    v.partsTable:setValue(1, 0)
  end
end

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = menuTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit part"
editPartMenu.y = 370
editPartMenu.x = 0
editPartMenu.width = 120

local randomizePitchButton = sequencerPanel:Button("RandomizePitch")
randomizePitchButton.persistent = false
randomizePitchButton.visible = false
randomizePitchButton.backgroundColourOff = "#33084486"
randomizePitchButton.backgroundColourOn = "#9902ACFE"
randomizePitchButton.textColourOff = "#cc22FFFF"
randomizePitchButton.textColourOn = "#ccFFFFFF"
randomizePitchButton.displayName = "Randomize"
randomizePitchButton.tooltip = "Randomize Pitch - NOTE: Changes all pitch settings!"
randomizePitchButton.fillColour = "#dd000061"
randomizePitchButton.size = {60,20}
randomizePitchButton.x = 640
randomizePitchButton.y = 47
randomizePitchButton.changed = function()
  for i=1,paramsPerPart[editPartMenu.value].numStepsBox.value do
    paramsPerPart[editPartMenu.value].seqPitchTable:setValue(i, getRandom(paramsPerPart[editPartMenu.value].seqPitchTable.min, paramsPerPart[editPartMenu.value].seqPitchTable.max))
  end
end

local clearPitchButton = sequencerPanel:Button("ClearPitch")
clearPitchButton.persistent = false
clearPitchButton.visible = false
clearPitchButton.backgroundColourOff = "#33084486"
clearPitchButton.backgroundColourOn = "#9902ACFE"
clearPitchButton.textColourOff = "#cc22FFFF"
clearPitchButton.textColourOn = "#ccFFFFFF"
clearPitchButton.displayName = "Clear"
clearPitchButton.tooltip = "Clear Pitch - NOTE: Resets all pitch settings!"
clearPitchButton.fillColour = "#dd000061"
clearPitchButton.size = {60,20}
clearPitchButton.x = 640
clearPitchButton.y = randomizePitchButton.y + randomizePitchButton.height + 3
clearPitchButton.changed = function()
  for i=1,paramsPerPart[editPartMenu.value].numStepsBox.value do
    paramsPerPart[editPartMenu.value].seqPitchTable:setValue(i, 0)
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
focusButton.size = {75,30}
focusButton.x = 450
focusButton.y = editPartMenu.y + 15
focusButton.changed = function(self)
  randomizePitchButton.visible = self.value
  clearPitchButton.visible = self.value
  setTableWidths()
end

local evolveButton = sequencerPanel:OnOffButton("EvolveOnOff", false)
evolveButton.backgroundColourOff = "#ff084486"
evolveButton.backgroundColourOn = "#ff02ACFE"
evolveButton.textColourOff = "#ff22FFFF"
evolveButton.textColourOn = "#efFFFFFF"
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "When evolve is active, randomization is written back to the corresponding table, allowing the table to evolve with the changes"
evolveButton.fillColour = "#dd000061"
evolveButton.size = focusButton.size
evolveButton.x = focusButton.x + focusButton.width + 10
evolveButton.y = editPartMenu.y + 15

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = evolveButton.size
holdButton.x = evolveButton.x + evolveButton.width + 10
holdButton.y = editPartMenu.y + 15
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
    arpId = arpId + 1
  end
end

editPartMenu.changed = function(self)
  print("editPartMenu.changed")
  for i,v in ipairs(paramsPerPart) do
    local isVisible = self.value == i

    if isVisible then
      v.partsTable.backgroundColour = "#cc33cc44"
    elseif i % 2 == 0 then
      v.partsTable.backgroundColour = "#3f09A3F4"
    else
      v.partsTable.backgroundColour = "#1f09A3F4"
    end  

    v.partResolution.visible = isVisible
    v.numStepsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.playMode.visible = isVisible
    v.playProbability.visible = isVisible
    v.repeatProbability.visible = isVisible
    v.directionProbability.visible = isVisible
    v.tieRandKnob.visible = isVisible
    v.pitchProbRandKnob.visible = isVisible
    v.velRandKnob.visible = isVisible
    v.gateRandKnob.visible = isVisible
  end
  setTableWidths()
end

local numPartsBox = sequencerPanel:NumBox("Parts", numParts, 1, 8, true)
numPartsBox.tooltip = "The Number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.arrowColour = menuArrowColour
numPartsBox.outlineColour = menuOutlineColour
numPartsBox.size = {90,20}
numPartsBox.x = editPartMenu.x + editPartMenu.width + 20
numPartsBox.y = editPartMenu.y + 24
numPartsBox.changed = function(self)
  print("numPartsBox.changed numParts/self.value", numParts, self.value)
  for i,v in ipairs(paramsPerPart) do
    v.partsTable.visible = false
    v.positionTable.visible = false
    v.seqPitchTable.visible = false
    v.tieStepTable.visible = false
    v.seqPitchChangeProbabilityTable.visible = false
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
      paramsPerPart[i].partResolution.value = prev.partResolution.value
      paramsPerPart[i].stepResolution.value = prev.stepResolution.value
      paramsPerPart[i].numStepsBox.value = prev.numStepsBox.value
      paramsPerPart[i].playMode.value = prev.playMode.value
      paramsPerPart[i].tieRandKnob.value = prev.tieRandKnob.value
      paramsPerPart[i].pitchProbRandKnob.value = prev.pitchProbRandKnob.value
      paramsPerPart[i].velRandKnob.value = prev.velRandKnob.value
      paramsPerPart[i].gateRandKnob.value = prev.gateRandKnob.value
      paramsPerPart[i].init = prev.init
    end
  end
  clearPosition()
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)
end

local partRandKnob = sequencerPanel:Knob("PartRandomization", 0, 0, 100, true)
partRandKnob.displayName = "Part Order Randomization"
partRandKnob.tooltip = "Amount of radomization applied to the playing order of parts"
partRandKnob.unit = Unit.Percent
partRandKnob.height = 40
partRandKnob.width = 200
partRandKnob.x = numPartsBox.x + numPartsBox.width + 20
partRandKnob.y = editPartMenu.y + 10
partRandKnob.changed = function(self)
  partRandomizationAmount = self.value
end

function setNumSteps(index)
  print("setNumSteps", index)
  local numSteps = paramsPerPart[index].numStepsBox.value
  -- If follow step is selected, we use the value from numStepsBox
  if paramsPerPart[index].partResolution.value > #resolutions then
    paramsPerPart[index].numStepsBox.enabled = true
  else
    local partDuration = getResolution(paramsPerPart[index].partResolution.value)
    local stepDuration = getResolution(paramsPerPart[index].stepResolution.value)
    numSteps = partDuration / stepDuration
    paramsPerPart[index].numStepsBox.enabled = false

    -- Set value in numsteps box
    if numSteps > paramsPerPart[index].numStepsBox.max then
      paramsPerPart[index].numStepsBox:setRange(1, numSteps)
    end
    paramsPerPart[index].numStepsBox:setValue(numSteps, false)
  end

  partToStepMap = {} -- Reset
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

    paramsPerPart[i].seqPitchTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqPitchTable.visible = isVisible
    paramsPerPart[i].seqPitchTable.width = partTableWidth
    paramsPerPart[i].seqPitchTable.x = x

    paramsPerPart[i].tieStepTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].tieStepTable.visible = isVisible
    paramsPerPart[i].tieStepTable.width = partTableWidth
    paramsPerPart[i].tieStepTable.x = x

    paramsPerPart[i].seqPitchChangeProbabilityTable.length = paramsPerPart[i].numStepsBox.value
    paramsPerPart[i].seqPitchChangeProbabilityTable.visible = isVisible
    paramsPerPart[i].seqPitchChangeProbabilityTable.width = partTableWidth
    paramsPerPart[i].seqPitchChangeProbabilityTable.x = x

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
  print("Set paramsPerPart", i)
  local isFirst = i == 1

  local partsTable = sequencerPanel:Table("Parts" .. i, 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  if i % 2 == 0 then
    partsTable.backgroundColour = "#3f09A3F4"
  else
    partsTable.backgroundColour = "#1f09A3F4"
  end
  partsTable.sliderColour = "#5FB5FF"
  partsTable.width = tableWidth
  partsTable.height = 10
  partsTable.x = tableX
  partsTable.y = 0

  local positionTable = sequencerPanel:Table("Position" .. i, totalNumSteps, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  if i % 2 == 0 then
    positionTable.backgroundColour = "#9f02ACFE"
  else
    positionTable.backgroundColour = "#6f02ACFE"
  end
  positionTable.sliderColour = outlineColour
  positionTable.width = tableWidth
  positionTable.height = partsTable.height
  positionTable.x = tableX
  positionTable.y = partsTable.y + partsTable.height

  local seqPitchTable = sequencerPanel:Table("Pitch" .. i, totalNumSteps, 0, -24, 24, true)
  seqPitchTable.displayName = "Pitch"
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.showLabel = true
  seqPitchTable.fillStyle = "solid"
  seqPitchTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqPitchTable.backgroundColour = "#3f000000"
  else
    seqPitchTable.backgroundColour = "#6f000000"
  end
  seqPitchTable.width = tableWidth
  seqPitchTable.height = 120
  seqPitchTable.x = tableX
  seqPitchTable.y = 20
  
  local tieStepTable = sequencerPanel:Table("TieStep" .. i, totalNumSteps, 0, 0, 1, true)
  tieStepTable.tooltip = "Tie with next step"
  tieStepTable.fillStyle = "solid"
  --tieStepTable.backgroundColour = "black"
  if i % 2 == 0 then
    tieStepTable.backgroundColour = "#99000000"
  else
    tieStepTable.backgroundColour = "#ff000000"
  end
  tieStepTable.showLabel = false
  tieStepTable.sliderColour = menuTextColour
  tieStepTable.width = tableWidth
  tieStepTable.height = 8
  tieStepTable.x = tableX
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2
  
  local seqPitchChangeProbabilityTable = sequencerPanel:Table("PitchChangeProbability" .. i, totalNumSteps, 0, 0, 100, true)
  seqPitchChangeProbabilityTable.displayName = "Change Probability"
  seqPitchChangeProbabilityTable.tooltip = "Set the probability that the pitch from another step will be used"
  seqPitchChangeProbabilityTable.showPopupDisplay = true
  seqPitchChangeProbabilityTable.showLabel = true
  seqPitchChangeProbabilityTable.fillStyle = "solid"
  seqPitchChangeProbabilityTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqPitchChangeProbabilityTable.backgroundColour = "#3f000000"
  else
    seqPitchChangeProbabilityTable.backgroundColour = "#6f000000"
  end
  seqPitchChangeProbabilityTable.width = tableWidth
  seqPitchChangeProbabilityTable.height = 68
  seqPitchChangeProbabilityTable.x = tableX
  seqPitchChangeProbabilityTable.y = tieStepTable.y + tieStepTable.height + 2
  
  local seqVelTable = sequencerPanel:Table("Velocity" .. i, totalNumSteps, 100, 1, 127, true)
  seqVelTable.displayName = "Velocity"
  seqVelTable.tooltip = "Set step velocity"
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqVelTable.backgroundColour = "#3f000000"
  else
    seqVelTable.backgroundColour = "#6f000000"
  end
  seqVelTable.width = tableWidth
  seqVelTable.height = seqPitchChangeProbabilityTable.height
  seqVelTable.x = tableX
  seqVelTable.y = seqPitchChangeProbabilityTable.y + seqPitchChangeProbabilityTable.height + 2
  
  local seqGateTable = sequencerPanel:Table("Gate" .. i, totalNumSteps, 100, 0, 120, true)
  seqGateTable.displayName = "Gate"
  seqGateTable.tooltip = "Set step gate length"
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqGateTable.backgroundColour = "#3f000000"
  else
    seqGateTable.backgroundColour = "#6f000000"
  end
  seqGateTable.width = seqVelTable.width
  seqGateTable.height = seqVelTable.height
  seqGateTable.x = tableX
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 2

  local tieRandKnob = sequencerPanel:Knob("TieRandomization" .. i, 0, 0, 100, true)
  tieRandKnob.visible = isFirst
  tieRandKnob.displayName = "Rand"
  tieRandKnob.tooltip = "Amount of radomization applied to ties for selected part"
  tieRandKnob.unit = Unit.Percent
  tieRandKnob.height = 30
  tieRandKnob.width = 70
  tieRandKnob.x = tableWidth + 5
  tieRandKnob.y = 130
  
  local pitchProbRandKnob = sequencerPanel:Knob("PitchProbabilityRandomization" .. i, 0, 0, 100, true)
  pitchProbRandKnob.visible = isFirst
  pitchProbRandKnob.displayName = "Rand"
  pitchProbRandKnob.tooltip = "Amount of radomization applied to pitch change probability for selected part"
  pitchProbRandKnob.unit = Unit.Percent
  pitchProbRandKnob.height = 30
  pitchProbRandKnob.width = 70
  pitchProbRandKnob.x = tableWidth + 5
  pitchProbRandKnob.y = tieRandKnob.y + tieRandKnob.height + 25
  
  local velRandKnob = sequencerPanel:Knob("VelocityRandomization" .. i, 0, 0, 100, true)
  velRandKnob.visible = isFirst
  velRandKnob.displayName = "Rand"
  velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity for selected part"
  velRandKnob.unit = Unit.Percent
  velRandKnob.height = 30
  velRandKnob.width = 70
  velRandKnob.x = tableWidth + 5
  velRandKnob.y = pitchProbRandKnob.y + pitchProbRandKnob.height + 45
  
  local gateRandKnob = sequencerPanel:Knob("GateRandomization" .. i, 0, 0, 100, true)
  gateRandKnob.visible = isFirst
  gateRandKnob.displayName = "Rand"
  gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate for selected part"
  gateRandKnob.unit = Unit.Percent
  gateRandKnob.height = 30
  gateRandKnob.width = 70
  gateRandKnob.x = tableWidth + 5
  gateRandKnob.y = velRandKnob.y + velRandKnob.height + 35

  local partResolution = sequencerPanel:Menu("PartDuration" .. i, getResolutionNames({"Follow Step"}))
  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())

  partResolution.displayName = "Part Duration"
  partResolution.tooltip = "Set the duration of a part."
  partResolution.selected = #resolutions + 1
  partResolution.visible = isFirst
  partResolution.x = 0
  partResolution.y = editPartMenu.y + editPartMenu.height + 10
  partResolution.width = 80
  partResolution.backgroundColour = menuBackgroundColour
  partResolution.textColour = menuTextColour
  partResolution.arrowColour = menuArrowColour
  partResolution.outlineColour = menuOutlineColour
  partResolution.changed = function(self)
    print("partResolution.changed", i)
    setNumSteps(i)
  end
  
  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, totalNumSteps, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.visible = isFirst
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.width = 70
  numStepsBox.x = partResolution.x + partResolution.width + 10
  numStepsBox.y = partResolution.y + 25
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  stepResolution.displayName = "Step Resolution"
  stepResolution.selected = 20
  stepResolution.visible = isFirst
  stepResolution.x = numStepsBox.x + numStepsBox.width + 10
  stepResolution.y = partResolution.y
  stepResolution.width = 90
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    print("stepResolution.changed", i)
    setNumSteps(i)
  end

  local playMode = sequencerPanel:Menu("PlayMode" .. i, {"Mono", "As Played", "Random", "Duo", "Chord", "Mono 2 (First Held)"})
  playMode.displayName = "Play Mode"
  playMode.visible = isFirst
  playMode.x = stepResolution.x + stepResolution.width + 10
  playMode.y = stepResolution.y
  playMode.width = 90
  playMode.backgroundColour = menuBackgroundColour
  playMode.textColour = menuTextColour
  playMode.arrowColour = menuArrowColour
  playMode.outlineColour = menuOutlineColour

  local playProbabilityKnob = sequencerPanel:Knob("PartPlayProbabilityKnob" .. i, 100, 0, 100, true)
  playProbabilityKnob.displayName = "Play"
  playProbabilityKnob.tooltip = "Set the probability that the part will be played when randomizing part order."
  playProbabilityKnob.visible = isFirst
  playProbabilityKnob.unit = Unit.Percent
  playProbabilityKnob.x = playMode.x + playMode.width + 15
  playProbabilityKnob.y = playMode.y + 8
  playProbabilityKnob.height = 40
  playProbabilityKnob.width = 100

  local repeatProbabilityKnob = sequencerPanel:Knob("PartRepeatProbabilityKnob" .. i, 50, 0, 100, true)
  repeatProbabilityKnob.displayName = "Repeat"
  repeatProbabilityKnob.tooltip = "Set the probability of that the part will be repeated when randomizing part order. When set to 0, the part is never repeated."
  repeatProbabilityKnob.visible = isFirst
  repeatProbabilityKnob.unit = Unit.Percent
  repeatProbabilityKnob.x = playProbabilityKnob.x + playProbabilityKnob.width + 10
  repeatProbabilityKnob.y = playProbabilityKnob.y
  repeatProbabilityKnob.height = playProbabilityKnob.height
  repeatProbabilityKnob.width = playProbabilityKnob.width

  local directionProbabilityKnob = sequencerPanel:Knob("PartDirectionProbabilityKnob" .. i, 0, 0, 100, true)
  directionProbabilityKnob.displayName = "Backward"
  directionProbabilityKnob.tooltip = "Set the probability that the part will play backwards"
  directionProbabilityKnob.visible = isFirst
  directionProbabilityKnob.unit = Unit.Percent
  directionProbabilityKnob.x = repeatProbabilityKnob.x + repeatProbabilityKnob.width + 10
  directionProbabilityKnob.y = repeatProbabilityKnob.y
  directionProbabilityKnob.height = repeatProbabilityKnob.height
  directionProbabilityKnob.width = playProbabilityKnob.width

  table.insert(paramsPerPart, {tieRandKnob=tieRandKnob,pitchProbRandKnob=pitchProbRandKnob,velRandKnob=velRandKnob,gateRandKnob=gateRandKnob,partsTable=partsTable,positionTable=positionTable,seqPitchTable=seqPitchTable,tieStepTable=tieStepTable,seqPitchChangeProbabilityTable=seqPitchChangeProbabilityTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,partResolution=partResolution,stepResolution=stepResolution,playMode=playMode,playProbability=playProbabilityKnob,directionProbability=directionProbabilityKnob,repeatProbability=repeatProbabilityKnob,numStepsBox=numStepsBox,init=i==1})
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(arpId_)
  local index = 0
  local heldNoteIndex = 0 -- Counter for held notes (used by As Played seq mode)
  local currentPartPosition = 0 -- Holds the currently playing part
  local randomTieCounter = 0 -- Used for holding random ties
  local partRepeat = 0 -- Used for holding part repeat info
  local partDirectionBackward = false -- Used for holding part direction
  -- START ARP LOOP
  while arpId_ == arpId do
    -- Reset notes table
    local notes = {} -- Holds the note(s) that plays at this position
    -- Set current position and part position
    local currentPosition = (index % totalNumSteps) + 1 -- 11 % 4 = 3
    local startOfPart = false
    for pp,sp in ipairs(partToStepMap) do
      if sp == currentPosition then
        currentPartPosition = pp
        --print("Set currentPartPosition", currentPartPosition)
        startOfPart = true
        break
      end
    end

    -- If we are at the start of a part (and there is more than one part), check for part order randomization (or an active repeat)
    if startOfPart and numParts > 1 and (getRandomBoolean(partRandomizationAmount) or partRepeat > 0 or focusButton.value == true) then
      if focusButton.value == true then
        currentPartPosition = editPartMenu.value
      elseif partRepeat > 0 then
        currentPartPosition = partRepeat
        partRepeat = 0 -- Reset repeat  
      else
        -- Randomize parts within the set limit
        print("currentPartPosition before", currentPartPosition)
        -- Suggest a part by random
        local suggestedPartPosition = getRandom(numParts)
        -- Check play probability
        if getRandomBoolean(paramsPerPart[suggestedPartPosition].playProbability.value) then
          currentPartPosition = suggestedPartPosition
          print("playProbability was used", playProbability)
        end
        -- Check if part should be repeated next time
        if getRandomBoolean(paramsPerPart[currentPartPosition].repeatProbability.value) then
          partRepeat = currentPartPosition
          print("Part is set for repeating", partRepeat)
        end
      end
      -- Set the current pos and index from the selected part
      currentPosition = partToStepMap[currentPartPosition]
      index = currentPosition - 1
      print("currentPartPosition after", currentPartPosition)
    end

    if startOfPart then
      -- Set direction for this part
      local directionProbability = paramsPerPart[currentPartPosition].directionProbability.value
      partDirectionBackward = getRandomBoolean(directionProbability)
      print("directionProbability/currentPartPosition/partDirectionBackward", directionProbability, currentPartPosition, partDirectionBackward)
    end

    -- If evolve is true, the randomization is written back to the table
    local evolve = evolveButton.value

    -- Params for current part position
    local stepDuration = getResolution(paramsPerPart[currentPartPosition].stepResolution.value)
    local playMode = paramsPerPart[currentPartPosition].playMode.value
    local numStepsInPart = paramsPerPart[currentPartPosition].numStepsBox.value

    -- Flip position if playing backwards
    local startStep = partToStepMap[currentPartPosition]
    if partDirectionBackward == true then
      local endStep = startStep + numStepsInPart - 1
      local diff = currentPosition - startStep
      currentPosition = endStep - diff
      print("startStep/endStep/diff/currentPosition", startStep, endStep, diff, currentPosition)
    end

    -- Tables for current step position
    local seqVelTable = paramsPerPart[currentPartPosition].seqVelTable
    local seqGateTable = paramsPerPart[currentPartPosition].seqGateTable
    local seqPitchTable = paramsPerPart[currentPartPosition].seqPitchTable
    local seqPitchChangeProbabilityTable = paramsPerPart[currentPartPosition].seqPitchChangeProbabilityTable
    local tieStepTable = paramsPerPart[currentPartPosition].tieStepTable

    -- Params for current step position
    local tablePos = currentPosition - startStep + 1
    local vel = seqVelTable:getValue(tablePos) -- get velocity
    local gate = seqGateTable:getValue(tablePos) -- get gate
    local pitchAdjustment = seqPitchTable:getValue(tablePos) -- get pitch adjustment
    local pitchChangeProbability = seqPitchChangeProbabilityTable:getValue(tablePos) -- get pitch change probability
    local tieNext = tieStepTable:getValue(tablePos)

    -- Randomize gate
    local gateRandomizationAmount = paramsPerPart[currentPartPosition].gateRandKnob.value
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
    local velocityRandomizationAmount = paramsPerPart[currentPartPosition].velRandKnob.value
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

    -- Randomize pitch probaility
    local pitchProbabilityRandomizationAmount = paramsPerPart[currentPartPosition].pitchProbRandKnob.value
    if pitchProbabilityRandomizationAmount > 0 then
      if getRandomBoolean(pitchProbabilityRandomizationAmount) then
        local changeMax = math.ceil(seqPitchChangeProbabilityTable.max * (pitchProbabilityRandomizationAmount/100))
        local min = pitchChangeProbability - changeMax
        local max = pitchChangeProbability + changeMax
        if min < seqPitchChangeProbabilityTable.min then
          min = seqPitchChangeProbabilityTable.min
        end
        if max > seqPitchChangeProbabilityTable.max then
          max = seqPitchChangeProbabilityTable.max
        end
        --print("Before randomize pitchChangeProbability", pitchChangeProbability)
        pitchChangeProbability = getRandom(min, max)
        --print("After randomize pitchChangeProbability/changeMax/min/max", pitchChangeProbability, changeMax, min, max)
        if evolve == true then
          seqPitchChangeProbabilityTable:setValue(currentPosition, pitchChangeProbability)
        end
      end
    end

    -- Randomize ties
    local tieRandomizationAmount = paramsPerPart[currentPartPosition].tieRandKnob.value
    if tieRandomizationAmount > 0 and randomTieCounter == 0 then
      --print("Before randomized tieNext", tieNext)
      if getRandomBoolean(tieRandomizationAmount) then
        tieNext = 1
        randomTieCounter = 2
      else
        tieNext = 0
        randomTieCounter = 0
      end
      --print("After randomize tieNext", tieNext)
      if evolve == true then
        tieStepTable:setValue(currentPosition, tieNext)
      end
    end

    local tieStepPos = currentPosition - 1
    if partDirectionBackward == true then
      tieStepPos = currentPosition + 1
    end

    local shouldAddNote = tieStepTable:getValue(tieStepPos) ~= 1
    if randomTieCounter > 0 then
      shouldAddNote = randomTieCounter == 2
      -- Reset tie counter
      if randomTieCounter == 1 then
        randomTieCounter = 0
        --print("Reset tie")
      end
    end

    -- If gate is zero no notes will play on this step
    if gate > 0 and shouldAddNote then

      -- note: the note to play
      -- gate: gate length
      -- vel: note velocity
      -- steps: the duration of the note in steps

      local noteSteps = 1
      -- Check tie to next step
      if tieNext == 1 then
        if randomTieCounter == 2 then
          noteSteps = randomTieCounter
          randomTieCounter = 1
          --print("Set automatic tie", noteSteps)
        else
          local tmp = currentPosition
          local endStep = startStep + numStepsInPart - 1
          while (tieStepTable:getValue(tmp) == 1 or randomTieCounter == 2) and tmp < endStep and tmp >= startStep do
            noteSteps = noteSteps + 1
            if partDirectionBackward == true then
              tmp = tmp - 1
            else
              tmp = tmp + 1
            end
          end
        end
        --print("Set tie steps currentPosition/noteSteps", currentPosition, noteSteps)
      end

      -- Check for pitch change randomization
      if getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      -- Add notes to play
      -- "Mono", "As Played", "Random", "Duo", "Chord", "Mono (First Held)"
      if playMode == 1 then
        -- Mono (Last held)
          table.insert(notes, {note=heldNotes[#heldNotes].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
      elseif playMode == 2 then
        -- As played
        if partDirectionBackward == true then
          heldNoteIndex = heldNoteIndex - 1 -- Decrement held note position
          if heldNoteIndex < 1 then
            heldNoteIndex = #heldNotes
          end
        else
          heldNoteIndex = heldNoteIndex + 1 -- Increment held note position
          if heldNoteIndex > #heldNotes then
            heldNoteIndex = 1
          end
        end
        if getRandomBoolean(pitchChangeProbability) then
          table.insert(notes, {note=heldNotes[getRandom(#heldNotes)].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
        else
          -- Add a failsafe i case #heldNotes has changed since setting index
          if heldNoteIndex > #heldNotes then
            heldNoteIndex = #heldNotes
          end
          table.insert(notes, {note=heldNotes[heldNoteIndex].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
        end
      elseif playMode == 3 then
        -- Random
        table.insert(notes, {note=heldNotes[getRandom(#heldNotes)].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
      elseif playMode == 4 then
        -- Duo (First and last held note)
        table.insert(notes, {note=heldNotes[1].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
        if #heldNotes > 1 then
          table.insert(notes, {note=heldNotes[#heldNotes].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
        end
      elseif playMode == 5 then
        -- Chord
        for i=1,#heldNotes do
          table.insert(notes, {note=heldNotes[i].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
        end
      else
        -- First held
        table.insert(notes, {note=heldNotes[1].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps})
      end
      print("#notes", #notes)
    end

    -- PLAY NOTE(S)
    for _,note in ipairs(notes) do
      if note.gate > 0 then
        -- Play the note for the number of steps that are set
        local beats = stepDuration * (note.gate / 100) * note.steps
        playNote(note.note, note.vel, beat2ms(beats))
        print("Playing note/stepDuration/note.gate/steps/beats", note.note, stepDuration, note.gate, note.steps, beats)
      end
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

    -- WAIT FOR NEXT BEAT
    waitBeat(stepDuration)
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
        --return
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
    postEvent(e)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local pitchTableData = {}
  local tieStepTableData = {}
  local seqPitchChangeProbabilityTableData = {}
  local seqVelTableData = {}
  local seqGateTableData = {}
  local numStepsData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(pitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(tieStepTableData, paramsPerPart[i].tieStepTable:getValue(j))
      table.insert(seqPitchChangeProbabilityTableData, paramsPerPart[i].seqPitchChangeProbabilityTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, pitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqPitchChangeProbabilityTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)
  table.insert(data, numStepsData)

  return data
end

function onLoad(data)
  local seqPitchTableData = data[1]
  local tieStepTableData = data[2]
  local seqPitchChangeProbabilityTableData = data[3]
  local seqVelTableData = data[4]
  local seqGateTableData = data[5]
  local numStepsData = data[6]

  numPartsBox:setValue(#numStepsData)

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].tieStepTable.length = v
    paramsPerPart[i].seqPitchChangeProbabilityTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].tieStepTable:setValue(j, tieStepTableData[dataCounter])
      paramsPerPart[i].seqPitchChangeProbabilityTable:setValue(j, seqPitchChangeProbabilityTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
