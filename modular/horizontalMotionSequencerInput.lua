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

local isPlaying = false
local baseNote = 60 -- Option
local tableRange = 16
local octaveRange = 2 -- Option
local bipolar = true -- Option
local scalePos = 0
local activationMode = 1
local activationModes = {"Max:On,Min:Off", "Max:Toggle", "Min:Toggle", "Zero:Toggle", "Min:On,Max:Off", "Min/Max:Toggle"}
local playModes = {"Random", "Up", "Down", "Alternate"}
local playMode = playModes[1]
local positionTable
local motionTable
local scaleNames = scales.getScaleNames()
local scaleDefinitions = scales.getScaleDefinitions()
local scaleDefinitionIndex = #scaleNames
local activeScale = {} -- Holds the active scale
local noteState = {} -- Holds the state (on/off) for notes in the scale
local currentValue = {} -- Holds the current table value to check for changes
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morpging sequencer
local movingCells = {}
local forward = false
local channel = 0
local shapeWidgets = {} -- Holds the widgets for controlling shape

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues(options)
  scalePos = 0

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

local function manual(uniqueId, stateFunction)
  while isPlaying and tableMotion.options.manualMode and morphSeqIndex == uniqueId do
    tableMotion.setStartMode(motionTable, tableMotion.shapeOptions, stateFunction)
    wait(tableMotion.getWaitDuration())
  end
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
    for _,v in ipairs({"z", "phase"}) do
      morphSettings[v].value, morphSettings[v].direction = tableMotion.advanceValue(motionTable, morphSettings[v].value, morphSettings[v].min, morphSettings[v].max, morphSettings[v].direction)
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
    updateNoteState(i, value)
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
    spawn(manual, morphSeqIndex, updateNoteState)
  elseif tableMotion.options.useMorph then
    spawn(morph, morphSeqIndex, updateNoteState)
  else
    for i=1,motionTable.length do
      table.insert(movingCells, uniqueIndex)
      spawn(move, i, uniqueIndex)
      uniqueIndex = gem.inc(uniqueIndex)
    end
  end
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues(tableMotion.shapeOptions)
end

local function setScaleTable()
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
  resetTableValues(tableMotion.shapeOptions)

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
      if playMode == "Down" or (playMode == "Alternate" and gem.getRandomBoolean()) then
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
  if isPlaying then
    return
  end
  isPlaying = true
  setScaleTable()
  startMoving()
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues(tableMotion.shapeOptions)
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
  width = noteWidgetWidth,
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
  width = 81,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

local startShape = widgets.menu("Start Shape", 3, tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  width = 81,
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues() -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

widgets.menu("Start Direction", tableMotion.directionStartModes, {
  tooltip = "Select start direction for the bars",
  width = 81,
  changed = function(self) tableMotion.options.directionStartMode = self.selectedText end
})

local activationModeMenu = widgets.menu("Activation Mode", activationMode, activationModes, {
  tooltip = "Activation mode controls when notes in the table are activated and deactivated.",
  width = 105,
  changed = function(self) activationMode = self.value end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  x = 470,
  name = "MoveSpeed",
  tooltip = "Set the speed of the up/down motion in each cell - Controlled by the X-axis on the XY controller",
  min = tableMotion.options.moveSpeedMin,
  max = tableMotion.options.moveSpeedMax,
  unit = Unit.MilliSeconds,
  changed = function(self) tableMotion.options.moveSpeed = self.value end
})

widgets.row()

widgets.button("Bipolar", bipolar, {
  tooltip = "Toggle table bipolar mode",
  x = widgets.posSide(activationModeMenu),
  width = 81,
  changed = function(self)
    bipolar = self.value
    setRange()
    setScaleTable()
    startMoving()
  end
})

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  x = moveSpeedInput.x,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  changed = function(self) tableMotion.options.factor = self.value end
})

widgets.row()

widgets.numBox("Range", tableRange, {
  width = 81,
  min = 8,
  max = 128,
  integer = true,
  tooltip = "Set the table range - high range = fewer events, low range = more events",
  changed = function(self)
    tableRange = self.value
    setRange()
    startMoving()
  end
})

-- TODO Add a menu for automatic reset options?
widgets.button("Reset", false, {
  tooltip = "Reset the start shape and direction",
  width = 81,
  changed = function(self)
    resetTableValues(tableMotion.shapeOptions)
    setScaleTable()
    startMoving()
    self.value = false
  end
})

local noteInput = widgets.numBox("Base Note", baseNote, {
  width = 33,
  unit = Unit.MidiKey,
  showLabel = false,
  tooltip = "Set the root note",
  changed = function(self)
    baseNote = self.value
    setScaleTable()
  end
})

widgets.menu("Scale", #scaleNames, scaleNames, {
  width = 117,
  showLabel = false,
  changed = function(self)
    scaleDefinitionIndex = self.value
    setScaleTable()
  end
})

widgets.numBox("Octave Range", octaveRange, {
  width = 117,
  tooltip = "Set the octave range",
  min = 1,
  max = 4,
  integer = true,
  changed = function(self)
    octaveRange = self.value
    setScaleTable()
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  tooltip = "Set the radomization amount applied to speed",
  x = moveSpeedInput.x,
  unit = Unit.Percent,
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

widgets.row()

shapeWidgets = shapes.getWidgets(109, true)

shapeWidgets.stepRange.changed = function(self)
  tableMotion.shapeOptions.stepRange = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.phase.changed = function(self)
  tableMotion.shapeOptions.phase = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.factor.changed = function(self)
  tableMotion.shapeOptions.factor = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

shapeWidgets.z.changed = function(self)
  tableMotion.shapeOptions.z = self.value
  resetTableValues(tableMotion.shapeOptions)
  setScaleTable()
  startMoving()
end

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput)
xySpeedFactor.width = 100
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(motionTable)
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
  setScaleTable()
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
