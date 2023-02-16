-- modular/gridSequencerInput -- 
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

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
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

local function triangle(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = round(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = valueRange / numStepsUpDown
  local startValue = minValue
  local tri = {}
  for i=1,numSteps do
    table.insert(tri, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  return tri
end

local function rampUp(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = minValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, changePerStep)
  end
  return ramp
end

local function rampDown(minValue, maxValue, numSteps)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numSteps)
  local startValue = maxValue
  local ramp = {}
  for i=1,numSteps do
    table.insert(ramp, startValue)
    startValue = inc(startValue, -changePerStep)
  end
  return ramp
end

local gem = {
  inc = inc,
  round = round,
  triangle = triangle,
  rampUp = rampUp,
  rampDown = rampDown,
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
-- Common Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2,2,2,1,2,1,2}, -- Acoustic
  {2,1,2,1,1,3,2}, -- Blues
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {3}, -- Diminished
  {2}, -- Whole tone scale
  {1}, -- Chomatic
}

local scaleNames = {
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Acoustic",
  "Blues",
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Diminished",
  "Whole tone",
  "Chomatic",
}

local scales = {
  getScaleDefinitions = function()
    return scaleDefinitions
  end,

  getScaleNames = function()
    return scaleNames
  end,

  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 128
    end
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote < maxNote do
      table.insert(scale, rootNote)
      rootNote = rootNote + scaleDefinition[pos]
      pos = pos + 1
      if pos > #scaleDefinition then
        pos = 1
      end
    end
    return scale
  end
}

--------------------------------------------------------------------------------
-- Common functions for notes
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

local notes = {
  getNoteNames = function()
    return notenames
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
    return note
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

-- Quantize the given beat to the closest recognized resolution value
local function quantizeToClosest(beat)
  for i,v in ipairs(resolutionValues) do
    local currentValue = v
    local nextValue = resolutionValues[i+1]
    --print("beat, currentValue, nextValue", beat, currentValue, nextValue)
    if type(nextValue) == "nil" or beat == currentValue then
      --print("beat == currentValue or nextValue == nil", beat, currentValue, nextValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        --print("Return currentValue diffCurrent < diffNext", diffCurrent, diffNext)
        return currentValue
      else
        --print("Return nextValue diffNext < diffCurrent", diffNext, diffCurrent)
        return nextValue
      end
    end
  end
  return beat
end

local resolutions = {
  quantizeToClosest = quantizeToClosest,

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
-- Grid Sequencer - Listens for incoming note events (rythm) on note number 0
--------------------------------------------------------------------------------

local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "CFFFFE" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuSelectedBackgroundColour = "052525"
local menuTextColour = "#9f02ACFE"
local noteSelectedTextColour = "green"
local notePlayingTextColour = "yellow"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local scaleIncrementDefinition = {} -- Holds the increment definition for scales
local degreeDefinition = {} -- Holds the definition for degrees on the y-axis
local noteInputs = {} -- Holds the note inputs
local listeners = {} -- Holds the note listeners
local gridXY = {} -- Holds x and y axis positon and other settings
local xAxis = 1 -- Hold the index for the x axis in the gridXY table
local yAxis = 2 -- Hold the index for the y axis in the gridXY table
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local rootNote = 1 -- Holds the current root note (key)
local scaleDefinitionIndex = #scalesNames -- Holds the scale definition index
local startOctave = -1 -- Holds the start octave when creating the scale
local octaves = 9 -- Holds the octave range
local noteRandomizationProbability = 0
local manualInput = false
local activeVoices = {}

-- X Axis (index 1)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 2,
  size = 8,
  max = 12
})

-- Y Axis (index 2)
table.insert(gridXY, {
  pos = 0,
  direction = 1,
  increment = 1,
  playMode = playModes[1],
  chord = false,
  chordNotes = 2,
  chordNotesIncrement = 1,
  randomChord = false,
  randomProbability = 0, -- Probability that position will be selected by chance
  advanceProbability = 100, -- Probability that a new position for the axis will be selected by the play mode
  mustAdvance = true, -- Set true to ensure pos is moved to within the selected area even if advanceProbability = 0
  hasAdvanced = false,
  offset = 3,
  size = 3,
  max = 9
})

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function getCell(x, y)
  --print("Get grid cell: x, y, floor(x), floor(y)", x, y, math.floor(x), math.floor(y))
  -- Not < 1
  x = math.max(1, math.ceil(x))
  y = math.max(1, math.ceil(y))
  -- Not > max
  if x > gridXY[xAxis].max then
    print("x > gridXY[xAxis].max")
    x = gridXY[xAxis].max
  end
  if y > gridXY[yAxis].max then
    print("y > gridXY[yAxis].max")
    y = gridXY[yAxis].max
  end
  -- Get cell name
  local cellName = 'Note' .. x .. '_' .. y
  for _,v in ipairs(noteInputs) do
    if v.name == cellName then
      return v
    end
  end
end

local function toggleNoteInputs(enabled)
  for i,v in ipairs(noteInputs) do
    v.enabled = enabled
  end
end

local function showListeners(show)
  for i,v in ipairs(noteInputs) do
    if show then
      v.width = 30
      v.x = listeners[i].x + listeners[i].width
    else
      v.width = 42
      v.x = listeners[i].x
    end
    listeners[i].visible = show
  end
end

local function isPosWithinSelectedAxis(pos, axis)
  return pos > gridXY[axis].offset and pos <= gridXY[axis].offset + gridXY[axis].size
end

local function isWithinSelectedGrid(x, y)
  return isPosWithinSelectedAxis(x, xAxis) and isPosWithinSelectedAxis(y, yAxis)
end

-- Returns the (reset) position before any increments are made
local function getStartPos(axis)
  local startPos = gridXY[axis].offset

  if string.sub(gridXY[axis].playMode, 1, 6) == "Follow" then
    return startPos + 1
  end

  gridXY[axis].mustAdvance = true

  if gridXY[axis].increment < 1 then
    return startPos
  end

  return startPos + 1 - math.floor(gridXY[axis].increment)
end

local function setPos()
  for axis=xAxis,yAxis do
    -- When direction is forward, we set the start pos
    if gridXY[axis].direction == 1 then
      gridXY[axis].pos = getStartPos(axis)
    else
      -- When direction is backward, we set the end pos
      local endPos = gridXY[axis].offset + gridXY[axis].size
      if gridXY[axis].playMode == "Follow <-" then
        gridXY[axis].pos = endPos
      else
        gridXY[axis].mustAdvance = true
        gridXY[axis].pos = endPos - gridXY[axis].increment
      end
    end
  end
end

local function setSelectedGrid()
  local i = 1
  for y=1,gridXY[yAxis].max do
    for x=1,gridXY[xAxis].max do
      if isWithinSelectedGrid(x, y) then
        noteInputs[i].textColour = noteSelectedTextColour
        noteInputs[i].backgroundColour = menuSelectedBackgroundColour
      else
        noteInputs[i].textColour = menuTextColour
        noteInputs[i].backgroundColour = menuBackgroundColour
      end
      i = gem.inc(i)
    end
  end
  setPos()
end

local function setDirectionFromPlaymode(axis, playMode)
  gridXY[axis].playMode = playMode
  gridXY[axis].direction = 1
  gridXY[axis].increment = math.abs(gridXY[axis].increment)

  if playMode == "<-" or playMode == "<-->" or playMode == "Follow <-" then
    gridXY[axis].direction = -1
    gridXY[axis].increment = -gridXY[axis].increment
  end

  --print("setDirectionFromPlaymode: direction, increment, playMode", gridXY[axis].direction, gridXY[axis].increment, playMode)
end

local function handleFollow(axis)
  if gridXY[axis].hasAdvanced or gem.getRandomBoolean(gridXY[axis].advanceProbability) == false then
    -- Skip follow if the axis has already advanced or advance probability does not hit
    return
  end
  gridXY[axis].pos = gem.inc(gridXY[axis].pos, gridXY[axis].increment)
  if gridXY[axis].direction == 1 and (gridXY[axis].pos > gridXY[axis].offset + gridXY[axis].size or gridXY[axis].pos > gridXY[axis].max) then
    gridXY[axis].pos = getStartPos(axis)
  elseif gridXY[axis].pos <= gridXY[axis].offset then
    gridXY[axis].pos = gridXY[axis].offset + gridXY[axis].size
  end
end

-- playModes = {"->", "<-", "-><-", "<-->", "Follow ->", "Follow <-"}
local function advanceByPlayMode(v, axis)
  local otherAxis = xAxis
  if axis == otherAxis then
    otherAxis = yAxis
  end
  local axisIsFollow = string.sub(v.playMode, 1, 6) == "Follow"
  local otherAxisIsFollow = string.sub(gridXY[otherAxis].playMode, 1, 6) == "Follow"
  local bothAxisAreFollow = axisIsFollow and otherAxisIsFollow
  if gem.getRandomBoolean(v.randomProbability) then
    --print("Advance random")
    if v.size > 1 then
      v.pos = gem.getRandom(v.offset + 1, v.offset + v.size)
    else
      v.pos = v.offset + v.size
    end
    v.hasAdvanced = true
    if otherAxisIsFollow then
      handleFollow(otherAxis)
    end
  elseif v.playMode == "-><-" or v.playMode == "<-->" then
    v.pos = gem.inc(v.pos, v.increment)
    if math.floor(v.pos) <= v.offset then
      v.direction = 1
      v.increment = math.abs(v.increment) -- Turn positive
      --print("Turned direction and increment positive", v.direction, v.increment)
      v.pos = getStartPos(axis) + v.increment
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    elseif v.pos > v.offset + v.size or v.pos > v.max then
      v.direction = -1
      v.increment = -v.increment -- Turn negative
      --print("Turned direction and increment negative", v.direction, v.increment)
      v.pos = v.offset + v.size
      if v.size > 1 and otherAxisIsFollow == false then
        v.pos = gem.inc(v.pos, v.increment) -- To avoid repeat
      end
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif (v.direction == 1 and axisIsFollow == false) or bothAxisAreFollow then
    --print("advanceByPlayMode: direction == 1")
    v.pos = gem.inc(v.pos, v.increment)
    --print("advanceByPlayMode: axis, pos", axis, v.pos)
    if v.pos > v.offset + v.size or v.pos > v.max then
      --v.pos = gem.inc(v.offset, v.increment)
      v.pos = getStartPos(axis) + v.increment
      --print("advanceByPlayMode: reset axis, pos", axis, v.pos)
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  elseif v.direction == -1 and axisIsFollow == false then
    v.pos = gem.inc(v.pos, v.increment)
    --print("axis, v.pos, v.increment, v.offset", axis, v.pos, v.increment, v.offset)
    if v.pos <= v.offset then
      v.pos = v.offset + v.size
      if otherAxisIsFollow then
        handleFollow(otherAxis)
      end
    end
  end
end

local function getCellForAxis(axis, pos)
  if axis == xAxis then
    local yPos = gridXY[yAxis].pos
    --print("getCell @ axis, pos, yPos", axis, pos, yPos)
    return getCell(pos, yPos)
  end

  local xPos = gridXY[xAxis].pos
  --print("getCell @ axis, xPos, pos", axis, xPos, pos)
  return getCell(xPos, pos)
end

local function getCellsForAxis(axis, v)
  local cellsForAxis = {}
  local startPos = v.offset + 1
  local endPos = math.min(v.max, v.offset + v.size)
  --print("axis, startPos, endPos", i, startPos, endPos)
  if v.chord and v.randomChord then
    -- Get selected notes in random order
    local currentPos = startPos
    while currentPos <= endPos do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos)
    end
    -- Remove random cells until we have the correct amount
    while #cellsForAxis > v.chordNotes do
      table.remove(cellsForAxis, gem.getRandom(#cellsForAxis))
    end
  else
    -- Get selected notes in sequential order
    local currentPos = v.pos
    -- Add cells until we have the correct amount
    while #cellsForAxis < v.chordNotes do
      table.insert(cellsForAxis, getCellForAxis(axis, currentPos))
      currentPos = gem.inc(currentPos, v.chordNotesIncrement, endPos, startPos)
    end
  end
  return cellsForAxis
end

local function getNotes()
  local cells = {} -- Holds the selected grid cells to play

  -- Reset advance status
  gridXY[xAxis].hasAdvanced = false
  gridXY[yAxis].hasAdvanced = false

  -- Advance each axis according to the set increment
  for axis,v in ipairs(gridXY) do
    if v.mustAdvance or gem.getRandomBoolean(v.advanceProbability) then
      advanceByPlayMode(v, axis)
      v.mustAdvance = false
    end
  end

  -- Get multiple cells if polymode is active on any of the axis
  for axis,v in ipairs(gridXY) do
    if v.chord then
      for _,cell in ipairs(getCellsForAxis(axis, v)) do
        table.insert(cells, cell)
      end
    end
  end

  -- If no cells were found using polymode, we return the cell at the current pos
  if #cells == 0 then
    table.insert(cells, getCell(gridXY[xAxis].pos, gridXY[yAxis].pos))
  end

  --print("Returning cells", #cells)
  return cells
end

local function releaseVoices()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
    print("Release active voice on channel", v.event.channel)
    if v.noteInput.backgroundColour == menuSelectedBackgroundColour then
      v.noteInput.textColour = noteSelectedTextColour
    else
      v.noteInput.textColour = menuTextColour
    end
  end
  activeVoices = {}
  setPos()
end

local function createTableFromText(text)
  local theTable = {}
  if string.len(text) > 0 then
    for w in string.gmatch(text, "[^,]+") do
      table.insert(theTable, tonumber(gem.trimStartAndEnd(w)))
    end
  end
  return theTable
end

local function setScale()
  if manualInput then
    -- Do not change anything when manual input is active
    --print("Skip set scale - manual input is active")
    return
  end
  local startNote = (rootNote - 1) + ((startOctave + 2) * 12)
  local maxNote = startNote + (octaves * 12)
  local scale = scales.createScale(scaleDefinitions[scaleDefinitionIndex], startNote, math.min(128, maxNote))
  local scalePos = 1
  local scaleIncrementDefinitionPos = 1
  local degreeDefinitionPos = 0
  local degreeOctave = 0
  local scaleResetPos = 1
  print("Root note is", startNote)
  print("Max note is", maxNote)
  print("Degree definition", #degreeDefinition)
  print("#scale", #scale)
  for i,v in ipairs(noteInputs) do
    -- Check if we have a degree definition
    -- Check if we are at the start of the x axis
    if #degreeDefinition > 0 and (i - 1) % gridXY[xAxis].max == 0 then
      -- Increment degree position
      degreeDefinitionPos = gem.inc(degreeDefinitionPos, 1, #degreeDefinition)
      -- Set the scale pos to the selected degree if within the scale
      if degreeDefinition[degreeDefinitionPos] <= #scale then
        scalePos = math.max(1, degreeDefinition[degreeDefinitionPos])
      end
      -- Set scale reset pos to match the scale pos set by the degree definition
      scaleResetPos = scalePos
      -- Increment degree octave on pos 1 of the degree def
      if i > 1 and degreeDefinitionPos == 1 then
        degreeOctave = gem.inc(degreeOctave, 1, (octaves - 1), 0)
        --print("Increment octave at degree pos", degreeOctave)
      end
      -- Reset the position for scale increments
      scaleIncrementDefinitionPos = 1
    end

    -- Set the note for this cell
    local noteNumber = math.min(127, scale[scalePos] + (degreeOctave * 12))
    -- Get random from scale
    if gem.getRandomBoolean(noteRandomizationProbability) then
      noteNumber = gem.getRandomFromTable(scale)
    end
    v:setValue(noteNumber)

    -- Get next scale position
    scalePos = math.max(1, gem.inc(scalePos, scaleIncrementDefinition[scaleIncrementDefinitionPos], #scale, scaleResetPos))

    if scalePos == scaleResetPos then
      -- Reset the position for scale increments when scale position is reset
      scaleIncrementDefinitionPos = 1
    else
      -- Get next scale increment position
      scaleIncrementDefinitionPos = gem.inc(scaleIncrementDefinitionPos, 1, #scaleIncrementDefinition)
    end
  end
end

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

local sequencerPanel = Panel("GridSequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 0
sequencerPanel.y = 0
sequencerPanel.width = 720
sequencerPanel.height = 30

local notePanel = Panel("Notes")
notePanel.backgroundColour = "black"
notePanel.x = sequencerPanel.x
notePanel.y = sequencerPanel.y + sequencerPanel.height
notePanel.width = sequencerPanel.width
notePanel.height = 240

local settingsPanel = Panel("Scale")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = notePanel.x
settingsPanel.y = notePanel.y + notePanel.height + 0
settingsPanel.width = sequencerPanel.width
settingsPanel.height = 84

local axisMotionPanel = Panel("AxisMotionPanel")
axisMotionPanel.backgroundColour = "404040"
axisMotionPanel.x = settingsPanel.x
axisMotionPanel.y = settingsPanel.y + settingsPanel.height + 0
axisMotionPanel.width = sequencerPanel.width
axisMotionPanel.height = 132

--------------------------------------------------------------------------------
-- Grid Sequencer
--------------------------------------------------------------------------------

local xSpacing = 5

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Grid Sequencer Input"
sequencerLabel.tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.position = {0,0}
sequencerLabel.size = {sequencerPanel.width,30}

local manualInputButton = sequencerPanel:OnOffButton("ManualInputButton", manualInput)
local showListenersButton = sequencerPanel:OnOffButton("ShowListeners", false)
local channelInput = sequencerPanel:Menu("ChannelInput", channels)

manualInputButton.backgroundColourOff = backgroundColourOff
manualInputButton.backgroundColourOn = backgroundColourOn
manualInputButton.textColourOff = textColourOff
manualInputButton.textColourOn = textColourOn
manualInputButton.displayName = "Manual Input"
manualInputButton.tooltip = "Make all note inputs available for direct edit or note listen"
manualInputButton.size = {100,22}
manualInputButton.x = sequencerPanel.width - (manualInputButton.width * 3) - 5
manualInputButton.y = 5
manualInputButton.changed = function(self)
  manualInput = self.value
  showListenersButton.enabled = self.value
  if self.value == false then
    showListenersButton:setValue(false)
  end
  settingsPanel.enabled = self.value == false
  toggleNoteInputs(self.value)
end

showListenersButton.enabled = false
showListenersButton.backgroundColourOff = backgroundColourOff
showListenersButton.backgroundColourOn = backgroundColourOn
showListenersButton.textColourOff = textColourOff
showListenersButton.textColourOn = textColourOn
showListenersButton.displayName = "Show Listeners"
showListenersButton.tooltip = "Show listeners for each note - only available in manual input mode"
showListenersButton.size = {100,22}
showListenersButton.x = manualInputButton.x + manualInputButton.width + xSpacing
showListenersButton.y = manualInputButton.y
showListenersButton.changed = function(self)
  showListeners(self.value)
end

channelInput.tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through"
channelInput.arrowColour = menuArrowColour
channelInput.showLabel = false
channelInput.backgroundColour = menuBackgroundColour
channelInput.textColour = widgetTextColour
channelInput.size = {90,22}
channelInput.x = showListenersButton.x + showListenersButton.width + xSpacing
channelInput.y = showListenersButton.y

--------------------------------------------------------------------------------
-- Note Grid
--------------------------------------------------------------------------------

local rowCounter = gridXY[yAxis].max - 1
local columnCounter = 0
local colSpacing = 3
local rowSpacing = 2
local noteListen = false
local noteIndex = 0

for y=1,gridXY[yAxis].max do
  for x=1,gridXY[xAxis].max do
    local listen = notePanel:OnOffButton("Listen" .. x .. '_' .. y)
    listen.visible = false
    listen.displayName = "L"
    listen.tooltip = "Note learn - check multiple listeners to set same note on several inputs"
    listen.persistent = false
    listen.textColourOff = "white"
    listen.backgroundColourOn = "green"
    listen.height = 24
    listen.width = 14
    listen.x = (colSpacing * 1) + (columnCounter * (42 + colSpacing))
    listen.y = (rowSpacing * 1.5) + ((listen.height + rowSpacing) * rowCounter)
    listen.changed = function(self)
      if self.value then
        noteListen = true
      end
    end
    table.insert(listeners, listen)

    local noteInput = notePanel:NumBox("Note" .. x .. '_' .. y, noteIndex + 12, 0, 127, true)
    noteInput.enabled = false
    noteInput.showLabel = false
    noteInput.displayName = "Note"
    noteInput.tooltip = "The note to trigger in cell x:" .. x .. ', y:' .. y
    noteInput.unit = Unit.MidiKey
    noteInput.backgroundColour = menuBackgroundColour
    noteInput.textColour = menuTextColour
    noteInput.height = 24
    noteInput.width = 42
    noteInput.x = listen.x
    noteInput.y = listen.y
    table.insert(noteInputs, noteInput)

    noteIndex = gem.inc(noteIndex)
    columnCounter = gem.inc(columnCounter)
    if columnCounter >= gridXY[xAxis].max then
      columnCounter = 0
      rowCounter = gem.inc(rowCounter, -1)
    end
  end
end

local xyOffset = notePanel:XY('GridOffset1', 'GridOffset2')
xyOffset.bounds = {546, 6, 168, 112}

local xySize = notePanel:XY('GridSize1', 'GridSize2')
xySize.bounds = {xyOffset.x, xyOffset.y+xyOffset.height+4, xyOffset.width, xyOffset.height}

--------------------------------------------------------------------------------
-- Note Selection
--------------------------------------------------------------------------------

xSpacing = 10

local noteSelectionLabel = settingsPanel:Label("NoteSelectionLabel")
noteSelectionLabel.text = "Note Selection"
noteSelectionLabel.tooltip = "Settings for selecting the notes in the grid (disabled when manual input is active)"
noteSelectionLabel.alpha = 0.3
noteSelectionLabel.fontSize = 16
noteSelectionLabel.backgroundColour = labelBackgoundColour
noteSelectionLabel.textColour = labelTextColour
noteSelectionLabel.width = settingsPanel.width
noteSelectionLabel.height = 18
noteSelectionLabel.x = 0
noteSelectionLabel.y = 0

local keyMenu = settingsPanel:Menu("Key", notes.getNoteNames())
keyMenu.displayName = "Key"
keyMenu.tooltip = "The key to set for the notes in the grid"
keyMenu.showLabel = true
keyMenu.width = 90
keyMenu.x = 5
keyMenu.y = noteSelectionLabel.y + noteSelectionLabel.height + 10
keyMenu.backgroundColour = menuBackgroundColour
keyMenu.textColour = menuTextColour
keyMenu.arrowColour = menuArrowColour
keyMenu.outlineColour = menuOutlineColour

local scaleMenu = settingsPanel:Menu("Scale", scalesNames)
scaleMenu.selected = #scalesNames
scaleMenu.displayName = "Scale"
scaleMenu.tooltip = "The scale to set for the notes in the grid"
scaleMenu.showLabel = true
scaleMenu.width = 120
scaleMenu.x = keyMenu.x + keyMenu.width + xSpacing
scaleMenu.y = keyMenu.y
scaleMenu.backgroundColour = menuBackgroundColour
scaleMenu.textColour = menuTextColour
scaleMenu.arrowColour = menuArrowColour
scaleMenu.outlineColour = menuOutlineColour

local startOctaveInput = settingsPanel:NumBox("StartOctave", startOctave, -2, 7, true)
startOctaveInput.displayName = "Start octave"
startOctaveInput.tooltip = "The octave to start from when creating the scale"
startOctaveInput.backgroundColour = menuBackgroundColour
startOctaveInput.textColour = menuTextColour
startOctaveInput.height = 20
startOctaveInput.width = 126
startOctaveInput.x = scaleMenu.x + scaleMenu.width + xSpacing
startOctaveInput.y = scaleMenu.y

local octavesInput = settingsPanel:NumBox("Octaves", octaves, 1, 10, true)
octavesInput.displayName = "Octaves"
octavesInput.tooltip = "Set the octave range"
octavesInput.backgroundColour = menuBackgroundColour
octavesInput.textColour = menuTextColour
octavesInput.height = startOctaveInput.height
octavesInput.width = startOctaveInput.width
octavesInput.x = startOctaveInput.x
octavesInput.y = startOctaveInput.y + startOctaveInput.height + 5

local noteRandomizationProbabilityInput = settingsPanel:Knob("NoteRandomizationProbability", noteRandomizationProbability, 0, 100, true)
noteRandomizationProbabilityInput.unit = Unit.Percent
noteRandomizationProbabilityInput.displayName = "Random notes"
noteRandomizationProbabilityInput.tooltip = "Set the probability that notes within the current scale will be selected by chance."
noteRandomizationProbabilityInput.backgroundColour = widgetBackgroundColour
noteRandomizationProbabilityInput.fillColour = knobFillColour
noteRandomizationProbabilityInput.outlineColour = labelBackgoundColour
noteRandomizationProbabilityInput.showPopupDisplay = true
noteRandomizationProbabilityInput.height = 45
noteRandomizationProbabilityInput.width = 130
noteRandomizationProbabilityInput.y = startOctaveInput.y
noteRandomizationProbabilityInput.x = startOctaveInput.x + startOctaveInput.width + xSpacing
noteRandomizationProbabilityInput.changed = function(self)
  noteRandomizationProbability = self.value
  setScale()
end

local scaleIncrementInputLabel = settingsPanel:Label("ScaleIncrementInputLabel")
scaleIncrementInputLabel.text = "X"
scaleIncrementInputLabel.x = noteRandomizationProbabilityInput.x + noteRandomizationProbabilityInput.width + xSpacing
scaleIncrementInputLabel.y = noteRandomizationProbabilityInput.y
scaleIncrementInputLabel.height = startOctaveInput.height
scaleIncrementInputLabel.width = 20

local scaleIncrementInput = settingsPanel:Label("ScaleIncrementInput")
scaleIncrementInput.text = "1"
scaleIncrementInput.tooltip = "Set scale increments on the x axis - default is to increment by one step per cell. Increments are separated by comma, and will repeat until all cells are set."
scaleIncrementInput.editable = true
scaleIncrementInput.backgroundColour = labelTextColour
scaleIncrementInput.backgroundColourWhenEditing = "white"
scaleIncrementInput.textColour = "white"
scaleIncrementInput.textColourWhenEditing = labelTextColour
scaleIncrementInput.height = startOctaveInput.height
scaleIncrementInput.width = 165
scaleIncrementInput.x = scaleIncrementInputLabel.x + scaleIncrementInputLabel.width
scaleIncrementInput.y = scaleIncrementInputLabel.y
scaleIncrementInput.changed = function(self)
  scaleIncrementDefinition = createTableFromText(self.text)
  setScale()
end

local degreeInputLabel = settingsPanel:Label("DegreeInputLabel")
degreeInputLabel.text = "Y"
degreeInputLabel.x = scaleIncrementInputLabel.x
degreeInputLabel.y = scaleIncrementInputLabel.y + scaleIncrementInputLabel.height + 5
degreeInputLabel.height = scaleIncrementInputLabel.height
degreeInputLabel.width = scaleIncrementInputLabel.width

local degreeInput = settingsPanel:Label("DegreeInput")
degreeInput.text = "1"
degreeInput.tooltip = "Degree definition: if set, the scale increment input will reset at the start of each row (y-axis), setting the degree as the root note. 1 = root. Degrees are separated by comma."
degreeInput.editable = true
degreeInput.backgroundColour = labelTextColour
degreeInput.backgroundColourWhenEditing = "white"
degreeInput.textColour = "white"
degreeInput.textColourWhenEditing = labelTextColour
degreeInput.height = scaleIncrementInput.height
degreeInput.width = scaleIncrementInput.width
degreeInput.x = degreeInputLabel.x + degreeInputLabel.width
degreeInput.y = degreeInputLabel.y
degreeInput.changed = function(self)  
  degreeDefinition = createTableFromText(self.text)
  setScale()
end

keyMenu.changed = function(self)
  rootNote = self.value
  setScale()
end

scaleMenu.changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

startOctaveInput.changed = function(self)
  startOctave = self.value
  setScale()
end

octavesInput.changed = function(self)
  octaves = self.value
  setScale()
end

--------------------------------------------------------------------------------
-- Axis Motion Settings
--------------------------------------------------------------------------------

xSpacing = 10 -- Horizontal widget spacing

local motionLabel = axisMotionPanel:Label("MotionLabel")
motionLabel.text = "Motion"
motionLabel.tooltip = "Settings for setting the grid selection, and controlling motion along the x and y axis"
motionLabel.alpha = noteSelectionLabel.alpha
motionLabel.fontSize = noteSelectionLabel.fontSize
motionLabel.backgroundColour = labelBackgoundColour
motionLabel.textColour = labelTextColour
motionLabel.width = axisMotionPanel.width
motionLabel.height = 18
motionLabel.x = 0
motionLabel.y = 0

-- XY Axis

for axis=xAxis,yAxis do
  local axisLabel = axisMotionPanel:Label("AxisLabel" .. axis)
  axisLabel.height = 40
  axisLabel.width = 24
  if axis == xAxis then
    axisLabel.text = "X"
    axisLabel.y = motionLabel.y + motionLabel.height + 10
  else
    axisLabel.text = "Y"
    axisLabel.y = motionLabel.y + motionLabel.height + 63
  end
  axisLabel.tooltip = "Settings for the current axis"
  axisLabel.textColour = labelBackgoundColour
  axisLabel.backgroundColour = labelTextColour
  axisLabel.fontSize = 22
  axisLabel.x = 5

  local gridOffset = axisMotionPanel:Slider("GridOffset" .. axis, gridXY[axis].offset, 0, gridXY[axis].max - 1)
  gridOffset.displayName = "Offset"
  gridOffset.tooltip = "Offset of the current axis (can be adjusted by the top XY controller)"
  gridOffset.backgroundColour = menuBackgroundColour
  gridOffset.textColour = menuTextColour
  gridOffset.height = 45
  gridOffset.width = 60
  gridOffset.x = axisLabel.x + axisLabel.width + xSpacing
  gridOffset.y = axisLabel.y - 5
  gridOffset.changed = function(self)
    local offset = gem.round(self.value)
    if offset ~= gridXY[axis].offset then
      gridXY[axis].offset = offset
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local gridLength = axisMotionPanel:Slider("GridSize" .. axis, gridXY[axis].size, 1, gridXY[axis].max)
  gridLength.displayName = "Length"
  gridLength.tooltip = "Length of current axis (can be adjusted by the bottom XY controller)"
  gridLength.backgroundColour = menuBackgroundColour
  gridLength.textColour = menuTextColour
  gridLength.height = gridOffset.height
  gridLength.width = gridOffset.width
  gridLength.x = gridOffset.x + gridOffset.width + xSpacing
  gridLength.y = gridOffset.y
  gridLength.changed = function(self)
    local size = gem.round(self.value)
    if size ~= gridXY[axis].size then
      gridXY[axis].size = size
      gridXY[axis].mustAdvance = true
      setSelectedGrid()
    end
  end

  local seqPlayMode = axisMotionPanel:Menu("SequencerPlayMode" .. axis, playModes)
  seqPlayMode.displayName = "Mode"
  seqPlayMode.tooltip = "The sequencer play mode for the current axis"
  seqPlayMode.x = gridLength.x + gridLength.width + xSpacing
  seqPlayMode.y = gridLength.y
  seqPlayMode.height = gridLength.height
  seqPlayMode.width = 75
  seqPlayMode.backgroundColour = menuBackgroundColour
  seqPlayMode.textColour = menuTextColour
  seqPlayMode.arrowColour = menuArrowColour
  seqPlayMode.outlineColour = menuOutlineColour
  seqPlayMode.changed = function(self)
    setDirectionFromPlaymode(axis, self.text)
  end
  seqPlayMode:changed()

  local chordNotes = axisMotionPanel:NumBox("ChordNotes" .. axis, gridXY[axis].chordNotes, 2, gridXY[axis].max, true)
  local chordNoteIncrement = axisMotionPanel:NumBox("ChordNoteIncrement" .. axis, gridXY[axis].chordNotesIncrement, 1, (math.floor(gridXY[axis].max / 2) + 1), true)
  local randomChordButton = axisMotionPanel:OnOffButton("RandomChordButton" .. axis, gridXY[axis].randomChord)

  local chordButton = axisMotionPanel:OnOffButton("ChordButton" .. axis, gridXY[axis].chord)
  chordButton.backgroundColourOff = backgroundColourOff
  chordButton.backgroundColourOn = backgroundColourOn
  chordButton.textColourOff = textColourOff
  chordButton.textColourOn = textColourOn
  chordButton.displayName = "Polymode"
  chordButton.tooltip = "In polymode, mutiple notes are played along the current axis"
  chordButton.size = {100,20}
  chordButton.x = seqPlayMode.x + seqPlayMode.width + xSpacing
  chordButton.y = seqPlayMode.y + 3
  chordButton.changed = function(self)
    gridXY[axis].chord = self.value
    if self.value then
      gridXY[axis].chordNotes = chordNotes.value
    else
      gridXY[axis].chordNotes = 1
    end
    chordNotes.enabled = self.value
    chordNoteIncrement.enabled = self.value and randomChordButton.value == false
    randomChordButton.enabled = self.value
  end
  chordButton:changed()

  chordNotes.enabled = false
  chordNotes.showLabel = false
  chordNotes.displayName = "Notes"
  chordNotes.tooltip = "Number of notes to play in polymode"
  chordNotes.backgroundColour = menuBackgroundColour
  chordNotes.textColour = menuTextColour
  chordNotes.size = {30,20}
  chordNotes.x = chordButton.x + chordButton.width + 1
  chordNotes.y = chordButton.y
  chordNotes.changed = function(self)
    gridXY[axis].chordNotes = self.value
  end

  chordNoteIncrement.enabled = false
  chordNoteIncrement.displayName = "Distance"
  chordNoteIncrement.tooltip = "The distance in steps up the scale between notes in polymode"
  chordNoteIncrement.backgroundColour = menuBackgroundColour
  chordNoteIncrement.textColour = menuTextColour
  chordNoteIncrement.size = {81,20}
  chordNoteIncrement.x = chordButton.x
  chordNoteIncrement.y = chordButton.y + chordButton.height + 2
  chordNoteIncrement.changed = function(self)
    gridXY[axis].chordNotesIncrement = self.value
  end

  randomChordButton.enabled = false
  randomChordButton.backgroundColourOff = backgroundColourOff
  randomChordButton.backgroundColourOn = backgroundColourOn
  randomChordButton.textColourOff = textColourOff
  randomChordButton.textColourOn = textColourOn
  randomChordButton.displayName = "Random"
  randomChordButton.tooltip = "Select chord notes by chance from within the active axis"
  randomChordButton.size = {48,chordNotes.height}
  randomChordButton.x = chordNoteIncrement.x + chordNoteIncrement.width + 2
  randomChordButton.y = chordNoteIncrement.y
  randomChordButton.changed = function(self)
    gridXY[axis].randomChord = self.value
    chordNoteIncrement.enabled = self.value == false
  end

  local increment = axisMotionPanel:Knob("Increment" .. axis, gridXY[axis].increment, .1, (gridXY[axis].max / 3))
  increment.displayName = "Increment"
  increment.tooltip = "Set the increment amount per step on the current axis"
  increment.backgroundColour = widgetBackgroundColour
  increment.fillColour = knobFillColour
  increment.outlineColour = labelBackgoundColour
  increment.showPopupDisplay = true
  increment.height = 39
  increment.width = 100
  increment.y = seqPlayMode.y + 8
  increment.x = randomChordButton.x + randomChordButton.width + xSpacing
  increment.changed = function(self)
    gridXY[axis].increment = self.value
    setDirectionFromPlaymode(axis, seqPlayMode.text)
  end

  local advanceProbability = axisMotionPanel:Knob("AdvanceProbability" .. axis, gridXY[axis].advanceProbability, 0, 100, true)
  advanceProbability.unit = Unit.Percent
  advanceProbability.displayName = "Advance"
  advanceProbability.tooltip = "Set the probability that the position will advance on the current axis"
  advanceProbability.backgroundColour = widgetBackgroundColour
  advanceProbability.fillColour = knobFillColour
  advanceProbability.outlineColour = labelBackgoundColour
  advanceProbability.showPopupDisplay = true
  advanceProbability.height = increment.height
  advanceProbability.width = increment.width
  advanceProbability.y = increment.y
  advanceProbability.x = increment.x + increment.width + xSpacing
  advanceProbability.changed = function(self)
    gridXY[axis].advanceProbability = self.value
  end

  local randomProbability = axisMotionPanel:Knob("RandomProbability" .. axis, gridXY[axis].randomProbability , 0, 100, true)
  randomProbability.unit = Unit.Percent
  randomProbability.displayName = "Random"
  randomProbability.tooltip = "Set the probability that the position on the current axis will be selected by chance"
  randomProbability.backgroundColour = widgetBackgroundColour
  randomProbability.fillColour = knobFillColour
  randomProbability.outlineColour = labelBackgoundColour
  randomProbability.showPopupDisplay = true
  randomProbability.height = advanceProbability.height
  randomProbability.width = advanceProbability.width
  randomProbability.y = advanceProbability.y
  randomProbability.x = advanceProbability.x + advanceProbability.width
  randomProbability.changed = function(self)
    gridXY[axis].randomProbability = self.value
  end
end

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

local function noteIsPlaying(note)
  for _,v in ipairs(activeVoices) do
    if v.event.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e)
  local channel = channelInput.value - 1
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e)
  local notesForPlaying = getNotes() -- The selected note inputs to play
  if #notesForPlaying > 0 then
    for _,noteInput in ipairs(notesForPlaying) do
      local note = noteInput.value
      if noteIsPlaying(note) == false then
        local id = playNote(note, e.velocity)
        e.note = note
        table.insert(activeVoices, {id=id,event=e,noteInput=noteInput})
      end
      noteInput.textColour = notePlayingTextColour
    end
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
      print("Release active voice on channel", v.event.channel)
      if v.noteInput.backgroundColour == menuSelectedBackgroundColour then
        v.noteInput.textColour = noteSelectedTextColour
      else
        v.noteInput.textColour = menuTextColour
      end
    end
  end
end

function onInit()
  print("Init grid sequencer")
  setSelectedGrid()
  scaleIncrementInput:changed()
  degreeInput:changed()
end

function onNote(e)
  if noteListen then
    for i,v in ipairs(noteInputs) do
      if listeners[i].value then
        v:setValue(e.note)
        listeners[i]:setValue(false)
      end
    end
    noteListen = false
  end
  if isTrigger(e) then
    handleTrigger(e)
  else
    postEvent(e)
  end
end

function onRelease(e)
  if isTrigger(e) then
    handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    releaseVoices()
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  return {scaleIncrementInput.text, degreeInput.text}
end

function onLoad(data)
  scaleIncrementInput.text = data[1]
  degreeInput.text = data[2]
  scaleIncrementInput:changed()
  degreeInput:changed()
end
