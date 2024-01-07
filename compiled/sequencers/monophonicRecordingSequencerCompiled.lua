-- sequencers/polyphonicRecordingSequencer -- 
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
  if randomizationAmount == 0 then
    return value
  end
  local limitRange = limitMax - limitMin
  local changeMax = getChangeMax(limitRange, randomizationAmount)
  local min = math.max(limitMin, (value - changeMax))
  local max = math.min(limitMax, (value + changeMax))
  return getRandom(min, max)
end

-- sign function: -1 if x<0; 1 if x>0
local function sign(x)
  if x < 0 then
    return -1
  end
  return 1
end

local function sum(t)
  local sum = 0
  for _,v in pairs(t) do -- Get the sum of all numbers in t
    sum = sum + v
  end
  return sum
end

local function avg(t)
  return sum(t) / #t
end

local function round(value)
  local int, frac = math.modf(value)
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
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
end

local function inc(val, inc, resetAt, resetTo)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(resetTo) ~= "number" then
    resetTo = 1
  end
  val = val + inc
  if type(resetAt) == "number" then
    if (inc > 0 and val > resetAt) or (inc < 0 and val < resetAt) then
      val = resetTo
    end
  end
  return val
end

local function advanceValue(bounds, value, min, max, direction)
  local valueRange = bounds.max - bounds.min
  local changeFactor = max - min
  local changePerStep = getChangePerStep(changeFactor, valueRange)

  if direction < 0 then
    changePerStep = -changePerStep
  end

  value = inc(value, changePerStep)
  if value > max then
    direction = -1
    value = max
  elseif value < min then
    direction = 1
    value = min
  end
  return value, direction
end

local function getValueOrDefault(value, default)
  if type(value) ~= "nil" then
    return value
  end
  return default
end

local function mapValueBetweenRanges(value, fromMin, fromMax, toMin, toMax)
  return ((value - fromMin) / (fromMax - fromMin)) * (toMax - toMin) + toMin
end

local gem = {
  e = 2.71828,
  inc = inc,
  avg = avg,
  sum = sum,
  sign = sign,
  round = round,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  advanceValue = advanceValue,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getChangePerStep = getChangePerStep,
  getRandomBoolean = getRandomBoolean,
  getValueOrDefault = getValueOrDefault,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
  mapValueBetweenRanges = mapValueBetweenRanges,
}

--------------------------------------------------------------------------------
-- Common functions for notes
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

