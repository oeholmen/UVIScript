----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local scales = require "includes.scales"
local modular = require "includes.modular"
local tableMotion = require "includes.tableMotion"

local backgroundColour = "606060"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
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
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morpging sequencer
local movingCells = {}
local forward = false
local channel = 0

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetPitches(options)
  pitchOffsetPos = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- TODO Check that shape adjustments are saved correctly!

  -- Set start mode
  options = tableMotion.setStartMode(motionTable, options)

  -- Update widgets with values from the shape
  local callChanged = true
  shapeWidgets.stepRange:setValue(options.stepRange, callChanged)
  shapeWidgets.phase:setValue(options.phase, callChanged)
  shapeWidgets.factor:setValue(options.factor, callChanged)
  shapeWidgets.z:setValue(options.z, callChanged)
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
  resetPitches(tableMotion.shapeOptions)
end

local function morph(uniqueId, stateFunction)
  print("startMorphing")
  local direction = tableMotion.getStartDirection()
  local morphSettings = {
    z = {
      value = shapeWidgets.z.value,
      min = shapeWidgets.z.min,
      max = shapeWidgets.z.max,
      direction = direction,
    },
    phase = {
      value = shapeWidgets.phase.value,
      min = shapeWidgets.phase.min,
      max = shapeWidgets.phase.max,
      direction = direction,
    }
  }
  while isPlaying and tableMotion.options.useMorph and morphSeqIndex == uniqueId do
    morphSettings.z.value, morphSettings.z.direction = tableMotion.advanceValue(motionTable, morphSettings.z.value, morphSettings.z.min, morphSettings.z.max, morphSettings.z.direction)
    if tableMotion.options.factor > 0 then
      local factor = tableMotion.options.factor / tableMotion.options.factorMax
      local min = morphSettings.phase.min * factor
      local max = morphSettings.phase.max * factor
      morphSettings.phase.value, morphSettings.phase.direction = tableMotion.advanceValue(motionTable, morphSettings.phase.value, min, max, morphSettings.phase.direction)
    end
    local options = {
      z = morphSettings.z.value,
      stepRange = tableMotion.shapeOptions.stepRange,
      phase = morphSettings.phase.value,
      factor = tableMotion.shapeOptions.factor,
    }
    tableMotion.setStartMode(motionTable, options, stateFunction)
    wait(tableMotion.getWaitDuration())
  end
end

local function move(i, uniqueId)
  local direction = tableMotion.getStartDirection(i)
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
    -- Wait happens in moveTable
  end
end

local function startMoving()
  if isPlaying == false then
    return
  end
  -- Reset index to stop motion
  morphSeqIndex = gem.inc(morphSeqIndex)
  movingCells = {}
  if tableMotion.options.manualMode then
    return -- Nothing needs to be done in manual mode
  elseif tableMotion.options.useMorph then
    spawn(morph, morphSeqIndex)
  else
    for i=1,motionTable.length do
      table.insert(movingCells, uniqueIndex)
      spawn(move, i, uniqueIndex)
      uniqueIndex = gem.inc(uniqueIndex)
    end
  end
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
    if playMode == "Down" or (playMode == "Drunk" and gem.getRandomBoolean()) then
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
  resetPitches(tableMotion.shapeOptions)
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
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(widgets.getPanel()),
  height = 276,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  width = widgets.getPanel().width - 146,
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

local startShape = widgets.menu("Start Mode", tableMotion.startModes, {
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetPitches() -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

local scaleMenu = widgets.menu("Scale", #scalesNames, scalesNames, {
  width = 90,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScale()
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
    setScale()
  end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  name = "MoveSpeed",
  mapper = Mapper.Quartic,
  x = widgets.posSide(noteInput),
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
  mapper = Mapper.Cubic,
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Length", tableMotion.options.tableLength, {
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    pitchOffsetPos = 1 -- Reset pos on length change
    resetPitches(tableMotion.shapeOptions)
    startMoving()
  end
})

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setScale()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  changed = function(self)
    resetPitches(tableMotion.shapeOptions)
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
    setScale()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

widgets.row()

shapeWidgets = shapes.getWidgets(noteWidgetWidth, true)

shapeWidgets.stepRange.changed = function(self)
  tableMotion.shapeOptions.stepRange = self.value
  setScale()
  startMoving()
end

shapeWidgets.phase.changed = function(self)
  tableMotion.shapeOptions.phase = self.value
  setScale()
  startMoving()
end

shapeWidgets.factor.changed = function(self)
  tableMotion.shapeOptions.factor = self.value
  setScale()
  startMoving()
end

shapeWidgets.z.changed = function(self)
  tableMotion.shapeOptions.z = self.value
  setScale()
  startMoving()
end

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput) - 5
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = xySpeedFactor.x
xyShapeMorph.width = xySpeedFactor.width
xyShapeMorph.height = motionTable.height

widgets.button("Morph", tableMotion.options.useMorph, {
  tooltip = "When active, use the shape morph for creating motion",
  x = xyShapeMorph.x,
  width = (xyShapeMorph.width / 2) - 3,
  changed = function(self)
    tableMotion.options.useMorph = self.value
    startMoving()
  end
})

widgets.button("Manual", tableMotion.options.manualMode, {
  tooltip = "When active, use the shape morph for creating motion",
  x = xyShapeMorph.x + (xyShapeMorph.width / 2),
  width = xyShapeMorph.width / 2,
  changed = function(self)
    tableMotion.options.manualMode = self.value
    startMoving()
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setScale()
  startShape:changed()
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
