--------------------------------------------------------------------------------
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"
local tableMotion = require "includes.tableMotion"

local backgroundColour = "202020" -- Light or Dark

setBackgroundColour(backgroundColour)

-- TODO Add parts and evolve like in generativeStrategySequencer

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

--local isPlaying = false
local tableRange = 16
local bipolar = true
local positionTable
local motionTable
local channel = 1
local triggerMode = 1 -- Holds the strategy for when events are triggered
local triggerModes = {"Min/Max", "Min", "Max", "Zero", "All"}
local currentValue = {} -- Holds the current table value to check for changes
local noteEventId = 0 -- Holds the index if the cell in the table that last triggered an event
local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local voiceId = nil -- Holds the id of the created note event

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function checkTrigger(i, value)
  --print("Running stateFunc")
  -- Send note event according to the selected trigger mode
  local valueHasChanged = value ~= currentValue[i]
  --print("value, currentValue[i], valueHasChanged", value, currentValue[i], valueHasChanged)
  -- Only set as trigger if value is changed
  if valueHasChanged then
    local isTrigger = false
    if triggerMode == 1 and (value == motionTable.min or value == motionTable.max) then
      isTrigger = true
    elseif triggerMode == 2 and value == motionTable.min then
      isTrigger = true
    elseif triggerMode == 3 and value == motionTable.max then
      isTrigger = true
    elseif triggerMode == 4 and value == 0 then
      isTrigger = true
    elseif triggerMode == 5 and (value == 0 or value == motionTable.min or value == motionTable.max) then
      isTrigger = true
    end
    if isTrigger then
      noteEventId = i
      print("Update noteEventId", noteEventId)
    end
  end
  -- Update the current value
  currentValue[i] = value
  --print("Update currentValue", value)
end

local function resetTableValues(loadShape)
  -- Reset event id
  noteEventId = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable, loadShape, checkTrigger)

  currentValue = {}
  for i=1,motionTable.length do
    table.insert(currentValue, nil) -- Set initial value
  end
end

local function setRange()
  print("Calling setRange")
  tableMotion.setRange(motionTable, tableRange, bipolar)
  print("Calling resetTableValues")
  resetTableValues()
  print("Done calling resetTableValues")
end

local function playTrigger()
  print("Play Trigger")
  if noteEventId > 0 then
    -- Release the voice if active
    if type(voiceId) == "userdata" then
      releaseVoice(voiceId)
      voiceId = nil
      print("Releasing trigger")
    end
    local velocity = 64
    voiceId = playNote(0, velocity, -1, nil, channel)
    print("Creating trigger")
    -- Mark the position that initiated the event
    for i=1,motionTable.length do
      local value = 0
      if i == noteEventId then
        value = 1
      end
      positionTable:setValue(i, value)
    end
    noteEventId = 0 -- Reset event id
  end
end

local function startMoving()
  if tableMotion.options.movementType == "Manual" and tableMotion.isNotMoving() then
    playTrigger()
  end
  print("StartMoving")
  tableMotion.startMoving(motionTable, checkTrigger)
end

local function sequenceRunner()
  startMoving()
  print("tableMotion.isMoving", tableMotion.isMoving())
  while tableMotion.isMoving() do
    playTrigger()
    waitBeat(resolutions.getResolution(resolution))
  end
end

local function startPlaying()
  if tableMotion.isMoving() then
    return
  end
  tableMotion.setMoving()
  run(sequenceRunner)
end

local function stopPlaying()
  if tableMotion.isNotMoving() then
    return
  end
  tableMotion.setMoving(false)
  resetTableValues()
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
    --print("Releasing trigger")
  end
end

--------------------------------------------------------------------------------
-- Motion Sequencer
--------------------------------------------------------------------------------

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Rythmic Motions Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  xOffset = (widgets.getPanel().width / 2) + 45,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

local channelInput = widgets.numBox('Channel', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end,
})

local autoplayButton = widgets.button('Auto Play', true, 2, 1, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, 3, 1)
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

--------------------------------------------------------------------------------
-- Sequencer Panel
--------------------------------------------------------------------------------

