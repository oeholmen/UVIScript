--------------------------------------------------------------------------------
-- Rythmic Motions - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
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
local noteEventId = 0 -- Holds the index if the cell in the table that last triggered an event
local resolutionNames = resolutions.getResolutionNames()
local resolution = #resolutionNames
local uniqueIndex = 1 -- Holds the unique id for each moving spawn
local movingCells = {}
local voiceId = nil -- Holds the id of the created note event

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function resetTableValues()
  -- Reset event id
  noteEventId = 0

  -- Reset position
  tableMotion.setTableZero(positionTable)

  -- Set start mode
  tableMotion.setStartMode(motionTable)
end

local function setRange()
  tableMotion.setRange(motionTable, tableRange, bipolar)
  resetTableValues()
end

local function move(i, uniqueId)
  local direction = 1
  local value = motionTable:getValue(i)
  while isPlaying and movingCells[i] == uniqueId do
    -- Send note event if value is min or max
    if value == motionTable.min or value == motionTable.max then
      noteEventId = i
    end  
    value, direction = tableMotion.moveTable(motionTable, i, value, direction)
  end
end

local function startMoving()
  movingCells = {} -- Reset index to stop
  for i=1,motionTable.length do
    table.insert(movingCells, uniqueIndex)
    spawn(move, i, uniqueIndex)
    uniqueIndex = gem.inc(uniqueIndex)
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
  height = 250,
})

positionTable = widgets.table(tableMotion.options.tableLength, 0, {
  enabled = false,
  persistent = false,
  sliderColour = "green",
  width = sequencerPanel.width,
  height = 6,
  x = 0,
  y = 0,
})

motionTable = widgets.table(tableMotion.options.tableLength, 0, {
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
  xOffset = noteWidgetCellSpacing,
  yOffset = firstRowY,
  xSpacing = noteWidgetCellSpacing,
  ySpacing = noteWidgetRowSpacing,
  cols = 4
})

widgets.menu("Speed Type", tableMotion.speedTypes, {
  changed = function(self) tableMotion.options.speedType = self.selectedText end
})

widgets.menu("Start Mode", tableMotion.startModes, {
  changed = function(self)
    tableMotion.options.startMode = self.selectedText
    resetTableValues()
  end
})

widgets.menu("Quantize", resolution, resolutionNames, {
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

widgets.col(3)

widgets.numBox("Speed Factor", tableMotion.options.factor, {
  name = "Factor",
  min = tableMotion.options.factorMin,
  max = tableMotion.options.factorMax,
  tooltip = "Set the factor of slowdown or speedup per cell. High factor = big difference between cells, 0 = all cells are moving at the same speed. Controlled by the Y-axis on the XY controller",
  changed = function(self) tableMotion.options.factor = self.value end
})

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

local bipolarButton = widgets.button("Bipolar", bipolar, {
  width = (noteWidgetWidth / 2) - (noteWidgetCellSpacing / 2),
  changed = function(self)
    bipolar = self.value
    setRange()
  end
})

widgets.button("Reset", false, {
  width = bipolarButton.width,
  x = widgets.posSide(bipolarButton),
  increment = false,
  changed = function(self)
    resetTableValues()
    startMoving()
    self.value = false
  end
})

widgets.numBox("Speed Rand", tableMotion.options.speedRandomizationAmount, {
  unit = Unit.Percent,
  tooltip = "Set the radomization amount applied to speed",
  changed = function(self) tableMotion.options.speedRandomizationAmount = self.value end
})

local xySpeedFactor = notePanel:XY('MoveSpeed', 'Factor')
xySpeedFactor.y = firstRowY
xySpeedFactor.x = widgets.posSide(moveSpeedInput)
xySpeedFactor.width = noteWidgetWidth
xySpeedFactor.height = (noteWidgetHeight * 3) + (noteWidgetRowSpacing * 2)

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  print("Init sequencer")
  uniqueIndex = 1
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
