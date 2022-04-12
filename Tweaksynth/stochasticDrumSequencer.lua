--------------------------------------------------------------------------------
-- Stochastic Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "00000000"
local arpId = {}
local numParts = 6
local paramsPerPart = {}

setBackgroundColour("#3f3f3f")

for i=1,numParts do
  table.insert(arpId, 0)
end

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
sequencerPanel.height = 600

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
  paramsPerPart[partIndex].seqVelTable.length = numSteps
  paramsPerPart[partIndex].seqTriggerProbabilityTable.length = numSteps
end

local tableX = 100
local tableY = 0
local tableWidth = 490
local tableHeight = 80

-- Add params that are to be editable per part
for i=1,numParts do
  print("Set paramsPerPart", i)

  local positionTable = sequencerPanel:Table("Position" .. i, 8, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  positionTable.backgroundColour = "#9f02ACFE"
  positionTable.sliderColour = outlineColour
  positionTable.width = tableWidth
  positionTable.height = 10
  positionTable.x = tableX
  positionTable.y = tableY

  local seqVelTable = sequencerPanel:Table("Velocity" .. i, 8, 100, 1, 127, true)
  seqVelTable.displayName = "Velocity"
  seqVelTable.tooltip = "Velocity for this step"
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = false
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqVelTable.backgroundColour = "#3f000000"
  else
    seqVelTable.backgroundColour = "#6f000000"
  end
  seqVelTable.width = tableWidth
  seqVelTable.height = tableHeight / 2
  seqVelTable.x = tableX
  seqVelTable.y = positionTable.y + positionTable.height + 3
  
  local seqTriggerProbabilityTable = sequencerPanel:Table("Trigger" .. i, 8, 0, 0, 100, true)
  seqTriggerProbabilityTable.displayName = "Trigger"
  seqTriggerProbabilityTable.tooltip = "Trigger probability for this step"
  seqTriggerProbabilityTable.showPopupDisplay = true
  seqTriggerProbabilityTable.showLabel = false
  seqTriggerProbabilityTable.fillStyle = "solid"
  seqTriggerProbabilityTable.sliderColour = menuArrowColour
  if i % 2 == 0 then
    seqTriggerProbabilityTable.backgroundColour = "#3f000000"
  else
    seqTriggerProbabilityTable.backgroundColour = "#6f000000"
  end
  seqTriggerProbabilityTable.width = tableWidth
  seqTriggerProbabilityTable.height = tableHeight / 2
  seqTriggerProbabilityTable.x = tableX
  seqTriggerProbabilityTable.y = seqVelTable.y + seqVelTable.height + 1

  local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
  directionProbability.displayName = "Backward"
  directionProbability.tooltip = "Backward probability amount"
  directionProbability.unit = Unit.Percent
  directionProbability.x = tableX + tableWidth + 10
  directionProbability.y = positionTable.y + 1
  directionProbability.size={100,22}

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.unit = Unit.Percent
  velRand.size = directionProbability.size
  velRand.x = directionProbability.x
  velRand.y = directionProbability.y + directionProbability.height + 2
  
  local triggerRand = sequencerPanel:NumBox("TriggerRandomization" .. i, 0, 0, 100, true)
  triggerRand.displayName = "Trigger"
  triggerRand.tooltip = "Trigger probability radomization amount"
  triggerRand.unit = Unit.Percent
  triggerRand.size = directionProbability.size
  triggerRand.x = directionProbability.x
  triggerRand.y = velRand.y + velRand.height + 2

  local randomizeTriggerButton = sequencerPanel:Button("RandomizePitch")
  randomizeTriggerButton.persistent = false
  randomizeTriggerButton.backgroundColourOff = "#33084486"
  randomizeTriggerButton.backgroundColourOn = "#9902ACFE"
  randomizeTriggerButton.textColourOff = "#cc22FFFF"
  randomizeTriggerButton.textColourOn = "#ccFFFFFF"
  randomizeTriggerButton.displayName = "Randomize"
  randomizeTriggerButton.tooltip = "Randomize Trigger Probability - NOTE: Changes all settings!"
  randomizeTriggerButton.fillColour = "#dd000061"
  randomizeTriggerButton.size = directionProbability.size
  randomizeTriggerButton.x = directionProbability.x
  randomizeTriggerButton.y = triggerRand.y + triggerRand.height + 2

  local typeMenu = sequencerPanel:Menu("Label" .. i, {"Off", "Kick", "Snare", "Hihat", "HH Open", "Clap", "Tom", "Perc", "Cymbal", "Note", "Misc"})
  typeMenu.tooltip = "Part Label"
  typeMenu.showLabel = false
  typeMenu.selected = i + 1
  typeMenu.x = 0
  typeMenu.y = seqVelTable.y
  typeMenu.width = 60
  typeMenu.height = 18
  typeMenu.backgroundColour = menuBackgroundColour
  typeMenu.textColour = menuTextColour
  typeMenu.arrowColour = menuArrowColour
  typeMenu.outlineColour = menuOutlineColour

  local triggerNote = sequencerPanel:NumBox("TriggerNote" .. i, 36, 0, 127, true)
  if i == 2 then
    triggerNote.value = 38
  elseif i == 3 then
    triggerNote.value = 42
  elseif i == 4 then
    triggerNote.value = 46
  elseif i == 5 then
    triggerNote.value = 39
  elseif i == 6 then
    triggerNote.value = 43
  end
  triggerNote.tooltip = "The note to trigger"
  triggerNote.unit = Unit.MidiKey
  triggerNote.showPopupDisplay = true
  triggerNote.showLabel = false
  triggerNote.fillStyle = "solid"
  triggerNote.sliderColour = menuArrowColour
  triggerNote.displayName = "Note"
  triggerNote.width = 30
  triggerNote.height = typeMenu.height
  triggerNote.x = typeMenu.width
  triggerNote.y = seqVelTable.y

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
  stepResolution.tooltip = "Set the step resolution"
  stepResolution.showLabel = false
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

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, 8, 1, 32, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
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
  channelBox.tooltip = "Midi channel to send to - 0 = omni"
  channelBox.backgroundColour = menuBackgroundColour
  channelBox.textColour = menuTextColour
  channelBox.arrowColour = menuArrowColour
  channelBox.outlineColour = menuOutlineColour
  channelBox.width = numStepsBox.width
  channelBox.height = numStepsBox.height
  channelBox.x = 0
  channelBox.y = numStepsBox.y + numStepsBox.height + 2

  table.insert(paramsPerPart, {velRand=velRand,triggerRand=triggerRand,typeMenu=typeMenu,triggerNote=triggerNote,channelBox=channelBox,positionTable=positionTable,seqVelTable=seqVelTable,seqTriggerProbabilityTable=seqTriggerProbabilityTable,stepResolution=stepResolution,directionProbability=directionProbability,numStepsBox=numStepsBox,init=i==1})
  tableY = tableY + tableHeight + 20
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
    local seqVelTable = paramsPerPart[partIndex].seqVelTable
    local seqTriggerProbabilityTable = paramsPerPart[partIndex].seqTriggerProbabilityTable

    -- Params for current step position
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local triggerProbability = seqTriggerProbabilityTable:getValue(currentPosition) -- get trigger probability

    -- Randomize trigger probability
    local triggerRandomizationAmount = paramsPerPart[partIndex].triggerRand.value
    if triggerRandomizationAmount > 0 then
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
    end

    -- Randomize velocity
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
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
        vel = getRandom(min, max)
        if evolve == true then
          seqVelTable:setValue(currentPosition, vel)
        end
      end
    end

    -- Play note if trigger probability hits (and part is not turned off)
    if paramsPerPart[partIndex].typeMenu.value > 1 and getRandomBoolean(triggerProbability) then
      local note = paramsPerPart[partIndex].triggerNote.value
      playNote(note, vel, beat2ms(stepDuration), nil, channel)
      print("Playing note/vel/stepDuration", note, vel, stepDuration)
  end

    -- UPDATE STEP POSITION TABLE
    for i=1, numStepsInPart do
      if i == currentPosition then
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

function startPlaying()
  for i,v in ipairs(arpId) do
    print("Start playing", i)
    run(arpeg, i, v)
  end
end

function stopPlaying()
  for i=1,#arpId do
    arpId[i] = arpId[i] + 1
    print("Stop playing", i)
  end
  clearPosition()
end

function onNote(e)
  -- Trigger on C4
  if e.note == 72 then
    startPlaying()
  else
    postEvent(e)
  end
end

function onRelease(e)
  -- Trigger on C4
  if e.note == 72 then
    stopPlaying()
  else
    postEvent(e)
  end
end

function onTransport(start)
  -- TODO Button for autoplay?
  print("onTransport", start)
  if start then
    startPlaying()
  else
    stopPlaying()
  end
end
