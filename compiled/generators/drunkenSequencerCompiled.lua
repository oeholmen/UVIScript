-- generators/drunkenSequencer -- 
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

local function avg(t)
  local sum = 0
  for _,v in pairs(t) do -- Get the sum of all numbers in t
    sum = sum + v
  end
  return sum / #t
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

local gem = {
  inc = inc,
  avg = avg,
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
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Common Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {def={2,2,1,2,2,2,1},name="7 Notes/Major (Ionian)",},
  {def={2,1,2,2,1,2,2},name="7 Notes/Minor (Aeolian)",},
  {def={2,1,2,2,2,1,2},name="7 Notes/Dorian",},
  {def={1,2,2,2,1,2,2},name="7 Notes/Phrygian",},
  {def={2,2,2,1,2,2,1},name="7 Notes/Lydian",},
  {def={2,2,1,2,2,1,2},name="7 Notes/Mixolydian",},
  {def={1,2,2,1,2,2,2},name="7 Notes/Locrian",},
  {def={2,2,2,1,2,1,2},name="7 Notes/Acoustic",},
  {def={2,1,2,1,1,3,2},name="7 Notes/Blues",},
  {def={1,2,1,3,1,2,2},name="7 Notes/Alterated",},
  {def={2,1,3,1,1,3,1},name="7 Notes/Maqam Saba",},
  {def={1,3,1,2,3,1,1},name="7 Notes/Persian",},
  {def={1,3,1,2,1,3,1},name="7 Notes/Arabic",},
  {def={2,1,3,1,1,2,2},name="7 Notes/Hungarian",},
  {def={2,2,3,2,3},name="5 Notes/Major Pentatonic",},
  {def={3,2,2,3,2},name="5 Notes/Minor Pentatonic",},
  {def={1,4,1,4,2},name="5 Notes/Hirajoshi",},
  {def={1,4,2,1,4},name="5 Notes/Miyako-Bushi",},
  {def={1,4,3,2,2},name="5 Notes/Iwato",},
  {def={2,2,1,2,2},name="5 Notes/Ritsu",},
  {def={2,1,4,2,1},name="5 Notes/Kumoi",},
  {def={1,3,1,2,3},name="5 Notes/Maqam Hijaz",},
  {def={2,1,4,1,2},name="5 Notes/Maqam Bayati",},
  {def={3},name="Diminished",},
  {def={2},name="Whole tone",},
  {def={1},name="Chomatic",},
}

local function getScaleNames()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.name)
  end
  return items
end

local function getScaleDefinitions()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.def)
  end
  return items
end

local function getTextFromScaleDefinition(scaleDefinition)
  if type(scaleDefinition) == nil or #scaleDefinition == 0 then
    return ""
  end
  return table.concat(scaleDefinition, ",")
end

local function getScaleDefinitionFromText(scaleText)
  local scale = {}
  if string.len(scaleText) > 0 then
    for w in string.gmatch(scaleText, "%d+") do
      table.insert(scale, tonumber(w))
    end
    print("Get scale from input", #scale)
  end
  return scale
end

local function getScaleDefinitionIndex(scaleDefinition)
  -- Check if we find a scale definition that matches the given definition
  if type(scaleDefinition) == "table" then
    scaleDefinition = getTextFromScaleDefinition(scaleDefinition)
  end
  for i,v in ipairs(scaleDefinitions) do
    if scaleDefinition == getTextFromScaleDefinition(v.def) then
      print("getScaleDefinitionIndex: found scale", v.name)
      return i
    end
  end
end

local function getScaleWidget(width, showLabel, i)
  -- Scale widget
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  return widgets.menu("Scale", #scaleDefinitions, getScaleNames(), {
    name = "Scale" .. i,
    tooltip = "Select a scale",
    hierarchical = true,
    width = width,
    showLabel = showLabel ~= false,
  })
end

local function getScaleInputWidget(scaleDefinition, width, i)
  -- Scale input widget
  if type(width) == "nil" then
    width = 120
  end
  if type(i) == "nil" then
    i = ""
  end
  return widgets.label(getTextFromScaleDefinition(scaleDefinition), {
    name = "ScaleInput" .. i,
    tooltip = "Scales are defined by setting semitones up from the previous note, separated by comma. If 12 is divisible by the definition sum, it will resolve every octave.",
    editable = true,
    backgroundColour = "black",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "white",
    width = width
  })
end

