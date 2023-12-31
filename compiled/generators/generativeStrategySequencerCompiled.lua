-- generators/generativeStrategySequencer -- 
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

local function createRandomScale(resolve, probability)
  if type(resolve) == "nil" then
    resolve = 12 -- The sum of the definition should resolve to this
  end
  if type(probability) == "nil" then
    probability = 50 -- Probability that the selected interval is 1 or 2
  end
  local sum = 0 -- Current scale definion sum
  local maxSum = 24
  local intervals1 = {1,2}
  local intervals2 = {1,2,3,4}
  local scaleDefinition = {}
  repeat
    local interval = 1
    if gem.getRandomBoolean(probability) then
      interval = gem.getRandomFromTable(intervals1)
    else
      interval = gem.getRandomFromTable(intervals2)
    end
    table.insert(scaleDefinition, interval)
    sum = gem.inc(sum, interval)
  until #scaleDefinition > 3 and (resolve % sum == 0 or maxSum % sum == 0 or sum >= maxSum)
  return scaleDefinition
end

local function getScaleDefinitionFromText(scaleText)
  local scale = {}
  if string.len(scaleText) > 0 then
    for w in string.gmatch(scaleText, "%d+") do
      local stepIncrement = tonumber(w)
      if stepIncrement > 0 then
        table.insert(scale, stepIncrement)
      end
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

local function getScaleInputTooltip(scaleDefinition)
  local sum = gem.sum(scaleDefinition)
  local tooltip = "Scales are defined by setting semitones up from the previous note. The current scale has " .. #scaleDefinition .. " notes and the definition sum is " .. sum
  if 12 % sum == 0 then
    tooltip = tooltip .. ", whitch resolves every octave."
  else
    tooltip = tooltip .. ", whitch does not resolve every octave."
  end
  return tooltip
end

