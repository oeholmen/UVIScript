----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local notes = require "includes.notes"
local modular = require "includes.modular"
local tableMotion = require "includes.tableMotion"

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local sequencerResolution = 0.25 -- Fallback value
local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local forward = false
local channel = 0
local notePositionIndex = 0 -- Holds the index if the cell in the table that last set a note active

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

function getScale(scaleIndex, keyIndex)
  local octave = octaveOffset.value + 2 -- Set the start octave for the scale
  print("getScale: octave", octave)
  local scaleDefinition = scaleDefinitions[scaleIndex]
  local rootNote = (keyIndex - 1) + (octave * 12) -- Root note
  print("getScale: rootNote", rootNote)
  return scales.createScale(scaleDefinition, rootNote)
end

function setScale(scaleIndex, keyIndex)
  local scale = getScale(scaleIndex, keyIndex)
  for i,v in ipairs(paramsPerNote) do
    if type(scale[i]) ~= "number" then
      break
    end
    v.noteInput:setValue(scale[i])
  end
end

function flashNoteLabel(voice, duration)
  local flashDuration = 150
  if type(duration) == "number" then
    flashDuration = beat2ms(duration)
  end
  paramsPerNote[voice].noteInput.textColour = "efefef"
  wait(flashDuration)
  paramsPerNote[voice].noteInput.textColour = menuTextColour
end

function doSelectNote(voice)
  return paramsPerNote[voice].mute.value == false and gem.getRandomBoolean(paramsPerNote[voice].noteProbability.value)
end

function generateNote()
  local selectedNotes = {}
  for i=1,numNotes do
    if doSelectNote(i) then
      table.insert(selectedNotes, i)
    end
  end

  if #selectedNotes == 0 then
    return nil
  end

  local note = nil
  local noteIndex = nil
  local maxRounds = 100
  repeat
    noteIndex = gem.getRandomFromTable(selectedNotes)
    note = paramsPerNote[noteIndex].noteInput.value
    maxRounds = maxRounds - 1
  until gem.tableIncludes(notesPlaying, selectedNotes[noteIndex]) == false or maxRounds < 1
  return noteIndex, note
end

local function resetTableValues()
  -- Reset note position index
  notePositionIndex = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable)
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    -- Set note position active when value is min or max
    if value == motionTable.min or value == motionTable.max then
      notePositionIndex = i
      --print("Set note position active when value is min or max", i)
    end
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop motion
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
  end
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues()
end

local function setTableRange()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)

  -- Set table length according to the number of notes in the selected scale
  tableMotion.options.tableLength = #activeScale
  positionTable.length = tableMotion.options.tableLength
  motionTable.length = tableMotion.options.tableLength

  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetTableValues()
  startMoving()
end

local function getResetPosition()
  local reset = gem.getRandom(4)

  -- Lowest
  if reset == 1 then
    return 1
  end

  -- Middle
  if reset == 2 then
    return math.ceil(#activeScale / 2)
  end

  -- Random
  if reset == 3 then
    return gem.getRandom(#activeScale)
  end

  -- Highest
  return #activeScale
end

local function getNote()
  if notePositionIndex < 1 or notePositionIndex > #activeScale then
    notePositionIndex = getResetPosition()
  end
  for i=1,positionTable.length do
    local val = 0
    if i == notePositionIndex then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  return activeScale[notePositionIndex]
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Horizontal Motion Sequencer", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  xOffset = 531,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 250,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 6,
})

widgets.setSection({
  height = 160,
  y = widgets.posUnder(positionTable),
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -tableRange,
  max = tableRange,
  integer = true,
})

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 14
local firstRowY = motionTable.y + motionTable.height + 10

widgets.setSection({
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  menuHeight = 45,
  xOffset = 10,
  yOffset = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

widgets.menu("Start Mode", 3, tableMotion.startModes, {
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues()
  end
}):changed()

local scaleMenu = widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 90,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setTableRange()
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  x = widgets.posSide(scaleMenu) - 7,
  y = firstRowY + 25,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setTableRange()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  x = widgets.posSide(noteInput),
  name = "MoveSpeed",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()
widgets.col(3)

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Range", tableRange, {
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
  end
})

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setRange()
    setTableRange()
    startMoving()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  changed = function(self)
    resetTableValues()
    startMoving()
    self.value = false
  end
})

widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setTableRange()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput) - 5
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

local colours = widgets.getColours()
local noteNames = notes.getNoteNames()
--local scaleNames = scales.getScaleNames()
--local scaleDefinitions = scales.getScaleDefinitions()
local noteListen = nil
local paramsPerNote = {}
local rowSpacing = 3
local numNotes = 8

local notePanel = widgets.panel({
  backgroundColour = "404040",
  y = widgets.posUnder(settingsPanel),
  x = 10,
  width = 700,
  height = 110,
})

local noteLabel = notePanel:Label("NotesLabel")
noteLabel.text = "Notes"
noteLabel.tooltip = "Set the probability that notes will be included when generating new notes"
noteLabel.alpha = 0.75
noteLabel.fontSize = 15
noteLabel.width = 300

local generateKey = notePanel:Menu("GenerateKey", noteNames)
generateKey.persistent = false
generateKey.tooltip = "Set selected notes from key"
generateKey.showLabel = false
generateKey.backgroundColour = colours.menuBackgroundColour
generateKey.textColour = colours.widgetTextColour
generateKey.arrowColour = colours.menuArrowColour
generateKey.outlineColour = colours.menuOutlineColour
generateKey.width = 60
generateKey.height = 18
generateKey.x = noteLabel.x + noteLabel.width + 10
generateKey.y = noteLabel.y

