--------------------------------------------------------------------------------
-- Polyphonic Sequencer
--------------------------------------------------------------------------------

require "common"

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local heldNotes = {}
local paramsPerPart = {}
local numParts = 4
local isPlaying = false
local title = "Polyphonic Sequencer"

setBackgroundColour("#2c2c2c")

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
  paramsPerPart[partIndex].seqGateTable.length = numSteps
  paramsPerPart[partIndex].seqRatchetTable.length = numSteps
end

function startPlaying()
  if isPlaying == true then
    return
  end
  for i=1,numParts do
    print("Start playing", i)
    spawn(arpeg, i)
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

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------
local tableX = 100
local tableY = 35
local tableWidth = 490
local tableHeight = 160

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = numParts * (tableHeight + 25) + 10

local label = sequencerPanel:Label("Label")
label.text = title
label.align = "left"
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {200,25}

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {102,22}
holdButton.x = sequencerPanel.width - holdButton.width
holdButton.y = 0
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
  end
end

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
  positionTable.height = tableHeight * 0.02
  positionTable.x = tableX
  positionTable.y = tableY

  local seqPitchTable = sequencerPanel:Table("Pitch" .. i, 8, 0, -12, 12, true)
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
  seqPitchTable.height = tableHeight * 0.38
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
  tieStepTable.height = tableHeight * 0.06
  tieStepTable.x = tableX
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2

  local seqVelTable = sequencerPanel:Table("Velocity" .. i, 8, 100, 1, 127, true)
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
  seqVelTable.height = tableHeight * 0.2
  seqVelTable.x = tableX
  seqVelTable.y = tieStepTable.y + tieStepTable.height + 2
  
  local seqGateTable = sequencerPanel:Table("Gate" .. i, 8, 100, 0, 120, true)
  seqGateTable.displayName = "Gate"
  seqGateTable.tooltip = "Gate for this step"
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = false
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = "#3322FFFF"
  if i % 2 == 0 then
    seqGateTable.backgroundColour = "#3f3e3e3e"
  else
    seqGateTable.backgroundColour = "#3f3e3e3e"
  end
  seqGateTable.width = tableWidth
  seqGateTable.height = tableHeight * 0.2
  seqGateTable.x = tableX
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 2
  
  local seqRatchetTable = sequencerPanel:Table("Subdivision" .. i, 8, 1, 1, 4, true)
  seqRatchetTable.displayName = "Subdivision"
  seqRatchetTable.tooltip = "Subdivision for this step"
  seqRatchetTable.showPopupDisplay = true
  seqRatchetTable.showLabel = false
  seqRatchetTable.fillStyle = "solid"
  seqRatchetTable.sliderColour = "#33229966"
  if i % 2 == 0 then
    seqRatchetTable.backgroundColour = "#3f000000"
  else
    seqRatchetTable.backgroundColour = "#3f000000"
  end
  seqRatchetTable.width = tableWidth
  seqRatchetTable.height = tableHeight * 0.14
  seqRatchetTable.x = tableX
  seqRatchetTable.y = seqGateTable.y + seqGateTable.height + 2

  local numBoxHeight = 20
  local numBoxSpacing = 1
  if numParts == 1 then
    numBoxSpacing = 6
  end
  local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
  directionProbability.displayName = "Backward"
  directionProbability.tooltip = "Backward probability amount"
  directionProbability.unit = Unit.Percent
  directionProbability.x = tableX + tableWidth + 10
  directionProbability.y = positionTable.y
  directionProbability.size = {100,numBoxHeight}

  local pitchRand = sequencerPanel:NumBox("PitchOffsetRandomization" .. i, 0, 0, 100, true)
  pitchRand.displayName = "Pitch"
  pitchRand.tooltip = "Set probability pitch from another step will be used"
  pitchRand.unit = Unit.Percent
  pitchRand.size = directionProbability.size
  pitchRand.x = directionProbability.x
  pitchRand.y = directionProbability.y + directionProbability.height + numBoxSpacing

  local tieRand = sequencerPanel:NumBox("TieRandomization" .. i, 0, 0, 100, true)
  tieRand.displayName = "Tie"
  tieRand.tooltip = "Amount of radomization applied to ties for selected part"
  tieRand.unit = Unit.Percent
  tieRand.size = directionProbability.size
  tieRand.x = directionProbability.x
  tieRand.y = pitchRand.y + pitchRand.height + numBoxSpacing

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.unit = Unit.Percent
  velRand.size = directionProbability.size
  velRand.x = directionProbability.x
  velRand.y = tieRand.y + tieRand.height + numBoxSpacing
  
  local gateRand = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRand.displayName = "Gate"
  gateRand.tooltip = "Gate radomization amount"
  gateRand.unit = Unit.Percent
  gateRand.size = directionProbability.size
  gateRand.x = directionProbability.x
  gateRand.y = velRand.y + velRand.height + numBoxSpacing

  local ratchetRand = sequencerPanel:NumBox("SubdivisionRandomization" .. i, 0, 0, 100, true)
  ratchetRand.displayName = "Subdivision"
  ratchetRand.tooltip = "Subdivision radomization amount"
  ratchetRand.unit = Unit.Percent
  ratchetRand.size = directionProbability.size
  ratchetRand.x = directionProbability.x
  ratchetRand.y = gateRand.y + gateRand.height + numBoxSpacing

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

  local leftButtonSpacing = 5

  local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
  stepResolution.tooltip = "Set the step resolution"
  stepResolution.showLabel = false
  stepResolution.selected = 20
  stepResolution.x = 0
  stepResolution.y = muteButton.y + muteButton.height + leftButtonSpacing
  stepResolution.size = muteButton.size
  stepResolution.backgroundColour = menuBackgroundColour
  stepResolution.textColour = menuTextColour
  stepResolution.arrowColour = menuArrowColour
  stepResolution.outlineColour = menuOutlineColour

  local numStepsBox = sequencerPanel:NumBox("Steps" .. i, 8, 1, 64, true)
  numStepsBox.displayName = "Steps"
  numStepsBox.tooltip = "The Number of steps in the part"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.size = stepResolution.size
  numStepsBox.x = 0
  numStepsBox.y = stepResolution.y + stepResolution.height + leftButtonSpacing
  numStepsBox.changed = function(self)
    print("numStepsBox.changed index/value", i, self.value)
    setNumSteps(i)
  end

  local ratchetMax = sequencerPanel:NumBox("SubdivisionMax" .. i, 4, 2, 16, true)
  ratchetMax.displayName = "Subdiv Max"
  ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
  ratchetMax.backgroundColour = menuBackgroundColour
  ratchetMax.textColour = menuTextColour
  ratchetMax.arrowColour = menuArrowColour
  ratchetMax.outlineColour = menuOutlineColour
  ratchetMax.size = numStepsBox.size
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
  channelBox.backgroundColour = menuBackgroundColour
  channelBox.textColour = menuTextColour
  channelBox.arrowColour = menuArrowColour
  channelBox.outlineColour = menuOutlineColour
  channelBox.size = ratchetMax.size
  channelBox.x = 0
  channelBox.y = ratchetMax.y + ratchetMax.height + leftButtonSpacing

  table.insert(paramsPerPart, {muteButton=muteButton,pitchRand=pitchRand,tieRand=tieRand,velRand=velRand,gateRand=gateRand,ratchetRand=ratchetRand,triggerNote=triggerNote,channelBox=channelBox,positionTable=positionTable,seqPitchTable=seqPitchTable,tieStepTable=tieStepTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,seqRatchetTable=seqRatchetTable,stepResolution=stepResolution,directionProbability=directionProbability,numStepsBox=numStepsBox})
  tableY = tableY + tableHeight + 20
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(partIndex)
  local index = 0
  local partDirectionBackward = false
  while isPlaying do
    local note = nil
    local isPartActive = false
    local offset = 0
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local channel = paramsPerPart[partIndex].channelBox.value
    print("Playing currentPosition/part/channel", currentPosition, partIndex, channel)
    if channel == 0 then
      channel = nil -- Play all channels
    end

    if #heldNotes == 0 then
      local buffer = 1 -- How long to wait for notes before stopping the sequencer
      wait(buffer)
      print("waiting for heldNotes", buffer)
      offset = offset + buffer
    end
    if #heldNotes == 0 then
      print("#heldNotes == 0 - stopping sequencer")
      stopPlaying()
      break
    end

    -- POLY
    local noteIndex = partIndex
    if #heldNotes > numParts then
      noteIndex = noteIndex + (#heldNotes - numParts)
    end
    isPartActive = type(heldNotes[noteIndex]) == "table" and paramsPerPart[partIndex].muteButton.value == false
    if isPartActive then
      note = heldNotes[noteIndex].note
    end

    print("partIndex/isPartActive", partIndex, isPartActive)

    if currentPosition == 1 then
      -- Set direction for this part
      local directionProbability = paramsPerPart[partIndex].directionProbability.value
      partDirectionBackward = getRandomBoolean(directionProbability)
      print("directionProbability/partIndex/partDirectionBackward", directionProbability, partIndex, partDirectionBackward)
    end

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
    local seqGateTable = paramsPerPart[partIndex].seqGateTable
    local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
    
    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local tieNext = tieStepTable:getValue(currentPosition)
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local gate = seqGateTable:getValue(currentPosition) -- get trigger probability
    local ratchet = seqRatchetTable:getValue(currentPosition) -- get ratchet

    -- Get randomization amounts
    local gateRandomizationAmount = paramsPerPart[partIndex].gateRand.value
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
    local pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    local tieRandomizationAmount = paramsPerPart[partIndex].tieRand.value
    local ratchetRandomizationAmount = paramsPerPart[partIndex].ratchetRand.value

    -- Randomize ratchet
    if getRandomBoolean(ratchetRandomizationAmount) then
      local min = seqRatchetTable.min
      local max = seqRatchetTable.max
      ratchet = getRandom(min, max)
      print("Randomize ratchet, min/max/ratchet", min, max, ratchet)
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

    -- Randomize gate
    if gateRandomizationAmount > 0 then
      gate = randomizeValue(gate, seqGateTable.min, seqGateTable.max, gateRandomizationAmount)
    end

    -- Check if step should trigger
    local shouldTrigger = gate > 0

    -- Get step duration
    local stepDuration = (getResolution(paramsPerPart[partIndex].stepResolution.value) * noteSteps) / ratchet

    -- Play subdivision
    for ratchetIndex=1, ratchet do
      -- Randomize velocity
      if velocityRandomizationAmount > 0 then
        vel = randomizeValue(vel, seqVelTable.min, seqVelTable.max, velocityRandomizationAmount)
      end

      -- Check for pitch change randomization
      if getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      if isPartActive and shouldTrigger then
        local duration = beat2ms(getPlayDuration(stepDuration, gate)) - 1 -- Make sure note is not played into the next
        playNote((note + pitchAdjustment), vel, duration, nil, channel)
        print("Playing note/vel/gate/ratchet/stepDuration/partIndex", note, vel, gate, ratchet, stepDuration, partIndex)
      end

      -- WAIT FOR NEXT BEAT
      wait(beat2ms(stepDuration) - offset)
      offset = 0 -- Reset offset
    end
    -- END SUBDIVISION LOOP

    -- Increment position
    if noteSteps > 1 then
      index = index + noteSteps - 1
    end
    index = (index + 1) % numStepsInPart
    print("Increment index, partIndex", index, partIndex)
  end
end

--------------------------------------------------------------------------------
-- Events
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
        break
      end
    end
  end
  table.insert(heldNotes, e)
  if #heldNotes == 1 and isPlaying == false then
    startPlaying()
  end
end

function onRelease(e)
  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
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
  local seqGateTableData = {}
  local seqRatchetTableData = {}

  for i=1, numParts do
    table.insert(numStepsData, paramsPerPart[i].numStepsBox.value)
    for j=1, paramsPerPart[i].numStepsBox.value do
      table.insert(seqPitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(tieStepTableData, paramsPerPart[i].tieStepTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
      table.insert(seqRatchetTableData, paramsPerPart[i].seqRatchetTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqPitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)
  table.insert(data, seqRatchetTableData)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqPitchTableData = data[2]
  local tieStepTableData = data[3]
  local seqVelTableData = data[4]
  local seqGateTableData = data[5]
  local seqRatchetTableData = data[6]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].tieStepTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    paramsPerPart[i].seqRatchetTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].tieStepTable:setValue(j, tieStepTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      paramsPerPart[i].seqRatchetTable:setValue(j, seqRatchetTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