local notes = {
  getNoteNames = function()
    return notenames
  end,

  getOctave = function(noteNumber)
    return math.floor(noteNumber / 12) - 2
  end,

  -- Used for mapping - does not include octave, only name of note (C, C#...)
  getNoteMapping = function()
    local noteNumberToNoteName = {}
    local notenamePos = 1
    for i=0,127 do
      table.insert(noteNumberToNoteName, notenames[notenamePos])
      notenamePos = notenamePos + 1
      if notenamePos > #notenames then
        notenamePos = 1
      end
    end
    return noteNumberToNoteName
  end,

  transpose = function(note, min, max)
    --print("Check transpose", note)
    if note < min then
      print("note < min", note, min)
      while note < min do
        note = note + 12
        print("transpose note up", note)
      end
    elseif note > max then
      print("note > max", note, max)
      while note > max do
        note = note - 12
        print("transpose note down", note)
      end
    end
    -- Ensure note is inside given min/max values
    note = math.max(min, math.min(max, note))
    -- Ensure note is inside valid values
    return math.max(0, math.min(127, note))
  end,

  getSemitonesBetweenNotes = function(note1, note2)
    return math.max(note1, note2) - math.min(note1, note1)
  end,

  getNoteAccordingToScale = function(scale, noteToPlay)
    for _,note in ipairs(scale) do
      if note == noteToPlay then
        return noteToPlay
      elseif note > noteToPlay then
        print("Change from noteToPlay to note", noteToPlay, note)
        return note
      end
    end
    return noteToPlay
  end,
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

local function getEvenFromTriplet(value)
  return value * 3
end

local function getEvenFromDotted(value)
  return value / 1.5
end

-- This variable is used by getResolutionsByType as the starting point for finding even/dot/tri resolutions
local resolutionTypeStartPosIndex = 11 -- 1/1

local function getResolutionsByType(maxResolutionIndex, includeSlowResolutions)
  if type(maxResolutionIndex) == "nil" then
    maxResolutionIndex = #resolutionValues
  end
  if type(includeSlowResolutions) == "nil" then
    includeSlowResolutions = true
  end
  local resOptions = {}
  -- Create table of resolution indexes by type (1=even,2=dot,3=tri,4=slow)
  for i=resolutionTypeStartPosIndex,resolutionTypeStartPosIndex+2 do
    local resolutionIndex = i
    local resolutionsOfType = {}
    while resolutionIndex <= maxResolutionIndex do
      table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
      --print("Insert resolutionIndex", resolutionIndex)
      resolutionIndex = gem.inc(resolutionIndex, 3) -- increment index
    end
    --print("#resolutionsOfType, i", #resolutionsOfType, i)
    table.insert(resOptions, resolutionsOfType)
  end
  -- Add the resolutions that are whole numbers (1,2,3,4...)
  if includeSlowResolutions then
    local slowResolutions = {}
    for i,resolution in ipairs(resolutionValues) do
      if resolution % 1 == 0 then
        table.insert(slowResolutions, i)
        --print("getResolutionsByType - included slow resolution", resolutionValues[i], i)
      end
    end
    --print("#slowResolutions", #slowResolutions)
    table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
  end
  --print("resOptions", #resOptions)
  return resOptions
end

local function isResolutionWithinRange(resolutionIndex, options, i)
  if resolutionIndex < options.minResolutionIndex or resolutionIndex > options.maxResolutionIndex then
    return false
  end

  if i == 2 and resolutionIndex > options.maxDotResolutionIndex then
    return false
  end

  if i == 3 and resolutionIndex > options.maxTriResolutionIndex then
    return false
  end

  return true
end

-- Returns a table of resolutions indexes that are within the given range
local function getSelectedResolutions(resolutionsByType, options)
  if type(options) == "nil" then
    options = {}
  end

  if type(options.minResolutionIndex) == "nil" then
    options.minResolutionIndex = 1
  end

  if type(options.maxResolutionIndex) == "nil" then
    options.maxResolutionIndex = #resolutionValues
  end

  if type(options.maxDotResolutionIndex) == "nil" then
    options.maxDotResolutionIndex = #resolutionValues
  end

  if type(options.maxTriResolutionIndex) == "nil" then
    options.maxTriResolutionIndex = #resolutionValues
  end

  local selectedResolutions = {}
  for i,type in ipairs(resolutionsByType) do
    for _,resolutionIndex in ipairs(type) do
      if isResolutionWithinRange(resolutionIndex, options, i) then
        table.insert(selectedResolutions, resolutionIndex)
      end
    end
  end
  return selectedResolutions
end

-- Tries to adjust the given resolution by adjusting
-- length, and/or setting a even/dot/tri value variant
-- Options are: adjustBias (0=slow -> 100=fast), doubleOrHalfProbaility, dotOrTriProbaility, selectedResolutions
local function getResolutionVariation(currentResolution, options)
  local currentIndex = gem.getIndexFromValue(currentResolution, resolutionValues)

  if type(currentIndex) == "nil" then
    return currentResolution
  end

  if type(options) == "nil" then
    options = {}
  end

  if type(options.minResolutionIndex) == "nil" then
    options.minResolutionIndex = 1
  end

  if type(options.maxResolutionIndex) == "nil" then
    options.maxResolutionIndex = #resolutionValues
  end

  if type(options.maxDotResolutionIndex) == "nil" then
    options.maxDotResolutionIndex = #resolutionValues
  end

  if type(options.maxTriResolutionIndex) == "nil" then
    options.maxTriResolutionIndex = #resolutionValues
  end

  if type(options.adjustBias) == "nil" then
    options.adjustBias = 50
  end

  if type(options.doubleOrHalfProbaility) == "nil" then
    options.doubleOrHalfProbaility = 50
  end

  if type(options.dotOrTriProbaility) == "nil" then
    options.dotOrTriProbaility = 50
  end

  local resolutionsByType = getResolutionsByType()

  if type(options.selectedResolutions) == "nil" then
    options.selectedResolutions = getSelectedResolutions(resolutionsByType, options)
  end

  -- Normalize resolution
  local resolution = currentResolution
  if gem.tableIncludes(resolutionsByType[2], currentIndex) then
    resolution = getEvenFromDotted(resolutionValues[currentIndex])
    --print("getEvenFromDotted", resolution)
  elseif gem.tableIncludes(resolutionsByType[3], currentIndex) then
    resolution = getEvenFromTriplet(resolutionValues[currentIndex])
    --print("getEvenFromTriplet", resolution)
  elseif gem.tableIncludes(resolutionsByType[1], currentIndex) or gem.tableIncludes(resolutionsByType[4], currentIndex) then
    resolution = resolutionValues[currentIndex]
    --print("getEvenOrSlow", resolution)
  end

  if type(resolution) == "number" then
    local doubleOrHalf = gem.getRandomBoolean(options.doubleOrHalfProbaility)
    -- Double (slow) or half (fast) duration
    if doubleOrHalf then
      local doubleResIndex = gem.getIndexFromValue((resolution * 2), resolutionValues)
      local halfResIndex = gem.getIndexFromValue((resolution / 2), resolutionValues)
      if gem.getRandomBoolean(options.adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, doubleResIndex) then
        resolution = resolutionValues[doubleResIndex]
        --print("Slower resolution", resolution)
      elseif type(halfResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, halfResIndex) then
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dot or tri on duration if probability hits
    if gem.getRandomBoolean(options.dotOrTriProbaility) then
      if gem.tableIncludes(resolutionsByType[3], currentIndex) then
        resolution = getTriplet(resolution)
        --print("getTriplet", resolution)
      else
        local dottedResIndex = gem.getIndexFromValue(getDotted(resolution), resolutionValues)
        if type(dottedResIndex) == "number" and gem.tableIncludes(options.selectedResolutions, dottedResIndex) then
          resolution = resolutionValues[dottedResIndex]
          --print("getDotted", resolution)
        end
      end
    end
  end
  if type(resolution) == "number" then
    currentIndex = gem.getIndexFromValue(resolution, resolutionValues)
  end
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(options.selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutionValues[currentIndex]
  end

  return currentResolution
end

-- If you want to add the resolutions to an existing table, give it as the second argument
local function getResolutionsFromIndexes(indexes, resolutions)
  if type(resolutions) == "nil" then
    resolutions = {}
  end
  for _,v in ipairs(indexes) do
    if gem.tableIncludes(resolutions, v) == false then
      table.insert(resolutions, resolutionValues[v])
    end
  end
  table.sort(resolutions, function(a,b) return a > b end) -- Ensure sorted desc
  return resolutions
end

local quantizeOptions = {"Off", "Any", "Even", "Dot", "Tri", "Even+Dot", "Even+Tri", "Dot+Tri"}

-- Quantize the given beat to the closest recognized resolution value
local function quantizeToClosest(beat, quantizeType)
  if type(quantizeType) == "nil" then
    quantizeType = quantizeOptions[2] -- Any
  end
  if quantizeType == quantizeOptions[1] then
    -- Quantize off, just return return the given beat value
    return beat
  end
  local includeSlowResolutions = beat > resolutionValues[resolutionTypeStartPosIndex]
  local resolutionsByType = getResolutionsByType(#resolutionValues, includeSlowResolutions)
  local quantizeResolutions = {}
  if includeSlowResolutions then
    --print("Beat > resolutionsByType[1][1]", beat, resolutionValues[resolutionsByType[1][1]])
    quantizeResolutions = getResolutionsFromIndexes(resolutionsByType[4], quantizeResolutions) -- Slow
  else
    for i=1,3 do
      if quantizeType == quantizeOptions[2] or string.find(quantizeType, quantizeOptions[i+2], 1, true) then
        quantizeResolutions = getResolutionsFromIndexes(resolutionsByType[i], quantizeResolutions)
        --print("Add quantize resolutions", quantizeType)
      end
    end
  end
  --print("quantizeResolutions min/max/count", quantizeResolutions[1], quantizeResolutions[#quantizeResolutions], #quantizeResolutions)
  for i,v in ipairs(quantizeResolutions) do
    local currentValue = v
    local nextValue = quantizeResolutions[i+1]
    if beat == currentValue or type(nextValue) == "nil" then
      --print("Found equal, or next is nil", beat, currentValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        --print("Closest to current", beat, currentValue, nextValue)
        return currentValue
      else
        --print("Closest to next", beat, nextValue, currentValue)
        return nextValue
      end
    end
  end
  --print("No resolution found, returning the given beat value", beat)
  return beat
end

local resolutions = {
  getResolutionsFromIndexes = getResolutionsFromIndexes,
  getSelectedResolutions = getSelectedResolutions,
  getResolutionVariation = getResolutionVariation,
  getResolutionsByType = getResolutionsByType,
  quantizeToClosest = quantizeToClosest,
  getDotted = getDotted,
  getTriplet = getTriplet,
  getEvenFromDotted = getEvenFromDotted,
  getEvenFromTriplet = getEvenFromTriplet,
  getResolution = function(i)
    return resolutionValues[i]
  end,
  getQuantizeOptions = function()
    return quantizeOptions
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
    for i,r in ipairs(resolutionNames) do
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
  getPlayDuration = function(duration, gate)
    if type(duration) == "nil" then
      duration = 0
    end
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

--------------------------------------------------------------------------------
-- Polyphonic Recording Sequencer
--------------------------------------------------------------------------------

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local activePage = 1
local nextUp = 1
local pageButtons = {}
local paramsPerPart = {}
local paramsPerPage = {}
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local playIndex = 0 -- Holds the unique id for each playing voice
local playingIndex = {}
local numPages = 1
local numParts = 1
local maxPages = 8
local numStepsDefault = 16
local numStepsMax = 512
local quantizeSubdivision = 3
local title = "Polyphonic Recording Sequencer"
local changePageProbability
local cyclePagesButton

if numParts == 1 then
  title = "Monophonic Recording Sequencer"
end

setBackgroundColour("#2c2c2c")

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Get the index for this part in paramsPerPart, given page and part number
local function getPartIndex(part, page)
  if type(page) == "nil" then
    page = activePage -- Default is the active page
  end
  --print("getPartIndex page/part/numParts", page, part, numParts)
  return (page * numParts) + (part - numParts)
end

-- Get page from part index
local function getPageFromPartIndex(partIndex)
  --print("getPageFromPartIndex partIndex", partIndex)
  return math.ceil(partIndex / maxPages)
end

local function advancePage()
  local next = activePage + 1
  if next > numPages then
    next = 1
  end
  pageButtons[next]:setValue(true)
end

local function gotoNextPage()
  -- Check that there is actually a a change
  if activePage == nextUp then
    return
  end
  activePage = nextUp
  for page,params in ipairs(paramsPerPage) do
    local isVisible = page == activePage
    params.sequencerPanel.visible = isVisible
    pageButtons[page]:setValue(isVisible, false)
  end
end

local function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

local function setPageDuration(page)
  --print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    --print("getResolution for partIndex", partIndex)
    local partResolution = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value) * paramsPerPart[partIndex].numStepsBox.value
    table.insert(pageResolutions, partResolution)
    --print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

local function setNumSteps(partIndex, numSteps)
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].tieStepTable.length = numSteps
  paramsPerPart[partIndex].seqPitchTable.length = numSteps
  paramsPerPart[partIndex].seqVelocityTable.length = numSteps
  paramsPerPart[partIndex].seqRatchetTable.length = numSteps
  local page = getPageFromPartIndex(partIndex)
  setPageDuration(page)
end

local function setRecordingPosition(partIndex, quantizeTo, stepDuration)
  local beatDuration = quantizeTo / quantizeSubdivision
  local totalDuration = 0
  while totalDuration < stepDuration do
    for subPosition=1,quantizeSubdivision do
      paramsPerPart[partIndex].subPosition = subPosition
      waitBeat(beatDuration)
      totalDuration = gem.inc(totalDuration, beatDuration)
    end
  end
end

local function arpeg(uniqueId, part)
  local index = 0
  local partDirectionBackward = false
  while isPlaying and playingIndex[part] == uniqueId do
    local partIndex = getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local isPartActive = paramsPerPart[partIndex].muteButton.value == false
    local channel = paramsPerPart[partIndex].channelBox.value
    paramsPerPart[partIndex].currentPosition = currentPosition
    --print("Playing part/currentPosition", partIndex, currentPosition)
    if channel == 0 then
      channel = nil -- Play all channels
    end

    if currentPosition == 1 then
      -- Set direction for this part
      local directionProbability = paramsPerPart[partIndex].directionProbability.value
      partDirectionBackward = gem.getRandomBoolean(directionProbability)
      --print("directionProbability/partIndex/partDirectionBackward", directionProbability, partIndex, partDirectionBackward)
    end

    -- Flip position if playing backwards
    if partDirectionBackward == true then
      local endStep = numStepsInPart
      local diff = currentPosition - 1
      currentPosition = endStep - diff
      --print("endStep/diff/currentPosition", endStep, diff, currentPosition)
    end

    -- Tables for current step position
    local seqPitchTable = paramsPerPart[partIndex].seqPitchTable
    local tieStepTable = paramsPerPart[partIndex].tieStepTable
    local seqVelocityTable = paramsPerPart[partIndex].seqVelocityTable
    local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
    
    -- Params for current step position
    local pitchAdjustment = seqPitchTable:getValue(currentPosition) -- get pitch adjustment
    local tieNext = tieStepTable:getValue(currentPosition)
    local velocity = seqVelocityTable:getValue(currentPosition) -- get velocity/gate 
    local ratchet = seqRatchetTable:getValue(currentPosition) -- get ratchet

    -- Get randomization amounts
    local velocityRandomizationAmount = paramsPerPart[partIndex].velocityRand.value
    local pitchChangeProbability = 0
    if type(paramsPerPart[partIndex].pitchRand) ~= "nil" then
      pitchChangeProbability = paramsPerPart[partIndex].pitchRand.value
    end
    local tieRandomizationAmount = paramsPerPart[partIndex].tieRand.value
    local ratchetRandomizationAmount = paramsPerPart[partIndex].ratchetRand.value

    -- Randomize ratchet
    if gem.getRandomBoolean(ratchetRandomizationAmount) then
      local min = math.max(1, seqRatchetTable.min)
      local max = seqRatchetTable.max
      ratchet = gem.getRandom(min, max)
    end

    -- Check if tie from previous step
    local tieStepPos = currentPosition - 1
    if partDirectionBackward == true then
      tieStepPos = currentPosition + 1
    end

    -- Hold the number of steps the note in this position should play
    local noteSteps = 1

    -- Randomize ties
    if currentPosition < numStepsInPart and gem.getRandomBoolean(tieRandomizationAmount) then
      --print("Before randomized tieNext", tieNext)
      -- Get length of tie
      local min = 2
      local max = math.ceil((numStepsInPart-currentPosition) * (tieRandomizationAmount/100))
      noteSteps = gem.getRandom(min, math.max(2, max))
      tieNext = 1
      --print("After randomize tieNext", tieNext)
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
      --print("Set tie steps currentPosition/noteSteps", currentPosition, noteSteps)
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

    -- Check if step should trigger
    local shouldTrigger = ratchet > 0 and isPartActive

    -- Get step base duration
    local baseDuration = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)

    -- Apply ties on duration
    local tieDuration = baseDuration * noteSteps

    -- Apply ratchet on duration
    stepDuration = tieDuration / math.max(1, ratchet)

    if paramsPerPart[partIndex].recordButton.value == true then
      spawn(setRecordingPosition, partIndex, baseDuration, stepDuration)
    end

    -- Play subdivision
    for ratchetIndex=1,math.max(1, ratchet) do
      -- Randomize velocity/gate
      velocity = gem.randomizeValue(velocity, seqVelocityTable.min, seqVelocityTable.max, velocityRandomizationAmount)

      -- Check for pitch change randomization
      if gem.getRandomBoolean(pitchChangeProbability) then
        -- Get pitch adjustment from random index in pitch table for current part
        local pitchPos = gem.getRandom(numStepsInPart)
        pitchAdjustment = seqPitchTable:getValue(pitchPos)
        --print("Playing pitch from other pos - currentPosition/pitchPos", currentPosition, pitchPos)
      end

      -- Play note if trigger probability hits (and part is not turned off)
      if shouldTrigger then
        local note = 0
        if type(paramsPerPart[partIndex].triggerNote) ~= "nil" then
          note = paramsPerPart[partIndex].triggerNote.value + pitchAdjustment
        end
        if isKeyDown(note) == false then
          playNote(note, velocity, beat2ms(stepDuration), nil, channel)
        end
        --print("Playing note/velocity/ratchet/stepDuration", note, velocity, ratchet, stepDuration)
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

local function pageRunner(uniqueId)
  playingIndex = {}
  for i=1,numParts do
    --print("Start playing", i)
    playIndex = gem.inc(playIndex)
    table.insert(playingIndex, playIndex)
    spawn(arpeg, playIndex, i)
  end
  local rounds = 0
  while isPlaying and seqIndex == uniqueId do
    rounds = rounds + 1
    if rounds > 1 and nextUp == activePage then
      if gem.getRandomBoolean(changePageProbability.value) then
        nextUp = gem.getRandom(numPages)
      elseif cyclePagesButton.value == true then
        nextUp = activePage + 1
        if nextUp > numPages then
          nextUp = 1
        end
      end
    end

    --print("New round on page/duration/round", activePage, paramsPerPage[activePage].pageDuration, rounds)
    waitBeat(paramsPerPage[activePage].pageDuration)

    gotoNextPage()
  end
end

local function startPlaying()
  if isPlaying == true then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(pageRunner, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  --print("Stop playing")
  isPlaying = false
  for page=1,numPages do
    for part=1,numParts do
      local partIndex = getPartIndex(part, page)
      if paramsPerPart[partIndex].recordButton.value == true then
        paramsPerPart[partIndex].recordButton:setValue(#paramsPerPart[partIndex].sequence == 0)
      end
      paramsPerPart[partIndex].sequence = {}
    end
  end
  clearPosition()
  gotoNextPage()
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local headerPanel = Panel("Header")
headerPanel.backgroundColour = menuOutlineColour
headerPanel.x = 10
headerPanel.y = 10
headerPanel.width = 700
headerPanel.height = 30

local label = headerPanel:Label("Label")
label.text = title
label.align = "left"
label.backgroundColour = "#272727"
label.fontSize = 22
label.position = {0,0}
label.size = {280,25}

local playButton = headerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = {102,22}
playButton.x = headerPanel.width - playButton.width
playButton.y = 2
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

local autoplayButton = headerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {102,22}
autoplayButton.x = playButton.x - playButton.width - 5
autoplayButton.y = playButton.y

local footerPanel = Panel("Footer")
footerPanel.backgroundColour = menuOutlineColour
footerPanel.x = 10
footerPanel.width = 700
if maxPages == 1 then
  footerPanel.enabled = false
  footerPanel.visible = false
  footerPanel.height = 10
else
  footerPanel.height = 30
end

changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)
changePageProbability.displayName = "Random"
changePageProbability.tooltip = "Probability of random page change"
changePageProbability.enabled = false
changePageProbability.unit = Unit.Percent
changePageProbability.size = {110,22}
changePageProbability.x = (33 * maxPages) + 102

local actionOptions = {"Actions...", "Randomize triggers", "Randomize pitches", "Randomize velocity", "Randomize ties", "Randomize all", "All ratchet = 1", "Clear page"}
local actionMenu = footerPanel:Menu("ActionMenu", actionOptions)
actionMenu.persistent = false
actionMenu.tooltip = "Select an action. NOTE: This changes data in the affected tables"
actionMenu.backgroundColour = menuBackgroundColour
actionMenu.textColour = menuTextColour
actionMenu.arrowColour = menuArrowColour
actionMenu.outlineColour = menuOutlineColour
actionMenu.showLabel = false
actionMenu.x = changePageProbability.x + changePageProbability.width + 5
actionMenu.size = {110,22}
actionMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end
  -- Randomize triggers
  if self.value == 2 or self.value == 6 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        if gem.getRandomBoolean(75) then
          paramsPerPart[partIndex].seqRatchetTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].seqRatchetTable.min, paramsPerPart[partIndex].seqRatchetTable.max))
        end
      end
    end
  end
  -- Randomize pitches
  if self.value == 3 or self.value == 6 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        if gem.getRandomBoolean(75) then
          paramsPerPart[partIndex].seqPitchTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].seqPitchTable.min, paramsPerPart[partIndex].seqPitchTable.max))
        end
      end
    end
  end
  -- Randomize velocity
  if self.value == 4 or self.value == 6 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        if gem.getRandomBoolean() then
          paramsPerPart[partIndex].seqVelocityTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].seqVelocityTable.min, paramsPerPart[partIndex].seqVelocityTable.max))
        end
      end
    end
  end
  -- Randomize ties
  if self.value == 5 or self.value == 6 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        if gem.getRandomBoolean() then
          paramsPerPart[partIndex].tieStepTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].tieStepTable.min, paramsPerPart[partIndex].tieStepTable.max))
        end
      end
    end
  end
  -- All ratchet = 1
  if self.value == 7 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        paramsPerPart[partIndex].seqRatchetTable:setValue(i, 1)
      end
    end
  end
  -- Clear all
  if self.value == 8 then
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      paramsPerPart[partIndex].sequence = {} -- Clear sequence
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        paramsPerPart[partIndex].seqRatchetTable:setValue(i, 0)
        paramsPerPart[partIndex].seqPitchTable:setValue(i, 0)
        paramsPerPart[partIndex].seqPitchTable:setRange(-12, 12)
        paramsPerPart[partIndex].tieStepTable:setValue(i, 0)
        paramsPerPart[partIndex].seqVelocityTable:setValue(i, 1)
      end
    end
  end
  -- Copy settings from another page
  if self.value > #actionOptions then
    local sourcePage = self.value - #actionOptions
    local targetPage = activePage
    for part=1,numParts do
      local sourcePartIndex = getPartIndex(part, sourcePage)
      local targetPartIndex = getPartIndex(part, targetPage)
      if sourcePartIndex ~= targetPartIndex then
        local source = paramsPerPart[sourcePartIndex]
        local target = paramsPerPart[targetPartIndex]
        target.numStepsBox:setValue(source.numStepsBox.value)
        target.seqPitchTable:setRange(source.seqPitchTable.min, source.seqPitchTable.max)
        for i=1, target.numStepsBox.value do
          target.seqPitchTable:setValue(i, source.seqPitchTable:getValue(i))
          target.tieStepTable:setValue(i, source.tieStepTable:getValue(i))
          target.seqVelocityTable:setValue(i, source.seqVelocityTable:getValue(i))
          target.seqRatchetTable:setValue(i, source.seqRatchetTable:getValue(i))
        end
        -- Copy Settings
        if type(target.pitchRand) ~= "nil" then
          target.pitchRand:setValue(source.pitchRand.value)
        end
        target.tieRand:setValue(source.tieRand.value)
        target.velocityRand:setValue(source.velocityRand.value)
        target.ratchetRand:setValue(source.ratchetRand.value)
        target.stepResolution:setValue(source.stepResolution.value)
        target.directionProbability:setValue(source.directionProbability.value)
        target.ratchetMax:setValue(source.ratchetMax.value)
        target.muteButton:setValue(source.muteButton.value)
        target.recordButton:setValue(source.recordButton.value)
        target.triggerNote:setValue(source.triggerNote.value)
        target.channelBox:setValue(source.channelBox.value)
        end  
    end
  end
  self.selected = 1
