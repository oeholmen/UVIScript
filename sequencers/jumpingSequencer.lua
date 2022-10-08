--------------------------------------------------------------------------------
-- Jumping Sequencer
--------------------------------------------------------------------------------

require "../includes/common"

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local heldNotes = {}
local paramsPerPart = {}
local heldNoteIndex = 0 -- Counter for held notes (used by "As Played" seq mode)
local numParts = 3
local isPlaying = false
local title = "Jumping Sequencer"

setBackgroundColour("#2c2c2c")

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------
local tableX = 0
local tableY = 35
local tableWidth = 590
local tableHeight = 160

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = menuOutlineColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = numParts * (tableHeight + 25) + 50

local label = sequencerPanel:Label("Label")
label.text = title
label.align = "left"
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {180,25}

local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
holdButton.backgroundColourOff = "#ff084486"
holdButton.backgroundColourOn = "#ff02ACFE"
holdButton.textColourOff = "#ff22FFFF"
holdButton.textColourOn = "#efFFFFFF"
holdButton.displayName = "Hold"
holdButton.fillColour = "#dd000061"
holdButton.size = {100,20}
holdButton.x = sequencerPanel.width - holdButton.width
holdButton.y = 0
holdButton.changed = function(self)
  if self.value == false then
    heldNotes = {}
    clearPosition()
  end
end

local jumpProbability = sequencerPanel:NumBox("JumpProbability", 50, 0, 100, true)
jumpProbability.unit = Unit.Percent
jumpProbability.displayName = "Jump Probability"
jumpProbability.tooltip = "The probability that the sequence will jump to another part"
jumpProbability.backgroundColour = menuBackgroundColour
jumpProbability.textColour = menuTextColour
jumpProbability.width = 150
jumpProbability.height = holdButton.height
jumpProbability.y = sequencerPanel.height - jumpProbability.height - 2
jumpProbability.x = 0

local playMode = sequencerPanel:Menu("PlayMode", {"Mono", "As Played", "Random"})
playMode.showLabel = false
playMode.width = 100
playMode.height = holdButton.height
playMode.x = jumpProbability.x + jumpProbability.width + 5
playMode.y = jumpProbability.y
playMode.backgroundColour = menuBackgroundColour
playMode.textColour = menuTextColour
playMode.arrowColour = menuArrowColour
playMode.outlineColour = menuOutlineColour

local numStepsBox = sequencerPanel:NumBox("Steps", 8, 1, 64, true)
numStepsBox.displayName = "Steps"
numStepsBox.tooltip = "The number of steps in the part"
numStepsBox.backgroundColour = menuBackgroundColour
numStepsBox.textColour = menuTextColour
numStepsBox.width = 90
numStepsBox.height = playMode.height
numStepsBox.y = playMode.y
numStepsBox.x = playMode.x + playMode.width + 5
numStepsBox.changed = function(self)
  setNumSteps()
end

local stepResolution = sequencerPanel:Menu("StepResolution", getResolutionNames())
stepResolution.tooltip = "Set the step resolution"
stepResolution.selected = 20
stepResolution.showLabel = false
stepResolution.width = 80
stepResolution.height = playMode.height
stepResolution.x = numStepsBox.x + numStepsBox.width + 5
stepResolution.y = playMode.y
stepResolution.backgroundColour = menuBackgroundColour
stepResolution.textColour = menuTextColour
stepResolution.arrowColour = menuArrowColour
stepResolution.outlineColour = menuOutlineColour

local directionProbability = sequencerPanel:NumBox("PartDirectionProbability", 0, 0, 100, true)
directionProbability.displayName = "Backward"
directionProbability.tooltip = "Backward probability amount"
directionProbability.unit = Unit.Percent
directionProbability.x = stepResolution.x + stepResolution.width + 5
directionProbability.y = playMode.y
directionProbability.width = 110
directionProbability.height = playMode.height

