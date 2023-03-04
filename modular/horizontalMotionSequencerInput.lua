----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local notes = require "includes.notes"
local resolutions = require "includes.resolutions"
local modular = require "includes.modular"
local tableMotion = require "includes.tableMotion"

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
local scalePos = 0
local activationMode = 1
local activationModes = {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off", "Min/Max:Toggle"}
local playModes = {"Right", "Left", "Drunk", "Random"}
local playMode = playModes[1]
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local noteState = {} -- Holds the state (on/off) for notes in the scale
local currentValue = {} -- Holds the current table value to check for changes
local forward = false
local channel = 0
local numNoteLabels = 9 -- Holds the maximum amount of note labels that are required when full range is used
local noteLabels = {} -- Holds the labels for the notes
local noteNumberToNoteName = notes.getNoteMapping()

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function updateNoteState(i, value)
  -- Only toggle if value is changed
  local valueHasChanged = value ~= currentValue[i]
  if valueHasChanged then
    if activationMode == 1 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = value == motionTable.max
    elseif activationMode == 2 and value == motionTable.max then
      noteState[i] = noteState[i] == false
    elseif activationMode == 3 and value == motionTable.min then
      noteState[i] = noteState[i] == false
    elseif activationMode == 4 and value == 0 then
      noteState[i] = noteState[i] == false
    elseif activationMode == 5 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = value == motionTable.min
    elseif activationMode == 6 and (value == motionTable.min or value == motionTable.max) then
      noteState[i] = noteState[i] == false
    end
  end
  -- Update the current value
  currentValue[i] = value
  if noteState[i] then
    positionTable:setValue(i, 1)
  else
    positionTable:setValue(i, 0)
  end
end

local function resetTableValues(loadShape)
  scalePos = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable, loadShape, updateNoteState)
end

local function startMoving()
  tableMotion.startMoving(motionTable, updateNoteState)
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues()
end