end

local pageTrigger = footerPanel:NumBox("PageTrigger", 96, 0, 127, true)
pageTrigger.enabled = false
pageTrigger.displayName = "Change"
pageTrigger.tooltip = "Go to next page by triggering this note. Notes immediately above, trigger pages directly."
pageTrigger.unit = Unit.MidiKey
pageTrigger.height = actionMenu.height
pageTrigger.width = 100

local nextPageButton = footerPanel:Button("NextPageButton")
nextPageButton.persistent = false
nextPageButton.enabled = numPages > 1
nextPageButton.displayName = ">"
nextPageButton.size = {25,22}
nextPageButton.changed = function(self)
  advancePage()
end

cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
cyclePagesButton.enabled = numPages > 1
cyclePagesButton.displayName = ">>"
cyclePagesButton.tooltip = "Play pages in cycle"
cyclePagesButton.backgroundColourOff = "#6600cc44"
cyclePagesButton.backgroundColourOn = "#aa00cc44"
cyclePagesButton.textColourOff = "#cc22FFFF"
cyclePagesButton.textColourOn = "#ccFFFFFF"
cyclePagesButton.size = {25,22}

local numPagesBox = footerPanel:NumBox("Pages", numPages, 1, maxPages, true)
numPagesBox.tooltip = "Number of active pages"
numPagesBox.backgroundColour = menuBackgroundColour
numPagesBox.textColour = menuTextColour
numPagesBox.size = {90,22}
numPagesBox.x = 0
numPagesBox.changed = function(self)
  numPages = self.value
  changePageProbability.enabled = self.value > 1
  nextPageButton.enabled = self.value > 1
  cyclePagesButton.enabled = self.value > 1
  pageTrigger.enabled = self.value > 1
  for page=1,self.max do
    setPageDuration(page)
    pageButtons[page].enabled = page <= numPages
  end
  -- Update action menu
  local actionMenuItems = {}
  for _,v in ipairs(actionOptions) do
    table.insert(actionMenuItems, v)
  end
  for i=1,numPages do
    table.insert(actionMenuItems, "Copy settings from page " .. i)
  end
  actionMenu.items = actionMenuItems