local scales = {
  widget = getScaleWidget,
  inputWidget = getScaleInputWidget,
  getScaleDefinitionIndex = getScaleDefinitionIndex,
  getTextFromScaleDefinition = getTextFromScaleDefinition,
  getScaleDefinitionFromText = getScaleDefinitionFromText,
  getScaleDefinitions = getScaleDefinitions,
  getScaleNames = getScaleNames,
  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 127
    end
    while rootNote < 0 do
      rootNote = rootNote + 12
      print("Transpose root note up to within range", rootNote)
    end
    while maxNote > 127 do
      maxNote = maxNote - 12
      print("Transpose max note down to within range", maxNote)
    end
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote <= maxNote do
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
-- Note and Scale Parameters
--------------------------------------------------------------------------------

local octaves = 9
local scaleDefinitions = scales.getScaleDefinitions()
local scaleNames = scales.getScaleNames()
local noteNames = notes.getNoteNames()
local selectedKey = 1

-- TODO Check if they can be local
local notesPlaying = {}
local noteInputs = {}
local noteProbabilityInputs = {}
local octaveInputs = {}
local octaveProbabilityInputs = {}

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

local function getNoteInputs()
  return noteInputs
end

local function getNotesPlaying()
  return notesPlaying
end

local function addNotePlaying(note)
  table.insert(notesPlaying, note)
end

local function removeNotePlaying(note)
  table.remove(notesPlaying, gem.getIndexFromValue(note, notesPlaying))
end

local function clearNotesPlaying()
  notesPlaying = {}
end

local function getScale(scaleIndex, keyIndex)
  local scaleDefinition = scaleDefinitions[scaleIndex]
  local rootNote = keyIndex - 1 -- Root note
  return scales.createScale(scaleDefinition, rootNote)
end

local function setScale(scaleIndex, keyIndex)
  local scale = getScale(scaleIndex, keyIndex)
  for i,v in ipairs(noteInputs) do
    local noteNumber = i + 11 -- Check note in octave above
    v:setValue(gem.tableIncludes(scale, noteNumber))
  end
end

-- Get notes that are activated in selected octaves, filtered by probability
-- If getAllNotes is true, the filter for playing notes is disabled
local function getSelectedNotes(getAllNotes)
  local selectedNotes = {} -- Holds note numbers that are available
  for octaveIndex,octave in ipairs(octaveInputs) do
    local octaveProbability = octaveProbabilityInputs[octaveIndex].value
    --print("octaveProbability octaveOnOff", octaveProbability, octave.value)
    if octave.value and octaveProbability > 0 then
      for i,v in ipairs(noteInputs) do
        -- Check if note should be added for this octave
        local noteProbability = noteProbabilityInputs[i].value
        --print("noteProbability, octaveProbability, noteOnOff", noteProbability, octaveProbability, v.value)
        if v.value and gem.getRandomBoolean(noteProbability) and gem.getRandomBoolean(octaveProbability) then
          local noteNumber = i - 1 -- Base note
          noteNumber = noteNumber + (12 * octaveIndex) -- Set octave
          if getAllNotes == true or gem.tableIncludes(notesPlaying, noteNumber) == false then
            table.insert(selectedNotes, noteNumber)
            --print("Note added: noteNumber", noteNumber)
          end
        end
      end
    end
  end
  --print("#selectedNotes", #selectedNotes)
  return selectedNotes
end

-- Get all notes that are activated in all octaves (full scale)
local function getActiveNotes()
  local notes = {}
  for octaveIndex=1, #octaveInputs do
    for i,v in ipairs(noteInputs) do
      if v.value then
        local noteNumber = i - 1 -- Base note
        noteNumber = noteNumber + (12 * octaveIndex) -- Set octave
        table.insert(notes, noteNumber)
      end
    end
  end
  return notes
end

local function createNoteAndOctaveSelector(notePanel, colours, noteLabel, offsetX, offsetY, generateKeyPos)
  if type(offsetX) == "nil" then
    offsetX = 5
  end
  if type(offsetY) == "nil" then
    offsetY = 5
  end
  if type(generateKeyPos) == "nil" then
    generateKeyPos = {
      x = noteLabel.x + noteLabel.width + 10,
      y = noteLabel.y
    }
  end
  local columnCount = 0
  for i=1,#noteNames do
    local note = notePanel:OnOffButton("Note" .. i, true)
    note.backgroundColourOff = "#ff084486"
    note.backgroundColourOn = "#ff02ACFE"
    note.textColourOff = "#ff22FFFF"
    note.textColourOn = "#efFFFFFF"
    note.displayName = noteNames[i]
    note.tooltip = "Toggle note on/off"
    note.size = {51,30}
    note.x = (columnCount * (note.width + 6.6)) + offsetX
    note.y = noteLabel.y + noteLabel.height + offsetY
  
    local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
    noteProbability.unit = Unit.Percent
    noteProbability.textColour = colours.widgetTextColour
    noteProbability.backgroundColour = colours.widgetBackgroundColour
    noteProbability.showLabel = false
    noteProbability.tooltip = "Set the probability that '" .. noteNames[i] .. "' will be available when generating notes to play"
    noteProbability.width = note.width
    noteProbability.height = 22
    noteProbability.x = note.x
    noteProbability.y = note.y + note.height + 1
  
    table.insert(noteInputs, note)
    table.insert(noteProbabilityInputs, noteProbability)
  
    columnCount = columnCount + 1
  end
  
  columnCount = 0
  
  local rising = true
  local numStepsUpDown = math.floor(octaves / 2)
  local changePerStep = 100 / numStepsUpDown
  local startValue = 0
  for i=1,octaves do
    local octave = notePanel:OnOffButton("Octave" .. i, (startValue > 50))
    octave.backgroundColourOff = "#ff084486"
    octave.backgroundColourOn = "#ff02ACFE"
    octave.textColourOff = "#ff22FFFF"
    octave.textColourOn = "#efFFFFFF"
    octave.displayName = "Oct " .. i - 2
    octave.tooltip = "Toggle octave on/off"
    octave.width = (636 / octaves)
    octave.height = 30
    octave.x = (columnCount * (octave.width + 6.9)) + offsetX
    octave.y = 90 + offsetY
  
    local octaveProbabilityInput = notePanel:NumBox("OctaveProbability" .. i, 100, 0, 100, true)
    octaveProbabilityInput.unit = Unit.Percent
    octaveProbabilityInput.textColour = colours.widgetTextColour
    octaveProbabilityInput.backgroundColour = colours.widgetBackgroundColour
    octaveProbabilityInput.showLabel = false
    octaveProbabilityInput.tooltip = "Set the probability that octave " .. i - 2 .. " will be available when generating notes to play"
    octaveProbabilityInput.width = octave.width
    octaveProbabilityInput.height = 22
    octaveProbabilityInput.x = octave.x
    octaveProbabilityInput.y = octave.y + octave.height

    table.insert(octaveInputs, octave)
    table.insert(octaveProbabilityInputs, octaveProbabilityInput)

    if rising then
      startValue = startValue + changePerStep
      if startValue >= 100 then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end

    columnCount = columnCount + 1
  end

  local generateKey = notePanel:Menu("GenerateKey", noteNames)
  generateKey.tooltip = "Set selected notes from key"
  generateKey.showLabel = false
  generateKey.backgroundColour = colours.menuBackgroundColour
  generateKey.textColour = colours.widgetTextColour
  generateKey.arrowColour = colours.menuArrowColour
  generateKey.outlineColour = colours.menuOutlineColour
  generateKey.size = {60,20}
  generateKey.x = generateKeyPos.x
  generateKey.y = generateKeyPos.y
  if type(generateKeyPos.height) == "number" then
    generateKey.height = generateKeyPos.height
  end

  local generateScale = notePanel:Menu("GenerateScale", scaleNames)
  generateScale.selected = #scaleNames
  generateScale.tooltip = "Set selected notes from scale"
  generateScale.showLabel = false
  generateScale.hierarchical = true
  generateScale.backgroundColour = colours.menuBackgroundColour
  generateScale.textColour = colours.widgetTextColour
  generateScale.arrowColour = colours.menuArrowColour
  generateScale.outlineColour = colours.menuOutlineColour
  generateScale.width = 144
  generateScale.height = generateKey.height
  generateScale.x = generateKey.x + generateKey.width + 10
  generateScale.y = generateKey.y

  generateKey.changed = function(self)
    setScale(generateScale.value, self.value)
    selectedKey = self.value
  end

  generateScale.changed = function(self)
    setScale(self.value, generateKey.value)
  end
end

local function getKey()
  return selectedKey
end

local noteSelector = {
  createNoteAndOctaveSelector = createNoteAndOctaveSelector,
  getActiveNotes = getActiveNotes,
  getSelectedNotes = getSelectedNotes,
  getNoteInputs = getNoteInputs,
  getNotesPlaying = getNotesPlaying,
  addNotePlaying = addNotePlaying,
  removeNotePlaying = removeNotePlaying,
  clearNotesPlaying = clearNotesPlaying,
  getKey = getKey,
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
      print("Found equal, or next is nil", beat, currentValue)
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        print("Closest to current", beat, currentValue, nextValue)
        return currentValue
      else
        print("Closest to next", beat, nextValue, currentValue)
        return nextValue
      end
    end
  end
  print("No resolution found, returning the given beat value", beat)
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
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

--------------------------------------------------------------------------------
-- Common functions for working with rythmic fragments
--------------------------------------------------------------------------------

local paramsPerFragment = {}

-- Expand defaults
local resolutionFragments = {
  {'1/16','1/16','1/8'},
  {'1/16','1/8','1/16'},
  {'1/4 dot','1/8'},
  {'1/4 dot','1/16','1/16'},
  {'1/4','1/8','1/8'},
  {'1/8','1/4','1/8'},
  {'1/4','1/8','1/16','1/16'},
  {'1/16','1/8 dot'},
  {'1/8 dot','1/16'},
  {'1/2 dot','1/4'},
  {'1/8 dot','1/4','1/4','1/16'},
  {'1/16','1/16','1/16','1/16','1/16','1/16','1/16','1/32','1/32'},
  {'1/8','1/8','1/16','1/4','1/8','1/16','1/8','1/16','1/16'},
  {'-1/1 dot','1/4 dot','1/8'},
  {'-1/4','1/4','-1/4','1/8 dot','1/16'},
  {'1/4','-1/4','1/4','-1/4','1/4','-1/4','1/4 dot','-1/16','1/16'},
  {'1.75','1/16','-1/4','-1/8','1/8'}
}

local singleResolutions = {14,15,17,18,20,23} -- Resolution indexes
local resolutionsForEvolve = {} -- Resolutions used when evolving
local resolutionsByType = resolutions.getResolutionsByType()
local maxResolutionIndex = resolutionsByType[1][#resolutionsByType[1]] -- Set max resolution to the highest even resolution index

local function setMaxResolutionIndex(i)
  maxResolutionIndex = i
end

-- Turn all recognized fragment items into note names
local function fragmentDefinitionToResolutionNames(fragmentDefinition)
  local parsed = {}
  for _,v in ipairs(fragmentDefinition) do
    local index = gem.getIndexFromValue(v, resolutions.getResolutions())
    local text = v
    --print("index, text", index, text)
    if type(index) == "number" then
      text = resolutions.getResolutionName(index)
      --print("text", text)
    end
    table.insert(parsed, text)
  end
  return parsed
end

local function parseToBeatValue(duration)
  if type(tonumber(duration)) == "number" then
    duration = tonumber(duration)
    --print("Duration is number", duration)
    return duration
  end

  --print("Duration is NOT a number, try to find beat value from name", duration)
  -- TODO Check if duration starts with a '-' indicating pause
  local isRest = string.sub(duration,1,1) == "-"
  if isRest then
    duration = string.sub(duration, 2, string.len(duration))
    --print("Duration starts with - 'REST'", duration)
  end
  local index = gem.getIndexFromValue(duration, resolutions.getResolutionNames())
  if type(index) == "number" then
    --print("Found duration", duration)
    if isRest then
      return -resolutions.getResolution(index)
    end
    return resolutions.getResolution(index)
  end

  --print("Could not resolve duration, returning 0", duration)
  return 0
end

local function createFragmentFromText(fragmentText)
  local fragment = {}
  if string.len(fragmentText) > 0 then
    for w in string.gmatch(fragmentText, "[^,]+") do
      --print("Before parse", w)
      local beat = parseToBeatValue(gem.trimStartAndEnd(w))
      --print("Add to fragment", w)
      if type(beat) == "number" then
        table.insert(fragment, beat)
      end
    end
  end
  return fragment
end

local function calculateFragmentDuration(fragmentText)
  local fragment = createFragmentFromText(fragmentText)
  local total = 0
  for _,v in ipairs(fragment) do
    total = total + math.abs(v)
    --print("calculateFragmentDuration v, total", v, total)
  end
  --print("TOTAL", total)
  return total
end

-- Get the fragment as text for fragment input
local function getFragmentInputText(fragment)
  if #fragment == 0 then
    return ""
  end
  return table.concat(fragment, ",")
end

-- Include all durations shorter than or equal to the total fragmentDuration
local function addDurations(resolutionIndexes, durations, fragmentDuration)
  for _,i in ipairs(resolutionIndexes) do
    local duration = resolutions.getResolution(i)
    if duration <= fragmentDuration then
      table.insert(durations, duration)
      --print("addDurations() Inserted duration", duration)
    end
  end
  return durations
end

-- Returns a probability (between 0-100) for the given resolution index
local function getProbabilityForResolutionIndex(i)
  local baseProbability = math.ceil(100 / resolutions.getResolution(i))
  local factor = i / 2
  return math.min(100, math.floor(baseProbability * factor))
end

-- Returns indexes for "whole" resolutions, filtered by probability
local function getSlowResolutions()
  local slowResolutions = {}
  for _,i in ipairs(resolutionsByType[4]) do
    local probability = getProbabilityForResolutionIndex(i)
    --print("getSlowResolutions - set probability for resolution", probability, resolutions.getResolution(i))
    if gem.getRandomBoolean(probability) then
      table.insert(slowResolutions, i)
      --print("getSlowResolutions - included slow resolution")
    end
  end
  --print("getSlowResolutions - found slow resolutions", #slowResolutions)
  return slowResolutions
end

-- Returns a table of resolutions indexes that are "approved" to use
local function getSelectedResolutions()
  local options = {
    minResolutionIndex = 3, -- Slowest
    maxResolutionIndex = maxResolutionIndex, -- Fastest
    maxDotResolutionIndex = 18, -- Fastest dotted
    maxTriResolutionIndex = 25, -- Fastest triplet
  }
  return resolutions.getSelectedResolutions(resolutionsByType, options)
  --[[ local selectedResolutions = getSlowResolutions()
  for i=1,3 do
    for _,resolutionIndex in ipairs(resolutionsByType[i]) do
      -- Limit dotted/tri resolutions above 1/8 dot and 1/16 tri
      if resolutionIndex > maxResolutionIndex or (i == 2 and resolutionIndex > 18) or (i == 3 and resolutionIndex > 25) then
        break
      end
      table.insert(selectedResolutions, resolutionIndex)
    end
  end
  return selectedResolutions ]]
end

-- Auto generate fragment
-- durationType:
--    "Create fragment (even+dot)" 1
--    "Create fragment (even+tri)" 2
--    "Create fragment (extended)" 3
--    "Create fragment (slow)" 4
local function createFragmentDefinition(durationType)
  if type(durationType) == "nil" then
    durationType = 1
  end
  local currentDuration = 0
  local fragmentDurations = {1,2,3,4,8}
  local fragmentDuration = gem.getRandomFromTable(fragmentDurations) -- TODO Param?
  --print("Selected fragmentDuration", fragmentDuration)
  local durations = {}
  -- Add resolutions that can fit inside the fragmentDuration
  if durationType == 1 or durationType == 2 then -- Add even
    durations = addDurations({17,20,23}, durations, fragmentDuration)
  end
  if durationType == 1 then -- Add dotted
    durations = addDurations({15,18}, durations, fragmentDuration)
  end
  if durationType == 2 then -- Add tri
    durations = addDurations({19,22}, durations, fragmentDuration)
  end
  if durationType == 3 then
    -- Extended includes both long and short durations
    local extendedDurations = getSlowResolutions()
    for _,v in ipairs(fragmentDurations) do
      table.insert(extendedDurations, v)
    end
    fragmentDuration = resolutions.getResolution(gem.getRandomFromTable(extendedDurations))
    durations = addDurations(getSelectedResolutions(), durations, fragmentDuration)
  end
  if durationType == 4 then
    -- Slow durations
    local slowResolutions = getSlowResolutions()
    fragmentDuration = resolutions.getResolution(gem.getRandomFromTable(slowResolutions))
    --print("Selected fragmentDuration", fragmentDuration)
    durations = addDurations(slowResolutions, durations, fragmentDuration)
  end
  --print("Found durations", #durations)
  -- Select durations to fill the definition until the total fragment duration is reached
  local definition = {}
  while currentDuration < fragmentDuration do
    local duration = gem.getRandomFromTable(durations)
    if currentDuration + duration > fragmentDuration then
      duration = fragmentDuration - currentDuration
      --print("currentDuration + duration > fragmentDuration", currentDuration, duration, fragmentDuration)
    end
    currentDuration = currentDuration + duration
    table.insert(definition, duration)
    --print("Add duration", duration)
  end
  return definition
end

local function parseFragment(fragmentInputIndex)
  if type(fragmentInputIndex) == "nil" then
    return
  end
  local fragmentInput = paramsPerFragment[fragmentInputIndex].fragmentInput
  local fragmentPlayProbability = paramsPerFragment[fragmentInputIndex].fragmentPlayProbability.value
  local fragmentActive = paramsPerFragment[fragmentInputIndex].fragmentActive.value
  if fragmentActive and string.len(fragmentInput.text) > 0 and gem.getRandomBoolean(fragmentPlayProbability) then
    local fragment = createFragmentFromText(fragmentInput.text)
    local selectProbability = 100
    local repeatProbability = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbability.value
    local repeatProbabilityDecay = paramsPerFragment[fragmentInputIndex].fragmentRepeatProbabilityDecay.value
    local minRepeats = paramsPerFragment[fragmentInputIndex].fragmentMinRepeats.value
    local reverseFragmentProbability = paramsPerFragment[fragmentInputIndex].reverseFragmentProbability.value
    local randomizeFragmentProbability = paramsPerFragment[fragmentInputIndex].randomizeFragmentProbability.value
    local restProbability = paramsPerFragment[fragmentInputIndex].restProbability.value
    -- i = the fragment input number
    -- f = the resolutions of the fragment definition (resolution name (1/8) or beat value (0.5))
    -- p = probability of include
    -- r = repeat probability
    -- d = repeat probability decay
    -- m = min repeats
    -- rev = reverse probability
    -- rnd = random order probability
    -- rst = rest randomization probability
    return {
      f=fragment,
      i=fragmentInputIndex,
      p=selectProbability,
      r=repeatProbability,
      d=repeatProbabilityDecay,
      m=minRepeats,
      rnd=randomizeFragmentProbability,
      rev=reverseFragmentProbability,
      rst=restProbability,
    }
  end
end

local function getSelectedFragments(fragmentIndexes)
  local selectedFragments = {}
  for i=1, #paramsPerFragment do
    local fragment = parseFragment(i)
    local includeFragment = type(fragmentIndexes) ~= "table" or gem.tableIncludes(fragmentIndexes, i)
    if type(fragment) == "table" and includeFragment then
      table.insert(selectedFragments, fragment)
    end
  end
  return selectedFragments
end

local function getFragment(fragmentIndexes, prevFragmentIndex)
  local selectedFragments = getSelectedFragments(fragmentIndexes)

  -- Remove the previous fragment to avoid repeat unless it is the only available fragment
  if #selectedFragments > 1 and type(prevFragmentIndex) == "number" and prevFragmentIndex > 0 then
    for i,v in ipairs(selectedFragments) do
      if v.i == prevFragmentIndex then
        table.remove(selectedFragments, i)
        break
      end
    end
  end

  local fragment = gem.getRandomFromTable(selectedFragments)

  if type(fragment) == "table" then
    return fragment
  end
end

local function flashFragmentActive(fragmentActive, duration)
  if type(duration) == "nil" then
    duration = 1
  end
  local flashDuration = math.min(150, beat2ms(duration))
  fragmentActive.textColourOn = "white"
  wait(flashDuration)
  fragmentActive.textColourOn = "black"
end

-- Get fragment state for storage
local function getFragmentState()
  local fragments = {}
  for i,v in ipairs(paramsPerFragment) do
    table.insert(fragments, {
      fragmentActive = v.fragmentActive.value,
      lockedForEvolve = v.lockedForEvolve.value,
      fragmentInput = v.fragmentInput.text,
      playProbability = v.fragmentPlayProbability.value,
      repeatProbability = v.fragmentRepeatProbability.value,
      repeatProbabilityDecay = v.fragmentRepeatProbabilityDecay.value,
      minRepeats = v.fragmentMinRepeats.value,
      reverseProbability = v.reverseFragmentProbability.value,
      randomizeProbability = v.randomizeFragmentProbability.value,
      restProbability = v.restProbability.value,
    })
  end
  return fragments
end

-- Set the fragment state based on the given state
local function setFragmentState(state)
  local fragments = state
  for i,v in ipairs(paramsPerFragment) do
    v.fragmentActive.value = fragments[i].fragmentActive
    v.lockedForEvolve.value = fragments[i].lockedForEvolve or false
    v.fragmentInput.text = fragments[i].fragmentInput
    v.fragmentPlayProbability.value = fragments[i].playProbability
    v.fragmentRepeatProbability.value = fragments[i].repeatProbability
    v.fragmentRepeatProbabilityDecay.value = fragments[i].repeatProbabilityDecay
    v.fragmentMinRepeats.value = fragments[i].minRepeats
    v.reverseFragmentProbability.value = fragments[i].reverseProbability
    v.randomizeFragmentProbability.value = fragments[i].randomizeProbability
    v.restProbability.value = fragments[i].restProbability
  end
end

-- Tries to adjust the given resolution by adjusting
-- length, and/or setting a even/dot/tri value variant
local function getResolutionFromCurrentIndex(currentResolution, adjustBias, dotOrTriProbaility)
  -- Include the resolutions that are available
  --local selectedResolutions = getSelectedResolutions()
  local options = {
    adjustBias=adjustBias,
    selectedResolutions=selectedResolutions,
    dotOrTriProbaility=dotOrTriProbaility,
    maxDotResolutionIndex = 18, -- Fastest dotted
    maxTriResolutionIndex = 25, -- Fastest triplet
  }
  return resolutions.getResolutionVariation(currentResolution, options)
  --[[ local currentIndex = gem.getIndexFromValue(currentResolution, resolutions.getResolutions())
  if type(currentIndex) == "nil" then
    return
  end

  -- Include the resolutions that are available
  local selectedResolutions = getSelectedResolutions()

  --print("BEFORE currentIndex", currentIndex)
  local resolutionIndex = currentIndex
  if gem.tableIncludes(resolutionsByType[2], currentIndex) then
    resolution = resolutions.getEvenFromDotted(resolutions.getResolution(currentIndex))
    --print("getEvenFromDotted", resolution)
  elseif gem.tableIncludes(resolutionsByType[3], currentIndex) then
    resolution = resolutions.getEvenFromTriplet(resolutions.getResolution(currentIndex))
    --print("getEvenFromTriplet", resolution)
  elseif gem.tableIncludes(resolutionsByType[1], currentIndex) or gem.tableIncludes(resolutionsByType[4], currentIndex) then
    resolution = resolutions.getResolution(currentIndex)
    --print("getEvenOrSlow", resolution)
  end
  if type(resolution) == "number" then
    local doubleOrHalf = gem.getRandomBoolean() -- 50/50 chance for double or half duration
    -- Double or half duration
    if doubleOrHalf then
      if type(adjustBias) == "nil" then
        adjustBias = 50
      end
      local doubleResIndex = gem.getIndexFromValue((resolution * 2), resolutions.getResolutions())
      if gem.getRandomBoolean(adjustBias) == false and type(doubleResIndex) == "number" and gem.tableIncludes(selectedResolutions, doubleResIndex) then
        resolution = resolutions.getResolution(doubleResIndex)
        --print("Slower resolution", resolution)
      else
        resolution = resolution / 2
        --print("Faster resolution", resolution)
      end
    end
    -- Set dotted (or tri) on duration if no change was done to the lenght, or probability hits
    if doubleOrHalf == false or gem.getRandomBoolean() then
      if gem.tableIncludes(resolutionsByType[3], currentIndex) then
        resolution = resolutions.getTriplet(resolution)
        --print("getTriplet", resolution)
      else
        local dottedResIndex = gem.getIndexFromValue(resolutions.getDotted(resolution), resolutions.getResolutions())
        if type(dottedResIndex) == "number" and gem.tableIncludes(selectedResolutions, dottedResIndex) then
          resolution = resolutions.getResolution(dottedResIndex)
          --print("getDotted", resolution)
        end
      end
    end
  end
  currentIndex = gem.getIndexFromValue(resolution, resolutions.getResolutions())
  --print("AFTER currentIndex", currentIndex)
  if type(currentIndex) == "number" and gem.tableIncludes(selectedResolutions, currentIndex) then
    --print("Got resolution from the current index")
    return resolutions.getResolution(currentIndex)
  end ]]
end

-- Remove first resolution and append a (new) resolution last in the fragments
-- Returns the removed resolution (or nil if no resolution was removed for some reason)
local function evolveFragment(fragmentIndex, previous, randomizeCurrentResolutionProbability, adjustBias)
  local fragment = parseFragment(fragmentIndex)
  local removed = nil
  if type(fragment) == "table" then
    removed = fragment.f[1]
    table.remove(fragment.f, 1) -- Remove first

    -- Holds the evolved resolution
    local resolution = nil

    -- Select evolve strategy

    -- Strategy 1: Create a resolution based on the current index
    if type(randomizeCurrentResolutionProbability) == "number" and gem.getRandomBoolean(randomizeCurrentResolutionProbability) then
      resolution = getResolutionFromCurrentIndex(removed, adjustBias)
    end

    -- Strategy 2: Use resolution from the previous fragment
    local usePreviousResolutionProbability = 75 -- TODO Param?
    if type(resolution) == "nil" and gem.getRandomBoolean(usePreviousResolutionProbability) then
      resolution = previous
      --print("Got resolution from the previous fragment")
    end

    -- Strategy 3: Get a resolution from the evolve memory
    if type(resolution) == "nil" then
      --print("Got resolution from the evolve memory")
      resolution = gem.getRandomFromTable(resolutionsForEvolve)
    end

    -- Set the resolution on the fragment, and update fragment input text
    table.insert(fragment.f, resolution)
    --print("Found resolution for evolve", resolution)
    paramsPerFragment[fragmentIndex].fragmentInput.text = getFragmentInputText(fragmentDefinitionToResolutionNames(fragment.f))
  end
  return removed
end

local function clearResolutionsForEvolve()
  resolutionsForEvolve = {}
end

local function removeDuplicates()
  local removeAmount = 0
  local uniqueResolutions = {}
  for _,v in ipairs(resolutionsForEvolve) do
    if gem.tableIncludes(uniqueResolutions, v) == false then
      table.insert(uniqueResolutions, v)
    else
      removeAmount = removeAmount + 1
      --print("Removing duplicate duration", v)
    end
  end
  resolutionsForEvolve = uniqueResolutions
  return removeAmount
end

local function setResolutionsForEvolve()
  local numFragments = #paramsPerFragment
  -- Remove the duplicates resolutions if memory is full
  if #resolutionsForEvolve > math.ceil(numFragments ^ 2.5) then
    local removeAmount = removeDuplicates()
    --print("Removed from resolutionsForEvolve", removeAmount)
  end
  -- Find all resolutions that are present in the current fragments, and add to evolve memory
  for i=1,numFragments do
    local fragment = parseFragment(i)
    if type(fragment) == "table" then
      for _,v in ipairs(fragment.f) do
        -- TODO Check that no resolution "takes over" if there are few resolutions to choose from
        table.insert(resolutionsForEvolve, v)
        --print("Add to resolutionsForEvolve", v)
      end
    end
  end
  --print("Total resolutionsForEvolve", #resolutionsForEvolve)
end

local function evolveFragments(previous, randomizeCurrentResolutionProbability, adjustBias)
  setResolutionsForEvolve()
  for i,v in ipairs(paramsPerFragment) do
    if v.lockedForEvolve.value == false and string.len(v.fragmentInput.text) > 0 then
      previous = evolveFragment(i, previous, randomizeCurrentResolutionProbability, adjustBias)
    end
  end
  return previous
end

local function getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
  local isRepeat = false
  local mustRepeat = false
  local duration = nil
  local rest = false
  local isFragmentStart = type(activeFragment) == "nil" or (reverseFragment == false and fragmentPos == #activeFragment.f) or (reverseFragment and fragmentPos == 1)
  if isFragmentStart then
    -- Start fragment (previous fragment is completed or no fragemt is selected)
    fragmentRepeatCount = fragmentRepeatCount + 1
    -- Check modulo for grouping/required number of repeats
    if type(activeFragment) == "table" and type(activeFragment.m) == "number" then
      --print("***MustRepeat?*** fragmentRepeatCount % activeFragment.m", fragmentRepeatCount, activeFragment.m, (fragmentRepeatCount % activeFragment.m))
      mustRepeat = fragmentRepeatCount % activeFragment.m > 0
    end

    -- Reload fragment in case parameters are changed
    if type(activeFragment) == "table" then
      local fragment = parseFragment(activeFragment.i)
      if type(fragment) == "table" or mustRepeat == false then
        activeFragment = fragment
      end
    end

    --print("FRAGMENT fragmentRepeatCount, mustRepeat", fragmentRepeatCount, mustRepeat)
    if type(activeFragment) == "table" and (mustRepeat or gem.getRandomBoolean(fragmentRepeatProbability)) then
      -- REPEAT FRAGMENT
      isRepeat = true
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      --print("REPEAT FRAGMENT, activeFragment.i, fragmentRepeatProbability", activeFragment.i, fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      fragmentRepeatCount = 0 -- Init repeat counter
      -- Register old fragemnt index (if any)
      local prevFragmentIndex = nil
      if type(activeFragment) == "table" then
        prevFragmentIndex = activeFragment.i
      end
      -- Change to a new fragment input
      activeFragment = getFragment(sources, prevFragmentIndex)
      if type(activeFragment) == "table" then
        isRepeat = prevFragmentIndex == activeFragment.i -- Check if same as previous
        fragmentRepeatProbability = activeFragment.r
      end
      --print("CHANGE FRAGMENT, isRepeat, fragmentRepeatProbability", isRepeat, fragmentRepeatProbability)
    end
    -- RANDOMIZE fragment
    randomizeFragment = type(activeFragment) == "table" and #activeFragment.f > 1 and gem.getRandomBoolean(activeFragment.rnd)
    if randomizeFragment then
      local tmp = {}
      local seen = {}
      local maxRounds = 100
      while #seen < #activeFragment.f and maxRounds > 0 do
        local i = gem.getRandom(#activeFragment.f)
        --print("maxRounds outer", maxRounds)
        while gem.tableIncludes(seen, i) do
          i = gem.getRandom(#activeFragment.f)
          maxRounds = maxRounds - 1
          --print("maxRounds inner", maxRounds)
        end
        table.insert(tmp, activeFragment.f[i])
        table.insert(seen, i)
        --print("#seen, i", #seen, i)
      end
      activeFragment.f = tmp
      --print("randomizeFragment")
    end
    -- REVERSE fragment
    reverseFragment = type(activeFragment) == "table" and #activeFragment.f > 1 and gem.getRandomBoolean(activeFragment.rev)
    if reverseFragment then
      --print("REVERSE fragment", reverseFragment)
      fragmentPos = #activeFragment.f
    else
      fragmentPos = 1
    end
    --print("SET fragmentPos", fragmentPos)
  else
    -- INCREMENT fragment pos
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    --print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  if type(activeFragment) == "table" then
    -- Get duration at current position
    duration = activeFragment.f[fragmentPos]
    -- A negative duration means a rest
    if duration < 0 then
      rest = gem.getRandomBoolean(activeFragment.rst) == false -- Apply randomization
      duration = math.abs(duration)
      --print("Rest detected for duration in activeFragment.i at fragmentPos, rest", duration, activeFragment.i, fragmentPos, rest)
    else
      rest = gem.getRandomBoolean(activeFragment.rst) -- Apply randomization
    end
  end

  return duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount
end

local function getParamsPerFragment(rythmPanel, rythmLabel, colours, numSelectors, x, y)
  if type(numSelectors) == "nil" then
    numSelectors = 4
  end
  if type(x) == "nil" then
    x = 0
  end
  if type(y) == "nil" then
    y = 0
  end
  local perColumn = 2
  local rowCounter = 0
  local columnCounter = 0
  for i=1,numSelectors do
    local offsetX = 354
    local offsetY = 100
    local defaultResolution = ""

    offsetX = (offsetX * columnCounter) + x
    offsetY = (offsetY * rowCounter) + 30 + y
  
    if i == 1 then
      defaultResolution = "1/8"
    end

    -- Increment counters
    columnCounter = columnCounter + 1
    if columnCounter >= perColumn then
      columnCounter = 0
      rowCounter = rowCounter + 1
    end

    local fragmentActive = rythmPanel:OnOffButton("FragmentActive" .. i, true)
    fragmentActive.backgroundColourOff = colours.backgroundColourOff
    fragmentActive.backgroundColourOn = colours.backgroundColourOn
    fragmentActive.textColourOff = "black"
    fragmentActive.textColourOn = "black"
    fragmentActive.fontSize = 20
    fragmentActive.displayName = "" .. i
    fragmentActive.tooltip = "Toggle fragment on/off"
    fragmentActive.size = {24,24}
    if type(rythmLabel) == "nil" then
      fragmentActive.x = offsetX
      fragmentActive.y = offsetY
    else
      fragmentActive.x = rythmLabel.x + offsetX
      fragmentActive.y = rythmLabel.y + rythmLabel.height + offsetY
    end

    local lockedForEvolve = rythmPanel:OnOffButton("LockedForEvolve" .. i, false)
    lockedForEvolve.backgroundColourOff = colours.backgroundColourOff
    lockedForEvolve.backgroundColourOn = colours.backgroundColourOn
    lockedForEvolve.textColourOff = "black"
    lockedForEvolve.textColourOn = "black"
    --lockedForEvolve.normalImage = "../resources/icons/lock_open.png"
    --lockedForEvolve.pressedImage = "../resources/icons/lock_closed.png"
    lockedForEvolve.fontSize = 14
    lockedForEvolve.displayName = "L"
    lockedForEvolve.tooltip = "Set fragment locked for evolve"
    lockedForEvolve.size = {24,20}
    lockedForEvolve.x = fragmentActive.x
    lockedForEvolve.y = fragmentActive.y + fragmentActive.height + 3

    -- Fragment Input
    local fragmentInput = rythmPanel:Label("FragmentInput" .. i)
    fragmentInput.text = defaultResolution
    fragmentInput.label = "Fragment definition. Use resolution names (1/8) or beat values (0.5), separated by comma (,). Prefix resolution with '-' (minus) for rests. Click to type, or select from the menus."
    fragmentInput.tooltip = fragmentInput.label
    fragmentInput.editable = true
    fragmentInput.backgroundColour = colours.labelTextColour
    fragmentInput.backgroundColourWhenEditing = "white"
    fragmentInput.textColour = "white"
    fragmentInput.textColourWhenEditing = colours.labelTextColour
    fragmentInput.x = fragmentActive.x + fragmentActive.width + 3
    fragmentInput.y = fragmentActive.y + 0
    fragmentInput.width = 235
    fragmentInput.height = 24
    fragmentInput.fontSize = 14
    fragmentInput.changed = function(self)
      local total = calculateFragmentDuration(self.text)
      if total == 0 then
        fragmentInput.tooltip = fragmentInput.label
      else
        fragmentInput.tooltip = "Total beat duration is " .. total
      end
      paramsPerFragment[i].fragmentInputDirty = true
    end
  
    -- Menus
    --    "Create fragment (even+dot)" 1
    --    "Create fragment (even+tri)" 2
    --    "Create fragment (extended)" 3
    --    "Create fragment (slow)" 4
    local actions = {"Actions...", "Create fragment (even+dot)", "Create fragment (even+tri)", "Create fragment (extended)", "Create fragment (slow)"}
    local fragmentActions = rythmPanel:Menu("FragmentActions" .. i, actions)
    fragmentActions.tooltip = "Select an action (replaces current input!)"
    fragmentActions.showLabel = false
    fragmentActions.height = 20
    fragmentActions.width = 75
    fragmentActions.x = fragmentInput.x
    fragmentActions.y = fragmentInput.y - 24
    fragmentActions.backgroundColour = colours.menuBackgroundColour
    fragmentActions.textColour = colours.widgetTextColour
    fragmentActions.arrowColour = colours.menuArrowColour
    fragmentActions.outlineColour = colours.menuOutlineColour
    fragmentActions.changed = function(self)
      if self.value > 1 then
        -- Create
        local fragmentDefinition = fragmentDefinitionToResolutionNames(createFragmentDefinition(self.value-1))
        --print("#fragmentDefinition", #fragmentDefinition)
        fragmentInput.text = getFragmentInputText(fragmentDefinition)
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local resolutionNames = resolutions.getResolutionNames()
    local addToFragment = {"Add..."}
    for _,v in ipairs(resolutionNames) do
      table.insert(addToFragment, v)
    end
  
    local fragmentAdd = rythmPanel:Menu("FragmentAdd" .. i, addToFragment)
    fragmentAdd.tooltip = "Add to the fragment"
    fragmentAdd.showLabel = false
    fragmentAdd.height = 20
    fragmentAdd.width = fragmentActions.width
    fragmentAdd.x = fragmentActions.x + fragmentActions.width + 5
    fragmentAdd.y = fragmentActions.y
    fragmentAdd.backgroundColour = colours.menuBackgroundColour
    fragmentAdd.textColour = colours.widgetTextColour
    fragmentAdd.arrowColour = colours.menuArrowColour
    fragmentAdd.outlineColour = colours.menuOutlineColour
    fragmentAdd.changed = function(self)
      if string.len(fragmentInput.text) == 0 then
        fragmentInput.text = self.selectedText
      else
        fragmentInput.text = fragmentInput.text .. "," .. self.selectedText
      end
      -- Must be last
      self:setValue(1, false)
    end
  
    local loadFragment = {"Load..."}
    for _,v in ipairs(resolutionFragments) do
      table.insert(loadFragment, getFragmentInputText(v))
    end
  
    local fragmentLoad = rythmPanel:Menu("FragmentLoad" .. i, loadFragment)
    fragmentLoad.tooltip = "Load fragment (replaces current input!)"
    fragmentLoad.showLabel = false
    fragmentLoad.height = 20
    fragmentLoad.width = fragmentActions.width
    fragmentLoad.x = fragmentAdd.x + fragmentAdd.width + 5
    fragmentLoad.y = fragmentAdd.y
    fragmentLoad.backgroundColour = colours.menuBackgroundColour
    fragmentLoad.textColour = colours.widgetTextColour
    fragmentLoad.arrowColour = colours.menuArrowColour
    fragmentLoad.outlineColour = colours.menuOutlineColour
    fragmentLoad.changed = function(self)
      fragmentInput.text = self.selectedText
      -- Must be last
      self:setValue(1, false)
    end
  
    -- Add p = play probability
    local fragmentPlayProbabilityLabel = rythmPanel:Label("FragmentPlayProbabilityLabel" .. i)
    fragmentPlayProbabilityLabel.text = "p"
    fragmentPlayProbabilityLabel.tooltip = "Probability that this fragment will be selected"
    fragmentPlayProbabilityLabel.textColour = colours.labelTextColour
    fragmentPlayProbabilityLabel.alpha = 0.5
    fragmentPlayProbabilityLabel.fontSize = 20
    fragmentPlayProbabilityLabel.width = 20
    fragmentPlayProbabilityLabel.x = fragmentInput.x
    fragmentPlayProbabilityLabel.y = fragmentInput.y + fragmentInput.height + 3
  
    local fragmentPlayProbability = rythmPanel:NumBox("FragmentPlayProbability" .. i, 100, 0, 100, true)
    fragmentPlayProbability.unit = Unit.Percent
    fragmentPlayProbability.showLabel = false
    fragmentPlayProbability.tooltip = fragmentPlayProbabilityLabel.tooltip
    fragmentPlayProbability.textColour = colours.widgetTextColour
    fragmentPlayProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentPlayProbability.width = 36
    fragmentPlayProbability.x = fragmentPlayProbabilityLabel.x + fragmentPlayProbabilityLabel.width - 1
    fragmentPlayProbability.y = fragmentPlayProbabilityLabel.y
  
    -- Add r = repeat probability
    local fragmentRepeatProbabilityLabel = rythmPanel:Label("FragmentRepeatProbabilityLabel" .. i)
    fragmentRepeatProbabilityLabel.text = "r"
    fragmentRepeatProbabilityLabel.tooltip = "Probability that this fragment will be repeated"
    fragmentRepeatProbabilityLabel.textColour = colours.labelTextColour
    fragmentRepeatProbabilityLabel.alpha = 0.5
    fragmentRepeatProbabilityLabel.fontSize = 20
    fragmentRepeatProbabilityLabel.width = fragmentPlayProbabilityLabel.width
    fragmentRepeatProbabilityLabel.x = fragmentPlayProbability.x + fragmentPlayProbability.width + 5
    fragmentRepeatProbabilityLabel.y = fragmentPlayProbability.y
  
    local fragmentRepeatProbability = rythmPanel:NumBox("FragmentRepeatProbability" .. i, 100, 0, 100, true)
    fragmentRepeatProbability.unit = Unit.Percent
    fragmentRepeatProbability.showLabel = false
    fragmentRepeatProbability.tooltip = fragmentRepeatProbabilityLabel.tooltip
    fragmentRepeatProbability.textColour = colours.widgetTextColour
    fragmentRepeatProbability.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbability.width = fragmentPlayProbability.width
    fragmentRepeatProbability.x = fragmentRepeatProbabilityLabel.x + fragmentRepeatProbabilityLabel.width - 1
    fragmentRepeatProbability.y = fragmentRepeatProbabilityLabel.y
  
    -- Add d = repeat probability decay
    local fragmentRepeatProbabilityDecayLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentRepeatProbabilityDecayLabel.text = "d"
    fragmentRepeatProbabilityDecayLabel.tooltip = "The reduction in repeat probability for each iteration of the fragment"
    fragmentRepeatProbabilityDecayLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentRepeatProbabilityDecayLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentRepeatProbabilityDecayLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentRepeatProbabilityDecayLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentRepeatProbabilityDecayLabel.x = fragmentRepeatProbability.x + fragmentRepeatProbability.width + 5
    fragmentRepeatProbabilityDecayLabel.y = fragmentRepeatProbability.y
  
    local fragmentRepeatProbabilityDecay = rythmPanel:NumBox("FragmentRepeatProbabilityDecay" .. i, 25, 0, 100, true)
    fragmentRepeatProbabilityDecay.unit = Unit.Percent
    fragmentRepeatProbabilityDecay.showLabel = false
    fragmentRepeatProbabilityDecay.tooltip = fragmentRepeatProbabilityDecayLabel.tooltip
    fragmentRepeatProbabilityDecay.textColour = colours.widgetTextColour
    fragmentRepeatProbabilityDecay.backgroundColour = colours.widgetBackgroundColour
    fragmentRepeatProbabilityDecay.width = fragmentRepeatProbability.width
    fragmentRepeatProbabilityDecay.x = fragmentRepeatProbabilityDecayLabel.x + fragmentRepeatProbabilityDecayLabel.width - 1
    fragmentRepeatProbabilityDecay.y = fragmentRepeatProbabilityDecayLabel.y
  
    -- Add m = min repeats
    local fragmentMinRepeatsLabel = rythmPanel:Label("FragmentRepeatProbabilityDecayLabel" .. i)
    fragmentMinRepeatsLabel.text = "m"
    fragmentMinRepeatsLabel.tooltip = "Minimum repeats for this fragment"
    fragmentMinRepeatsLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    fragmentMinRepeatsLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    fragmentMinRepeatsLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    fragmentMinRepeatsLabel.width = fragmentRepeatProbabilityLabel.width
    fragmentMinRepeatsLabel.x = fragmentRepeatProbabilityDecay.x + fragmentRepeatProbabilityDecay.width + 5
    fragmentMinRepeatsLabel.y = fragmentRepeatProbabilityDecay.y
  
    local fragmentMinRepeats = rythmPanel:NumBox("FragmentMinRepeats" .. i, 1, 1, 64, true)
    fragmentMinRepeats.showLabel = false
    fragmentMinRepeats.tooltip = fragmentMinRepeatsLabel.tooltip
    fragmentMinRepeats.textColour = colours.widgetTextColour
    fragmentMinRepeats.backgroundColour = colours.widgetBackgroundColour
    fragmentMinRepeats.width = 26
    fragmentMinRepeats.x = fragmentMinRepeatsLabel.x + fragmentMinRepeatsLabel.width - 1
    fragmentMinRepeats.y = fragmentMinRepeatsLabel.y
  
    -- Randomize fragment probability
    local randomizeFragmentProbabilityLabel = rythmPanel:Label("RandomizeFragmentProbabilityLabel" .. i)
    randomizeFragmentProbabilityLabel.text = "rnd"
    randomizeFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    randomizeFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    randomizeFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    randomizeFragmentProbabilityLabel.width = 30
    randomizeFragmentProbabilityLabel.x = fragmentLoad.x + fragmentLoad.width + 0
    randomizeFragmentProbabilityLabel.y = fragmentLoad.y
  
    local randomizeFragmentProbability = rythmPanel:NumBox("RandomizeFragmentProbability" .. i, 0, 0, 100, true)
    randomizeFragmentProbability.unit = Unit.Percent
    randomizeFragmentProbability.showLabel = false
    randomizeFragmentProbability.tooltip = "Probability that rythmic fragments will be played in random order"
    randomizeFragmentProbability.textColour = colours.widgetTextColour
    randomizeFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    randomizeFragmentProbability.width = fragmentRepeatProbability.width
    randomizeFragmentProbability.x = randomizeFragmentProbabilityLabel.x + randomizeFragmentProbabilityLabel.width - 1
    randomizeFragmentProbability.y = randomizeFragmentProbabilityLabel.y
  
    -- Reverse fragment probability
    local reverseFragmentProbabilityLabel = rythmPanel:Label("ReverseFragmentProbabilityLabel" .. i)
    reverseFragmentProbabilityLabel.text = "rev"
    reverseFragmentProbabilityLabel.tooltip = "Probability that rythmic fragments will be played backwards"
    reverseFragmentProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    reverseFragmentProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    reverseFragmentProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    reverseFragmentProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    reverseFragmentProbabilityLabel.x = randomizeFragmentProbabilityLabel.x
    reverseFragmentProbabilityLabel.y = fragmentInput.y + 2
  
    local reverseFragmentProbability = rythmPanel:NumBox("ReverseProbability" .. i, 0, 0, 100, true)
    reverseFragmentProbability.unit = Unit.Percent
    reverseFragmentProbability.showLabel = false
    reverseFragmentProbability.tooltip = reverseFragmentProbabilityLabel.tooltip
    reverseFragmentProbability.textColour = colours.widgetTextColour
    reverseFragmentProbability.backgroundColour = colours.widgetBackgroundColour
    reverseFragmentProbability.width = fragmentRepeatProbability.width
    reverseFragmentProbability.x = reverseFragmentProbabilityLabel.x + reverseFragmentProbabilityLabel.width - 1
    reverseFragmentProbability.y = reverseFragmentProbabilityLabel.y
  
    -- Rest probability
    local restProbabilityLabel = rythmPanel:Label("RestProbabilityLabel" .. i)
    restProbabilityLabel.text = "rst"
    restProbabilityLabel.tooltip = "Probability of rest randomization"
    restProbabilityLabel.textColour = fragmentRepeatProbabilityLabel.textColour
    restProbabilityLabel.alpha = fragmentRepeatProbabilityLabel.alpha
    restProbabilityLabel.fontSize = fragmentRepeatProbabilityLabel.fontSize
    restProbabilityLabel.width = randomizeFragmentProbabilityLabel.width
    restProbabilityLabel.x = reverseFragmentProbabilityLabel.x
    restProbabilityLabel.y = fragmentMinRepeats.y
  
    local restProbability = rythmPanel:NumBox("RestProbability" .. i, 0, 0, 100, true)
    restProbability.unit = Unit.Percent
    restProbability.showLabel = false
    restProbability.tooltip = restProbabilityLabel.tooltip
    restProbability.textColour = colours.widgetTextColour
    restProbability.backgroundColour = colours.widgetBackgroundColour
    restProbability.width = fragmentRepeatProbability.width
    restProbability.x = restProbabilityLabel.x + restProbabilityLabel.width - 1
    restProbability.y = restProbabilityLabel.y

    table.insert(paramsPerFragment, {fragmentInput=fragmentInput, fragmentInputDirty=false, fragmentActive=fragmentActive, lockedForEvolve=lockedForEvolve, fragmentPlayProbability=fragmentPlayProbability, randomizeFragmentProbability=randomizeFragmentProbability, reverseFragmentProbability=reverseFragmentProbability, restProbability=restProbability, fragmentRepeatProbability=fragmentRepeatProbability, fragmentRepeatProbabilityDecay=fragmentRepeatProbabilityDecay, fragmentMinRepeats=fragmentMinRepeats})
  end
  return paramsPerFragment
end

local rythmicFragments = {
  resolutions = resolutions,
  getParamsPerFragment = getParamsPerFragment,
  getDuration = getDuration,
  evolveFragments = evolveFragments,
  clearResolutionsForEvolve = clearResolutionsForEvolve,
  getSelectedResolutions = getSelectedResolutions,
  getFragmentState = getFragmentState,
  setFragmentState = setFragmentState,
  flashFragmentActive = flashFragmentActive,
  createFragmentDefinition = createFragmentDefinition,
  getFragmentInputText = getFragmentInputText,
  fragmentDefinitionToResolutionNames = fragmentDefinitionToResolutionNames,
  setMaxResolutionIndex = setMaxResolutionIndex,
}

--------------------------------------------------------------------------------
-- Drunken Sequencer
--------------------------------------------------------------------------------

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "white"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"

local colours = {
  backgroundColour = backgroundColour,
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = labelTextColour,
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
}

local voices = 1
local notesPlaying = {}
local isPlaying = {}

--------------------------------------------------------------------------------
-- Panel Definitions
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local sequencerPanel = Panel("Sequencer")
sequencerPanel.backgroundColour = backgroundColour
sequencerPanel.x = 10
sequencerPanel.y = 10
sequencerPanel.width = 700
sequencerPanel.height = 30

local settingsPanel = Panel("Settings")
settingsPanel.backgroundColour = "404040"
settingsPanel.x = sequencerPanel.x
settingsPanel.y = sequencerPanel.y + sequencerPanel.height + 5
settingsPanel.width = 700
settingsPanel.height = 85

local notePanel = Panel("Notes")
notePanel.backgroundColour = "404040"
notePanel.x = settingsPanel.x
notePanel.y = settingsPanel.y + settingsPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local rythmPanel = Panel("Rythm")
rythmPanel.backgroundColour = "404040"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 215

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local sequencerLabel = sequencerPanel:Label("Label")
sequencerLabel.text = "Drunken Sequencer"
sequencerLabel.alpha = 0.5
sequencerLabel.backgroundColour = labelBackgoundColour
sequencerLabel.textColour = labelTextColour
sequencerLabel.fontSize = 22
sequencerLabel.width = 170
sequencerLabel.x = 0

meter = sequencerPanel:AudioMeter("OutputLevel", Part, false, 0, true)
meter.height = sequencerLabel.height
meter.width = sequencerLabel.width
meter.x = sequencerLabel.x + sequencerLabel.width + 15
meter.y = sequencerLabel.y
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "yellow"
meter["10dBColour"] = "green"

local channelOffset = sequencerPanel:NumBox("ChannelOffset", 1, 1, 16, true)
channelOffset.textColour = widgetTextColour
channelOffset.backgroundColour = widgetBackgroundColour
channelOffset.enabled = false
channelOffset.showLabel = false
channelOffset.displayName = "Offset"
channelOffset.tooltip = "When multichannel is enabled, each voice is assigned to separate channels starting from this channel"
channelOffset.size = {22,22}
channelOffset.x = sequencerPanel.width - 337
channelOffset.y = 5

local channelButton = sequencerPanel:OnOffButton("ChannelButton", false)
channelButton.backgroundColourOff = "#ff084486"
channelButton.backgroundColourOn = "#ff02ACFE"
channelButton.textColourOff = "#ff22FFFF"
channelButton.textColourOn = "#efFFFFFF"
channelButton.displayName = "Multichannel"
channelButton.tooltip = "When multichannel mode is enabled, each voice is sent to a separate channel"
channelButton.size = {100,22}
channelButton.x = channelOffset.x + channelOffset.width + 5
channelButton.y = channelOffset.y
channelButton.changed = function(self)
  channelOffset.enabled = self.value
end

local autoplayButton = sequencerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = channelButton.size
autoplayButton.x = channelButton.x + channelButton.width + 5
autoplayButton.y = channelButton.y

local playButton = sequencerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = autoplayButton.size
playButton.x = autoplayButton.x + autoplayButton.width + 5
playButton.y = channelButton.y
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsLabel = settingsPanel:Label("SettingsLabel")
settingsLabel.text = "Settings"
settingsLabel.alpha = 0.75
settingsLabel.fontSize = 15
settingsLabel.width = 350

--- First row ---

local noteRandomization = settingsPanel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Movement"
noteRandomization.tooltip = "Random note movement amount - a small amount gives small steps between notes"
noteRandomization.size = {163,20}
noteRandomization.x = 5
noteRandomization.y = settingsLabel.y + settingsLabel.height + 5

local noteDirection = settingsPanel:NumBox("NoteDirection", 50, 0, 100, true)
noteDirection.unit = Unit.Percent
noteDirection.textColour = widgetTextColour
noteDirection.backgroundColour = widgetBackgroundColour
noteDirection.displayName = "Direction"
noteDirection.tooltip = "Affect the random note movement by specifying the probability of direction. <50% = more down, >50% = more up, 50% = equal chance"
noteDirection.size = noteRandomization.size
noteDirection.x = noteRandomization.x + noteRandomization.width + 10
noteDirection.y = noteRandomization.y

local randomReset = settingsPanel:OnOffButton("RandomReset", true)
randomReset.enabled = false
randomReset.backgroundColourOff = "#ff084486"
randomReset.backgroundColourOn = "#ff02ACFE"
randomReset.textColourOff = "#ff22FFFF"
randomReset.textColourOn = "#efFFFFFF"
randomReset.displayName = "Random Reset"
randomReset.tooltip = "When direction is biased (above or below 50%), use random reset to start from a random note when highest or lowest note is reached"
randomReset.size = noteDirection.size
randomReset.x = noteDirection.x + noteDirection.width + 10
randomReset.y = noteDirection.y

local voicesInput = settingsPanel:NumBox("Voices", voices, 1, 4, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Number of voices playing"
voicesInput.size = noteDirection.size
voicesInput.x = randomReset.x + randomReset.width + 10
voicesInput.y = randomReset.y
voicesInput.changed = function(self)
  voices = self.value
end

noteDirection.changed = function(self)
  randomReset.enabled = self.value ~= 50
end

--- Second row ---

local gateInput = settingsPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Default gate"
gateInput.size = noteDirection.size
gateInput.x = noteRandomization.x
gateInput.y = noteDirection.y + noteDirection.height + 5

local gateRandomization = settingsPanel:NumBox("GateRandomization", 25, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x + gateInput.width + 10
gateRandomization.y = gateInput.y

local velocityInput = settingsPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x + gateRandomization.width + 10
velocityInput.y = gateInput.y

local velocityAccent = settingsPanel:NumBox("VelocityAccent", 64, 1, 127, true)
velocityAccent.textColour = widgetTextColour
velocityAccent.backgroundColour = widgetBackgroundColour
velocityAccent.displayName = "Accent"
velocityAccent.tooltip = "Velocity accent amount triggered at the start of a fragment"
velocityAccent.size = velocityInput.size
velocityAccent.x = velocityInput.x + velocityInput.width + 10
velocityAccent.y = velocityInput.y

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 50

local clearNotes = notePanel:Button("ClearNotes")
clearNotes.displayName = "Clear notes"
clearNotes.tooltip = "Deselect all notes"
clearNotes.persistent = false
clearNotes.height = noteLabel.height
clearNotes.width = 90
clearNotes.x = notePanel.width - (clearNotes.width * 3) - 30
clearNotes.y = 5
clearNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(false)
  end
end

local addNotes = notePanel:Button("AddNotes")
addNotes.displayName = "All notes"
addNotes.tooltip = "Select all notes"
addNotes.persistent = false
addNotes.height = noteLabel.height
addNotes.width = 90
addNotes.x = clearNotes.x + clearNotes.width + 10
addNotes.y = 5
addNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(true)
  end
end

local randomizeNotes = notePanel:Button("RandomizeNotes")
randomizeNotes.displayName = "Randomize notes"
randomizeNotes.tooltip = "Randomize all notes"
randomizeNotes.persistent = false
randomizeNotes.height = noteLabel.height
randomizeNotes.width = 90
randomizeNotes.x = addNotes.x + addNotes.width + 10
randomizeNotes.y = 5
randomizeNotes.changed = function()
  for _,v in ipairs(noteInputs) do
    v:setValue(gem.getRandomBoolean())
  end
end

noteSelector.createNoteAndOctaveSelector(notePanel, colours, noteLabel)

--------------------------------------------------------------------------------
-- Rythm Panel
--------------------------------------------------------------------------------

local rythmLabel = rythmPanel:Label("RythmLabel")
rythmLabel.text = "Rythmic fragments"
rythmLabel.alpha = 0.75
rythmLabel.fontSize = 15
rythmLabel.width = 153

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

function generateNote(currentNote)
  local selectedNotes = noteSelector.getSelectedNotes() -- Holds note numbers that are available

  if #selectedNotes == 0 then
    return nil
  end

  if #selectedNotes == 1 then
    return selectedNotes[1]
  end

  local noteIndex = 1
  local currentIndex = gem.getIndexFromValue(currentNote, selectedNotes)

  if type(currentNote) == "nil" or type(currentIndex) == "nil" then
    noteIndex = gem.getRandom(#selectedNotes)
    --print("Get random note index", noteIndex)
  else
    local noteDirectionProbability = noteDirection.value
    local goUp = gem.getRandomBoolean(noteDirectionProbability)
    local resetFull = randomReset.value == false
    if noteDirectionProbability == 50 then
      -- Equal up/down
      noteIndex = gem.randomizeValue(currentIndex, 1, #selectedNotes, noteRandomization.value)
      --print("Equal up/down noteIndex/currentIndex", noteIndex, currentIndex)
    elseif goUp and (currentIndex < #selectedNotes or resetFull) then
      if currentIndex == #selectedNotes then
        noteIndex = 1 -- Reset to lowest index
      else
        noteIndex = gem.randomizeValue(currentIndex, currentIndex, #selectedNotes, noteRandomization.value)
      end
      print("Up noteIndex/currentIndex", noteIndex, currentIndex)
    elseif currentIndex > 1 or resetFull then
      if currentIndex == 1 then
        noteIndex = #selectedNotes -- Reset to max index
      else
        noteIndex = gem.randomizeValue(currentIndex, 1, currentIndex, noteRandomization.value)
      end
      print("Down noteIndex/currentIndex", noteIndex, currentIndex)
    else
      noteIndex = gem.getRandom(#selectedNotes)
      print("Random note index", noteIndex)
    end
  end

  return selectedNotes[noteIndex]
end

function getGate()
  return gem.randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
end

function startPlaying()
  if #isPlaying > 1 then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if #isPlaying == 0 then
    return
  end
  isPlaying = {}
  notesPlaying = {}
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sequenceRunner()
  --local previous = nil
  local currentVoices = 0
  repeat
    if currentVoices ~= voices then
      isPlaying = {}
      for i=1,voices do
        table.insert(isPlaying, i)
        if i > currentVoices then
          spawn(play, i)
        end
      end
      currentVoices = #isPlaying
    end
    local baseDuration = 4
    waitBeat(baseDuration)
  until #isPlaying == 0
end

function play(voice)
  local note = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  while isPlaying[voice] == voice do
    local channel = nil
    if channelButton.value then
      channel = voice + channelOffset.value - 1
    end
    note = generateNote(note)
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount)
    local doPlayNote = rest == false and type(note) == "number" and type(duration) == "number"
    if doPlayNote then
      local gate = getGate()
      local velocity = velocityInput.value
      -- Use accent value in fragment start, if there is more than one resolution defined in the fragment
      if isFragmentStart and #activeFragment.f > 1 then
        velocity = velocityAccent.value
      end
      playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
      table.insert(notesPlaying, note) -- Register
      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
        end
      end
    end
    if type(duration) == "nil" then
      duration = 1 -- Failsafe
    end
    waitBeat(duration)
    if doPlayNote then
      table.remove(notesPlaying, gem.getIndexFromValue(note, notesPlaying)) -- Remove
    end
  end
end

--------------------------------------------------------------------------------
-- Handle note events
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
  local fragmentInputData = {}

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  return {fragmentInputData}
end

function onLoad(data)
  local fragmentInputData = data[1]

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end
end
