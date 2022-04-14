--------------------------------------------------------------------------------
-- Stochastic Drum Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "00000000"
local arpId = {}
local paramsPerPart = {}
local isPlaying = false

if type(numParts) == "nil" then
  numParts = 4
end

if type(title) == "nil" then
  title = "Stochastic Drum Sequencer"
end

setBackgroundColour("#2c2c2c")

for i=1,numParts do
  table.insert(arpId, 0)
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
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

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

function setNumSteps(partIndex)
  local numSteps = paramsPerPart[partIndex].numStepsBox.value
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].seqPitchTable.length = numSteps
  paramsPerPart[partIndex].seqVelTable.length = numSteps
  paramsPerPart[partIndex].seqTriggerProbabilityTable.length = numSteps
end

function startPlaying()
  if isPlaying == true then
    return
  end
  for i,v in ipairs(arpId) do
    print("Start playing", i)
    spawn(arpeg, i, v)
  end
  isPlaying = true
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  for i=1,#arpId do
    arpId[i] = arpId[i] + 1
    print("Stop playing", i)
  end
  isPlaying = false
  clearPosition()
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------
local tableX = 100
local tableY = 35
local tableWidth = 490
local tableHeight = 94

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = numParts * (tableHeight + 25) + 30

local label = sequencerPanel:Label("Label")
label.text = title
label.align = "left"
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {230,25}

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.fillColour = "#dd000061"
playButton.displayName = "Play"
playButton.size = {102,22}
playButton.x = sequencerPanel.width - playButton.width
playButton.y = 0
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