end

-- Add page buttons
local xPadding = 1
for page=1,maxPages do
  local pageButton = footerPanel:OnOffButton("PageButton" .. page, (page==1))
  pageButton.persistent = false
  pageButton.enabled = page <= numPages
  pageButton.displayName = "" .. page
  pageButton.backgroundColourOff = "#ff084486"
  pageButton.backgroundColourOn = "#ff02ACFE"
  pageButton.textColourOff = "#ff22FFFF"
  pageButton.textColourOn = "#efFFFFFF"
  pageButton.size = {25,22}
  pageButton.x = ((pageButton.width + xPadding) * page) + 76
  pageButton.changed = function(self)
    if self.value == true then
      nextUp = page -- register next up
      if isPlaying == false then
        gotoNextPage()
      end
    end
    self:setValue(true, false) -- The clicked button should stay active
  end
  table.insert(pageButtons, pageButton)
end

cyclePagesButton.x = pageButtons[#pageButtons].x + pageButtons[#pageButtons].width + xPadding
nextPageButton.x = cyclePagesButton.x + cyclePagesButton.width + xPadding

pageTrigger.x = actionMenu.x + actionMenu.width + 9
pageTrigger.y = actionMenu.y

local sequencerPanelOffset = 0

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 100
  local tableY = 0
  local tableWidth = 490
  local tableHeight = 105

  local sequencerPanel = Panel("SequencerPage" .. page)
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = headerPanel.height + 15
  sequencerPanel.width = 700
  if numParts == 1 then
    sequencerPanel.height = 234
    tableWidth = 600
  else
    sequencerPanel.height = numParts * (tableHeight + 25) + sequencerPanelOffset
  end

  for part=1,numParts do
    local isVisible = true
    local i = getPartIndex(part, page)

    local positionTable = sequencerPanel:Table("Position" .. i, numStepsDefault, 0, 0, 1, true)
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

    local seqPitchTable = sequencerPanel:Table("Pitch" .. i, numStepsDefault, 0, -12, 12, true)
    seqPitchTable.width = tableWidth
    if numParts == 1 then
      seqPitchTable.height = tableHeight * 1.5
    else
      seqPitchTable.height = tableHeight * 0.5
    end
    seqPitchTable.visible = isVisible
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
    seqPitchTable.x = tableX
    seqPitchTable.y = positionTable.y + positionTable.height + 2

    local tieStepTable = sequencerPanel:Table("TieStep" .. i, numStepsDefault, 0, 0, 1, true)
    tieStepTable.visible = isVisible
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
    tieStepTable.x = tableX
    tieStepTable.height = 9
    tieStepTable.y = seqPitchTable.y + seqPitchTable.height

    local valMin = 1
    local valMax = 127
    local valDefault = valMin
    local seqVelocityTable = sequencerPanel:Table("Velocity" .. i, numStepsDefault, valDefault, valMin, valMax, true)
    seqVelocityTable.visible = isVisible
    seqVelocityTable.displayName = "Velocity"
    seqVelocityTable.tooltip = "Velocity for this step"
    seqVelocityTable.showPopupDisplay = true
    seqVelocityTable.showLabel = false
    seqVelocityTable.fillStyle = "solid"
    seqVelocityTable.sliderColour = "#9f09A3F4"
    if i % 2 == 0 then
      seqVelocityTable.backgroundColour = "#3f000000"
    else
      seqVelocityTable.backgroundColour = "#3f000000"
    end
    seqVelocityTable.width = tableWidth
    seqVelocityTable.height = tableHeight * 0.3
    seqVelocityTable.x = tableX
    seqVelocityTable.y = tieStepTable.y + tieStepTable.height + 2

    local seqRatchetTable = sequencerPanel:Table("Subdivision" .. i, numStepsDefault, 0, 0, 4, true)
    seqRatchetTable.displayName = "Ratchet"
    seqRatchetTable.tooltip = "Subdivision/ratchet for this step (0=trigger off)"
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
    seqRatchetTable.height = tableHeight * 0.23
    seqRatchetTable.x = tableX
    seqRatchetTable.y = seqVelocityTable.y + seqVelocityTable.height + 2

    local muteButton = sequencerPanel:OnOffButton("MutePart" .. i, false)
    muteButton.visible = isVisible
    muteButton.backgroundColourOff = "#ff084486"
    muteButton.backgroundColourOn = "#ff02ACFE"
    muteButton.textColourOff = "#ff22FFFF"
    muteButton.textColourOn = "#efFFFFFF"
    muteButton.displayName = "Mute"
    muteButton.tooltip = "Mute part"
    muteButton.size = {39,20}
    muteButton.x = 0
    muteButton.y = positionTable.y

    local recordButton = sequencerPanel:OnOffButton("RecordPart" .. i, (i==1))
    recordButton.visible = isVisible
    recordButton.backgroundColourOff = "#ff084486"
    recordButton.backgroundColourOn = "#ff02ACFE"
    recordButton.textColourOff = "#ff22FFFF"
    recordButton.textColourOn = "#efFFFFFF"
    recordButton.displayName = "R"
    recordButton.tooltip = "Activate recording"
    recordButton.size = {25,20}
    recordButton.x = muteButton.width + muteButton.x + 1
    recordButton.y = muteButton.y

    local listenButton = sequencerPanel:OnOffButton("ListenPart" .. i, false)
    listenButton.visible = isVisible
    listenButton.backgroundColourOff = "#ff084486"
    listenButton.backgroundColourOn = "#ff02ACFE"
    listenButton.textColourOff = "#ff22FFFF"
    listenButton.textColourOn = "#efFFFFFF"
    listenButton.displayName = "L"
    listenButton.tooltip = "Activate listen for root note"
    listenButton.size = {25,20}
    listenButton.x = recordButton.width + recordButton.x + 1
    listenButton.y = recordButton.y

    local numBoxSpacing = 1
    local numBoxHeight = muteButton.height

    local triggerNote = sequencerPanel:NumBox("TriggerNote" .. i, 24 + (i * 12), 0, 127, true)
    if numParts == 1 then
      triggerNote.value = 60
    end
    triggerNote.displayName = "Root Note"
    triggerNote.tooltip = "Set the root note for this voice"
    triggerNote.unit = Unit.MidiKey
    triggerNote.visible = isVisible
    triggerNote.showLabel = true
    triggerNote.backgroundColour = menuBackgroundColour
    triggerNote.textColour = menuTextColour
    triggerNote.height = numBoxHeight
    triggerNote.width = 90
    triggerNote.x = 0
    triggerNote.y = muteButton.y + numBoxHeight + numBoxSpacing

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the step resolution"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 23
    stepResolution.x = 0
    stepResolution.y = triggerNote.y + numBoxHeight + numBoxSpacing
    stepResolution.height = numBoxHeight
    stepResolution.width = 90
    stepResolution.backgroundColour = menuBackgroundColour
    stepResolution.textColour = menuTextColour
    stepResolution.arrowColour = menuArrowColour
    stepResolution.outlineColour = menuOutlineColour
    stepResolution.changed = function(self)
      setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, numStepsDefault, 1, numStepsMax, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = menuBackgroundColour
    numStepsBox.textColour = menuTextColour
    numStepsBox.arrowColour = menuArrowColour
    numStepsBox.outlineColour = menuOutlineColour
    numStepsBox.width = stepResolution.width
    numStepsBox.height = numBoxHeight
    numStepsBox.x = 0
    numStepsBox.y = stepResolution.y + numBoxHeight + numBoxSpacing
    numStepsBox.changed = function(self)
      --print("numStepsBox.changed index/value", i, self.value)
      setNumSteps(i, self.value)
    end

    local ratchetMax = sequencerPanel:NumBox("RatchetMax" .. i, 4, 1, 16, true)
    ratchetMax.displayName = "Ratchet"
    ratchetMax.tooltip = "Set the maximum allowed subdivision that can be selected for each step"
    ratchetMax.visible = isVisible
    ratchetMax.backgroundColour = menuBackgroundColour
    ratchetMax.textColour = menuTextColour
    ratchetMax.arrowColour = menuArrowColour
    ratchetMax.outlineColour = menuOutlineColour
    ratchetMax.width = numStepsBox.width
    ratchetMax.height = numBoxHeight
    ratchetMax.x = 0
    ratchetMax.y = numStepsBox.y + numBoxHeight + numBoxSpacing
    ratchetMax.changed = function(self)
      for i=1, seqRatchetTable.length do
        if seqRatchetTable:getValue(i) > self.value then
          seqRatchetTable:setValue(i, self.value)
        end
      end
      seqRatchetTable:setRange(seqRatchetTable.min, self.value)
    end

    local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
    channelBox.displayName = "Channel"
    channelBox.showLabel = true
    channelBox.tooltip = "Midi channel that receives trigger from this part. 0 = omni"
    channelBox.visible = isVisible
    channelBox.backgroundColour = menuBackgroundColour
    channelBox.textColour = menuTextColour
    channelBox.arrowColour = menuArrowColour
    channelBox.outlineColour = menuOutlineColour
    channelBox.width = numStepsBox.width
    channelBox.x = 0
    channelBox.height = numBoxHeight
    channelBox.y = ratchetMax.y + ratchetMax.height + numBoxSpacing

    local directionProbability = sequencerPanel:NumBox("PartDirectionProbability" .. i, 0, 0, 100, true)
    directionProbability.displayName = "Backward"
    directionProbability.visible = isVisible
    directionProbability.tooltip = "Backward probability amount"
    directionProbability.backgroundColour = menuBackgroundColour
    directionProbability.textColour = menuTextColour
    directionProbability.arrowColour = menuArrowColour
    directionProbability.outlineColour = menuOutlineColour
    directionProbability.unit = Unit.Percent
    if numParts == 1 then
      directionProbability.x = channelBox.x
      directionProbability.y = channelBox.y + channelBox.height + numBoxSpacing
      directionProbability.size = {channelBox.width,numBoxHeight}
    else
      directionProbability.x = tableX + tableWidth + 10
      directionProbability.y = positionTable.y
      directionProbability.size = {100,numBoxHeight}
    end

    local pitchRand = sequencerPanel:NumBox("PitchOffsetRandomization" .. i, 0, 0, 100, true)
    pitchRand.displayName = "Pitch"
    pitchRand.tooltip = "Probability that the pitch offset from another step will be used"
    pitchRand.visible = isVisible
    pitchRand.unit = Unit.Percent
    pitchRand.size = directionProbability.size
    pitchRand.x = directionProbability.x
    pitchRand.y = directionProbability.y + numBoxHeight + numBoxSpacing
    pitchRand.backgroundColour = menuBackgroundColour
    pitchRand.textColour = menuTextColour
    pitchRand.arrowColour = menuArrowColour
    pitchRand.outlineColour = menuOutlineColour

    local tieRand = sequencerPanel:NumBox("TieRandomization" .. i, 0, 0, 100, true)
    tieRand.displayName = "Tie"
    tieRand.tooltip = "Amount of radomization applied to ties for selected part"
    tieRand.visible = isVisible
    tieRand.backgroundColour = menuBackgroundColour
    tieRand.textColour = menuTextColour
    tieRand.arrowColour = menuArrowColour
    tieRand.outlineColour = menuOutlineColour
    tieRand.unit = Unit.Percent
    tieRand.size = directionProbability.size
    tieRand.x = directionProbability.x
    if type(pitchRand) == "nil" then
      tieRand.y = directionProbability.y + numBoxHeight + numBoxSpacing
    else
      tieRand.y = pitchRand.y + pitchRand.height + numBoxSpacing
    end

    local velocityRand = sequencerPanel:NumBox("VelocityRandomization" .. i, 0, 0, 100, true)
    velocityRand.displayName = "Velocity"
    velocityRand.tooltip = "Velocity radomization amount"
    velocityRand.visible = isVisible
    velocityRand.unit = Unit.Percent
    velocityRand.size = directionProbability.size
    velocityRand.x = directionProbability.x
    velocityRand.y = tieRand.y + tieRand.height + numBoxSpacing
    velocityRand.backgroundColour = menuBackgroundColour
    velocityRand.textColour = menuTextColour
    velocityRand.arrowColour = menuArrowColour
    velocityRand.outlineColour = menuOutlineColour

    local ratchetRand = sequencerPanel:NumBox("SubdivisionRandomization" .. i, 0, 0, 100, true)
    ratchetRand.displayName = "Ratchet"
    ratchetRand.tooltip = "Ratchet radomization amount"
    ratchetRand.visible = isVisible
    ratchetRand.unit = Unit.Percent
    ratchetRand.size = directionProbability.size
    ratchetRand.x = directionProbability.x
    ratchetRand.y = velocityRand.y + velocityRand.height + numBoxSpacing
    ratchetRand.backgroundColour = menuBackgroundColour
    ratchetRand.textColour = menuTextColour
    ratchetRand.arrowColour = menuArrowColour
    ratchetRand.outlineColour = menuOutlineColour

    table.insert(paramsPerPart, {muteButton=muteButton,ratchetMax=ratchetMax,pitchRand=pitchRand,tieRand=tieRand,velocityRand=velocityRand,ratchetRand=ratchetRand,triggerNote=triggerNote,recordButton=recordButton,listenButton=listenButton,channelBox=channelBox,positionTable=positionTable,seqPitchTable=seqPitchTable,tieStepTable=tieStepTable,seqVelocityTable=seqVelocityTable,seqRatchetTable=seqRatchetTable,stepResolution=stepResolution,directionProbability=directionProbability,numStepsBox=numStepsBox,currentPosition=0,subPosition=0,sequence={}})

    local yOffset = 25
    tableY = tableY + tableHeight + yOffset
  end
  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,pageDuration=4,active=(page==1)})
  setPageDuration(page)
