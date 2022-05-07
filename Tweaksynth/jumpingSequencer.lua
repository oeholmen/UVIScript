--------------------------------------------------------------------------------
-- Jumping Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local heldNotes = {}
local paramsPerPart = {}
local heldNoteIndex = 0 -- Counter for held notes (used by As Played seq mode)
local numParts = 3
local seen = {}
local isPlaying = false
local title = "Jumping Sequencer"

setBackgroundColour("#2c2c2c")


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

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------
local tableX = 0
local tableY = 35
local tableWidth = 590
local tableHeight = 120

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
holdButton.size = {102,22}
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

local ratchetMax = sequencerPanel:NumBox("SubdivisionMax", 4, 2, 16, true)
ratchetMax.displayName = "Subdivision Max"
ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
ratchetMax.backgroundColour = menuBackgroundColour
ratchetMax.textColour = menuTextColour
ratchetMax.arrowColour = menuArrowColour
ratchetMax.outlineColour = menuOutlineColour
ratchetMax.width = 150
ratchetMax.height = playMode.height
ratchetMax.x = stepResolution.x + stepResolution.width + 5
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
  positionTable.height = 3
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
  seqPitchTable.height = tableHeight * 0.4
  seqPitchTable.x = tableX
  seqPitchTable.y = positionTable.y + positionTable.height + 2

  --[[ local tieStepTable = sequencerPanel:Table("TieStep" .. i, 8, 0, 0, 1, true)
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
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2 ]]

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
  seqVelTable.height = tableHeight * 0.25
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
  seqGateTable.height = tableHeight * 0.25
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
  seqRatchetTable.height = tableHeight * 0.1
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

  --[[ local tieRand = sequencerPanel:NumBox("TieRandomization" .. i, 0, 0, 100, true)
  tieRand.displayName = "Tie"
  tieRand.tooltip = "Amount of radomization applied to ties for selected part"
  tieRand.unit = Unit.Percent
  tieRand.size = directionProbability.size
  tieRand.x = directionProbability.x
  tieRand.y = pitchRand.y + pitchRand.height + numBoxSpacing ]]

  local velRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
  velRand.displayName = "Velocity"
  velRand.tooltip = "Velocity radomization amount"
  velRand.unit = Unit.Percent
  velRand.size = directionProbability.size
  velRand.x = directionProbability.x
  velRand.y = pitchRand.y + pitchRand.height + numBoxSpacing
  
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

  local leftButtonSpacing = 5

  local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
  channelBox.visible = false -- disabled for now
  channelBox.displayName = "Channel"
  channelBox.tooltip = "Midi channel that receives trigger from this part. 0 = omni"
  channelBox.backgroundColour = menuBackgroundColour
  channelBox.textColour = menuTextColour
  channelBox.arrowColour = menuArrowColour
  channelBox.outlineColour = menuOutlineColour
  --channelBox.width = numStepsBox.width
  --channelBox.height = numStepsBox.height
  --channelBox.x = 0
  --channelBox.y = ratchetMax.y + ratchetMax.height + leftButtonSpacing

  table.insert(paramsPerPart, {active=(i==1),pitchRand=pitchRand,velRand=velRand,gateRand=gateRand,ratchetRand=ratchetRand,triggerNote=triggerNote,channelBox=channelBox,positionTable=positionTable,seqPitchTable=seqPitchTable,seqVelTable=seqVelTable,seqGateTable=seqGateTable,seqRatchetTable=seqRatchetTable,directionProbability=directionProbability})
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
    local isPartActive = false
    local offset = 0
    local numStepsInPart = numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local channel = paramsPerPart[partIndex].channelBox.value
    print("Playing currentPosition/part/channel", currentPosition, partIndex, channel)
    if channel == 0 then
      channel = nil -- Ignore channel
    end

    if #seen == 0 and getRandomBoolean(jumpProbability.value) == true then
      -- Change active part
      print("Change active part before", partIndex)
      local activePart = getRandom(numParts)
      for i=1,numParts do
        paramsPerPart[i].active = activePart == i
      end
      print("Change active part after activePart/partIndex", activePart, partIndex)
    end

    table.insert(seen, partIndex)
    local buffer = 1
    while isPlaying and #seen < numParts do
      wait(buffer)
      print("Waiting for parts, offset/#seen/partIndex", offset, #seen, partIndex)
      offset = offset + buffer
    end

    if #seen == 4 then
      wait(buffer)
      seen = {}
      offset = offset + buffer
    end

    isPartActive = paramsPerPart[partIndex].active and #heldNotes > 0
    if isPartActive then
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

      print("note ready, partIndex", note, partIndex)
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
    --local tieStepTable = paramsPerPart[partIndex].tieStepTable
    local seqVelTable = paramsPerPart[partIndex].seqVelTable
    local seqGateTable = paramsPerPart[partIndex].seqGateTable
    local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
    
    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    --local tieNext = tieStepTable:getValue(currentPosition)
    local vel = seqVelTable:getValue(currentPosition) -- get velocity
    local gate = seqGateTable:getValue(currentPosition) -- get trigger probability
    local ratchet = seqRatchetTable:getValue(currentPosition) -- get ratchet

    -- Get randomization amounts
    local gateRandomizationAmount = paramsPerPart[partIndex].gateRand.value
    local velocityRandomizationAmount = paramsPerPart[partIndex].velRand.value
    local pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    --local tieRandomizationAmount = paramsPerPart[partIndex].tieRand.value
    local ratchetRandomizationAmount = paramsPerPart[partIndex].ratchetRand.value

    -- Randomize ratchet
    if getRandomBoolean(ratchetRandomizationAmount) then
      local min = seqRatchetTable.min
      local max = seqRatchetTable.max
      --local max = math.min(seqRatchetTable.max, (math.ceil(seqRatchetTable.max * (ratchetRandomizationAmount/100)) + 1))
      ratchet = getRandom(min, max)
      print("Randomize ratchet, min/max/ratchet", min, max, ratchet)
    end

    -- Check if tie from previous step
    --[[ local tieStepPos = currentPosition - 1
    if partDirectionBackward == true then
      tieStepPos = currentPosition + 1
    end
    print("tieStepPos", tieStepPos) ]]

    -- Hold the number of steps the note in this position should play
    local noteSteps = 1

    -- Randomize ties
    --[[ if currentPosition < numStepsInPart and getRandomBoolean(tieRandomizationAmount) then
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
    end ]]

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
    if getRandomBoolean(gateRandomizationAmount) then
      local changeMax = math.ceil(seqGateTable.max * (gateRandomizationAmount/100))
      local min = gate - changeMax
      local max = gate + changeMax
      if min < seqGateTable.min then
        min = seqGateTable.min
      end
      if max > seqGateTable.max then
        max = seqGateTable.max
      end
      gate = getRandom(min, max)
    end

    -- Check if step should trigger
    local shouldTrigger = gate > 0

    -- Get step duration
    local stepDuration = (getResolution(stepResolution.value) * noteSteps) / ratchet

    -- Play subdivision
    for ratchetIndex=1, ratchet do
      if #heldNotes == 0 then
        stopPlaying()
        break
      end
      -- Randomize velocity
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
      end

      -- Check for pitch change randomization
      if getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      if isPartActive and shouldTrigger then
        local duration = beat2ms(stepDuration * (gate / 100)) - 1 -- Make sure note is not played into the next
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
    paramsPerPart[i].tieStepTable.length = numSteps
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
    table.insert(numStepsData, numStepsBox.value)
    for j=1, numStepsBox.value do
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
    numStepsBox:setValue(v)
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
