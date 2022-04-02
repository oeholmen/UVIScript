--------------------------------------------------------------------------------
-- GENEREATIVE SEQUENCER
--------------------------------------------------------------------------------

local buttonBackgroundColourOff = "#ff084486"
local buttonBackgroundColourOn = "#ff02ACFE"
local buttonTextColourOff = "#ff22FFFF"
local buttonTextColourOn = "#efFFFFFF"

local outlineColour = "#FFB5FF"
local bgColor = "00000000"
local knobColour = "#dd000061"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = bgColor

-- Helper functions

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

local selectedArpResolutions = {} -- Must be at the global level
local selectedSeqResolutions = {} -- Must be at the global level
local resolutions = {
  128, -- "32x" -- 0
  64, -- "16x" -- 1
  32, -- "8x" -- 2
  28, -- "7x" -- 3
  24, -- "6x" -- 4
  20, -- "5x" -- 5
  16, -- "4x" -- 6 <---- FROM HERE: ADD 1 to index to get arp res
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

 function getResolutionIndex(i)
  if i > #resolutions then
    -- If Random is selected, we pick one of the selected resolutions
    local activeResolutions = {}
    for j,v in ipairs(selectedSeqResolutions) do
      if v == true then
        table.insert(activeResolutions, j)
      end
    end
    if #activeResolutions > 0 then
      i = activeResolutions[getRandom(#activeResolutions)]
      print("activeResolutions", #activeResolutions, i, resolutionNames[i])
    else
      i = getRandom(#resolutions)
    end
  end
  return i
end

function getResolution(i)
  i = getResolutionIndex(i)
  print("getResolution", resolutionNames[i])
  return resolutions[i]
end

function getResolutionName(i)
  return resolutionNames[i]
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

function createSequencerPanel()
  local arpId = 0
  local partToStepMap = {1} -- Holds the starting step for each part
  local velocityRandomizationAmount = 0
  local gateRandomizationAmount = 0
  local partRandomizationAmount = 0
  local baseNoteProbability = 0
  local totalNumSteps = 0
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
  
  local sequencerPanel = Panel("Sequencer")
  sequencerPanel.backgroundColour = bgColor
  sequencerPanel.x = 10
  sequencerPanel.y = 10
  sequencerPanel.width = 700
  sequencerPanel.height = 330

  local partsTable = sequencerPanel:Table("Parts", 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  partsTable.backgroundColour = menuArrowColour
  partsTable.sliderColour = outlineColour
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

  local numPartsBox = sequencerPanel:NumBox("Parts", 1, 1, 8, true)
  numPartsBox.tooltip = "The Number of parts in the sequence"
  numPartsBox.backgroundColour = menuBackgroundColour
  numPartsBox.textColour = menuTextColour
  numPartsBox.arrowColour = menuArrowColour
  numPartsBox.outlineColour = menuOutlineColour
  numPartsBox.size = {120,30}
  numPartsBox.x = 500
  numPartsBox.y = 290

  function clearPosition()
    for i=1, totalNumSteps do
      positionTable:setValue(i, 0)
    end
    for i=1, totalNumSteps do
      partsTable:setValue(i, 0)
    end
  end

  local holdButton = sequencerPanel:OnOffButton("HoldOnOff", false)
  holdButton.backgroundColourOff = buttonBackgroundColourOff
  holdButton.backgroundColourOn = buttonBackgroundColourOn
  holdButton.textColourOff = buttonTextColourOff
  holdButton.textColourOn = buttonTextColourOn
  holdButton.displayName = "Hold"
  holdButton.fillColour = knobColour
  holdButton.size = {50,30}
  holdButton.x = 650
  holdButton.y = 290
  holdButton.changed = function(self)
    if self.value == false then
      heldNotes = {}
      clearPosition()
      arpId = arpId + 1
    end
  end

  local seqVelTable = sequencerPanel:Table("Velocity", totalNumSteps, 100, 1, 127, true)
  seqVelTable.tooltip = "Set step velocity. Randomization available in settings."
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "solid"
  seqVelTable.sliderColour = menuArrowColour
  seqVelTable.width = positionTable.width
  seqVelTable.height = 70
  seqVelTable.x = positionTable.x
  seqVelTable.y = 130

  local seqGateTable = sequencerPanel:Table("Gate", totalNumSteps, 100, 0, 100, true)
  seqGateTable.tooltip = "Set step gate length. Randomization available in settings."
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "solid"
  seqGateTable.sliderColour = menuArrowColour
  seqGateTable.width = seqVelTable.width
  seqGateTable.height = 70
  seqGateTable.x = seqVelTable.x
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 5

  -- Handle keys
  local generateKey = sequencerPanel:Menu("GenerateKey", notenames)
  generateKey.displayName = "Key"
  generateKey.visible = false
  generateKey.width = 150
  generateKey.x = 200
  generateKey.y = positionTable.y + positionTable.height + 5
  generateKey.backgroundColour = menuBackgroundColour
  generateKey.textColour = menuTextColour
  generateKey.arrowColour = menuArrowColour
  generateKey.outlineColour = menuOutlineColour

  -- Handle scales
  local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}, {5,2,5}, {7,5}, {3}, {5}, {7}}
  local paramsPerPart = {}
  local partSelect = {}
  for i=1,numPartsBox.value do
    table.insert(partSelect, "Part " .. i)
  end

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
      v.noteStartStep.visible = isVisible
    end
  end

  numPartsBox.changed = function(self)
    for i=1, self.value do
      setNumSteps(i)
    end
    --partsTable.length = self.value

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
        paramsPerPart[i].noteStartStep.value = prev.noteStartStep.value
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

  local velRandKnob = sequencerPanel:Knob("VelocityRandomization", 0, 0, 1)
  velRandKnob.displayName = "Velocity"
  velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandKnob.unit = Unit.PercentNormalized
  velRandKnob.width = 100
  velRandKnob.x = 0
  velRandKnob.y = seqGateTable.y + seqGateTable.height + 5
  velRandKnob.changed = function(self)
    velocityRandomizationAmount = self.value
  end

  local gateRandKnob = sequencerPanel:Knob("GateRandomization", 0, 0, 1)
  gateRandKnob.displayName = "Gate"
  gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandKnob.unit = Unit.PercentNormalized
  gateRandKnob.width = 100
  gateRandKnob.x = velRandKnob.x + velRandKnob.width + 20
  gateRandKnob.y = seqGateTable.y + seqGateTable.height + 5
  gateRandKnob.changed = function(self)
    gateRandomizationAmount = self.value
  end

  local partRandKnob = sequencerPanel:Knob("PartRandomization", 0, 0, 100, true)
  partRandKnob.displayName = "Part"
  partRandKnob.tooltip = "Amount of radomization applied to parts"
  partRandKnob.unit = Unit.Percent
  partRandKnob.width = 90
  partRandKnob.x = gateRandKnob.x + gateRandKnob.width + 20
  partRandKnob.y = seqGateTable.y + seqGateTable.height + 5
  partRandKnob.changed = function(self)
    partRandomizationAmount = self.value
  end

  local baseNoteRandKnob = sequencerPanel:Knob("BaseNoteProbability", 0, 0, 100, true)
  baseNoteRandKnob.displayName = "Base note"
  baseNoteRandKnob.tooltip = "Probability that first note in part will be the base note"
  baseNoteRandKnob.unit = Unit.Percent
  baseNoteRandKnob.width = 100
  baseNoteRandKnob.x = partRandKnob.x + partRandKnob.width + 20
  baseNoteRandKnob.y = seqGateTable.y + seqGateTable.height + 5
  baseNoteRandKnob.changed = function(self)
    baseNoteProbability = self.value
  end

  function setNumSteps(index)
    local partDuration = getResolution(paramsPerPart[index].partResolution.value)
    local stepDuration = getResolution(paramsPerPart[index].stepResolution.value)
    paramsPerPart[index].numSteps = partDuration / stepDuration
    print("stepDuration/partDuration/numSteps", stepDuration,partDuration,paramsPerPart[index].numSteps)
    partToStepMap = {} -- Reset
    totalNumSteps = 0
    for i=1, numPartsBox.value do
      paramsPerPart[i].noteStartStep:setRange(1, math.ceil(paramsPerPart[i].numSteps / 2))
      table.insert(partToStepMap, (totalNumSteps + 1))
      print("Updated partToStepMap part/step", i, (totalNumSteps + 1))
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
    generateMinNoteStepsPart.width = (generatePolyphonyPart.width / 2) - 2
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
    generateMaxNoteStepsPart.x = generateMinNoteStepsPart.x + generateMinNoteStepsPart.width + 4
    generateMaxNoteStepsPart.y = generateMinNoteStepsPart.y
    generateMaxNoteStepsPart.changed = function(self)
      generateMinNoteStepsPart:setRange(1, self.value)
      generateMinNoteStepsPart.enabled = self.value > 1
    end
  
    local generateNoteStartStepPart = sequencerPanel:NumBox("GenerateNoteStartStep" .. i, 1, 1, 1, true) -- UPDATE ON numStepsBox change
    generateNoteStartStepPart.displayName = "Start notes every n-th step"
    generateNoteStartStepPart.tooltip = "The steps a note can start on"
    generateNoteStartStepPart.backgroundColour = menuBackgroundColour
    generateNoteStartStepPart.textColour = menuTextColour
    generateNoteStartStepPart.arrowColour = menuArrowColour
    generateNoteStartStepPart.outlineColour = menuOutlineColour
    generateNoteStartStepPart.visible = false
    generateNoteStartStepPart.width = generatePolyphonyPart.width
    generateNoteStartStepPart.x = generatePolyphonyPart.x
    generateNoteStartStepPart.y = generateMinNoteStepsPart.y + generateMinNoteStepsPart.height + 5

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
  
    local generateScalePart = sequencerPanel:Menu("GenerateScale" .. i, {"12 tone", "Major", "Minor", "Dorian", "Whole tone", "Major Pentatonic", "Minor Pentatonic", "1-4-5", "1-5", "Dim", "Fours", "Fives"})
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

    local partResolution = sequencerPanel:Menu("PartDuration" .. i, getResolutionNames())
    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())

    partResolution.displayName = "Part Duration"
    partResolution.tooltip = "Set the duration of a part."
    partResolution.selected = 11
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

    table.insert(paramsPerPart, {polyphony=generatePolyphonyPart,partResolution=partResolution,stepResolution=stepResolution,numSteps=0,fullScale={},filteredScale={},scale=generateScalePart,key=generateKeyPart,droneLow=droneLowPart,droneHigh=droneHighPart,minNote=generateMinPart,maxNote=generateMaxPart,minNoteSteps=generateMinNoteStepsPart,maxNoteSteps=generateMaxNoteStepsPart,noteStartStep=generateNoteStartStepPart,init=i==1})

    stepResolution:changed()
  end

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
    for _,value in pairs(notesTable) do
      if value.note == note then
        return true
      end
    end
    return false
  end

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
      print("currentPosition", currentPosition)
      -- Set part position
      local startOfPart = false
      for pp,sp in ipairs(partToStepMap) do
        if sp == currentPosition then
          currentPartPosition = pp
          print("Set currentPartPosition", currentPartPosition)
          startOfPart = true
          break
        end
      end
      local numStepsInPart = paramsPerPart[currentPartPosition].numSteps
      --local currentPartPosition = math.floor(index / numStepsInPart) + 1 -- 5 / 4 = 1.25 = 1 + 1 = 2

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

      -- Randomize select parameters for each round
      if currentStep == 1 then
        -- Randomize gate within the set limit
        if gateRandomizationAmount > 0 then
          --print("gateRandomizationAmount", gateRandomizationAmount)
          local changeMax = math.ceil(seqGateTable.max * gateRandomizationAmount)
          --print("seqGateTable.min", seqGateTable.min)
          --print("seqGateTable.max", seqGateTable.max)
          --print("changeMax", changeMax)
          for i=1,numStepsInPart do
            if getRandomBoolean() then
              local currentVal = seqGateTable:getValue(i)
              --print("currentVal", currentVal)
              local min = currentVal - changeMax
              local max = currentVal + changeMax
              if min < seqGateTable.min then
                min = seqGateTable.min
              end
              if max > seqGateTable.max then
                max = seqGateTable.max
              end
              --print("seqGateTable:setValue(i, getRandom(min, max))", i, min, max)
              seqGateTable:setValue(i, getRandom(min, max))
            end
          end
        end
        -- Randomize vel within the set limit
        if velocityRandomizationAmount > 0 then
          --print("velocityRandomizationAmount", velocityRandomizationAmount)
          local changeMax = math.ceil(seqVelTable.max * velocityRandomizationAmount)
          --print("seqVelTable.min", seqVelTable.min)
          --print("seqVelTable.max", seqVelTable.max)
          --print("changeMax", changeMax)
          for i=1,numStepsInPart do
            if getRandomBoolean() then
              local currentVal = seqVelTable:getValue(i)
              --print("currentVal", currentVal)
              local min = currentVal - changeMax
              local max = currentVal + changeMax
              if min < seqVelTable.min then
                min = seqVelTable.min
              end
              if max > seqVelTable.max then
                max = seqVelTable.max
              end
              --print("seqVelTable:setValue(i, getRandom(min, max))", i, min, max)
              seqVelTable:setValue(i, getRandom(min, max))
            end
          end
        end
      end

      -- Set values pt 2
      local vel = seqVelTable:getValue(currentPosition) -- get velocity
      local gate = seqGateTable:getValue(currentPosition) / 100 -- get gate

      local shouldAddNote = (currentPosition - 1) % paramsPerPart[currentPartPosition].noteStartStep.value == 0

      -- If gate is zero no notes will play on this step
      if gate > 0 and shouldAddNote == true then

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

        -- On step one, always the base note if probability hits (unless low drone is active)
        local isLowDroneActive = paramsPerPart[currentPartPosition].droneLow.visible and paramsPerPart[currentPartPosition].droneLow.value > 1
        if currentStep == 1 and isLowDroneActive == false and notesInclude(notes, minNote) == false and getRandomBoolean(baseNoteProbability) then
          local noteSteps = getRandom(minNoteSteps,maxNoteSteps)
          table.insert(notes, {note=minNote,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
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
        for i=1,numberOfNotes do
          local noteToPlay = generateNoteToPlay(currentPartPosition)
          if notesInclude(notes, noteToPlay) == false then
            local noteSteps = getRandom(minNoteSteps,maxNoteSteps)
            table.insert(notes, {note=noteToPlay,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
            --print("Insert to notes note/steps/gate", noteToPlay, noteSteps, gate)
          end
        end
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

  return sequencerPanel
end

createSequencerPanel()
setBackgroundColour("#4f4f4f")
makePerformanceView()