----------------------------------------------------------------------------------
-- Motion Sequencer - Listens for incoming note events (rythm) on note number 0
----------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
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

  -- Reset note state
  noteState = {}
  currentValue = {}
  for i,v in ipairs(activeScale) do
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
        scalePos = nil
      end
    elseif #activePositions == 1 then
      scalePos = activePositions[1]
    else
      scalePos = nil
    end
  end

  --print("type(scalePos)", type(scalePos), scalePos)

  -- No active notes
  if type(scalePos) == "nil" then
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
  x = 0,
  y = 0,
  xSpacing = 0,
  ySpacing = 0,
})

local settingsPanel = widgets.panel({
  backgroundColour = backgroundColour,
  y = widgets.posUnder(sequencerPanel),
  height = 280,
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

local noteWidgetHeight = 20
local noteWidgetWidth = 138
local noteWidgetRowSpacing = 6
local noteWidgetCellSpacing = 6
local firstRowY = motionTable.y + motionTable.height + 6

widgets.setSection({
  width = 109,
  height = noteWidgetHeight,
  menuHeight = 45,
  x = 10,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 9
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  tooltip = "The speed type works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center.",
  changed = function(self)
    tableMotion.options.speedType = self.selectedText
    setScaleTable()
  end
})

local startShape = widgets.menu("Start Shape", tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    setScaleTable(true) -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

widgets.menu("Start Direction", tableMotion.directionStartModes, {
  tooltip = "Select start direction for the bars",
  changed = function(self)
    tableMotion.options.directionStartMode = self.selectedText
    setScaleTable()
  end
})

local activationModeMenu = widgets.menu("Activation Mode", activationMode, activationModes, {
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

widgets.row()

widgets.col(5)

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  name = "MoveSpeed",
  width = 130,
  mapper = Mapper.Quartic,
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
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

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 54,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 137,
  showLabel = false,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScaleTable()
  end
})

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

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  width = 130,
  mapper = Mapper.Cubic,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  changed = function(self)
    tableMotion.options.factor = self.value
    setScaleTable()
  end
})

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

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  tooltip = "Set the radomization amount applied to speed",
  width = 130,
  unit = Unit.Percent,
  integer = false,
  mapper = Mapper.Quadratic,
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

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

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
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
