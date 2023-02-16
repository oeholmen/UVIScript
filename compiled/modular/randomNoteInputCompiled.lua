-- modular/randomNoteInput -- 
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
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local widgetNameIndex = 1

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 100,
  height = 20,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "202020",
  sliderColour = "5FB5FF", -- Table slider colour
  labelTextColour = "black", -- Light
  labelBackgoundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "#9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getWidgetValue(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function xOffset(val)
  widgetDefaults.xOffset = val
end

local function yOffset(val)
  widgetDefaults.yOffset = val
end

local function xSpacing(val)
  widgetDefaults.xSpacing = val
end

local function ySpacing(val)
  widgetDefaults.ySpacing = val
end

local function widthDefault(val)
  widgetDefaults.width = val
end

local function heightDefault(val)
  widgetDefaults.height = val
end

local function setColour(key, color)
  widgetColours[key] = color
end

local function getColour(key)
  return widgetColours[key]
end

local function posSide(widget)
  return widget.x + widget.width + widgetDefaults.xSpacing
end

local function posUnder(widget)
  return widget.y + widget.height + widgetDefaults.ySpacing
end

local function setWidgetDefaults(settings)
  widgetDefaults.width = getWidgetValue(settings.width, widgetDefaults.width)
  widgetDefaults.height = getWidgetValue(settings.height, widgetDefaults.height)
  widgetDefaults.xOffset = getWidgetValue(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getWidgetValue(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getWidgetValue(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getWidgetValue(settings.ySpacing, widgetDefaults.ySpacing)
end

local function getWidgetName(name)
  if type(name) == "nil" then
    name = "Widget" .. widgetNameIndex
    widgetNameIndex = widgetNameIndex + 1
  end
  return name
end

local function getWidgetX(options)
  if type(options.x) == "number" then
    return options.x
  end

  if type(options.col) == "number" then
    -- Calculate widget x position
    local col = options.col - 1
    local width = col * widgetDefaults.width
    local xSpacing = col * widgetDefaults.xSpacing
    return widgetDefaults.xOffset + width + xSpacing
  end

  return widgetDefaults.xSpacing
end

local function getWidgetY(options)
  if type(options.y) == "number" then
    return options.y
  end

  if type(options.row) == "number" then
    -- Calculate widget y position
    local row = options.row - 1
    local height = row * widgetDefaults.height
    local ySpacing = row * widgetDefaults.ySpacing
    return widgetDefaults.yOffset + height + ySpacing
  end

  return widgetDefaults.yOffset + widgetDefaults.ySpacing
end

local function getWidgetBounds(options)
  local x = getWidgetX(options)
  local y = getWidgetY(options)
  local w = getWidgetValue(options.width, widgetDefaults.width)
  local h = getWidgetValue(options.height, widgetDefaults.height)
  return {x, y, w, h}
end

local function getWidgetOptions(options, col, row, displayName, default)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getWidgetValue(default, options.default)
  options.col = getWidgetValue(col, options.col)
  options.row = getWidgetValue(row, options.row)
  options.name = getWidgetName(options.name)
  options.displayName = getWidgetValue(displayName, options.name)
  options.tooltip = getWidgetValue(options.tooltip, options.displayName)
  options.integer = getWidgetValue(options.integer, (options.unit == Unit.Percent))
  options.min = getWidgetValue(options.min, 0)
  options.default = getWidgetValue(options.default, options.min)
  if options.unit == Unit.Percent then
    options.max = getWidgetValue(options.max, 100)
  else
    options.max = getWidgetValue(options.max, 1)
  end
  return options
end

local function setOptional(widget, options)
  if type(options.changed) == "function" then
    widget.changed = options.changed
  end
  if type(options.alpha) == "number" then
    widget.alpha = options.alpha
  end
  if type(options.fontSize) == "number" then
    widget.fontSize = options.fontSize
  end
  if type(options.unit) == "number" then
    widget.unit = options.unit
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
  if type(options.enabled) == "boolean" then
    widget.enabled = options.enabled
  end
  if type(options.showPopupDisplay) == "boolean" then
    widget.showPopupDisplay = options.showPopupDisplay
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
end

local function setPanel(panel)
  widgetDefaults.panel = panel
end

local function getPanel(col, row, options, create)
  if type(col) == "number" or type(row) == "number" or type(col) == "table" or type(options) == "table" or create == true then
    if type(col) == "table" then
      options = col
      col = nil
    end
    options = getWidgetOptions(options, col, row)
    if create == true then
      widgetDefaults.panel = Panel(options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options)
    setOptional(widgetDefaults.panel, options)
  end
  return widgetDefaults.panel
end

local widgets = {
  colours = widgetColours,
  setColour = setColour,
  getColour = getColour,
  setPanel = setPanel,
  getPanel = getPanel,
  setWidgetDefaults = setWidgetDefaults,
  xOffset = xOffset,
  yOffset = yOffset,
  xSpacing = xSpacing,
  ySpacing = ySpacing,
  widthDefault = widthDefault,
  heightDefault = heightDefault,
  posSide = posSide,
  posUnder = posUnder,
  panel = function(col, row, options)
    return getPanel(col, row, options, true)
  end,
  button = function(displayName, default, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
    local widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, col, row, options)
    options = getWidgetOptions(options, col, row, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgoundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.menuBackgroundColour
    widget.textColour = widgetColours.menuTextColour
    widget.arrowColour = widgetColours.menuArrowColour
    widget.outlineColour = widgetColours.menuOutlineColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  numBox = function(displayName, default, col, row, options)
    options = getWidgetOptions(options, col, row, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
  table = function(size, default, col, row, options)
    options = getWidgetOptions(options, col, row, nil, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options)
    setOptional(widget, options)
    return widget
  end,
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

  local generateScale = notePanel:Menu("GenerateScale", scaleNames)
  generateScale.selected = #scaleNames
  generateScale.tooltip = "Set selected notes from scale"
  generateScale.showLabel = false
  generateScale.backgroundColour = colours.menuBackgroundColour
  generateScale.textColour = colours.widgetTextColour
  generateScale.arrowColour = colours.menuArrowColour
  generateScale.outlineColour = colours.menuOutlineColour
  generateScale.size = {144,20}
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
  getKey = getKey,
}

-----------------------------------------------------------------------------------------------------------------
-- Random Notes - Replaces note 0 in incoming note events with a random note from the selected key and scale
-----------------------------------------------------------------------------------------------------------------

local activeVoices = {}

local sequencerPanel = widgets.getPanel(1, 1, {
  width = 720,
  height = 30,
})

widgets.label("Random Note Input", 1, 1, {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

local channels = {"Omni"}
for j=1,16 do
  table.insert(channels, "" .. j)
end

local channelInput = widgets.menu("Channel", 1, channels, 1, 1, {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  width = 90,
  x = sequencerPanel.width - 95,
  y = 5
})

--------------------------------------------------------------------------------
-- Notes
--------------------------------------------------------------------------------

local notePanel = widgets.panel(1, 1, {
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 200,
})

local noteLabel = widgets.label("Notes", 1, 1, {
  tooltip = "Set the probability that notes will be included when generating new notes",
  alpha = 0.75,
  width = sequencerPanel.width,
})

local inputButton = widgets.button(" ", false, 8, 1, {
  tooltip = "Shows when notes are triggered",
  persistent = false,
  enabled = false,
  height = 18,
  width = channelInput.width,
  y = 1,
  x = channelInput.x,
})
inputButton.backgroundColourOff = "202020"
 
noteSelector.createNoteAndOctaveSelector(notePanel, widgets.colours, noteLabel, 15, 42, {x = 15, y = widgets.posUnder(noteLabel) + 10})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashInput()
  inputButton.backgroundColourOff = "606060"
  waitBeat(.125)
  inputButton.backgroundColourOff = "202020"
end

local function getNote()
  return gem.getRandomFromTable(noteSelector.getSelectedNotes())
end

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
  e.note = getNote()
  if noteIsPlaying(e.note) == false then
    local id = postEvent(e)
    table.insert(activeVoices, {id=id,event=e})
    spawn(flashInput)
  end
end

local function handleReleaseTrigger(e)
  for i,v in ipairs(activeVoices) do
    if v.event.channel == e.channel then
      releaseVoice(v.id)
      table.remove(activeVoices, i)
    end
  end
end

local function releaseVoices()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
    print("Release active voice on channel", v.event.channel)
  end
  activeVoices = {}
end

function onNote(e)
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