-- Add params that are to be editable per part
for i=1,numParts do
  print("Set paramsPerPart", i)

  local isVisible = i <= numParts

  local positionTable = sequencerPanel:Table("Position" .. i, 8, 0, 0, 1, true)
  positionTable.visible = isVisible
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  positionTable.backgroundColour = "#9f02ACFE"
  positionTable.sliderColour = outlineColour
  positionTable.width = tableWidth
  positionTable.height = 10
  positionTable.x = tableX
  positionTable.y = tableY

  local seqPitchTable = sequencerPanel:Table("Pitch" .. i, 8, 0, 0, 12, true)
  seqPitchTable.displayName = "Pitch"
  seqPitchTable.tooltip = "Pitch offset for this step"
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.showLabel = false
  seqPitchTable.fillStyle = "solid"
  seqPitchTable.sliderColour = "#3f6c6c6c"
  if i % 2 == 0 then
    seqPitchTable.backgroundColour = "#3f606060"
  else
    seqPitchTable.backgroundColour = "#3f606060"
  end
  seqPitchTable.width = tableWidth
  seqPitchTable.height = tableHeight * 0.2
  seqPitchTable.x = tableX
  seqPitchTable.y = positionTable.y + positionTable.height + 2

  local seqVelTable = sequencerPanel:Table("Velocity" .. i, 8, 100, 1, 127, true)
  seqVelTable.visible = isVisible
  seqVelTable.displayName = "Velocity"
  seqVelTable.tooltip = "Velocity for this step"
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = false
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = "#9f09A3F4"
  if i % 2 == 0 then
    seqVelTable.backgroundColour = "#3f000000"
  else
    seqVelTable.backgroundColour = "#3f000000"
  end
  seqVelTable.width = tableWidth
  seqVelTable.height = tableHeight * 0.4
  seqVelTable.x = tableX
  seqVelTable.y = seqPitchTable.y + seqPitchTable.height + 2
  
  local seqTriggerProbabilityTable = sequencerPanel:Table("Trigger" .. i, 8, 0, 0, 100, true)
  seqTriggerProbabilityTable.displayName = "Trigger"
  seqTriggerProbabilityTable.tooltip = "Trigger probability for this step"
  seqTriggerProbabilityTable.showPopupDisplay = true
  seqTriggerProbabilityTable.showLabel = false
  seqTriggerProbabilityTable.visible = isVisible
  seqTriggerProbabilityTable.fillStyle = "solid"
  seqTriggerProbabilityTable.sliderColour = "#3322FFFF"
  if i % 2 == 0 then
    seqTriggerProbabilityTable.backgroundColour = "#3f3e3e3e"
  else
    seqTriggerProbabilityTable.backgroundColour = "#3f3e3e3e"
  end
  seqTriggerProbabilityTable.width = tableWidth
  seqTriggerProbabilityTable.height = tableHeight * 0.4
  seqTriggerProbabilityTable.x = tableX
  seqTriggerProbabilityTable.y = seqVelTable.y + seqVelTable.height + 2

  local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
  directionProbability.displayName = "Backward"
  directionProbability.visible = isVisible
  directionProbability.tooltip = "Backward probability amount"
  directionProbability.unit = Unit.Percent
  directionProbability.x = tableX + tableWidth + 10
  directionProbability.y = positionTable.y + 1
  directionProbability.size={100,20}

  local pitchRand = sequencerPanel:NumBox("PitchOffsetRandomization" .. i, 0, 0, 100, true)
  pitchRand.displayName = "Pitch"
  pitchRand.tooltip = "Set probability pitch from another step will be used"
  pitchRand.visible = isVisible
  pitchRand.unit = Unit.Percent
  pitchRand.size = directionProbability.size
  pitchRand.x = directionProbability.x
  pitchRand.y = directionProbability.y + directionProbability.height + 2

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.visible = isVisible
  velRand.unit = Unit.Percent
  velRand.size = directionProbability.size
  velRand.x = directionProbability.x
  velRand.y = pitchRand.y + pitchRand.height + 2
  
  local triggerRand = sequencerPanel:NumBox("TriggerRandomization" .. i, 0, 0, 100, true)
  triggerRand.displayName = "Trigger"
  triggerRand.tooltip = "Trigger probability radomization amount"
  triggerRand.visible = isVisible
  triggerRand.unit = Unit.Percent
  triggerRand.size = directionProbability.size
  triggerRand.x = directionProbability.x
  triggerRand.y = velRand.y + velRand.height + 2

  local randomizeTriggerButton = sequencerPanel:Button("RandomizePitch" .. i)
  randomizeTriggerButton.persistent = false
  randomizeTriggerButton.visible = isVisible
  randomizeTriggerButton.backgroundColourOff = "#33084486"
  randomizeTriggerButton.backgroundColourOn = "#9902ACFE"
  randomizeTriggerButton.textColourOff = "#cc22FFFF"
  randomizeTriggerButton.textColourOn = "#ccFFFFFF"
  randomizeTriggerButton.displayName = "Randomize"
  randomizeTriggerButton.tooltip = "Randomize Trigger Probability"
  randomizeTriggerButton.fillColour = "#dd000061"
  randomizeTriggerButton.size = directionProbability.size
  randomizeTriggerButton.x = directionProbability.x
  randomizeTriggerButton.y = triggerRand.y + triggerRand.height + 2

  local muteButton = sequencerPanel:OnOffButton("MutePart" .. i, false)
  muteButton.backgroundColourOff = "#ff084486"
  muteButton.backgroundColourOn = "#ff02ACFE"
  muteButton.textColourOff = "#ff22FFFF"
  muteButton.textColourOn = "#efFFFFFF"
  muteButton.fillColour = "#dd000061"
  muteButton.displayName = "Mute"
  muteButton.tooltip = "Mute part"
  muteButton.size = {90,20}
  muteButton.x = 0
  muteButton.y = positionTable.y

  if numParts > 1 then
    local types = {"Kick", "Snare", "Hihat", "Clap"}
    local typeLabel = sequencerPanel:Label("Label" .. i)
    typeLabel.tooltip = "Part Label"
    typeLabel.editable = true
    typeLabel.text = types[i]
    typeLabel.backgroundColour = menuBackgroundColour
    typeLabel.backgroundColourWhenEditing = "#cccccc"
    typeLabel.x = 0
    typeLabel.y = muteButton.y + muteButton.height + 2
    typeLabel.width = 59
    typeLabel.height = muteButton.height
  end

  local triggerNote = sequencerPanel:NumBox("TriggerNote" .. i, 36, 0, 127, true)
  if i == 2 then
    triggerNote.value = 38
  elseif i == 3 then
    triggerNote.value = 42
  elseif i == 4 then
    triggerNote.value = 39
  end
  triggerNote.tooltip = "The note to trigger"
  triggerNote.unit = Unit.MidiKey
  triggerNote.showPopupDisplay = true
  triggerNote.visible = isVisible
  triggerNote.showLabel = numParts == 1
  triggerNote.fillStyle = "solid"
  triggerNote.backgroundColour = menuBackgroundColour
  triggerNote.textColour = menuTextColour
  triggerNote.arrowColour = menuArrowColour
  triggerNote.outlineColour = menuOutlineColour
  triggerNote.displayName = "Note"
  if numParts == 1 then
    triggerNote.size = muteButton.size
    triggerNote.x = 0
    triggerNote.y = muteButton.y + muteButton.height + 2
  else
    triggerNote.width = 30
    triggerNote.height = muteButton.height
    triggerNote.x = 60
    triggerNote.y = muteButton.y + muteButton.height + 2
  end

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
  stepResolution.tooltip = "Set the step resolution"
  stepResolution.showLabel = false
  stepResolution.visible = isVisible
  stepResolution.selected = 20
  stepResolution.x = 0
  stepResolution.y = triggerNote.y + triggerNote.height + 2
  stepResolution.width = 90
  stepResolution.height = triggerNote.height
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour
  stepResolution.changed = function(self)
    print("stepResolution.changed", i)
    setNumSteps(i)
  end

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, 8, 1, 64, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.visible = isVisible
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.width = stepResolution.width
  numStepsBox.height = stepResolution.height
  numStepsBox.x = 0
  numStepsBox.y = stepResolution.y + stepResolution.height + 2
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  randomizeTriggerButton.changed = function()
    for i=1,numStepsBox.value do
      seqTriggerProbabilityTable:setValue(i, getRandom(seqTriggerProbabilityTable.min, seqTriggerProbabilityTable.max))
    end
  end

  local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
  channelBox.displayName = "Channel"
  channelBox.tooltip = "Midi channel that receives trigger from this part. 0 = omni"
  channelBox.visible = isVisible
  channelBox.backgroundColour = menuBackgroundColour
  channelBox.textColour = menuTextColour
  channelBox.arrowColour = menuArrowColour
  channelBox.outlineColour = menuOutlineColour
  channelBox.width = numStepsBox.width
  channelBox.height = numStepsBox.height
  channelBox.x = 0
  channelBox.y = numStepsBox.y + numStepsBox.height + 2

  table.insert(paramsPerPart, {muteButton=muteButton,pitchRand=pitchRand,velRand=velRand,triggerRand=triggerRand,triggerNote=triggerNote,channelBox=channelBox,positionTable=positionTable,seqPitchTable=seqPitchTable,seqVelTable=seqVelTable,seqTriggerProbabilityTable=seqTriggerProbabilityTable,stepResolution=stepResolution,directionProbability=directionProbability,numStepsBox=numStepsBox})
  tableY = tableY + tableHeight + 25
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(partIndex, arpId_)
  local index = 0
  local partDirectionBackward = false
  while arpId_ == arpId[partIndex] do
    -- Set current position and part position
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1 -- 11 % 4 = 3
    local channel = paramsPerPart[partIndex].channelBox.value
    print("Playing part/channel", partIndex, channel)
    if channel == 0 then
      channel = nil -- Play all channels
    end

    if currentPosition == 1 then
      -- Set direction for this part
      local directionProbability = paramsPerPart[partIndex].directionProbability.value
      partDirectionBackward = getRandomBoolean(directionProbability)
      print("directionProbability/partIndex/partDirectionBackward", directionProbability, partIndex, partDirectionBackward)
    end

    -- If evolve is true, the randomization is written back to the table
    local evolve = false--evolveButton.value

    -- Params for current part position
    local stepDuration = getResolution(paramsPerPart[partIndex].stepResolution.value)

    -- Flip position if playing backwards
    local startStep = 1
    if partDirectionBackward == true then
      local endStep = startStep + numStepsInPart - 1
      local diff = currentPosition - startStep
      currentPosition = endStep - diff
      print("startStep/endStep/diff/currentPosition", startStep, endStep, diff, currentPosition)
    end

    -- Tables for current step position
    local seqPitchTable = paramsPerPart[partIndex].seqPitchTable
    local seqVelTable = paramsPerPart[partIndex].seqVelTable
    local seqTriggerProbabilityTable = paramsPerPart[partIndex].seqTriggerProbabilityTable

    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local triggerProbability = seqTriggerProbabilityTable:getValue(currentPosition) -- get trigger probability

    -- Randomize trigger probability
    local triggerRandomizationAmount = paramsPerPart[partIndex].triggerRand.value
    if getRandomBoolean(triggerRandomizationAmount) then
      local changeMax = math.ceil(seqTriggerProbabilityTable.max * (triggerRandomizationAmount/100))
      local min = triggerProbability - changeMax
      local max = triggerProbability + changeMax
      if min < seqTriggerProbabilityTable.min then
        min = seqTriggerProbabilityTable.min
      end
      if max > seqTriggerProbabilityTable.max then
        max = seqTriggerProbabilityTable.max
      end
      triggerProbability = getRandom(min, max)
      if evolve == true then
        seqTriggerProbabilityTable:setValue(currentPosition, triggerProbability)
      end
    end

    -- Randomize velocity
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
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
      vel = getRandom(min, max)
      if evolve == true then
        seqVelTable:setValue(currentPosition, vel)
      end
    end

    -- Check for pitch change randomization
    local pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    if getRandomBoolean(pitchChangeProbability) then
      -- Get pitch adjustment from random index in pitch table for current part
      local pitchPos = getRandom(numStepsInPart)
      pitchAdjustment = seqPitchTable:getValue(pitchPos)
      print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
    end

    local isActive = paramsPerPart[partIndex].muteButton.value == false

    -- Play note if trigger probability hits (and part is not turned off)
    if isActive and getRandomBoolean(triggerProbability) then
      local note = paramsPerPart[partIndex].triggerNote.value + pitchAdjustment
      playNote(note, vel, beat2ms(stepDuration), nil, channel)
      print("Playing note/vel/stepDuration", note, vel, stepDuration)
  end

    -- UPDATE STEP POSITION TABLE
    for i=1, numStepsInPart do
      if isActive and i == currentPosition then
        paramsPerPart[partIndex].positionTable:setValue(i, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(i, 0)
      end
    end

    -- INCREMENT POSITION
    index = (index + 1) % numStepsInPart -- increment position

    -- WAIT FOR NEXT BEAT
    waitBeat(stepDuration)
  end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onTransport(start)
  playButton:setValue(start)
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqPitchTableData = {}
  local seqVelTableData = {}
  local seqTriggerProbabilityTableData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqPitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqTriggerProbabilityTableData, paramsPerPart[i].seqTriggerProbabilityTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqPitchTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqTriggerProbabilityTableData)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqPitchTableData = data[2]
  local seqVelTableData = data[3]
  local seqTriggerProbabilityTableData = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqTriggerProbabilityTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqTriggerProbabilityTable:setValue(j, seqTriggerProbabilityTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