local function getScaleWidget(options, i)
  -- Scale widget
  if type(options) == "nil" then
    options = {}
  end
  if type(i) == "nil" then
    i = ""
  end
  options.name = gem.getValueOrDefault(options.name, "Scale" .. i)
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Select a scale")
  options.hierarchical = true
  options.showLabel = gem.getValueOrDefault(options.showLabel, true)
  return widgets.menu("Scale", #scaleDefinitions, getScaleNames(), options)
end

local function getScaleInputWidget(scaleDefinition, width, i)
  -- Scale input widget
  if type(i) == "nil" then
    i = ""
  end
  local options = {
    name = "ScaleInput" .. i,
    tooltip = getScaleInputTooltip(scaleDefinition),
    editable = true,
    backgroundColour = "black",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "white",
  }
  if type(width) == "number" then
    options.width = width
  end
  return widgets.label(getTextFromScaleDefinition(scaleDefinition), options)
end

local function handleScaleInputChanged(self, scaleMenu)
  print("scaleInput.changed", self.text)
  local scaleDefinition = getScaleDefinitionFromText(self.text)
  if #scaleDefinition == 0 then
    -- Ensure we have a scale...
    print("No scale def. Using default scale.")
    scaleDefinition = scaleDefinitions[#scaleDefinitions]
    scaleMenu:setValue(#scaleDefinitions)
    return handleScaleInputChanged(self, scaleMenu)
  end
  self.tooltip = getScaleInputTooltip(scaleDefinition)
  return scaleDefinition
end

local scales = {
  widget = getScaleWidget,
  inputWidget = getScaleInputWidget,
  getScaleInputTooltip = getScaleInputTooltip,
  getScaleDefinitionIndex = getScaleDefinitionIndex,
  handleScaleInputChanged = handleScaleInputChanged,
  getTextFromScaleDefinition = getTextFromScaleDefinition,
  getScaleDefinitionFromText = getScaleDefinitionFromText,
  getScaleDefinitions = getScaleDefinitions,
  getScaleNames = getScaleNames,
  createRandomScale = createRandomScale,
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
    selectedResolutions=getSelectedResolutions(),
    dotOrTriProbaility=dotOrTriProbaility,
    maxDotResolutionIndex = 18, -- Fastest dotted
    maxTriResolutionIndex = 25, -- Fastest triplet
  }
  return resolutions.getResolutionVariation(currentResolution, options)
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
-- Generative Strategy Sequencer
--------------------------------------------------------------------------------

local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "9f02ACFE" -- Light
local labelTextColour = "AEFEFF" -- Light
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local backgroundColourOff = "ff084486"
local backgroundColourOn = "ff02ACFE"
local textColourOff = "ff22FFFF"
local textColourOn = "efFFFFFF"
local backgroundColour = "202020"
local knobFillColour = "E6D5B8" -- Light

local colours = {
  widgetBackgroundColour = widgetBackgroundColour,
  widgetTextColour = widgetTextColour,
  labelTextColour = "black", -- Used for rythmic fragments
  menuBackgroundColour = menuBackgroundColour,
  menuArrowColour = menuArrowColour,
  menuOutlineColour = menuOutlineColour,
  backgroundColourOff = backgroundColourOff,
  backgroundColourOn = backgroundColourOn,
  textColourOff = textColourOff,
  textColourOn = textColourOn,
  backgroundColour = backgroundColour
}

local voices = 1
local isPlaying = false
local baseDuration = nil
local recallStoredState = nil -- Holds the index of the stored fragment state to recall
local storedFragments = {} -- Holds stored fragment states
local partOrder = {} -- Holds the playing order of the parts
local playingIndex = {}
local playIndex = 1

--------------------------------------------------------------------------------
-- Strategies
--------------------------------------------------------------------------------

-- Strategies are ways to play chords and scales
local strategies = {
  {}, -- Randomize next note position +/- 1 oct
  {1}, -- Up
  {-1}, -- Down
  {2,-1}, -- Alternate up
  {-2,1}, -- Alternate down
  {-1,1,-2,-1,3}, -- Generated 1
  {3,1,-1,2}, -- Generated 2
  {-3,2}, -- Generated 3
  {2,2,3}, -- Up v 2
  {-3,-2,-2}, -- Down v 2
  {3,-2,7},
  {-5,4,4},
  {7,7,-5},
  {7,5,6},
  {-7,2,7},
  {7,0,-7},
  {4,0,-4},
  {0},
  {4,-2},
  {3,-2},
}

local strategyPos = {} -- Holds the position in the selected strategy
local notePosition = {} -- Holds the current note position
local unusedStrategySlotDefaultText = "Unused"
local selectedNotes = {}

function getStrategyInputText(strategy)
  if type(strategy) == nil or #strategy == 0 then
    return "Randomize"
  end
  return table.concat(strategy, ",")
end

function createStrategy()
  local maxLength = 8
  local strategy = {} -- Table to hold strategy
  local ln = gem.getRandom(maxLength) -- Length
  for i=1, ln do
    local value = gem.getRandom(-7,7)
    table.insert(strategy, value)
    --print("Add value to strategy", value)
  end
  return strategy
end

-- Returns a fragment that can be set directly on fragmentInput.text
-- Used by the tools menu
-- 1 = Default (even+dot)
-- 2 = Single
-- 3 = Extended (fast+slow)
-- 4 = Slow
function getRandomFragment(definitionNumber)
  local fragmentDefinition = {}
  if definitionNumber == 2 then
    fragmentDefinition = {resolutions.getResolution(gem.getRandomFromTable(rythmicFragments.getSelectedResolutions()))} -- Single
  else
    fragmentDefinition = rythmicFragments.createFragmentDefinition(definitionNumber)
  end
  return rythmicFragments.getFragmentInputText(rythmicFragments.fragmentDefinitionToResolutionNames(fragmentDefinition))
end

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

function startPlaying()
  if isPlaying then
    return
  end
  run(sequenceRunner)
end

function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  initNotes()
end

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

local strategyPanel = Panel("Strategy")
strategyPanel.backgroundColour = "003865"
strategyPanel.x = sequencerPanel.x
strategyPanel.y = sequencerPanel.y + sequencerPanel.height + 5
strategyPanel.width = 405
strategyPanel.height = 110

local gateVelPanel = Panel("GateVelocityPanel")
gateVelPanel.backgroundColour = "303030"
gateVelPanel.x = strategyPanel.x + strategyPanel.width + 5
gateVelPanel.y = strategyPanel.y
gateVelPanel.width = 140
gateVelPanel.height = strategyPanel.height

local voicePanel = Panel("VoicePanel")
voicePanel.backgroundColour = "003865"
voicePanel.x = gateVelPanel.x + gateVelPanel.width + 5
voicePanel.y = strategyPanel.y
voicePanel.width = gateVelPanel.width
voicePanel.height = strategyPanel.height

local notePanel = Panel("Notes")
notePanel.backgroundColour = "505050"
notePanel.x = strategyPanel.x
notePanel.y = strategyPanel.y + strategyPanel.height + 5
notePanel.width = 700
notePanel.height = 150

local rythmPanel = Panel("Resolutions")
rythmPanel.backgroundColour = "003865"
rythmPanel.x = notePanel.x
rythmPanel.y = notePanel.y + notePanel.height + 5
rythmPanel.width = 700
rythmPanel.height = 282

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

local label = sequencerPanel:Label("Label")
label.text = "Generative Strategy Sequencer"
label.alpha = 0.5
label.textColour = labelTextColour
label.fontSize = 22
label.width = 260
label.x = 0

local channelOffset = sequencerPanel:NumBox("ChannelOffset", 1, 1, 16, true)
channelOffset.textColour = widgetTextColour
channelOffset.backgroundColour = widgetBackgroundColour
channelOffset.enabled = false
channelOffset.showLabel = false
channelOffset.displayName = "Offset"
channelOffset.tooltip = "When multichannel is enabled, each voice is assigned to separate channels starting from this channel"
channelOffset.size = {22,22}
channelOffset.x = sequencerPanel.width - 342
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

local gateInput = gateVelPanel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate level"
gateInput.size = {130,20}
gateInput.x = 5
gateInput.y = 7

local gateRandomization = gateVelPanel:NumBox("GateRandomization", 15, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Randomization"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.size = gateInput.size
gateRandomization.x = gateInput.x
gateRandomization.y = gateInput.y + gateInput.height + 5

local velocityInput = gateVelPanel:NumBox("Velocity", 64, 1, 127, true)
velocityInput.textColour = widgetTextColour
velocityInput.backgroundColour = widgetBackgroundColour
velocityInput.displayName = "Velocity"
velocityInput.tooltip = "Default velocity"
velocityInput.size = gateRandomization.size
velocityInput.x = gateRandomization.x
velocityInput.y = gateRandomization.y + gateRandomization.height + 5

local velocityRandomization = gateVelPanel:NumBox("VelocityRandomization", 15, 0, 100, true)
velocityRandomization.unit = Unit.Percent
velocityRandomization.textColour = widgetTextColour
velocityRandomization.backgroundColour = widgetBackgroundColour
velocityRandomization.displayName = "Randomization"
velocityRandomization.tooltip = "Velocity randomization amount"
velocityRandomization.size = velocityInput.size
velocityRandomization.x = velocityInput.x
velocityRandomization.y = velocityInput.y + velocityInput.height + 5

local voicesInput = voicePanel:NumBox("Voices", voices, 1, 4, true)
voicesInput.textColour = widgetTextColour
voicesInput.backgroundColour = widgetBackgroundColour
voicesInput.displayName = "Voices"
voicesInput.tooltip = "Voices"
voicesInput.size = gateRandomization.size
voicesInput.x = 5
voicesInput.y = 5
voicesInput.changed = function(self)
  for voice=1,math.max(voices, self.value) do
    if voice > self.value and type(playingIndex[voice]) == "number" then
      print("Stopping voice", voice)
      playingIndex[voice] = nil
    elseif type(playingIndex[voice]) == "nil" then
      table.insert(playingIndex, nil)
    end
  end
  voices = self.value
end

local rangeOverlap = voicePanel:NumBox("RangeOverlap", 50, 0, 100, true)
rangeOverlap.unit = Unit.Percent
rangeOverlap.textColour = widgetTextColour
rangeOverlap.backgroundColour = widgetBackgroundColour
rangeOverlap.displayName = "Range Overlap"
rangeOverlap.tooltip = "Set the overlap range for the voices. 100 = all voices use the full range, 0 = separate ranges. Requires at least 7 notes per voice."
rangeOverlap.size = voicesInput.size
rangeOverlap.x = voicesInput.x
rangeOverlap.y = voicesInput.y + voicesInput.height + 5

local voiceToFragmentButton = voicePanel:OnOffButton("VoiceToFragmentButton", false)
voiceToFragmentButton.displayName = "Voice to fragment"
voiceToFragmentButton.tooltip = "Activate to let each voice use the corresponding fragment."
voiceToFragmentButton.backgroundColourOff = backgroundColourOff
voiceToFragmentButton.backgroundColourOn = backgroundColourOn
voiceToFragmentButton.textColourOff = textColourOff
voiceToFragmentButton.textColourOn = textColourOn
voiceToFragmentButton.size = rangeOverlap.size
voiceToFragmentButton.x = rangeOverlap.x
voiceToFragmentButton.y = rangeOverlap.y + rangeOverlap.height + 5

local voiceToStrategySlotButton = voicePanel:OnOffButton("VoiceToStrategySlotButton", false)
voiceToStrategySlotButton.displayName = "Voice to strategy slot"
voiceToStrategySlotButton.tooltip = "Activate to let each voice use the corresponding slot. Voice 1 gets slot 1+5, voice 2 gets 2+6 etc..."
voiceToStrategySlotButton.backgroundColourOff = backgroundColourOff
voiceToStrategySlotButton.backgroundColourOn = backgroundColourOn
voiceToStrategySlotButton.textColourOff = textColourOff
voiceToStrategySlotButton.textColourOn = textColourOn
voiceToStrategySlotButton.size = voiceToFragmentButton.size
voiceToStrategySlotButton.x = voiceToFragmentButton.x
voiceToStrategySlotButton.y = voiceToFragmentButton.y + voiceToFragmentButton.height + 5

--------------------------------------------------------------------------------
-- Strategy Panel
--------------------------------------------------------------------------------

local strategyLabel = strategyPanel:Label("StrategyLabel")
strategyLabel.text = "Strategy"
strategyLabel.alpha = 0.75
strategyLabel.fontSize = 15
strategyLabel.width = 350

local boxSize = {120,20}

-- TODO Add param for strategy probability decay?
local strategyPropbability = strategyPanel:NumBox("StrategyPropbability", 100, 0, 100, true)
strategyPropbability.displayName = "Probability"
strategyPropbability.tooltip = "Probability that a playing strategy will be used to select the next note. Otherwise notes are selected by random."
strategyPropbability.unit = Unit.Percent
strategyPropbability.size = boxSize
strategyPropbability.x = strategyLabel.x
strategyPropbability.y = strategyLabel.y + strategyLabel.height + 5
strategyPropbability.backgroundColour = menuBackgroundColour
strategyPropbability.textColour = widgetTextColour

local strategyRestart = strategyPanel:Menu("StrategyRestart", {"Restart each round", "Out of range", "When finished", "Finished+round"})
strategyRestart.tooltip = "Choose when a strategy restarts"
strategyRestart.showLabel = false
strategyRestart.size = boxSize
strategyRestart.x = strategyPropbability.x
strategyRestart.y = strategyPropbability.y + strategyPropbability.height + 5
strategyRestart.backgroundColour = menuBackgroundColour
strategyRestart.textColour = widgetTextColour
strategyRestart.arrowColour = menuArrowColour
strategyRestart.outlineColour = menuOutlineColour

local resLabel = strategyPanel:Label("ResolutionsLabel")
resLabel.text = "Round"
resLabel.tooltip = "Round duration affects strategy, selected notes and fragment evolve."
resLabel.alpha = 0.5
resLabel.fontSize = 15
resLabel.width = boxSize[1] / 2
resLabel.height = boxSize[2]
resLabel.x = strategyRestart.x
resLabel.y = strategyRestart.y + strategyRestart.height + 5

local baseResolution = strategyPanel:Menu("BaseResolution", resolutions.getResolutionNames())
baseResolution.displayName = resLabel.text
baseResolution.tooltip = resLabel.tooltip
baseResolution.selected = 11
baseResolution.showLabel = false
baseResolution.width = boxSize[1] / 2
baseResolution.height = boxSize[2]
baseResolution.backgroundColour = widgetBackgroundColour
baseResolution.textColour = widgetTextColour
baseResolution.arrowColour = menuArrowColour
baseResolution.outlineColour = menuOutlineColour
baseResolution.x = resLabel.x + resLabel.width
baseResolution.y = resLabel.y
baseResolution.changed = function(self)
  baseDuration = resolutions.getResolution(self.value)
end
baseResolution:changed()

local strategyInput = strategyPanel:Label("StrategyInput")
strategyInput.text = getStrategyInputText(gem.getRandomFromTable(strategies))
strategyInput.tooltip = "Strategies are ways to play scales. Numbers represent steps up or down the scale that is currently playing. Feel free to type your own strategies here."
strategyInput.editable = true
strategyInput.backgroundColour = "black"
strategyInput.backgroundColourWhenEditing = "white"
strategyInput.textColour = "white"
strategyInput.textColourWhenEditing = "black"
strategyInput.x = strategyRestart.x + strategyRestart.width + 10
strategyInput.y = strategyPropbability.y
strategyInput.width = 260
strategyInput.height = 45
strategyInput.fontSize = 30

local actions = {"Actions..."}
local strategySlots = {}
for j=1,(voicesInput.max*2) do
  local strategySlot = strategyPanel:OnOffButton("StrategySlot" .. j)
  strategySlot.backgroundColourOff = backgroundColourOff
  strategySlot.backgroundColourOn = backgroundColourOn
  strategySlot.textColourOff = textColourOff
  strategySlot.textColourOn = textColourOn
  strategySlot.displayName = "" .. j
  strategySlot.enabled = false
  strategySlot.tooltip = unusedStrategySlotDefaultText
  strategySlot.height = 20
  strategySlot.width = 30
  strategySlot.x = strategyInput.x + ((j-1) * (strategySlot.width+3)) - 1
  strategySlot.y = strategyInput.y + strategyInput.height + 5
  strategySlot.changed = function(self)
    strategyInput.text = strategySlot.tooltip
    self.value = false
  end
  table.insert(strategySlots, strategySlot)
  table.insert(actions, "Save to " .. j)
end

table.insert(actions, "--- Load ---")
for _,v in ipairs(strategies) do
  table.insert(actions, getStrategyInputText(v))
end

local autoStrategyButton = strategyPanel:OnOffButton("AutoStrategyButton", false)
autoStrategyButton.displayName = "Auto"
autoStrategyButton.tooltip = "Random strategies are automatically created for every round."
autoStrategyButton.backgroundColourOff = backgroundColourOff
autoStrategyButton.backgroundColourOn = backgroundColourOn
autoStrategyButton.textColourOff = textColourOff
autoStrategyButton.textColourOn = textColourOn
autoStrategyButton.width = (boxSize[1] / 2) - 15
autoStrategyButton.x = strategyRestart.x + strategyRestart.width + 10
autoStrategyButton.y = strategyLabel.y

local slotStrategyButton = strategyPanel:OnOffButton("SlotStrategyButton", false)
slotStrategyButton.displayName = "Slots"
slotStrategyButton.tooltip = "Strategies are selected from the slots."
slotStrategyButton.backgroundColourOff = backgroundColourOff
slotStrategyButton.backgroundColourOn = backgroundColourOn
slotStrategyButton.textColourOff = textColourOff
slotStrategyButton.textColourOn = textColourOn
slotStrategyButton.width = autoStrategyButton.width
slotStrategyButton.x = autoStrategyButton.x + autoStrategyButton.width + 5
slotStrategyButton.y = autoStrategyButton.y

local createStrategyButton = strategyPanel:Button("CreateStrategyButton")
createStrategyButton.displayName = "Create"
createStrategyButton.tooltip = "Replace the current strategy with a new one."
createStrategyButton.persistent = false
createStrategyButton.width = slotStrategyButton.width
createStrategyButton.x = slotStrategyButton.x + slotStrategyButton.width + 5
createStrategyButton.y = slotStrategyButton.y

autoStrategyButton.changed = function(self)
  slotStrategyButton:setValue(false, false)
  notePosition = {} -- Reset note position
  strategyInput.enabled = self.value == false
  createStrategyButton.enabled = self.value == false
end

slotStrategyButton.changed = function(self)
  autoStrategyButton:setValue(false, false)
  notePosition = {} -- Reset note position
  strategyInput.enabled = true
  createStrategyButton.enabled = true
end

createStrategyButton.changed = function()
  local strategy = createStrategy()
  strategyInput.text = table.concat(strategy, ",")
end

local strategyActions = strategyPanel:Menu("StrategyActions", actions)
strategyActions.tooltip = "Available actions for strategies"
strategyActions.showLabel = false
strategyActions.height = 20
strategyActions.width = 110
strategyActions.x = createStrategyButton.x + createStrategyButton.width + 5
strategyActions.y = createStrategyButton.y
strategyActions.backgroundColour = menuBackgroundColour
strategyActions.textColour = widgetTextColour
strategyActions.arrowColour = menuArrowColour
strategyActions.outlineColour = menuOutlineColour
strategyActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local actionIndex = self.value - 1

  -- Save strategy
  if actionIndex <= #strategySlots then
    if string.len(strategyInput.text) > 0 then
      strategySlots[actionIndex].tooltip = strategyInput.text
      strategySlots[actionIndex].enabled = true
    else
      strategySlots[actionIndex].tooltip = unusedStrategySlotDefaultText
      strategySlots[actionIndex].enabled = false
    end
    --print("Strategy saved to slot", strategyInput.text, actionIndex)
  elseif actionIndex > #strategySlots + 1 then
    strategyInput.text = self.selectedText
  end

  -- Must be last
  self:setValue(1, false)
end

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
rythmLabel.width = 120

paramsPerFragment = rythmicFragments.getParamsPerFragment(rythmPanel, rythmLabel, colours, voicesInput.max)

local templates = {
  "Action...",
  "Clear all fragment settings",
  "Clear fragment inputs",
  "Randomize all fragment settings",
  "Randomize fragment inputs",
  "Randomize fragments (single)",
  "Randomize fragments (slow)",
  "Randomize fragments (extended)",
}
local templateMenu = rythmPanel:Menu("Templates", templates)
templateMenu.tooltip = "Randomize fragments - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.height = 18
templateMenu.width = 100
templateMenu.x = 685 - templateMenu.width
templateMenu.y = rythmLabel.y
templateMenu.backgroundColour = menuBackgroundColour
templateMenu.textColour = widgetTextColour
templateMenu.arrowColour = menuArrowColour
templateMenu.outlineColour = menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for _,v in ipairs(paramsPerFragment) do
    if self.selectedText == "Clear fragment inputs" then
      v.fragmentInput.text = ""
    elseif self.selectedText == "Clear all fragment settings" then
      v.fragmentInput.text = ""
      v.fragmentPlayProbability.value = v.fragmentPlayProbability.default
      v.fragmentActive.value = v.fragmentActive.default
      v.fragmentRepeatProbability.value = v.fragmentRepeatProbability.default
      v.fragmentRepeatProbabilityDecay.value = v.fragmentRepeatProbabilityDecay.default
      v.fragmentMinRepeats.value = v.fragmentMinRepeats.default
      v.reverseFragmentProbability.value = v.reverseFragmentProbability.default
      v.randomizeFragmentProbability.value = v.randomizeFragmentProbability.default
      v.restProbability.value = v.restProbability.default
    elseif self.selectedText == "Randomize all fragment settings" then
      v.fragmentInput.text = getRandomFragment(1)
      v.fragmentPlayProbability.value = gem.getRandom(100)
      v.fragmentActive.value = true
      v.fragmentRepeatProbability.value = gem.getRandom(100)
      v.fragmentRepeatProbabilityDecay.value = gem.getRandom(100)
      v.fragmentMinRepeats.value = gem.getRandom(100)
      v.reverseFragmentProbability.value = gem.getRandom(100)
      v.randomizeFragmentProbability.value = gem.getRandom(100)
      v.restProbability.value = gem.getRandom(100)
    elseif self.selectedText == "Randomize fragment inputs" then
      v.fragmentInput.text = getRandomFragment(1)
    elseif self.selectedText == "Randomize fragments (single)" then
      v.fragmentInput.text = getRandomFragment(2)
    elseif self.selectedText == "Randomize fragments (extended)" then
      v.fragmentInput.text = getRandomFragment(3)
    elseif self.selectedText == "Randomize fragments (slow)" then
      v.fragmentInput.text = getRandomFragment(4)
    end
  end
  -- Must be last
  self:setValue(1, false)
end

--- Structure - Store/recall parts, set playing order etc. ---

local loadFragmentMenu = rythmPanel:Menu("LoadFragmentMenu", {"Load..."})
loadFragmentMenu.enabled = false

local storeButton = rythmPanel:Button("StoreButton")
storeButton.displayName = "Store"
storeButton.tooltip = "Store the current state of the fragments"
storeButton.width = 75
storeButton.height = 20
storeButton.x = rythmLabel.x
storeButton.y = 220

local slotSpacing = 3
local unusedSlotDefaultText = "Unused"
local actions = {"Save..."}
local slotToStoredIndex = {} -- Holds the index of the stored fragment for each slot
local fragmentSlots = {}
for i=1,8 do
  local fragmentSlot = rythmPanel:OnOffButton("StoreFragmentSlot" .. i)
  fragmentSlot.backgroundColourOff = backgroundColourOff
  fragmentSlot.backgroundColourOn = backgroundColourOn
  fragmentSlot.textColourOff = textColourOff
  fragmentSlot.textColourOn = textColourOn
  fragmentSlot.displayName = "" .. i
  fragmentSlot.enabled = false
  fragmentSlot.tooltip = unusedSlotDefaultText
  fragmentSlot.width = 20
  fragmentSlot.height = storeButton.height
  fragmentSlot.x = storeButton.x + storeButton.width + ((i-1) * (fragmentSlot.width + slotSpacing)) + 10
  fragmentSlot.y = storeButton.y
  fragmentSlot.changed = function(self)
    if self.value then
      local storedIndex = slotToStoredIndex[i]
      if type(storedFragments[storedIndex]) == "table" then
        recallStoredState = storedIndex
        --print("Set part/recallStoredState", i, recallStoredState)
        -- If sequencer is not playing, we can recall right now
        if isPlaying == false then
          recall()
        end
      end
    end
    for j,v in ipairs(fragmentSlots) do
      if j ~= i then
        v:setValue(false, false)
      end
    end
  end
  table.insert(fragmentSlots, fragmentSlot)
  table.insert(slotToStoredIndex, nil)
  table.insert(actions, "Save to " .. i)
end

local slotActions = rythmPanel:Menu("SlotActions", actions)
slotActions.tooltip = "Save current fragment state to the selected slot"
slotActions.showLabel = false
slotActions.height = storeButton.height
slotActions.width = 90
slotActions.x = storeButton.x + storeButton.width + ((fragmentSlots[1].width + slotSpacing) * #fragmentSlots) + 15
slotActions.y = storeButton.y
slotActions.backgroundColour = menuBackgroundColour
slotActions.textColour = widgetTextColour
slotActions.arrowColour = menuArrowColour
slotActions.outlineColour = menuOutlineColour
slotActions.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  -- Save current fragment state
  -- TODO Add options to remove?
  if index <= #fragmentSlots then
    storeButton:changed() -- Store the current state
    slotToStoredIndex[index] = #storedFragments -- Set the most recent stored fragment to this slot
    fragmentSlots[index].tooltip = "Part " .. index .. " - Stored state " .. slotToStoredIndex[index]
    fragmentSlots[index].enabled = true
  end

  -- Must be last
  self:setValue(1, false)
end

loadFragmentMenu.tooltip = "Load a stored fragment state"
loadFragmentMenu.showLabel = false
loadFragmentMenu.height = storeButton.height
loadFragmentMenu.width = slotActions.width
loadFragmentMenu.x = slotActions.x + slotActions.width + 10
loadFragmentMenu.y = slotActions.y
loadFragmentMenu.backgroundColour = menuBackgroundColour
loadFragmentMenu.textColour = widgetTextColour
loadFragmentMenu.arrowColour = menuArrowColour
loadFragmentMenu.outlineColour = menuOutlineColour
loadFragmentMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end

  local index = self.value - 1

  if type(storedFragments[index]) == "table" then
    recallStoredState = index
    -- If sequencer is not playing, we can recall right now
    if isPlaying == false then
      recall()
    end  
  end

  -- Must be last
  self:setValue(1, false)
end

local partOrderButton = rythmPanel:OnOffButton("PartOrderLabel")
partOrderButton.displayName = "Part Order"
partOrderButton.tooltip = "Activate part order"
partOrderButton.width = 60
partOrderButton.height = 20
partOrderButton.backgroundColourOff = backgroundColourOff
partOrderButton.backgroundColourOn = backgroundColourOn
partOrderButton.textColourOff = textColourOff
partOrderButton.textColourOn = textColourOn
partOrderButton.x = loadFragmentMenu.x + loadFragmentMenu.width + 10
partOrderButton.y = loadFragmentMenu.y

local partOrderInput = rythmPanel:Label("PartOrderInput")
partOrderInput.text = ""
partOrderInput.tooltip = "Set the playing order of the parts (1-8 as stored in the slots). Format <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3"
partOrderInput.editable = true
partOrderInput.backgroundColour = "black"
partOrderInput.backgroundColourWhenEditing = "white"
partOrderInput.textColour = "white"
partOrderInput.textColourWhenEditing = "black"
partOrderInput.x = partOrderButton.x + partOrderButton.width
partOrderInput.y = partOrderButton.y
partOrderInput.width = 156
partOrderInput.height = 20
partOrderInput.fontSize = 15
partOrderInput.changed = function(self)
  setPartOrder(self.text)
end

--- Evolve ---

local recallButton = rythmPanel:Button("RecallButton")
recallButton.displayName = "Recall"
recallButton.enabled = false
recallButton.tooltip = "Recall the last stored fragment state"
recallButton.width = storeButton.width
recallButton.height = storeButton.height
recallButton.x = storeButton.x
recallButton.y = storeButton.y + storeButton.height + 10

local evolveButton = rythmPanel:OnOffButton("EvolveActive", false)
evolveButton.backgroundColourOff = backgroundColourOff
evolveButton.backgroundColourOn = backgroundColourOn
evolveButton.textColourOff = textColourOff
evolveButton.textColourOn = textColourOn
evolveButton.displayName = "Evolve"
evolveButton.tooltip = "Activate evolve"
evolveButton.width = recallButton.width
evolveButton.height = recallButton.height
evolveButton.x = recallButton.x + recallButton.width + 10
evolveButton.y = recallButton.y

local evolveFragmentProbability = rythmPanel:NumBox("EvolveFragmentProbability", 50, 0, 100, true)
evolveFragmentProbability.unit = Unit.Percent
evolveFragmentProbability.textColour = widgetTextColour
evolveFragmentProbability.backgroundColour = widgetBackgroundColour
evolveFragmentProbability.displayName = "Amount"
evolveFragmentProbability.tooltip = "Set the probability that fragments will change over time, using the resolutions present in the fragments"
evolveFragmentProbability.width = 105
evolveFragmentProbability.height = recallButton.height
evolveFragmentProbability.x = evolveButton.x + evolveButton.width + 10
evolveFragmentProbability.y = evolveButton.y

local randomizeCurrentResolutionProbability = rythmPanel:NumBox("RandomizeCurrentResolutionProbability", 0, 0, 100, true)
randomizeCurrentResolutionProbability.unit = Unit.Percent
randomizeCurrentResolutionProbability.textColour = widgetTextColour
randomizeCurrentResolutionProbability.backgroundColour = widgetBackgroundColour
randomizeCurrentResolutionProbability.displayName = "Adjust"
randomizeCurrentResolutionProbability.tooltip = "Set the probability that evolve will adjust resolutions (double, half, dot/tri), based on the resolutions present in the fragments"
randomizeCurrentResolutionProbability.width = evolveFragmentProbability.width
randomizeCurrentResolutionProbability.height = evolveFragmentProbability.height
randomizeCurrentResolutionProbability.x = evolveFragmentProbability.x + evolveFragmentProbability.width + 10
randomizeCurrentResolutionProbability.y = evolveFragmentProbability.y

local biasLabel = rythmPanel:Label("BiasLabel")
biasLabel.text = "Bias slow > fast"
biasLabel.tooltip = "Adjust bias: <50=more slow resolutions, >50=more fast resolutions"
biasLabel.alpha = 0.5
biasLabel.fontSize = 15
biasLabel.width = 95
biasLabel.height = randomizeCurrentResolutionProbability.height
biasLabel.x = randomizeCurrentResolutionProbability.x + randomizeCurrentResolutionProbability.width + 10
biasLabel.y = randomizeCurrentResolutionProbability.y

local adjustBias = rythmPanel:Knob("Bias", 50, 0, 100, true)
adjustBias.showLabel = false
adjustBias.showValue = false
adjustBias.displayName = "Bias"
adjustBias.tooltip = biasLabel.tooltip
adjustBias.backgroundColour = widgetBackgroundColour
adjustBias.fillColour = knobFillColour
adjustBias.outlineColour = widgetTextColour
adjustBias.width = 20
adjustBias.height = biasLabel.height
adjustBias.x = biasLabel.x + biasLabel.width
adjustBias.y = biasLabel.y

local minResLabel = rythmPanel:Label("MinResolutionsLabel")
minResLabel.text = "Min resolution"
minResLabel.alpha = 0.5
minResLabel.fontSize = 15
minResLabel.width = biasLabel.width
minResLabel.height = adjustBias.height
minResLabel.x = adjustBias.x + adjustBias.width + 10
minResLabel.y = adjustBias.y

local minResolution = rythmPanel:Menu("MinResolution", resolutions.getResolutionNames())
minResolution.displayName = minResLabel.text
minResolution.tooltip = "The highest allowed resolution for evolve adjustments"
minResolution.selected = 26
minResolution.showLabel = false
minResolution.width = 69
minResolution.height = adjustBias.height
minResolution.backgroundColour = widgetBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour
minResolution.x = minResLabel.x + minResLabel.width
minResolution.y = minResLabel.y
minResolution.changed = function(self)
  rythmicFragments.setMaxResolutionIndex(self.value)
end
minResolution:changed()

storeButton.changed = function(self)
  table.insert(storedFragments, rythmicFragments.getFragmentState())
  recallButton.enabled = true
  loadFragmentMenu.enabled = true
  loadFragmentMenu:addItem("State " .. #storedFragments)
end

recallButton.changed = function(self)
  recallStoredState = #storedFragments
  -- If sequencer is not playing, we can recall right now
  if isPlaying == false then
    recall()
  end
end

--------------------------------------------------------------------------------
-- Note Functions
--------------------------------------------------------------------------------

-- Returns the selected notes filtered by overlap range and playing notes
local function getFilteredNotes(voice)
  --print("BEFORE selectedNotes, voices, voice", #selectedNotes, voices, voice)
  local noteRangeMin = 1
  local noteRangeMax = #selectedNotes
  local notesPerVoice = 5
  local notesRequiredForRange = voices * notesPerVoice

  -- Adjust note range min/max for voice overlap, if we have enough available notes
  if #selectedNotes >= notesRequiredForRange then
    local rangeOverlapAmount = rangeOverlap.value
    local range = #selectedNotes / voices
    --print("range, voices, voice", range, voices, voice)
    local overlapValue = math.ceil(range * (rangeOverlapAmount / 100))
    --print("overlapValue, voice", overlapValue, voice)
    noteRangeMax = math.min(noteRangeMax, ((range * voice) + overlapValue))
    noteRangeMin = math.max(1, (noteRangeMax - range - overlapValue))
    --print("noteRangeMin, noteRangeMax, voice", noteRangeMin, noteRangeMax, voice)
  end

  -- Find the notes, filter for min/max and notes that are already playing
  local notes = {}
  for i,v in ipairs(selectedNotes) do
    if i >= noteRangeMin and i <= noteRangeMax and gem.tableIncludes(noteSelector.getNotesPlaying(), v) == false then
      table.insert(notes, v)
    end
  end

  --print("AFTER notes, voice", #notes, voice)
  return notes
end

local function generateNote(voice)
  local notes = getFilteredNotes(voice)

  if #notes == 0 then
    return nil
  end

  if #notes == 1 then
    return notes[1]
  end

  if gem.getRandomBoolean(strategyPropbability.value) then
    return getNoteFromStrategy(notes, voice)
  end

  return gem.getRandomFromTable(notes)
end

function getGate()
  return gem.randomizeValue(gateInput.value, 0, 101, gateRandomization.value) / 100
end

function getVelocity()
  return gem.randomizeValue(velocityInput.value, 1, 127, velocityRandomization.value)
end

--------------------------------------------------------------------------------
-- Strategy Functions
--------------------------------------------------------------------------------

function getSlotForVoice(voice)
  -- Select strategies from slot 1 and 5 for voice 1, 2 and 6 for voice 2 etc.
  local slot1 = strategySlots[voice]
  local slot2 = strategySlots[voice+voicesInput.max]
  if slot1.enabled and slot2.enabled then
    if gem.getRandomBoolean() then
      return slot1.tooltip
    else
      return slot2.tooltip
    end
  end
  if slot1.enabled then
    return slot1.tooltip
  end
  if slot2.enabled then
    return slot2.tooltip
  end
end

function getNoteFromStrategy(notes, voice)
  local strategy = {}
  -- Get strategy from slot, if button active
  if voiceToStrategySlotButton.value then
    local slot = getSlotForVoice(voice)
    if type(slot) == "string" then
      for w in string.gmatch(slot, "-?%d+") do
        table.insert(strategy, tonumber(w))
        --print("Add to strategy from slot for voice", w, voice)
      end
      --print("Get strategy from slot", #strategy)
    end
  end
  -- Get strategy from input
  if #strategy == 0 then
    local input = strategyInput
    if string.len(input.text) > 0 then
      for w in string.gmatch(input.text, "-?%d+") do
        table.insert(strategy, w)
        --print("Add to strategy", w)
      end
      --print("Get strategy from input", #strategy)
    end
  end
  -- Get strategy from index
  if #strategy == 0 then
    strategy = gem.getRandomFromTable(strategies)
  end
  -- Reset strategy position
  if type(strategyPos[voice]) == "nil" or strategyPos[voice] > #strategy then
    strategyPos[voice] = 1
    if strategyRestart.value == 3 or strategyRestart.value == 4 then
      notePosition[voice] = nil -- Reset counter for note position
      --print("Reset note position for voice", voice)
    end
  end
  if type(notePosition[voice]) == "nil" or #strategy == 0 then
    -- Start at a random notePosition
    notePosition[voice] = gem.getRandom(#notes)
    --print("Set random notePosition, voice", notePosition[voice], voice)
    if strategyRestart.value == 1 then
      strategyPos[voice] = 1
    end
  else
    -- Get next notePosition from strategy
    --print("Set notePosition, strategyPos, voice", notePosition[voice], strategy[strategyPos[voice]], voice)
    notePosition[voice] = gem.inc(notePosition[voice], strategy[strategyPos[voice]])
    local randomReset = true -- TODO Param?
    if randomReset and (notePosition[voice] > #notes or notePosition[voice] < 1) then
      notePosition[voice] = gem.getRandom(#notes)
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] > #notes then
      --print("Reset notePosition >= #notes", notePosition, #notes)
      notePosition[voice] = 1
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    elseif notePosition[voice] < 1 then
      --print("Reset notePosition[voice] <= 1", notePosition[voice])
      notePosition[voice] = #notes
      if strategyRestart.value == 2 then
        strategyPos[voice] = 1
      end
    else
      -- Increment strategy pos
      if #strategy > 1 then
        strategyPos[voice] = gem.inc(strategyPos[voice])
        --print("Increment strategy pos", strategyPos)
      end
    end
  end
  return notes[notePosition[voice]]
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function initNotes()
  noteSelector.clearNotesPlaying()
  playingIndex = {}
  rythmicFragments.clearResolutionsForEvolve()
  for voice=1,voices do
    table.insert(playingIndex, nil) -- Init index
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentActive.textColourOn = "black"
  end
  for _,v in ipairs(paramsPerFragment) do
    v.fragmentInputDirty = false
  end
end

function playVoices(partDuration)
  for voice=1,voices do
    if playingIndex[voice] == nil then
      playingIndex[voice] = playIndex
      print("Play voice", voice)
      spawn(play, voice, playIndex, partDuration)
      playIndex = playIndex + 1
    end
  end
end

function recall()
  -- Find the state we are to recall
  rythmicFragments.setFragmentState(storedFragments[recallStoredState])
  --print("Recalled fragments from stored state", recallStoredState)
  recallStoredState = nil
end

-- Parse the part order input
-- Format: <PART><x|e><REPEATS> separated by comma (use e instead of x to activate evolve). Example: 1x16,2e8,3
-- Set the part to zero "0" to use the current state instead of loading a part
function setPartOrder(partOrderText)
  partOrder = {} -- Reset
  for s in string.gmatch(partOrderText, "[^,]+") do
    local evolve = type(string.find(s, "e", 1, true)) == "number" -- Check if "e" is given for evolve
    local part = tonumber(string.sub(s, 1, 1)) -- Parts are 1-8, so we get the first pos in the string
    local repeats = tonumber(string.sub(s, 3)) -- Get repeats from the third pos to the end - if any is set
    if type(repeats) ~= "number" then
      repeats = 1
    end
    if type(part) == "number" then
      --print("setPartOrder part, repeats, evolve", part, repeats, evolve)
      table.insert(partOrder, {part=part,repeats=repeats,evolve=evolve})
    end
  end
  --print("#partOrder", #partOrder)
  return partOrder
end

function sequenceRunner()
  strategyPos = {} -- Reset strategy pos
  local partOrderPos = 1 -- Position in the part order
  local partOrderRepeatCounter = 0 -- Counter for part repeats
  local slotIndex = nil -- The currently selected slot
  local remainingDuration = 0
  local partDuration = nil -- When using part order, this is the duration of the parts with repeats
  local partInfo = nil
  local startEvolve = false -- Can be set by part order
  local maxStrategies = 32
  local currentVoices = 0
  local previous = nil
  playIndex = 1 -- Reset play index
  isPlaying = true
  initNotes()
  while isPlaying do
    --print("sequenceRunner new round: #partOrder", #partOrder)

    if partOrderButton.value and #partOrder > 0 then
      if partOrderRepeatCounter == 0 then
        -- Start new part
        partInfo = partOrder[partOrderPos]
        slotIndex = partInfo.part
        partOrderRepeatCounter = partInfo.repeats
        startEvolve = partInfo.evolve
        --print("startEvolve, slotIndex, partOrderPos", startEvolve, slotIndex, partOrderPos)
        partDuration = partOrderRepeatCounter * baseDuration
        remainingDuration = partDuration
        -- If slot is already selected, deactivate so we can select it again
        if slotIndex > 0 then
          if fragmentSlots[slotIndex].value == true then
            fragmentSlots[slotIndex]:setValue(false)
          end
          fragmentSlots[slotIndex]:setValue(true)
        end
        -- Increment part order position
        partOrderPos = partOrderPos + 1
        if partOrderPos > #partOrder then
          partOrderPos = 1
        end
      end

      partOrderRepeatCounter = partOrderRepeatCounter - 1 -- Decrement repeat counter
      --print("Decrementing partOrderRepeatCounter", partOrderRepeatCounter)
    end

    if type(recallStoredState) == "number" then
      initNotes()
      recall()
      evolveButton:setValue(startEvolve)
    end

    selectedNotes = noteSelector.getSelectedNotes(true) -- Refresh selected notes
    if autoStrategyButton.value == true then
      local strategy = createStrategy()
      strategyInput.text = getStrategyInputText(strategy)
    end

    if slotStrategyButton.value == true then
      local slots = {}
      for _,v in ipairs(strategySlots) do
        if v.enabled == true then
          table.insert(slots, v)
        end
      end
      if #slots > 0 then
        slots[gem.getRandom(#slots)]:setValue(true)
      end
    end

    if strategyRestart.value == 1 or strategyRestart.value == 4 then
      notePosition = {} -- Reset counter for note position
      if strategyRestart.value == 4 then
        strategyPos = {} -- Reset strategy position
      end
    end

    if type(partDuration) == "nil" or remainingDuration == partDuration or remainingDuration == 0 then
      playVoices(partDuration)
    end

    waitBeat(baseDuration)
    if evolveButton.value and gem.getRandomBoolean(evolveFragmentProbability.value) then
      previous = rythmicFragments.evolveFragments(previous, randomizeCurrentResolutionProbability.value, adjustBias.value)
    end
  end
end

function play(voice, uniqueId, partDuration)
  local playDuration = 0 -- Keep track of the played duration
  local noteToPlay = nil
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatCount = 0
  local fragmentRepeatProbability = 0
  local duration = nil
  local rest = false
  local reverseFragment = false
  while playingIndex[voice] == uniqueId do
    local channel = nil
    if channelButton.value then
      channel = voice + channelOffset.value - 1
    end
    local sources = nil
    if voiceToFragmentButton.value then
      sources = {voice}
    end
    duration, isFragmentStart, isRepeat, mustRepeat, rest, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount = rythmicFragments.getDuration(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment, fragmentRepeatCount, sources)
    if type(duration) == "nil" then
      playingIndex[voice] = nil
      --print("No duration was found for voice", voice)
      break
    end

    if type(partDuration) == "number" and (playDuration + duration) > partDuration then
      duration = partDuration - playDuration -- Remaining
      --print("duration changed to remaining", duration, "voice " .. voice)
    end

    -- Update total play duration
    playDuration = playDuration + duration

    local gate = getGate()
    if gate > 0 and rest == false then
      noteToPlay = generateNote(voice)
    else
      noteToPlay = nil
    end
    if type(noteToPlay) == "number" then
      local velocity = getVelocity()
      local noteDuration = beat2ms(duration) * gate
      playNote(noteToPlay, velocity, noteDuration, nil, channel)
      --print("playNote noteToPlay, velocity, noteDuration, voice", noteToPlay, velocity, noteDuration, voice)
      -- Register playing note
      noteSelector.addNotePlaying(noteToPlay)
      for i,v in ipairs(paramsPerFragment) do
        if activeFragment.i == i then
          spawn(rythmicFragments.flashFragmentActive, v.fragmentActive, duration)
        end
      end
    end

    if type(partDuration) == "number" and playDuration == partDuration then
      playingIndex[voice] = nil
    else
      waitBeat(duration)
    end

    if type(noteToPlay) == "number" then
      -- Unregister note
      noteSelector.removeNotePlaying(noteToPlay)
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
  local strategyInputData = {}
  local strategySlotsData = {}
  local fragmentInputData = {}
  local fragmentSlotsData = {}

  strategyInputData = strategyInput.text
  for _,v in ipairs(strategySlots) do
    table.insert(strategySlotsData, v.tooltip)
  end

  for _,v in ipairs(paramsPerFragment) do
    table.insert(fragmentInputData, v.fragmentInput.text)
  end

  for _,v in ipairs(fragmentSlots) do
    table.insert(fragmentSlotsData, v.tooltip)
  end

  return {strategyInputData, strategySlotsData, fragmentInputData, fragmentSlotsData, storedFragments, partOrderInput.text, slotToStoredIndex}
end

function onLoad(data)
  local strategyInputData = data[1]
  local strategySlotsData = data[2]
  local fragmentInputData = data[3]
  local fragmentSlotsData = data[4]
  storedFragments = data[5]
  partOrderInput.text = tostring(data[6])
  slotToStoredIndex = data[7]

  setPartOrder(partOrderInput.text)

  strategyInput.text = strategyInputData
  for i,v in ipairs(strategySlots) do
    v.tooltip = strategySlotsData[i]
    v.enabled = v.tooltip ~= unusedStrategySlotDefaultText
  end

  if type(storedFragments) == "nil" then
    storedFragments = {}
  end

  if type(fragmentSlotsData) == "nil" then
    fragmentSlotsData = {}
  end

  if type(slotToStoredIndex) == "nil" then
    slotToStoredIndex = {}
    for i=1,#fragmentSlots do
      table.insert(slotToStoredIndex, nil)
    end
  end

  recallButton.enabled = #storedFragments > 0

  for i=1,#storedFragments do
    loadFragmentMenu:addItem("State " .. i)
  end
  loadFragmentMenu.enabled = #storedFragments > 0

  for i,v in ipairs(fragmentInputData) do
    paramsPerFragment[i].fragmentInput.text = v
  end

  for i,v in ipairs(fragmentSlotsData) do
    fragmentSlots[i].tooltip = v
    fragmentSlots[i].enabled = type(slotToStoredIndex[i]) == "number"
  end
end
