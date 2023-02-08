--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local limitRange = limitMax - limitMin
    local changeMax = getChangeMax(limitRange, randomizationAmount)
    local min = math.max(limitMin, (value - changeMax))
    local max = math.min(limitMax, (value + changeMax))
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

local function round(value)
  local int, frac = math.modf(value)
  --print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  --print("getRandomFromTable index, value", index, value)
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
      --print("getRandomFromTable except, maxRounds", except, maxRounds)
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function inc(val, inc, max, reset)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(reset) ~= "number" then
    reset = 1
  end
  val = val + inc
  if type(max) == "number" and val > max then
    val = reset
  end
  return val
end

local gem = {
  inc = inc,
  round = round,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

local function getDotted(value)
  return value * 1.5
end

local function getTriplet(value)
  return value / 3
end

-- NOTE: Make sure resolutionValues and resolutionNames are in sync
local resolutionValues = {
  128, -- "32x" -- 1
  64, -- "16x" -- 2
  32, -- "8x" -- 3
  28, -- "7x" -- 4
  24, -- "6x" -- 5
  20, -- "5x" -- 6
  16, -- "4x" -- 7
  12, -- "3x" -- 8
  8, -- "2x" -- 9
  6, -- "1/1 dot" -- 10
  4, -- "1/1" -- 11
  3, -- "1/2 dot" -- 12
  getTriplet(8), -- "1/1 tri" -- 13
  2, -- "1/2" -- 14
  getDotted(1), -- "1/4 dot", -- 15
  getTriplet(4), -- "1/2 tri", -- 16
  1, -- "1/4", -- 17
  getDotted(0.5), -- "1/8 dot", -- 18
  getTriplet(2), -- "1/4 tri", -- 19
  0.5,  -- "1/8", -- 20
  getDotted(0.25), -- "1/16 dot", -- 21
  getTriplet(1), -- "1/8 tri", -- 22
  0.25, -- "1/16", -- 23
  getDotted(0.125), -- "1/32 dot", -- 24
  getTriplet(0.5), -- "1/16 tri", -- 25
  0.125, -- "1/32" -- 26
  getDotted(0.0625), -- "1/64 dot", -- 27
  getTriplet(0.25), -- "1/32 tri", -- 28
  0.0625, -- "1/64", -- 29
  getDotted(0.03125), -- "1/128 dot" -- 30
  getTriplet(0.125), -- "1/64 tri" -- 31
  0.03125 -- "1/128" -- 32
}

local resolutionNames = {
  "32x", -- 1
  "16x", -- 2
  "8x", -- 3
  "7x", -- 4
  "6x", -- 5
  "5x", -- 6
  "4x", -- 7
  "3x", -- 8
  "2x", -- 9
  "1/1 dot", -- 10
  "1/1", -- 11
  "1/2 dot", -- 12
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/4 dot", -- 15
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/8 dot", -- 18
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/16 dot", -- 21
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/32 dot", -- 24
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/64 dot", -- 27
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/128 dot", -- 30
  "1/64 tri", -- 31
  "1/128" -- 32
}

local resolutions = {
  getDotted = getDotted,
  
  getTriplet = getTriplet,
  
  getEvenFromDotted = function(value)
    return value / 1.5
  end,
  
  getEvenFromTriplet = function(value)
    return value * 3
  end,
  
  getResolution = function(i)
    return resolutionValues[i]
  end,
  
  getResolutions = function()
    return resolutionValues
  end,
  
  getResolutionName = function(i)
    return resolutionNames[i]
  end,
  
  getResolutionNames = function(options, max)
    if type(max) ~= "number" then
      max = #resolutionNames
    end
  
    local res = {}
  
    for _,r in ipairs(resolutionNames) do
      table.insert(res, r)
      if i == max then
        break
      end
    end
  
    -- Add any options
    if type(options) == "table" then
      for _,o in ipairs(options) do
        table.insert(res, o)
      end
    end
  
    return res
  end,
  
  getResolutionsByType = function(maxResolutionIndex)
    if type(maxResolutionIndex) == "nil" then
      maxResolutionIndex = #resolutionValues
    end
    local startPosIndex = 11
    local resOptions = {}
    -- Create table of resolution indexes by type (1=even,2=dot,3=tri)
    for i=startPosIndex,startPosIndex+2 do
      local resolutionIndex = i
      local resolutionsOfType = {}
      while resolutionIndex <= maxResolutionIndex do
        table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
        --print("Insert resolutionIndex", resolutionIndex)
        resolutionIndex = resolutionIndex + 3 -- increment index
      end
      --print("#resolutionsOfType, i", #resolutionsOfType, i)
      table.insert(resOptions, resolutionsOfType)
    end
    -- Add the resolutions that are whole numbers (1,2,3,4...)
    local slowResolutions = {}
    for i,resolution in ipairs(resolutionValues) do
      if resolution % 1 == 0 then
        table.insert(slowResolutions, i)
        --print("getResolutionsByType - included slow resolution", resolution)
      end
    end
    --print("#slowResolutions", #slowResolutions)
    table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
    --print("resOptions", #resOptions)
    return resOptions
  end,
  
  getPlayDuration = function(duration, gate)
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

--------------------------------------------------------------------------------
-- A sequencer sending script event modulation in broadcast mode
--------------------------------------------------------------------------------




local isAutoPlayActive = false
local heldNotes = {}

outlineColour = "#FFB5FF"
menuBackgroundColour = "#bf01011F"
menuTextColour = "#9f02ACFE"
menuArrowColour = "#9f09A3F4"
menuOutlineColour = "#00000000"
pageBackgoundColour = "222222"

if type(numParts) == "nil" then
  numParts = 1
end

if type(maxPages) == "nil" then
  maxPages = 8
end

if type(title) == "nil" then
  title = "Modulation Sequencer"
end

if type(tooltip) == "nil" then
  tooltip = "A sequencer sending script event modulation in broadcast mode"
end

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Include common functions and widgets
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local sourceIndex = modseq.headerPanel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.displayName = "Event Id"
sourceIndex.backgroundColour = menuBackgroundColour
sourceIndex.textColour = menuTextColour
sourceIndex.size = {102,22}
sourceIndex.x = modseq.autoplayButton.x - modseq.autoplayButton.width - 5
sourceIndex.y = modseq.autoplayButton.y

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 9
  local inputWidgetSize = {90,20}
  local defaultSteps = 16

  if numParts == 1 then
    tableHeight = tableHeight * 2
  end

  local sequencerPanel = Panel("SequencerPage" .. page)
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = numParts * (tableHeight + 30 + buttonRowHeight)

  for part=1,numParts do
    local isVisible = true
    local i = modseq.getPartIndex(part, page)
    print("Set paramsPerPart, page/part", page, i)

    -- Tables

    local positionTable = sequencerPanel:Table("Position" .. i, defaultSteps, 0, 0, 1, true)
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

    local seqValueTable = sequencerPanel:Table("ModulationValue" .. i, defaultSteps, 0, 0, 100)
    seqValueTable.visible = isVisible
    seqValueTable.displayName = "Velocity"
    seqValueTable.tooltip = "Velocity for this step"
    seqValueTable.showPopupDisplay = true
    seqValueTable.showLabel = false
    seqValueTable.fillStyle = "solid"
    seqValueTable.sliderColour = "#9f09A3F4"
    if i % 2 == 0 then
      seqValueTable.backgroundColour = "#3f000000"
    else
      seqValueTable.backgroundColour = "#3f000000"
    end
    seqValueTable.width = tableWidth
    seqValueTable.height = tableHeight
    seqValueTable.x = tableX
    seqValueTable.y = positionTable.y + positionTable.height + 2
    
    local smoothStepTable = sequencerPanel:Table("SmoothStep" .. i, defaultSteps, 0, 0, 100, true)
    smoothStepTable.visible = isVisible
    smoothStepTable.tooltip = "Smooth transition to next step (overrides global smoothing for this step)"
    smoothStepTable.fillStyle = "solid"
    if i % 2 == 0 then
      smoothStepTable.backgroundColour = "#3f606060"
    else
      smoothStepTable.backgroundColour = "#3f606060"
    end
    smoothStepTable.showLabel = false
    smoothStepTable.sliderColour = "#3f339900"
    smoothStepTable.width = tableWidth
    smoothStepTable.height = 30
    smoothStepTable.x = tableX
    smoothStepTable.y = seqValueTable.y + seqValueTable.height + 2

    local inputWidgetY = smoothStepTable.y + smoothStepTable.height + 5

    -- Inputs

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {53,20}
    stepButton.x = 0
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the round (or step) resolution"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 11
    stepResolution.x = stepButton.x + stepButton.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = {60,20}
    stepResolution.backgroundColour = menuBackgroundColour
    stepResolution.textColour = menuTextColour
    stepResolution.arrowColour = menuArrowColour
    stepResolution.outlineColour = menuOutlineColour
    stepResolution.changed = function(self)
      modseq.setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = menuBackgroundColour
    numStepsBox.textColour = menuTextColour
    numStepsBox.arrowColour = menuArrowColour
    numStepsBox.outlineColour = menuOutlineColour
    numStepsBox.size = {80,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      setNumSteps(i, self.value)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Value Rand"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = menuBackgroundColour
    valueRandomization.textColour = menuTextColour
    valueRandomization.arrowColour = menuArrowColour
    valueRandomization.outlineColour = menuOutlineColour
    valueRandomization.size = {150,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local smoothRandomization = sequencerPanel:NumBox("SmoothRandomization" .. i, 0, 0, 100, true)
    smoothRandomization.displayName = "Smooth Rand"
    smoothRandomization.tooltip = "Level of randomization applied to smooth level"
    smoothRandomization.unit = Unit.Percent
    smoothRandomization.visible = isVisible
    smoothRandomization.backgroundColour = menuBackgroundColour
    smoothRandomization.textColour = menuTextColour
    smoothRandomization.arrowColour = menuArrowColour
    smoothRandomization.outlineColour = menuOutlineColour
    smoothRandomization.size = {150,20}
    smoothRandomization.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    smoothRandomization.y = inputWidgetY

    local smoothInput = sequencerPanel:NumBox("GlobalSmooth" .. i, 0, 0, 100, true)
    smoothInput.displayName = "Smooth"
    smoothInput.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothInput.unit = Unit.Percent
    smoothInput.visible = isVisible
    smoothInput.backgroundColour = menuBackgroundColour
    smoothInput.textColour = menuTextColour
    smoothInput.arrowColour = menuArrowColour
    smoothInput.outlineColour = menuOutlineColour
    smoothInput.size = {100,20}
    smoothInput.x = smoothRandomization.x + smoothRandomization.width + buttonSpacing
    smoothInput.y = inputWidgetY

    local bipolarButton = sequencerPanel:OnOffButton("Bipolar" .. i, false)
    bipolarButton.displayName = "Bipolar"
    bipolarButton.visible = isVisible
    bipolarButton.backgroundColourOff = "#ff084486"
    bipolarButton.backgroundColourOn = "#ff02ACFE"
    bipolarButton.textColourOff = "#ff22FFFF"
    bipolarButton.textColourOn = "#efFFFFFF"
    bipolarButton.size = {53,20}
    bipolarButton.x = smoothInput.x + smoothInput.width + buttonSpacing
    bipolarButton.y = inputWidgetY
    bipolarButton.changed = function(self)
      if self.value then
        seqValueTable:setRange(-100,100)
      else
        seqValueTable:setRange(0,100)
      end
    end

    table.insert(paramsPerPart, {stepButton=stepButton,smoothStepTable=smoothStepTable,smoothInput=smoothInput,valueRandomization=valueRandomization,smoothRandomization=smoothRandomization,seqValueTable=seqValueTable,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = modseq.footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = menuBackgroundColour
  minRepeats.textColour = menuTextColour
  minRepeats.arrowColour = menuArrowColour
  minRepeats.outlineColour = menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 9
  minRepeats.y = modseq.actionMenu.y

  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=nil,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(part)
  local index = 0
  while isPlaying do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = paramsPerPart[partIndex].smoothInput.value
    local step = paramsPerPart[partIndex].stepButton.value
    local duration = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local smoothStepTable = paramsPerPart[partIndex].smoothStepTable
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value
    local smoothRandomizationAmount = paramsPerPart[partIndex].smoothRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isActiveStep then
        paramsPerPart[partIndex].positionTable:setValue(i, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(i, 0)
      end
    end

    if step == false then
      duration = duration / numStepsInPart
    end

    -- Send modulation
    local smoothStepValue = smoothStepTable:getValue(currentPosition)
    if smoothStepValue > 0 then
      smooth = smoothStepValue
    end
    smooth = gem.randomizeValue(smooth, smoothStepTable.min, smoothStepTable.max, smoothRandomizationAmount)
    local rampTime = 20
    if smooth > 0 then
      rampTime = beat2ms(duration) * (smooth / 100)
    end
    local value = seqValueTable:getValue(currentPosition)
    value = gem.randomizeValue(value, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    sendScriptModulation(sourceIndex.value, (value/100), rampTime)

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  table.insert(heldNotes, voiceId)
  if #heldNotes == 1 then
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
  -- Make sure we do not stop the modulation sequencer when transport is playing
  if #heldNotes == 0 and isAutoPlayActive == false then
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    isAutoPlayActive = start
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local smoothStepTableData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
      table.insert(smoothStepTableData, v.smoothStepTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, smoothStepTableData)
  table.insert(data, modseq.labelInput.text)
  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local smoothStepTableData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqValueTable.length = v
    paramsPerPart[i].smoothStepTable.length = v
    for j=1, v do
      paramsPerPart[i].seqValueTable:setValue(j, seqValueTableData[dataCounter])
      paramsPerPart[i].smoothStepTable:setValue(j, smoothStepTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    modseq.setPageDuration(page)
  end
end