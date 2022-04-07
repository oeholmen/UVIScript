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
local velocityRandomizationAmount = 0
local gateRandomizationAmount = 0
local partRandomizationAmount = 0
local tieRandomizationAmount = 0
local pitchProbabilityRandomizationAmount = 0
local totalNumSteps = 8
local numParts = 1
local heldNotes = {}
local paramsPerPart = {}
local partSelect = {}

setBackgroundColour("#4f4f4f")

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

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 480

local partsTable = sequencerPanel:Table("Parts", totalNumSteps, 0, 0, 1, true)
partsTable.enabled = false
partsTable.persistent = false
partsTable.fillStyle = "solid"
partsTable.backgroundColour = "#1f09A3F4"
partsTable.sliderColour = "#5FB5FF"
partsTable.width = 630
partsTable.height = 10
partsTable.x = 0
partsTable.y = 0

local positionTable = sequencerPanel:Table("Position", totalNumSteps, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false
positionTable.fillStyle = "solid"
positionTable.backgroundColour = menuTextColour
positionTable.sliderColour = outlineColour
positionTable.width = partsTable.width
positionTable.height = partsTable.height
positionTable.x = partsTable.x
positionTable.y = partsTable.y + partsTable.height

local seqPitchTable = sequencerPanel:Table("Pitch", totalNumSteps, 0, -24, 24, true)
seqPitchTable.showPopupDisplay = true
seqPitchTable.showLabel = true
seqPitchTable.fillStyle = "solid"
seqPitchTable.sliderColour = menuArrowColour
seqPitchTable.width = positionTable.width
seqPitchTable.height = 120
seqPitchTable.x = positionTable.x
seqPitchTable.y = positionTable.y + positionTable.height + 2
--seqPitchTable.changed = function(self, index)
--end

local tieStepTable = sequencerPanel:Table("TieStep", totalNumSteps, 0, 0, 1, true)
tieStepTable.tooltip = "Tie with next step"
tieStepTable.fillStyle = "solid"
tieStepTable.backgroundColour = "black"
tieStepTable.showLabel = false
tieStepTable.sliderColour = menuTextColour
tieStepTable.width = positionTable.width
tieStepTable.height = 8
tieStepTable.x = seqPitchTable.x
tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2

local seqPitchChangeProbabilityTable = sequencerPanel:Table("PitchChangeProbability", totalNumSteps, 0, 0, 100, true)
seqPitchChangeProbabilityTable.displayName = "Change Probability"
seqPitchChangeProbabilityTable.tooltip = "Set the probability that the pitch from another step will be used"
seqPitchChangeProbabilityTable.showPopupDisplay = true
seqPitchChangeProbabilityTable.showLabel = true
seqPitchChangeProbabilityTable.fillStyle = "solid"
seqPitchChangeProbabilityTable.sliderColour = menuArrowColour
seqPitchChangeProbabilityTable.width = tieStepTable.width
seqPitchChangeProbabilityTable.height = 68
seqPitchChangeProbabilityTable.x = tieStepTable.x
seqPitchChangeProbabilityTable.y = tieStepTable.y + tieStepTable.height + 2

local seqVelTable = sequencerPanel:Table("Velocity", totalNumSteps, 100, 1, 127, true)
seqVelTable.tooltip = "Set step velocity"
seqVelTable.showPopupDisplay = true
seqVelTable.showLabel = true
seqVelTable.fillStyle = "solid"
seqVelTable.sliderColour = menuArrowColour
seqVelTable.width = positionTable.width
seqVelTable.height = seqPitchChangeProbabilityTable.height
seqVelTable.x = positionTable.x
seqVelTable.y = seqPitchChangeProbabilityTable.y + seqPitchChangeProbabilityTable.height + 2

local seqGateTable = sequencerPanel:Table("Gate", totalNumSteps, 100, 0, 110, true)
seqGateTable.tooltip = "Set step gate length"
seqGateTable.showPopupDisplay = true
seqGateTable.showLabel = true
seqGateTable.fillStyle = "solid"
seqGateTable.sliderColour = menuArrowColour
seqGateTable.width = seqVelTable.width
seqGateTable.height = seqVelTable.height
seqGateTable.x = seqVelTable.x
seqGateTable.y = seqVelTable.y + seqVelTable.height + 2

function clearPosition()
  for i=1, totalNumSteps do
    positionTable:setValue(i, 0)
  end
  for i=1, totalNumSteps do
    partsTable:setValue(i, 0)
  end
end

local editPartMenu = sequencerPanel:Menu("EditPart", partSelect)
editPartMenu.backgroundColour = menuBackgroundColour
editPartMenu.textColour = menuTextColour
editPartMenu.arrowColour = menuArrowColour
editPartMenu.outlineColour = menuOutlineColour
editPartMenu.displayName = "Edit part"
editPartMenu.y = seqGateTable.y + seqGateTable.height + 5
editPartMenu.x = 0
editPartMenu.width = 120

local randomizePitchButton = sequencerPanel:Button("RandomizePitch")
randomizePitchButton.persistent = false
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
  for i=1,totalNumSteps do
    seqPitchTable:setValue(i, getRandom(seqPitchTable.min, seqPitchTable.max))
  end
end

local clearPitchButton = sequencerPanel:Button("ClearPitch")
clearPitchButton.persistent = false
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
  for i=1,totalNumSteps do
    seqPitchTable:setValue(i, 0)
  end
end

local evolveButton = sequencerPanel:OnOffButton("EvolveOnOff", false)
evolveButton.backgroundColourOff = "#ff084486"
evolveButton.backgroundColourOn = "#ff02ACFE"
evolveButton.textColourOff = "#ff22FFFF"
evolveButton.textColourOn = "#efFFFFFF"
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "When evolve is active, randomization is written back to the corresponding table, allowing the table to evolve with the changes"
evolveButton.fillColour = "#dd000061"
evolveButton.size = {85,30}
evolveButton.x = 450
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
    v.partResolution.visible = isVisible
    v.numStepsBox.visible = isVisible
    v.stepResolution.visible = isVisible
    v.playMode.visible = isVisible
    v.playProbability.visible = isVisible
    v.repeatProbability.visible = isVisible
    v.directionProbability.visible = isVisible
  end
end

local tieRandKnob = sequencerPanel:Knob("TieRandomization", 0, 0, 100, true)
tieRandKnob.displayName = "Rand"
tieRandKnob.tooltip = "Amount of radomization applied to ties"
tieRandKnob.unit = Unit.Percent
tieRandKnob.height = 30
tieRandKnob.width = 70
tieRandKnob.x = tieStepTable.x + tieStepTable.width + 5
tieRandKnob.y = tieStepTable.y - 10
tieRandKnob.changed = function(self)
  tieRandomizationAmount = self.value
end

local pitchProbRandKnob = sequencerPanel:Knob("PitchProbabilityRandomization", 0, 0, 100, true)
pitchProbRandKnob.displayName = "Rand"
pitchProbRandKnob.tooltip = "Amount of radomization applied to pitch change probability"
pitchProbRandKnob.unit = Unit.Percent
pitchProbRandKnob.height = 30
pitchProbRandKnob.width = 70
pitchProbRandKnob.x = seqPitchChangeProbabilityTable.x + seqPitchChangeProbabilityTable.width + 5
pitchProbRandKnob.y = seqPitchChangeProbabilityTable.y + 36
pitchProbRandKnob.changed = function(self)
  pitchProbabilityRandomizationAmount = self.value
end

local velRandKnob = sequencerPanel:Knob("VelocityRandomization", 0, 0, 100, true)
velRandKnob.displayName = "Rand"
velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity"
velRandKnob.unit = Unit.Percent
velRandKnob.height = 30
velRandKnob.width = 70
velRandKnob.x = seqVelTable.x + seqVelTable.width + 5
velRandKnob.y = seqVelTable.y + 36
velRandKnob.changed = function(self)
  velocityRandomizationAmount = self.value
end

local gateRandKnob = sequencerPanel:Knob("GateRandomization", 0, 0, 100, true)
gateRandKnob.displayName = "Rand"
gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate"
gateRandKnob.unit = Unit.Percent
gateRandKnob.height = 30
gateRandKnob.width = 70
gateRandKnob.x = seqGateTable.x + seqGateTable.width + 5
gateRandKnob.y = seqGateTable.y + 36
gateRandKnob.changed = function(self)
  print("gateRandKnob.changed")
  gateRandomizationAmount = self.value
end

local numPartsBox = sequencerPanel:NumBox("Parts", numParts, 1, 8, true)
numPartsBox.tooltip = "The Number of parts in the sequence"
numPartsBox.backgroundColour = menuBackgroundColour
numPartsBox.textColour = menuTextColour
numPartsBox.arrowColour = menuArrowColour
numPartsBox.outlineColour = menuOutlineColour
numPartsBox.size = {90,20}
numPartsBox.x = editPartMenu.x + editPartMenu.width + 20
numPartsBox.y = seqGateTable.y + seqGateTable.height + 30
numPartsBox.changed = function(self)
  print("numPartsBox.changed numParts/self.value", numParts, self.value)
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
      paramsPerPart[i].init = prev.init
    end
  end
  editPartMenu.items = partSelect
  editPartMenu:setValue(#partSelect)

  clearPosition()
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
    paramsPerPart[index].numStepsBox:setValue(numSteps)
  end

  partToStepMap = {} -- Reset
  totalNumSteps = 0
  for i=1, numPartsBox.value do
    table.insert(partToStepMap, (totalNumSteps + 1))
    totalNumSteps = totalNumSteps + paramsPerPart[i].numStepsBox.value
  end
  seqPitchTable.length = totalNumSteps
  tieStepTable.length = totalNumSteps
  seqPitchChangeProbabilityTable.length = totalNumSteps
  seqVelTable.length = totalNumSteps
  seqGateTable.length = totalNumSteps
  positionTable.length = totalNumSteps
  partsTable.length = totalNumSteps
  clearPosition()
end

-- Add params that are to be editable per part
for i=1,numPartsBox.max do
  print("Set paramsPerPart", i)
  local isVisible = i == 1
  local partResolution = sequencerPanel:Menu("PartDuration" .. i, getResolutionNames({"Follow Step"}))
  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())

  partResolution.displayName = "Part Duration"
  partResolution.tooltip = "Set the duration of a part."
  partResolution.selected = #resolutions + 1
  partResolution.visible = isVisible
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
  numStepsBox.visible = isVisible
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.width = 70
  numStepsBox.x = partResolution.x + partResolution.width + 10
  numStepsBox.y = partResolution.y + 25
  numStepsBox.changed = function(self)
    print("numStepsBox.changed", i)
    setNumSteps(i)
  end

  stepResolution.displayName = "Step Resolution"
  stepResolution.selected = 20
  stepResolution.visible = isVisible
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

  local playMode = sequencerPanel:Menu("PlayMode" .. i, {"Mono", "Poly"})
  playMode.displayName = "Play Mode"
  playMode.visible = isVisible
  playMode.x = stepResolution.x + stepResolution.width + 10
  playMode.y = stepResolution.y
  playMode.width = 60
  playMode.backgroundColour = menuBackgroundColour
  playMode.textColour = menuTextColour
  playMode.arrowColour = menuArrowColour
  playMode.outlineColour = menuOutlineColour

  local playProbabilityKnob = sequencerPanel:Knob("PartPlayProbabilityKnob" .. i, 100, 0, 100, true)
  playProbabilityKnob.displayName = "Play"
  playProbabilityKnob.tooltip = "Set the probability that the part will be played when randomizing part order."
  playProbabilityKnob.visible = isVisible
  playProbabilityKnob.unit = Unit.Percent
  playProbabilityKnob.x = playMode.x + playMode.width + 20
  playProbabilityKnob.y = playMode.y + 8
  playProbabilityKnob.height = 40
  playProbabilityKnob.width = 100

  local repeatProbabilityKnob = sequencerPanel:Knob("PartRepeatProbabilityKnob" .. i, 50, 0, 100, true)
  repeatProbabilityKnob.displayName = "Repeat"
  repeatProbabilityKnob.tooltip = "Set the probability of that the part will be repeated when randomizing part order. When set to 0, the part is never repeated."
  repeatProbabilityKnob.visible = isVisible
  repeatProbabilityKnob.unit = Unit.Percent
  repeatProbabilityKnob.x = playProbabilityKnob.x + playProbabilityKnob.width + 10
  repeatProbabilityKnob.y = playProbabilityKnob.y
  repeatProbabilityKnob.height = playProbabilityKnob.height
  repeatProbabilityKnob.width = playProbabilityKnob.width

  local directionProbabilityKnob = sequencerPanel:Knob("PartDirectionProbabilityKnob" .. i, 0, 0, 100, true)
  directionProbabilityKnob.displayName = "Backward"
  directionProbabilityKnob.tooltip = "Set the probability that the part will play backwards"
  directionProbabilityKnob.visible = isVisible
  directionProbabilityKnob.unit = Unit.Percent
  directionProbabilityKnob.x = repeatProbabilityKnob.x + repeatProbabilityKnob.width + 10
  directionProbabilityKnob.y = repeatProbabilityKnob.y
  directionProbabilityKnob.height = repeatProbabilityKnob.height
  directionProbabilityKnob.width = playProbabilityKnob.width

  table.insert(paramsPerPart, {partResolution=partResolution,stepResolution=stepResolution,playMode=playMode,playProbability=playProbabilityKnob,directionProbability=directionProbabilityKnob,repeatProbability=repeatProbabilityKnob,numStepsBox=numStepsBox,init=i==1})
end

editPartMenu:changed()
numPartsBox:changed()

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(arpId_)
  local index = 0
  local currentStep = 0 -- Holds the current step in the round that is being played
  local currentPartPosition = 0 -- Holds the currently playing part
  local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
  local randomTieCounter = 0 -- Used for holding random ties
  local partRepeat = 0 -- Used for holding part repeat info
  local partDirectionBackward = false -- Used for holding part direction
  -- START ARP LOOP
  while arpId_ == arpId do
    -- SET VALUES
    --local numParts = numPartsBox.value
    local currentPosition = (index % totalNumSteps) + 1 -- 11 % 4 = 3
    currentPosition = (index % totalNumSteps) + 1 -- 11 % 4 = 3
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

    -- If we are at the start of a part (and there is more than one part), check for part order randomization (or an active repeat)
    if startOfPart and numParts > 1 and (getRandomBoolean(partRandomizationAmount) or partRepeat > 0) then
      if partRepeat > 0 then
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
    if partDirectionBackward == true then
      local startStep = partToStepMap[currentPartPosition]
      local endStep = startStep + numStepsInPart - 1
      local diff = currentPosition - startStep
      currentPosition = endStep - diff
      print("startStep/endStep/diff/currentPosition", startStep, endStep, diff, currentPosition)
    end

    -- Params for current step position
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local gate = seqGateTable:getValue(currentPosition) -- get gate
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local pitchChangeProbability = seqPitchChangeProbabilityTable:getValue(currentPosition) -- get pitch change probability
    local tieNext = tieStepTable:getValue(currentPosition)

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

    -- Randomize pitch probaility
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
    if tieRandomizationAmount > 0 and randomTieCounter == 0 then
      print("Before randomized tieNext", tieNext)
      if getRandomBoolean(tieRandomizationAmount) then
        tieNext = 1
        randomTieCounter = 2
      else
        tieNext = 0
        randomTieCounter = 0
      end
      print("After randomize tieNext", tieNext)
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
        print("Reset tie")
      end
    end

    -- If gate is zero no notes will play on this step
    if gate > 0 and shouldAddNote then

      -- note: the note to play
      -- gate: gate length
      -- vel: note velocity
      -- steps: the duration of the note in steps
      -- stepCounter: the counter for how many steps the note has lasted so far

      local noteSteps = 1
      -- Check tie to next step
      if tieNext == 1 then
        if randomTieCounter == 2 then
          noteSteps = randomTieCounter
          randomTieCounter = 1
          print("Set automatic tie", noteSteps)
        else
          local tmp = currentPosition
          local startStep = partToStepMap[currentPartPosition]
          local endStep = startStep + numStepsInPart - 1
          print("Find tie length startStep/endStep/currentPosition", startStep, endStep, currentPosition)

          while (tieStepTable:getValue(tmp) == 1 or randomTieCounter == 2) and tmp < endStep and tmp >= startStep do
            noteSteps = noteSteps + 1
            if partDirectionBackward == true then
              tmp = tmp - 1
            else
              tmp = tmp + 1
            end
          end
        end
        print("Set tie steps currentPosition/noteSteps", currentPosition, noteSteps)
      end

      -- Check for pitch change randomization
      if getRandomBoolean(pitchChangeProbability) then
        local pitchPos = currentPosition
        if pitchChangeProbability > 50 and getRandomBoolean() then
          -- Get pitch adjustment from random index in the whole pitch table
          pitchPos = getRandom(1,totalNumSteps)
        else
          -- Get pitch adjustment from random index in pitch table for current part
          local min = partToStepMap[currentPartPosition]
          local max = min + numStepsInPart - 1
          pitchPos = getRandom(min, max)
        end
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      -- Add notes to play
      if playMode == 1 then
        -- MONO
        table.insert(notes, {note=heldNotes[#heldNotes].note+pitchAdjustment,gate=(gate/100),vel=vel,steps=noteSteps,stepCounter=0})
      else
        -- CHORD
        for i=1,#heldNotes do
          table.insert(notes, {note=heldNotes[i].note+pitchAdjustment,gate=(gate/100),vel=vel,steps=noteSteps,stepCounter=0})
        end
      end
    end

    -- PLAY NOTE
    --print("Ready to play notes", #notes)
    for _,note in ipairs(notes) do
      --print("Check note/stepCounter", note.note, note.stepCounter)
      -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
      if note.stepCounter == 0 and note.gate > 0 then
        -- Play the note for the number of steps that are set
        playNote(note.note, note.vel, beat2ms(stepDuration * note.gate * note.steps))
        --print("Playing note/stepDuration/steps", note.note, stepDuration * note.gate, note.steps)
      end
      -- Increment step counter
      note.stepCounter = note.stepCounter + 1
      --print("Increment note step counter", note.stepCounter)
    end

    -- REMOVE COMPLETED NOTES
    local keep = {}
    for _,note in ipairs(notes) do
      if note.steps > note.stepCounter then
        -- Keep note if more steps than counter is currently on
        table.insert(keep, note)
      end
    end
    notes = keep -- Refresh notes table

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
        break
      end
    end
  end
  postEvent(e)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local data = {totalNumSteps,numParts}
  local pitchTableData = {}
  local tieStepTableData = {}
  local seqPitchChangeProbabilityTableData = {}
  local seqVelTableData = {}
  local seqGateTableData = {}

  for i=1,totalNumSteps do
    table.insert(pitchTableData, seqPitchTable:getValue(i))
    table.insert(tieStepTableData, tieStepTable:getValue(i))
    table.insert(seqPitchChangeProbabilityTableData, seqPitchChangeProbabilityTable:getValue(i))
    table.insert(seqVelTableData, seqVelTable:getValue(i))
    table.insert(seqGateTableData, seqGateTable:getValue(i))
  end

  table.insert(data, pitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqPitchChangeProbabilityTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)

  return data
end

function onLoad(data)
  totalNumSteps = data[1]
  numParts = data[2]
  local seqPitchTableData = data[3]
  local tieStepTableData = data[4]
  local seqPitchChangeProbabilityTableData = data[5]
  local seqVelTableData = data[6]
  local seqGateTableData = data[7]

  seqPitchTable.length = totalNumSteps
  tieStepTable.length = totalNumSteps
  seqPitchChangeProbabilityTable.length = totalNumSteps
  seqVelTable.length = totalNumSteps
  seqGateTable.length = totalNumSteps

  for i=1,totalNumSteps do
    seqPitchTable:setValue(i, seqPitchTableData[i])
    tieStepTable:setValue(i, tieStepTableData[i])
    seqPitchChangeProbabilityTable:setValue(i, seqPitchChangeProbabilityTableData[i])
    seqVelTable:setValue(i, seqVelTableData[i])
    seqGateTable:setValue(i, seqGateTableData[i])
  end

  print("Loading totalNumSteps/numParts", totalNumSteps, numParts)
end