local function setScaleTable(loadShape)
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

  -- Reset table values and set start shape
  resetTableValues(loadShape)

  local distance = (#activeScale - 1) / (#noteLabels - 1)
  --print("distance", distance)
  local scaleIndex = 1
  for _,v in ipairs(noteLabels) do
    local i = gem.round(scaleIndex)
    --print("Round, scaleIndex, i", scaleIndex, i)
    v.text = noteNumberToNoteName[activeScale[i] + 1] .. notes.getOctave(activeScale[i])
    scaleIndex = gem.inc(scaleIndex, distance)
    --print("After inc: scaleIndex, #activeScale", scaleIndex, #activeScale)
  end

  -- Reset note state
  noteState = {}
  currentValue = {}
  for i=1, #activeScale do
    table.insert(noteState, false) -- Notes start deactivated
    table.insert(currentValue, nil) -- Set initial value
    updateNoteState(i, motionTable:getValue(i))
  end

  startMoving()
end

local function getNote()
  -- Find all active positions
  local activePositions = {}
  for i,v in ipairs(noteState) do
    if v then
      table.insert(activePositions, i)
    end
  end
  --print("activePositions", #activePositions)  
  --print("noteState", #noteState)

  if playMode == "Random" then
    -- Get a random position from the active positions
    scalePos = gem.getRandomFromTable(activePositions)
  else
    -- Walk up or down the scale
    if #activePositions > 1 then
      local increment = 1
      local resetAt = #activeScale
      local resetTo = 1
      if playMode == "Left" or (playMode == "Drunk" and gem.getRandomBoolean()) then
        increment = -1
        resetAt = 1
        resetTo = #activeScale
      end
      local counter = 1
      repeat
        scalePos = gem.inc(scalePos, increment, resetAt, resetTo)
        counter = gem.inc(counter)
      until noteState[scalePos] or counter > #activeScale
      if noteState[scalePos] == false then
        scalePos = 0
      end
    elseif #activePositions == 1 then
      scalePos = activePositions[1]
    else
      scalePos = 0
    end
  end

  --print("type(scalePos)", type(scalePos), scalePos)

  -- No active notes
  if scalePos == 1 or type(scalePos) == "nil" then
    scalePos = 0 -- Reset if no note was found
    return
  end

  -- Set in position table
  for i=1,positionTable.length do
    local val = 0
    if noteState[i] then
      val = 1
    end
    if i == scalePos then
      val = 2
    end
    positionTable:setValue(i, val)
  end

  -- Get note from scale
  return activeScale[scalePos]
end

local function startPlaying()
  if tableMotion.isMoving() then
    return
  end
  tableMotion.setMoving()
  setScaleTable()
  startMoving()
end

local function stopPlaying()
  if tableMotion.isNotMoving() then
    return
  end
  tableMotion.setMoving(false)
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
  x = 348,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label("Play Direction", {
  width = 81,
  backgroundColour = "transparent",
})

widgets.menu("Play Mode", playModes, {
  tooltip = "Set the play direction for the sequencer",
  showLabel = false,
  changed = function(self) playMode = self.selectedText end
})

widgets.button("Forward", forward, {
  tooltip = "Forward triggers (note=0 events) to the next processor",
  changed = function(self) forward = self.value end,
})

widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = sequencerPanel.width,
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 300,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  width = settingsPanel.width - 112,
  max = 2,
  integer = true,
  enabled = false,
  persistent = false,
  sliderColour = "green",
  backgroundColour = "CFFFFE",
  height = 10,
})

widgets.setSection({
  width = positionTable.width,
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

widgets.setSection({
  width = 24,
  height = 15,
  xSpacing = 1,
  ySpacing = 0,
  x = 0,
  y = widgets.posUnder(motionTable),
  cols = 27
})

for i=1,numNoteLabels do
  local factor = (i - 1) / (numNoteLabels - 1.04)
  table.insert(noteLabels, widgets.label(noteNumberToNoteName[i], {
    fontSize = 11,
    textColour = "#a0a0a0",
    backgroundColour = "transparent",
    x = math.floor(motionTable.width * factor) - math.ceil(18 * factor)
  }))
end

widgets.setSection({
  width = 109,
  height = 20,
  menuHeight = 45,
  xSpacing = 5,
  ySpacing = 5,
  x = 9,
  y = widgets.posUnder(motionTable) + 20,
  cols = 9
})

tableMotion.getStartShapeWidget().changed = function(self)
  tableMotion.options.startMode = self.value
  setScaleTable(true) -- Load a "fresh" shape without adjustments when selecting a shape
end

tableMotion.getSpeedSpreadWidget()
tableMotion.getStartDirectionWidget()

widgets.menu("Activation Mode", activationMode, activationModes, {
  tooltip = "Activation mode controls when notes in the table are activated and deactivated.",
  changed = function(self)
    activationMode = self.value
    setScaleTable()
  end
})

widgets.menu("Motion Type", tableMotion.movementTypes, {
  changed = function(self)
    tableMotion.options.movementType = self.selectedText
    setScaleTable()
  end
})

tableMotion.getMotionSpeedWidget(130)

widgets.row(2)

widgets.numBox("Range", tableRange, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
    setScaleTable()
  end
})

widgets.button("Reset", false, {
  tooltip = "Reset the start shape and direction",
  changed = function(self)
    setScaleTable()
    self.value = false
  end
})

widgets.numBox("Base Note", baseNote, {
  width = 54,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

scales.widget(137, false).changed = function(self)
  scaleDefinitionIndex = self.value
  setScaleTable()
end

widgets.numBox("Octave Range", octaveRange, {
  width = 137,
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScaleTable()
  end
})

tableMotion.getSpeedFactorWidget(130)

widgets.row()

tableMotion.setShapeWidgets(shapes.getWidgets(150, true))

widgets.button("Bipolar", bipolar, {
  tooltip = "Toggle table bipolar mode",
  width = 103,
  changed = function(self)
    bipolar = self.value
    setRange()
    setScaleTable()
  end
})

tableMotion.getSpeedRandWidget(130)

tableMotion.getShapeWidgets().phase.changed = function(self)
  tableMotion.getShapeOptions().phase = self.value
  setScaleTable()
end

tableMotion.getShapeWidgets().factor.changed = function(self)
  tableMotion.getShapeOptions().factor = self.value
  setScaleTable()
end

tableMotion.getShapeWidgets().z.changed = function(self)
  tableMotion.getShapeOptions().z = self.value
  setScaleTable()
end

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(motionTable)
xyShapeMorph.width = 100
xyShapeMorph.height = motionTable.height / 2

local xySpeedFactor = widgets.getPanel():XY('MotionResolution', 'SpeedFactor')
xySpeedFactor.y = widgets.posUnder(xyShapeMorph)
xySpeedFactor.x = xyShapeMorph.x
xySpeedFactor.width = xyShapeMorph.width
xySpeedFactor.height = (motionTable.height / 2) - 6

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  tableMotion.resetUniqueIndex()
  setScaleTable()
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