end

footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local function recordNoteEventStart(e)
  for part=1,numParts do
    local partIndex = getPartIndex(part)
    if paramsPerPart[partIndex].listenButton.value then
      paramsPerPart[partIndex].triggerNote:setValue(e.note)
      paramsPerPart[partIndex].listenButton:setValue(false)
    end
    if isPlaying and paramsPerPart[partIndex].recordButton.value then
      local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
      local basePitch = paramsPerPart[partIndex].triggerNote.value
      local seqPitchTable = paramsPerPart[partIndex].seqPitchTable
      local seqVelocityTable = paramsPerPart[partIndex].seqVelocityTable
      local seqRatchetTable = paramsPerPart[partIndex].seqRatchetTable
      local noteMin = basePitch + seqPitchTable.min
      local noteMax = basePitch + seqPitchTable.max
      local currentPosition = paramsPerPart[partIndex].currentPosition
      local subPosition = paramsPerPart[partIndex].subPosition
      if subPosition == quantizeSubdivision then
        currentPosition = gem.inc(currentPosition, 1, numStepsInPart)
      end
      table.insert(paramsPerPart[partIndex].sequence, {note=e.note, velocity=e.velocity, startPos=currentPosition})
      local distanceFromBase = e.note - basePitch
      --print("Record startPos, note, distanceFromBase", currentPosition, e.note, distanceFromBase)
      if distanceFromBase < seqPitchTable.min then
        seqPitchTable:setRange(distanceFromBase, seqPitchTable.max)
        --print("setRange min", distanceFromBase)
      elseif distanceFromBase > seqPitchTable.max then
        seqPitchTable:setRange(seqPitchTable.min, distanceFromBase)
        --print("setRange max", distanceFromBase)
      end
      seqPitchTable:setValue(currentPosition, distanceFromBase)
      seqVelocityTable:setValue(currentPosition, e.velocity)
      seqRatchetTable:setValue(currentPosition, 1)
    end
  end
