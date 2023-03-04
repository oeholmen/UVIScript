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
local octaveRange = 2 -- Option
local bipolar = true -- Option
local pitchOffsetPos = 0
local positionTable
local motionTable
local playModes = {"Right", "Left", "Drunk", "Random"}
local playMode = playModes[1]
local scalesNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scalesNames
local activeScale = {} -- Holds the active scale
local forward = false
local channel = 0
local numNoteLabels = 9 -- Holds the maximum amount of note labels that are required when full range is used
local noteLabels = {} -- Holds the labels for the notes
local noteNumberToNoteName = notes.getNoteMapping()


--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches(loadShape)
  pitchOffsetPos = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable, loadShape)
end

local function setScale()
  local scaleDefinition = scaleDefinitions[scaleDefinitionIndex]
  local oneOctScale = scales.createScale(scaleDefinition, 0, 11)
  --print("#oneOctScale", #oneOctScale)
  -- Check octave range / bipolar before setting the table range
  local tableRange = #oneOctScale * octaveRange
  --print("tableRange", tableRange)
  tableMotion.setRange(motionTable, tableRange, bipolar)
  local startNote = baseNote
  if bipolar then
    startNote = startNote - (octaveRange * 12)
  end
  local maxNote = baseNote + (octaveRange * 12)
  activeScale = scales.createScale(scaleDefinition, startNote, maxNote)
  --print("#activeScale, startNote, maxNote", #activeScale, startNote, maxNote)
  resetPitches()

  local distance = (#activeScale - 1) / (#noteLabels - 1)
  --print("distance", distance)
  local scaleIndex = #activeScale
  for _,v in ipairs(noteLabels) do
    local i = gem.round(scaleIndex)
    --print("Round, scaleIndex, i", scaleIndex, i)
    v.text = noteNumberToNoteName[activeScale[i] + 1] .. notes.getOctave(activeScale[i])
    scaleIndex = gem.inc(scaleIndex, -distance)
    --print("After inc: scaleIndex, #activeScale", scaleIndex, #activeScale)
  end
end

local function startMoving()
  tableMotion.startMoving(motionTable)
end

local function getNote()
  -- Increment table pos
  if playMode == "Random" then
    -- Get a random position from the active positions
    pitchOffsetPos = gem.getRandom(motionTable.length)
  else
    -- Walk up or down the scale
    local increment = 1
    local resetAt = motionTable.length
    local resetTo = 1
    if playMode == "Left" or (playMode == "Drunk" and gem.getRandomBoolean()) then
      increment = -1
      resetAt = 1
      resetTo = motionTable.length
    end
    pitchOffsetPos = gem.inc(pitchOffsetPos, increment, resetAt, resetTo)
  end
  --print("pitchOffsetPos", pitchOffsetPos)
  -- Set position in position table
  for i=1,positionTable.length do
    local val = 0
    if i == pitchOffsetPos then
      val = 1
    end
    positionTable:setValue(i, val)
  end
  -- Get scale pos
  local scalePos = motionTable:getValue(pitchOffsetPos) + 1
  -- Bipolar check
  if motionTable.min < 0 then
    scalePos = scalePos + math.abs(motionTable.min)
  end
  -- Get note at pos
  return activeScale[scalePos]
end

local function startPlaying()
  if tableMotion.isMoving() then
    return
  end
  tableMotion.setMoving()
  startMoving()
end

local function stopPlaying()
  if tableMotion.isNotMoving() then
    return
  end
  tableMotion.setMoving(false)
  resetPitches()
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Motion Sequencer Input", {
  tooltip = "This sequencer listens to incoming pulses from a rythmic sequencer (Sent as note 0) and generates notes in response",
  width = widgets.getPanel().width,
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

local channelInput = widgets.menu("Channel", widgets.channels(), {
  tooltip = "Listen to note events on this channel - if a note event is not being listened to, it will be pass through",
  showLabel = false,
  changed = function(self) channel = self.value - 1 end
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setSection({
  width = widgets.getPanel().width,
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
  cols = 7
})

widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(widgets.getPanel()),
  height = 276,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  width = widgets.getPanel().width - 160,
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
  width = positionTable.width,
  showPopupDisplay = true,
  backgroundColour = "191E25",
  min = -24,
  max = 24,
  integer = true,
})

widgets.setSection({
  width = 24,
  height = 15,
  xSpacing = 1,
  ySpacing = 0,
  x = widgets.posSide(motionTable) - 1,
  y = motionTable.y,
  cols = 1
})

for i=1,numNoteLabels do
  local factor = (i - 1) / (numNoteLabels - 1.04)
  table.insert(noteLabels, widgets.label(noteNumberToNoteName[i], {
    fontSize = 11,
    textColour = "#a0a0a0",
    backgroundColour = "transparent",
    y = (motionTable.y - 3) + (math.floor(motionTable.height * factor) - math.ceil(9 * factor))
  }))
end

local noteWidgetWidth = 129

widgets.setSection({
  width = noteWidgetWidth,
  height = 20,
  menuHeight = 45,
  x = 10,
  y = widgets.posUnder(motionTable) + 6,
  xSpacing = 14,
  ySpacing = 5,
  cols = 7
})

tableMotion.getStartShapeWidget().changed = function(self)
  tableMotion.options.startMode = self.value
  resetPitches(true) -- Load a "fresh" shape without adjustments when selecting a shape
end

tableMotion.getSpeedSpreadWidget(85)
tableMotion.getStartDirectionWidget(84)

widgets.menu("Motion Type", tableMotion.movementTypes, {
  width = 75,
  changed = function(self)
    tableMotion.options.movementType = self.selectedText
    startMoving()
  end
})

--[[ widgets.menu("Scale", #scalesNames, scalesNames, {
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScale()
  end
}) ]]

scales.widget(noteWidgetWidth).changed = function(self)
  scaleDefinitionIndex = self.value
  setScale()
end

tableMotion.getMotionSpeedWidget(noteWidgetWidth)

widgets.row(2)

widgets.numBox("Length", tableMotion.options.tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the sequence length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    resetPitches()
    startMoving()
  end
})

widgets.button("Reset", false, {
  changed = function(self)
    resetPitches()
    startMoving()
    self.value = false
  end
})

widgets.button("Bipolar", bipolar, {
  changed = function(self)
    bipolar = self.value
    setScale()
  end
})

widgets.numBox("Base Note", baseNote, {
  unit = Unit.MidiKey,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScale()
  end
})

tableMotion.getSpeedFactorWidget(noteWidgetWidth)

widgets.row()

tableMotion.setShapeWidgets(shapes.getWidgets(noteWidgetWidth, true))

widgets.numBox("Octave Range", octaveRange, {
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScale()
  end
})

tableMotion.getSpeedRandWidget(noteWidgetWidth)

tableMotion.getShapeWidgets().phase.changed = function(self)
  tableMotion.getShapeOptions().phase = self.value
  setScale()
  startMoving()
end

tableMotion.getShapeWidgets().factor.changed = function(self)
  tableMotion.getShapeOptions().factor = self.value
  setScale()
  startMoving()
end

tableMotion.getShapeWidgets().z.changed = function(self)
  tableMotion.getShapeOptions().z = self.value
  setScale()
  startMoving()
end

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(motionTable) + 7
xyShapeMorph.width = noteWidgetWidth + 5
xyShapeMorph.height = motionTable.height / 2

local xySpeedFactor = widgets.getPanel():XY('MotionResolution', 'SpeedFactor')
xySpeedFactor.y = widgets.posUnder(xyShapeMorph)
xySpeedFactor.x = xyShapeMorph.x
xySpeedFactor.width = xyShapeMorph.width
xySpeedFactor.height = (motionTable.height / 2) - 5

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  tableMotion.resetUniqueIndex()
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