widgets.xSpacing(0)
widgets.ySpacing(0)
widgets.backgroundColour = "606060"

widgets.panel({
  backgroundColour = backgroundColour,
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 270,
})

positionTable = widgets.table("Position", 0, tableMotion.options.tableLength, {
  enabled = false,
  persistent = false,
  sliderColour = "yellow",
  width = sequencerPanel.width - 120,
  height = 6,
  x = 0,
  y = 0,
})

motionTable = widgets.table("Motion", 0, tableMotion.options.tableLength, {
  tooltip = "Events are triggered when the value hits max or min",
  showPopupDisplay = true,
  min = -tableRange,
  max = tableRange,
  integer = true,
  sliderColour = "pink",
  width = positionTable.width,
  height = 160,
  x = 0,
  y = widgets.posUnder(positionTable),
})

local noteWidgetHeight = 20
local noteWidgetWidth = 130
local noteWidgetRowSpacing = 5
local noteWidgetCellSpacing = 12
local firstRowY = motionTable.y + motionTable.height + (noteWidgetRowSpacing * 1.5)

widgets.setSection({
  width = 109,
  height = noteWidgetHeight,
  x = noteWidgetCellSpacing,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 9
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  tooltip = "The speed type works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center.",
  --width = 100,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

local startShape = widgets.menu("Start Shape", 4, tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  --width = 100,
  changed = function(self)
    print("Calling startShape:changed", self.selectedText)
    tableMotion.options.startMode = self.selectedText
    resetTableValues(true) -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

widgets.menu("Start Direction", tableMotion.directionStartModes, {
  tooltip = "Select start direction for the bars",
  --width = 100,
  changed = function(self) tableMotion.options.directionStartMode = self.selectedText end
})

widgets.menu("Trigger Mode", triggerMode, triggerModes, {
  --width = 100,
  changed = function(self) triggerMode = self.value end
})

widgets.menu("Quantize", resolution, resolutionNames, {
  width = 75,
  changed = function(self) resolution = self.value end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
  name = "MoveSpeed",
  width = 130,
  mapper = Mapper.Quartic,
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
  width = 130,
  mapper = Mapper.Cubic,
  x = moveSpeedInput.x,
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. When using morph, this controls phase amount. Controlled by the Y-axis on the XY controller",
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

widgets.numBox("Length", tableMotion.options.tableLength, {
  --width = 129,
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    resetTableValues()
    startMoving()
  end
})

widgets.button("Bipolar", bipolar, {
  --width = 51,
  changed = function(self)
    bipolar = self.value
    setRange()
  end
})

widgets.button("Reset", false, {
  --width = 51,
  changed = function(self)
    resetTableValues()
    startMoving()
    self.value = false
  end
})

widgets.menu("Motion Type", tableMotion.movementTypes, {
  width = 75,
  changed = function(self)
    tableMotion.options.movementType = self.selectedText
    startMoving()
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

widgets.row()

tableMotion.setShapeWidgets(shapes.getWidgets(widgets.getSectionValue('width'), true))

tableMotion.getShapeWidgets().stepRange.changed = function(self)
  tableMotion.getShapeOptions().stepRange = self.value
  resetTableValues()
  startMoving()
end

tableMotion.getShapeWidgets().phase.changed = function(self)
  tableMotion.getShapeOptions().phase = self.value
  resetTableValues()
  startMoving()
end

tableMotion.getShapeWidgets().factor.changed = function(self)
  tableMotion.getShapeOptions().factor = self.value
  resetTableValues()
  startMoving()
end

tableMotion.getShapeWidgets().z.changed = function(self)
  tableMotion.getShapeOptions().z = self.value
  resetTableValues()
  startMoving()
end

local xyShapeMorph = widgets.getPanel():XY('ShapePhase', 'ShapeMorph')
xyShapeMorph.y = motionTable.y
xyShapeMorph.x = widgets.posSide(motionTable)
xyShapeMorph.width = 102
xyShapeMorph.height = motionTable.height / 2

local xySpeedFactor = widgets.getPanel():XY('MoveSpeed', 'Factor')
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
  --tableMotion.setRange(motionTable, tableRange, bipolar)
  setRange()
end

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