end

local function recordNoteEventEnd(e)
  for part=1,numParts do
    local partIndex = getPartIndex(part)
    for _,event in ipairs(paramsPerPart[partIndex].sequence) do
      if event.note == e.note and type(event.endPos) == "nil" then
        local tieStepTable = paramsPerPart[partIndex].tieStepTable
        local currentPosition = paramsPerPart[partIndex].currentPosition
        local subPosition = paramsPerPart[partIndex].subPosition
        if subPosition < quantizeSubdivision then
          currentPosition = currentPosition - 1
        end
        event.endPos = math.max(event.startPos, currentPosition)
        local prevPos = event.startPos - 1
        if prevPos > 1 then
          tieStepTable:setValue(prevPos, 0)
        end
        tieStepTable:setValue(event.endPos, 0)
        if event.startPos < event.endPos then
          for i=event.startPos,event.endPos do
            tieStepTable:setValue(i, 1)
          end
        end
      end
    end
  end
end

function onInit()
  -- Reset play indexes
 seqIndex = 0
 playIndex = 0
end

function onNote(e)
  if pageTrigger.enabled == true then
    for page=1,numPages do
      if pageTrigger.value == e.note then
        advancePage()
        break
      elseif (pageTrigger.value + page) == e.note then
        pageButtons[page]:setValue(true)
        break
      end
    end
  end

  recordNoteEventStart(e)

  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(true)
  end