local ratchetMax = sequencerPanel:NumBox("SubdivisionMax", 4, 2, 16, true)
ratchetMax.displayName = "Subdivision Max"
ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
ratchetMax.backgroundColour = menuBackgroundColour
ratchetMax.textColour = menuTextColour
ratchetMax.arrowColour = menuArrowColour
ratchetMax.outlineColour = menuOutlineColour
ratchetMax.width = 150
ratchetMax.height = playMode.height
ratchetMax.x = directionProbability.x + directionProbability.width + 5
ratchetMax.y = playMode.y
ratchetMax.changed = function(self)
  for i=1,numParts do
    seqRatchetTable = paramsPerPart[i].seqRatchetTable
    for j=1, seqRatchetTable.length do
      if seqRatchetTable:getValue(j) > self.value then
        seqRatchetTable:setValue(j, self.value)
      end
    end
    seqRatchetTable:setRange(1, self.value)
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
  seqVelTable.height = tableHeight * 0.23
  seqVelTable.x = tableX
  seqVelTable.y = seqPitchTable.y + seqPitchTable.height + 2
  
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
  seqGateTable.height = tableHeight * 0.23
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

  local numBoxHeight = 25
  local numBoxSpacing = 3

  local activeButton = sequencerPanel:OnOffButton("ActiveButtonOnOff" .. i, (i == 1))
  activeButton.persistent = false
  activeButton.displayName = "Playing"
  activeButton.tooltip = "Shows the playing part - click to manually trigger"
  activeButton.backgroundColourOff = "#ff084486"
  activeButton.backgroundColourOn = "#ff02ACFE"
  activeButton.textColourOff = "#ff22FFFF"
  activeButton.textColourOn = "#efFFFFFF"
  activeButton.fillColour = "#dd000061"
  activeButton.x = tableX + tableWidth + 10
  activeButton.y = positionTable.y
  activeButton.size = {100,numBoxHeight}
  activeButton.changed = function(self)
    if self.value == true then
      for pt=1, numParts do
        if pt ~= i then
          paramsPerPart[pt].activeButton:setValue(false)
        end
      end
    end
  end

  local octaveOffset = sequencerPanel:NumBox("OctaveOffset" .. i, 0, -2, 2, true)
  octaveOffset.displayName = "Octave"
  octaveOffset.tooltip = "Set the octave offset for this part"
  octaveOffset.x = activeButton.x
  octaveOffset.y = activeButton.y + activeButton.height + numBoxSpacing
  octaveOffset.size = {100,numBoxHeight}

  local pitchRand = sequencerPanel:NumBox("PitchOffsetRandomization" .. i, 0, 0, 100, true)
  pitchRand.displayName = "Pitch"
  pitchRand.tooltip = "Set probability pitch from another step will be used"
  pitchRand.unit = Unit.Percent
  pitchRand.size = octaveOffset.size
  pitchRand.x = octaveOffset.x
  pitchRand.y = octaveOffset.y + octaveOffset.height + numBoxSpacing

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.unit = Unit.Percent
  velRand.size = pitchRand.size
  velRand.x = pitchRand.x
  velRand.y = pitchRand.y + pitchRand.height + numBoxSpacing
  
  local gateRand = sequencerPanel:NumBox("GateRandomization" .. i, 0, 0, 100, true)
  gateRand.displayName = "Gate"
  gateRand.tooltip = "Gate radomization amount"
  gateRand.unit = Unit.Percent
  gateRand.size = velRand.size
  gateRand.x = velRand.x
  gateRand.y = velRand.y + velRand.height + numBoxSpacing

  local ratchetRand = sequencerPanel:NumBox("SubdivisionRandomization" .. i, 0, 0, 100, true)
  ratchetRand.displayName = "Subdivision"
  ratchetRand.tooltip = "Subdivision radomization amount"
  ratchetRand.unit = Unit.Percent
  ratchetRand.size = gateRand.size
  ratchetRand.x = gateRand.x
  ratchetRand.y = gateRand.y + gateRand.height + numBoxSpacing

  local leftButtonSpacing = 5

  table.insert(paramsPerPart, {activeButton=activeButton,octaveOffset=octaveOffset,pitchRand=pitchRand,velRand=velRand,gateRand=gateRand,ratchetRand=ratchetRand,triggerNote=triggerNote,positionTable=positionTable,seqPitchTable=seqPitchTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,seqRatchetTable=seqRatchetTable})
  tableY = tableY + tableHeight + 25
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(partIndex)
  local index = 0
  local partDirectionBackward = false
  while isPlaying do
    local note = nil
    local offset = 0
    local numStepsInPart = numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local activePart = partIndex

    --print("Active part before", activePart)

    -- Check if part was manually changed
    for i=1,numParts do
      if paramsPerPart[i].activeButton.value == true then
        activePart = i
        break
      end
    end
  
    -- Change active part by random (if not changed by button)
    if activePart == partIndex and getRandomBoolean(jumpProbability.value) == true then
      activePart = getRandom(numParts)
    end

    if currentPosition == 1 then
      -- Set direction for this round
      partDirectionBackward = getRandomBoolean(directionProbability.value)
      --print("directionProbability/partIndex/partDirectionBackward", directionProbability.value, partIndex, partDirectionBackward)
    end

    partIndex = activePart
    for i=1,numParts do
      paramsPerPart[i].activeButton:setValue(activePart == i)
    end

    --print("Active part after activePart/partIndex", activePart, partIndex)

    -- Check for held notes
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

    -- Flip position if playing backwards
    local startStep = 1
    if partDirectionBackward == true then
      local endStep = startStep + numStepsInPart - 1
      local diff = currentPosition - startStep
      currentPosition = endStep - diff
      print("startStep/endStep/diff/currentPosition", startStep, endStep, diff, currentPosition)
    end

    -- UPDATE STEP POSITION TABLE
    for i,v in ipairs(paramsPerPart) do
      for j=1,numStepsInPart do
        if i == partIndex and j == currentPosition then
          v.positionTable:setValue(j, 1)
        else
          v.positionTable:setValue(j, 0)
        end
      end
    end

    -- Tables for current step position
    local seqPitchTable = paramsPerPart[partIndex].seqPitchTable
    local seqVelTable = paramsPerPart[partIndex].seqVelTable
    local seqGateTable = paramsPerPart[partIndex].seqGateTable
    local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
    
    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local gate = seqGateTable:getValue(currentPosition) -- get trigger probability
    local ratchet = seqRatchetTable:getValue(currentPosition) -- get ratchet

    -- Get randomization amounts
    local gateRandomizationAmount = paramsPerPart[partIndex].gateRand.value
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
    local pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    local ratchetRandomizationAmount = paramsPerPart[partIndex].ratchetRand.value

    -- Randomize ratchet
    if getRandomBoolean(ratchetRandomizationAmount) then
      local min = seqRatchetTable.min
      local max = seqRatchetTable.max
      ratchet = getRandom(min, max)
      print("Randomize ratchet, min/max/ratchet", min, max, ratchet)
    end

    -- Randomize gate
    if getRandomBoolean(gateRandomizationAmount) then
      gate = randomizeValue(gate, seqGateTable.min, seqGateTable.max, gateRandomizationAmount)
    end

    -- Check if step should trigger
    local shouldTrigger = gate > 0

    -- Get step duration
    local stepDuration = getResolution(stepResolution.value) / ratchet

    -- Find note to play
    if playMode.value == 1 then
      -- Mono (Last held)
      note = heldNotes[#heldNotes].note
    elseif playMode.value == 2 then
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
      -- Add a failsafe in case #heldNotes has changed since setting index
      if heldNoteIndex > #heldNotes then
        heldNoteIndex = #heldNotes
      end
      note = heldNotes[heldNoteIndex].note
    elseif playMode.value == 3 then
      -- Random
      note = heldNotes[getRandom(#heldNotes)].note
    end

    -- Play subdivision
    for ratchetIndex=1, ratchet do
      -- Randomize velocity
      if getRandomBoolean(velocityRandomizationAmount) then
        vel = randomizeValue(vel, seqVelTable.min, seqVelTable.max, velocityRandomizationAmount)
      end

      -- Check for pitch change randomization
      if getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      pitchAdjustment = pitchAdjustment + (paramsPerPart[partIndex].octaveOffset.value * 12)

      if shouldTrigger then
        local duration = beat2ms(getPlayDuration(stepDuration, gate)) - 1 -- Make sure note is not played into the next
        playNote((note + pitchAdjustment), vel, duration, nil, channel)
        print("Playing note/vel/gate/ratchet/stepDuration/currentPosition/partIndex", note, vel, gate, ratchet, stepDuration, currentPosition, partIndex)
      end

      -- WAIT FOR NEXT BEAT
      wait(beat2ms(stepDuration) - offset)
      offset = 0 -- Reset offset
    end
    -- END SUBDIVISION LOOP

    -- Increment position
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
-- Functions
--------------------------------------------------------------------------------

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

function setNumSteps()
  local numSteps = numStepsBox.value
  for i=1,numParts do
    paramsPerPart[i].positionTable.length = numSteps
    paramsPerPart[i].seqPitchTable.length = numSteps
    paramsPerPart[i].seqVelTable.length = numSteps
    paramsPerPart[i].seqGateTable.length = numSteps
    paramsPerPart[i].seqRatchetTable.length = numSteps
  end
end

function startPlaying()
  if isPlaying == true then
    return
  end
  local partIndex = 1
  for i=1,numParts do
    if paramsPerPart[i].activeButton.value == true then
      partIndex = i
      break
    end
  end
  print("Start playing", partIndex)
  spawn(arpeg, partIndex)
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
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqPitchTableData = {}
  local seqVelTableData = {}
  local seqGateTableData = {}
  local seqRatchetTableData = {}

  for i=1, numParts do
    table.insert(numStepsData, numStepsBox.value)
    for j=1, numStepsBox.value do
      table.insert(seqPitchTableData, paramsPerPart[i].seqPitchTable:getValue(j))
      table.insert(seqVelTableData, paramsPerPart[i].seqVelTable:getValue(j))
      table.insert(seqGateTableData, paramsPerPart[i].seqGateTable:getValue(j))
      table.insert(seqRatchetTableData, paramsPerPart[i].seqRatchetTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqPitchTableData)
  table.insert(data, seqVelTableData)
  table.insert(data, seqGateTableData)
  table.insert(data, seqRatchetTableData)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqPitchTableData = data[2]
  local seqVelTableData = data[3]
  local seqGateTableData = data[4]
  local seqRatchetTableData = data[5]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].seqVelTable.length = v
    paramsPerPart[i].seqGateTable.length = v
    paramsPerPart[i].seqRatchetTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].seqVelTable:setValue(j, seqVelTableData[dataCounter])
      paramsPerPart[i].seqGateTable:setValue(j, seqGateTableData[dataCounter])
      paramsPerPart[i].seqRatchetTable:setValue(j, seqRatchetTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
end