local generateScale = notePanel:Menu("GenerateScale", scaleNames)
generateScale.persistent = false
generateScale.tooltip = "Set selected notes from scale"
generateScale.showLabel = false
generateScale.backgroundColour = colours.menuBackgroundColour
generateScale.textColour = colours.widgetTextColour
generateScale.arrowColour = colours.menuArrowColour
generateScale.outlineColour = colours.menuOutlineColour
generateScale.width = 120
generateScale.height = generateKey.height
generateScale.x = generateKey.x + generateKey.width + 10
generateScale.y = generateKey.y

local octaveOffset = notePanel:NumBox("OctaveOffset", 2, -2, 6, true)
octaveOffset.persistent = false
octaveOffset.displayName = "Octave"
octaveOffset.tooltip = "Set the octave to start from"
octaveOffset.backgroundColour = colours.menuBackgroundColour
octaveOffset.textColour = colours.menuTextColour
octaveOffset.width = 90
octaveOffset.height = generateScale.height
octaveOffset.x = generateScale.x + generateScale.width + 10
octaveOffset.y = generateScale.y

local templates = {
  "Tools...",
  "Mute all",
  "Unmute all",
  "Toggle mute",
  "Set all note probabilities to 100%",
  "Set all note probabilities to 0%",
  "Randomize note probabilities",
  "Randomize notes",
}
local templateMenu = notePanel:Menu("Templates", templates)
templateMenu.tooltip = "Select a tool - NOTE: Will change current settings!"
templateMenu.showLabel = false
templateMenu.width = 75
templateMenu.height = octaveOffset.height
templateMenu.x = octaveOffset.x + octaveOffset.width + 10
templateMenu.y = octaveOffset.y
templateMenu.backgroundColour = colours.menuBackgroundColour
templateMenu.textColour = colours.widgetTextColour
templateMenu.arrowColour = colours.menuArrowColour
templateMenu.outlineColour = colours.menuOutlineColour
templateMenu.changed = function(self)
  if self.value == 1 then
    return
  end
  for part,v in ipairs(paramsPerNote) do
    if self.selectedText == "Mute all" then
      v.mute:setValue(true)
    elseif self.selectedText == "Unmute all" then
      v.mute:setValue(false)
    elseif self.selectedText == "Toggle mute" then
      v.mute:setValue(v.mute.value == false)
    elseif self.selectedText == "Set all note probabilities to 100%" then
      v.noteProbability:setValue(100)
    elseif self.selectedText == "Set all note probabilities to 0%" then
      v.noteProbability:setValue(0)
    elseif self.selectedText == "Randomize note probabilities" then
      v.noteProbability:setValue(gem.getRandom(100))
    elseif self.selectedText == "Randomize notes" then
      v.noteInput:setValue(gem.getRandom(21, 108))
    end
  end
  -- Must be last
  self:setValue(1, false)
end

generateKey.changed = function(self)
  setScale(generateScale.value, self.value)
end

generateScale.changed = function(self)
  setScale(self.value, generateKey.value)
end

octaveOffset.changed = function(self)
  setScale(generateScale.value, generateKey.value)
end

local inputWidth = 654 / numNotes
for i=1,numNotes do
  local noteInput = notePanel:NumBox("TriggerNote" .. i, (47+i), 0, 127, true)
  noteInput.displayName = "Note"
  noteInput.tooltip = "The note to trigger"
  noteInput.unit = Unit.MidiKey
  noteInput.showLabel = false
  noteInput.backgroundColour = colours.menuBackgroundColour
  noteInput.textColour = colours.menuTextColour
  noteInput.height = 22
  noteInput.width = inputWidth
  noteInput.x = ((noteInput.width + 5) * (i - 1)) + 10
  noteInput.y = noteLabel.height + 10

  local noteProbability = notePanel:NumBox("NoteProbability" .. i, 100, 0, 100, true)
  noteProbability.tooltip = "Probability that note will be played"
  noteProbability.unit = Unit.Percent
  noteProbability.showLabel = false
  noteProbability.backgroundColour = colours.menuBackgroundColour
  noteProbability.textColour = colours.menuTextColour
  noteProbability.height = noteInput.height
  noteProbability.width = noteInput.width
  noteProbability.x = noteInput.x-- + noteInput.width + rowSpacing
  noteProbability.y = noteInput.y + noteInput.height + rowSpacing

  local listen = notePanel:OnOffButton("Listen" .. i)
  listen.displayName = "Learn"
  listen.tooltip = "Note learn"
  listen.persistent = false
  listen.textColourOff = "white"
  listen.backgroundColourOn = "green"
  listen.height = noteInput.height
  listen.width = noteInput.width / 2
  listen.x = noteProbability.x
  listen.y = noteProbability.y + noteProbability.height + rowSpacing
  listen.changed = function(self)
    if self.value then
      noteListen = i
    else
      noteListen = nil
    end
  end

  local mute = notePanel:OnOffButton("Mute" .. i)
  mute.displayName = "Mute"
  mute.tooltip = "Mute note"
  mute.textColourOff = "white"
  mute.backgroundColourOn = "red"
  mute.height = listen.height
  mute.width = listen.width
  mute.x = listen.x + listen.width-- + rowSpacing
  mute.y = listen.y

  table.insert(paramsPerNote, {noteInput=noteInput, noteProbability=noteProbability, listen=listen, mute=mute})
end

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setScale()
end

function onNote(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    startPlaying()
    modular.handleTrigger(e, getNote())
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e, channel) then
    if forward then
      postEvent(e)
    end
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == true then
    startPlaying()
  else
    stopPlaying()
  end
end
