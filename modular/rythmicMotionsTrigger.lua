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

local isPlaying = false
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
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local morphSeqIndex = 0 -- Holds the unique id for the morpging sequencer
local movingCells = {}
local voiceId = nil -- Holds the id of the created note event
local shapeWidgets = {} -- Holds the widgets for controlling shape

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues(options)
  -- Reset event id
  noteEventId = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- TODO Check that shape adjustments are saved correctly!

  -- Set start mode
  options = tableMotion.setStartMode(motionTable, options)

  --print("options.stepRange, options.phase, options.factor, options.z", options.stepRange, options.phase, options.factor, options.z)

  -- Update widgets with values from the shape
  shapeWidgets.stepRange.value = options.stepRange
  shapeWidgets.phase.value = options.phase
  shapeWidgets.factor.value = options.factor
  shapeWidgets.z.value = options.z

  currentValue = {}
  for i=1,motionTable.length do
    table.insert(currentValue, nil) -- Set initial value
  end
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues(tableMotion.shapeOptions)
end

local function checkTrigger(i, value)
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
    end
  end
  -- Update the current value
  currentValue[i] = value
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
    checkTrigger(i, value)
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
  if tableMotion.options.useMorph then
    spawn(morph, morphSeqIndex, checkTrigger)
  else
    for i=1,motionTable.length do
      table.insert(movingCells, uniqueIndex)
      spawn(move, i, uniqueIndex)
      uniqueIndex = gem.inc(uniqueIndex)
    end
  end
end

local function sequenceRunner()
  startMoving()
  while isPlaying do
    if noteEventId > 0 then
      -- Release the voice if active
      if type(voiceId) == "userdata" then
        releaseVoice(voiceId)
        voiceId = nil
        --print("Releasing trigger")
      end
      local velocity = 64
      voiceId = playNote(0, velocity, -1, nil, channel)
      --print("Creating trigger")
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
    waitBeat(resolutions.getResolution(resolution))
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  run(sequenceRunner)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  resetTableValues(tableMotion.shapeOptions)
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
-- Notes Panel
--------------------------------------------------------------------------------

widgets.xSpacing(0)
widgets.ySpacing(0)
widgets.backgroundColour = "606060"

local notePanel = widgets.panel({
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
  width = sequencerPanel.width,
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
  width = sequencerPanel.width,
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
  width = noteWidgetWidth,
  height = noteWidgetHeight,
  x = noteWidgetCellSpacing,
  y = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 9
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  tooltip = "The speed type works with the speed factor to control speed variations across the table. Ramp Up means fast -> slower, Triangle means slower in the center.",
  width = 82,
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

local startShape = widgets.menu("Start Shape", 3, tableMotion.startModes, {
  tooltip = "Set how the table will look when starting.",
  width = 82,
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues() -- Load a "fresh" shape without adjustments when selecting a shape
  end
})

widgets.menu("Start Direction", tableMotion.directionStartModes, {
  tooltip = "Select start direction for the bars",
  width = 82,
  changed = function(self) tableMotion.options.directionStartMode = self.selectedText end
})

widgets.menu("Trigger Mode", triggerMode, triggerModes, {
  width = 75,
  changed = function(self) triggerMode = self.value end
})

widgets.menu("Quantize", resolution, resolutionNames, {
  width = 75,
  changed = function(self) resolution = self.value end
})

local moveSpeedInput = widgets.numBox("Motion Speed", tableMotion.options.moveSpeed, {
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
  x = moveSpeedInput.x,
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

widgets.numBox("Length", tableMotion.options.tableLength, {
  width = 129,
  min = 2,
  max = 128,
  integer = true,
  tooltip = "Set the table length",
  changed = function(self)
    tableMotion.options.tableLength = self.value
    positionTable.length = tableMotion.options.tableLength
    motionTable.length = tableMotion.options.tableLength
    resetTableValues(tableMotion.shapeOptions)
    startMoving()
  end
})

widgets.button("Bipolar", bipolar, {
  width = 75,
  changed = function(self)
    bipolar = self.value
    setRange()
  end
})

widgets.button("Reset", false, {
  width = 75,
  changed = function(self)
    resetTableValues(tableMotion.shapeOptions)
    startMoving()
    self.value = false
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

widgets.row()

shapeWidgets = shapes.getWidgets(138, true)

shapeWidgets.stepRange.changed = function(self)
  tableMotion.shapeOptions.stepRange = self.value
  resetTableValues(tableMotion.shapeOptions)
  startMoving()
end

shapeWidgets.phase.changed = function(self)
  tableMotion.shapeOptions.phase = self.value
  resetTableValues(tableMotion.shapeOptions)
  startMoving()
end

shapeWidgets.factor.changed = function(self)
  tableMotion.shapeOptions.factor = self.value
  resetTableValues(tableMotion.shapeOptions)
  startMoving()
end

shapeWidgets.z.changed = function(self)
  tableMotion.shapeOptions.z = self.value
  resetTableValues(tableMotion.shapeOptions)
  startMoving()
end

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput)
xySpeedFactor.width = 102
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

widgets.button("Morph", tableMotion.options.useMorph, {
  tooltip = "When active, use the shape morph for creating motion",
  x = xySpeedFactor.x,
  width = xySpeedFactor.width,
  changed = function(self)
    tableMotion.options.useMorph = self.value
    startMoving()
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
  setRange()
  startShape:changed()
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
