--------------------------------------------------------------------------------
-- Stochastic Drum Sequencer
--------------------------------------------------------------------------------

require "common"

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
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
  paramsPerPart[partIndex].tieStepTable.length = numSteps
  paramsPerPart[partIndex].seqPitchTable.length = numSteps
  paramsPerPart[partIndex].seqVelTable.length = numSteps
  paramsPerPart[partIndex].seqTriggerProbabilityTable.length = numSteps
  paramsPerPart[partIndex].seqRatchetTable.length = numSteps
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
local tableHeight = 105

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
if numParts == 1 then
  sequencerPanel.height = numParts * (tableHeight + 25) + 60
else
  sequencerPanel.height = numParts * (tableHeight + 25) + 30
end

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

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.fillColour = "#dd000061"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {102,22}
autoplayButton.x = playButton.x - playButton.width - 5
autoplayButton.y = 0

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
  positionTable.height = 3
  positionTable.x = tableX
  positionTable.y = tableY

  local seqPitchTableMin = 0
  if numParts == 1 then
    seqPitchTableMin = -12
  end
  local seqPitchTable = sequencerPanel:Table("Pitch" .. i, 8, 0, seqPitchTableMin, 12, true)
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
  if numParts == 1 then
    seqPitchTable.height = tableHeight * 0.5
  else
    seqPitchTable.height = tableHeight * 0.2
  end
  seqPitchTable.x = tableX
  seqPitchTable.y = positionTable.y + positionTable.height + 2

  local tieStepTable = sequencerPanel:Table("TieStep" .. i, 8, 0, 0, 1, true)
  tieStepTable.tooltip = "Tie with next step"
  tieStepTable.fillStyle = "solid"
  if i % 2 == 0 then
    tieStepTable.backgroundColour = "#3f606060"
  else
    tieStepTable.backgroundColour = "#3f606060"
  end
  tieStepTable.showLabel = false
  tieStepTable.sliderColour = "#3fcc3300"
  tieStepTable.width = tableWidth
  tieStepTable.height = 6
  tieStepTable.x = tableX
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2

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
  seqVelTable.height = tableHeight * 0.3
  seqVelTable.x = tableX
  seqVelTable.y = tieStepTable.y + tieStepTable.height + 2
  
  local seqTriggerProbabilityTableDefault = 0
  if numParts == 1 then
    seqTriggerProbabilityTableDefault = 100
  end
  local seqTriggerProbabilityTable = sequencerPanel:Table("Trigger" .. i, 8, seqTriggerProbabilityTableDefault, 0, 100, true)
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
  seqTriggerProbabilityTable.height = tableHeight * 0.3
  seqTriggerProbabilityTable.x = tableX
  seqTriggerProbabilityTable.y = seqVelTable.y + seqVelTable.height + 2
  
  local seqRatchetTable = sequencerPanel:Table("Subdivision" .. i, 8, 1, 1, 4, true)
  seqRatchetTable.displayName = "Subdivision"
  seqRatchetTable.tooltip = "Subdivision for this step"
  seqRatchetTable.showPopupDisplay = true
  seqRatchetTable.showLabel = false
  seqRatchetTable.visible = isVisible
  seqRatchetTable.fillStyle = "solid"
  seqRatchetTable.sliderColour = "#33229966"
  if i % 2 == 0 then
    seqRatchetTable.backgroundColour = "#3f000000"
  else
    seqRatchetTable.backgroundColour = "#3f000000"
  end
  seqRatchetTable.width = tableWidth
  seqRatchetTable.height = tableHeight * 0.2
  seqRatchetTable.x = tableX
  seqRatchetTable.y = seqTriggerProbabilityTable.y + seqTriggerProbabilityTable.height + 2

  local numBoxHeight = 20
  local numBoxSpacing = 1
  if numParts == 1 then
    numBoxSpacing = 6
  end
  local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
  directionProbability.displayName = "Backward"
  directionProbability.visible = isVisible
  directionProbability.tooltip = "Backward probability amount"
  directionProbability.unit = Unit.Percent
  directionProbability.x = tableX + tableWidth + 10
  directionProbability.y = positionTable.y
  directionProbability.size = {100,numBoxHeight}

  local pitchRand = sequencerPanel:NumBox("PitchOffsetRandomization" .. i, 0, 0, 100, true)
  pitchRand.displayName = "Pitch"
  pitchRand.tooltip = "Set probability pitch from another step will be used"
  pitchRand.visible = isVisible
  pitchRand.unit = Unit.Percent
  pitchRand.size = directionProbability.size
  pitchRand.x = directionProbability.x
  pitchRand.y = directionProbability.y + directionProbability.height + numBoxSpacing

  local tieRand = sequencerPanel:NumBox("TieRandomization" .. i, 0, 0, 100, true)
  tieRand.displayName = "Tie"
  tieRand.tooltip = "Amount of radomization applied to ties for selected part"
  tieRand.visible = isVisible
  tieRand.unit = Unit.Percent
  tieRand.size = directionProbability.size
  tieRand.x = directionProbability.x
  tieRand.y = pitchRand.y + pitchRand.height + numBoxSpacing

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.visible = isVisible
  velRand.unit = Unit.Percent
  velRand.size = directionProbability.size
  velRand.x = directionProbability.x
  velRand.y = tieRand.y + tieRand.height + numBoxSpacing
  
  local triggerRand = sequencerPanel:NumBox("TriggerRandomization" .. i, 0, 0, 100, true)
  triggerRand.displayName = "Trigger"
  triggerRand.tooltip = "Trigger probability radomization amount"
  triggerRand.visible = isVisible
  triggerRand.unit = Unit.Percent
  triggerRand.size = directionProbability.size
  triggerRand.x = directionProbability.x
  triggerRand.y = velRand.y + velRand.height + numBoxSpacing

  local ratchetRand = sequencerPanel:NumBox("SubdivisionRandomization" .. i, 0, 0, 100, true)
  ratchetRand.displayName = "Subdivision"
  ratchetRand.tooltip = "Subdivision radomization amount"
  ratchetRand.visible = isVisible
  ratchetRand.unit = Unit.Percent
  ratchetRand.size = directionProbability.size
  ratchetRand.x = directionProbability.x
  ratchetRand.y = triggerRand.y + triggerRand.height + numBoxSpacing

  --[[ local randomizeTriggerButton = sequencerPanel:Button("RandomizeTrigger" .. i)
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
  randomizeTriggerButton.y = triggerRand.y + triggerRand.height + 2 ]]

  local muteButton = sequencerPanel:OnOffButton("MutePart" .. i, false)
  muteButton.visible = isVisible
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

  local leftButtonSpacing = 1
  if numParts == 1 then
    leftButtonSpacing = 6
  else
    local types = {"Kick", "Snare", "Hihat", "Clap", "Toms", "Cymbal", "Tambourine", "Perc"}
    local typeLabel = sequencerPanel:Label("Label" .. i)
    typeLabel.tooltip = "Part Label"
    typeLabel.editable = true
    typeLabel.text = types[i]
    typeLabel.backgroundColour = menuBackgroundColour
    typeLabel.backgroundColourWhenEditing = "#cccccc"
    typeLabel.x = 0
    typeLabel.y = muteButton.y + muteButton.height + leftButtonSpacing
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
  elseif i == 5 then
    triggerNote.value = 41
  elseif i == 6 then
    triggerNote.value = 49
  elseif i == 7 then
    triggerNote.value = 54
  elseif i == 8 then
    triggerNote.value = 66
  end
  triggerNote.displayName = "Note"
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
  triggerNote.height = muteButton.height
  if numParts == 1 then
    triggerNote.width = muteButton.width
    triggerNote.x = 0
    triggerNote.y = muteButton.y + muteButton.height + leftButtonSpacing
  else
    triggerNote.width = 30
    triggerNote.x = 60
    triggerNote.y = muteButton.y + muteButton.height + leftButtonSpacing
  end

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
  stepResolution.tooltip = "Set the step resolution"
  stepResolution.showLabel = false
  stepResolution.visible = isVisible
  if numParts == 1 then
    stepResolution.selected = 11
  else
    stepResolution.selected = 20
  end
  stepResolution.x = 0
  stepResolution.y = triggerNote.y + triggerNote.height + leftButtonSpacing
  stepResolution.width = 90
  stepResolution.height = triggerNote.height
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour

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
  numStepsBox.y = stepResolution.y + stepResolution.height + leftButtonSpacing
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  --[[ randomizeTriggerButton.changed = function()
    for i=1,numStepsBox.value do
      if getRandomBoolean(25) then
        seqTriggerProbabilityTable:setValue(i, 0)
      elseif getRandomBoolean(25) then
        seqTriggerProbabilityTable:setValue(i, 100)
      else
        seqTriggerProbabilityTable:setValue(i, getRandom(seqTriggerProbabilityTable.min, seqTriggerProbabilityTable.max))
      end
    end
  end ]]

  local ratchetMax = sequencerPanel:NumBox("SubdivisionMax" .. i, 4, 2, 16, true)
  ratchetMax.displayName = "Subdivision"
  ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
  ratchetMax.visible = isVisible
  ratchetMax.backgroundColour = menuBackgroundColour
  ratchetMax.textColour = menuTextColour
  ratchetMax.arrowColour = menuArrowColour
  ratchetMax.outlineColour = menuOutlineColour
  ratchetMax.width = numStepsBox.width
  ratchetMax.height = numStepsBox.height
  ratchetMax.x = 0
  ratchetMax.y = numStepsBox.y + numStepsBox.height + leftButtonSpacing
  ratchetMax.changed = function(self)
    for i=1, seqRatchetTable.length do
      if seqRatchetTable:getValue(i) > self.value then
        seqRatchetTable:setValue(i, self.value)
      end
    end
    seqRatchetTable:setRange(1, self.value)
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
  channelBox.y = ratchetMax.y + ratchetMax.height + leftButtonSpacing

  table.insert(paramsPerPart, {muteButton=muteButton,pitchRand=pitchRand,tieRand=tieRand,velRand=velRand,triggerRand=triggerRand,ratchetRand=ratchetRand,triggerNote=triggerNote,channelBox=channelBox,positionTable=positionTable,seqPitchTable=seqPitchTable,tieStepTable=tieStepTable,seqVelTable=seqVelTable,seqTriggerProbabilityTable=seqTriggerProbabilityTable,seqRatchetTable=seqRatchetTable,stepResolution=stepResolution,directionProbability=directionProbability,numStepsBox=numStepsBox})
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
    local isPartActive = paramsPerPart[partIndex].muteButton.value == false
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
    local tieStepTable = paramsPerPart[partIndex].tieStepTable
    local seqVelTable = paramsPerPart[partIndex].seqVelTable
    local seqTriggerProbabilityTable = paramsPerPart[partIndex].seqTriggerProbabilityTable
    local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
    
    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local tieNext = tieStepTable:getValue(currentPosition)
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local triggerProbability = seqTriggerProbabilityTable:getValue(currentPosition) -- get trigger probability
    local ratchet = seqRatchetTable:getValue(currentPosition) -- get ratchet

    -- Get randomization amounts
    local triggerRandomizationAmount = paramsPerPart[partIndex].triggerRand.value
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
    local pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    local tieRandomizationAmount = paramsPerPart[partIndex].tieRand.value
    local ratchetRandomizationAmount = paramsPerPart[partIndex].ratchetRand.value

    -- Randomize ratchet
    if getRandomBoolean(ratchetRandomizationAmount) then
      local min = seqRatchetTable.min
      local max = seqRatchetTable.max
      --local max = math.min(seqRatchetTable.max, (math.ceil(seqRatchetTable.max * (ratchetRandomizationAmount/100)) + 1))
      ratchet = getRandom(min, max)
      print("Randomize ratchet, min/max/ratchet", min, max, ratchet)
      if evolve == true then
        seqRatchetTable:setValue(currentPosition, ratchet)
      end
    end

    -- Check if tie from previous step
    local tieStepPos = currentPosition - 1
    if partDirectionBackward == true then
      tieStepPos = currentPosition + 1
    end
    print("tieStepPos", tieStepPos)

    -- Hold the number of steps the note in this position should play
    local noteSteps = 1

    -- Randomize ties
    if currentPosition < numStepsInPart and getRandomBoolean(tieRandomizationAmount) then
      print("Before randomized tieNext", tieNext)
      -- Get length of tie
      local min = 2
      local max = math.ceil((numStepsInPart-currentPosition) * (tieRandomizationAmount/100))
      noteSteps = getRandom(min, math.max(2, max))
      tieNext = 1
      if evolve == true then
        tieStepTable:setValue(currentPosition, tieNext)
      end
      print("After randomize tieNext", tieNext)
    elseif tieNext == 1 then
      local tieStepPos = currentPosition
      while tieStepPos > 0 and tieStepPos < numStepsInPart and tieStepTable:getValue(tieStepPos) == 1 do
        noteSteps = noteSteps + 1
        if partDirectionBackward == true then
          tieStepPos = tieStepPos - 1
        else
          tieStepPos = tieStepPos + 1
        end
      end
      print("Set tie steps currentPosition/noteSteps", currentPosition, noteSteps)
    end

    -- UPDATE STEP POSITION TABLE
    for j=1, numStepsInPart do
      local isActiveStep = j >= currentPosition and j < currentPosition + noteSteps
      if partDirectionBackward == true then
        isActiveStep = j <= currentPosition and j > currentPosition - noteSteps
      end
      if isPartActive and isActiveStep then
        paramsPerPart[partIndex].positionTable:setValue(j, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(j, 0)
      end
    end

    -- Randomize trigger probability
    if getRandomBoolean(triggerRandomizationAmount) then
      local changeMax = getChangeMax(seqTriggerProbabilityTable.max, triggerRandomizationAmount)
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

    -- Check if step should trigger
    local shouldTrigger = getRandomBoolean(triggerProbability)

    -- Get step duration
    local stepDuration = (getResolution(paramsPerPart[partIndex].stepResolution.value) * noteSteps) / ratchet

    -- Play subdivision
    for ratchetIndex=1, ratchet do
      -- Randomize trigger probability
      --[[ if getRandomBoolean(triggerRandomizationAmount) then
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

      -- Check if step should trigger
      local shouldTrigger = getRandomBoolean(triggerProbability) ]]

      -- Randomize velocity
      if getRandomBoolean(velocityRandomizationAmount) then
        local changeMax = getChangeMax(seqVelTable.max, velocityRandomizationAmount)
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
      if getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      -- Play note if trigger probability hits (and part is not turned off)
      if isPartActive and shouldTrigger then
        local note = paramsPerPart[partIndex].triggerNote.value + pitchAdjustment
        local duration = beat2ms(stepDuration) - 1 -- Make sure note is not played into the next
        playNote(note, vel, duration, nil, channel)
        print("Playing note/vel/ratchet/stepDuration", note, vel, ratchet, stepDuration)
      end

      -- WAIT FOR NEXT BEAT
      waitBeat(stepDuration)
    end
    -- END RATCHET LOOP

    -- Increment position
    if noteSteps > 1 then
      index = index + noteSteps - 1
    end
    index = (index + 1) % numStepsInPart
  end
end

--------------------------------------------------------------------------------
-- Events
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
  local seqPitchTableData = {}
  local tieStepTableData = {}
  local seqVelTableData = {}
  local seqTriggerProbabilityTableData = {}
  local seqRatchetTableData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqPitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(tieStepTableData, paramsPerPart[i].tieStepTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqTriggerProbabilityTableData, paramsPerPart[i].seqTriggerProbabilityTable:getValue(j))
      table.insert(seqRatchetTableData, paramsPerPart[i].seqRatchetTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqPitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqTriggerProbabilityTableData)
  table.insert(data, seqRatchetTableData)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqPitchTableData = data[2]
  local tieStepTableData = data[3]
  local seqVelTableData = data[4]
  local seqTriggerProbabilityTableData = data[5]
  local seqRatchetTableData = data[6]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].tieStepTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqTriggerProbabilityTable.length = v
    paramsPerPart[i].seqRatchetTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].tieStepTable:setValue(j, tieStepTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqTriggerProbabilityTable:setValue(j, seqTriggerProbabilityTableData[dataCounter])
      paramsPerPart[i].seqRatchetTable:setValue(j, seqRatchetTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