end

function onRelease(e)
  recordNoteEventEnd(e)

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
  local seqVelocityTableData = {}
  local seqRatchetTableData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    for j=1, v.numStepsBox.value do
      table.insert(seqPitchTableData, v.seqPitchTable:getValue(j))
      table.insert(tieStepTableData, v.tieStepTable:getValue(j))
      table.insert(seqVelocityTableData, v.seqVelocityTable:getValue(j))
      table.insert(seqRatchetTableData, v.seqRatchetTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqPitchTableData)
  table.insert(data, tieStepTableData)
  table.insert(data, seqVelocityTableData)
  table.insert(data, seqRatchetTableData)
  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqPitchTableData = data[2]
  local tieStepTableData = data[3]
  local seqVelocityTableData = data[4]
  local seqRatchetTableData = data[5]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqPitchTable.length = v
    paramsPerPart[i].tieStepTable.length = v
    paramsPerPart[i].seqVelocityTable.length = v
    paramsPerPart[i].seqRatchetTable.length = v
    for j=1, v do
      paramsPerPart[i].seqPitchTable:setValue(j, seqPitchTableData[dataCounter])
      paramsPerPart[i].tieStepTable:setValue(j, tieStepTableData[dataCounter])
      paramsPerPart[i].seqVelocityTable:setValue(j, seqVelocityTableData[dataCounter])
      paramsPerPart[i].seqRatchetTable:setValue(j, seqRatchetTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    setPageDuration(page)
  end
end
